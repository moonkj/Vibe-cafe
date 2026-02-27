import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/constants/map_constants.dart';
import '../domain/spot_model.dart';

class SpotsRepository {
  final SupabaseClient _client;
  SpotsRepository(this._client);

  /// Fetch spots within [radiusMeters] of [lat]/[lng] using PostGIS RPC.
  /// Optionally filter by [sticker] type.
  /// Results exclude spots inactive for 30+ days.
  Future<List<SpotModel>> getSpotsNear({
    required double lat,
    required double lng,
    double radiusMeters = MapConstants.defaultRadiusMeters,
    StickerType? sticker,
  }) async {
    final clampedRadius = radiusMeters.clamp(0, MapConstants.maxRadiusMeters);

    final response = await _client.rpc(
      'get_spots_near',
      params: {
        'user_lat': lat,
        'user_lng': lng,
        'radius_meters': clampedRadius,
        if (sticker != null) 'filter_sticker': sticker.key,
      },
    );

    final data = response as List<dynamic>;
    return data
        .map((e) => SpotModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Look up a spot by google_place_id. Returns null if not found.
  /// Note: lat/lng not available from direct table query — use get_spots_near RPC.
  Future<bool> spotExistsByPlaceId(String placeId) async {
    final response = await _client
        .from('spots')
        .select('id')
        .eq('google_place_id', placeId)
        .maybeSingle();
    return response != null;
  }

  /// Create a new spot (called once per new location during first report).
  Future<String> createSpot({
    required String name,
    required String? googlePlaceId,
    required double lat,
    required double lng,
  }) async {
    final response = await _client
        .from('spots')
        .insert({
          'name': name,
          // ignore: use_null_aware_elements
          if (googlePlaceId != null) 'google_place_id': googlePlaceId,
          'location': 'POINT($lng $lat)',
          'average_db': 0,
          'report_count': 0,
          'trust_score': 0,
        })
        .select('id')
        .single();

    return response['id'] as String;
  }
}

final spotsRepositoryProvider = Provider<SpotsRepository>(
  (ref) => SpotsRepository(ref.watch(supabaseClientProvider)),
);
