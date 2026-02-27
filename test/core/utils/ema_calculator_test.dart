import 'package:flutter_test/flutter_test.dart';
import 'package:noise_spot/core/utils/ema_calculator.dart';

void main() {
  group('EmaCalculator', () {
    test('첫 번째 리포트는 newDb를 그대로 반환한다', () {
      final result = EmaCalculator.calculate(
        oldAvg: 0,
        newDb: 55.0,
        reportCount: 0,
      );
      expect(result, 55.0);
    });

    test('EMA 공식: (old × 0.7) + (new × 0.3)', () {
      final result = EmaCalculator.calculate(
        oldAvg: 60.0,
        newDb: 40.0,
        reportCount: 5,
      );
      // (60 × 0.7) + (40 × 0.3) = 42 + 12 = 54
      expect(result, closeTo(54.0, 0.001));
    });

    test('동일한 값이 계속 들어오면 수렴한다', () {
      double avg = 70.0;
      for (int i = 1; i <= 20; i++) {
        avg = EmaCalculator.calculate(oldAvg: avg, newDb: 50.0, reportCount: i);
      }
      // 50dB로 수렴해야 한다
      expect(avg, closeTo(50.0, 1.0));
    });

    test('reportCount=1도 EMA를 적용한다', () {
      final result = EmaCalculator.calculate(
        oldAvg: 80.0,
        newDb: 50.0,
        reportCount: 1,
      );
      // (80 × 0.7) + (50 × 0.3) = 56 + 15 = 71
      expect(result, closeTo(71.0, 0.001));
    });

    test('극단값 — 0dB 신규 리포트', () {
      final result = EmaCalculator.calculate(
        oldAvg: 100.0,
        newDb: 0.0,
        reportCount: 3,
      );
      // (100 × 0.7) + (0 × 0.3) = 70
      expect(result, closeTo(70.0, 0.001));
    });
  });
}
