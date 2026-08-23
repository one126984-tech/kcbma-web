-- =====================================================================
-- KCBMA 자격증 과정 초기 데이터 시드 — 9개 과정 + 커리큘럼 + 시험/문제
-- 대상 테이블: cert_courses, cert_curriculum, cert_exams, cert_exam_questions
-- 주의: 05~09 번 SQL 파일을 먼저 실행한 뒤에 이 파일을 실행할 것
-- 실행:
--   1. https://supabase.com/dashboard/project/ehrahnnowwjkgycvlbzk/sql/new
--   2. 전체 복사 → 붙여넣기 → [Run] (한 번만)
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. cert_courses (자격증 과정 9개)
-- ---------------------------------------------------------------------
insert into public.cert_courses
  (title, slug, category, description, edu_method, edu_period,
   original_price, discount_price, is_free, cert_price, instructor_name, status, sort_order)
values
  ('기전당직실무관리사', 'electrical-duty', '기전',
   '<p>건물 기전실 당직 운영에 필요한 전기·기계 설비 실무 지식을 학습합니다. 수변전설비, 발전기, 공조설비 등 당직 근무 중 발생하는 실무 상황에 대한 대응 능력을 배양합니다.</p>',
   'VOD', '신청일로부터 30일', 0, 0, true, 250000, '김기전', 'OPEN', 1),

  ('전기방재설비관리사', 'fire-electrical', '전기방재',
   '<p>소방전기설비 및 방재시스템의 점검·유지관리 실무를 학습합니다. 자동화재탐지설비, 비상방송설비, 유도등 등 전기방재 설비 전반의 관리 능력을 배양합니다.</p>',
   'VOD', '신청일로부터 30일', 0, 0, true, 250000, '이방재', 'OPEN', 2),

  ('기계설비실무관리사', 'mechanical-equipment', '기계',
   '<p>공동주택 및 건축물의 기계설비(냉난방, 급배수, 소방펌프 등) 운영·유지관리 실무를 학습합니다. 기계설비법 및 성능점검 실무 능력을 배양합니다.</p>',
   'VOD', '신청일로부터 30일', 0, 0, true, 250000, '박기계', 'OPEN', 3),

  ('건물영선실무관리사', 'building-maintenance', '영선',
   '<p>건축물 영선(유지보수) 업무 전반에 대한 실무 지식을 학습합니다. 건물 하자보수, 도장, 방수, 시설 개보수 등 실무 중심 커리큘럼으로 구성되어 있습니다.</p>',
   'VOD', '신청일로부터 30일', 0, 0, true, 250000, '최영선', 'OPEN', 4),

  ('배관설비실무관리사', 'plumbing', '배관',
   '<p>급수·급탕·배수 등 건축물 배관설비의 시공 및 유지관리 실무를 학습합니다. 배관 자재, 누수 진단, 배관 보수 실무 능력을 배양합니다.</p>',
   'VOD', '신청일로부터 30일', 0, 0, true, 250000, '정배관', 'OPEN', 5),

  ('시설행정실무관리사', 'facility-admin', '행정',
   '<p>집합건물 관리사무소의 행정 업무 전반(관리비 산정, 장기수선계획, 관리규약, 입주자대표회의 운영 등)을 학습합니다.</p>',
   'LIVE', '신청일로부터 30일', 0, 0, true, 250000, '한행정', 'OPEN', 6),

  ('환경위생실무관리사', 'environmental-hygiene', '환경위생',
   '<p>공동주택 및 건축물의 환경위생 관리(먹는물 수질관리, 저수조 청소, 소독, 실내공기질 관리 등) 실무를 학습합니다.</p>',
   'MIX', '신청일로부터 30일', 0, 0, true, 250000, '오위생', 'OPEN', 7),

  ('경리회계실무관리사', 'accounting-practice', '회계',
   '<p>건물 관리 현장의 경리·회계 실무 능력을 검증하는 과정입니다. 관리비 회계처리, 예산편성, 세무신고, 재무제표 분석 등 관리사무소 회계 업무 전반을 학습합니다.</p>',
   'VOD', '신청일로부터 30일', 0, 0, true, 250000, '강경리', 'OPEN', 8),

  ('환경미화관리사', 'cleaning-management', '환경미화',
   '<p>건물 환경미화 실무 능력을 검증하는 과정입니다. 처음 미화원이 되려는 분들을 위해 약품 사용법, 구역별 청소 방법, 위생 관리 등을 체계적으로 교육합니다.</p>',
   'VOD', '신청일로부터 30일', 0, 0, true, 250000, '윤미화', 'OPEN', 9)
on conflict (slug) do nothing;

-- ---------------------------------------------------------------------
-- 2. cert_curriculum (과정별 커리큘럼)
-- ---------------------------------------------------------------------

