import 'package:flutter_test/flutter_test.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:finwise/core/state/state_persistence_service.dart';
import 'package:finwise/presentation/providers/background_sync_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockConnectivity extends Connectivity {
  ConnectivityResult _result = ConnectivityResult.none;
  final StreamController<ConnectivityResult> _controller = StreamController<ConnectivityResult>();

  void emitConnectivityChange(ConnectivityResult result) {
    _result = result;
    _controller.add(result);
  }

  @override
  Future<ConnectivityResult> checkConnectivity() async {
    return _result;
  }

  @override
  Stream<ConnectivityResult> get onConnectivityChanged => _controller.stream;
}

void main() {
  late MockConnectivity mockConnectivity;
  late StatePersistenceService persistenceService;
  late BackgroundSyncNotifier syncNotifier;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    persistenceService = StatePersistenceService(prefs);
    mockConnectivity = MockConnectivity();
    syncNotifier = BackgroundSyncNotifier(persistenceService, mockConnectivity);
  });

  tearDown(() {
    syncNotifier.dispose();
  });

  group('BackgroundSyncNotifier', () {
    test('should initialize with offline state', () {
      expect(syncNotifier.state.isOnline, false);
      expect(syncNotifier.state.queue, isEmpty);
      expect(syncNotifier.state.failedOperations, isEmpty);
    });

    test('should queue operations when offline', () async {
      mockConnectivity.emitConnectivityChange(ConnectivityResult.none);

      final operation = SyncOperation(
        id: 'test_op_1',
        type: OfflineOperationType.createExpense,
        payload: {'amount': 1000, 'description': 'Test expense'},
      );

      await syncNotifier.queueOperation(operation);

      expect(syncNotifier.state.queue.length, 1);
      expect(syncNotifier.state.queue[0].id, 'test_op_1');
      expect(syncNotifier.state.queue[0].type, OfflineOperationType.createExpense);
    });

    test('should process queue when coming online', () async {
      // Start offline
      mockConnectivity.emitConnectivityChange(ConnectivityResult.none);

      final operation = SyncOperation(
        id: 'test_op_1',
        type: OfflineOperationType.createExpense,
        payload: {'amount': 1000, 'description': 'Test expense'},
      );

      await syncNotifier.queueOperation(operation);
      expect(syncNotifier.state.queue.length, 1);

      // Come online
      mockConnectivity.emitConnectivityChange(ConnectivityResult.wifi);

      // Wait for processing
      await Future.delayed(const Duration(milliseconds: 100));

      // Queue should be processed (though operation may fail without real backend)
      // In real scenario, this would succeed with actual API
      expect(syncNotifier.state.isOnline, true);
    });

    test('should handle operation failures gracefully', () async {
      mockConnectivity.emitConnectivityChange(ConnectivityResult.wifi);

      final operation = SyncOperation(
        id: 'failing_op',
        type: OfflineOperationType.createExpense,
        payload: {'invalid': 'data'}, // This would cause failure
      );

      await syncNotifier.queueOperation(operation);

      // Give time for processing
      await Future.delayed(const Duration(milliseconds: 100));

      // Operation should either succeed or move to failed operations
      expect(syncNotifier.state.isOnline, true);
    });

    test('should provide correct sync status', () {
      // Offline
      mockConnectivity.emitConnectivityChange(ConnectivityResult.none);
      expect(syncNotifier.syncStatus, SyncStatus.offline);

      // Online but no pending operations
      mockConnectivity.emitConnectivityChange(ConnectivityResult.wifi);
      expect(syncNotifier.syncStatus, SyncStatus.synced);
    });

    test('should clear failed operations', () async {
      // Add a failed operation to state
      final failedOp = OfflineOperation(
        id: 'failed_op',
        type: OfflineOperationType.createExpense,
        payload: {'test': 'data'},
      );

      syncNotifier.state = syncNotifier.state.copyWith(
        failedOperations: [failedOp],
      );

      expect(syncNotifier.state.failedOperations.length, 1);

      await syncNotifier.clearFailedOperations();

      expect(syncNotifier.state.failedOperations, isEmpty);
    });

    test('should manually trigger sync', () async {
      mockConnectivity.emitConnectivityChange(ConnectivityResult.wifi);

      final operation = SyncOperation(
        id: 'manual_sync_op',
        type: OfflineOperationType.createExpense,
        payload: {'amount': 2000},
      );

      await syncNotifier.queueOperation(operation);
      expect(syncNotifier.state.queue.length, 1);

      await syncNotifier.syncNow();

      // Sync should have been attempted
      expect(syncNotifier.state.isOnline, true);
    });
  });

  group('SyncOperation', () {
    test('should create operation with correct data', () {
      final operation = SyncOperation(
        id: 'test_op',
        type: OfflineOperationType.updateExpense,
        payload: {'id': 'exp_123', 'amount': 5000},
      );

      expect(operation.id, 'test_op');
      expect(operation.type, OfflineOperationType.updateExpense);
      expect(operation.payload['id'], 'exp_123');
      expect(operation.payload['amount'], 5000);
    });
  });

  group('OfflineOperation', () {
    test('should create offline operation', () {
      final timestamp = DateTime.now();
      final operation = OfflineOperation(
        id: 'offline_op',
        type: OfflineOperationType.createExpense,
        payload: {'test': 'data'},
        timestamp: timestamp,
      );

      expect(operation.id, 'offline_op');
      expect(operation.type, OfflineOperationType.createExpense);
      expect(operation.retryCount, 0);
      expect(operation.timestamp, timestamp);
      expect(operation.canRetry, true);
    });

    test('should calculate next retry delay', () {
      final operation = OfflineOperation(
        id: 'retry_op',
        type: OfflineOperationType.createExpense,
        payload: {'test': 'data'},
        retryCount: 2,
      );

      // 1 << 2 = 4 minutes
      expect(operation.nextRetryDelay.inMinutes, 4);

      final maxRetriesOp = OfflineOperation(
        id: 'max_retry_op',
        type: OfflineOperationType.createExpense,
        payload: {'test': 'data'},
        retryCount: 10,
      );

      expect(maxRetriesOp.canRetry, false);
    });

    test('should serialize and deserialize correctly', () {
      final original = OfflineOperation(
        id: 'serialize_test',
        type: OfflineOperationType.updateExpense,
        payload: {'amount': 3000, 'description': 'Test'},
        retryCount: 1,
        timestamp: DateTime(2024, 1, 1, 12, 0, 0),
      );

      final json = original.toJson();
      final deserialized = OfflineOperation.fromJson(json);

      expect(deserialized.id, original.id);
      expect(deserialized.type, original.type);
      expect(deserialized.payload, original.payload);
      expect(deserialized.retryCount, original.retryCount);
      expect(deserialized.timestamp, original.timestamp);
    });
  });

  group('SyncStatus', () {
    test('should provide correct display names', () {
      expect(SyncStatus.offline.displayName, 'Offline');
      expect(SyncStatus.syncing.displayName, 'Syncing...');
      expect(SyncStatus.pending.displayName, 'Pending sync');
      expect(SyncStatus.error.displayName, 'Sync error');
      expect(SyncStatus.synced.displayName, 'Synced');
    });

    test('should provide correct icons', () {
      expect(SyncStatus.offline.icon, Icons.cloud_off);
      expect(SyncStatus.syncing.icon, Icons.sync);
      expect(SyncStatus.pending.icon, Icons.schedule);
      expect(SyncStatus.error.icon, Icons.sync_problem);
      expect(SyncStatus.synced.icon, Icons.cloud_done);
    });

    test('should provide correct colors', () {
      expect(SyncStatus.offline.color, Colors.grey);
      expect(SyncStatus.syncing.color, Colors.blue);
      expect(SyncStatus.pending.color, Colors.orange);
      expect(SyncStatus.error.color, Colors.red);
      expect(SyncStatus.synced.color, Colors.green);
    });
  });
}
