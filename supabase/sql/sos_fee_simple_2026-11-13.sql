-- =====================================================================
-- 긴급 SOS 전화상담 요금 단순화 (2026-11-13)
--   · 평일 주간 09:00~21:00 (공휴일 제외)          : 30,000원  (전문가 몫 24,000원)
--   · 그 외 모든 시간 (야간·주말·공휴일·심야)      : 50,000원  (전문가 몫 40,000원)
--   · 30분 연장 = 기본 상담료의 절반 (15,000 / 25,000원), 1건당 최대 2회 — 그대로
--   · 심야(21~09시)는 요금만 같아지고, '대기 전문가가 있을 때만 접수 + 09시 예약 안내'는 그대로
--   · 이미 접수된 건의 요금은 바뀌지 않음 (접수 시각에 정해진 금액 그대로)
--
-- 요금 설정 함수(_sos_fee_cfg) 하나만 바꿉니다. 계산·결제·정산 함수는 모두 이 값을 읽어 씁니다.
-- Supabase SQL Editor에 통째로 붙여 넣고 Run 하세요.
-- =====================================================================

create or replace function public._sos_fee_cfg(p_key text) returns int
language sql immutable as $$
    select case p_key
        when 'day_fee'        then 30000   -- 평일 주간 상담료
        when 'night_fee'      then 50000   -- 야간·주말·공휴일 상담료
        when 'late_fee'       then 50000   -- 심야 상담료 (야간과 같음)
        when 'late_from'      then 21      -- 심야 시작 시각 (시) — 심야 접수 제한에 사용
        when 'late_to'        then 9       -- 심야 끝 시각 (시, 다음 날)
        when 'day_from'       then 9       -- 주간 시작 시각 (시)
        when 'day_to'         then 21      -- 주간 끝 시각 (시) — 18시에서 21시로 늘림
        when 'extend_min'     then 30      -- 연장 1회 시간 (분)
        when 'extend_max'     then 2       -- 1건당 최대 연장 횟수
        when 'extend_percent' then 50      -- 연장 요금 = 기본 상담료의 몇 %
    end
$$;

-- 확인: 각 시간대 요금 (평일 낮 30000 / 평일 밤 50000 / 토요일 낮 50000 / 새벽 50000 이 나오면 정상)
select public.sos_fee_for_time('2026-11-16 14:00:00+09') as 평일_낮_14시,
       public.sos_fee_for_time('2026-11-16 20:30:00+09') as 평일_20시반,
       public.sos_fee_for_time('2026-11-16 22:00:00+09') as 평일_밤_22시,
       public.sos_fee_for_time('2026-11-21 14:00:00+09') as 토요일_낮,
       public.sos_fee_for_time('2026-11-17 03:00:00+09') as 새벽_3시,
       public.sos_extend_fee(public.sos_fee_for_time('2026-11-16 14:00:00+09')) as 평일_연장요금;
