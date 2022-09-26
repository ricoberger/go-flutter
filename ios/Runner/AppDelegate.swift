import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    MobilePlugin.register(with: registrar(forPlugin: "ricoberger.de/go-flutter")!)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
