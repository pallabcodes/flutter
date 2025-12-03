import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:finwise/core/errors/failure.dart';
import 'package:finwise/core/state/state_persistence_service.dart';
import 'package:finwise/domain/entities/expense.dart';
import 'package:finwise/domain/entities/budget.dart';
import 'package:finwise/presentation/providers/connectivity_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Background sync queue for offline-first operations
/// Manages queuing operations when offline and syncing when online
class BackgroundSyncNotifier extends StateNotifier<SyncQueueState> {
  final StatePersistenceService _persistence;
  final Connectivity _connectivity;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  Timer? _syncTimer;
  Timer? _retryTimer;

  static const Duration _syncInterval = Duration(minutes: 5);
  static const Duration _retryDelay = Duration(seconds: 30);
  static const int _maxRetries = 3;

  BackgroundSyncNotifier(this._persistence, this._connectivity)
      : super(SyncQueueState.empty()) {
    _initialize();
  }

  Future<void> _initialize() async {
    // Load persisted queue on startup
    final persistedOperations = await _persistence.loadOfflineQueue();
    state = state.copyWith(queue: persistedOperations);

    // Set up connectivity monitoring
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _onConnectivityChanged,
    );

    // Check initial connectivity
    final result = await _connectivity.checkConnectivity();
    _onConnectivityChanged(result);

    // Start periodic sync if online
    if (result != ConnectivityResult.none) {
      _startPeriodicSync();
    }
  }

  void _onConnectivityChanged(ConnectivityResult result) {
    final isOnline = result != ConnectivityResult.none;

    if (isOnline && !state.isOnline) {
      // Came online - start syncing
      state = state.copyWith(isOnline: true);
      _startPeriodicSync();
      _processQueue();
    } else if (!isOnline && state.isOnline) {
      // Went offline - stop syncing
      state = state.copyWith(isOnline: false);
      _stopPeriodicSync();
    }
  }

  /// Queue an operation for background sync
  Future<void> queueOperation(SyncOperation operation) async {
    final offlineOperation = OfflineOperation(
      id: operation.id,
      type: operation.type,
      payload: operation.payload,
    );

    final updatedQueue = [...state.queue, offlineOperation];
    state = state.copyWith(queue: updatedQueue);

    // Persist queue
    await _persistence.saveOfflineQueue(updatedQueue);

    // Try to process immediately if online
    if (state.isOnline) {
      _processQueue();
    }
  }

  /// Process the sync queue
  Future<void> _processQueue() async {
    if (!state.isOnline || state.isProcessing || state.queue.isEmpty) {
      return;
    }

    state = state.copyWith(isProcessing: true, lastSyncAttempt: DateTime.now());

    final operationsToProcess = List<OfflineOperation>.from(state.queue);
    final successfulOps = <String>[];
    final failedOps = <OfflineOperation>[];

    for (final operation in operationsToProcess) {
      try {
        await _executeOperation(operation);
        successfulOps.add(operation.id);
      } catch (e) {
        final updatedOp = operation.copyWith(retryCount: operation.retryCount + 1);

        if (updatedOp.canRetry) {
          failedOps.add(updatedOp);
        } else {
          // Max retries exceeded - mark as failed
          state = state.copyWith(
            failedOperations: [...state.failedOperations, updatedOp],
          );
        }
      }
    }

    // Update queue - remove successful, update failed with retry counts
    final updatedQueue = state.queue
        .where((op) => !successfulOps.contains(op.id))
        .map((op) {
          final failedOp = failedOps.firstWhere(
            (failed) => failed.id == op.id,
            orElse: () => op,
          );
          return failedOp;
        })
        .toList();

    state = state.copyWith(
      queue: updatedQueue,
      isProcessing: false,
      lastSyncTime: successfulOps.isNotEmpty ? DateTime.now() : state.lastSyncTime,
    );

    // Persist updated queue
    await _persistence.saveOfflineQueue(updatedQueue);

    // Schedule retry for failed operations
    if (failedOps.isNotEmpty && failedOps.any((op) => op.canRetry)) {
      _scheduleRetry();
    }
  }

  Future<void> _executeOperation(OfflineOperation operation) async {
    // This would integrate with your existing use cases
    // For now, we'll simulate the execution
    switch (operation.type) {
      case OfflineOperationType.createExpense:
        // await expenseUseCase.createExpense(Expense.fromJson(operation.payload));
        break;
      case OfflineOperationType.updateExpense:
        // await expenseUseCase.updateExpense(Expense.fromJson(operation.payload));
        break;
      case OfflineOperationType.deleteExpense:
        // await expenseUseCase.deleteExpense(operation.payload['id']);
        break;
      case OfflineOperationType.createBudget:
        // await budgetUseCase.createBudget(Budget.fromJson(operation.payload));
        break;
      case OfflineOperationType.updateBudget:
        // await budgetUseCase.updateBudget(Budget.fromJson(operation.payload));
        break;
      case OfflineOperationType.deleteBudget:
        // await budgetUseCase.deleteBudget(operation.payload['id']);
        break;
    }

    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));
  }

  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(_syncInterval, (_) => _processQueue());
  }

  void _stopPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    _retryTimer = Timer(_retryDelay, _processQueue);
  }

  /// Manually trigger sync
  Future<void> syncNow() async {
    if (state.isOnline) {
      await _processQueue();
    }
  }

  /// Clear failed operations
  Future<void> clearFailedOperations() async {
    state = state.copyWith(failedOperations: []);
    await _persistence.saveOfflineQueue(state.queue);
  }

  /// Get sync status for UI
  SyncStatus get syncStatus {
    if (!state.isOnline) {
      return SyncStatus.offline;
    }

    if (state.isProcessing) {
      return SyncStatus.syncing;
    }

    if (state.queue.isNotEmpty) {
      return SyncStatus.pending;
    }

    if (state.failedOperations.isNotEmpty) {
      return SyncStatus.error;
    }

    return SyncStatus.synced;
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _syncTimer?.cancel();
    _retryTimer?.cancel();
    super.dispose();
  }
}

