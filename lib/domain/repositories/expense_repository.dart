import 'package:dartz/dartz.dart';
import 'package:finwise/core/errors/failure.dart';
import 'package:finwise/domain/entities/expense.dart';

/// Abstract repository interface for expense operations
/// Defines the contract for expense data access following Clean Architecture
abstract class ExpenseRepository {
  /// Get all expenses for a user with optional filtering
  Future<Either<Failure, List<Expense>>> getExpenses({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
    List<ExpenseCategory>? categories,
    String? searchQuery,
    int? limit,
    int? offset,
  });

  /// Get a specific expense by ID
  Future<Either<Failure, Expense>> getExpense(String expenseId);

  /// Create a new expense
  Future<Either<Failure, Expense>> createExpense(Expense expense);

  /// Update an existing expense
  Future<Either<Failure, Expense>> updateExpense(Expense expense);

  /// Delete an expense
  Future<Either<Failure, bool>> deleteExpense(String expenseId);

  /// Get expense statistics for a date range
  Future<Either<Failure, ExpenseStatistics>> getExpenseStatistics({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Get expenses grouped by category
  Future<Either<Failure, Map<ExpenseCategory, double>>> getExpensesByCategory({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Get monthly expense trends
  Future<Either<Failure, List<MonthlyExpense>>> getMonthlyTrends({
    required String userId,
    int months = 12,
  });

  /// Sync local expenses with remote server
  Future<Either<Failure, SyncResult>> syncExpenses(String userId);

  /// Search expenses by query
  Future<Either<Failure, List<Expense>>> searchExpenses({
    required String userId,
    required String query,
    int? limit,
  });

  /// Get recurring expenses for a user
  Future<Either<Failure, List<Expense>>> getRecurringExpenses(String userId);

  /// Bulk create expenses (for import operations)
  Future<Either<Failure, List<Expense>>> bulkCreateExpenses(
    List<Expense> expenses,
  );

  /// Get expenses near a location
  Future<Either<Failure, List<Expense>>> getExpensesNearLocation({
    required String userId,
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  });
}

/// Expense statistics data class
class ExpenseStatistics {
  final int totalExpenses;
  final double totalAmount;
  final double averageAmount;
  final double highestAmount;
  final double lowestAmount;
  final int expensesThisMonth;
  final double amountThisMonth;
  final int expensesLastMonth;
  final double amountLastMonth;
  final double monthlyChangePercent;
  final ExpenseCategory topCategory;
  final Map<String, double> dailySpending;

  const ExpenseStatistics({
    required this.totalExpenses,
    required this.totalAmount,
    required this.averageAmount,
    required this.highestAmount,
    required this.lowestAmount,
    required this.expensesThisMonth,
    required this.amountThisMonth,
    required this.expensesLastMonth,
    required this.amountLastMonth,
    required this.monthlyChangePercent,
    required this.topCategory,
    required this.dailySpending,
  });
}

/// Monthly expense data for trends
class MonthlyExpense {
  final DateTime month;
  final int expenseCount;
  final double totalAmount;
  final Map<ExpenseCategory, double> categoryBreakdown;

  const MonthlyExpense({
    required this.month,
    required this.expenseCount,
    required this.totalAmount,
    required this.categoryBreakdown,
  });
}

/// Sync operation result
class SyncResult {
  final int uploadedCount;
  final int downloadedCount;
  final int conflictCount;
  final List<String> errors;
  final bool success;

  const SyncResult({
    required this.uploadedCount,
    required this.downloadedCount,
    required this.conflictCount,
    required this.errors,
    required this.success,
  });

  factory SyncResult.success({
    required int uploadedCount,
    required int downloadedCount,
  }) {
    return SyncResult(
      uploadedCount: uploadedCount,
      downloadedCount: downloadedCount,
      conflictCount: 0,
      errors: [],
      success: true,
    );
  }

  factory SyncResult.failure(List<String> errors) {
    return SyncResult(
      uploadedCount: 0,
      downloadedCount: 0,
      conflictCount: 0,
      errors: errors,
      success: false,
    );
  }
}
