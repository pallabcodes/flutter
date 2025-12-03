import 'package:finwise/presentation/providers/budget_providers.dart';
import 'package:finwise/presentation/providers/expense_providers.dart';
import 'package:finwise/presentation/theme/app_theme.dart';
import 'package:finwise/presentation/widgets/expense_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

/// Detailed budget view with analytics and expense breakdown
class BudgetDetailsScreen extends ConsumerStatefulWidget {
  final dynamic budget;

  const BudgetDetailsScreen({
    super.key,
    required this.budget,
  });

  @override
  ConsumerState<BudgetDetailsScreen> createState() => _BudgetDetailsScreenState();
}

class _BudgetDetailsScreenState extends ConsumerState<BudgetDetailsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final budget = widget.budget;
    final allExpenses = ref.watch(expensesProvider);
    final budgetExpenses = _getBudgetExpenses(allExpenses);

    final spentAmount = budgetExpenses.fold<double>(
      0,
      (sum, expense) => sum + (expense.amount ?? 0),
    );
    final remainingAmount = (budget.targetAmount ?? 0) - spentAmount;
    final progressPercentage = budget.targetAmount != null && budget.targetAmount! > 0
        ? (spentAmount / budget.targetAmount!) * 100
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(budget.name ?? 'Budget Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _editBudget(budget),
            tooltip: 'Edit Budget',
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _deleteBudget(budget),
            tooltip: 'Delete Budget',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Expenses', icon: Icon(Icons.list)),
            Tab(text: 'Analytics', icon: Icon(Icons.analytics)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(budget, spentAmount, remainingAmount, progressPercentage),
          _buildExpensesTab(budgetExpenses),
          _buildAnalyticsTab(budget, budgetExpenses),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(dynamic budget, double spentAmount, double remainingAmount, double progress) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Budget Summary Card
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingLG),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Target Amount',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            currencyFormat.format(budget.targetAmount ?? 0),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getProgressColor(progress).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _getProgressColor(progress)),
                        ),
                        child: Text(
                          '${progress.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: _getProgressColor(progress),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingMD),
                  LinearProgressIndicator(
                    value: progress / 100,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(_getProgressColor(progress)),
                  ),
                  const SizedBox(height: AppTheme.spacingMD),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Spent',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            currencyFormat.format(spentAmount),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Remaining',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            currencyFormat.format(remainingAmount),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppTheme.spacingLG),

          // Budget Info
          _buildInfoSection('Budget Information', [
            _buildInfoRow('Name', budget.name ?? 'Unnamed Budget'),
            _buildInfoRow('Period', _getPeriodText(budget.period)),
            _buildInfoRow('Categories', _getCategoriesText(budget.categories)),
            _buildInfoRow('Created', _formatDate(budget.createdAt)),
          ]),

          // Quick Actions
          const SizedBox(height: AppTheme.spacingLG),
          const Text(
            'Quick Actions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppTheme.spacingMD),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _addExpenseToBudget(budget),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Expense'),
                ),
              ),
              const SizedBox(width: AppTheme.spacingMD),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _viewAllExpenses(budget),
                  icon: const Icon(Icons.list),
                  label: const Text('View All'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpensesTab(List<dynamic> budgetExpenses) {
    if (budgetExpenses.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No expenses in this budget yet',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Add expenses to track your spending',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      itemCount: budgetExpenses.length,
      itemBuilder: (context, index) {
        final expense = budgetExpenses[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spacingMD),
          child: ExpenseCard(
            expense: expense,
            onTap: () => _showExpenseDetails(expense),
            onEdit: () => _editExpense(expense),
            onDelete: () => _deleteExpense(expense),
          ),
        );
      },
    );
  }

  Widget _buildAnalyticsTab(dynamic budget, List<dynamic> budgetExpenses) {
    final categorySpending = _calculateCategorySpending(budgetExpenses);
    final dailySpending = _calculateDailySpending(budgetExpenses);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Spending by Category Chart
          if (categorySpending.isNotEmpty) ...[
            const Text(
              'Spending by Category',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppTheme.spacingMD),
            SizedBox(
              height: 300,
              child: SfCircularChart(
                legend: Legend(isVisible: true, position: LegendPosition.bottom),
                series: <CircularSeries>[
                  PieSeries<MapEntry<String, double>, String>(
                    dataSource: categorySpending.entries.map((e) => e).toList(),
                    xValueMapper: (data, _) => data.key,
                    yValueMapper: (data, _) => data.value,
                    dataLabelMapper: (data, _) =>
                        '${data.key}: \$${data.value.toStringAsFixed(2)}',
                    dataLabelSettings: const DataLabelSettings(isVisible: true),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: AppTheme.spacingLG),

          // Daily Spending Trend
          if (dailySpending.isNotEmpty) ...[
            const Text(
              'Daily Spending Trend',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppTheme.spacingMD),
            SizedBox(
              height: 250,
              child: SfCartesianChart(
                primaryXAxis: CategoryAxis(),
                series: <ChartSeries>[
                  LineSeries<MapEntry<String, double>, String>(
                    dataSource: dailySpending.entries.map((e) => e).toList(),
                    xValueMapper: (data, _) => data.key,
                    yValueMapper: (data, _) => data.value,
                    markerSettings: const MarkerSettings(isVisible: true),
                  ),
                ],
              ),
            ),
          ],

          // Spending Insights
          const SizedBox(height: AppTheme.spacingLG),
          const Text(
            'Spending Insights',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppTheme.spacingMD),

          _buildInsightCard(
            'Average Daily Spending',
            '\$${_calculateAverageDailySpending(budgetExpenses).toStringAsFixed(2)}',
            Icons.trending_up,
            Colors.blue,
          ),

          _buildInsightCard(
            'Largest Expense',
            '\$${_getLargestExpense(budgetExpenses).toStringAsFixed(2)}',
            Icons.arrow_upward,
            Colors.orange,
          ),

          _buildInsightCard(
            'Most Used Category',
            _getMostUsedCategory(budgetExpenses),
            Icons.category,
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppTheme.spacingMD),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingSM),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(String title, String value, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMD),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        subtitle: Text(value),
      ),
    );
  }

  List<dynamic> _getBudgetExpenses(AsyncValue<List<dynamic>> allExpenses) {
    return allExpenses.maybeWhen(
      data: (expenses) {
        final budgetCategories = widget.budget.categories as List? ?? [];
        return expenses.where((expense) {
          if (budgetCategories.isEmpty) return true;
          return budgetCategories.contains(expense.category);
        }).toList();
      },
      orElse: () => [],
    );
  }

  Map<String, double> _calculateCategorySpending(List<dynamic> expenses) {
    final spending = <String, double>{};
    for (final expense in expenses) {
      final category = expense.category ?? 'Uncategorized';
      spending[category] = (spending[category] ?? 0) + (expense.amount ?? 0);
    }
    return spending;
  }

  Map<String, double> _calculateDailySpending(List<dynamic> expenses) {
    final dailySpending = <String, double>{};
    for (final expense in expenses) {
      if (expense.date != null) {
        final dayKey = DateFormat('MMM dd').format(expense.date!);
        dailySpending[dayKey] = (dailySpending[dayKey] ?? 0) + (expense.amount ?? 0);
      }
    }
    return dailySpending;
  }

  double _calculateAverageDailySpending(List<dynamic> expenses) {
    if (expenses.isEmpty) return 0;
    final totalSpending = expenses.fold<double>(0, (sum, expense) => sum + (expense.amount ?? 0));
    final uniqueDays = expenses
        .where((expense) => expense.date != null)
        .map((expense) => DateFormat('yyyy-MM-dd').format(expense.date!))
        .toSet()
        .length;
    return uniqueDays > 0 ? totalSpending / uniqueDays : 0;
  }

  double _getLargestExpense(List<dynamic> expenses) {
    if (expenses.isEmpty) return 0;
    return expenses
        .map((expense) => expense.amount ?? 0)
        .reduce((a, b) => a > b ? a : b);
  }

  String _getMostUsedCategory(List<dynamic> expenses) {
    final categoryCount = <String, int>{};
    for (final expense in expenses) {
      final category = expense.category ?? 'Uncategorized';
      categoryCount[category] = (categoryCount[category] ?? 0) + 1;
    }
    if (categoryCount.isEmpty) return 'None';
    final mostUsed = categoryCount.entries.reduce((a, b) => a.value > b.value ? a : b);
    return mostUsed.key;
  }

  Color _getProgressColor(double progress) {
    if (progress < 50) return Colors.green;
    if (progress < 80) return Colors.orange;
    return Colors.red;
  }

  String _getPeriodText(String? period) {
    switch (period) {
      case 'daily': return 'Daily';
      case 'weekly': return 'Weekly';
      case 'monthly': return 'Monthly';
      case 'yearly': return 'Yearly';
      default: return 'Monthly';
    }
  }

  String _getCategoriesText(List<dynamic>? categories) {
    if (categories == null || categories.isEmpty) return 'All Categories';
    return categories.join(', ');
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    return DateFormat('MMM dd, yyyy').format(date);
  }

  void _editBudget(dynamic budget) {
    // TODO: Navigate to edit budget screen (requires edit budget screen)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit budget: ${budget.name}')),
    );
  }

  void _deleteBudget(dynamic budget) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Budget'),
        content: Text('Are you sure you want to delete "${budget.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final deleteUseCase = ref.read(deleteBudgetUseCaseProvider);
        final result = await deleteUseCase(DeleteBudgetParams(budgetId: budget.id));

        result.fold(
          (failure) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to delete budget: ${failure.message}')),
              );
            }
          },
          (success) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Budget deleted successfully')),
              );
              Navigator.of(context).pop();
            }
          },
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete budget: $e')),
          );
        }
      }
    }
  }

  void _addExpenseToBudget(dynamic budget) {
    // TODO: Navigate to add expense screen with budget pre-selected
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add expense to budget coming soon!')),
    );
  }

  void _viewAllExpenses(dynamic budget) {
    _tabController.animateTo(1); // Switch to expenses tab
  }

  void _showExpenseDetails(dynamic expense) {
    // TODO: Show expense details dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Expense details: ${expense.description}')),
    );
  }

  void _editExpense(dynamic expense) {
    // TODO: Navigate to edit expense screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit expense: ${expense.description}')),
    );
  }

  void _deleteExpense(dynamic expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense'),
        content: Text('Are you sure you want to delete "${expense.description}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // TODO: Call delete expense use case
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense deleted from budget')),
      );
    }
  }
}
