// 1. 공통 모달 HTML을 변수에 저장 (백틱 ` 사용)
const authModalsHtml = `
  <div class="modal-backdrop" id="modal-login" role="dialog" aria-modal="true" aria-label="로그인">
    <div class="modal-dialog">
      <button type="button" class="modal-close" onclick="closeCustomModal('login')" aria-label="닫기">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
      </button>
      <div class="modal-brand">
        <img src="assets/img/방패로고-removebg-preview.png" style="height:50px; width:auto; margin:0 auto 10px;" alt="KCBMA" class="modal-brand-img" onerror="this.style.display='none'" />
        <p class="modal-title">로그인</p>
        <p class="modal-subtitle">대한집합건물관리협회에 오신 것을 환영합니다</p>
      </div>
      <form class="modal-form" id="login-form" novalidate>
        <div class="modal-field">
          <label class="modal-label" for="login-id">아이디 또는 이메일</label>
          <input class="modal-input" type="text" id="login-id" name="login-id" placeholder="아이디 또는 이메일 입력" autocomplete="username" required />
        </div>
        <div class="modal-field">
          <label class="modal-label" for="login-pw">비밀번호</label>
          <input class="modal-input" type="password" id="login-pw" name="login-pw" placeholder="비밀번호" autocomplete="current-password" required />
        </div>
        <div class="modal-row">
          <label class="modal-remember" style="cursor:pointer;"><input type="checkbox" name="login-keep" /> 로그인 상태 유지</label>
          <div>
            <a class="modal-forgot" onclick="switchCustomModal('login', 'find-id')">아이디 찾기</a>
            <span class="mx-1 text-gray-400">|</span>
            <a class="modal-forgot" onclick="switchCustomModal('login', 'find-pw')">비밀번호 찾기</a>
          </div>
        </div>
        <div id="login-message" class="modal-message"></div>
        <button type="submit" id="login-btn" class="btn-primary-full">로그인</button>
      </form>
      <p class="modal-switch">아직 회원이 아니신가요? <a onclick="switchCustomModal('login', 'signup')">회원가입</a></p>
    </div>
  </div>

  <div class="modal-backdrop" id="modal-signup" role="dialog" aria-modal="true" aria-label="회원가입">
    <div class="modal-dialog signup-dialog">
      <button type="button" class="modal-close" onclick="closeCustomModal('signup')" aria-label="닫기">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
      </button>
      <div class="modal-brand">
        <img src="assets/img/방패로고-removebg-preview.png" style="height:50px; width:auto; margin:0 auto 10px;" alt="KCBMA" class="modal-brand-img" onerror="this.style.display='none'" />
        <p class="modal-title">회원가입</p>
        <p class="modal-subtitle">대한집합건물관리협회 회원이 되어보세요</p>
      </div>
      <form class="modal-form" id="signup-form" novalidate>
        <div class="modal-field">
          <label class="modal-label" for="signup-name">이름 <span style="color:#EF4444">*</span></label>
          <input class="modal-input" type="text" id="signup-name" name="signup-name" placeholder="이름" required />
        </div>
        <div class="modal-field">
          <label class="modal-label" for="signup-id">아이디 <span style="color:#EF4444">*</span></label>
          <input class="modal-input" type="text" id="signup-id" name="signup-id" placeholder="아이디 (영문·숫자)" required />
        </div>
        <div class="modal-field">
          <label class="modal-label" for="signup-email">이메일 <span style="color:#EF4444">*</span></label>
          <input class="modal-input" type="email" id="signup-email" name="signup-email" placeholder="이메일 주소" required />
        </div>
        <div class="modal-field">
          <label class="modal-label" for="signup-pw">비밀번호 <span style="color:#EF4444">*</span></label>
          <input class="modal-input" type="password" id="signup-pw" name="signup-pw" placeholder="비밀번호 (8자 이상)" required />
        </div>
        <div class="modal-field">
          <label class="modal-label" for="signup-pw2">비밀번호 확인 <span style="color:#EF4444">*</span></label>
          <input class="modal-input" type="password" id="signup-pw2" name="signup-pw2" placeholder="비밀번호 확인" required />
        </div>
        <div class="modal-checkbox-group" style="font-size:0.85rem; margin-top:5px; line-height: 1.8;">
          <label class="modal-check-label" style="display:block; cursor:pointer;">
            <input type="checkbox" name="signup-tc1" /> <span style="color:#EF4444; font-weight:bold;">[필수]</span> <a>이용약관</a>에 동의합니다
          </label>
          <label class="modal-check-label" style="display:block; cursor:pointer;">
            <input type="checkbox" name="signup-tc2" /> <span style="color:#EF4444; font-weight:bold;">[필수]</span> <a>개인정보 처리방침</a>에 동의합니다
          </label>
        </div>
        <div id="signup-message" class="modal-message"></div>
        <button type="submit" id="signup-btn" class="btn-primary-full">회원가입</button>
      </form>
      <p class="modal-switch">이미 계정이 있으신가요? <a onclick="switchCustomModal('signup', 'login')">로그인</a></p>
    </div>
  </div>

  <div class="modal-backdrop" id="modal-find-id" role="dialog" aria-modal="true" aria-label="아이디 찾기">
    <div class="modal-dialog">
      <button type="button" class="modal-close" onclick="closeCustomModal('find-id')" aria-label="닫기">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
      </button>
      <div class="modal-brand">
        <p class="modal-title">아이디 찾기</p>
        <p class="modal-subtitle">가입 시 등록한 정보를 입력해주세요.</p>
      </div>
      <form class="modal-form" id="find-id-form">
        <div class="modal-field">
          <label class="modal-label" for="find-id-name">이름</label>
          <input class="modal-input" type="text" id="find-id-name" placeholder="이름 입력" required />
        </div>
        <div class="modal-field">
          <label class="modal-label" for="find-id-email">이메일</label>
          <input class="modal-input" type="email" id="find-id-email" placeholder="가입한 이메일 입력" required />
        </div>
        <div id="find-id-message" class="modal-message"></div>
        <button type="submit" id="find-id-btn" class="btn-primary-full" style="margin-top:20px;">아이디 찾기</button>
      </form>
      <p class="modal-switch"><a onclick="switchCustomModal('find-id', 'login')">로그인으로 돌아가기</a></p>
    </div>
  </div>

  <div class="modal-backdrop" id="modal-find-pw" role="dialog" aria-modal="true" aria-label="비밀번호 찾기">
    <div class="modal-dialog">
      <button type="button" class="modal-close" onclick="closeCustomModal('find-pw')" aria-label="닫기">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
      </button>
      <div class="modal-brand">
        <p class="modal-title">비밀번호 찾기</p>
        <p class="modal-subtitle">가입 시 등록한 정보를 입력해주세요.</p>
      </div>
      <form class="modal-form" id="find-pw-form">
        <div class="modal-field">
          <label class="modal-label" for="find-pw-id">아이디</label>
          <input class="modal-input" type="text" id="find-pw-id" placeholder="아이디 입력" required />
        </div>
        <div class="modal-field">
          <label class="modal-label" for="find-pw-email">이메일</label>
          <input class="modal-input" type="email" id="find-pw-email" placeholder="가입한 이메일 입력" required />
        </div>
        <div id="find-pw-message" class="modal-message"></div>
        <button type="submit" id="find-pw-btn" class="btn-primary-full" style="margin-top:20px;">임시 비밀번호 발송</button>
      </form>
      <p class="modal-switch"><a onclick="switchCustomModal('find-pw', 'login')">로그인으로 돌아가기</a></p>
    </div>
  </div>
`;

