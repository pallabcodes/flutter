import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:finwise_payments/finwise_payments.dart';
import '../models/rental_models.dart';

/// Service for handling rent payments and payment processing
class RentPaymentService {
  final PaymentProcessor _paymentProcessor;
  final http.Client _client;

  RentPaymentService(this._paymentProcessor, this._client);

  /// Process rent payment
  Future<PaymentResult> processRentPayment({
    required RentalProperty property,
    required double amount,
    required PaymentMethod method,
    String? notes,
  }) async {
    try {
      final result = await _paymentProcessor.processPayment(
        amount: amount,
        currency: 'USD',
        method: method,
        metadata: {
          'type': 'rent_payment',
          'propertyId': property.id,
          'propertyName': property.name,
          'landlordEmail': property.landlordEmail,
        },
      );

      if (result.success) {
        // Create payment record
        final payment = RentPayment(
          id: result.transactionId,
          propertyId: property.id,
          userId: property.userId,
          amount: amount,
          lateFee: 0.0, // Calculate if overdue
          dueDate: _calculateNextDueDate(property),
          paidDate: DateTime.now(),
          status: 'paid',
          paymentMethod: method.toString(),
          transactionId: result.transactionId,
          notes: notes,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Send confirmation to landlord
        await _notifyLandlordOfPayment(property, payment);

        // Log expense in FinWise
        await _logRentExpense(property, payment);
      }

      return result;
    } catch (e) {
      throw RentPaymentException('Payment processing failed: ${e.toString()}');
    }
  }

  /// Schedule recurring rent payments
  Future<void> scheduleRecurringPayment({
    required RentalProperty property,
    required PaymentMethod method,
    required DateTime startDate,
    int numberOfPayments = 12, // Default 1 year
  }) async {
    final payments = <RentPayment>[];

    DateTime currentDueDate = startDate;
    for (int i = 0; i < numberOfPayments; i++) {
      final payment = RentPayment(
        id: 'scheduled_${property.id}_${i}',
        propertyId: property.id,
        userId: property.userId,
        amount: property.monthlyRent,
        lateFee: 0.0,
        dueDate: currentDueDate,
        status: 'scheduled',
        paymentMethod: method.toString(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      payments.add(payment);
      currentDueDate = _addMonths(currentDueDate, 1);
    }

    // Store scheduled payments
    await _storeScheduledPayments(payments);
  }

  /// Process automatic payment for scheduled rent
  Future<PaymentResult?> processAutomaticPayment({
    required RentPayment scheduledPayment,
    required RentalProperty property,
  }) async {
    if (scheduledPayment.status != 'scheduled') return null;

    // Check if payment is due (within 1 day of due date)
    final now = DateTime.now();
    final daysUntilDue = scheduledPayment.dueDate.difference(now).inDays;

    if (daysUntilDue > 1) return null; // Not due yet

    try {
      final result = await _paymentProcessor.processPayment(
        amount: scheduledPayment.amount,
        currency: 'USD',
        method: PaymentMethod.fromString(scheduledPayment.paymentMethod),
        metadata: {
          'type': 'automatic_rent_payment',
          'scheduledPaymentId': scheduledPayment.id,
          'propertyId': property.id,
        },
      );

      if (result.success) {
        // Update payment record
        final updatedPayment = scheduledPayment.copyWith(
          paidDate: DateTime.now(),
          status: 'paid',
          transactionId: result.transactionId,
          updatedAt: DateTime.now(),
        );

        await _updatePaymentRecord(updatedPayment);
        await _notifyLandlordOfPayment(property, updatedPayment);
        await _logRentExpense(property, updatedPayment);
      }

      return result;
    } catch (e) {
      // Mark payment as failed
      final failedPayment = scheduledPayment.copyWith(
        status: 'failed',
        notes: 'Automatic payment failed: ${e.toString()}',
        updatedAt: DateTime.now(),
      );

      await _updatePaymentRecord(failedPayment);
      throw RentPaymentException('Automatic payment failed: ${e.toString()}');
    }
  }

  /// Calculate late fees for overdue payments
  Future<double> calculateLateFees({
    required RentalProperty property,
    required DateTime dueDate,
    required double dailyLateFee,
    required int gracePeriodDays,
  }) async {
    final now = DateTime.now();
    final daysOverdue = now.difference(dueDate).inDays;

    if (daysOverdue <= gracePeriodDays) return 0.0;

    return daysOverdue * dailyLateFee;
  }

  /// Get payment history for a property
  Future<List<RentPayment>> getPaymentHistory({
    required String propertyId,
    int limit = 24, // Last 2 years
  }) async {
    // This would fetch from your backend API
    // For now, return mock data
    return _getMockPaymentHistory(propertyId, limit);
  }

  /// Get upcoming payments
  Future<List<RentPayment>> getUpcomingPayments({
    required String userId,
    int daysAhead = 30,
  }) async {
    final cutoffDate = DateTime.now().add(Duration(days: daysAhead));

    // Fetch scheduled payments due within the timeframe
    // For now, return mock data
    return _getMockUpcomingPayments(userId, cutoffDate);
  }

  /// Send payment receipt
  Future<void> sendPaymentReceipt({
    required RentPayment payment,
    required RentalProperty property,
    required String recipientEmail,
  }) async {
    // Generate PDF receipt
    final receiptPdf = await _generatePaymentReceipt(payment, property);

    // Send via email
    await _sendEmail(
      to: recipientEmail,
      subject: 'Rent Payment Receipt - ${property.name}',
      body: 'Please find your rent payment receipt attached.',
      attachment: receiptPdf,
    );
  }

  // Helper methods
  DateTime _calculateNextDueDate(RentalProperty property) {
    // Calculate the next due date based on lease terms
    // This is a simplified implementation
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month, property.leaseStartDate.day);

    if (currentMonth.isBefore(now)) {
      return DateTime(now.year, now.month + 1, property.leaseStartDate.day);
    }

    return currentMonth;
  }

  DateTime _addMonths(DateTime date, int months) {
    final newMonth = date.month + months;
    final newYear = date.year + (newMonth - 1) ~/ 12;
    final adjustedMonth = ((newMonth - 1) % 12) + 1;

    // Handle month-end dates
    final lastDayOfMonth = DateTime(newYear, adjustedMonth + 1, 0).day;
    final day = date.day > lastDayOfMonth ? lastDayOfMonth : date.day;

    return DateTime(newYear, adjustedMonth, day);
  }

  Future<void> _notifyLandlordOfPayment(RentalProperty property, RentPayment payment) async {
    // Send notification to landlord
    await _sendEmail(
      to: property.landlordEmail,
      subject: 'Rent Payment Received - ${property.name}',
      body: '''
Dear ${property.landlordName},

We are pleased to confirm that rent payment has been received for ${property.name}.

Payment Details:
- Amount: \$${payment.amount.toStringAsFixed(2)}
- Date: ${payment.paidDate?.toString() ?? 'N/A'}
- Property: ${property.name}
- Unit: ${property.unit}

Thank you for using RentWise for rent payments.

Best regards,
RentWise Team
      ''',
    );
  }

  Future<void> _logRentExpense(RentalProperty property, RentPayment payment) async {
    // Integration with FinWise expense tracking
    // This would automatically categorize the payment as housing expense
    await FinWiseExpenseTracker.logExpense(
      amount: payment.amount,
      category: 'Housing',
      subcategory: 'Rent',
      description: 'Rent payment for ${property.name}',
      date: payment.paidDate ?? DateTime.now(),
      metadata: {
        'propertyId': property.id,
        'landlord': property.landlordName,
        'paymentMethod': payment.paymentMethod,
      },
    );
  }

  Future<List<int>> _generatePaymentReceipt(RentPayment payment, RentalProperty property) async {
    // Generate PDF receipt using pdf package
    // This is a simplified implementation
    return []; // Return PDF bytes
  }

  Future<void> _sendEmail({
    required String to,
    required String subject,
    required String body,
    List<int>? attachment,
  }) async {
    // Send email via your email service
    // Implementation depends on your email provider
  }

  Future<void> _storeScheduledPayments(List<RentPayment> payments) async {
    // Store in local database
    for (final payment in payments) {
      await _storePaymentRecord(payment);
    }
  }

  Future<void> _storePaymentRecord(RentPayment payment) async {
    // Store in local database
    // Implementation depends on your storage solution
  }

  Future<void> _updatePaymentRecord(RentPayment payment) async {
    // Update payment record in database
  }

  // Mock data for development
  List<RentPayment> _getMockPaymentHistory(String propertyId, int limit) {
    final payments = <RentPayment>[];
    final now = DateTime.now();

    for (int i = 0; i < limit; i++) {
      final paymentDate = DateTime(now.year, now.month - i, 1);
      final isPaid = i < 2; // Last 2 payments paid, others pending

      payments.add(RentPayment(
        id: 'payment_${propertyId}_$i',
        propertyId: propertyId,
        userId: 'user_123',
        amount: 1200.0,
        lateFee: isPaid ? 0.0 : (i == 1 ? 25.0 : 0.0),
        dueDate: paymentDate,
        paidDate: isPaid ? paymentDate : null,
        status: isPaid ? 'paid' : 'pending',
        paymentMethod: 'bank_account',
        transactionId: isPaid ? 'txn_${i}' : null,
        createdAt: paymentDate,
        updatedAt: paymentDate,
      ));
    }

    return payments;
  }

  List<RentPayment> _getMockUpcomingPayments(String userId, DateTime cutoffDate) {
    final payments = <RentPayment>[];
    final now = DateTime.now();

    // Add next 3 months of rent payments
    for (int i = 0; i < 3; i++) {
      final dueDate = DateTime(now.year, now.month + i, 1);
      if (dueDate.isBefore(cutoffDate)) {
        payments.add(RentPayment(
          id: 'upcoming_$i',
          propertyId: 'property_123',
          userId: userId,
          amount: 1200.0,
          lateFee: 0.0,
          dueDate: dueDate,
          status: 'scheduled',
          paymentMethod: 'bank_account',
          createdAt: now,
          updatedAt: now,
        ));
      }
    }

    return payments;
  }
}

/// Exception for rent payment errors
class RentPaymentException implements Exception {
  final String message;

  RentPaymentException(this.message);

  @override
  String toString() => 'RentPaymentException: $message';
}

/// Mock implementations for development
class MockRentPaymentService extends RentPaymentService {
  MockRentPaymentService(super.paymentProcessor, super.client);

  @override
  Future<PaymentResult> processRentPayment({
    required RentalProperty property,
    required double amount,
    required PaymentMethod method,
    String? notes,
  }) async {
    // Simulate payment processing delay
    await Future.delayed(const Duration(seconds: 2));

    // Mock successful payment
    return PaymentResult(
      success: true,
      transactionId: 'mock_txn_${DateTime.now().millisecondsSinceEpoch}',
      amount: amount,
      currency: 'USD',
      timestamp: DateTime.now(),
    );
  }
}
