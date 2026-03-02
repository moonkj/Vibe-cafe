import 'package:flutter_test/flutter_test.dart';
import 'package:cafe_vibe/features/report/domain/report_model.dart';
import 'package:cafe_vibe/features/map/domain/spot_model.dart';

// ──────────────────────────────────────────────────────────────
// Helpers
// ──────────────────────────────────────────────────────────────

Map<String, dynamic> _baseJson({
  String id = 'report-001',
  String userId = 'user-001',
  String spotId = 'spot-001',
  Map<String, dynamic>? spots,
  double measuredDb = 58.3,
  String? selectedSticker,
  String? tagText,
  String? moodTag,
  String createdAt = '2025-03-01T10:00:00.000Z',
}) =>
    {
      'id': id,
      'user_id': userId,
      'spot_id': spotId,
      'spots': spots,
      'measured_db': measuredDb,
      'selected_sticker': selectedSticker,
      'tag_text': tagText,
      'mood_tag': moodTag,
      'created_at': createdAt,
    };

void main() {
  // ── ReportModel.fromJson ──────────────────────────────────
  group('ReportModel.fromJson — 기본 파싱', () {
    test('필수 필드 파싱', () {
      final report = ReportModel.fromJson(_baseJson());
      expect(report.id, 'report-001');
      expect(report.userId, 'user-001');
      expect(report.spotId, 'spot-001');
      expect(report.measuredDb, 58.3);
      expect(report.createdAt.year, 2025);
      expect(report.createdAt.month, 3);
      expect(report.createdAt.day, 1);
    });

    test('선택적 필드 null 처리', () {
      final report = ReportModel.fromJson(_baseJson(
        spots: null,
        selectedSticker: null,
        tagText: null,
        moodTag: null,
      ));
      expect(report.spotName, isNull);
      expect(report.spotAddress, isNull);
      expect(report.selectedSticker, isNull);
      expect(report.tagText, isNull);
      expect(report.moodTag, isNull);
    });

    test('spots 조인 데이터 파싱 — name, formatted_address', () {
      final report = ReportModel.fromJson(_baseJson(
        spots: {
          'name': '스타벅스 종로점',
          'formatted_address': '서울 종로구 1번지',
        },
      ));
      expect(report.spotName, '스타벅스 종로점');
      expect(report.spotAddress, '서울 종로구 1번지');
    });

    test('selectedSticker — STUDY 파싱', () {
      final report = ReportModel.fromJson(_baseJson(selectedSticker: 'STUDY'));
      expect(report.selectedSticker, StickerType.study);
    });

    test('selectedSticker — MEETING 파싱', () {
      final report = ReportModel.fromJson(_baseJson(selectedSticker: 'MEETING'));
      expect(report.selectedSticker, StickerType.meeting);
    });

    test('selectedSticker — RELAX 파싱', () {
      final report = ReportModel.fromJson(_baseJson(selectedSticker: 'RELAX'));
      expect(report.selectedSticker, StickerType.relax);
    });

    test('measuredDb: int 형태 num도 double로 변환', () {
      final json = _baseJson();
      json['measured_db'] = 60; // int
      final report = ReportModel.fromJson(json);
      expect(report.measuredDb, 60.0);
      expect(report.measuredDb, isA<double>());
    });

    test('tagText 파싱', () {
      final report = ReportModel.fromJson(_baseJson(tagText: '창가 자리 좋음'));
      expect(report.tagText, '창가 자리 좋음');
    });

    test('moodTag 파싱', () {
      final report = ReportModel.fromJson(_baseJson(moodTag: 'calm'));
      expect(report.moodTag, 'calm');
    });

    test('createdAt — UTC ISO8601 파싱', () {
      final report = ReportModel.fromJson(
        _baseJson(createdAt: '2025-12-31T23:59:59.999Z'),
      );
      expect(report.createdAt.year, 2025);
      expect(report.createdAt.month, 12);
      expect(report.createdAt.day, 31);
    });
  });

  group('ReportModel.fromJson — 경계값', () {
    test('measuredDb=0.0 허용', () {
      final report = ReportModel.fromJson(_baseJson(measuredDb: 0.0));
      expect(report.measuredDb, 0.0);
    });

    test('measuredDb=119.9 허용', () {
      final report = ReportModel.fromJson(_baseJson(measuredDb: 119.9));
      expect(report.measuredDb, closeTo(119.9, 0.001));
    });

    test('measuredDb 소수점 정밀도 유지', () {
      final report = ReportModel.fromJson(_baseJson(measuredDb: 48.333333));
      expect(report.measuredDb, closeTo(48.333333, 0.000001));
    });
  });

  group('ReportModel — 상수 필드 확인', () {
    test('id, userId, spotId는 String', () {
      final report = ReportModel.fromJson(_baseJson());
      expect(report.id, isA<String>());
      expect(report.userId, isA<String>());
      expect(report.spotId, isA<String>());
    });

    test('createdAt은 DateTime', () {
      final report = ReportModel.fromJson(_baseJson());
      expect(report.createdAt, isA<DateTime>());
    });
  });
}