-- 2-1) 기전당직실무관리사 (electrical-duty) — 6차시
insert into public.cert_curriculum (course_id, chapter_no, title, duration_min, content_type, is_preview, sort_order)
select c.id, v.chapter_no, v.title, v.duration_min, 'VOD', v.is_preview, v.chapter_no
from public.cert_courses c
join (values
  (1, '기전 당직 업무 개요와 근무 체계', 40, true),
  (2, '수변전설비 구조와 점검 실무', 50, false),
  (3, '비상발전기 운영 및 정기 시운전', 45, false),
  (4, '공조설비(냉동기·보일러) 운전관리', 50, false),
  (5, '당직 중 전기 고장 대응 및 안전조치', 45, false),
  (6, '기전 설비 일일점검표 작성과 인수인계 실무', 35, false)
) as v(chapter_no, title, duration_min, is_preview)
on true
where c.slug = 'electrical-duty';

-- 2-2) 전기방재설비관리사 (fire-electrical) — 7차시
insert into public.cert_curriculum (course_id, chapter_no, title, duration_min, content_type, is_preview, sort_order)
select c.id, v.chapter_no, v.title, v.duration_min, 'VOD', v.is_preview, v.chapter_no
from public.cert_courses c
join (values
  (1, '소방전기설비 개론과 관련 법령', 40, true),
  (2, '자동화재탐지설비 구조와 점검 방법', 50, false),
  (3, '비상방송설비 및 유도등·비상조명등 점검', 45, false),
  (4, '스프링클러 연동 전기설비와 수신기 운용', 50, false),
  (5, '비상전원(축전지·발전기) 관리 실무', 40, false),
  (6, '방재센터 운영과 화재 대응 시나리오', 45, false),
  (7, '소방전기설비 자체점검 실습 및 기록 작성', 35, false)
) as v(chapter_no, title, duration_min, is_preview)
on true
where c.slug = 'fire-electrical';

-- 2-3) 기계설비실무관리사 (mechanical-equipment) — 8차시
insert into public.cert_curriculum (course_id, chapter_no, title, duration_min, content_type, is_preview, sort_order)
select c.id, v.chapter_no, v.title, v.duration_min, 'VOD', v.is_preview, v.chapter_no
from public.cert_courses c
join (values
  (1, '기계설비법과 유지관리 제도 개요', 40, true),
  (2, '냉동기·냉각탑 운전관리 실무', 50, false),
  (3, '보일러 및 난방설비 안전관리', 50, false),
  (4, '급수·급탕 설비 유지관리', 45, false),
  (5, '소방펌프·옥내소화전 설비 점검', 45, false),
  (6, '환기·공조 덕트 시스템 관리', 40, false),
  (7, '기계설비 성능점검 실무와 보고서 작성', 45, false),
  (8, '기계설비 유지관리자 배치 기준과 실무 사례', 35, false)
) as v(chapter_no, title, duration_min, is_preview)
on true
where c.slug = 'mechanical-equipment';

-- 2-4) 건물영선실무관리사 (building-maintenance) — 6차시
insert into public.cert_curriculum (course_id, chapter_no, title, duration_min, content_type, is_preview, sort_order)
select c.id, v.chapter_no, v.title, v.duration_min, 'VOD', v.is_preview, v.chapter_no
from public.cert_courses c
join (values
  (1, '건물 영선업무 개론과 유지보수 계획', 40, true),
  (2, '건축물 균열·누수 진단과 보수 방법', 50, false),
  (3, '도장 및 마감재 보수 실무', 40, false),
  (4, '방수공사 종류와 시공 실무', 45, false),
  (5, '목공·창호·타일 보수 실무', 45, false),
  (6, '영선 작업 안전관리와 하자보수 사례 분석', 35, false)
) as v(chapter_no, title, duration_min, is_preview)
on true
where c.slug = 'building-maintenance';

-- 2-5) 배관설비실무관리사 (plumbing) — 6차시
insert into public.cert_curriculum (course_id, chapter_no, title, duration_min, content_type, is_preview, sort_order)
select c.id, v.chapter_no, v.title, v.duration_min, 'VOD', v.is_preview, v.chapter_no
from public.cert_courses c
join (values
  (1, '배관설비 개론과 배관 자재 종류', 40, true),
  (2, '급수·급탕 배관 시공과 유지관리', 50, false),
  (3, '배수·통기 배관 시스템 관리', 45, false),
  (4, '누수 진단 장비 활용과 탐지 실무', 45, false),
  (5, '배관 부식·동파 방지 및 보수 실무', 40, false),
  (6, '배관설비 정기점검과 유지관리 기록 작성', 35, false)
) as v(chapter_no, title, duration_min, is_preview)
on true
where c.slug = 'plumbing';

-- 2-6) 시설행정실무관리사 (facility-admin) — 7차시 (LIVE 과정)
insert into public.cert_curriculum (course_id, chapter_no, title, duration_min, content_type, is_preview, sort_order)
select c.id, v.chapter_no, v.title, v.duration_min, 'LIVE', v.is_preview, v.chapter_no
from public.cert_courses c
join (values
  (1, '집합건물법과 관리사무소 행정 개요', 60, true),
  (2, '관리비 산정과 회계 처리 실무', 60, false),
  (3, '장기수선계획 수립과 장기수선충당금 운용', 60, false),
  (4, '관리규약 제정·개정 절차와 실무', 60, false),
  (5, '입주자대표회의 운영과 의사록 작성', 60, false),
  (6, '민원 처리와 분쟁 조정 실무', 60, false),
  (7, '행정 서류 작성 실습과 사례 토론', 60, false)
) as v(chapter_no, title, duration_min, is_preview)
on true
where c.slug = 'facility-admin';

