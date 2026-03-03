import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'secure_local_storage.dart';

// Supabase credentials — must be supplied via --dart-define at build time.
// No fallback defaultValue: failure at startup is preferable to shipping keys.
const _kSupabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
const _kSupabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

class SupabaseService {
  SupabaseService._();
  static SupabaseClient get client => Supabase.instance.client;
}

/// Initialises Supabase asynchronously.
///
/// Primary path: [SecureLocalStorage] — stores the anonymous session in iOS
/// Keychain so the same user identity is preserved across app restarts.
///
/// Fallback path: [EmptyLocalStorage] — used if the primary path fails
/// (e.g. corrupted keychain entry or network hang during token refresh).
/// This starts a fresh session; the user will be signed in anonymously again.
final supabaseInitProvider = FutureProvider<void>((ref) async {
  try {
    await Supabase.initialize(
      url: _kSupabaseUrl,
      anonKey: _kSupabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        localStorage: SecureLocalStorage(),
      ),
    ).timeout(const Duration(seconds: 10));
  } catch (_) {
    // Fallback: start fresh with no stored session
    try {
      await Supabase.initialize(
        url: _kSupabaseUrl,
        anonKey: _kSupabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
          localStorage: EmptyLocalStorage(),
        ),
      ).timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('[Supabase] 초기화 실패 (fallback도 실패): $e');
      rethrow;
    }
  }
});

/// Riverpod provider for the Supabase client.
/// Only safe to read after [supabaseInitProvider] has completed.
final supabaseClientProvider = Provider<SupabaseClient>(
  (_) => SupabaseService.client,
);

/// Current auth user stream provider.
/// Waits for Supabase to finish initialising before accessing the client,
/// so accessing this before [supabaseInitProvider] completes is safe.
final authStateProvider = StreamProvider<AuthState>((ref) async* {
  // Block until Supabase.initialize() completes — avoids "not initialized" crash
  await ref.watch(supabaseInitProvider.future);
  yield* SupabaseService.client.auth.onAuthStateChange;
});

/// Convenience: current user (null if logged out)
final currentUserProvider = Provider<User?>((ref) {
  final auth = ref.watch(authStateProvider);
  return auth.whenOrNull(data: (state) => state.session?.user);
});
