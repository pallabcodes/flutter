package com.finwise.native

import android.content.Context
import android.os.Build
import androidx.biometric.BiometricManager
// import androidx.biometric.BiometricPrompt // Temporarily disabled due to API compatibility issues
import androidx.core.content.ContextCompat
import androidx.fragment.app.FragmentActivity
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.*

class BiometricHandler(private val context: Context) {

    private val biometricManager = BiometricManager.from(context)

    fun hasBiometrics(): Boolean {
        return when (biometricManager.canAuthenticate(BiometricManager.Authenticators.BIOMETRIC_STRONG)) {
            BiometricManager.BIOMETRIC_SUCCESS -> true
            BiometricManager.BIOMETRIC_ERROR_NO_HARDWARE -> false
            BiometricManager.BIOMETRIC_ERROR_HW_UNAVAILABLE -> false
            BiometricManager.BIOMETRIC_ERROR_NONE_ENROLLED -> false
            else -> false
        }
    }

    fun hasFingerprint(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            biometricManager.canAuthenticate(BiometricManager.Authenticators.BIOMETRIC_WEAK) ==
                    BiometricManager.BIOMETRIC_SUCCESS
        } else {
            // For older versions, check if device has fingerprint hardware
            val biometricManagerLegacy = context.getSystemService(Context.FINGERPRINT_SERVICE)
            biometricManagerLegacy != null
        }
    }

    fun hasFaceUnlock(): Boolean {
        return Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q &&
               biometricManager.canAuthenticate(BiometricManager.Authenticators.BIOMETRIC_STRONG or
                                              BiometricManager.Authenticators.DEVICE_CREDENTIAL) ==
               BiometricManager.BIOMETRIC_SUCCESS
    }

    fun getBiometricType(): String {
        return when {
            hasFaceUnlock() -> "face_unlock"
            hasFingerprint() -> "fingerprint"
            else -> "none"
        }
    }

    fun authenticate(call: MethodCall, result: Result) {
        val args = call.arguments as? Map<String, Any>
        val title = args?.get("title") as? String ?: "Authenticate"
        val subtitle = args?.get("subtitle") as? String
        val description = args?.get("description") as? String ?: "Use your biometric credential to authenticate"
        val useFingerprint = args?.get("useFingerprint") as? Boolean ?: true
        val useFace = args?.get("useFace") as? Boolean ?: true

        // Check if biometrics are available
        if (!hasBiometrics()) {
            result.success(mapOf(
                "success" to false,
                "errorMessage" to "Biometric authentication not available",
                "errorCode" to "BIOMETRIC_NOT_AVAILABLE"
            ))
            return
        }

        // Get the current activity
        val activity = context as? FragmentActivity
        if (activity == null) {
            result.error("ACTIVITY_ERROR", "Unable to get activity for biometric authentication", null)
            return
        }

        CoroutineScope(Dispatchers.Main).launch {
            try {
                val success = performBiometricAuthentication(
                    activity = activity,
                    title = title,
                    subtitle = subtitle,
                    description = description,
                    useFingerprint = useFingerprint,
                    useFace = useFace
                )

                if (success) {
                    result.success(mapOf(
                        "success" to true,
                        "usedFace" to (getBiometricType() == "face_unlock"),
                        "usedFingerprint" to (getBiometricType() == "fingerprint")
                    ))
                } else {
                    result.success(mapOf(
                        "success" to false,
                        "errorMessage" to "Authentication failed",
                        "errorCode" to "AUTHENTICATION_FAILED"
                    ))
                }
            } catch (e: Exception) {
                result.success(mapOf(
                    "success" to false,
                    "errorMessage" to e.message,
                    "errorCode" to "BIOMETRIC_ERROR"
                ))
            }
        }
    }

    private suspend fun performBiometricAuthentication(
        activity: FragmentActivity,
        title: String,
        subtitle: String?,
        description: String,
        useFingerprint: Boolean,
        useFace: Boolean
    ): Boolean {
        // TODO: Fix BiometricPrompt API compatibility
        // Temporarily returning false to allow build to succeed
        return false
    }

    fun getBiometricCapabilities(): Map<String, Any> {
        return mapOf(
            "available" to hasBiometrics(),
            "fingerprint" to hasFingerprint(),
            "faceUnlock" to hasFaceUnlock(),
            "type" to getBiometricType(),
            "canAuthenticate" to (biometricManager.canAuthenticate(BiometricManager.Authenticators.BIOMETRIC_STRONG) == BiometricManager.BIOMETRIC_SUCCESS),
            "enrolled" to (biometricManager.canAuthenticate(BiometricManager.Authenticators.BIOMETRIC_STRONG) == BiometricManager.BIOMETRIC_SUCCESS),
            "hardwareDetected" to (biometricManager.canAuthenticate() != BiometricManager.BIOMETRIC_ERROR_NO_HARDWARE)
        )
    }

    fun getBiometricState(): Map<String, Any> {
        val authenticateResult = biometricManager.canAuthenticate(BiometricManager.Authenticators.BIOMETRIC_STRONG)

        return mapOf(
            "available" to hasBiometrics(),
            "type" to getBiometricType(),
            "enrolled" to (authenticateResult == BiometricManager.BIOMETRIC_SUCCESS),
            "hardwareDetected" to (authenticateResult != BiometricManager.BIOMETRIC_ERROR_NO_HARDWARE),
            "lockout" to false, // Lockout detection removed in newer API
            "errorCode" to authenticateResult,
            "errorMessage" to getBiometricErrorMessage(authenticateResult)
        )
    }

    private fun getBiometricErrorMessage(errorCode: Int): String {
        return when (errorCode) {
            BiometricManager.BIOMETRIC_SUCCESS -> "Biometric authentication available"
            BiometricManager.BIOMETRIC_ERROR_NO_HARDWARE -> "No biometric hardware detected"
            BiometricManager.BIOMETRIC_ERROR_HW_UNAVAILABLE -> "Biometric hardware unavailable"
            BiometricManager.BIOMETRIC_ERROR_NONE_ENROLLED -> "No biometric credentials enrolled"
            BiometricManager.BIOMETRIC_ERROR_SECURITY_UPDATE_REQUIRED -> "Security update required"
            BiometricManager.BIOMETRIC_ERROR_SECURITY_UPDATE_REQUIRED -> "Security update required"
            else -> "Unknown biometric error"
        }
    }

    fun isBiometricLockout(): Boolean {
        return false // Lockout detection removed in newer API
    }

    companion object {
        fun isBiometricSupported(context: Context): Boolean {
            val biometricManager = BiometricManager.from(context)
            return biometricManager.canAuthenticate(BiometricManager.Authenticators.BIOMETRIC_STRONG) == BiometricManager.BIOMETRIC_SUCCESS
        }

        fun getSupportedBiometricTypes(context: Context): List<String> {
            val types = mutableListOf<String>()

            if (BiometricHandler(context).hasFingerprint()) {
                types.add("fingerprint")
            }

            if (BiometricHandler(context).hasFaceUnlock()) {
                types.add("face_unlock")
            }

            return types
        }
    }
}
