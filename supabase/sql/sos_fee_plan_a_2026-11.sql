-- =====================================================================
-- 긴급 SOS 전화상담 요금 A안 + 심야 당번제 (2026-11)
--   · 주간(평일 09:00~18:00, 공휴일 제외)              : 40,000원
--   · 저녁·주말·공휴일(09:00~21:00 중 주간이 아닌 시간) : 60,000원
--   · 심야(매일 21:00~다음 날 09:00)                    : 80,000원
--   · 기본 상담 시간 30분 (그 안에서는 끊겨서 다시 걸어도 추가 요금 없음)
--   · 30분 연장 = 기본 상담료의 절반 (2만 / 3만 / 4만 원), 1건당 최대 2회
--   · 심야에는 대기를 켜 둔 전문가가 1명도 없으면 접수를 받지 않고, 09시 연결 예약을 받습니다.
--   · 심야 당번: 관리자가 날짜별로 전문가를 지정 → 요청자 목록 맨 위 + '오늘 심야 당번' 표시
--   · 요금 시간대는 '접수한 시각' 기준
--   · 금액·시간을 바꾸려면 맨 위 _sos_fee_cfg 한 곳만 고치면 됩니다.
--
-- 먼저 sos_call_session_2026-11.sql 이 실행되어 있어야 합니다.
-- Supabase SQL Editor에 통째로 붙여 넣고 Run 하세요. (오류가 나면 아무것도 반영되지 않습니다)
-- 실행이 끝나면 맨 아래 '점검 결과' 표가 나옵니다. 표에 줄이 있으면 그 내용을 그대로 보내 주세요.
-- =====================================================================

begin;

-- ---------------------------------------------------------------------
-- 1. 요금 설정 (바꾸려면 여기만)
-- ---------------------------------------------------------------------
create or replace function public._sos_fee_cfg(p_key text) returns int
language sql immutable as $$
    select case p_key
        when 'day_fee'        then 40000   -- 주간 상담료
        when 'night_fee'      then 60000   -- 저녁·주말·공휴일 상담료
        when 'late_fee'       then 80000   -- 심야 상담료
        when 'late_from'      then 21      -- 심야 시작 시각 (시)
        when 'late_to'        then 9       -- 심야 끝 시각 (시, 다음 날)
        when 'day_from'       then 9       -- 주간 시작 시각 (시)
        when 'day_to'         then 18      -- 주간 끝 시각 (시, 이 시각부터는 야간)
        when 'extend_min'     then 30      -- 연장 1회 시간 (분)
        when 'extend_max'     then 2       -- 1건당 최대 연장 횟수
        when 'extend_percent' then 50      -- 연장 요금 = 기본 상담료의 몇 %
    end
$$;

-- ---------------------------------------------------------------------
-- 2. 공휴일 표 (평일 공휴일만 실제로 영향이 있지만, 알아보기 쉽게 전부 넣어 둠)
--    매년 12월에 다음 해 공휴일을 아래처럼 추가해 주세요.
-- ---------------------------------------------------------------------
create table if not exists public.sos_holidays (
    day  date primary key,
    name text not null
);
alter table public.sos_holidays enable row level security;
drop policy if exists "anyone read sos_holidays" on public.sos_holidays;
create policy "anyone read sos_holidays" on public.sos_holidays for select using (true);
drop policy if exists "admin write sos_holidays" on public.sos_holidays;
create policy "admin write sos_holidays" on public.sos_holidays for all using (public.is_admin()) with check (public.is_admin());

