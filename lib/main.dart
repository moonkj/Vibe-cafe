import 'package:app_tracking_transparency/app_tracking_transparency.dart';
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
  defaultValue: 'https://rqlfyumzmpmhupjtroid.supabase.co',
);
const _supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJxbGZ5dW16bXBtaHVwanRyb2lkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzIxMzY4MjIsImV4cCI6MjA4NzcxMjgyMn0.PiivIIa-mjgOTLOH_suaAyllGQZRb8p-cYLi5gHpPXk',
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Portrait lock for iPhone; iPad uses all orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // ATT (App Tracking Transparency) — required for App Store (iOS 14.5+)
  // Google Maps SDK may access IDFA; request before map loads.
  final trackingStatus = await AppTrackingTransparency.trackingAuthorizationStatus;
  if (trackingStatus == TrackingStatus.notDetermined) {
    await AppTrackingTransparency.requestTrackingAuthorization();
  }

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
