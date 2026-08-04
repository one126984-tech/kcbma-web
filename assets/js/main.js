<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>대한집합건물관리협회</title>
  <script src="https://cdn.tailwindcss.com"></script>
  <style>
    /* 모달 필수 스타일 */
    .modal-backdrop { display: none; position: fixed; inset: 0; background: rgba(0,0,0,0.5); z-index: 1000; align-items: center; justify-content: center; }
    .modal-backdrop.is-open { display: flex; }
    .modal-dialog { background: white; padding: 30px; border-radius: 12px; width: 100%; max-width: 400px; position: relative; }
    .modal-close { position: absolute; top: 15px; right: 15px; cursor: pointer; }
    .modal-form { display: flex; flex-direction: column; gap: 15px; }
    .modal-input { border: 1px solid #ddd; padding: 10px; border-radius: 6px; width: 100%; }
    .btn-primary-full { background: #0e2b61; color: white; padding: 12px; border-radius: 6px; font-weight: bold; width: 100%; }
    .modal-switch { text-align: center; margin-top: 15px; font-size: 0.9rem; }
    .modal-switch a { color: #0e2b61; font-weight: bold; cursor: pointer; }
  </style>
</head>
<body class="bg-gray-50">

  <header class="w-full bg-[#0a1931] py-2">
    <div class="max-w-7xl mx-auto px-8 flex justify-end items-center space-x-4 text-white text-[13px] font-bold">
      <span data-open-modal="login" class="cursor-pointer hover:text-gray-300">로그인</span>
      <span data-open-modal="signup" class="cursor-pointer hover:text-gray-300">회원가입</span>
      <span data-open-modal="find-id" class="cursor-pointer hover:text-gray-300">아이디찾기</span>
      <span data-open-modal="find-pw" class="cursor-pointer hover:text-gray-300">비밀번호찾기</span>
    </div>
  </header>

  <div class="modal-backdrop" id="modal-login">
    <div class="modal-dialog">
      <button class="modal-close" onclick="closeModal('login')">✕</button>
      <h2 class="text-xl font-bold mb-4">로그인</h2>
      <form class="modal-form"><input class="modal-input" placeholder="아이디"><input class="modal-input" type="password" placeholder="비밀번호"><button type="button" class="btn-primary-full">로그인</button></form>
      <p class="modal-switch">아직 회원이 아니신가요? <a data-switch-modal="login:signup">회원가입</a></p>
    </div>
  </div>

  <div class="modal-backdrop" id="modal-signup">
    <div class="modal-dialog">
      <button class="modal-close" onclick="closeModal('signup')">✕</button>
      <h2 class="text-xl font-bold mb-4">회원가입</h2>
      <form class="modal-form"><input class="modal-input" placeholder="이름"><input class="modal-input" placeholder="아이디"><button type="button" class="btn-primary-full">가입하기</button></form>
      <p class="modal-switch">이미 계정이 있으신가요? <a data-switch-modal="signup:login">로그인</a></p>
    </div>
  </div>

  <div class="modal-backdrop" id="modal-find-id">
    <div class="modal-dialog">
      <button class="modal-close" onclick="closeModal('find-id')">✕</button>
      <h2 class="text-xl font-bold mb-4">아이디 찾기</h2>
      <form class="modal-form"><input class="modal-input" placeholder="이름"><input class="modal-input" placeholder="이메일"><button type="button" class="btn-primary-full">아이디 찾기</button></form>
      <p class="modal-switch"><a data-switch-modal="find-id:login">로그인으로 돌아가기</a></p>
    </div>
  </div>

  <div class="modal-backdrop" id="modal-find-pw">
    <div class="modal-dialog">
      <button class="modal-close" onclick="closeModal('find-pw')">✕</button>
      <h2 class="text-xl font-bold mb-4">비밀번호 찾기</h2>
      <form class="modal-form"><input class="modal-input" placeholder="아이디"><input class="modal-input" placeholder="이메일"><button type="button" class="btn-primary-full">비밀번호 찾기</button></form>
      <p class="modal-switch"><a data-switch-modal="find-pw:login">로그인으로 돌아가기</a></p>
    </div>
  </div>

  <script>
    // 모든 모달 제어 로직
    function openModal(name) {
      document.querySelectorAll('.modal-backdrop').forEach(m => m.classList.remove('is-open'));
      const el = document.getElementById('modal-' + name);
      if (el) el.classList.add('is-open');
    }

    function closeModal(name) {
      const el = document.getElementById('modal-' + name);
      if (el) el.classList.remove('is-open');
    }

    // 버튼 이벤트 리스너 등록
    document.querySelectorAll('[data-open-modal]').forEach(el => {
      el.addEventListener('click', () => openModal(el.getAttribute('data-open-modal')));
    });

    document.querySelectorAll('[data-switch-modal]').forEach(el => {
      el.addEventListener('click', () => {
        const [close, open] = el.getAttribute('data-switch-modal').split(':');
        closeModal(close);
        setTimeout(() => openModal(open), 100);
      });
    });
  </script>
</body>
</html>