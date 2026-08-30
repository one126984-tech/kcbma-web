/**
 * footer.js
 * 푸터 로고/링크를 현재 사이트 구조(pages/섹션/파일.html)에 맞춰 정비함.
 */

document.addEventListener("DOMContentLoaded", () => {
  const footerContainer = document.getElementById("footer-container");
  if (!footerContainer) return;

  // footer.js를 로드하는 페이지는 전부 pages/섹션/파일.html 깊이(루트 기준 2단계)라
  // 접두 경로는 항상 "../../". 나중에 다른 깊이에서 쓸 일이 생기면
  // window.BASE_PATH를 페이지에서 미리 지정해 덮어쓸 수 있게 열어둠.
  const prefix = window.BASE_PATH || "../../";

  footerContainer.innerHTML = `
    <footer class="bg-[#040f24] text-white py-12 md:py-16 px-6 mt-12 border-t border-gray-800">
      <div class="max-w-7xl mx-auto flex flex-col md:flex-row justify-between items-start gap-10 md:gap-8">
        
        <!-- 푸터 좌측 정보 -->
        <div class="flex-1 w-full">
          <!-- 이미지 로드 실패 시 텍스트로 자동 전환 -->
          <div id="footer-fallback-logo" class="hidden font-black text-xl md:text-2xl text-white mb-5 flex items-center gap-1.5">
            <span>🛡️</span>
            <span>대한집합건물관리협회</span>
          </div>
          <img src="${prefix}assets/img/logo.png" 
               class="h-[50px] md:h-[60px] filter brightness-0 invert mb-5 object-contain" 
               alt="대한집합건물관리협회"
               onerror="this.style.display='none'; document.getElementById('footer-fallback-logo').classList.remove('hidden');">
               
          <div class="text-[14px] md:text-[15px] leading-relaxed text-gray-300">
            <p class="mb-1">주소: 경기도 김포시 김포대로 699</p>
            <p class="mb-1">전화: 031-984-6199 · 팩스: 031-985-6199</p>
            <p class="mb-1">이메일: idea8888@naver.com</p>
          </div>
        </div>

        <!-- 중앙 사이트맵 -->
        <div class="flex-[0.5] w-full">
          <h4 class="mb-4 font-bold text-white text-[16px]">사이트맵</h4>
          <div class="text-[14px] md:text-[15px] leading-[2.2] text-gray-300 flex flex-col">
            <a href="${prefix}pages/about/about.html" class="hover:text-white transition-colors no-underline text-gray-300">협회소개</a>
            <a href="${prefix}pages/jobs/job-list.html" class="hover:text-white transition-colors no-underline text-gray-300">구인구직 센터</a>
            <a href="${prefix}pages/bid/bid-list.html" class="hover:text-white transition-colors no-underline text-gray-300">입찰공고</a>
            <a href="${prefix}pages/board/board-corner.html" class="hover:text-white transition-colors no-underline text-gray-300">관리단 코너</a>
          </div>
        </div>

        <!-- 우측 제휴 파트너 및 카페 -->
        <div class="flex-[0.5] w-full">
          <h4 class="mb-4 font-bold text-white text-[16px]">제휴 파트너</h4>
          <div class="text-[14px] md:text-[15px] leading-[2.2] text-gray-300 flex flex-col">
            <a href="${prefix}pages/bid/company-ads.html" class="hover:text-white transition-colors no-underline text-gray-300">우수 파트너사 목록</a>
            <a href="${prefix}pages/bid/company-write.html" class="hover:text-white transition-colors no-underline text-gray-300">유지 보수사 협력 신청</a>
          </div>
          <a href="https://cafe.naver.com/kcbma114" target="_blank" class="inline-block bg-[#00C73C] text-white px-4 py-2 rounded font-bold text-[14px] mt-4 hover:bg-[#00a833] transition-colors no-underline">
            N 네이버카페
          </a>
        </div>

      </div>
      
      <!-- 하단 카피라이트 -->
      <div class="max-w-7xl mx-auto mt-10 md:mt-12 pt-6 border-t border-blue-900/60 text-[12px] md:text-[13px] flex flex-col md:flex-row justify-between items-center text-gray-400 gap-4">
        <span>© 2026 대한집합건물관리협회(KCBMA). All rights reserved.</span>
        <div class="flex space-x-5">
          <a href="#" class="hover:text-white transition-colors no-underline text-gray-400">이용약관</a>
          <a href="#" class="hover:text-white transition-colors no-underline text-gray-400">개인정보처리방침</a>
        </div>
      </div>
    </footer>
  `;
});