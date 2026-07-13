// 1. 공통 푸터 HTML을 변수에 저장 (백틱 ` 사용)
const footerHtml = `
  <footer style="background: #040f24; color: #fff; padding: 60px 20px; margin-top: 50px;">
    <div style="max-width: 1200px; margin: 0 auto; display: flex; justify-content: space-between; align-items: flex-start; flex-wrap: wrap; gap: 40px;">
      <div style="flex: 1; min-width: 250px;">
        <img src="assets/img/대한집합건물관리협회-removebg-preview.png" style="height: 60px; filter: brightness(0) invert(1); margin-bottom: 20px;" alt="대한집합건물관리협회 로고" onerror="this.style.display='none'">
        <div style="font-size: 0.9rem; line-height: 1.8; color: #fff;">
          <p style="margin: 5px 0;">주소: 경기도 김포시 김포대로 699</p>
          <p style="margin: 5px 0;">전화: 031-984-6199 · 팩스: 031-985-6199</p>
          <p style="margin: 5px 0;">이메일: idea8888@naver.com</p>
        </div>
      </div>
      <div style="flex: 0.5; min-width: 150px;">
        <h4 style="margin: 0 0 20px 0; font-weight:bold; color: #fff;">사이트맵</h4>
        <div style="font-size: 0.9rem; line-height: 2.2;">
          <a href="info/index.html" style="color: #fff; text-decoration: none;">정보교류 종합 포털</a><br>
          <a href="info/forum.html" style="color: #fff; text-decoration: none;">정책 토론 광장</a><br>
          <a href="jobs/list.html" style="color: #fff; text-decoration: none;">구인구직 센터</a>
        </div>
      </div>
      <div style="flex: 0.5; min-width: 150px;">
        <h4 style="margin: 0 0 20px 0; font-weight:bold; color: #fff;">제휴 파트너</h4>
        <div style="font-size: 0.9rem; line-height: 2.2;">
          <a href="partners/list.html" style="color: #fff; text-decoration: none;">우수 파트너사 목록</a><br>
          <a href="partners/apply.html" style="color: #fff; text-decoration: none;">유지 보수사 협력 신청</a>
        </div>
        <a href="https://cafe.naver.com/kcbma114" target="_blank" style="display: inline-block; background: #00C73C; color: #fff; padding: 8px 16px; border-radius: 4px; font-weight: bold; font-size: 0.9rem; margin-top: 15px; text-decoration: none;">N 네이버카페</a>
      </div>
    </div>
    <div style="max-width: 1200px; margin: 40px auto 0 auto; border-top: 1px solid #1e3a8a; padding-top: 20px; font-size: 0.8rem; display: flex; justify-content: space-between; color: #fff; flex-wrap: wrap; gap: 10px;">
      <span>© 2026 대한집합건물관리협회(KCBMA). All rights reserved.</span>
      <div>
        <a href="#" style="color: #fff; text-decoration: none; margin-left: 20px;">이용약관</a>
        <a href="#" style="color: #fff; text-decoration: none; margin-left: 20px;">개인정보처리방침</a>
      </div>
    </div>
  </footer>
`;

// 2. 페이지 화면이 로드되면 가장 아래쪽에 푸터를 밀어넣습니다.
document.addEventListener('DOMContentLoaded', () => {
  // 푸터는 모달창보다 앞쪽에 있어야 하므로 body의 자식 요소 중 가장 끝에 삽입
  document.body.insertAdjacentHTML('beforeend', footerHtml);
});