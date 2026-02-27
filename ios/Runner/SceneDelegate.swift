import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  // Forward URL-scheme deep links (e.g. Supabase OAuth callback) to Flutter plugins.
  // In UIScene lifecycle, iOS delivers URL scheme callbacks here instead of
  // AppDelegate.application(_:open:url:options:), so we must forward manually.
  override func scene(
    _ scene: UIScene,
    openURLContexts URLContexts: Set<UIOpenURLContext>
  ) {
    super.scene(scene, openURLContexts: URLContexts)
    guard let url = URLContexts.first?.url else { return }
    _ = UIApplication.shared.delegate?.application?(
      UIApplication.shared,
      open: url,
      options: [:]
    )
  }
}
