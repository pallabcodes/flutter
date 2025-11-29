import UIKit
import Flutter
import FirebaseCore
import FirebaseCrashlytics

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Configure Firebase
    FirebaseApp.configure()

    // Configure Crashlytics
    let crashlytics = Crashlytics.crashlytics()
    crashlytics.setCrashlyticsCollectionEnabled(true)

    // Register native plugins
    GeneratedPluginRegistrant.register(with: self)

    // Register FinWise native bridge
    FinWiseNativeBridge.register(with: self)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func applicationWillResignActive(_ application: UIApplication) {
    // Handle app moving to background
    super.applicationWillResignActive(application)
  }

  override func applicationDidEnterBackground(_ application: UIApplication) {
    // Handle app entering background
    super.applicationDidEnterBackground(application)
  }

  override func applicationWillEnterForeground(_ application: UIApplication) {
    // Handle app entering foreground
    super.applicationWillEnterForeground(application)
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
    // Handle app becoming active
    super.applicationDidBecomeActive(application)
  }

  override func applicationWillTerminate(_ application: UIApplication) {
    // Handle app termination
    super.applicationWillTerminate(application)
  }
}
