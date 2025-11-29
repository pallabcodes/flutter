import 'package:finwise/presentation/providers/budget_providers.dart';
import 'package:finwise/presentation/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Header widget displaying budget summary statistics
class BudgetSummaryHeader extends StatelessWidget {
  final BudgetSummary summary;

  const BudgetSummaryHeader({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(
                  Icons.analytics,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: AppTheme.spacingSM),
                Text(
                  'Budget Overview',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppTheme.spacingLG),

            // Summary Stats Grid
            Row(
              children: [
                // Total Budgeted
                Expanded(
                  child: _buildStatItem(
                    context,
                    label: 'Total Budgeted',
                    value: summary.formattedTotalBudgeted,
                    icon: Icons.account_balance_wallet,
                    color: AppTheme.primaryColor,
                  ),
                ),

                const SizedBox(width: AppTheme.spacingMD),

                // Total Spent
                Expanded(
                  child: _buildStatItem(
                    context,
                    label: 'Total Spent',
                    value: summary.formattedTotalSpent,
                    icon: Icons.payments,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppTheme.spacingMD),

            // Budget Count and Status
            Row(
              children: [
                // Active Budgets
                Expanded(
                  child: _buildStatItem(
                    context,
                    label: 'Active Budgets',
                    value: summary.activeBudgets.toString(),
                    icon: Icons.check_circle,
                    color: AppTheme.successColor,
                  ),
                ),

                const SizedBox(width: AppTheme.spacingMD),

                // Utilization
                Expanded(
                  child: _buildStatItem(
                    context,
                    label: 'Utilization',
                    value: '${summary.utilizationPercentage.toStringAsFixed(1)}%',
                    icon: Icons.trending_up,
                    color: _getUtilizationColor(),
                  ),
                ),
              ],
            ),

            // Status Breakdown
            if (summary.totalBudgets > 0) ...[
              const SizedBox(height: AppTheme.spacingLG),
              Text(
                'Budget Status',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppTheme.spacingSM),
              _buildStatusBreakdown(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: AppTheme.spacingXS),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBreakdown(BuildContext context) {
    final totalActive = summary.onTrack + summary.warning + summary.overBudget;

    if (totalActive == 0) {
      return Text(
        'No active budgets to analyze',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppTheme.textSecondary,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Column(
      children: [
        // Progress bars for each status
        _buildStatusRow(
          context,
          label: 'On Track',
          count: summary.onTrack,
          total: totalActive,
          color: AppTheme.successColor,
        ),
        const SizedBox(height: AppTheme.spacingSM),
        _buildStatusRow(
          context,
          label: 'Warning',
          count: summary.warning,
          total: totalActive,
          color: Colors.orange,
        ),
        const SizedBox(height: AppTheme.spacingSM),
        _buildStatusRow(
          context,
          label: 'Over Budget',
          count: summary.overBudget,
          total: totalActive,
          color: AppTheme.errorColor,
        ),
      ],
    );
  }

  Widget _buildStatusRow(
    BuildContext context, {
    required String label,
    required int count,
    required int total,
    required Color color,
  }) {
    final percentage = total > 0 ? (count / total) * 100 : 0.0;

    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: AppTheme.spacingSM),
        Expanded(
          child: LinearProgressIndicator(
            value: total > 0 ? (count / total) : 0,
            backgroundColor: color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(width: AppTheme.spacingSM),
        SizedBox(
          width: 50,
          child: Text(
            '${percentage.toStringAsFixed(0)}%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Color _getUtilizationColor() {
    final percentage = summary.utilizationPercentage;
    if (percentage >= 90) return AppTheme.errorColor;
    if (percentage >= 75) return Colors.orange;
    if (percentage >= 50) return Colors.yellow.shade700;
    return AppTheme.successColor;
  }
}
