// assets/js/auth.js

const AuthManager = {
    // 1. 초기화 함수 (DOM이 로드되면 실행됨)
    init: function() {
        this.renderModals();
        this.bindGlobalFunctions();
        this.bindEvents();
    },

    // 2. 인증 관련 모달 4종 HTML 렌더링
    renderModals: function() {
        // 절대 경로 변수 설정 (어느 폴더에서든 이미지가 깨지지 않도록 ../assets/img/... 경로 사용)
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
                    <form class="mt-4" id="login-form" novalidate onsubmit="handleFormSubmit(event, 'login', '로그인이 완료되었습니다.');">
                        <input class="modal-input" type="text" id="login-id" placeholder="아이디 또는 이메일 입력" autocomplete="username" required />
                        <input class="modal-input" type="password" id="login-pw" placeholder="비밀번호" autocomplete="current-password" required />
                        <div class="modal-row">
                            <label class="modal-remember"><input type="checkbox" name="login-keep" /> 로그인 상태 유지</label>
                            <div>
                                <a class="modal-forgot" onclick="switchCustomModal('login', 'find-id')">아이디 찾기</a>
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
                    <form class="mt-4" id="signup-form" onsubmit="handleFormSubmit(event, 'signup', '회원가입 신청이 완료되었습니다.');">
                        <input class="modal-input" type="text" id="signup-name" placeholder="성함" required />
                        <input class="modal-input" type="text" id="signup-id" placeholder="아이디 희망문자" required />
                        <input class="modal-input" type="email" id="signup-email" placeholder="이메일 주소" required />
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
                        <p class="modal-title">아이디 찾기</p>
                        <p class="text-xs text-gray-500 text-center mt-1">가입 시 등록하신 이메일 정보를 입력해 주세요.</p>
                    </div>
                    <form class="mt-4" id="find-id-form" onsubmit="handleFormSubmit(event, 'find-id', '입력하신 이메일로 아이디 정보가 발송되었습니다.');">
                        <input class="modal-input" type="text" id="find-id-name" placeholder="이름" required />
                        <input class="modal-input" type="email" id="find-id-email" placeholder="가입 이메일 주소" required />
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
                        <p class="text-xs text-gray-500 text-center mt-1">아이디와 이메일을 입력하시면 임시 비밀번호를 발송해 드립니다.</p>
                    </div>
                    <form class="mt-4" id="find-pw-form" onsubmit="handleFormSubmit(event, 'find-pw', '입력하신 이메일로 임시 비밀번호가 발송되었습니다.');">
                        <input class="modal-input" type="text" id="find-pw-id" placeholder="아이디" required />
                        <input class="modal-input" type="email" id="find-pw-email" placeholder="가입 이메일 주소" required />
                        <button type="submit" id="find-pw-btn" class="btn-primary-full mt-2">임시 비밀번호 발송</button>
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

    // 3. 기존 HTML에서 사용하던 인라인 함수들(onclick 등)을 전역(window) 객체에 연결
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

        window.handleFormSubmit = function(event, modalId, message) {
            event.preventDefault(); 
            alert(message);
            window.closeCustomModal(modalId);
        };

        window.socialLogin = async function(provider) {
            // 전역 변수로 선언된 supabaseClient를 사용 (HTML 페이지 내에서 Supabase 초기화 필요)
            if (!window.supabaseClient) {
                alert("인증 시스템 연결을 확인 중입니다. 잠시 후 다시 시도해주세요.");
                return;
            }

            // 기본 옵션 설정
            const authOptions = {
                redirectTo: window.location.origin 
            };

            // 카카오 로그인일 경우, 이메일 에러(KOE205) 방지를 위해 닉네임만 요구하도록 강제 설정
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
        // 모달 배경(검은 여백) 클릭 시 닫기
        document.addEventListener('click', e => {
            if (e.target.classList.contains('modal-backdrop')) {
                e.target.classList.remove('is-open');
                document.body.style.overflow = '';
                document.body.style.paddingRight = ''; 
            }
        });
    }
};

// 브라우저 로딩 상태를 체크하여 무조건 AuthManager가 실행되도록 보장
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => {
        AuthManager.init();
    });
} else {
    AuthManager.init();
}