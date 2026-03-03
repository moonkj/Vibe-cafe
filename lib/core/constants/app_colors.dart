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

  // Sticker Category — 포커스 & 생산성
  static const Color stickerStudy    = Color(0xFF5BC8AC); // mint green
  static const Color stickerWork     = Color(0xFF6E8EBF); // calm blue
  static const Color stickerStudyZone = Color(0xFF3DAAA0); // dark teal
  static const Color stickerNomad    = Color(0xFF5B7FCC); // tech blue

  // Sticker Category — 소셜
  static const Color stickerMeeting  = Color(0xFF78C5E8); // sky blue
  static const Color stickerVibe     = Color(0xFFFF9A3C); // energetic orange
  static const Color stickerDate     = Color(0xFFE975A8); // romantic pink
  static const Color stickerGathering = Color(0xFF9B7DD4); // purple

  // Sticker Category — 가족 & 라이프
  static const Color stickerFamily   = Color(0xFFFF8C42); // warm orange
  static const Color stickerRelax    = Color(0xFF9CC5A1); // soft green
  static const Color stickerHealing  = Color(0xFF7CBF9E); // nature green
  static const Color stickerCozy     = Color(0xFFD4935A); // warm amber

  // Sticker Category — 감성 스타일
  static const Color stickerInsta    = Color(0xFFE8526A); // coral pink
  static const Color stickerRetro    = Color(0xFFA07850); // retro brown
  static const Color stickerMinimal  = Color(0xFF8EA5A2); // muted teal
  static const Color stickerGreen    = Color(0xFF5AAE6E); // plant green

  // Sticker Category — 기타
  static const Color stickerPeak     = Color(0xFFFF5252); // energetic red
  static const Color stickerMusic    = Color(0xFF7B68EE); // medium slate blue

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

  // ── Dark Mode Tokens ────────────────────────────────────────────
  static const Color darkBgBase      = Color(0xFF121212); // Scaffold 배경
  static const Color darkBgSurface   = Color(0xFF1E1E1E); // 카드, AppBar, 모달
  static const Color darkBgCard      = Color(0xFF2C2C2C); // 카드 내부 섹션
  static const Color darkBgSecondary = Color(0xFF242424); // 구분 섹션 배경

  static const Color darkTextPrimary   = Color(0xFFF0EDE6); // 주요 텍스트 (웜 화이트)
  static const Color darkTextSecondary = Color(0xFFA0ADA0); // 보조 텍스트
  static const Color darkTextHint      = Color(0xFF555E5A); // 힌트 텍스트

  static const Color darkDivider  = Color(0xFF2E3530); // 구분선
  static const Color darkDisabled = Color(0xFF4A5250); // 비활성 아이콘/마커

  // Accent (공통)
  static const Color accentCoral = Color(0xFFFF8C69); // 알림·강조 포인트
}