-- 2-7) 환경위생실무관리사 (environmental-hygiene) — 6차시 (MIX 과정)
insert into public.cert_curriculum (course_id, chapter_no, title, duration_min, content_type, is_preview, sort_order)
select c.id, v.chapter_no, v.title, v.duration_min, v.content_type, v.is_preview, v.chapter_no
from public.cert_courses c
join (values
  (1, '환경위생 관리 개론과 관련 법령', 40, 'VOD', true),
  (2, '먹는물 수질관리와 저수조 청소 실무', 50, 'VOD', false),
  (3, '저수조·물탱크 소독 실습', 45, 'LIVE', false),
  (4, '실내공기질 측정과 관리 기준', 45, 'VOD', false),
  (5, '해충·설치류 방역 관리 실무', 40, 'VOD', false),
  (6, '환경위생 점검 기록 작성과 현장 실습', 45, 'LIVE', false)
) as v(chapter_no, title, duration_min, content_type, is_preview)
on true
where c.slug = 'environmental-hygiene';

-- 2-8) 경리회계실무관리사 (accounting-practice) — 5차시
insert into public.cert_curriculum (course_id, chapter_no, title, duration_min, content_type, is_preview, sort_order)
select c.id, v.chapter_no, v.title, v.duration_min, 'VOD', v.is_preview, v.chapter_no
from public.cert_courses c
join (values
  (1, '집합건물 관리비 회계 기초', 40, true),
  (2, '예산 편성 및 집행 관리', 50, false),
  (3, '세무 실무(부가세·원천징수·4대보험)', 50, false),
  (4, '재무제표 분석 및 감사 대응', 45, false),
  (5, '관리비 정산 및 입주민 고지', 40, false)
) as v(chapter_no, title, duration_min, is_preview)
on true
where c.slug = 'accounting-practice';

-- 2-9) 환경미화관리사 (cleaning-management) — 5차시
insert into public.cert_curriculum (course_id, chapter_no, title, duration_min, content_type, is_preview, sort_order)
select c.id, v.chapter_no, v.title, v.duration_min, 'VOD', v.is_preview, v.chapter_no
from public.cert_courses c
join (values
  (1, '환경미화 기초 및 안전교육', 35, true),
  (2, '청소 약품 및 장비 사용법', 45, false),
  (3, '구역별 청소 실무', 45, false),
  (4, '특수 청소 및 위생 관리', 40, false),
  (5, '환경미화 관리 계획 수립', 35, false)
) as v(chapter_no, title, duration_min, is_preview)
on true
where c.slug = 'cleaning-management';

-- ---------------------------------------------------------------------
-- 3. cert_exams (과정별 시험 1개씩)
-- ---------------------------------------------------------------------
insert into public.cert_exams (course_id, title, time_limit_min, pass_score, max_attempts, is_active)
select c.id, '자격 평가', 40, 60, 3, true
from public.cert_courses c
where c.slug in (
  'electrical-duty', 'fire-electrical', 'mechanical-equipment',
  'building-maintenance', 'plumbing', 'facility-admin', 'environmental-hygiene',
  'accounting-practice', 'cleaning-management'
);

-- ---------------------------------------------------------------------
-- 4. cert_exam_questions (과정별 문제 10개씩)
-- ---------------------------------------------------------------------

-- 4-1) 기전당직실무관리사
insert into public.cert_exam_questions
  (exam_id, question_no, question_text, option_1, option_2, option_3, option_4, correct_option, points, sort_order)
