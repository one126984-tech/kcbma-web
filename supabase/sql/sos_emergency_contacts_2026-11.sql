-- =====================================================================
-- SOS 비상 연락 명부 (2026-11)
--   · 전문가가 [비상 연락 허용]을 켜 두면 대기 중이 아닐 때도 요청자 화면 '📇 비상 연락 가능' 묶음에 표시
--     (연락받지 않을 시간은 전문가가 정함, 상담 중이면 제외)
--   · 요청자는 이 묶음에서 전화번호를 볼 수 없고 콜 문자만 보낼 수 있음
--   · 콜 문자를 받은 전문가가 [응답하기]를 누르면 30분짜리 '알림 오면 응답' 대기가 자동으로 시작되고
--     요청자 화면 '응답한 전문가'에 올라감 → 이후 선택·결제는 기존 흐름 그대로
--
-- 먼저 sos_call_session_2026-11.sql, sos_standby_modes_2026-11.sql 이 실행되어 있어야 합니다.
-- 기존 함수 중 list_open_sos_requests, sos_expert_presence, sos_send_call_invites 세 개의
-- 조건만 바꿉니다 (이름·입출력 그대로).
-- =====================================================================

begin;

-- ---------------------------------------------------------------------
-- 1. 새 컬럼
-- ---------------------------------------------------------------------
alter table public.sos_experts add column if not exists emergency_contact    boolean not null default false;
alter table public.sos_experts add column if not exists emergency_quiet_from time;   -- 연락받지 않을 시간 시작 (예: 22:00)
alter table public.sos_experts add column if not exists emergency_quiet_to   time;   -- 연락받지 않을 시간 끝 (예: 07:00)

-- ---------------------------------------------------------------------
-- 2. 지금 비상 연락 명부에 올라갈 수 있는가
--    (대기 중이라 이미 받을 수 있는 사람은 제외 → 대기 목록에 이미 나옴)
-- ---------------------------------------------------------------------
create or replace function public.sos_expert_emergency_ok(e public.sos_experts) returns boolean
language sql stable as $$
    select coalesce(e.is_active, false)
       and coalesce(e.emergency_contact, false)
       and e.phone is not null and e.phone <> ''
       -- 대기를 켜 두지 않았거나, 켜 두었어도 서비스 시간 밖이면 비상 연락 대상 (자리 비움 중은 제외)
       and (not public.sos_expert_standby_alive(e)
            or (public.sos_expert_mode_now(e) is not null and not public.expert_in_hours(e.avail_from, e.avail_to)))
       and not (e.emergency_quiet_from is not null and e.emergency_quiet_to is not null
                and e.emergency_quiet_from <> e.emergency_quiet_to
                and public.expert_in_hours(e.emergency_quiet_from, e.emergency_quiet_to))
       and not exists (select 1 from public.sos_sessions s
                        where s.sos_expert_id = e.id and s.kind = 'main'
                          and s.closed_at is null and s.expires_at > now())
$$;

-- ---------------------------------------------------------------------
-- 3. 요청자 화면: 비상 연락 가능 전문가 (전화번호 없음)
-- ---------------------------------------------------------------------
create or replace function public.list_emergency_experts_for_request(p_request_id uuid)
returns jsonb language sql stable security definer set search_path = public as $$
  select coalesce(jsonb_agg(
           jsonb_build_object(
             'id', e.id, 'name', e.name, 'category', e.category, 'categories', e.categories,
             'intro', e.intro, 'region_main', e.region_main, 'region_sub', e.region_sub,
             'service_level', e.service_level, 'avg_rating', e.avg_rating,
             'total_cases', e.total_cases, 'provides_photo', e.provides_photo,
             'avail_from', e.avail_from, 'avail_to', e.avail_to, 'emergency', true)
           order by case when public.sos_category_match(split_part(r.category, ',', 1), e.categories) then 0 else 1 end,
                    e.avg_rating desc nulls last, e.total_cases desc
         ), '[]'::jsonb)
    from public.sos_requests r
    join public.sos_experts e on true
   where r.id = p_request_id and r.user_id = auth.uid() and r.status = '대기중'
     and r.service_type = 'phone'
     and public.sos_expert_emergency_ok(e)
     and public.sos_category_match(r.category, e.categories)
     and not exists (select 1 from public.sos_offers o
                      where o.request_id = r.id and o.expert_id = e.id and o.status = 'released');
$$;

-- ---------------------------------------------------------------------
-- 4. 기존 함수 조건 변경
-- ---------------------------------------------------------------------
-- 4-1. 전문가 게시판: 서비스 시간 밖이어도 콜 문자를 받은 요청은 보이게
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
    left join public.sos_offers o
      on o.request_id = r.id and o.expert_id = e.id and o.status = 'offered'
   where r.status = '대기중'
     and r.created_at > now() - interval '12 hours'
     and (public.expert_in_hours(e.avail_from, e.avail_to)
          or exists (select 1 from public.sos_expert_notices n
                      where n.request_id = r.id and n.expert_id = e.id and n.kind = 'invite'))
     and (r.service_type = 'phone' or e.service_level = 'dispatch')
     and public.sos_category_match(r.category, e.categories)
     and (r.service_type = 'phone' or public.sos_region_match(r.region, e.region_main))
     and not exists (select 1 from public.sos_offers x
                      where x.request_id = r.id and x.expert_id = e.id and x.status = 'released')
   order by r.created_at desc;
$function$;

