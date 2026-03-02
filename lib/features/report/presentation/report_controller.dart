import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:noise_meter/noise_meter.dart';
import '../../../core/constants/map_constants.dart';
import '../../../core/services/admin_dummy_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/review_service.dart';
import '../../../core/utils/noise_filter.dart';
import '../data/report_repository.dart';
import '../../map/data/spots_repository.dart';
import '../../map/domain/spot_model.dart';

enum ReportPhase { idle, measuring, stabilizing, stickerSelection, submitting, done, error }

class ReportState {
  final double currentDb;
  final double stableDb;
  final ReportPhase phase;
  final StickerType? selectedSticker;
  final String? errorMessage;
  final int elapsedSeconds;

  const ReportState({
    this.currentDb = 30.0,
    this.stableDb = 0,
    this.phase = ReportPhase.idle,
    this.selectedSticker,
    this.errorMessage,
    this.elapsedSeconds = 0,
  });

  ReportState copyWith({
    double? currentDb,
    double? stableDb,
    ReportPhase? phase,
    StickerType? selectedSticker,
    String? errorMessage,
    bool clearError = false,
    int? elapsedSeconds,
  }) {
    return ReportState(
      currentDb: currentDb ?? this.currentDb,
      stableDb: stableDb ?? this.stableDb,
      phase: phase ?? this.phase,
      selectedSticker: selectedSticker ?? this.selectedSticker,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
    );
  }
}

/// Riverpod 3.x Notifier for noise reporting.
/// Call [initialize] before [startMeasurement].
class ReportController extends Notifier<ReportState> {
  NoiseMeter? _meter;
  StreamSubscription<NoiseReading>? _sub;
  Timer? _stabilizeTimer;
  Timer? _elapsedTimer;
  int _elapsed = 0;
  final List<double> _recentReadings = [];

  // GPS focused 3-second sampling at measurement start
  StreamSubscription<Position>? _gpsSub;
  Timer? _gpsCollectionTimer;
  final List<Position> _gpsSamples = [];
  Position? _bestGpsPosition; // resolved after 3s collection window

  // Good GPS quality threshold (matches proximity gate radius)
  static const double _gpsAccuracyThresholdM = 50.0;
  // Duration to collect GPS samples when measurement starts
  static const Duration _gpsCollectionDuration = Duration(seconds: 3);

  // Empty string = new spot (will be created on submit)
  String _spotId = '';
  String _spotName = '';
  String? _googlePlaceId;
  double? _spotLat;
  double? _spotLng;

  /// Called by ReportScreen before startMeasurement().
  /// Pass empty [spotId] to create a new spot on submit.
  void initialize({
    required String spotId,
    String spotName = '',
    String? googlePlaceId,
    double? lat,
    double? lng,
  }) {
    _stopMeasurement();
    _spotId = spotId;
    _spotName = spotName;
    _googlePlaceId = googlePlaceId;
    _spotLat = lat;
    _spotLng = lng;
    _bestGpsPosition = null;
    _gpsSamples.clear();
    state = const ReportState();
  }

  /// Update the spot name (used when user types a name for a new spot).
  void updateSpotName(String name) {
    _spotName = name;
  }

  @override
  ReportState build() {
    ref.onDispose(_stopMeasurement);
    return const ReportState();
  }

