// region-data.js

// 1. 시/도 데이터
const regions = ['전국', '서울', '부산', '인천', '대구', '광주', '대전', '울산', '세종', '경기', '강원', '충북', '충남', '전북', '전남', '경북', '경남', '제주'];

// 2. 구/군 상세 지역 데이터
const subRegionData = {
    '전국': ['전국전체'],
    '서울': ['서울전체', '강남구', '강동구', '강북구', '강서구', '관악구', '광진구', '구로구', '금천구', '노원구', '도봉구', '동대문구', '동작구', '마포구', '서대문구', '서초구', '성동구', '성북구', '송파구', '양천구', '영등포구', '용산구', '은평구', '종로구', '중구', '중랑구'],
    '부산': ['부산전체', '강서구', '사하구', '서구', '수영구', '연제구', '영도구', '중구', '해운대구', '금정구', '기장군', '남구', '동구', '동래구', '부산진구', '북구', '사상구'],
    '인천': ['인천전체', '강화군', '영종구', '서해구', '계양구', '미추홀구', '남동구', '제물포구', '부평구', '검단구', '연수구', '옹진군'],
    '대구': ['대구 전체', '중구', '동구', '서구', '남구', '북구', '수성구', '달서구', '달성군', '군위군'],
    '광주': ['광주전체', '광산구', '남구', '동구', '북구', '서구'],
    '대전': ['대전전체', '동구', '서구', '중구', '대덕구', '유성구'],
    '울산': ['울산전체', '남구', '동구', '북구', '울주군', '중구'],
    '세종': ['세종전체', '세종시'],
    '경기': ['경기전체', '가평군', '군포시', '김포시', '고양시', '남양주시', '동두천시', '부천시', '성남시', '성남시분당구', '성남시수정구', '성남시중원구', '수원시', '수원시권선구', '수원시영통구', '수원시장안구', '수원시팔달구', '시흥시', '안산시', '안산시단원구', '안산시상록구', '안성시', '안양시', '안양시동안구', '안양시만안구', '양주시', '양평군', '여주시', '연천군', '오산시', '용인시', '용인시기흥구', '용인시수지구', '용인시처인구', '의왕시', '의정부시', '이천시', '파주시', '평택시', '포천시', '하남시', '화성시', '과천시', '광명시', '광주시', '구리시'],
    '강원': ['강원전체', '강릉시', '인제군', '정선군', '철원군', '춘천시', '태백시', '평창군', '홍천군', '화천군', '횡성군', '고성군', '동해시', '삼척시', '속초시', '양구군', '양양군', '영월군', '원주시'],
    '충북': ['충북전체', '괴산군', '청주시', '청주시상당구', '청주시서원구', '청주시청원구', '청주시흥덕구', '충주시', '단양군', '보은군', '영동군', '옥천군', '음성군', '제천시', '증평군', '진천군'],
    '충남': ['충남전체', '천안시', '천안시 동남구', '천안시 서북구', '공주시', '보령시', '아산시', '서산시', '논산시', '당진시', '계룡시', '금산군', '부여군', '서천군', '청양군', '홍성군', '예산군', '태안군'],
    '전북': ['전북전체', '고창군', '임실군', '장수군', '전주시', '전주시덕진구', '전주시완산구', '정읍시', '진안군', '군산시', '김제시', '남원시', '무주군', '부안군', '순창군', '완주군', '익산시'],
    '전남': ['전남전체', '강진군', '고흥군', '곡성군', '광양시', '구례군', '보성군', '순천시', '신안군', '여수시', '영광군', '영암군', '완도군', '장성군', '장흥군', '진도군', '함평군', '화순군', '해남군', '나주시', '담양군', '목포시', '무안군'],
    '경북': ['경북전체', '성주군', '안동시', '영덕군', '영양군', '영주시', '영천시', '예천군', '울릉군', '울진군', '의성군', '경주시', '청도군', '청송군', '칠곡군', '포항시', '포항시남구', '포항시북구', '고령군', '구미시', '군위군', '김천시', '문경시', '봉화군', '상주시'],
    '경남': ['경남전체', '거제시', '의령군', '진주시', '창녕군', '창원시', '창원시마산합포구', '창원시마산회원구', '창원시성산구', '창원시의창구', '창원시진해구', '통영시', '거창군', '하동군', '함안군', '함양군', '합천군', '고성군', '김해시', '남해군', '밀양시', '사천시', '산청군', '양산시'],
    '제주': ['제주전체', '서귀포시', '제주시']
};

