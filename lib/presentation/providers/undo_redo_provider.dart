import 'package:finwise/domain/entities/expense.dart';
import 'package:finwise/domain/entities/budget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Abstract base class for undoable actions
abstract class UndoableAction {
  final String id;
  final String description;
  final DateTime timestamp;

  UndoableAction({
    required this.id,
    required this.description,
  }) : timestamp = DateTime.now();

  /// Execute the action
  Future<void> execute();

  /// Undo the action
  Future<void> undo();

  /// Get a human-readable description of what this action does
  String get actionDescription;

  /// Check if this action can be undone
  bool get canUndo => true;

  /// Get the action type for UI categorization
  String get actionType;

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson();

  /// Create from JSON
  static UndoableAction? fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    switch (type) {
      case 'create_expense':
        return CreateExpenseAction.fromJson(json);
      case 'update_expense':
        return UpdateExpenseAction.fromJson(json);
      case 'delete_expense':
        return DeleteExpenseAction.fromJson(json);
      case 'create_budget':
        return CreateBudgetAction.fromJson(json);
      case 'update_budget':
        return UpdateBudgetAction.fromJson(json);
      case 'delete_budget':
        return DeleteBudgetAction.fromJson(json);
      default:
        return null;
    }
  }
}

/// Action for creating an expense
class CreateExpenseAction extends UndoableAction {
  final Expense expense;

  CreateExpenseAction(this.expense)
      : super(
          id: 'create_expense_${expense.id}_${DateTime.now().millisecondsSinceEpoch}',
          description: 'Created expense: ${expense.description}',
        );

  @override
  Future<void> execute() async {
    // This action is executed when undoing a delete
    // Implementation would call the expense creation use case
  }

  @override
  Future<void> undo() async {
    // Delete the expense that was created
    // Implementation would call the expense deletion use case
  }

  @override
  String get actionDescription => 'Created expense "${expense.description}" for \$${expense.amount / 100}';

  @override
  String get actionType => 'expense';

  @override
  Map<String, dynamic> toJson() => {
    'type': 'create_expense',
    'id': id,
    'description': description,
    'timestamp': timestamp.toIso8601String(),
    'expense': expense.toJson(),
  };

  static CreateExpenseAction fromJson(Map<String, dynamic> json) {
    return CreateExpenseAction(
      Expense.fromJson(json['expense'] as Map<String, dynamic>),
    );
  }
}

/// Action for updating an expense
class UpdateExpenseAction extends UndoableAction {
  final Expense oldExpense;
  final Expense newExpense;

  UpdateExpenseAction(this.oldExpense, this.newExpense)
      : super(
          id: 'update_expense_${oldExpense.id}_${DateTime.now().millisecondsSinceEpoch}',
          description: 'Updated expense: ${oldExpense.description}',
        );

  @override
  Future<void> execute() async {
    // Apply the update
    // Implementation would call the expense update use case
  }

  @override
  Future<void> undo() async {
    // Revert to the old expense
    // Implementation would call the expense update use case with oldExpense
  }

  @override
  String get actionDescription => 'Updated expense "${oldExpense.description}"';

  @override
  String get actionType => 'expense';

  @override
  Map<String, dynamic> toJson() => {
    'type': 'update_expense',
    'id': id,
    'description': description,
    'timestamp': timestamp.toIso8601String(),
    'oldExpense': oldExpense.toJson(),
    'newExpense': newExpense.toJson(),
  };

  static UpdateExpenseAction fromJson(Map<String, dynamic> json) {
    return UpdateExpenseAction(
      Expense.fromJson(json['oldExpense'] as Map<String, dynamic>),
      Expense.fromJson(json['newExpense'] as Map<String, dynamic>),
    );
  }
}

/// Action for deleting an expense
class DeleteExpenseAction extends UndoableAction {
  final Expense deletedExpense;

  DeleteExpenseAction(this.deletedExpense)
      : super(
          id: 'delete_expense_${deletedExpense.id}_${DateTime.now().millisecondsSinceEpoch}',
          description: 'Deleted expense: ${deletedExpense.description}',
        );

  @override
  Future<void> execute() async {
    // Delete the expense
    // Implementation would call the expense deletion use case
  }

  @override
  Future<void> undo() async {
    // Recreate the deleted expense
    // Implementation would call the expense creation use case
  }

  @override
  String get actionDescription => 'Deleted expense "${deletedExpense.description}"';

  @override
  String get actionType => 'expense';

  @override
  Map<String, dynamic> toJson() => {
    'type': 'delete_expense',
    'id': id,
    'description': description,
    'timestamp': timestamp.toIso8601String(),
    'deletedExpense': deletedExpense.toJson(),
  };

