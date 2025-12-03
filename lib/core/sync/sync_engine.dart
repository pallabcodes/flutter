import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:finwise/core/errors/failure.dart';
import 'package:finwise/core/security/encryption_service.dart';
import 'package:finwise/core/security/secure_storage.dart';
import 'package:finwise/core/sync/sync_conflict_resolver.dart';
import 'package:finwise/core/sync/sync_queue.dart';
import 'package:finwise/core/sync/sync_repository.dart';
import 'package:finwise/domain/entities/expense.dart';
import 'package:finwise/domain/entities/budget.dart';

/// Offline-first synchronization engine
/// Handles bidirectional sync between local and remote data sources
class SyncEngine {
  final SyncRepository _syncRepository;
  final SyncQueue _syncQueue;
  final SyncConflictResolver _conflictResolver;
  final Connectivity _connectivity;

  final StreamController<SyncStatus> _syncStatusController =
      StreamController<SyncStatus>.broadcast();

  Timer? _backgroundSyncTimer;
  bool _isOnline = true;

  static const Duration _syncInterval = Duration(minutes: 15);
  static const Duration _retryDelay = Duration(seconds: 30);

  SyncEngine({
    required SyncRepository syncRepository,
    required SyncQueue syncQueue,
    required SyncConflictResolver conflictResolver,
  })  : _syncRepository = syncRepository,
        _syncQueue = syncQueue,
        _conflictResolver = conflictResolver,
        _connectivity = Connectivity();

  /// Initialize the sync engine
  Future<void> initialize() async {
    // Set up connectivity monitoring
    _connectivity.onConnectivityChanged.listen(_onConnectivityChanged);

    // Check initial connectivity
    final connectivityResult = await _connectivity.checkConnectivity();
    _isOnline = _isConnectivityOnline(connectivityResult);

    // Start background sync if online
    if (_isOnline) {
      await _startBackgroundSync();
    }

    // Process any pending sync operations
    await _processPendingOperations();
  }

  /// Synchronize all data for a user
  Future<SyncResult> syncUserData(String userId) async {
    if (!_isOnline) {
      return SyncResult.offline();
    }

    try {
      _emitSyncStatus(SyncStatus.syncing('Starting sync for user $userId'));

      // Get last sync timestamp
      final lastSync = await SecureStorage.getLastSyncTimestamp();
      final sinceTimestamp = lastSync ?? DateTime.now().subtract(const Duration(days: 30));

      // Sync expenses
      final expenseResult = await _syncExpenses(userId, sinceTimestamp);
      if (expenseResult.hasConflicts) {
        await _handleConflicts(expenseResult.conflicts);
      }

      // Sync budgets
      final budgetResult = await _syncBudgets(userId, sinceTimestamp);
      if (budgetResult.hasConflicts) {
        await _handleConflicts(budgetResult.conflicts);
      }

      // Update sync timestamp
      await SecureStorage.storeLastSyncTimestamp(DateTime.now());

      final result = SyncResult.success(
        syncedExpenses: expenseResult.syncedItems,
        syncedBudgets: budgetResult.syncedItems,
        conflictsResolved: expenseResult.conflicts.length + budgetResult.conflicts.length,
      );

      _emitSyncStatus(SyncStatus.success(result));
      return result;

    } catch (e) {
      final result = SyncResult.failure(e.toString());
      _emitSyncStatus(SyncStatus.failure(e.toString()));
      return result;
    }
  }

  /// Queue operation for sync when offline
  Future<void> queueOperation(SyncOperation operation) async {
    await _syncQueue.addOperation(operation);

    if (_isOnline) {
      // Try to sync immediately if online
      await _processPendingOperations();
    }
  }

  /// Get sync status stream
  Stream<SyncStatus> get syncStatus => _syncStatusController.stream;

  /// Get current sync status
  SyncStatus get currentStatus => _syncStatusController.hasListener
      ? SyncStatus.idle()
      : SyncStatus.idle();

  /// Force immediate sync
  Future<SyncResult> forceSync(String userId) async {
    await _stopBackgroundSync();
    final result = await syncUserData(userId);
    await _startBackgroundSync();
    return result;
  }

  /// Dispose of sync engine resources
  Future<void> dispose() async {
    await _stopBackgroundSync();
    await _syncStatusController.close();
    await _syncRepository.dispose();
  }

  // Private methods

