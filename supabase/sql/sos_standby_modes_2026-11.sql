-- =====================================================================
-- SOS 전문가 대기 상태 선택 (2026-11)
--   상태(하나만): live = 🟢 바로 받기 / notify = 🔔 알림 오면 응답(3분) / away = ☕ 자리 비움(15·30·60분)
--   대기 끝나는 시각(standby_until) 필수 → 지나면 자동으로 목록에서 빠짐
--   상담 세션 중인 전문가는 요청자의 '대기 중 전문가' 목록에서 빠짐
--
-- 기존 함수 5개(list_open_sos_requests, list_standby_experts_for_request, set_my_standby,
-- sos_checkin, sos_expert_presence, sos_send_call_invites)는 이름·입출력은 그대로 두고
-- '대기 중' 판단만 새 기준으로 바꿉니다. (예전 방식으로 대기 중인 전문가도 그대로 동작)
-- 먼저 sos_call_session_2026-11.sql 이 실행되어 있어야 합니다.
-- =====================================================================

begin;

-- ---------------------------------------------------------------------
-- 1. 새 컬럼
-- ---------------------------------------------------------------------
alter table public.sos_experts add column if not exists standby_mode   text;          -- live / notify / away
alter table public.sos_experts add column if not exists standby_until  timestamptz;   -- 대기 끝나는 시각 (null = 예전 방식)
alter table public.sos_experts add column if not exists away_until     timestamptz;   -- 자리 비움 끝나는 시각
alter table public.sos_experts add column if not exists away_prev_mode text;          -- 자리 비움 전 상태

do $$ begin
    alter table public.sos_experts add constraint sos_experts_standby_mode_chk
        check (standby_mode is null or standby_mode in ('live', 'notify', 'away'));
exception when duplicate_object then null; end $$;

-- ---------------------------------------------------------------------
-- 2. 지금 이 전문가의 실제 상태
--    live / notify = 요청을 받을 수 있음, null = 받을 수 없음(대기 안 함·시간 끝남·자리 비움 중)
-- ---------------------------------------------------------------------
create or replace function public.sos_expert_mode_now(e public.sos_experts) returns text
language sql stable as $$
    select case
        when not coalesce(e.is_active, false) or not coalesce(e.is_standby, false) then null
        when e.standby_until is not null and e.standby_until <= now() then null
        when e.standby_mode = 'away' and (e.away_until is null or e.away_until > now()) then null
        when e.standby_mode = 'away' then coalesce(e.away_prev_mode, 'live')
        when e.standby_mode = 'notify' then 'notify'
        else 'live'
    end
$$;

-- 대기를 켜 둔 상태인지 (자리 비움 포함, 끝나는 시각 전) — 전문가 본인 화면용
create or replace function public.sos_expert_standby_alive(e public.sos_experts) returns boolean
language sql stable as $$
    select coalesce(e.is_active, false) and coalesce(e.is_standby, false)
       and (e.standby_until is null or e.standby_until > now())
$$;

