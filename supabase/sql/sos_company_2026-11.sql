-- =====================================================================
-- 긴급 SOS 회원사(B2B) 기능 (2026-11)
--   · 회사 담당자: 회원사 가입 신청 → 카드 등록 → 관리 건물 등록(건물마다 6자리 건물 코드 발급)
--   · 직원: 자기 개인 계정으로 로그인 → 건물 코드 입력 → 담당자 승인 → 회원사 후불로 SOS 이용
--   · 방재실 등 공용 휴대폰: 담당자가 '공용 계정'으로 승인 → 접수할 때 호출자 이름·연락처를 반드시 입력
--   · 협회 승인 + 카드 등록(필수)이 끝난 회원사의 승인 직원은 자동으로 후불(is_postpaid_member)
--     → 기존 접수·번호 공개·종료·연장 흐름이 그대로 결제 없이 진행됨
--   · 회원사 직원이 접수하면 접수 건에 회사·건물·호출자가 자동으로 붙음 → 회사별 월 이용 내역·청구
--   · 청구: 매월 초 전월 이용분을 등록 카드로 청구 (카드 등록 필수). 월 회비 없음(이용한 만큼만)
--   · 월 이용 한도는 '알림용'(넘어도 긴급 접수는 막지 않음, 담당자·관리자 화면에 빨간 표시)
--
-- sos_refunds_2026-11.sql 까지 실행한 뒤 실행하세요.
-- Supabase SQL Editor에 통째로 붙여 넣고 Run 하세요. 맨 아래 '점검' 표를 보내 주세요.
-- =====================================================================

begin;

-- ---------------------------------------------------------------------
-- 1. 테이블
-- ---------------------------------------------------------------------
create table if not exists public.sos_companies (
    id                 uuid primary key default gen_random_uuid(),
    name               text not null,
    biz_no             text,                         -- 사업자등록번호
    manager_user_id    uuid not null,                -- 회사 담당자 계정
    manager_name       text,
    manager_phone      text,
    tax_email          text,                         -- 이용 내역서·영수증 받을 이메일
    status             text not null default 'pending' check (status in ('pending', 'active', 'suspended', 'rejected')),
    card_customer_uid  text,                         -- 포트원 빌링키 고객 번호 (카드번호는 보관하지 않음)
    card_label         text,                         -- 화면 표시용 (예: 신한카드 ****1234)
    card_registered_at timestamptz,
    monthly_limit      int not null default 500000,  -- 월 이용 한도 (알림용)
    admin_note         text,
    created_at         timestamptz not null default now(),
    approved_at        timestamptz
);
create index if not exists sos_companies_manager_idx on public.sos_companies (manager_user_id);

create table if not exists public.sos_company_buildings (
    id             uuid primary key default gen_random_uuid(),
    company_id     uuid not null references public.sos_companies(id) on delete cascade,
    name           text not null,
    address        text not null,
    address_detail text,
    code           text not null unique,             -- 6자리 건물 코드 (직원 연결용)
    active         boolean not null default true,
    created_at     timestamptz not null default now()
);
create index if not exists sos_company_buildings_company_idx on public.sos_company_buildings (company_id);

create table if not exists public.sos_company_members (
    id                 uuid primary key default gen_random_uuid(),
    company_id         uuid not null references public.sos_companies(id) on delete cascade,
    user_id            uuid not null,
    joined_building_id uuid references public.sos_company_buildings(id) on delete set null,
    name               text,
    phone              text,
    role               text not null default 'staff' check (role in ('manager', 'staff', 'shared')),
    status             text not null default 'pending' check (status in ('pending', 'active', 'removed')),
    last_building_id   uuid references public.sos_company_buildings(id) on delete set null,  -- 이번 접수에 쓸 건물
    last_caller_name   text,                          -- 공용 계정: 이번 호출자
    last_caller_phone  text,
    last_prepared_at   timestamptz,
    created_at         timestamptz not null default now(),
    decided_at         timestamptz,
    unique (company_id, user_id)
);
create index if not exists sos_company_members_user_idx on public.sos_company_members (user_id, status);

