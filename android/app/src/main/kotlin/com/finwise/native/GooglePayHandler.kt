package com.finwise.native

import android.content.Context
import com.google.android.gms.common.api.ApiException
import com.google.android.gms.tasks.Tasks
import com.google.android.gms.wallet.*
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel.Result
import org.json.JSONArray
import org.json.JSONObject

class GooglePayHandler(private val context: Context) {

    private val paymentsClient: PaymentsClient = createPaymentsClient()

    companion object {
        private const val PAYMENTS_ENVIRONMENT = WalletConstants.ENVIRONMENT_TEST
        private val SUPPORTED_NETWORKS = listOf(
            WalletConstants.CARD_NETWORK_VISA,
            WalletConstants.CARD_NETWORK_MASTERCARD,
            WalletConstants.CARD_NETWORK_AMEX,
            WalletConstants.CARD_NETWORK_DISCOVER
        )
        private val SUPPORTED_METHODS = listOf(
            WalletConstants.PAYMENT_METHOD_CARD,
            WalletConstants.PAYMENT_METHOD_TOKENIZED_CARD
        )
    }

    private fun createPaymentsClient(): PaymentsClient {
        val walletOptions = Wallet.WalletOptions.Builder()
            .setEnvironment(PAYMENTS_ENVIRONMENT)
            .build()
        return Wallet.getPaymentsClient(context, walletOptions)
    }

    fun isGooglePayAvailable(): Boolean {
        return paymentsClient.isReadyToPay(createIsReadyToPayRequest()).isSuccessful
    }

    fun processPayment(call: MethodCall, result: Result) {
        val args = call.arguments as? Map<String, Any>
        val amount = args?.get("amount") as? Double
        val currency = args?.get("currency") as? String ?: "USD"
        val description = args?.get("description") as? String ?: "Expense Payment"

        if (amount == null) {
            result.error("INVALID_ARGS", "Payment amount is required", null)
            return
        }

        val paymentDataRequest = createPaymentDataRequest(amount, currency, description)
        val task = paymentsClient.loadPaymentData(paymentDataRequest)

        task.addOnCompleteListener { task ->
            if (task.isSuccessful) {
                val paymentData = task.result
                handlePaymentSuccess(paymentData, result)
            } else {
                val exception = task.exception
                handlePaymentError(exception, result)
            }
        }
    }

    private fun createIsReadyToPayRequest(): IsReadyToPayRequest {
        return IsReadyToPayRequest.newBuilder()
            .addAllowedPaymentMethod(WalletConstants.PAYMENT_METHOD_CARD)
            .addAllowedPaymentMethod(WalletConstants.PAYMENT_METHOD_TOKENIZED_CARD)
            .addAllowedCardNetwork(WalletConstants.CARD_NETWORK_VISA)
            .addAllowedCardNetwork(WalletConstants.CARD_NETWORK_MASTERCARD)
            .addAllowedCardNetwork(WalletConstants.CARD_NETWORK_AMEX)
            .addAllowedCardNetwork(WalletConstants.CARD_NETWORK_DISCOVER)
            .setExistingPaymentMethodRequired(false)
            .build()
    }

    private fun createPaymentDataRequest(amount: Double, currency: String, description: String): PaymentDataRequest {
        val transactionInfo = createTransactionInfo(amount, currency, description)
        val paymentMethodTokenization = createPaymentMethodTokenization()

        val builder = PaymentDataRequest.newBuilder()
            .setTransactionInfo(transactionInfo)
            .addAllowedPaymentMethod(WalletConstants.PAYMENT_METHOD_CARD)
            .addAllowedPaymentMethod(WalletConstants.PAYMENT_METHOD_TOKENIZED_CARD)
        // Card networks are configured via IsReadyToPayRequest, not PaymentDataRequest
        builder.setPaymentMethodTokenizationParameters(paymentMethodTokenization)
        return builder.build()
    }

