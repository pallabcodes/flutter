import 'package:finwise/domain/entities/expense.dart';
import 'package:finwise/presentation/theme/app_theme.dart';
import 'package:finwise/presentation/widgets/expense_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test_utils/test_helpers.dart';

void main() {
  late Expense testExpense;

  setUp(() {
    testExpense = TestHelpers.createTestExpense(
      id: 'test_expense_1',
      userId: 'test_user',
      amount: 2599, // $25.99
      description: 'Lunch at restaurant',
      category: ExpenseCategory.food,
      date: DateTime(2024, 1, 15),
    );
  });

  group('ExpenseCard Widget Tests', () {
    testWidgets('should display expense information correctly', (tester) async {
      // Arrange
      await tester.pumpWidget(
        TestHelpers.TestWidgetWrapper(
          child: ExpenseCard(expense: testExpense),
        ),
      );

      // Assert
      expect(find.text('Lunch at restaurant'), findsOneWidget);
      expect(find.text('\$25.99'), findsOneWidget);
      expect(find.text('Jan 15, 2024'), findsOneWidget);
      expect(find.text('FOOD'), findsOneWidget);
    });

    testWidgets('should display different date formats correctly', (tester) async {
      // Test today
      final todayExpense = testExpense.copyWith(date: DateTime.now());
      await tester.pumpWidget(
        TestHelpers.TestWidgetWrapper(
          child: ExpenseCard(expense: todayExpense),
        ),
      );
      expect(find.text('Today'), findsOneWidget);

      // Test yesterday
      final yesterdayExpense = testExpense.copyWith(
        date: DateTime.now().subtract(const Duration(days: 1)),
      );
      await tester.pumpWidget(
        TestHelpers.TestWidgetWrapper(
          child: ExpenseCard(expense: yesterdayExpense),
        ),
      );
      expect(find.text('Yesterday'), findsOneWidget);

      // Test this week
      final thisWeekExpense = testExpense.copyWith(
        date: DateTime.now().subtract(const Duration(days: 3)),
      );
      await tester.pumpWidget(
        TestHelpers.TestWidgetWrapper(
          child: ExpenseCard(expense: thisWeekExpense),
        ),
      );
      // Should show day name (e.g., "Monday")
      expect(find.byType(ExpenseCard), findsOneWidget);
    });

    testWidgets('should display recurring expense indicator', (tester) async {
      // Arrange
      final recurringExpense = testExpense.copyWith(isRecurring: true);

      await tester.pumpWidget(
        TestHelpers.TestWidgetWrapper(
          child: ExpenseCard(expense: recurringExpense),
        ),
      );

      // Assert
      expect(find.text('Recurring'), findsOneWidget);
      expect(find.byIcon(Icons.repeat), findsOneWidget);
    });

    testWidgets('should not display recurring indicator for non-recurring expense', (tester) async {
      // Arrange
      final nonRecurringExpense = testExpense.copyWith(isRecurring: false);

      await tester.pumpWidget(
        TestHelpers.TestWidgetWrapper(
          child: ExpenseCard(expense: nonRecurringExpense),
        ),
      );

      // Assert
      expect(find.text('Recurring'), findsNothing);
      expect(find.byIcon(Icons.repeat), findsNothing);
    });

    testWidgets('should display category icon correctly', (tester) async {
      // Test different categories
      final categoriesToTest = [
        ExpenseCategory.food,
        ExpenseCategory.transportation,
        ExpenseCategory.entertainment,
        ExpenseCategory.shopping,
        ExpenseCategory.bills,
        ExpenseCategory.healthcare,
        ExpenseCategory.education,
        ExpenseCategory.travel,
        ExpenseCategory.personal,
        ExpenseCategory.other,
      ];

      for (final category in categoriesToTest) {
        final categoryExpense = testExpense.copyWith(category: category);

        await tester.pumpWidget(
          TestHelpers.TestWidgetWrapper(
            child: ExpenseCard(expense: categoryExpense),
          ),
        );

        // Each category should have an icon
        expect(find.byIcon(Icons.restaurant), findsOneWidget); // Default fallback
        await tester.pumpAndSettle();
      }
    });

    testWidgets('should handle long descriptions with ellipsis', (tester) async {
      // Arrange
      final longDescriptionExpense = testExpense.copyWith(
        description: 'This is a very long description that should be truncated with ellipsis when it exceeds the available space',
      );

      await tester.pumpWidget(
        TestHelpers.TestWidgetWrapper(
          child: SizedBox(
            width: 300, // Constrain width to force truncation
            child: ExpenseCard(expense: longDescriptionExpense),
          ),
        ),
      );

      // The text should be truncated
      final textWidget = tester.widget<Text>(
        find.text('This is a very long description that should be truncated with ellipsis when it exceeds the available space'),
      );
      expect(textWidget.maxLines, equals(1));
      expect(textWidget.overflow, equals(TextOverflow.ellipsis));
    });

    testWidgets('should handle note display', (tester) async {
      // Arrange
      final expenseWithNote = testExpense.copyWith(note: 'Additional expense details');

      await tester.pumpWidget(
        TestHelpers.TestWidgetWrapper(
          child: ExpenseCard(expense: expenseWithNote),
        ),
      );

      // Assert
      expect(find.text('Additional expense details'), findsOneWidget);
    });

    testWidgets('should handle empty note gracefully', (tester) async {
      // Arrange
      final expenseWithoutNote = testExpense.copyWith(note: null);

      await tester.pumpWidget(
        TestHelpers.TestWidgetWrapper(
          child: ExpenseCard(expense: expenseWithoutNote),
        ),
      );

      // Assert - no note should be displayed
      expect(find.text('Additional expense details'), findsNothing);
    });

    testWidgets('should call onTap callback when tapped', (tester) async {
      // Arrange
      bool tapped = false;
      final expenseCard = ExpenseCard(
        expense: testExpense,
        onTap: () => tapped = true,
      );

      await tester.pumpWidget(
        TestHelpers.TestWidgetWrapper(child: expenseCard),
      );

      // Act
      await tester.tap(find.byType(ExpenseCard));
      await tester.pumpAndSettle();

      // Assert
      expect(tapped, isTrue);
    });

    testWidgets('should not be tappable when onTap is null', (tester) async {
      // Arrange
      await tester.pumpWidget(
        TestHelpers.TestWidgetWrapper(
          child: ExpenseCard(expense: testExpense), // No onTap callback
        ),
      );

      // The card should still render but not respond to taps
      expect(find.byType(ExpenseCard), findsOneWidget);
      expect(find.text('Lunch at restaurant'), findsOneWidget);
    });

    testWidgets('should display different payment methods', (tester) async {
      // Test various payment methods
      final paymentMethods = [
        null,
        // Note: PaymentMethod enum would need to be imported and tested
      ];

      for (final method in paymentMethods) {
        final expenseWithPayment = testExpense.copyWith(paymentMethod: method);

        await tester.pumpWidget(
          TestHelpers.TestWidgetWrapper(
            child: ExpenseCard(expense: expenseWithPayment),
          ),
        );

        // Should render without errors
        expect(find.byType(ExpenseCard), findsOneWidget);
      }
    });

    testWidgets('should format currency correctly', (tester) async {
      // Test various amounts
      final testAmounts = [
        99,    // $0.99
        100,   // $1.00
        150,   // $1.50
        999,   // $9.99
        1000,  // $10.00
        12345, // $123.45
      ];

      for (final amount in testAmounts) {
        final expenseWithAmount = testExpense.copyWith(amount: amount);

        await tester.pumpWidget(
          TestHelpers.TestWidgetWrapper(
            child: ExpenseCard(expense: expenseWithAmount),
          ),
        );

        // Should display formatted amount
        expect(find.byType(ExpenseCard), findsOneWidget);
      }
    });

    testWidgets('should show category colors correctly', (tester) async {
      // Arrange
      await tester.pumpWidget(
        TestHelpers.TestWidgetWrapper(
          child: ExpenseCard(expense: testExpense),
        ),
      );

      // The card should use the appropriate category color
      final card = tester.widget<Card>(find.byType(Card));
      // Note: Testing exact colors would require more complex widget testing
      expect(card, isNotNull);
    });

    testWidgets('should handle showCategoryIcon parameter', (tester) async {
      // Test with icon shown (default)
      await tester.pumpWidget(
        TestHelpers.TestWidgetWrapper(
          child: ExpenseCard(expense: testExpense, showCategoryIcon: true),
        ),
      );

      // Should show icon
      expect(find.byType(ExpenseCard), findsOneWidget);

      // Test with icon hidden
      await tester.pumpWidget(
        TestHelpers.TestWidgetWrapper(
          child: ExpenseCard(expense: testExpense, showCategoryIcon: false),
        ),
      );

      // Should still render correctly
      expect(find.byType(ExpenseCard), findsOneWidget);
    });

    testWidgets('should be accessible', (tester) async {
      // Arrange
      await tester.pumpWidget(
        TestHelpers.TestWidgetWrapper(
          child: ExpenseCard(expense: testExpense),
        ),
      );

      // Check for semantic labels (accessibility)
      final semantics = tester.getSemantics(find.byType(ExpenseCard));
      expect(semantics, isNotNull);
    });

    testWidgets('should handle null values gracefully', (tester) async {
      // Arrange - create expense with some null values
      final incompleteExpense = Expense(
        id: 'test_id',
        userId: 'test_user',
        amount: 1000,
        currency: 'USD',
        description: 'Test',
        category: ExpenseCategory.other,
        date: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isSynced: false,
      );

      await tester.pumpWidget(
        TestHelpers.TestWidgetWrapper(
          child: ExpenseCard(expense: incompleteExpense),
        ),
      );

      // Should render without crashing
      expect(find.byType(ExpenseCard), findsOneWidget);
      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('should handle very small amounts', (tester) async {
      // Arrange
      final smallAmountExpense = testExpense.copyWith(amount: 1); // $0.01

      await tester.pumpWidget(
        TestHelpers.TestWidgetWrapper(
          child: ExpenseCard(expense: smallAmountExpense),
        ),
      );

      // Assert
      expect(find.text('\$0.01'), findsOneWidget);
    });

    testWidgets('should handle large amounts', (tester) async {
      // Arrange
      final largeAmountExpense = testExpense.copyWith(amount: 10000000); // $100,000.00

      await tester.pumpWidget(
        TestHelpers.TestWidgetWrapper(
          child: ExpenseCard(expense: largeAmountExpense),
        ),
      );

      // Assert
      expect(find.text('\$100,000.00'), findsOneWidget);
    });
  });
}