create table if not exists public.sos_company_invoices (
    id          uuid primary key default gen_random_uuid(),
    company_id  uuid not null references public.sos_companies(id) on delete cascade,
    month       date not null,                        -- 그달 1일
    amount      int  not null,
    status      text not null default 'unpaid' check (status in ('unpaid', 'paid', 'void')),
    method      text,                                 -- card (등록 카드 청구) / transfer (예외)
    memo        text,
    paid_at     timestamptz,
    created_at  timestamptz not null default now(),
    unique (company_id, month)
);

-- 접수 건에 회사·건물·호출자
alter table public.sos_requests add column if not exists company_id  uuid references public.sos_companies(id) on delete set null;
alter table public.sos_requests add column if not exists building_id uuid references public.sos_company_buildings(id) on delete set null;
alter table public.sos_requests add column if not exists caller_name  text;
alter table public.sos_requests add column if not exists caller_phone text;
create index if not exists sos_requests_company_idx on public.sos_requests (company_id, fee_charged_at);

-- 회원사 때문에 켜진 후불 표시인지 (직접 켠 후불 회원은 건드리지 않기 위함)
alter table public.user_profiles add column if not exists postpaid_by_company boolean not null default false;

-- 화면에서 직접 읽고 쓰지 못하게 막고, 아래 함수로만 다룹니다. 관리자만 직접 조회 가능.
alter table public.sos_companies         enable row level security;
alter table public.sos_company_buildings enable row level security;
alter table public.sos_company_members   enable row level security;
alter table public.sos_company_invoices  enable row level security;
drop policy if exists "admin all sos_companies" on public.sos_companies;
create policy "admin all sos_companies" on public.sos_companies for all using (public.is_admin()) with check (public.is_admin());
drop policy if exists "admin all sos_company_buildings" on public.sos_company_buildings;
create policy "admin all sos_company_buildings" on public.sos_company_buildings for all using (public.is_admin()) with check (public.is_admin());
drop policy if exists "admin all sos_company_members" on public.sos_company_members;
create policy "admin all sos_company_members" on public.sos_company_members for all using (public.is_admin()) with check (public.is_admin());
drop policy if exists "admin all sos_company_invoices" on public.sos_company_invoices;
create policy "admin all sos_company_invoices" on public.sos_company_invoices for all using (public.is_admin()) with check (public.is_admin());

-- ---------------------------------------------------------------------
-- 2. 내부 도우미
-- ---------------------------------------------------------------------
-- 회원사가 후불을 쓸 수 있는 상태인지 (협회 승인 + 카드 등록 필수)
create or replace function public._sos_company_ready(c public.sos_companies) returns boolean
language sql stable as $$
    select c.status = 'active' and c.card_customer_uid is not null
$$;

-- 이 사용자의 후불 표시를 회원사 상태에 맞춤
create or replace function public._sos_company_sync_user(p_user_id uuid) returns void
language plpgsql security definer set search_path = public as $$
declare v_ok boolean;
begin
    if p_user_id is null then return; end if;
    select exists (
        select 1 from sos_company_members m join sos_companies c on c.id = m.company_id
         where m.user_id = p_user_id and m.status = 'active' and _sos_company_ready(c)
    ) into v_ok;
    if v_ok then
        update user_profiles set is_postpaid_member = true, postpaid_by_company = true
         where id = p_user_id and not (coalesce(is_postpaid_member, false) and postpaid_by_company);
    else
        update user_profiles set is_postpaid_member = false, postpaid_by_company = false
         where id = p_user_id and postpaid_by_company;
    end if;
end $$;

create or replace function public._sos_company_sync_company(p_company_id uuid) returns void
language plpgsql security definer set search_path = public as $$
declare r record;
begin
    for r in select user_id from sos_company_members where company_id = p_company_id loop
        perform _sos_company_sync_user(r.user_id);
    end loop;
end $$;

