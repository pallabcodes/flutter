import 'package:finwise/core/config/injection.dart';
import 'package:finwise/domain/entities/expense.dart';
import 'package:finwise/domain/repositories/expense_repository.dart';
import 'package:finwise/domain/usecases/create_expense_usecase.dart';
import 'package:finwise/domain/usecases/get_expenses_usecase.dart';
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

// State Providers
final expensesProvider = StateNotifierProvider<ExpensesNotifier, AsyncValue<List<Expense>>>((ref) {
  final getExpensesUseCase = ref.watch(getExpensesUseCaseProvider);
  final currentUser = ref.watch(currentUserProvider);
  return ExpensesNotifier(getExpensesUseCase, currentUser?.id);
});

final selectedExpenseProvider = StateProvider<Expense?>((ref) => null);

final expenseFiltersProvider = StateProvider<ExpenseFilters>((ref) {
  return const ExpenseFilters();
});

// Notifiers
class ExpensesNotifier extends StateNotifier<AsyncValue<List<Expense>>> {
  final GetExpensesUseCase _getExpensesUseCase;
  final String? _userId;

  ExpensesNotifier(this._getExpensesUseCase, this._userId) : super(const AsyncValue.loading()) {
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