insert into public.sos_holidays (day, name) values
    ('2026-12-25', '성탄절'),
    ('2027-01-01', '신정'),
    ('2027-02-06', '설날 연휴'),
    ('2027-02-07', '설날'),
    ('2027-02-08', '설날 연휴'),
    ('2027-02-09', '대체공휴일(설날)'),
    ('2027-03-01', '삼일절'),
    ('2027-05-01', '노동절'),
    ('2027-05-03', '대체공휴일(노동절)'),
    ('2027-05-05', '어린이날'),
    ('2027-05-13', '부처님오신날'),
    ('2027-06-06', '현충일'),
    ('2027-07-17', '제헌절'),
    ('2027-07-19', '대체공휴일(제헌절)'),
    ('2027-08-15', '광복절'),
    ('2027-08-16', '대체공휴일(광복절)'),
    ('2027-09-14', '추석 연휴'),
    ('2027-09-15', '추석'),
    ('2027-09-16', '추석 연휴'),
    ('2027-10-03', '개천절'),
    ('2027-10-04', '대체공휴일(개천절)'),
    ('2027-10-09', '한글날'),
    ('2027-10-11', '대체공휴일(한글날)'),
    ('2027-12-25', '성탄절'),
    ('2027-12-27', '대체공휴일(성탄절)')
on conflict (day) do update set name = excluded.name;

-- ---------------------------------------------------------------------
-- 3. 요금 계산
-- ---------------------------------------------------------------------
-- 이 시각이 주간 요금 시간인가? (한국 시간 기준)
create or replace function public.sos_is_day_rate(p_at timestamptz) returns boolean
language sql stable security definer set search_path = public as $$
    with k as (select (p_at at time zone 'Asia/Seoul') as t)
    select extract(isodow from k.t) between 1 and 5
       and extract(hour from k.t) >= _sos_fee_cfg('day_from')
       and extract(hour from k.t) <  _sos_fee_cfg('day_to')
       and not exists (select 1 from sos_holidays h where h.day = k.t::date)
      from k
$$;

-- 이 시각이 심야(21~09시)인가? (요일·공휴일 상관없이 매일)
create or replace function public.sos_is_late(p_at timestamptz) returns boolean
language sql stable as $$
    select extract(hour from (p_at at time zone 'Asia/Seoul')) >= _sos_fee_cfg('late_from')
        or extract(hour from (p_at at time zone 'Asia/Seoul')) <  _sos_fee_cfg('late_to')
$$;

-- 요금 시간대: day(주간) / evening(저녁·주말·공휴일) / late(심야)
create or replace function public.sos_fee_tier(p_at timestamptz) returns text
language sql stable security definer set search_path = public as $$
    select case when sos_is_late(p_at) then 'late'
                when sos_is_day_rate(p_at) then 'day'
                else 'evening' end
$$;

-- 이 시각에 접수하면 내는 기본 상담료
create or replace function public.sos_fee_for_time(p_at timestamptz) returns int
language sql stable security definer set search_path = public as $$
    select case sos_fee_tier(p_at)
               when 'late' then _sos_fee_cfg('late_fee')
               when 'day'  then _sos_fee_cfg('day_fee')
               else _sos_fee_cfg('night_fee') end
$$;

-- 기본 상담료에 대한 30분 연장 요금
create or replace function public.sos_extend_fee(p_base int) returns int
language sql immutable as $$
    select (p_base * _sos_fee_cfg('extend_percent') / 100)
$$;

-- 접수 화면용: 지금 요금 안내 (로그인 안 해도 조회 가능)
create or replace function public.sos_fee_now() returns jsonb
language sql stable security definer set search_path = public as $$
    select jsonb_build_object(
        'server_now',     now(),
        'is_day',         sos_fee_tier(now()) = 'day',
        'tier',           sos_fee_tier(now()),
        'late_fee',       _sos_fee_cfg('late_fee'),
        'late_extend_fee', sos_extend_fee(_sos_fee_cfg('late_fee')),
        'late_from',      _sos_fee_cfg('late_from'),
        'late_to',        _sos_fee_cfg('late_to'),
        'fee',            sos_fee_for_time(now()),
        'extend_fee',     sos_extend_fee(sos_fee_for_time(now())),
        'day_fee',        _sos_fee_cfg('day_fee'),
        'night_fee',      _sos_fee_cfg('night_fee'),
        'day_extend_fee', sos_extend_fee(_sos_fee_cfg('day_fee')),
        'night_extend_fee', sos_extend_fee(_sos_fee_cfg('night_fee')),
        'day_from',       _sos_fee_cfg('day_from'),
        'day_to',         _sos_fee_cfg('day_to'),
        'base_min',       30,
        'extend_min',     _sos_fee_cfg('extend_min'),
        'extend_max',     _sos_fee_cfg('extend_max'),
        'holiday_name',   (select name from sos_holidays where day = (now() at time zone 'Asia/Seoul')::date)
    )