// 2. 전역 함수 설정 (모달 열기/닫기 등)
let supabaseClientInstance;

window.openCustomModal = function(id) {
  document.querySelectorAll('.modal-backdrop').forEach(function(m) { m.classList.remove('is-open'); });
  var modal = document.getElementById('modal-' + id);
  if (modal) {
    modal.classList.add('is-open');
    document.body.style.overflow = 'hidden'; 
    var msg = modal.querySelector('.modal-message');
    if (msg) { msg.className = 'modal-message'; msg.textContent = ''; }
  }
};

window.closeCustomModal = function(id) {
  var modal = document.getElementById('modal-' + id);
  if (modal) {
    modal.classList.remove('is-open');
    document.body.style.overflow = ''; 
    if (id === 'login') resetLoginForm();
  }
};

window.switchCustomModal = function(closeId, openId) {
  closeCustomModal(closeId);
  setTimeout(function() { openCustomModal(openId); }, 150); 
};

window.showMessage = function(elId, text, type) {
  const el = document.getElementById(elId);
  if (el) {
    el.textContent = text;
    el.className = 'modal-message ' + type;
  }
};

window.handleLogout = async function() {
  if (supabaseClientInstance) {
    await supabaseClientInstance.auth.signOut();
    alert('안전하게 로그아웃 되었습니다.');
    window.location.reload();
  }
};

