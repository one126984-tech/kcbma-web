/**
 * footer.js
 * pages/ 폴더가 삭제되고 하위 폴더들이 최상단으로 이동한 구조에 맞춰 경로를 모두 수정했습니다.
 * 트렌디하고 깔끔한 다크 테마 기반의 3단 Grid 레이아웃으로 디자인을 업그레이드했습니다.
 */

document.addEventListener("DOMContentLoaded", () => {
  const footerContainer = document.getElementById("footer-container");
  if (!footerContainer) return;

  // pages/ 폴더가 사라지면서 파일 깊이가 1단계 얕아졌으므로 기본값을 "../"로 변경합니다.
  // (루트 디렉토리의 index.html 등에서 사용할 경우 window.BASE_PATH = "./" 로 덮어쓰기 가능)
  const prefix = window.BASE_PATH || "../";

  footerContainer.innerHTML = `
    <footer class="bg-[#0b1121] text-slate-300 py-16 border-t border-slate-800/80 font-sans mt-16">
      <div class="max-w-7xl mx-auto px-6 lg:px-8">
        <!-- 3단 그리드 레이아웃 -->
        <div class="grid grid-cols-1 md:grid-cols-12 gap-12 lg:gap-8">
          
          <!-- [1] 좌측: 로고 및 협회 정보 -->
          <div class="md:col-span-5 lg:col-span-6 flex flex-col">
            <!-- 이미지 로드 실패 시 텍스트 렌더링 -->
            <div id="footer-fallback-logo" class="hidden font-extrabold text-2xl text-white mb-6 flex items-center gap-2 tracking-tight">
              <span class="text-blue-500">🛡️</span>
              <span>대한집합건물관리협회</span>
            </div>
            
            <img src="${prefix}assets/img/kcbma_logo_nobg.png" 
                 class="h-[48px] md:h-[54px] filter brightness-0 invert mb-6 object-contain self-start opacity-90 hover:opacity-100 transition-opacity" 
                 alt="대한집합건물관리협회"
                 onerror="this.style.display='none'; document.getElementById('footer-fallback-logo').classList.remove('hidden');">
                 
            <div class="text-[14px] md:text-[15px] leading-relaxed text-slate-400 space-y-2">
              <p><span class="font-medium text-slate-300">주소:</span> 경기도 김포시 김포대로 699</p>
              <p><span class="font-medium text-slate-300">전화:</span> 031-984-6199 <span class="mx-3 text-slate-700">|</span> <span class="font-medium text-slate-300">팩스:</span> 031-985-6199</p>
              <p><span class="font-medium text-slate-300">이메일:</span> <a href="mailto:idea8888@naver.com" class="hover:text-white transition-colors">idea8888@naver.com</a></p>
            </div>
          </div>

          <!-- [2] 중앙: 사이트맵 -->
          <div class="md:col-span-3 lg:col-span-3">
            <h4 class="mb-5 font-semibold text-white text-[16px] tracking-wide">사이트맵</h4>
            <ul class="flex flex-col space-y-3 text-[14px] md:text-[15px]">
              <!-- pages/ 경로 삭제 완료 -->
              <li><a href="${prefix}about/about.html" class="text-slate-400 hover:text-white hover:translate-x-1 inline-block transition-transform duration-200 no-underline">협회소개</a></li>
              <li><a href="${prefix}jobs/job-list.html" class="text-slate-400 hover:text-white hover:translate-x-1 inline-block transition-transform duration-200 no-underline">구인구직 센터</a></li>
              <li><a href="${prefix}bid/bid-list.html" class="text-slate-400 hover:text-white hover:translate-x-1 inline-block transition-transform duration-200 no-underline">입찰공고</a></li>
              <li><a href="${prefix}board/board-corner.html" class="text-slate-400 hover:text-white hover:translate-x-1 inline-block transition-transform duration-200 no-underline">관리단 코너</a></li>
            </ul>
          </div>

          <!-- [3] 우측: 제휴 및 네이버 카페 -->
          <div class="md:col-span-4 lg:col-span-3">
            <h4 class="mb-5 font-semibold text-white text-[16px] tracking-wide">제휴 파트너</h4>
            <ul class="flex flex-col space-y-3 text-[14px] md:text-[15px] mb-7">
              <!-- pages/ 경로 삭제 완료 -->
              <li><a href="${prefix}bid/company-ads.html" class="text-slate-400 hover:text-white hover:translate-x-1 inline-block transition-transform duration-200 no-underline">우수 파트너사 목록</a></li>
              <li><a href="${prefix}bid/company-write.html" class="text-slate-400 hover:text-white hover:translate-x-1 inline-block transition-transform duration-200 no-underline">유지 보수사 협력 신청</a></li>
            </ul>
            
            <!-- 네이버 카페 버튼 디자인 강화 -->
            <a href="https://cafe.naver.com/kcbma114" target="_blank" 
               class="inline-flex items-center justify-center gap-2 bg-[#03c75a] text-white px-5 py-2.5 rounded-lg font-bold text-[14px] shadow-lg shadow-[#03c75a]/20 hover:bg-[#02b351] hover:shadow-[#03c75a]/40 hover:-translate-y-0.5 transition-all w-full sm:w-auto no-underline">
              <!-- 네이버 'N' 로고 SVG -->
              <svg class="w-4 h-4 fill-current" viewBox="0 0 24 24"><path d="M16.273 12.845L7.376 0H0v24h7.727V11.155L16.624 24H24V0h-7.727v12.845z"/></svg>
              네이버 카페 방문하기
            </a>
          </div>

        </div>
        
        <!-- 하단 카피라이트 및 정책 -->
        <div class="mt-16 pt-8 border-t border-slate-800/80 flex flex-col md:flex-row justify-between items-center gap-4">
          <p class="text-[13px] text-slate-500">
            © 2026 대한집합건물관리협회(KCBMA). All rights reserved.
          </p>
          <div class="flex space-x-6 text-[13px]">
            <!-- 이용약관 및 개인정보처리방침 경로도 맞춰주었습니다 (필요시 폴더명 변경 가능) -->
            <a href="${prefix}policy/terms.html" class="text-slate-500 hover:text-slate-300 transition-colors no-underline">이용약관</a>
            <a href="${prefix}policy/privacy.html" class="text-slate-500 hover:text-slate-300 transition-colors font-medium no-underline">개인정보처리방침</a>
          </div>
        </div>
      </div>
    </footer>
  `;
});