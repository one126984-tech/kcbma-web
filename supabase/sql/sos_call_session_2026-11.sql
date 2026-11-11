-- =====================================================================
-- 긴급 SOS 전화상담 "세션" 기능 (2026-11)
--   · 상담 1건 = 세션 1개: 첫 통화 시작부터 60분, 그 안의 재연결은 추가 요금 없음
--   · 통화가 끊기면 전문가가 1분 안에 다시 건다 (요청자 [통화가 끊겼어요] → 전문가 화면 알림)
--   · 세션 중인 전문가는 다른 접수에 배정되지 않음 (전문가 잠금)
--   · 끊긴 뒤 10분 넘게 연결이 안 되면 요청자가 운영진 확인 요청 (관리자 화면에서 처리)
--   · 상담 종료 후 24시간 안에 같은 전문가와 '후속 확인 통화' 1회 무료 (30분)
--
-- 기존 테이블·함수는 고치지 않고 새 테이블·함수만 추가합니다.
-- Supabase SQL Editor에 통째로 붙여 넣고 Run 하세요. (오류가 나면 아무것도 반영되지 않습니다)
-- =====================================================================

begin;

-- ---------------------------------------------------------------------
-- 1. 테이블
-- ---------------------------------------------------------------------
create table if not exists public.sos_sessions (
    id                      uuid primary key default gen_random_uuid(),
    request_id              uuid not null references public.sos_requests(id) on delete cascade,
    sos_expert_id           uuid not null references public.sos_experts(id) on delete cascade,
    kind                    text not null default 'main' check (kind in ('main', 'followup')),
    started_at              timestamptz not null default now(),
    expires_at              timestamptz not null,
    connected_at            timestamptz,          -- 실제로 통화가 연결됐다고 누군가 표시한 시각
    closed_at               timestamptz,
    closed_by               text,                 -- requester_end / expert_end / released / unreachable
    contact_phone_override  text,                 -- 요청자가 바꾼 '받을 번호'
    last_drop_at            timestamptz,          -- 마지막 [통화가 끊겼어요]
    last_reconnect_at       timestamptz,          -- 마지막 [다시 연결됨]
    drop_count              int not null default 0,
    dispute_status          text check (dispute_status in ('open', 'resolved')),
    dispute_note            text,
    created_at              timestamptz not null default now(),
    unique (request_id, sos_expert_id, kind)
);
create index if not exists sos_sessions_expert_idx on public.sos_sessions (sos_expert_id, kind, expires_at);
create index if not exists sos_sessions_dispute_idx on public.sos_sessions (dispute_status) where dispute_status is not null;

create table if not exists public.sos_call_events (
    id          bigserial primary key,
    session_id  uuid references public.sos_sessions(id) on delete cascade,
    request_id  uuid not null references public.sos_requests(id) on delete cascade,
    actor       text not null check (actor in ('requester', 'expert', 'system', 'admin')),
    event       text not null,
    note        text,
    created_at  timestamptz not null default now()
);
create index if not exists sos_call_events_req_idx on public.sos_call_events (request_id, created_at);

-- 화면에서 직접 읽고 쓰지 못하게 막고, 아래 함수로만 다룹니다. 관리자만 직접 조회 가능.
alter table public.sos_sessions    enable row level security;
alter table public.sos_call_events enable row level security;
drop policy if exists "admin read sos_sessions" on public.sos_sessions;
create policy "admin read sos_sessions" on public.sos_sessions for select using (public.is_admin());
drop policy if exists "admin read sos_call_events" on public.sos_call_events;
create policy "admin read sos_call_events" on public.sos_call_events for select using (public.is_admin());

-- ---------------------------------------------------------------------
-- 2. 내부 도우미
-- ---------------------------------------------------------------------
-- 세션 길이 (바꾸려면 여기만 고치면 됩니다)
create or replace function public._sos_cfg(p_key text) returns interval
language sql immutable as $$
    select case p_key
        when 'main'            then interval '60 minutes'   -- 본 상담 세션
        when 'followup'        then interval '30 minutes'   -- 후속 확인 통화
        when 'followup_window' then interval '24 hours'     -- 종료 후 후속 통화 가능 기간
        when 'unreachable'     then interval '10 minutes'   -- 끊긴 뒤 이 시간이 지나면 '연결 안 됨' 신고 가능
        when 'start_grace'     then interval '60 minutes'   -- 상담료 확정(완료) 뒤에도 세션을 시작할 수 있는 시간(배정 기준)
    end
