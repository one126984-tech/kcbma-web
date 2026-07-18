document.addEventListener("DOMContentLoaded", function() {
  const existingModal = document.getElementById('kcbma-auth-modals');
  if(existingModal) existingModal.remove();

  const modalWrapper = document.createElement('div');
  modalWrapper.id = 'kcbma-auth-modals';
  
  // 스타일 및 모달 HTML 구성
  modalWrapper.innerHTML = `
    <style>
      .auth-modal-backdrop { display: none; position: fixed; inset: 0; background: rgba(15, 23, 42, 0.65); backdrop-filter: blur(4px); z-index: 99999; align-items: center; justify-content: center; }
      .auth-modal-backdrop.is-open { display: flex !important; }
      .auth-modal-dialog { background: #ffffff; padding: 35px 30px; border-radius: 16px; width: 90%; max-width: 420px; position: relative; box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25); max-height: 90vh; overflow-y: auto; }
    </style>

    <!-- [1] 로그인 모달 -->
    <div id="modal-login" class="auth-modal-backdrop">
      <div class="auth-modal-dialog">
        <button onclick="closeCustomModal('login')" class="absolute top-4 right-4 text-gray-400 hover:text-gray-600 text-2xl font-bold">&times;</button>
        <div class="text-center mb-6">
          <h2 class="text-2xl font-black text-[#0B2A5B]">로그인</h2>
          <p class="text-xs text-gray-500 mt-1">대한집합건물관리협회 통합 회원 로그인</p>
        </div>
        
        <!-- 가짜 경고창을 제거하고, index.html과 연결되도록 id="login-form" 부여 -->
        <form id="login-form">
          <!-- 수파베이스 이메일 전용 설정에 맞춰 placeholder를 '이메일'로 수정하고 id="login-id" 부여 -->
          <input type="email" id="login-id" placeholder="이메일" class="w-full p-3.5 border border-gray-300 rounded-xl mb-3 text-sm focus:border-[#0B2A5B] focus:outline-none" required>
          <input type="password" id="login-pw" placeholder="비밀번호" class="w-full p-3.5 border border-gray-300 rounded-xl mb-2 text-sm focus:border-[#0B2A5B] focus:outline-none" required>
          
          <!-- 에러/성공 메시지가 출력될 공간 추가 -->
          <div id="login-message" class="text-sm font-bold text-center mb-3"></div>
          
          <button type="submit" id="login-btn" class="w-full py-3.5 bg-[#0B2A5B] hover:bg-[#153b80] text-white font-bold rounded-xl transition-colors mb-4">로그인</button>
        </form>

        <div class="relative flex py-2 items-center mb-4">
          <div class="flex-grow border-t border-gray-200"></div>
          <span class="flex-shrink mx-4 text-xs text-gray-400">또는</span>
          <div class="flex-grow border-t border-gray-200"></div>
        </div>
        
        <!-- 기존 카카오 1초 로그인 완벽 보존 -->
        <a href="https://kauth.kakao.com/oauth/authorize?client_id=52e43b389c04e568275a7d67d07308ee&redirect_uri=http://localhost:8080/login/kakao&response_type=code" class="block w-full">
          <div class="w-full bg-[#FEE500] hover:bg-[#FDD800] text-[#000000] py-3.5 rounded-xl font-bold text-[15px] flex justify-center items-center gap-2 transition-colors">
            <svg viewBox="0 0 32 32" class="w-5 h-5">
              <path fill="#000000" d="M16 4.64c-6.96 0-12.64 4.48-12.64 10.08 0 3.52 2.32 6.64 5.76 8.48l-1.44 5.44c-0.08 0.4 0.32 0.72 0.64 0.56l6.24-4.24c0.48 0.08 0.96 0.08 1.44 0.08 6.96 0 12.64-4.48 12.64-10.08s-5.68-10.08-12.64-10.08z"></path>
            </svg>
            카카오 1초 로그인
          </div>
        </a>
        
        <div class="text-center mt-6 text-xs text-gray-500">
          아직 회원이 아니신가요? <a onclick="switchCustomModal('login', 'signup')" class="text-[#2BA8A0] font-bold cursor-pointer hover:underline">회원가입</a>
        </div>
      </div>
    </div>

    <!-- [2] 회원가입 모달 -->
    <div id="modal-signup" class="auth-modal-backdrop">
      <div class="auth-modal-dialog">
        <button onclick="closeCustomModal('signup')" class="absolute top-4 right-4 text-gray-400 hover:text-gray-600 text-2xl font-bold">&times;</button>
        <div class="text-center mb-6">
          <h2 class="text-2xl font-black text-[#0B2A5B]">회원가입</h2>
          <p class="text-xs text-gray-500 mt-1">통합 회원이 되어 실무 인프라를 누려보세요</p>
        </div>
        
        <a href="https://kauth.kakao.com/oauth/authorize?client_id=52e43b389c04e568275a7d67d07308ee&redirect_uri=http://localhost:8080/login/kakao&response_type=code" class="block w-full mb-4">
          <div class="w-full bg-[#FEE500] hover:bg-[#FDD800] text-[#000000] py-3.5 rounded-xl font-bold text-[15px] flex justify-center items-center gap-2 transition-colors">
            <svg viewBox="0 0 32 32" class="w-5 h-5">
              <path fill="#000000" d="M16 4.64c-6.96 0-12.64 4.48-12.64 10.08 0 3.52 2.32 6.64 5.76 8.48l-1.44 5.44c-0.08 0.4 0.32 0.72 0.64 0.56l6.24-4.24c0.48 0.08 0.96 0.08 1.44 0.08 6.96 0 12.64-4.48 12.64-10.08s-5.68-10.08-12.64-10.08z"></path>
            </svg>
            카카오 계정으로 가입하기
          </div>
        </a>

        <div class="relative flex py-2 items-center mb-4">
          <div class="flex-grow border-t border-gray-200"></div>
          <span class="flex-shrink mx-4 text-xs text-gray-400">또는 일반 가입</span>
          <div class="flex-grow border-t border-gray-200"></div>
        </div>

        <!-- index.html의 로직이 요구하는 모든 필드(아이디, 비번확인, 약관동의) 추가 및 id 부여 -->
        <form id="signup-form">
          <input type="text" id="signup-name" placeholder="이름" class="w-full p-3 border border-gray-300 rounded-xl mb-3 text-sm focus:border-[#0B2A5B] focus:outline-none" required>
          <input type="text" id="signup-id" placeholder="아이디 (영문/숫자)" class="w-full p-3 border border-gray-300 rounded-xl mb-3 text-sm focus:border-[#0B2A5B] focus:outline-none" required>
          <input type="email" id="signup-email" placeholder="이메일" class="w-full p-3 border border-gray-300 rounded-xl mb-3 text-sm focus:border-[#0B2A5B] focus:outline-none" required>
          <input type="password" id="signup-pw" placeholder="비밀번호 (8자 이상)" class="w-full p-3 border border-gray-300 rounded-xl mb-3 text-sm focus:border-[#0B2A5B] focus:outline-none" required>
          <input type="password" id="signup-pw2" placeholder="비밀번호 확인" class="w-full p-3 border border-gray-300 rounded-xl mb-4 text-sm focus:border-[#0B2A5B] focus:outline-none" required>
          
          <div class="flex items-center gap-2 mb-2 px-1 text-sm text-gray-600">
            <input type="checkbox" id="signup-tc1" name="signup-tc1" required> <label for="signup-tc1" class="cursor-pointer">이용약관 동의 (필수)</label>
          </div>
          <div class="flex items-center gap-2 mb-4 px-1 text-sm text-gray-600">
            <input type="checkbox" id="signup-tc2" name="signup-tc2" required> <label for="signup-tc2" class="cursor-pointer">개인정보 처리방침 동의 (필수)</label>
          </div>

          <div id="signup-message" class="text-sm font-bold text-center mb-3"></div>
          
          <button type="submit" id="signup-btn" class="w-full py-3.5 bg-white border-2 border-[#0B2A5B] text-[#0B2A5B] hover:bg-gray-50 font-bold rounded-xl transition-colors">이메일로 가입하기</button>
        </form>

        <div class="text-center mt-6 text-xs text-gray-500">
          이미 계정이 있으신가요? <a onclick="switchCustomModal('signup', 'login')" class="text-[#0B2A5B] font-bold cursor-pointer hover:underline">로그인</a>
        </div>
      </div>
    </div>
  `;
  
  document.body.appendChild(modalWrapper);

  window.openCustomModal = function(id) {
    document.querySelectorAll('.auth-modal-backdrop').forEach(m => m.classList.remove('is-open'));
    const target = document.getElementById('modal-' + id);
    if (target) {
      target.classList.add('is-open');
      document.body.style.overflow = 'hidden';
      // 모달 열 때 이전 메시지 지우기 연동
      const msg = document.getElementById(id + '-message');
      if (msg) msg.textContent = '';
    }
  };
  
  window.closeCustomModal = function(id) {
    const target = document.getElementById('modal-' + id);
    if (target) {
      target.classList.remove('is-open');
      document.body.style.overflow = '';
      // 모달 닫을 때 폼 초기화 연동
      const form = document.getElementById(id + '-form');
      if (form) form.reset();
    }
  };

  window.switchCustomModal = function(closeId, openId) {
    window.closeCustomModal(closeId);
    setTimeout(() => window.openCustomModal(openId), 150);
  };
});