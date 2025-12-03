import 'dart:async';
import 'package:finwise_core/finwise_core.dart';
import '../models/rental_models.dart';
import '../datasources/rent_payment_service.dart';

/// Repository for rental property and payment data operations
class RentalRepository {
  final RentPaymentService _paymentService;
  final SecureStorageService _storage;
  final LocalDatabaseService _database;

  RentalRepository(this._paymentService, this._storage, this._database);

  /// Get all rental properties for a user
  Future<Either<Failure, List<RentalProperty>>> getRentalProperties({
    required String userId,
  }) async {
    try {
      final properties = await _database.getRentalProperties(userId);
      return Right(properties);
    } catch (e) {
      return Left(RentalDataFailure('Failed to load rental properties: ${e.toString()}'));
    }
  }

  /// Add a new rental property
  Future<Either<Failure, RentalProperty>> addRentalProperty({
    required RentalProperty property,
  }) async {
    try {
      final savedProperty = await _database.saveRentalProperty(property);
      return Right(savedProperty);
    } catch (e) {
      return Left(RentalDataFailure('Failed to save rental property: ${e.toString()}'));
    }
  }

  /// Update an existing rental property
  Future<Either<Failure, RentalProperty>> updateRentalProperty({
    required RentalProperty property,
  }) async {
    try {
      final updatedProperty = await _database.updateRentalProperty(property);
      return Right(updatedProperty);
    } catch (e) {
      return Left(RentalDataFailure('Failed to update rental property: ${e.toString()}'));
    }
  }

  /// Delete a rental property
  Future<Either<Failure, void>> deleteRentalProperty({
    required String propertyId,
  }) async {
    try {
      await _database.deleteRentalProperty(propertyId);
      return const Right(null);
    } catch (e) {
      return Left(RentalDataFailure('Failed to delete rental property: ${e.toString()}'));
    }
  }

  /// Process rent payment
  Future<Either<Failure, PaymentResult>> processRentPayment({
    required RentalProperty property,
    required double amount,
    required PaymentMethod method,
    String? notes,
  }) async {
    try {
      final result = await _paymentService.processRentPayment(
        property: property,
        amount: amount,
        method: method,
        notes: notes,
      );

      if (result.success) {
        // Save payment record
        await _savePaymentRecord(property, result, notes);
      }

      return Right(result);
    } catch (e) {
      return Left(RentalPaymentFailure('Payment processing failed: ${e.toString()}'));
    }
  }

  /// Get payment history for a property
  Future<Either<Failure, List<RentPayment>>> getPaymentHistory({
    required String propertyId,
    int limit = 24,
  }) async {
    try {
      final payments = await _paymentService.getPaymentHistory(
        propertyId: propertyId,
        limit: limit,
      );
      return Right(payments);
    } catch (e) {
      return Left(RentalDataFailure('Failed to load payment history: ${e.toString()}'));
    }
  }

  /// Get upcoming payments for all properties
  Future<Either<Failure, List<RentPayment>>> getUpcomingPayments({
    required String userId,
    int daysAhead = 30,
  }) async {
    try {
      final payments = await _paymentService.getUpcomingPayments(
        userId: userId,
        daysAhead: daysAhead,
      );
      return Right(payments);
    } catch (e) {
      return Left(RentalDataFailure('Failed to load upcoming payments: ${e.toString()}'));
    }
  }

  /// Schedule recurring rent payments
  Future<Either<Failure, void>> scheduleRecurringPayments({
    required RentalProperty property,
    required PaymentMethod method,
    required DateTime startDate,
    int numberOfPayments = 12,
  }) async {
    try {
      await _paymentService.scheduleRecurringPayment(
        property: property,
        method: method,
        startDate: startDate,
        numberOfPayments: numberOfPayments,
      );
      return const Right(null);
    } catch (e) {
      return Left(RentalPaymentFailure('Failed to schedule payments: ${e.toString()}'));
    }
  }