-- ---------------------------------------------------------------------
-- 3. 기존 함수 교체 (입출력 동일)
-- ---------------------------------------------------------------------
-- 3-1. 전문가 요청현황 게시판: 대기 시간이 끝났으면 비움 (자리 비움 중에는 계속 보임)
CREATE OR REPLACE FUNCTION public.list_open_sos_requests()
 RETURNS TABLE(id uuid, category text, region_short text, service_type text, created_at timestamp with time zone, my_offer text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select r.id,
         r.category,
         array_to_string((string_to_array(coalesce(r.region, ''), ' '))[1:3], ' '),
         r.service_type,
         r.created_at,
         o.offer_type
    from public.sos_requests r
    join public.sos_experts e
      on e.user_id = auth.uid()
     and public.sos_expert_standby_alive(e)
     and public.expert_in_hours(e.avail_from, e.avail_to)
    left join public.sos_offers o
      on o.request_id = r.id and o.expert_id = e.id and o.status = 'offered'
   where r.status = '대기중'
     and r.created_at > now() - interval '12 hours'
     and (r.service_type = 'phone' or e.service_level = 'dispatch')
     and public.sos_category_match(r.category, e.categories)
     and (r.service_type = 'phone' or public.sos_region_match(r.region, e.region_main))
     and not exists (select 1 from public.sos_offers x
                      where x.request_id = r.id and x.expert_id = e.id and x.status = 'released')
   order by r.created_at desc;
$function$;

-- 3-2. 요청자 화면 '대기 중인 등록 전문가': 받을 수 있는 상태(live/notify)만, 상담 중인 전문가 제외
CREATE OR REPLACE FUNCTION public.list_standby_experts_for_request(p_request_id uuid)
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select coalesce(jsonb_agg(
           jsonb_build_object(
             'id', e.id, 'name', e.name, 'category', e.category, 'categories', e.categories,
             'intro', e.intro, 'region_main', e.region_main, 'region_sub', e.region_sub,
             'service_level', e.service_level, 'avg_rating', e.avg_rating,
             'total_cases', e.total_cases, 'provides_photo', e.provides_photo,
             'avail_from', e.avail_from, 'avail_to', e.avail_to,
             'standby_mode', public.sos_expert_mode_now(e), 'standby_until', e.standby_until)
           order by case when public.sos_category_match(split_part(r.category, ',', 1), e.categories) then 0 else 1 end,
                    e.avg_rating desc nulls last, e.total_cases desc
         ), '[]'::jsonb)
    from public.sos_requests r
    join public.sos_experts e on true
   where r.id = p_request_id and r.user_id = auth.uid() and r.status = '대기중'
     and public.sos_expert_mode_now(e) is not null
     and e.phone is not null and e.phone <> ''
     and public.expert_in_hours(e.avail_from, e.avail_to)
     and (r.service_type = 'phone' or (e.can_dispatch and e.service_level = 'dispatch'))
     and public.sos_category_match(r.category, e.categories)
     and (r.service_type = 'phone' or public.sos_region_match(r.region, e.region_main))
     and not exists (select 1 from public.sos_offers o
                      where o.request_id = r.id and o.expert_id = e.id and o.status = 'released')
     and not exists (select 1 from public.sos_sessions s
                      where s.sos_expert_id = e.id and s.kind = 'main'
                        and s.closed_at is null and s.expires_at > now());
$function$;

-- 3-3. 대기 켜기/끄기: 끌 때 상태·끝나는 시각도 정리
CREATE OR REPLACE FUNCTION public.set_my_standby(p_on boolean, p_level text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_uid uuid := auth.uid();
  e     public.sos_experts%rowtype;
begin
  if v_uid is null then raise exception 'LOGIN_REQUIRED'; end if;
  if p_level not in ('phone','dispatch') then raise exception 'INVALID_LEVEL'; end if;

  select * into e from public.sos_experts
   where user_id = v_uid and coalesce(is_active, false) limit 1;
  if not found then raise exception 'NOT_EXPERT'; end if;

  if p_level = 'dispatch' and not e.can_dispatch then raise exception 'LEVEL_NOT_ALLOWED'; end if;

  update public.sos_experts
     set is_standby = p_on,
         service_level = p_level,
         last_active_at = now(),
         standby_mode   = case when p_on then standby_mode   else null end,
         standby_until  = case when p_on then standby_until  else null end,
         away_until     = case when p_on then away_until     else null end,
         away_prev_mode = case when p_on then away_prev_mode else null end
   where id = e.id;
end;
$function$;

-- 3-4. 순위 올리기: '바로 받기' 상태에서만
CREATE OR REPLACE FUNCTION public.sos_checkin()
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if auth.uid() is null then raise exception 'LOGIN_REQUIRED'; end if;

  update sos_experts
     set last_checkin_at = now()
   where user_id = auth.uid()
     and public.sos_expert_mode_now(sos_experts) = 'live'
     and (last_checkin_at is null or last_checkin_at <= now() - interval '10 minutes');

  return found;
end;
$function$;

-- 3-5. 요청자 화면의 대기 정보: '알림 오면 응답'은 contact_mode='text'로, 확인 시각 없이 전달
CREATE OR REPLACE FUNCTION public.sos_expert_presence(p_request_id uuid)
 RETURNS TABLE(expert_id uuid, last_checkin_at timestamp with time zone, contact_mode text, invited_at timestamp with time zone)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if not exists (select 1 from sos_requests r where r.id = p_request_id and r.user_id = auth.uid()) then
    raise exception 'FORBIDDEN';
  end if;
  return query
    select e.id,
           case when public.sos_expert_mode_now(e) = 'notify' then null else e.last_checkin_at end,
           case when public.sos_expert_mode_now(e) = 'notify' then 'text'
                when e.standby_until is not null then 'call'
                else e.contact_mode end,
           n.created_at
      from sos_experts e
      left join sos_expert_notices n
        on n.expert_id = e.id and n.request_id = p_request_id and n.kind = 'invite'
     where public.sos_expert_mode_now(e) is not null;
end;
$function$;

-- 3-6. 콜 문자: 받을 수 있는 상태(live/notify)인 전문가에게만
CREATE OR REPLACE FUNCTION public.sos_send_call_invites(p_request_id uuid, p_expert_ids uuid[])
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_req   sos_requests%rowtype;
  v_ids   uuid[];
  v_prev  int;
  v_new   int;
  v_ins   int;
begin
  if auth.uid() is null then raise exception 'LOGIN_REQUIRED'; end if;
  select * into v_req from sos_requests where id = p_request_id and user_id = auth.uid();
  if not found then raise exception 'FORBIDDEN'; end if;
  if v_req.status <> '대기중' then raise exception 'REQUEST_CLOSED'; end if;

  select coalesce(array_agg(distinct x), '{}') into v_ids from unnest(p_expert_ids) x;
  if array_length(v_ids, 1) is null then raise exception 'NO_TARGET'; end if;
  if array_length(v_ids, 1) > 3 then raise exception 'INVITE_LIMIT_ONCE'; end if;

  select count(*) into v_prev from sos_expert_notices where request_id = p_request_id and kind = 'invite';
  select count(*) into v_new from unnest(v_ids) x
   where not exists (select 1 from sos_expert_notices n where n.request_id = p_request_id and n.expert_id = x and n.kind = 'invite');
  if v_prev + v_new > 6 then raise exception 'INVITE_LIMIT_TOTAL'; end if;

  insert into sos_expert_notices (request_id, expert_id, kind)
  select p_request_id, e.id, 'invite'
    from sos_experts e
   where e.id = any(v_ids)
     and public.sos_expert_mode_now(e) is not null
     and e.phone is not null and e.phone <> ''
     and public.expert_in_hours(e.avail_from, e.avail_to)
     and (v_req.service_type = 'phone' or (e.can_dispatch and e.service_level = 'dispatch'))
     and public.sos_category_match(v_req.category, e.categories)
     and (v_req.service_type = 'phone' or public.sos_region_match(v_req.region, e.region_main))
  on conflict (request_id, expert_id, kind) do nothing;
  get diagnostics v_ins = row_count;
  if v_ins = 0 and v_new > 0 then raise exception 'NO_VALID_TARGET'; end if;
  return v_ins;
end;
$function$;

-- ---------------------------------------------------------------------
-- 4. 새 함수 (전문가 본인)
-- ---------------------------------------------------------------------
-- 내 대기 상태
create or replace function public.sos_my_standby()
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare e sos_experts%rowtype;
begin
    select * into e from sos_experts where user_id = auth.uid() and coalesce(is_active, false) limit 1;
    if not found then return null; end if;
    return jsonb_build_object(
        'server_now', now(),
        'alive', sos_expert_standby_alive(e),
        'mode', sos_expert_mode_now(e),
        'raw_mode', e.standby_mode,
        'standby_until', e.standby_until,
        'away_until', e.away_until,
        'away_prev_mode', e.away_prev_mode,
        'last_checkin_at', e.last_checkin_at
    );
end $$;

-- 상태 바꾸기
--   p_mode = 'live' | 'notify'  : 대기 시작 또는 상태 변경 (p_until: 끝나는 시각, 처음 시작할 때 필수)
--            'away'             : 자리 비움 (p_away_minutes: 15·30·60)
--            'back'             : 자리 비움에서 바로 복귀
--            'extend'           : 끝나는 시각만 바꾸기 (p_until)
create or replace function public.sos_set_standby_mode(p_mode text, p_until timestamptz default null, p_away_minutes int default null)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
    e sos_experts%rowtype;
    v_now_mode text;
begin
    if auth.uid() is null then raise exception 'LOGIN_REQUIRED'; end if;
    select * into e from sos_experts where user_id = auth.uid() and coalesce(is_active, false) limit 1;
    if not found then raise exception 'NOT_EXPERT'; end if;
    v_now_mode := sos_expert_mode_now(e);

    if p_until is not null and (p_until <= now() + interval '4 minutes' or p_until > now() + interval '24 hours') then
        raise exception 'BAD_UNTIL';
    end if;

    if p_mode in ('live', 'notify') then
        if p_until is null and (e.standby_until is null or e.standby_until <= now()) then raise exception 'BAD_UNTIL'; end if;
        update sos_experts
           set is_standby = true,
               standby_mode = p_mode,
               standby_until = coalesce(p_until, standby_until),
               away_until = null, away_prev_mode = null,
               last_active_at = now(),
               last_checkin_at = case when p_mode = 'live' then now() else last_checkin_at end
         where id = e.id;

    elsif p_mode = 'away' then
        if not sos_expert_standby_alive(e) then raise exception 'NOT_STANDBY'; end if;
        if p_away_minutes not in (15, 30, 60) then raise exception 'BAD_AWAY'; end if;
        update sos_experts
           set away_prev_mode = case when e.standby_mode = 'away' then coalesce(e.away_prev_mode, 'live')
                                     else coalesce(v_now_mode, e.standby_mode, 'live') end,
               standby_mode = 'away',
               away_until = case when e.standby_until is null then now() + make_interval(mins => p_away_minutes)
                                 else least(now() + make_interval(mins => p_away_minutes), e.standby_until) end
         where id = e.id;

    elsif p_mode = 'back' then
        if e.standby_mode = 'away' then
            update sos_experts
               set standby_mode = coalesce(away_prev_mode, 'live'),
                   away_until = null, away_prev_mode = null,
                   last_checkin_at = case when coalesce(away_prev_mode, 'live') = 'live' then now() else last_checkin_at end
             where id = e.id;
        end if;

    elsif p_mode = 'extend' then
        if p_until is null then raise exception 'BAD_UNTIL'; end if;
        if not sos_expert_standby_alive(e) then raise exception 'NOT_STANDBY'; end if;
        update sos_experts set standby_until = p_until where id = e.id;

    else
        raise exception 'BAD_MODE';
    end if;

    return sos_my_standby();
end $$;

-- 나에게 온 콜 문자 (최근 30분, 아직 대기중인 접수)
create or replace function public.sos_my_invites()
returns table(request_id uuid, invited_at timestamptz)
language sql stable security definer set search_path = public as $$
    select n.request_id, n.created_at
      from sos_expert_notices n
      join sos_experts e on e.id = n.expert_id and e.user_id = auth.uid()
      join sos_requests r on r.id = n.request_id and r.status = '대기중'
     where n.kind = 'invite' and n.created_at > now() - interval '30 minutes'
     order by n.created_at desc
$$;

grant execute on function public.sos_my_standby()                          to authenticated;
grant execute on function public.sos_set_standby_mode(text, timestamptz, int) to authenticated;
grant execute on function public.sos_my_invites()                          to authenticated;

commit;
