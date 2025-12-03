package com.finwise.native

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import androidx.annotation.RequiresApi
import com.google.android.gms.wallet.PaymentsClient
import com.google.android.gms.wallet.Wallet
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.EventChannel.StreamHandler
import kotlinx.coroutines.*

/** FinWiseNativeBridge */
class FinWiseNativeBridge : FlutterPlugin, MethodCallHandler, StreamHandler {
    private lateinit var channel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private lateinit var context: Context
    private var eventSink: EventChannel.EventSink? = null

    private lateinit var googlePayHandler: GooglePayHandler
    private lateinit var biometricHandler: BiometricHandler
    private lateinit var notificationHandler: NotificationHandler

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext

        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.finwise.native")
        channel.setMethodCallHandler(this)

        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "com.finwise.native.events")
        eventChannel.setStreamHandler(this)

        // Initialize native handlers
        googlePayHandler = GooglePayHandler(context)
        biometricHandler = BiometricHandler(context)
        notificationHandler = NotificationHandler(context)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        CoroutineScope(Dispatchers.Main).launch {
            try {
                when (call.method) {
                    "getPlatformInfo" -> result.success(getPlatformInfo())
                    "isFeatureAvailable" -> handleFeatureCheck(call, result)
                    "processGooglePay" -> googlePayHandler.processPayment(call, result)
                    "authenticateBiometrics" -> biometricHandler.authenticate(call, result)
                    "createNotificationChannel" -> notificationHandler.createNotificationChannel(call, result)
                    "showNotification" -> notificationHandler.showNotification(call, result)
                    "enableAndroidAuto" -> handleAndroidAuto(call, result)
                    "getDynamicColorScheme" -> handleDynamicColors(call, result)
                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                result.error("NATIVE_ERROR", e.message, e.stackTraceToString())
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    private fun getPlatformInfo(): Map<String, Any> {
        return mapOf(
            "platform" to "android",
            "version" to Build.VERSION.RELEASE,
            "sdk" to Build.VERSION.SDK_INT,
            "model" to Build.MODEL,
            "manufacturer" to Build.MANUFACTURER,
            "brand" to Build.BRAND,
            "isEmulator" to isEmulator(),
            "hasNotch" to hasNotch(),
            "hasBiometrics" to biometricHandler.hasBiometrics(),
            "hasGooglePay" to googlePayHandler.isGooglePayAvailable(),
            "supportedAbis" to Build.SUPPORTED_ABIS.toList(),
        )
    }

    private fun handleFeatureCheck(call: MethodCall, result: Result) {
        val args = call.arguments as? Map<String, Any>
        val feature = args?.get("feature") as? String

        val isAvailable = when (feature) {
            "google_pay" -> googlePayHandler.isGooglePayAvailable()
            "android_auto" -> true // Android Auto is generally available
            "biometric_auth" -> biometricHandler.hasBiometrics()
            "dynamic_theming" -> Build.VERSION.SDK_INT >= Build.VERSION_CODES.S
            "notification_channels" -> Build.VERSION.SDK_INT >= Build.VERSION_CODES.O
            "background_location" -> true
            else -> false
        }

        result.success(isAvailable)
    }

    private fun handleAndroidAuto(call: MethodCall, result: Result) {
        // Android Auto integration would be implemented here
        // For now, just acknowledge
        result.success(true)
    }

    private fun handleDynamicColors(call: MethodCall, result: Result) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            try {
                val dynamicColors = getDynamicColors()
                result.success(dynamicColors)
            } catch (e: Exception) {
                result.error("DYNAMIC_COLORS_ERROR", e.message, null)
            }
        } else {
            result.error("UNSUPPORTED", "Dynamic colors require Android 12+", null)
        }
    }

    @RequiresApi(Build.VERSION_CODES.S)
    private fun getDynamicColors(): Map<String, Any> {
        val resources = context.resources
        val theme = context.theme

        // Get system accent colors
        val accent1 = getSystemAccentColor(resources, "system_accent1")
        val accent2 = getSystemAccentColor(resources, "system_accent2")
        val accent3 = getSystemAccentColor(resources, "system_accent3")

        return mapOf(
            "primary" to (accent1 ?: 0xFF2196F3.toInt()),
            "onPrimary" to 0xFFFFFFFF.toInt(),
            "secondary" to (accent2 ?: 0xFF1976D2.toInt()),
            "onSecondary" to 0xFFFFFFFF.toInt(),
            "surface" to 0xFFFFFFFF.toInt(),
            "onSurface" to 0xFF000000.toInt(),
        )
    }

    private fun getSystemAccentColor(resources: android.content.res.Resources, colorName: String): Int? {
        return try {
            val colorId = resources.getIdentifier(colorName, "color", "android")
            if (colorId != 0) resources.getColor(colorId, context.theme) else null
        } catch (e: Exception) {
            null
        }
    }

    private fun isEmulator(): Boolean {
        return (Build.BRAND.startsWith("generic") && Build.DEVICE.startsWith("generic"))
                || Build.FINGERPRINT.startsWith("generic")
                || Build.FINGERPRINT.startsWith("unknown")
                || Build.HARDWARE.contains("goldfish")
                || Build.HARDWARE.contains("ranchu")
                || Build.MODEL.contains("google_sdk")
                || Build.MODEL.contains("Emulator")
                || Build.MODEL.contains("Android SDK built for x86")
                || Build.MANUFACTURER.contains("Genymotion")
                || Build.PRODUCT.contains("sdk_google")
                || Build.PRODUCT.contains("google_sdk")
                || Build.PRODUCT.contains("sdk")
                || Build.PRODUCT.contains("sdk_x86")
                || Build.PRODUCT.contains("vbox86p")
                || Build.PRODUCT.contains("emulator")
                || Build.PRODUCT.contains("simulator")
    }

    private fun hasNotch(): Boolean {
        val resources = context.resources
        val resourceId = resources.getIdentifier("status_bar_height", "dimen", "android")
        return if (resourceId > 0) {
            val statusBarHeight = resources.getDimensionPixelSize(resourceId)
            statusBarHeight > 24 * resources.displayMetrics.density.toInt()
        } else {
            false
        }
    }

    fun sendEvent(event: Map<String, Any>) {
        CoroutineScope(Dispatchers.Main).launch {
            eventSink?.success(event)
        }
    }
}