  /// Submit maintenance request
  Future<Either<Failure, MaintenanceRequest>> submitMaintenanceRequest({
    required MaintenanceRequest request,
    required List<String> photoPaths,
  }) async {
    try {
      // Upload photos
      final photoUrls = await _uploadPhotos(photoPaths);

      // Create maintenance request with photo URLs
      final requestWithPhotos = request.copyWith(photoUrls: photoUrls);

      // Save to database
      final savedRequest = await _database.saveMaintenanceRequest(requestWithPhotos);

      // Notify landlord
      await _notifyLandlordOfMaintenance(savedRequest);

      return Right(savedRequest);
    } catch (e) {
      return Left(RentalDataFailure('Failed to submit maintenance request: ${e.toString()}'));
    }
  }

  /// Get maintenance requests for a property
  Future<Either<Failure, List<MaintenanceRequest>>> getMaintenanceRequests({
    required String propertyId,
  }) async {
    try {
      final requests = await _database.getMaintenanceRequests(propertyId);
      return Right(requests);
    } catch (e) {
      return Left(RentalDataFailure('Failed to load maintenance requests: ${e.toString()}'));
    }
  }

  /// Send message to landlord
  Future<Either<Failure, LandlordMessage>> sendMessageToLandlord({
    required LandlordMessage message,
    required List<String> attachmentPaths,
  }) async {
    try {
      // Upload attachments if any
      final attachmentUrls = await _uploadAttachments(attachmentPaths);

      // Create message with attachments
      final messageWithAttachments = LandlordMessage(
        id: message.id,
        propertyId: message.propertyId,
        userId: message.userId,
        senderId: message.senderId,
        senderType: message.senderType,
        subject: message.subject,
        message: message.message,
        attachmentUrls: attachmentUrls,
        isRead: message.isRead,
        sentAt: message.sentAt,
        threadId: message.threadId,
      );

      // Save message
      final savedMessage = await _database.saveLandlordMessage(messageWithAttachments);

      // Send notification to landlord
      await _notifyLandlordOfMessage(savedMessage);

      return Right(savedMessage);
    } catch (e) {
      return Left(RentalDataFailure('Failed to send message: ${e.toString()}'));
    }
  }

  /// Get message history with landlord
  Future<Either<Failure, List<LandlordMessage>>> getMessageHistory({
    required String propertyId,
    String? threadId,
  }) async {
    try {
      final messages = await _database.getLandlordMessages(propertyId, threadId);
      return Right(messages);
    } catch (e) {
      return Left(RentalDataFailure('Failed to load messages: ${e.toString()}'));
    }
  }

  /// Upload rental document
  Future<Either<Failure, RentalDocument>> uploadDocument({
    required RentalDocument document,
    required String filePath,
  }) async {
    try {
      // Upload file to cloud storage
      final fileUrl = await _uploadFile(filePath, document.type);

      // Extract text from document if it's a lease or receipt
      String? extractedText;
      if (document.type == 'lease' || document.type == 'receipt') {
        extractedText = await _extractTextFromDocument(filePath);
      }

      // Create document record
      final documentWithUrl = RentalDocument(
        id: document.id,
        propertyId: document.propertyId,
        userId: document.userId,
        name: document.name,
        type: document.type,
        fileUrl: fileUrl,
        extractedText: extractedText,
        metadata: document.metadata,
        uploadedAt: document.uploadedAt,
        expiresAt: document.expiresAt,
        isEncrypted: document.isEncrypted,
      );

      // Save to database
      final savedDocument = await _database.saveRentalDocument(documentWithUrl);

      return Right(savedDocument);
    } catch (e) {
      return Left(RentalDataFailure('Failed to upload document: ${e.toString()}'));
    }
  }

  /// Get documents for a property
  Future<Either<Failure, List<RentalDocument>>> getPropertyDocuments({
    required String propertyId,
  }) async {
    try {
      final documents = await _database.getRentalDocuments(propertyId);
      return Right(documents);
    } catch (e) {
      return Left(RentalDataFailure('Failed to load documents: ${e.toString()}'));
    }
  }

