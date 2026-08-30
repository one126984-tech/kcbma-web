/**
 * cert-common.js
 * 자격증 발급비 계좌이체 안내 + 공통 토스트 알림 유틸
 * - 계좌 정보는 아래 CERT_PAYMENT_ACCOUNT 상수에서 일괄 관리 (변경 시 이 파일만 수정)
 */

// ===================== 자격증 발급비 계좌 정보 (예시 — 실제 계좌로 교체 필요) =====================
const CERT_PAYMENT_ACCOUNT = {
  bank: '국민은행',
  number: '000-000-00-000000',
  holder: '대한집합건물관리협회',
  amount: 250000 // 기본 발급비 (원). 과정별 cert_price 가 있으면 그 값을 우선 사용.
};

function certPaymentAmountLabel(amount) {
  const n = (amount === undefined || amount === null) ? CERT_PAYMENT_ACCOUNT.amount : amount;
  return n.toLocaleString() + '원';
}

// 계좌 정보 안내 박스 HTML (공통 컴포넌트)
function renderCertAccountBox(amount) {
  const amt = (amount === undefined || amount === null) ? CERT_PAYMENT_ACCOUNT.amount : amount;
  return `
    <div class="cert-account-box">
      <div class="cert-account-row"><span class="label">은행</span><span class="value">${CERT_PAYMENT_ACCOUNT.bank}</span></div>
      <div class="cert-account-row"><span class="label">계좌번호</span><span class="value font-mono">${CERT_PAYMENT_ACCOUNT.number}</span></div>
      <div class="cert-account-row"><span class="label">예금주</span><span class="value">${CERT_PAYMENT_ACCOUNT.holder}</span></div>
      <div class="cert-account-row"><span class="label">입금액</span><span class="value cert-account-amount">${amt.toLocaleString()}원</span></div>
    </div>
  `;
}

// ===================== 공통 토스트 알림 =====================
(function () {
  function ensureContainer() {
    let el = document.getElementById('kcbma-toast-container');
    if (!el) {
      el = document.createElement('div');
      el.id = 'kcbma-toast-container';
      el.style.position = 'fixed';
      el.style.top = '20px';
      el.style.left = '50%';
      el.style.transform = 'translateX(-50%)';
      el.style.zIndex = '99999';
      el.style.display = 'flex';
      el.style.flexDirection = 'column';
      el.style.gap = '10px';
      el.style.pointerEvents = 'none';
      document.body.appendChild(el);
    }
    return el;
  }

  window.showToast = function (message, type) {
    const t = type || 'info'; // success | error | info
    const container = ensureContainer();

    const colors = {
      success: { bg: '#ecfdf5', border: '#10b981', text: '#065f46', icon: 'fa-circle-check' },
      error:   { bg: '#fef2f2', border: '#ef4444', text: '#991b1b', icon: 'fa-circle-xmark' },
      info:    { bg: '#eff6ff', border: '#3b82f6', text: '#1e3a8a', icon: 'fa-circle-info' }
    };
    const c = colors[t] || colors.info;

    const toast = document.createElement('div');
    toast.style.background = c.bg;
    toast.style.border = `1px solid ${c.border}`;
    toast.style.color = c.text;
    toast.style.padding = '14px 22px';
    toast.style.borderRadius = '10px';
    toast.style.fontSize = '14px';
    toast.style.fontWeight = '700';
    toast.style.boxShadow = '0 6px 20px rgba(0,0,0,0.12)';
    toast.style.display = 'flex';
    toast.style.alignItems = 'center';
    toast.style.gap = '10px';
    toast.style.opacity = '0';
    toast.style.transition = 'opacity 0.25s ease, transform 0.25s ease';
    toast.style.transform = 'translateY(-8px)';
    toast.style.pointerEvents = 'auto';
    toast.style.whiteSpace = 'pre-line';
    toast.innerHTML = `<i class="fas ${c.icon}"></i><span>${message}</span>`;

    container.appendChild(toast);
    requestAnimationFrame(() => {
      toast.style.opacity = '1';
      toast.style.transform = 'translateY(0)';
    });

    setTimeout(() => {
      toast.style.opacity = '0';
      toast.style.transform = 'translateY(-8px)';
      setTimeout(() => toast.remove(), 250);
    }, 3200);
  };
})();

// ===================== 공통 로딩 스피너 HTML =====================
function certLoadingHtml(message) {
  return `
    <div class="cert-loading-box">
      <div class="cert-spinner"></div>
      <p>${message || '데이터를 불러오는 중입니다...'}</p>
    </div>
  `;
}

function certErrorHtml(message, retryFn) {
  const retryAttr = retryFn ? `onclick="${retryFn}"` : '';
  return `
    <div class="cert-error-box">
      <i class="fas fa-triangle-exclamation"></i>
      <p>${message || '데이터를 불러오는 중 오류가 발생했습니다.'}</p>
      ${retryFn ? `<button ${retryAttr} class="cert-retry-btn">다시 시도</button>` : ''}
    </div>
  `;
}