select e.id, v.question_no, v.question_text, v.option_1, v.option_2, v.option_3, v.option_4, v.correct_option, 10, v.question_no
from public.cert_exams e
join public.cert_courses c on c.id = e.course_id
join (values
  (1, '수변전설비에서 정전 사고를 예방하기 위해 정기적으로 점검해야 하는 항목이 아닌 것은?', '절연저항 측정', '차단기 동작 시험', '변압기 유온 확인', '엘리베이터 속도 측정', 4),
  (2, '비상발전기의 정기 시운전 주기로 가장 일반적인 것은?', '매일', '주 1회 또는 월 1회', '연 1회', '5년에 1회', 2),
  (3, '변압기의 절연유 색상이 갈색으로 변하는 주된 원인은?', '절연유의 산화·열화', '실내 조명 반사', '먼지 유입', '변압기 도색', 1),
  (4, '기전실 당직자가 화재경보 발생 시 가장 먼저 해야 할 조치는?', '경보 상태와 발생 위치 확인', '즉시 전원 전체 차단', '휴식', '민원 응대', 1),
  (5, '냉동기(터보냉동기) 운전 중 응축압력이 비정상적으로 높을 때 점검할 항목은?', '냉각수 유량 및 냉각탑 상태', '조명 밝기', '주차장 환기', '엘리베이터 속도', 1),
  (6, '보일러 저수위 사고를 방지하기 위한 안전장치는?', '저수위 차단장치(저수위 경보 및 인터록)', '자동문 센서', 'CCTV', '화재감지기', 1),
  (7, '무정전전원장치(UPS)의 주된 역할은?', '정전 시 순간적인 전원 공급 유지', '조명 밝기 조절', '수질 정화', '엘리베이터 속도 제어', 1),
  (8, '당직 근무 인수인계 시 반드시 포함되어야 할 내용이 아닌 것은?', '설비 이상 유무', '점검 예정 사항', '개인 휴가 계획', '민원 처리 현황', 3),
  (9, '차단기(VCB) 투입 전 반드시 확인해야 할 사항은?', '차단기 접점 및 절연 상태', '엘리베이터 정원', '주차 요금', '조경 관리 상태', 1),
  (10, '전기설비 점검 시 감전 사고 예방을 위한 기본 조치는?', '개인보호구 착용 및 활선 여부 확인', '점검 시간을 단축', '조명을 최대한 어둡게 유지', '점검자 수를 최소화', 1)
) as v(question_no, question_text, option_1, option_2, option_3, option_4, correct_option)
on true
where c.slug = 'electrical-duty';

-- 4-2) 전기방재설비관리사
insert into public.cert_exam_questions
  (exam_id, question_no, question_text, option_1, option_2, option_3, option_4, correct_option, points, sort_order)
select e.id, v.question_no, v.question_text, v.option_1, v.option_2, v.option_3, v.option_4, v.correct_option, 10, v.question_no
from public.cert_exams e
join public.cert_courses c on c.id = e.course_id
join (values
  (1, '자동화재탐지설비의 감지기 중 열을 감지하여 작동하는 것은?', '차동식 열감지기', '광전식 연기감지기', '이온화식 감지기', '불꽃감지기', 1),
  (2, '수신기에서 화재 신호를 수신했을 때 가장 먼저 확인해야 할 사항은?', '발화 구역과 감지기 위치', '전기요금', '주차 현황', '조경 상태', 1),
  (3, '비상방송설비의 주된 목적은?', '화재 시 재실자에게 대피 안내 방송', '광고 방송', '음악 방송', '민원 안내', 1),
  (4, '유도등의 점검 항목으로 옳지 않은 것은?', '점등 상태 확인', '비상전원 작동 확인', '표시면 오염 확인', '실내 온도 확인', 4),
  (5, '스프링클러설비와 연동되는 전기적 요소는?', '유수검지장치의 압력스위치 신호', '조명 스위치', 'CCTV 녹화', '주차 차단기', 1),
  (6, '축전지(예비전원) 설비의 정기 점검 항목은?', '전해액 및 단자 부식 상태', '주차장 조명', '엘리베이터 속도', '수도 요금', 1),
  (7, '자동화재탐지설비의 발신기와 함께 설치되는 장치는?', '위치표시등과 응답램프', '냉방기', '방송 스피커만 단독', '주차 차단기', 1),
  (8, '방재센터에서 화재 수신 후 취해야 할 표준 대응 절차 순서로 옳은 것은?', '수신 확인 → 현장 확인 → 방송/대피 안내 → 소방서 신고', '즉시 퇴근', '민원 접수', '조명 소등', 1),
  (9, '비상콘센트설비의 설치 목적은?', '소방활동 시 조명 및 장비에 전원 공급', '일반 가전제품 사용', '주차 관제', '엘리베이터 운행', 1),
  (10, '감지기 오작동(비화재보)이 잦을 때 우선 점검할 사항은?', '감지기 오염 및 설치 환경(먼지, 습기 등)', '건물 외벽 도색', '주차 요금 정산', '조경수 상태', 1)
) as v(question_no, question_text, option_1, option_2, option_3, option_4, correct_option)
on true
where c.slug = 'fire-electrical';

-- 4-3) 기계설비실무관리사
insert into public.cert_exam_questions
  (exam_id, question_no, question_text, option_1, option_2, option_3, option_4, correct_option, points, sort_order)
