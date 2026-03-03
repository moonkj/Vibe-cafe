import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class AppTheme {
  AppTheme._();

  // ── 공통 textTheme 빌더 ───────────────────────────────────────────
  static TextTheme _buildTextTheme({required bool dark}) {
    final primary   = dark ? AppColors.darkTextPrimary   : AppColors.textPrimary;
    final secondary = dark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final hint      = dark ? AppColors.darkTextHint      : AppColors.textHint;

    return TextTheme(
      headlineLarge: GoogleFonts.notoSansKr(
        fontSize: 72,
        fontWeight: FontWeight.w300,
        letterSpacing: -2,
        color: primary,
      ),
      headlineMedium: GoogleFonts.notoSansKr(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: primary,
      ),
      titleLarge: GoogleFonts.notoSansKr(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        color: primary,
      ),
      titleMedium: GoogleFonts.notoSansKr(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.2,
        color: primary,
      ),
      bodyLarge: GoogleFonts.notoSansKr(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: primary,
      ),
      bodyMedium: GoogleFonts.notoSansKr(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: secondary,
      ),
      labelSmall: GoogleFonts.notoSansKr(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
        color: hint,
      ),
    );
  }

  // ── Light Theme ─────────────────────────────────────────────────
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.mintGreen,
          brightness: Brightness.light,
          primary: AppColors.mintGreen,
          secondary: AppColors.skyBlue,
          surface: AppColors.bgWhite,
          onSurface: AppColors.textPrimary,
          error: const Color(0xFFE05C5C),
        ),
        scaffoldBackgroundColor: AppColors.bgWhite,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: AppColors.textPrimary),
          titleTextStyle: GoogleFonts.notoSansKr(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.mintGreen,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: GoogleFonts.notoSansKr(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
            ),
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.bgCard,
          elevation: 0,
          shadowColor: AppColors.shadow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.divider, width: 1),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.divider,
          thickness: 1,
          space: 1,
        ),
        textTheme: _buildTextTheme(dark: false),
      );

  // ── Dark Theme ──────────────────────────────────────────────────
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.mintGreen,
          brightness: Brightness.dark,
          primary: AppColors.mintGreen,
          secondary: AppColors.skyBlue,
          surface: AppColors.darkBgSurface,
          onSurface: AppColors.darkTextPrimary,
          error: const Color(0xFFCF6679),
        ),
        scaffoldBackgroundColor: AppColors.darkBgBase,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: AppColors.darkTextPrimary),
          titleTextStyle: GoogleFonts.notoSansKr(
            color: AppColors.darkTextPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.mintGreen,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: GoogleFonts.notoSansKr(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
            ),
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.darkBgSurface,
          elevation: 2,
          shadowColor: AppColors.darkDisabled.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: AppColors.darkDivider,
              width: 1,
            ),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.darkDivider,
          thickness: 1,
          space: 1,
        ),
        textTheme: _buildTextTheme(dark: true),
      );
}
