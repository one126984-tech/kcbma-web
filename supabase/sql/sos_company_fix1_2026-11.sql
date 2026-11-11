-- =====================================================================
-- 회원사 후속 수정 1 (2026-11)
--   1) 중복 가입 막기: 같은 사업자등록번호(또는 같은 담당자 계정)로 이미 신청·가입된 회원사가 있으면
--      가입 신청을 막고 "이미 가입된 회원사" 안내 (반려된 회사는 제외)
--   2) 회원사 번호: 협회가 승인하면 'SOS-0001' 같은 번호가 붙음 (관리자·회원사 센터에 표시)
--   3) 관리자 화면: 담당자 로그인 아이디(이메일), 중복 의심 표시, 접수 기록이 없는 회원사 삭제
--
-- sos_company_2026-11.sql 을 먼저 실행한 뒤 실행하세요.
-- =====================================================================

begin;

-- ---------------------------------------------------------------------
-- 1. 회원사 번호
-- ---------------------------------------------------------------------
create sequence if not exists public.sos_company_no_seq;
alter table public.sos_companies add column if not exists member_no int unique;

-- 이미 승인된 회원사에 번호 채우기 (승인 순서대로)
update public.sos_companies c
   set member_no = nextval('public.sos_company_no_seq')
  from (select id from public.sos_companies where status = 'active' and member_no is null order by coalesce(approved_at, created_at)) x
 where c.id = x.id;

-- ---------------------------------------------------------------------
-- 2. 가입 신청: 중복 막기
-- ---------------------------------------------------------------------
create or replace function public.sos_company_apply(p_name text, p_biz_no text, p_manager_name text, p_manager_phone text,
                                                   p_tax_email text default null)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
    v_id   uuid;
    v_biz  text := regexp_replace(coalesce(p_biz_no, ''), '[^0-9]', '', 'g');
    v_dup  sos_companies%rowtype;
begin
    if auth.uid() is null then raise exception 'LOGIN_REQUIRED'; end if;
    if coalesce(trim(p_name), '') = '' or coalesce(trim(p_manager_name), '') = ''
       or length(regexp_replace(coalesce(p_manager_phone, ''), '[^0-9]', '', 'g')) < 9 then raise exception 'BAD_INPUT'; end if;
    if exists (select 1 from sos_company_members where user_id = auth.uid() and status <> 'removed') then
        raise exception 'ALREADY_MEMBER';
    end if;
    if v_biz <> '' then
        select * into v_dup from sos_companies
         where status <> 'rejected' and regexp_replace(coalesce(biz_no, ''), '[^0-9]', '', 'g') = v_biz
         order by created_at limit 1;
        if found then
            raise exception 'DUPLICATE_BIZ|%|%', v_dup.name, coalesce(v_dup.manager_name, '');
        end if;
    end if;
    insert into sos_companies (name, biz_no, manager_user_id, manager_name, manager_phone, tax_email)
    values (trim(p_name), nullif(trim(p_biz_no), ''), auth.uid(), trim(p_manager_name), trim(p_manager_phone),
            nullif(trim(p_tax_email), ''))
    returning id into v_id;
    insert into sos_company_members (company_id, user_id, name, phone, role, status, decided_at)
    values (v_id, auth.uid(), trim(p_manager_name), trim(p_manager_phone), 'manager', 'active', now());
    return sos_company_me();
end $$;

-- ---------------------------------------------------------------------
-- 3. 승인할 때 회원사 번호 부여
-- ---------------------------------------------------------------------
create or replace function public.admin_sos_company_update(p_company_id uuid, p_status text, p_monthly_limit int, p_note text)
returns void language plpgsql security definer set search_path = public as $$
begin
    if not public.is_admin() then raise exception 'ADMIN_ONLY'; end if;
    if p_status not in ('pending', 'active', 'suspended', 'rejected') then raise exception 'BAD_STATUS'; end if;
    update sos_companies
       set status = p_status,
           approved_at = case when p_status = 'active' and approved_at is null then now() else approved_at end,
           member_no = case when p_status = 'active' and member_no is null then nextval('public.sos_company_no_seq') else member_no end,
           monthly_limit = greatest(0, coalesce(p_monthly_limit, monthly_limit)),
           admin_note = p_note
     where id = p_company_id;
    if not found then raise exception 'NOT_FOUND'; end if;
    perform _sos_company_sync_company(p_company_id);
end $$;

-- ---------------------------------------------------------------------
-- 4. 관리자: 회원사 삭제 (중복·잘못된 신청 정리용, 접수 기록이 있으면 삭제 불가 → 반려로)
-- ---------------------------------------------------------------------
create or replace function public.admin_sos_company_delete(p_company_id uuid)
returns void language plpgsql security definer set search_path = public as $$
declare r record;
begin
    if not public.is_admin() then raise exception 'ADMIN_ONLY'; end if;
    if exists (select 1 from sos_requests where company_id = p_company_id) then raise exception 'HAS_REQUESTS'; end if;
    -- 연결된 직원들의 후불 표시를 먼저 끔
    update sos_company_members set status = 'removed' where company_id = p_company_id;
    for r in select user_id from sos_company_members where company_id = p_company_id loop
        perform _sos_company_sync_user(r.user_id);
    end loop;
    delete from sos_companies where id = p_company_id;
    if not found then raise exception 'NOT_FOUND'; end if;
