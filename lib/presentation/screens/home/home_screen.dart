import 'package:finwise/presentation/providers/background_sync_provider.dart';
import 'package:finwise/presentation/providers/connectivity_provider.dart';
import 'package:finwise/presentation/providers/expense_providers.dart';
import 'package:finwise/presentation/providers/global_loading_provider.dart';
import 'package:finwise/presentation/providers/sample_data_provider.dart';
import 'package:finwise/presentation/theme/app_theme.dart';
import 'package:finwise/presentation/widgets/error_boundary.dart';
import 'package:finwise/presentation/widgets/expense_card.dart';
import 'package:finwise/presentation/widgets/expense_summary_card.dart';
import 'package:finwise/presentation/widgets/filter_dialog.dart';
import 'package:finwise/presentation/widgets/sync_status_indicator.dart';
import 'package:finwise/presentation/widgets/undo_redo_controls.dart';
import 'package:finwise/presentation/screens/add_expense/add_expense_screen.dart';
import 'package:finwise/presentation/screens/budget/budget_list_screen.dart';
import 'package:finwise/core/navigation/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Home screen displaying expense list and summary
/// Implements Material Design 3 with responsive layout
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with TickerProviderStateMixin {
  late final AnimationController _fabAnimationController;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(filteredExpensesProvider); // Watch expenses
    final summary = ref.watch(expensesSummaryProvider);
    final connectionStatus = ref.watch(connectionStatusProvider);
    final optimisticUpdates = ref.watch(optimisticUpdatesProvider);
    final isGlobalLoading = ref.watch(isAnyLoadingProvider);

    // Seed sample data if needed
    ref.watch(sampleDataProvider);

    return ScreenErrorBoundary(
      screenName: 'Home',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('FinWise'),
          actions: [
            // Sync status indicator
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: SyncStatusIndicator(),
            ),
            // Connectivity indicator
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: Tooltip(
                message: connectionStatus.displayName,
                child: Icon(
                  connectionStatus.icon,
                  color: connectionStatus.isOnline ? Colors.green : Colors.red,
                  size: 20,
                ),
              ),
            ),
            // Undo/Redo controls
            const UndoRedoAppBarAction(),
            IconButton(
              icon: const Icon(Icons.account_balance_wallet),
              onPressed: isGlobalLoading ? null : _navigateToBudgets,
              tooltip: 'Budgets',
            ),
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: isGlobalLoading ? null : _showFilterDialog,
            ),
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => AppRouter.push(AppRouter.search),
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: isGlobalLoading ? null : _navigateToSettings,
              tooltip: 'Settings',
            ),
          ],
        ),
      body: Column(
        children: [
          // Summary Card
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMD),
            child: ExpenseSummaryCard(summary: summary),
          ),

          // Expenses List
          Expanded(
            child: ScopedErrorBoundary(
              scopeName: 'Expenses List',
              child: expensesAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: AppTheme.errorColor,
                      ),
                      const SizedBox(height: AppTheme.spacingMD),
                      Text(
                        'Failed to load expenses',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: AppTheme.spacingSM),
                      Text(
                        error.toString(),
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppTheme.spacingLG),
                      ElevatedButton(
                        onPressed: () {
                          ref.invalidate(expensesProvider);
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              data: (expenses) => expenses.isEmpty
                  ? _buildEmptyState()
                  : _buildExpensesList(expenses),
            ),
          ),
        ],
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabAnimationController,
        child: FloatingActionButton(
          onPressed: _addNewExpense,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet,
            size: 80,
            color: AppTheme.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: AppTheme.spacingLG),
          Text(
            'No expenses yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingMD),
          Text(
            'Start tracking your expenses by adding your first one',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingXL),
          ElevatedButton.icon(
            onPressed: _addNewExpense,
            icon: const Icon(Icons.add),
            label: const Text('Add Expense'),
          ),
        ],
      ),
    );
  }

  Widget _buildExpensesList(List expenses) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(expensesProvider);
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMD),
        itemCount: expenses.length,
        itemBuilder: (context, index) {
          final expense = expenses[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spacingMD),
            child: ExpenseCard(
              expense: expense,
              onTap: () => _editExpense(expense),
            ),
          );
        },
      ),
    );
  }

  void _showFilterDialog() async {
    final currentFilters = ref.read(expenseFiltersProvider);
    final result = await showDialog<ExpenseFilters>(
      context: context,
      builder: (context) => FilterDialog(
        currentFilters: currentFilters,
        onApplyFilters: (filters) {
          ref.read(expenseFiltersProvider.notifier).state = filters;
        },
      ),
    );

    if (result != null) {
      ref.read(expenseFiltersProvider.notifier).state = result;
    }
  }

  void _showSearchDialog() {
    AppRouter.goToSearch();
  }

  void _addNewExpense() {
    AppRouter.push(AppRouter.addExpense);
  }

  void _navigateToBudgets() {
    AppRouter.push(AppRouter.budgets);
  }

  void _navigateToSettings() {
    AppRouter.goToSettings();
  }

  void _editExpense(expense) {
    AppRouter.goToEditExpense(expense);
  }
}
