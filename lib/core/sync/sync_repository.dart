import 'package:finwise/core/errors/failure.dart';
import 'package:finwise/domain/entities/expense.dart';
import 'package:finwise/domain/entities/budget.dart';

/// Repository interface for data synchronization
/// Defines contract for local and remote data operations
abstract class SyncRepository {
  /// Get local expenses modified since given timestamp
  Future<Either<Failure, List<Expense>>> getLocalExpenses(
    String userId,
    DateTime since,
  );

  /// Get remote expenses modified since given timestamp
  Future<Either<Failure, List<Expense>>> getRemoteExpenses(
    String userId,
    DateTime since,
  );

  /// Save expense locally
  Future<Either<Failure, void>> saveExpenseLocally(Expense expense);

  /// Upload expense to remote
  Future<Either<Failure, void>> uploadExpense(Expense expense);

  /// Delete expense remotely
  Future<Either<Failure, void>> deleteExpenseRemotely(String expenseId);

  /// Get local budgets modified since given timestamp
  Future<Either<Failure, List<Budget>>> getLocalBudgets(
    String userId,
    DateTime since,
  );

  /// Get remote budgets modified since given timestamp
  Future<Either<Failure, List<Budget>>> getRemoteBudgets(
    String userId,
    DateTime since,
  );

  /// Save budget locally
  Future<Either<Failure, void>> saveBudgetLocally(Budget budget);

  /// Upload budget to remote
  Future<Either<Failure, void>> uploadBudget(Budget budget);

  /// Delete budget remotely
  Future<Either<Failure, void>> deleteBudgetRemotely(String budgetId);

  /// Check if device is online
  Future<bool> isOnline();

  /// Get last successful sync timestamp
  Future<DateTime?> getLastSyncTimestamp();

  /// Set last successful sync timestamp
  Future<void> setLastSyncTimestamp(DateTime timestamp);

  /// Dispose resources
  Future<void> dispose();
}

/// Default implementation combining local and remote repositories
class DefaultSyncRepository implements SyncRepository {
  final SyncRepository _localRepository;
  final SyncRepository _remoteRepository;

  const DefaultSyncRepository({
    required SyncRepository localRepository,
    required SyncRepository remoteRepository,
  })  : _localRepository = localRepository,
        _remoteRepository = remoteRepository;

  @override
  Future<Either<Failure, List<Expense>>> getLocalExpenses(
    String userId,
    DateTime since,
  ) async {
    return _localRepository.getLocalExpenses(userId, since);
  }

  @override
  Future<Either<Failure, List<Expense>>> getRemoteExpenses(
    String userId,
    DateTime since,
  ) async {
    return _remoteRepository.getRemoteExpenses(userId, since);
  }

  @override
  Future<Either<Failure, void>> saveExpenseLocally(Expense expense) async {
    return _localRepository.saveExpenseLocally(expense);
  }

  @override
  Future<Either<Failure, void>> uploadExpense(Expense expense) async {
    return _remoteRepository.uploadExpense(expense);
  }

  @override
  Future<Either<Failure, void>> deleteExpenseRemotely(String expenseId) async {
    return _remoteRepository.deleteExpenseRemotely(expenseId);
  }

  @override
  Future<Either<Failure, List<Budget>>> getLocalBudgets(
    String userId,
    DateTime since,
  ) async {
    return _localRepository.getLocalBudgets(userId, since);
  }

  @override
  Future<Either<Failure, List<Budget>>> getRemoteBudgets(
    String userId,
    DateTime since,
  ) async {
    return _remoteRepository.getRemoteBudgets(userId, since);
  }

  @override
  Future<Either<Failure, void>> saveBudgetLocally(Budget budget) async {
    return _localRepository.saveBudgetLocally(budget);
  }

  @override
  Future<Either<Failure, void>> uploadBudget(Budget budget) async {
    return _remoteRepository.uploadBudget(budget);
  }

