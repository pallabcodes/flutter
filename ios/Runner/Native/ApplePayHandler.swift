import Flutter
import PassKit
import UIKit

/// Apple Pay handler for FinWise expense payments
@available(iOS 10.0, *)
public class ApplePayHandler: NSObject, PKPaymentAuthorizationViewControllerDelegate {
    private var flutterResult: FlutterResult?
    private var paymentController: PKPaymentAuthorizationViewController?

    /// Process Apple Pay payment
    func processPayment(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let amount = args["amount"] as? Double,
              let currency = args["currency"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid payment arguments", details: nil))
            return
        }

        let description = args["description"] as? String ?? "Expense Payment"

        // Check if Apple Pay is available
        if !PKPaymentAuthorizationController.canMakePayments() {
            result(FlutterError(code: "UNAVAILABLE", message: "Apple Pay is not available on this device", details: nil))
            return
        }

        // Check if user has payment cards
        if !PKPaymentAuthorizationController.canMakePayments(usingNetworks: getSupportedNetworks()) {
            result(FlutterError(code: "NO_CARDS", message: "No eligible payment cards found", details: nil))
            return
        }

        flutterResult = result

        // Create payment request
        let request = PKPaymentRequest()
        request.merchantIdentifier = "merchant.com.finwise.app" // Replace with actual merchant ID
        request.supportedNetworks = getSupportedNetworks()
        request.merchantCapabilities = .capability3DS
        request.countryCode = "US" // Replace with user's country
        request.currencyCode = currency

        // Create payment summary item
        let item = PKPaymentSummaryItem(
            label: description,
            amount: NSDecimalNumber(value: amount)
        )
        request.paymentSummaryItems = [item]

        // Create payment authorization controller
        paymentController = PKPaymentAuthorizationViewController(paymentRequest: request)
        paymentController?.delegate = self

        // Present payment sheet
        DispatchQueue.main.async {
            if let rootVC = UIApplication.shared.keyWindow?.rootViewController,
               let controller = self.paymentController {
                rootVC.present(controller, animated: true, completion: nil)
            } else {
                result(FlutterError(code: "PRESENT_FAILED", message: "Failed to present payment interface", details: nil))
            }
        }
    }

    // MARK: - PKPaymentAuthorizationViewControllerDelegate

    public func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController,
                                                  didAuthorizePayment payment: PKPayment,
                                                  handler completion: @escaping (PKPaymentAuthorizationResult) -> Void) {

        // Process the payment
        processPaymentAuthorization(payment) { success, errorMessage in
            if success {
                completion(PKPaymentAuthorizationResult(status: .success, errors: nil))
            } else {
                let error = NSError(domain: "FinWise", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMessage ?? "Payment failed"])
                completion(PKPaymentAuthorizationResult(status: .failure, errors: [error]))
            }
        }
    }

    public func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController) {
        controller.dismiss(animated: true) {
            self.paymentController = nil

            // If we haven't sent a result yet, it means payment was cancelled
            if self.flutterResult != nil {
                let result: [String: Any] = [
                    "success": false,
                    "errorMessage": "Payment cancelled by user"
                ]
                self.flutterResult?(result)
                self.flutterResult = nil
            }
        }
    }

    // MARK: - Private Methods

    private func getSupportedNetworks() -> [PKPaymentNetwork] {
        if #available(iOS 12.1.1, *) {
            return [.visa, .masterCard, .amex, .discover]
        } else if #available(iOS 11.2, *) {
            return [.visa, .masterCard, .amex]
        } else {
            return [.visa, .masterCard]
        }
    }

    private func processPaymentAuthorization(_ payment: PKPayment,
                                           completion: @escaping (Bool, String?) -> Void) {
        // Extract payment token data
        let paymentData = extractPaymentData(from: payment)

        // In a real app, you would send this to your payment processor
        // For FinWise, we're just capturing receipt data
        let receiptData: [String: Any] = [
            "transactionId": UUID().uuidString,
            "amount": calculateTotalAmount(from: payment),
            "currency": payment.currencyCode,
            "timestamp": Date().timeIntervalSince1970,
            "paymentMethod": "apple_pay",
            "paymentData": paymentData,
            "merchantId": payment.merchantIdentifier
        ]

        // Send result back to Flutter
        let result: [String: Any] = [
            "success": true,
            "transactionId": receiptData["transactionId"] as! String,
            "receiptData": receiptData
        ]

        flutterResult?(result)
        flutterResult = nil

        completion(true, nil)
    }

    private func extractPaymentData(from payment: PKPayment) -> [String: Any] {
        do {
            let paymentToken = try JSONSerialization.jsonObject(with: payment.token.paymentData, options: []) as? [String: Any]

            return [
                "paymentToken": paymentToken ?? [:],
                "transactionIdentifier": payment.token.transactionIdentifier,
                "paymentMethod": [
                    "displayName": payment.token.paymentMethod.displayName ?? "",
                    "network": payment.token.paymentMethod.network?.rawValue ?? "",
                    "type": payment.token.paymentMethod.type.rawValue
                ]
            ]
        } catch {
            return ["error": "Failed to parse payment data"]
        }
    }

    private func calculateTotalAmount(from payment: PKPayment) -> Double {
        return payment.token.paymentSummaryItems
            .map { $0.amount.doubleValue }
            .reduce(0, +)
    }

    /// Check if Apple Pay can process payments for specific networks
    static func canProcessPayments(for networks: [PKPaymentNetwork] = []) -> Bool {
        if networks.isEmpty {
            return PKPaymentAuthorizationController.canMakePayments()
        } else {
            return PKPaymentAuthorizationController.canMakePayments(usingNetworks: networks)
        }
    }

    /// Get available payment passes
    static func getAvailablePaymentPasses() -> [PKPaymentPass] {
        return PKPassLibrary().passes(of: .payment).compactMap { $0.paymentPass }
    }

    /// Check if device supports Apple Pay
    static func isApplePaySupported() -> Bool {
        return PKPaymentAuthorizationController.canMakePayments()
    }
}

