import 'package:flutter_test/flutter_test.dart';
import 'package:finwise/domain/entities/expense.dart';
import 'package:finwise/domain/entities/budget.dart';
import 'package:finwise/presentation/providers/undo_redo_provider.dart';

void main() {
  group('UndoRedoNotifier', () {
    late UndoRedoNotifier undoRedoNotifier;

    setUp(() {
      undoRedoNotifier = UndoRedoNotifier();
    });

    tearDown(() {
      undoRedoNotifier.dispose();
    });

    test('should initialize with empty state', () {
      expect(undoRedoNotifier.state.canUndo, false);
      expect(undoRedoNotifier.state.canRedo, false);
      expect(undoRedoNotifier.state.lastUndoneAction, null);
      expect(undoRedoNotifier.state.nextRedoAction, null);
    });

    test('should execute and track undoable actions', () async {
      final action = CreateExpenseAction(Expense(
        id: 'test_expense',
        userId: 'user_123',
        amount: 10000, // $100.00
        currency: 'USD',
        description: 'Test expense',
        category: ExpenseCategory.food,
        date: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      await undoRedoNotifier.execute(action);

      expect(undoRedoNotifier.state.canUndo, true);
      expect(undoRedoNotifier.state.canRedo, false);
      expect(undoRedoNotifier.getRecentActions().length, 1);
      expect(undoRedoNotifier.getRecentActions()[0].id, action.id);
    });

    test('should undo last action', () async {
      final action = CreateExpenseAction(Expense(
        id: 'test_expense',
        userId: 'user_123',
        amount: 5000,
        currency: 'USD',
        description: 'Test expense',
        category: ExpenseCategory.transport,
        date: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      await undoRedoNotifier.execute(action);
      expect(undoRedoNotifier.state.canUndo, true);

      await undoRedoNotifier.undo();

      expect(undoRedoNotifier.state.canUndo, false);
      expect(undoRedoNotifier.state.canRedo, true);
      expect(undoRedoNotifier.state.lastUndoneAction, action);
    });

    test('should redo undone action', () async {
      final action = UpdateExpenseAction(
        Expense(
          id: 'test_expense',
          userId: 'user_123',
          amount: 5000,
          currency: 'USD',
          description: 'Old description',
          category: ExpenseCategory.food,
          date: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Expense(
          id: 'test_expense',
          userId: 'user_123',
          amount: 7500,
          currency: 'USD',
          description: 'New description',
          category: ExpenseCategory.food,
          date: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      await undoRedoNotifier.execute(action);
      await undoRedoNotifier.undo();
      expect(undoRedoNotifier.state.canRedo, true);

      await undoRedoNotifier.redo();

      expect(undoRedoNotifier.state.canUndo, true);
      expect(undoRedoNotifier.state.canRedo, false);
    });

    test('should clear history', () async {
      final action1 = CreateExpenseAction(Expense(
        id: 'expense_1',
        userId: 'user_123',
        amount: 1000,
        currency: 'USD',
        description: 'Expense 1',
        category: ExpenseCategory.other,
        date: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final action2 = CreateExpenseAction(Expense(
        id: 'expense_2',
        userId: 'user_123',
        amount: 2000,
        currency: 'USD',
        description: 'Expense 2',
        category: ExpenseCategory.other,
        date: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      await undoRedoNotifier.execute(action1);
      await undoRedoNotifier.execute(action2);

      expect(undoRedoNotifier.getRecentActions().length, 2);

      undoRedoNotifier.clearHistory();

      expect(undoRedoNotifier.state.canUndo, false);
      expect(undoRedoNotifier.state.canRedo, false);
      expect(undoRedoNotifier.getRecentActions(), isEmpty);
    });

    test('should limit history size', () async {
      // Add more than max history size (50)
      for (int i = 0; i < 55; i++) {
        final action = CreateExpenseAction(Expense(
          id: 'expense_$i',
          userId: 'user_123',
          amount: 1000 + i,
          currency: 'USD',
          description: 'Expense $i',
          category: ExpenseCategory.other,
          date: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));

        await undoRedoNotifier.execute(action);
      }

      // Should only keep last 50 actions
      expect(undoRedoNotifier.getRecentActions().length, 50);
      expect(undoRedoNotifier.getRecentActions()[0].description, 'Created expense: Expense 5');
    });

    test('should filter actions by type', () async {
      final expenseAction = CreateExpenseAction(Expense(
        id: 'expense_1',
        userId: 'user_123',
        amount: 1000,
        currency: 'USD',
        description: 'Test expense',
        category: ExpenseCategory.food,
        date: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final budgetAction = CreateBudgetAction(Budget(
        id: 'budget_1',
        userId: 'user_123',
        name: 'Test Budget',
        amount: 50000,
        currency: 'USD',
        categories: [ExpenseCategory.food],
        period: BudgetPeriod.monthly,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 30)),
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      await undoRedoNotifier.execute(expenseAction);
      await undoRedoNotifier.execute(budgetAction);

      final expenseActions = undoRedoNotifier.getActionsByType('expense');
      final budgetActions = undoRedoNotifier.getActionsByType('budget');

      expect(expenseActions.length, 1);
      expect(expenseActions[0].actionType, 'expense');
      expect(budgetActions.length, 1);
      expect(budgetActions[0].actionType, 'budget');
    });
  });

  group('Undoable Actions', () {
    group('CreateExpenseAction', () {
      test('should create action with correct description', () {
        final expense = Expense(
          id: 'test_expense',
          userId: 'user_123',
          amount: 2500, // $25.00
          currency: 'USD',
          description: 'Lunch at restaurant',
          category: ExpenseCategory.food,
          date: DateTime(2024, 1, 15),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final action = CreateExpenseAction(expense);

        expect(action.id.startsWith('create_expense_test_expense'), true);
        expect(action.description, 'Created expense: Lunch at restaurant');
        expect(action.actionDescription, 'Created expense "Lunch at restaurant" for \$25.00');
        expect(action.actionType, 'expense');
        expect(action.canUndo, true);
      });

      test('should serialize and deserialize correctly', () {
        final expense = Expense(
          id: 'test_expense',
          userId: 'user_123',
          amount: 3000,
          currency: 'USD',
          description: 'Test expense',
          category: ExpenseCategory.transport,
          date: DateTime(2024, 1, 1),
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        );

        final action = CreateExpenseAction(expense);
        final json = action.toJson();
        final deserializedAction = UndoableAction.fromJson(json);

        expect(deserializedAction, isA<CreateExpenseAction>());
        final createAction = deserializedAction as CreateExpenseAction;
        expect(createAction.expense.id, expense.id);
        expect(createAction.expense.amount, expense.amount);
        expect(createAction.expense.description, expense.description);
      });
    });

    group('UpdateExpenseAction', () {
      test('should create action with correct description', () {
        final oldExpense = Expense(
          id: 'test_expense',
          userId: 'user_123',
          amount: 2000,
          currency: 'USD',
          description: 'Old description',
          category: ExpenseCategory.food,
          date: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final newExpense = Expense(
          id: 'test_expense',
          userId: 'user_123',
          amount: 2500,
          currency: 'USD',
          description: 'Updated description',
          category: ExpenseCategory.food,
          date: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final action = UpdateExpenseAction(oldExpense, newExpense);

        expect(action.id.startsWith('update_expense_test_expense'), true);
        expect(action.description, 'Updated expense: Old description');
        expect(action.actionDescription, 'Updated expense "Old description"');
        expect(action.actionType, 'expense');
      });
    });

    group('DeleteExpenseAction', () {
      test('should create action with correct description', () {
        final expense = Expense(
          id: 'test_expense',
          userId: 'user_123',
          amount: 1500,
          currency: 'USD',
          description: 'Expense to delete',
          category: ExpenseCategory.other,
          date: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final action = DeleteExpenseAction(expense);

        expect(action.id.startsWith('delete_expense_test_expense'), true);
        expect(action.description, 'Deleted expense: Expense to delete');
        expect(action.actionDescription, 'Deleted expense "Expense to delete"');
        expect(action.actionType, 'expense');
      });
    });

    group('Budget Actions', () {
      test('CreateBudgetAction should work correctly', () {
        final budget = Budget(
          id: 'test_budget',
          userId: 'user_123',
          name: 'Monthly Budget',
          amount: 100000, // $1000.00
          currency: 'USD',
          categories: [ExpenseCategory.food, ExpenseCategory.transport],
          period: BudgetPeriod.monthly,
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 1, 31),
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final action = CreateBudgetAction(budget);

        expect(action.id.startsWith('create_budget_test_budget'), true);
        expect(action.description, 'Created budget: Monthly Budget');
        expect(action.actionDescription, 'Created budget "Monthly Budget"');
        expect(action.actionType, 'budget');
      });
    });
  });

  group('UndoRedo Extensions', () {
    test('should execute action with undo support', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final action = CreateExpenseAction(Expense(
        id: 'extension_test',
        userId: 'user_123',
        amount: 1000,
        currency: 'USD',
        description: 'Extension test',
        category: ExpenseCategory.other,
        date: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      await container.executeWithUndo(action);

      expect(container.read(canUndoProvider), true);
      expect(container.read(canRedoProvider), false);
    });
  });

  group('UndoRedoSnackBar', () {
    test('should show undo snackbar', () {
      // This would typically be tested in a widget test
      // but we can verify the static method exists
      expect(UndoRedoSnackBar.showUndoSnackBar, isNotNull);
    });
  });
}
