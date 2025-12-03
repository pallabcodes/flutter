import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:finwise/core/errors/failure.dart';
import 'package:finwise/data/datasources/local/database/database.dart' as db;
import 'package:finwise/data/datasources/local/database/tables/budget_table.dart' as db_budget;
import 'package:finwise/data/datasources/remote/api_client.dart';
import 'package:finwise/domain/entities/budget.dart';
import 'package:finwise/domain/repositories/budget_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:drift/drift.dart' as drift;

@injectable
class BudgetRepositoryImpl implements BudgetRepository {
  final db.AppDatabase _database;
  final ApiClient _apiClient;

  BudgetRepositoryImpl(this._database, this._apiClient);

  @override
  Future<Either<Failure, List<Budget>>> getBudgets(String userId) async {
    try {
      final budgets = await _database.getBudgets(userId);
      return Right(budgets.map((b) => _mapDatabaseBudgetToEntity(b)).toList());
    } catch (e) {
      return Left(DatabaseFailure(message: 'Failed to fetch budgets: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Budget>>> getActiveBudgets(String userId) async {
    try {
      final budgets = await _database.getActiveBudgets(userId);
      return Right(budgets.map((b) => _mapDatabaseBudgetToEntity(b)).toList());
    } catch (e) {
      return Left(DatabaseFailure(message: 'Failed to fetch active budgets: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Budget>> getBudget(String budgetId) async {
    try {
      final budget = await _database.getBudget(budgetId);
      if (budget == null) {
        return Left(DatabaseFailure.notFound('Budget'));
      }
      return Right(_mapDatabaseBudgetToEntity(budget));
    } catch (e) {
      return Left(DatabaseFailure(message: 'Failed to fetch budget: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Budget>> createBudget(Budget budget) async {
    try {
      final companion = _mapEntityToDatabaseCompanion(budget);
      final id = await _database.saveBudget(companion);

      if (id > 0) {
        return Right(budget);
      } else {
        return Left(DatabaseFailure.insertError());
      }
    } catch (e) {
      return Left(DatabaseFailure(message: 'Failed to create budget: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Budget>> updateBudget(Budget budget) async {
    try {
      final companion = _mapEntityToDatabaseCompanion(budget);
      final id = await _database.saveBudget(companion);

      if (id > 0) {
        return Right(budget);
      } else {
        return Left(DatabaseFailure(message: 'Failed to update budget'));
      }
    } catch (e) {
      return Left(DatabaseFailure(message: 'Failed to update budget: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteBudget(String budgetId) async {
    try {
      final rowsAffected = await _database.deleteBudget(budgetId);
      return Right(rowsAffected > 0);
    } catch (e) {
      return Left(DatabaseFailure(message: 'Failed to delete budget: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Budget>> updateBudgetSpentAmount({
    required String budgetId,
    required int spentAmount,
  }) async {
    try {
      final success = await _database.updateBudgetSpentAmount(budgetId, spentAmount);
      if (success) {
        // Return updated budget
        final budgetResult = await getBudget(budgetId);
        return budgetResult;
      } else {
        return Left(DatabaseFailure(message: 'Failed to update budget spent amount'));
      }
    } catch (e) {
      return Left(DatabaseFailure(message: 'Failed to update budget spent amount: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<BudgetProgress>>> getBudgetProgress(String userId) async {
    try {
      final activeBudgets = await _database.getActiveBudgets(userId);
      final progress = activeBudgets.map((b) => BudgetProgress.fromBudget(_mapDatabaseBudgetToEntity(b))).toList();
      return Right(progress);
    } catch (e) {
      return Left(DatabaseFailure(message: 'Failed to get budget progress: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<BudgetAlert>>> getBudgetAlerts(String userId) async {
    try {
      // TODO: Implement budget alerts logic
      // This would check budgets approaching limits, over budget, etc.
      return const Right([]);
    } catch (e) {
      return Left(DatabaseFailure(message: 'Failed to get budget alerts: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, bool>> markAlertAsRead(String alertId) async {
    try {
      // TODO: Implement mark alert as read
      return const Right(true);
    } catch (e) {
      return Left(DatabaseFailure(message: 'Failed to mark alert as read: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<BudgetPerformance>>> getBudgetPerformance({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // TODO: Implement budget performance tracking
      return const Right([]);
    } catch (e) {
      return Left(DatabaseFailure(message: 'Failed to get budget performance: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Budget>>> getRecommendedBudgets(String userId) async {
    try {
      // TODO: Implement AI-based budget recommendations
      // This would analyze spending patterns and suggest budgets
      return const Right([]);
    } catch (e) {
      return Left(DatabaseFailure(message: 'Failed to get recommended budgets: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, SyncResult>> syncBudgets(String userId) async {
    try {
      // TODO: Implement budget sync logic
      return Right(SyncResult.success(
        uploadedCount: 0,
        downloadedCount: 0,
      ));
    } catch (e) {
      return Left(NetworkFailure(message: 'Failed to sync budgets: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Map<ExpenseCategory, List<Budget>>>> getBudgetsByCategory(String userId) async {
    try {
      final budgets = await _database.getBudgets(userId);
      final Map<ExpenseCategory, List<Budget>> categoryBudgets = {};

      for (final budget in budgets) {
        final entity = _mapDatabaseBudgetToEntity(budget);

        // Handle category-specific budgets
        if (entity.categories.isNotEmpty) {
          for (final category in entity.categories) {
            categoryBudgets.putIfAbsent(category, () => []).add(entity);
          }
        } else {
          // Overall budgets go under 'other' or a special key
          categoryBudgets.putIfAbsent(ExpenseCategory.other, () => []).add(entity);
        }
      }

      return Right(categoryBudgets);
    } catch (e) {
      return Left(DatabaseFailure(message: 'Failed to get budgets by category: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, int>> archiveExpiredBudgets(String userId) async {
    try {
      // TODO: Implement archiving expired budgets
      // This would move expired budgets to an archive table or mark as archived
      return const Right(0);
    } catch (e) {
      return Left(DatabaseFailure(message: 'Failed to archive expired budgets: ${e.toString()}'));
    }
  }

  /// Maps database budget model to domain entity
  Budget _mapDatabaseBudgetToEntity(db_budget.Budget budget) {
    return Budget(
      id: budget.id,
      userId: budget.userId,
      name: budget.name,
      description: budget.description,
      type: BudgetType.values.firstWhere(
        (t) => t.name == budget.type,
        orElse: () => BudgetType.category,
      ),
      targetAmount: budget.targetAmount,
      currency: budget.currency,
      period: BudgetPeriod.values.firstWhere(
        (p) => p.name == budget.period,
        orElse: () => BudgetPeriod.monthly,
      ),
      startDate: budget.startDate,
      endDate: budget.endDate,
      categories: budget.categories != null
          ? (jsonDecode(budget.categories!) as List<dynamic>)
              .map((c) => ExpenseCategory.values.firstWhere(
                    (cat) => cat.name == c,
                    orElse: () => ExpenseCategory.other,
                  ))
              .toList()
          : [],
      spentAmount: budget.spentAmount,
      enableNotifications: budget.enableNotifications,
      warningThreshold: budget.warningThreshold,
      createdAt: budget.createdAt,
      updatedAt: budget.updatedAt,
      isActive: budget.isActive,
      isSynced: budget.isSynced,
    );
  }

  /// Maps domain entity to database companion
  db.BudgetsCompanion _mapEntityToDatabaseCompanion(Budget budget) {
    return db.BudgetsCompanion(
      id: drift.Value(budget.id),
      userId: drift.Value(budget.userId),
      name: drift.Value(budget.name),
      description: drift.Value(budget.description),
      type: drift.Value(budget.type.name),
      targetAmount: drift.Value(budget.targetAmount),
      currency: drift.Value(budget.currency),
      period: drift.Value(budget.period.name),
      startDate: drift.Value(budget.startDate),
      endDate: drift.Value(budget.endDate),
      categories: drift.Value(
        budget.categories.isNotEmpty
            ? jsonEncode(budget.categories.map((c) => c.name).toList())
            : null,
      ),
      spentAmount: drift.Value(budget.spentAmount),
      enableNotifications: drift.Value(budget.enableNotifications),
      warningThreshold: drift.Value(budget.warningThreshold),
      createdAt: drift.Value(budget.createdAt),
      updatedAt: drift.Value(budget.updatedAt),
      isActive: drift.Value(budget.isActive),
      isSynced: drift.Value(budget.isSynced),
    );
  }
}