/// Extension for easier payment network handling
extension PKPaymentNetwork {
    @available(iOS 10.0, *)
    static var allCases: [PKPaymentNetwork] {
        if #available(iOS 12.1.1, *) {
            return [.amex, .chinaUnionPay, .discover, .interac, .masterCard, .privateLabel, .visa]
        } else if #available(iOS 11.2, *) {
            return [.amex, .chinaUnionPay, .discover, .masterCard, .privateLabel, .visa]
        } else if #available(iOS 11.0, *) {
            return [.amex, .chinaUnionPay, .discover, .masterCard, .visa]
        } else {
            return [.amex, .discover, .masterCard, .visa]
        }
    }
}

/// Apple Pay configuration helper
public class ApplePayConfiguration {
    /// Configure merchant identifier
    static let merchantIdentifier = "merchant.com.finwise.app"

    /// Supported payment networks
    static let supportedNetworks: [PKPaymentNetwork] = {
        if #available(iOS 12.1.1, *) {
            return [.visa, .masterCard, .amex, .discover]
        } else if #available(iOS 11.2, *) {
            return [.visa, .masterCard, .amex]
        } else {
            return [.visa, .masterCard]
        }
    }()

    /// Merchant capabilities
    static let merchantCapabilities: PKMerchantCapability = .capability3DS

    /// Country code
    static let countryCode = "US"

    /// Currency code
    static let currencyCode = "USD"

    /// Create payment request for expense
    static func createPaymentRequest(amount: Double, description: String) -> PKPaymentRequest {
        let request = PKPaymentRequest()
        request.merchantIdentifier = merchantIdentifier
        request.supportedNetworks = supportedNetworks
        request.merchantCapabilities = merchantCapabilities
        request.countryCode = countryCode
        request.currencyCode = currencyCode

        let item = PKPaymentSummaryItem(
            label: description,
            amount: NSDecimalNumber(value: amount)
        )
        request.paymentSummaryItems = [item]

        return request
    }

    /// Validate merchant setup
    static func validateMerchantSetup() -> (isValid: Bool, errors: [String]) {
        var errors: [String] = []

        if merchantIdentifier.isEmpty {
            errors.append("Merchant identifier is not configured")
        }

        if !PKPaymentAuthorizationController.canMakePayments() {
            errors.append("Device does not support Apple Pay")
        }

        if !PKPaymentAuthorizationController.canMakePayments(usingNetworks: supportedNetworks) {
            errors.append("No eligible payment cards available")
        }

        return (errors.isEmpty, errors)
    }
}
