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
  Future<void> submitReport({
    required String spotId,
    required double measuredDb,
    required StickerType sticker,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('로그인이 필요합니다.');

    // Validate dB range (120dB+ rejected)
    if (measuredDb >= 120 || measuredDb < 0 || !measuredDb.isFinite) {
      throw Exception('유효하지 않은 dB 값입니다.');
    }

    // Insert report (DB: only the number, no audio)
    await _client.from('reports').insert({
      'user_id': userId,
      'spot_id': spotId,
      'measured_db': measuredDb,
      'selected_sticker': sticker.key,
    });

    // Update spot EMA average via RPC
    await _client.rpc('update_spot_after_report', params: {
      'p_spot_id': spotId,
      'p_new_db': measuredDb,
      'p_sticker': sticker.key,
      'p_user_id': userId,
    });
  }

  /// Fetch user's own reports, newest first.
  Future<List<ReportModel>> getMyReports({int limit = 50}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from('reports')
        .select('*, spots(name)')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit);

    return (response as List)
        .map((e) => ReportModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get stats for the current user.
  Future<Map<String, dynamic>> getMyStats() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return {};

    final response = await _client
        .from('reports')
        .select('measured_db')
        .eq('user_id', userId);

    final data = response as List;
    if (data.isEmpty) return {'total': 0, 'avg_db': 0.0};

    final total = data.length;
    final avgDb = data
            .map((e) => (e['measured_db'] as num).toDouble())
            .reduce((a, b) => a + b) /
        total;

    return {'total': total, 'avg_db': avgDb};
  }
}

final reportRepositoryProvider = Provider<ReportRepository>(
  (ref) => ReportRepository(ref.watch(supabaseClientProvider)),
);
