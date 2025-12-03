import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:finwise/core/errors/failure.dart';

/// Repository interface for receipt scanning operations
abstract class ReceiptScannerRepository {
  /// Scan receipt from image file and extract expense data
  Future<Either<Failure, ReceiptScanResult>> scanReceipt(File imageFile);

  /// Check if camera permission is granted
  Future<Either<Failure, bool>> checkCameraPermission();

  /// Request camera permission
  Future<Either<Failure, bool>> requestCameraPermission();

  /// Check if storage permission is granted (for saving images)
  Future<Either<Failure, bool>> checkStoragePermission();

  /// Request storage permission
  Future<Either<Failure, bool>> requestStoragePermission();
}

/// Result of receipt scanning operation
class ReceiptScanResult {
  final String rawText;
  final ParsedReceiptData? parsedData;
  final double confidence;
  final List<String> extractedItems;

  const ReceiptScanResult({
    required this.rawText,
    this.parsedData,
    required this.confidence,
    required this.extractedItems,
  });

  /// Create result with no parsed data
  factory ReceiptScanResult.rawText(String text) {
    return ReceiptScanResult(
      rawText: text,
      confidence: 0.0,
      extractedItems: [],
    );
  }

  /// Check if parsing was successful
  bool get hasParsedData => parsedData != null;

  /// Get formatted confidence percentage
  String get confidencePercentage => '${(confidence * 100).round()}%';
}

/// Parsed data extracted from receipt
class ParsedReceiptData {
  final String? merchantName;
  final DateTime? date;
  final double? totalAmount;
  final String? currency;
  final List<ReceiptItem> items;
  final String? taxAmount;
  final String? subtotal;

  const ParsedReceiptData({
    this.merchantName,
    this.date,
    this.totalAmount,
    this.currency,
    this.items = const [],
    this.taxAmount,
    this.subtotal,
  });

  /// Check if we have meaningful parsed data
  bool get hasData =>
      merchantName != null ||
      date != null ||
      totalAmount != null ||
      items.isNotEmpty;

  /// Create a copy with updated fields
  ParsedReceiptData copyWith({
    String? merchantName,
    DateTime? date,
    double? totalAmount,
    String? currency,
    List<ReceiptItem>? items,
    String? taxAmount,
    String? subtotal,
  }) {
    return ParsedReceiptData(
      merchantName: merchantName ?? this.merchantName,
      date: date ?? this.date,
      totalAmount: totalAmount ?? this.totalAmount,
      currency: currency ?? this.currency,
      items: items ?? this.items,
      taxAmount: taxAmount ?? this.taxAmount,
      subtotal: subtotal ?? this.subtotal,
    );
  }
}

/// Individual item from receipt
class ReceiptItem {
  final String description;
  final double? price;
  final int? quantity;

  const ReceiptItem({
    required this.description,
    this.price,
    this.quantity,
  });

  /// Get total price for this item
  double? get totalPrice {
    if (price == null) return null;
    if (quantity == null) return price;
    return price! * quantity!;
  }

  /// Create item from string description
  factory ReceiptItem.fromDescription(String description) {
    return ReceiptItem(description: description.trim());
  }
}

/// Receipt scanning configuration
class ReceiptScanConfig {
  final bool enableTextRecognition;
  final bool enableSmartParsing;
  final bool enableItemExtraction;
  final int maxProcessingTimeSeconds;
  final double minConfidenceThreshold;

  const ReceiptScanConfig({
    this.enableTextRecognition = true,
    this.enableSmartParsing = true,
    this.enableItemExtraction = true,
    this.maxProcessingTimeSeconds = 30,
    this.minConfidenceThreshold = 0.6,
  });

  /// Default configuration
  factory ReceiptScanConfig.defaultConfig() => const ReceiptScanConfig();

  /// High accuracy configuration (slower)
  factory ReceiptScanConfig.highAccuracy() => const ReceiptScanConfig(
    maxProcessingTimeSeconds: 60,
    minConfidenceThreshold: 0.8,
  );
}