$$;
grant execute on function public.sos_fee_now() to anon, authenticated;

-- ---------------------------------------------------------------------
-- 4. 기존 sos_base_fee() 를 새 요금으로 교체
--    (기존 함수의 이름·인자 모양은 그대로 두고 내용만 바꿉니다.
--     시각을 받는 인자가 있으면 그 시각, 없으면 지금 시각으로 계산)
-- ---------------------------------------------------------------------
do $$
declare
    r record;
    v_first_type text;
    v_at text;
    v_found boolean := false;
begin
    for r in
        select p.oid,
               pg_get_function_arguments(p.oid)          as args,
               pg_get_function_result(p.oid)             as res,
               p.pronargs,
               p.proargtypes
          from pg_proc p
          join pg_namespace n on n.oid = p.pronamespace
         where n.nspname = 'public' and p.proname = 'sos_base_fee'
    loop
        v_found := true;
        v_at := 'now()';
        if r.pronargs > 0 then
            v_first_type := format_type(r.proargtypes[0], null);
            if v_first_type in ('timestamp with time zone', 'timestamp without time zone') then
                v_at := '$1::timestamptz';
            end if;
        end if;
        execute format(
            'create or replace function public.sos_base_fee(%s) returns %s language sql stable security definer set search_path = public as $f$ select (public.sos_fee_for_time(%s))::%s $f$',
            r.args, r.res, v_at, r.res);
        raise notice 'sos_base_fee(%) 교체 완료 (기준 시각: %)', r.args, v_at;
    end loop;
    if not v_found then
        create or replace function public.sos_base_fee() returns int
        language sql stable security definer set search_path = public as $f$ select public.sos_fee_for_time(now()) $f$;
        raise notice 'sos_base_fee() 가 없어 새로 만들었습니다';
    end if;
end $$;

-- ---------------------------------------------------------------------
-- 5. 상담 시간: 기본 60분 → 30분 (기존 _sos_cfg 를 그대로 두고 main 값만 30분으로)
-- ---------------------------------------------------------------------
create or replace function public._sos_cfg(p_key text) returns interval
language sql immutable as $$
    select case p_key
        when 'main'            then interval '30 minutes'   -- 본 상담 (기본 30분, 연장하면 30분씩 늘어남)
        when 'followup'        then interval '30 minutes'   -- 후속 확인 통화
        when 'followup_window' then interval '24 hours'     -- 종료 후 후속 통화 가능 기간
        when 'unreachable'     then interval '10 minutes'   -- 끊긴 뒤 이 시간이 지나면 '연결 안 됨' 신고 가능
        when 'start_grace'     then interval '60 minutes'   -- 상담료 확정(완료) 뒤에도 세션을 시작할 수 있는 시간(배정 기준)
    end
$$;

-- ---------------------------------------------------------------------
-- 6. 30분 연장 기록
-- ---------------------------------------------------------------------
create table if not exists public.sos_session_extensions (
    id             uuid primary key default gen_random_uuid(),
    session_id     uuid not null references public.sos_sessions(id) on delete cascade,
    request_id     uuid not null references public.sos_requests(id) on delete cascade,
    sos_expert_id  uuid not null references public.sos_experts(id) on delete cascade,
    user_id        uuid not null,
    seq            int  not null,                         -- 몇 번째 연장인지 (1, 2)
    amount         int  not null,                         -- 연장 요금
    billing        text not null check (billing in ('points', 'postpaid')),
    minutes        int  not null,
    created_at     timestamptz not null default now(),
    unique (session_id, seq)
);
create index if not exists sos_session_extensions_req_idx on public.sos_session_extensions (request_id);
create index if not exists sos_session_extensions_expert_idx on public.sos_session_extensions (sos_expert_id, created_at);
alter table public.sos_session_extensions enable row level security;
drop policy if exists "admin read sos_session_extensions" on public.sos_session_extensions;
create policy "admin read sos_session_extensions" on public.sos_session_extensions for select using (public.is_admin());

