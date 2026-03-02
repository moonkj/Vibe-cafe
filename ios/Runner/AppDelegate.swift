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
