import 'package:flutter_test/flutter_test.dart';
import 'package:noise_spot/features/map/presentation/map_controller.dart';
import 'package:noise_spot/features/map/domain/spot_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MapController.displayMode — 줌 레벨별 표시 모드', () {
    test('zoom 10.9 (11 미만) → hidden', () {
      expect(MapController.displayMode(10.9), SpotDisplayMode.hidden);
    });

    test('zoom 0 → hidden', () {
      expect(MapController.displayMode(0), SpotDisplayMode.hidden);
    });

    test('zoom 11.0 (경계 최소값) → heatmap', () {
      expect(MapController.displayMode(11.0), SpotDisplayMode.heatmap);
    });

    test('zoom 12.0 → heatmap', () {
      expect(MapController.displayMode(12.0), SpotDisplayMode.heatmap);
    });

    test('zoom 12.9 → heatmap', () {
      expect(MapController.displayMode(12.9), SpotDisplayMode.heatmap);
    });

    test('zoom 13.0 (경계) → reduced', () {
      expect(MapController.displayMode(13.0), SpotDisplayMode.reduced);
    });

    test('zoom 14.0 → reduced', () {
      expect(MapController.displayMode(14.0), SpotDisplayMode.reduced);
    });

    test('zoom 14.9 → reduced', () {
      expect(MapController.displayMode(14.9), SpotDisplayMode.reduced);
    });

    test('zoom 15.0 (경계) → individual', () {
      expect(MapController.displayMode(15.0), SpotDisplayMode.individual);
    });

    test('zoom 18.0 → individual', () {
      expect(MapController.displayMode(18.0), SpotDisplayMode.individual);
    });

    test('zoom 21.0 (최대치 초과) → individual', () {
      expect(MapController.displayMode(21.0), SpotDisplayMode.individual);
    });
  });

  group('SpotDisplayMode 열거형', () {
    test('4가지 모드가 모두 정의됐다', () {
      expect(SpotDisplayMode.values, containsAll([
        SpotDisplayMode.individual,
        SpotDisplayMode.reduced,
        SpotDisplayMode.heatmap,
        SpotDisplayMode.hidden,
      ]));
    });
  });

  group('MapState.copyWith', () {
    test('기본 상태 값 확인', () {
      const state = MapState();
      expect(state.spots, isEmpty);
      expect(state.activeFilter, isNull);
      expect(state.isLoading, isFalse);
      expect(state.userPosition, isNull);
      expect(state.error, isNull);
    });

    test('isLoading 변경', () {
      const state = MapState();
      final loading = state.copyWith(isLoading: true);
      expect(loading.isLoading, isTrue);
      expect(loading.spots, isEmpty); // 나머지 유지
    });

    test('error 설정 후 clearError', () {
      final withError = const MapState().copyWith(error: '네트워크 오류');
      expect(withError.error, '네트워크 오류');

      final cleared = withError.copyWith(clearError: true);
      expect(cleared.error, isNull);
    });

    test('clearFilter — activeFilter null로 초기화', () {
      final withFilter = const MapState().copyWith(
        activeFilter: StickerType.study,
      );
      expect(withFilter.activeFilter, StickerType.study);

      final cleared = withFilter.copyWith(clearFilter: true);
      expect(cleared.activeFilter, isNull);
    });

    test('동일 activeFilter로 setFilter 호출 시 토글 로직 확인 (clearFilter=true)', () {
      // 이미 study 필터 → clearFilter=true → null
      const state = MapState(activeFilter: StickerType.study);
      final toggled = state.copyWith(clearFilter: true);
      expect(toggled.activeFilter, isNull);
    });
  });
}
