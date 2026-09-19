// ★ 2026-09: 네이버(및 앞으로 다른 커스텀 로그인)로 들어온 이메일을, 그 이메일로 이미
//   가입된 계정(이메일 매직링크/구글/카카오 등 어떤 경로로 가입했든)이 있으면 그 계정에,
//   없으면 새로 만든 계정에 로그인시키기 위한 서버 함수.
//   관리자 권한(SERVICE_ROLE_KEY)으로 generateLink를 호출하면, 이미 있는 이메일이면
//   에러 없이 그 계정의 링크를, 없으면 새로 만들어서 링크를 내려줌 — 이게 핵심.
//   실제 이메일 발송은 하지 않고, 그 링크의 token_hash만 브라우저로 돌려줘서
//   브라우저가 바로 그 자리에서 verifyOtp로 소비하게 함(사용자는 이메일을 볼 필요 없음).

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { email, name } = await req.json();

    if (!email || typeof email !== "string") {
      return new Response(JSON.stringify({ error: "email이 필요합니다." }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const { data, error } = await supabaseAdmin.auth.admin.generateLink({
      type: "magiclink",
      email,
      options: name ? { data: { full_name: name } } : undefined,
    });

    if (error) {
      return new Response(JSON.stringify({ error: error.message }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    return new Response(
      JSON.stringify({
        email,
        token_hash: data.properties.hashed_token,
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
