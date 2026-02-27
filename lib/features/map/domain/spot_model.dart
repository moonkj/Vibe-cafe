import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/map_constants.dart';

enum StickerType { study, meeting, relax }

extension StickerTypeX on StickerType {
  String get key => switch (this) {
        StickerType.study => 'STUDY',
        StickerType.meeting => 'MEETING',
        StickerType.relax => 'RELAX',
      };

  String get label => switch (this) {
        StickerType.study => '집중하기 좋아요',
        StickerType.meeting => '화상회의 가능해요',
        StickerType.relax => '쉬기 좋아요',
      };

  String get emoji => switch (this) {
        StickerType.study => '📚',
        StickerType.meeting => '📹',
        StickerType.relax => '🌿',
      };

  static StickerType fromKey(String key) => switch (key.toUpperCase()) {
        'STUDY' => StickerType.study,
        'MEETING' => StickerType.meeting,
        _ => StickerType.relax,
      };
}

class SpotModel {
  final String id;
  final String name;
  final String? googlePlaceId;
  final double lat;
  final double lng;
  final double averageDb;
  final StickerType? representativeSticker;
  final int reportCount;
  final double trustScore;
  final int recent24hCount;
  final DateTime? lastReportAt;

  const SpotModel({
    required this.id,
    required this.name,
    this.googlePlaceId,
    required this.lat,
    required this.lng,
    required this.averageDb,
    this.representativeSticker,
    required this.reportCount,
    required this.trustScore,
    required this.recent24hCount,
    this.lastReportAt,
  });

  factory SpotModel.fromJson(Map<String, dynamic> json) {
    return SpotModel(
      id: json['id'] as String,
      name: json['name'] as String,
      googlePlaceId: json['google_place_id'] as String?,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      averageDb: (json['average_db'] as num).toDouble(),
      representativeSticker: json['representative_sticker'] != null
          ? StickerTypeX.fromKey(json['representative_sticker'] as String)
          : null,
      reportCount: (json['report_count'] as num).toInt(),
      trustScore: (json['trust_score'] as num).toDouble(),
      recent24hCount: (json['recent_24h_count'] as num? ?? 0).toInt(),
      lastReportAt: json['last_report_at'] != null
          ? DateTime.parse(json['last_report_at'] as String)
          : null,
    );
  }

  /// True if the spot has not been reported for [MapConstants.spotFadeAfterDays] days.
  bool get isStale {
    if (lastReportAt == null) return true;
    return DateTime.now().difference(lastReportAt!).inDays >=
        MapConstants.spotFadeAfterDays;
  }

  /// Opacity: 1.0 for active spots, 0.4 for stale ones.
  double get markerOpacity => isStale ? 0.4 : 1.0;

  Color get markerColor => AppColors.dbColor(averageDb);

  /// Border width based on trust score (gamification)
  double get markerBorderWidth => switch (trustScore) {
        >= 3 => 3.5,
        >= 2 => 2.5,
        >= 1 => 1.5,
        _ => 0.5,
      };
}