-- 요청자: 30분 연장 (로그인한 접수 본인만. 포인트 차감 또는 후불 회원사는 월말 청구)
create or replace function public.sos_session_extend(p_request_id uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
    v_req     sos_requests%rowtype;
    s         sos_sessions%rowtype;
    v_count   int;
    v_base    int;
    v_amount  int;
    v_points  int;
    v_postpaid boolean;
    v_billing text;
begin
    select * into v_req from sos_requests where id = p_request_id;
    if not found then raise exception 'REQUEST_NOT_FOUND'; end if;
    if auth.uid() is null or v_req.user_id is distinct from auth.uid() then raise exception 'NOT_OWNER'; end if;

    s := _sos_live_session(p_request_id);
    if s.id is null or s.kind <> 'main' then raise exception 'NO_ACTIVE_SESSION'; end if;

    -- 같은 세션에 동시에 두 번 눌러도 한 번만 처리
    perform 1 from sos_sessions where id = s.id for update;

    select count(*) into v_count from sos_session_extensions where session_id = s.id;
    if v_count >= _sos_fee_cfg('extend_max') then raise exception 'EXTEND_LIMIT'; end if;

    v_base   := sos_fee_for_time(v_req.created_at);
    v_amount := sos_extend_fee(v_base);

    select coalesce(points, 0), coalesce(is_postpaid_member, false)
      into v_points, v_postpaid
      from user_profiles where id = auth.uid()
       for update;
    if not found then raise exception 'INSUFFICIENT_BALANCE'; end if;

    if v_postpaid then
        v_billing := 'postpaid';
    else
        if v_points < v_amount then raise exception 'INSUFFICIENT_BALANCE'; end if;
        update user_profiles set points = points - v_amount where id = auth.uid();
        v_billing := 'points';
    end if;

    insert into sos_session_extensions (session_id, request_id, sos_expert_id, user_id, seq, amount, billing, minutes)
    values (s.id, p_request_id, s.sos_expert_id, auth.uid(), v_count + 1, v_amount, v_billing, _sos_fee_cfg('extend_min'));

    update sos_sessions
       set expires_at = expires_at + make_interval(mins => _sos_fee_cfg('extend_min'))
     where id = s.id;

    perform _sos_log(s.id, p_request_id, 'requester', 'extended',
                     (v_count + 1)::text || '회 · ' || v_amount::text || '원 · ' || v_billing);
    return sos_session_get(p_request_id);
end $$;
grant execute on function public.sos_session_extend(uuid) to authenticated;

-- ---------------------------------------------------------------------
-- 7. 세션 조회에 연장 정보 추가 (기존 내용 + extend 항목)
-- ---------------------------------------------------------------------
create or replace function public.sos_session_get(p_request_id uuid)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare
    v_expert uuid;
    m sos_sessions%rowtype;
    f sos_sessions%rowtype;
    v_main_end timestamptz;
    v_deadline timestamptz;
    v_can_followup boolean := false;
    v_created timestamptz;
    v_base int;
    v_ext_count int := 0;
    v_ext_total int := 0;
begin
    select created_at into v_created from sos_requests where id = p_request_id;
    v_base := sos_fee_for_time(coalesce(v_created, now()));

    select o_expert into v_expert from _sos_current_match(p_request_id);
    if v_expert is null then
        return jsonb_build_object('server_now', now(), 'main', null, 'followup', null, 'followup_available', false,
                                  'base_fee', v_base, 'extend_fee', sos_extend_fee(v_base),
                                  'extend_count', 0, 'extend_max', _sos_fee_cfg('extend_max'),
                                  'extend_min', _sos_fee_cfg('extend_min'), 'can_extend', false);
    end if;
    select * into m from sos_sessions where request_id = p_request_id and sos_expert_id = v_expert and kind = 'main';
    select * into f from sos_sessions where request_id = p_request_id and sos_expert_id = v_expert and kind = 'followup';

    if m.id is not null then
        select count(*), coalesce(sum(amount), 0) into v_ext_count, v_ext_total
          from sos_session_extensions where session_id = m.id;
    end if;

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
        'unreachable_after_sec', extract(epoch from _sos_cfg('unreachable'))::int,
        'base_fee', v_base,
        'extend_fee', sos_extend_fee(v_base),
        'extend_count', v_ext_count,
        'extend_total', v_ext_total,
        'extend_max', _sos_fee_cfg('extend_max'),
        'extend_min', _sos_fee_cfg('extend_min'),
        'can_extend', (m.id is not null and m.closed_at is null and m.expires_at > now()
                       and v_ext_count < _sos_fee_cfg('extend_max'))
    );
