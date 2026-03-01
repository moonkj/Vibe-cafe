-- ============================================================
-- Cafe Vibe — Migration 002: User Stats, Profiles & Rankings
-- Run this in: Supabase Dashboard → SQL Editor
-- ============================================================

-- ============================================================
-- 1. Add formatted_address to spots table
-- ============================================================
ALTER TABLE spots ADD COLUMN IF NOT EXISTS formatted_address TEXT;

-- ============================================================
-- 2. user_profiles table — stores server-side nickname
-- ============================================================
CREATE TABLE IF NOT EXISTS user_profiles (
  user_id   UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  nickname  TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "profiles_read_all"
  ON user_profiles FOR SELECT USING (true);

CREATE POLICY "profiles_insert_own"
  ON user_profiles FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "profiles_update_own"
  ON user_profiles FOR UPDATE TO authenticated
  USING (auth.uid() = user_id);

-- ============================================================
-- 3. user_stats table — aggregated user stats
-- ============================================================
CREATE TABLE IF NOT EXISTS user_stats (
  user_id       UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  total_reports INT NOT NULL DEFAULT 0,
  total_cafes   INT NOT NULL DEFAULT 0,
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE user_stats ENABLE ROW LEVEL SECURITY;

CREATE POLICY "stats_read_all"
  ON user_stats FOR SELECT USING (true);

CREATE POLICY "stats_own_all"
  ON user_stats FOR ALL TO authenticated
  USING (auth.uid() = user_id);

-- ============================================================
-- 4. update_user_stats() — called after each report submission
-- Upserts total_reports + total_cafes for the user
-- ============================================================
CREATE OR REPLACE FUNCTION update_user_stats(
  p_user_id UUID
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_total_reports INT;
  v_total_cafes   INT;
BEGIN
  SELECT COUNT(*)
  INTO v_total_reports
  FROM reports
  WHERE user_id = p_user_id;

  SELECT COUNT(DISTINCT spot_id)
  INTO v_total_cafes
  FROM reports
  WHERE user_id = p_user_id;

  INSERT INTO user_stats (user_id, total_reports, total_cafes, updated_at)
  VALUES (p_user_id, v_total_reports, v_total_cafes, NOW())
  ON CONFLICT (user_id) DO UPDATE SET
    total_reports = EXCLUDED.total_reports,
    total_cafes   = EXCLUDED.total_cafes,
    updated_at    = NOW();
END;
$$;

GRANT EXECUTE ON FUNCTION update_user_stats TO authenticated;

-- ============================================================
-- 5. get_cafe_ranking_quiet — 조용한 카페 TOP (avg_db ASC)
-- Min 3 reports required for reliability
-- ============================================================
CREATE OR REPLACE FUNCTION get_cafe_ranking_quiet(
  limit_count INT DEFAULT 20
)
RETURNS TABLE (
  id                     UUID,
  name                   TEXT,
  formatted_address      TEXT,
  average_db             FLOAT,
  representative_sticker TEXT,
  report_count           INT
)
LANGUAGE sql STABLE
SECURITY DEFINER
AS $$
  SELECT
    s.id,
    s.name,
    s.formatted_address,
    s.average_db,
    s.representative_sticker,
    s.report_count
  FROM spots s
  WHERE s.report_count >= 3
    AND s.average_db > 0
    AND (s.last_report_at IS NULL OR s.last_report_at > NOW() - INTERVAL '30 days')
  ORDER BY s.average_db ASC
  LIMIT limit_count;
$$;

GRANT EXECUTE ON FUNCTION get_cafe_ranking_quiet TO anon, authenticated;

-- ============================================================
-- 6. get_user_ranking — 측정왕 TOP (total reports DESC)
-- ============================================================
CREATE OR REPLACE FUNCTION get_user_ranking(
  limit_count INT DEFAULT 20
)
RETURNS TABLE (
  user_id       UUID,
  nickname      TEXT,
  total_reports INT,
  total_cafes   INT
)
LANGUAGE sql STABLE
SECURITY DEFINER
AS $$
  SELECT
    us.user_id,
    COALESCE(up.nickname, '카페바이브 유저') AS nickname,
    us.total_reports,
    us.total_cafes
  FROM user_stats us
  LEFT JOIN user_profiles up ON up.user_id = us.user_id
  WHERE us.total_reports > 0
  ORDER BY us.total_reports DESC
  LIMIT limit_count;
$$;

GRANT EXECUTE ON FUNCTION get_user_ranking TO anon, authenticated;

-- ============================================================
-- 7. get_cafe_ranking_weekly — 이번 주 활발한 카페 TOP
-- Sorted by report count in the last 7 days
-- ============================================================
CREATE OR REPLACE FUNCTION get_cafe_ranking_weekly(
  limit_count INT DEFAULT 20
)
RETURNS TABLE (
  id                     UUID,
  name                   TEXT,
  formatted_address      TEXT,
  representative_sticker TEXT,
  weekly_count           INT,
  total_count            INT
)
LANGUAGE sql STABLE
SECURITY DEFINER
AS $$
  SELECT
    s.id,
    s.name,
    s.formatted_address,
    s.representative_sticker,
    COUNT(r.id) FILTER (WHERE r.created_at > NOW() - INTERVAL '7 days')::INT AS weekly_count,
    s.report_count AS total_count
  FROM spots s
  LEFT JOIN reports r ON r.spot_id = s.id
  WHERE s.last_report_at > NOW() - INTERVAL '30 days'
  GROUP BY s.id
  HAVING COUNT(r.id) FILTER (WHERE r.created_at > NOW() - INTERVAL '7 days') > 0
  ORDER BY weekly_count DESC
  LIMIT limit_count;
$$;

GRANT EXECUTE ON FUNCTION get_cafe_ranking_weekly TO anon, authenticated;

-- ============================================================
-- 8. upsert_user_profile — nickname 서버 저장용
-- ============================================================
CREATE OR REPLACE FUNCTION upsert_user_profile(
  p_user_id UUID,
  p_nickname TEXT
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO user_profiles (user_id, nickname, updated_at)
  VALUES (p_user_id, p_nickname, NOW())
  ON CONFLICT (user_id) DO UPDATE SET
    nickname   = EXCLUDED.nickname,
    updated_at = NOW();
END;
$$;

GRANT EXECUTE ON FUNCTION upsert_user_profile TO authenticated;

-- ============================================================
-- 9. get_my_stats — 내 통계 (user_stats + profile 통합)
-- ============================================================
CREATE OR REPLACE FUNCTION get_my_stats(
  p_user_id UUID
)
RETURNS TABLE (
  total_reports INT,
  total_cafes   INT
)
LANGUAGE sql STABLE
SECURITY DEFINER
AS $$
  SELECT
    COALESCE(us.total_reports, 0),
    COALESCE(us.total_cafes, 0)
  FROM user_stats us
  WHERE us.user_id = p_user_id;
$$;

GRANT EXECUTE ON FUNCTION get_my_stats TO authenticated;
