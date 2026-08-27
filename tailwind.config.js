/** Tailwind CDN 스크립트를 걷어내고 정적 CSS 파일로 self-host 하기 위한 설정.
 *  사용법 (인터넷 되는 PC/VS Code 터미널에서, 이 site 폴더 기준으로):
 *
 *  1) npm install -D tailwindcss@3
 *  2) npx tailwindcss -i ./assets/css/tailwind-input.css -o ./assets/css/tailwind.css --minify
 *  3) 그러면 assets/css/tailwind.css 파일이 생김
 *  4) 모든 페이지(각 .src.html)의
 *       <script src="https://cdn.tailwindcss.com"></script>
 *     줄을 아래로 교체:
 *       <link rel="stylesheet" href="{{BASE}}assets/css/tailwind.css">
 *     (44개 파일 전부 VS Code "모든 파일에서 찾아 바꾸기"로 한 번에 가능)
 *  5) node build.js 로 재빌드
 *
 *  이렇게 하면 브라우저가 그냥 평범한 .css 파일을 받아오는 것뿐이라
 *  로드 순서/타이밍에 따라 화면이 튀거나 흔들리는 문제가 구조적으로 사라짐.
 */
module.exports = {
  content: ["./**/*.html", "!./node_modules/**"],
  theme: { extend: {} },
  plugins: [],
};
