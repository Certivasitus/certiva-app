import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Retrasar el registro de plugins para evitar crash en path_provider
    // Los plugins se registran después de que iOS esté completamente inicializado
    // Balance: 1.0s evita el crash sin colgar la app (2.0s era demasiado largo)
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
      GeneratedPluginRegistrant.register(with: self)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
