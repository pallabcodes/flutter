import 'package:dartz/dartz.dart';
import 'package:finwise/core/errors/failure.dart';
import 'package:finwise/domain/entities/budget.dart';
import 'package:finwise/domain/entities/expense.dart';

/// Abstract repository interface for budget operations
/// Defines the contract for budget data access following Clean Architecture
abstract class BudgetRepository {
  /// Get all budgets for a user
  Future<Either<Failure, List<Budget>>> getBudgets(String userId);

  /// Get active budgets for a user
  Future<Either<Failure, List<Budget>>> getActiveBudgets(String userId);

  /// Get a specific budget by ID
  Future<Either<Failure, Budget>> getBudget(String budgetId);

  /// Create a new budget
  Future<Either<Failure, Budget>> createBudget(Budget budget);

  /// Update an existing budget
  Future<Either<Failure, Budget>> updateBudget(Budget budget);

  /// Delete a budget
  Future<Either<Failure, bool>> deleteBudget(String budgetId);

  /// Update spent amount for a budget based on expenses
  Future<Either<Failure, Budget>> updateBudgetSpentAmount({
    required String budgetId,
    required int spentAmount,
  });

  /// Get budget progress for all active budgets
  Future<Either<Failure, List<BudgetProgress>>> getBudgetProgress(String userId);

  /// Get budget alerts/notifications
  Future<Either<Failure, List<BudgetAlert>>> getBudgetAlerts(String userId);

  /// Mark budget alert as read
  Future<Either<Failure, bool>> markAlertAsRead(String alertId);

  /// Get budget performance history
  Future<Either<Failure, List<BudgetPerformance>>> getBudgetPerformance({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Calculate recommended budgets based on spending history
  Future<Either<Failure, List<Budget>>> getRecommendedBudgets(String userId);

  /// Sync local budgets with remote server
  Future<Either<Failure, SyncResult>> syncBudgets(String userId);

  /// Get budgets by category
  Future<Either<Failure, Map<ExpenseCategory, List<Budget>>>> getBudgetsByCategory(
    String userId,
  );

  /// Archive expired budgets
  Future<Either<Failure, int>> archiveExpiredBudgets(String userId);
}

/// Budget alert/notification data class
class BudgetAlert {
  final String id;
  final String budgetId;
  final String userId;
  final BudgetAlertType type;
  final String message;
  final DateTime createdAt;
  final bool isRead;

  const BudgetAlert({
    required this.id,
    required this.budgetId,
    required this.userId,
    required this.type,
    required this.message,
    required this.createdAt,
    this.isRead = false,
  });
}

/// Budget performance data for analytics
class BudgetPerformance {
  final Budget budget;
  final double adherenceRate; // Percentage of budget kept within limit
  final List<BudgetCheckpoint> checkpoints;
  final BudgetInsights insights;

  const BudgetPerformance({
    required this.budget,
    required this.adherenceRate,
    required this.checkpoints,
    required this.insights,
  });
}

/// Budget checkpoint for tracking progress over time
class BudgetCheckpoint {
  final DateTime date;
  final double spentAmount;
  final double targetAmount;
  final double utilizationPercentage;

  const BudgetCheckpoint({
    required this.date,
    required this.spentAmount,
    required this.targetAmount,
    required this.utilizationPercentage,
  });
}

/// Budget insights and recommendations
class BudgetInsights {
  final List<String> recommendations;
  final List<String> warnings;
  final double projectedOverspend;
  final List<ExpenseCategory> overspendingCategories;
  final double savingsPotential;

  const BudgetInsights({
    required this.recommendations,
    required this.warnings,
    required this.projectedOverspend,
    required this.overspendingCategories,
    required this.savingsPotential,
  });
}

/// Sync operation result (reused from expense repository)
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
