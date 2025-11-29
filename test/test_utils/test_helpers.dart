import 'dart:io';

import 'package:finwise/domain/entities/expense.dart';
import 'package:finwise/domain/entities/budget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test utilities and helpers for comprehensive testing
class TestHelpers {
  /// Creates a test expense with default values
  static Expense createTestExpense({
    String? id,
    String? userId,
    int? amount,
    String? description,
    ExpenseCategory? category,
    DateTime? date,
    bool isRecurring = false,
  }) {
    return Expense(
      id: id ?? 'test_expense_id',
      userId: userId ?? 'test_user_id',
      amount: amount ?? 2500, // $25.00
      currency: 'USD',
      description: description ?? 'Test expense',
      category: category ?? ExpenseCategory.food,
      date: date ?? DateTime(2024, 1, 15),
      createdAt: DateTime(2024, 1, 15),
      updatedAt: DateTime(2024, 1, 15),
      isSynced: true,
    );
  }

  /// Creates a test budget with default values
  static Budget createTestBudget({
    String? id,
    String? userId,
    String? name,
    BudgetType? type,
    int? targetAmount,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return Budget(
      id: id ?? 'test_budget_id',
      userId: userId ?? 'test_user_id',
      name: name ?? 'Test Budget',
      type: type ?? BudgetType.category,
      targetAmount: targetAmount ?? 100000, // $1000.00
      currency: 'USD',
      period: BudgetPeriod.monthly,
      startDate: startDate ?? DateTime(2024, 1, 1),
      endDate: endDate ?? DateTime(2024, 1, 31),
      categories: [ExpenseCategory.food],
      spentAmount: 0,
      enableNotifications: true,
      warningThreshold: 80,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
      isActive: true,
      isSynced: true,
    );
  }

  /// Creates a list of test expenses with varied data
  static List<Expense> createTestExpensesList({
    int count = 5,
    String userId = 'test_user_id',
  }) {
    return List.generate(count, (index) {
      final categories = ExpenseCategory.values;
      final category = categories[index % categories.length];

      return createTestExpense(
        id: 'test_expense_$index',
        userId: userId,
        amount: (index + 1) * 1000, // $10.00, $20.00, etc.
        description: 'Test expense ${index + 1}',
        category: category,
        date: DateTime(2024, 1, index + 1),
      );
    });
  }

  /// Creates a list of test budgets
  static List<Budget> createTestBudgetsList({
    int count = 3,
    String userId = 'test_user_id',
  }) {
    return List.generate(count, (index) {
      final types = BudgetType.values;
      final type = types[index % types.length];

      return createTestBudget(
        id: 'test_budget_$index',
        userId: userId,
        name: 'Test Budget ${index + 1}',
        type: type,
        targetAmount: (index + 1) * 50000, // $500, $1000, etc.
      );
    });
  }

  /// Creates a test user authentication data
  static Map<String, dynamic> createTestUserData({
    String? id,
    String? email,
    String? displayName,
  }) {
    return {
      'id': id ?? 'test_user_id',
      'email': email ?? 'test@example.com',
      'displayName': displayName ?? 'Test User',
      'emailVerified': true,
      'lastSignInTime': DateTime.now().toIso8601String(),
      'creationTime': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
    };
  }
}

/// Custom test matchers for better test assertions
class TestMatchers {
  /// Matcher for expense objects
  static ExpenseMatcher isExpense({
    String? id,
    String? userId,
    int? amount,
    String? description,
    ExpenseCategory? category,
  }) {
    return ExpenseMatcher(
      id: id,
      userId: userId,
      amount: amount,
      description: description,
      category: category,
    );
  }

  /// Matcher for budget objects
  static BudgetMatcher isBudget({
    String? id,
    String? userId,
    String? name,
    BudgetType? type,
    int? targetAmount,
  }) {
    return BudgetMatcher(
      id: id,
      userId: userId,
      name: name,
      type: type,
      targetAmount: targetAmount,
    );
  }
}

/// Custom matcher for Expense objects
class ExpenseMatcher extends Matcher {
  final String? id;
  final String? userId;
  final int? amount;
  final String? description;
  final ExpenseCategory? category;

