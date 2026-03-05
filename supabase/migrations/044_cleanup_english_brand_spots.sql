-- ──────────────────────────────────────────────────────────────
-- 044_cleanup_english_brand_spots.sql
-- 순수 영문 브랜드명 스팟 삭제 (지점 정보 없는 "Starbucks" 등)
-- 조건: report_count = 0 AND 이름이 ASCII 영문자·공백만으로 구성
-- ──────────────────────────────────────────────────────────────

DELETE FROM spots
WHERE report_count = 0
  AND name ~ '^[A-Za-z\s''&]+$';
