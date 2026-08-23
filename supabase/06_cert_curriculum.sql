-- =====================================================================
-- KCBMA cert_curriculum 테이블 — 자격증 과정 커리큘럼(차시)
-- 정책: 누구나 SELECT 가능, 등록/수정/삭제는 관리자만
-- 관리자 판별: auth.jwt()->'user_metadata'->>'role' = 'admin'
-- 실행:
--   1. https://supabase.com/dashboard/project/ehrahnnowwjkgycvlbzk/sql/new
--   2. 전체 복사 → 붙여넣기 → [Run] (한 번만)
-- =====================================================================

-- 1) 테이블 생성
create table if not exists public.cert_curriculum (
  id              bigserial primary key,
  course_id       bigint      not null references public.cert_courses(id) on delete cascade,

  chapter_no      integer     not null,                -- 차시 번호
  title           text        not null,                -- 강의 제목
  duration_min    integer     not null default 0,      -- 강의 시간 (분)

  content_type    text        not null default 'VOD',  -- VOD / LIVE / DOCUMENT
  video_url       text,                                 -- 동영상 URL (YouTube, Vimeo, Storage 등)
  zoom_link       text,                                 -- 실시간 강의 Zoom 링크
  zoom_datetime   timestamptz,                          -- 실시간 강의 일시

  is_preview      boolean     not null default false,  -- 미리보기 가능 여부
  sort_order      integer     not null default 0,

  created_at      timestamptz not null default now(),

  constraint cert_curriculum_type_ok check (content_type in ('VOD','LIVE','DOCUMENT'))
);

-- 2) 인덱스 (과정별 차시 조회 성능)
create index if not exists cert_curriculum_course_idx on public.cert_curriculum (course_id, chapter_no);

-- 3) RLS 정책
alter table public.cert_curriculum enable row level security;

-- 3-1) 누구나 SELECT
drop policy if exists "cert_curriculum_public_read" on public.cert_curriculum;
create policy "cert_curriculum_public_read"
  on public.cert_curriculum
  for select
  using (true);

-- 3-2) 관리자만 INSERT
drop policy if exists "cert_curriculum_admin_insert" on public.cert_curriculum;
create policy "cert_curriculum_admin_insert"
  on public.cert_curriculum
  for insert
  to authenticated
  with check (auth.jwt() -> 'user_metadata' ->> 'role' = 'admin');

-- 3-3) 관리자만 UPDATE
drop policy if exists "cert_curriculum_admin_update" on public.cert_curriculum;
create policy "cert_curriculum_admin_update"
  on public.cert_curriculum
  for update
  to authenticated
  using (auth.jwt() -> 'user_metadata' ->> 'role' = 'admin')
  with check (auth.jwt() -> 'user_metadata' ->> 'role' = 'admin');

-- 3-4) 관리자만 DELETE
drop policy if exists "cert_curriculum_admin_delete" on public.cert_curriculum;
create policy "cert_curriculum_admin_delete"
  on public.cert_curriculum
  for delete
  to authenticated
  using (auth.jwt() -> 'user_metadata' ->> 'role' = 'admin');

-- 4) 검증 쿼리
-- select * from public.cert_curriculum where course_id = 1 order by chapter_no;