function resetLoginForm() {
  const idInput = document.getElementById('login-id');
  const pwInput = document.getElementById('login-pw');
  const msg = document.getElementById('login-message');
  if(idInput) idInput.value = '';
  if(pwInput) pwInput.value = '';
  if(msg) msg.textContent = '';
}

// 3. 모달 HTML 삽입 및 이벤트 초기화 함수
function initAuthModals() {
  // body 끝에 HTML 밀어넣기
  document.body.insertAdjacentHTML('beforeend', authModalsHtml);

  // 모달 배경 클릭 시 닫기 이벤트 연결
  document.querySelectorAll('.modal-backdrop').forEach(function(backdrop) {
    backdrop.addEventListener('click', function(e) {
      if (e.target === backdrop) {
        backdrop.classList.remove('is-open');
        document.body.style.overflow = '';
      }
    });
  });

  // ----------------------------------------------------
  // 로그인 기능 연결
  // ----------------------------------------------------
  const loginForm = document.getElementById('login-form');
  if(loginForm) {
    loginForm.addEventListener('submit', async (e) => {
      e.preventDefault();
      
      const idInput = document.getElementById('login-id');
      const pwInput = document.getElementById('login-pw');
      const btn = document.getElementById('login-btn');
      
      const emailOrId = idInput.value.trim();
      const password = pwInput.value;

      if(!emailOrId || !password) {
        return showMessage('login-message', '정보를 모두 입력해 주세요.', 'error');
      }
      
      btn.disabled = true; 
      btn.textContent = '로그인 중...';
      
      let loginEmail = emailOrId;
      if (!emailOrId.includes('@')) {
        loginEmail = emailOrId + "@kcbma.com";
      }

      const { error } = await supabaseClientInstance.auth.signInWithPassword({ 
        email: loginEmail, 
        password: password 
      });
      
      if (error) {
        showMessage('login-message', '아이디 또는 비밀번호가 올바르지 않습니다.', 'error');
        pwInput.value = '';
        pwInput.focus();
      } else {
        showMessage('login-message', '로그인 성공!', 'success');
        resetLoginForm();
        setTimeout(() => window.location.reload(), 1000);
      }
      btn.disabled = false; 
      btn.textContent = '로그인';
    });
  }

  // ----------------------------------------------------
  // 회원가입 기능 연결
  // ----------------------------------------------------
  const signupForm = document.getElementById('signup-form');
  if(signupForm) {
    signupForm.addEventListener('submit', async (e) => {
      e.preventDefault();
      const name = document.getElementById('signup-name').value.trim();
      const username = document.getElementById('signup-id').value.trim();
      const email = document.getElementById('signup-email').value.trim();
      const pw = document.getElementById('signup-pw').value;
      const pw2 = document.getElementById('signup-pw2').value;
      const tc1 = document.querySelector('[name="signup-tc1"]').checked;
      const tc2 = document.querySelector('[name="signup-tc2"]').checked;
      const btn = document.getElementById('signup-btn');

      const idRegex = /^[a-zA-Z0-9]+$/;

      if(!name || !username || !email || !pw) return showMessage('signup-message', '필수 입력 항목을 모두 채워주세요.', 'error');
      if (!idRegex.test(username)) return showMessage('signup-message', '아이디는 영문과 숫자만 사용 가능합니다.', 'error');
      if(pw.length < 8) return showMessage('signup-message', '비밀번호는 8자 이상이어야 합니다.', 'error');
      if(pw !== pw2) return showMessage('signup-message', '비밀번호 확인이 일치하지 않습니다.', 'error');
      if(!tc1 || !tc2) return showMessage('signup-message', '필수 약관에 모두 동의해 주세요.', 'error');

      btn.disabled = true; btn.textContent = '처리 중...';

      const { error } = await supabaseClientInstance.auth.signUp({
        email: email,
        password: pw,
        options: { data: { name: name, username: username } }
      });

      if (error) {
        showMessage('signup-message', '가입 실패: ' + error.message, 'error');
      } else {
        showMessage('signup-message', '회원가입 성공! 잠시 후 자동으로 로그인 창으로 이동합니다.', 'success');
        e.target.reset();
        setTimeout(() => switchCustomModal('signup', 'login'), 2000);
      }
      btn.disabled = false; btn.textContent = '회원가입';
    });
  }

  // ----------------------------------------------------
  // 아이디/비밀번호 찾기 기능 연결
  // ----------------------------------------------------
  const findIdForm = document.getElementById('find-id-form');
  if(findIdForm) {
    findIdForm.addEventListener('submit', (e) => {
      e.preventDefault();
      const email = document.getElementById('find-id-email').value.trim();
      showMessage('find-id-message', `입력하신 이메일(${email}) 주소가 회원 아이디 식별 기준입니다.`, 'info');
    });
  }

  const findPwForm = document.getElementById('find-pw-form');
  if(findPwForm) {
    findPwForm.addEventListener('submit', async (e) => {
      e.preventDefault();
      const email = document.getElementById('find-pw-email').value.trim();
      const btn = document.getElementById('find-pw-btn');
      
      btn.disabled = true; btn.textContent = '발송 중...';
      const { error } = await supabaseClientInstance.auth.resetPasswordForEmail(email);
      if (error) {
        showMessage('find-pw-message', '오류: ' + error.message, 'error');
      } else {
        showMessage('find-pw-message', '입력하신 이메일로 비밀번호 재설정 링크를 보냈습니다.', 'success');
      }
      btn.disabled = false; btn.textContent = '임시 비밀번호 발송';
    });
  }
}

