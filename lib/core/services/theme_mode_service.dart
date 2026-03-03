import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kThemeModeKey = 'theme_mode';

/// main()에서 runApp() 전에 설정 — build()가 첫 프레임부터 올바른 테마를 반환
ThemeMode _preloadedThemeMode = ThemeMode.system;

void preloadThemeMode(String? stored) {
  _preloadedThemeMode = stored == 'dark'
      ? ThemeMode.dark
      : stored == 'light'
          ? ThemeMode.light
          : ThemeMode.system;
}

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => _preloadedThemeMode;

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    _preloadedThemeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    switch (mode) {
      case ThemeMode.light:
        await prefs.setString(_kThemeModeKey, 'light');
      case ThemeMode.dark:
        await prefs.setString(_kThemeModeKey, 'dark');
      case ThemeMode.system:
        await prefs.setString(_kThemeModeKey, 'system');
    }
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);
