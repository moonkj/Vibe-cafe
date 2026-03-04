-- ──────────────────────────────────────────────────────────────
-- 030_security_fixes.sql
-- Phase 35 보안 강화 — 코드 리뷰 CRITICAL 이슈 수정
-- ──────────────────────────────────────────────────────────────

-- ═══════════════════════════════════════════════════════════════
-- [SEC-01] get_all_spots_admin — anon 접근 차단 + 어드민 인증
-- 기존: GRANT TO anon → 비인증 사용자가 전체 카페 200건 조회 가능
-- 수정: REVOKE anon + 함수 내부에서 admin UUID 확인
-- ═══════════════════════════════════════════════════════════════
REVOKE EXECUTE ON FUNCTION get_all_spots_admin FROM anon;

CREATE OR REPLACE FUNCTION get_all_spots_admin(search_query TEXT DEFAULT NULL)
RETURNS TABLE (
  id              UUID,
  name            TEXT,
  formatted_address TEXT,
  lat             FLOAT,
  lng             FLOAT,
  report_count    INT,
  created_at      TIMESTAMPTZ
)
LANGUAGE plpgsql STABLE
SECURITY DEFINER
AS $$
BEGIN
  IF auth.uid() IS NULL
     OR auth.uid() != 'da2a8b72-a3c2-415b-bae5-63f2fa0b92a0'::uuid
  THEN
    RAISE EXCEPTION 'Access denied: admin only';
  END IF;

  RETURN QUERY
    SELECT
      s.id,
      s.name,
      s.formatted_address,
      ST_Y(s.location::geometry) AS lat,
      ST_X(s.location::geometry) AS lng,
      s.report_count,
      s.created_at
    FROM spots s
    WHERE search_query IS NULL OR s.name ILIKE '%' || search_query || '%'
    ORDER BY s.created_at DESC
    LIMIT 200;
END;
$$;

GRANT EXECUTE ON FUNCTION get_all_spots_admin TO authenticated;

-- ═══════════════════════════════════════════════════════════════
-- [SEC-02] spots 테이블 UPDATE / DELETE RLS — 어드민 전용
-- 기존: RLS 정책 없음 → 인증된 모든 사용자가 카페 수정/삭제 가능
-- ═══════════════════════════════════════════════════════════════
DROP POLICY IF EXISTS "spots_update_admin" ON spots;
DROP POLICY IF EXISTS "spots_delete_admin" ON spots;

CREATE POLICY "spots_update_admin"
  ON spots FOR UPDATE
  USING (auth.uid() = 'da2a8b72-a3c2-415b-bae5-63f2fa0b92a0'::uuid);

CREATE POLICY "spots_delete_admin"
  ON spots FOR DELETE
  USING (auth.uid() = 'da2a8b72-a3c2-415b-bae5-63f2fa0b92a0'::uuid);

-- ═══════════════════════════════════════════════════════════════
-- [SEC-03] get_admin_user_stats — 어드민 인증 추가
-- 기존: 모든 로그인 사용자가 DAU/WAU/MAU 통계 조회 가능
-- ═══════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION get_admin_user_stats()
RETURNS TABLE (
  dau   INT,
  wau   INT,
  mau   INT,
  total INT
)
LANGUAGE plpgsql STABLE
SECURITY DEFINER
AS $$
BEGIN
  IF auth.uid() IS NULL
     OR auth.uid() != 'da2a8b72-a3c2-415b-bae5-63f2fa0b92a0'::uuid
  THEN
    RAISE EXCEPTION 'Access denied: admin only';
  END IF;

  RETURN QUERY
    SELECT
      (SELECT COUNT(DISTINCT user_id)::INT FROM user_sessions
        WHERE date = CURRENT_DATE)                             AS dau,
      (SELECT COUNT(DISTINCT user_id)::INT FROM user_sessions
        WHERE date >= CURRENT_DATE - 6)                       AS wau,
      (SELECT COUNT(DISTINCT user_id)::INT FROM user_sessions
        WHERE date >= CURRENT_DATE - 29)                      AS mau,
      (SELECT COUNT(DISTINCT user_id)::INT FROM user_sessions) AS total;
END;
$$;

GRANT EXECUTE ON FUNCTION get_admin_user_stats TO authenticated;

-- ═══════════════════════════════════════════════════════════════
-- [SEC-04] reports — 같은 날 같은 카페 중복 제출 방지 UNIQUE 제약
-- 기존: 별개 쿼리로 중복 체크 → race condition 허용
-- 수정: DB 레벨 UNIQUE → ON CONFLICT DO NOTHING으로 원자적 방어
-- ═══════════════════════════════════════════════════════════════
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'reports_user_spot_day_unique'
  ) THEN
    ALTER TABLE reports
      ADD CONSTRAINT reports_user_spot_day_unique
      UNIQUE (user_id, spot_id, (created_at::date));
  END IF;
END;
$$;
