// Supabase Edge Function: super-endpoint (payment confirmation -> points credit)
// - The charge screen calls this right after payment. PortOne webhooks can call it too.
// - Values sent from the browser are never trusted: the payment is looked up directly at PortOne.
// - One order is credited only once (guaranteed by the DB function credit_charge_order).
import { createClient } from 'npm:@supabase/supabase-js@2';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SERVICE_KEY  = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

// Secret names: the new names are preferred, the names already registered in this project (IMP_KEY / IMP_SECRET) also work.
const PORTONE_API_SECRET = Deno.env.get('PORTONE_API_SECRET') ?? '';                                  // PortOne V2 API Secret (optional)
const IAMPORT_API_KEY    = Deno.env.get('IAMPORT_API_KEY')    ?? Deno.env.get('IMP_KEY')    ?? '';   // PortOne V1 REST API key
const IAMPORT_API_SECRET = Deno.env.get('IAMPORT_API_SECRET') ?? Deno.env.get('IMP_SECRET') ?? '';   // PortOne V1 REST API secret

const admin = createClient(SUPABASE_URL, SERVICE_KEY, { auth: { persistSession: false } });

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};
const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { ...cors, 'Content-Type': 'application/json' } });

type Verified = { ok: boolean; amount?: number; impUid?: string; reason?: string };

// V2: look up the payment by paymentId (= merchant_uid created by our server)
async function verifyV2(paymentId: string): Promise<Verified> {
  if (!PORTONE_API_SECRET) return { ok: false, reason: 'NO_V2_SECRET' };
  const r = await fetch(`https://api.portone.io/payments/${encodeURIComponent(paymentId)}`, {
    headers: { Authorization: `PortOne ${PORTONE_API_SECRET}` },
  });
  if (!r.ok) return { ok: false, reason: `V2_HTTP_${r.status}` };
  const p = await r.json();
  if (p.status !== 'PAID') return { ok: false, reason: `V2_STATUS_${p.status}` };
  if (p.currency && p.currency !== 'KRW') return { ok: false, reason: 'CURRENCY' };
  return { ok: true, amount: p.amount?.total, impUid: p.pgTxId ?? p.transactionId ?? paymentId };
}

// V1: look up the payment at PortOne (iamport.js SDK).
// First by imp_uid (if given), then by our own order number (merchant_uid) as a fallback.
async function v1Get(token: string, path: string) {
  try {
    const r = await fetch(`https://api.iamport.kr${path}`, { headers: { Authorization: token } });
    return await r.json();
  } catch (_e) {
    return null;
  }
}

async function verifyV1(impUid: string | undefined, merchantUid: string): Promise<Verified> {
  if (!IAMPORT_API_KEY || !IAMPORT_API_SECRET) return { ok: false, reason: 'NO_V1_KEYS' };
  const t = await fetch('https://api.iamport.kr/users/getToken', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ imp_key: IAMPORT_API_KEY, imp_secret: IAMPORT_API_SECRET }),
  });
  const tj = await t.json().catch(() => null);
  const token = tj?.response?.access_token;
  if (!token) return { ok: false, reason: `V1_TOKEN_${String(tj?.message ?? '').slice(0, 60)}` };

  let pj: any = null;
  let p: any = null;
  if (impUid) {
    pj = await v1Get(token, `/payments/${encodeURIComponent(impUid)}`);
    p = pj?.response ?? null;
  }
  if (!p) {
    const pj2 = await v1Get(token, `/payments/find/${encodeURIComponent(merchantUid)}`);
    p = pj2?.response ?? null;
    if (!p) pj = pj2 ?? pj;
  }
  if (!p) return { ok: false, reason: `V1_NOT_FOUND_code${pj?.code}_${String(pj?.message ?? '').slice(0, 60)}` };
  if (p.status !== 'paid') return { ok: false, reason: `V1_STATUS_${p.status}` };
  if (p.merchant_uid !== merchantUid) return { ok: false, reason: 'V1_MERCHANT_MISMATCH' };
  return { ok: true, amount: p.amount, impUid: p.imp_uid };
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors });
  if (req.method !== 'POST') return json({ error: 'METHOD_NOT_ALLOWED' }, 405);

  const body = await req.json().catch(() => ({}));

  // Ignore webhooks that are not "payment completed" (V1: status / V2: type)
  if (body?.status && body.status !== 'paid') return json({ ignored: true });
  if (body?.type && body.type !== 'Transaction.Paid') return json({ ignored: true });

  const merchantUid: string | undefined = body?.merchant_uid ?? body?.data?.paymentId;
  const impUidFromClient: string | undefined = body?.imp_uid ?? body?.data?.transactionId;
  if (!merchantUid || typeof merchantUid !== 'string') return json({ error: 'NO_MERCHANT_UID' }, 400);

  // Make sure this is an order created by our own server
  const { data: order } = await admin.from('sos_charge_orders')
    .select('merchant_uid, user_id, amount, status').eq('merchant_uid', merchantUid).maybeSingle();
  if (!order) return json({ error: 'ORDER_NOT_FOUND' }, 404);

  if (order.status === 'paid') {
    // 2026-11-13: wallet is unified into user_profiles.points (1P = 1 KRW); prepaid_balance is no longer used
    const { data: prof } = await admin.from('user_profiles').select('points').eq('id', order.user_id).maybeSingle();
    return json({ credited: false, already: true, balance: prof?.points ?? 0 });
  }

  // Confirm directly at PortOne (V2 first, then V1)
  let v = await verifyV2(merchantUid);
  if (!v.ok) {
    const v1 = await verifyV1(impUidFromClient, merchantUid);
    if (v1.ok) v = v1; else v = { ok: false, reason: `${v.reason} / ${v1.reason}` };
  }
  if (!v.ok) return json({ error: 'NOT_PAID', reason: v.reason }, 402);
  if (v.amount !== order.amount) return json({ error: 'AMOUNT_MISMATCH' }, 409);

  const { data, error } = await admin.rpc('credit_charge_order', {
    p_merchant_uid: merchantUid,
    p_imp_uid: v.impUid ?? impUidFromClient ?? merchantUid,
    p_paid_amount: v.amount,
  });
  if (error) return json({ error: 'CREDIT_FAILED', detail: error.message }, 500);
  return json(data);
});