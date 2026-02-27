import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Access the initialized Supabase client throughout the app.
/// Call [SupabaseService.initialize] once in main() before runApp.
class SupabaseService {
  SupabaseService._();

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize({
    required String url,
    required String anonKey,
  }) async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
  }
}

/// Riverpod provider for the Supabase client
final supabaseClientProvider = Provider<SupabaseClient>(
  (_) => SupabaseService.client,
);

/// Current auth user stream provider
final authStateProvider = StreamProvider<AuthState>(
  (ref) => SupabaseService.client.auth.onAuthStateChange,
);

/// Convenience: current user (null if logged out)
final currentUserProvider = Provider<User?>((ref) {
  final auth = ref.watch(authStateProvider);
  return auth.whenOrNull(data: (state) => state.session?.user);
});