  /// Begin dB measurement.
  /// Audio is processed in-memory only — never stored or transmitted.
  /// GPS sampling starts in parallel for 3 seconds — best accuracy sample
  /// (horizontalAccuracy ≤ 30m preferred) is cached for proximity checks.
  void startMeasurement() {
    if (state.phase == ReportPhase.measuring || state.phase == ReportPhase.stabilizing) return;
    _elapsed = 0;
    state = state.copyWith(phase: ReportPhase.measuring, elapsedSeconds: 0, clearError: true);
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsed++;
      state = state.copyWith(elapsedSeconds: _elapsed);
    });
    _startGpsSampling();
    _meter = NoiseMeter();

    _sub = _meter!.noise.listen(
      (NoiseReading reading) {
        final db = reading.meanDecibel;
        if (!NoiseFilter.isValid(db)) return;

        _recentReadings.add(db);
        if (_recentReadings.length > 30) _recentReadings.removeAt(0);

        state = state.copyWith(currentDb: db);

        if (_recentReadings.length >= 5 &&
            state.phase == ReportPhase.measuring) {
          state = state.copyWith(phase: ReportPhase.stabilizing);
          _startStabilizationCountdown();
        }
      },
      onError: (e) {
        state = state.copyWith(
          phase: ReportPhase.error,
          errorMessage: '마이크 접근 오류: $e',
        );
        _stopMeasurement();
      },
    );
  }

  void _startStabilizationCountdown() {
    _stabilizeTimer?.cancel();
    _stabilizeTimer = Timer(const Duration(seconds: 3), () {
      final filtered = NoiseFilter.filterOutliers(List.from(_recentReadings));
      if (filtered.isEmpty) return;

      final stable = filtered.reduce((a, b) => a + b) / filtered.length;

      // Audio stream torn down — all voice data volatilised
      _stopMeasurement();

      state = state.copyWith(
        stableDb: stable,
        phase: ReportPhase.stickerSelection,
      );
    });
  }

  /// Public stop — cancels measurement and returns to idle.
  void stopMeasurement() {
    _stopMeasurement();
    state = state.copyWith(phase: ReportPhase.idle, elapsedSeconds: 0);
  }

  void _stopMeasurement() {
    _elapsedTimer?.cancel();
    _elapsedTimer = null;
    _sub?.cancel();
    _sub = null;
    _meter = null; // NoiseMeter released — no audio file ever created
    _recentReadings.clear();
    _stabilizeTimer?.cancel();
    // Cancel GPS collection stream + timer (keep _bestGpsPosition for submit)
    _gpsCollectionTimer?.cancel();
    _gpsCollectionTimer = null;
    _gpsSub?.cancel();
    _gpsSub = null;
    _gpsSamples.clear();
  }

  /// Focused 3-second GPS sampling at measurement start.
  /// Collects all incoming position fixes into [_gpsSamples], then after
  /// [_gpsCollectionDuration] resolves to the best quality sample.
  ///
  /// Selection priority:
  ///   1. Samples with accuracy ≤ [_gpsAccuracyThresholdM] — pick lowest accuracy
  ///   2. If none qualify, use the best unfiltered sample (graceful fallback)
  void _startGpsSampling() {
    _gpsSub?.cancel();
    _gpsCollectionTimer?.cancel();
    _bestGpsPosition = null;
    _gpsSamples.clear();

    Geolocator.checkPermission().then((permission) {
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      _gpsSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 0,
        ),
      ).listen((pos) {
        _gpsSamples.add(pos);
      });

      // After 3 seconds, stop stream and resolve best position
      _gpsCollectionTimer = Timer(_gpsCollectionDuration, _resolveGpsPosition);
    });
  }

  /// Called after the 3-second collection window ends.
  /// Picks the best GPS sample, preferring high-accuracy fixes.
  void _resolveGpsPosition() {
    _gpsSub?.cancel();
    _gpsSub = null;
    _gpsCollectionTimer = null;

    if (_gpsSamples.isEmpty) {
      // No samples — _bestGpsPosition stays null
      // verifyProximity will fall back to a fresh getCurrentPosition() call
      return;
    }

    // Prefer samples within accuracy threshold (≤30m)
    final goodSamples = _gpsSamples
        .where((p) => p.accuracy <= _gpsAccuracyThresholdM)
        .toList();

    // Fall back to all samples if none meet the quality threshold
    final pool = goodSamples.isNotEmpty ? goodSamples : _gpsSamples;

    // Pick the sample with lowest (best) accuracy value
    pool.sort((a, b) => a.accuracy.compareTo(b.accuracy));
    _bestGpsPosition = pool.first;

    assert(() {
      final quality = goodSamples.isNotEmpty ? '정밀' : '저정밀(fallback)';
      // ignore: avoid_print
      print('[GPS] 수집=${_gpsSamples.length}개 '
          '정밀샘플=${goodSamples.length}개 '
          '선택=${_bestGpsPosition!.accuracy.toStringAsFixed(1)}m '
          '품질=$quality');
      return true;
    }());

    _gpsSamples.clear();
  }

  Future<bool> verifyProximity() async {
    // Admin dummy mode: skip proximity gate entirely
    if (ref.read(adminDummyModeProvider).asData?.value == true) return true;

    // New spot (no spotId): no proximity gate — location is captured from GPS at submit
    if (_spotId.isEmpty) return true;

    // Existing spot: if coordinates missing (route bug), block as safety net
    if (_spotLat == null || _spotLng == null) {
      assert(false, 'verifyProximity: spotId=$_spotId but _spotLat=$_spotLat _spotLng=$_spotLng');
      return false;
    }

    try {
      // Use resolved GPS sample; fall back to a fresh fix if sampling hasn't
      // completed yet (e.g., called before the 3s window expires at start button)
      final pos = _bestGpsPosition ?? await LocationService.getCurrentPosition();
      final dist = LocationService.distanceMeters(
        userLat: pos.latitude,
        userLng: pos.longitude,
        targetLat: _spotLat!,
        targetLng: _spotLng!,
      );
      final isNear = dist <= MapConstants.reportMaxDistanceMeters;
      assert(() {
        // ignore: avoid_print
        print('[ReportController] 거리=${dist.toStringAsFixed(1)}m '
            '한도=${MapConstants.reportMaxDistanceMeters}m '
            'accuracy=${pos.accuracy.toStringAsFixed(1)}m '
            'cached=${_bestGpsPosition != null} '
            'isNear=$isNear');
        return true;
      }());
      return isNear;
    } catch (e) {
      assert(() {
        // ignore: avoid_print
        print('[ReportController] verifyProximity GPS 오류: $e → block');
        return true;
      }());
      return false;
    }
  }

  Future<void> submitWithSticker(
    StickerType? sticker, {
    String? tagText,
    String? moodTag,
  }) async {
    state = state.copyWith(
      selectedSticker: sticker,
      phase: ReportPhase.submitting,
    );

    try {
      var spotId = _spotId;

      // New spot: use stored coordinates (from search) or best GPS sample
      if (spotId.isEmpty) {
        final double lat, lng;
        if (_spotLat != null && _spotLng != null) {
          lat = _spotLat!;
          lng = _spotLng!;
        } else {
          final pos = _bestGpsPosition ?? await LocationService.getCurrentPosition();
          lat = pos.latitude;
          lng = pos.longitude;
        }
        final name = _spotName.trim().isEmpty ? '내 스팟' : _spotName.trim();
        spotId = await ref.read(spotsRepositoryProvider).createSpot(
          name: name,
          googlePlaceId: _googlePlaceId,
          lat: lat,
          lng: lng,
        );
      }

      await ref.read(reportRepositoryProvider).submitReport(
            spotId: spotId,
            measuredDb: state.stableDb,
            sticker: sticker,
            tagText: tagText,
            moodTag: moodTag,
          );
      state = state.copyWith(phase: ReportPhase.done);
      ReviewService.requestIfEligible().catchError((_) {});
    } catch (e) {
      state = state.copyWith(
        phase: ReportPhase.error,
        errorMessage: e.toString(),
      );
    }
  }
}

final reportControllerProvider =
    NotifierProvider<ReportController, ReportState>(
  ReportController.new,
);