  static DeleteExpenseAction fromJson(Map<String, dynamic> json) {
    return DeleteExpenseAction(
      Expense.fromJson(json['deletedExpense'] as Map<String, dynamic>),
    );
  }
}

/// Action for creating a budget
class CreateBudgetAction extends UndoableAction {
  final Budget budget;

  CreateBudgetAction(this.budget)
      : super(
          id: 'create_budget_${budget.id}_${DateTime.now().millisecondsSinceEpoch}',
          description: 'Created budget: ${budget.name}',
        );

  @override
  Future<void> execute() async {
    // Implementation would call the budget creation use case
  }

  @override
  Future<void> undo() async {
    // Implementation would call the budget deletion use case
  }

  @override
  String get actionDescription => 'Created budget "${budget.name}"';

  @override
  String get actionType => 'budget';

  @override
  Map<String, dynamic> toJson() => {
    'type': 'create_budget',
    'id': id,
    'description': description,
    'timestamp': timestamp.toIso8601String(),
    'budget': budget.toJson(),
  };

  static CreateBudgetAction fromJson(Map<String, dynamic> json) {
    return CreateBudgetAction(
      Budget.fromJson(json['budget'] as Map<String, dynamic>),
    );
  }
}

/// Action for updating a budget
class UpdateBudgetAction extends UndoableAction {
  final Budget oldBudget;
  final Budget newBudget;

  UpdateBudgetAction(this.oldBudget, this.newBudget)
      : super(
          id: 'update_budget_${oldBudget.id}_${DateTime.now().millisecondsSinceEpoch}',
          description: 'Updated budget: ${oldBudget.name}',
        );

  @override
  Future<void> execute() async {
    // Implementation would call the budget update use case
  }

  @override
  Future<void> undo() async {
    // Implementation would call the budget update use case with oldBudget
  }

  @override
  String get actionDescription => 'Updated budget "${oldBudget.name}"';

  @override
  String get actionType => 'budget';

  @override
  Map<String, dynamic> toJson() => {
    'type': 'update_budget',
    'id': id,
    'description': description,
    'timestamp': timestamp.toIso8601String(),
    'oldBudget': oldBudget.toJson(),
    'newBudget': newBudget.toJson(),
  };

  static UpdateBudgetAction fromJson(Map<String, dynamic> json) {
    return UpdateBudgetAction(
      Budget.fromJson(json['oldBudget'] as Map<String, dynamic>),
      Budget.fromJson(json['newBudget'] as Map<String, dynamic>),
    );
  }
}

/// Action for deleting a budget
class DeleteBudgetAction extends UndoableAction {
  final Budget deletedBudget;

  DeleteBudgetAction(this.deletedBudget)
      : super(
          id: 'delete_budget_${deletedBudget.id}_${DateTime.now().millisecondsSinceEpoch}',
          description: 'Deleted budget: ${deletedBudget.name}',
        );

  @override
  Future<void> execute() async {
    // Implementation would call the budget deletion use case
  }

  @override
  Future<void> undo() async {
    // Implementation would call the budget creation use case
  }

  @override
  String get actionDescription => 'Deleted budget "${deletedBudget.name}"';

  @override
  String get actionType => 'budget';

  @override
  Map<String, dynamic> toJson() => {
    'type': 'delete_budget',
    'id': id,
    'description': description,
    'timestamp': timestamp.toIso8601String(),
    'deletedBudget': deletedBudget.toJson(),
  };

  static DeleteBudgetAction fromJson(Map<String, dynamic> json) {
    return DeleteBudgetAction(
      Budget.fromJson(json['deletedBudget'] as Map<String, dynamic>),
    );
  }
}

/// Undo/Redo state
class UndoRedoState {
  final bool canUndo;
  final bool canRedo;
  final UndoableAction? lastUndoneAction;
  final UndoableAction? nextRedoAction;

  const UndoRedoState({
    this.canUndo = false,
    this.canRedo = false,
    this.lastUndoneAction,
    this.nextRedoAction,
  });

  UndoRedoState copyWith({
    bool? canUndo,
    bool? canRedo,
    UndoableAction? lastUndoneAction,
    UndoableAction? nextRedoAction,
  }) {
    return UndoRedoState(
      canUndo: canUndo ?? this.canUndo,
      canRedo: canRedo ?? this.canRedo,
      lastUndoneAction: lastUndoneAction ?? this.lastUndoneAction,
      nextRedoAction: nextRedoAction ?? this.nextRedoAction,
    );
  }
}

