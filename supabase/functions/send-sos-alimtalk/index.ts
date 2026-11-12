// Supabase Edge Function: send-sos-alimtalk
// New SOS request -> notify standby experts via SOLAPI (SMS now, Kakao AlimTalk later).
// - Called by a Database Webhook on sos_requests INSERT (header x-hook-secret required).
// - Manual test: POST {"test_to":"01012345678"} with the same header -> one test SMS.
// - Only city/district level region is sent. Requester phone and detailed address are never sent.
// - AlimTalk is used automatically once SOLAPI_PFID and SOLAPI_TPL_NEW secrets are set.
// - Called by the requester's room page (logged-in user token, no hook secret):
//     {"action":"invite","request_id":...}   -> sends call SMS to experts recorded by sos_send_call_invites (not yet sent)
//     {"action":"selected","request_id":...} -> tells the selected expert (once per request/expert)
import { createClient } from 'npm:@supabase/supabase-js@2';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SERVICE_KEY  = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const HOOK_SECRET  = Deno.env.get('SOS_HOOK_SECRET') ?? '';
const SOLAPI_KEY    = Deno.env.get('SOLAPI_KEY') ?? '';
const SOLAPI_SECRET = Deno.env.get('SOLAPI_SECRET') ?? '';
const SOLAPI_SENDER = (Deno.env.get('SOLAPI_SENDER') ?? '').replace(/\D/g, '');
const PFID          = Deno.env.get('SOLAPI_PFID') ?? '';
const TPL_NEW       = Deno.env.get('SOLAPI_TPL_NEW') ?? '';
const STANDBY_URL   = Deno.env.get('SOS_STANDBY_URL') ?? '';
const MAX_TARGETS   = Number(Deno.env.get('SOS_MAX_TARGETS') ?? '20');

const admin = createClient(SUPABASE_URL, SERVICE_KEY, { auth: { persistSession: false } });

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { 'Content-Type': 'application/json' } });

// ---------- helpers ----------
function shortRegion(region: unknown): string {
  const parts = String(region ?? '').trim().split(/\s+/).filter(Boolean);
  const out = parts.slice(0, 2);
  if (parts[2] && /(\ub3d9|\uc74d|\uba74|\ub9ac)$/.test(parts[2])) out.push(parts[2]);
  return out.join(' ') || '\uc9c0\uc5ed \ubbf8\uc785\ub825';
}
// 2026-11-13: request categories are short codes (소방/전기/누수/기타(...)).
// Show them in the SMS the same way the request screen does.
const CAT_LABEL: Record<string, string> = {
  '소방': '경보기 오작동', '화재': '경보기 오작동',
  '전기': '전기 정전',
  '누수': '배관 누수', '화장실': '배관 누수',
};
function categoryText(cat: unknown): string {
  const raw = Array.isArray(cat) ? cat.filter(Boolean).join(',') : String(cat ?? '').replace(/[{}"]/g, '');
  const parts = raw.split(',').map((p) => p.trim()).filter(Boolean).map((p) => CAT_LABEL[p] ?? p);
  return parts.join(', ') || '기타';
}
// Dispatch (출동) was removed in 2026-11: phone consultation only
function serviceText(_t: unknown): string {
  return '전화상담';
}
function kstTime(iso: unknown): string {
  const d = iso ? new Date(String(iso)) : new Date();
  const k = new Date(d.getTime() + 9 * 3600 * 1000);
  const p = (n: number) => String(n).padStart(2, '0');
  return `${p(k.getUTCMonth() + 1)}/${p(k.getUTCDate())} ${p(k.getUTCHours())}:${p(k.getUTCMinutes())}`;
}
const digits = (s: unknown) => String(s ?? '').replace(/\D/g, '');

async function authHeader(): Promise<string> {
  const date = new Date().toISOString();
  const salt = crypto.randomUUID().replace(/-/g, '');
  const key = await crypto.subtle.importKey('raw', new TextEncoder().encode(SOLAPI_SECRET),
    { name: 'HMAC', hash: 'SHA-256' }, false, ['sign']);
  const sig = await crypto.subtle.sign('HMAC', key, new TextEncoder().encode(date + salt));
  const hex = Array.from(new Uint8Array(sig)).map((b) => b.toString(16).padStart(2, '0')).join('');
  return `HMAC-SHA256 apiKey=${SOLAPI_KEY}, date=${date}, salt=${salt}, signature=${hex}`;
}

async function solapiSend(messages: unknown[]) {
  const res = await fetch('https://api.solapi.com/messages/v4/send-many/detail', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Authorization: await authHeader() },
    body: JSON.stringify({ messages }),
  });
  const body = await res.json().catch(() => ({}));
  return { status: res.status, body };
}

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};
const cjson = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { ...cors, 'Content-Type': 'application/json' } });

