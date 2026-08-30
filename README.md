# 사이트 빌드 시스템 사용법 (v2 — 5개 실제 페이지 반영)

## 이번 버전에서 바뀐 것

이전 버전은 job-list.html 하나만 보고 만들었는데, 실제로 about/bid-list/
resume-list/field-experience 파일을 받아보니 페이지마다 헤더와 전환
방식이 이미 4갈래로 갈라져 있었습니다. 이번에 전부 하나로 통일했습니다.

**표준으로 채택한 방식: View Transition API**
- about.html / resume-list.html에 이미 구현되어 있던, 페이지 이동 시
  헤더는 고정하고 나머지(#page-content)만 부드럽게 전환하는 네이티브
  브라우저 기능입니다. opacity 페이드보다 우월한 방식이라 이걸 표준으로
  삼았습니다.
- ⚠ 예전에 opacity 0→1 페이드 트릭을 같이 쓰면 "이중 페이드"로 흰 화면이
  더 도드라져 보이는 버그가 실제로 있었습니다 (resume-list.html 원본
  주석에 기록되어 있음). 그래서 이번 버전에서는 opacity 페이드 트릭을
  완전히 제거했습니다. 앞으로도 critical-css 파샬에 그런 트릭을 다시
  넣지 마세요.
- 크롬/엣지에서는 부드럽게 전환되고, 사파리/파이어폭스는 이 효과를
  무시하고 기존처럼 즉시 이동합니다 (정상적인 폴백 동작입니다).

**헤더도 통일**
- 원래 bid-list.html에만 있던 "현재 메뉴 파란색 강조" 기능을 전체
  페이지 공통으로 만들었습니다.
- 원래 job-list.html에만 있던 "같은 페이지 클릭 시 새로고침 안 함"
  가드를 모든 메뉴 항목에 적용했습니다.

## 폴더 구조

```
site/
  _partials/                    ← 공통 덩어리 원본. 고칠 때는 여기만 고침
    critical-css.html            (배경색 즉시 고정용, 아주 작음)
    view-transition-css.html     (페이지 전환 효과 — 새 표준)
    common-css.html              (스크롤바, 사이드메뉴, 헤더 버튼 스타일)
    header.html                  (로고, GNB, 모바일메뉴, 관련 스크립트)
  pages/
    about/about.src.html   → about.html
    jobs/job-list.src.html → job-list.html
    jobs/resume-list.src.html → resume-list.html
    bid/bid-list.src.html  → bid-list.html
    community/field-experience.src.html → field-experience.html
  build.js
  README.md
```

## 사용법은 이전과 동일

```
cd site
node build.js
```

`_partials/` 안의 파일 하나를 고치고 위 명령을 실행하면, `pages/` 아래
5개 페이지 전부가 자동으로 다시 만들어집니다.

## 새 페이지를 만들 때 반드시 넣어야 하는 4가지

1. 맨 위에 `<!-- @var PAGE_CLASS: page-이름 -->`
2. `<head>` 안에 순서대로:
   ```
   <!-- @include critical-css -->
   <!-- @include view-transition-css -->
   <!-- @include common-css -->
   ```
3. `<body class="flex flex-col h-screen overflow-hidden {{PAGE_CLASS}}">` 여는 태그 바로 아래에:
   ```
   <!-- @include header -->
   ```
4. 헤더 다음, 이 페이지의 실제 내용 전체를 감싸는 래퍼:
   ```html
   <div id="page-content" class="flex-1 flex flex-col overflow-hidden min-h-0">
       (서브헤더 + 사이드바 + 본문 전부 여기 안에)
   </div>
   ```
   이 div가 없으면 View Transition 효과가 정상 동작하지 않습니다.

**사이드바에 AJAX 탭 전환(같은 페이지 안에서 loadContent로 내용만
바꾸는 기능)이 있는 페이지라면**, 그 탭 전환 스크립트 맨 앞에 아래
코드를 반드시 추가하세요 (안 넣으면 탭만 바꿨는데도 슬라이드
애니메이션이 걸려서 어색해 보입니다):
```js
document.documentElement.classList.add('no-page-transition');
if (document.activeViewTransition) {
    document.activeViewTransition.skipTransition();
}
```
그리고 탭 전환이 끝나는 시점(성공 콜백 마지막)에:
```js
requestAnimationFrame(() => requestAnimationFrame(() => {
    document.documentElement.classList.remove('no-page-transition');
}));
```
job-list.src.html / resume-list.src.html / bid-list.src.html 세 곳에
이미 적용되어 있으니, 그대로 참고해서 복사하면 됩니다.

## 아직 남아있는 사소한 불일치 (당장 고칠 필요는 없음)

- 사이드 탭 메뉴 스타일이 두 가지 패턴으로 공존합니다:
  - 패턴 A `.side-menu-tab` / `.side-menu-tab-active` — job-list, resume-list
  - 패턴 B `.side-menu-item` / `.side-menu-active` — bid-list, field-experience
  둘 다 common-css.html에 넣어뒀지만, 언젠가 여유가 되면 하나로
  통일하는 걸 권장합니다.
- job-list는 `region-data.js`, resume-list/bid-list는 `region.js`를
  씁니다. 실제로 같은 데이터라면 파일명을 통일하는 게 좋습니다.

## 아직 안 만든 페이지

`cert`(자격증), `mypage`(마이페이지), `sos`(SOS) 폴더는 비어 있습니다.
실제 파일을 보내주시면 같은 방식으로 편입해드립니다.

## 실제 자산(assets) 파일

`assets/img/`, `assets/js/` 안의 실제 이미지·스크립트 파일은 이 데모에
포함되어 있지 않습니다 (README.txt만 있음). 사용자님의 실제 assets
폴더로 통째로 교체하셔야 로고/기능이 정상 동작합니다.

## 브라우저에서 확인하는 법

`pages/jobs/job-list.html` 등을 더블클릭해서 열면 레이아웃과 기능은
바로 보이지만(로고 이미지만 깨짐), **View Transition 슬라이드 효과는
`file://`로 직접 열면 제대로 안 보일 수 있습니다.** VS Code의 "Live
Server" 확장 등으로 로컬 웹서버를 띄워서 실제 링크 클릭으로 이동해보셔야
정확히 확인됩니다.

## v3 업데이트 — cert/sos/mypage 3개 페이지 추가 (총 8개)

- **`mypage/dashboard.html`**: 원래 `header.js`를 `defer`로 비동기 로드해서
  `#header-container`에 나중에 헤더를 주입하는 방식이었습니다. **이게 바로
  이 대화 맨 처음에 문제 삼았던 "헤더가 늦게 나타나며 울렁거리는" 버그와
  동일한 패턴**입니다. `@include header`로 교체해서 완전히 제거했습니다.
  레이아웃도 다른 페이지들과 같은 구조(h-screen + 독립 스크롤 영역)로
  맞췄습니다.
- **`sos/sos-request.html`**: 이미 View Transition이 적용된 버전이었지만
  새로고침 방지 가드가 없었고, SOS 버튼 링크에 `pages/SOS/`(대문자)와
  `pages/sos/`(소문자)가 섞여 있었습니다. 표준 헤더로 교체하면서 자동으로
  통일됨.
- **`cert/cert-list.html`**: `field-experience.html`과 완전히 동일한
  `left-scroll-area`/`main-scroll-area` 스크롤 패턴을 쓰고 있어서
  common-css로 승격했습니다. `side-menu-active-wrapper`도 함께 공통화.

이제 사이트 전체 8개 페이지가 헤더/전환/스크롤 패턴 기준으로 완전히
통일되었습니다. 아직 안 받은 페이지(로그인, 자격증 상세, 입찰 상세 등)가
있다면 같은 방식으로 편입 가능합니다.

## v4 업데이트 — index.html/login.html 추가, BASE 변수 도입 (총 10개 페이지)

**중요한 구조 변경:** `index.html`은 사이트 루트에 있어서 `pages/xxx/yyy.html`
페이지들과 상대경로 깊이가 다릅니다(`../../` vs 그냥 `""`). 그래서 헤더
파샬의 모든 경로를 하드코딩된 `../../` 대신 `{{BASE}}` 변수로 바꿨습니다.

**새 페이지를 만들 때 반드시 넣어야 하는 것에 추가:**
```
<!-- @var BASE: ../../ -->   ← pages/섹션/파일.html 위치인 경우
<!-- @var BASE: -->          ← 사이트 루트에 있는 경우 (index.html처럼)
```
이 값은 헤더 파샬 안의 로고 이미지, GNB 메뉴, SOS 버튼, 마이페이지,
로그인 링크에 전부 자동으로 붙습니다.

**`login.html`은 파샬 시스템에 안 넣었습니다.** 헤더도 없고 다른 페이지로
가는 상대경로 링크도 전혀 없는 순수 모달 팝업 페이지라서, 조립할 게
없습니다. `login.src.html`이 아니라 `login.html`로 최종본 그대로
있습니다.

**build.js도 확장됨:** 이제 `pages/` 뿐 아니라 사이트 루트도 스캔해서
`.src.html`을 찾습니다. `_partials` 폴더는 스캔에서 제외됩니다.

## v5 업데이트 — 상세/작성 페이지 4개 추가 (총 13개 페이지)

- **`cert-detail.html`**: 또 `header.js` 비동기 주입 버그였습니다(dashboard.html과
  동일 패턴). 표준 헤더로 교체. 이 페이지의 `aside`는 실제로 `md:sticky`가
  걸려 있어서 `--header-actual-height` 계산이 죽은 코드가 아니라 실제로
  필요한 코드였습니다 (다른 cert 페이지들과 달리 이 페이지만 그러함).
- **`bid-detail.html`**: 이미 View Transition이 적용돼 있었지만 새로고침
  방지 가드가 없어서 표준 헤더로 교체하며 추가함. 자체 사이드바
  sticky 스크롤 레이아웃은 합리적이라 그대로 유지.
- **`field-experience-write.html`, `job-write.html`**: 원래 사이트 헤더가
  아예 없는 완전 별개 화면(자체 미니 타이틀 바만 있음)이었습니다. 목록
  페이지에서 글쓰기 버튼을 눌렀을 때 급격히 다른 사이트처럼 보이지
  않도록 표준 헤더/서브헤더/사이드바(또는 브레드크럼)를 붙였습니다.
  - `job-write.html`은 폼 자체의 고유 폰트(Pretendard)와 색상 테마는
    이 페이지만의 개성으로 보고 그대로 유지 (사이트 공통 폰트인
    Noto Sans KR 대신 페이지 자체 `<style>`에서 재정의).

v5 시점에는 "헤더가 늦게 나타나는" 유형의 버그(`header.js` 비동기 주입)가
`dashboard.html`, `cert-detail.html` 두 곳에서만 발견되어 고쳐졌다고
적었는데, v6에서 6곳이 더 나왔습니다 (아래 참고). 이 패턴은 여전히
반복적으로 튀어나오고 있어 — 아직 안 받은 파일 중에도 있을 가능성이
높습니다.

## v6 업데이트 — bid/cert/jobs/community/mypage 나머지 페이지 대량 반영 (총 33개 페이지)

**추가로 발견된 `header.js` 비동기 주입 버그 (6곳):** `joint-bid.html`,
`cert-enroll.html`, `cert-exam.html`, `cert-verify.html`, `my-certs.html`,
`my-courses.html`. 전부 표준 헤더로 교체.

**`my-certs.html` / `my-courses.html`은 자체 하드코딩 `<footer>`를 쓰고
있었습니다** (다른 모든 페이지처럼 `#footer-container` + `footer.js`가
아니라 직접 마크업). `header.js` 문제를 우회하려던 흔적으로 보여, 이번에
표준 `footer.js` 연동으로 통일했습니다.

**원래 사이트 헤더가 아예 없던 완전 별개 화면 4개**에 표준 헤더/서브헤더
(+필요시 사이드바)를 새로 붙임: `job-detail.html`, `resume-write.html`,
`field-experience-detail.html`, `field-experience-edit.html`.
- `job-detail.html`, `resume-write.html`은 `job-write.html`과 마찬가지로
  Pretendard 폰트·고유 색상 테마를 페이지 개성으로 보고 유지.

**이번 배치에 포함된 나머지 페이지** (기존에 문제없이 표준에 가까웠던
것들 — 헤더를 파샬로 바꾸고 BASE 변수만 도입): `bid-write.html`,
`company-ads.html`(AJAX 탭 전환 + no-page-transition 가드 유지),
`company-detail.html`, `joint-bid-detail.html`, `joint-bid-write.html`,
`edu-field-list.html`, `notice.html`/`free-board.html`/`work-qna.html`/
`data-room.html` (4개 동일 구조, 사이드바 활성 항목만 다름).

**미해결 — 다음 세션 필요 작업:**
1. `my-exams.html`: 사용자가 "my-exams 이다"라며 보내준 파일이 실제로는
   `cert-list.html`과 거의 동일한 "자격증 과정" 페이지 내용이었음(제목도
   "자격증 과정", header.js v1.5). 시험 결과 페이지가 아니므로 빌드하지
   않음 — 정확한 파일 재요청 필요.
2. `admin-*` 페이지들 (admin-certs, admin-dashboard, admin-course-edit,
   admin-courses, admin-curriculum, admin-enrollments, admin-exams,
   admin-stats): 스크린샷으로만 봤고 실제 파일 내용은 아직 못 받음.
3. `resume-detail.html`, `company-write.html`: 아직 요청 목록에 있었으나
   미수신.

## v7 업데이트 — my-exams.html + admin 관리자 페이지 8개 전체 반영 (총 48개 페이지)

**`my-exams.html` (정정본)**: 이전 세션에서 잘못 도착했던 파일(cert-list
내용)과 달리 정확한 시험 결과 페이지가 도착함. `header.js` 버그는 아니고
다른 예전 스타일 하드코딩 헤더(정보교류/교육·실습/네이버카페 링크가 있는
구버전 GNB)를 쓰고 있었음 — 표준 헤더로 교체.

**admin-* 8종 전체 신규 반영**: `admin-dashboard`, `admin-courses`,
`admin-course-edit`, `admin-curriculum`, `admin-exams`, `admin-enrollments`,
`admin-certs`, `admin-stats`. 새 폴더 `/pages/admin/`.

- 처음엔 admin 전용 헤더 파샬(`admin-header.html`)을 따로 만들어 예전
  하드코딩 헤더(정보교류/교육·실습/네이버카페 링크)를 그대로 옮겨
  붙였는데, 사용자가 "그건 수정 전 구버전 헤더다, 최신 헤더에 맞춰라"라고
  정정해줌. 별도 파샬을 없애고 **8개 페이지 전부 다른 모든 페이지와
  동일한 표준 `header` 파샬**을 쓰도록 다시 고침. 파란 "관리자" 서브헤더
  바(관리자 화면임을 나타내는 라벨)만 표준 헤더 아래에 각 페이지별로
  그대로 유지.
- view-transition/#page-content 래핑은 적용하지 않음(관리자 화면은
  AJAX 탭 전환이 없는 평범한 다중 페이지 구조라 불필요).
