import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:finwise/core/config/app_config.dart';
import 'package:finwise/data/datasources/local/database/tables/expense_table.dart';
import 'package:finwise/data/datasources/local/database/tables/budget_table.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:injectable/injectable.dart';

part 'database.g.dart';

/// Main database class using Drift ORM
/// Handles all local data persistence with proper migrations
@DriftDatabase(tables: [Expenses, Budgets])
@singleton
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        // Initialize with default categories or sample data if needed
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Handle schema migrations here
        if (from < 2) {
          // Example migration logic
          // await m.addColumn(expenses, expenses.newColumn);
        }
      },
      beforeOpen: (details) async {
        // Enable foreign keys and other PRAGMA settings
        await customStatement('PRAGMA foreign_keys = ON');

        // Enable WAL mode for better performance
        if (details.wasCreated) {
          await customStatement('PRAGMA journal_mode = WAL');
        }
      },
    );
  }

  /// Get all expenses for a user with optional filtering
  Future<List<Expense>> getExpenses({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? categoryIds,
    String? searchQuery,
    int? limit,
    int? offset,
  }) {
    var query = select(expenses)..where((tbl) => tbl.userId.equals(userId));

    if (startDate != null) {
      query = query..where((tbl) => tbl.date.isBiggerOrEqualValue(startDate));
    }

    if (endDate != null) {
      query = query..where((tbl) => tbl.date.isSmallerOrEqualValue(endDate));
    }

    if (categoryIds != null && categoryIds.isNotEmpty) {
      query = query..where((tbl) => tbl.category.isIn(categoryIds));
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query
        ..where((tbl) =>
            tbl.description.contains(searchQuery) |
            tbl.note.contains(searchQuery));
    }

    if (limit != null) {
      query = query..limit(limit, offset: offset ?? 0);
    }

    return query.get();
  }

  /// Get expense by ID
  Future<Expense?> getExpense(String expenseId) {
    return (select(expenses)..where((tbl) => tbl.id.equals(expenseId)))
        .getSingleOrNull();
  }

  /// Insert or update expense
  Future<int> saveExpense(ExpensesCompanion expense) {
    return into(expenses).insertOnConflictUpdate(expense);
  }

  /// Delete expense
  Future<int> deleteExpense(String expenseId) {
    return (delete(expenses)..where((tbl) => tbl.id.equals(expenseId))).go();
  }

  /// Get expenses by date range for statistics
  Future<List<Expense>> getExpensesInRange(
      String userId, DateTime start, DateTime end) async {
    final query = select(expenses)
      ..where((tbl) =>
          tbl.userId.equals(userId) &
          tbl.date.isBiggerOrEqualValue(start) &
          tbl.date.isSmallerOrEqualValue(end))
      ..orderBy(
          [(t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)]);
    return query.get();
  }

  /// Get expense statistics
  Future<Map<String, dynamic>> getExpenseStats(
      String userId, DateTime start, DateTime end) async {
    final result = await customSelect(
      '''
      SELECT
        COUNT(*) as total_count,
        SUM(amount) as total_amount,
        AVG(amount) as avg_amount,
        MIN(amount) as min_amount,
        MAX(amount) as max_amount,
        GROUP_CONCAT(DISTINCT category) as categories
      FROM expenses
      WHERE user_id = ? AND date BETWEEN ? AND ?
      ''',
      variables: [
        Variable.withString(userId),
        Variable.withDateTime(start),
        Variable.withDateTime(end)
      ],
    ).getSingle();

    return {
      'totalCount': result.read<int>('total_count'),
      'totalAmount': result.read<int?>('total_amount') ?? 0,
      'averageAmount': result.read<double?>('avg_amount') ?? 0.0,
      'minAmount': result.read<int?>('min_amount') ?? 0,
      'maxAmount': result.read<int?>('max_amount') ?? 0,
      'categories': result.read<String?>('categories')?.split(',') ?? [],
    };
  }

  /// Get all budgets for a user
  Future<List<Budget>> getBudgets(String userId) {
    return (select(budgets)
          ..where((tbl) => tbl.userId.equals(userId))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)
          ]))
        .get();
  }

  /// Get active budgets
  Future<List<Budget>> getActiveBudgets(String userId) {
    final now = DateTime.now();
    return (select(budgets)
          ..where((tbl) =>
              tbl.userId.equals(userId) &
              tbl.isActive.equals(true) &
              tbl.startDate.isSmallerOrEqualValue(now) &
              tbl.endDate.isBiggerOrEqualValue(now)))
        .get();
  }

  /// Get budget by ID
  Future<Budget?> getBudget(String budgetId) {
    return (select(budgets)..where((tbl) => tbl.id.equals(budgetId)))
        .getSingleOrNull();
  }

  /// Save budget
  Future<int> saveBudget(BudgetsCompanion budget) {
    return into(budgets).insertOnConflictUpdate(budget);
  }

  /// Delete budget
  Future<int> deleteBudget(String budgetId) {
    return (delete(budgets)..where((tbl) => tbl.id.equals(budgetId))).go();
  }

  /// Update budget spent amount
  Future<bool> updateBudgetSpentAmount(String budgetId, int spentAmount) {
    return (update(budgets)..where((tbl) => tbl.id.equals(budgetId)))
        .write(BudgetsCompanion(
          spentAmount: Value(spentAmount),
          updatedAt: Value(DateTime.now()),
        ))
        .then((rowsAffected) => rowsAffected > 0);
  }

  /// Clear all data (useful for logout or data reset)
  Future<void> clearAllData() async {
    await delete(expenses).go();
    await delete(budgets).go();
  }

  /// Get database file size
  Future<int> getDatabaseSize() async {
    final result = await customSelect('PRAGMA page_size').getSingle();
    final pageSize = result.read<int>('page_size');

    final pageCountResult = await customSelect('PRAGMA page_count').getSingle();
    final pageCount = pageCountResult.read<int>('page_count');

    return pageSize * pageCount;
  }

  /// Optimize database
  Future<void> optimizeDatabase() async {
    await customStatement('VACUUM');
    await customStatement('ANALYZE');
  }
}

/// Open database connection with proper path handling
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, AppConfig.databaseName));

    return NativeDatabase.createInBackground(file);
  });
}
