/* ===== KCBMA Main JS v4.0 ===== */
document.addEventListener('DOMContentLoaded', function () {

  /* ── Mobile Menu ── */
  const mobileBtn = document.getElementById('mobile-menu-btn');
  const mobileMenu = document.getElementById('mobile-menu');
  const mobileClose = document.getElementById('mobile-close');
  function openMobile() { if (mobileMenu) { mobileMenu.classList.add('open'); document.body.style.overflow = 'hidden'; } }
  function closeMobile() { if (mobileMenu) { mobileMenu.classList.remove('open'); document.body.style.overflow = ''; } }
  if (mobileBtn) mobileBtn.addEventListener('click', openMobile);
  if (mobileClose) mobileClose.addEventListener('click', closeMobile);
  if (mobileMenu) mobileMenu.addEventListener('click', function (e) { if (e.target === mobileMenu) closeMobile(); });

  /* ── Sticky Header Shadow ── */
  const header = document.getElementById('site-header');
  if (header) {
    window.addEventListener('scroll', function () {
      header.classList.toggle('scrolled', window.scrollY > 50);
    }, { passive: true });
  }

  /* ── Category Filter Chips ── */
  document.querySelectorAll('.filter-chips').forEach(function (group) {
    group.querySelectorAll('.chip').forEach(function (btn) {
      btn.addEventListener('click', function () {
        group.querySelectorAll('.chip').forEach(function (b) { b.classList.remove('active'); });
        btn.classList.add('active');
        const cat = btn.getAttribute('data-cat');
        const container = document.getElementById(btn.getAttribute('data-target') || 'filter-items');
        if (!container) return;
        container.querySelectorAll('[data-cat]').forEach(function (item) {
          item.style.display = (cat === 'all' || item.getAttribute('data-cat') === cat) ? '' : 'none';
        });
      });
    });
  });

  /* ── Ad/Partner Apply Form ── */
  const applyForm = document.getElementById('apply-form');
  if (applyForm) {
    applyForm.addEventListener('submit', function (e) {
      e.preventDefault();
      const consent = applyForm.querySelector('[name="consent"]');
      if (!consent || !consent.checked) { alert('개인정보 수집에 동의해주세요.'); return; }
      applyForm.innerHTML = '<div style="text-align:center;padding:48px 0;"><div style="font-size:3.2rem;margin-bottom:16px;">✅</div><h3 style="font-size:1.3rem;font-weight:900;color:#0B2A5B;margin-bottom:8px;">광고 문의가 접수되었습니다!</h3><p style="color:#475569;font-size:.94rem;line-height:1.7;">담당자가 확인 후 1~2 영업일 이내 연락드리겠습니다.<br>감사합니다.</p></div>';
    });
  }

  /* ── Jobs Register Alert ── */
  const jobRegBtn = document.getElementById('job-reg-btn');
  if (jobRegBtn) jobRegBtn.addEventListener('click', function () { alert('회원 로그인 후 공고를 등록하실 수 있습니다.'); });

  /* ── Board Row Click ── */
  document.querySelectorAll('[data-href]').forEach(function (row) {
    row.addEventListener('click', function () {
      const href = row.getAttribute('data-href');
      if (href) window.location.href = href;
    });
  });

  /* ── Inquiry Alert (partner detail) ── */
  document.querySelectorAll('.btn-inquiry-alert').forEach(function (btn) {
    btn.addEventListener('click', function () { alert('업체 담당자에게 연결됩니다.\n전화: ' + (btn.getAttribute('data-phone') || '02-000-0000')); });
  });

  /* ── Smooth Anchor (About page) ── */
  document.querySelectorAll('a[href^="#"]').forEach(function (a) {
    a.addEventListener('click', function (e) {
      const id = a.getAttribute('href').slice(1);
      if (!id) return;
      const target = document.getElementById(id);
      if (target) {
        e.preventDefault();
        const top = target.getBoundingClientRect().top + window.scrollY - 76;
        window.scrollTo({ top: top, behavior: 'smooth' });
      }
    });
  });

  /* ── About sidebar active on scroll ── */
  const sections = document.querySelectorAll('.about-section[id]');
  const sideLinks = document.querySelectorAll('.sidebar-menu a[href^="#"]');
  if (sections.length && sideLinks.length) {
    window.addEventListener('scroll', function () {
      let cur = '';
      sections.forEach(function (s) {
        if (window.scrollY >= s.offsetTop - 100) cur = s.id;
      });
      sideLinks.forEach(function (l) { l.classList.toggle('active', l.getAttribute('href') === '#' + cur); });
    }, { passive: true });
  }

  /* ── Modal Controller ── */
  (function () {
    var loginBackdrop = document.getElementById('modal-login');
    var signupBackdrop = document.getElementById('modal-signup');

    function openModal(name) {
      var el = name === 'login' ? loginBackdrop : signupBackdrop;
      if (!el) return;
      el.classList.add('is-open');
      document.body.style.overflow = 'hidden';
      // clear errors
      el.querySelectorAll('.modal-error').forEach(function (e) { e.classList.remove('show'); });
    }

    function closeModal(name) {
      var el = name === 'login' ? loginBackdrop : signupBackdrop;
      if (!el) return;
      el.classList.remove('is-open');
      // restore overflow only if both modals closed
      if (loginBackdrop && !loginBackdrop.classList.contains('is-open') &&
          signupBackdrop && !signupBackdrop.classList.contains('is-open')) {
        document.body.style.overflow = '';
      }
    }

    function switchModal(from, to) {
      closeModal(from);
      setTimeout(function () { openModal(to); }, 60);
    }

    // trigger binding: data-open-modal="login" or data-open-modal="signup"
    document.querySelectorAll('[data-open-modal]').forEach(function (el) {
      el.addEventListener('click', function (e) {
        e.preventDefault();
        openModal(el.getAttribute('data-open-modal'));
      });
    });

    // backdrop click to close (but not dialog click)
    [loginBackdrop, signupBackdrop].forEach(function (bd) {
      if (!bd) return;
      bd.addEventListener('click', function (e) {
        if (e.target === bd) closeModal(bd.id === 'modal-login' ? 'login' : 'signup');
      });
    });

    // close buttons
    document.querySelectorAll('.modal-close[data-close-modal]').forEach(function (btn) {
      btn.addEventListener('click', function () {
        closeModal(btn.getAttribute('data-close-modal'));
      });
    });

    // switch links
    document.querySelectorAll('[data-switch-modal]').forEach(function (el) {
      el.addEventListener('click', function (e) {
        e.preventDefault();
        var parts = el.getAttribute('data-switch-modal').split(':');
        switchModal(parts[0], parts[1]);
      });
    });

    // Esc key
    document.addEventListener('keydown', function (e) {
      if (e.key === 'Escape') {
        if (loginBackdrop && loginBackdrop.classList.contains('is-open')) closeModal('login');
        if (signupBackdrop && signupBackdrop.classList.contains('is-open')) closeModal('signup');
      }
    });

    // Login form submit
    var loginForm = document.getElementById('login-form');
    if (loginForm) {
      loginForm.addEventListener('submit', function (e) {
        e.preventDefault();
        var id = loginForm.querySelector('[name="login-id"]').value.trim();
        var pw = loginForm.querySelector('[name="login-pw"]').value.trim();
        var idErr = document.getElementById('login-id-err');
        var pwErr = document.getElementById('login-pw-err');
        var ok = true;
        if (idErr) idErr.classList.remove('show');
        if (pwErr) pwErr.classList.remove('show');
        if (!id) { if (idErr) idErr.classList.add('show'); ok = false; }
        if (!pw) { if (pwErr) pwErr.classList.add('show'); ok = false; }
        if (!ok) return;
        var body = loginForm.closest('.modal-dialog');
        if (body) {
          body.innerHTML = '<div class="modal-success"><div class="modal-success-icon">&#10003;</div><p class="modal-success-msg">로그인 시뮬레이션: ' + id + '</p><p class="modal-success-sub">환영합니다!</p></div>';
          setTimeout(function () { closeModal('login'); }, 1500);
        }
      });
    }

    // Signup form submit
    var signupForm = document.getElementById('signup-form');
    if (signupForm) {
      signupForm.addEventListener('submit', function (e) {
        e.preventDefault();
        var pw = signupForm.querySelector('[name="signup-pw"]').value;
        var pw2 = signupForm.querySelector('[name="signup-pw2"]').value;
        var pwErr = document.getElementById('signup-pw-err');
        var pw2Err = document.getElementById('signup-pw2-err');
        var tc1Err = document.getElementById('signup-tc1-err');
        var tc2Err = document.getElementById('signup-tc2-err');
        var tc1 = signupForm.querySelector('[name="signup-tc1"]');
        var tc2 = signupForm.querySelector('[name="signup-tc2"]');
        var ok = true;
        [pwErr, pw2Err, tc1Err, tc2Err].forEach(function (e) { if (e) e.classList.remove('show'); });
        if (pw && pw2 && pw !== pw2) { if (pw2Err) pw2Err.classList.add('show'); ok = false; }
        if (tc1 && !tc1.checked) { if (tc1Err) tc1Err.classList.add('show'); ok = false; }
        if (tc2 && !tc2.checked) { if (tc2Err) tc2Err.classList.add('show'); ok = false; }
        if (!ok) return;
        var body = signupForm.closest('.modal-dialog');
        if (body) {
          body.innerHTML = '<div class="modal-success"><div class="modal-success-icon">&#10003;</div><p class="modal-success-msg">회원가입이 완료되었습니다 (시뮬레이션)</p><p class="modal-success-sub">로그인 후 이용해주세요.</p></div>';
          setTimeout(function () { closeModal('signup'); }, 2000);
        }
      });
    }
  })();

});
