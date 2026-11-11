-- =====================================================================
-- 긴급 SOS 전문가 정산: 정률 수수료 20% (2026-11)
--   · 상담료 + 연장 요금의 20% = 플랫폼 수수료, 80% = 전문가 지급액
--   · 초기 모집 전문가: sos_experts.early_rate_until 날짜까지 수수료 10%
--       (승인일 + 6개월로 관리자가 지정. 비워 두면 기본 20%)
--   · 정산 대상: 그달(한국 시간)에 상담료가 확정된 접수 + 그달에 결제된 연장
--   · 끊김·연결불가 신고가 '처리 중'인 상담은 보류(이번 달 지급에서 제외)로 따로 표시
--   · 환불분 차감, 최소 지급액 이월은 관리자 확인 후 처리
--
-- sos_fee_plan_a_2026-11.sql 을 먼저 실행한 뒤 실행하세요.
-- Supabase SQL Editor에 통째로 붙여 넣고 Run 하세요.
-- =====================================================================

begin;

-- 수수료 설정 (바꾸려면 여기만)
create or replace function public._sos_commission_cfg(p_key text) returns int
language sql immutable as $$
    select case p_key
        when 'rate'       then 20   -- 기본 수수료 %
        when 'early_rate' then 10   -- 초기 모집 전문가 수수료 %
        when 'min_payout' then 10000 -- 최소 지급액 (미달 시 이월)
    end
$$;

alter table public.sos_experts add column if not exists early_rate_until date;   -- 이 날짜까지 초기 수수료 적용

-- 관리자: 월 정산표 (p_month: 그달 아무 날짜, 기본 = 지난달)
create or replace function public.admin_sos_settlement(p_month date default (date_trunc('month', (now() at time zone 'Asia/Seoul')) - interval '1 month')::date)
returns table (
    sos_expert_id   uuid,
    expert_name     text,
    consult_count   int,
    consult_amount  int,
    extend_count    int,
    extend_amount   int,
    held_count      int,
    held_amount     int,
    gross_amount    int,
    commission      int,
    payout          int,
    below_minimum   boolean
)
language plpgsql stable security definer set search_path = public as $$
declare
    v_from timestamptz := (date_trunc('month', p_month)::timestamp at time zone 'Asia/Seoul');
    v_to   timestamptz := ((date_trunc('month', p_month) + interval '1 month')::timestamp at time zone 'Asia/Seoul');
begin
    if not public.is_admin() then raise exception 'ADMIN_ONLY'; end if;

    return query
    with consult as (
        select m.o_expert as expert_id,
               coalesce(r.fee_amount, r.base_fee, 0)::int as amount,
               r.fee_charged_at as at,
               exists (select 1 from sos_sessions s
                        where s.request_id = r.id and s.dispute_status = 'open') as held
          from sos_requests r
          cross join lateral _sos_current_match(r.id) m
         where r.fee_charged_at >= v_from and r.fee_charged_at < v_to
           and m.o_expert is not null
    ),
    ext as (
        select e.sos_expert_id as expert_id, e.amount, e.created_at as at,
               exists (select 1 from sos_sessions s
                        where s.id = e.session_id and s.dispute_status = 'open') as held
          from sos_session_extensions e
         where e.created_at >= v_from and e.created_at < v_to
    ),
    items as (
        select c.expert_id, 'consult'::text as kind, c.amount, c.at, c.held from consult c
        union all
        select x.expert_id, 'extend', x.amount, x.at, x.held from ext x
    ),
    priced as (
        select i.*,
               case when ex.early_rate_until is not null and (i.at at time zone 'Asia/Seoul')::date <= ex.early_rate_until
                    then _sos_commission_cfg('early_rate') else _sos_commission_cfg('rate') end as rate
          from items i
          left join sos_experts ex on ex.id = i.expert_id
    )
    select p.expert_id,
           max(x.name)::text,
           count(*) filter (where p.kind = 'consult' and not p.held)::int,
           coalesce(sum(p.amount) filter (where p.kind = 'consult' and not p.held), 0)::int,
           count(*) filter (where p.kind = 'extend' and not p.held)::int,
           coalesce(sum(p.amount) filter (where p.kind = 'extend' and not p.held), 0)::int,
           count(*) filter (where p.held)::int,
           coalesce(sum(p.amount) filter (where p.held), 0)::int,
           coalesce(sum(p.amount) filter (where not p.held), 0)::int,
           coalesce(sum(round(p.amount * p.rate / 100.0)) filter (where not p.held), 0)::int,
           coalesce(sum(p.amount - round(p.amount * p.rate / 100.0)) filter (where not p.held), 0)::int,
           coalesce(sum(p.amount - round(p.amount * p.rate / 100.0)) filter (where not p.held), 0) < _sos_commission_cfg('min_payout')
      from priced p
      left join sos_experts x on x.id = p.expert_id
     group by p.expert_id
     order by 11 desc;
end $$;
grant execute on function public.admin_sos_settlement(date) to authenticated;

-- 관리자: 초기 수수료 적용 기간 지정 (p_until 을 비우면 해제)
create or replace function public.admin_set_early_rate(p_expert_id uuid, p_until date)
returns void language plpgsql security definer set search_path = public as $$
begin
    if not public.is_admin() then raise exception 'ADMIN_ONLY'; end if;
    update sos_experts set early_rate_until = p_until where id = p_expert_id;
end $$;
grant execute on function public.admin_set_early_rate(uuid, date) to authenticated;

commit;
