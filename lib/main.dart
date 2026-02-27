import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/services/supabase_service.dart';

/// ─────────────────────────────────────────────────────────────────
/// IMPORTANT: Set your credentials via --dart-define at build time:
///   flutter build ios \
///     --dart-define=SUPABASE_URL=https://xxx.supabase.co \
///     --dart-define=SUPABASE_ANON_KEY=your_anon_key
///
/// Google Maps API key must be set in ios/Runner/AppDelegate.swift
/// ─────────────────────────────────────────────────────────────────
const _supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://YOUR_PROJECT.supabase.co',
);
const _supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: 'YOUR_ANON_KEY',
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Portrait lock for iPhone; iPad uses all orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Initialise Supabase before runApp
  await SupabaseService.initialize(
    url: _supabaseUrl,
    anonKey: _supabaseAnonKey,
  );

  runApp(
    const ProviderScope(
      child: NoiseSpotApp(),
    ),
  );
}
