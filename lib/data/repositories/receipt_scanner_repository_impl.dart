import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:finwise/core/errors/failure.dart';
import 'package:finwise/domain/repositories/receipt_scanner_repository.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:injectable/injectable.dart';

@injectable
class ReceiptScannerRepositoryImpl implements ReceiptScannerRepository {
  final TextRecognizer _textRecognizer;

  ReceiptScannerRepositoryImpl()
      : _textRecognizer = GoogleMlKit.vision.textRecognizer();

  @override
  Future<Either<Failure, ReceiptScanResult>> scanReceipt(File imageFile) async {
    try {
      // Check if file exists and is readable
      if (!await imageFile.exists()) {
        return Left(FileFailure.notFound(imageFile.path));
      }

      // Create input image from file
      final inputImage = InputImage.fromFile(imageFile);

      // Perform text recognition
      final recognizedText = await _textRecognizer.processImage(inputImage);

      if (recognizedText.text.isEmpty) {
        return Left(ValidationFailure('No text found in image. Please try a clearer photo.'));
      }

      // Parse the recognized text
      final parsedData = _parseReceiptText(recognizedText.text);
      final confidence = _calculateConfidence(recognizedText);

      // Extract individual items
      final extractedItems = _extractItems(recognizedText);

      final result = ReceiptScanResult(
        rawText: recognizedText.text,
        parsedData: parsedData,
        confidence: confidence,
        extractedItems: extractedItems,
      );

      return Right(result);
    } catch (e) {
      return Left(UnexpectedFailure.withMessage('Receipt scanning failed: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, bool>> checkCameraPermission() async {
    try {
      final status = await Permission.camera.status;
      return Right(status.isGranted);
    } catch (e) {
      return Left(PermissionFailure.cameraDenied());
    }
  }

  @override
  Future<Either<Failure, bool>> requestCameraPermission() async {
    try {
      final status = await Permission.camera.request();
      return Right(status.isGranted);
    } catch (e) {
      return Left(PermissionFailure.cameraDenied());
    }
  }

  @override
  Future<Either<Failure, bool>> checkStoragePermission() async {
    try {
      final status = await Permission.storage.status;
      return Right(status.isGranted);
    } catch (e) {
      return Left(PermissionFailure.storageDenied());
    }
  }

  @override
  Future<Either<Failure, bool>> requestStoragePermission() async {
    try {
      final status = await Permission.storage.request();
      return Right(status.isGranted);
    } catch (e) {
      return Left(PermissionFailure.storageDenied());
    }
  }

  /// Parse receipt text to extract structured data
  ParsedReceiptData? _parseReceiptText(String text) {
    final lines = text.split('\n').map((line) => line.trim()).where((line) => line.isNotEmpty).toList();

    String? merchantName;
    DateTime? date;
    double? totalAmount;
    String? currency;
    final items = <ReceiptItem>[];
    String? taxAmount;
    String? subtotal;

    // Look for merchant name (usually at the top)
    if (lines.isNotEmpty) {
      merchantName = _extractMerchantName(lines.first);
    }

    // Process each line
    for (final line in lines) {
      final lowerLine = line.toLowerCase();

      // Look for total amount
      if (_isTotalLine(lowerLine)) {
        final amount = _extractAmount(line);
        if (amount != null) {
          totalAmount = amount;
          currency = _extractCurrency(line);
        }
      }

      // Look for tax
      else if (_isTaxLine(lowerLine)) {
        taxAmount = _extractAmountString(line);
      }

      // Look for subtotal
      else if (_isSubtotalLine(lowerLine)) {
        subtotal = _extractAmountString(line);
      }

      // Look for date
      else if (date == null) {
        date = _extractDate(line);
      }

      // Look for item lines
      else if (_isItemLine(line)) {
        final item = _parseItemLine(line);
        if (item != null) {
          items.add(item);
        }
      }
    }

    // If we found meaningful data, return it
    final parsedData = ParsedReceiptData(
      merchantName: merchantName,
      date: date,
      totalAmount: totalAmount,
      currency: currency ?? 'USD',
      items: items,
      taxAmount: taxAmount,
      subtotal: subtotal,
    );

    return parsedData.hasData ? parsedData : null;
  }

  /// Calculate confidence score based on text recognition results
  double _calculateConfidence(RecognizedText recognizedText) {
    if (recognizedText.blocks.isEmpty) return 0.0;

    double totalConfidence = 0.0;
    int totalLines = 0;

    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        totalConfidence += line.confidence;
        totalLines++;
      }
    }

    return totalLines > 0 ? totalConfidence / totalLines : 0.0;
  }

  /// Extract individual items from recognized text
  List<String> _extractItems(RecognizedText recognizedText) {
    final items = <String>[];

    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        final text = line.text.trim();
        if (_isItemLine(text) && text.length > 3) {
          items.add(text);
        }
      }
    }