  Future<SyncDataResult> _syncExpenses(String userId, DateTime since) async {
    final localExpenses = await _syncRepository.getLocalExpenses(userId, since);
    final remoteExpenses = await _syncRepository.getRemoteExpenses(userId, since);

    final conflicts = <SyncConflict>[];
    final syncedItems = <Expense>[];

    // Find conflicts and changes
    final localMap = {for (var expense in localExpenses) expense.id: expense};
    final remoteMap = {for (var expense in remoteExpenses) expense.id: expense};

    // Process all expense IDs
    final allIds = {...localMap.keys, ...remoteMap.keys};

    for (final id in allIds) {
      final localExpense = localMap[id];
      final remoteExpense = remoteMap[id];

      if (localExpense != null && remoteExpense != null) {
        // Both exist - check for conflicts
        if (_hasConflict(localExpense, remoteExpense)) {
          conflicts.add(SyncConflict(
            id: id,
            type: SyncConflictType.expense,
            localData: localExpense,
            remoteData: remoteExpense,
            timestamp: DateTime.now(),
          ));
        }
      } else if (localExpense != null) {
        // Only local - upload to remote
        await _syncRepository.uploadExpense(localExpense);
        syncedItems.add(localExpense);
      } else if (remoteExpense != null) {
        // Only remote - download to local
        await _syncRepository.saveExpenseLocally(remoteExpense);
        syncedItems.add(remoteExpense);
      }
    }

    return SyncDataResult(
      syncedItems: syncedItems,
      conflicts: conflicts,
    );
  }

  Future<SyncDataResult> _syncBudgets(String userId, DateTime since) async {
    final localBudgets = await _syncRepository.getLocalBudgets(userId, since);
    final remoteBudgets = await _syncRepository.getRemoteBudgets(userId, since);

    final conflicts = <SyncConflict>[];
    final syncedItems = <Budget>[];

    // Similar logic to expense sync
    final localMap = {for (var budget in localBudgets) budget.id: budget};
    final remoteMap = {for (var budget in remoteBudgets) budget.id: budget};

    final allIds = {...localMap.keys, ...remoteMap.keys};

    for (final id in allIds) {
      final localBudget = localMap[id];
      final remoteBudget = remoteMap[id];

      if (localBudget != null && remoteBudget != null) {
        if (_hasConflict(localBudget, remoteBudget)) {
          conflicts.add(SyncConflict(
            id: id,
            type: SyncConflictType.budget,
            localData: localBudget,
            remoteData: remoteBudget,
            timestamp: DateTime.now(),
          ));
        }
      } else if (localBudget != null) {
        await _syncRepository.uploadBudget(localBudget);
        syncedItems.add(localBudget);
      } else if (remoteBudget != null) {
        await _syncRepository.saveBudgetLocally(remoteBudget);
        syncedItems.add(remoteBudget);
      }
    }

    return SyncDataResult(
      syncedItems: syncedItems,
      conflicts: conflicts,
    );
  }

  bool _hasConflict(dynamic local, dynamic remote) {
    // Check if both items have been modified since last sync
    if (local is Expense && remote is Expense) {
      return local.updatedAt.isAfter(remote.updatedAt) &&
             remote.updatedAt.isAfter(local.updatedAt.subtract(const Duration(seconds: 1)));
    } else if (local is Budget && remote is Budget) {
      return local.updatedAt.isAfter(remote.updatedAt) &&
             remote.updatedAt.isAfter(local.updatedAt.subtract(const Duration(seconds: 1)));
    }
    return false;
  }

  Future<void> _handleConflicts(List<SyncConflict> conflicts) async {
    for (final conflict in conflicts) {
      try {
        final resolution = await _conflictResolver.resolveConflict(conflict);
        await _applyConflictResolution(conflict, resolution);
      } catch (e) {
        // Log conflict resolution failure
        _emitSyncStatus(SyncStatus.conflict('Failed to resolve conflict: ${conflict.id}'));
      }
    }
  }

  Future<void> _applyConflictResolution(SyncConflict conflict, ConflictResolution resolution) async {
    switch (resolution.action) {
      case ConflictAction.keepLocal:
        if (conflict.type == SyncConflictType.expense) {
          await _syncRepository.uploadExpense(conflict.localData as Expense);
        } else {
          await _syncRepository.uploadBudget(conflict.localData as Budget);
        }
        break;

      case ConflictAction.keepRemote:
        if (conflict.type == SyncConflictType.expense) {
          await _syncRepository.saveExpenseLocally(conflict.remoteData as Expense);
        } else {
          await _syncRepository.saveBudgetLocally(conflict.remoteData as Budget);
        }
        break;

      case ConflictAction.merge:
        final merged = resolution.mergedData;
        if (merged is Expense) {
          await _syncRepository.saveExpenseLocally(merged);
          await _syncRepository.uploadExpense(merged);
        } else if (merged is Budget) {
          await _syncRepository.saveBudgetLocally(merged);
          await _syncRepository.uploadBudget(merged);
        }
        break;
    }
  }

  Future<void> _processPendingOperations() async {
    final operations = await _syncQueue.getPendingOperations();

    for (final operation in operations) {
      try {
        await _executeOperation(operation);
        await _syncQueue.markOperationCompleted(operation.id);
      } catch (e) {
        operation.retryCount++;
        if (operation.retryCount < 3) {
          await _syncQueue.updateOperation(operation);
          // Schedule retry
          Future.delayed(_retryDelay, () => _processPendingOperations());
        } else {
          await _syncQueue.markOperationFailed(operation.id, e.toString());
        }
      }
    }
  }

