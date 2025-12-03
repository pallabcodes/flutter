import 'package:finwise/core/config/injection.dart';
import 'package:finwise/domain/entities/expense.dart';
import 'package:finwise/domain/repositories/expense_repository.dart';
import 'package:finwise/domain/usecases/create_expense_usecase.dart';
import 'package:finwise/domain/usecases/get_expenses_usecase.dart';
import 'package:finwise/domain/usecases/update_expense_usecase.dart';
import 'package:finwise/presentation/providers/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Repository Providers
final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return getIt<ExpenseRepository>();
});

// Use Case Providers
final getExpensesUseCaseProvider = Provider<GetExpensesUseCase>((ref) {
  final repository = ref.watch(expenseRepositoryProvider);
  return GetExpensesUseCase(repository);
});

final createExpenseUseCaseProvider = Provider<CreateExpenseUseCase>((ref) {
  final repository = ref.watch(expenseRepositoryProvider);
  return CreateExpenseUseCase(repository);
});

final updateExpenseUseCaseProvider = Provider<UpdateExpenseUseCase>((ref) {
  final repository = ref.watch(expenseRepositoryProvider);
  return UpdateExpenseUseCase(repository);
});

final deleteExpenseUseCaseProvider = Provider<DeleteExpenseUseCase>((ref) {
  final repository = ref.watch(expenseRepositoryProvider);
  return DeleteExpenseUseCase(repository);
});

// State Providers
final expensesProvider = StateNotifierProvider<ExpensesNotifier, AsyncValue<List<Expense>>>((ref) {
  final getExpensesUseCase = ref.watch(getExpensesUseCaseProvider);
  final createExpenseUseCase = ref.watch(createExpenseUseCaseProvider);
  final updateExpenseUseCase = ref.watch(updateExpenseUseCaseProvider);
  final deleteExpenseUseCase = ref.watch(deleteExpenseUseCaseProvider);
  final currentUser = ref.watch(currentUserProvider);
  return ExpensesNotifier(
    getExpensesUseCase,
    createExpenseUseCase,
    updateExpenseUseCase,
    deleteExpenseUseCase,
    currentUser?.id,
  );
});

final selectedExpenseProvider = StateProvider<Expense?>((ref) => null);

final expenseFiltersProvider = StateProvider<ExpenseFilters>((ref) {
  return const ExpenseFilters();
});

// Notifiers
class ExpensesNotifier extends StateNotifier<AsyncValue<List<Expense>>> {
  final GetExpensesUseCase _getExpensesUseCase;
  final CreateExpenseUseCase _createExpenseUseCase;
  final UpdateExpenseUseCase _updateExpenseUseCase;
  final DeleteExpenseUseCase _deleteExpenseUseCase;
  final String? _userId;

  // Track optimistic updates for rollback
  final Map<String, Expense> _optimisticUpdates = {};
  final Map<String, Expense> _originalExpenses = {};

  ExpensesNotifier(
    this._getExpensesUseCase,
    this._createExpenseUseCase,
    this._updateExpenseUseCase,
    this._deleteExpenseUseCase,
    this._userId,
  ) : super(const AsyncValue.loading()) {
    if (_userId != null) {
      loadExpenses();
    } else {
      state = const AsyncValue.data([]); // No user, no expenses
    }
  }

  Future<void> loadExpenses({
    DateTime? startDate,
    DateTime? endDate,
    List<ExpenseCategory>? categories,
    String? searchQuery,
  }) async {
    if (_userId == null) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();

    final result = await _getExpensesUseCase(
      GetExpensesParams(
        userId: _userId!,
        startDate: startDate,
        endDate: endDate,
        categories: categories,
        searchQuery: searchQuery,
      ),
    );

    state = result.fold(
      (failure) => AsyncValue.error(failure.message, StackTrace.current),
      (expenses) => AsyncValue.data(expenses),
    );
  }

  Future<void> refreshExpenses() async {
    await loadExpenses();
  }

