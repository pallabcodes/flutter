import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:finwise_core/animations/meaningful_interactions.dart';
import '../../../data/models/investment_models.dart';
import '../../providers/investment_providers.dart';

class PortfolioDashboardScreen extends ConsumerStatefulWidget {
  const PortfolioDashboardScreen({super.key});

  @override
  ConsumerState<PortfolioDashboardScreen> createState() => _PortfolioDashboardScreenState();
}

class _PortfolioDashboardScreenState extends ConsumerState<PortfolioDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final portfolioState = ref.watch(investmentPortfolioProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('InvestWise'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(investmentPortfolioProvider),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: portfolioState.isLoading
          ? const _LoadingView()
          : portfolioState.error != null
              ? _ErrorView(error: portfolioState.error!)
              : portfolioState.portfolio == null
                  ? const _EmptyPortfolioView()
                  : _PortfolioContent(portfolio: portfolioState.portfolio!),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showQuickActions(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showQuickActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('Discover Investments'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/discover');
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag),
              title: const Text('Set Investment Goal'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/goals');
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet),
              title: const Text('Buy Assets'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to buy screen
              },
            ),
            ListTile(
              leading: const Icon(Icons.savings),
              title: const Text('Micro-Invest'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to micro-invest screen
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading your portfolio...'),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to load portfolio',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Retry logic would be handled by parent
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPortfolioView extends StatelessWidget {
  const _EmptyPortfolioView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.account_balance_wallet,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 24),
            Text(
              'Start Your Investment Journey',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Build wealth through smart investing. Start with as little as $1 and grow your portfolio over time.',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to first investment flow
              },
              icon: const Icon(Icons.rocket_launch),
              label: const Text('Start Investing'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                // Navigate to education
              },
              icon: const Icon(Icons.school),
              label: const Text('Learn First'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PortfolioContent extends ConsumerWidget {
  const _PortfolioContent({required this.portfolio});

  final InvestmentPortfolio portfolio;

  @override
  Widget build(BuildContext context, ref) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(investmentPortfolioProvider);
        await Future.delayed(const Duration(seconds: 1));
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPortfolioHeader(context, portfolio),
            const SizedBox(height: 24),
            _buildPerformanceChart(context, portfolio),
            const SizedBox(height: 24),
            _buildHoldingsList(context, portfolio.holdings),
            const SizedBox(height: 24),
            _buildGoalsOverview(context, ref),
            const SizedBox(height: 24),
            _buildRecentActivity(context),
          ],
        ),
      ),
    );
  }

  Widget _buildPortfolioHeader(BuildContext context, InvestmentPortfolio portfolio) {
    // Determine top contributors for portfolio balance animation
    final topContributors = portfolio.holdings
        .where((h) => h.value > 0)
        .map((h) => AssetContribution(
          assetName: h.asset.symbol,
          contribution: h.value,
          percentage: (h.value / portfolio.totalValue) * 100,
          color: h.asset.assetColor,
        ))
        .toList()
        ..sort((a, b) => b.contribution.compareTo(a.contribution));

    return MeaningfulInteractions().createPortfolioBalance(
      balance: portfolio.totalValue,
      change: portfolio.totalGainLoss,
      timeframe: const Duration(days: 30), // Last 30 days
      topContributors: topContributors.take(3).toList(),
    );
  }

  Widget _buildMetricChip(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceChart(BuildContext context, InvestmentPortfolio portfolio) {
    // Generate sample performance data points
    final performanceData = _generateSamplePerformanceData();
    final dataPoints = performanceData.map((spot) {
      final date = DateTime.now().subtract(Duration(days: (60 - spot.x.toInt())));
      return DataPoint(
        date: date,
        value: spot.y,
        label: date.day == 1 ? '${date.month}/${date.day}' : null,
      );
    }).toList();

    // Determine chart type based on performance
    final isPositive = portfolio.totalGainLoss >= 0;
    final chartType = isPositive ? ChartType.growth : ChartType.decline;

    // Generate insight based on performance
    final insight = _generatePerformanceInsight(portfolio);

    return MeaningfulInteractions().createDataStory(
      title: 'Portfolio Performance Story',
      dataPoints: dataPoints,
      chartType: chartType,
      insight: insight,
      onInsightTap: () {
        // Show detailed performance analysis
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Performance Insights'),
            content: Text(
              'Your portfolio has ${isPositive ? 'grown' : 'declined'} by '
              '${portfolio.totalGainLossPercent.toStringAsFixed(1)}% over the past 60 days.\n\n'
              '${_getPerformanceAdvice(portfolio)}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Got it'),
              ),
            ],
          ),
        );
      },
    );
  }

  String _generatePerformanceInsight(InvestmentPortfolio portfolio) {
    final isPositive = portfolio.totalGainLoss >= 0;
    final percentChange = portfolio.totalGainLossPercent.abs();

    if (isPositive) {
      if (percentChange > 15) {
        return '🚀 Outstanding! Your portfolio surged ${percentChange.toStringAsFixed(1)}% - you\'re beating the market!';
      } else if (percentChange > 5) {
        return '📈 Great job! Steady growth of ${percentChange.toStringAsFixed(1)}% shows smart investing.';
      } else {
        return '✅ Solid performance with ${percentChange.toStringAsFixed(1)}% growth - consistent wins add up!';
      }
    } else {
      if (percentChange > 15) {
        return '📉 Market volatility affected your portfolio. Consider long-term strategies.';
      } else {
        return '🔄 Temporary dip of ${percentChange.toStringAsFixed(1)}%. Markets fluctuate - stay the course!';
      }
    }
  }

  String _getPerformanceAdvice(InvestmentPortfolio portfolio) {
    if (portfolio.diversificationScore < 0.5) {
      return 'Consider diversifying your portfolio to reduce risk.';
    } else if (portfolio.riskScore > 0.7) {
      return 'Your portfolio has higher risk. Balance with more stable investments.';
    } else {
      return 'Your portfolio is well-balanced. Keep monitoring and adjusting as needed.';
    }
  }

  Widget _buildHoldingsList(BuildContext context, List<PortfolioHolding> holdings) {
    if (holdings.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Holdings',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'No holdings yet. Start investing to see your portfolio here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Your Holdings',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                // Navigate to detailed holdings view
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...holdings.take(3).map((holding) {
          // Determine risk level based on asset type and performance
          final riskLevel = _determineRiskLevel(holding);

          return Column(
            children: [
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: holding.asset.assetColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            holding.asset.symbol.substring(0, 1),
                            style: TextStyle(
                              color: holding.asset.assetColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              holding.asset.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '${holding.shares.toStringAsFixed(2)} shares • \$${holding.averageCost.toStringAsFixed(2)} avg',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '\$${holding.value.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '${holding.gainLossPercent >= 0 ? '+' : ''}${holding.gainLossPercent.toStringAsFixed(2)}%',
                            style: TextStyle(
                              color: holding.isProfitable ? Colors.green : Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Add risk indicator below each holding
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: MeaningfulInteractions().createRiskIndicator(
                  level: riskLevel,
                  assetName: holding.asset.name,
                  volatility: holding.gainLossPercent.abs() / 10, // Mock volatility
                  onTap: () {
                    // Show detailed risk analysis
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('${holding.asset.name} Risk Analysis'),
                        content: Text(
                          'Risk Level: ${_getRiskLevelName(riskLevel)}\n\n'
                          'This asset has ${_getRiskDescription(riskLevel)}.\n'
                          'Consider your risk tolerance before making changes.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Got it'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildGoalsOverview(BuildContext context, WidgetRef ref) {
    final goalsState = ref.watch(investmentGoalsProvider);

    if (goalsState.goals.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Investment Goals',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    const Icon(
                      Icons.flag_outlined,
                      size: 48,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Set investment goals to stay motivated',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/goals'),
                      icon: const Icon(Icons.add),
                      label: const Text('Create Goal'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    final activeGoals = goalsState.activeGoals.take(2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Investment Goals',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/goals'),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...activeGoals.map((goal) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: MeaningfulInteractions().createGoalProgress(
            goalName: goal.name,
            progress: goal.progressPercent,
            targetAmount: goal.targetAmount,
            currentAmount: goal.currentAmount,
            isCompleted: goal.progressPercent >= 1.0,
            onCelebrate: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('🎉 Congratulations on your ${goal.name} goal progress!'),
                  duration: const Duration(seconds: 3),
                ),
              );
            },
          ),
        )),
      ],
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildSwipeableActivity(
          'Bought AAPL',
          '50 shares • \$150.00',
          Icons.trending_up,
          Colors.green,
          '2h ago',
          [
            SwipeAction(
              SwipeActionType.analyze,
              'View Trade',
              Icons.visibility,
              Colors.green,
              'See detailed transaction information',
            ),
            SwipeAction(
              SwipeActionType.save,
              'Save Receipt',
              Icons.bookmark,
              Colors.blue,
              'Save this transaction for records',
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildSwipeableActivity(
          'Micro-investment',
          'Spare change • \$2.50',
          Icons.savings,
          Colors.blue,
          '1d ago',
          [
            SwipeAction(
              SwipeActionType.analyze,
              'View Details',
              Icons.visibility,
              Colors.blue,
              'See how your spare change investments add up',
            ),
            SwipeAction(
              SwipeActionType.pay,
              'Invest More',
              Icons.add,
              Colors.green,
              'Add more to your micro-investment pool',
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildSwipeableActivity(
          'Goal progress',
          'Emergency Fund +\$25.00',
          Icons.flag,
          Colors.orange,
          '2d ago',
          [
            SwipeAction(
              SwipeActionType.analyze,
              'View Goal',
              Icons.flag,
              Colors.orange,
              'See your complete goal progress',
            ),
            SwipeAction(
              SwipeActionType.pay,
              'Add More',
              Icons.add,
              Colors.green,
              'Contribute more to reach your goal faster',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSwipeableActivity(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    String timeAgo,
    List<SwipeAction> actions,
  ) {
    final activityCard = Card(
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Text(timeAgo, style: TextStyle(color: Colors.grey[500])),
      ),
    );

    return MeaningfulInteractions().createSwipeAction(
      child: activityCard,
      actions: actions,
      primaryAction: actions.first.type,
      onActionTriggered: () => _handleActivitySwipeAction(actions.first),
    );
  }

  void _handleActivitySwipeAction(SwipeAction action) {
    // Handle different swipe actions for activities
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${action.label} action triggered')),
    );
  }

  List<FlSpot> _generateSamplePerformanceData() {
    // Generate sample portfolio performance data
    final spots = <FlSpot>[];
    double value = 10000;

    for (int i = 0; i < 60; i++) {
      // Simulate some growth with volatility
      final change = (value * 0.002) * (0.5 - (DateTime.now().millisecondsSinceEpoch % 1000) / 1000.0);
      value += change;
      spots.add(FlSpot(i.toDouble(), value));
    }

    return spots;
  }

  IconData _getGoalIcon(String category) {
    switch (category) {
      case 'emergency': return Icons.security;
      case 'vacation': return Icons.beach_access;
      case 'house': return Icons.home;
      case 'retirement': return Icons.account_balance;
      case 'education': return Icons.school;
      default: return Icons.flag;
    }
  }

  RiskLevel _determineRiskLevel(PortfolioHolding holding) {
    // Simple risk determination based on asset type and volatility
    final symbol = holding.asset.symbol.toLowerCase();
    final volatility = holding.gainLossPercent.abs();

    if (symbol.contains('bond') || symbol.contains('mmm') || symbol.contains('jnj')) {
      return RiskLevel.low;
    } else if (symbol.contains('tsla') || symbol.contains('coin') || volatility > 20) {
      return RiskLevel.veryHigh;
    } else if (symbol.contains('amzn') || symbol.contains('googl') || volatility > 10) {
      return RiskLevel.high;
    } else {
      return RiskLevel.moderate;
    }
  }

  String _getRiskLevelName(RiskLevel level) {
    switch (level) {
      case RiskLevel.veryLow: return 'Very Low Risk';
      case RiskLevel.low: return 'Low Risk';
      case RiskLevel.moderate: return 'Moderate Risk';
      case RiskLevel.high: return 'High Risk';
      case RiskLevel.veryHigh: return 'Very High Risk';
    }
  }

  String _getRiskDescription(RiskLevel level) {
    switch (level) {
      case RiskLevel.veryLow: return 'very low volatility and stable returns';
      case RiskLevel.low: return 'low volatility with steady growth potential';
      case RiskLevel.moderate: return 'moderate volatility balancing risk and reward';
      case RiskLevel.high: return 'high volatility with potential for significant gains or losses';
      case RiskLevel.veryHigh: return 'very high volatility requiring careful monitoring';
    }
  }
}