  Future<void> _executeOperation(SyncOperation operation) async {
    switch (operation.type) {
      case SyncOperationType.createExpense:
        final expense = Expense.fromJson(jsonDecode(operation.data));
        await _syncRepository.uploadExpense(expense);
        break;

      case SyncOperationType.updateExpense:
        final expense = Expense.fromJson(jsonDecode(operation.data));
        await _syncRepository.uploadExpense(expense);
        break;

      case SyncOperationType.deleteExpense:
        await _syncRepository.deleteExpenseRemotely(operation.entityId);
        break;

      case SyncOperationType.createBudget:
        final budget = Budget.fromJson(jsonDecode(operation.data));
        await _syncRepository.uploadBudget(budget);
        break;

      case SyncOperationType.updateBudget:
        final budget = Budget.fromJson(jsonDecode(operation.data));
        await _syncRepository.uploadBudget(budget);
        break;

      case SyncOperationType.deleteBudget:
        await _syncRepository.deleteBudgetRemotely(operation.entityId);
        break;
    }
  }

  void _onConnectivityChanged(ConnectivityResult result) {
    final wasOnline = _isOnline;
    _isOnline = _isConnectivityOnline(result);

    if (!wasOnline && _isOnline) {
      // Came back online - start sync
      _startBackgroundSync();
      _processPendingOperations();
      _emitSyncStatus(SyncStatus.online());
    } else if (wasOnline && !_isOnline) {
      // Went offline
      _stopBackgroundSync();
      _emitSyncStatus(SyncStatus.offline());
    }
  }

  bool _isConnectivityOnline(ConnectivityResult result) {
    return result != ConnectivityResult.none;
  }

  Future<void> _startBackgroundSync() async {
    if (_backgroundSyncTimer != null) return;

    _backgroundSyncTimer = Timer.periodic(_syncInterval, (timer) async {
      if (_isOnline) {
        // Get current user and sync
        final userId = await SecureStorage.getUserId();
        if (userId != null) {
          await syncUserData(userId);
        }
      }
    });
  }

  Future<void> _stopBackgroundSync() async {
    _backgroundSyncTimer?.cancel();
    _backgroundSyncTimer = null;
  }

  void _emitSyncStatus(SyncStatus status) {
    if (!_syncStatusController.isClosed) {
      _syncStatusController.add(status);
    }
  }
}

/// Sync result data class
class SyncResult {
  final bool success;
  final int syncedExpenses;
  final int syncedBudgets;
  final int conflictsResolved;
  final String? errorMessage;

  SyncResult._({
    required this.success,
    this.syncedExpenses = 0,
    this.syncedBudgets = 0,
    this.conflictsResolved = 0,
    this.errorMessage,
  });

  factory SyncResult.success({
    int syncedExpenses = 0,
    int syncedBudgets = 0,
    int conflictsResolved = 0,
  }) {
    return SyncResult._(
      success: true,
      syncedExpenses: syncedExpenses,
      syncedBudgets: syncedBudgets,
      conflictsResolved: conflictsResolved,
    );
  }

  factory SyncResult.failure(String errorMessage) {
    return SyncResult._(
      success: false,
      errorMessage: errorMessage,
    );
  }

  factory SyncResult.offline() {
    return SyncResult._(
      success: false,
      errorMessage: 'Device is offline',
    );
  }

  bool get isOffline => errorMessage == 'Device is offline';
}

/// Sync status for UI feedback
class SyncStatus {
  final String type;
  final String? message;
  final SyncResult? result;

  SyncStatus._(this.type, {this.message, this.result});

  factory SyncStatus.idle() => SyncStatus._('idle');
  factory SyncStatus.syncing(String message) => SyncStatus._('syncing', message: message);
  factory SyncStatus.success(SyncResult result) => SyncStatus._('success', result: result);
  factory SyncStatus.failure(String error) => SyncStatus._('failure', message: error);
  factory SyncStatus.online() => SyncStatus._('online');
  factory SyncStatus.offline() => SyncStatus._('offline');
  factory SyncStatus.conflict(String message) => SyncStatus._('conflict', message: message);

  bool get isIdle => type == 'idle';
  bool get isSyncing => type == 'syncing';
  bool get isSuccessful => type == 'success';
  bool get hasFailed => type == 'failure';
  bool get isOnline => type == 'online';
  bool get isOffline => type == 'offline';
  bool get hasConflict => type == 'conflict';
}

/// Internal sync data result
class SyncDataResult {
  final List<dynamic> syncedItems;
  final List<SyncConflict> conflicts;

  SyncDataResult({
    required this.syncedItems,
    required this.conflicts,
  });

  bool get hasConflicts => conflicts.isNotEmpty;
}