- 8개 중 `admin-certs.html`만 완전한 표준 푸터가 있었고 나머지 7개
  (dashboard, courses, course-edit, curriculum, exams, enrollments,
  stats)는 푸터가 아예 없었음. 전부 `#footer-container` + 표준
  `footer.js`로 통일.
- 사이드바(대시보드/과정관리/커리큘럼/시험/수강생/자격증발급/통계
  7항목, 페이지별 활성 표시만 다름)는 파샬화하지 않고 각 페이지에
  그대로 둠 — 활성 항목이 매번 달라 토큰 시스템으로 깔끔하게 추상화하기
  애매해서, 짧은 블록이니 인라인 유지가 낫다고 판단.
- 전부 `checkAdmin()`으로 `user_metadata.role === 'admin'` 체크 후
  아니면 `{{BASE}}index.html`로 리다이렉트하는 로직 그대로 보존.

**빌드 시스템 확장:** `_partials/`에 파샬 파일을 추가하면 어떤 이름이든
`@include 파일명`으로 쓸 수 있다는 걸 admin 작업 중 처음 검증함(기존엔
critical-css/view-transition-css/common-css/header 4종만 사용) —
결국 admin도 표준 header로 통일하면서 이 확장 자체는 다시 안 썼지만,
필요하면 페이지군별 전용 파샬을 언제든 추가할 수 있다는 게 확인됨.

