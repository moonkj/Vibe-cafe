# Noise Spot — 개발 진행 현황 (Process Log)

마지막 업데이트: 2026-02-27 (Phase 9 단위 테스트 완료, 카카오 로그인 추가)

---

## 전체 진행률

```
Phase 1: 프로젝트 초기화     ████████████ 100% ✅
Phase 2: Core 레이어         ████████████ 100% ✅
Phase 3: Auth Feature         ████████████ 100% ✅
Phase 4: Map Feature          ████████████ 100% ✅
Phase 5: Report Feature       ████████████ 100% ✅
Phase 6: Profile Feature      ████████████ 100% ✅
Phase 7: Settings Feature     ████████████ 100% ✅
Phase 8: DB 마이그레이션      ████████████ 100% ✅
Phase 9: 테스트               ████████░░░░  60% ✅ (core/utils 4개 완료)
Phase 10: 실제 API 연동       ░░░░░░░░░░░░   0% ⏳
Phase 11: 앱 아이콘 & 빌드    ░░░░░░░░░░░░   0% ⏳
```

---

## ✅ 완료된 작업

### Phase 1: 프로젝트 초기화
- [x] `flutter create noise_spot --org com.noisespot --platforms ios` 실행
- [x] `pubspec.yaml` 전체 의존성 설정 (버전 충돌 해결 포함)
  - noise_meter: 6.x → **5.1.0** 수정 (pub.dev 최신)
  - permission_handler: 11.x → **12.0.0** 수정 (noise_meter 요구)
  - freezed: 2.x → **3.2.5** 수정 (freezed_annotation 3.x와 매칭)
- [x] `flutter pub get` 성공 (171개 패키지 설치)
- [x] `.gitignore`에 API 키 파일 추가 (`.env`, `secrets.json` 등)
- [x] `ios/Runner/Info.plist` iOS 권한 문구 설정
  - `NSMicrophoneUsageDescription`
  - `NSLocationWhenInUseUsageDescription`
  - `NSLocationAlwaysAndWhenInUseUsageDescription`
  - `CFBundleURLTypes` — URL Scheme `com.noisespot.noisespot` (Supabase OAuth 딥링크)

### Phase 2: Core 레이어

#### constants/
- [x] `app_colors.dart` — Mint→SkyBlue 팔레트, dB 레벨별 색상(5단계), Trust Score 색상
- [x] `app_strings.dart` — 모든 고정 문구 (개인정보 고지, 필터 레이블, 카카오/애플/구글 로그인 문구)
- [x] `map_constants.dart` — 반경 3km/5km, 줌 임계값(11/13/15), debounce 300ms, TTL 300s

#### theme/
- [x] `app_theme.dart` — Material 3 기반, Mint-Blue 팔레트, 미니멀 폰트 스케일

#### router/
- [x] `app_router.dart` — go_router 라우트 정의
  - `/onboarding` → OnboardingScreen
  - `/map` → MapScreen (ShellRoute)
  - `/report?spotId=&spotName=` → ReportScreen
  - `/profile` → ProfileScreen
  - `/settings` → SettingsScreen

#### utils/
- [x] `db_classifier.dart` — dB 수치 → 색상/레이블/이모지 변환
- [x] `ema_calculator.dart` — EMA 공식: `(old×0.7) + (new×0.3)`
- [x] `bounds_cache.dart` — 지도 bounds 5분 TTL 캐시 (중복 요청 방지)
- [x] `noise_filter.dart` — 120dB+ 무효화, 이상치 통계 필터링 (sqrt 버그 수정 완료)

#### services/
- [x] `supabase_service.dart` — Supabase 싱글턴, authStateProvider, currentUserProvider
- [x] `location_service.dart` — GPS 권한 요청, Haversine 100m 게이트, currentPositionProvider
- [x] `calibration_service.dart` — 최초 실행 3초 샘플링 → mic_offset SharedPreferences 저장

### Phase 3: Auth Feature
- [x] `auth_repository.dart` — Supabase Auth Kakao/Apple/Google OAuth
  - `signInWithKakao()` — OAuthProvider.kakao + redirectTo 딥링크
  - `signInWithApple()` — sign_in_with_apple 패키지
  - `signInWithGoogle()` — google_sign_in 패키지
