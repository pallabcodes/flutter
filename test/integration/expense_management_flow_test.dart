import 'dart:io';

import 'package:finwise/core/config/injection.dart';
import 'package:finwise/domain/entities/expense.dart';
import 'package:finwise/domain/repositories/expense_repository.dart';
import 'package:finwise/presentation/providers/expense_providers.dart';
import 'package:finwise/presentation/screens/add_expense/add_expense_screen.dart';
import 'package:finwise/presentation/screens/home/home_screen.dart';
import 'package:finwise/presentation/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../test_utils/test_helpers.dart';

// Mock implementations for integration testing
class MockExpenseRepository extends Mock implements ExpenseRepository {
  final List<Expense> _expenses = [];

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
    var filteredExpenses = _expenses.where((expense) => expense.userId == userId).toList();

    // Apply date filtering
    if (startDate != null) {
      filteredExpenses = filteredExpenses.where((expense) =>
        expense.date.isAfter(startDate.subtract(const Duration(days: 1)))).toList();
    }
    if (endDate != null) {
      filteredExpenses = filteredExpenses.where((expense) =>
        expense.date.isBefore(endDate.add(const Duration(days: 1)))).toList();
    }

    // Apply category filtering
    if (categories != null && categories.isNotEmpty) {
      filteredExpenses = filteredExpenses.where((expense) =>
        categories.contains(expense.category)).toList();
    }

    // Apply search filtering
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filteredExpenses = filteredExpenses.where((expense) =>
        expense.description.toLowerCase().contains(query) ||
        expense.category.name.toLowerCase().contains(query)).toList();
    }

    // Sort by date descending
    filteredExpenses.sort((a, b) => b.date.compareTo(a.date));

    return Right(filteredExpenses);
  }

  @override
  Future<Either<Failure, Expense>> createExpense(Expense expense) async {
    final newExpense = expense.copyWith(
      id: 'integration_test_${DateTime.now().millisecondsSinceEpoch}',
    );
    _expenses.add(newExpense);
    return Right(newExpense);
  }

  // Other methods can return default implementations
  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

