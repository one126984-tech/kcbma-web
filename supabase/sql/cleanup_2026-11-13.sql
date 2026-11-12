-- =====================================================================
-- 정리 작업 SQL (2026-11-13)
--   블록 A: 견적의뢰(bids) 작성자 본인·관리자 수정 권한
--   블록 B: SOS 분야를 4개로 정리 (소방=경보기 오작동 / 전기=정전 / 누수=배관 / 기타)
-- Supabase > SQL Editor 에서 블록별로 실행하세요. (여러 번 실행해도 안전)
-- =====================================================================


-- ---------------------------------------------------------------------
-- [블록 A] 견적의뢰 수정 권한
-- ---------------------------------------------------------------------
-- 작성자 칸이 없으면 만들고, 비워 두면 로그인한 본인 아이디가 자동으로 들어가게 함
alter table public.bids add column if not exists created_by uuid default auth.uid();

alter table public.bids enable row level security;

-- 등록: 로그인한 회원이 '본인 이름으로'만 등록 가능
drop policy if exists "bids_insert_own" on public.bids;
create policy "bids_insert_own" on public.bids
  for insert to authenticated
  with check (created_by::text = auth.uid()::text);

-- 수정: 작성자 본인 또는 관리자만
drop policy if exists "bids_update_own_or_admin" on public.bids;
create policy "bids_update_own_or_admin" on public.bids
  for update to authenticated
  using (created_by::text = auth.uid()::text or public.is_admin())
  with check (created_by::text = auth.uid()::text or public.is_admin());

-- 수정할 때 작성자를 바꿔치기하지 못하게 고정 (관리자는 예외)
-- (조회수는 조회수 증가 함수가 써야 하므로 여기서 막지 않음)
create or replace function public.bids_lock_fields_trg()
returns trigger language plpgsql as $$
begin
  if not public.is_admin() then
    new.created_by := old.created_by;
  end if;
  return new;
end $$;

drop trigger if exists bids_lock_fields on public.bids;
create trigger bids_lock_fields
  before update on public.bids
  for each row execute function public.bids_lock_fields_trg();

-- 확인용: bids 테이블에 걸린 규칙 목록
select policyname, cmd, roles from pg_policies where tablename = 'bids' order by cmd, policyname;


-- ---------------------------------------------------------------------
-- [블록 B] SOS 분야를 4개로 정리
--   새 분야: 소방(경보기 오작동) / 전기(정전) / 누수(배관, 화장실 누수 포함) / 기타
--   예전 값 옮기기: 화재·소방 → 소방, 정전 → 전기, 배관·화장실 → 누수, 가스·승강기 → 기타
--   '기타' 접수는 분야 상관없이 모든 전문가에게 콜이 가도록 매칭 규칙도 바꿈
--   ※ B-1 → B-2 → B-3 → B-4 순서대로 실행하세요.
-- ---------------------------------------------------------------------

-- B-1. 분야 이름 하나를 새 분야로 바꾸는 함수
--      '기타(…)'처럼 직접 입력한 내용은 안에 다른 단어가 있어도 '기타'로 봄
create or replace function public.sos_cat_token(part text)
returns text language sql immutable as $$
  select case
           when btrim(coalesce(part, '')) = ''                       then null
           when btrim(part) like '기타%'                             then '기타'
           when part like '%화재%' or part like '%소방%' or part like '%경보%' then '소방'
           when part like '%전기%' or part like '%정전%'             then '전기'
           when part like '%누수%' or part like '%배관%' or part like '%화장실%' then '누수'
           when part like '%가스%' or part like '%승강기%' or part like '%기타%' then '기타'
         end
$$;

-- 쉼표로 이어진 여러 분야를 한 번에 정리 (순서 유지, 중복 제거, 예: '화재 / 소방,화장실' → '소방,누수')
create or replace function public.sos_norm_cats(t text)
returns text language sql immutable as $$
  select nullif(string_agg(c, ',' order by first_pos), '')
  from (
    select c, min(ord) as first_pos
    from (
      select ord, public.sos_cat_token(part) as c
      from unnest(string_to_array(coalesce(t, ''), ',')) with ordinality as u(part, ord)
    ) x
    where c is not null
    group by c
  ) y
$$;