select e.id, v.question_no, v.question_text, v.option_1, v.option_2, v.option_3, v.option_4, v.correct_option, 10, v.question_no
from public.cert_exams e
join public.cert_courses c on c.id = e.course_id
join (values
  (1, '기계설비법상 기계설비 유지관리자를 두어야 하는 주된 목적은?', '기계설비의 안전하고 효율적인 유지관리', '건물 미화', '조경 관리', '민원 접수', 1),
  (2, '냉각탑의 주된 기능은?', '냉동기 응축기의 열을 대기로 방출', '실내 조명 제어', '음용수 정화', '엘리베이터 운행', 1),
  (3, '보일러 안전밸브의 역할은?', '설정 압력 초과 시 증기를 배출하여 압력 조절', '연료 절감', '소음 감소', '외관 보호', 1),
  (4, '기계설비 성능점검의 주요 점검 대상이 아닌 것은?', '냉난방설비', '급수·배수설비', '환기설비', '조경 식재', 4),
  (5, '옥내소화전 펌프의 기동 방식으로 일반적으로 사용되는 것은?', '압력스위치에 의한 자동기동', '수동 조작만 가능', '타이머에 의한 정시 기동만', '조도 감지 기동', 1),
  (6, '급수설비에서 수질 오염을 방지하기 위한 배관 시공 원칙은?', '역류방지밸브 설치 및 상수/중수 배관 분리', '배관을 최대한 길게 설치', '배관 재질을 통일하지 않음', '점검구를 설치하지 않음', 1),
  (7, '공조설비에서 필터의 주된 역할은?', '공기 중 먼지·이물질 제거', '온도를 낮춤', '소음을 증폭', '습도를 높임', 1),
  (8, '냉동기 냉매 누설 시 우선 조치는?', '환기 및 누설 부위 확인 후 보수', '즉시 무시하고 운전 지속', '냉매를 추가로 충전만 함', '전원을 차단 없이 방치', 1),
  (9, '장기수선계획에 포함되어야 하는 기계설비 항목의 예는?', '보일러, 냉동기 등 주요 설비의 교체 주기', '조경수 종류', '주차장 도색 색상', '민원 접수 방식', 1),
  (10, '기계설비 유지관리 점검표 작성 시 반드시 기록해야 할 사항은?', '점검일자, 점검자, 설비 상태 및 조치 내용', '점검자의 개인 취향', '점검 당일 날씨만', '주변 상가 정보', 1)
) as v(question_no, question_text, option_1, option_2, option_3, option_4, correct_option)
on true
where c.slug = 'mechanical-equipment';

-- 4-4) 건물영선실무관리사
insert into public.cert_exam_questions
  (exam_id, question_no, question_text, option_1, option_2, option_3, option_4, correct_option, points, sort_order)
select e.id, v.question_no, v.question_text, v.option_1, v.option_2, v.option_3, v.option_4, v.correct_option, 10, v.question_no
from public.cert_exams e
join public.cert_courses c on c.id = e.course_id
join (values
  (1, '건축물 외벽에 발생한 균열을 보수하기 전 가장 먼저 해야 할 작업은?', '균열의 원인과 진행 여부 진단', '즉시 도장 작업', '균열 부위 방치', '조경수 식재', 1),
  (2, '누수 발생 시 가장 먼저 확인해야 할 사항은?', '누수 발생 위치와 경로 파악', '전체 배관 교체', '민원인에게 책임 전가', '조명 교체', 1),
  (3, '방수공사 중 도막방수의 특징으로 옳은 것은?', '액상 방수재를 도포하여 방수막 형성', '시트를 접착하여 방수막 형성', '콘크리트에 방수제를 혼합하는 방식만 의미', '타일로만 방수 처리', 1),
  (4, '외부 도장 작업 시 적정 시공 조건으로 옳은 것은?', '적정 온도와 습도, 강우가 없는 날 시공', '비가 오는 날 시공', '한밤중 무조명 시공', '온도와 관계없이 시공', 1),
  (5, '창호 누수의 주요 원인이 될 수 있는 것은?', '실링(코킹) 노화 및 손상', '창호 색상', '창호 브랜드', '창호 개폐 방향', 1),
  (6, '목재 마감재의 부식(부패)을 방지하기 위한 방법은?', '방부 처리 및 습기 차단', '통풍을 완전히 차단', '방부처리 없이 방치', '직사광선에 장시간 노출', 1),
  (7, '타일 들뜸 현상이 발생하는 주요 원인은?', '접착 불량 또는 하부 바탕면의 이완', '타일 색상', '타일 크기', '실내 조도', 1),
  (8, '하자보수 작업 시 안전관리를 위해 가장 우선되어야 하는 것은?', '작업 전 위험요소 확인 및 보호장비 착용', '작업 속도 최우선', '비용 절감 최우선', '민원 응대 최우선', 1),
  (9, '옥상 방수층 손상을 조기에 발견하기 위한 방법은?', '정기적인 옥상 순회점검', '민원 접수 후에만 확인', '5년에 한 번만 확인', '점검을 하지 않음', 1),
  (10, '영선 작업 기록(하자보수 이력) 관리가 필요한 이유는?', '반복 하자 파악 및 유지관리 계획 수립', '민원인 개인정보 수집', '작업자 평가와 무관한 자료 축적', '단순 서류 보관 의무', 1)
) as v(question_no, question_text, option_1, option_2, option_3, option_4, correct_option)
on true
where c.slug = 'building-maintenance';

-- 4-5) 배관설비실무관리사
insert into public.cert_exam_questions
  (exam_id, question_no, question_text, option_1, option_2, option_3, option_4, correct_option, points, sort_order)
