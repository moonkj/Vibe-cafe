import 'package:flutter_test/flutter_test.dart';
import 'package:cafe_vibe/core/services/location_service.dart';

void main() {
  // 서울 광화문 기준 좌표
  const baseLat = 37.5759;
  const baseLng = 126.9769;

  // reportMaxDistanceMeters = 50m (MapConstants.reportMaxDistanceMeters)
  group('LocationService.isWithinReportRadius — Haversine 50m 게이트', () {
    test('동일한 위치(0m)는 반경 내에 있다', () {
      expect(
        LocationService.isWithinReportRadius(
          userLat: baseLat, userLng: baseLng,
          targetLat: baseLat, targetLng: baseLng,
        ),
        isTrue,
      );
    });

    test('약 22m 북쪽은 반경 내에 있다 (50m 한계 내)', () {
      // 22m ≈ 0.000198° 위도 차이
      expect(
        LocationService.isWithinReportRadius(
          userLat: baseLat, userLng: baseLng,
          targetLat: baseLat + 0.000198, targetLng: baseLng,
        ),
        isTrue,
      );
    });

    test('약 49m(50m 미만)는 반경 내에 있다', () {
      // 49m ≈ 0.000441° 위도 차이
      expect(
        LocationService.isWithinReportRadius(
          userLat: baseLat, userLng: baseLng,
          targetLat: baseLat + 0.000441, targetLng: baseLng,
        ),
        isTrue,
      );
    });

    test('약 55m(50m 초과)는 반경 밖에 있다', () {
      // 55m ≈ 0.000495° 위도 차이
      expect(
        LocationService.isWithinReportRadius(
          userLat: baseLat, userLng: baseLng,
          targetLat: baseLat + 0.000495, targetLng: baseLng,
        ),
        isFalse,
      );
    });

    test('약 200m(4배)는 반경 밖에 있다', () {
      // 200m ≈ 0.001800° 위도 차이
      expect(
        LocationService.isWithinReportRadius(
          userLat: baseLat, userLng: baseLng,
          targetLat: baseLat + 0.001800, targetLng: baseLng,
        ),
        isFalse,
      );
    });

    test('서울→부산 약 325km는 반경 밖에 있다', () {
      const busanLat = 35.1796;
      const busanLng = 129.0756;
      expect(
        LocationService.isWithinReportRadius(
          userLat: baseLat, userLng: baseLng,
          targetLat: busanLat, targetLng: busanLng,
        ),
        isFalse,
      );
    });

    test('경도 방향 이동 — 약 40m(위도 37° 기준)는 반경 내에 있다', () {
      // 위도 37°에서 경도 1° ≈ 88,000m
      // 40m ≈ 0.000455° 경도 차이
      expect(
        LocationService.isWithinReportRadius(
          userLat: baseLat, userLng: baseLng,
          targetLat: baseLat, targetLng: baseLng + 0.000455,
        ),
        isTrue,
      );
    });

    test('경도 방향 이동 — 약 70m는 반경 밖에 있다', () {
      // 70m ≈ 0.000795° 경도 차이
      expect(
        LocationService.isWithinReportRadius(
          userLat: baseLat, userLng: baseLng,
          targetLat: baseLat, targetLng: baseLng + 0.000795,
        ),
        isFalse,
      );
    });

    test('대각선 이동(북동) — 약 22m 북 + 22m 동 ≈ 31m → 반경 내', () {
      // 22m 북 ≈ 0.000198°, 22m 동 ≈ 0.000250°
      // 합산 약 31m → 50m 이내
      expect(
        LocationService.isWithinReportRadius(
          userLat: baseLat, userLng: baseLng,
          targetLat: baseLat + 0.000198,
          targetLng: baseLng + 0.000250,
        ),
        isTrue,
      );
    });

    test('대각선 이동(북동) — 약 40m 북 + 40m 동 ≈ 56.6m → 반경 밖', () {
      // 40m 북 ≈ 0.000360°, 40m 동 ≈ 0.000455°
      // 합산 약 56.6m → 50m 초과
      expect(
        LocationService.isWithinReportRadius(
          userLat: baseLat, userLng: baseLng,
          targetLat: baseLat + 0.000360,
          targetLng: baseLng + 0.000455,
        ),
        isFalse,
      );
    });
  });
}
