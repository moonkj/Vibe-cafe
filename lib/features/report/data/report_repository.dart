import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';
import '../../map/domain/spot_model.dart';
import '../domain/report_model.dart';

class ReportRepository {
  final SupabaseClient _client;
  ReportRepository(this._client);

  /// Submit a noise report.
  /// - Saves report row (no audio — only dB number)
  /// - Calls update_spot_after_report RPC to apply EMA avg update
  /// - Awards XP: +10 (1일 1회 제한) + +5 bonus (처음 가본 카페)
  Future<void> submitReport({
    required String spotId,
    required double measuredDb,
    required StickerType? sticker,
    String? tagText,
    String? moodTag,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('로그인이 필요합니다.');

    // Validate dB range (120dB+ rejected)
    if (measuredDb >= 120 || measuredDb < 0 || !measuredDb.isFinite) {
      throw Exception('유효하지 않은 dB 값입니다.');
    }

    // XP check 1: 1일 1회 제한 — has user already submitted a report today?
    final todayStart = DateTime.now().toUtc().copyWith(
      hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0,
    ).toIso8601String();
    final todayResp = await _client
        .from('reports')
        .select('id')
        .eq('user_id', userId)
        .gte('created_at', todayStart)
        .limit(1);
    final hasReportedToday = (todayResp as List).isNotEmpty;

    // XP check 2: first time at this cafe?
    final prevResp = await _client
        .from('reports')
        .select('id')
        .eq('user_id', userId)
        .eq('spot_id', spotId)
        .limit(1);
    final isNewCafe = (prevResp as List).isEmpty;

    // Insert report (DB: only the number, no audio)
    await _client.from('reports').insert({
      'user_id': userId,
      'spot_id': spotId,
      'measured_db': measuredDb,
      if (sticker != null) 'selected_sticker': sticker.key,
      if (tagText != null && tagText.isNotEmpty) 'tag_text': tagText,
      if (moodTag != null && moodTag.isNotEmpty) 'mood_tag': moodTag,
    });

    // Update spot EMA average via RPC
    await _client.rpc('update_spot_after_report', params: {
      'p_spot_id': spotId,
      'p_new_db': measuredDb,
      'p_sticker': sticker?.key,
      'p_user_id': userId,
    });

    // Update aggregated user stats (total_reports, total_cafes)
    try {
      await _client.rpc('update_user_stats', params: {'p_user_id': userId});
    } catch (_) {}

    // Award XP
    final xpEarned = (hasReportedToday ? 0 : 10) + (isNewCafe ? 5 : 0);
    if (xpEarned > 0) {
      try {
        await _client.rpc('award_xp', params: {
          'p_user_id': userId,
          'p_xp': xpEarned,
        });
      } catch (_) {}
    }
  }

  /// Fetch user's own reports, newest first.
  Future<List<ReportModel>> getMyReports({int limit = 50}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from('reports')
        .select('*, spots(name, formatted_address)')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit);

    return (response as List)
        .map((e) => ReportModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get stats for the current user.
  /// Returns: total, avg_db, total_cafes, has_quiet_cafe, total_xp
  Future<Map<String, dynamic>> getMyStats() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return {};

    final data = await _client
        .from('reports')
        .select('measured_db, spot_id, spots(average_db)')
        .eq('user_id', userId) as List;

    final xpRow = await _client
        .from('user_stats')
        .select('total_xp')
        .eq('user_id', userId)
        .maybeSingle();
    final totalXp = (xpRow?['total_xp'] as int?) ?? 0;

    if (data.isEmpty) {
      return {
        'total': 0,
        'avg_db': 0.0,
        'total_cafes': 0,
        'has_quiet_cafe': false,
        'total_xp': totalXp,
      };
    }

    final total = data.length;
    final avgDb = data
            .map((e) => (e['measured_db'] as num).toDouble())
            .reduce((a, b) => a + b) /
        total;

    final spotIds = data.map((e) => e['spot_id'] as String).toSet();
    final totalCafes = spotIds.length;

    final hasQuietCafe = data.any((e) {
      final spotData = e['spots'] as Map<String, dynamic>?;
      if (spotData == null) return false;
      final avgSpotDb = (spotData['average_db'] as num?)?.toDouble() ?? 100.0;
      return avgSpotDb < 50;
    });

    return {
      'total': total,
      'avg_db': avgDb,
      'total_cafes': totalCafes,
      'has_quiet_cafe': hasQuietCafe,
      'total_xp': totalXp,
    };
  }

  /// Fetch recent reports for a spot with user nicknames.
  /// Uses 2 queries to avoid N+1: reports → user_profiles nickname merge.
  Future<List<Map<String, dynamic>>> getSpotRecentReports(
    String spotId, {
    int limit = 10,
  }) async {
    final reportsResp = await _client
        .from('reports')
        .select('measured_db, selected_sticker, created_at, user_id, mood_tag, tag_text')
        .eq('spot_id', spotId)
        .order('created_at', ascending: false)
        .limit(limit);

    final reports = (reportsResp as List).cast<Map<String, dynamic>>();
    if (reports.isEmpty) return [];

    final userIds =
        reports.map((r) => r['user_id'] as String).toSet().toList();
    final profilesResp = await _client
        .from('user_profiles')
        .select('user_id, nickname')
        .inFilter('user_id', userIds);

    final nickMap = {
      for (final p in (profilesResp as List).cast<Map<String, dynamic>>())
        p['user_id'] as String: p['nickname'] as String?,
    };

    return reports
        .map((r) => {
              ...r,
              'nickname': nickMap[r['user_id'] as String] ?? '익명',
            })
        .toList();
  }

  /// Returns the nickname of the first person who measured this spot.
  /// Returns null if no reports exist.
  Future<String?> getFirstReporterNickname(String spotId) async {
    final reportResp = await _client
        .from('reports')
        .select('user_id')
        .eq('spot_id', spotId)
        .order('created_at', ascending: true)
        .limit(1)
        .maybeSingle();

    if (reportResp == null) return null;
    final userId = reportResp['user_id'] as String?;
    if (userId == null) return null;

    final profileResp = await _client
        .from('user_profiles')
        .select('nickname')
        .eq('user_id', userId)
        .maybeSingle();

    return profileResp?['nickname'] as String? ?? '익명';
  }

  /// Fetch hourly average dB for a spot over the past 30 days.
  /// Aggregated client-side by hour-of-day.
  Future<List<(int hour, double avgDb)>> getSpotHourlyNoise(
      String spotId) async {
    final since = DateTime.now()
        .subtract(const Duration(days: 30))
        .toIso8601String();
    final response = await _client
        .from('reports')
        .select('measured_db, created_at')
        .eq('spot_id', spotId)
        .gte('created_at', since);

    final data = (response as List).cast<Map<String, dynamic>>();
    final Map<int, List<double>> byHour = {};
    for (final row in data) {
      final hour =
          DateTime.parse(row['created_at'] as String).toLocal().hour;
      byHour
          .putIfAbsent(hour, () => [])
          .add((row['measured_db'] as num).toDouble());
    }
    return byHour.entries
        .map((e) =>
            (e.key, e.value.reduce((a, b) => a + b) / e.value.length))
        .toList()
      ..sort((a, b) => a.$1.compareTo(b.$1));
  }
}

final reportRepositoryProvider = Provider<ReportRepository>(
  (ref) => ReportRepository(ref.watch(supabaseClientProvider)),
);
