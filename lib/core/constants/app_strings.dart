class AppStrings {
  AppStrings._();

  // App Info
  static const String appName = 'Noise Spot';
  static const String appSlogan = '시끄러운 도시 속, 나만의 고요한 스팟 찾기';

  // Privacy — fixed notice (displayed on all measurement & settings screens)
  static const String privacyNoticeMeasure =
      '음성은 저장되지 않으며 소음 수치(dB)만 기록됩니다.';
  static const String privacyNoticeSettings =
      '소음은 수치(dB)만 추출하며 절대 저장되지 않습니다.';

  // Onboarding
  // Onboarding — login buttons
  static const String loginWithKakao = '카카오로 로그인';
  static const String loginWithApple = 'Apple로 로그인';
  static const String loginWithGoogle = 'Google로 로그인';

  // Map Filters
  static const String filterStudy = 'STUDY';
  static const String filterMeeting = 'MEETING';
  static const String filterRelax = 'RELAX';

  // Sticker Labels
  static const String stickerStudyLabel = '집중하기 좋아요';
  static const String stickerMeetingLabel = '화상회의 가능해요';
  static const String stickerRelaxLabel = '쉬기 좋아요';

  // dB Labels
  static const String dbVeryQuiet = '매우 조용';
  static const String dbQuiet = '조용함';
  static const String dbModerate = '보통';
  static const String dbLoud = '시끄러움';
  static const String dbVeryLoud = '매우 시끄러움';

  // Reporting
  static const String reportTooFar =
      '현재 위치에서 100m 이내에서만 리포팅 가능합니다.';
  static const String reportBackground =
      '앱이 활성화된 상태에서만 측정 가능합니다.';
  static const String reportInvalidDb = '측정값이 유효하지 않습니다.';
  static const String reportSuccess = '리포트가 등록되었습니다!';
  static const String measuring = '측정 중...';
  static const String measureStabilizing = '3초 안정화 중...';

  // Calibration
  static const String calibrationTitle = '마이크 초기 설정';
  static const String calibrationDesc = '3초간 주변 소음을 측정해 기기를 최적화합니다.';

  // Trust Score
  static const String trustBronze = 'Bronze';
  static const String trustSilver = 'Silver';
  static const String trustGold = 'Gold';

  // Profile
  static const String totalReports = '총 리포트';
  static const String avgDb = '평균 dB';
  static const String quietestSpot = '가장 조용한 스팟';

  // Settings
  static const String micPermission = '마이크 권한';
  static const String locationPermission = '위치 권한';
  static const String privacyPolicy = '개인정보 처리방침';
  static const String logout = '로그아웃';
  static const String deleteAccount = '계정 삭제';

  // Data Freshness
  static const String dataInsufficient = '데이터 부족';
  static const String dataStale = '오래된 정보';

  // Social Proof
  static String recentReports(int count) => '최근 30분 $count명 리포팅';
  static String todayVisitors(int count) => '오늘 방문자 $count명';
  static String lastHourAvg(String db) => '최근 1시간 평균 ${db}dB';
}
