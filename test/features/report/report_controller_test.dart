import 'package:flutter_test/flutter_test.dart';
import 'package:cafe_vibe/features/report/presentation/report_controller.dart';
import 'package:cafe_vibe/features/map/domain/spot_model.dart';

void main() {
  group('ReportState — 기본값 및 copyWith', () {
    test('기본 상태 값 확인', () {
      const state = ReportState();
      expect(state.currentDb, 0.0);
      expect(state.stableDb, 0.0);
      expect(state.phase, ReportPhase.measuring);
      expect(state.selectedSticker, isNull);
      expect(state.errorMessage, isNull);
    });

    test('copyWith — currentDb만 변경, 나머지 유지', () {
      const state = ReportState();
      final updated = state.copyWith(currentDb: 65.5);
      expect(updated.currentDb, 65.5);
      expect(updated.stableDb, 0.0);
      expect(updated.phase, ReportPhase.measuring);
      expect(updated.selectedSticker, isNull);
    });

    test('copyWith — phase measuring → stabilizing', () {
      const state = ReportState();
      final stabilizing = state.copyWith(phase: ReportPhase.stabilizing);
      expect(stabilizing.phase, ReportPhase.stabilizing);
      expect(stabilizing.currentDb, 0.0); // 변경 안 됨
    });

    test('copyWith — stableDb + stickerSelection 단계 전환', () {
      const state = ReportState(phase: ReportPhase.stabilizing, currentDb: 52.0);
      final ready = state.copyWith(
        stableDb: 52.0,
        phase: ReportPhase.stickerSelection,
      );
      expect(ready.stableDb, 52.0);
      expect(ready.phase, ReportPhase.stickerSelection);
      expect(ready.currentDb, 52.0); // 유지
    });

    test('copyWith — submitting 단계: selectedSticker 포함', () {
      const state = ReportState(
        stableDb: 45.0,
        phase: ReportPhase.stickerSelection,
      );
      final submitting = state.copyWith(
        selectedSticker: StickerType.study,
        phase: ReportPhase.submitting,
      );
      expect(submitting.selectedSticker, StickerType.study);
      expect(submitting.phase, ReportPhase.submitting);
      expect(submitting.stableDb, 45.0); // 유지
    });

    test('copyWith — done 단계', () {
      const state = ReportState(
        phase: ReportPhase.submitting,
        stableDb: 48.3,
        selectedSticker: StickerType.relax,
      );
      final done = state.copyWith(phase: ReportPhase.done);
      expect(done.phase, ReportPhase.done);
      expect(done.selectedSticker, StickerType.relax); // 유지
      expect(done.stableDb, 48.3); // 유지
    });

    test('copyWith — error 설정', () {
      const state = ReportState(phase: ReportPhase.submitting);
      final errored = state.copyWith(
        phase: ReportPhase.error,
        errorMessage: 'Supabase 연결 실패',
      );
      expect(errored.phase, ReportPhase.error);
      expect(errored.errorMessage, 'Supabase 연결 실패');
    });

    test('copyWith — clearError 플래그로 errorMessage null 처리', () {
      final state = ReportState(
        phase: ReportPhase.error,
        errorMessage: '마이크 접근 오류',
      );
      final recovered = state.copyWith(
        clearError: true,
        phase: ReportPhase.measuring,
      );
      expect(recovered.errorMessage, isNull);
      expect(recovered.phase, ReportPhase.measuring);
    });

    test('copyWith — clearError=false면 기존 errorMessage 유지', () {
      final state = ReportState(
        phase: ReportPhase.error,
        errorMessage: '기존 오류',
      );
      final unchanged = state.copyWith(currentDb: 60.0);
      expect(unchanged.errorMessage, '기존 오류'); // clearError=false (기본값)
    });

    test('여러 필드 동시 변경', () {
      const state = ReportState();
      final updated = state.copyWith(
        currentDb: 72.0,
        stableDb: 68.5,
        phase: ReportPhase.stickerSelection,
        selectedSticker: StickerType.meeting,
      );
      expect(updated.currentDb, 72.0);
      expect(updated.stableDb, 68.5);
      expect(updated.phase, ReportPhase.stickerSelection);
      expect(updated.selectedSticker, StickerType.meeting);
      expect(updated.errorMessage, isNull);
    });
  });

  group('ReportPhase 열거형 — 6개 단계', () {
    test('모든 단계가 순서대로 정의됐다', () {
      expect(ReportPhase.values.length, 6);
      expect(ReportPhase.values, containsAll([
        ReportPhase.measuring,
        ReportPhase.stabilizing,
        ReportPhase.stickerSelection,
        ReportPhase.submitting,
        ReportPhase.done,
        ReportPhase.error,
      ]));
    });

    test('measuring이 첫 번째 단계다', () {
      expect(ReportPhase.values.first, ReportPhase.measuring);
    });
  });

  group('dB 측정값 범위 검증 (ReportState 관점)', () {
    test('유효 범위 내 dB (0–119.9) 상태 업데이트', () {
      const state = ReportState();
      for (final db in [0.0, 30.0, 55.0, 70.0, 85.0, 119.9]) {
        final updated = state.copyWith(currentDb: db);
        expect(updated.currentDb, db);
      }
    });

    test('stableDb는 평균값이므로 소수점 정밀도 유지', () {
      const state = ReportState();
      final updated = state.copyWith(stableDb: 48.333333);
      expect(updated.stableDb, closeTo(48.333333, 0.000001));
    });
  });
}
