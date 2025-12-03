import Flutter
import UIKit
import Intents
import PassKit
import AuthenticationServices

/// Main native bridge handler for FinWise iOS integration
public class FinWiseNativeBridge: NSObject, FlutterPlugin {
    private var siriHandler: SiriHandler?
    private var applePayHandler: ApplePayHandler?
    private var biometricHandler: BiometricHandler?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "com.finwise.native", binaryMessenger: registrar.messenger())
        let eventChannel = FlutterEventChannel(name: "com.finwise.native.events", binaryMessenger: registrar.messenger())

        let instance = FinWiseNativeBridge()
        registrar.addMethodCallDelegate(instance, channel: channel)

        // Initialize native handlers
        instance.siriHandler = SiriHandler()
        instance.applePayHandler = ApplePayHandler()
        instance.biometricHandler = BiometricHandler()

        // Set up event stream
        eventChannel.setStreamHandler(NativeEventStreamHandler())
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        // Platform info
        case "getPlatformInfo":
            result(getPlatformInfo())

        // Feature availability
        case "isFeatureAvailable":
            handleFeatureCheck(call, result: result)

        // Siri shortcuts
        case "addSiriShortcut":
            siriHandler?.addShortcut(call, result: result)

        // Apple Pay
        case "processApplePay":
            applePayHandler?.processPayment(call, result: result)

        // Biometric authentication
        case "authenticateBiometrics":
            biometricHandler?.authenticate(call, result: result)

        // iCloud sync
        case "syncWithiCloud":
            handleiCloudSync(call, result: result)

        // Sharing
        case "shareContent":
            handleShareContent(call, result: result)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func getPlatformInfo() -> [String: Any] {
        return [
            "platform": "ios",
            "version": UIDevice.current.systemVersion,
            "model": UIDevice.current.model,
            "name": UIDevice.current.name,
            "systemName": UIDevice.current.systemName,
            "isJailbroken": isJailbroken(),
            "hasNotch": hasNotch(),
            "hasBiometrics": hasBiometrics(),
            "hasApplePay": PKPaymentAuthorizationController.canMakePayments(),
            "supportedApplePayNetworks": getSupportedApplePayNetworks(),
        ]
    }

    private func handleFeatureCheck(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let feature = args["feature"] as? String else {
            result(false)
            return
        }

        var isAvailable = false

        switch feature {
        case "siri_shortcuts":
            isAvailable = true // iOS 12+
        case "apple_pay":
            isAvailable = PKPaymentAuthorizationController.canMakePayments()
        case "icloud_sync":
            isAvailable = FileManager.default.ubiquityIdentityToken != nil
        case "face_id":
            isAvailable = BiometricHandler.canUseFaceID()
        case "touch_id":
            isAvailable = BiometricHandler.canUseTouchID()
        case "health_kit":
            isAvailable = HKHealthStore.isHealthDataAvailable()
        case "home_kit":
            isAvailable = true // iOS 8+
        default:
            isAvailable = false
        }

        result(isAvailable)
    }

    private func handleiCloudSync(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let data = args["data"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "Data is required", details: nil))
            return
        }

        // iCloud sync implementation would go here
        // For now, just acknowledge
        result(true)
    }

    private func handleShareContent(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result(false)
            return
        }

        let text = args["text"] as? String
        let url = args["url"] as? String
        let imagePaths = args["imagePaths"] as? [String]

        var items: [Any] = []

        if let text = text {
            items.append(text)
        }

        if let urlString = url, let url = URL(string: urlString) {
            items.append(url)
        }

        if let imagePaths = imagePaths {
            for path in imagePaths {
                if let image = UIImage(contentsOfFile: path) {
                    items.append(image)
                }
            }
        }

        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)

        if let rootVC = UIApplication.shared.keyWindow?.rootViewController {
            rootVC.present(activityVC, animated: true, completion: nil)
            result(true)
        } else {
            result(false)
        }
    }

    private func isJailbroken() -> Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        let fileManager = FileManager.default
        let jailbreakPaths = [
            "/Applications/Cydia.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt",
            "/usr/bin/ssh"
        ]

        for path in jailbreakPaths {
            if fileManager.fileExists(atPath: path) {
                return true
            }
        }

        // Check if can write to system locations
        let testPath = "/private/test.txt"
        do {
            try "test".write(toFile: testPath, atomically: true, encoding: .utf8)
            try fileManager.removeItem(atPath: testPath)
            return true
        } catch {
            return false
        }
        #endif
    }

    private func hasNotch() -> Bool {
        if #available(iOS 11.0, *) {
            let keyWindow = UIApplication.shared.windows.first { $0.isKeyWindow }
            return keyWindow?.safeAreaInsets.bottom ?? 0 > 0
        }
        return false
    }

    private func hasBiometrics() -> Bool {
        return BiometricHandler.canUseBiometrics()
    }

    private func getSupportedApplePayNetworks() -> [String] {
        if #available(iOS 10.0, *) {
            return PKPaymentNetwork.allCases.map { $0.rawValue }
        }
        return []
    }
}

/// Event stream handler for sending events to Flutter
class NativeEventStreamHandler: NSObject, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }

    func sendEvent(_ event: [String: Any]) {
        eventSink?(event)
    }
}
