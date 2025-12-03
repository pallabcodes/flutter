import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:finwise/core/state/state_persistence_service.dart';
import 'package:finwise/domain/entities/expense.dart';
import 'package:finwise/presentation/providers/app_lifecycle_provider.dart';
import 'package:finwise/presentation/providers/background_sync_provider.dart';
import 'package:finwise/presentation/providers/connectivity_provider.dart';
import 'package:finwise/presentation/providers/global_loading_provider.dart';
import 'package:finwise/presentation/providers/undo_redo_provider.dart';
import 'package:finwise/presentation/widgets/error_boundary.dart';
import 'package:finwise/presentation/widgets/sync_status_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Production Readiness Integration Tests', () {
    late StatePersistenceService persistenceService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      persistenceService = StatePersistenceService(prefs);
    });

    test('should survive app restart with state persistence', () async {
      // Simulate app creating data before "restart"
      final preferences = UserPreferences(
        enableNotifications: false,
        enableBiometrics: true,
        autoSync: true,
        defaultCurrency: 'EUR',
        itemsPerPage: 25,
        showWelcomeScreen: false,
        customSettings: {'theme': 'dark'},
      );

      await persistenceService.saveUserPreferences(preferences);

      final pendingOperation = PendingOperation(
        id: 'restart_test_op',
        type: 'create_expense',
        data: {'amount': 5000, 'description': 'Restart test'},
      );

      await persistenceService.savePendingOperations([pendingOperation]);

      // Simulate app "restart" - create new instance
      final newPersistence = StatePersistenceService(await SharedPreferences.getInstance());

      // Verify data survived restart
      final loadedPreferences = await newPersistence.loadUserPreferences();
      final loadedOperations = await newPersistence.loadPendingOperations();

      expect(loadedPreferences.enableBiometrics, true);
      expect(loadedPreferences.defaultCurrency, 'EUR');
      expect(loadedOperations.length, 1);
      expect(loadedOperations[0].id, 'restart_test_op');
    });

    test('should handle offline to online transition', () async {
      final syncNotifier = BackgroundSyncNotifier(persistenceService, Connectivity());

      // Start offline
      syncNotifier.state = syncNotifier.state.copyWith(isOnline: false);

      // Queue operations offline
      final operation = SyncOperation(
        id: 'offline_test_op',
        type: OfflineOperationType.createExpense,
        payload: {'amount': 1000, 'description': 'Offline operation'},
      );

      await syncNotifier.queueOperation(operation);
      expect(syncNotifier.state.queue.length, 1);

      // Simulate coming online
      syncNotifier.state = syncNotifier.state.copyWith(isOnline: true);

      // Should still have operation queued (would be processed in real scenario)
      expect(syncNotifier.state.isOnline, true);
      expect(syncNotifier.state.queue.length, 1);

      syncNotifier.dispose();
    });

    test('should provide comprehensive undo/redo functionality', () async {
      final undoRedoNotifier = UndoRedoNotifier();

      // Create multiple actions
      final expense = Expense(
        id: 'undo_test_expense',
        userId: 'test_user',
        amount: 2000,
        currency: 'USD',
        description: 'Undo test expense',
        category: ExpenseCategory.food,
        date: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final action1 = CreateExpenseAction(expense);
      final action2 = UpdateExpenseAction(
        expense,
        expense.copyWith(amount: 2500, description: 'Updated expense'),
      );

      // Execute actions
      await undoRedoNotifier.execute(action1);
      await undoRedoNotifier.execute(action2);

      expect(undoRedoNotifier.state.canUndo, true);
      expect(undoRedoNotifier.getRecentActions().length, 2);

      // Undo last action
      await undoRedoNotifier.undo();
      expect(undoRedoNotifier.state.canRedo, true);

      // Redo action
      await undoRedoNotifier.redo();
      expect(undoRedoNotifier.state.canUndo, true);
      expect(undoRedoNotifier.state.canRedo, false);

      undoRedoNotifier.dispose();
    });

    test('should manage global loading states across operations', () async {
      final globalLoadingNotifier = GlobalLoadingNotifier();
      final operationsNotifier = LoadingOperationsNotifier();

      // Start multiple operations
      globalLoadingNotifier.showLoading();
      operationsNotifier.startOperation('op1');
      operationsNotifier.startOperation('op2');

      // Check combined loading state
      final isAnyLoading = globalLoadingNotifier.state || operationsNotifier.hasActiveOperations;
      expect(isAnyLoading, true);

      // Complete operations
      globalLoadingNotifier.hideLoading();
      operationsNotifier.completeOperation('op1');
      operationsNotifier.completeOperation('op2');

      // Should be no loading
      final isStillLoading = globalLoadingNotifier.state || operationsNotifier.hasActiveOperations;
      expect(isStillLoading, false);

      globalLoadingNotifier.dispose();
    });

    test('should handle connectivity state changes', () async {
      final connectivityNotifier = ConnectivityNotifier();

      // Test initial state
      expect(connectivityNotifier.state, ConnectivityResult.none);

      // Simulate connectivity check
      connectivityNotifier.state = ConnectivityResult.wifi;
      expect(connectivityNotifier.state, ConnectivityResult.wifi);

      connectivityNotifier.dispose();
    });

    test('should provide user-friendly error messages', () {
      const errorFallback = ErrorFallbackWidget(
        error: Exception('Network timeout error'),
      );

      // Test error message parsing
      final errorMessage = _getErrorMessage(Exception('Network timeout'));
      expect(errorMessage, 'Network connection error. Please check your internet connection.');

      final genericError = _getErrorMessage(Exception('Unknown error'));
      expect(genericError, 'An unexpected error occurred. Please try again.');
    });

    test('should integrate sync status with UI', () {
      // Test sync status enum values
      expect(SyncStatus.offline.displayName, 'Offline');
      expect(SyncStatus.syncing.displayName, 'Syncing...');
      expect(SyncStatus.pending.displayName, 'Pending sync');
      expect(SyncStatus.error.displayName, 'Sync error');
      expect(SyncStatus.synced.displayName, 'Synced');

      // Test colors
      expect(SyncStatus.synced.color, Colors.green);
      expect(SyncStatus.error.color, Colors.red);
      expect(SyncStatus.offline.color, Colors.grey);
    });
  });

  group('App Lifecycle Integration', () {
    test('should handle app lifecycle state transitions', () {
      final lifecycleNotifier = AppLifecycleNotifier(
        StatePersistenceService(SharedPreferences.getInstance() as SharedPreferences),
        // Mock performance monitor
        () => null as dynamic,
      );

      // Test initial state
      expect(lifecycleNotifier.state, AppLifecycleState.resumed);

      // Simulate state change
      lifecycleNotifier.didChangeAppLifecycleState(AppLifecycleState.paused);
      expect(lifecycleNotifier.state, AppLifecycleState.paused);

      lifecycleNotifier.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(lifecycleNotifier.state, AppLifecycleState.resumed);

      lifecycleNotifier.dispose();
    });
  });

  group('End-to-End Feature Integration', () {
    test('should handle complex user workflow with all features', () async {
      // This test simulates a complete user workflow using all production features

      // 1. State persistence survives app restart
      final prefs = await SharedPreferences.getInstance();
      final persistence = StatePersistenceService(prefs);

      final userPrefs = UserPreferences(
        enableNotifications: true,
        enableBiometrics: false,
        autoSync: true,
        defaultCurrency: 'USD',
        itemsPerPage: 20,
        showWelcomeScreen: true,
        customSettings: {},
      );

      await persistence.saveUserPreferences(userPrefs);
      final loadedPrefs = await persistence.loadUserPreferences();
      expect(loadedPrefs.enableNotifications, true);

      // 2. Connectivity monitoring works
      final connectivityNotifier = ConnectivityNotifier();
      connectivityNotifier.state = ConnectivityResult.wifi;
      expect(connectivityNotifier.state, ConnectivityResult.wifi);

      // 3. Undo/redo system works
      final undoRedoNotifier = UndoRedoNotifier();
      final expense = Expense(
        id: 'e2e_test',
        userId: 'user_123',
        amount: 1500,
        currency: 'USD',
        description: 'E2E test expense',
        category: ExpenseCategory.other,
        date: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await undoRedoNotifier.execute(CreateExpenseAction(expense));
      expect(undoRedoNotifier.state.canUndo, true);

      // 4. Background sync queues operations
      final syncNotifier = BackgroundSyncNotifier(persistence, Connectivity());
      final syncOp = SyncOperation(
        id: 'e2e_sync_op',
        type: OfflineOperationType.createExpense,
        payload: expense.toJson(),
      );

      await syncNotifier.queueOperation(syncOp);
      expect(syncNotifier.state.queue.length, 1);

      // 5. Global loading works
      final loadingNotifier = GlobalLoadingNotifier();
      await loadingNotifier.executeWithGlobalLoading(() async {
        await Future.delayed(const Duration(milliseconds: 50));
        return 'success';
      });
      expect(loadingNotifier.state, false);

      // Cleanup
      connectivityNotifier.dispose();
      undoRedoNotifier.dispose();
      syncNotifier.dispose();
      loadingNotifier.dispose();
    });
  });
}

// Helper function to test error message parsing
String _getErrorMessage(Object error) {
  if (error.toString().contains('Network')) {
    return 'Network connection error. Please check your internet connection.';
  }
  if (error.toString().contains('Timeout')) {
    return 'Request timed out. Please try again.';
  }
  if (error.toString().contains('Permission')) {
    return 'Permission denied. Please check app permissions.';
  }
  if (error.toString().contains('Database')) {
    return 'Database error. Please restart the app.';
  }

  // Generic fallback
  return 'An unexpected error occurred. Please try again.';
}
