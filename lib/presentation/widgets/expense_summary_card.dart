import 'package:finwise/presentation/providers/expense_providers.dart';
import 'package:finwise/presentation/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

/// Card displaying expense summary with charts
/// Shows total spending, average, and category breakdown
class ExpenseSummaryCard extends StatelessWidget {
  final ExpenseSummary summary;

  const ExpenseSummaryCard({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMD),
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
                  'This Month',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppTheme.spacingMD),

            // Summary Stats
            Row(
              children: [
                // Total Amount
                Expanded(
                  child: _buildStatItem(
                    context,
                    label: 'Total',
                    value: summary.formattedTotalAmount,
                    icon: Icons.account_balance_wallet,
                  ),
                ),

                const SizedBox(width: AppTheme.spacingMD),

                // Average Amount
                Expanded(
                  child: _buildStatItem(
                    context,
                    label: 'Average',
                    value: summary.formattedAverageAmount,
                    icon: Icons.trending_up,
                  ),
                ),

                const SizedBox(width: AppTheme.spacingMD),

                // Transaction Count
                Expanded(
                  child: _buildStatItem(
                    context,
                    label: 'Transactions',
                    value: summary.totalCount.toString(),
                    icon: Icons.receipt,
                  ),
                ),
              ],
            ),

            // Category Chart
            if (summary.categoryBreakdown.isNotEmpty) ...[
              const SizedBox(height: AppTheme.spacingLG),
              Text(
                'Spending by Category',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppTheme.spacingMD),
              SizedBox(
                height: 120,
                child: SfCircularChart(
                  margin: EdgeInsets.zero,
                  series: <CircularSeries>[
                    DoughnutSeries<CategoryChartData, String>(
                      dataSource: _getCategoryChartData(),
                      xValueMapper: (data, _) => data.category,
                      yValueMapper: (data, _) => data.amount,
                      pointColorMapper: (data, _) => data.color,
                      innerRadius: '60%',
                      dataLabelSettings: const DataLabelSettings(
                        isVisible: false,
                      ),
                      enableTooltip: true,
                    ),
                  ],
                  tooltipBehavior: TooltipBehavior(
                    enable: true,
                    format: 'point.x: \$point.y',
                  ),
                ),
              ),

              // Category Legend
              const SizedBox(height: AppTheme.spacingMD),
              Wrap(
                spacing: AppTheme.spacingSM,
                runSpacing: AppTheme.spacingXS,
                children: summary.categoryBreakdown.entries.map((entry) {
                  final percentage = summary.totalAmount > 0
                      ? (entry.value / summary.totalAmount) * 100
                      : 0.0;

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingSM,
                      vertical: AppTheme.spacingXS,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.getCategoryColor(entry.key.name).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppTheme.getCategoryColor(entry.key.name),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingXS),
                        Text(
                          '${entry.key.name} (${percentage.toStringAsFixed(1)}%)',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppTheme.getCategoryColor(entry.key.name),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
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
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(
          color: AppTheme.textSecondary.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 24,
          ),
          const SizedBox(height: AppTheme.spacingXS),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  List<CategoryChartData> _getCategoryChartData() {
    return summary.categoryBreakdown.entries.map((entry) {
      return CategoryChartData(
        category: entry.key.name,
        amount: entry.value / 100, // Convert cents to dollars
        color: AppTheme.getCategoryColor(entry.key.name),
      );
    }).toList();
  }
}

/// Data class for category chart
class CategoryChartData {
  final String category;
  final double amount;
  final Color color;

  CategoryChartData({
    required this.category,
    required this.amount,
    required this.color,
  });
}
