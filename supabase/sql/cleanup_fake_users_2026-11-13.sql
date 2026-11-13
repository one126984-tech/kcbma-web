-- =====================================================================
-- 가짜 이메일 계정 정리 (2026-11-13)
--   대상: 실제 메일함이 없어 로그인할 수 없는 테스트 계정
--         (@test.com, @test.kr, @example.com 등)
--   순서: [1] 대상 확인 → [2] 딸린 자료 확인 → [3] 삭제
--   ※ 블록을 하나씩 실행하세요. [3]은 [1]·[2] 결과를 확인한 뒤에만!
-- =====================================================================


-- [1] 지울 대상 확인 (아무것도 바뀌지 않음)
select id, email, raw_user_meta_data->>'name' as 이름, created_at + interval '9 hours' as 가입_한국시간
  from auth.users
 where split_part(lower(email), '@', 2) in ('test.com', 'test.kr', 'example.com', 'test.co.kr')
 order by email;


-- [2] 이 계정들에 딸린 자료가 있는지 확인 (아무것도 바뀌지 않음)
--     모든 표에서 user_id / created_by / author_id / owner_id / writer_id / requester_id 칸을 찾아
--     가짜 계정이 남긴 줄 수를 셉니다. 결과가 없으면 딸린 자료가 없는 것입니다.
create or replace function pg_temp.fake_user_refs()
returns table(표 text, 칸 text, 줄수 bigint)
language plpgsql as $$
declare r record; n bigint;
begin
  for r in
    select c.table_schema, c.table_name, c.column_name
      from information_schema.columns c
      join information_schema.tables t
        on t.table_schema = c.table_schema and t.table_name = c.table_name and t.table_type = 'BASE TABLE'
     where c.table_schema = 'public'
       and c.column_name in ('user_id', 'created_by', 'author_id', 'owner_id', 'writer_id', 'requester_id', 'id')
       and c.data_type in ('uuid', 'text', 'character varying')
  loop
    -- 'id' 칸은 회원 프로필처럼 계정 번호를 그대로 쓰는 표만 셈
    if r.column_name = 'id' and r.table_name not in ('user_profiles', 'profiles', 'member_sos_profile') then
      continue;
    end if;
    execute format(
      'select count(*) from %I.%I where %I::text in (select id::text from auth.users where split_part(lower(email), ''@'', 2) in (''test.com'', ''test.kr'', ''example.com'', ''test.co.kr''))',
      r.table_schema, r.table_name, r.column_name) into n;
    if n > 0 then
      표 := r.table_name; 칸 := r.column_name; 줄수 := n;
      return next;
    end if;
  end loop;
end $$;

select * from pg_temp.fake_user_refs() order by 표;


-- [3] 삭제 — [2] 결과를 보고 지워도 되는 자료일 때만 실행
--     · 회원 프로필(user_profiles)은 함께 지웁니다.
--     · 다른 표에 남은 글·기록이 있어 삭제가 막히면 오류 문구를 그대로 보내 주세요.
--       (그 경우 무엇을 먼저 지울지 정리해 드립니다. 오류가 나면 아무것도 지워지지 않습니다)
begin;

delete from public.user_profiles
 where id in (select id from auth.users where split_part(lower(email), '@', 2) in ('test.com', 'test.kr', 'example.com', 'test.co.kr'));

delete from auth.users
 where split_part(lower(email), '@', 2) in ('test.com', 'test.kr', 'example.com', 'test.co.kr');

commit;

-- 확인: 0 이 나오면 정리 완료
select count(*) as 남은_가짜계정
  from auth.users
 where split_part(lower(email), '@', 2) in ('test.com', 'test.kr', 'example.com', 'test.co.kr');