**여전히 미해결:** 없음 — 지금까지 요청/파악된 파일은 모두 반영됨.

## v8 업데이트 — company-write.html 반영 + resume-detail.html 신규 작성 (총 44개 페이지)

**`company-write.html`**: bid-write.html과 동일한 패턴(표준 헤더 없이
이미 완성된 헤더 블록 + view-transition 보유)이라 표준 파샬로 교체만
하면 됐음. `company-ads.html` 사이드바와 짝을 이루는 업체 등록 폼.

**`resume-detail.html`: 사용자가 원본 파일을 갖고 있지 않다고 해서
신규 작성함.** 근거로 삼은 것:
- `resume-list.html`의 `incrementViewAndGo()`가 `resume-detail.html?id=...`
  형태로 이동시키는 흐름
- `resume-write.html`이 `master_board` 테이블에 `board_type: 'RESUME'`,
  `custom_data`(JSON: name/phone/email/address/job_category/
  desired_location/desired_salary/employment_type/experience/
  education/certification/skills)로 저장하는 스키마
- `job-detail.html` / `company-detail.html`의 표준 상세페이지 레이아웃
  (로딩 스피너 → Supabase 조회 → 렌더 함수 → 더미데이터 폴백, 연락처
  강조 박스, 정보 테이블, 목록으로 버튼)

