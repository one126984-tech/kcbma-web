/**
 * footer.js
 * pages/ 폴더가 삭제되고 하위 폴더들이 최상단으로 이동한 구조에 맞춰 경로를 모두 수정했습니다.
 * 트렌디하고 깔끔한 다크 테마 기반의 3단 Grid 레이아웃으로 디자인을 업그레이드했습니다.
 */

/**
 * footer.js
 * 2026-09: 사용자 요청으로 푸터를 3~4줄 분량의 얇은 형태로 재설계.
 * - 로고 크기를 주소 한 줄 너비 정도로 축소
 * - 네이버 카페는 아직 활성화 전이라 버튼(초록 배경) 대신 일반 텍스트 링크로 변경
 * - 협회가 중개 역할만 하며 법적 책임을 지지 않는다는 면책 문구 추가
 */

document.addEventListener("DOMContentLoaded", () => {
  const footerContainer = document.getElementById("footer-container");
  if (!footerContainer) return;

  const prefix = window.BASE_PATH || "../";

  footerContainer.innerHTML = `
    <footer style="background-color:#061530;" class="text-slate-300 py-8 border-t border-slate-800/80 font-sans mt-16 text-[13px] leading-relaxed">
      <div class="max-w-7xl mx-auto px-6 lg:px-8 space-y-3">

        <!-- 상단: 좌측(로고+연락처+면책) / 우측(사이트맵 2단) -->
        <div class="flex flex-col md:flex-row justify-between gap-6 items-stretch">

          <!-- 좌측 -->
          <div class="flex-1 min-w-0 flex flex-col justify-between gap-2">
            <div id="footer-fallback-logo" class="hidden font-extrabold text-white items-center gap-2 tracking-tight mb-2">
              <span class="text-blue-500">🛡️</span>
              <span>대한집합건물관리협회</span>
            </div>

            <!-- 1줄: 로고 + 연락처 (같은 줄에 나란히) -->
            <div class="flex flex-wrap items-center gap-4">
              <div class="inline-block bg-white rounded-md px-3 py-1 shrink-0">
                <img src="${prefix}assets/img/logo.png"
                     style="height:28px;"
                     class="object-contain"
                     alt="대한집합건물관리협회"
                     onerror="this.parentElement.style.display='none'; document.getElementById('footer-fallback-logo').classList.remove('hidden');">
              </div>
              <p class="text-white font-semibold">
                전화: 031-984-6199
                <span class="mx-2 text-white/40 font-normal">|</span>
                팩스: 031-985-6199
                <span class="mx-2 text-white/40 font-normal">|</span>
                이메일: <a href="mailto:idea8888@naver.com" class="hover:text-slate-200 transition-colors">idea8888@naver.com</a>
              </p>
            </div>

            <p class="text-white font-semibold">
              주소: 경기도 김포시 김포대로 699
              <span class="mx-2 text-white/40 font-normal">|</span>
              <a href="${prefix}bid/company-ads.html" class="hover:text-slate-200 transition-colors no-underline">우수 파트너사 목록</a>
              <span class="mx-2 text-white/40 font-normal">|</span>
              <a href="${prefix}bid/company-write.html" class="hover:text-slate-200 transition-colors no-underline">유지 보수사 협력 신청</a>
            </p>
            <p class="text-white/80 text-[12px] font-normal">
              본 협회는 회원 간 정보 교류 및 중개 역할만 수행하며, 게시된 정보의 정확성이나 회원 간 거래·계약에 대해 어떠한 법적 책임도 지지 않습니다.
            </p>
          </div>

          <!-- 우측: 사이트맵 (2열 그리드로 통일 — flex는 항목별 텍스트 길이가 달라 두 번째 열이
               행마다 어긋나 보이는 문제가 있었음. grid는 컬럼 폭이 고정되어 항상 줄이 맞음) -->
          <div class="grid grid-cols-2 gap-x-8 gap-y-2 shrink-0 text-white font-semibold self-center">
            <a href="${prefix}about/about.html" class="hover:text-slate-200 transition-colors no-underline">협회소개</a>
            <a href="${prefix}board/board-corner.html" class="hover:text-slate-200 transition-colors no-underline">관리단 코너</a>
            <a href="${prefix}jobs/job-list.html" class="hover:text-slate-200 transition-colors no-underline">구인구직</a>
            <a href="${prefix}community/notice.html" class="hover:text-slate-200 transition-colors no-underline">커뮤니티</a>
            <a href="${prefix}bid/bid-list.html" class="hover:text-slate-200 transition-colors no-underline">입찰공고</a>
            <a href="https://cafe.naver.com/kcbma114" target="_blank" class="text-lime-400 hover:text-lime-300 transition-colors no-underline">네이버 카페</a>
          </div>
        </div>

        <!-- 하단: 저작권 + 약관 -->
        <div class="pt-3 border-t border-white/20 flex flex-col md:flex-row justify-between items-start md:items-center gap-2">
          <p class="text-white/80 font-normal">© 2026 대한집합건물관리협회(KCBMA) 네트워크. All rights reserved.</p>
          <div class="flex gap-5 font-semibold">
            <a href="${prefix}policy/terms.html" class="text-white/80 hover:text-white transition-colors no-underline">이용약관</a>
            <a href="${prefix}policy/privacy.html" class="text-white/80 hover:text-white transition-colors no-underline">개인정보처리방침</a>
          </div>
        </div>

      </div>
    </footer>
  `;
});