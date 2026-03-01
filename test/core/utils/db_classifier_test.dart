import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cafe_vibe/core/utils/db_classifier.dart';

void main() {
  group('DbClassifier.colorFromDb', () {
    test('40dB 미만 → Mint Green (매우 조용)', () {
      final color = DbClassifier.colorFromDb(30.0);
      expect(color, const Color(0xFF5BC8AC));
    });

    test('40~55dB → Sky Blue (조용)', () {
      expect(DbClassifier.colorFromDb(40.0), const Color(0xFF78C5E8));
      expect(DbClassifier.colorFromDb(54.9), const Color(0xFF78C5E8));
    });

    test('55~70dB → Yellow (보통)', () {
      expect(DbClassifier.colorFromDb(55.0), const Color(0xFFF5C842));
      expect(DbClassifier.colorFromDb(69.9), const Color(0xFFF5C842));
    });

    test('70~85dB → Orange (시끄러움)', () {
      expect(DbClassifier.colorFromDb(70.0), const Color(0xFFFF9A3C));
      expect(DbClassifier.colorFromDb(84.9), const Color(0xFFFF9A3C));
    });

    test('85dB 이상 → Red (매우 시끄러움)', () {
      expect(DbClassifier.colorFromDb(85.0), const Color(0xFFE05C5C));
      expect(DbClassifier.colorFromDb(110.0), const Color(0xFFE05C5C));
    });
  });

  group('DbClassifier.labelFromDb', () {
    test('경계값 레이블 정확성', () {
      expect(DbClassifier.labelFromDb(0.0), '매우 조용');
      expect(DbClassifier.labelFromDb(39.9), '매우 조용');
      expect(DbClassifier.labelFromDb(40.0), '조용함');
      expect(DbClassifier.labelFromDb(55.0), '보통');
      expect(DbClassifier.labelFromDb(70.0), '시끄러움');
      expect(DbClassifier.labelFromDb(85.0), '매우 시끄러움');
    });
  });

  group('DbClassifier.formatDb', () {
    test('소수점 1자리로 포맷팅', () {
      expect(DbClassifier.formatDb(55.123), '55.1 dB');
      expect(DbClassifier.formatDb(100.0), '100.0 dB');
    });
  });
}