`field-experience-detail.html`의 조회수 증가 패턴(update 후 fire-and-forget)도
차용함. **이 파일은 실제 원본이 아니라 사이트 패턴에 맞춰 새로 만든
것이므로, 실제 DB 컬럼명이나 화면 구성이 원래 기획과 다를 수 있음 —
사용자가 검토 후 다른 점이 있으면 알려줘야 함.**

## v9 업데이트 — data-room.html / work-qna.html 실제 콘텐츠 반영 (총 44개 페이지, 개수 변화 없음)

지금까지 이 두 페이지는 "페이지 기획 및 준비 중입니다" 플레이스홀더였는데,
실제 콘텐츠를 받아 교체함. 페이지 자체는 이미 존재했으므로 총 페이지
수는 그대로 44개.

- **`data-room.html` (서식/자료실)**: 관리단집회/회계행정/입찰계약/시설점검/
  산업안전보건 5개 카테고리, 24종 서식을 아코디언(`<details>`)으로 펼쳐보는
  콘텐츠. Malgun Gothic 서식 톤, 과태료 경고 박스 등 원본의 고유 스타일은
  `#data-room-content` 스코프 안에 그대로 유지하고, 바깥 셸(헤더/서브헤더/
  사이드바/푸터)만 표준으로 감쌈.
