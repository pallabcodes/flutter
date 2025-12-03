import 'package:finwise/presentation/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Card widget displaying expense information
/// Implements Material Design 3 with proper accessibility
class ExpenseCard extends StatelessWidget {
  final dynamic expense;
  final VoidCallback? onTap;
  final bool showCategoryIcon;

  const ExpenseCard({
    super.key,
    required this.expense,
    this.onTap,
    this.showCategoryIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(symbol: '\$');

    return Card(
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMD),
          child: Row(
            children: [
              // Category Icon
              if (showCategoryIcon) ...[
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.getCategoryColor(expense.category?.name ?? 'other').withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  ),
                  child: Icon(
                    _getCategoryIcon(expense.category?.name ?? 'other'),
                    color: AppTheme.getCategoryColor(expense.category?.name ?? 'other'),
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingMD),
              ],

              // Expense Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Description
                    Text(
                      expense.description ?? 'No description',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: AppTheme.spacingXS),

                    // Date and Category
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: AppTheme.spacingXS),
                        Text(
                          _formatDate(expense.date),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        if (expense.category != null) ...[
                          const SizedBox(width: AppTheme.spacingMD),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spacingXS,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.getCategoryColor(expense.category.name).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                            ),
                            child: Text(
                              expense.category.name.toUpperCase(),
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppTheme.getCategoryColor(expense.category.name),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),

                    // Note (if available)
                    if (expense.note?.isNotEmpty == true) ...[
                      const SizedBox(height: AppTheme.spacingXS),
                      Text(
                        expense.note!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Amount
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    currencyFormatter.format((expense.amount ?? 0) / 100),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),

                  // Recurring indicator
                  if (expense.isRecurring == true) ...[
                    const SizedBox(height: AppTheme.spacingXS),
                    Row(
                      children: [
                        Icon(
                          Icons.repeat,
                          size: 14,
                          color: AppTheme.secondaryColor,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          'Recurring',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppTheme.secondaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'transportation':
        return Icons.directions_car;
      case 'shopping':
        return Icons.shopping_bag;
      case 'entertainment':
        return Icons.movie;
      case 'bills':
        return Icons.receipt;
      case 'healthcare':
        return Icons.local_hospital;
      case 'education':
        return Icons.school;
      case 'travel':
        return Icons.flight;
      case 'personal':
        return Icons.person;
      default:
        return Icons.category;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown date';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expenseDate = DateTime(date.year, date.month, date.day);

    if (expenseDate == today) {
      return 'Today';
    } else if (expenseDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else if (expenseDate.isAfter(today.subtract(const Duration(days: 7)))) {
      return DateFormat('EEEE').format(date); // Day name
    } else {
      return DateFormat('MMM d, y').format(date);
    }
  }
}