  ExpenseMatcher({
    this.id,
    this.userId,
    this.amount,
    this.description,
    this.category,
  });

  @override
  Description describe(Description description) {
    return description.add('Expense with properties: '
        'id=$id, userId=$userId, amount=$amount, '
        'description=$description, category=$category');
  }

  @override
  bool matches(dynamic item, Map matchState) {
    if (item is! Expense) return false;

    return (id == null || item.id == id) &&
           (userId == null || item.userId == userId) &&
           (amount == null || item.amount == amount) &&
           (description == null || item.description == description) &&
           (category == null || item.category == category);
  }
}

/// Custom matcher for Budget objects
class BudgetMatcher extends Matcher {
  final String? id;
  final String? userId;
  final String? name;
  final BudgetType? type;
  final int? targetAmount;

  BudgetMatcher({
    this.id,
    this.userId,
    this.name,
    this.type,
    this.targetAmount,
  });

  @override
  Description describe(Description description) {
    return description.add('Budget with properties: '
        'id=$id, userId=$userId, name=$name, type=$type, targetAmount=$targetAmount');
  }

  @override
  bool matches(dynamic item, Map matchState) {
    if (item is! Budget) return false;

    return (id == null || item.id == id) &&
           (userId == null || item.userId == userId) &&
           (name == null || item.name == name) &&
           (type == null || item.type == type) &&
           (targetAmount == null || item.targetAmount == targetAmount);
  }
}

/// Test widget wrapper for Riverpod testing
class TestWidgetWrapper extends StatelessWidget {
  final Widget child;
  final List<Override> overrides;

  const TestWidgetWrapper({
    super.key,
    required this.child,
    this.overrides = const [],
  });

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        home: child,
        // Add other theme/navigation configurations as needed for tests
      ),
    );
  }
}

/// Test file utilities
class TestFileUtils {
  /// Creates a temporary test image file
  static Future<File> createTestImageFile({
    String name = 'test_image.jpg',
    int size = 1024,
  }) async {
    final tempDir = Directory.systemTemp;
    final file = File('${tempDir.path}/$name');

    // Create a simple test image (just some bytes)
    final bytes = List<int>.generate(size, (i) => i % 256);
    await file.writeAsBytes(bytes);

    return file;
  }

  /// Cleans up test files
  static Future<void> cleanupTestFiles(List<File> files) async {
    for (final file in files) {
      if (await file.exists()) {
        await file.delete();
      }
    }
  }
}

/// Test database utilities
class TestDatabaseUtils {
  /// Creates an in-memory database for testing
  static Future<void> setupTestDatabase() async {
    // This would set up an in-memory database for testing
    // Implementation depends on your database setup
  }

  /// Cleans up test database
  static Future<void> cleanupTestDatabase() async {
    // Clean up test database after tests
  }
}

/// Mock data generators for consistent testing
class MockDataGenerator {
  static final _random = DateTime.now().millisecondsSinceEpoch;

  /// Generates a random expense ID
  static String randomExpenseId() => 'expense_${_random}_${DateTime.now().microsecondsSinceEpoch}';

  /// Generates a random budget ID
  static String randomBudgetId() => 'budget_${_random}_${DateTime.now().microsecondsSinceEpoch}';

  /// Generates a random user ID
  static String randomUserId() => 'user_${_random}_${DateTime.now().microsecondsSinceEpoch}';

  /// Generates a random amount between min and max (in cents)
  static int randomAmount({int min = 100, int max = 100000}) {
    return min + (_random % (max - min));
  }

  /// Generates a random date within the last year
  static DateTime randomDate() {
    final now = DateTime.now();
    final daysAgo = _random % 365;
    return now.subtract(Duration(days: daysAgo));
  }
}