- **`work-qna.html` (닥터소장 Q&A)**: 질문에 현상금(포인트)을 걸고, 채택된
  전문가 답변은 블러 처리 + 잠금 오버레이로 유료 열람시키는 하이브리드
  게시판. 이것도 고유 UI(블러 답변, 현상금 입력 버튼 등)는
  `#dr-qna-content` 스코프 안에서 그대로 유지.
- 두 페이지 모두 표준 파샬(critical-css/view-transition-css/common-css/
  header) 적용, 커뮤니티 섹션 사이드바 5항목 중 해당 항목만 활성 표시,
  본문 스크롤 영역(`main-scroll-area`) 안에 원본 콘텐츠를 그대로 얹음.

## v10 업데이트 — 헤더 GNB에 "관리단코너" 메뉴 추가, "자료 / 커뮤니티" → "커뮤니티"로 텍스트 변경

`_partials/header.html` 딱 한 곳만 수정 후 `node build.js` 재실행 →
44개 페이지 전체(데스크탑 GNB + 모바일 메뉴 각각)에 동시 반영됨.

- 새 메뉴 순서: 협회소개 → 구인구직 → 입찰공고 → 자격증 →
  **관리단코너(신규)** → 커뮤니티(구 "자료 / 커뮤니티")
- **`관리단코너`의 링크 대상 페이지(`pages/board/board-corner.html`)는
  아직 실존하지 않는 가칭 경로.** 실제 페이지가 만들어지면
  `_partials/header.html`에서 `board-corner.html` 부분만 실제 파일명으로
  바꾸면 됨(데스크탑/모바일 두 군데).
- 커뮤니티 링크가 가리키는 실제 페이지(`field-experience.html`)는 안 바뀜 —
  메뉴판에 보이는 글자만 "자료 / 커뮤니티"에서 "커뮤니티"로 축약됨.

## v11 업데이트 — board-corner.html (관리단 코너) 실제 페이지 반영 (총 45개 페이지)

v10에서 헤더 GNB에 미리 심어둔 "관리단코너" 메뉴가 가리키던 가칭 경로
`pages/board/board-corner.html`에 실제 콘텐츠가 도착 — 새 폴더
`/pages/board/`를 만들고 그대로 그 경로에 배치해서, 헤더 파샬은 추가
수정 없이 바로 연결됨.

