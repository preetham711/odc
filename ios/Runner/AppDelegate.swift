import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {

  // ── Method channel for native iOS features ──────────────────────────────
  private var methodChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // Register Flutter plugins (flutter_local_notifications, Firebase, local_auth, etc.)
    GeneratedPluginRegistrant.register(with: self)

    // ── Set up native method channel ───────────────────────────────────────
    if let controller = window?.rootViewController as? FlutterViewController {
      methodChannel = FlutterMethodChannel(
        name: "com.odctracker/native",
        binaryMessenger: controller.binaryMessenger
      )
      methodChannel?.setMethodCallHandler { [weak self] (call, result) in
        self?.handleMethodCall(call, result: result)
      }
    }

    // ── Notification permissions ──────────────────────────────────────────
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self

      let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound, .criticalAlert]
      UNUserNotificationCenter.current().requestAuthorization(
        options: authOptions,
        completionHandler: { _, _ in }
      )
    } else {
      let settings: UIUserNotificationSettings =
        UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
      application.registerUserNotificationSettings(settings)
    }

    // ── Register for remote notifications (APNs / Firebase Messaging) ──────
    application.registerForRemoteNotifications()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // ── Handle foreground notifications ───────────────────────────────────────
  // Shows banner + plays sound even when app is in the foreground
  @available(iOS 10.0, *)
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler:
      @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    if #available(iOS 14.0, *) {
      completionHandler([.banner, .badge, .sound])
    } else {
      completionHandler([.alert, .badge, .sound])
    }
  }

  // ── Handle notification tap ────────────────────────────────────────────────
  @available(iOS 10.0, *)
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    // Forward to Flutter via super (flutter_local_notifications handles this)
    super.userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)
  }

  // ── Deep link / URL scheme handler ────────────────────────────────────────
  // Handles odctracker://checkin, odctracker://checkout, etc.
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    // Send deep link to Flutter
    if url.scheme == "odctracker" {
      methodChannel?.invokeMethod("deepLink", arguments: url.absoluteString)
      return true
    }
    return super.application(app, open: url, options: options)
  }

  // ── Siri Shortcuts / Universal Links ──────────────────────────────────────
  override func application(
    _ application: UIApplication,
    continue userActivity: NSUserActivity,
    restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
  ) -> Bool {
    if let url = userActivity.webpageURL {
      methodChannel?.invokeMethod("universalLink", arguments: url.absoluteString)
    }
    return super.application(
      application,
      continue: userActivity,
      restorationHandler: restorationHandler
    )
  }

  // ── Method channel handlers ────────────────────────────────────────────────
  private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getBatteryLevel":
      UIDevice.current.isBatteryMonitoringEnabled = true
      let level = Int(UIDevice.current.batteryLevel * 100)
      result(level)

    case "getDeviceModel":
      result(UIDevice.current.model)

    case "getSystemVersion":
      result(UIDevice.current.systemVersion)

    case "isLowPowerMode":
      result(ProcessInfo.processInfo.isLowPowerModeEnabled)

    case "getDeviceName":
      result(UIDevice.current.name)

    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
