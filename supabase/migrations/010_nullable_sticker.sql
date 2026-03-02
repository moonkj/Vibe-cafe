-- Allow text-only reports (no sticker selected)
ALTER TABLE reports ALTER COLUMN selected_sticker DROP NOT NULL;

-- Update RPC: only overwrite representative_sticker when a sticker is provided
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
  v_count       INT;
  v_trust       FLOAT;
BEGIN
  SELECT average_db, report_count
  INTO v_old_avg, v_count
  FROM spots
  WHERE id = p_spot_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Spot % not found', p_spot_id;
  END IF;

  v_new_avg := CASE
    WHEN v_count = 0 THEN p_new_db
    ELSE (v_old_avg * 0.7) + (p_new_db * 0.3)
  END;

  v_trust := CASE
    WHEN v_count + 1 >= 50 THEN 3
    WHEN v_count + 1 >= 20 THEN 2
    WHEN v_count + 1 >= 5  THEN 1
    ELSE 0
  END;

  UPDATE spots SET
    average_db             = v_new_avg,
    report_count           = v_count + 1,
    -- Only update representative_sticker when a sticker was provided
    representative_sticker = CASE WHEN p_sticker IS NOT NULL THEN p_sticker ELSE representative_sticker END,
    trust_score            = v_trust,
    last_report_at         = NOW()
  WHERE id = p_spot_id;
END;
$$;
