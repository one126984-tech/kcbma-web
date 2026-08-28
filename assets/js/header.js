// 파일명: assets/js/header.js
(function() {
  const basePath = window.BASE_PATH || '../../';

  const headerHtml = `
    <style>
      /* 로그인 버튼 스타일 (이미지와 동일한 다크네이비 톤) */
      .login-btn {
        background-color: #334155;
        color: #ffffff;
        font-weight: 700;
        padding: 7px 20px;
        border-radius: 4px;
        font-size: 14px;
        cursor: pointer;
        box-shadow: 0 1px 2px rgba(0,0,0,0.05);
        transition: background-color 0.15s;
      }
      .login-btn:hover {
        background-color: #1e293b;
      }

      /* 모바일 환경 긴급 SOS 버튼 */
      .sos-btn-mobile {
        margin-top: 12px;
        background-color: #ef4444;
        color: white;
        display: flex;
        justify-content: center;
        align-items: center;
        gap: 6px;
        padding: 12px;
        font-size: 16px;
        font-weight: 700;
        border-radius: 8px;
      }

      /* 모바일 마이페이지 버튼 */
      .mypage-btn-mobile {
        background-color: #0088cc;
        color: #ffffff;
        transition: background-color 0.15s;
      }
      .mypage-btn-mobile:hover {
        background-color: #0077b3;
      }
    </style>
    <div class="w-full flex flex-col bg-white border-b border-gray-200 shadow-sm">
      <header class="flex justify-between items-center px-4 md:px-6 max-w-[1400px] mx-auto w-full h-[70px]">
        
        <!-- 1) 좌측 로고 (메인화면 이동) -->
        <div class="flex items-center h-full cursor-pointer shrink-0 mr-4" data-href="${basePath}index.html" onclick="handleNavigation(this)">
          <img src="${basePath}assets/img/관리협회.png" class="h-[38px] md:h-[44px] w-auto object-contain" alt="대한집합건물관리협회" onerror="this.src='${basePath}방패로고.jpg'">
        </div>
        
        <!-- 2) 중앙 메인 GNB (PC 메뉴) -->
        <nav class="hidden lg:flex flex-1 justify-center items-center gap-6 xl:gap-9 font-medium text-[15px] xl:text-[16px] text-gray-700 whitespace-nowrap">
          <div data-menu="about" data-href="${basePath}pages/about/about.html" onclick="handleNavigation(this)" class="gnb-item cursor-pointer hover:text-[#0088cc] pb-1 transition-colors">협회소개</div>
          <div data-menu="jobs" data-href="${basePath}pages/jobs/job-list.html" onclick="handleNavigation(this)" class="gnb-item cursor-pointer hover:text-[#0088cc] pb-1 transition-colors">구인구직</div>
          <div data-menu="bid" data-href="${basePath}pages/bid/bid-list.html" onclick="handleNavigation(this)" class="gnb-item cursor-pointer hover:text-[#0088cc] pb-1 transition-colors">입찰공고</div>
          <div data-menu="cert" data-href="${basePath}pages/cert/cert-list.html" onclick="handleNavigation(this)" class="gnb-item cursor-pointer hover:text-[#0088cc] pb-1 transition-colors">자격증</div>
          <div data-menu="management" data-href="${basePath}pages/management/management.html" onclick="handleNavigation(this)" class="gnb-item cursor-pointer hover:text-[#0088cc] pb-1 transition-colors">관리단코너</div>
          <div data-menu="community" data-href="${basePath}pages/community/field-experience.html" onclick="handleNavigation(this)" class="gnb-item cursor-pointer hover:text-[#0088cc] pb-1 transition-colors">커뮤니티</div>
          
          <!-- 이미지와 동일한 텍스트형 긴급SOS 호출 -->
          <div data-menu="sos" data-href="${basePath}pages/SOS/sos-request.html" onclick="handleNavigation(this)" class="cursor-pointer text-[#dc2626] font-bold hover:text-[#b91c1c] pb-1 transition-colors flex items-center gap-1.5 ml-2">
            <i class="fa-solid fa-phone"></i>
            <span>긴급 SOS 호출</span>
          </div>
        </nav>

        <!-- 3) 우측 유틸리티 영역 -->
        <div class="hidden lg:flex items-center gap-4 shrink-0 ml-6 whitespace-nowrap font-medium text-gray-700">
          <!-- 알림 아이콘 -->
          <div class="relative cursor-pointer flex items-center justify-center w-[36px] h-[36px] rounded-full hover:bg-gray-100 transition-colors" title="알림 확인">
            <i class="fa-regular fa-bell text-gray-700 text-[20px]"></i>
            <span class="absolute top-0 right-0 flex h-4 w-4 items-center justify-center rounded-full bg-red-500 text-[10px] font-bold text-white border-2 border-white">2</span>
          </div>
          
          <div data-href="${basePath}pages/mypage/dashboard.html" onclick="handleNavigation(this)" class="cursor-pointer text-[15px] hover:text-[#0088cc]">마이페이지</div>
          <div onclick="window.location.href='${basePath}login.html'" class="login-btn ml-1">로그인</div>
        </div>
        
        <button class="lg:hidden p-2 text-[#0a1931] cursor-pointer ml-auto" onclick="toggleMobileMenu()" aria-label="메뉴열기">
          <svg class="pointer-events-none" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <line x1="3" y1="12" x2="21" y2="12"></line>
            <line x1="3" y1="6" x2="21" y2="6"></line>
            <line x1="3" y1="18" x2="21" y2="18"></line>
          </svg>
        </button>
      </header>
    </div>

    <!-- 모바일 메뉴 -->
    <div id="mobile-menu" style="display:none;" class="fixed inset-0 z-[1100] bg-black/60 transition-opacity" role="dialog" aria-modal="true">
      <div class="absolute top-0 right-0 bottom-0 w-4/5 max-w-[320px] bg-[#0a1931] shadow-2xl flex flex-col">
        <div class="flex justify-between items-center p-4 bg-white border-b border-gray-200">
          <div class="flex items-center h-full">
            <img src="${basePath}assets/img/관리협회.png" alt="대한집합건물관리협회" class="h-[36px] w-auto object-contain" />
          </div>
          <button onclick="toggleMobileMenu()" class="text-3xl text-gray-500 hover:text-gray-800 leading-none px-2">&times;</button>
        </div>
        
        <div class="flex-1 overflow-y-auto p-6 space-y-6 text-white font-medium text-[16px]">
          <div data-href="${basePath}pages/about/about.html" onclick="handleNavigation(this)" class="cursor-pointer hover:text-[#0088cc]">협회소개</div>
          <div data-href="${basePath}pages/jobs/job-list.html" onclick="handleNavigation(this)" class="cursor-pointer hover:text-[#0088cc]">구인구직</div>
          <div data-href="${basePath}pages/bid/bid-list.html" onclick="handleNavigation(this)" class="cursor-pointer hover:text-[#0088cc]">입찰공고</div>
          <div data-href="${basePath}pages/cert/cert-list.html" onclick="handleNavigation(this)" class="cursor-pointer hover:text-[#0088cc]">자격증</div>
          <div data-href="${basePath}pages/management/management.html" onclick="handleNavigation(this)" class="cursor-pointer hover:text-[#0088cc]">관리단코너</div>
          <div data-href="${basePath}pages/community/field-experience.html" onclick="handleNavigation(this)" class="cursor-pointer hover:text-[#0088cc]">커뮤니티</div>
          
          <!-- 모바일 긴급SOS 호출 (버튼형) -->
          <div data-href="${basePath}pages/SOS/sos-request.html" onclick="handleNavigation(this)" class="sos-btn-mobile cursor-pointer">
            <i class="fa-solid fa-phone"></i>
            <span>긴급 SOS 전문가 호출</span>
          </div>
        </div>
        
        <div class="p-6 bg-[#061124] space-y-3 text-[14px] font-medium text-center text-gray-300">
          <div class="flex gap-2 w-full">
            <div class="flex-1 py-3 bg-[#1e293b] text-white rounded-lg cursor-pointer hover:bg-gray-800 transition-colors relative">
              <i class="fa-regular fa-bell mr-1"></i> 알림
              <span class="absolute top-1 right-2 bg-red-500 text-white text-[10px] px-[5px] py-[2px] rounded-full leading-none border border-[#1e293b]">2</span>
            </div>
            <div data-href="${basePath}pages/mypage/dashboard.html" onclick="handleNavigation(this)" class="flex-1 py-3 mypage-btn-mobile rounded-lg cursor-pointer">마이페이지</div>
          </div>
          <div onclick="window.location.href='${basePath}login.html'" class="w-full py-2.5 mt-2 border border-gray-600 hover:text-white hover:bg-gray-800 rounded-lg cursor-pointer transition-colors">로그아웃</div>
        </div>
      </div>
    </div>
  `;

  document.documentElement.setAttribute('translate', 'no');

  window.handleNavigation = function(element) {
    var url = element.getAttribute('data-href');
    var target = element.getAttribute('data-target');
    if (url && url !== '#') {
      if (target === '_blank') { window.open(url, '_blank'); } 
      else { window.location.href = url; }
    }
  };

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

  function renderHeader() {
    const container = document.getElementById('header-container');
    if (container) {
      if (container.dataset.rendered === 'true') return;
      container.innerHTML = headerHtml;
      container.dataset.rendered = 'true';
    } else if (document.body) {
      document.body.insertAdjacentHTML('afterbegin', headerHtml);
    }

    const currentPath = window.location.pathname.toLowerCase();
    const menuItems = document.querySelectorAll('.gnb-item');
    menuItems.forEach(item => {
      const menuKey = item.getAttribute('data-menu');
      if (menuKey && currentPath.includes('/' + menuKey + '/')) {
        item.classList.add('text-[#0088cc]', 'border-b-[2px]', 'border-[#0088cc]');
      }
    });

    const headerEl = container ? container.querySelector(':scope > div') : null;
    if (headerEl && 'ResizeObserver' in window) {
      const updateHeaderHeightVar = () => {
        const h = headerEl.getBoundingClientRect().height;
        document.documentElement.style.setProperty('--header-actual-height', h + 'px');
      };
      updateHeaderHeightVar();
      const ro = new ResizeObserver(updateHeaderHeightVar);
      ro.observe(headerEl);
    } else if (headerEl) {
      const h = headerEl.getBoundingClientRect().height;
      document.documentElement.style.setProperty('--header-actual-height', h + 'px');
      window.addEventListener('resize', () => {
        const h2 = headerEl.getBoundingClientRect().height;
        document.documentElement.style.setProperty('--header-actual-height', h2 + 'px');
      });
    }
  }

  const targetContainer = document.getElementById('header-container');
  if (targetContainer) {
    renderHeader();
  } else {
    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', renderHeader);
    } else {
      renderHeader();
    }
  }
})();