-- =====================================================================
-- KCBMA videos 테이블 — 영상자료실용
-- 실행 방법:
--   1. https://supabase.com/dashboard/project/ehrahnnowwjkgycvlbzk/sql/new 접속
--   2. 아래 전체 복사해서 붙여넣기
--   3. 우측 하단 [Run] 클릭
-- =====================================================================

-- 1) 테이블 생성
create table if not exists public.videos (
  id            bigserial primary key,
  title         text        not null,                -- 영상 제목
  description   text,                                -- 설명 (선택)
  youtube_id    text        not null,                -- 유튜브 영상 ID (예: dQw4w9WgXcQ)
  category      text,                                -- 카테고리 (교육/세미나/공지 등)
  thumbnail_url text,                                -- 커스텀 썸네일 (없으면 유튜브 기본 사용)
  duration      text,                                -- "12:34" 형식 (선택)
  view_count    integer     default 0,               -- 조회수
  is_published  boolean     default true,            -- 공개 여부
  created_at    timestamptz default now(),
  updated_at    timestamptz default now()
);

-- 2) 인덱스 (목록 조회 성능)
create index if not exists videos_created_at_idx on public.videos (created_at desc);
create index if not exists videos_category_idx   on public.videos (category);
create index if not exists videos_published_idx  on public.videos (is_published);

-- 3) updated_at 자동 갱신 트리거
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end $$;

drop trigger if exists trg_videos_updated_at on public.videos;
create trigger trg_videos_updated_at
  before update on public.videos
  for each row execute function public.set_updated_at();

-- 4) RLS 활성화 + 정책
--    - 공개 SELECT: 누구나 published=true 인 영상 조회 가능
--    - INSERT/UPDATE/DELETE: 인증된 사용자만 (관리자 페이지에서 처리)
alter table public.videos enable row level security;

drop policy if exists "videos_public_read" on public.videos;
create policy "videos_public_read"
  on public.videos
  for select
  using (is_published = true);

drop policy if exists "videos_auth_write" on public.videos;
create policy "videos_auth_write"
  on public.videos
  for all
  to authenticated
  using (true)
  with check (true);

-- 5) 샘플 데이터 4건 (현재 videos.html 카드 개수에 맞춤)
--    실제 유튜브 ID로 교체하세요.
insert into public.videos (title, description, youtube_id, category, duration) values
  ('집합건물 관리 실무 세미나 1회',  '집합건물법 개정 사항 및 실무 적용', 'dQw4w9WgXcQ', '세미나', '45:12'),
  ('관리인 필수 교육 — 회계 편',    '아파트/오피스텔 관리비 회계 처리 기초', '9bZkp7q19f0', '교육',   '32:08'),
  ('입주자대표회의 운영 가이드',    '대표회의 의결·회의록 작성 실무',       'ScMzIvxBSi4', '교육',   '28:44'),
  ('협회 소식 — 2026 상반기',      '주요 활동 및 정책 브리핑',            'kJQP7kiw5Fk', '공지',   '15:20')
on conflict do nothing;

-- 6) 검증 쿼리 (실행 후 결과 확인용)
-- select id, title, youtube_id, category from public.videos order by id;
