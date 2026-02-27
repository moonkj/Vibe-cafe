import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';

class DbClassifier {
  DbClassifier._();

  static Color colorFromDb(double db) {
    if (db < 40) return AppColors.dbVeryQuiet;
    if (db < 55) return AppColors.dbQuiet;
    if (db < 70) return AppColors.dbModerate;
    if (db < 85) return AppColors.dbLoud;
    return AppColors.dbVeryLoud;
  }

  static String labelFromDb(double db) {
    if (db < 40) return AppStrings.dbVeryQuiet;
    if (db < 55) return AppStrings.dbQuiet;
    if (db < 70) return AppStrings.dbModerate;
    if (db < 85) return AppStrings.dbLoud;
    return AppStrings.dbVeryLoud;
  }

  static String formatDb(double db) => '${db.toStringAsFixed(1)} dB';

  /// Emoji icon representing quietness level
  static String emojiFromDb(double db) {
    if (db < 40) return '🍃';
    if (db < 55) return '🌿';
    if (db < 70) return '🔔';
    if (db < 85) return '📢';
    return '🔊';
  }
}
