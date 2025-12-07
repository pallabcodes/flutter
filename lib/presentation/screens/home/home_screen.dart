import 'package:finwise/core/navigation/app_router.dart';
import 'package:finwise/presentation/providers/expense_providers.dart';
import 'package:finwise/presentation/providers/sample_data_provider.dart';
import 'package:finwise/presentation/theme/app_theme.dart';
import 'package:finwise/presentation/widgets/expense_card.dart';
import 'package:finwise/presentation/widgets/expense_summary_card.dart';
import 'package:finwise/presentation/screens/add_expense/add_expense_screen.dart';
import 'package:finwise/presentation/screens/budget/budget_list_screen.dart';
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
    final expensesAsync = ref.watch(filteredExpensesProvider);
    final summary = ref.watch(expensesSummaryProvider);

    // Seed sample data if needed
    ref.watch(sampleDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('FinWise'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet),
            onPressed: _navigateToBudgets,
            tooltip: 'Budgets',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
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

  void _showFilterDialog() {
    // TODO: Implement filter dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Filter dialog coming soon!')),
    );
  }

  void _showSearchDialog() {
    // TODO: Implement search dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Search dialog coming soon!')),
    );
  }

  void _addNewExpense() {
    AppRouter.push(AppRouter.addExpense);
  }

  void _navigateToBudgets() {
    AppRouter.push(AppRouter.budgets);
  }

  void _editExpense(expense) {
    // TODO: Navigate to edit expense screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit expense: ${expense.description}')),
    );
  }
}