$$;

-- 지금 이 접수에 배정된 전문가(sos_experts.id)와 배정 시각
create or replace function public._sos_current_match(p_request_id uuid, out o_expert uuid, out o_matched_at timestamptz)
language sql stable security definer set search_path = public as $$
    select m.sos_expert_id, m.created_at
      from sos_matches m
     where m.request_id = p_request_id and m.sos_expert_id is not null
     order by m.created_at desc
     limit 1
$$;

-- 세션을 화면용 JSON으로
create or replace function public._sos_session_json(s public.sos_sessions) returns jsonb
language sql stable as $$
    select case when s.id is null then null else jsonb_build_object(
        'id', s.id,
        'kind', s.kind,
        'started_at', s.started_at,
        'expires_at', s.expires_at,
        'connected_at', s.connected_at,
        'closed_at', s.closed_at,
        'closed_by', s.closed_by,
        'active', (s.closed_at is null and s.expires_at > now()),
        'remaining_sec', greatest(0, floor(extract(epoch from (s.expires_at - now()))))::int,
        'contact_phone_override', s.contact_phone_override,
        'last_drop_at', s.last_drop_at,
        'last_reconnect_at', s.last_reconnect_at,
        'drop_count', s.drop_count,
        'dispute_status', s.dispute_status
    ) end
$$;

create or replace function public._sos_log(p_session uuid, p_request uuid, p_actor text, p_event text, p_note text default null)
returns void language sql security definer set search_path = public as $$
    insert into sos_call_events (session_id, request_id, actor, event, note)
    values (p_session, p_request, p_actor, p_event, p_note)
$$;

-- 내 전문가 id (로그인한 전문가)
create or replace function public._sos_my_expert_id() returns uuid
language sql stable security definer set search_path = public as $$
    select id from sos_experts where user_id = auth.uid() and is_active = true limit 1
$$;

-- 본 상담 세션 시작 (이미 있으면 그대로 반환). 요청자·전문가 공용
create or replace function public._sos_ensure_main(p_request_id uuid, p_actor text)
returns public.sos_sessions language plpgsql security definer set search_path = public as $$
declare
    v_req      sos_requests%rowtype;
    v_expert   uuid;
    v_matched  timestamptz;
    s          sos_sessions%rowtype;
begin
    select * into v_req from sos_requests where id = p_request_id;
    if not found then raise exception 'REQUEST_NOT_FOUND'; end if;

    select o_expert, o_matched_at into v_expert, v_matched from _sos_current_match(p_request_id);
    if v_expert is null then raise exception 'NOT_MATCHED'; end if;

    select * into s from sos_sessions where request_id = p_request_id and sos_expert_id = v_expert and kind = 'main';
    if found then return s; end if;

    -- 상담 중(매칭됨)이거나, 10분 경과로 상담료가 확정(완료)된 직후에만 새로 시작
    if v_req.status = '매칭됨'
       or (v_req.status = '완료' and v_matched > now() - _sos_cfg('start_grace')) then
        insert into sos_sessions (request_id, sos_expert_id, kind, started_at, expires_at)
        values (p_request_id, v_expert, 'main', now(), now() + _sos_cfg('main'))
        on conflict (request_id, sos_expert_id, kind) do nothing
        returning * into s;
        if s.id is null then
            select * into s from sos_sessions where request_id = p_request_id and sos_expert_id = v_expert and kind = 'main';
        else
            perform _sos_log(s.id, p_request_id, p_actor, 'session_start');
        end if;
        return s;
    end if;
    raise exception 'REQUEST_CLOSED';
end $$;

-- 지금 의미 있는 세션(진행 중인 후속 통화 > 본 상담) 한 개
create or replace function public._sos_live_session(p_request_id uuid)
returns public.sos_sessions language sql stable security definer set search_path = public as $$
    select s.* from sos_sessions s
     where s.request_id = p_request_id
       and s.sos_expert_id = (select o_expert from _sos_current_match(p_request_id))
       and s.closed_at is null and s.expires_at > now()
     order by (s.kind = 'followup') desc
     limit 1
