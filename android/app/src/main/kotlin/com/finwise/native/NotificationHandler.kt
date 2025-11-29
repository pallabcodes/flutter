package com.finwise.native

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel.Result

class NotificationHandler(private val context: Context) {

    private val notificationManager = NotificationManagerCompat.from(context)
    private val androidNotificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    companion object {
        private const val DEFAULT_CHANNEL_ID = "finwise_default"
        private const val DEFAULT_CHANNEL_NAME = "FinWise Notifications"
        private const val DEFAULT_CHANNEL_DESCRIPTION = "General notifications for FinWise"
    }

    fun createNotificationChannel(call: MethodCall, result: Result) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val args = call.arguments as? Map<String, Any>
            val channelId = args?.get("id") as? String ?: DEFAULT_CHANNEL_ID
            val channelName = args?.get("name") as? String ?: DEFAULT_CHANNEL_NAME
            val channelDescription = args?.get("description") as? String ?: DEFAULT_CHANNEL_DESCRIPTION
            val importance = args?.get("importance") as? Int ?: NotificationManager.IMPORTANCE_DEFAULT

            val channel = NotificationChannel(channelId, channelName, importance).apply {
                description = channelDescription
                enableVibration(true)
                enableLights(true)
            }

            androidNotificationManager.createNotificationChannel(channel)
            result.success(true)
        } else {
            // For versions below Oreo, channels are not needed
            result.success(true)
        }
    }

    fun showNotification(call: MethodCall, result: Result) {
        val args = call.arguments as? Map<String, Any>
        val channelId = args?.get("channelId") as? String ?: DEFAULT_CHANNEL_ID
        val title = args?.get("title") as? String ?: "FinWise"
        val body = args?.get("body") as? String ?: ""
        val payload = args?.get("payload") as? String

        // Create notification channel if it doesn't exist (for Android 8.0+)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            createDefaultChannelIfNeeded()
        }

        val notificationId = System.currentTimeMillis().toInt()

        val builder = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(getNotificationIcon())
            .setContentTitle(title)
            .setContentText(body)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setAutoCancel(true)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))

        // Add payload if provided
        payload?.let { data ->
            val intent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
                putExtra("notification_payload", data)
            }

            val pendingIntent = PendingIntent.getActivity(
                context,
                notificationId,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            builder.setContentIntent(pendingIntent)
        }

        try {
            notificationManager.notify(notificationId, builder.build())
            result.success(mapOf(
                "success" to true,
                "notificationId" to notificationId
            ))
        } catch (e: SecurityException) {
            result.error("PERMISSION_DENIED", "Notification permission not granted", null)
        } catch (e: Exception) {
            result.error("NOTIFICATION_ERROR", e.message, null)
        }
    }

    fun cancelNotification(notificationId: Int) {
        notificationManager.cancel(notificationId)
    }

    fun cancelAllNotifications() {
        notificationManager.cancelAll()
    }

    fun areNotificationsEnabled(): Boolean {
        return notificationManager.areNotificationsEnabled()
    }

    fun isChannelEnabled(channelId: String): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = androidNotificationManager.getNotificationChannel(channelId)
            return channel?.importance != NotificationManager.IMPORTANCE_NONE
        }
        return areNotificationsEnabled()
    }

    fun getNotificationChannels(): List<Map<String, Any>> {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            return androidNotificationManager.notificationChannels.map { channel ->
                mapOf(
                    "id" to channel.id,
                    "name" to channel.name,
                    "description" to channel.description,
                    "importance" to channel.importance,
                    "enabled" to (channel.importance != NotificationManager.IMPORTANCE_NONE)
                )
            }
        }
        return emptyList()
    }

    fun deleteNotificationChannel(channelId: String) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            androidNotificationManager.deleteNotificationChannel(channelId)
        }
    }

    private fun createDefaultChannelIfNeeded() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val existingChannel = androidNotificationManager.getNotificationChannel(DEFAULT_CHANNEL_ID)
            if (existingChannel == null) {
                val channel = NotificationChannel(
                    DEFAULT_CHANNEL_ID,
                    DEFAULT_CHANNEL_NAME,
                    NotificationManager.IMPORTANCE_DEFAULT
                ).apply {
                    description = DEFAULT_CHANNEL_DESCRIPTION
                    enableVibration(true)
                    enableLights(true)
                }
                androidNotificationManager.createNotificationChannel(channel)
            }
        }
    }

    private fun getNotificationIcon(): Int {
        // Try to get the app icon, fallback to default Android icon
        val iconName = "ic_notification" // This should match your drawable resource
        val iconResId = context.resources.getIdentifier(iconName, "drawable", context.packageName)

        return if (iconResId != 0) {
            iconResId
        } else {
            // Fallback to default Android icon
            android.R.drawable.ic_dialog_info
        }
    }

    fun createBudgetAlertChannel(): String {
        val channelId = "finwise_budget_alerts"
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "Budget Alerts",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notifications when you're approaching budget limits"
                enableVibration(true)
                enableLights(true)
                lightColor = 0xFFFF6B35.toInt() // Orange color for alerts
            }
            androidNotificationManager.createNotificationChannel(channel)
        }
        return channelId
    }

    fun createReceiptScanChannel(): String {
        val channelId = "finwise_receipt_scan"
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "Receipt Scanning",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Notifications for receipt scanning completion"
                enableVibration(false)
                enableLights(true)
                lightColor = 0xFF4CAF50.toInt() // Green color for success
            }
            androidNotificationManager.createNotificationChannel(channel)
        }
        return channelId
    }

    fun showBudgetAlert(title: String, message: String, budgetId: String) {
        val channelId = createBudgetAlertChannel()
        val payload = "budget_alert:$budgetId"

        showNotificationWithData(channelId, title, message, payload)
    }

    fun showReceiptScanComplete(receiptId: String, amount: Double) {
        val channelId = createReceiptScanChannel()
        val title = "Receipt Scanned"
        val message = "Receipt processed: \$${String.format("%.2f", amount)}"
        val payload = "receipt_scan:$receiptId"

        showNotificationWithData(channelId, title, message, payload)
    }

    private fun showNotificationWithData(channelId: String, title: String, message: String, payload: String) {
        val notificationId = System.currentTimeMillis().toInt()

        val builder = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(getNotificationIcon())
            .setContentTitle(title)
            .setContentText(message)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setAutoCancel(true)
            .setStyle(NotificationCompat.BigTextStyle().bigText(message))

        // Add tap action
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            putExtra("notification_payload", payload)
        }

        val pendingIntent = PendingIntent.getActivity(
            context,
            notificationId,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        builder.setContentIntent(pendingIntent)

        try {
            notificationManager.notify(notificationId, builder.build())
        } catch (e: SecurityException) {
            // Notification permission not granted
            println("Notification permission not granted: ${e.message}")
        }
    }

    fun getNotificationSettings(): Map<String, Any> {
        return mapOf(
            "enabled" to areNotificationsEnabled(),
            "channels" to getNotificationChannels(),
            "importance_levels" to if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                mapOf(
                    "min" to NotificationManager.IMPORTANCE_MIN,
                    "low" to NotificationManager.IMPORTANCE_LOW,
                    "default" to NotificationManager.IMPORTANCE_DEFAULT,
                    "high" to NotificationManager.IMPORTANCE_HIGH,
                    "max" to NotificationManager.IMPORTANCE_MAX
                )
            } else {
                emptyMap<String, Any>()
            }
        )
    }
}
