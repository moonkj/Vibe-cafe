import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';

class AuthRepository {
  final SupabaseClient _client;
  AuthRepository(this._client);

  /// Sign in with Apple (required for iOS)
  Future<AuthResponse> signInWithApple() async {
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );

    final idToken = credential.identityToken;
    if (idToken == null) throw Exception('Apple ID 토큰을 가져올 수 없습니다.');

    return _client.auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: idToken,
    );
  }

  /// Sign in with Google
  Future<AuthResponse> signInWithGoogle() async {
    const webClientId =
        'YOUR_GOOGLE_WEB_CLIENT_ID'; // Replace with actual web client ID
    const iosClientId =
        'YOUR_GOOGLE_IOS_CLIENT_ID'; // Replace with actual iOS client ID

    final googleSignIn = GoogleSignIn(
      clientId: iosClientId,
      serverClientId: webClientId,
    );

    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) throw Exception('Google 로그인이 취소되었습니다.');

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    final accessToken = googleAuth.accessToken;

    if (idToken == null) throw Exception('Google ID 토큰을 가져올 수 없습니다.');

    return _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
  }

  /// Sign in with Kakao via Supabase OAuth (browser redirect flow).
  /// Requires Kakao configured in Supabase Dashboard → Auth → Providers → Kakao.
  /// After browser redirect, auth state is updated via deep link (app_links).
  Future<void> signInWithKakao() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.kakao,
      redirectTo: 'com.noisespot.noisespot://login-callback',
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  User? get currentUser => _client.auth.currentUser;
  bool get isSignedIn => currentUser != null;
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(supabaseClientProvider)),
);