// 3. 지역 선택 팝업(모달) 생성 및 제어 함수
function initRegionPopup(triggerBtnId, displayTargetId, onSelectCallback) {
    const triggerBtn = document.getElementById(triggerBtnId);
    const displayTarget = document.getElementById(displayTargetId);

    if (!triggerBtn) return;

    // 모달 HTML 구조 동적 생성
    const modalHtml = `
        <div id="region-modal-wrapper" class="fixed inset-0 z-[9999] flex items-center justify-center bg-black/50 backdrop-blur-sm" style="display: none;">
            <div class="bg-white rounded-xl shadow-2xl w-[90%] max-w-[650px] overflow-hidden flex flex-col max-h-[85vh]">
                <!-- 팝업 헤더 -->
                <div class="flex justify-between items-center px-6 py-4 border-b border-gray-200 bg-gray-50">
                    <h3 class="text-lg font-bold text-gray-800">📍 지역 선택</h3>
                    <button type="button" id="region-modal-close" class="text-gray-400 hover:text-gray-700 text-2xl font-bold leading-none">&times;</button>
                </div>
                <!-- 팝업 바디 -->
                <div class="p-6 overflow-y-auto flex-1 space-y-6">
                    <!-- 시/도 선택 영역 -->
                    <div>
                        <label class="block text-xs font-bold text-gray-500 mb-2 uppercase">시/도 선택</label>
                        <div id="modal-sido-container" class="grid grid-cols-4 sm:grid-cols-6 gap-2"></div>
                    </div>
                    <!-- 구/군 선택 영역 -->
                    <div>
                        <label class="block text-xs font-bold text-gray-500 mb-2 uppercase">구/군 선택</label>
                        <div id="modal-sigungu-container" class="flex flex-wrap gap-2"></div>
                    </div>
                </div>
                <!-- 팝업 푸터 -->
                <div class="px-6 py-3 bg-gray-50 border-t border-gray-200 text-right">
                    <button type="button" id="region-modal-confirm" class="bg-[#274bce] text-white px-5 py-2 rounded-lg font-bold text-sm hover:bg-[#1d3893] transition-colors">선택 완료</button>
                </div>
            </div>
        </div>
    `;

    // 바디에 모달이 없다면 삽입
    if (!document.getElementById('region-modal-wrapper')) {
        document.body.insertAdjacentHTML('end', modalHtml);
    }

    const modal = document.getElementById('region-modal-wrapper');
    const closeBtn = document.getElementById('region-modal-close');
    const confirmBtn = document.getElementById('region-modal-confirm');
    const sidoContainer = document.getElementById('modal-sido-container');
    const sigunguContainer = document.getElementById('modal-sigungu-container');

    let selectedSido = '전국';
    let selectedSigungu = '전국전체';

    // 팝업 열기 버튼 이벤트
    triggerBtn.onclick = () => {
        modal.style.display = 'flex';
        renderSidoButtons();
    };

    // 팝업 닫기 함수
    const closeModal = () => {
        modal.style.display = 'none';
    };

    closeBtn.onclick = closeModal;
    modal.onclick = (e) => {
        if (e.target === modal) closeModal();
    };

    // 시/도 버튼 렌더링
    function renderSidoButtons() {
        sidoContainer.innerHTML = '';
        regions.forEach(sido => {
            const btn = document.createElement('button');
            btn.type = 'button';
            btn.innerText = sido;
            const isSelected = sido === selectedSido;
            btn.className = `px-3 py-2 text-xs sm:text-sm font-semibold rounded-lg border transition-all ${
                isSelected 
                    ? 'bg-[#274bce] text-white border-[#274bce] shadow-sm' 
                    : 'bg-white text-gray-700 border-gray-200 hover:bg-gray-100'
            }`;

            btn.onclick = () => {
                selectedSido = sido;
                // 해당 시/도의 첫 번째 구/군을 기본값으로 설정
                const subList = subRegionData[sido] || ['전체'];
                selectedSigungu = subList[0];
                renderSidoButtons();
                renderSigunguButtons(sido);
            };

            sidoContainer.appendChild(btn);
        });
        renderSigunguButtons(selectedSido);
    }

    // 구/군 버튼 렌더링
    function renderSigunguButtons(sido) {
        sigunguContainer.innerHTML = '';
        const subList = subRegionData[sido] || [];

        subList.forEach(sigungu => {
            const btn = document.createElement('button');
            btn.type = 'button';
            btn.innerText = sigungu;
            const isSelected = sigungu === selectedSigungu;
            btn.className = `px-3 py-1.5 text-xs sm:text-sm rounded-lg border transition-all ${
                isSelected 
                    ? 'bg-gray-800 text-white border-gray-800' 
                    : 'bg-gray-50 text-gray-600 border-gray-200 hover:bg-gray-200'
            }`;

            btn.onclick = () => {
                selectedSigungu = sigungu;
                renderSigunguButtons(sido);
            };

            sigunguContainer.appendChild(btn);
        });
    }

    // 선택 완료 버튼 이벤트
    confirmBtn.onclick = () => {
        const fullText = selectedSigungu.includes(selectedSido) || selectedSigungu === '전국전체' 
            ? selectedSigungu 
            : `${selectedSido} ${selectedSigungu}`;

        // 화면의 텍스트 타겟이 있다면 업데이트
        if (displayTarget) {
            if (displayTarget.tagName === 'INPUT') {
                displayTarget.value = fullText;
            } else {
                displayTarget.innerText = fullText;
            }
        }

        // 콜백 함수 실행 (필요한 데이터 전달)
        if (typeof onSelectCallback === 'function') {
            onSelectCallback(selectedSido, selectedSigungu, fullText);
        }

        closeModal();
    };
}