/**
 * jobs.js
 * 구인구직 리스트 페이지(jobs/list.html) 전용 스크립트
 * Supabase의 jobs 테이블에서 데이터를 조회하여 테이블에 동적 렌더링합니다.
 */

document.addEventListener('DOMContentLoaded', async () => {
  const loadingEl = document.getElementById('loading-state');
  const tableEl = document.getElementById('jobs-table');
  const tbodyEl = document.getElementById('jobs-tbody');
  const emptyEl = document.getElementById('empty-state');

  // 1. 전역 Supabase Client 검증 (auth.js의 window.supabaseClient 존재 여부 확인)
  if (!window.supabaseClient) {
    console.error('Supabase Client가 초기화되지 않았습니다. auth.js가 정상적으로 로드되었는지 확인하세요.');
    loadingEl.innerHTML = '<p class="text-red-500 text-sm py-4">인증 및 DB 모듈을 불러오지 못했습니다.</p>';
    return;
  }

  try {
    // 2. Supabase에서 jobs 테이블 데이터 조회 (최신 등록순 created_at 내림차순 정렬)
    const { data: jobs, error } = await window.supabaseClient
      .from('jobs')
      .select('id, title, company, location, salary, created_at')
      .order('created_at', { ascending: false });

    // API 호출 에러 발생 시 Catch 블록으로 전달
    if (error) {
      throw error;
    }

    // 데이터 로드 완료: 로딩 UI 숨김
    loadingEl.classList.add('hidden');

    // 3. 데이터 유무에 따른 화면 분기
    if (!jobs || jobs.length === 0) {
      emptyEl.classList.remove('hidden');
      return;
    }

    // 4. 테이블 Row 동적 생성 및 tbody 내 HTML 삽입
    tbodyEl.innerHTML = jobs.map(job => `
      <tr class="hover:bg-blue-50/30 transition">
        <td class="py-4 px-6 font-medium text-gray-900">
          <a href="./detail.html?id=${job.id}" class="hover:text-blue-600 hover:underline block truncate max-w-md">
            ${escapeHtml(job.title)}
          </a>
        </td>
        <td class="py-4 px-6 text-gray-600 truncate">${escapeHtml(job.company)}</td>
        <td class="py-4 px-6 text-gray-500">${escapeHtml(job.location)}</td>
        <td class="py-4 px-6 font-semibold text-blue-600">${formatSalary(job.salary)}</td>
        <td class="py-4 px-6 text-right">
          <a href="./detail.html?id=${job.id}" 
             class="inline-block bg-white border border-gray-300 hover:bg-gray-50 text-gray-700 px-3 py-1.5 rounded-md text-xs font-medium transition shadow-sm">
            상세보기
          </a>
        </td>
      </tr>
    `).join('');

    // 실제 데이터 테이블 표시
    tableEl.classList.remove('hidden');

  } catch (err) {
    console.error('구인 공고 목록을 불러오는 중 오류 발생:', err.message);
    // 에러 발생 시 사용자에게 친절한 에러 메시지 출력
    loadingEl.innerHTML = `<p class="text-red-500 text-sm py-4">데이터를 불러오는 데 실패했습니다: ${escapeHtml(err.message)}</p>`;
    loadingEl.classList.remove('hidden');
  }
});

/**
 * [유틸리티 함수] XSS(크로스 사이트 스크립팅) 공격 방지를 위한 문자열 이스케이프 처리
 * @param {string} str - 변환할 원본 문자열
 * @returns {string} - 안전하게 변환된 HTML 문자열
 */
function escapeHtml(str) {
  if (!str) return '';
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');
}

/**
 * [유틸리티 함수] 급여 정보 포맷팅 (숫자형일 경우 콤마 및 '원' 단위 추가)
 * @param {number|string} salary - 급여 데이터
 * @returns {string} - 가공된 급여 문자열
 */
function formatSalary(salary) {
  if (salary === undefined || salary === null || salary === '') {
    return '회사 내규에 따름';
  }
  if (typeof salary === 'number' || !isNaN(Number(salary))) {
    return `${Number(salary).toLocaleString()}원`;
  }
  return escapeHtml(salary);
}