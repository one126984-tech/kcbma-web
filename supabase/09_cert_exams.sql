-- =====================================================================
-- KCBMA 시험 관련 테이블 — cert_exams / cert_exam_questions / cert_exam_attempts
-- 정책:
--   - cert_exams / cert_exam_questions : 누구나 SELECT(is_active 만), 관리자만 CUD
--     단, cert_exam_questions 의 correct_option(정답) 은 관리자만 조회 가능하도록
--       공개 뷰(cert_exam_questions_public)를 별도 제공한다.
--   - cert_exam_attempts : 본인 것만 SELECT, 인증된 사용자가 본인 명의로만 INSERT
-- 관리자 판별: auth.jwt()->'user_metadata'->>'role' = 'admin'
-- 실행:
--   1. https://supabase.com/dashboard/project/ehrahnnowwjkgycvlbzk/sql/new
--   2. 전체 복사 → 붙여넣기 → [Run] (한 번만)
-- =====================================================================

-- =====================================================================
-- 1. cert_exams (시험)
-- =====================================================================

-- 1-1) 테이블 생성
create table if not exists public.cert_exams (
  id              bigserial primary key,
  course_id       bigint      not null references public.cert_courses(id) on delete cascade,

  title           text        not null default '자격 평가',
  time_limit_min  integer     not null default 60,      -- 제한 시간 (분)
  pass_score      integer     not null default 60,      -- 합격 점수
  max_attempts    integer     not null default 3,       -- 최대 응시 횟수

  is_active       boolean     not null default true,
  created_at      timestamptz not null default now()
);

-- 1-2) 인덱스
create index if not exists cert_exams_course_idx on public.cert_exams (course_id);

-- 1-3) RLS
alter table public.cert_exams enable row level security;

-- 누구나 SELECT (is_active 만 노출)
drop policy if exists "cert_exams_public_read" on public.cert_exams;
create policy "cert_exams_public_read"
  on public.cert_exams
  for select
  using (is_active = true);

-- 관리자만 INSERT
drop policy if exists "cert_exams_admin_insert" on public.cert_exams;
create policy "cert_exams_admin_insert"
  on public.cert_exams
  for insert
  to authenticated
  with check (auth.jwt() -> 'user_metadata' ->> 'role' = 'admin');

-- 관리자만 UPDATE
drop policy if exists "cert_exams_admin_update" on public.cert_exams;
create policy "cert_exams_admin_update"
  on public.cert_exams
  for update
  to authenticated
  using (auth.jwt() -> 'user_metadata' ->> 'role' = 'admin')
  with check (auth.jwt() -> 'user_metadata' ->> 'role' = 'admin');

-- 관리자만 DELETE
drop policy if exists "cert_exams_admin_delete" on public.cert_exams;
create policy "cert_exams_admin_delete"
  on public.cert_exams
  for delete
  to authenticated
  using (auth.jwt() -> 'user_metadata' ->> 'role' = 'admin');


-- =====================================================================
-- 2. cert_exam_questions (시험 문제)
-- =====================================================================

-- 2-1) 테이블 생성
create table if not exists public.cert_exam_questions (
  id              bigserial primary key,
  exam_id         bigint      not null references public.cert_exams(id) on delete cascade,

  question_no     integer     not null,                -- 문제 번호
  question_text   text        not null,                -- 문제 내용

  option_1        text        not null,                -- 선택지 1
  option_2        text        not null,                -- 선택지 2
  option_3        text        not null,                -- 선택지 3
  option_4        text        not null,                -- 선택지 4
  correct_option  integer     not null,                -- 정답 번호 (1~4)

  points          integer     not null default 1,      -- 배점
  explanation     text,                                 -- 해설

  sort_order      integer     not null default 0,
  created_at      timestamptz not null default now(),

  constraint cert_questions_correct_ok check (correct_option between 1 and 4)
);

-- 2-2) 인덱스
create index if not exists cert_questions_exam_idx on public.cert_exam_questions (exam_id, question_no);

-- 2-3) RLS
-- 주의: 이 테이블은 원본(correct_option 포함)이므로 일반 사용자에게 SELECT 를 허용하지 않는다.
--       클라이언트(시험 응시 화면)는 아래 2-4) 의 cert_exam_questions_public 뷰를 사용해야 한다.
alter table public.cert_exam_questions enable row level security;

