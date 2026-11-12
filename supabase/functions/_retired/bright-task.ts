// Supabase Edge Function: portone-confirm
// 역할: 포트원 결제가 실제로 완료됐는지 서버에서 다시 확인한 뒤, 그때만 예치금을 올립니다.
//  - 충전 화면이 결제 직후 호출하고, 포트원 웹훅(결제 완료 알림)도 같은 주소로 받습니다.
//  - 화면에서 보낸 값은 믿지 않고, 포트원에서 직접 조회한 결과만 믿습니다.
//  - 같은 주문은 한 번만 반영됩니다 (DB 함수가 보장).
import { createClient } from 'npm:@supabase/supabase-js@2';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SERVICE_KEY  = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const PORTONE_API_SECRET = Deno.env.get('PORTONE_API_SECRET') ?? '';      // 포트원 V2 API Secret
const IAMPORT_API_KEY    = Deno.env.get('IAMPORT_API_KEY') ?? '';         // (선택) 포트원 V1 REST API 키
const IAMPORT_API_SECRET = Deno.env.get('IAMPORT_API_SECRET') ?? '';      // (선택) 포트원 V1 REST API Secret

const admin = createClient(SUPABASE_URL, SERVICE_KEY, { auth: { persistSession: false } });

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};
const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { ...cors, 'Content-Type': 'application/json' } });

type Verified = { ok: boolean; amount?: number; impUid?: string; reason?: string };

// V2: paymentId(= 우리가 만든 merchant_uid)로 결제 조회
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

// V1: imp_uid로 결제 조회 (V1 키를 쓰는 경우)
async function verifyV1(impUid: string, merchantUid: string): Promise<Verified> {
  if (!IAMPORT_API_KEY || !IAMPORT_API_SECRET) return { ok: false, reason: 'NO_V1_KEYS' };
  const t = await fetch('https://api.iamport.kr/users/getToken', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ imp_key: IAMPORT_API_KEY, imp_secret: IAMPORT_API_SECRET }),
  });
  const tj = await t.json();
  const token = tj?.response?.access_token;
  if (!token) return { ok: false, reason: 'V1_TOKEN' };
  const r = await fetch(`https://api.iamport.kr/payments/${encodeURIComponent(impUid)}`, { headers: { Authorization: token } });
  const pj = await r.json();
  const p = pj?.response;
  if (!p || p.status !== 'paid') return { ok: false, reason: `V1_STATUS_${p?.status}` };
  if (p.merchant_uid !== merchantUid) return { ok: false, reason: 'V1_MERCHANT_MISMATCH' };
  return { ok: true, amount: p.amount, impUid: p.imp_uid };
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors });
  if (req.method !== 'POST') return json({ error: 'METHOD_NOT_ALLOWED' }, 405);

  const body = await req.json().catch(() => ({}));

  // 웹훅(V1: status / V2: type)이 '결제 완료'가 아니면 무시
  if (body?.status && body.status !== 'paid') return json({ ignored: true });
  if (body?.type && body.type !== 'Transaction.Paid') return json({ ignored: true });

  const merchantUid: string | undefined = body?.merchant_uid ?? body?.data?.paymentId;
  const impUidFromClient: string | undefined = body?.imp_uid ?? body?.data?.transactionId;
  if (!merchantUid || typeof merchantUid !== 'string') return json({ error: 'NO_MERCHANT_UID' }, 400);

  // 우리 서버가 만든 주문인지 확인
  const { data: order } = await admin.from('sos_charge_orders')
    .select('merchant_uid, user_id, amount, status').eq('merchant_uid', merchantUid).maybeSingle();
  if (!order) return json({ error: 'ORDER_NOT_FOUND' }, 404);

  if (order.status === 'paid') {
    const { data: prof } = await admin.from('user_profiles').select('prepaid_balance').eq('id', order.user_id).maybeSingle();
    return json({ credited: false, already: true, balance: prof?.prepaid_balance ?? 0 });
  }

  // 포트원에서 직접 확인 (V2 먼저, 안 되면 V1)
  let v = await verifyV2(merchantUid);
  if (!v.ok && impUidFromClient) {
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
