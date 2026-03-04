class AdminConfig {
  AdminConfig._();

  /// Supabase user IDs that have admin privileges.
  /// dart-define으로 주입: --dart-define=ADMIN_USER_ID=UUID
  /// 미설정 시 기본값 사용 (개발 환경 전용).
  static const String _adminUserId = String.fromEnvironment(
    'ADMIN_USER_ID',
    defaultValue: 'da2a8b72-a3c2-415b-bae5-63f2fa0b92a0',
  );

  static const List<String> adminUserIds = [_adminUserId];

  /// Admin email for cafe request notifications.
  static const String adminEmail = 'imurmkj@gmail.com';
}
