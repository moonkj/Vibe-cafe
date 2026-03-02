-- Migration 015: User Badges
-- user_badges table + get_first_reporter_count RPC

-- 1. user_badges — stores which badges each user has earned
CREATE TABLE IF NOT EXISTS user_badges (
  user_id   UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  badge_id  TEXT NOT NULL,
  earned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_id, badge_id)
);

ALTER TABLE user_badges ENABLE ROW LEVEL SECURITY;

CREATE POLICY "owner_select" ON user_badges
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "owner_insert" ON user_badges
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 2. get_first_reporter_count
--    Returns how many spots this user was the first to measure.
CREATE OR REPLACE FUNCTION get_first_reporter_count(p_user_id UUID)
RETURNS INTEGER
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT COUNT(*)::INTEGER
  FROM (
    SELECT DISTINCT ON (spot_id) spot_id, user_id
    FROM reports
    WHERE spot_id IN (
      SELECT DISTINCT spot_id FROM reports WHERE user_id = p_user_id
    )
    ORDER BY spot_id, created_at ASC
  ) first_reporters
  WHERE user_id = p_user_id;
$$;

GRANT EXECUTE ON FUNCTION get_first_reporter_count TO authenticated;
