// Supabase 설정 통합 - 모든 페이지에서 이 파일을 로드하여 사용
const SUPABASE_URL = 'https://ehrahnnowwjkgycvlbzk.supabase.co';
const SUPABASE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVocmFobm5vd3dqa2d5Y3ZsYnprIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODIwMzQ1NjQsImV4cCI6MjA5NzYxMDU2NH0.A0MfXNI4W7sPUM4UwSn7_kY5n2gEhp3N8ubH7uBZZwk';
// 이미 다른 스크립트(예: 헤더의 로그인 상태 체크)가 window.sb를 만들어뒀으면
// 재사용 — 같은 페이지에 supabase 클라이언트가 여러 개 생기면(특히 OAuth
// 로그인 직후 URL의 인증 코드를 여러 클라이언트가 동시에 처리하려다) 코드
// 교환이 실패하는 문제가 있어 반드시 하나만 유지해야 함.
window.sb = window.sb || window.supabase.createClient(SUPABASE_URL, SUPABASE_KEY);
