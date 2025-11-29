import 'dart:convert';
import 'package:finwise/core/errors/failure.dart';
import 'package:finwise/core/security/encryption_service.dart';
import 'package:finwise/core/sync/sync_models.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

/// Sync queue for managing offline operations
/// Stores operations locally when offline and processes them when online
abstract class SyncQueue {
  /// Add operation to queue
  Future<void> addOperation(SyncOperation operation);

  /// Get all pending operations
  Future<List<SyncOperation>> getPendingOperations();

  /// Update operation (for retry counts, etc.)
  Future<void> updateOperation(SyncOperation operation);

  /// Mark operation as completed
  Future<void> markOperationCompleted(String operationId);

  /// Mark operation as failed
  Future<void> markOperationFailed(String operationId, String errorMessage);

  /// Clear all completed operations
  Future<void> clearCompletedOperations();

  /// Get queue statistics
  Future<Map<String, dynamic>> getQueueStatistics();

  /// Dispose resources
  Future<void> dispose();
}

/// File-based sync queue implementation
class FileSyncQueue implements SyncQueue {
  static const String _queueFileName = 'sync_queue.json';
  static const int _maxQueueSize = 1000; // Prevent unlimited growth

  File? _queueFile;
  final Map<String, SyncOperation> _operations = {};

