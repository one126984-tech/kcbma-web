/** Tailwind CDN 스크립트를 걷어내고 정적 CSS 파일로 self-host 하기 위한 설정.
 *
 *  ★★★ 2026-08: 아래 작업 이미 완료됨 ★★★
 *  - assets/css/tailwind.css 생성 완료 (이 설정 기준으로 빌드된 정적 CSS)
 *  - 모든 .src.html의 <script src="https://cdn.tailwindcss.com"></script>는
 *    <link rel="stylesheet" href="{{BASE}}assets/css/tailwind.css">로 교체 완료
 *    (login.html은 @var BASE 체계가 없는 독립 파일이라 "assets/css/tailwind.css"로 직접 교체)
 *  - node build.js 재빌드까지 완료됨
 *
 *  → CDN 스크립트가 다운로드/실행되길 "기다리는" 시간 자체가 없어져서,
 *    로드/네비게이션 시 파란 버튼이 흰색으로 보였다가 바뀌는 깜빡임,
 *    유틸리티 클래스 미적용으로 인한 레이아웃 튐 등이 구조적으로 없어짐.
 *    이제 그냥 평범한 .css 파일을 <link>로 받아오는 것뿐이라, 브라우저가
 *    렌더링을 시작하기 "전에" 이미 스타일이 다 준비되어 있음.
 *
 *  ── 이후에 HTML을 더 추가/수정해서 새로운 Tailwind 클래스(w-[123px] 같은
 *  임의값 포함)를 썼는데 화면에 안 먹는다면, 그건 정적 빌드가 실제 사용된
 *  클래스만 스캔해서 담기 때문(런타임 JIT였던 CDN과 달리). 그럴 땐 인터넷
 *  되는 PC에서 이 폴더 기준으로 아래 명령만 다시 실행하면 됨:
 *
 *    1) npm install -D tailwindcss@3   (최초 1회만)
 *    2) npx tailwindcss -c tailwind.config.js -i ./assets/css/tailwind-input.css -o ./assets/css/tailwind.css --minify
 *
 *  content 아래 글롭이 pages/**\/*.src.html과 완성된 .html을 전부 스캔하므로,
 *  새 페이지를 추가했으면 build.js로 먼저 .html을 만든 뒤에 위 명령을 돌릴 것.
 */
module.exports = {
  content: ["./**/*.html", "!./node_modules/**"],
  theme: { extend: {} },
  plugins: [],
};
