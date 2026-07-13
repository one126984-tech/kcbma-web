-- =====================================================================
-- KCBMA videos 테이블 리셋 — 5개 실제 영상 깔끔하게 재삽입
-- 실행 방법:
--   1. https://supabase.com/dashboard/project/ehrahnnowwjkgycvlbzk/sql/new
--   2. 전체 복사 → 붙여넣기 → [Run] (한 번만!)
-- =====================================================================

-- 1) 기존 데이터 전부 삭제 + id 시퀀스 초기화
truncate table public.videos restart identity;

-- 2) 5개 영상 한꺼번에 INSERT
insert into public.videos (title, description, youtube_id, category, is_published) values
  ('시설관리 영상 1', '대한집합건물관리협회 시설관리 관련 영상 (1편)', 'z3L4ir1vTfk', '시설관리', true),
  ('시설관리 영상 2', '대한집합건물관리협회 시설관리 관련 영상 (2편)', 'z-e6oMgHUwQ', '시설관리', true),
  ('시설관리 영상 3', '대한집합건물관리협회 시설관리 관련 영상 (3편)', 'h5kTi7c5Aoc', '시설관리', true),
  ('시설관리 영상 4', '대한집합건물관리협회 시설관리 관련 영상 (4편)', 'oft_W1Nyny4', '시설관리', true),
  ('시설관리 영상 5', '대한집합건물관리협회 시설관리 관련 영상 (5편)', 'zjGBpHwbAAw', '시설관리', true);

-- 3) 검증 — 5개 서로 다른 youtube_id가 나와야 정상
select id, title, youtube_id from public.videos order by id;
