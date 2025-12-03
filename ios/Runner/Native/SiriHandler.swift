import Flutter
import Intents
import IntentsUI

/// Siri shortcuts handler for FinWise
public class SiriHandler: NSObject {
    private var shortcuts: [String: [String: Any]] = [:]

    /// Add a Siri shortcut
    func addShortcut(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let identifier = args["identifier"] as? String,
              let title = args["title"] as? String,
              let phrase = args["phrase"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid shortcut arguments", details: nil))
            return
        }

        let userInfo = args["userInfo"] as? [String: Any] ?? [:]

        // Store shortcut data
        shortcuts[identifier] = [
            "title": title,
            "phrase": phrase,
            "userInfo": userInfo
        ]

        // Create INShortcut
        if #available(iOS 12.0, *) {
            let intent = AddExpenseIntent()
            intent.suggestedInvocationPhrase = phrase
            intent.expenseTitle = title

            let shortcut = INShortcut(intent: intent)
            let vc = INUIAddVoiceShortcutViewController(shortcut: shortcut!)

            vc.delegate = self

            if let rootVC = UIApplication.shared.keyWindow?.rootViewController {
                rootVC.present(vc, animated: true, completion: nil)
                result(true)
            } else {
                result(false)
            }
        } else {
            result(FlutterError(code: "UNSUPPORTED", message: "Siri shortcuts require iOS 12+", details: nil))
        }
    }

    /// Handle voice command from Siri
    func handleVoiceCommand(_ command: String, userInfo: [String: Any]?) -> [String: Any]? {
        // Parse voice command and extract expense data
        let parsedData = parseExpenseCommand(command)

        if let data = parsedData {
            return [
                "type": "voice_command",
                "data": data,
                "userInfo": userInfo ?? [:]
            ]
        }

        return nil
    }

    /// Parse natural language expense commands
    private func parseExpenseCommand(_ command: String) -> [String: Any]? {
        let lowerCommand = command.lowercased()

        // Simple pattern matching for expense commands
        // This would be enhanced with more sophisticated NLP in production

        if lowerCommand.contains("add expense") || lowerCommand.contains("log expense") {
            return extractExpenseData(from: lowerCommand)
        }

        if lowerCommand.contains("spent") || lowerCommand.contains("paid") {
            return extractExpenseData(from: lowerCommand)
        }

        return nil
    }

    /// Extract expense data from command text
    private func extractExpenseData(from command: String) -> [String: Any] {
        var amount: Double = 0
        var description = ""
        var category = "other"

        // Extract amount (simple regex for currency patterns)
        let amountPattern = try? NSRegularExpression(pattern: "\\$?(\\d+(?:\\.\\d{2})?)", options: [])
        if let match = amountPattern?.firstMatch(in: command, options: [], range: NSRange(location: 0, length: command.count)) {
            if let range = Range(match.range(at: 1), in: command) {
                amount = Double(command[range]) ?? 0
            }
        }

        // Extract description (text after amount)
        let words = command.split(separator: " ")
        var descriptionWords: [String] = []

        for word in words {
            if let _ = Double(word.replacingOccurrences(of: "$", with: "")) {
                // Found amount, everything after is description
                break
            }
            descriptionWords.append(String(word))
        }

        description = descriptionWords.joined(separator: " ")

        // Basic category detection
        if command.contains("food") || command.contains("restaurant") || command.contains("lunch") {
            category = "food"
        } else if command.contains("gas") || command.contains("fuel") || command.contains("car") {
            category = "transportation"
        } else if command.contains("movie") || command.contains("entertainment") {
            category = "entertainment"
        }

        return [
            "amount": amount,
            "description": description,
            "category": category,
            "timestamp": Date().timeIntervalSince1970
        ]
    }

    /// Get available shortcuts
    func getShortcuts() -> [[String: Any]] {
        return shortcuts.values.map { $0 }
    }

    /// Remove shortcut
    func removeShortcut(identifier: String) -> Bool {
        return shortcuts.removeValue(forKey: identifier) != nil
    }
}

@available(iOS 12.0, *)
extension SiriHandler: INUIAddVoiceShortcutViewControllerDelegate {
    public func addVoiceShortcutViewController(_ controller: INUIAddVoiceShortcutViewController,
                                              didFinishWith voiceShortcut: INVoiceShortcut?,
                                              error: Error?) {
        controller.dismiss(animated: true, completion: nil)

        if let error = error {
            print("Failed to add Siri shortcut: \(error.localizedDescription)")
        } else if let shortcut = voiceShortcut {
            print("Successfully added Siri shortcut: \(shortcut.invocationPhrase)")
        }
    }

    public func addVoiceShortcutViewControllerDidCancel(_ controller: INUIAddVoiceShortcutViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
}

@available(iOS 12.0, *)
extension SiriHandler: INUIEditVoiceShortcutViewControllerDelegate {
    public func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController,
                                               didUpdate voiceShortcut: INVoiceShortcut?,
                                               error: Error?) {
        controller.dismiss(animated: true, completion: nil)

        if let error = error {
            print("Failed to update Siri shortcut: \(error.localizedDescription)")
        }
    }

    public func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController,
                                               didDeleteVoiceShortcutWithIdentifier deletedVoiceShortcutIdentifier: UUID) {
        controller.dismiss(animated: true, completion: nil)
        print("Deleted Siri shortcut: \(deletedVoiceShortcutIdentifier)")
    }

    public func editVoiceShortcutViewControllerDidCancel(_ controller: INUIEditVoiceShortcutViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
}

/// Custom Intent for Add Expense
@available(iOS 12.0, *)
public class AddExpenseIntent: INIntent {
    @NSManaged public var expenseTitle: String?
    @NSManaged public var expenseAmount: NSNumber?
    @NSManaged public var expenseCategory: String?
}

@available(iOS 12.0, *)
public class AddExpenseIntentHandler: NSObject, AddExpenseIntentHandling {
    public func handle(intent: AddExpenseIntent, completion: @escaping (AddExpenseIntentResponse) -> Void) {
        let response = AddExpenseIntentResponse(code: .success, userActivity: nil)

        // Process the expense data
        if let title = intent.expenseTitle,
           let amount = intent.expenseAmount?.doubleValue {
            let expenseData: [String: Any] = [
                "title": title,
                "amount": amount,
                "category": intent.expenseCategory ?? "other",
                "timestamp": Date().timeIntervalSince1970
            ]

            // Send to Flutter through notification or callback
            NotificationCenter.default.post(
                name: NSNotification.Name("ExpenseAddedFromSiri"),
                object: nil,
                userInfo: expenseData
            )
        }

        completion(response)
    }

    public func confirm(intent: AddExpenseIntent, completion: @escaping (AddExpenseIntentResponse) -> Void) {
        completion(AddExpenseIntentResponse(code: .ready, userActivity: nil))
    }
}
