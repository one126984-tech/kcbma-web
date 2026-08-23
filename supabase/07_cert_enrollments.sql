-- =====================================================================
-- KCBMA cert_enrollments 테이블 — 자격증 과정 수강 신청
-- 정책: 본인 것만 SELECT, 인증된 사용자가 본인 명의로만 INSERT,
--       관리자 + 본인 UPDATE, 관리자만 DELETE
-- 관리자 판별: auth.jwt()->'user_metadata'->>'role' = 'admin'
-- 실행:
--   1. https://supabase.com/dashboard/project/ehrahnnowwjkgycvlbzk/sql/new
--   2. 전체 복사 → 붙여넣기 → [Run] (한 번만)
-- =====================================================================

-- 1) 테이블 생성
create table if not exists public.cert_enrollments (
  id              bigserial primary key,
  user_id         uuid        not null references auth.users(id) on delete cascade,
  course_id       bigint      not null references public.cert_courses(id) on delete cascade,

  status          text        not null default 'ACTIVE', -- ACTIVE(수강중) / COMPLETED(수료) / EXPIRED(만료) / CANCELLED(취소)
  enrolled_at     timestamptz not null default now(),
  completed_at    timestamptz,                            -- 수료 일시
  expires_at      timestamptz,                            -- 수강 만료일

  progress_rate   numeric(5,2) not null default 0,        -- 전체 진도율 (%)

  payment_amount  integer     not null default 0,         -- 결제 금액
  payment_method  text,                                    -- 결제 수단
  payment_id      text,                                    -- 외부 결제 ID

  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),

  constraint cert_enrollments_status_ok check (status in ('ACTIVE','COMPLETED','EXPIRED','CANCELLED')),
  constraint cert_enrollments_unique unique (user_id, course_id)
);

-- 2) 인덱스
create index if not exists cert_enrollments_user_idx   on public.cert_enrollments (user_id);
create index if not exists cert_enrollments_course_idx  on public.cert_enrollments (course_id);
create index if not exists cert_enrollments_status_idx  on public.cert_enrollments (status);

-- 3) updated_at 자동 갱신 트리거 (기존 public.set_updated_at() 함수 재사용)
drop trigger if exists trg_cert_enrollments_updated_at on public.cert_enrollments;
create trigger trg_cert_enrollments_updated_at
  before update on public.cert_enrollments
  for each row execute function public.set_updated_at();

-- 4) RLS 정책
alter table public.cert_enrollments enable row level security;

-- 4-1) 본인 것만 SELECT (관리자는 전체 조회 가능)
drop policy if exists "cert_enrollments_owner_read" on public.cert_enrollments;
create policy "cert_enrollments_owner_read"
  on public.cert_enrollments
  for select
  to authenticated
  using (
    user_id = auth.uid()
    or auth.jwt() -> 'user_metadata' ->> 'role' = 'admin'
  );

-- 4-2) 인증된 사용자만 INSERT (본인 명의로만)
drop policy if exists "cert_enrollments_auth_insert" on public.cert_enrollments;
create policy "cert_enrollments_auth_insert"
  on public.cert_enrollments
  for insert
  to authenticated
  with check (user_id = auth.uid());

-- 4-3) 관리자 + 본인 UPDATE
drop policy if exists "cert_enrollments_owner_admin_update" on public.cert_enrollments;
create policy "cert_enrollments_owner_admin_update"
  on public.cert_enrollments
  for update
  to authenticated
  using (
    user_id = auth.uid()
    or auth.jwt() -> 'user_metadata' ->> 'role' = 'admin'
  )
  with check (
    user_id = auth.uid()
    or auth.jwt() -> 'user_metadata' ->> 'role' = 'admin'
  );

-- 4-4) 관리자만 DELETE
drop policy if exists "cert_enrollments_admin_delete" on public.cert_enrollments;
create policy "cert_enrollments_admin_delete"
  on public.cert_enrollments
  for delete
  to authenticated
  using (auth.jwt() -> 'user_metadata' ->> 'role' = 'admin');

-- 5) 검증 쿼리
-- select * from public.cert_enrollments where user_id = auth.uid();
