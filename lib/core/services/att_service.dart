import 'dart:io';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';

/// App Tracking Transparency — iOS 전용, 최초 실행 시 1회 권한 요청.
class AttService {
  AttService._();

  /// iOS에서만 ATT 팝업을 표시합니다.
  /// 이미 결정된 상태(authorized/denied/restricted)면 스킵합니다.
  static Future<void> requestIfNeeded() async {
    if (!Platform.isIOS) return;
    try {
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;
      if (status == TrackingStatus.notDetermined) {
        await AppTrackingTransparency.requestTrackingAuthorization();
      }
    } catch (_) {
      // ATT 초기화 실패 시 앱 흐름에 영향 없도록 무시
    }
  }
}
