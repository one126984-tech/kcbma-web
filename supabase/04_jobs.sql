-- =====================================================================
-- KCBMA jobs 테이블 — 구인구직 공고
-- 정책: 로그인 사용자만 등록 (스팸 방지), 즉시 공개, 본인 글만 수정/삭제
-- 실행:
--   1. https://supabase.com/dashboard/project/ehrahnnowwjkgycvlbzk/sql/new
--   2. 전체 복사 → 붙여넣기 → [Run] (한 번만)
-- =====================================================================

-- 1) 테이블 생성
create table if not exists public.jobs (
  id           bigserial primary key,
  user_id      uuid        not null references auth.users(id) on delete cascade,

  -- 폼 필드 (jobs/register.html 과 1:1 매핑)
  category     text        not null,   -- 건물 구분 (아파트/오피스텔/빌딩 등)
  type         text        not null,   -- 모집 직종 (관리소장/시설관리/경비 등)
  title        text        not null,   -- 공고 제목
  employment   text        not null,   -- 고용 형태 (정규직/계약직 등)
  experience   text        not null,   -- 경력 여부 (신입/경력/무관)
  region       text        not null,   -- 근무 지역 (서울/경기 등)
  salary       text        not null,   -- 급여 조건 (자유 텍스트)
  address      text        not null,   -- 상세 근무지 주소
  start_date   date        not null,   -- 모집 시작일
  end_date     date        not null,   -- 모집 마감일
  description  text        not null,   -- 상세 내용 (지원 방법·연락처 포함)

  -- 운영 컬럼
  status       text        not null default 'active',  -- active / closed (나중에 pending/rejected 확장 가능)
  view_count   integer     not null default 0,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),

  -- 무결성
  constraint jobs_dates_ok check (end_date >= start_date),
  constraint jobs_status_ok check (status in ('active','closed','pending','rejected'))
);

-- 2) 인덱스 (목록·필터 성능)
create index if not exists jobs_created_at_idx on public.jobs (created_at desc);
create index if not exists jobs_status_idx     on public.jobs (status);
create index if not exists jobs_region_idx     on public.jobs (region);
create index if not exists jobs_type_idx       on public.jobs (type);
create index if not exists jobs_user_idx       on public.jobs (user_id);

-- 3) updated_at 자동 갱신 트리거 (이전 videos 세션에서 만든 함수 재사용)
drop trigger if exists trg_jobs_updated_at on public.jobs;
create trigger trg_jobs_updated_at
  before update on public.jobs
  for each row execute function public.set_updated_at();

-- 4) RLS 정책
alter table public.jobs enable row level security;

-- 4-1) 누구나 SELECT (active 만 노출)
drop policy if exists "jobs_public_read" on public.jobs;
create policy "jobs_public_read"
  on public.jobs
  for select
  using (status in ('active','closed'));   -- closed 도 보이게(마감 표시). 스팸 방지 위해 pending/rejected 는 숨김

-- 4-2) 로그인 사용자만 INSERT (본인 계정으로만)
drop policy if exists "jobs_auth_insert" on public.jobs;
create policy "jobs_auth_insert"
  on public.jobs
  for insert
  to authenticated
  with check (user_id = auth.uid());

-- 4-3) 본인 글만 UPDATE
drop policy if exists "jobs_owner_update" on public.jobs;
create policy "jobs_owner_update"
  on public.jobs
  for update
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- 4-4) 본인 글만 DELETE
drop policy if exists "jobs_owner_delete" on public.jobs;
create policy "jobs_owner_delete"
  on public.jobs
  for delete
  to authenticated
  using (user_id = auth.uid());

-- 5) 검증 쿼리
-- select * from public.jobs order by created_at desc limit 5;
