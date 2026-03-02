import '../../map/domain/spot_model.dart';

class ReportModel {
  final String id;
  final String userId;
  final String spotId;
  final String? spotName;
  final String? spotAddress;
  final double measuredDb;
  final StickerType? selectedSticker;
  final String? tagText;
  final String? moodTag;
  final DateTime createdAt;

  const ReportModel({
    required this.id,
    required this.userId,
    required this.spotId,
    this.spotName,
    this.spotAddress,
    required this.measuredDb,
    this.selectedSticker,
    this.tagText,
    this.moodTag,
    required this.createdAt,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    final spots = json['spots'] as Map<String, dynamic>?;
    final stickerKey = json['selected_sticker'] as String?;
    return ReportModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      spotId: json['spot_id'] as String,
      spotName: spots?['name'] as String?,
      spotAddress: spots?['formatted_address'] as String?,
      measuredDb: (json['measured_db'] as num).toDouble(),
      selectedSticker:
          stickerKey != null ? StickerTypeX.fromKey(stickerKey) : null,
      tagText: json['tag_text'] as String?,
      moodTag: json['mood_tag'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