select e.id, v.question_no, v.question_text, v.option_1, v.option_2, v.option_3, v.option_4, v.correct_option, 10, v.question_no
from public.cert_exams e
join public.cert_courses c on c.id = e.course_id
join (values
  (1, '급수 배관 자재 중 내식성이 우수하여 최근 널리 사용되는 것은?', '스테인리스강관 또는 동관', '무처리 주철관', '목재관', '흙관', 1),
  (2, '배수배관에서 트랩(P트랩 등)의 주된 역할은?', '악취 및 해충의 역류 방지(봉수 형성)', '유량 증가', '배관 색상 유지', '수압 증가', 1),
  (3, '급탕 배관에서 열손실을 줄이기 위한 방법은?', '배관 보온재 시공', '배관을 노출시켜 방치', '배관 직경을 최대한 크게 시공', '보온 없이 매립', 1),
  (4, '누수 탐지 장비로 일반적으로 사용되는 것은?', '음파(청음) 누수탐지기', '온도계만 사용', '줄자', '수평계', 1),
  (5, '동파 방지를 위한 배관 시공 방법으로 옳은 것은?', '동결 우려 구간에 보온재 및 열선 설치', '배관을 외부에 완전 노출', '겨울철 배관 내 물을 가득 채워 방치', '보온 없이 매립', 1),
  (6, '배관 부식을 촉진하는 주요 요인은?', '이종 금속 접촉에 의한 전기화학적 부식', '배관을 자주 청소하는 것', '배관 보온', '정기적인 수질 검사', 1),
  (7, '통기배관(벤트파이프)의 주된 목적은?', '배수 시스템 내 공기 흐름 확보 및 사이펀 작용 방지', '급수 압력 증가', '온수 온도 상승', '배관 소음 증가', 1),
  (8, '배관 접합 방법 중 나사접합에 비해 용접접합의 특징은?', '기밀성이 높고 누수 위험이 낮음', '항상 시공 시간이 짧음', '숙련도가 필요 없음', '내구성이 낮음', 1),
  (9, '배관설비 정기점검 시 확인해야 할 항목으로 옳지 않은 것은?', '배관 부식 및 누수 여부', '밸브 작동 상태', '수압 및 유량 상태', '건물 외벽 색상', 4),
  (10, '급수설비의 역류를 방지하기 위해 설치하는 장치는?', '역류방지밸브(체크밸브)', '배수트랩', '통기관', '온도조절밸브', 1)
) as v(question_no, question_text, option_1, option_2, option_3, option_4, correct_option)
on true
where c.slug = 'plumbing';

-- 4-6) 시설행정실무관리사
insert into public.cert_exam_questions
  (exam_id, question_no, question_text, option_1, option_2, option_3, option_4, correct_option, points, sort_order)
select e.id, v.question_no, v.question_text, v.option_1, v.option_2, v.option_3, v.option_4, v.correct_option, 10, v.question_no
from public.cert_exams e
join public.cert_courses c on c.id = e.course_id
join (values
  (1, '집합건물의 관리규약을 제정·개정하기 위한 일반적인 절차는?', '구분소유자 및 관리단(입주자대표회의) 의결을 통한 승인', '관리소장 단독 결정', '외부 용역업체 임의 결정', '관리사무소 직원 투표', 1),
  (2, '장기수선충당금의 주된 용도는?', '건물 주요 시설의 계획적인 교체·보수 비용 충당', '관리직원 인건비 지급', '입주자 경조사비', '광고비 지출', 1),
  (3, '관리비 부과 항목 중 공용부분 관리비에 해당하는 것은?', '공동 전기·수도료 및 청소비', '개별 세대 전기료', '개별 세대 인터넷 요금', '개인 차량 유지비', 1),
  (4, '입주자대표회의 의사록 작성 시 반드시 포함되어야 할 내용은?', '회의 일시, 참석자, 의결사항 및 표결 결과', '참석자의 개인 취향', '회의와 무관한 잡담 내용', '관리소장의 개인 일정', 1),
  (5, '관리비 연체 시 관리주체가 취할 수 있는 일반적인 조치는?', '연체료 부과 및 납부 독촉', '즉시 단전·단수 조치(법령 검토 없이)', '무조건 소송 진행', '아무 조치 없이 방치', 1),
  (6, '민원 처리 시 가장 우선되어야 하는 원칙은?', '사실 확인 후 신속하고 공정한 처리', '민원인의 요구를 무조건 수용', '민원을 최대한 미루기', '담당자 임의 판단으로 종결', 1),
  (7, '공동주택관리법상 관리사무소장의 주요 업무가 아닌 것은?', '개별 세대의 사적 재산 관리', '공용부분 유지관리', '관리비 운영 관리', '안전관리 계획 수립', 1),
  (8, '장기수선계획 수립 시 고려해야 할 요소는?', '건물 주요 시설의 예상 수선 주기와 소요 비용', '입주자의 개인 취향', '관리소장의 개인 선호', '외부 상가 임대료', 1),
  (9, '관리규약 위반 행위에 대한 일반적인 처리 절차로 옳은 것은?', '사실 확인 → 시정 요청 → 필요 시 관리단 의결에 따른 조치', '즉시 강제 퇴거', '무조건 벌금 부과', '조치 없이 방치', 1),
  (10, '관리사무소의 행정서류(회계자료 등) 보관과 관련한 원칙은?', '법령에서 정한 기간 동안 체계적으로 보관', '즉시 폐기', '개인이 임의로 보관', '전자문서는 보관 대상 제외', 1)
) as v(question_no, question_text, option_1, option_2, option_3, option_4, correct_option)
on true
where c.slug = 'facility-admin';