-- 내가 담당자인 회사
create or replace function public._sos_my_company_as_manager() returns uuid
language sql stable security definer set search_path = public as $$
    select m.company_id from sos_company_members m
     where m.user_id = auth.uid() and m.role = 'manager' and m.status = 'active'
     order by m.created_at limit 1
$$;

-- 6자리 건물 코드 (헷갈리는 글자 0·O·1·I·L 제외)
create or replace function public._sos_new_building_code() returns text
language plpgsql volatile as $$
declare
    v_chars text := 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
    v_code  text;
begin
    loop
        v_code := '';
        for i in 1..6 loop
            v_code := v_code || substr(v_chars, 1 + floor(random() * length(v_chars))::int, 1);
        end loop;
        exit when not exists (select 1 from public.sos_company_buildings where code = v_code);
    end loop;
    return v_code;
end $$;

-- 회사별 그달 이용 금액 (상담료 + 후불 연장 - 환불)
create or replace function public._sos_company_month_total(p_company_id uuid, p_month date)
returns jsonb language sql stable security definer set search_path = public as $$
    with b as (
        select (date_trunc('month', p_month)::timestamp at time zone 'Asia/Seoul') as f,
               ((date_trunc('month', p_month) + interval '1 month')::timestamp at time zone 'Asia/Seoul') as t
    ),
    consult as (
        select count(*) as n, coalesce(sum(coalesce(r.fee_amount, r.base_fee, 0)), 0) as amt
          from sos_requests r, b
         where r.company_id = p_company_id and r.fee_charged_at >= b.f and r.fee_charged_at < b.t
    ),
    ext as (
        select count(*) as n, coalesce(sum(e.amount), 0) as amt
          from sos_session_extensions e join sos_requests r on r.id = e.request_id, b
         where r.company_id = p_company_id and e.billing = 'postpaid' and e.created_at >= b.f and e.created_at < b.t
    ),
    ref as (
        select count(*) as n, coalesce(sum(f.amount), 0) as amt
          from sos_refunds f join sos_requests r on r.id = f.request_id, b
         where r.company_id = p_company_id and f.refunded_at >= b.f and f.refunded_at < b.t
    ),
    c as (select monthly_limit from sos_companies where id = p_company_id)
    select jsonb_build_object(
        'month', date_trunc('month', p_month)::date,
        'consult_count', consult.n, 'consult_amount', consult.amt,
        'extend_count', ext.n, 'extend_amount', ext.amt,
        'refund_count', ref.n, 'refund_amount', ref.amt,
        'monthly_limit', coalesce(c.monthly_limit, 0),
        'total', consult.amt + ext.amt - ref.amt
    ) from consult, ext, ref, c
$$;

-- ---------------------------------------------------------------------
-- 3. 접수할 때 회사·건물·호출자 자동 표시
-- ---------------------------------------------------------------------
create or replace function public._sos_tag_company_request() returns trigger
language plpgsql security definer set search_path = public as $$
declare m record;
begin
    if new.user_id is null or new.company_id is not null then return new; end if;
    select mm.*
      into m
      from sos_company_members mm join sos_companies c on c.id = mm.company_id
     where mm.user_id = new.user_id and mm.status = 'active'
       and c.status = 'active' and c.card_customer_uid is not null
     order by mm.last_prepared_at desc nulls last, mm.created_at
     limit 1;
    if not found then return new; end if;

    new.company_id := m.company_id;
    -- 방금(30분 안) 고른 건물이 이 회사 건물이면 그 건물, 아니면 처음 연결한 건물
    if m.last_building_id is not null and m.last_prepared_at > now() - interval '30 minutes'
       and exists (select 1 from sos_company_buildings b where b.id = m.last_building_id and b.company_id = m.company_id) then
        new.building_id := m.last_building_id;
    else
        new.building_id := m.joined_building_id;
    end if;
    if m.role = 'shared' and m.last_prepared_at > now() - interval '30 minutes' then
        new.caller_name  := m.last_caller_name;
        new.caller_phone := m.last_caller_phone;
    else
        new.caller_name  := m.name;
        new.caller_phone := m.phone;
    end if;
    return new;
