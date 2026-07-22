// assets/js/auth.js

// ==========================================
// 1. Supabase 초기화 설정
// (주의: HTML 파일의 <head> 태그 안에 반드시 아래 스크립트가 있어야 합니다.)
// <script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>
// ==========================================
const SUPABASE_URL = 'https://ehrahnnowwjkgycvlbzk.supabase.co'; 
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVocmFobm5vd3dqa2d5Y3ZsYnprIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODIwMzQ1NjQsImV4cCI6MjA5NzYxMDU2NH0.A0MfXNI4W7sPUM4UwSn7_kY5n2gEhp3N8ubH7uBZZwk';

// 전역 객체로 생성하여 다른 곳(소셜 로그인 등)에서도 쓸 수 있도록 합니다.
if (typeof supabase !== 'undefined') {
    window.supabaseClient = supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
} else {
    console.error("Supabase 라이브러리가 로드되지 않았습니다. HTML 파일에 CDN 스크립트를 추가해주세요.");
}

const AuthManager = {
    // 1. 초기화 함수 (DOM이 로드되면 실행됨)
    init: function() {
        this.renderModals();
        this.bindGlobalFunctions();
        this.bindEvents();
    },

    // 2. 인증 관련 모달 4종 HTML 렌더링
    renderModals: function() {
        // 절대 경로 변수 설정
        const logoPath = "../assets/img/대한집합건물관리협회-removebg-preview.png";
        const fallbackPath = "../assets/img/방패로고.jpg";

        const modalsHtml = `
            <!-- 로그인 모달 -->
            <div class="modal-backdrop" id="modal-login" role="dialog" aria-modal="true" aria-label="로그인">
                <div class="modal-dialog">
                    <button type="button" class="modal-close" onclick="closeCustomModal('login')" aria-label="닫기">
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
                    </button>
                    <div class="modal-brand">
                        <img src="${logoPath}" style="height:68px; width:auto; max-width:85%; margin:0 auto 14px; object-fit:contain;" alt="KCBMA" class="modal-brand-img" onerror="this.src='${fallbackPath}'" />
                        <p class="modal-title">로그인</p>
                        <p class="text-xs text-gray-500 text-center mt-1">대한집합건물관리협회에 오신 것을 환영합니다</p>
                    </div>
                    <!-- 폼 제출 시 실제 로그인 함수(handleEmailLogin) 호출 -->
                    <form class="mt-4" id="login-form" novalidate onsubmit="handleEmailLogin(event)">
                        <!-- 사용자의 혼동을 줄이기 위해 '가입하신 이메일'로 안내 문구 수정 -->
                        <input class="modal-input" type="email" id="login-id" placeholder="가입하신 이메일 입력" autocomplete="username" required />
                        <input class="modal-input" type="password" id="login-pw" placeholder="비밀번호" autocomplete="current-password" required />
                        <div class="modal-row">
                            <label class="modal-remember"><input type="checkbox" name="login-keep" /> 로그인 상태 유지</label>
                            <div>
                                <a class="modal-forgot" onclick="switchCustomModal('login', 'find-id')">아이디(이메일) 찾기</a>
                                <span class="mx-1 text-gray-400">|</span>
                                <a class="modal-forgot" onclick="switchCustomModal('login', 'find-pw')">비밀번호 찾기</a>
                            </div>
                        </div>
                        <button type="submit" id="login-btn" class="btn-primary-full mt-2">이메일 로그인</button>
                    </form>
                    
                    <!-- 간편 로그인 구분선 -->
                    <div class="mt-6 mb-5 relative flex items-center justify-center">
                        <div class="border-t border-gray-300 w-full absolute"></div>
                        <span class="bg-white px-3 text-sm text-gray-500 font-bold relative z-10">간편 로그인</span>
                    </div>
                    
                    <!-- 간편 로그인 버튼 -->
                    <div class="grid grid-cols-3 gap-2">
                        <button onclick="socialLogin('kakao')" type="button" class="flex justify-center items-center h-12 rounded-lg bg-[#FEE500] font-bold text-[14px] text-[#000000] shadow-sm hover:bg-[#F4DC00] transition">
                            <span class="mr-1.5 text-lg">💬</span> 카카오
                        </button>
                        <button onclick="socialLogin('naver')" type="button" class="flex justify-center items-center h-12 rounded-lg bg-[#03C75A] font-bold text-[14px] text-white shadow-sm hover:bg-[#02b351] transition">
                            <span class="mr-1.5 font-black">N</span> 네이버
                        </button>
                        <button onclick="socialLogin('google')" type="button" class="flex justify-center items-center h-12 rounded-lg bg-gray-100 font-bold text-[14px] text-gray-800 shadow-sm hover:bg-gray-200 transition">
                            <svg class="w-4 h-4 mr-1.5" viewBox="0 0 24 24"><path fill="#EA4335" d="M24 12.27c0-.81-.07-1.6-.2-2.36H12v4.46h6.71c-.29 1.44-1.07 2.66-2.22 3.48v2.9h3.6c2.1-1.93 3.32-4.78 3.32-8.48z"/><path fill="#34A853" d="M12 24c3.37 0 6.2-1.12 8.27-3.03l-3.6-2.9c-1.12.75-2.55 1.2-4.67 1.2-3.59 0-6.64-2.42-7.72-5.69H.52v3C2.6 20.73 6.96 24 12 24z"/><path fill="#FBBC05" d="M4.28 13.58c-.28-.84-.43-1.74-.43-2.67s.15-1.83.43-2.67v-3H.52C-.17 6.83-.5 8.35-.5 10c0 1.65.33 3.17.93 4.54l3.85-2.96z"/><path fill="#EA4335" d="M12 4.9c1.83 0 3.48.63 4.77 1.87l3.58-3.58C18.2 1.13 15.37 0 12 0 6.96 0 2.6 3.27.52 7.82l3.76 3.01C5.36 7.32 8.41 4.9 12 4.9z"/></svg> 구글
                        </button>
                    </div>
                    <p class="modal-switch mt-5">아직 회원이 아니신가요? <a onclick="switchCustomModal('login', 'signup')">회원가입</a></p>
                </div>
            </div>

            <!-- 회원가입 모달 -->
            <div class="modal-backdrop" id="modal-signup" role="dialog" aria-modal="true">
                <div class="modal-dialog overflow-y-auto max-h-[90vh]">
                    <button class="modal-close" onclick="closeCustomModal('signup')">✕</button>
                    <div class="modal-brand">
                        <img src="${logoPath}" style="height:68px; width:auto; max-width:85%; margin:0 auto 14px; object-fit:contain;" alt="KCBMA" class="modal-brand-img" onerror="this.src='${fallbackPath}'" />
                        <p class="modal-title">회원가입</p>
                        <p class="text-xs text-gray-500 text-center mt-1">통합 회원이 되어 실무 권익 인프라를 누리세요</p>
                    </div>
                    <!-- 폼 제출 시 실제 회원가입 함수(handleEmailSignup) 호출 -->
                    <form class="mt-4" id="signup-form" onsubmit="handleEmailSignup(event)">
                        <input class="modal-input" type="text" id="signup-name" placeholder="성함" required />
                        <input class="modal-input" type="text" id="signup-id" placeholder="아이디 희망문자" required />
                        <input class="modal-input" type="email" id="signup-email" placeholder="이메일 주소 (로그인 시 사용됩니다)" required />
                        <input class="modal-input" type="password" id="signup-pw" placeholder="비밀번호 서식 (8자 이상)" required />
                        <input class="modal-input" type="password" id="signup-pw2" placeholder="비밀번호 확인" required />
                        <div class="modal-checkbox-group" style="font-size:0.85rem; margin-top:5px; margin-bottom:15px; line-height: 1.8; background:#f9fafb; padding:15px; border-radius:6px;">
                            <label class="modal-check-label flex items-center gap-2 cursor-pointer mb-2">
                                <input type="checkbox" name="signup-tc1" class="w-4 h-4" required /> 
                                <span><span style="color:#EF4444; font-weight:bold;">[필수]</span> <a>이용약관</a>에 동의합니다</span>
                            </label>
                            <label class="modal-check-label flex items-center gap-2 cursor-pointer">
                                <input type="checkbox" name="signup-tc2" class="w-4 h-4" required /> 
                                <span><span style="color:#EF4444; font-weight:bold;">[필수]</span> <a>개인정보 처리방침</a>에 동의합니다</span>
                            </label>
                        </div>
                        <button type="submit" id="signup-btn" class="btn-primary-full mt-2">가입 신청 완료</button>
                    </form>
                    <p class="modal-switch">이미 계정이 있으신가요? <a onclick="switchCustomModal('signup', 'login')">로그인</a></p>
                </div>
            </div>

            <!-- 아이디 찾기 모달 -->
            <div class="modal-backdrop" id="modal-find-id" role="dialog" aria-modal="true">
                <div class="modal-dialog">
                    <button class="modal-close" onclick="closeCustomModal('find-id')">✕</button>
                    <div class="modal-brand">
                        <img src="${logoPath}" style="height:68px; width:auto; max-width:85%; margin:0 auto 14px; object-fit:contain;" alt="KCBMA" class="modal-brand-img" onerror="this.src='${fallbackPath}'" />
                        <p class="modal-title">아이디(이메일) 찾기</p>
                        <p class="text-xs text-gray-500 text-center mt-1">가입 시 등록하신 성함을 입력해 주세요.</p>
                    </div>
                    <!-- 폼 제출 시 handleFindId 호출 -->
                    <form class="mt-4" id="find-id-form" onsubmit="handleFindId(event)">
                        <input class="modal-input" type="text" id="find-id-name" placeholder="이름" required />
                        <button type="submit" id="find-id-btn" class="btn-primary-full mt-2">아이디 찾기</button>
                    </form>
                    <p class="modal-switch"><a onclick="switchCustomModal('find-id', 'login')">로그인으로 돌아가기</a></p>
                </div>
            </div>

            <!-- 비밀번호 찾기 모달 -->
            <div class="modal-backdrop" id="modal-find-pw" role="dialog" aria-modal="true">
                <div class="modal-dialog">
                    <button class="modal-close" onclick="closeCustomModal('find-pw')">✕</button>
                    <div class="modal-brand">
                        <img src="${logoPath}" style="height:68px; width:auto; max-width:85%; margin:0 auto 14px; object-fit:contain;" alt="KCBMA" class="modal-brand-img" onerror="this.src='${fallbackPath}'" />
                        <p class="modal-title">비밀번호 찾기</p>
                        <p class="text-xs text-gray-500 text-center mt-1">가입하신 이메일을 입력하시면 비밀번호 재설정 링크를 발송해 드립니다.</p>
                    </div>
                    <!-- 폼 제출 시 handleFindPassword 호출 -->
                    <form class="mt-4" id="find-pw-form" onsubmit="handleFindPassword(event)">
                        <input class="modal-input" type="email" id="find-pw-email" placeholder="가입 이메일 주소" required />
                        <button type="submit" id="find-pw-btn" class="btn-primary-full mt-2">재설정 링크 발송</button>
                    </form>
                    <p class="modal-switch"><a onclick="switchCustomModal('find-pw', 'login')">로그인으로 돌아가기</a></p>
                </div>
            </div>
        `;

        // body 끝부분에 모달들을 담을 컨테이너 생성 후 삽입
        const container = document.createElement('div');
        container.id = 'auth-modals-container';
        container.innerHTML = modalsHtml;
        document.body.appendChild(container);
    },

    // 3. 기존 HTML에서 사용하던 인라인 함수들 연결 및 Supabase 연동 함수
    bindGlobalFunctions: function() {
        window.getScrollbarWidth = function() {
            return window.innerWidth - document.documentElement.clientWidth;
        };

        window.openCustomModal = function(id) {
            document.querySelectorAll('.modal-backdrop').forEach(m => m.classList.remove('is-open'));
            const modal = document.getElementById('modal-' + id);
            if (modal) {
                modal.classList.add('is-open');
                if (document.body.scrollHeight > window.innerHeight) {
                    document.body.style.paddingRight = window.getScrollbarWidth() + 'px';
                }
                document.body.style.overflow = 'hidden';
            }
        };

        window.closeCustomModal = function(id) {
            const modal = document.getElementById('modal-' + id);
            if (modal) {
                modal.classList.remove('is-open');
                document.body.style.overflow = '';
                document.body.style.paddingRight = ''; 
            }
        };

        window.switchCustomModal = function(closeId, openId) {
            window.closeCustomModal(closeId);
            setTimeout(() => window.openCustomModal(openId), 100);
        };

        // ==========================================
        // 🔥 Supabase: 이메일 회원가입 로직
        // ==========================================
        window.handleEmailSignup = async function(event) {
            event.preventDefault();
            if (!window.supabaseClient) return alert('시스템 오류: 통신 클라이언트가 연결되지 않았습니다.');

            const name = document.getElementById('signup-name').value;
            const usernameId = document.getElementById('signup-id').value;
            const email = document.getElementById('signup-email').value;
            const pw = document.getElementById('signup-pw').value;
            const pw2 = document.getElementById('signup-pw2').value;

            if (pw !== pw2) return alert('비밀번호가 서로 일치하지 않습니다.');
            if (pw.length < 8) return alert('비밀번호는 8자 이상이어야 합니다.');

            const { data, error } = await window.supabaseClient.auth.signUp({
                email: email,
                password: pw,
                options: {
                    data: {
                        full_name: name,
                        preferred_username: usernameId
                    }
                }
            });

            if (error) {
                console.error("회원가입 에러:", error);
                alert(`가입 실패: ${error.message}\n(이미 가입된 이메일이거나 형식이 잘못되었을 수 있습니다)`);
            } else {
                alert('회원가입이 성공적으로 접수되었습니다!\n(인증 이메일이 발송되었을 수 있습니다. 이메일함을 확인해주세요.)');
                window.switchCustomModal('signup', 'login');
            }
        };

        // ==========================================
        // 🔥 Supabase: 이메일 로그인 로직
        // ==========================================
        window.handleEmailLogin = async function(event) {
            event.preventDefault();
            if (!window.supabaseClient) return alert('시스템 오류: 통신 클라이언트가 연결되지 않았습니다.');

            const email = document.getElementById('login-id').value;
            const pw = document.getElementById('login-pw').value;

            const { data, error } = await window.supabaseClient.auth.signInWithPassword({
                email: email,
                password: pw
            });

            if (error) {
                console.error("로그인 에러:", error.message);
                alert('로그인 실패: 등록되지 않은 이메일이거나 비밀번호가 일치하지 않습니다.');
            } else {
                alert('로그인되었습니다. 환영합니다!');
                window.closeCustomModal('login');
                window.location.reload(); 
            }
        };

        // ==========================================
        // 🔥 Supabase: 아이디 찾기 로직
        // ==========================================
        window.handleFindId = async function(event) {
            event.preventDefault();
            // Supabase는 이메일을 고유 ID로 사용합니다.
            // 이름만으로 이메일을 찾으려면 별도의 데이터베이스 조회가 필요합니다.
            alert('보안 정책상 가입하신 이메일 전체를 직접 알려드리지 않습니다.\n관리자에게 문의하시거나 가입 시 사용한 이메일함을 확인해 주세요.');
            window.closeCustomModal('find-id');
        };

        // ==========================================
        // 🔥 Supabase: 비밀번호 찾기 (재설정 이메일 발송)
        // ==========================================
        window.handleFindPassword = async function(event) {
            event.preventDefault();
            if (!window.supabaseClient) return alert('시스템 오류: 통신 클라이언트가 연결되지 않았습니다.');

            const email = document.getElementById('find-pw-email').value;

            // Supabase 비밀번호 재설정 이메일 발송 요청
            const { data, error } = await window.supabaseClient.auth.resetPasswordForEmail(email, {
                // 발송된 이메일의 링크를 클릭했을 때 돌아올 주소입니다.
                // 향후 비밀번호 재설정 전용 페이지(예: /update-password.html)를 만들면 이곳을 수정하세요.
                redirectTo: window.location.origin, 
            });

            if (error) {
                console.error("비밀번호 찾기 에러:", error.message);
                alert('오류가 발생했습니다. 가입하신 이메일 주소가 맞는지 확인해 주세요.');
            } else {
                alert('입력하신 이메일로 비밀번호 재설정 링크가 발송되었습니다.\n이메일함을 확인해 주세요.');
                window.closeCustomModal('find-pw');
            }
        };

        // ==========================================
        // 🔥 Supabase: 소셜 로그인 로직 (기존 코드 유지)
        // ==========================================
        window.socialLogin = async function(provider) {
            if (!window.supabaseClient) {
                alert("인증 시스템 연결을 확인 중입니다. 잠시 후 다시 시도해주세요.");
                return;
            }

            const authOptions = {
                redirectTo: window.location.origin 
            };

            if (provider === 'kakao') {
                authOptions.scopes = 'profile_nickname';
            }

            const { data, error } = await window.supabaseClient.auth.signInWithOAuth({
                provider: provider,
                options: authOptions
            });

            if (error) {
                console.error(`${provider} 간편 로그인 에러:`, error.message);
                alert('간편 로그인 중 오류가 발생했습니다.');
            }
        };
    },

    // 4. 이벤트 리스너 부착
    bindEvents: function() {
        document.addEventListener('click', e => {
            if (e.target.classList.contains('modal-backdrop')) {
                e.target.classList.remove('is-open');
                document.body.style.overflow = '';
                document.body.style.paddingRight = ''; 
            }
        });
    }
};

if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => {
        AuthManager.init();
    });
} else {
    AuthManager.init();
}