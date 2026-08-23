-- =====================================================================
-- KCBMA videos 테이블 — 실제 협회 영상 5개로 교체
-- 실행 방법:
--   1. https://supabase.com/dashboard/project/ehrahnnowwjkgycvlbzk/sql/new
--   2. 전체 복사 → 붙여넣기 → [Run]
-- =====================================================================

-- 기존 샘플 4행 UPDATE (id 1~4)
update public.videos set
  youtube_id  = 'z3L4ir1vTfk',
  title       = '시설관리 영상 1',
  description = '대한집합건물관리협회 시설관리 관련 영상 (1편)',
  category    = '시설관리',
  duration    = null
where id = 1;

update public.videos set
  youtube_id  = 'z-e6oMgHUwQ',
  title       = '시설관리 영상 2',
  description = '대한집합건물관리협회 시설관리 관련 영상 (2편)',
  category    = '시설관리',
  duration    = null
where id = 2;

update public.videos set
  youtube_id  = 'h5kTi7c5Aoc',
  title       = '시설관리 영상 3',
  description = '대한집합건물관리협회 시설관리 관련 영상 (3편)',
  category    = '시설관리',
  duration    = null
where id = 3;

update public.videos set
  youtube_id  = 'oft_W1Nyny4',
  title       = '시설관리 영상 4',
  description = '대한집합건물관리협회 시설관리 관련 영상 (4편)',
  category    = '시설관리',
  duration    = null
where id = 4;

-- 5번째 영상 INSERT
insert into public.videos (title, description, youtube_id, category, is_published)
values (
  '시설관리 영상 5',
  '대한집합건물관리협회 시설관리 관련 영상 (5편)',
  'zjGBpHwbAAw',
  '시설관리',
  true
)
on conflict do nothing;

-- 검증
select id, title, youtube_id, category from public.videos order by id;