end $$;

-- 전문가 화면: 진행 중인 내 세션 (기존 내용 + 연장 횟수)
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
                    'extend_count', (select count(*) from sos_session_extensions e where e.session_id = s.id),
                    'server_now', now())
                order by s.started_at desc)
          from sos_sessions s
          join sos_requests r on r.id = s.request_id
         where s.sos_expert_id = v_me
           and s.closed_at is null and s.expires_at > now()
    ), '[]'::jsonb);
end $$;

-- ---------------------------------------------------------------------
-- 8. 심야 당번제
--    '당번 날짜' = 그날 21:00 ~ 다음 날 09:00 (예: 11/12 당번 = 11/12 21시 ~ 11/13 09시)
-- ---------------------------------------------------------------------
create table if not exists public.sos_night_duty (
    duty_date      date not null,
    sos_expert_id  uuid not null references public.sos_experts(id) on delete cascade,
    memo           text,
    created_at     timestamptz not null default now(),
    primary key (duty_date, sos_expert_id)
);
alter table public.sos_night_duty enable row level security;
drop policy if exists "admin all sos_night_duty" on public.sos_night_duty;
create policy "admin all sos_night_duty" on public.sos_night_duty for all using (public.is_admin()) with check (public.is_admin());

-- 지금 시각이 속한 당번 날짜 (심야가 아니면 오늘 밤 날짜)
create or replace function public.sos_duty_date(p_at timestamptz default now()) returns date
language sql stable as $$
    select ((p_at at time zone 'Asia/Seoul') - make_interval(hours => _sos_fee_cfg('late_to')))::date
$$;

-- 지금 상담을 받을 수 있는 전문가 수 (대기 켜짐·자리 비움 아님·서비스 시간 안·상담 중 아님)
create or replace function public.sos_available_expert_count() returns int
language sql stable security definer set search_path = public as $$
    select count(*)::int
      from sos_experts e
     where sos_expert_mode_now(e) is not null
       and public.expert_in_hours(e.avail_from, e.avail_to)
       and not exists (select 1 from sos_sessions s
                        where s.sos_expert_id = e.id and s.kind = 'main'
                          and s.closed_at is null and s.expires_at > now())
$$;

-- 접수 화면용: 지금 심야인지, 받을 수 있는 전문가가 몇 명인지 (번호·이름은 공개하지 않음)
create or replace function public.sos_night_status() returns jsonb
language sql stable security definer set search_path = public as $$
    select jsonb_build_object(
        'server_now', now(),
        'is_late', sos_is_late(now()),
        'available', sos_available_expert_count(),
        'duty_count', (select count(*) from sos_night_duty d where d.duty_date = sos_duty_date(now())),
        'late_from', _sos_fee_cfg('late_from'),
        'late_to', _sos_fee_cfg('late_to')
    )
$$;
grant execute on function public.sos_night_status() to anon, authenticated;

-- 요청자 화면용: 오늘 밤 당번 전문가 id (번호 없음)
create or replace function public.sos_tonight_duty_ids()
returns setof uuid language sql stable security definer set search_path = public as $$
    select sos_expert_id from sos_night_duty where duty_date = sos_duty_date(now())
$$;
grant execute on function public.sos_tonight_duty_ids() to anon, authenticated;