-- 4-7) 환경위생실무관리사
insert into public.cert_exam_questions
  (exam_id, question_no, question_text, option_1, option_2, option_3, option_4, correct_option, points, sort_order)
select e.id, v.question_no, v.question_text, v.option_1, v.option_2, v.option_3, v.option_4, v.correct_option, 10, v.question_no
from public.cert_exams e
join public.cert_courses c on c.id = e.course_id
join (values
  (1, '먹는물관리법상 저수조 청소의 일반적인 권장 주기는?', '반기 1회 이상(연 2회 이상)', '10년에 1회', '청소 의무 없음', '입주민 요청 시에만', 1),
  (2, '저수조 소독에 일반적으로 사용되는 약품은?', '차아염소산나트륨 등 소독제', '식용유', '세제 원액만 사용', '소독 없이 물로만 세척', 1),
  (3, '실내공기질 관리 항목에 해당하는 것은?', '미세먼지(PM10), 이산화탄소 농도', '건물 외벽 색상', '주차장 면적', '조경수 종류', 1),
  (4, '해충 방역 관리에서 가장 우선되는 예방적 조치는?', '서식 환경 제거(청소, 습기 관리 등)', '방역 없이 방치', '살충제만 반복 살포', '민원 발생 후에만 조치', 1),
  (5, '수질 검사 결과 부적합 판정을 받았을 때 취해야 할 조치는?', '원인 파악 후 저수조 청소·소독 및 재검사', '결과를 무시하고 계속 사용', '검사 자체를 중단', '수질과 무관하게 방치', 1),
  (6, '저수조 관리 기록에 포함되어야 할 항목은?', '청소·소독 일자 및 수질검사 결과', '입주민 개인정보', '관리소장의 개인 일정', '주변 상가 정보', 1),
  (7, '실내공기질 측정 시 일반적으로 측정하는 대상 공간은?', '다중이용시설 및 공동 공간(로비, 지하주차장 등)', '개별 세대 내부만', '건물 외부 공터', '옥상 정원만', 1),
  (8, '레지오넬라균 등 수계 감염병 예방을 위한 관리 방법은?', '냉각탑수 및 급수설비의 정기적 소독·청소', '예방 조치 불필요', '온도를 무조건 낮게만 유지', '검사 없이 방치', 1),
  (9, '환경위생 점검표 작성 시 반드시 기록해야 할 사항은?', '점검일자, 점검자, 점검 결과 및 조치 내용', '점검자의 개인 취향', '당일 날씨 정보만', '주변 교통 상황', 1),
  (10, '공동주택 저수조 및 물탱크 위생관리의 최종 목적은?', '입주민에게 안전한 먹는물 공급', '관리비 절감만을 위한 형식적 조치', '민원 감소만을 위한 조치', '외관 미화', 1)
) as v(question_no, question_text, option_1, option_2, option_3, option_4, correct_option)
on true
where c.slug = 'environmental-hygiene';

-- 4-8) 경리회계실무관리사
insert into public.cert_exam_questions
  (exam_id, question_no, question_text, option_1, option_2, option_3, option_4, correct_option, points, sort_order)
