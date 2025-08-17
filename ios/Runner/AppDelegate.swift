import UIKit
import Flutter
import GoogleMaps // Add this import

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Add this line
    GMSServices.provideAPIKey("AIzaSyDtVraYiTxFTjU4bCvIUzTgJUMnL2F2bb4")

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
