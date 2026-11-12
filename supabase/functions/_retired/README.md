# 사용하지 않는 서버 함수 기록 (2026-11-13)

사이트 코드에서 부르지 않는 함수들. Supabase에서 삭제 권장.

- **bright-task**: 예전 결제 확인 함수(portone-confirm) 사본. 지금은 `super-endpoint`가 같은 일을 함. 코드는 `bright-task.ts`에 보관.
- **send-sms** (2026-11-13 Supabase에서 삭제함): 로그인 확인 없이 아무 번호로나 문자를 보낼 수 있음 → 솔라피 잔액 도용 위험. 지금은 `send-sos-alimtalk`가 문자 발송 담당.
- **cancel-payment** (2026-11-13 Supabase에서 삭제함): 로그인·관리자 확인 없이 결제 취소(환불)를 할 수 있음 → 충전 후 결제만 취소해 포인트를 공짜로 얻는 악용 가능. 환불이 필요하면 포트원 관리자 화면에서 직접 처리.
- **portone-webhook**: 아무 일도 하지 않는 빈 함수(안전 모드). 포트원 웹훅 주소를 `super-endpoint`로 바꾼 뒤 삭제.

참고: sos_requests 데이터베이스 웹훅은 없음(2026-11-13 확인) → 접수 시 전체 문자는 나가지 않음. `send-sos-alimtalk`는 요청자가 고른 전문가에게 보내는 콜 문자(invite)와 선택 알림(selected)만 사용.