  /// Create expense with optimistic update
  Future<void> createExpenseOptimistically(Expense expense) async {
    if (state is! AsyncData<List<Expense>>) return;

    final currentExpenses = (state as AsyncData<List<Expense>>).value;

    // Store original state for potential rollback
    final optimisticId = 'optimistic_${DateTime.now().millisecondsSinceEpoch}';
    final optimisticExpense = expense.copyWith(id: optimisticId);
    _optimisticUpdates[optimisticId] = optimisticExpense;
    _originalExpenses[optimisticId] = expense; // Store original for API call

    // Immediately update UI with optimistic data
    state = AsyncValue.data([...currentExpenses, optimisticExpense]);

    try {
      // Perform API call in background
      final result = await _createExpenseUseCase(
        CreateExpenseParams(expense: expense),
      );

      await result.fold(
        (failure) async {
          // Rollback optimistic update on failure
          await _rollbackOptimisticUpdate(optimisticId);
        },
        (createdExpense) async {
          // Replace optimistic update with real data
          await _confirmOptimisticUpdate(optimisticId, createdExpense);
        },
      );
    } catch (e) {
      // Rollback on any error
      await _rollbackOptimisticUpdate(optimisticId);
    }
  }

  /// Update expense with optimistic update
  Future<void> updateExpenseOptimistically(String expenseId, Expense updatedExpense) async {
    if (state is! AsyncData<List<Expense>>) return;

    final currentExpenses = (state as AsyncData<List<Expense>>).value;
    final existingExpense = currentExpenses.firstWhere(
      (e) => e.id == expenseId,
      orElse: () => throw Exception('Expense not found'),
    );

    // Store original for rollback
    _optimisticUpdates[expenseId] = updatedExpense;
    _originalExpenses[expenseId] = existingExpense;

    // Immediately update UI
    final updatedExpenses = currentExpenses.map((e) =>
      e.id == expenseId ? updatedExpense : e
    ).toList();
    state = AsyncValue.data(updatedExpenses);

    try {
      final result = await _updateExpenseUseCase(
        UpdateExpenseParams(expense: updatedExpense),
      );

      await result.fold(
        (failure) async {
          await _rollbackOptimisticUpdate(expenseId);
        },
        (updated) async {
          await _confirmOptimisticUpdate(expenseId, updated);
        },
      );
    } catch (e) {
      await _rollbackOptimisticUpdate(expenseId);
    }
  }

  /// Delete expense with optimistic update
  Future<void> deleteExpenseOptimistically(String expenseId) async {
    if (state is! AsyncData<List<Expense>>) return;

    final currentExpenses = (state as AsyncData<List<Expense>>).value;
    final expenseToDelete = currentExpenses.firstWhere(
      (e) => e.id == expenseId,
      orElse: () => throw Exception('Expense not found'),
    );

    // Store for potential rollback
    _optimisticUpdates[expenseId] = expenseToDelete;
    _originalExpenses[expenseId] = expenseToDelete;

    // Immediately remove from UI
    final filteredExpenses = currentExpenses.where((e) => e.id != expenseId).toList();
    state = AsyncValue.data(filteredExpenses);

    try {
      final result = await _deleteExpenseUseCase(
        DeleteExpenseParams(expenseId: expenseId),
      );

      result.fold(
        (failure) async {
          await _rollbackOptimisticUpdate(expenseId);
        },
        (success) {
          // Success - remove from tracking
          _optimisticUpdates.remove(expenseId);
          _originalExpenses.remove(expenseId);
        },
      );
    } catch (e) {
      await _rollbackOptimisticUpdate(expenseId);
    }
  }

