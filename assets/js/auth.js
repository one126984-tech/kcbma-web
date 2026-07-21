/**
 * auth.js
 * 인증 모달 HTML 삽입 및 모달 제어 함수 (전역)
 */

document.addEventListener("DOMContentLoaded", () => {
  const authContainer = document.getElementById("auth-modal-container");
  if (!authContainer) return;

  // 현재 경로에 따라 로고 이미지 경로(prefix) 자동 계산
  const path = window.location.pathname;
  let prefix = "./";
  if (path.includes("/about/") || path.includes("/info/") || path.includes("/jobs/") || path.includes("/policy/") || path.includes("/partners/")) {
    prefix = "../";
  }

  // 모달 필수 CSS와 HTML을 한 번에 삽입 (스타일 누락 방지)
  authContainer.innerHTML = `
    <style>
      .modal-backdrop { display: none; position: fixed; inset: 0; background: rgba(0,0,0,0.6); z-index: 9999; align-items: center; justify-content: center; }
      .modal-backdrop.is-open { display: flex !important; }
      .modal-dialog { background: white; padding: 35px 30px; border-radius: 12px; width: 90%; max-width: 420px; position: relative; box-shadow: 0 10px 25px rgba(0,0,0,0.2); max-height: 90vh; overflow-y: auto; }
      .modal-close { position: absolute; top: 15px; right: 15px; cursor: pointer; background: none; border: none; padding: 5px; color: #94A3B8; font-size: 20px; }
      .modal-brand { text-align: center; margin-bottom: 20px; }
      .modal-title { font-size: 1.5rem; font-weight: 800; color: #0e2b61; margin-bottom: 5px; }
      .modal-input { width: 100%; padding: 12px 14px; border: 1.5px solid #E2E8F0; border-radius: 10px; margin-bottom: 12px; outline: none; }
      .modal-input:focus { border-color: #0e2b61; }
      .btn-primary-full { width: 100%; padding: 14px; background: #0B2A5B; color: #fff; font-weight: 700; border-radius: 10px; cursor: pointer; transition: background 0.2s; border: none; }
      .btn-primary-full:hover { background: #153b80; }
      .modal-switch { text-align: center; margin-top: 20px; font-size: 0.9rem; color: #64748b; }
      .modal-switch a { color: #0e2b61; font-weight: bold; cursor: pointer; text-decoration: none; }
      .modal-row { display: flex; justify-content: space-between; align-items: center; margin-bottom: 15px; font-size: 0.85rem; color: #475569; }
      .modal-remember { display: flex; align-items: center; gap: 6px; cursor: pointer; }
      .modal-forgot { cursor: pointer; transition: color 0.2s; color: #475569; text-decoration: none; }
      .modal-forgot:hover { color: #0e2b61; font-weight: bold; text-decoration: underline; }
    </style>

    <!-- 로그인 모달 -->
    <div class="modal-backdrop" id="modal-login">
      <div class="modal-dialog">
        <button type="button" class="modal-close" onclick="closeCustomModal('login')">✕</button>
        <div class="modal-brand">
          <img src="${prefix}대한집합건물관리협회-removebg-preview.png" style="height:68px; width:auto; max-width:85%; margin:0 auto 14px; object-fit:contain;" alt="KCBMA" onerror="this.style.display='none';">
          <p class="modal-title">로그인</p>
        </div>
        <form class="mt-4" onsubmit="event.preventDefault(); alert('로그인 기능 준비중입니다.'); closeCustomModal('login');">
          <input class="modal-input" type="text" placeholder="아이디 또는 이메일 입력" required />
          <input class="modal-input" type="password" placeholder="비밀번호" required />
          <div class="modal-row">
            <label class="modal-remember"><input type="checkbox" /> 로그인 유지</label>
            <div>
              <a class="modal-forgot" onclick="switchCustomModal('login', 'find-id')">아이디 찾기</a> | 
              <a class="modal-forgot" onclick="switchCustomModal('login', 'find-pw')">비밀번호 찾기</a>
            </div>
          </div>
          <button type="submit" class="btn-primary-full mt-2">로그인</button>
        </form>
        <p class="modal-switch">아직 회원이 아니신가요? <a onclick="switchCustomModal('login', 'signup')">회원가입</a></p>
      </div>
    </div>

    <!-- 회원가입 모달 -->
    <div class="modal-backdrop" id="modal-signup">
      <div class="modal-dialog">
        <button type="button" class="modal-close" onclick="closeCustomModal('signup')">✕</button>
        <div class="modal-brand">
          <img src="${prefix}대한집합건물관리협회-removebg-preview.png" style="height:68px; width:auto; max-width:85%; margin:0 auto 14px; object-fit:contain;" alt="KCBMA" onerror="this.style.display='none';">
          <p class="modal-title">회원가입</p>
        </div>
        <form class="mt-4" onsubmit="event.preventDefault(); alert('회원가입 기능 준비중입니다.'); closeCustomModal('signup');">
          <input class="modal-input" type="text" placeholder="성함" required />
          <input class="modal-input" type="email" placeholder="이메일 주소" required />
          <button type="submit" class="btn-primary-full mt-2">가입 신청</button>
        </form>
        <p class="modal-switch">이미 계정이 있으신가요? <a onclick="switchCustomModal('signup', 'login')">로그인</a></p>
      </div>
    </div>

    <!-- 아이디 찾기 모달 -->
    <div class="modal-backdrop" id="modal-find-id">
      <div class="modal-dialog">
        <button type="button" class="modal-close" onclick="closeCustomModal('find-id')">✕</button>
        <div class="modal-brand">
          <p class="modal-title">아이디 찾기</p>
        </div>
        <form class="mt-4" onsubmit="event.preventDefault(); alert('준비중입니다.'); closeCustomModal('find-id');">
          <input class="modal-input" type="email" placeholder="가입 이메일 주소" required />
          <button type="submit" class="btn-primary-full mt-2">아이디 찾기</button>
        </form>
        <p class="modal-switch"><a onclick="switchCustomModal('find-id', 'login')">로그인으로 돌아가기</a></p>
      </div>
    </div>

    <!-- 비밀번호 찾기 모달 -->
    <div class="modal-backdrop" id="modal-find-pw">
      <div class="modal-dialog">
        <button type="button" class="modal-close" onclick="closeCustomModal('find-pw')">✕</button>
        <div class="modal-brand">
          <p class="modal-title">비밀번호 찾기</p>
        </div>
        <form class="mt-4" onsubmit="event.preventDefault(); alert('준비중입니다.'); closeCustomModal('find-pw');">
          <input class="modal-input" type="text" placeholder="아이디" required />
          <input class="modal-input" type="email" placeholder="가입 이메일 주소" required />
          <button type="submit" class="btn-primary-full mt-2">임시 비밀번호 발송</button>
        </form>
        <p class="modal-switch"><a onclick="switchCustomModal('find-pw', 'login')">로그인으로 돌아가기</a></p>
      </div>
    </div>
  `;
});

// ★ HTML의 onclick에서 부를 수 있도록 전역(window) 함수로 등록
window.openCustomModal = function(id) {
  document.querySelectorAll('.modal-backdrop').forEach(m => m.classList.remove('is-open'));
  const modal = document.getElementById('modal-' + id);
  if (modal) {
    modal.classList.add('is-open');
    document.body.style.overflow = 'hidden'; // 배경 스크롤 방지
  }
};

window.closeCustomModal = function(id) {
  const modal = document.getElementById('modal-' + id);
  if (modal) {
    modal.classList.remove('is-open');
    document.body.style.overflow = ''; // 배경 스크롤 복구
  }
};

window.switchCustomModal = function(closeId, openId) {
  window.closeCustomModal(closeId);
  setTimeout(() => window.openCustomModal(openId), 100); // 부드러운 전환을 위해 약간의 딜레이
};