$$;

-- ---------------------------------------------------------------------
-- 3. 요청자용 함수 (접수번호를 아는 사람 = 요청자. 기존 get_sos_request_by_id 와 같은 방식)
-- ---------------------------------------------------------------------
-- 세션 상태 조회
create or replace function public.sos_session_get(p_request_id uuid)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare
    v_expert uuid;
    m sos_sessions%rowtype;
    f sos_sessions%rowtype;
    v_main_end timestamptz;
    v_deadline timestamptz;
    v_can_followup boolean := false;
begin
    select o_expert into v_expert from _sos_current_match(p_request_id);
    if v_expert is null then
        return jsonb_build_object('server_now', now(), 'main', null, 'followup', null, 'followup_available', false);
    end if;
    select * into m from sos_sessions where request_id = p_request_id and sos_expert_id = v_expert and kind = 'main';
    select * into f from sos_sessions where request_id = p_request_id and sos_expert_id = v_expert and kind = 'followup';

    if m.id is not null and not (m.closed_at is null and m.expires_at > now()) and coalesce(m.closed_by, '') not in ('released', 'unreachable') then
        v_main_end := least(coalesce(m.closed_at, m.expires_at), m.expires_at);
        v_deadline := v_main_end + _sos_cfg('followup_window');
        v_can_followup := now() < v_deadline
            and (f.id is null or (f.connected_at is null and not (f.closed_at is null and f.expires_at > now())));
    end if;

    return jsonb_build_object(
        'server_now', now(),
        'main', _sos_session_json(m),
        'followup', _sos_session_json(f),
        'followup_used', (f.id is not null and f.connected_at is not null),
        'followup_available', v_can_followup,
        'followup_deadline', v_deadline,
        'unreachable_after_sec', extract(epoch from _sos_cfg('unreachable'))::int
    );
end $$;