    return items.take(10).toList(); // Limit to first 10 items
  }

  /// Extract merchant name from the first line
  String? _extractMerchantName(String firstLine) {
    // Remove common receipt headers
    final cleaned = firstLine
        .replaceAll(RegExp(r'(receipt|invoice|bill)', caseSensitive: false), '')
        .trim();

    if (cleaned.length > 3 && cleaned.length < 50) {
      return cleaned;
    }
    return null;
  }

  /// Check if line contains total amount
  bool _isTotalLine(String line) {
    return line.contains('total') ||
           line.contains('grand total') ||
           line.startsWith('total:') ||
           line.contains('amount due');
  }

  /// Check if line contains tax
  bool _isTaxLine(String line) {
    return line.contains('tax') ||
           line.contains('vat') ||
           line.contains('gst');
  }

  /// Check if line contains subtotal
  bool _isSubtotalLine(String line) {
    return line.contains('subtotal') ||
           line.contains('sub-total') ||
           line.contains('net amount');
  }

  /// Check if line looks like an item
  bool _isItemLine(String line) {
    // Items typically have prices at the end
    final pricePattern = RegExp(r'\$?\d+\.?\d*$');
    return pricePattern.hasMatch(line) && line.length > 5 && line.length < 100;
  }

  /// Extract amount from line
  double? _extractAmount(String line) {
    final amountPattern = RegExp(r'[\$]?\d+\.?\d{2}');
    final match = amountPattern.firstMatch(line);
    if (match != null) {
      final amountString = match.group(0)?.replaceAll('\$', '') ?? '';
      return double.tryParse(amountString);
    }
    return null;
  }

  /// Extract amount as string
  String? _extractAmountString(String line) {
    final amount = _extractAmount(line);
    return amount?.toStringAsFixed(2);
  }

  /// Extract currency symbol
  String _extractCurrency(String line) {
    if (line.contains('\$')) return 'USD';
    if (line.contains('€')) return 'EUR';
    if (line.contains('£')) return 'GBP';
    if (line.contains('¥')) return 'JPY';
    return 'USD'; // Default
  }

  /// Extract date from line
  DateTime? _extractDate(String line) {
    // Look for common date patterns
    final datePatterns = [
      RegExp(r'\d{1,2}[/-]\d{1,2}[/-]\d{2,4}'), // MM/DD/YYYY or DD/MM/YYYY
      RegExp(r'\d{4}[/-]\d{1,2}[/-]\d{1,2}'), // YYYY/MM/DD
      RegExp(r'\d{1,2}\s+(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\s+\d{2,4}', caseSensitive: false),
    ];

    for (final pattern in datePatterns) {
      final match = pattern.firstMatch(line);
      if (match != null) {
        try {
          return DateTime.parse(match.group(0)!);
        } catch (_) {
          // Continue to next pattern
        }
      }
    }

    return null;
  }

  /// Parse a line as an item with description and price
  ReceiptItem? _parseItemLine(String line) {
    final amount = _extractAmount(line);
    if (amount == null) return null;

    // Remove the price from the line to get description
    final priceString = amount.toStringAsFixed(2);
    final description = line
        .replaceAll('\$', '')
        .replaceAll(priceString, '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (description.isEmpty || description.length < 3) return null;

    return ReceiptItem(
      description: description,
      price: amount,
      quantity: 1,
    );
  }

  /// Clean up resources
  void dispose() {
    _textRecognizer.close();
  }
}
