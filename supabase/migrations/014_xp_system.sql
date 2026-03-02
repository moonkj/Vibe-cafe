-- Migration 014: XP System
-- Adds total_xp to user_stats and creates award_xp RPC

-- 1. Add total_xp column
ALTER TABLE user_stats
  ADD COLUMN IF NOT EXISTS total_xp INTEGER NOT NULL DEFAULT 0;

-- 2. award_xp — safely increments total_xp for a user
--    Called after report submission with xp_earned (+10 report, +5 new cafe)
CREATE OR REPLACE FUNCTION award_xp(
  p_user_id UUID,
  p_xp      INTEGER
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO user_stats (user_id, total_xp, updated_at)
  VALUES (p_user_id, p_xp, NOW())
  ON CONFLICT (user_id) DO UPDATE SET
    total_xp   = user_stats.total_xp + EXCLUDED.total_xp,
    updated_at = NOW();
END;
$$;

GRANT EXECUTE ON FUNCTION award_xp TO authenticated;
