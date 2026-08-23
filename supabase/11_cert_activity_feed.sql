-- =====================================================================
-- KCBMA cert_activity_feed 테이블 — 실시간 수강완료/발급완료 피드
-- 정책: 누구나 SELECT, INSERT 는 서비스 롤(service_role)만 (클라이언트 anon/authenticated 는 불가)
-- 실행:
--   1. https://supabase.com/dashboard/project/ehrahnnowwjkgycvlbzk/sql/new
--   2. 전체 복사 → 붙여넣기 → [Run] (한 번만)
-- =====================================================================

-- 1) 테이블 생성
create table if not exists public.cert_activity_feed (
  id              bigserial primary key,

  activity_type   text        not null,                -- ENROLL / COMPLETE / CERT_ISSUED
  user_name       text        not null,                -- 마스킹된 이름 (예: 박*진)
  course_title    text        not null,                -- 자격증/과정명

  created_at      timestamptz not null default now(),

  constraint cert_feed_type_ok check (activity_type in ('ENROLL','COMPLETE','CERT_ISSUED'))
);

-- 2) 인덱스 (최신순 조회 성능)
create index if not exists cert_feed_created_idx on public.cert_activity_feed (created_at desc);

-- 3) RLS 정책
alter table public.cert_activity_feed enable row level security;

-- 3-1) 누구나 SELECT (실시간 피드 공개 표시)
drop policy if exists "cert_feed_public_read" on public.cert_activity_feed;
create policy "cert_feed_public_read"
  on public.cert_activity_feed
  for select
  using (true);

-- 3-2) INSERT 정책 없음
--      cert_activity_feed 는 anon/authenticated 를 위한 INSERT 정책을 두지 않는다.
--      RLS 활성화 상태에서 매칭되는 정책이 없으면 기본적으로 거부되므로,
--      일반 클라이언트는 INSERT 할 수 없고, service_role(Edge Function 등)만
--      RLS 를 우회하여 데이터를 적재할 수 있다.

-- 4) 검증 쿼리
-- select * from public.cert_activity_feed order by created_at desc limit 20;