  /// Rollback an optimistic update
  Future<void> _rollbackOptimisticUpdate(String optimisticId) async {
    if (state is! AsyncData<List<Expense>>) return;

    final currentExpenses = (state as AsyncData<List<Expense>>).value;
    final originalExpense = _originalExpenses[optimisticId];

    if (originalExpense != null && optimisticId.startsWith('optimistic_')) {
      // This was an add operation - remove the optimistic item
      final rolledBackExpenses = currentExpenses.where((e) => e.id != optimisticId).toList();
      state = AsyncValue.data(rolledBackExpenses);
    } else if (originalExpense != null) {
      // This was an update/delete operation - restore original
      final rolledBackExpenses = currentExpenses.map((e) =>
        e.id == optimisticId ? originalExpense : e
      ).toList();
      state = AsyncValue.data(rolledBackExpenses);
    }

    // Clean up tracking
    _optimisticUpdates.remove(optimisticId);
    _originalExpenses.remove(optimisticId);
  }

  /// Confirm an optimistic update with real data
  Future<void> _confirmOptimisticUpdate(String optimisticId, Expense realExpense) async {
    if (state is! AsyncData<List<Expense>>) return;

    final currentExpenses = (state as AsyncData<List<Expense>>).value;

    if (optimisticId.startsWith('optimistic_')) {
      // Replace optimistic item with real data
      final confirmedExpenses = currentExpenses.map((e) =>
        e.id == optimisticId ? realExpense : e
      ).toList();
      state = AsyncValue.data(confirmedExpenses);
    } else {
      // Update existing item with confirmed data
      final confirmedExpenses = currentExpenses.map((e) =>
        e.id == optimisticId ? realExpense : e
      ).toList();
      state = AsyncValue.data(confirmedExpenses);
    }

    // Clean up tracking
    _optimisticUpdates.remove(optimisticId);
    _originalExpenses.remove(optimisticId);
  }

  /// Check if an expense is currently being optimistically updated
  bool isOptimisticallyUpdated(String expenseId) {
    return _optimisticUpdates.containsKey(expenseId);
  }

  /// Get all optimistically updated expense IDs
  Set<String> get optimisticUpdateIds => _optimisticUpdates.keys.toSet();
}

// Data Classes
class ExpenseFilters {
  final DateTime? startDate;
  final DateTime? endDate;
  final List<ExpenseCategory> categories;
  final String? searchQuery;
  final ExpenseSortBy sortBy;
  final SortOrder sortOrder;

  const ExpenseFilters({
    this.startDate,
    this.endDate,
    this.categories = const [],
    this.searchQuery,
    this.sortBy = ExpenseSortBy.date,
    this.sortOrder = SortOrder.descending,
  });

