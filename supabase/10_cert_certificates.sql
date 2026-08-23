-- =====================================================================
-- KCBMA cert_certificates 테이블 — 자격증 발급
-- 정책: 누구나 SELECT(진위 확인용), 등록/수정은 관리자만, 삭제는 불가
-- 관리자 판별: auth.jwt()->'user_metadata'->>'role' = 'admin'
--
-- 발급 플로우 (자격증 발급비 25만원, 계좌이체):
--   PENDING_PAYMENT(입금대기) → PAYMENT_CONFIRMED(입금확인) → ISSUED(발급완료) / REVOKED(취소)
--
-- 실행:
--   1. https://supabase.com/dashboard/project/ehrahnnowwjkgycvlbzk/sql/new
--   2. 전체 복사 → 붙여넣기 → [Run] (한 번만)
-- =====================================================================

-- 1) 테이블 생성
create table if not exists public.cert_certificates (
  id              bigserial primary key,
  user_id         uuid        not null references auth.users(id) on delete cascade,
  course_id       bigint      not null references public.cert_courses(id) on delete cascade,
  enrollment_id   bigint      not null references public.cert_enrollments(id) on delete cascade,

  cert_number     text        unique,                   -- 자격증 번호 (KCBMA-2026-ELC-00001) — 발급 완료 전까지는 null
  cert_name       text        not null,                 -- 자격증명
  holder_name     text        not null,                 -- 취득자 이름

  status          text        not null default 'PENDING_PAYMENT',
                                                          -- PENDING_PAYMENT(입금대기) / PAYMENT_CONFIRMED(입금확인) / ISSUED(발급완료) / REVOKED(취소)
  issued_at       timestamptz,                            -- 발급(ISSUED) 처리 일시
  expires_at      timestamptz,                            -- 유효기간 (null = 영구)

  pdf_url         text,                                    -- 발급된 자격증 PDF URL

  -- 자격증 발급비 계좌이체 관련
  payment_status  text        not null default 'PENDING', -- PENDING(대기) / CONFIRMED(확인) / REFUNDED(환불)
  payment_amount  integer     not null default 250000,    -- 발급비 (원)
  depositor_name  text,                                    -- 입금자명

  created_at      timestamptz not null default now(),

  constraint cert_certificates_status_ok check (status in ('PENDING_PAYMENT','PAYMENT_CONFIRMED','ISSUED','REVOKED')),
  constraint cert_certificates_payment_status_ok check (payment_status in ('PENDING','CONFIRMED','REFUNDED'))
);

-- 1-1) 기존 테이블에 이미 존재하는 경우를 위한 컬럼/제약 추가 (idempotent)
alter table public.cert_certificates alter column cert_number drop not null;
alter table public.cert_certificates alter column issued_at drop not null;
alter table public.cert_certificates alter column status set default 'PENDING_PAYMENT';

alter table public.cert_certificates add column if not exists payment_status text not null default 'PENDING';
alter table public.cert_certificates add column if not exists payment_amount integer not null default 250000;
alter table public.cert_certificates add column if not exists depositor_name text;

alter table public.cert_certificates drop constraint if exists cert_certificates_status_ok;
alter table public.cert_certificates add constraint cert_certificates_status_ok
  check (status in ('PENDING_PAYMENT','PAYMENT_CONFIRMED','ISSUED','REVOKED'));

alter table public.cert_certificates drop constraint if exists cert_certificates_payment_status_ok;
alter table public.cert_certificates add constraint cert_certificates_payment_status_ok
  check (payment_status in ('PENDING','CONFIRMED','REFUNDED'));

-- 2) 인덱스
create index if not exists cert_certificates_user_idx    on public.cert_certificates (user_id);
create index if not exists cert_certificates_number_idx  on public.cert_certificates (cert_number);
create index if not exists cert_certificates_course_idx   on public.cert_certificates (course_id);
create index if not exists cert_certificates_status_idx   on public.cert_certificates (status);

-- 3) RLS 정책
alter table public.cert_certificates enable row level security;

-- 3-1) 누구나 SELECT (진위 확인용 공개 조회 — cert-verify.html 등)
drop policy if exists "cert_certificates_public_read" on public.cert_certificates;
create policy "cert_certificates_public_read"
  on public.cert_certificates
  for select
  using (true);

-- 3-2) 관리자만 INSERT (자격증 발급)
drop policy if exists "cert_certificates_admin_insert" on public.cert_certificates;
create policy "cert_certificates_admin_insert"
  on public.cert_certificates
  for insert
  to authenticated
  with check (auth.jwt() -> 'user_metadata' ->> 'role' = 'admin');

-- 3-3) 관리자만 UPDATE (발급 취소/PDF 갱신 등)
drop policy if exists "cert_certificates_admin_update" on public.cert_certificates;
create policy "cert_certificates_admin_update"
  on public.cert_certificates
  for update
  to authenticated
  using (auth.jwt() -> 'user_metadata' ->> 'role' = 'admin')
  with check (auth.jwt() -> 'user_metadata' ->> 'role' = 'admin');

-- 3-4) DELETE 정책 없음 — 발급 이력 보존을 위해 삭제 불가 (취소는 status='REVOKED' 로 처리)

-- 4) 검증 쿼리
-- select * from public.cert_certificates where cert_number = 'KCBMA-2026-ELC-00001';
-- select * from public.cert_certificates where status = 'PENDING_PAYMENT' order by created_at desc;
