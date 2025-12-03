import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/credit_providers.dart';

class CreditDashboardScreen extends ConsumerWidget {
  const CreditDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(creditDashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('CreditWise'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(creditDashboardProvider.notifier).refreshScores(),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: dashboardState.isLoading
          ? const _LoadingView()
          : dashboardState.error != null
              ? _ErrorView(error: dashboardState.error!)
              : _DashboardContent(state: dashboardState),
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
              leading: const Icon(Icons.account_balance),
              title: const Text('Connect Credit Report'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to bureau connection
              },
            ),
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('View Full Report'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/report');
              },
            ),
            ListTile(
              leading: const Icon(Icons.lightbulb),
              title: const Text('Get Recommendations'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/recommendations');
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
          Text('Loading your credit insights...'),
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
        padding: const EdgeInsets.all(16),
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
              'Unable to load credit data',
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
            ElevatedButton(
              onPressed: () {
                // Retry logic would go here
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardContent extends ConsumerWidget {
  const _DashboardContent({required this.state});

  final CreditDashboardState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () => ref.read(creditDashboardProvider.notifier).refreshScores(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCreditScoreCard(context),
            const SizedBox(height: 24),
            _buildScoreBreakdown(),
            const SizedBox(height: 24),
            _buildCreditFactors(),
            const SizedBox(height: 24),
            _buildBureauConnections(context, ref),
            const SizedBox(height: 24),
            _buildRecentActivity(),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditScoreCard(BuildContext context) {
    final primaryScore = state.primaryScore;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'Your Credit Score',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              primaryScore?.score.toString() ?? '--',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: primaryScore?.scoreColor ?? Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: Colors.grey[300],
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: primaryScore != null
                    ? (primaryScore.score - primaryScore.range.min) /
                        (primaryScore.range.max - primaryScore.range.min)
                    : 0.0,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: primaryScore?.scoreColor ?? Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  primaryScore?.range.min.toString() ?? '300',
                  style: const TextStyle(color: Colors.grey),
                ),
                Text(
                  primaryScore?.scoreLabel ?? 'Loading...',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: primaryScore?.scoreColor ?? Colors.grey,
                  ),
                ),
                Text(
                  primaryScore?.range.max.toString() ?? '850',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            if (primaryScore?.changeFromLastMonth != null) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    primaryScore!.changeFromLastMonth! > 0
                        ? Icons.trending_up
                        : Icons.trending_down,
                    color: primaryScore.changeFromLastMonth! > 0
                        ? Colors.green
                        : Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${primaryScore.changeFromLastMonth! > 0 ? '+' : ''}${primaryScore.changeFromLastMonth!.toStringAsFixed(0)} from last month',
                    style: TextStyle(
                      color: primaryScore.changeFromLastMonth! > 0
                          ? Colors.green
                          : Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScoreBreakdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Score Breakdown',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...state.scores.map((score) => Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: score.scoreColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        score.bureau,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '${score.score} • ${score.scoreLabel}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Text(
                  score.score.toString(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildCreditFactors() {
    final primaryScore = state.primaryScore;
    if (primaryScore == null || primaryScore.factors.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Key Factors',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/recommendations'),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...primaryScore.factors.take(3).map((factor) => Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  factor.isNegative ? Icons.warning : Icons.check_circle,
                  color: factor.isNegative ? Colors.orange : Colors.green,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        factor.name,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        factor.description,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${factor.impact > 0 ? '+' : ''}${factor.impact.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: factor.isNegative ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildBureauConnections(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Credit Bureaus',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...CreditBureau.values.map((bureau) {
          final isConnected = state.connectionStatus[bureau] ?? false;
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    isConnected ? Icons.link : Icons.link_off,
                    color: isConnected ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      bureau.name,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  if (isConnected)
                    TextButton(
                      onPressed: () => ref
                          .read(creditDashboardProvider.notifier)
                          .disconnectBureau(bureau),
                      child: const Text('Disconnect'),
                    )
                  else
                    ElevatedButton(
                      onPressed: () => ref
                          .read(creditDashboardProvider.notifier)
                          .connectBureau(bureau),
                      child: const Text('Connect'),
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.score, color: Colors.blue),
                title: const Text('Credit score updated'),
                subtitle: const Text('TransUnion • +5 points'),
                trailing: const Text('2h ago'),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.description, color: Colors.green),
                title: const Text('Report refreshed'),
                subtitle: const Text('Equifax • Full report'),
                trailing: const Text('1d ago'),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.lightbulb, color: Colors.orange),
                title: const Text('New recommendation'),
                subtitle: const Text('Reduce credit utilization'),
                trailing: const Text('2d ago'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
