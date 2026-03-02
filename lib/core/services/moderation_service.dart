import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/content_filter.dart';

/// Calls Google Cloud Natural Language Moderate Text API.
///
/// Key is injected at build time via:
///   --dart-define=GOOGLE_MODERATION_KEY=YOUR_KEY
///
/// Two-layer strategy:
///   1. Local blocklist (ContentFilter) — instant, no network
///   2. Google NL API — catches non-obvious Korean text on submit
abstract class ModerationService {
  static const _apiKey =
      String.fromEnvironment('GOOGLE_MODERATION_KEY', defaultValue: '');

  static const _endpoint =
      'https://language.googleapis.com/v1/documents:moderateText';

  /// Categories that trigger a block (confidence >= threshold)
  static const _blockedCategories = {
    'Toxic',
    'Insult',
    'Profanity',
    'Derogatory',
    'Sexually Explicit',
  };

  static const double _threshold = 0.5;

  /// Returns null if text is acceptable, or an error message if blocked.
  ///
  /// - Always runs local filter first (fast path).
  /// - If API key is configured, calls Google NL as a second pass.
  /// - Network errors are treated as "allow" so users aren't blocked by flaky connectivity.
  static Future<String?> validate(String text) async {
    if (text.trim().isEmpty) return null;

    // Layer 1: local blocklist (instant)
    final localError = ContentFilter.validate(text);
    if (localError != null) return localError;

    // Layer 2: Google Cloud NL (skip if no key)
    if (_apiKey.isEmpty) return null;

    try {
      final response = await http
          .post(
            Uri.parse('$_endpoint?key=$_apiKey'),
            headers: {'Content-Type': 'application/json; charset=utf-8'},
            body: jsonEncode({
              'document': {
                'type': 'PLAIN_TEXT',
                'language': 'ko',
                'content': text,
              },
            }),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) return null; // API error → allow

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final categories =
          (data['moderationCategories'] as List? ?? [])
              .cast<Map<String, dynamic>>();

      for (final cat in categories) {
        final name = cat['name'] as String? ?? '';
        final confidence = (cat['confidence'] as num?)?.toDouble() ?? 0.0;
        if (_blockedCategories.contains(name) && confidence >= _threshold) {
          return '부적절한 표현이 포함되어 있습니다.';
        }
      }
      return null;
    } catch (_) {
      return null; // network / parse error → allow
    }
  }
}
