-- ──────────────────────────────────────────────────────────────
-- 028_get_spots_near_no_limit.sql
-- get_spots_near: LIMIT 100 제거 → 3km 내 전체 카페 반환
-- ──────────────────────────────────────────────────────────────

DROP FUNCTION IF EXISTS get_spots_near(FLOAT, FLOAT, FLOAT, TEXT);

CREATE OR REPLACE FUNCTION get_spots_near(
  user_lat        FLOAT,
  user_lng        FLOAT,
  radius_meters   FLOAT DEFAULT 3000,
  filter_sticker  TEXT DEFAULT NULL
)
RETURNS TABLE (
  id                     UUID,
  name                   TEXT,
  google_place_id        TEXT,
  formatted_address      TEXT,
  lat                    FLOAT,
  lng                    FLOAT,
  average_db             FLOAT,
  representative_sticker TEXT,
  report_count           INT,
  trust_score            FLOAT,
  recent_24h_count       INT,
  last_report_at         TIMESTAMPTZ,
  photo_url              TEXT
)
LANGUAGE sql STABLE
SECURITY DEFINER
AS $$
  SELECT
    s.id,
    s.name,
    s.google_place_id,
    s.formatted_address,
    ST_Y(s.location::geometry)  AS lat,
    ST_X(s.location::geometry)  AS lng,
    s.average_db,
    s.representative_sticker,
    s.report_count,
    s.trust_score,
    COUNT(r.id) FILTER (
      WHERE r.created_at > NOW() - INTERVAL '24 hours'
    )::INT                       AS recent_24h_count,
    s.last_report_at,
    s.photo_url
  FROM spots s
  LEFT JOIN reports r ON r.spot_id = s.id
  WHERE
    ST_DWithin(
      s.location,
      ST_MakePoint(user_lng, user_lat)::geography,
      LEAST(radius_meters, 5000)
    )
    AND (
      s.last_report_at IS NULL
      OR s.last_report_at > NOW() - INTERVAL '30 days'
    )
    AND (filter_sticker IS NULL OR s.representative_sticker = filter_sticker)
  GROUP BY s.id
  ORDER BY ST_Distance(
    s.location,
    ST_MakePoint(user_lng, user_lat)::geography
  );
$$;

GRANT EXECUTE ON FUNCTION get_spots_near TO anon;
