-- ──────────────────────────────────────────────────────────────
-- 021_spot_photo_url.sql
-- Google Places (New) API 사진 URL 캐싱을 위한 컬럼 추가
-- ──────────────────────────────────────────────────────────────

ALTER TABLE spots
ADD COLUMN IF NOT EXISTS photo_url TEXT;