// 4. Supabase 초기화 및 페이지 로드 시 실행
document.addEventListener('DOMContentLoaded', () => {
  const SUPABASE_URL = 'https://ehrahnnowwjkgycvlbzk.supabase.co';
  const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVocmFobm5vd3dqa2d5Y3ZsYnprIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODIwMzQ1NjQsImV4cCI6MjA5NzYxMDU2NH0.A0MfXNI4W7sPUM4UwSn7_kY5n2gEhp3N8ubH7uBZZwk';
  
  if (window.supabase) {
    supabaseClientInstance = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

    supabaseClientInstance.auth.getSession().then(({ data: { session } }) => updateUI(session));
    supabaseClientInstance.auth.onAuthStateChange((event, session) => updateUI(session));
  }

  function updateUI(session) {
    const authBtns = document.getElementById('auth-buttons');
    const userSec = document.getElementById('user-section');
    
    if (session && session.user) {
      const name = session.user.user_metadata?.name || session.user.email.split('@')[0];
      if(authBtns) authBtns.style.display = 'none';
      if(userSec) {
        userSec.style.display = 'flex';
        userSec.innerHTML = `<div class="flex items-center text-white text-[13px] md:text-[15px] font-bold px-1"><span class="text-[#8b5cf6] mr-1.5 text-lg">👤</span><span>${name}</span>님</div><div onclick="window.handleLogout()" class="bg-[#dc2626] hover:bg-[#b91c1c] px-2.5 py-1.5 md:px-4 md:py-1.5 text-[11px] md:text-[13px] rounded cursor-pointer transition-colors whitespace-nowrap">로그아웃</div>`;
      }
    } else {
      if(authBtns) authBtns.style.display = 'flex';
      if(userSec) userSec.style.display = 'none';
    }
  }

  // ★ 페이지 화면이 로드되면 모달을 생성하고 이벤트를 연결합니다.
  initAuthModals();
});