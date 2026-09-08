<style>
  /* 로그인 및 유틸리티 버튼 스타일 */
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
  .mypage-btn-mobile {
    background-color: #0088cc;
    color: #ffffff;
    transition: background-color 0.15s;
  }
  .mypage-btn-mobile:hover {
    background-color: #0077b3;
  }
</style>

<!-- PC 및 공통 헤더 상단바 -->
<div class="w-full flex flex-col bg-white border-b border-gray-200 shadow-sm" id="header-container">
  <header class="flex justify-between items-center px-4 md:px-6 max-w-[1400px] mx-auto w-full h-[70px]">
    
    <!-- 1) 좌측 로고 -->
    <div class="flex items-center h-full cursor-pointer shrink-0 mr-4" onclick="location.href='../../index.html'">
      <img src="../../assets/img/logo.png" class="h-[38px] md:h-[44px] w-auto object-contain" alt="대한집합건물관리협회">
    </div>
    
    <!-- 2) 중앙 메인 GNB (PC 메뉴) -->
    <nav class="hidden lg:flex flex-1 justify-center items-center gap-6 xl:gap-9 font-medium text-[15px] xl:text-[16px] text-gray-700 whitespace-nowrap">
      <div data-menu="about" onclick="location.href='../../about/about.html'" class="gnb-item cursor-pointer hover:text-[#0088cc] pb-1 transition-colors">협회소개</div>
      <div data-menu="jobs" onclick="location.href='../../jobs/job-list.html'" class="gnb-item cursor-pointer hover:text-[#0088cc] pb-1 transition-colors">구인구직</div>
      <div data-menu="bid" onclick="location.href='../../bid/bid-list.html'" class="gnb-item cursor-pointer hover:text-[#0088cc] pb-1 transition-colors">입찰공고</div>
      <div data-menu="cert" onclick="location.href='../../cert/cert-list.html'" class="gnb-item cursor-pointer hover:text-[#0088cc] pb-1 transition-colors">자격증</div>
      <div data-menu="board-corner" onclick="location.href='../../board/board-corner.html'" class="gnb-item cursor-pointer hover:text-[#0088cc] pb-1 transition-colors">관리단코너</div>
      
      <!-- ⭐ 신규: 지식컨설팅 (업무 Q&A로 연결) -->
      <div data-menu="consulting" onclick="location.href='../../community/work-qna.html'" class="gnb-item cursor-pointer hover:text-[#0088cc] pb-1 transition-colors font-bold text-[#12387a]">지식컨설팅</div>
      
      <!-- ⭐ 기존 커뮤니티 (공지사항으로 연결) -->
      <div data-menu="community" onclick="location.href='../../community/notice.html'" class="gnb-item cursor-pointer hover:text-[#0088cc] pb-1 transition-colors">커뮤니티</div>
      
      <div onclick="location.href='../../sos/sos-request.html'" class="cursor-pointer font-bold hover:text-[#b91c1c] pb-1 transition-colors flex items-center gap-1.5 ml-2" style="color: #ef4444;">
        <i class="fa-solid fa-phone"></i>
        <span>긴급 SOS 호출</span>
      </div>
    </nav>

    <!-- 3) 우측 유틸리티 영역 -->
    <div class="hidden lg:flex items-center gap-4 shrink-0 ml-6 whitespace-nowrap font-medium text-gray-700">
      <div class="relative cursor-pointer flex items-center justify-center w-[36px] h-[36px] rounded-full hover:bg-gray-100 transition-colors" title="알림 확인">
        <i class="fa-regular fa-bell text-gray-700 text-[20px]"></i>
        <span class="absolute top-0 right-0 flex h-4 w-4 items-center justify-center rounded-full bg-red-500 text-[10px] font-bold text-white border-2 border-white">2</span>
      </div>
      
      <div onclick="goToMypage()" class="cursor-pointer text-[15px] hover:text-[#0088cc]">마이페이지</div>
      <div id="pc-login-btn" class="login-btn ml-1">로그인</div>
    </div>
    
    <!-- 모바일 햄버거 버튼 -->
    <button class="lg:hidden p-2 text-[#0a1931] cursor-pointer ml-auto" onclick="toggleMobileMenu()" aria-label="메뉴열기">
      <svg class="pointer-events-none" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <line x1="3" y1="12" x2="21" y2="12"></line>
        <line x1="3" y1="6" x2="21" y2="6"></line>
        <line x1="3" y1="18" x2="21" y2="18"></line>
      </svg>
    </button>
  </header>
