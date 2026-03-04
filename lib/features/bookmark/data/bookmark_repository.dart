import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';
import '../../map/domain/spot_model.dart';

// ──────────────────────────────────────────────────────────────
// Repository
// ──────────────────────────────────────────────────────────────

class BookmarkRepository {
  const BookmarkRepository(this._client);
  final SupabaseClient _client;

  String get _userId {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw StateError('북마크 기능은 로그인이 필요합니다.');
    return uid;
  }

  /// 해당 spot이 북마크됐는지 확인
  Future<bool> isBookmarked(String spotId) async {
    final res = await _client
        .from('user_bookmarks')
        .select('id')
        .eq('user_id', _userId)
        .eq('spot_id', spotId)
        .maybeSingle();
    return res != null;
  }

  /// 북마크 토글 — 추가하면 true, 삭제하면 false 반환
  Future<bool> toggleBookmark(String spotId) async {
    final already = await isBookmarked(spotId);
    if (already) {
      await _client
          .from('user_bookmarks')
          .delete()
          .eq('user_id', _userId)
          .eq('spot_id', spotId);
      return false;
    } else {
      await _client.from('user_bookmarks').insert({
        'user_id': _userId,
        'spot_id': spotId,
      });
      return true;
    }
  }

  /// 내가 찜한 카페 목록 (최신 순)
  /// get_spots_by_ids RPC 사용 — ST_Y/ST_X로 정확한 lat/lng 반환
  /// (spots(*) 직접 join은 location 컬럼이 WKB hex로 반환돼 lat/lng = 0,0 버그 발생)
  Future<List<SpotModel>> getMyBookmarks() async {
    // 1단계: 내 북마크 spot_id 목록 조회 (최신순)
    final bookmarkRes = await _client
        .from('user_bookmarks')
        .select('spot_id')
        .eq('user_id', _userId)
        .order('created_at', ascending: false)
        .timeout(const Duration(seconds: 10));

    final ids = (bookmarkRes as List<dynamic>)
        .map((e) => e['spot_id'] as String?)
        .whereType<String>()
        .toList();

    if (ids.isEmpty) return [];

    // 2단계: get_spots_by_ids RPC로 정확한 위경도 포함 스팟 정보 조회
    final spotRes = await _client.rpc(
      'get_spots_by_ids',
      params: {'p_ids': ids},
    ).timeout(const Duration(seconds: 10));

    final spotsById = <String, SpotModel>{};
    for (final e in (spotRes as List<dynamic>)) {
      final spot = SpotModel.fromJson(e as Map<String, dynamic>);
      spotsById[spot.id] = spot;
    }

    // 북마크 순서 유지
    return ids.map((id) => spotsById[id]).whereType<SpotModel>().toList();
  }
}

final bookmarkRepositoryProvider = Provider<BookmarkRepository>((ref) {
  return BookmarkRepository(ref.read(supabaseClientProvider));
});

// ──────────────────────────────────────────────────────────────
// Providers
// ──────────────────────────────────────────────────────────────

/// 단일 spot 북마크 초기값 (SpotDetailScreen — 실제 토글은 위젯에서 처리)
final isBookmarkedProvider =
    FutureProvider.autoDispose.family<bool, String>((ref, spotId) {
  return ref.read(bookmarkRepositoryProvider).isBookmarked(spotId);
});

/// 내가 찜한 카페 목록 (ProfileScreen용)
final bookmarkedSpotsProvider =
    FutureProvider.autoDispose<List<SpotModel>>((ref) {
  return ref.read(bookmarkRepositoryProvider).getMyBookmarks();
});