-- 요청자가 전화번호를 눌렀을 때: 세션 시작(없으면) + 기록
create or replace function public.sos_session_start(p_request_id uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
declare s sos_sessions%rowtype;
begin
    s := _sos_live_session(p_request_id);
    if s.id is null then
        s := _sos_ensure_main(p_request_id, 'requester');
    end if;
    perform _sos_log(s.id, p_request_id, 'requester', 'call_click');
    return sos_session_get(p_request_id);
end $$;

-- 요청자 이벤트: dropped(통화가 끊겼어요) / reconnected(다시 연결됐어요)
create or replace function public.sos_session_event(p_request_id uuid, p_event text)
returns jsonb language plpgsql security definer set search_path = public as $$
declare s sos_sessions%rowtype;
begin
    if p_event not in ('dropped', 'reconnected') then raise exception 'BAD_EVENT'; end if;
    s := _sos_live_session(p_request_id);
    if s.id is null then raise exception 'NO_ACTIVE_SESSION'; end if;

    if p_event = 'dropped' then
        update sos_sessions set last_drop_at = now(), drop_count = drop_count + 1 where id = s.id;
    else
        update sos_sessions set last_reconnect_at = now(), connected_at = coalesce(connected_at, now()) where id = s.id;
    end if;
    perform _sos_log(s.id, p_request_id, 'requester', p_event);
    return sos_session_get(p_request_id);
end $$;

-- 받을 번호 바꾸기
create or replace function public.sos_session_change_phone(p_request_id uuid, p_phone text)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
    s sos_sessions%rowtype;
    v_digits text := regexp_replace(coalesce(p_phone, ''), '[^0-9]', '', 'g');
begin
    if length(v_digits) < 9 or length(v_digits) > 11 then raise exception 'BAD_PHONE'; end if;
    s := _sos_live_session(p_request_id);
    if s.id is null then raise exception 'NO_ACTIVE_SESSION'; end if;
    update sos_sessions set contact_phone_override = v_digits where id = s.id;
    perform _sos_log(s.id, p_request_id, 'requester', 'phone_changed', v_digits);
    return sos_session_get(p_request_id);
end $$;

-- 요청자가 세션 종료 (상담 종료 / 전문가 해지)
create or replace function public.sos_session_close(p_request_id uuid, p_reason text default 'requester_end')
returns jsonb language plpgsql security definer set search_path = public as $$
declare s sos_sessions%rowtype;
begin
    if p_reason not in ('requester_end', 'released') then raise exception 'BAD_REASON'; end if;
    for s in select * from sos_sessions where request_id = p_request_id and closed_at is null and expires_at > now() loop
        update sos_sessions set closed_at = now(), closed_by = p_reason where id = s.id;
        perform _sos_log(s.id, p_request_id, 'requester', 'session_end', p_reason);
    end loop;
    return sos_session_get(p_request_id);
end $$;

-- 끊긴 뒤 10분 넘게 전문가와 연결이 안 될 때: 운영진 확인 요청 (세션 종료 + 신고 접수)
create or replace function public.sos_session_report_unreachable(p_request_id uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
declare s sos_sessions%rowtype;
begin
    s := _sos_live_session(p_request_id);
    if s.id is null or s.kind <> 'main' then raise exception 'NO_ACTIVE_SESSION'; end if;
    if s.last_drop_at is null
       or s.last_drop_at > now() - _sos_cfg('unreachable')
       or (s.last_reconnect_at is not null and s.last_reconnect_at > s.last_drop_at) then
        raise exception 'TOO_EARLY';
    end if;
    update sos_sessions
       set closed_at = now(), closed_by = 'unreachable', dispute_status = 'open'
     where id = s.id;
    perform _sos_log(s.id, p_request_id, 'requester', 'unreachable_report');
    return sos_session_get(p_request_id);
end $$;

-- 후속 확인 통화 시작 (종료 후 24시간 안, 1회 무료. 전문가와 연결되지 않았으면 다시 시작 가능)
create or replace function public.sos_followup_start(p_request_id uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
    v_expert uuid;
    m sos_sessions%rowtype;
    f sos_sessions%rowtype;
begin
    select o_expert into v_expert from _sos_current_match(p_request_id);
    if v_expert is null then raise exception 'NOT_MATCHED'; end if;
    select * into m from sos_sessions where request_id = p_request_id and sos_expert_id = v_expert and kind = 'main';
    if m.id is null then raise exception 'NO_MAIN_SESSION'; end if;
    if m.closed_at is null and m.expires_at > now() then raise exception 'MAIN_STILL_ACTIVE'; end if;
    if coalesce(m.closed_by, '') in ('released', 'unreachable') then raise exception 'FOLLOWUP_NOT_ALLOWED'; end if;
    if now() >= least(coalesce(m.closed_at, m.expires_at), m.expires_at) + _sos_cfg('followup_window') then
        raise exception 'FOLLOWUP_EXPIRED';
    end if;

    select * into f from sos_sessions where request_id = p_request_id and sos_expert_id = v_expert and kind = 'followup';
    if f.id is not null then
        if f.closed_at is null and f.expires_at > now() then
            perform _sos_log(f.id, p_request_id, 'requester', 'call_click');
            return sos_session_get(p_request_id);
        end if;
        if f.connected_at is not null then raise exception 'FOLLOWUP_USED'; end if;
        update sos_sessions
           set started_at = now(), expires_at = now() + _sos_cfg('followup'), closed_at = null, closed_by = null,
               last_drop_at = null, last_reconnect_at = null, drop_count = 0
         where id = f.id;
    else
        insert into sos_sessions (request_id, sos_expert_id, kind, started_at, expires_at, contact_phone_override)
        values (p_request_id, v_expert, 'followup', now(), now() + _sos_cfg('followup'), m.contact_phone_override)
        returning * into f;
    end if;
    perform _sos_log(f.id, p_request_id, 'requester', 'followup_start');
    return sos_session_get(p_request_id);
end $$;

-- 세션 중인 전문가 목록 (요청자 화면에서 '대기 중 전문가'에서 빼기 위함, id만 공개)
create or replace function public.sos_busy_expert_ids()
returns setof uuid language sql stable security definer set search_path = public as $$
    select distinct sos_expert_id from sos_sessions
     where kind = 'main' and closed_at is null and expires_at > now()
$$;

-- ---------------------------------------------------------------------
-- 4. 전문가용 함수 (로그인한 전문가 본인 것만)
-- ---------------------------------------------------------------------
-- 진행 중인 내 세션 (요청자 번호 포함: 접수 상태가 '완료'가 되어도 세션 동안은 다시 걸 수 있게)
create or replace function public.sos_my_sessions()
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare v_me uuid := _sos_my_expert_id();
begin
    if v_me is null then return '[]'::jsonb; end if;
    return coalesce((
        select jsonb_agg(_sos_session_json(s) || jsonb_build_object(
                    'request_id', r.id,
                    'category', r.category,
                    'region', r.region,
                    'contact_phone', coalesce(s.contact_phone_override, r.contact_phone),
                    'phone_changed', s.contact_phone_override is not null,
                    'server_now', now())
                order by s.started_at desc)
          from sos_sessions s
          join sos_requests r on r.id = s.request_id
         where s.sos_expert_id = v_me
           and s.closed_at is null and s.expires_at > now()
    ), '[]'::jsonb);
end $$;

-- 전문가 이벤트: call_click(전화 걸기, 없으면 세션 시작) / connected / reconnected / no_answer(고객이 안 받음)
create or replace function public.sos_expert_session_event(p_request_id uuid, p_event text)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
    v_me uuid := _sos_my_expert_id();
    v_expert uuid;
    s sos_sessions%rowtype;
begin
    if v_me is null then raise exception 'NOT_EXPERT'; end if;
    if p_event not in ('call_click', 'connected', 'reconnected', 'no_answer') then raise exception 'BAD_EVENT'; end if;
    select o_expert into v_expert from _sos_current_match(p_request_id);
    if v_expert is distinct from v_me then raise exception 'NOT_MY_REQUEST'; end if;

    s := _sos_live_session(p_request_id);
    if s.id is null then
        if p_event in ('call_click', 'connected') then
            s := _sos_ensure_main(p_request_id, 'expert');
        else
            raise exception 'NO_ACTIVE_SESSION';
        end if;
    end if;

    if p_event = 'connected' then
        update sos_sessions set connected_at = coalesce(connected_at, now()) where id = s.id;
    elsif p_event = 'reconnected' then
        update sos_sessions set last_reconnect_at = now(), connected_at = coalesce(connected_at, now()) where id = s.id;
    end if;
    perform _sos_log(s.id, p_request_id, 'expert', p_event);
    return sos_my_sessions();
end $$;

-- 전문가가 상담 완료 (세션을 닫고 대기 목록으로 복귀)
create or replace function public.sos_expert_session_close(p_request_id uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
    v_me uuid := _sos_my_expert_id();
    s sos_sessions%rowtype;
begin
    if v_me is null then raise exception 'NOT_EXPERT'; end if;
    for s in select * from sos_sessions where request_id = p_request_id and sos_expert_id = v_me and closed_at is null and expires_at > now() loop
        update sos_sessions set closed_at = now(), closed_by = 'expert_end' where id = s.id;
        perform _sos_log(s.id, p_request_id, 'expert', 'session_end', 'expert_end');
    end loop;
    return sos_my_sessions();
end $$;

-- ---------------------------------------------------------------------
-- 5. 전문가 잠금: 다른 접수에서 세션 중인 전문가는 새로 배정할 수 없음
-- ---------------------------------------------------------------------
create or replace function public._sos_block_busy_expert() returns trigger
language plpgsql security definer set search_path = public as $$
begin
    if new.sos_expert_id is not null and exists (
        select 1 from sos_sessions s
         where s.sos_expert_id = new.sos_expert_id and s.kind = 'main'
           and s.request_id <> new.request_id
           and s.closed_at is null and s.expires_at > now()
    ) then
        raise exception 'EXPERT_BUSY';
    end if;
    return new;
end $$;
drop trigger if exists trg_sos_block_busy_expert on public.sos_matches;
create trigger trg_sos_block_busy_expert
    before insert or update of sos_expert_id on public.sos_matches
    for each row execute function public._sos_block_busy_expert();

-- ---------------------------------------------------------------------
-- 6. 관리자: 끊김·연결불가 신고 목록 / 처리 완료
-- ---------------------------------------------------------------------
create or replace function public.admin_list_sos_disputes(p_include_resolved boolean default false)
returns jsonb language plpgsql stable security definer set search_path = public as $$
begin
    if not public.is_admin() then raise exception 'NOT_ADMIN'; end if;
    return coalesce((
        select jsonb_agg(jsonb_build_object(
                    'session_id', s.id,
                    'request_id', s.request_id,
                    'kind', s.kind,
                    'started_at', s.started_at,
                    'closed_at', s.closed_at,
                    'drop_count', s.drop_count,
                    'dispute_status', s.dispute_status,
                    'dispute_note', s.dispute_note,
                    'category', r.category,
                    'region', r.region,
                    'contact_phone', r.contact_phone,
                    'requester_user_id', r.user_id,
                    'requester_email', (select u.email from auth.users u where u.id = r.user_id),
                    'expert_name', e.name,
                    'events', (select coalesce(jsonb_agg(jsonb_build_object('at', ev.created_at, 'actor', ev.actor, 'event', ev.event, 'note', ev.note) order by ev.created_at), '[]'::jsonb)
                                 from sos_call_events ev where ev.request_id = s.request_id))
                order by s.closed_at desc nulls last)
          from sos_sessions s
          join sos_requests r on r.id = s.request_id
          join sos_experts  e on e.id = s.sos_expert_id
         where s.dispute_status = 'open' or (p_include_resolved and s.dispute_status = 'resolved')
    ), '[]'::jsonb);
end $$;

create or replace function public.admin_resolve_sos_dispute(p_session_id uuid, p_note text)
returns void language plpgsql security definer set search_path = public as $$
declare v_req uuid;
begin
    if not public.is_admin() then raise exception 'NOT_ADMIN'; end if;
    update sos_sessions set dispute_status = 'resolved', dispute_note = p_note
     where id = p_session_id and dispute_status = 'open'
     returning request_id into v_req;
    if v_req is null then raise exception 'NOT_FOUND'; end if;
    perform _sos_log(p_session_id, v_req, 'admin', 'dispute_resolved', p_note);
end $$;

-- ---------------------------------------------------------------------
-- 7. 실행 권한
-- ---------------------------------------------------------------------
revoke all on function public._sos_current_match(uuid)               from public, anon, authenticated;
revoke all on function public._sos_log(uuid, uuid, text, text, text) from public, anon, authenticated;
revoke all on function public._sos_my_expert_id()                    from public, anon, authenticated;
revoke all on function public._sos_ensure_main(uuid, text)           from public, anon, authenticated;
revoke all on function public._sos_live_session(uuid)                from public, anon, authenticated;
revoke all on function public._sos_block_busy_expert()               from public, anon, authenticated;

grant execute on function public.sos_session_get(uuid)                  to anon, authenticated;
grant execute on function public.sos_session_start(uuid)                to anon, authenticated;
grant execute on function public.sos_session_event(uuid, text)          to anon, authenticated;
grant execute on function public.sos_session_change_phone(uuid, text)   to anon, authenticated;
grant execute on function public.sos_session_close(uuid, text)          to anon, authenticated;
grant execute on function public.sos_session_report_unreachable(uuid)   to anon, authenticated;
grant execute on function public.sos_followup_start(uuid)               to anon, authenticated;
grant execute on function public.sos_busy_expert_ids()                  to anon, authenticated;
grant execute on function public.sos_my_sessions()                      to authenticated;
grant execute on function public.sos_expert_session_event(uuid, text)   to authenticated;
grant execute on function public.sos_expert_session_close(uuid)         to authenticated;
grant execute on function public.admin_list_sos_disputes(boolean)       to authenticated;
grant execute on function public.admin_resolve_sos_dispute(uuid, text)  to authenticated;

commit;

-- 확인용 (실행 후 아래 한 줄을 따로 돌려 보면 새 함수 13개가 보여야 합니다)
-- select proname from pg_proc where proname like 'sos_session%' or proname like 'sos_followup%' or proname like 'sos_my_sessions' or proname like 'sos_expert_session%' or proname like 'sos_busy%' or proname like 'admin_%sos_dispute%';
