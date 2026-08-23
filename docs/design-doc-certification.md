# 대한집합건물관리협회 — 자격증 교육 플랫폼 설계 문서

> **버전:** v1.0  
> **작성일:** 2026-08-15  
> **참고:** [한국자격증협회(korea-kca.com)](https://korea-kca.com) 벤치마킹  

---

## 1. 프로젝트 개요

### 1.1 목적
기존 대한집합건물관리협회(KCBMA) 웹사이트의 원격교육 기능을 확장하여,  
**집합건물 관리 분야 전문 자격증 교육·발급 플랫폼**으로 발전시킨다.

### 1.2 대상 사용자
| 사용자 유형 | 설명 |
|-------------|------|
| **수강생** | 집합건물 관리인, 시설관리 종사자, 취업 준비생 |
| **관리자** | 협회 운영진 (과정 등록, 수강 관리, 자격증 발급) |
| **강사** | 자격증 과정 교수진 (강의 콘텐츠 제공) |

### 1.3 핵심 가치
- **전문성** — 집합건물 관리 분야 특화 자격증
- **접근성** — 온라인 VOD/실시간 강의로 시공간 제약 없이 학습
- **신뢰성** — 협회 공식 인증 자격증 발급

### 1.4 자격증 과정 목록
| # | 자격증명 | 분야 |
|---|----------|------|
| 1 | 기전당직실무관리사 | 기전 |
| 2 | 전기방재설비관리사 | 전기/방재 |
| 3 | 기계설비실무관리사 | 기계 |
| 4 | 건물영선실무관리사 | 영선/건축 |
| 5 | 배관설비실무관리사 | 배관 |
| 6 | 시설행정실무관리사 | 행정 |
| 7 | 환경위생실무관리사 | 환경/위생 |

---

## 2. 기능 명세

### 2.1 자격증 과정 목록 페이지
korea-kca.com의 카드형 UI를 차용하되, 기존 사이트의 디자인 시스템을 유지한다.

| 기능 | 설명 |
|------|------|
| **카드형 그리드** | 3열 그리드, 과정 썸네일/제목/분야/수강료/접수상태 표시 |
| **필터링** | 분야별(기전/전기/기계/영선/배관/행정/환경), 방식별(VOD/실시간/혼합), 접수상태별 |
| **정렬** | 최신순, 인기순(수강 신청 수), 마감임박순 |
| **검색** | 과정명 키워드 검색 |
| **수강료 표시** | 정가 → 할인가(장학 지원) 표시, "100% 지원" 뱃지 |
| **실시간 피드** | 상단에 최근 수강완료/자격증발급 실시간 알림 표시 (korea-kca 스타일) |

### 2.2 과정 상세 페이지
| 섹션 | 내용 |
|------|------|
| **과정 기본 정보** | 자격증명, 분야, 수강 기간, 수강료, 접수 상태, 수강 방식 |
| **과정 소개** | 자격증 설명, 취득 후 활용 분야, 대상자 |
| **커리큘럼** | 차시별 강의 목록 (제목, 시간, 강의 유형) |
| **강사 정보** | 담당 교수 프로필 (사진, 이름, 약력) |
| **수강 안내** | 학습 방법, 수료 기준(진도율, 평가 점수), 자격증 발급 절차 |
| **수강 신청 CTA** | 로그인 상태에 따라 "수강 신청" 또는 "로그인 후 신청" 버튼 |

### 2.3 수강 신청 및 결제
| 단계 | 설명 |
|------|------|
| 1. 수강 신청 | 과정 상세에서 "수강 신청" 클릭 → 약관 동의 |
| 2. 결제 | 무료(장학 지원) 과정은 바로 수강 시작, 유료 과정은 결제 진행 |
| 3. 수강 확정 | 결제 완료 → enrollments 테이블에 레코드 생성 → 마이페이지에 표시 |

> **결제 시스템:** 1차는 무료(100% 장학지원) 과정으로 시작하여 결제 모듈 없이 출시.  
> 이후 토스페이먼츠 또는 아임포트(포트원) 연동 검토.

### 2.4 온라인 수강 (학습 플레이어)
| 기능 | 설명 |
|------|------|
| **VOD 수강** | 차시별 동영상 재생, 이어보기 지원, 진도율 자동 추적 |
| **실시간 강의** | Zoom 연동 링크 제공, 일정 표시 |
| **진도 관리** | 각 차시 시청 완료 여부 체크, 전체 진도율 % 표시 |
| **수료 판정** | 진도율 기준(예: 80% 이상) 충족 시 수료 처리 |

### 2.5 온라인 시험/평가
| 기능 | 설명 |
|------|------|
| **시험 응시** | 진도율 기준 충족 후 시험 응시 가능 |
| **문제 유형** | 객관식(4지선다), 자동 채점 |
| **합격 기준** | 과정별 설정(예: 60점 이상) |
| **재시험** | 불합격 시 재응시 가능 (횟수 제한 설정 가능) |

### 2.6 자격증 발급
| 기능 | 설명 |
|------|------|
| **자동 발급 트리거** | 수료 + 시험 합격 시 발급 가능 상태로 전환 |
| **발급 신청** | 마이페이지에서 발급 신청 |
| **자격증 번호** | 고유 번호 자동 생성 (예: KCBMA-2026-ELC-00001) |
| **PDF 다운로드** | 자격증 이미지/PDF 생성 및 다운로드 |
| **발급 이력** | 발급일, 자격증 번호, 상태 관리 |

### 2.7 실시간 수강/발급 피드
korea-kca.com 스타일의 실시간 알림 피드.
```
✅ 수강완료  박*진  기전당직실무관리사  2026-08-15
📜 발급완료  이*영  전기방재설비관리사  2026-08-15
```
- 최근 수강완료/자격증발급 데이터를 Supabase에서 실시간 조회
- 이름은 마스킹 처리 (첫 글자 + * + 마지막 글자)
- 메인 페이지 및 자격증 목록 페이지 상단에 표시

### 2.8 회원 마이페이지
| 섹션 | 내용 |
|------|------|
| **내 정보** | 프로필, 이름, 이메일, 가입일 |
| **수강 현황** | 신청한 과정 목록, 진도율, 수강 상태(수강중/수료/미수료) |
| **시험 결과** | 응시 과목, 점수, 합격 여부 |
| **자격증 관리** | 발급된 자격증 목록, PDF 다운로드, 자격증 번호 조회 |

### 2.9 관리자 페이지
| 기능 | 설명 |
|------|------|
| **과정 관리** | 자격증 과정 CRUD, 커리큘럼(차시) 관리, 강사 배정 |
| **동영상 관리** | 차시별 영상 업로드/URL 등록 |
| **시험 관리** | 문제 등록, 합격 기준 설정 |
| **수강생 관리** | 수강 신청 현황, 진도율 확인, 수료 처리 |
| **자격증 발급 관리** | 발급 신청 승인/반려, 발급 이력 조회 |
| **통계 대시보드** | 수강 신청 수, 수료율, 발급 건수 통계 |

---

## 3. 페이지 구조 (사이트맵)

```
kcbma-web/
├── index.html                          # 메인 홈페이지
├── login.html                          # 로그인 (기존)
├── callback.html                       # OAuth 콜백 (기존)
│
├── pages/
│   ├── about/                          # 협회소개 (기존)
│   │   ├── greeting.html
│   │   ├── history.html
│   │   ├── notice-detail.html
│   │   └── notice-write.html
│   │
│   ├── edu/                            # 교육/실습
│   │   ├── edu-online-list.html        # 원격교육 목록 (기존 → 확장)
│   │   ├── edu-online-detail.html      # 원격교육 상세 (신규)
│   │   ├── edu-field-list.html         # 현장교육 목록 (기존)
│   │   ├── edu-seminar-list.html       # 세미나 목록 (기존)
│   │   └── edu-player.html             # 수강 플레이어 (신규)
│   │
│   ├── cert/                           # ⭐ 자격증 (신규 섹션)
│   │   ├── cert-list.html              # 자격증 과정 목록
│   │   ├── cert-detail.html            # 자격증 과정 상세
│   │   ├── cert-enroll.html            # 수강 신청 확인
│   │   ├── cert-player.html            # 자격증 강의 수강 플레이어
│   │   ├── cert-exam.html              # 온라인 시험
│   │   └── cert-verify.html            # 자격증 진위 확인 (공개)
│   │
│   ├── mypage/                         # ⭐ 마이페이지 (신규 섹션)
│   │   ├── dashboard.html              # 대시보드 (수강 현황 요약)
│   │   ├── my-courses.html             # 내 수강 목록
│   │   ├── my-certs.html               # 내 자격증
│   │   ├── my-exams.html               # 시험 결과
│   │   └── my-profile.html             # 내 정보 수정
│   │
│   ├── admin/                          # ⭐ 관리자 (신규 섹션)
│   │   ├── admin-dashboard.html        # 관리자 대시보드
│   │   ├── admin-courses.html          # 과정 관리
│   │   ├── admin-course-edit.html      # 과정 등록/수정
│   │   ├── admin-curriculum.html       # 커리큘럼(차시) 관리
│   │   ├── admin-exams.html            # 시험 문제 관리
│   │   ├── admin-enrollments.html      # 수강생 관리
│   │   ├── admin-certs.html            # 자격증 발급 관리
│   │   └── admin-stats.html            # 통계
│   │
│   ├── bid/                            # 입찰공고 (기존)
│   ├── jobs/                           # 구인구직 (기존)
│   ├── comunity/                       # 커뮤니티 (기존)
│   ├── partners/                       # 협력사 (기존)
│   └── policy/                         # 정책 (기존)
│
├── assets/
│   ├── css/style.css
│   ├── img/
│   └── js/
│       ├── auth.js                     # 인증 (기존)
│       ├── header.js                   # 헤더 (기존)
│       ├── footer.js                   # 푸터 (기존)
│       ├── main.js                     # 메인 (기존)
│       ├── supabase-config.js          # ⭐ Supabase 설정 통합 (신규)
│       ├── cert.js                     # ⭐ 자격증 과정 로직 (신규)
│       ├── player.js                   # ⭐ 강의 플레이어 로직 (신규)
│       ├── exam.js                     # ⭐ 시험 로직 (신규)
│       └── mypage.js                   # ⭐ 마이페이지 로직 (신규)
│
└── supabase/
    ├── 01_videos.sql                   # (기존)
    ├── 02_videos_real.sql              # (기존)
    ├── 03_videos_reset.sql             # (기존)
    ├── 04_jobs.sql                     # (기존)
    ├── 05_cert_courses.sql             # ⭐ 자격증 과정 테이블 (신규)
    ├── 06_cert_curriculum.sql          # ⭐ 커리큘럼 테이블 (신규)
    ├── 07_cert_enrollments.sql         # ⭐ 수강 신청 테이블 (신규)
    ├── 08_cert_progress.sql            # ⭐ 수강 진도 테이블 (신규)
    ├── 09_cert_exams.sql               # ⭐ 시험/문제 테이블 (신규)
    ├── 10_cert_certificates.sql        # ⭐ 자격증 발급 테이블 (신규)
    └── 11_cert_seed.sql                # ⭐ 초기 데이터 시드 (신규)
```

---

## 4. DB 스키마 설계

기존 Supabase 프로젝트(`ehrahnnowwjkgycvlbzk`)에 테이블을 추가한다.  
기존 `master_board` 테이블의 교육 데이터와 분리하여 전용 테이블을 설계한다.

### 4.1 cert_courses (자격증 과정)
```sql
create table public.cert_courses (
  id              bigserial primary key,
  title           text not null,                    -- 자격증명 (예: 기전당직실무관리사)
  slug            text not null unique,             -- URL용 슬러그 (예: electrical-duty)
  category        text not null,                    -- 분야 (기전/전기/기계/영선/배관/행정/환경)
  description     text,                             -- 과정 소개 (HTML 허용)
  thumbnail_url   text,                             -- 썸네일 이미지 URL
  
  edu_method      text not null default 'VOD',      -- 수강 방식 (VOD/LIVE/MIX)
  edu_period      text,                             -- 수강 기간 (예: '신청일로부터 30일')
  
  original_price  integer not null default 0,       -- 정가 (원)
  discount_price  integer not null default 0,       -- 할인가 (0이면 무료)
  is_free         boolean not null default true,    -- 무료 여부 (장학 지원)
  
  pass_criteria   jsonb default '{"progress_rate": 80, "exam_score": 60}'::jsonb,
                                                    -- 수료 기준 (진도율 %, 시험 점수)
  
  instructor_name text,                             -- 담당 강사명
  instructor_bio  text,                             -- 강사 약력
  instructor_img  text,                             -- 강사 사진 URL
  
  status          text not null default 'OPEN',     -- 접수 상태 (OPEN/CLOSED/UPCOMING)
  sort_order      integer not null default 0,       -- 정렬 순서
  view_count      integer not null default 0,       -- 조회수
  enroll_count    integer not null default 0,       -- 수강 신청 수
  
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  
  constraint cert_courses_status_ok check (status in ('OPEN','CLOSED','UPCOMING')),
  constraint cert_courses_method_ok check (edu_method in ('VOD','LIVE','MIX'))
);

create index cert_courses_category_idx on public.cert_courses (category);
create index cert_courses_status_idx on public.cert_courses (status);
create index cert_courses_sort_idx on public.cert_courses (sort_order, created_at desc);
```

### 4.2 cert_curriculum (커리큘럼/차시)
```sql
create table public.cert_curriculum (
  id              bigserial primary key,
  course_id       bigint not null references public.cert_courses(id) on delete cascade,
  
  chapter_no      integer not null,                 -- 차시 번호
  title           text not null,                    -- 강의 제목
  duration_min    integer not null default 0,       -- 강의 시간 (분)
  
  content_type    text not null default 'VOD',      -- VOD / LIVE / DOCUMENT
  video_url       text,                             -- 동영상 URL (YouTube, Vimeo, Storage 등)
  zoom_link       text,                             -- 실시간 강의 Zoom 링크
  zoom_datetime   timestamptz,                      -- 실시간 강의 일시
  
  is_preview      boolean not null default false,   -- 미리보기 가능 여부
  sort_order      integer not null default 0,
  
  created_at      timestamptz not null default now(),
  
  constraint cert_curriculum_type_ok check (content_type in ('VOD','LIVE','DOCUMENT'))
);

create index cert_curriculum_course_idx on public.cert_curriculum (course_id, chapter_no);
```

### 4.3 cert_enrollments (수강 신청)
```sql
create table public.cert_enrollments (
  id              bigserial primary key,
  user_id         uuid not null references auth.users(id) on delete cascade,
  course_id       bigint not null references public.cert_courses(id) on delete cascade,
  
  status          text not null default 'ACTIVE',   -- ACTIVE(수강중) / COMPLETED(수료) / EXPIRED(만료) / CANCELLED(취소)
  enrolled_at     timestamptz not null default now(),
  completed_at    timestamptz,                      -- 수료 일시
  expires_at      timestamptz,                      -- 수강 만료일
  
  progress_rate   numeric(5,2) not null default 0,  -- 전체 진도율 (%)
  
  payment_amount  integer not null default 0,       -- 결제 금액
  payment_method  text,                             -- 결제 수단
  payment_id      text,                             -- 외부 결제 ID
  
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  
  constraint cert_enrollments_status_ok check (status in ('ACTIVE','COMPLETED','EXPIRED','CANCELLED')),
  constraint cert_enrollments_unique unique (user_id, course_id)
);

create index cert_enrollments_user_idx on public.cert_enrollments (user_id);
create index cert_enrollments_course_idx on public.cert_enrollments (course_id);
create index cert_enrollments_status_idx on public.cert_enrollments (status);
```

### 4.4 cert_progress (수강 진도)
```sql
create table public.cert_progress (
  id              bigserial primary key,
  enrollment_id   bigint not null references public.cert_enrollments(id) on delete cascade,
  curriculum_id   bigint not null references public.cert_curriculum(id) on delete cascade,
  
  is_completed    boolean not null default false,   -- 해당 차시 수강 완료 여부
  watch_seconds   integer not null default 0,       -- 시청 시간 (초)
  last_position   integer not null default 0,       -- 마지막 재생 위치 (초, 이어보기용)
  completed_at    timestamptz,                      -- 완료 일시
  
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  
  constraint cert_progress_unique unique (enrollment_id, curriculum_id)
);

create index cert_progress_enrollment_idx on public.cert_progress (enrollment_id);
```

### 4.5 cert_exams (시험)
```sql
create table public.cert_exams (
  id              bigserial primary key,
  course_id       bigint not null references public.cert_courses(id) on delete cascade,
  
  title           text not null default '자격 평가',
  time_limit_min  integer not null default 60,      -- 제한 시간 (분)
  pass_score      integer not null default 60,      -- 합격 점수
  max_attempts    integer not null default 3,       -- 최대 응시 횟수
  
  is_active       boolean not null default true,
  created_at      timestamptz not null default now()
);

create index cert_exams_course_idx on public.cert_exams (course_id);
```

### 4.6 cert_exam_questions (시험 문제)
```sql
create table public.cert_exam_questions (
  id              bigserial primary key,
  exam_id         bigint not null references public.cert_exams(id) on delete cascade,
  
  question_no     integer not null,                 -- 문제 번호
  question_text   text not null,                    -- 문제 내용
  
  option_1        text not null,                    -- 선택지 1
  option_2        text not null,                    -- 선택지 2
  option_3        text not null,                    -- 선택지 3
  option_4        text not null,                    -- 선택지 4
  correct_option  integer not null,                 -- 정답 번호 (1~4)
  
  points          integer not null default 1,       -- 배점
  explanation     text,                             -- 해설
  
  sort_order      integer not null default 0,
  created_at      timestamptz not null default now(),
  
  constraint cert_questions_correct_ok check (correct_option between 1 and 4)
);

create index cert_questions_exam_idx on public.cert_exam_questions (exam_id, question_no);
```

### 4.7 cert_exam_attempts (시험 응시 기록)
```sql
create table public.cert_exam_attempts (
  id              bigserial primary key,
  user_id         uuid not null references auth.users(id) on delete cascade,
  exam_id         bigint not null references public.cert_exams(id) on delete cascade,
  enrollment_id   bigint not null references public.cert_enrollments(id) on delete cascade,
  
  attempt_no      integer not null default 1,       -- 응시 회차
  score           numeric(5,2),                     -- 획득 점수
  total_points    integer,                          -- 총점
  is_passed       boolean not null default false,   -- 합격 여부
  
  answers         jsonb,                            -- 답안 데이터 [{q_id, selected, is_correct}]
  
  started_at      timestamptz not null default now(),
  submitted_at    timestamptz,                      -- 제출 일시
  
  created_at      timestamptz not null default now()
);

create index cert_attempts_user_idx on public.cert_exam_attempts (user_id);
create index cert_attempts_exam_idx on public.cert_exam_attempts (exam_id);
create index cert_attempts_enrollment_idx on public.cert_exam_attempts (enrollment_id);
```

### 4.8 cert_certificates (자격증 발급)
```sql
create table public.cert_certificates (
  id              bigserial primary key,
  user_id         uuid not null references auth.users(id) on delete cascade,
  course_id       bigint not null references public.cert_courses(id) on delete cascade,
  enrollment_id   bigint not null references public.cert_enrollments(id) on delete cascade,
  
  cert_number     text not null unique,             -- 자격증 번호 (KCBMA-2026-ELC-00001)
  cert_name       text not null,                    -- 자격증명
  holder_name     text not null,                    -- 취득자 이름
  
  status          text not null default 'ISSUED',   -- ISSUED(발급) / REVOKED(취소)
  issued_at       timestamptz not null default now(),
  expires_at      timestamptz,                      -- 유효기간 (null = 영구)
  
  pdf_url         text,                             -- 발급된 자격증 PDF URL
  
  created_at      timestamptz not null default now(),
  
  constraint cert_certificates_status_ok check (status in ('ISSUED','REVOKED'))
);

create index cert_certificates_user_idx on public.cert_certificates (user_id);
create index cert_certificates_number_idx on public.cert_certificates (cert_number);
create index cert_certificates_course_idx on public.cert_certificates (course_id);
```

### 4.9 cert_activity_feed (실시간 피드용)
```sql
create table public.cert_activity_feed (
  id              bigserial primary key,
  
  activity_type   text not null,                    -- ENROLL / COMPLETE / CERT_ISSUED
  user_name       text not null,                    -- 마스킹된 이름 (예: 박*진)
  course_title    text not null,                    -- 자격증/과정명
  
  created_at      timestamptz not null default now(),
  
  constraint cert_feed_type_ok check (activity_type in ('ENROLL','COMPLETE','CERT_ISSUED'))
);

create index cert_feed_created_idx on public.cert_activity_feed (created_at desc);
```

### 4.10 ER 다이어그램 (관계도)

```
┌──────────────────┐     ┌──────────────────┐
│   cert_courses   │────<│  cert_curriculum │
│                  │     └──────────────────┘
│                  │
│                  │────<┌──────────────────┐     ┌────────────────────┐
│                  │     │  cert_exams      │────<│ cert_exam_questions│
└──────────────────┘     └──────────────────┘     └────────────────────┘
        │                        │
        │                        │
        ▼                        ▼
┌──────────────────┐     ┌──────────────────────┐
│cert_enrollments  │────<│  cert_exam_attempts   │
│  (user_id FK)    │     │  (user_id FK)         │
└──────────────────┘     └──────────────────────┘
        │
        │
        ▼
┌──────────────────┐     ┌──────────────────┐
│  cert_progress   │     │cert_certificates │
│                  │     │  (user_id FK)     │
└──────────────────┘     └──────────────────┘
```

### 4.11 RLS 정책 요약
| 테이블 | SELECT | INSERT | UPDATE | DELETE |
|--------|--------|--------|--------|--------|
| cert_courses | 모두 (OPEN/CLOSED) | 관리자만 | 관리자만 | 관리자만 |
| cert_curriculum | 모두 | 관리자만 | 관리자만 | 관리자만 |
| cert_enrollments | 본인 것만 | 인증된 사용자 (본인) | 관리자 + 본인 | 관리자만 |
| cert_progress | 본인 것만 | 인증된 사용자 (본인) | 본인 | - |
| cert_exams | 수강 중인 사용자 | 관리자만 | 관리자만 | 관리자만 |
| cert_exam_questions | 시험 응시 중 | 관리자만 | 관리자만 | 관리자만 |
| cert_exam_attempts | 본인 것만 | 인증된 사용자 | - (제출 후 변경 불가) | - |
| cert_certificates | 모두 (진위 확인용) | 시스템/관리자 | 관리자만 | - |
| cert_activity_feed | 모두 | 시스템만 | - | - |

> **관리자 판별:** `auth.users` 의 `raw_user_meta_data->>'role' = 'admin'` 또는 별도 `user_roles` 테이블 운영

---

## 5. UI/UX 설계

### 5.1 디자인 시스템 (기존 유지)
| 요소 | 값 |
|------|-----|
| **메인 컬러** | `#12387a` (네이비), `#0B2A5B` (다크 네이비) |
| **서브 컬러** | `#274bce` (활성 메뉴), `#0088cc` (링크/액센트) |
| **배경** | `#F8FAFC`, `#f9fafb` |
| **폰트** | Noto Sans KR (400/500/700/900) |
| **아이콘** | Font Awesome 6.4 |
| **프레임워크** | Tailwind CSS (CDN) |
| **라운딩** | 카드 `rounded-lg`, 버튼 `rounded`, 모달 `rounded-xl` |
| **그림자** | `shadow-sm` 기본, `shadow-md` 호버 |

### 5.2 korea-kca.com에서 차용할 UI 패턴

#### 5.2.1 자격증 과정 카드 (cert-list.html)
```
┌─────────────────────────────────┐
│ [접수중] 뱃지          👁 125  │
│                                 │
│  기전당직실무관리사              │
│  (과정 제목, 2줄 제한)          │
│                                 │
│ ┌─────────────────────────────┐ │
│ │ 분야     기전               │ │
│ │ 방식     동영상(VOD)        │ │
│ │ 기간     신청일로부터 30일  │ │
│ │ 수강료   400,000원 → 0원   │ │
│ └─────────────────────────────┘ │
│                                 │
│     [ 수강 신청하기 ]           │
└─────────────────────────────────┘
```

#### 5.2.2 실시간 피드 (korea-kca 스타일)
```
┌───────────────────────────────────────────────┐
│ ✅ 수강완료  박*진  기전당직실무관리사  08-15 │
│ 📜 발급완료  이*영  전기방재설비관리사  08-15 │
│ ✅ 수강완료  김*수  기계설비실무관리사  08-15 │
└───────────────────────────────────────────────┘
```
- 세로 스크롤 애니메이션 (자동 롤링)

#### 5.2.3 과정 상세 페이지 레이아웃
```
┌──────────────────────────────────────────┐
│  [사이드바]  │  과정 상세 콘텐츠         │
│             │                            │
│  자격증     │  ┌──────────────────────┐  │
│  과정 목록  │  │  과정명 + 상태 뱃지  │  │
│             │  │  분야 / 방식 / 기간  │  │
│  원격 교육  │  │  수강료 표시         │  │
│  현장 교육  │  │  [수강 신청 버튼]    │  │
│             │  └──────────────────────┘  │
│             │                            │
│             │  ── 과정 소개 ──           │
│             │  ── 커리큘럼 ──            │
│             │  ── 강사 정보 ──           │
│             │  ── 수강 안내 ──           │
└──────────────────────────────────────────┘
```

### 5.3 네비게이션 메뉴 변경
기존 메인 네비게이션에 **"자격증"** 메뉴를 추가한다.

```
협회소개 | 정보교류 | 입찰공고 | 구인구직 | 교육/실습 | ⭐자격증 | 커뮤니티
```

사이드바 메뉴에도 추가:
```
[자격증 과정]  ← 활성
[원격 교육]
[현장 교육]
```

---

## 6. 기술 아키텍처

### 6.1 프론트엔드
기존 순수 HTML/JS/Tailwind CSS 스택을 유지한다. 프레임워크(React/Next.js 등) 도입은 하지 않는다.

| 항목 | 기술 |
|------|------|
| **마크업** | HTML5 |
| **스타일링** | Tailwind CSS (CDN) + 인라인 `<style>` |
| **인터렉션** | Vanilla JavaScript (ES6+) |
| **HTTP** | Supabase JS Client (CDN) |
| **폰트** | Google Fonts (Noto Sans KR) |
| **아이콘** | Font Awesome 6 (CDN) |

#### Supabase 설정 통합
현재 각 HTML 파일마다 SUPABASE_URL/KEY가 중복 선언되어 있다.  
→ `assets/js/supabase-config.js`로 통합하여 모든 페이지에서 import.

```javascript
// assets/js/supabase-config.js
const SUPABASE_URL = 'https://ehrahnnowwjkgycvlbzk.supabase.co';
const SUPABASE_KEY = '...anon key...';
window.sb = window.supabase.createClient(SUPABASE_URL, SUPABASE_KEY);
```

### 6.2 백엔드 (Supabase)

| 기능 | Supabase 서비스 |
|------|-----------------|
| **인증** | Supabase Auth (이메일, Google, Naver, Kakao — 기존) |
| **데이터베이스** | PostgreSQL (기존 프로젝트에 테이블 추가) |
| **보안** | RLS (Row Level Security) 정책 |
| **파일 저장** | Supabase Storage (강의 영상, 자격증 PDF, 썸네일) |
| **서버리스** | Supabase Edge Functions (자격증 번호 생성, PDF 생성) |
| **실시간** | Supabase Realtime (실시간 피드 구독) |

### 6.3 영상 호스팅 전략
| 옵션 | 설명 | 추천 |
|------|------|------|
| YouTube (비공개) | 무료, 임베드 URL 제공 | ✅ Phase 1 |
| Vimeo | 유료, 보안 강화 (도메인 제한) | Phase 2 |
| Supabase Storage | 직접 호스팅, 비용 발생 | 소규모만 |

### 6.4 자격증 PDF 생성
- **Supabase Edge Function** (Deno) 으로 구현
- HTML 템플릿 → PDF 변환 (jsPDF 또는 서버사이드 Puppeteer)
- 생성된 PDF를 Supabase Storage에 저장
- cert_certificates 테이블의 pdf_url에 링크 기록

### 6.5 결제 시스템 (Phase 2)
| 단계 | 내용 |
|------|------|
| Phase 1 | 무료(100% 장학지원) 과정만 운영 → 결제 모듈 불필요 |
| Phase 2 | 토스페이먼츠 또는 포트원(구 아임포트) 연동 |

---

## 7. 구현 로드맵

### Phase 1: 핵심 기능 (MVP) — 2~3주
> 목표: 자격증 과정 목록/상세 조회 + 수강 신청 + VOD 수강 + 수료

| 순서 | 작업 | 산출물 |
|------|------|--------|
| 1-1 | Supabase 스키마 생성 | SQL 파일 (05~11번) |
| 1-2 | 초기 데이터 시드 (7개 자격증) | seed SQL |
| 1-3 | supabase-config.js 통합 | JS 파일 |
| 1-4 | 자격증 과정 목록 페이지 | cert-list.html |
| 1-5 | 자격증 과정 상세 페이지 | cert-detail.html |
| 1-6 | 수강 신청 기능 | cert-enroll.html + JS |
| 1-7 | VOD 수강 플레이어 | cert-player.html |
| 1-8 | 진도 추적 기능 | cert_progress 연동 |
| 1-9 | 마이페이지 (수강 현황) | mypage/dashboard.html, my-courses.html |
| 1-10 | 메인 네비게이션 업데이트 | header 수정 |

### Phase 2: 시험 & 자격증 발급 — 2주
> 목표: 온라인 시험 + 자격증 발급 + 실시간 피드

| 순서 | 작업 | 산출물 |
|------|------|--------|
| 2-1 | 온라인 시험 시스템 | cert-exam.html + exam.js |
| 2-2 | 자격증 발급 기능 | Edge Function + PDF 생성 |
| 2-3 | 자격증 진위 확인 페이지 | cert-verify.html |
| 2-4 | 마이페이지 확장 (시험/자격증) | my-exams.html, my-certs.html |
| 2-5 | 실시간 수강/발급 피드 | cert_activity_feed + 프론트 |
| 2-6 | 메인 홈페이지 자격증 섹션 추가 | index.html 수정 |

### Phase 3: 관리자 & 고도화 — 2주
> 목표: 관리자 페이지 + 결제 + 통계

| 순서 | 작업 | 산출물 |
|------|------|--------|
| 3-1 | 관리자 대시보드 | admin-dashboard.html |
| 3-2 | 과정 관리 (CRUD) | admin-courses.html |
| 3-3 | 커리큘럼 관리 | admin-curriculum.html |
| 3-4 | 시험 문제 관리 | admin-exams.html |
| 3-5 | 수강생/발급 관리 | admin-enrollments.html, admin-certs.html |
| 3-6 | 통계 대시보드 | admin-stats.html |
| 3-7 | 결제 연동 (선택) | 토스페이먼츠/포트원 |
| 3-8 | 실시간 Zoom 강의 연동 | 캘린더 + Zoom 링크 |

---

## 8. 기술적 고려사항

### 8.1 관리자 권한 관리
```sql
-- user_roles 테이블 또는 auth.users metadata 활용
-- 방법 1: metadata
update auth.users set raw_user_meta_data = 
  raw_user_meta_data || '{"role": "admin"}'::jsonb
where id = '관리자-user-id';

-- 방법 2: 별도 테이블
create table public.user_roles (
  user_id uuid primary key references auth.users(id),
  role text not null default 'member',
  constraint role_ok check (role in ('member','admin'))
);
```

### 8.2 자격증 번호 체계
```
KCBMA-{연도}-{분야코드}-{일련번호}

예시:
KCBMA-2026-ELC-00001  (기전당직실무관리사)
KCBMA-2026-FPE-00001  (전기방재설비관리사)
KCBMA-2026-MEC-00001  (기계설비실무관리사)
KCBMA-2026-BLD-00001  (건물영선실무관리사)
KCBMA-2026-PIP-00001  (배관설비실무관리사)
KCBMA-2026-ADM-00001  (시설행정실무관리사)
KCBMA-2026-ENV-00001  (환경위생실무관리사)
```

### 8.3 보안 주의사항
- Supabase anon key는 공개키이므로 RLS 정책이 반드시 필요
- 시험 정답은 클라이언트에 노출하지 않도록 Edge Function에서 채점
- 관리자 페이지는 RLS + 클라이언트 측 라우트 가드 모두 적용

---

## 부록: 기존 코드와의 호환성

| 기존 요소 | 처리 방식 |
|-----------|-----------|
| `master_board` 테이블 | 기존 교육(EDU) 데이터 유지, 자격증은 별도 테이블 |
| `auth.js` 인증 시스템 | 그대로 활용, supabaseClient 공유 |
| 헤더/푸터 구조 | header.js/footer.js 기존 패턴 유지 |
| 디자인 변수 | 기존 색상/폰트/스타일 그대로 사용 |
| 사이드바 패턴 | edu-online-list.html의 패턴을 cert 페이지에도 동일 적용 |

---

> **다음 단계:** 이 설계 문서를 검토/승인 후 Phase 1 구현을 시작합니다.
