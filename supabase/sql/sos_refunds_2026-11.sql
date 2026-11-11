-- =====================================================================
-- 긴급 SOS 환불 장부 (2026-11)
--   · sos_refunds: 언제·얼마를·어떤 이유로 환불했는지 한 줄씩 남기는 장부
--   · 마이페이지 환불 요청 → 관리자 '환불 승인'으로 접수 상태가 refund_completed 가 되면 자동 기록
--   · 끊김·연결불가 신고: 관리자 화면에서 [포인트 환불 + 처리 완료] 한 번으로
--       포인트 환불 + 장부 기록 + 신고 처리 + 접수 상태 '환불 완료' (마이페이지 중복 환불 요청 방지)
--   · 이미 환불 완료된 지난 접수도 장부에 채워 넣음
--   · 월 정산표: 그달 환불된 금액만큼 전문가 지급액·수수료를 차감 (환불 차감 칸 추가)
--
-- sos_commission_2026-11.sql 을 먼저 실행한 뒤 실행하세요.
-- Supabase SQL Editor에 통째로 붙여 넣고 Run 하세요.
-- =====================================================================

begin;

-- ---------------------------------------------------------------------
-- 1. 환불 장부
-- ---------------------------------------------------------------------
create table if not exists public.sos_refunds (
    id           uuid primary key default gen_random_uuid(),
    request_id   uuid not null references public.sos_requests(id) on delete cascade,
    user_id      uuid,
    amount       int  not null check (amount >= 0),
    kind         text not null check (kind in ('request', 'dispute', 'manual')),  -- 요청 환불 / 끊김 신고 환불 / 기타
    reason       text,
    refunded_at  timestamptz not null default now(),
    created_by   uuid default auth.uid(),
    unique (request_id, kind)
);
create index if not exists sos_refunds_at_idx on public.sos_refunds (refunded_at);
alter table public.sos_refunds enable row level security;
drop policy if exists "admin read sos_refunds" on public.sos_refunds;
create policy "admin read sos_refunds" on public.sos_refunds for select using (public.is_admin());
drop policy if exists "own read sos_refunds" on public.sos_refunds;
create policy "own read sos_refunds" on public.sos_refunds for select using (user_id = auth.uid());

-- ---------------------------------------------------------------------
-- 2. 접수 상태가 '환불 완료'가 되면 자동 기록 (이미 기록이 있으면 건너뜀)
-- ---------------------------------------------------------------------
create or replace function public._sos_record_refund() returns trigger
language plpgsql security definer set search_path = public as $$
begin
    if new.status = 'refund_completed' and old.status is distinct from 'refund_completed'
       and not exists (select 1 from sos_refunds where request_id = new.id) then
        insert into sos_refunds (request_id, user_id, amount, kind, reason)
        values (new.id, new.user_id, coalesce(new.fee_amount, new.base_fee, 0), 'request', new.refund_reason)
        on conflict (request_id, kind) do nothing;
    end if;
    return new;
end $$;
drop trigger if exists trg_sos_record_refund on public.sos_requests;
create trigger trg_sos_record_refund
    after update of status on public.sos_requests
    for each row execute function public._sos_record_refund();

-- 지난 환불 완료 건 채워 넣기 (환불 시각을 모르는 건은 환불 요청 시각으로)
insert into public.sos_refunds (request_id, user_id, amount, kind, reason, refunded_at, created_by)
select r.id, r.user_id, coalesce(r.fee_amount, r.base_fee, 0), 'request', r.refund_reason,
       coalesce(r.refund_requested_at, r.created_at), null
  from public.sos_requests r
 where r.status = 'refund_completed'
   and not exists (select 1 from public.sos_refunds f where f.request_id = r.id)
on conflict (request_id, kind) do nothing;

-- ---------------------------------------------------------------------
-- 3. 관리자: 끊김·연결불가 신고 → 포인트 환불 + 장부 기록 + 처리 완료 (한 번에)
--    p_amount 를 비우면 그 접수의 상담료 전액
-- ---------------------------------------------------------------------
create or replace function public.admin_sos_dispute_refund(p_session_id uuid, p_amount int default null, p_note text default null)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
    s       sos_sessions%rowtype;
    r       sos_requests%rowtype;
    v_amt   int;
