-- =====================================================================
-- KCBMA cert_courses 테이블 — 자격증 과정
-- 정책: 누구나 목록 조회 가능(OPEN/CLOSED만 노출), 등록/수정/삭제는 관리자만
-- 관리자 판별: auth.jwt()->'user_metadata'->>'role' = 'admin'
-- 실행:
--   1. https://supabase.com/dashboard/project/ehrahnnowwjkgycvlbzk/sql/new
--   2. 전체 복사 → 붙여넣기 → [Run] (한 번만)
-- =====================================================================

-- 1) 테이블 생성
create table if not exists public.cert_courses (
  id              bigserial primary key,
  title           text        not null,               -- 자격증명 (예: 기전당직실무관리사)
  slug            text        not null unique,         -- URL용 슬러그 (예: electrical-duty)
  category        text        not null,                -- 분야 (기전/전기방재/기계/영선/배관/행정/환경위생)
  description     text,                                 -- 과정 소개 (HTML 허용)
  thumbnail_url   text,                                 -- 썸네일 이미지 URL

  edu_method      text        not null default 'VOD',  -- 수강 방식 (VOD/LIVE/MIX)
  edu_period      text,                                 -- 수강 기간 (예: '신청일로부터 30일')

  original_price  integer     not null default 0,      -- 정가 (원)
  discount_price  integer     not null default 0,      -- 할인가 (0이면 무료)
  is_free         boolean     not null default true,   -- 무료 여부 (장학 지원)
  cert_price      integer     not null default 250000, -- 자격증 발급 비용 (원)

  pass_criteria   jsonb       default '{"progress_rate": 80, "exam_score": 60}'::jsonb,
                                                        -- 수료 기준 (진도율 %, 시험 점수)

  instructor_name text,                                 -- 담당 강사명
  instructor_bio  text,                                 -- 강사 약력
  instructor_img  text,                                 -- 강사 사진 URL

  status          text        not null default 'OPEN',  -- 접수 상태 (OPEN/CLOSED/UPCOMING)
  sort_order      integer     not null default 0,       -- 정렬 순서
  view_count      integer     not null default 0,       -- 조회수
  enroll_count    integer     not null default 0,       -- 수강 신청 수

  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),

  constraint cert_courses_status_ok check (status in ('OPEN','CLOSED','UPCOMING')),
  constraint cert_courses_method_ok check (edu_method in ('VOD','LIVE','MIX'))
);

-- 1-1) 기존 테이블에 cert_price 컬럼이 없을 경우를 대비한 보강 (이미 생성된 환경 대응)
alter table public.cert_courses
  add column if not exists cert_price integer not null default 250000;

-- 2) 인덱스 (목록·필터 성능)
create index if not exists cert_courses_category_idx on public.cert_courses (category);
create index if not exists cert_courses_status_idx   on public.cert_courses (status);
create index if not exists cert_courses_sort_idx      on public.cert_courses (sort_order, created_at desc);

-- 3) updated_at 자동 갱신 트리거 (기존 public.set_updated_at() 함수 재사용)
drop trigger if exists trg_cert_courses_updated_at on public.cert_courses;
create trigger trg_cert_courses_updated_at
  before update on public.cert_courses
  for each row execute function public.set_updated_at();

-- 4) RLS 정책
alter table public.cert_courses enable row level security;

-- 4-1) 누구나 SELECT (OPEN/CLOSED 만 노출, UPCOMING 은 숨김)
drop policy if exists "cert_courses_public_read" on public.cert_courses;
create policy "cert_courses_public_read"
  on public.cert_courses
  for select
  using (status in ('OPEN','CLOSED'));

-- 4-2) 관리자만 INSERT
drop policy if exists "cert_courses_admin_insert" on public.cert_courses;
create policy "cert_courses_admin_insert"
  on public.cert_courses
  for insert
  to authenticated
  with check (auth.jwt() -> 'user_metadata' ->> 'role' = 'admin');

-- 4-3) 관리자만 UPDATE
drop policy if exists "cert_courses_admin_update" on public.cert_courses;
create policy "cert_courses_admin_update"
  on public.cert_courses
  for update
  to authenticated
  using (auth.jwt() -> 'user_metadata' ->> 'role' = 'admin')
  with check (auth.jwt() -> 'user_metadata' ->> 'role' = 'admin');

-- 4-4) 관리자만 DELETE
drop policy if exists "cert_courses_admin_delete" on public.cert_courses;
create policy "cert_courses_admin_delete"
  on public.cert_courses
  for delete
  to authenticated
  using (auth.jwt() -> 'user_metadata' ->> 'role' = 'admin');

-- 5) 검증 쿼리
-- select * from public.cert_courses order by sort_order, created_at desc limit 10;
