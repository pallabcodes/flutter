import 'package:finwise/presentation/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Card widget displaying budget information with progress
class BudgetCard extends StatelessWidget {
  final dynamic budget;
  final VoidCallback? onTap;

  const BudgetCard({
    super.key,
    required this.budget,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(symbol: '\$');
    final percentage = budget.targetAmount > 0
        ? (budget.spentAmount / budget.targetAmount) * 100
        : 0.0;

    final isOverBudget = budget.spentAmount > budget.targetAmount;
    final statusColor = _getStatusColor(percentage, isOverBudget);

    return Card(
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with name and status
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          budget.name ?? 'Unnamed Budget',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _getBudgetTypeText(),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingSM,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                    ),
                    child: Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppTheme.spacingMD),

              // Progress Bar
              LinearProgressIndicator(
                value: (percentage / 100).clamp(0.0, 1.0),
                backgroundColor: AppTheme.textSecondary.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),

              const SizedBox(height: AppTheme.spacingSM),

              // Amount Details
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Spent',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        Text(
                          currencyFormatter.format((budget.spentAmount ?? 0) / 100),
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isOverBudget ? AppTheme.errorColor : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Budget',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        Text(
                          currencyFormatter.format((budget.targetAmount ?? 0) / 100),
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Remaining amount
              if (!isOverBudget) ...[
                const SizedBox(height: AppTheme.spacingSM),
                Row(
                  children: [
                    Icon(
                      Icons.trending_down,
                      size: 16,
                      color: AppTheme.successColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${currencyFormatter.format(((budget.targetAmount ?? 0) - (budget.spentAmount ?? 0)) / 100)} remaining',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.successColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: AppTheme.spacingSM),
                Row(
                  children: [
                    Icon(
                      Icons.warning,
                      size: 16,
                      color: AppTheme.errorColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${currencyFormatter.format(((budget.spentAmount ?? 0) - (budget.targetAmount ?? 0)) / 100)} over budget',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.errorColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],

              // Period and categories
              if (budget.period != null || (budget.categories != null && budget.categories.isNotEmpty)) ...[
                const SizedBox(height: AppTheme.spacingMD),
                Row(
                  children: [
                    if (budget.period != null) ...[
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        budget.period.displayName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                    if (budget.categories != null && budget.categories.isNotEmpty) ...[
                      if (budget.period != null) const SizedBox(width: AppTheme.spacingMD),
                      Icon(
                        Icons.category,
                        size: 16,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${budget.categories.length} categories',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],

              // Status indicator
              if (!budget.isActive) ...[
                const SizedBox(height: AppTheme.spacingSM),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingSM,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.textSecondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                  ),
                  child: Text(
                    'Inactive',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getBudgetTypeText() {
    if (budget.type == null) return 'Budget';

    switch (budget.type.toString().split('.').last) {
      case 'category':
        return 'Category Budget';
      case 'overall':
        return 'Overall Budget';
      default:
        return 'Budget';
    }
  }

  Color _getStatusColor(double percentage, bool isOverBudget) {
    if (isOverBudget) return AppTheme.errorColor;
    if (percentage >= 90) return AppTheme.errorColor;
    if (percentage >= 75) return Colors.orange;
    if (percentage >= 50) return Colors.yellow.shade700;
    return AppTheme.successColor;
  }
}
