/// Client-side Korean content filter for user-generated text.
/// Blocks common profanity, sexual expressions, and abbreviations (초성 포함).
/// Used before storing public-facing fields (memo, tag).
abstract class ContentFilter {
  // ── 욕설 & 비속어 ──────────────────────────────────────────
  static const _profanity = [
    '씨발', '씨팔', '시발', '시팔', '쉬발', '쉬팔',
    '개새끼', '개새', '새끼', '새기',
    '병신', '븅신', '빙신',
    '지랄', '지럴', '짜증나', '존나', '졸라', '개같', '개소리',
    '미친', '미쳤', '꺼져', '닥쳐', '닥치',
    '개년', '창녀', '걸레', '보지', '자지', '좆', '씹',
    'ㅅㅂ', 'ㅆㅂ', 'ㅂㅅ', 'ㅈㄹ', 'ㄱㅅㄲ', 'ㅅㄲ',
    'ㅗ', 'ㅗㅗ',
  ];

  // ── 성적 표현 ──────────────────────────────────────────────
  static const _sexual = [
    '섹스', '섹시', '야동', '야설', '포르노', '음란',
    '자위', '오르가', '성기', '유두', '가슴', '엉덩이',
    '페니스', '질', '항문', '정액', '사정',
    '강간', '성폭', '성추행', '몰카', '불법촬영',
  ];

  static final _allTerms = [..._profanity, ..._sexual];

  /// Returns `true` if [text] contains any blocked term.
  /// Normalises whitespace and checks case-insensitively.
  static bool contains(String text) {
    final normalised = text.replaceAll(RegExp(r'\s+'), '').toLowerCase();
    return _allTerms.any((term) => normalised.contains(term.toLowerCase()));
  }

  /// Returns a user-facing error message if the text is blocked, otherwise null.
  static String? validate(String text) {
    if (text.trim().isEmpty) return null;
    if (contains(text)) return '부적절한 표현이 포함되어 있습니다.';
    return null;
  }
}
