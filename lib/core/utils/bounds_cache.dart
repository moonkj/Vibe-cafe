import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Caches map bounds for [ttlSeconds] to prevent redundant server queries.
/// Default TTL: 5 minutes (300 seconds).
class BoundsCache {
  static const int _defaultTtl = 300;
  static const double _tolerance = 0.005; // ~500m tolerance for bounds match

  final int ttlSeconds;
  final List<_CachedBounds> _entries = [];

  BoundsCache({this.ttlSeconds = _defaultTtl});

  bool isCached(LatLngBounds bounds) {
    _evictExpired();
    return _entries.any((e) => _boundsOverlap(e.bounds, bounds));
  }

  void set(LatLngBounds bounds) {
    _evictExpired();
    _entries.add(_CachedBounds(bounds, DateTime.now()));
  }

  void clear() => _entries.clear();

  void _evictExpired() {
    final now = DateTime.now();
    _entries.removeWhere(
      (e) => now.difference(e.cachedAt).inSeconds > ttlSeconds,
    );
  }

  bool _boundsOverlap(LatLngBounds a, LatLngBounds b) {
    return (a.southwest.latitude - _tolerance) <= b.northeast.latitude &&
        (a.northeast.latitude + _tolerance) >= b.southwest.latitude &&
        (a.southwest.longitude - _tolerance) <= b.northeast.longitude &&
        (a.northeast.longitude + _tolerance) >= b.southwest.longitude;
  }
}

class _CachedBounds {
  final LatLngBounds bounds;
  final DateTime cachedAt;
  _CachedBounds(this.bounds, this.cachedAt);
}
