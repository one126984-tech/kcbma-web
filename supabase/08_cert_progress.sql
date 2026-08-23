-- =====================================================================
-- KCBMA cert_progress 테이블 — 자격증 과정 수강 진도
-- 정책: 본인 것만 SELECT/INSERT/UPDATE
-- 관리자 판별: auth.jwt()->'user_metadata'->>'role' = 'admin'
-- 실행:
--   1. https://supabase.com/dashboard/project/ehrahnnowwjkgycvlbzk/sql/new
--   2. 전체 복사 → 붙여넣기 → [Run] (한 번만)
-- =====================================================================

-- 1) 테이블 생성
create table if not exists public.cert_progress (
  id              bigserial primary key,
  enrollment_id   bigint      not null references public.cert_enrollments(id) on delete cascade,
  curriculum_id   bigint      not null references public.cert_curriculum(id) on delete cascade,

  is_completed    boolean     not null default false,   -- 해당 차시 수강 완료 여부
  watch_seconds   integer     not null default 0,       -- 시청 시간 (초)
  last_position   integer     not null default 0,       -- 마지막 재생 위치 (초, 이어보기용)
  completed_at    timestamptz,                           -- 완료 일시

  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),

  constraint cert_progress_unique unique (enrollment_id, curriculum_id)
);

-- 2) 인덱스
create index if not exists cert_progress_enrollment_idx on public.cert_progress (enrollment_id);

-- 3) updated_at 자동 갱신 트리거 (기존 public.set_updated_at() 함수 재사용)
drop trigger if exists trg_cert_progress_updated_at on public.cert_progress;
create trigger trg_cert_progress_updated_at
  before update on public.cert_progress
  for each row execute function public.set_updated_at();

-- 4) RLS 정책
-- cert_progress 는 user_id 컬럼이 없으므로, cert_enrollments 를 통해 소유권을 확인한다.
alter table public.cert_progress enable row level security;

-- 4-1) 본인 것만 SELECT (관리자는 전체 조회 가능)
drop policy if exists "cert_progress_owner_read" on public.cert_progress;
create policy "cert_progress_owner_read"
  on public.cert_progress
  for select
  to authenticated
  using (
    exists (
      select 1 from public.cert_enrollments e
      where e.id = cert_progress.enrollment_id
        and e.user_id = auth.uid()
    )
    or auth.jwt() -> 'user_metadata' ->> 'role' = 'admin'
  );

-- 4-2) 본인 소유 enrollment 에만 INSERT
drop policy if exists "cert_progress_owner_insert" on public.cert_progress;
create policy "cert_progress_owner_insert"
  on public.cert_progress
  for insert
  to authenticated
  with check (
    exists (
      select 1 from public.cert_enrollments e
      where e.id = cert_progress.enrollment_id
        and e.user_id = auth.uid()
    )
  );

-- 4-3) 본인 소유 enrollment 에만 UPDATE
drop policy if exists "cert_progress_owner_update" on public.cert_progress;
create policy "cert_progress_owner_update"
  on public.cert_progress
  for update
  to authenticated
  using (
    exists (
      select 1 from public.cert_enrollments e
      where e.id = cert_progress.enrollment_id
        and e.user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.cert_enrollments e
      where e.id = cert_progress.enrollment_id
        and e.user_id = auth.uid()
    )
  );

-- 5) 검증 쿼리
-- select * from public.cert_progress p
--   join public.cert_enrollments e on e.id = p.enrollment_id
--   where e.user_id = auth.uid();