/// Undo/Redo manager
class UndoRedoNotifier extends StateNotifier<UndoRedoState> {
  final List<UndoableAction> _undoStack = [];
  final List<UndoableAction> _redoStack = [];

  static const int _maxHistorySize = 50; // Limit history to prevent memory issues
  static const Duration _autoClearDelay = Duration(minutes: 30); // Auto-clear old actions

  UndoRedoNotifier() : super(const UndoRedoState()) {
    // Auto-clear old actions periodically
    Timer.periodic(_autoClearDelay, (_) => _clearOldActions());
  }

  /// Execute an action and add it to undo history
  Future<void> execute(UndoableAction action) async {
    await action.execute();
    _undoStack.add(action);
    _redoStack.clear(); // Clear redo stack when new action is executed

    // Limit history size
    if (_undoStack.length > _maxHistorySize) {
      _undoStack.removeAt(0);
    }

    state = state.copyWith(
      canUndo: true,
      canRedo: false,
      lastUndoneAction: null,
    );
  }

  /// Undo the last action
  Future<void> undo() async {
    if (_undoStack.isEmpty) return;

    final action = _undoStack.removeLast();
    await action.undo();
    _redoStack.add(action);

    state = state.copyWith(
      canUndo: _undoStack.isNotEmpty,
      canRedo: true,
      lastUndoneAction: action,
      nextRedoAction: action,
    );
  }

  /// Redo the last undone action
  Future<void> redo() async {
    if (_redoStack.isEmpty) return;

    final action = _redoStack.removeLast();
    await action.execute();
    _undoStack.add(action);

    state = state.copyWith(
      canUndo: true,
      canRedo: _redoStack.isNotEmpty,
      lastUndoneAction: null,
      nextRedoAction: _redoStack.isNotEmpty ? _redoStack.last : null,
    );
  }

  /// Clear all undo/redo history
  void clearHistory() {
    _undoStack.clear();
    _redoStack.clear();
    state = const UndoRedoState();
  }

  /// Get recent undo actions for UI display
  List<UndoableAction> getRecentActions({int limit = 5}) {
    return _undoStack.reversed.take(limit).toList();
  }

  /// Check if an action can be undone
  bool canUndoAction(UndoableAction action) {
    return action.canUndo;
  }

  /// Get actions by type
  List<UndoableAction> getActionsByType(String type) {
    return _undoStack.where((action) => action.actionType == type).toList();
  }

  /// Save undo/redo state to persistent storage
  Future<void> saveState() async {
    // Implementation would save to SharedPreferences or similar
    final actionsJson = _undoStack.map((action) => action.toJson()).toList();
    // Save to persistent storage
  }

  /// Load undo/redo state from persistent storage
  Future<void> loadState() async {
    // Implementation would load from SharedPreferences or similar
    // final savedActions = await loadFromStorage();
    // _undoStack.addAll(savedActions);
  }

  void _clearOldActions() {
    final cutoffTime = DateTime.now().subtract(_autoClearDelay);
    _undoStack.removeWhere((action) => action.timestamp.isBefore(cutoffTime));
    _redoStack.removeWhere((action) => action.timestamp.isBefore(cutoffTime));
  }
}

/// Undo/Redo provider
final undoRedoProvider = StateNotifierProvider<UndoRedoNotifier, UndoRedoState>((ref) {
  return UndoRedoNotifier();
});

/// Computed providers for easy access
final canUndoProvider = Provider<bool>((ref) {
  return ref.watch(undoRedoProvider).canUndo;
});

final canRedoProvider = Provider<bool>((ref) {
  return ref.watch(undoRedoProvider).canRedo;
});

final recentUndoActionsProvider = Provider<List<UndoableAction>>((ref) {
  return ref.watch(undoRedoProvider.notifier).getRecentActions();
});

/// Extension methods for easy undo/redo operations
extension UndoRedoExtensions on WidgetRef {
  /// Execute an action with undo support
  Future<void> executeWithUndo(UndoableAction action) async {
    await read(undoRedoProvider.notifier).execute(action);
  }

  /// Undo the last action
  Future<void> undo() async {
    await read(undoRedoProvider.notifier).undo();
  }

  /// Redo the last undone action
  Future<void> redo() async {
    await read(undoRedoProvider.notifier).redo();
  }
}

/// Undo/Redo snackbar helper
class UndoRedoSnackBar {
  static void showUndoSnackBar(
    BuildContext context,
    String message,
    VoidCallback onUndo,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: onUndo,
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  static void showUndoRedoSnackBar(
    BuildContext context,
    String message,
    VoidCallback onUndo,
    VoidCallback? onRedo,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: onUndo,
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}

