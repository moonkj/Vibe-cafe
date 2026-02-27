import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/constants/map_constants.dart';
import '../../../core/services/location_service.dart';
import '../../../core/utils/bounds_cache.dart';
import '../data/spots_repository.dart';
import '../domain/spot_model.dart';

enum SpotDisplayMode { individual, reduced, heatmap, hidden }

class MapState {
  final List<SpotModel> spots;
  final StickerType? activeFilter;
  final bool isLoading;
  final Position? userPosition;
  final String? error;

  const MapState({
    this.spots = const [],
    this.activeFilter,
    this.isLoading = false,
    this.userPosition,
    this.error,
  });

  MapState copyWith({
    List<SpotModel>? spots,
    StickerType? activeFilter,
    bool clearFilter = false,
    bool? isLoading,
    Position? userPosition,
    String? error,
    bool clearError = false,
  }) {
    return MapState(
      spots: spots ?? this.spots,
      activeFilter: clearFilter ? null : (activeFilter ?? this.activeFilter),
      isLoading: isLoading ?? this.isLoading,
      userPosition: userPosition ?? this.userPosition,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Riverpod 3.x Notifier (replaces deprecated StateNotifier)
class MapController extends Notifier<MapState> {
  Timer? _debounceTimer;
  final _boundsCache = BoundsCache();
  GoogleMapController? mapController;

  @override
  MapState build() {
    ref.onDispose(() => _debounceTimer?.cancel());
    _initLocation();
    return const MapState();
  }

  Future<void> _initLocation() async {
    try {
      final position = await LocationService.getCurrentPosition();
      state = state.copyWith(userPosition: position);
      await _loadSpots(lat: position.latitude, lng: position.longitude);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Called on onCameraIdle — debounced 300ms, skips cached bounds.
  void onCameraIdle(LatLngBounds bounds, double zoom) {
    if (zoom < MapConstants.zoomMinLoad) return;

    _debounceTimer?.cancel();
    _debounceTimer = Timer(
      const Duration(milliseconds: MapConstants.cameraIdleDebounceMs),
      () async {
        if (_boundsCache.isCached(bounds)) return;
        _boundsCache.set(bounds);
        final center = _boundsCenter(bounds);
        await _loadSpots(lat: center.latitude, lng: center.longitude);
      },
    );
  }

  Future<void> _loadSpots({required double lat, required double lng}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final spots = await ref.read(spotsRepositoryProvider).getSpotsNear(
            lat: lat,
            lng: lng,
            sticker: state.activeFilter,
          );
      state = state.copyWith(spots: spots, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setFilter(StickerType? filter) {
    final isToggle = state.activeFilter == filter;
    state = state.copyWith(
      activeFilter: isToggle ? null : filter,
      clearFilter: isToggle,
    );
    _boundsCache.clear();
    final pos = state.userPosition;
    if (pos != null) _loadSpots(lat: pos.latitude, lng: pos.longitude);
  }

  void refreshLocation() {
    _boundsCache.clear();
    _initLocation();
  }

  static SpotDisplayMode displayMode(double zoom) {
    if (zoom >= MapConstants.zoomIndividualMin) return SpotDisplayMode.individual;
    if (zoom >= MapConstants.zoomReducedMin) return SpotDisplayMode.reduced;
    if (zoom >= MapConstants.zoomMinLoad) return SpotDisplayMode.heatmap;
    return SpotDisplayMode.hidden;
  }

  LatLng _boundsCenter(LatLngBounds bounds) => LatLng(
        (bounds.northeast.latitude + bounds.southwest.latitude) / 2,
        (bounds.northeast.longitude + bounds.southwest.longitude) / 2,
      );
}

final mapControllerProvider = NotifierProvider<MapController, MapState>(
  MapController.new,
);
