import 'package:finwise/presentation/providers/budget_providers.dart';
import 'package:finwise/presentation/screens/budget/create_budget_screen.dart';
import 'package:finwise/presentation/theme/app_theme.dart';
import 'package:finwise/presentation/widgets/budget_card.dart';
import 'package:finwise/presentation/widgets/budget_summary_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Screen displaying list of user budgets with summary
class BudgetListScreen extends ConsumerWidget {
  const BudgetListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(budgetsProvider);
    final summary = ref.watch(budgetSummaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budgets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              AppRouter.push(AppRouter.createBudget);
            },
            tooltip: 'Create Budget',
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary Header
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMD),
            child: BudgetSummaryHeader(summary: summary),
          ),

          // Budgets List
          Expanded(
            child: budgetsAsync.when(
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
                      'Failed to load budgets',
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
                        ref.invalidate(budgetsProvider);
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (budgets) => budgets.isEmpty
                  ? _buildEmptyState(context)
                  : _buildBudgetsList(context, budgets, ref),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
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
            'No budgets yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingMD),
          Text(
            'Create your first budget to start tracking spending',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingXXL),
          ElevatedButton.icon(
            onPressed: () {
              AppRouter.push(AppRouter.createBudget);
            },
            icon: const Icon(Icons.add),
            label: const Text('Create Budget'),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetsList(BuildContext context, List budgets, WidgetRef ref) {
    // Separate active and inactive budgets
    final activeBudgets = budgets.where((b) => b.isActive).toList();
    final inactiveBudgets = budgets.where((b) => !b.isActive).toList();

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(budgetsProvider);
      },
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMD),
        children: [
          // Active Budgets Section
          if (activeBudgets.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMD),
              child: Text(
                'Active Budgets',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ...activeBudgets.map((budget) => Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacingMD),
              child: BudgetCard(
                budget: budget,
                onTap: () => _showBudgetDetails(context, budget),
              ),
            )),
          ],

          // Inactive Budgets Section
          if (inactiveBudgets.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMD),
              child: Text(
                'Inactive Budgets',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
            ...inactiveBudgets.map((budget) => Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacingMD),
              child: BudgetCard(
                budget: budget,
                onTap: () => _showBudgetDetails(context, budget),
              ),
            )),
          ],
        ],
      ),
    );
  }

  void _showBudgetDetails(BuildContext context, budget) {
    // TODO: Navigate to budget details screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Budget details for: ${budget.name}')),
    );
  }
}