  @override
  Future<Either<Failure, void>> deleteBudgetRemotely(String budgetId) async {
    return _remoteRepository.deleteBudgetRemotely(budgetId);
  }

  @override
  Future<bool> isOnline() async {
    return _remoteRepository.isOnline();
  }

  @override
  Future<DateTime?> getLastSyncTimestamp() async {
    return _localRepository.getLastSyncTimestamp();
  }

  @override
  Future<void> setLastSyncTimestamp(DateTime timestamp) async {
    await _localRepository.setLastSyncTimestamp(timestamp);
  }

  @override
  Future<void> dispose() async {
    await _localRepository.dispose();
    await _remoteRepository.dispose();
  }
}

/// Sync repository implementation for local Drift database
class LocalSyncRepository implements SyncRepository {
  // This would be implemented using the existing Drift repositories
  // For now, placeholder implementations

  @override
  Future<Either<Failure, List<Expense>>> getLocalExpenses(
    String userId,
    DateTime since,
  ) async {
    // TODO: Implement using Drift expense repository
    return const Right([]);
  }

  @override
  Future<Either<Failure, List<Expense>>> getRemoteExpenses(
    String userId,
    DateTime since,
  ) async {
    // Local repository doesn't handle remote data
    return const Right([]);
  }

  @override
  Future<Either<Failure, void>> saveExpenseLocally(Expense expense) async {
    // TODO: Implement using Drift expense repository
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> uploadExpense(Expense expense) async {
    // Local repository doesn't upload to remote
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> deleteExpenseRemotely(String expenseId) async {
    // Local repository doesn't handle remote operations
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<Budget>>> getLocalBudgets(
    String userId,
    DateTime since,
  ) async {
    // TODO: Implement using Drift budget repository
    return const Right([]);
  }

  @override
  Future<Either<Failure, List<Budget>>> getRemoteBudgets(
    String userId,
    DateTime since,
  ) async {
    // Local repository doesn't handle remote data
    return const Right([]);
  }

  @override
  Future<Either<Failure, void>> saveBudgetLocally(Budget budget) async {
    // TODO: Implement using Drift budget repository
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> uploadBudget(Budget budget) async {
    // Local repository doesn't upload to remote
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> deleteBudgetRemotely(String budgetId) async {
    // Local repository doesn't handle remote operations
    return const Right(null);
  }

  @override
  Future<bool> isOnline() async {
    // Local repository is always "online" for local operations
    return true;
  }

  @override
  Future<DateTime?> getLastSyncTimestamp() async {
    // TODO: Store and retrieve from local storage
    return null;
  }

  @override
  Future<void> setLastSyncTimestamp(DateTime timestamp) async {
    // TODO: Store in local storage
  }

  @override
  Future<void> dispose() async {
    // Clean up resources if needed
  }
}

/// Sync repository implementation for remote API
class RemoteSyncRepository implements SyncRepository {
  // This would be implemented using the existing API client
  // For now, placeholder implementations

  @override
  Future<Either<Failure, List<Expense>>> getLocalExpenses(
    String userId,
    DateTime since,
  ) async {
    // Remote repository doesn't handle local data
    return const Right([]);
  }

  @override
  Future<Either<Failure, List<Expense>>> getRemoteExpenses(
    String userId,
    DateTime since,
  ) async {
    // TODO: Implement using API client
    return const Right([]);
  }

  @override
  Future<Either<Failure, void>> saveExpenseLocally(Expense expense) async {
    // Remote repository doesn't save locally
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> uploadExpense(Expense expense) async {
    // TODO: Implement using API client
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> deleteExpenseRemotely(String expenseId) async {
    // TODO: Implement using API client
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<Budget>>> getLocalBudgets(
    String userId,
    DateTime since,
  ) async {
    // Remote repository doesn't handle local data
    return const Right([]);
  }

  @override
  Future<Either<Failure, List<Budget>>> getRemoteBudgets(
    String userId,
    DateTime since,
  ) async {
    // TODO: Implement using API client
    return const Right([]);
  }

  @override
  Future<Either<Failure, void>> saveBudgetLocally(Budget budget) async {
    // Remote repository doesn't save locally
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> uploadBudget(Budget budget) async {
    // TODO: Implement using API client
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> deleteBudgetRemotely(String budgetId) async {
    // TODO: Implement using API client
    return const Right(null);
  }

  @override
  Future<bool> isOnline() async {
    // TODO: Implement connectivity check
    return true;
  }

  @override
  Future<DateTime?> getLastSyncTimestamp() async {
    // Remote repository doesn't track local sync timestamps
    return null;
  }

  @override
  Future<void> setLastSyncTimestamp(DateTime timestamp) async {
    // Remote repository doesn't track local sync timestamps
  }

  @override
  Future<void> dispose() async {
    // Clean up API client resources if needed
  }
}

/// Sync repository factory
class SyncRepositoryFactory {
  static SyncRepository createDefault({
    required SyncRepository localRepository,
    required SyncRepository remoteRepository,
  }) {
    return DefaultSyncRepository(
      localRepository: localRepository,
      remoteRepository: remoteRepository,
    );
  }

  static SyncRepository createLocal() {
    return LocalSyncRepository();
  }

  static SyncRepository createRemote() {
    return RemoteSyncRepository();
  }

  static SyncRepository createMock() {
    // For testing purposes
    return MockSyncRepository();
  }
}

/// Mock sync repository for testing
class MockSyncRepository implements SyncRepository {
  final List<Expense> _localExpenses = [];
  final List<Budget> _localBudgets = [];
  final List<Expense> _remoteExpenses = [];
  final List<Budget> _remoteBudgets = [];

  @override
  Future<Either<Failure, List<Expense>>> getLocalExpenses(
    String userId,
    DateTime since,
  ) async {
    final filtered = _localExpenses.where((e) =>
      e.userId == userId && e.updatedAt.isAfter(since)).toList();
    return Right(filtered);
  }

  @override
  Future<Either<Failure, List<Expense>>> getRemoteExpenses(
    String userId,
    DateTime since,
  ) async {
    final filtered = _remoteExpenses.where((e) =>
      e.userId == userId && e.updatedAt.isAfter(since)).toList();
    return Right(filtered);
  }

  @override
  Future<Either<Failure, void>> saveExpenseLocally(Expense expense) async {
    _localExpenses.add(expense);
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> uploadExpense(Expense expense) async {
    _remoteExpenses.add(expense);
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> deleteExpenseRemotely(String expenseId) async {
    _remoteExpenses.removeWhere((e) => e.id == expenseId);
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<Budget>>> getLocalBudgets(
    String userId,
    DateTime since,
  ) async {
    final filtered = _localBudgets.where((b) =>
      b.userId == userId && b.updatedAt.isAfter(since)).toList();
    return Right(filtered);
  }

  @override
  Future<Either<Failure, List<Budget>>> getRemoteBudgets(
    String userId,
    DateTime since,
  ) async {
    final filtered = _remoteBudgets.where((b) =>
      b.userId == userId && b.updatedAt.isAfter(since)).toList();
    return Right(filtered);
  }

  @override
  Future<Either<Failure, void>> saveBudgetLocally(Budget budget) async {
    _localBudgets.add(budget);
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> uploadBudget(Budget budget) async {
    _remoteBudgets.add(budget);
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> deleteBudgetRemotely(String budgetId) async {
    _remoteBudgets.removeWhere((b) => b.id == budgetId);
    return const Right(null);
  }

  @override
  Future<bool> isOnline() async => true;

  @override
  Future<DateTime?> getLastSyncTimestamp() async => DateTime.now();

  @override
  Future<void> setLastSyncTimestamp(DateTime timestamp) async {}

  @override
  Future<void> dispose() async {
    _localExpenses.clear();
    _localBudgets.clear();
    _remoteExpenses.clear();
    _remoteBudgets.clear();
  }
}