</div>

<!-- 모바일 전용 전체화면 메뉴 -->
<div id="mobile-menu" style="display:none;" class="fixed inset-0 z-[1100] bg-black/60 transition-opacity" role="dialog" aria-modal="true">
  <div class="absolute top-0 right-0 bottom-0 w-4/5 max-w-[320px] bg-[#0a1931] shadow-2xl flex flex-col">
    <div class="flex justify-between items-center p-4 bg-white border-b border-gray-200">
      <div class="flex items-center h-full">
        <img src="../../assets/img/logo.png" alt="대한집합건물관리협회" class="h-[36px] w-auto object-contain" />
      </div>
      <button onclick="toggleMobileMenu()" class="text-3xl text-gray-500 hover:text-gray-800 leading-none px-2">&times;</button>
    </div>
    
    <div class="flex-1 overflow-y-auto p-6 space-y-6 text-white font-medium text-[16px]">
      <div onclick="location.href='../../about/about.html'" class="cursor-pointer hover:text-[#0088cc]">협회소개</div>
      <div onclick="location.href='../../jobs/job-list.html'" class="cursor-pointer hover:text-[#0088cc]">구인구직</div>
      <div onclick="location.href='../../bid/bid-list.html'" class="cursor-pointer hover:text-[#0088cc]">입찰공고</div>
      <div onclick="location.href='../../cert/cert-list.html'" class="cursor-pointer hover:text-[#0088cc]">자격증</div>
      <div onclick="location.href='../../board/board-corner.html'" class="cursor-pointer hover:text-[#0088cc]">관리단코너</div>
      
      <!-- ⭐ 모바일 메뉴 신규 분리 -->
      <div onclick="location.href='../../community/work-qna.html'" class="cursor-pointer hover:text-[#0088cc] text-blue-300">지식컨설팅</div>
      <div onclick="location.href='../../community/notice.html'" class="cursor-pointer hover:text-[#0088cc]">커뮤니티</div>
      
      <div onclick="location.href='../../sos/sos-request.html'" class="sos-btn-mobile cursor-pointer" style="background-color: #ef4444; color: white;">
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
        <div onclick="goToMypage()" class="flex-1 py-3 mypage-btn-mobile rounded-lg cursor-pointer">마이페이지</div>
      </div>
      <div id="mobile-login-btn" class="w-full py-2.5 mt-2 border border-gray-600 hover:text-white hover:bg-gray-800 rounded-lg cursor-pointer transition-colors">로그인</div>
    </div>
  </div>
</div>