-- 관리자만 SELECT (정답 포함 원본 데이터 보호)
drop policy if exists "cert_exam_questions_admin_read" on public.cert_exam_questions;
create policy "cert_exam_questions_admin_read"
  on public.cert_exam_questions
  for select
  to authenticated
  using (auth.jwt() -> 'user_metadata' ->> 'role' = 'admin');

-- 관리자만 INSERT
drop policy if exists "cert_exam_questions_admin_insert" on public.cert_exam_questions;
create policy "cert_exam_questions_admin_insert"
  on public.cert_exam_questions
  for insert
  to authenticated
  with check (auth.jwt() -> 'user_metadata' ->> 'role' = 'admin');

-- 관리자만 UPDATE
drop policy if exists "cert_exam_questions_admin_update" on public.cert_exam_questions;
create policy "cert_exam_questions_admin_update"
  on public.cert_exam_questions
  for update
  to authenticated
  using (auth.jwt() -> 'user_metadata' ->> 'role' = 'admin')
  with check (auth.jwt() -> 'user_metadata' ->> 'role' = 'admin');

-- 관리자만 DELETE
drop policy if exists "cert_exam_questions_admin_delete" on public.cert_exam_questions;
create policy "cert_exam_questions_admin_delete"
  on public.cert_exam_questions
  for delete
  to authenticated
  using (auth.jwt() -> 'user_metadata' ->> 'role' = 'admin');

-- 2-4) 공개 뷰 (정답(correct_option)/해설(explanation) 제외 — 시험 응시 화면에서 사용)
--      뷰는 호출자의 RLS 를 우회하지 않도록 security_invoker 로 생성한다.
--      is_active 인 시험의 문제만 노출한다.
drop view if exists public.cert_exam_questions_public;
create view public.cert_exam_questions_public
  with (security_invoker = true)
  as
  select
    q.id,
    q.exam_id,
    q.question_no,
    q.question_text,
    q.option_1,
    q.option_2,
    q.option_3,
    q.option_4,
    q.points,
    q.sort_order
  from public.cert_exam_questions q
  join public.cert_exams ex on ex.id = q.exam_id
  where ex.is_active = true;

grant select on public.cert_exam_questions_public to anon, authenticated;


-- =====================================================================
-- 3. cert_exam_attempts (시험 응시 기록)
-- =====================================================================

-- 3-1) 테이블 생성
create table if not exists public.cert_exam_attempts (
  id              bigserial primary key,
  user_id         uuid        not null references auth.users(id) on delete cascade,
  exam_id         bigint      not null references public.cert_exams(id) on delete cascade,
  enrollment_id   bigint      not null references public.cert_enrollments(id) on delete cascade,

  attempt_no      integer     not null default 1,      -- 응시 회차
  score           numeric(5,2),                          -- 획득 점수
  total_points    integer,                                -- 총점
  is_passed       boolean     not null default false,  -- 합격 여부

  answers         jsonb,                                  -- 답안 데이터 [{q_id, selected, is_correct}]

  started_at      timestamptz not null default now(),
  submitted_at    timestamptz,                            -- 제출 일시

  created_at      timestamptz not null default now()
);

-- 3-2) 인덱스
create index if not exists cert_attempts_user_idx       on public.cert_exam_attempts (user_id);
create index if not exists cert_attempts_exam_idx        on public.cert_exam_attempts (exam_id);
create index if not exists cert_attempts_enrollment_idx  on public.cert_exam_attempts (enrollment_id);

-- 3-3) RLS
alter table public.cert_exam_attempts enable row level security;

-- 본인 것만 SELECT (관리자는 전체 조회 가능)
drop policy if exists "cert_attempts_owner_read" on public.cert_exam_attempts;
create policy "cert_attempts_owner_read"
  on public.cert_exam_attempts
  for select
  to authenticated
  using (
    user_id = auth.uid()
    or auth.jwt() -> 'user_metadata' ->> 'role' = 'admin'
  );

-- 인증된 사용자만 INSERT (본인 명의로만)
drop policy if exists "cert_attempts_auth_insert" on public.cert_exam_attempts;
create policy "cert_attempts_auth_insert"
  on public.cert_exam_attempts
  for insert
  to authenticated
  with check (user_id = auth.uid());

-- 5) 검증 쿼리
-- select * from public.cert_exam_questions_public where exam_id = 1 order by question_no;
-- select * from public.cert_exam_attempts where user_id = auth.uid();