  @override
  Future<void> addOperation(SyncOperation operation) async {
    try {
      await _ensureInitialized();
      _operations[operation.id] = operation;
      await _saveQueueToFile();
    } catch (e) {
      throw SyncFailure(
        message: 'Failed to add operation to queue: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<SyncOperation>> getPendingOperations() async {
    try {
      await _ensureInitialized();
      return _operations.values
          .where((op) => !op.isCompleted)
          .toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp)); // Process oldest first
    } catch (e) {
      throw SyncFailure(
        message: 'Failed to get pending operations: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> updateOperation(SyncOperation operation) async {
    try {
      await _ensureInitialized();
      _operations[operation.id] = operation;
      await _saveQueueToFile();
    } catch (e) {
      throw SyncFailure(
        message: 'Failed to update operation: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> markOperationCompleted(String operationId) async {
    try {
      await _ensureInitialized();
      final operation = _operations[operationId];
      if (operation != null) {
        _operations[operationId] = operation.copyWith(isCompleted: true);
        await _saveQueueToFile();
      }
    } catch (e) {
      throw SyncFailure(
        message: 'Failed to mark operation completed: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> markOperationFailed(String operationId, String errorMessage) async {
    try {
      await _ensureInitialized();
      final operation = _operations[operationId];
      if (operation != null) {
        _operations[operationId] = operation.copyWith(
          errorMessage: errorMessage,
          retryCount: operation.retryCount + 1,
        );
        await _saveQueueToFile();
      }
    } catch (e) {
      throw SyncFailure(
        message: 'Failed to mark operation failed: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> clearCompletedOperations() async {
    try {
      await _ensureInitialized();
      _operations.removeWhere((key, operation) => operation.isCompleted);
      await _saveQueueToFile();
    } catch (e) {
      throw SyncFailure(
        message: 'Failed to clear completed operations: ${e.toString()}',
      );
    }
  }

  @override
  Future<Map<String, dynamic>> getQueueStatistics() async {
    try {
      await _ensureInitialized();

      final total = _operations.length;
      final pending = _operations.values.where((op) => !op.isCompleted).length;
      final completed = total - pending;
      final failed = _operations.values.where((op) => op.errorMessage != null).length;

      final oldestPending = _operations.values
          .where((op) => !op.isCompleted)
          .fold<DateTime?>(
            null,
            (oldest, op) => oldest == null || op.timestamp.isBefore(oldest)
                ? op.timestamp
                : oldest,
          );

      final operationTypes = <String, int>{};
      for (final operation in _operations.values) {
        operationTypes[operation.type.name] =
            (operationTypes[operation.type.name] ?? 0) + 1;
      }

      return {
        'total_operations': total,
        'pending_operations': pending,
        'completed_operations': completed,
        'failed_operations': failed,
        'oldest_pending_operation': oldestPending?.toIso8601String(),
        'operation_types': operationTypes,
        'queue_size_bytes': await _getQueueSize(),
      };
    } catch (e) {
      return {
        'error': 'Failed to get queue statistics: ${e.toString()}',
      };
    }
  }

  @override
  Future<void> dispose() async {
    _operations.clear();
  }

  // Private methods

  Future<void> _ensureInitialized() async {
    if (_queueFile != null) return;

    final appDir = await getApplicationDocumentsDirectory();
    final syncDir = Directory('${appDir.path}/sync');
    await syncDir.create(recursive: true);

    _queueFile = File('${syncDir.path}/$_queueFileName');

    if (await _queueFile!.exists()) {
      await _loadQueueFromFile();
    }
  }

  Future<void> _saveQueueToFile() async {
    try {
      if (_queueFile == null) return;

      // Limit queue size
      if (_operations.length > _maxQueueSize) {
        // Remove oldest completed operations first
        final completedOps = _operations.values
            .where((op) => op.isCompleted)
            .toList()
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

        final toRemove = _operations.length - _maxQueueSize;
        for (var i = 0; i < toRemove && i < completedOps.length; i++) {
          _operations.remove(completedOps[i].id);
        }

        // If still too large, remove oldest pending operations
        if (_operations.length > _maxQueueSize) {
          final pendingOps = _operations.values
              .where((op) => !op.isCompleted)
              .toList()
            ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

          final remainingToRemove = _operations.length - _maxQueueSize;
          for (var i = 0; i < remainingToRemove && i < pendingOps.length; i++) {
            _operations.remove(pendingOps[i].id);
          }
        }
      }

      final queueData = _operations.map(
        (key, operation) => MapEntry(key, operation.toJson()),
      );

      final jsonString = jsonEncode(queueData);
      final encryptedData = await EncryptionService.encryptData(jsonString);

      await _queueFile!.writeAsString(encryptedData);
    } catch (e) {
      throw SyncFailure(
        message: 'Failed to save queue to file: ${e.toString()}',
      );
    }
  }

  Future<void> _loadQueueFromFile() async {
    try {
      if (_queueFile == null || !await _queueFile!.exists()) return;

      final encryptedData = await _queueFile!.readAsString();
      final jsonString = await EncryptionService.decryptData(encryptedData);

      final queueData = jsonDecode(jsonString) as Map<String, dynamic>;

      _operations.clear();
      for (final entry in queueData.entries) {
        final operationJson = entry.value as Map<String, dynamic>;
        final operation = SyncOperation.fromJson(operationJson);
        _operations[entry.key] = operation;
      }
    } catch (e) {
      // If file is corrupted, start with empty queue
      _operations.clear();
      // Log the error for debugging
      print('Warning: Failed to load sync queue from file: $e');
    }
  }

  Future<int> _getQueueSize() async {
    try {
      if (_queueFile == null || !await _queueFile!.exists()) return 0;
      return await _queueFile!.length();
    } catch (e) {
      return 0;
    }
  }
}

/// In-memory sync queue for testing
class InMemorySyncQueue implements SyncQueue {
  final Map<String, SyncOperation> _operations = {};

  @override
  Future<void> addOperation(SyncOperation operation) async {
    _operations[operation.id] = operation;
  }

  @override
  Future<List<SyncOperation>> getPendingOperations() async {
    return _operations.values
        .where((op) => !op.isCompleted)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  @override
  Future<void> updateOperation(SyncOperation operation) async {
    _operations[operation.id] = operation;
  }

  @override
  Future<void> markOperationCompleted(String operationId) async {
    final operation = _operations[operationId];
    if (operation != null) {
      _operations[operationId] = operation.copyWith(isCompleted: true);
    }
  }

  @override
  Future<void> markOperationFailed(String operationId, String errorMessage) async {
    final operation = _operations[operationId];
    if (operation != null) {
      _operations[operationId] = operation.copyWith(
        errorMessage: errorMessage,
        retryCount: operation.retryCount + 1,
      );
    }
  }

  @override
  Future<void> clearCompletedOperations() async {
    _operations.removeWhere((key, operation) => operation.isCompleted);
  }

  @override
  Future<Map<String, dynamic>> getQueueStatistics() async {
    final total = _operations.length;
    final pending = _operations.values.where((op) => !op.isCompleted).length;
    final completed = total - pending;
    final failed = _operations.values.where((op) => op.errorMessage != null).length;

    return {
      'total_operations': total,
      'pending_operations': pending,
      'completed_operations': completed,
      'failed_operations': failed,
    };
  }

  @override
  Future<void> dispose() async {
    _operations.clear();
  }
}

/// Sync failure exception
class SyncFailure extends Failure {
  SyncFailure({required super.message});
}