select e.id, v.question_no, v.question_text, v.option_1, v.option_2, v.option_3, v.option_4, v.correct_option, 10, v.question_no
from public.cert_exams e
join public.cert_courses c on c.id = e.course_id
join (values
  (1, '집합건물 관리비 회계에서 복식부기의 기본 원리는?', '거래를 자산·부채·자본 등 계정에 이중으로 기록', '모든 거래를 현금 입출금으로만 기록', '연말에 한 번만 기록', '관리소장이 임의로 기록', 1),
  (2, '연간 관리비 예산을 편성할 때 우선적으로 고려해야 할 사항은?', '전년도 집행 내역과 향후 수선계획', '입주민의 개인 취향', '관리직원의 개인 일정', '주변 상가 임대료', 1),
  (3, '부가가치세 신고와 관련하여 관리사무소가 유의해야 할 사항은?', '과세·면세 대상 구분 및 신고 기한 준수', '신고 기한과 무관하게 처리', '세금계산서 발급 없이 처리', '신고 자체를 생략', 1),
  (4, '원천징수의 주된 목적은?', '소득 지급 시 세금을 미리 징수하여 납부', '지급액을 늘리기 위함', '직원 복지 향상', '관리비 절감', 1),
  (5, '4대보험 신고 대상에 해당하지 않는 것은?', '국민연금·건강보험·고용보험·산재보험', '자동차보험', '건강보험', '고용보험', 1),
  (6, '재무상태표에서 확인할 수 있는 정보는?', '특정 시점의 자산·부채·자본 현황', '한 해 동안의 매출액만', '입주민 명단', '주차장 이용 현황', 1),
  (7, '외부감사 대응 시 우선적으로 준비해야 할 자료는?', '회계 증빙자료 및 장부의 정합성 확인', '입주민 개인정보', '관리직원 이력서', '건물 도면만', 1),
  (8, '장기수선충당금의 회계 처리에서 중요한 점은?', '용도에 맞게 별도 계정으로 구분 관리', '일반 관리비와 통합하여 관리', '연말에 전액 소진', '회계 처리 대상 아님', 1),
  (9, '관리비 고지서 작성 시 반드시 포함되어야 할 항목은?', '항목별 부과 내역과 납부 기한', '입주민의 개인 취향', '관리소장의 개인 의견', '주변 상가 정보', 1),
  (10, '관리비 미납 세대에 대한 일반적인 회계·행정 절차는?', '연체 내역 기록 및 납부 독촉 절차 진행', '즉시 단전·단수(법령 검토 없이)', '미납 내역을 기록하지 않음', '전체 입주민에게 책임 전가', 1)
) as v(question_no, question_text, option_1, option_2, option_3, option_4, correct_option)
on true
where c.slug = 'accounting-practice';

-- 4-9) 환경미화관리사
insert into public.cert_exam_questions
  (exam_id, question_no, question_text, option_1, option_2, option_3, option_4, correct_option, points, sort_order)
select e.id, v.question_no, v.question_text, v.option_1, v.option_2, v.option_3, v.option_4, v.correct_option, 10, v.question_no
from public.cert_exams e
join public.cert_courses c on c.id = e.course_id
join (values
  (1, '환경미화 작업 시 개인보호장비(PPE)를 착용해야 하는 주된 이유는?', '화학약품 및 작업 위험으로부터 신체 보호', '작업 속도 향상', '외관을 깔끔하게 보이기 위함', '규정상 형식적 절차', 1),
  (2, '세제 사용 시 라벨의 희석 비율을 지켜야 하는 이유는?', '적정 세척 효과 확보 및 안전사고 예방', '세제를 빨리 소진하기 위함', '냄새를 강하게 하기 위함', '비용을 늘리기 위함', 1),
  (3, 'MSDS(물질안전보건자료)의 주된 용도는?', '화학물질의 위험성과 안전한 취급 방법 확인', '제품 가격 정보 확인', '제품 디자인 확인', '재고 관리용 문서', 1),
  (4, '대리석 바닥 청소 시 산성 세제 사용을 피해야 하는 이유는?', '대리석 표면이 부식·손상될 수 있음', '냄새가 강해짐', '가격이 비쌈', '색상이 진해짐', 1),
  (5, '카펫 세척 방법 중 습식 세척의 특징은?', '세제와 물을 이용해 깊은 오염까지 제거', '물을 전혀 사용하지 않음', '세제만 뿌리고 방치', '진공청소기만 사용', 1),
  (6, '감염병 예방을 위한 소독 작업 시 우선 고려사항은?', '적정 소독제 선택과 접촉면 충분한 소독시간 확보', '소독제를 최대한 적게 사용', '환기 없이 밀폐된 상태로 작업', '소독 후 즉시 사용 재개', 1),
  (7, '폐기물 분류 작업에서 가장 중요한 원칙은?', '일반·재활용·유해 폐기물의 정확한 구분', '모든 폐기물을 한 곳에 모음', '분류 없이 소각', '분류는 입주민의 책임', 1),
  (8, '유리창 청소 시 고소작업이 필요한 경우 우선되어야 하는 것은?', '안전장비 착용 및 추락 방지 조치', '작업 시간 단축', '비용 절감', '작업 인원 최소화', 1),
  (9, '일일·주간·월간 청소 스케줄을 수립하는 목적은?', '구역별 청소 품질을 체계적으로 관리하기 위함', '작업자의 개인 일정 관리', '관리비 절감만을 위한 형식적 문서', '입주민 민원 대응용 문서', 1),
  (10, '청소 품질 점검 시 확인해야 할 사항은?', '구역별 청소 상태 및 미흡 사항 개선 여부', '작업자의 개인 취향', '당일 날씨 정보만', '주변 상가 정보', 1)
) as v(question_no, question_text, option_1, option_2, option_3, option_4, correct_option)
on true
where c.slug = 'cleaning-management';

-- ---------------------------------------------------------------------
-- 5. 검증 쿼리
-- ---------------------------------------------------------------------
-- select id, title, slug, category, edu_method from public.cert_courses order by sort_order;
-- select course_id, count(*) from public.cert_curriculum group by course_id;
-- select exam_id, count(*) from public.cert_exam_questions group by exam_id;
