-- ──────────────────────────────────────────────────────────────
-- 036_get_spots_near_no_limit.sql
-- LIMIT 200 제거 → 3km 이내 활성 스팟 전부 반환
-- 기존: 거리순 상위 200개만 반환 → 가장자리 카페 누락
-- 수정: 상한 없이 모두 반환 (30일 활동 필터로 실제 결과 수 자연 제한)
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
