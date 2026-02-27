import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Persists the Supabase session in the iOS Keychain via flutter_secure_storage.
///
/// Unlike [EmptyLocalStorage], this survives app restarts so that:
///   - Anonymous users keep the same ID across launches (reports & profile intact)
///   - Valid sessions are restored instantly without a network call
///   - Expired sessions are refreshed automatically using the stored refresh_token
///
/// Keychain item is removed on [removePersistedSession] (sign-out / delete account).
class SecureLocalStorage extends LocalStorage {
  static const _key = 'sb_session';
  static const _st = FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  const SecureLocalStorage();

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async {
    try {
      final val = await _st.read(key: _key);
      return val != null;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<String?> accessToken() async {
    try {
      return await _st.read(key: _key);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    try {
      await _st.write(key: _key, value: persistSessionString);
    } catch (_) {}
  }

  @override
  Future<void> removePersistedSession() async {
    try {
      await _st.delete(key: _key);
    } catch (_) {}
  }
}
