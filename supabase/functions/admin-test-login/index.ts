// Supabase Edge Function: admin-test-login
// 관리자 전용 '테스트 계정 로그인' 도구 (2026-11-13)
//  - 관리자가 테스트 주소(one126984+역할@gmail.com)를 넣으면, 메일을 보내지 않고
//    1회용 로그인 토큰을 바로 돌려줍니다. 계정이 없으면 새로 만듭니다.
//  - 관리자 화면은 이 토큰으로 'test-login.html?th=...' 링크를 만들어 보여 주고,
//    그 링크를 시크릿 창에 붙여넣으면 그 테스트 계정으로 로그인됩니다.
//  - 안전장치
//    1) 호출한 사람이 관리자(app_metadata.role = 'admin')가 아니면 거부
//    2) TEST_EMAIL_BASE(기본 one126984@gmail.com)에 '+태그'를 붙인 주소만 허용
//       → 실제 회원 계정으로는 절대 로그인 링크를 만들 수 없음
//
// 요청 형식
//   { "action": "list" }                       → 테스트 계정 목록
//   { "action": "link", "tag": "hq" }          → one126984+hq@gmail.com 로그인 토큰
//   { "action": "link", "email": "one126984+hq@gmail.com" }  (주소로 줘도 됨)
import { createClient } from 'npm:@supabase/supabase-js@2';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SERVICE_KEY  = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const BASE = (Deno.env.get('TEST_EMAIL_BASE') ?? 'one126984@gmail.com').trim().toLowerCase();
const [BASE_LOCAL, BASE_DOMAIN] = BASE.split('@');

const admin = createClient(SUPABASE_URL, SERVICE_KEY, { auth: { persistSession: false } });

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};
const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { ...cors, 'Content-Type': 'application/json' } });

const TAG_RE = /^[a-z0-9][a-z0-9._-]{0,29}$/;

// 'one126984+hq@gmail.com' → 'hq' (테스트 주소가 아니면 null)
function tagOf(email: string): string | null {
  const m = String(email || '').trim().toLowerCase().match(/^([^@+]+)\+([^@]+)@(.+)$/);
  if (!m || m[1] !== BASE_LOCAL || m[3] !== BASE_DOMAIN) return null;
  return TAG_RE.test(m[2]) ? m[2] : null;
}
const emailOf = (tag: string) => `${BASE_LOCAL}+${tag}@${BASE_DOMAIN}`;

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors });
  if (req.method !== 'POST') return json({ error: 'METHOD_NOT_ALLOWED' }, 405);

  // 1) 관리자만
  const token = (req.headers.get('Authorization') ?? '').replace(/^Bearer\s+/i, '');
  const { data: u } = await admin.auth.getUser(token);
  const caller = u?.user;
  if (!caller) return json({ error: 'LOGIN_REQUIRED' }, 401);
  if (caller.app_metadata?.role !== 'admin') return json({ error: 'ADMIN_ONLY' }, 403);

  const body = await req.json().catch(() => ({}));

  // 2) 테스트 계정 목록
  if (body?.action === 'list') {
    const out: unknown[] = [];
    for (let page = 1; page <= 10; page++) {
      const { data, error } = await admin.auth.admin.listUsers({ page, perPage: 200 });
      if (error) return json({ error: 'LIST_FAILED', detail: error.message }, 500);
      for (const x of data.users) {
        const tag = tagOf(x.email ?? '');
        if (tag) out.push({ tag, email: x.email, created_at: x.created_at, last_sign_in_at: x.last_sign_in_at ?? null });
      }
      if (data.users.length < 200) break;
    }
    return json({ base: BASE, users: out });
  }

  // 3) 로그인 토큰 만들기
  if (body?.action === 'link') {
    const tag = body?.tag ? String(body.tag).trim().toLowerCase() : tagOf(String(body?.email ?? ''));
    if (!tag || !TAG_RE.test(tag)) return json({ error: 'NOT_TEST_EMAIL', base: BASE }, 400);
    const email = emailOf(tag);

    // 계정이 없으면 만들기 (이미 있으면 그대로 사용)
    let created = false;
    const { error: cErr } = await admin.auth.admin.createUser({
      email, email_confirm: true, user_metadata: { name: `테스트-${tag}`, full_name: `테스트-${tag}`, is_test: true },
    });
    if (!cErr) created = true;
    else if (!/already|registered|exists/i.test(cErr.message)) return json({ error: 'CREATE_FAILED', detail: cErr.message }, 500);

    const { data, error } = await admin.auth.admin.generateLink({ type: 'magiclink', email });
    if (error || !data?.properties?.hashed_token) return json({ error: 'LINK_FAILED', detail: error?.message }, 500);

    console.log('test login link', email, created ? '(new)' : '', 'by', caller.email);
    return json({ email, tag, created, token_hash: data.properties.hashed_token });
  }

  return json({ error: 'UNKNOWN_ACTION' }, 400);
});
