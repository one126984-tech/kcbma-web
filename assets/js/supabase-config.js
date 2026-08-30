// Supabase 설정 통합 - 모든 페이지에서 이 파일을 로드하여 사용
const SUPABASE_URL = 'https://ehrahnnowwjkgycvlbzk.supabase.co';
const SUPABASE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVocmFobm5vd3dqa2d5Y3ZsYnprIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODIwMzQ1NjQsImV4cCI6MjA5NzYxMDU2NH0.A0MfXNI4W7sPUM4UwSn7_kY5n2gEhp3N8ubH7uBZZwk';
window.sb = window.supabase.createClient(SUPABASE_URL, SUPABASE_KEY);
