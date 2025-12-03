import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finwise_core/animations/meaningful_interactions.dart';
import '../../../features/improvement/credit_recommendation_engine.dart';
import '../../providers/credit_providers.dart';

class RecommendationsScreen extends ConsumerStatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  ConsumerState<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends ConsumerState<RecommendationsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final creditState = ref.watch(creditDashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Recommendations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _refreshRecommendations(),
          ),
        ],
      ),
      body: creditState.isLoading
          ? const _LoadingView()
          : creditState.error != null
              ? _ErrorView(error: creditState.error!)
              : _RecommendationsContent(
                  primaryScore: creditState.primaryScore,
                  scrollController: _scrollController,
                ),
    );
  }

  Future<void> _refreshRecommendations() async {
    await ref.read(creditDashboardProvider.notifier).refreshScores();
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
          Text('Analyzing your credit data...'),
          SizedBox(height: 8),
          Text(
            'Generating personalized recommendations',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
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
              'Unable to generate recommendations',
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
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecommendationsContent extends ConsumerWidget {
  const _RecommendationsContent({
    required this.primaryScore,
    required this.scrollController,
  });

  final CreditScore? primaryScore;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (primaryScore == null) {
      return const _NoDataView();
    }

    // Generate recommendations based on current score data
    final recommendations = _generateMockRecommendations(primaryScore!);

    return CustomScrollView(
      controller: scrollController,
      slivers: [
        SliverToBoxAdapter(
          child: _buildHeader(context, primaryScore!, recommendations),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildRecommendationCard(
              context,
              recommendations[index],
              index,
            ),
            childCount: recommendations.length,
          ),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(height: 24),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, CreditScore score, List<CreditRecommendation> recommendations) {
    final highImpactCount = recommendations.where((r) => r.isHighImpact).length;
    final quickWinsCount = recommendations.where((r) => r.isQuickWin).length;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb,
                color: Colors.blue.shade700,
                size: 32,
              ),
              const SizedBox(width: 12),
              Text(
                'Personalized Plan',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Based on your ${score.bureau} score of ${score.score}, here are ${recommendations.length} AI-powered recommendations to improve your credit.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildStatChip(
                '${recommendations.length}',
                'Recommendations',
                Colors.blue,
              ),
              const SizedBox(width: 12),
              _buildStatChip(
                '$highImpactCount',
                'High Impact',
                Colors.green,
              ),
              const SizedBox(width: 12),
              _buildStatChip(
                '$quickWinsCount',
                'Quick Wins',
                Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 16),
          MeaningfulInteractions().createGoalProgress(
            goalName: 'Credit Score Improvement',
            progress: score.isExcellent ? 1.0 : (score.score - score.range.poorMin) / (score.range.excellentMin - score.range.poorMin),
            targetAmount: score.range.excellentMin.toDouble(),
            currentAmount: score.score.toDouble(),
            isCompleted: score.isExcellent,
            onCelebrate: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🎉 Congratulations on your excellent credit score!'),
                  duration: Duration(seconds: 3),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String value, String label, Color color) {
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
              fontSize: 18,
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

  Widget _buildRecommendationCard(BuildContext context, CreditRecommendation recommendation, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: InkWell(
        onTap: () => _showRecommendationDetails(context, recommendation),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildPriorityIndicator(recommendation),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recommendation.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          recommendation.category,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildImpactBadge(recommendation),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                recommendation.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildTimelineChip(recommendation.timeline),
                  const SizedBox(width: 8),
                  _buildConfidenceIndicator(recommendation.confidence),
                  const Spacer(),
                  TextButton(
                    onPressed: () => _showRecommendationDetails(context, recommendation),
                    child: const Text('View Steps'),
                  ),
                ],
              ),
              if (recommendation.relatedFactors.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: recommendation.relatedFactors
                      .map((factor) => Chip(
                            label: Text(
                              factor,
                              style: const TextStyle(fontSize: 11),
                            ),
                            backgroundColor: Colors.grey[100],
                            padding: EdgeInsets.zero,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityIndicator(CreditRecommendation recommendation) {
    Color color;
    IconData icon;

    if (recommendation.isHighPriority) {
      color = Colors.red;
      icon = Icons.priority_high;
    } else if (recommendation.priority > 40) {
      color = Colors.orange;
      icon = Icons.arrow_upward;
    } else {
      color = Colors.green;
      icon = Icons.low_priority;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildImpactBadge(CreditRecommendation recommendation) {
    final color = recommendation.isHighImpact ? Colors.green : Colors.blue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        '+${recommendation.impact.round()} pts',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildTimelineChip(String timeline) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.schedule, size: 14, color: Colors.grey),
          const SizedBox(width: 4),
          Text(
            timeline,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceIndicator(double confidence) {
    final percentage = (confidence * 100).round();
    return MeaningfulInteractions().createConfidenceIndicator(
      confidence: confidence,
      action: 'Implement this recommendation',
      reasoning: 'Based on your credit profile and historical data',
      onDetailsTap: () {
        // Show detailed reasoning
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('AI Confidence Explanation'),
            content: Text(
              'This recommendation has ${(confidence * 100).round()}% confidence based on:\n\n'
              '• Your current credit factors\n'
              '• Historical improvement patterns\n'
              '• Industry benchmarks\n'
              '• Statistical correlations',
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

  void _showRecommendationDetails(BuildContext context, CreditRecommendation recommendation) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        builder: (context, scrollController) => _RecommendationDetailsSheet(
          recommendation: recommendation,
          scrollController: scrollController,
        ),
      ),
    );
  }

  List<CreditRecommendation> _generateMockRecommendations(CreditScore score) {
    // Generate mock recommendations based on score data
    // In production, this would use the actual AI engine
    final engine = CreditRecommendationEngine();
    final mockReport = _createMockReport(score);

    // For now, return static recommendations
    // In production: return engine.generateRecommendations(report: mockReport, factors: score.factors);
    return [
      CreditRecommendation(
        id: 'utilization_001',
        title: 'Reduce Credit Utilization Below 30%',
        description: 'Your current utilization is 35%. Paying down balances can improve your score by up to 30 points.',
        impact: 25.0,
        priority: 85.0,
        timeline: '1-2 months',
        confidence: 0.9,
        category: 'Credit Usage',
        action: CreditAction(
          type: 'payment',
          title: 'Pay down credit card balances',
          description: 'Reduce balances on cards above 30% utilization',
          steps: [
            'Check current balances and limits',
            'Calculate payment amounts needed',
            'Set up automatic payments',
            'Monitor progress monthly'
          ],
          estimatedCost: '\$500-1000',
          timeEstimate: '1-2 months',
          difficulty: 'Medium',
          impact: 25.0,
        ),
        relatedFactors: ['Payment History'],
      ),
      CreditRecommendation(
        id: 'inquiries_002',
        title: 'Limit New Credit Applications',
        description: 'You have 3 inquiries in the last 6 months. Each hard inquiry can lower your score by 5-10 points.',
        impact: 15.0,
        priority: 70.0,
        timeline: '6-12 months',
        confidence: 0.85,
        category: 'Credit Applications',
        action: CreditAction(
          type: 'education',
          title: 'Understand inquiry impact',
          description: 'Learn when applications affect your score',
          steps: [
            'Wait 2-4 months between hard inquiries',
            'Use soft inquiries when possible',
            'Only apply for pre-approved offers',
            'Monitor score after applications'
          ],
          estimatedCost: '\$0',
          timeEstimate: 'Ongoing',
          difficulty: 'Easy',
          impact: 15.0,
        ),
        relatedFactors: ['Credit Mix'],
      ),
      CreditRecommendation(
        id: 'age_003',
        title: 'Maintain Account History',
        description: 'Keep your oldest accounts open to strengthen credit history. Accounts lose value when closed.',
        impact: 10.0,
        priority: 45.0,
        timeline: 'Ongoing',
        confidence: 0.8,
        category: 'Account History',
        action: CreditAction(
          type: 'maintenance',
          title: 'Preserve account ages',
          description: 'Keep existing accounts active',
          steps: [
            'Identify oldest accounts',
            'Keep small balances to show activity',
            'Avoid closing old accounts',
            'Monitor account ages annually'
          ],
          estimatedCost: '\$0',
          timeEstimate: 'Ongoing',
          difficulty: 'Easy',
          impact: 10.0,
        ),
        relatedFactors: [],
      ),
    ];
  }

  CreditReport _createMockReport(CreditScore score) {
    return CreditReport(
      id: 'mock_${score.bureau}',
      userId: 'user_123',
      bureau: CreditBureau.values.firstWhere(
        (b) => b.name == score.bureau,
        orElse: () => CreditBureau.transUnion,
      ),
      currentScore: score,
      historicalScores: [],
      accounts: [],
      inquiries: [],
      publicRecords: [],
      generatedAt: DateTime.now(),
      nextUpdate: DateTime.now().add(const Duration(days: 30)),
    );
  }
}

class _NoDataView extends StatelessWidget {
  const _NoDataView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.credit_score,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No Credit Data Available',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Connect your credit report to get personalized AI recommendations for improving your score.',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to bureau connection
              },
              icon: const Icon(Icons.link),
              label: const Text('Connect Credit Report'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecommendationDetailsSheet extends StatelessWidget {
  const _RecommendationDetailsSheet({
    required this.recommendation,
    required this.scrollController,
  });

  final CreditRecommendation recommendation;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildPriorityIndicator(recommendation),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recommendation.title,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      recommendation.category,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.trending_up, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Potential Score Impact',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '+${recommendation.impact.round()} points',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Action Plan',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              itemCount: recommendation.action.steps.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        recommendation.action.steps[index],
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildInfoChip(
                  Icons.schedule,
                  recommendation.action.timeEstimate,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoChip(
                  Icons.attach_money,
                  recommendation.action.estimatedCost,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Mark as started/completed
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Recommendation marked as in progress!'),
                  ),
                );
              },
              child: const Text('Start This Action'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityIndicator(CreditRecommendation recommendation) {
    Color color;
    String label;

    if (recommendation.isHighPriority) {
      color = Colors.red;
      label = 'High';
    } else if (recommendation.priority > 40) {
      color = Colors.orange;
      label = 'Medium';
    } else {
      color = Colors.green;
      label = 'Low';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