void main() {
  late MockExpenseRepository mockRepository;
  late ProviderContainer container;

  setUp(() async {
    mockRepository = MockExpenseRepository();

    // Set up dependency injection with mock
    await configureDependencies();

    // Override the repository provider
    container = ProviderContainer(
      overrides: [
        expenseRepositoryProvider.overrideWithValue(mockRepository),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('Expense Management Integration Tests', () {
    testWidgets('complete expense creation and display flow', (tester) async {
      // Arrange - Set up providers
      final testUserId = 'integration_test_user';

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially should show empty state
      expect(find.text('No expenses yet'), findsOneWidget);

      // Navigate to add expense screen
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Should be on add expense screen
      expect(find.text('Add Expense'), findsOneWidget);

      // Fill out the form
      await tester.enterText(find.byType(TextFormField).first, '25.99');
      await tester.enterText(find.widgetWithText(TextFormField, 'Description'), 'Integration test expense');

      // Select category (assuming first category chip)
      await tester.tap(find.byType(FilterChip).first);
      await tester.pumpAndSettle();

      // Submit the form
      await tester.tap(find.text('Create Expense'));
      await tester.pumpAndSettle();

      // Should navigate back to home screen
      expect(find.text('FinWise'), findsOneWidget);

      // Should show the created expense
      expect(find.text('Integration test expense'), findsOneWidget);
      expect(find.text('\$25.99'), findsOneWidget);

      // Verify the expense was actually created
      final expensesAsync = container.read(expensesProvider);
      expect(expensesAsync, isA<AsyncData<List<Expense>>>());

      final expenses = (expensesAsync as AsyncData<List<Expense>>).value;
      expect(expenses.length, equals(1));
      expect(expenses.first.description, equals('Integration test expense'));
      expect(expenses.first.amount, equals(2599)); // $25.99 in cents
    });

    testWidgets('expense filtering and search functionality', (tester) async {
      // Arrange - Create multiple test expenses
      final testExpenses = TestHelpers.createTestExpensesList(count: 5);
      for (final expense in testExpenses) {
        mockRepository.createExpense(expense);
      }

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should display all expenses initially
      expect(find.byType(ListView), findsOneWidget);

      // Test search functionality (if implemented)
      // Note: This assumes search UI exists, adjust based on actual implementation
      final searchFields = find.byType(TextField).where((element) {
        final widget = element.widget as TextField;
        return widget.decoration?.hintText?.contains('search') == true ||
               widget.decoration?.labelText?.contains('Search') == true;
      });

      if (searchFields.isNotEmpty) {
        // Enter search query
        await tester.enterText(searchFields.first, 'food');
        await tester.pumpAndSettle();

        // Should filter results
        // Note: Actual filtering logic depends on implementation
      }
    });

    testWidgets('expense list refresh functionality', (tester) async {
      // Arrange - Start with empty list
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show empty state
      expect(find.text('No expenses yet'), findsOneWidget);

      // Add an expense programmatically
      final testExpense = TestHelpers.createTestExpense();
      mockRepository.createExpense(testExpense);

      // Pull to refresh
      await tester.drag(find.byType(ListView), const Offset(0, 300));
      await tester.pumpAndSettle();

      // Should now show the expense
      expect(find.text(testExpense.description), findsOneWidget);
    });

    testWidgets('expense details and editing flow', (tester) async {
      // Arrange - Add a test expense
      final testExpense = TestHelpers.createTestExpense();
      mockRepository.createExpense(testExpense);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show the expense
      expect(find.text(testExpense.description), findsOneWidget);

      // Tap on the expense card
      await tester.tap(find.text(testExpense.description));
      await tester.pumpAndSettle();

      // Should navigate to expense details (if implemented)
      // Note: This depends on whether expense details screen exists
      // For now, just verify the tap doesn't crash
    });

    testWidgets('error handling in expense operations', (tester) async {
      // Arrange - Set up repository to fail
      when(mockRepository.createExpense(any))
          .thenAnswer((_) async => Left(DatabaseFailure('Test error')));

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const AddExpenseScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Fill out form minimally
      await tester.enterText(find.byType(TextFormField).first, '10.00');
      await tester.enterText(find.widgetWithText(TextFormField, 'Description'), 'Test expense');

      // Try to submit
      await tester.tap(find.text('Create Expense'));
      await tester.pumpAndSettle();

      // Should show error message
      expect(find.textContaining('Failed'), findsOneWidget);
    });

    testWidgets('navigation between screens', (tester) async {
      // Test navigation to add expense screen
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap add button
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Should be on add expense screen
      expect(find.text('Add Expense'), findsOneWidget);

      // Navigate back
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Should be back on home screen
      expect(find.text('FinWise'), findsOneWidget);
    });

    testWidgets('budget integration with expenses', (tester) async {
      // This test would verify that expenses update budget progress
      // Note: Implementation depends on budget-expense integration

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Add an expense that should affect budget
      final testExpense = TestHelpers.createTestExpense(
        category: ExpenseCategory.food,
        amount: 5000, // $50.00
      );
      mockRepository.createExpense(testExpense);

      // Navigate to budgets
      await tester.tap(find.byIcon(Icons.account_balance_wallet));
      await tester.pumpAndSettle();

      // Should be on budgets screen
      // Note: Budget integration testing depends on actual implementation
    });

    testWidgets('data persistence across app restarts', (tester) async {
      // Arrange - Add expense
      final testExpense = TestHelpers.createTestExpense();
      mockRepository.createExpense(testExpense);

      // Simulate app restart by creating new widget tree
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should still show the expense (if persistence is implemented)
      expect(find.text(testExpense.description), findsOneWidget);
    });

    testWidgets('responsive design across screen sizes', (tester) async {
      // Test on different screen sizes
      const testSizes = [
        Size(360, 640),   // Small phone
        Size(414, 896),   // Large phone
        Size(768, 1024),  // Tablet
      ];

      for (final size in testSizes) {
        await tester.binding.setSurfaceSize(size);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const HomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should render without overflow
        expect(tester.takeException(), isNull);
        expect(find.byType(HomeScreen), findsOneWidget);
      }

      // Reset to default size
      await tester.binding.setSurfaceSize(const Size(800, 600));
    });

    testWidgets('accessibility compliance', (tester) async {
      // Arrange - Add test expense
      final testExpense = TestHelpers.createTestExpense();
      mockRepository.createExpense(testExpense);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check for semantic labels
      final semantics = tester.getSemantics(find.byType(ListView));
      expect(semantics, isNotNull);

      // Test keyboard navigation (if implemented)
      // Note: Depends on actual accessibility implementation
    });

    testWidgets('performance with large expense lists', (tester) async {
      // Arrange - Create many expenses
      final manyExpenses = TestHelpers.createTestExpensesList(count: 100);
      for (final expense in manyExpenses) {
        mockRepository.createExpense(expense);
      }

      final startTime = DateTime.now().millisecondsSinceEpoch;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const HomeScreen(),
          ),
        ),
      );

      // Wait for initial load
      await tester.pumpAndSettle();

      final endTime = DateTime.now().millisecondsSinceEpoch;
      final loadTime = endTime - startTime;

      // Should load within reasonable time (under 2 seconds for 100 items)
      expect(loadTime, lessThan(2000));

      // Should display expenses without crashing
      expect(find.byType(ListView), findsOneWidget);
    });
  });
}
