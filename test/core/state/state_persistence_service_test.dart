import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finwise/core/state/state_persistence_service.dart';

void main() {
  late StatePersistenceService persistenceService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    persistenceService = StatePersistenceService(prefs);
  });

  group('StatePersistenceService', () {
    group('Pending Operations', () {
      test('should save and load pending operations', () async {
        final operations = [
          PendingOperation(
            id: 'test_op_1',
            type: 'create_expense',
            data: {'amount': 1000, 'description': 'Test expense'},
            timestamp: DateTime(2024, 1, 1),
          ),
          PendingOperation(
            id: 'test_op_2',
            type: 'update_expense',
            data: {'id': 'exp_123', 'amount': 2000},
            timestamp: DateTime(2024, 1, 2),
          ),
        ];

        await persistenceService.savePendingOperations(operations);
        final loadedOperations = await persistenceService.loadPendingOperations();

        expect(loadedOperations.length, 2);
        expect(loadedOperations[0].id, 'test_op_1');
        expect(loadedOperations[0].type, 'create_expense');
        expect(loadedOperations[0].data['amount'], 1000);
        expect(loadedOperations[1].id, 'test_op_2');
        expect(loadedOperations[1].type, 'update_expense');
      });

      test('should return empty list when no operations saved', () async {
        final operations = await persistenceService.loadPendingOperations();
        expect(operations, isEmpty);
      });

      test('should filter expired operations', () async {
        final expiredOperation = PendingOperation(
          id: 'expired_op',
          type: 'create_expense',
          data: {'test': 'data'},
          timestamp: DateTime.now().subtract(const Duration(hours: 25)), // Expired
          ttl: const Duration(hours: 24),
        );

        final validOperation = PendingOperation(
          id: 'valid_op',
          type: 'update_expense',
          data: {'test': 'data'},
          timestamp: DateTime.now().subtract(const Duration(hours: 1)), // Still valid
          ttl: const Duration(hours: 24),
        );

        await persistenceService.savePendingOperations([expiredOperation, validOperation]);
        final loadedOperations = await persistenceService.loadPendingOperations();

        expect(loadedOperations.length, 1);
        expect(loadedOperations[0].id, 'valid_op');
      });
    });

    group('User Preferences', () {
      test('should save and load user preferences', () async {
        final preferences = UserPreferences(
          enableNotifications: false,
          enableBiometrics: true,
          autoSync: false,
          defaultCurrency: 'EUR',
          itemsPerPage: 50,
          showWelcomeScreen: false,
          customSettings: {'theme': 'dark', 'language': 'de'},
        );

        await persistenceService.saveUserPreferences(preferences);
        final loadedPreferences = await persistenceService.loadUserPreferences();

        expect(loadedPreferences.enableNotifications, false);
        expect(loadedPreferences.enableBiometrics, true);
        expect(loadedPreferences.autoSync, false);
        expect(loadedPreferences.defaultCurrency, 'EUR');
        expect(loadedPreferences.itemsPerPage, 50);
        expect(loadedPreferences.showWelcomeScreen, false);
        expect(loadedPreferences.customSettings['theme'], 'dark');
        expect(loadedPreferences.customSettings['language'], 'de');
      });

      test('should return defaults when no preferences saved', () async {
        final preferences = await persistenceService.loadUserPreferences();
        expect(preferences.enableNotifications, true); // Default value
        expect(preferences.enableBiometrics, false); // Default value
        expect(preferences.autoSync, true); // Default value
      });
    });

    group('App State', () {
      test('should save and load app state snapshot', () async {
        final stateSnapshot = AppStateSnapshot(
          lastScreen: 'home',
          navigationState: {'tab': 'expenses', 'filter': 'all'},
          formState: {'draft_expense': {'amount': 5000}},
          timestamp: DateTime(2024, 1, 1),
        );

        await persistenceService.saveAppState(stateSnapshot);
        final loadedState = await persistenceService.loadAppState();

        expect(loadedState, isNotNull);
        expect(loadedState!.lastScreen, 'home');
        expect(loadedState.navigationState['tab'], 'expenses');
        expect(loadedState.formState['draft_expense']['amount'], 5000);
      });

      test('should return null when no app state saved', () async {
        final state = await persistenceService.loadAppState();
        expect(state, isNull);
      });
    });

    group('Sync Time', () {
      test('should save and load last sync time', () async {
        final syncTime = DateTime(2024, 1, 1, 12, 0, 0);
        await persistenceService.saveLastSyncTime(syncTime);

        final loadedSyncTime = persistenceService.loadLastSyncTime();
        expect(loadedSyncTime, syncTime);
      });

      test('should return null when no sync time saved', () {
        final syncTime = persistenceService.loadLastSyncTime();
        expect(syncTime, isNull);
      });
    });

    group('Offline Queue', () {
      test('should save and load offline operations', () async {
        final operations = [
          OfflineOperation(
            id: 'offline_op_1',
            type: OfflineOperationType.createExpense,
            payload: {'amount': 1500, 'description': 'Offline expense'},
            timestamp: DateTime(2024, 1, 1),
          ),
          OfflineOperation(
            id: 'offline_op_2',
            type: OfflineOperationType.updateExpense,
            payload: {'id': 'exp_456', 'amount': 2500},
            timestamp: DateTime(2024, 1, 2),
            retryCount: 2,
          ),
        ];

        await persistenceService.saveOfflineQueue(operations);
        final loadedOperations = await persistenceService.loadOfflineQueue();

        expect(loadedOperations.length, 2);
        expect(loadedOperations[0].id, 'offline_op_1');
        expect(loadedOperations[0].type, OfflineOperationType.createExpense);
        expect(loadedOperations[0].payload['amount'], 1500);
        expect(loadedOperations[1].id, 'offline_op_2');
        expect(loadedOperations[1].retryCount, 2);
      });

      test('should clean up old operations', () async {
        final oldOperation = OfflineOperation(
          id: 'old_op',
          type: OfflineOperationType.createExpense,
          payload: {'test': 'data'},
          timestamp: DateTime.now().subtract(const Duration(days: 8)), // Older than 7 days
        );

        final recentOperation = OfflineOperation(
          id: 'recent_op',
          type: OfflineOperationType.updateExpense,
          payload: {'test': 'data'},
          timestamp: DateTime.now().subtract(const Duration(hours: 1)), // Recent
        );

        await persistenceService.saveOfflineQueue([oldOperation, recentOperation]);
        await persistenceService.cleanupExpiredData();

        final loadedOperations = await persistenceService.loadOfflineQueue();
        expect(loadedOperations.length, 1);
        expect(loadedOperations[0].id, 'recent_op');
      });
    });

    group('Cleanup', () {
      test('should clear all persisted state', () async {
        // Save some data first
        await persistenceService.savePendingOperations([
          PendingOperation(id: 'test', type: 'test', data: {}),
        ]);

        await persistenceService.saveUserPreferences(UserPreferences(
          enableNotifications: false,
          enableBiometrics: true,
          autoSync: false,
          defaultCurrency: 'EUR',
          itemsPerPage: 50,
          showWelcomeScreen: false,
          customSettings: {},
        ));

        await persistenceService.saveOfflineQueue([
          OfflineOperation(id: 'test', type: OfflineOperationType.createExpense, payload: {}),
        ]);

        // Verify data exists
        expect((await persistenceService.loadPendingOperations()).length, 1);
        expect((await persistenceService.loadUserPreferences()).defaultCurrency, 'EUR');
        expect((await persistenceService.loadOfflineQueue()).length, 1);

        // Clear all state
        await persistenceService.clearAllState();

        // Verify data is cleared
        expect(await persistenceService.loadPendingOperations(), isEmpty);
        expect((await persistenceService.loadUserPreferences()).defaultCurrency, 'USD'); // Back to default
        expect(await persistenceService.loadOfflineQueue(), isEmpty);
      });
    });
  });
}
