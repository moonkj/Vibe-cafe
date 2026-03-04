-- ──────────────────────────────────────────────────────────────
-- 032_update_spot_after_report_security.sql
-- update_spot_after_report 보안 강화:
--   1. p_user_id 파라미터 제거 → auth.uid() 사용
--   2. p_new_db 범위 검증 (0~120 dB)
--   3. 미인증 호출 차단
-- ──────────────────────────────────────────────────────────────

DROP FUNCTION IF EXISTS update_spot_after_report(UUID, FLOAT, TEXT, UUID);

CREATE OR REPLACE FUNCTION update_spot_after_report(
  p_spot_id   UUID,
  p_new_db    FLOAT,
  p_sticker   TEXT
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_old_avg     FLOAT;
  v_new_avg     FLOAT;
  v_count       INT;
  v_trust       FLOAT;
BEGIN
  -- 인증 필수: 미로그인 호출 차단
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Unauthorized: authentication required';
  END IF;

  -- dB 범위 검증: 0~120 dB
  IF p_new_db < 0 OR p_new_db > 120 THEN
    RAISE EXCEPTION 'Invalid dB value: % (must be 0–120)', p_new_db;
  END IF;

  -- Lock the row to prevent concurrent update races
  SELECT average_db, report_count
  INTO v_old_avg, v_count
  FROM spots
  WHERE id = p_spot_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Spot % not found', p_spot_id;
  END IF;

  -- EMA: first report uses the raw value directly
  v_new_avg := CASE
    WHEN v_count = 0 THEN p_new_db
    ELSE (v_old_avg * 0.7) + (p_new_db * 0.3)
  END;

  -- Trust score grade (report count includes the new one)
  v_trust := CASE
    WHEN v_count + 1 >= 50 THEN 3   -- Gold
    WHEN v_count + 1 >= 20 THEN 2   -- Silver
    WHEN v_count + 1 >= 5  THEN 1   -- Bronze
    ELSE 0
  END;

  UPDATE spots SET
    average_db             = v_new_avg,
    report_count           = v_count + 1,
    representative_sticker = p_sticker,
    trust_score            = v_trust,
    last_report_at         = NOW()
  WHERE id = p_spot_id;
END;
$$;

GRANT EXECUTE ON FUNCTION update_spot_after_report(UUID, FLOAT, TEXT) TO authenticated;