- [x] `onboarding_screen.dart` — 그라데이션 배경, 로그인 버튼 3종
  - 카카오 (노란색 #FEE500, 검정 텍스트) — 첫 번째
  - Apple (검정 배경, 흰 텍스트)
  - Google (아웃라인, 커스텀 G 아이콘)
  - `didChangeDependencies()` — authStateProvider 리스너로 OAuth 콜백 감지 → `/map` 이동
- [x] `wave_to_spot_painter.dart` — **PathMetric 기반 완전 재작성**
  - 작은 흰 점이 경로를 따라 이동하며 잔상을 남기는 애니메이션
  - 좌측: EKG 심전도 파형 클러스터 (아이콘과 동일한 파형 형태)
  - 우측: 상향 곡률의 부드러운 QuadraticBezier 호
  - 종점 도착 시 흰 원(Spot) bloom 효과 (progress > 0.90)
  - Mint Green → White 그라데이션 트레일
  - `metric.extractPath(0, drawn)` — 잔상 유지 방식

### Phase 4: Map Feature
- [x] `spot_model.dart` — SpotModel Freezed 모델 (StickerType enum 포함)
  - `isStale` — 30일 이상 비활성 판별
  - `markerOpacity` — 비활성 스팟 투명도 0.4
  - `markerBorderWidth` — trust_score 기반 테두리 굵기
- [x] `spots_repository.dart` — PostGIS `get_spots_near` RPC 호출, `createSpot()`
- [x] `map_controller.dart` — StateNotifier 기반
  - onCameraIdle + 300ms debounce
  - BoundsCache 5분 TTL
  - Zoom 11 미만 로딩 중단
  - `SpotDisplayMode` (individual/reduced/heatmap/hidden)
  - STUDY/MEETING/RELAX 필터 토글
- [x] `map_screen.dart` — GoogleMap 전체화면 + 검색바 + 필터바 + 스팟 정보카드 + FAB
- [x] `spot_marker_widget.dart` — dB 색상 원형 마커 + SpotInfoCard (Social Proof 포함)
- [x] `filter_bar.dart` — STUDY/MEETING/RELAX 토글 칩

### Phase 5: Report Feature
- [x] `report_model.dart` — ReportModel (Supabase 응답 파싱)
- [x] `report_repository.dart` — `submitReport()` (dB만 저장, 음성 없음) + `getMyReports()` + `getMyStats()`
- [x] `report_controller.dart` — Riverpod 3.x `Notifier<ReportState>`, NoiseMeter 스트림 처리
  - `initialize(spotId, lat?, lng?)` — screen이 직접 args 전달 (StateProvider 대체)
  - `startMeasurement()` — NoiseMeter.noise 스트림 구독 (파일 저장 없음)
  - `stopMeasurement()` — 스트림 취소 + meter null 처리 (즉시 휘발)
  - 3초 안정화 후 평균 계산 → StickerSelection 단계로 전환
  - `verifyProximity()` — 100m 반경 검증
  - `submitWithSticker()` — Supabase RPC 호출 (EMA 갱신)
  - `ReportPhase`: measuring → stabilizing → stickerSelection → submitting → done/error
- [x] `report_screen.dart` — 단계별 화면 전환 (switch expression 활용)
- [x] `privacy_notice_bar.dart` — 상단 고정 개인정보 고지 바 (항상 표시)
- [x] `db_meter_widget.dart` — 실시간 dB 대형 숫자 + 반응형 파형 바 + 안정화 중 표시
- [x] `sticker_card_grid.dart` — STUDY/MEETING/RELAX 카드 3종 (flutter_animate 등장 효과)

### Phase 6: Profile Feature
- [x] `profile_screen.dart`
  - 총 리포트 수 / 평균 dB 통계 카드
  - Trust Grade 카드 (Bronze/Silver/Gold 진행률 바)
  - 방문 기록 리스트 (스티커 + dB + 날짜)

### Phase 7: Settings Feature
- [x] `settings_screen.dart`
  - 개인정보 처리방침 카드 (강조 표시)
  - 마이크/위치 권한 상태 표시 + 관리 버튼
  - 로그아웃 / 계정 삭제

### Phase 8: Supabase DB 마이그레이션
- [x] `supabase/migrations/001_initial_schema.sql`
  - `CREATE EXTENSION postgis`
  - `spots` 테이블 + GIST Spatial Index + google_place_id UNIQUE 인덱스
  - `reports` 테이블 + 복합 인덱스 (spot_id, created_at DESC)
  - Row Level Security (공개 읽기, 인증 사용자 쓰기)
  - `get_spots_near()` RPC — ST_DWithin 반경 조회 + 24h 카운트
  - `update_spot_after_report()` RPC — EMA 갱신 + trust_score 계산 (FOR UPDATE 락)

### Phase 9: 단위 테스트 (core/utils 완료)
- [x] `test/core/utils/ema_calculator_test.dart` — 5개 테스트 (EMA 공식, 첫 리포트, 수렴, 경계값)
- [x] `test/core/utils/noise_filter_test.dart` — 8개 테스트 (isValid, filterOutliers)
- [x] `test/core/utils/db_classifier_test.dart` — 7개 테스트 (colorFromDb, labelFromDb, formatDb)
- [x] `test/core/utils/bounds_cache_test.dart` — 7개 테스트 (히트/미스, tolerance, TTL, clear)
- **flutter test 결과: 30/30 통과** ✅

### iOS 실기기 빌드
- [x] iOS Deployment Target: **13.0 → 14.0** 상향 (google_maps_flutter_ios 요구사항)
  - `ios/Podfile`: `platform :ios, '14.0'`
  - `ios/Runner.xcodeproj/project.pbxproj`: `IPHONEOS_DEPLOYMENT_TARGET = 14.0`
- [x] iPhone "Moon" (iOS 26.4 beta) 릴리즈 빌드 설치 성공
  - Supabase 실제 URL/KEY로 `--dart-define` 연결
  - 온보딩 화면 및 애니메이션 정상 작동 확인

---

## ⏳ 남은 작업

### Phase 9: 테스트 (추가 작성 권장)

| 상태 | 파일 | 테스트 대상 |
|------|------|-------------|
| ✅ | `test/core/utils/ema_calculator_test.dart` | EMA 공식 정확성, 첫 리포트 처리 |
| ✅ | `test/core/utils/noise_filter_test.dart` | 120dB 거부, 이상치 필터링 |
| ✅ | `test/core/utils/db_classifier_test.dart` | 경계값 색상/레이블 매핑 |
| ✅ | `test/core/utils/bounds_cache_test.dart` | TTL, 캐시 히트/미스, tolerance |
| ⏳ | `test/core/services/location_service_test.dart` | 100m 반경 게이트, Haversine 정확도 |
| ⏳ | `test/features/map/map_controller_test.dart` | debounce, 줌 레벨 displayMode |
| ⏳ | `test/features/report/report_controller_test.dart` | 단계 전환, dB 필터링 |

### Phase 10: 실제 API 연동

| 상태 | 작업 |
|------|------|
| ⏳ | Supabase 프로젝트 생성 + PostGIS 활성화 |
| ⏳ | `001_initial_schema.sql` SQL Editor 실행 |
| ⏳ | Supabase Auth에서 Kakao + Apple + Google Provider 활성화 |
| ⏳ | Kakao Developers — 앱 등록, Supabase Redirect URI 허용 설정 |
| ⏳ | Google Cloud Console — Maps SDK for iOS + Places API 활성화 |
| ⏳ | `AppDelegate.swift`에 Google Maps API 키 입력 |
| ⏳ | Google Sign-In iOS Client ID 설정 (`auth_repository.dart` 상단 상수) |

### Phase 11: 앱 아이콘 & 최종 빌드

| 상태 | 작업 |
|------|------|
| ⏳ | `assets/icon/app_icon.png` 저장 (Concept 2, 1024×1024 PNG) |
| ⏳ | `dart run flutter_launcher_icons` 실행 |
| ⏳ | iOS 시뮬레이터에서 첫 실행 테스트 |
| ⏳ | 실기기 테스트 (마이크, GPS 권한 플로우) |
| ⏳ | App Store Connect — Sign in with Apple Capability 활성화 |

---

## 알려진 이슈 & 참고사항

### 1. ~~app_router.dart `part` 지시어~~ ✅ 해결됨
`part 'app_router.g.dart';` 불필요한 줄 제거 완료 (go_router codegen 미사용)

### 2. ~~Riverpod 3.x 마이그레이션~~ ✅ 완전 해결됨
- `StateNotifier` → `Notifier<S>`, `StateNotifierProvider` → `NotifierProvider<N, S>`
- `StateProvider<ReportArgs?>` 제거 → `ReportController.initialize()` 메서드로 대체
- `ReportArgs` 클래스 제거, `_spotId`/`_spotLat`/`_spotLng` 인스턴스 필드 사용

### 3. ~~`flutter analyze` 74개 오류~~ ✅ 0 issues 달성 (2026-02-27)
- `CardTheme` → `CardThemeData`
- `background` deprecated → 제거
- `withOpacity()` → `withValues(alpha:)` (8개 파일)
- 미사용 import 제거 (`cupertino.dart`, `dart:ui`, `rendering.dart`)
- `unnecessary_brace_in_string_interps` 수정

### 4. ~~noise_filter.dart stddev 버그~~ ✅ 수정됨 (2026-02-27)
```dart
// 수정 전 (bug): final stddev = variance == 0 ? 1.0 : variance;
// 수정 후: final stddev = variance == 0 ? 1.0 : sqrt(variance);
```
- `dart:math show sqrt` import 추가

### 5. Google Sign-In Client ID 미설정
```dart
// lib/features/auth/data/auth_repository.dart
const webClientId = 'YOUR_GOOGLE_WEB_CLIENT_ID';    // ← 실제 값으로 교체 필요
const iosClientId = 'YOUR_GOOGLE_IOS_CLIENT_ID';    // ← 실제 값으로 교체 필요
```

### 6. 앱 아이콘 파일 미등록
- `assets/icon/app_icon.png` 파일이 아직 없음
- `flutter build` 전에 반드시 추가 필요

### 7. Kakao OAuth 설정 필요
- Kakao Developers (developers.kakao.com)에서 앱 등록
- 플랫폼 → iOS 번들 ID `com.noisespot.noisespot` 등록
- Supabase Dashboard → Auth → Providers → Kakao에 REST API 키 + 시크릿 등록
- Redirect URI 허용: `https://rqlfyumzmpmhupjtroid.supabase.co/auth/v1/callback`

### 8. SpotInfoCard Lazy Loading
- 현재 마커 탭 시 이미 로드된 SpotModel 데이터만 표시
- 상세 정보(오늘 방문자 수, 1시간 평균 dB)는 추가 RPC 호출 필요
- 향후 `get_spot_detail(spot_id)` RPC 추가 권장

### 9. 구글 지도 Custom Style
- 현재 기본 지도 스타일 사용
- 미니멀 Custom Map Style JSON 적용 권장 (연한 회색 배경, POI 최소화)
- Google Cloud Console → Map Styles에서 JSON 생성 후 `GoogleMap(style:)` 파라미터 적용

---

## 빠른 시작 명령어

```bash
# 프로젝트 디렉토리
cd "/Users/kjmoon/Noise Spot/noise_spot"

# 의존성 설치
flutter pub get

# iOS 시뮬레이터 실행
flutter run -d "iPhone 16 Pro"

# 분석 (lint 체크)
flutter analyze

# 단위 테스트 실행
flutter test test/core/utils/

# 전체 테스트 실행
flutter test

# 아이콘 생성 (assets/icon/app_icon.png 추가 후)
dart run flutter_launcher_icons

# 실기기 릴리즈 빌드 & 설치 (iPhone "Moon")
flutter run --release \
  -d 00008150-001128391EF0401C \
  --dart-define=SUPABASE_URL=https://rqlfyumzmpmhupjtroid.supabase.co \
  "--dart-define=SUPABASE_ANON_KEY=<your_anon_key>"

# iOS 빌드
flutter build ios \
  --dart-define=SUPABASE_URL=https://rqlfyumzmpmhupjtroid.supabase.co \
  "--dart-define=SUPABASE_ANON_KEY=<your_anon_key>"
```
