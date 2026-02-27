import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:noise_spot/core/utils/bounds_cache.dart';

LatLngBounds _bounds(
  double swLat,
  double swLng,
  double neLat,
  double neLng,
) =>
    LatLngBounds(
      southwest: LatLng(swLat, swLng),
      northeast: LatLng(neLat, neLng),
    );

void main() {
  group('BoundsCache.isCached / set', () {
    test('빈 캐시는 항상 미스', () {
      final cache = BoundsCache();
      final b = _bounds(37.50, 127.00, 37.53, 127.03);
      expect(cache.isCached(b), isFalse);
    });

    test('set 후 동일 bounds는 히트', () {
      final cache = BoundsCache();
      final b = _bounds(37.50, 127.00, 37.53, 127.03);
      cache.set(b);
      expect(cache.isCached(b), isTrue);
    });

    test('겹치는 bounds는 히트 (tolerance 범위 내)', () {
      final cache = BoundsCache();
      final b1 = _bounds(37.50, 127.00, 37.53, 127.03);
      // b2는 b1 대비 ~0.001도 이동 (tolerance 0.005보다 작음)
      final b2 = _bounds(37.501, 127.001, 37.531, 127.031);
      cache.set(b1);
      expect(cache.isCached(b2), isTrue);
    });

    test('완전히 다른 bounds는 미스', () {
      final cache = BoundsCache();
      final b1 = _bounds(37.50, 127.00, 37.53, 127.03);
      final b2 = _bounds(35.10, 129.00, 35.13, 129.03); // 부산
      cache.set(b1);
      expect(cache.isCached(b2), isFalse);
    });
  });

  group('BoundsCache TTL', () {
    test('TTL 만료 전에는 히트', () {
      final cache = BoundsCache(ttlSeconds: 60);
      final b = _bounds(37.50, 127.00, 37.53, 127.03);
      cache.set(b);
      expect(cache.isCached(b), isTrue);
    });

    test('ttlSeconds=0 이면 set 직후에는 아직 캐시됨 (inSeconds 절삭 특성)', () {
      // _evictExpired 조건: inSeconds > ttlSeconds
      // ttlSeconds=0일 때 set 직후 inSeconds=0 → 0 > 0 = false → 아직 제거 안 됨
      final cache = BoundsCache(ttlSeconds: 0);
      final b = _bounds(37.50, 127.00, 37.53, 127.03);
      cache.set(b);
      expect(cache.isCached(b), isTrue);
    });
  });

  group('BoundsCache.clear', () {
    test('clear 후 이전 캐시는 미스', () {
      final cache = BoundsCache();
      final b = _bounds(37.50, 127.00, 37.53, 127.03);
      cache.set(b);
      cache.clear();
      expect(cache.isCached(b), isFalse);
    });

    test('clear 후 새로운 set은 정상 히트', () {
      final cache = BoundsCache();
      final b1 = _bounds(37.50, 127.00, 37.53, 127.03);
      final b2 = _bounds(37.60, 127.10, 37.63, 127.13);
      cache.set(b1);
      cache.clear();
      cache.set(b2);
      expect(cache.isCached(b1), isFalse);
      expect(cache.isCached(b2), isTrue);
    });
  });
}
