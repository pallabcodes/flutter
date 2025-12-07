import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:finwise/core/errors/failure.dart';
import 'package:finwise/data/datasources/local/database/database.dart' as db;
import 'package:finwise/data/datasources/local/database/tables/expense_table.dart' as db_expense;
import 'package:finwise/data/datasources/remote/api_client.dart';
import 'package:finwise/domain/entities/expense.dart';
import 'package:finwise/domain/repositories/expense_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:drift/drift.dart' as drift;

@injectable
class ExpenseRepositoryImpl implements ExpenseRepository {
  final db.AppDatabase _database;
  final ApiClient _apiClient;

  ExpenseRepositoryImpl(this._database, this._apiClient);

  @override
  Future<Either<Failure, List<Expense>>> getExpenses({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
    List<ExpenseCategory>? categories,
    String? searchQuery,
    int? limit,
    int? offset,
  }) async {
    try {
      // Try to get from local database first
      final localExpenses = await _database.getExpenses(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
        categoryIds: categories?.map((c) => c.name).toList(),
        searchQuery: searchQuery,
        limit: limit,
        offset: offset,
      );

      // Convert database models to domain entities
      final expenses = localExpenses.map((e) => _mapDatabaseExpenseToEntity(e)).toList();

      // TODO: Implement background sync with remote API
      // For now, return local data
      return Right(expenses);
    } catch (e) {
      return Left(DatabaseFailure(message: 'Failed to fetch expenses: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Expense>> getExpense(String expenseId) async {
    try {
      final expense = await _database.getExpense(expenseId);
      if (expense == null) {
        return Left(DatabaseFailure.notFound('Expense'));
      }
      return Right(_mapDatabaseExpenseToEntity(expense));
    } catch (e) {
      return Left(DatabaseFailure(message: 'Failed to fetch expense: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Expense>> createExpense(Expense expense) async {
    try {
      final companion = _mapEntityToDatabaseCompanion(expense);
      final id = await _database.saveExpense(companion);

      if (id > 0) {
        // Return the expense with generated ID if needed
        final createdExpense = expense.copyWith(id: expense.id);
        return Right(createdExpense);
      } else {
        return Left(DatabaseFailure.insertError());
      }
    } catch (e) {
      return Left(DatabaseFailure(message: 'Failed to create expense: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Expense>> updateExpense(Expense expense) async {
    try {
      final companion = _mapEntityToDatabaseCompanion(expense);
      final id = await _database.saveExpense(companion);

      if (id > 0) {
        return Right(expense);
      } else {
        return Left(DatabaseFailure(message: 'Failed to update expense'));
      }
    } catch (e) {
      return Left(DatabaseFailure(message: 'Failed to update expense: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteExpense(String expenseId) async {
    try {
      final rowsAffected = await _database.deleteExpense(expenseId);
      return Right(rowsAffected > 0);
    } catch (e) {
      return Left(DatabaseFailure(message: 'Failed to delete expense: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, ExpenseStatistics>> getExpenseStatistics({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final stats = await _database.getExpenseStats(userId, startDate, endDate);

      final statistics = ExpenseStatistics(
        totalExpenses: stats['totalCount'] as int,
        totalAmount: (stats['totalAmount'] as int?)?.toDouble() ?? 0.0,
        averageAmount: (stats['avgAmount'] as double?) ?? 0.0,
        highestAmount: (stats['maxAmount'] as int?)?.toDouble() ?? 0.0,
        lowestAmount: (stats['minAmount'] as int?)?.toDouble() ?? 0.0,
        expensesThisMonth: 0, // TODO: Calculate properly
        amountThisMonth: 0.0, // TODO: Calculate properly
        expensesLastMonth: 0, // TODO: Calculate properly
        amountLastMonth: 0.0, // TODO: Calculate properly
        monthlyChangePercent: 0.0, // TODO: Calculate properly
        topCategory: ExpenseCategory.other, // TODO: Calculate properly
        dailySpending: {}, // TODO: Implement daily spending
      );

      return Right(statistics);
    } catch (e) {
      return Left(DatabaseFailure(message: 'Failed to get statistics: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Map<ExpenseCategory, double>>> getExpensesByCategory({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // This would require a custom query to group by category
      // For now, return empty map - implement in database layer
      return const Right({});
    } catch (e) {
      return Left(DatabaseFailure(message: 'Failed to get category breakdown: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<MonthlyExpense>>> getMonthlyTrends({
    required String userId,
    int months = 12,
  }) async {
    try {
      // TODO: Implement monthly trends query
      return const Right([]);
    } catch (e) {
      return Left(DatabaseFailure(message: 'Failed to get monthly trends: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, SyncResult>> syncExpenses(String userId) async {
    try {
      // TODO: Implement sync logic
      // 1. Get local changes (unsynced expenses)
      // 2. Send to remote API
      // 3. Get remote changes
      // 4. Merge conflicts
      // 5. Update local database

      return Right(SyncResult.success(
        uploadedCount: 0,
        downloadedCount: 0,
      ));
    } catch (e) {
      return Left(NetworkFailure(message: 'Failed to sync expenses: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Expense>>> searchExpenses({
    required String userId,
    required String query,
    int? limit,
  }) async {
    try {
      return getExpenses(
        userId: userId,
        searchQuery: query,
        limit: limit,
      );
    } catch (e) {
      return Left(DatabaseFailure(message: 'Failed to search expenses: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Expense>>> getRecurringExpenses(String userId) async {
    try {
      // TODO: Implement recurring expenses query
      return const Right([]);
    } catch (e) {
      return Left(DatabaseFailure(message: 'Failed to get recurring expenses: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Expense>>> bulkCreateExpenses(List<Expense> expenses) async {
    try {
      final companions = expenses.map(_mapEntityToDatabaseCompanion).toList();

      await _database.batch((batch) {
        batch.insertAll(_database.expenses, companions, mode: drift.InsertMode.insertOrReplace);
      });

      return Right(expenses);
    } catch (e) {
      return Left(DatabaseFailure(message: 'Failed to bulk create expenses: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Expense>>> getExpensesNearLocation({
    required String userId,
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  }) async {
    try {
      // TODO: Implement location-based query
      // This would require spatial queries or approximation
      return const Right([]);
    } catch (e) {
      return Left(DatabaseFailure(message: 'Failed to get expenses near location: ${e.toString()}'));
    }
  }

  /// Maps database expense model to domain entity
  Expense _mapDatabaseExpenseToEntity(db.Expense expense) {
    return Expense(
      id: expense.id,
      userId: expense.userId,
      amount: expense.amount,
      currency: expense.currency,
      description: expense.description,
      category: ExpenseCategory.values.firstWhere(
        (c) => c.name == expense.category,
        orElse: () => ExpenseCategory.other,
      ),
      date: expense.date,
      paymentMethod: expense.paymentMethod != null
          ? PaymentMethod.values.firstWhere(
              (p) => p.name == expense.paymentMethod,
              orElse: () => PaymentMethod.other,
            )
          : null,
      tags: expense.tags != null ? jsonDecode(expense.tags!) : null,
      receiptUrl: expense.receiptUrl,
      location: expense.latitude != null && expense.longitude != null
          ? ExpenseLocation(
              latitude: expense.latitude!,
              longitude: expense.longitude!,
              address: expense.address,
              placeName: expense.placeName,
            )
          : null,
      isRecurring: expense.isRecurring,
      recurringConfig: expense.recurringFrequency != null
          ? RecurringConfig(
              frequency: RecurringFrequency.values.firstWhere(
                (f) => f.name == expense.recurringFrequency,
                orElse: () => RecurringFrequency.monthly,
              ),
              interval: expense.recurringInterval ?? 1,
              endDate: expense.recurringEndDate,
              nextOccurrence: expense.nextOccurrence ?? DateTime.now(),
            )
          : null,
      createdAt: expense.createdAt,
      updatedAt: expense.updatedAt,
      isSynced: expense.isSynced,
      note: expense.note,
    );
  }

  /// Maps domain entity to database companion
  db.ExpensesCompanion _mapEntityToDatabaseCompanion(Expense expense) {
    return db.ExpensesCompanion(
      id: drift.Value(expense.id),
      userId: drift.Value(expense.userId),
      amount: drift.Value(expense.amount),
      currency: drift.Value(expense.currency),
      description: drift.Value(expense.description),
      category: drift.Value(expense.category.name),
      date: drift.Value(expense.date),
      paymentMethod: drift.Value(expense.paymentMethod?.name),
      tags: drift.Value(expense.tags != null ? jsonEncode(expense.tags) : null),
      receiptUrl: drift.Value(expense.receiptUrl),
      latitude: drift.Value(expense.location?.latitude),
      longitude: drift.Value(expense.location?.longitude),
      address: drift.Value(expense.location?.address),
      placeName: drift.Value(expense.location?.placeName),
      isRecurring: drift.Value(expense.isRecurring),
      recurringFrequency: drift.Value(expense.recurringConfig?.frequency.name),
      recurringInterval: drift.Value(expense.recurringConfig?.interval),
      recurringEndDate: drift.Value(expense.recurringConfig?.endDate),
      nextOccurrence: drift.Value(expense.recurringConfig?.nextOccurrence),
      createdAt: drift.Value(expense.createdAt),
      updatedAt: drift.Value(expense.updatedAt),
      isSynced: drift.Value(expense.isSynced),
      note: drift.Value(expense.note),
    );
  }
}