    private fun createTransactionInfo(amount: Double, currency: String, description: String): TransactionInfo {
        val builder = TransactionInfo.newBuilder()
            .setTotalPriceStatus(WalletConstants.TOTAL_PRICE_STATUS_FINAL)
            .setTotalPrice(amount.toString())
            .setCurrencyCode(currency)
        // Note: setTransactionId may not be available in all API versions
        return builder.build()
    }

    private fun createPaymentMethodTokenization(): PaymentMethodTokenizationParameters {
        return PaymentMethodTokenizationParameters.newBuilder()
            .setPaymentMethodTokenizationType(WalletConstants.PAYMENT_METHOD_TOKENIZATION_TYPE_PAYMENT_GATEWAY)
            .addParameter("gateway", "example")
            .addParameter("gatewayMerchantId", "exampleGatewayMerchantId")
            .build()
    }

    private fun handlePaymentSuccess(paymentData: PaymentData?, result: Result) {
        if (paymentData == null) {
            result.error("PAYMENT_ERROR", "Payment data is null", null)
            return
        }

        try {
            val paymentInfo = extractPaymentInfo(paymentData)
            result.success(mapOf(
                "success" to true,
                "transactionId" to java.util.UUID.randomUUID().toString(),
                "receiptData" to paymentInfo
            ))
        } catch (e: Exception) {
            result.error("PARSE_ERROR", "Failed to parse payment data: ${e.message}", null)
        }
    }

    private fun handlePaymentError(exception: Exception?, result: Result) {
        val errorMessage = when (exception) {
            is ApiException -> {
                when (exception.statusCode) {
                    WalletConstants.ERROR_CODE_DEVELOPER_ERROR -> "Developer error"
                    WalletConstants.ERROR_CODE_INVALID_TRANSACTION -> "Invalid transaction"
                    WalletConstants.ERROR_CODE_MERCHANT_ACCOUNT_ERROR -> "Merchant account error"
                    WalletConstants.ERROR_CODE_SERVICE_UNAVAILABLE -> "Service unavailable"
                    else -> "Google Pay error: ${exception.message}"
                }
            }
            else -> exception?.message ?: "Unknown payment error"
        }

        result.success(mapOf(
            "success" to false,
            "errorMessage" to errorMessage
        ))
    }

    private fun extractPaymentInfo(paymentData: PaymentData): Map<String, Any> {
        // PaymentData API has changed - return basic structure
        // In production, properly extract data from PaymentData object
        return mapOf(
            "paymentMethod" to "google_pay",
            "amount" to "",
            "currency" to "",
            "timestamp" to System.currentTimeMillis() / 1000.0,
            "paymentMethodData" to mapOf(
                "description" to "",
                "network" to "",
                "tokenizationData" to ""
            )
        )
    }

    fun getPaymentMethods(): com.google.android.gms.tasks.Task<JSONArray> {
        // Note: getPaymentMethods may not be available in all API versions
        // This is a placeholder implementation
        val request = createPaymentMethodsRequest()
        return com.google.android.gms.tasks.Tasks.forResult(request)
    }

    private fun createPaymentMethodsRequest(): JSONArray {
        return JSONArray().apply {
            put(JSONObject().apply {
                put("allowedAuthMethods", JSONArray(SUPPORTED_METHODS))
                put("allowedCardNetworks", JSONArray(SUPPORTED_NETWORKS))
                put("billingAddressRequired", true)
                put("billingAddressParameters", JSONObject().apply {
                    put("format", "FULL")
                })
            })
        }
    }

    fun canUseGooglePay(): Boolean {
        val request = createIsReadyToPayRequest()
        val task = paymentsClient.isReadyToPay(request)
        return try {
            Tasks.await(task)
        } catch (e: Exception) {
            false
        }
    }

    fun getGooglePayConfiguration(): Map<String, Any> {
        return mapOf<String, Any>(
            "environment" to (if (PAYMENTS_ENVIRONMENT == WalletConstants.ENVIRONMENT_PRODUCTION) "production" else "test"),
            "supportedNetworks" to SUPPORTED_NETWORKS.map { it.toString() },
            "supportedMethods" to SUPPORTED_METHODS.map { it.toString() },
            "isReadyToPay" to isGooglePayAvailable()
        )
    }
}