- `header.js` 비동기 주입 버그 있었음(다른 여러 페이지와 동일 패턴) →
  표준 헤더로 교체.
- 좌측 사이드바는 3개 탭(위탁관리사 선정/전자투표·총회 대행/법률·회계
  자문)을 JS로 전환하는 자체 구조라 사이트 표준 `side-menu-tab`
  클래스 대신 이 페이지 전용 `partner-sub-item` 스타일 그대로 유지.
- 리로드가드(`location.pathname.endsWith`) 개수가 15→17로 늘어남 —
  v10에서 헤더에 "관리단코너" 항목이 데스크탑/모바일 각 1개씩 추가된
  결과이며, 45개 페이지 전부 동일하게 17개로 확인됨(정상).

## v12 업데이트 — Font Awesome 아이콘 깜빡임(전화/알림 등) 완화, cdnjs preconnect 45개 페이지 전체 반영

메뉴 클릭 등으로 페이지가 새로 로드될 때마다 헤더의 전화(SOS)/알림(종) 아이콘이
잠깐 사라졌다가 나타나는 깜빡임 현상이 있었음. Font Awesome 아이콘은 웹폰트
파일이 실제로 다운로드되기 전까지는 그려질 수 없는데, 이 폰트를 받아오는
`cdnjs.cloudflare.com` 서버에 대한 `preconnect`(미리 연결) 힌트가 전체
페이지에 빠져 있었음(Google Fonts 쪽만 preconnect가 걸려 있었음). 45개
`.src.html` 파일 전체의 Font Awesome `<link rel="stylesheet">` 바로 앞에
`<link rel="preconnect" href="https://cdnjs.cloudflare.com" crossorigin />`
를 추가해서, 연결을 미리 맺어둔 상태로 폰트를 받게 해 깜빡이는 공백을 줄임.

⚠ 완전히 없앤 건 아니고 **줄인 것**임 — 아이콘 폰트 자체가 비동기로 받아와지는
구조상, 아주 처음 접속할 때(캐시가 없을 때)는 아주 짧은 깜빡임이 원천적으로
남아있을 수 있음. 완전히 없애려면 Font Awesome 대신 인라인 SVG 아이콘으로
바꾸는 방법이 있음(다음에 필요하면 적용 가능).

## v13 업데이트 — 좌측 사이드 메뉴 3종(구인구직/입찰공고/관리단 코너) 크기·형태 통일

구인구직(job-list) 페이지의 좌측 메뉴 박스를 기준으로 삼아, 입찰공고 계열
(bid-list/joint-bid/company-ads)과 관리단 코너(board-corner)의 좌측 메뉴를
전부 동일한 형태로 맞춤:
- 바깥 박스: `bg-white border border-gray-200 rounded shadow-sm p-3 flex
  flex-col gap-1` 로 통일 (안쪽 여백 p-3, 항목 사이 간격 gap-1 추가 — 이전엔
  없거나 항목마다 `mx-4`/`border-b`로 어색하게 구분했었음)
- 개별 항목: 공통 CSS(`_partials/common-css.html`)에 이미 있던
  `.side-menu-tab` / `.side-menu-tab-active` 클래스로 통일 (각 항목이
  개별적으로 둥근 모서리(4px)를 가지면서 바깥 박스 테두리와 안쪽 여백만큼
  떨어져 있는 "테두리 안에 테두리" 형태 — bid-list는 이전에 항목이 바깥
  테두리에 딱 붙어 있었고 모서리도 각져 있었음)
- 관리단 코너(board-corner)는 폭을 280px → 220px로, 자체 전용 스타일이던
  `.side-menu-box`/`.partner-sub-item`(글자 크기 다름, 왼쪽 여백 좁음)을
  삭제하고 위와 동일한 공통 클래스로 교체. `switchTab()` 함수도 클래스 교체
  방식으로 맞춰 수정.
- bid-list/joint-bid의 `loadContent()` 탭 전환 로직도 새 클래스명
  (`side-menu-tab`/`side-menu-tab-active`)에 맞게 같이 수정.

### 여기서 더 나아가 — 좌측 메뉴 전체(23개 페이지) 완전 통일