// Requester actions (invite / selected): the caller must be the owner of the request
async function handleUserAction(req: Request, body: any) {
  const token = (req.headers.get('Authorization') ?? '').replace(/^Bearer\s+/i, '');
  const { data: u } = await admin.auth.getUser(token);
  const user = u?.user;
  if (!user) return cjson({ error: 'LOGIN_REQUIRED' }, 401);
  const requestId = body?.request_id;
  if (!requestId) return cjson({ error: 'NO_REQUEST_ID' }, 400);

  const { data: r } = await admin.from('sos_requests').select('*').eq('id', requestId).maybeSingle();
  if (!r || r.user_id !== user.id) return cjson({ error: 'FORBIDDEN' }, 403);
  const svc = serviceText(r.service_type), cat = categoryText(r.category), reg = shortRegion(r.region);

  if (body.action === 'invite') {
    if (r.status !== '\ub300\uae30\uc911') return cjson({ error: 'REQUEST_CLOSED' }, 409);
    const since = new Date(Date.now() - 10 * 60 * 1000).toISOString();
    const { data: notes } = await admin.from('sos_expert_notices').select('id, expert_id')
      .eq('request_id', requestId).eq('kind', 'invite').is('sent_at', null).gte('created_at', since);
    if (!notes || notes.length === 0) return cjson({ sent: 0 });
    const { data: exps } = await admin.from('sos_experts').select('id, phone').in('id', notes.map((n: any) => n.expert_id));
    const phoneOf = new Map((exps ?? []).map((e: any) => [e.id, digits(e.phone)]));
    const link = STANDBY_URL ? `${STANDBY_URL}?req=${requestId}` : '';
    const text = `[SOS \ucf5c] ${reg} / ${svc} / ${cat}\n\uc751\ub2f5\ud558\uc2dc\uba74 \uc694\uccad\uc790 \ud654\uba74\uc5d0 \ud504\ub85c\ud544\uc774 \ud45c\uc2dc\ub429\ub2c8\ub2e4.` + (link ? `\n\uc751\ub2f5\ud558\uae30: ${link}` : '\n\ub300\uae30\uc2e4\uc5d0\uc11c \uc751\ub2f5\ud574 \uc8fc\uc138\uc694.');
    const targets = notes.filter((n: any) => (phoneOf.get(n.expert_id) ?? '').length >= 10);
    if (targets.length === 0) return cjson({ sent: 0, reason: 'NO_PHONE' });
    const result = await solapiSend(targets.map((n: any) => ({ to: phoneOf.get(n.expert_id), from: SOLAPI_SENDER, text })));
    console.log('sos invite', requestId, targets.length, result.status, JSON.stringify(result.body).slice(0, 500));
    if (result.status >= 200 && result.status < 300) {
      await admin.from('sos_expert_notices').update({ sent_at: new Date().toISOString() }).in('id', targets.map((n: any) => n.id));
      return cjson({ sent: targets.length });
    }
    return cjson({ error: 'SEND_FAILED', status: result.status }, 502);
  }

  if (body.action === 'selected') {
    if (r.status !== '\ub9e4\uce6d\ub428') return cjson({ skipped: 'NOT_MATCHED' });
    const { data: m } = await admin.from('sos_matches').select('sos_expert_id').eq('request_id', requestId).maybeSingle();
    if (!m?.sos_expert_id) return cjson({ skipped: 'NO_MATCH' });
    const { data: ins } = await admin.from('sos_expert_notices')
      .upsert({ request_id: requestId, expert_id: m.sos_expert_id, kind: 'selected' }, { onConflict: 'request_id,expert_id,kind', ignoreDuplicates: true })
      .select('id');
    if (!ins || ins.length === 0) return cjson({ skipped: 'ALREADY_SENT' });
    const { data: e } = await admin.from('sos_experts').select('phone, contact_mode').eq('id', m.sos_expert_id).maybeSingle();
    const to = digits(e?.phone);
    if (to.length < 10) return cjson({ skipped: 'NO_PHONE' });
    const text = e?.contact_mode === 'text'
      ? `[SOS \uc120\ud0dd\ub428] \uc694\uccad\uc790\uac00 \uc804\ubb38\uac00\ub2d8\uc744 \uc120\ud0dd\ud588\uc2b5\ub2c8\ub2e4.\n10\ubd84 \uc548\uc5d0 \uc694\uccad\uc790\uc5d0\uac8c \uc804\ud654\ud574 \uc8fc\uc138\uc694.\n\uc694\uccad\uc790: ${r.contact_phone ?? ''}\n${reg} / ${svc} / ${cat}`
      : `[SOS \uc120\ud0dd\ub428] \uc694\uccad\uc790\uac00 \uc804\ubb38\uac00\ub2d8\uc744 \uc120\ud0dd\ud588\uc2b5\ub2c8\ub2e4.\n\uace7 \uc694\uccad\uc790\uac00 \uc804\ud654\ub4dc\ub9bd\ub2c8\ub2e4. \uaf2d \ubc1b\uc544 \uc8fc\uc138\uc694.\n${reg} / ${svc} / ${cat}`;
    const result = await solapiSend([{ to, from: SOLAPI_SENDER, text }]);
    console.log('sos selected', requestId, result.status, JSON.stringify(result.body).slice(0, 500));
    if (result.status >= 200 && result.status < 300) {
      await admin.from('sos_expert_notices').update({ sent_at: new Date().toISOString() }).eq('id', ins[0].id);
      return cjson({ sent: 1 });
    }
    return cjson({ error: 'SEND_FAILED', status: result.status }, 502);
  }
  return cjson({ error: 'UNKNOWN_ACTION' }, 400);
}