end $$;
grant execute on function public.admin_sos_company_delete(uuid) to authenticated;

-- ---------------------------------------------------------------------
-- 5. 화면용 조회에 회원사 번호·담당자 아이디·중복 의심 추가
-- ---------------------------------------------------------------------
create or replace function public.sos_company_me()
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare
    m sos_company_members%rowtype;
    c sos_companies%rowtype;
    v_is_manager boolean;
begin
    if auth.uid() is null then return null; end if;
    select * into m from sos_company_members
     where user_id = auth.uid() and status <> 'removed'
     order by (status = 'active') desc, (role = 'manager') desc, created_at desc limit 1;
    if not found then return jsonb_build_object('member', null); end if;
    select * into c from sos_companies where id = m.company_id;
    v_is_manager := (m.role = 'manager' and m.status = 'active');

    return jsonb_build_object(
        'server_now', now(),
        'member', jsonb_build_object('id', m.id, 'role', m.role, 'status', m.status, 'name', m.name, 'phone', m.phone,
                                     'joined_building_id', m.joined_building_id),
        'company', jsonb_build_object('id', c.id, 'name', c.name, 'status', c.status, 'member_no', c.member_no,
                                      'member_code', case when c.member_no is not null then 'SOS-' || lpad(c.member_no::text, 4, '0') end,
                                      'card_label', c.card_label, 'card_registered', c.card_customer_uid is not null,
                                      'ready', _sos_company_ready(c), 'monthly_limit', c.monthly_limit,
                                      'biz_no', case when v_is_manager then c.biz_no end,
                                      'tax_email', case when v_is_manager then c.tax_email end,
                                      'manager_name', c.manager_name, 'manager_phone', c.manager_phone),
        'buildings', case when m.status = 'active' then coalesce((
            select jsonb_agg(jsonb_build_object('id', b.id, 'name', b.name, 'address', b.address, 'address_detail', b.address_detail,
                                                'code', case when v_is_manager then b.code end, 'active', b.active) order by b.created_at)
              from sos_company_buildings b where b.company_id = c.id and (b.active or v_is_manager)), '[]'::jsonb) else '[]'::jsonb end,
        'members', case when v_is_manager then coalesce((
            select jsonb_agg(jsonb_build_object('id', x.id, 'name', x.name, 'phone', x.phone, 'role', x.role, 'status', x.status,
                                                'building', (select name from sos_company_buildings where id = x.joined_building_id),
                                                'created_at', x.created_at, 'is_me', x.user_id = auth.uid())
                             order by (x.status = 'pending') desc, x.created_at)
              from sos_company_members x where x.company_id = c.id and x.status <> 'removed'), '[]'::jsonb) end,
        'usage', case when v_is_manager then _sos_company_month_total(c.id, (now() at time zone 'Asia/Seoul')::date) end
    );
end $$;


create or replace function public.admin_sos_companies(p_month date default (now() at time zone 'Asia/Seoul')::date)
returns jsonb language plpgsql stable security definer set search_path = public as $$
begin
    if not public.is_admin() then raise exception 'ADMIN_ONLY'; end if;
    return coalesce((
        select jsonb_agg(jsonb_build_object(
                   'id', c.id, 'name', c.name, 'biz_no', c.biz_no, 'manager_name', c.manager_name, 'manager_phone', c.manager_phone,
                   'member_no', c.member_no,
                   'member_code', case when c.member_no is not null then 'SOS-' || lpad(c.member_no::text, 4, '0') end,
                   'manager_email', (select u.email from auth.users u where u.id = c.manager_user_id),
                   'request_count', (select count(*) from sos_requests r where r.company_id = c.id),
                   'duplicate_of', (select d.name || ' (' || to_char(d.created_at at time zone 'Asia/Seoul', 'MM/DD HH24:MI') || ' 신청)'
                                      from sos_companies d
                                     where d.id <> c.id and d.status <> 'rejected'
                                       and ((regexp_replace(coalesce(d.biz_no, ''), '[^0-9]', '', 'g') <> ''
                                             and regexp_replace(coalesce(d.biz_no, ''), '[^0-9]', '', 'g') = regexp_replace(coalesce(c.biz_no, ''), '[^0-9]', '', 'g'))
                                            or d.manager_user_id = c.manager_user_id)
                                     order by d.created_at limit 1),
                   'tax_email', c.tax_email, 'status', c.status, 'ready', _sos_company_ready(c),
                   'card_label', c.card_label, 'card_registered', c.card_customer_uid is not null, 'card_customer_uid', c.card_customer_uid,
                   'monthly_limit', c.monthly_limit,
                   'admin_note', c.admin_note, 'created_at', c.created_at, 'approved_at', c.approved_at,
                   'building_count', (select count(*) from sos_company_buildings b where b.company_id = c.id and b.active),
                   'member_count', (select count(*) from sos_company_members m where m.company_id = c.id and m.status = 'active'),
                   'pending_count', (select count(*) from sos_company_members m where m.company_id = c.id and m.status = 'pending'),
                   'usage', _sos_company_month_total(c.id, p_month),
                   'invoice', (select to_jsonb(i) from sos_company_invoices i where i.company_id = c.id and i.month = date_trunc('month', p_month)::date))
               order by (c.status = 'pending') desc, c.created_at desc)
          from sos_companies c
    ), '[]'::jsonb);
end $$;


commit;