<!-- 헤더 제어용 자바스크립트 -->
<script>
  window.__isLoggedIn = false;

  // 1. 모바일 메뉴 토글
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

  // 2. 마이페이지 이동 전 권한 체크
  window.goToMypage = function() {
    if (window.__isLoggedIn) {
      window.location.href = '../../mypage/dashboard.html';
    } else {
      showLoginRequiredModal();
    }
  };

  function showLoginRequiredModal() {
    if (document.getElementById('login-required-modal')) return;
    var modal = document.createElement('div');
    modal.id = 'login-required-modal';
    modal.style.cssText = 'position:fixed;inset:0;background:rgba(0,0,0,.5);z-index:99999;display:flex;align-items:center;justify-content:center;padding:16px;';
    modal.innerHTML =
      '<div style="background:#fff;border-radius:16px;padding:28px 24px;max-width:320px;width:100%;text-align:center;box-shadow:0 20px 40px rgba(0,0,0,.2);">' +
        '<p style="font-size:15px;color:#1f2937;font-weight:700;margin-bottom:6px;">먼저 로그인 후 이용 가능합니다.</p>' +
        '<p style="font-size:13px;color:#6b7280;margin-bottom:20px;">마이페이지는 로그인이 필요한 서비스입니다.</p>' +
        '<div style="display:flex;gap:8px;">' +
          '<button id="login-required-cancel" style="flex:1;padding:10px;border-radius:8px;border:1px solid #d1d5db;background:#fff;color:#374151;font-weight:700;cursor:pointer;">취소</button>' +
          '<button id="login-required-confirm" style="flex:1;padding:10px;border-radius:8px;border:none;background:#0B2A5B;color:#fff;font-weight:700;cursor:pointer;">로그인</button>' +
        '</div>' +
      '</div>';
    document.body.appendChild(modal);
    document.getElementById('login-required-cancel').onclick = function() { modal.remove(); };
    document.getElementById('login-required-confirm').onclick = function() {
      localStorage.setItem('returnUrl', '/mypage/dashboard.html');
      window.location.href = '../../login.html';
    };
  }

  // 3. 현재 페이지에 맞춰 GNB 파란색 밑줄 활성화 로직
  function activateCurrentMenu() {
    const currentPath = window.location.pathname.toLowerCase();
    const menuItems = document.querySelectorAll('.gnb-item');
    
    menuItems.forEach(item => {
      const menuKey = item.getAttribute('data-menu');
      let isActive = false;
      
      if (menuKey === 'consulting') {
        if (currentPath.includes('work-qna.html') || currentPath.includes('field-experience.html') || currentPath.includes('work-qna-detail.html') || currentPath.includes('field-experience-detail.html')) {
          isActive = true;
        }
      } else if (menuKey === 'community') {
        if (currentPath.includes('notice.html') || currentPath.includes('free-board.html') || currentPath.includes('data-room.html') || currentPath.includes('notice-detail.html') || currentPath.includes('free-board-detail.html')) {
          isActive = true;
        }
      } else if (menuKey && currentPath.includes('/' + menuKey + '/')) {
        isActive = true;
      }
      
      if (isActive) {
        item.classList.add('text-[#0088cc]', 'border-b-[2px]', 'border-[#0088cc]');
      }
    });
  }

  // 4. Supabase 로그인 상태 연동
  async function initAuth() {
    if (!window.supabase) return;
    const supabaseUrl = 'https://ehrahnnowwjkgycvlbzk.supabase.co';
    const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVocmFobm5vd3dqa2d5Y3ZsYnprIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODIwMzQ1NjQsImV4cCI6MjA5NzYxMDU2NH0.A0MfXNI4W7sPUM4UwSn7_kY5n2gEhp3N8ubH7uBZZwk';
    
    // 전역 클라이언트가 없으면 생성
    if (!window.supabaseClient) {
      window.supabaseClient = window.supabase.createClient(supabaseUrl, supabaseKey);
    }

    const { data: { session } } = await window.supabaseClient.auth.getSession();
    updateAuthUI(session);

    window.supabaseClient.auth.onAuthStateChange((event, session) => {
      updateAuthUI(session);
    });
  }

  function updateAuthUI(session) {
    window.__isLoggedIn = !!session;
    const pcLoginBtn = document.getElementById('pc-login-btn');
    const mobileLoginBtn = document.getElementById('mobile-login-btn');

    const handleLogout = async () => {
      await window.supabaseClient.auth.signOut();
      alert("로그아웃 되었습니다.");
      window.location.reload();
    };
    
    const handleLogin = () => { window.location.href = '../../login.html'; };

    if (session) {
      if (pcLoginBtn) { pcLoginBtn.innerText = "로그아웃"; pcLoginBtn.onclick = handleLogout; }
      if (mobileLoginBtn) { mobileLoginBtn.innerText = "로그아웃"; mobileLoginBtn.onclick = handleLogout; }
    } else {
      if (pcLoginBtn) { pcLoginBtn.innerText = "로그인"; pcLoginBtn.onclick = handleLogin; }
      if (mobileLoginBtn) { mobileLoginBtn.innerText = "로그인"; mobileLoginBtn.onclick = handleLogin; }
    }
  }

  // 실행
  document.addEventListener('DOMContentLoaded', () => {
    activateCurrentMenu();
    if(window.supabase) {
        initAuth();
    } else {
        // supabase 스크립트가 늦게 로드될 경우를 대비
        const script = document.createElement('script');
        script.src = 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2';
        script.onload = initAuth;
        document.head.appendChild(script);
    }
  });
</script>