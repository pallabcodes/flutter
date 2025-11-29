package com.finwise.native

import android.content.Context
import com.google.android.gms.wallet.*
import com.google.android.gms.tasks.Task
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

        return PaymentDataRequest.newBuilder()
            .setTransactionInfo(transactionInfo)
            .addAllowedPaymentMethod(WalletConstants.PAYMENT_METHOD_CARD)
            .addAllowedPaymentMethod(WalletConstants.PAYMENT_METHOD_TOKENIZED_CARD)
            .addAllowedCardNetwork(WalletConstants.CARD_NETWORK_VISA)
            .addAllowedCardNetwork(WalletConstants.CARD_NETWORK_MASTERCARD)
            .addAllowedCardNetwork(WalletConstants.CARD_NETWORK_AMEX)
            .addAllowedCardNetwork(WalletConstants.CARD_NETWORK_DISCOVER)
            .setPaymentMethodTokenizationParameters(paymentMethodTokenization)
            .setEmailRequired(false)
            .setShippingAddressRequired(false)
            .setPhoneNumberRequired(false)
            .build()
    }

    private fun createTransactionInfo(amount: Double, currency: String, description: String): TransactionInfo {
        return TransactionInfo.newBuilder()
            .setTotalPriceStatus(WalletConstants.TOTAL_PRICE_STATUS_FINAL)
            .setTotalPrice(amount.toString())
            .setCurrencyCode(currency)
            .setCountryCode("US")
            .setTransactionId(java.util.UUID.randomUUID().toString())
            .build()
    }

    private fun createPaymentMethodTokenization(): JSONObject {
        return JSONObject().apply {
            put("type", "PAYMENT_GATEWAY")
            put("parameters", JSONObject().apply {
                put("gateway", "example")
                put("gatewayMerchantId", "exampleGatewayMerchantId")
            })
        }
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
            is com.google.android.gms.common.api.ApiException -> {
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
        val json = JSONObject(paymentData.toJson())

        return mapOf(
            "paymentMethod" to "google_pay",
            "amount" to json.optJSONObject("transactionInfo")?.optString("totalPrice"),
            "currency" to json.optJSONObject("transactionInfo")?.optString("currencyCode"),
            "timestamp" to System.currentTimeMillis() / 1000.0,
            "paymentMethodData" to mapOf(
                "description" to json.optJSONObject("paymentMethodData")?.optJSONObject("info")?.optString("cardDetails"),
                "network" to json.optJSONObject("paymentMethodData")?.optJSONObject("info")?.optString("cardNetwork"),
                "tokenizationData" to json.optJSONObject("paymentMethodData")?.optJSONObject("tokenizationData")?.toString()
            )
        )
    }

    fun getPaymentMethods(): Task<JSONArray> {
        return paymentsClient.getPaymentMethods(createPaymentMethodsRequest())
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
        return paymentsClient.isReadyToPay(request).isSuccessful
    }

    fun getGooglePayConfiguration(): Map<String, Any> {
        return mapOf(
            "environment" to if (PAYMENTS_ENVIRONMENT == WalletConstants.ENVIRONMENT_PRODUCTION) "production" else "test",
            "supportedNetworks" to SUPPORTED_NETWORKS,
            "supportedMethods" to SUPPORTED_METHODS,
            "isReadyToPay" to isGooglePayAvailable()
        )
    }
}
