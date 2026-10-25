import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  private let channelName = "com.trustlens/native"
  private let appGroupId = "group.com.trustlens.filter"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: controller.binaryMessenger)

    channel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      guard let self = self else { return }

      switch call.method {
      case "syncFilterConfig":
        if let configJson = call.arguments as? String {
          let success = self.saveConfigToAppGroup(configJson)
          result(success)
        } else {
          result(FlutterError(code: "INVALID_ARGS", message: "Missing config JSON", details: nil))
        }
      case "evaluateAccelerator":
        if let args = call.arguments as? [String: Any] {
          let text = args["text"] as? String ?? ""
          let sender = args["sender"] as? String
          let decision = TrustFilterEngine.shared.classify(text, sender: sender)
          result([
            "score": decision.score,
            "isSpam": decision.category == "spam" ? 1.0 : 0.0,
            "isTransaction": decision.category == "transaction" ? 1.0 : 0.0
          ])
        } else {
          result(nil)
        }
      case "isNotificationAccessGranted":
        // iOS uses SMS MessageFilter extension rather than notification listener
        result(true)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func saveConfigToAppGroup(_ configJson: String) -> Bool {
    guard let sharedDefaults = UserDefaults(suiteName: appGroupId) else {
      return false
    }
    sharedDefaults.set(configJson, forKey: "trustlens_filter_config")
    sharedDefaults.synchronize()
    return true
  }
}
