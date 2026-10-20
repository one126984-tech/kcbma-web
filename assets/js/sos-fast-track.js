/**
 * 파일명: sos-fast-track.js
 */
const SOSLogic = (function() {
    const supabaseClient = window.sb;
    
    // 상태 관리 변수 (어떤 버튼으로 진입했는지 기억)
    let isPracticeMode = false;
    let isFastTrackMode = false; // 예치금 회원 빠른길 모드
    
    let selectedType = 'phone';
    let currentBasePrice = 4;
    const DISPATCH_FEE = 50000;

    const STORE_ID = 'store-f9176089e3...'; // 본인 상점 아이디 유지
    const CHANNEL_KEY = 'cha-12345678...';  // 본인 채널 키 유지
    
    if (typeof IMP !== 'undefined') IMP.init(STORE_ID); 

    function updateTimePrice() {
        const hour = new Date().getHours();
        currentBasePrice = (hour >= 9 && hour < 18) ? 2 : (hour >= 22 || hour < 6) ? 4 : 3;
        document.querySelectorAll('.dynamic-time-price').forEach(el => el.innerText = currentBasePrice);
    }

    // 화면 전환 함수
    function showStep(stepId) {
        ['step-intro', 'step-unified-form'].forEach(id => {
            const el = document.getElementById(id);
            if(el) { el.classList.add('hidden'); el.classList.remove('flex', 'block'); }
        });
        const target = document.getElementById(stepId);
        if(target) { target.classList.remove('hidden'); target.classList.add('block'); }
    }

    // 폼 초기화 함수 (비회원/연습용 진입 시)
    function clearForm() {
        document.getElementById('location-input').value = '';
        document.querySelectorAll('.qcat-btn').forEach(btn => btn.classList.remove('selected'));
        document.getElementById('agree-1').checked = false;
        checkSubmitReady();
    }

    function bindEvents() {
        document.querySelectorAll('.qcat-btn').forEach(btn => {
            btn.addEventListener('click', function () { 
                document.querySelectorAll('.qcat-btn').forEach(b => b.classList.remove('selected'));
                this.classList.add('selected'); 
                checkSubmitReady();
            });
        });

        document.querySelectorAll('input[name="svc_type"]').forEach(r => {
            r.addEventListener('change', function () { 
                selectedType = this.value; 
                document.querySelectorAll('.svc-label').forEach(lbl => lbl.classList.remove('border-blue-500', 'bg-blue-50'));
                const p = this.closest('label');
                if(p) p.classList.add('border-blue-500', 'bg-blue-50');
            });
        });

        document.getElementById('agree-1')?.addEventListener('change', checkSubmitReady);
    }

    function checkSubmitReady() {
        const agree = document.getElementById('agree-1')?.checked;
        const submitBtn = document.getElementById('sos-submit-btn');
        if(submitBtn) {
            submitBtn.disabled = !agree;
            submitBtn.className = agree 
                ? 'w-full bg-[#2563eb] text-white font-black text-[16px] py-4 rounded-xl shadow-sm transition mt-4'
                : 'w-full bg-gray-300 text-gray-500 font-black text-[16px] py-4 rounded-xl shadow-sm transition mt-4 cursor-not-allowed';
        }
    }

    function getRequiredAmount() {
        return (currentBasePrice * 10000) + (selectedType === 'dispatch' ? DISPATCH_FEE : 0);
    }

    // ==========================================
    // [1] 빠른 길로 가기 (예치금 회원 전용) 버튼 클릭 시
    // ==========================================
    async function handleFastTrackClick() {
        const { data: { user }, error: authError } = await supabaseClient.auth.getUser();
        if (authError || !user) {
            alert("예치금 회원 전용 기능입니다.\n아래의 [실제 긴급 호출하기] 버튼을 이용해 주십시오.");
            return;
        }

        const { data: profile } = await supabaseClient.from('user_profiles').select('is_premium, default_address, phone').eq('id', user.id).single();

        if (profile && profile.is_premium) {
            isFastTrackMode = true;
            isPracticeMode = false;
            
            // 공통 폼 화면 띄우기
            showStep('step-unified-form');
            
            // 정보 자동 입력 (DB 기반)
            document.getElementById('location-input').value = profile.default_address || '기본 등록 주소';
            document.querySelector('.qcat-btn[data-cat="누수"]')?.classList.add('selected'); // 누수 기본 선택
            document.getElementById('agree-1').checked = true; // 약관 자동 동의
            checkSubmitReady();
            
            document.getElementById('form-title').innerHTML = '🚀 빠른 긴급 접수 <span class="text-sm font-bold text-blue-600 bg-blue-100 px-2 py-1 rounded ml-2">정보 자동입력됨</span>';
        } else {
            alert("예치금 회원 전용 기능입니다.\n아래의 [실제 긴급 호출하기] 버튼을 이용해 주십시오.");
        }
    }

    // ==========================================
    // [2] 실제 긴급 호출하기 (기존 방식 그대로)
    // ==========================================
    function startClassic() {
        isFastTrackMode = false;
        isPracticeMode = false;
        clearForm();
        showStep('step-unified-form');
        document.getElementById('form-title').innerText = '🚨 긴급 상황 입력';
    }

    // ==========================================
    // [3] 똑같이 연습해보기 (기존 방식 그대로)
    // ==========================================
    function startPractice() {
        isFastTrackMode = false;
        isPracticeMode = true;
        clearForm();
        showStep('step-unified-form');
        document.getElementById('form-title').innerText = '🛠 긴급 호출 연습모드';
    }

    // ==========================================
    // 공통 폼 하단의 "전문가 찾기" 제출 버튼 클릭 시 분기 처리
    // ==========================================
    async function handleEmergencySubmit() {
        const cost = getRequiredAmount();

        // 1. 연습 모드인 경우 -> 그냥 통과
        if (isPracticeMode) {
            window.location.href = 'sos-experts.html?practice=1';
            return;
        }

        // 2. 패스트트랙 모드인 경우 -> 안내 후 바로 매칭 화면으로
        if (isFastTrackMode) {
            const proceed = confirm(`해당 금액(${cost.toLocaleString()}원)이 연락처 확인 시 예치금에서 차감됩니다.\n바로 전문가 대기창으로 넘어가시겠습니까?`);
            if (proceed) {
                window.location.href = `sos-experts.html?estimated_cost=${cost}`;
            }
        } 
        // 3. 일반 결제 모드인 경우 -> 기존처럼 결제창(모달) 띄우기
        else {
            document.getElementById('modal-total').innerText = cost.toLocaleString() + '원';
            document.getElementById('payment-modal').classList.remove('hidden'); 
            document.getElementById('payment-modal').classList.add('flex');
        }
    }

    updateTimePrice();
    setInterval(updateTimePrice, 60000);
    
    document.addEventListener('DOMContentLoaded', bindEvents);

    return {
        handleFastTrackClick: handleFastTrackClick,
        startClassic: startClassic,
        startPractice: startPractice,
        handleEmergencySubmit: handleEmergencySubmit,
        closePaymentModal: () => document.getElementById('payment-modal').classList.replace('flex', 'hidden'),
        processStandardPayment: async () => { alert("일반 결제 연동 생략"); }
    };
})();