-- 4-2. 요청자 화면의 대기 정보: 비상 연락 전문가도 포함 (contact_mode = 'emergency')
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
           case when public.sos_expert_mode_now(e) = 'live' or (public.sos_expert_mode_now(e) is not null and e.standby_until is null)
                then e.last_checkin_at end,
           case when public.sos_expert_mode_now(e) is null then 'emergency'
                when public.sos_expert_mode_now(e) = 'notify' then 'text'
                when e.standby_until is not null then 'call'
                else e.contact_mode end,
           n.created_at
      from sos_experts e
      left join sos_expert_notices n
        on n.expert_id = e.id and n.request_id = p_request_id and n.kind = 'invite'
     where public.sos_expert_mode_now(e) is not null
        or public.sos_expert_emergency_ok(e)
        or n.created_at is not null;
end;
$function$;

-- 4-3. 콜 문자: 대기 중(서비스 시간 안)이거나 비상 연락 가능한 전문가에게
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
     and e.phone is not null and e.phone <> ''
     and (
           (public.sos_expert_mode_now(e) is not null and public.expert_in_hours(e.avail_from, e.avail_to)
            and (v_req.service_type = 'phone' or (e.can_dispatch and e.service_level = 'dispatch'))
            and (v_req.service_type = 'phone' or public.sos_region_match(v_req.region, e.region_main)))
        or (v_req.service_type = 'phone' and public.sos_expert_emergency_ok(e))
         )
     and public.sos_category_match(v_req.category, e.categories)
  on conflict (request_id, expert_id, kind) do nothing;
  get diagnostics v_ins = row_count;
  if v_ins = 0 and v_new > 0 then raise exception 'NO_VALID_TARGET'; end if;
  return v_ins;
end;
$function$;

-- ---------------------------------------------------------------------
-- 5. 전문가용 새 함수
-- ---------------------------------------------------------------------
-- 비상 연락 허용 켜기/끄기 + 연락받지 않을 시간
create or replace function public.sos_set_emergency_contact(p_on boolean, p_quiet_from time default null, p_quiet_to time default null)
returns void language plpgsql security definer set search_path = public as $$
begin
    if auth.uid() is null then raise exception 'LOGIN_REQUIRED'; end if;
    update sos_experts
       set emergency_contact = coalesce(p_on, false),
           emergency_quiet_from = p_quiet_from,
           emergency_quiet_to = p_quiet_to
     where user_id = auth.uid() and coalesce(is_active, false);
    if not found then raise exception 'NOT_EXPERT'; end if;
end $$;

-- 콜 문자를 받은 요청에 바로 응답 (대기 중이 아니어도, 서비스 시간 밖이어도)
--   → 30분짜리 '알림 오면 응답' 대기를 켜고, 이 요청에 신청한 것으로 처리
create or replace function public.sos_invite_respond(p_request_id uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
    e sos_experts%rowtype;
    r sos_requests%rowtype;
begin
    if auth.uid() is null then raise exception 'LOGIN_REQUIRED'; end if;
    select * into e from sos_experts where user_id = auth.uid() and coalesce(is_active, false) limit 1;
    if not found then raise exception 'NOT_EXPERT'; end if;
    if e.phone is null or e.phone = '' then raise exception 'NO_PHONE'; end if;

    select * into r from sos_requests where id = p_request_id;
    if not found or r.status <> '대기중' then raise exception 'REQUEST_CLOSED'; end if;
    if r.service_type <> 'phone' then raise exception 'LEVEL_NOT_ALLOWED'; end if;
    if not exists (select 1 from sos_expert_notices n
                    where n.request_id = p_request_id and n.expert_id = e.id and n.kind = 'invite'
                      and n.created_at > now() - interval '30 minutes') then
        raise exception 'NOT_INVITED';
    end if;
    if not public.sos_category_match(r.category, e.categories) then raise exception 'CATEGORY_MISMATCH'; end if;
    if exists (select 1 from sos_offers where request_id = p_request_id and expert_id = e.id and status = 'released') then
        raise exception 'EXPERT_RELEASED';
    end if;
    if exists (select 1 from sos_sessions s where s.sos_expert_id = e.id and s.kind = 'main'
                 and s.request_id <> p_request_id and s.closed_at is null and s.expires_at > now()) then
        raise exception 'EXPERT_BUSY';
    end if;

    -- 대기 중이 아니면 30분 '알림 오면 응답' 대기 시작 (이미 대기 중이면 상태는 그대로, 끝나는 시각만 최소 30분 보장)
    update sos_experts
       set is_standby = true,
           service_level = coalesce(service_level, 'phone'),
           standby_mode = case when public.sos_expert_standby_alive(e) and coalesce(standby_mode, '') <> 'away' then standby_mode else 'notify' end,
           standby_until = greatest(coalesce(case when public.sos_expert_standby_alive(e) then standby_until end, now()), now() + interval '30 minutes'),
           away_until = null, away_prev_mode = null,
           last_active_at = now()
     where id = e.id;

    insert into sos_offers (request_id, expert_id, offer_type)
    values (p_request_id, e.id, 'phone')
    on conflict (request_id, expert_id) do update
       set offer_type = excluded.offer_type, status = 'offered'
     where sos_offers.status in ('offered', 'withdrawn');

    return sos_my_standby();
end $$;

grant execute on function public.list_emergency_experts_for_request(uuid)        to authenticated;
grant execute on function public.sos_set_emergency_contact(boolean, time, time)   to authenticated;
grant execute on function public.sos_invite_respond(uuid)                         to authenticated;

commit;