-- 전문가 화면용: 나의 당번 일정 (오늘 밤부터 14일)
create or replace function public.sos_my_night_duty()
returns jsonb language sql stable security definer set search_path = public as $$
    select jsonb_build_object(
        'server_now', now(),
        'is_late', sos_is_late(now()),
        'current_duty_date', sos_duty_date(now()),
        'dates', coalesce((
            select jsonb_agg(d.duty_date order by d.duty_date)
              from sos_night_duty d
              join sos_experts e on e.id = d.sos_expert_id
             where e.user_id = auth.uid()
               and d.duty_date between sos_duty_date(now()) and sos_duty_date(now()) + 14
        ), '[]'::jsonb)
    )
$$;
grant execute on function public.sos_my_night_duty() to authenticated;

-- 심야에 받을 수 있는 전문가가 0명이면 접수 자체를 막음 (화면을 우회해도 서버에서 막힘)
create or replace function public._sos_block_late_without_expert() returns trigger
language plpgsql security definer set search_path = public as $$
begin
    if sos_is_late(now()) and sos_available_expert_count() = 0 then
        raise exception 'NIGHT_NO_EXPERT';
    end if;
    return new;
end $$;
drop trigger if exists trg_sos_block_late_without_expert on public.sos_requests;
create trigger trg_sos_block_late_without_expert
    before insert on public.sos_requests
    for each row execute function public._sos_block_late_without_expert();

-- ---------------------------------------------------------------------
-- 9. 09시 연결 예약 (심야에 전문가가 없을 때)
-- ---------------------------------------------------------------------
create table if not exists public.sos_morning_reservations (
    id          uuid primary key default gen_random_uuid(),
    user_id     uuid not null default auth.uid(),
    phone       text not null,
    category    text,
    region      text,
    note        text,
    status      text not null default 'waiting' check (status in ('waiting', 'done', 'cancelled')),
    admin_note  text,
    created_at  timestamptz not null default now(),
    handled_at  timestamptz
);
create index if not exists sos_morning_reservations_status_idx on public.sos_morning_reservations (status, created_at);
alter table public.sos_morning_reservations enable row level security;
drop policy if exists "own insert sos_morning_reservations" on public.sos_morning_reservations;
create policy "own insert sos_morning_reservations" on public.sos_morning_reservations for insert
    with check (auth.uid() is not null and user_id = auth.uid());
drop policy if exists "own read sos_morning_reservations" on public.sos_morning_reservations;
create policy "own read sos_morning_reservations" on public.sos_morning_reservations for select
    using (user_id = auth.uid() or public.is_admin());
drop policy if exists "admin update sos_morning_reservations" on public.sos_morning_reservations;
create policy "admin update sos_morning_reservations" on public.sos_morning_reservations for update
    using (public.is_admin()) with check (public.is_admin());

-- 관리자: 월 정산용 연장 내역 (전문가별 합계)
create or replace function public.admin_sos_extension_summary(p_month date default date_trunc('month', now())::date)
returns table (sos_expert_id uuid, expert_name text, ext_count bigint, ext_amount bigint)
language sql stable security definer set search_path = public as $$
    select e.sos_expert_id, max(x.name)::text, count(*), sum(e.amount)::bigint
      from sos_session_extensions e
      left join sos_experts x on x.id = e.sos_expert_id
     where public.is_admin()
       and e.created_at >= (p_month::timestamp at time zone 'Asia/Seoul')
       and e.created_at <  ((p_month + interval '1 month')::timestamp at time zone 'Asia/Seoul')
     group by e.sos_expert_id
$$;

commit;

-- =====================================================================
-- 점검 결과: 아직 '3만 원'(30000)이 직접 적혀 있는 서버 함수 목록
--   · 줄이 없으면 끝입니다.
--   · 줄이 있으면 그 함수가 아직 옛 금액을 쓰고 있을 수 있으니 결과를 그대로 보내 주세요.
--     (create_charge_order 가 나오면 충전 금액 4만/6만/10만 원이 막혀 있을 수 있습니다)
-- =====================================================================
select p.proname as 함수이름,
       pg_get_function_identity_arguments(p.oid) as 인자,
       substring(p.prosrc from greatest(1, position('30000' in p.prosrc) - 120) for 260) as 해당부분
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
 where n.nspname = 'public'
   and p.prosrc like '%30000%'
 order by p.proname;
