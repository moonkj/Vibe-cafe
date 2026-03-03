import Flutter
import UIKit
import GoogleMaps
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("AIzaSyBigJrMfUqNTkMyoy_rOli5M1PRdP2YDOU")

    // LaunchScreen → Flutter 첫 프레임 사이 flash 방지
    // Flutter SharedPreferences는 NSUserDefaults에 "flutter." 접두사로 저장됨
    let stored = UserDefaults.standard.string(forKey: "flutter.theme_mode")
    let isDark: Bool
    if stored == "dark" {
      isDark = true
    } else if stored == "light" {
      isDark = false
    } else {
      isDark = UITraitCollection.current.userInterfaceStyle == .dark
    }
    window?.backgroundColor = isDark
      ? UIColor(red: 0.051, green: 0.122, blue: 0.102, alpha: 1.0)  // #0D1F1A
      : UIColor(red: 0.961, green: 0.953, blue: 0.937, alpha: 1.0)  // #F5F2EF

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // Native permission channel — bypasses permission_handler iOS 26 beta bugs.
    let channel = FlutterMethodChannel(
      name: "com.cafevibe/permissions",
      binaryMessenger: engineBridge.pluginRegistry.registrar(forPlugin: "permissions")!.messenger()
    )
    channel.setMethodCallHandler { (call, result) in
      if call.method == "checkMicrophonePermission" {
        // AVCaptureDevice is the most reliable API across all iOS versions.
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        switch status {
        case .authorized:
          result("authorized")
        case .denied:
          result("denied")
        case .restricted:
          result("restricted")
        case .notDetermined:
          result("notDetermined")
        @unknown default:
          result("unknown")
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
