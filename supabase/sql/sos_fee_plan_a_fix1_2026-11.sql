-- =====================================================================
-- 요금 A안 후속 수정 1 (2026-11)
--   1) create_charge_order: 결제 허용 금액에 새 상담료·연장료·충전 금액 추가
--      (기존 30000, 50000, 100000, 200000, 300000 은 그대로 두고 20000, 40000, 60000, 80000 을 추가)
--   2) get_fee_by_time: 옛 시간대 요금 → 새 요금(주간 4만 / 저녁·주말·공휴일 6만 / 심야 8만)
--   3) 점검: 상담료를 다루는 서버 함수들 안에서 요금 관련 줄만 뽑아 보여 줌
--
-- sos_fee_plan_a_2026-11.sql 을 먼저 실행한 뒤에 실행하세요.
-- Supabase SQL Editor에 통째로 붙여 넣고 Run 하세요. (오류가 나면 아무것도 반영되지 않습니다)
-- =====================================================================

begin;

-- ---------------------------------------------------------------------
-- 1. create_charge_order 허용 금액 추가 (함수의 나머지 내용은 그대로, 금액 목록만 바꿈)
-- ---------------------------------------------------------------------
do $$
declare
    v_oid  oid;
    v_def  text;
    v_new  text;
begin
    select p.oid into v_oid
      from pg_proc p join pg_namespace n on n.oid = p.pronamespace
     where n.nspname = 'public' and p.proname = 'create_charge_order'
     limit 1;
    if v_oid is null then raise exception 'create_charge_order 함수가 없습니다'; end if;

    v_def := pg_get_functiondef(v_oid);
    v_new := regexp_replace(v_def,
                            'NOT IN \(30000, 50000, 100000, 200000, 300000\)',
                            'NOT IN (20000, 30000, 40000, 50000, 60000, 80000, 100000, 200000, 300000)',
                            'i');
    if v_new = v_def then
        if v_def ~* '40000, 50000, 60000, 80000' then
            raise notice 'create_charge_order: 이미 수정되어 있습니다';
        else
            raise exception 'create_charge_order: 금액 목록을 찾지 못했습니다. 함수 내용을 보내 주세요';
        end if;
    else
        execute v_new;
        raise notice 'create_charge_order: 허용 금액 수정 완료';
    end if;
end $$;

-- ---------------------------------------------------------------------
-- 2. get_fee_by_time 을 새 요금으로 (이름·인자·출력 모양은 그대로)
--    출동은 현재 중단 상태라 dispatch_fee 는 참고용 값만 유지
-- ---------------------------------------------------------------------
create or replace function public.get_fee_by_time(p_time timestamp with time zone, out base_fee integer, out dispatch_fee integer)
language plpgsql stable security definer set search_path = public as $$
begin
    base_fee := public.sos_fee_for_time(coalesce(p_time, now()));
    dispatch_fee := case public.sos_fee_tier(coalesce(p_time, now()))
                        when 'day'  then 40000
                        when 'late' then 60000
                        else 50000 end;
end $$;

commit;

-- =====================================================================
-- 3. 점검 결과 (결과 표를 그대로 보내 주세요)
--    상담료를 다루는 함수 안에서 금액·요금 관련 줄만 보여 줍니다.
--    'trigger' 줄은 handle_counseling_settlement 가 어느 표에 붙어 있는지 알려 줍니다.
-- =====================================================================
select '함수' as 구분, p.proname as 이름, trim(l.line) as 내용
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  cross join lateral regexp_split_to_table(p.prosrc, E'\n') with ordinality as l(line, ln)
 where n.nspname = 'public'
   and p.proname in ('create_sos_request', 'get_sos_request_fee', 'assign_expert_direct', 'assign_expert',
                     'complete_sos_request', 'my_sos_refund_info', 'sos_request_refund',
                     'handle_counseling_settlement', 'sos_base_fee')
   and (l.line ~* '(fee|30000|40000|get_fee_by_time|sos_base_fee|points|insufficient)')
union all
select 'trigger', t.tgname || ' → ' || c.relname, pg_get_triggerdef(t.oid)
  from pg_trigger t
  join pg_class c on c.oid = t.tgrelid
  join pg_proc p on p.oid = t.tgfoid
 where p.proname = 'handle_counseling_settlement' and not t.tgisinternal
union all
select '참조', p.proname, '이 함수가 get_fee_by_time 을 사용함'
  from pg_proc p join pg_namespace n on n.oid = p.pronamespace
 where n.nspname = 'public' and p.prosrc ilike '%get_fee_by_time%' and p.proname <> 'get_fee_by_time';
