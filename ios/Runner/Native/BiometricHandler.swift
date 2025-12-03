import Flutter
import LocalAuthentication
import UIKit

/// Biometric authentication handler for Face ID and Touch ID
public class BiometricHandler: NSObject {
    private let context = LAContext()
    private var flutterResult: FlutterResult?

    /// Check if Face ID is available
    static func canUseFaceID() -> Bool {
        let context = LAContext()
        var error: NSError?

        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) &&
               context.biometryType == .faceID
    }

    /// Check if Touch ID is available
    static func canUseTouchID() -> Bool {
        let context = LAContext()
        var error: NSError?

        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) &&
               context.biometryType == .touchID
    }

    /// Check if any biometric authentication is available
    static func canUseBiometrics() -> Bool {
        let context = LAContext()
        var error: NSError?

        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    /// Get biometric type available on device
    static func getBiometricType() -> String {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return "none"
        }

        switch context.biometryType {
        case .faceID:
            return "face_id"
        case .touchID:
            return "touch_id"
        case .opticID:
            return "optic_id"
        default:
            return "unknown"
        }
    }

    /// Authenticate using biometrics
    func authenticate(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid authentication arguments", details: nil))
            return
        }

        let reason = args["reason"] as? String ?? "Authenticate to continue"
        let useFaceId = args["useFaceId"] as? Bool ?? true
        let useTouchId = args["useTouchId"] as? Bool ?? true

        flutterResult = result

        // Configure authentication policies
        var policies: [LAPolicy] = []

        if useFaceId && BiometricHandler.canUseFaceID() {
            policies.append(.deviceOwnerAuthenticationWithBiometrics)
        }

        if useTouchId && BiometricHandler.canUseTouchID() {
            policies.append(.deviceOwnerAuthenticationWithBiometrics)
        }

        // Fallback to passcode if biometrics not available
        if policies.isEmpty {
            policies.append(.deviceOwnerAuthentication)
        }

        // Evaluate authentication
        evaluateAuthentication(reason: reason, policies: policies)
    }

    private func evaluateAuthentication(reason: String, policies: [LAPolicy]) {
        // Reset context for fresh evaluation
        context.invalidate()

        let newContext = LAContext()

        // Evaluate the first available policy
        for policy in policies {
            newContext.evaluatePolicy(policy, localizedReason: reason) { [weak self] success, error in
                DispatchQueue.main.async {
                    self?.handleAuthenticationResult(success: success, error: error, reason: reason)
                }
            }
            break // Only evaluate the first available policy
        }
    }

    private func handleAuthenticationResult(success: Bool, error: LAError?, reason: String) {
        var result: [String: Any] = [
            "success": success,
            "usedFace": BiometricHandler.canUseFaceID() && context.biometryType == .faceID,
            "usedFingerprint": BiometricHandler.canUseTouchID() && context.biometryType == .touchID,
        ]

        if let error = error {
            result["errorMessage"] = getErrorMessage(for: error)
            result["errorCode"] = getErrorCode(for: error)
        }

        flutterResult?(result)
        flutterResult = nil
    }

    private func getErrorMessage(for error: LAError) -> String {
        switch error.code {
        case .authenticationFailed:
            return "Authentication failed"
        case .userCancel:
            return "Authentication cancelled by user"
        case .userFallback:
            return "User chose to enter password"
        case .systemCancel:
            return "Authentication cancelled by system"
        case .passcodeNotSet:
            return "Passcode not set"
        case .biometryNotAvailable:
            return "Biometric authentication not available"
        case .biometryNotEnrolled:
            return "Biometric authentication not enrolled"
        case .biometryLockout:
            return "Biometric authentication locked out"
        case .appCancel:
            return "Authentication cancelled by app"
        case .invalidContext:
            return "Invalid authentication context"
        @unknown default:
            return "Unknown authentication error"
        }
    }

    private func getErrorCode(for error: LAError) -> String {
        return "LA_\(error.code.rawValue)"
    }

    /// Check if biometric authentication is locked out
    static func isBiometricLockout() -> Bool {
        let context = LAContext()
        var error: NSError?

        let canEvaluate = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)

        if let error = error as? LAError {
            return error.code == .biometryLockout
        }

        return false
    }

    /// Get biometric authentication state
    static func getBiometricState() -> [String: Any] {
        let context = LAContext()
        var error: NSError?

        let canEvaluate = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)

        return [
            "available": canEvaluate,
            "type": getBiometricType(),
            "enrolled": canEvaluate,
            "lockout": isBiometricLockout(),
            "error": error?.localizedDescription
        ]
    }

    /// Reset biometric lockout (requires user to authenticate with passcode)
    static func resetBiometricLockout() {
        // This would typically require showing a passcode entry UI
        // For now, we just invalidate the context
        LAContext().invalidate()
    }
}

/// Biometric authentication configuration
public class BiometricConfig {
    /// Default authentication reason
    static let defaultReason = "Authenticate to access your expense data"

    /// Authentication timeout (seconds)
    static let timeout = 30

    /// Maximum retry attempts
    static let maxRetries = 3

    /// Fallback to passcode after biometric failure
    static let allowPasscodeFallback = true

    /// Require authentication for sensitive operations
    static let requireForSensitiveOps = true

    /// Auto-lock timeout (minutes)
    static let autoLockTimeout = 5

    /// Get authentication policies based on availability
    static func getAuthenticationPolicies() -> [LAPolicy] {
        var policies: [LAPolicy] = []

        if BiometricHandler.canUseBiometrics() {
            policies.append(.deviceOwnerAuthenticationWithBiometrics)
        }

        policies.append(.deviceOwnerAuthentication) // Fallback to passcode

        return policies
    }

    /// Check if device meets security requirements
    static func meetsSecurityRequirements() -> Bool {
        // Check if device has secure enclave (iPhone 5s and later, iPad Air and later)
        // This is a simplified check - in production you'd check device capabilities
        return true
    }

    /// Get security level description
    static func getSecurityLevel() -> String {
        if BiometricHandler.canUseFaceID() {
            return "high"
        } else if BiometricHandler.canUseTouchID() {
            return "medium"
        } else {
            return "basic"
        }
    }
}

/// Biometric permission handler
public class BiometricPermissionHandler {
    /// Request biometric permission
    static func requestBiometricPermission(completion: @escaping (Bool, String?) -> Void) {
        let context = LAContext()

        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                             localizedReason: "Enable biometric authentication for secure access") { success, error in
            DispatchQueue.main.async {
                if success {
                    completion(true, nil)
                } else if let error = error as? LAError {
                    switch error.code {
                    case .biometryNotEnrolled:
                        completion(false, "Biometric authentication not set up. Please go to Settings > Face ID & Passcode (or Touch ID & Passcode) to set it up.")
                    case .passcodeNotSet:
                        completion(false, "Device passcode not set. Please set a passcode in Settings.")
                    default:
                        completion(false, error.localizedDescription)
                    }
                } else {
                    completion(false, "Unknown error occurred")
                }
            }
        }
    }

    /// Check if biometric permission is granted
    static func isBiometricPermissionGranted() -> Bool {
        let context = LAContext()
        var error: NSError?

        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    /// Open device settings for biometric setup
    static func openBiometricSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}