  /// Calculate total housing expenses for the month
  Future<Either<Failure, double>> calculateMonthlyHousingExpenses({
    required String userId,
    required DateTime month,
  }) async {
    try {
      final properties = await _database.getRentalProperties(userId);
      double totalExpenses = 0.0;

      for (final property in properties) {
        // Sum rent payments for the month
        final payments = await _paymentService.getPaymentHistory(
          propertyId: property.id,
          limit: 1,
        );

        if (payments.isNotEmpty) {
          final recentPayment = payments.first;
          totalExpenses += recentPayment.amount + recentPayment.lateFee;
        } else {
          // Estimate based on monthly rent
          totalExpenses += property.monthlyRent;
        }
      }

      return Right(totalExpenses);
    } catch (e) {
      return Left(RentalDataFailure('Failed to calculate housing expenses: ${e.toString()}'));
    }
  }

  // Helper methods
  Future<void> _savePaymentRecord(
    RentalProperty property,
    PaymentResult result,
    String? notes,
  ) async {
    final payment = RentPayment(
      id: result.transactionId,
      propertyId: property.id,
      userId: property.userId,
      amount: result.amount,
      lateFee: 0.0, // Calculate if overdue
      dueDate: DateTime.now(), // Current due date
      paidDate: result.timestamp,
      status: 'paid',
      paymentMethod: 'card', // From payment method
      transactionId: result.transactionId,
      notes: notes,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _database.saveRentPayment(payment);
  }

  Future<List<String>> _uploadPhotos(List<String> photoPaths) async {
    // Upload photos to cloud storage
    final urls = <String>[];
    for (final path in photoPaths) {
      final url = await _uploadFile(path, 'photo');
      urls.add(url);
    }
    return urls;
  }

  Future<List<String>> _uploadAttachments(List<String> attachmentPaths) async {
    final urls = <String>[];
    for (final path in attachmentPaths) {
      final url = await _uploadFile(path, 'attachment');
      urls.add(url);
    }
    return urls;
  }

  Future<String> _uploadFile(String filePath, String type) async {
    // Upload to Firebase Storage or your cloud storage
    // Return the download URL
    return 'https://storage.example.com/files/${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<String?> _extractTextFromDocument(String filePath) async {
    // Use ML Kit or other OCR service to extract text
    // Return extracted text or null if extraction fails
    return null;
  }

  Future<void> _notifyLandlordOfMaintenance(MaintenanceRequest request) async {
    // Send notification to landlord via email/push
    // Implementation depends on your notification system
  }

  Future<void> _notifyLandlordOfMessage(LandlordMessage message) async {
    // Send notification to landlord
    // Implementation depends on your notification system
  }
}

/// Rental-specific failure types
class RentalDataFailure extends Failure {
  const RentalDataFailure(String message) : super(message: message);
}

class RentalPaymentFailure extends Failure {
  const RentalPaymentFailure(String message) : super(message: message);
}

/// Repository provider for dependency injection
final rentalRepositoryProvider = Provider<RentalRepository>((ref) {
  final paymentService = ref.watch(rentPaymentServiceProvider);
  final storage = ref.watch(secureStorageProvider);
  final database = ref.watch(localDatabaseProvider);
  return RentalRepository(paymentService, storage, database);
});

/// Service providers
final rentPaymentServiceProvider = Provider<RentPaymentService>((ref) {
  final paymentProcessor = ref.watch(paymentProcessorProvider);
  final client = ref.watch(httpClientProvider);
  return RentPaymentService(paymentProcessor, client);
});

final localDatabaseProvider = Provider<LocalDatabaseService>((ref) {
  return LocalDatabaseService();
});

/// Mock provider for development
final mockRentalRepositoryProvider = Provider<RentalRepository>((ref) {
  final paymentService = ref.watch(mockRentPaymentServiceProvider);
  final storage = ref.watch(secureStorageProvider);
  final database = ref.watch(localDatabaseProvider);
  return RentalRepository(paymentService, storage, database);
});

final mockRentPaymentServiceProvider = Provider<RentPaymentService>((ref) {
  final paymentProcessor = ref.watch(paymentProcessorProvider);
  final client = ref.watch(httpClientProvider);
  return MockRentPaymentService(paymentProcessor, client);
});
