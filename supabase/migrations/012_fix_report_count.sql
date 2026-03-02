-- migration 012: fix report_count to use COUNT(*) instead of incrementing counter
-- Prevents drift between spots.report_count and actual reports rows.

-- 1. Update RPC: count is derived from actual rows, not from cached counter
CREATE OR REPLACE FUNCTION update_spot_after_report(
  p_spot_id   UUID,
  p_new_db    FLOAT,
  p_sticker   TEXT,
  p_user_id   UUID
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_old_avg     FLOAT;
  v_new_avg     FLOAT;
  v_count       INT;  -- actual row count AFTER insert (caller already inserted)
  v_trust       FLOAT;
BEGIN
  -- Lock spot row for update
  SELECT average_db
  INTO v_old_avg
  FROM spots
  WHERE id = p_spot_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Spot % not found', p_spot_id;
  END IF;

  -- Count actual report rows (includes the just-inserted report)
  SELECT COUNT(*) INTO v_count
  FROM reports
  WHERE spot_id = p_spot_id;

  -- EMA: first report uses raw value directly
  v_new_avg := CASE
    WHEN v_count = 1 THEN p_new_db
    ELSE (v_old_avg * 0.7) + (p_new_db * 0.3)
  END;

  -- Trust score based on actual count
  v_trust := CASE
    WHEN v_count >= 50 THEN 3   -- Gold
    WHEN v_count >= 20 THEN 2   -- Silver
    WHEN v_count >= 5  THEN 1   -- Bronze
    ELSE 0
  END;

  UPDATE spots SET
    average_db             = v_new_avg,
    report_count           = v_count,
    representative_sticker = CASE WHEN p_sticker IS NOT NULL THEN p_sticker ELSE representative_sticker END,
    trust_score            = v_trust,
    last_report_at         = NOW()
  WHERE id = p_spot_id;
END;
$$;

-- 2. Recalculate report_count for all existing spots (fix any drifted counts)
UPDATE spots s
SET report_count = (
  SELECT COUNT(*) FROM reports r WHERE r.spot_id = s.id
);