end $$;
drop trigger if exists trg_sos_tag_company_request on public.sos_requests;
create trigger trg_sos_tag_company_request
    before insert on public.sos_requests
    for each row execute function public._sos_tag_company_request();

-- ---------------------------------------------------------------------
-- 4. 회원(담당자·직원)용 함수
-- ---------------------------------------------------------------------
-- 내 회원사 정보 (담당자면 직원·건물·이번 달 이용까지)
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
        'company', jsonb_build_object('id', c.id, 'name', c.name, 'status', c.status,
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

-- 회원사 가입 신청 (담당자)
create or replace function public.sos_company_apply(p_name text, p_biz_no text, p_manager_name text, p_manager_phone text,
                                                   p_tax_email text default null)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_id uuid;
begin
    if auth.uid() is null then raise exception 'LOGIN_REQUIRED'; end if;
    if coalesce(trim(p_name), '') = '' or coalesce(trim(p_manager_name), '') = ''
       or length(regexp_replace(coalesce(p_manager_phone, ''), '[^0-9]', '', 'g')) < 9 then raise exception 'BAD_INPUT'; end if;
    if exists (select 1 from sos_company_members where user_id = auth.uid() and status <> 'removed') then
        raise exception 'ALREADY_MEMBER';
    end if;
    insert into sos_companies (name, biz_no, manager_user_id, manager_name, manager_phone, tax_email)
    values (trim(p_name), nullif(trim(p_biz_no), ''), auth.uid(), trim(p_manager_name), trim(p_manager_phone),
            nullif(trim(p_tax_email), ''))
    returning id into v_id;
    insert into sos_company_members (company_id, user_id, name, phone, role, status, decided_at)
    values (v_id, auth.uid(), trim(p_manager_name), trim(p_manager_phone), 'manager', 'active', now());
    return sos_company_me();
end $$;

-- 회사 정보 수정 (담당자)
create or replace function public.sos_company_update(p_name text, p_biz_no text, p_manager_name text, p_manager_phone text,
                                                    p_tax_email text, p_monthly_limit int)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_c uuid := _sos_my_company_as_manager();
begin
    if v_c is null then raise exception 'NOT_MANAGER'; end if;
    update sos_companies
       set name = coalesce(nullif(trim(p_name), ''), name),
           biz_no = nullif(trim(p_biz_no), ''),
           manager_name = coalesce(nullif(trim(p_manager_name), ''), manager_name),
           manager_phone = coalesce(nullif(trim(p_manager_phone), ''), manager_phone),
           tax_email = nullif(trim(p_tax_email), ''),
           monthly_limit = greatest(0, coalesce(p_monthly_limit, monthly_limit))
     where id = v_c;
    return sos_company_me();
end $$;

-- 카드 등록 결과 저장 (담당자, 포트원 빌링키 발급 성공 후)
create or replace function public.sos_company_set_card(p_customer_uid text, p_card_label text)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_c uuid := _sos_my_company_as_manager();
begin
    if v_c is null then raise exception 'NOT_MANAGER'; end if;
    if coalesce(p_customer_uid, '') = '' or p_customer_uid not like 'kcbma_co_%' then raise exception 'BAD_CARD'; end if;
    update sos_companies set card_customer_uid = p_customer_uid, card_label = nullif(trim(p_card_label), ''), card_registered_at = now()
     where id = v_c;
    perform _sos_company_sync_company(v_c);
    return sos_company_me();
end $$;

-- 건물 추가 (담당자) → 건물 코드 발급
create or replace function public.sos_company_add_building(p_name text, p_address text, p_detail text default null)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_c uuid := _sos_my_company_as_manager();
begin
    if v_c is null then raise exception 'NOT_MANAGER'; end if;
    if coalesce(trim(p_name), '') = '' or coalesce(trim(p_address), '') = '' then raise exception 'BAD_INPUT'; end if;
    insert into sos_company_buildings (company_id, name, address, address_detail, code)
    values (v_c, trim(p_name), trim(p_address), nullif(trim(p_detail), ''), _sos_new_building_code());
    return sos_company_me();
end $$;

-- 건물 수정·사용 중지·코드 새로 발급 (담당자)
create or replace function public.sos_company_update_building(p_building_id uuid, p_name text, p_address text, p_detail text,
                                                             p_active boolean, p_new_code boolean default false)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_c uuid := _sos_my_company_as_manager();
begin
    if v_c is null then raise exception 'NOT_MANAGER'; end if;
    update sos_company_buildings
       set name = coalesce(nullif(trim(p_name), ''), name),
           address = coalesce(nullif(trim(p_address), ''), address),
           address_detail = nullif(trim(p_detail), ''),
           active = coalesce(p_active, active),
           code = case when p_new_code then _sos_new_building_code() else code end
     where id = p_building_id and company_id = v_c;
    if not found then raise exception 'NOT_FOUND'; end if;
    return sos_company_me();
end $$;

-- 직원: 건물 코드로 연결 신청
create or replace function public.sos_company_join(p_code text, p_name text, p_phone text)
returns jsonb language plpgsql security definer set search_path = public as $$
declare b sos_company_buildings%rowtype;
begin
    if auth.uid() is null then raise exception 'LOGIN_REQUIRED'; end if;
    if coalesce(trim(p_name), '') = '' or length(regexp_replace(coalesce(p_phone, ''), '[^0-9]', '', 'g')) < 9 then raise exception 'BAD_INPUT'; end if;
    select * into b from sos_company_buildings where code = upper(trim(p_code)) and active;
    if not found then raise exception 'BAD_CODE'; end if;
    if exists (select 1 from sos_company_members where user_id = auth.uid() and status <> 'removed' and company_id <> b.company_id) then
        raise exception 'OTHER_COMPANY';
    end if;
    insert into sos_company_members (company_id, user_id, joined_building_id, name, phone, role, status)
    values (b.company_id, auth.uid(), b.id, trim(p_name), trim(p_phone), 'staff', 'pending')
    on conflict (company_id, user_id) do update
        set status = case when sos_company_members.status = 'active' then 'active' else 'pending' end,
            joined_building_id = excluded.joined_building_id, name = excluded.name, phone = excluded.phone;
    return sos_company_me();
end $$;

-- 직원: 연결 끊기 (본인)
create or replace function public.sos_company_leave()
returns jsonb language plpgsql security definer set search_path = public as $$
begin
    if auth.uid() is null then raise exception 'LOGIN_REQUIRED'; end if;
    if exists (select 1 from sos_company_members where user_id = auth.uid() and role = 'manager' and status = 'active') then
        raise exception 'MANAGER_CANNOT_LEAVE';
    end if;
    update sos_company_members set status = 'removed', decided_at = now() where user_id = auth.uid() and status <> 'removed';
    perform _sos_company_sync_user(auth.uid());
    return sos_company_me();
end $$;

-- 담당자: 직원 승인 / 공용 계정으로 승인 / 연결 해제
--   p_action = 'approve' | 'approve_shared' | 'remove'
create or replace function public.sos_company_member_action(p_member_id uuid, p_action text)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
    v_c uuid := _sos_my_company_as_manager();
    x sos_company_members%rowtype;
begin
    if v_c is null then raise exception 'NOT_MANAGER'; end if;
    select * into x from sos_company_members where id = p_member_id and company_id = v_c;
    if not found then raise exception 'NOT_FOUND'; end if;
    if x.role = 'manager' then raise exception 'CANNOT_CHANGE_MANAGER'; end if;
    if p_action = 'approve' then
        update sos_company_members set status = 'active', role = 'staff', decided_at = now() where id = x.id;
    elsif p_action = 'approve_shared' then
        update sos_company_members set status = 'active', role = 'shared', decided_at = now() where id = x.id;
    elsif p_action = 'remove' then
        update sos_company_members set status = 'removed', decided_at = now() where id = x.id;
    else
        raise exception 'BAD_ACTION';
    end if;
    perform _sos_company_sync_user(x.user_id);
    return sos_company_me();
end $$;

-- 접수 직전: 이번 접수의 건물·호출자 (공용 계정은 호출자 이름·연락처 필수)
create or replace function public.sos_company_prepare(p_building_id uuid, p_caller_name text default null, p_caller_phone text default null)
returns jsonb language plpgsql security definer set search_path = public as $$
declare m sos_company_members%rowtype;
begin
    if auth.uid() is null then raise exception 'LOGIN_REQUIRED'; end if;
    select * into m from sos_company_members where user_id = auth.uid() and status = 'active' order by created_at limit 1;
    if not found then return null; end if;
    if m.role = 'shared' and (coalesce(trim(p_caller_name), '') = ''
                              or length(regexp_replace(coalesce(p_caller_phone, ''), '[^0-9]', '', 'g')) < 9) then
        raise exception 'CALLER_REQUIRED';
    end if;
    update sos_company_members
       set last_building_id = case when exists (select 1 from sos_company_buildings b where b.id = p_building_id and b.company_id = m.company_id)
                                   then p_building_id else null end,
           last_caller_name = nullif(trim(p_caller_name), ''),
           last_caller_phone = nullif(trim(p_caller_phone), ''),
           last_prepared_at = now()
     where id = m.id;
    return jsonb_build_object('ok', true);
end $$;

-- 담당자: 월 이용 내역 (건별)
create or replace function public.sos_company_usage(p_month date default (now() at time zone 'Asia/Seoul')::date)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare
    v_c uuid := _sos_my_company_as_manager();
    v_from timestamptz := (date_trunc('month', p_month)::timestamp at time zone 'Asia/Seoul');
    v_to   timestamptz := ((date_trunc('month', p_month) + interval '1 month')::timestamp at time zone 'Asia/Seoul');
begin
    if v_c is null then raise exception 'NOT_MANAGER'; end if;
    return jsonb_build_object(
        'summary', _sos_company_month_total(v_c, p_month),
        'invoice', (select to_jsonb(i) from sos_company_invoices i where i.company_id = v_c and i.month = date_trunc('month', p_month)::date),
        'items', coalesce((
            select jsonb_agg(jsonb_build_object(
                       'request_id', r.id, 'at', r.fee_charged_at, 'category', r.category,
                       'building', b.name, 'caller', r.caller_name, 'caller_phone', r.caller_phone,
                       'fee', coalesce(r.fee_amount, r.base_fee, 0),
                       'extend', (select coalesce(sum(e.amount), 0) from sos_session_extensions e where e.request_id = r.id and e.billing = 'postpaid'),
                       'refunded', (select coalesce(sum(f.amount), 0) from sos_refunds f where f.request_id = r.id))
                   order by r.fee_charged_at desc)
              from sos_requests r left join sos_company_buildings b on b.id = r.building_id
             where r.company_id = v_c and r.fee_charged_at >= v_from and r.fee_charged_at < v_to), '[]'::jsonb)
    );
end $$;

-- ---------------------------------------------------------------------
-- 5. 관리자용 함수
-- ---------------------------------------------------------------------
-- 회원사 목록 + 그달 이용 금액
create or replace function public.admin_sos_companies(p_month date default (now() at time zone 'Asia/Seoul')::date)
returns jsonb language plpgsql stable security definer set search_path = public as $$
begin
    if not public.is_admin() then raise exception 'ADMIN_ONLY'; end if;
    return coalesce((
        select jsonb_agg(jsonb_build_object(
                   'id', c.id, 'name', c.name, 'biz_no', c.biz_no, 'manager_name', c.manager_name, 'manager_phone', c.manager_phone,
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

-- 회원사 승인·정지·반려 / 한도·메모 (카드 등록 전에 승인해도 카드를 등록해야 이용 시작)
create or replace function public.admin_sos_company_update(p_company_id uuid, p_status text, p_monthly_limit int, p_note text)
returns void language plpgsql security definer set search_path = public as $$
begin
    if not public.is_admin() then raise exception 'ADMIN_ONLY'; end if;
    if p_status not in ('pending', 'active', 'suspended', 'rejected') then raise exception 'BAD_STATUS'; end if;
    update sos_companies
       set status = p_status,
           approved_at = case when p_status = 'active' and approved_at is null then now() else approved_at end,
           monthly_limit = greatest(0, coalesce(p_monthly_limit, monthly_limit)),
           admin_note = p_note
     where id = p_company_id;
    if not found then raise exception 'NOT_FOUND'; end if;
    perform _sos_company_sync_company(p_company_id);
end $$;

-- 월 청구 기록 (청구 금액 확정 / 카드 결제 완료 표시)
create or replace function public.admin_sos_company_invoice(p_company_id uuid, p_month date, p_status text, p_method text, p_memo text)
returns void language plpgsql security definer set search_path = public as $$
declare v_amt int;
begin
    if not public.is_admin() then raise exception 'ADMIN_ONLY'; end if;
    if p_status not in ('unpaid', 'paid', 'void') then raise exception 'BAD_STATUS'; end if;
    v_amt := (_sos_company_month_total(p_company_id, p_month) ->> 'total')::int;
    insert into sos_company_invoices (company_id, month, amount, status, method, memo, paid_at)
    values (p_company_id, date_trunc('month', p_month)::date, v_amt, p_status, p_method, p_memo,
            case when p_status = 'paid' then now() end)
    on conflict (company_id, month) do update
        set amount = case when sos_company_invoices.status = 'paid' then sos_company_invoices.amount else excluded.amount end,
            status = excluded.status, method = coalesce(excluded.method, sos_company_invoices.method),
            memo = coalesce(excluded.memo, sos_company_invoices.memo),
            paid_at = case when excluded.status = 'paid' then coalesce(sos_company_invoices.paid_at, now()) else null end;
end $$;

-- ---------------------------------------------------------------------
-- 6. 실행 권한
-- ---------------------------------------------------------------------
revoke all on function public._sos_company_sync_user(uuid)        from public, anon, authenticated;
revoke all on function public._sos_company_sync_company(uuid)     from public, anon, authenticated;
revoke all on function public._sos_company_month_total(uuid, date) from public, anon, authenticated;
grant execute on function public.sos_company_me()                                              to authenticated;
grant execute on function public.sos_company_apply(text, text, text, text, text)               to authenticated;
grant execute on function public.sos_company_update(text, text, text, text, text, int)         to authenticated;
grant execute on function public.sos_company_set_card(text, text)                              to authenticated;
grant execute on function public.sos_company_add_building(text, text, text)                    to authenticated;
grant execute on function public.sos_company_update_building(uuid, text, text, text, boolean, boolean) to authenticated;
grant execute on function public.sos_company_join(text, text, text)                            to authenticated;
grant execute on function public.sos_company_leave()                                           to authenticated;
grant execute on function public.sos_company_member_action(uuid, text)                         to authenticated;
grant execute on function public.sos_company_prepare(uuid, text, text)                         to authenticated;
grant execute on function public.sos_company_usage(date)                                       to authenticated;
grant execute on function public.admin_sos_companies(date)                                     to authenticated;
grant execute on function public.admin_sos_company_update(uuid, text, int, text)               to authenticated;
grant execute on function public.admin_sos_company_invoice(uuid, date, text, text, text)       to authenticated;

commit;

-- =====================================================================
-- 점검: 후불 회원이 번호 공개·종료 때 포인트 없이 진행되는지 (기존 서버 함수 확인)
--   '후불 처리 있음'이 '예'여야 회원사 직원이 결제 없이 이용할 수 있습니다. '아니오'면 결과를 보내 주세요.
-- =====================================================================
select p.proname as 함수이름,
       case when p.prosrc ilike '%postpaid%' then '예' else '아니오' end as 후불_처리_있음
  from pg_proc p join pg_namespace n on n.oid = p.pronamespace
 where n.nspname = 'public'
   and p.proname in ('create_sos_request', 'assign_expert', 'assign_expert_direct', 'complete_sos_request')
 order by 1;
