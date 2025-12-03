import 'dart:io';

import 'package:finwise/core/config/injection.dart';
import 'package:finwise/domain/repositories/receipt_scanner_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Repository Provider
final receiptScannerRepositoryProvider = Provider<ReceiptScannerRepository>((ref) {
  return getIt<ReceiptScannerRepository>();
});

// Scan Result Provider (for processing screen)
final receiptScanResultProvider = FutureProvider.family<ReceiptScanResult, File>((ref, imageFile) async {
  final repository = ref.watch(receiptScannerRepositoryProvider);
  final result = await repository.scanReceipt(imageFile);

  return result.fold(
    (failure) => throw Exception(failure.message),
    (scanResult) => scanResult,
  );
});

// Camera Permission Providers
final cameraPermissionProvider = FutureProvider<bool>((ref) async {
  final repository = ref.watch(receiptScannerRepositoryProvider);
  final result = await repository.checkCameraPermission();

  return result.fold(
    (failure) => false,
    (hasPermission) => hasPermission,
  );
});

final storagePermissionProvider = FutureProvider<bool>((ref) async {
  final repository = ref.watch(receiptScannerRepositoryProvider);
  final result = await repository.checkStoragePermission();

  return result.fold(
    (failure) => false,
    (hasPermission) => hasPermission,
  );
});

// Permission Request Providers
final requestCameraPermissionProvider = FutureProvider<bool>((ref) async {
  final repository = ref.watch(receiptScannerRepositoryProvider);
  final result = await repository.requestCameraPermission();

  return result.fold(
    (failure) => false,
    (granted) => granted,
  );
});

final requestStoragePermissionProvider = FutureProvider<bool>((ref) async {
  final repository = ref.watch(receiptScannerRepositoryProvider);
  final result = await repository.requestStoragePermission();

  return result.fold(
    (failure) => false,
    (granted) => granted,
  );
});

// Receipt Scanning State Notifier
class ReceiptScannerNotifier extends StateNotifier<AsyncValue<ReceiptScanResult?>> {
  final ReceiptScannerRepository _repository;

  ReceiptScannerNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> scanReceipt(File imageFile) async {
    state = const AsyncValue.loading();

    final result = await _repository.scanReceipt(imageFile);

    state = result.fold(
      (failure) => AsyncValue.error(failure.message, StackTrace.current),
      (scanResult) => AsyncValue.data(scanResult),
    );
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

final receiptScannerNotifierProvider = StateNotifierProvider<ReceiptScannerNotifier, AsyncValue<ReceiptScanResult?>>((ref) {
  final repository = ref.watch(receiptScannerRepositoryProvider);
  return ReceiptScannerNotifier(repository);
});