/// Sync operation data class
class SyncOperation {
  final String id;
  final OfflineOperationType type;
  final Map<String, dynamic> payload;

  SyncOperation({
    required this.id,
    required this.type,
    required this.payload,
  });
}

/// Sync queue state
class SyncQueueState {
  final List<OfflineOperation> queue;
  final List<OfflineOperation> failedOperations;
  final bool isOnline;
  final bool isProcessing;
  final DateTime? lastSyncTime;
  final DateTime? lastSyncAttempt;

  const SyncQueueState({
    required this.queue,
    required this.failedOperations,
    required this.isOnline,
    required this.isProcessing,
    this.lastSyncTime,
    this.lastSyncAttempt,
  });

  factory SyncQueueState.empty() => const SyncQueueState(
    queue: [],
    failedOperations: [],
    isOnline: false,
    isProcessing: false,
  );

  SyncQueueState copyWith({
    List<OfflineOperation>? queue,
    List<OfflineOperation>? failedOperations,
    bool? isOnline,
    bool? isProcessing,
    DateTime? lastSyncTime,
    DateTime? lastSyncAttempt,
  }) {
    return SyncQueueState(
      queue: queue ?? this.queue,
      failedOperations: failedOperations ?? this.failedOperations,
      isOnline: isOnline ?? this.isOnline,
      isProcessing: isProcessing ?? this.isProcessing,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      lastSyncAttempt: lastSyncAttempt ?? this.lastSyncAttempt,
    );
  }

  int get pendingOperations => queue.length;
  int get failedOperationsCount => failedOperations.length;
  bool get hasPendingOperations => queue.isNotEmpty;
  bool get hasFailedOperations => failedOperations.isNotEmpty;
}