위 3개 페이지를 고치고 나서 같은 옛날 방식(`.side-menu-item`/`.side-menu-active`,
항목 모서리가 각지고 바깥 테두리에 딱 붙어있던 방식)이 전체 사이트에 훨씬
더 많이 남아있는 걸 발견해서 전부 같이 정리함:
- 자격증 계열: cert-list, cert-detail, cert-enroll, cert-verify, edu-field-list
- 커뮤니티 계열: notice, free-board, field-experience(+detail/edit/write), work-qna, data-room
- 마이페이지 계열: dashboard, my-certs, my-courses, my-exams
- 관리자 계열: admin-dashboard, admin-courses, admin-course-edit, admin-curriculum, admin-exams, admin-enrollments, admin-certs, admin-stats

총 23개 페이지의 좌측 메뉴를 전부 `.side-menu-tab`/`.side-menu-tab-active`
(구인구직과 동일 클래스)로 교체하고, 바깥 박스에도 전부 `p-3 flex flex-col
gap-1`을 추가해서 모서리 둥글기·안쪽 여백까지 구인구직 페이지와 동일하게
맞춤. 이제 사이트 전체에서 좌측 사이드 메뉴 모양이 한 가지로 통일됨.

### 부수적으로 발견/수정한 문제
v12에서 전체 페이지에 cdnjs preconnect를 추가할 때, index.html /
field-experience.html / board-corner.html 이 3개 페이지는 원래 폰트를
"preload 후 onload 시 적용"하는 예전 방식(다른 페이지들은 이미 v11 이전에
직접 `<link rel="stylesheet">` 방식으로 바뀌어 있었으나 이 3개만 안 바뀌어
있었음)을 쓰고 있었던 걸 뒤늦게 발견. 자동 삽입 스크립트가 이 3개 파일의
`<noscript>` 안쪽에 잘못 끼워 넣어져 태그가 깨지는 문제가 있어, 이 3개
파일의 폰트 로딩 부분을 전부 다른 페이지와 동일한 직접 `<link
rel="stylesheet">` 방식으로 다시 통일함 (전화/알림 아이콘 깜빡임 문제도
이 3개 페이지에서 마저 해결됨).

## v15 업데이트 — 관리단 코너 좌측 메뉴: 아이콘 제거, 폭 축소(220→200px)

3개 항목(위탁관리사 선정 / 전자투표·총회 대행 / 법률·회계 자문) 글자 앞
아이콘(<i class="fas ...">)을 전부 삭제. 아이콘이 없어지니 시각적으로
좀 더 컴팩트해 보이게, 좌측 사이드바 폭도 220px → 200px로 살짝 줄임.
글자 크기는 v14에서 이미 공통 클래스(.side-menu-tab)로 통일되어 있어서
다른 페이지(구인구직 등)와 원래부터 동일 — 이번에 추가로 손댈 것 없었음.

## v16 업데이트 — 관리단 코너 폭 수정 (200px는 잘못된 임의값이었음 → 220px로 되돌림)

v15에서 "폭을 살짝 줄이라"는 요청을 임의로 200px로 해석해서 바꿨었는데,
사용자가 실제로 원한 건 다른 페이지(구인구직 등)와 폭을 "비교해서 똑같이
맞추라"는 의미였음. 그래서 200px를 되돌리고, 사이트 전체와 동일한 220px로
재통일함. (아이콘 삭제는 v15 그대로 유지.)

## v17 업데이트 — 사이드바 있는 모든 페이지의 좌우 바깥 여백을 구인구직 기준으로 통일

구인구직(job-list)은 본문 영역에 `px-4 md:px-8`(모바일 16px / 데스크탑
32px)를 쓰는데, 좌측 메뉴가 있는 페이지 24개는 `md:px-8`이 빠진 채
`px-4`만 있어서 데스크탑 기준 바깥 여백이 절반(16px)밖에 안 됐던 것을
찾아서 전부 `md:px-8` 추가:
- 관리자(admin) 8개, 관리단 코너, 자격증(cert-detail/cert-enroll/
  edu-field-list) 3개, 커뮤니티 8개, 마이페이지 4개 = 총 24개 페이지

또한 "진위확인" 좌측 메뉴 라벨을 "진위 확인"으로 띄어쓰기 추가
(cert-list/cert-verify/cert-enroll/cert-detail/edu-field-list 5개
페이지의 사이드 메뉴 항목만 — 페이지 제목/본문의 "진위확인"은 원래
표기 유지).

(사이드바가 없는 단일 컬럼 페이지 4개 — cert-exam, job-detail,
job-write, resume-write — 는 애초에 이 좌측 메뉴 비교 대상이 아니라서
건드리지 않음.)

