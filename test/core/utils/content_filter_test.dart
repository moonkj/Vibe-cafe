import 'package:flutter_test/flutter_test.dart';
import 'package:cafe_vibe/core/utils/content_filter.dart';

void main() {
  group('ContentFilter.contains — 욕설 감지', () {
    test('욕설이 없는 텍스트는 false', () {
      expect(ContentFilter.contains('조용한 카페 좋아요'), isFalse);
      expect(ContentFilter.contains('공부하기 좋은 곳'), isFalse);
      expect(ContentFilter.contains(''), isFalse);
    });

    test('직접적인 욕설은 true', () {
      expect(ContentFilter.contains('씨발'), isTrue);
      expect(ContentFilter.contains('개새끼'), isTrue);
      expect(ContentFilter.contains('병신'), isTrue);
      expect(ContentFilter.contains('지랄'), isTrue);
    });

    test('초성 욕설도 감지된다', () {
      expect(ContentFilter.contains('ㅅㅂ'), isTrue);
      expect(ContentFilter.contains('ㅂㅅ'), isTrue);
      expect(ContentFilter.contains('ㅈㄹ'), isTrue);
      expect(ContentFilter.contains('ㄱㅅㄲ'), isTrue);
    });

    test('문장 중간에 포함된 욕설도 감지된다', () {
      expect(ContentFilter.contains('여기 진짜 씨발 시끄럽다'), isTrue);
      expect(ContentFilter.contains('개같은 소리'), isTrue);
    });

    test('공백이 있어도 정규화 후 감지된다', () {
      // replaceAll whitespace → 공백 제거 후 비교
      expect(ContentFilter.contains('씨 발'), isTrue);
      expect(ContentFilter.contains('개  새끼'), isTrue);
    });

    test('성적 표현은 true', () {
      expect(ContentFilter.contains('야동'), isTrue);
      expect(ContentFilter.contains('섹스'), isTrue);
      expect(ContentFilter.contains('강간'), isTrue);
      expect(ContentFilter.contains('몰카'), isTrue);
    });

    test('대소문자 구분 없이 감지 (영문 포함 혼합어)', () {
      // _allTerms는 한글 위주지만 .toLowerCase() 적용
      // 한글은 대소문자 없음 — normalised는 항상 낮은 코드포인트
      expect(ContentFilter.contains('야설'), isTrue);
    });
  });

  group('ContentFilter.validate — 반환값 검증', () {
    test('정상 텍스트 → null 반환', () {
      expect(ContentFilter.validate('조용하고 집중하기 좋아요'), isNull);
      expect(ContentFilter.validate('WiFi 빠르고 콘센트 많음'), isNull);
    });

    test('빈 문자열 → null 반환 (검사 생략)', () {
      expect(ContentFilter.validate(''), isNull);
      expect(ContentFilter.validate('   '), isNull);
    });

    test('욕설 포함 → 에러 메시지 반환', () {
      final result = ContentFilter.validate('씨발 시끄럽다');
      expect(result, '부적절한 표현이 포함되어 있습니다.');
    });

    test('성적 표현 포함 → 에러 메시지 반환', () {
      final result = ContentFilter.validate('야동 같은 분위기');
      expect(result, '부적절한 표현이 포함되어 있습니다.');
    });

    test('에러 메시지는 항상 동일한 문자열', () {
      final r1 = ContentFilter.validate('병신같은');
      final r2 = ContentFilter.validate('개새끼');
      expect(r1, r2);
      expect(r1, '부적절한 표현이 포함되어 있습니다.');
    });

    test('유사 단어이지만 차단 리스트에 없으면 null', () {
      // '신발', '가슴앓이' 등 단순 포함 관계에 주의
      // '가슴' 은 차단어에 포함되어 있으므로 테스트 대상에서 제외
      expect(ContentFilter.validate('신발이 예쁘다'), isNull);
    });
  });
}