begin
    if not public.is_admin() then raise exception 'NOT_ADMIN'; end if;
    select * into s from sos_sessions where id = p_session_id for update;
    if not found then raise exception 'NOT_FOUND'; end if;
    select * into r from sos_requests where id = s.request_id for update;
    if exists (select 1 from sos_refunds where request_id = r.id) then raise exception 'ALREADY_REFUNDED'; end if;
    if r.user_id is null then raise exception 'NO_USER'; end if;

    v_amt := coalesce(p_amount, r.fee_amount, r.base_fee, 0);
    if v_amt <= 0 then raise exception 'NOTHING_TO_REFUND'; end if;

    update user_profiles set points = coalesce(points, 0) + v_amt where id = r.user_id;
    if not found then raise exception 'NO_PROFILE'; end if;

    insert into sos_refunds (request_id, user_id, amount, kind, reason)
    values (r.id, r.user_id, v_amt, 'dispute', coalesce(nullif(trim(p_note), ''), '끊김·연결불가 신고 환불'));

    -- 마이페이지에서 '환불 완료'로 보이고 다시 환불 요청을 못 하게 (장부는 위에서 이미 기록 → 트리거는 건너뜀)
    update sos_requests set status = 'refund_completed' where id = r.id and status is distinct from 'refund_completed';

    update sos_sessions
       set dispute_status = 'resolved',
           dispute_note = coalesce(nullif(trim(p_note), ''), '') || ' [포인트 ' || v_amt || 'P 환불]'
     where id = p_session_id;
    perform _sos_log(p_session_id, r.id, 'admin', 'dispute_refunded', v_amt::text);

    return jsonb_build_object('refunded', v_amt);
end $$;
grant execute on function public.admin_sos_dispute_refund(uuid, int, text) to authenticated;

-- ---------------------------------------------------------------------
-- 4. 월 정산표 (환불 차감 반영) — 출력 칸이 바뀌어 지우고 다시 만듦
-- ---------------------------------------------------------------------
drop function if exists public.admin_sos_settlement(date);
create function public.admin_sos_settlement(p_month date default (date_trunc('month', (now() at time zone 'Asia/Seoul')) - interval '1 month')::date)
returns table (
    sos_expert_id   uuid,
    expert_name     text,
    consult_count   int,
    consult_amount  int,
    extend_count    int,
    extend_amount   int,
    held_count      int,
    held_amount     int,
    refund_count    int,
    refund_amount   int,
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
    refunds as (
        -- 그달에 환불된 금액 (수수료율은 원래 상담료가 확정된 날 기준)
        select m.o_expert as expert_id, -f.amount as amount,
               coalesce(r.fee_charged_at, f.refunded_at) as at, false as held
          from sos_refunds f
          join sos_requests r on r.id = f.request_id
          cross join lateral _sos_current_match(r.id) m
         where f.refunded_at >= v_from and f.refunded_at < v_to
           and m.o_expert is not null
    ),
    items as (
        select c.expert_id, 'consult'::text as kind, c.amount, c.at, c.held from consult c
        union all
        select x.expert_id, 'extend', x.amount, x.at, x.held from ext x
        union all
        select f.expert_id, 'refund', f.amount, f.at, f.held from refunds f
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
           count(*) filter (where p.kind = 'refund')::int,
           coalesce(-sum(p.amount) filter (where p.kind = 'refund'), 0)::int,
           coalesce(sum(p.amount) filter (where not p.held), 0)::int,
           coalesce(sum(round(p.amount * p.rate / 100.0)) filter (where not p.held), 0)::int,
           coalesce(sum(p.amount - round(p.amount * p.rate / 100.0)) filter (where not p.held), 0)::int,
           coalesce(sum(p.amount - round(p.amount * p.rate / 100.0)) filter (where not p.held), 0) < _sos_commission_cfg('min_payout')
      from priced p
      left join sos_experts x on x.id = p.expert_id
     group by p.expert_id
     order by 13 desc;
end $$;
grant execute on function public.admin_sos_settlement(date) to authenticated;

commit;

-- 확인용: 장부에 들어간 환불 건수와 합계
select count(*) as 환불건수, coalesce(sum(amount), 0) as 환불합계 from public.sos_refunds;