// ---------- main ----------
Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors });
  if (req.method !== 'POST') return json({ error: 'METHOD' }, 405);
  const peek = await req.clone().json().catch(() => ({}));
  if (peek?.action === 'invite' || peek?.action === 'selected') {
    if (!SOLAPI_KEY || !SOLAPI_SECRET || !SOLAPI_SENDER) return cjson({ error: 'SOLAPI_NOT_CONFIGURED' }, 500);
    return await handleUserAction(req, peek);
  }
  if (!HOOK_SECRET || req.headers.get('x-hook-secret') !== HOOK_SECRET) return json({ error: 'FORBIDDEN' }, 403);
  if (!SOLAPI_KEY || !SOLAPI_SECRET || !SOLAPI_SENDER) return json({ error: 'SOLAPI_NOT_CONFIGURED' }, 500);

  const body = await req.json().catch(() => ({}));

  // Manual test: one SMS to the given number
  if (body?.test_to) {
    const r = await solapiSend([{ to: digits(body.test_to), from: SOLAPI_SENDER, text: '[SOS] \uc54c\ub9bc \ubc1c\uc1a1 \ud14c\uc2a4\ud2b8\uc785\ub2c8\ub2e4.' }]);
    console.log('test send', r.status, JSON.stringify(r.body));
    return json({ test: true, status: r.status, result: r.body });
  }

  // Database Webhook payload: { type: 'INSERT', table: 'sos_requests', record: {...} }
  const requestId: string | undefined = body?.record?.id ?? body?.request_id;
  if (!requestId) return json({ error: 'NO_REQUEST_ID' }, 400);
  if (body?.type && body.type !== 'INSERT') return json({ skipped: 'NOT_INSERT' });

  const { data: r, error: rErr } = await admin.from('sos_requests').select('*').eq('id', requestId).maybeSingle();
  if (rErr || !r) return json({ error: 'REQUEST_NOT_FOUND', detail: rErr?.message }, 404);
  if (r.status !== '\ub300\uae30\uc911') return json({ skipped: 'STATUS_' + r.status });

  const { data: targets, error: tErr } = await admin.rpc('sos_alert_targets', { p_request_id: requestId });
  if (tErr) return json({ error: 'TARGETS_FAILED', detail: tErr.message }, 500);

  const seen = new Set<string>();
  const list = (targets ?? [])
    .map((t: { name: string; phone: string }) => ({ name: t.name || '\uc804\ubb38\uac00', phone: digits(t.phone) }))
    .filter((t: { phone: string }) => t.phone.length >= 10 && !seen.has(t.phone) && seen.add(t.phone))
    .slice(0, MAX_TARGETS);
  if (list.length === 0) return json({ sent: 0, reason: 'NO_TARGETS' });

  const svc = serviceText(r.service_type);
  const cat = categoryText(r.category);
  const reg = shortRegion(r.region);
  const at  = kstTime(r.created_at);

  const messages = list.map((t: { name: string; phone: string }) => {
    if (PFID && TPL_NEW) {
      // AlimTalk (falls back to SMS automatically if it cannot be delivered)
      return {
        to: t.phone, from: SOLAPI_SENDER,
        kakaoOptions: {
          pfId: PFID, templateId: TPL_NEW, disableSms: false,
          variables: {
            '#{\uc804\ubb38\uac00\uba85}': t.name, '#{\uc11c\ube44\uc2a4\uc885\ub958}': svc, '#{\ud604\uc7a5\uc0c1\ud669}': cat,
            '#{\uc9c0\uc5ed}': reg, '#{\uc811\uc218\uc2dc\uac01}': at,
          },
        },
      };
    }
    // SMS/LMS (type decided automatically by length)
    const text = `[SOS \uae34\uae09\uc811\uc218] ${reg} / ${svc} / ${cat}\n\ub300\uae30\uc2e4\uc5d0\uc11c \uc751\ub2f5\ud574 \uc8fc\uc138\uc694.` + (STANDBY_URL ? `\n${STANDBY_URL}` : '');
    return { to: t.phone, from: SOLAPI_SENDER, text };
  });

  const result = await solapiSend(messages);
  console.log('sos alert', requestId, 'targets', list.length, 'status', result.status, JSON.stringify(result.body).slice(0, 800));
  return json({ sent: list.length, mode: PFID && TPL_NEW ? 'alimtalk' : 'sms', status: result.status });
});