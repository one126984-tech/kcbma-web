// 1. 페이지 위치(폴더 깊이)에 따라 경로를 자동으로 맞춰주는 변수
const basePath = window.BASE_PATH || '';

// 2. 인덱스(표준) 기준 헤더 + 모바일 메뉴 HTML
const headerHtml = `
  <div class="sticky top-0 z-[900] w-full flex flex-col bg-white border-b border-gray-300 shadow-sm">
    
    <div class="w-full bg-[#0a1931] py-2.5">
      <div class="max-w-7xl mx-auto px-2 md:px-8 flex flex-wrap justify-center sm:justify-end items-center gap-1.5 md:gap-3 text-white text-[11px] sm:text-[13px] font-bold">
        <div data-href="https://cafe.naver.com/kcbma114" data-target="_blank" onclick="handleNavigation(this)" class="bg-[#03c75a] hover:bg-[#02a64b] px-2.5 py-1.5 md:px-4 md:py-1.5 rounded cursor-pointer whitespace-nowrap">네이버카페</div>
        
        <div id="auth-buttons" class="flex flex-wrap items-center gap-1.5 md:gap-3">
          <div onclick="openCustomModal('login')" class="bg-[#1f3b73] hover:bg-[#152a55] px-2.5 py-1.5 md:px-4 md:py-1.5 rounded cursor-pointer whitespace-nowrap">로그인</div>
          <div onclick="openCustomModal('signup')" class="bg-[#1f3b73] hover:bg-[#152a55] px-2.5 py-1.5 md:px-4 md:py-1.5 rounded cursor-pointer whitespace-nowrap">회원가입</div>
          <div class="flex items-center cursor-pointer bg-[#0a1931] px-1 md:ml-2 whitespace-nowrap">
            <span onclick="openCustomModal('find-id')" class="hover:text-gray-300 p-1.5">아이디찾기</span>
            <span class="text-gray-400 font-normal">|</span>
            <span onclick="openCustomModal('find-pw')" class="hover:text-gray-300 p-1.5">비밀번호찾기</span>
          </div>
        </div>
        
        <div id="user-section" style="display:none;" class="flex-wrap items-center gap-1.5 md:gap-3"></div>
      </div>
    </div>
    
    <header class="flex justify-between items-center px-4 md:px-8 py-4 max-w-7xl mx-auto w-full">
      <div class="flex items-center h-[40px] md:h-[48px] cursor-pointer" data-href="${basePath}index.html" onclick="handleNavigation(this)">
        <img src="${basePath}assets/img/방패로고-removebg-preview.png" class="h-full w-auto object-contain flex-shrink-0" alt="KCBMA 마크" onerror="this.src='${basePath}방패로고.jpg'">
        <img src="${basePath}assets/img/로고_글자-removebg-preview.png" class="h-[36px] md:h-[44px] w-auto object-contain flex-shrink-0 ml-2 mt-1" alt="대한집합건물관리협회" onerror="this.src='${basePath}로고_글자.png'">
      </div>
      
      <nav class="hidden md:flex space-x-12 font-bold text-[17px] items-center">
        <div data-href="${basePath}about/intro.html" onclick="handleNavigation(this)" class="menu-item py-1 cursor-pointer">협회소개</div>
        
        <div class="relative gnb-dropdown-wrap cursor-pointer">
          <div data-href="${basePath}info/index.html" onclick="handleNavigation(this)" class="menu-item">정보교류</div>
          <div class="gnb-dropdown-menu">
            <div class="dropdown-box">
              <div data-href="${basePath}policy/law.html" onclick="event.stopPropagation(); handleNavigation(this)">법규·정책</div>
              <div data-href="${basePath}info/videos.html" onclick="event.stopPropagation(); handleNavigation(this)">영상 자료실</div>
              <div data-href="${basePath}info/columns.html" onclick="event.stopPropagation(); handleNavigation(this)">시설업체 칼럼</div>
            </div>
          </div>
        </div>

        <div data-href="${basePath}info/forum.html" onclick="handleNavigation(this)" class="menu-item cursor-pointer">정책토론</div>
        <div data-href="${basePath}jobs/list.html" onclick="handleNavigation(this)" class="menu-item cursor-pointer">구인구직</div>
        <div data-href="${basePath}info/sinmungo.html" onclick="handleNavigation(this)" class="menu-item cursor-pointer">정책신문고</div>
      </nav>

      <button class="md:hidden p-2 text-[#0a1931] cursor-pointer" onclick="toggleMobileMenu()" aria-label="메뉴열기">
        <svg class="pointer-events-none" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
          <line x1="3" y1="12" x2="21" y2="12"></line>
          <line x1="3" y1="6" x2="21" y2="6"></line>
          <line x1="3" y1="18" x2="21" y2="18"></line>
        </svg>
      </button>
    </header>
  </div>

  <div id="mobile-menu" style="display:none;" class="fixed inset-0 z-[1000] bg-black/60 transition-opacity" role="dialog" aria-modal="true">
    <div class="absolute top-0 right-0 bottom-0 w-4/5 max-w-[320px] bg-[#0a1931] shadow-2xl flex flex-col">
      <div class="flex justify-between items-center p-4 bg-white border-b border-gray-200">
        <div class="flex items-center gap-2">
          <img src="${basePath}assets/img/방패로고-removebg-preview.png" alt="KCBMA 방패마크" class="h-[36px] w-auto object-contain" />
          <img src="${basePath}assets/img/로고_글자-removebg-preview.png" alt="대한집합건물관리협회" class="h-[28px] w-auto object-contain" />
        </div>
        <button onclick="toggleMobileMenu()" class="text-3xl text-gray-500 hover:text-gray-800 leading-none px-2">&times;</button>
      </div>
      <div class="flex-1 overflow-y-auto p-6 space-y-6 text-white font-bold text-[17px]">
        <div data-href="${basePath}about/intro.html" onclick="handleNavigation(this)" class="cursor-pointer hover:text-[#2BA8A0]">협회소개</div>
        <details class="group">
          <summary class="cursor-pointer hover:text-[#2BA8A0] list-none flex justify-between items-center outline-none">
            정보교류
            <span class="text-xl group-open:rotate-180 transition-transform">▾</span>
          </summary>
          <div class="mt-3 ml-4 space-y-3 text-[15px] font-normal text-gray-300">
            <div data-href="${basePath}policy/law.html" onclick="event.stopPropagation(); handleNavigation(this)" class="cursor-pointer hover:text-white">법규·정책</div>
            <div data-href="${basePath}info/videos.html" onclick="event.stopPropagation(); handleNavigation(this)" class="cursor-pointer hover:text-white">영상 자료실</div>
            <div data-href="${basePath}info/columns.html" onclick="event.stopPropagation(); handleNavigation(this)" class="cursor-pointer hover:text-white">시설업체 칼럼</div>
          </div>
        </details>
        <div data-href="${basePath}info/forum.html" onclick="handleNavigation(this)" class="cursor-pointer hover:text-[#2BA8A0]">정책토론</div>
        <div data-href="${basePath}jobs/list.html" onclick="handleNavigation(this)" class="cursor-pointer hover:text-[#2BA8A0]">구인구직</div>
        <div data-href="${basePath}info/sinmungo.html" onclick="handleNavigation(this)" class="cursor-pointer hover:text-[#2BA8A0]">정책신문고</div>
      </div>
      <div class="p-6 bg-[#061124] space-y-3 text-[14px] font-bold text-center">
        <div data-href="${basePath}partners/apply.html" onclick="handleNavigation(this)" class="w-full py-3 bg-white text-[#0a1931] rounded-lg cursor-pointer">광고 문의</div>
        <div data-href="https://cafe.naver.com/kcbma114" data-target="_blank" onclick="handleNavigation(this)" class="w-full py-3 bg-[#03c75a] text-white rounded-lg cursor-pointer">네이버카페 바로가기</div>
      </div>
    </div>
  </div>
`;

// 3. 네비게이션 이동 함수 (기존 head 스크립트에서 이동)
window.handleNavigation = function(element) {
  var url = element.getAttribute('data-href');
  var target = element.getAttribute('data-target');
  if (url && url !== '#') {
    if (target === '_blank') { window.open(url, '_blank'); } 
    else { window.location.href = url; }
  }
};

// 4. 모바일 메뉴 열기/닫기 (기존 head 스크립트에서 이동)
window.toggleMobileMenu = function() {
  var menu = document.getElementById('mobile-menu');
  if (menu.style.display === 'block') {
    menu.style.display = 'none';
    document.body.style.overflow = '';
  } else {
    menu.style.display = 'block';
    document.body.style.overflow = 'hidden';
  }
};

// 5. 화면이 로드되면 <body> 맨 앞줄에 헤더 삽입
document.addEventListener('DOMContentLoaded', () => {
  document.body.insertAdjacentHTML('afterbegin', headerHtml);
});