  ExpenseFilters copyWith({
    DateTime? startDate,
    DateTime? endDate,
    List<ExpenseCategory>? categories,
    String? searchQuery,
    ExpenseSortBy? sortBy,
    SortOrder? sortOrder,
  }) {
    return ExpenseFilters(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      categories: categories ?? this.categories,
      searchQuery: searchQuery ?? this.searchQuery,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}

enum ExpenseSortBy {
  date,
  amount,
  category,
  description,
}

enum SortOrder {
  ascending,
  descending,
}

// Computed Providers
final filteredExpensesProvider = Provider<AsyncValue<List<Expense>>>((ref) {
  final expensesAsync = ref.watch(expensesProvider);
  final filters = ref.watch(expenseFiltersProvider);

  return expensesAsync.whenData((expenses) {
    var filtered = expenses;

    // Apply search filter
    if (filters.searchQuery?.isNotEmpty == true) {
      final query = filters.searchQuery!.toLowerCase();
      filtered = filtered.where((expense) {
        return expense.description.toLowerCase().contains(query) ||
               expense.category.name.toLowerCase().contains(query) ||
               expense.note?.toLowerCase().contains(query) == true;
      }).toList();
    }

    // Apply category filter
    if (filters.categories.isNotEmpty) {
      filtered = filtered.where((expense) {
        return filters.categories.contains(expense.category);
      }).toList();
    }

    // Apply date filters
    if (filters.startDate != null) {
      filtered = filtered.where((expense) {
        return expense.date.isAfter(filters.startDate!.subtract(const Duration(days: 1)));
      }).toList();
    }

    if (filters.endDate != null) {
      filtered = filtered.where((expense) {
        return expense.date.isBefore(filters.endDate!.add(const Duration(days: 1)));
      }).toList();
    }

    // Apply sorting
    filtered.sort((a, b) {
      int comparison;
      switch (filters.sortBy) {
        case ExpenseSortBy.date:
          comparison = a.date.compareTo(b.date);
          break;
        case ExpenseSortBy.amount:
          comparison = a.amount.compareTo(b.amount);
          break;
        case ExpenseSortBy.category:
          comparison = a.category.name.compareTo(b.category.name);
          break;
        case ExpenseSortBy.description:
          comparison = a.description.compareTo(b.description);
          break;
      }

      return filters.sortOrder == SortOrder.ascending ? comparison : -comparison;
    });

    return filtered;
  });
});

final expensesSummaryProvider = Provider<ExpenseSummary>((ref) {
  final expensesAsync = ref.watch(filteredExpensesProvider);

  return expensesAsync.maybeWhen(
    data: (expenses) {
      final totalAmount = expenses.fold<int>(0, (sum, expense) => sum + expense.amount);
      final averageAmount = expenses.isNotEmpty ? totalAmount / expenses.length : 0.0;
      final categoryBreakdown = <ExpenseCategory, double>{};

      for (final expense in expenses) {
        categoryBreakdown[expense.category] = (categoryBreakdown[expense.category] ?? 0) + expense.amount;
      }

      return ExpenseSummary(
        totalCount: expenses.length,
        totalAmount: totalAmount,
        averageAmount: averageAmount,
        categoryBreakdown: categoryBreakdown,
      );
    },
    orElse: () => ExpenseSummary.empty(),
  );
});

// Optimistic Operations Providers
final createExpenseOptimisticallyProvider = FutureProvider.family<void, Expense>((ref, expense) async {
  final expensesNotifier = ref.watch(expensesProvider.notifier);
  await expensesNotifier.createExpenseOptimistically(expense);
});

final updateExpenseOptimisticallyProvider = FutureProvider.family<void, Map<String, dynamic>>((ref, params) async {
  final expenseId = params['expenseId'] as String;
  final updatedExpense = params['expense'] as Expense;
  final expensesNotifier = ref.watch(expensesProvider.notifier);
  await expensesNotifier.updateExpenseOptimistically(expenseId, updatedExpense);
});

final deleteExpenseOptimisticallyProvider = FutureProvider.family<void, String>((ref, expenseId) async {
  final expensesNotifier = ref.watch(expensesProvider.notifier);
  await expensesNotifier.deleteExpenseOptimistically(expenseId);
});

// Computed provider for optimistic update status
final optimisticUpdatesProvider = Provider<Set<String>>((ref) {
  final expensesAsync = ref.watch(expensesProvider);
  return expensesAsync.maybeWhen(
    data: (expenses) => ref.watch(expensesProvider.notifier).optimisticUpdateIds,
    orElse: () => {},
  );
});

// Provider to check if specific expense is being optimistically updated
final isExpenseOptimisticallyUpdatedProvider = Provider.family<bool, String>((ref, expenseId) {
  return ref.watch(expensesProvider.notifier).isOptimisticallyUpdated(expenseId);
});

// Summary Data Class
class ExpenseSummary {
  final int totalCount;
  final int totalAmount;
  final double averageAmount;
  final Map<ExpenseCategory, double> categoryBreakdown;

  const ExpenseSummary({
    required this.totalCount,
    required this.totalAmount,
    required this.averageAmount,
    required this.categoryBreakdown,
  });

  factory ExpenseSummary.empty() {
    return const ExpenseSummary(
      totalCount: 0,
      totalAmount: 0,
      averageAmount: 0.0,
      categoryBreakdown: {},
    );
  }

  String get formattedTotalAmount {
    final amountInDollars = totalAmount / 100;
    return '\$${amountInDollars.toStringAsFixed(2)}';
  }

  String get formattedAverageAmount {
    final amountInDollars = averageAmount / 100;
    return '\$${amountInDollars.toStringAsFixed(2)}';
  }
}