-- 미리 보기: 지금 값과 바뀔 값 (아무것도 바뀌지 않음)
select id, name, category as 지금_대표분야, categories as 지금_전체분야,
       split_part(public.sos_norm_cats(coalesce(nullif(categories, ''), category)), ',', 1) as 바뀔_대표분야,
       public.sos_norm_cats(coalesce(nullif(categories, ''), category))                   as 바뀔_전체분야
from public.sos_experts
order by name;

-- B-2. 콜 매칭 규칙 다시 만들기
--      접수 분야(1~2개)와 전문가 분야가 하나라도 겹치면 일치.
--      접수에 '기타'가 있거나 분야가 비어 있으면 모든 전문가와 일치.
--      예전 접수(화재·가스·화장실 등)도 새 분야로 바꿔서 비교함.
drop function if exists public.sos_category_match(text, text);
create function public.sos_category_match(req_cats text, expert_cats text)
returns boolean language sql immutable as $$
  select case
    when public.sos_norm_cats(req_cats) is null then true
    when '기타' = any(string_to_array(public.sos_norm_cats(req_cats), ',')) then true
    else coalesce(string_to_array(public.sos_norm_cats(req_cats), ',')
                  && string_to_array(public.sos_norm_cats(expert_cats), ','), false)
  end
$$;

-- B-3. 기존 자료 옮기기
--   · 분야 칸이 비어 있던 전문가(관리자가 직접 등록·지원서 승인)도 대표 분야로 채움 → 콜 매칭에 잡히게 됨
--   · 알 수 없는 이름이면 원래 값을 그대로 둠
update public.sos_experts e
   set categories = v.cats,
       category   = split_part(v.cats, ',', 1)
  from (select id, public.sos_norm_cats(coalesce(nullif(categories, ''), category)) as cats
          from public.sos_experts) v
 where e.id = v.id
   and v.cats is not null
   and (e.categories is distinct from v.cats or e.category is distinct from split_part(v.cats, ',', 1));

update public.sos_applications
   set categories = public.sos_norm_cats(categories)
 where public.sos_norm_cats(categories) is not null
   and categories is distinct from public.sos_norm_cats(categories);

-- B-4. 앞으로 저장될 때도 자동으로 정리 (다시 섞이지 않게)
create or replace function public.sos_experts_norm_cats_trg()
returns trigger language plpgsql as $$
declare v text;
begin
  if tg_op = 'UPDATE'
     and new.category is distinct from old.category
     and new.categories is not distinct from old.categories then
    -- 관리자가 '전문가 관리'에서 대표 분야만 바꾼 경우: 새 대표 분야를 맨 앞으로
    v := public.sos_norm_cats(coalesce(new.category, '') || ',' || coalesce(new.categories, ''));
  else
    v := public.sos_norm_cats(coalesce(nullif(new.categories, ''), new.category));
  end if;

  if v is not null then
    new.categories := split_part(v, ',', 1) || coalesce(nullif(',' || split_part(v, ',', 2), ','), '');  -- 최대 2개
    new.category   := split_part(v, ',', 1);
  end if;
  return new;
end $$;

drop trigger if exists sos_experts_norm_cats on public.sos_experts;
create trigger sos_experts_norm_cats
  before insert or update of category, categories on public.sos_experts
  for each row execute function public.sos_experts_norm_cats_trg();

create or replace function public.sos_applications_norm_cats_trg()
returns trigger language plpgsql as $$
declare v text;
begin
  v := public.sos_norm_cats(new.categories);
  if v is not null then new.categories := v; end if;
  return new;
end $$;

drop trigger if exists sos_applications_norm_cats on public.sos_applications;
create trigger sos_applications_norm_cats
  before insert or update of categories on public.sos_applications
  for each row execute function public.sos_applications_norm_cats_trg();

-- 확인용: 정리 후 분야 값 종류 (소방/전기/누수/기타 조합만 나오면 정상)
select categories, count(*) from public.sos_experts group by categories order by 2 desc;
-- 확인용: 매칭 규칙 (위에서부터 true, true, false, true)
select public.sos_category_match('누수,전기', '전기')       as 겹침,
       public.sos_category_match('기타(엘리베이터 소음)', '소방') as 기타는_전체,
       public.sos_category_match('소방', '누수')            as 안겹침,
       public.sos_category_match('화장실', '배관(누수)')     as 예전값;
