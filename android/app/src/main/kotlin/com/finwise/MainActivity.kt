package com.finwise

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import com.finwise.native.FinWiseNativeBridge

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Register native bridge using v2 embedding
        // Flutter automatically discovers and registers plugins, so manual registration is not needed
        // The plugin will be registered automatically via the plugin registry
    }

    override fun onResume() {
        super.onResume()

        // Handle notification tap
        intent?.getStringExtra("notification_payload")?.let { payload ->
            // Send notification payload to Flutter
            handleNotificationPayload(payload)
        }
    }

    private fun handleNotificationPayload(payload: String) {
        // Parse payload and navigate to appropriate screen
        when {
            payload.startsWith("budget_alert:") -> {
                val budgetId = payload.substringAfter("budget_alert:")
                navigateToBudget(budgetId)
            }
            payload.startsWith("receipt_scan:") -> {
                val receiptId = payload.substringAfter("receipt_scan:")
                navigateToReceipt(receiptId)
            }
            else -> {
                // Handle other notification types
                println("Unknown notification payload: $payload")
            }
        }
    }

    private fun navigateToBudget(budgetId: String) {
        // Navigate to budget screen (would be implemented with Flutter navigation)
        println("Navigate to budget: $budgetId")
    }

    private fun navigateToReceipt(receiptId: String) {
        // Navigate to receipt screen (would be implemented with Flutter navigation)
        println("Navigate to receipt: $receiptId")
    }
}