/// Sync status enum for UI
enum SyncStatus {
  offline,
  syncing,
  pending,
  error,
  synced,
}

extension SyncStatusExtension on SyncStatus {
  String get displayText {
    switch (this) {
      case SyncStatus.offline:
        return 'Offline';
      case SyncStatus.syncing:
        return 'Syncing...';
      case SyncStatus.pending:
        return 'Pending sync';
      case SyncStatus.error:
        return 'Sync error';
      case SyncStatus.synced:
        return 'Synced';
    }
  }

  IconData get icon {
    switch (this) {
      case SyncStatus.offline:
        return Icons.cloud_off;
      case SyncStatus.syncing:
        return Icons.sync;
      case SyncStatus.pending:
        return Icons.schedule;
      case SyncStatus.error:
        return Icons.sync_problem;
      case SyncStatus.synced:
        return Icons.cloud_done;
    }
  }

  Color get color {
    switch (this) {
      case SyncStatus.offline:
        return Colors.grey;
      case SyncStatus.syncing:
        return Colors.blue;
      case SyncStatus.pending:
        return Colors.orange;
      case SyncStatus.error:
        return Colors.red;
      case SyncStatus.synced:
        return Colors.green;
    }
  }
}

/// Background sync provider
final backgroundSyncProvider = StateNotifierProvider<BackgroundSyncNotifier, SyncQueueState>((ref) {
  final persistence = ref.watch(statePersistenceProvider);
  final connectivity = Connectivity();
  return BackgroundSyncNotifier(persistence, connectivity);
});

/// Sync status provider for UI
final syncStatusProvider = Provider<SyncStatus>((ref) {
  return ref.watch(backgroundSyncProvider.notifier).syncStatus;
});

/// Sync queue provider for detailed UI
final syncQueueProvider = Provider<SyncQueueState>((ref) {
  return ref.watch(backgroundSyncProvider);
});

/// Extension methods for easy sync operations
extension SyncExtensions on WidgetRef {
  /// Queue an operation for background sync
  Future<void> queueSyncOperation(SyncOperation operation) async {
    await read(backgroundSyncProvider.notifier).queueOperation(operation);
  }

  /// Manually trigger sync
  Future<void> syncNow() async {
    await read(backgroundSyncProvider.notifier).syncNow();
  }

  /// Clear failed operations
  Future<void> clearSyncErrors() async {
    await read(backgroundSyncProvider.notifier).clearFailedOperations();
  }
}

/// Sync status indicator widget
class SyncStatusIndicator extends ConsumerWidget {
  final bool showDetails;

  const SyncStatusIndicator({
    super.key,
    this.showDetails = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatus = ref.watch(syncStatusProvider);
    final queueState = ref.watch(syncQueueProvider);

    return InkWell(
      onTap: showDetails ? () => _showSyncDetails(context, ref, queueState) : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: syncStatus.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: syncStatus.color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              syncStatus.icon,
              size: 16,
              color: syncStatus.color,
            ),
            const SizedBox(width: 4),
            Text(
              syncStatus.displayText,
              style: TextStyle(
                fontSize: 12,
                color: syncStatus.color,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (queueState.pendingOperations > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${queueState.pendingOperations}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showSyncDetails(BuildContext context, WidgetRef ref, SyncQueueState state) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sync Status',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildSyncDetailRow('Status', state.isOnline ? 'Online' : 'Offline'),
            _buildSyncDetailRow('Pending Operations', '${state.pendingOperations}'),
            _buildSyncDetailRow('Failed Operations', '${state.failedOperationsCount}'),
            if (state.lastSyncTime != null)
              _buildSyncDetailRow('Last Sync', _formatDateTime(state.lastSyncTime!)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: state.isOnline ? () => ref.syncNow() : null,
                    child: const Text('Sync Now'),
                  ),
                ),
                if (state.hasFailedOperations) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => ref.clearSyncErrors(),
                      child: const Text('Clear Errors'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }
}
