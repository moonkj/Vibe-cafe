import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand gradient — Mint Green → Sky Blue (Frequency of Calm)
  static const Color mintGreen = Color(0xFF5BC8AC);
  static const Color skyBlue = Color(0xFF78C5E8);
  static const Color mintLight = Color(0xFFA8E6CF);
  static const Color skyLight = Color(0xFFB8E0F0);

  // Background
  static const Color bgWhite = Color(0xFFFAFCFB);
  static const Color bgCard = Color(0xFFFFFFFF);
  static const Color bgMap = Color(0xFFF5F8F7);

  // Text
  static const Color textPrimary = Color(0xFF1A2B2A);
  static const Color textSecondary = Color(0xFF6B8E8A);
  static const Color textHint = Color(0xFFAAC5C2);

  // dB Level Colors
  static const Color dbVeryQuiet = Color(0xFF5BC8AC);   // < 40dB  — Mint Green
  static const Color dbQuiet = Color(0xFF78C5E8);        // 40–54dB — Sky Blue
  static const Color dbModerate = Color(0xFFF5C842);     // 55–69dB — Yellow
  static const Color dbLoud = Color(0xFFFF9A3C);         // 70–84dB — Orange
  static const Color dbVeryLoud = Color(0xFFE05C5C);     // 85+dB   — Red

  // Trust Score (Gamification)
  static const Color trustBronze = Color(0xFFCD7F32);
  static const Color trustSilver = Color(0xFF9CA3AF);
  static const Color trustGold = Color(0xFFD4A017);

  // Sticker Category
  static const Color stickerStudy = Color(0xFF5BC8AC);
  static const Color stickerMeeting = Color(0xFF78C5E8);
  static const Color stickerRelax = Color(0xFF9CC5A1);

  // UI State
  static const Color divider = Color(0xFFE8F2F0);
  static const Color shadow = Color(0x1A5BC8AC);

  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [mintGreen, skyBlue],
  );

  static const LinearGradient bgGradient = LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [mintLight, skyLight],
  );

  static Color dbColor(double db) {
    if (db < 40) return dbVeryQuiet;
    if (db < 55) return dbQuiet;
    if (db < 70) return dbModerate;
    if (db < 85) return dbLoud;
    return dbVeryLoud;
  }
}
