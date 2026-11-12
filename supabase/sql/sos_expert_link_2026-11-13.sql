-- =====================================================================
-- SOS 전문가 ↔ 회원 계정 연결 (2026-11-13)
--   원인: 관리자가 직접 등록하거나 지원서를 승인한 전문가에 회원 계정(user_id)이
--         연결되지 않아, 그 계정으로 로그인해도 대기실에서 "승인된 전문가 계정이 아닙니다"가 뜸.
-- Supabase > SQL Editor 에서 블록별로 실행하세요.
-- =====================================================================


-- [1] 현재 전문가 목록과 연결 상태 확인 (아무것도 바뀌지 않음)
select e.id, e.name, e.phone, e.is_active,
       u.email as 연결된_계정
  from public.sos_experts e
  left join auth.users u on u.id = e.user_id
 order by e.name;


-- [2] 테스트 전문가를 idea8888@kakao.com 계정에 연결
--     ↓ '01000000000' 자리에 세컨폰 번호를 숫자만 넣고 실행하세요.
--     (같은 계정에 연결돼 있던 다른 전문가 행이 있으면 먼저 연결을 풀어 중복을 막음)
update public.sos_experts
   set user_id = null
 where user_id = (select id from auth.users where email = 'idea8888@kakao.com')
   and regexp_replace(coalesce(phone, ''), '\D', '', 'g') <> '01000000000';

update public.sos_experts
   set user_id   = (select id from auth.users where email = 'idea8888@kakao.com'),
       is_active = true
 where regexp_replace(coalesce(phone, ''), '\D', '', 'g') = '01000000000';


-- [3] 지금까지 승인된 지원자들도 같은 전화번호의 전문가와 연결 (빠진 것만)
update public.sos_experts e
   set user_id = a.user_id
  from public.sos_applications a
 where e.user_id is null
   and a.user_id is not null
   and a.status = '승인'
   and regexp_replace(coalesce(e.phone, ''), '\D', '', 'g') = regexp_replace(coalesce(a.phone, ''), '\D', '', 'g')
   and not exists (select 1 from public.sos_experts x where x.user_id = a.user_id);


-- [4] 결과 확인: 테스트 전문가 줄의 '연결된_계정'에 idea8888@kakao.com 이 보이면 성공
select e.name, e.phone, e.is_active, u.email as 연결된_계정
  from public.sos_experts e
  left join auth.users u on u.id = e.user_id
 order by e.name;
