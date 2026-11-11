-- =====================================================================
-- 환불 장부 후속 수정 1 (2026-11)
--   끊김·연결불가 신고 환불: 후불 접수(회원사·후불 회원)는 포인트로 돌려주지 않고 장부에만 기록
--   → 회원사는 그달 청구 금액에서 자동으로 빠짐 (이중 환불 방지)
--   선불(포인트·카드 결제) 접수는 지금처럼 포인트로 돌려줌
-- sos_company_2026-11.sql 까지 실행한 뒤 실행하세요.
-- =====================================================================

begin;

create or replace function public.admin_sos_dispute_refund(p_session_id uuid, p_amount int default null, p_note text default null)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
    s         sos_sessions%rowtype;
    r         sos_requests%rowtype;
    v_amt     int;
    v_postpaid boolean;
begin
    if not public.is_admin() then raise exception 'NOT_ADMIN'; end if;
    select * into s from sos_sessions where id = p_session_id for update;
    if not found then raise exception 'NOT_FOUND'; end if;
    select * into r from sos_requests where id = s.request_id for update;
    if exists (select 1 from sos_refunds where request_id = r.id) then raise exception 'ALREADY_REFUNDED'; end if;

    v_amt := coalesce(p_amount, r.fee_amount, r.base_fee, 0);
    if v_amt <= 0 then raise exception 'NOTHING_TO_REFUND'; end if;

    -- 후불 접수인지: 회원사 접수이거나, 접수 때 후불 방식으로 기록된 건
    v_postpaid := r.company_id is not null or coalesce(r.pay_mode, '') ilike '%post%';

    if not v_postpaid then
        if r.user_id is null then raise exception 'NO_USER'; end if;
        update user_profiles set points = coalesce(points, 0) + v_amt where id = r.user_id;
        if not found then raise exception 'NO_PROFILE'; end if;
    end if;

    insert into sos_refunds (request_id, user_id, amount, kind, reason)
    values (r.id, r.user_id, v_amt, 'dispute',
            coalesce(nullif(trim(p_note), ''), '끊김·연결불가 신고 환불') || case when v_postpaid then ' (후불: 청구에서 차감)' else '' end);

    update sos_requests set status = 'refund_completed' where id = r.id and status is distinct from 'refund_completed';

    update sos_sessions
       set dispute_status = 'resolved',
           dispute_note = coalesce(nullif(trim(p_note), ''), '') ||
                          case when v_postpaid then ' [후불 ' || v_amt || '원 청구 차감]' else ' [포인트 ' || v_amt || 'P 환불]' end
     where id = p_session_id;
    perform _sos_log(p_session_id, r.id, 'admin', 'dispute_refunded', v_amt::text || case when v_postpaid then ' postpaid' else ' points' end);

    return jsonb_build_object('refunded', v_amt, 'to_points', not v_postpaid);
end $$;
grant execute on function public.admin_sos_dispute_refund(uuid, int, text) to authenticated;

commit;