## v18 업데이트 — 공지사항/자유게시판에 실제 콘텐츠 연결 (placeholder 제거)

사용자가 예전에 만들어뒀던 실제 동작하는 파일들(notice-detail.html,
notice-write.html, free-board-detail.html, free-board-edit.html,
free-board-write.html — 지금까지는 사이트 코드 어디에도 연결 안 된
고아 파일이었음)을 전달받아서 커뮤니티에 정식으로 편입시킴:

- **notice.src.html / free-board.src.html**: "페이지 기획 및 준비
  중입니다" placeholder를 지우고, Supabase(`notices` / `free_board`
  테이블)에서 실제 글 목록을 불러와 보여주는 게시판형 리스트로 교체.
  고정 공지는 상단에 "공지" 배지와 함께 우선 정렬. 목록 우측 상단에
  글쓰기 버튼 추가.
- **notice-detail / notice-write / free-board-detail / free-board-edit /
  free-board-write**: 5개 파일 전부 새로 `.src.html`로 편입. 원본은
  사이트 헤더가 아예 없는 독립된 화면(자체 제작 파란 타이틀 바만 있음)
  이었는데, 표준 헤더/서브헤더/좌측 사이드바(공지사항/자유게시판/
  현장경험 나누어요/업무 Q&A/서식자료실, side-menu-tab 패턴)를 붙여서
  다른 커뮤니티 페이지들과 완전히 같은 틀 안에 들어오도록 통일.
  Supabase 접속 정보도 각 파일에 중복 하드코딩되어 있던 걸 지우고
  공용 `assets/js/supabase-config.js`(`window.sb`)를 쓰도록 변경.
- 원본 notice-detail.html / notice-write.html에 있던 버그(목록으로
  버튼이 `notice.src.html`을 가리키고 있던 것 — 브라우저에서는 열리지
  않는 소스 파일 경로)도 `notice.html`로 수정.

이제 커뮤니티 5개 메뉴(공지사항/자유게시판/현장경험 나누어요/업무 Q&A/
서식자료실) 전부 실제 데이터가 붙은 목록+상세+글쓰기 구조를 갖추게 됨.
(자유게시판은 비밀번호 기반 수정/삭제, 댓글 기능까지 포함.)

## v19 업데이트 — 입찰공고 상단 카드에서 "관리대행사 모집" 삭제

입찰공고(bid-list) 페이지 상단 4개 아이콘 카드 중 "관리대행사 모집"은
관리단 코너에서 이미 다루는 영역이라 중복이라 삭제. 4개 → 3개가 되면서
그리드를 2x4(모바일 2열/데스크탑 4열)에서 모바일 1열 / sm 이상 3열로
재배치.

참고: 그 아래 "분류" 체크박스 필터 목록에는 "관리대행사 모집" 항목이
아직 남아있음 — 이번엔 상단 카드만 지워달라는 요청이라 그대로 뒀음.
같이 지울지 필요하면 알려주면 됨.

## v20 업데이트 — 입찰공고 "분류" 체크박스에서도 "관리대행사 모집" 삭제

v19에서 상단 카드만 지웠던 "관리대행사 모집"을 그 아래 분류 체크박스
필터 목록에서도 삭제 요청받아 제거. 이제 bid-list.html 안에 "관리대행사
모집" 문구가 전혀 남아있지 않음.

참고: bid-write.html(입찰 등록 글쓰기 폼)의 카테고리 선택 드롭다운에는
"관리대행사 모집" 옵션이 아직 남아있음 — 이건 글을 "분류"하는 필터가
아니라 글을 쓸 때 카테고리를 지정하는 별개 용도라 이번 요청 범위로
보지 않고 그대로 둠. 필요하면 알려주면 됨.

## v21 업데이트 — 입찰 글쓰기 폼 분류 드롭다운에서도 "관리대행사 모집" 삭제

bid-write.html(입찰 등록 글쓰기)의 "분류" 선택 드롭다운에 남아있던
"관리대행사 모집" 옵션도 삭제 요청받아 제거. 이제 입찰공고 관련 페이지
전체(bid-list 상단 카드/체크박스 필터, bid-write 분류 드롭다운)에서 이
항목이 완전히 사라짐 — 해당 기능은 관리단 코너 페이지에서만 다룸.
