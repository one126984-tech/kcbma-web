-- ① 확인용: DB에 저장된 과정명·평가명·수료증명 중 "자격" 또는 "관리사"가 들어간 것 찾기 (아무것도 바뀌지 않음)
select 'cert_courses' as 테이블, id::text, title as 이름 from cert_courses
 where title like '%자격%' or title like '%관리사%'
union all
select 'cert_exams', id::text, title from cert_exams
 where title like '%자격%' or title like '%관리사%'
union all
select 'cert_certificates', id::text, cert_name from cert_certificates
 where cert_name like '%자격%' or cert_name like '%관리사%';

-- ② 결과가 나오면: 관리자 화면(관리자 → 과정 관리 → 수정)에서 이름을 하나씩 고치는 게 가장 안전합니다.
--    예) "기전당직실무관리사 자격 취득 과정" → "기전당직 실무 교육과정"
