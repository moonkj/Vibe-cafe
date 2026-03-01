import 'package:flutter_test/flutter_test.dart';
import 'package:cafe_vibe/core/services/location_service.dart';

void main() {
  // 서울 광화문 기준 좌표
  const baseLat = 37.5759;
  const baseLng = 126.9769;

  group('LocationService.isWithinReportRadius — Haversine 100m 게이트', () {
    test('동일한 위치(0m)는 반경 내에 있다', () {
      expect(
        LocationService.isWithinReportRadius(
          userLat: baseLat, userLng: baseLng,
          targetLat: baseLat, targetLng: baseLng,
        ),
        isTrue,
      );
    });

    test('약 50m 북쪽은 반경 내에 있다', () {
      // 50m ≈ 0.000450° 위도 차이
      expect(
        LocationService.isWithinReportRadius(
          userLat: baseLat, userLng: baseLng,
          targetLat: baseLat + 0.000450, targetLng: baseLng,
        ),
        isTrue,
      );
    });

    test('약 89m(100m 미만)는 반경 내에 있다', () {
      // 89m ≈ 0.000801° 위도 차이
      expect(
        LocationService.isWithinReportRadius(
          userLat: baseLat, userLng: baseLng,
          targetLat: baseLat + 0.000801, targetLng: baseLng,
        ),
        isTrue,
      );
    });

    test('약 122m(100m 초과)는 반경 밖에 있다', () {
      // 122m ≈ 0.001098° 위도 차이
      expect(
        LocationService.isWithinReportRadius(
          userLat: baseLat, userLng: baseLng,
          targetLat: baseLat + 0.001098, targetLng: baseLng,
        ),
        isFalse,
      );
    });

    test('약 200m(2배)는 반경 밖에 있다', () {
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

    test('경도 방향 이동 — 약 83m(위도 37° 기준)는 반경 내에 있다', () {
      // 위도 37°에서 경도 1° ≈ 88,750m
      // 83m ≈ 0.000936° 경도 차이
      expect(
        LocationService.isWithinReportRadius(
          userLat: baseLat, userLng: baseLng,
          targetLat: baseLat, targetLng: baseLng + 0.000936,
        ),
        isTrue,
      );
    });

    test('경도 방향 이동 — 약 112m는 반경 밖에 있다', () {
      // 112m ≈ 0.001263° 경도 차이
      expect(
        LocationService.isWithinReportRadius(
          userLat: baseLat, userLng: baseLng,
          targetLat: baseLat, targetLng: baseLng + 0.001263,
        ),
        isFalse,
      );
    });

    test('대각선 이동(북동)도 Haversine으로 정확히 판단된다', () {
      // 50m 북 + 50m 동 → 합산 약 70.7m → 반경 내
      expect(
        LocationService.isWithinReportRadius(
          userLat: baseLat, userLng: baseLng,
          targetLat: baseLat + 0.000450,
          targetLng: baseLng + 0.000561, // 50m @ 37° lat
        ),
        isTrue,
      );
    });
  });
}
