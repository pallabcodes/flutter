import '../../data/models/credit_score.dart';

/// AI-powered credit improvement recommendation engine
class CreditRecommendationEngine {
  /// Factor weights based on FICO scoring model
  static const Map<String, double> factorWeights = {
    'paymentHistory': 0.35,
    'creditUtilization': 0.30,
    'accountAge': 0.15,
    'creditInquiries': 0.10,
    'accountTypes': 0.10,
  };

  /// Generate personalized credit improvement recommendations
  Future<List<CreditRecommendation>> generateRecommendations({
    required CreditReport report,
    required List<CreditFactor> factors,
  }) async {
    final recommendations = <CreditRecommendation>[];

    // Analyze each credit factor
    for (final factor in factors) {
      final impact = await _calculateImpact(factor, report);
      final priority = _calculatePriority(factor, impact, report);
      final timeline = _estimateTimeline(factor, report);
      final confidence = _calculateConfidence(factor, report);

      if (impact > 5 && confidence > 0.6) { // Only show impactful, confident recommendations
        recommendations.add(CreditRecommendation(
          id: _generateRecommendationId(factor),
          title: _generateTitle(factor, report),
          description: _generateDescription(factor, report),
          impact: impact,
          priority: priority,
          timeline: timeline,
          confidence: confidence,
          category: _getCategory(factor),
          action: _generateAction(factor, report),
          relatedFactors: _findRelatedFactors(factor, factors),
        ));
      }
    }

    // Sort by priority and impact
    recommendations.sort((a, b) {
      final priorityCompare = b.priority.compareTo(a.priority);
      if (priorityCompare != 0) return priorityCompare;
      return b.impact.compareTo(a.impact);
    });

    return recommendations.take(5).toList(); // Top 5 recommendations
  }

  /// Calculate potential score impact of a recommendation
  Future<double> _calculateImpact(CreditFactor factor, CreditReport report) async {
    final baseImpact = factorWeights[factor.type] ?? 0.1;
    final severity = factor.isNegative ? 1.5 : 0.8;
    final accountsImpact = _calculateAccountsImpact(factor, report.accounts);

    return (baseImpact * severity * accountsImpact).clamp(0, 100);
  }

  /// Calculate priority score (0-100) based on multiple factors
  double _calculatePriority(CreditFactor factor, double impact, CreditReport report) {
    final urgency = _calculateUrgency(factor, report);
    final ease = _calculateEase(factor, report);
    final userHistory = _calculateUserHistoryFactor(factor, report);

    // Priority = (Impact × Urgency × User History) ÷ Ease
    return ((impact * urgency * userHistory) / ease).clamp(0, 100);
  }

  /// Estimate timeline for seeing results
  String _estimateTimeline(CreditFactor factor, CreditReport report) {
    final severity = factor.isNegative ? 2.0 : 1.0;
    final accounts = report.accounts.length;
    final baseMonths = _getBaseTimelineMonths(factor.type);

    final adjustedMonths = (baseMonths * severity / (accounts > 0 ? accounts : 1)).round();
    return _formatTimeline(adjustedMonths);
  }

  /// Calculate confidence in recommendation (0-1)
  double _calculateConfidence(CreditFactor factor, CreditReport report) {
    // Confidence based on data completeness and factor clarity
    final dataCompleteness = _calculateDataCompleteness(report);
    final factorClarity = _calculateFactorClarity(factor);

    return (dataCompleteness * factorClarity).clamp(0.0, 1.0);
  }

  /// Generate recommendation title
  String _generateTitle(CreditFactor factor, CreditReport report) {
    switch (factor.type) {
      case 'creditUtilization':
        final utilization = _calculateAverageUtilization(report.accounts);
        if (utilization > 50) return 'Urgently Reduce Credit Utilization';
        if (utilization > 30) return 'Lower Credit Utilization';
        return 'Optimize Credit Utilization';

      case 'paymentHistory':
        final latePayments = _countLatePayments(report.accounts);
        if (latePayments > 0) return 'Clear Payment Issues';
        return 'Maintain Perfect Payment History';

      case 'creditInquiries':
        final recentInquiries = _countRecentInquiries(report.inquiries);
        if (recentInquiries > 2) return 'Stop Unnecessary Credit Inquiries';
        return 'Limit Credit Applications';

      case 'accountAge':
        return 'Strengthen Account History';

      case 'accountTypes':
        return 'Diversify Credit Mix';

      default:
        return 'Improve ${factor.name}';
    }
  }

  /// Generate detailed description
  String _generateDescription(CreditFactor factor, CreditReport report) {
    switch (factor.type) {
      case 'creditUtilization':
        final utilization = _calculateAverageUtilization(report.accounts);
        return 'Your credit utilization is ${utilization.toStringAsFixed(1)}%. Keeping it below 30% can improve your score by up to 30 points. Current impact: -${factor.impact.toStringAsFixed(0)} points.';

      case 'paymentHistory':
        final latePayments = _countLatePayments(report.accounts);
        if (latePayments > 0) {
          return 'You have $latePayments late payments in the last 24 months. Paying on time can improve your score by up to 100 points over time.';
        }
        return 'Your payment history is excellent. Maintaining perfect payments will continue to support your credit score.';

      case 'creditInquiries':
        final recentInquiries = _countRecentInquiries(report.inquiries);
        return 'You have $recentInquiries credit inquiries in the last 12 months. Each hard inquiry can lower your score by 5-10 points. Limit applications to preserve your score.';

      case 'accountAge':
        final averageAge = _calculateAverageAccountAge(report.accounts);
        return 'Your accounts average ${averageAge.toStringAsFixed(1)} years old. Credit scores favor longer account histories. Keep existing accounts open.';

      case 'accountTypes':
        final accountTypes = _getUniqueAccountTypes(report.accounts);
        return 'You have ${accountTypes.length} types of credit accounts. A diverse mix (revolving, installment, mortgage) can improve your score.';

      default:
        return factor.description;
    }
  }

  /// Generate actionable steps
  CreditAction _generateAction(CreditFactor factor, CreditReport report) {
    switch (factor.type) {
      case 'creditUtilization':
        final highUtilizationAccounts = report.accounts
            .where((account) => account.utilization > 30)
            .toList();

        return CreditAction(
          type: 'payment',
          title: 'Pay down high utilization cards',
          description: 'Reduce balances on ${highUtilizationAccounts.length} cards above 30% utilization',
          steps: [
            'Identify cards with utilization > 30%',
            'Calculate payment amounts needed to reach < 30%',
            'Set up automatic payments or payment reminders',
            'Monitor progress monthly until goal reached',
            'Repeat process quarterly to maintain healthy utilization'
          ],
          estimatedCost: _calculatePaydownCost(highUtilizationAccounts),
          timeEstimate: '1-3 months',
          difficulty: 'Medium',
          impact: factor.impact,
        );

      case 'paymentHistory':
        return CreditAction(
          type: 'monitoring',
          title: 'Set up payment tracking and reminders',
          description: 'Ensure all payments are made on time',
          steps: [
            'Review all credit card and loan statements',
            'Note due dates and minimum payments',
            'Set calendar reminders 3 days before due dates',
            'Enable auto-pay where possible',
            'Set up account alerts from card issuers',
            'Track payment history monthly'
          ],
          estimatedCost: '\$0',
          timeEstimate: '1 week setup, ongoing',
          difficulty: 'Easy',
          impact: factor.impact,
        );

      case 'creditInquiries':
        return CreditAction(
          type: 'education',
          title: 'Understand credit application impact',
          description: 'Learn when and how to apply for credit wisely',
          steps: [
            'Research your current credit needs',
            'Compare offers without hard inquiries (soft pulls)',
            'Apply for only pre-approved offers',
            'Space out applications by 2-3 months',
            'Monitor your credit score after applications',
            'Wait 2-4 months between hard inquiries'
          ],
          estimatedCost: '\$0',
          timeEstimate: 'Ongoing education',
          difficulty: 'Easy',
          impact: factor.impact,
        );

      case 'accountAge':
        return CreditAction(
          type: 'maintenance',
          title: 'Preserve and strengthen account history',
          description: 'Keep existing accounts active and in good standing',
          steps: [
            'Identify your oldest credit accounts',
            'Keep these accounts open with small balances',
            'Use accounts occasionally to show activity',
            'Avoid closing old accounts',
            'Consider adding authorized users to build history',
            'Monitor account ages annually'
          ],
          estimatedCost: '\$0',
          timeEstimate: 'Ongoing',
          difficulty: 'Easy',
          impact: factor.impact,
        );

      case 'accountTypes':
        final currentTypes = _getUniqueAccountTypes(report.accounts);
        final missingTypes = _getMissingAccountTypes(currentTypes);

        return CreditAction(
          type: 'planning',
          title: 'Add diverse credit types',
          description: 'Consider adding ${missingTypes.join(", ")} to diversify your credit mix',
          steps: [
            'Assess your current credit account types',
            'Research benefits of different credit types',
            'Apply for missing credit types when ready',
            'Start with secured cards if needed',
            'Monitor credit score after new accounts',
            'Maintain good payment history on all accounts'
          ],
          estimatedCost: 'Varies by credit type',
          timeEstimate: '3-12 months',
          difficulty: 'Medium',
          impact: factor.impact,
        );

      default:
        return CreditAction(
          type: 'general',
          title: 'General credit improvement',
          description: 'Focus on overall credit health',
          steps: [
            'Monitor your credit regularly',
            'Pay bills on time',
            'Keep utilization low',
            'Limit new credit applications',
            'Maintain diverse credit mix'
          ],
          estimatedCost: '\$0',
          timeEstimate: 'Ongoing',
          difficulty: 'Easy',
          impact: factor.impact,
        );
    }
  }

  // Helper methods
  double _calculateAccountsImpact(CreditFactor factor, List<CreditAccount> accounts) {
    if (accounts.isEmpty) return 1.0;

    switch (factor.type) {
      case 'creditUtilization':
        final avgUtilization = _calculateAverageUtilization(accounts);
        if (avgUtilization > 50) return 2.0;
        if (avgUtilization > 30) return 1.5;
        return 1.0;

      case 'paymentHistory':
        final latePayments = _countLatePayments(accounts);
        return latePayments > 2 ? 2.0 : 1.0;

      case 'accountAge':
        final avgAge = _calculateAverageAccountAge(accounts);
        return avgAge < 2 ? 1.5 : 1.0;

      default:
        return 1.0;
    }
  }

  double _calculateUrgency(CreditFactor factor, CreditReport report) {
    switch (factor.type) {
      case 'paymentHistory':
        return _countLatePayments(report.accounts) > 0 ? 2.0 : 1.0;
      case 'creditUtilization':
        return _calculateAverageUtilization(report.accounts) > 40 ? 1.8 : 1.2;
      case 'creditInquiries':
        return _countRecentInquiries(report.inquiries) > 3 ? 1.6 : 1.0;
      default:
        return 1.0;
    }
  }

  double _calculateEase(CreditFactor factor, CreditReport report) {
    switch (factor.type) {
      case 'paymentHistory':
        return 1.2; // Requires ongoing discipline
      case 'creditUtilization':
        return 1.5; // Requires financial resources
      case 'creditInquiries':
        return 1.0; // Easy to control
      case 'accountAge':
        return 2.0; // Hard to change quickly
      case 'accountTypes':
        return 1.8; // Requires planning and approval
      default:
        return 1.5;
    }
  }

  double _calculateUserHistoryFactor(CreditFactor factor, CreditReport report) {
    // This would be based on user's historical behavior
    // For now, return neutral factor
    return 1.0;
  }

  int _getBaseTimelineMonths(String factorType) {
    switch (factorType) {
      case 'paymentHistory':
        return 12;
      case 'creditUtilization':
        return 3;
      case 'creditInquiries':
        return 6;
      case 'accountAge':
        return 24;
      case 'accountTypes':
        return 6;
      default:
        return 6;
    }
  }

  String _formatTimeline(int months) {
    if (months < 1) return 'Immediate';
    if (months == 1) return '1 month';
    if (months < 12) return '$months months';
    final years = months ~/ 12;
    final remainingMonths = months % 12;
    if (remainingMonths == 0) return '$years year${years > 1 ? 's' : ''}';
    return '$years year${years > 1 ? 's' : ''} ${remainingMonths} month${remainingMonths > 1 ? 's' : ''}';
  }

  double _calculateDataCompleteness(CreditReport report) {
    // Calculate how complete the credit data is
    final hasAccounts = report.accounts.isNotEmpty ? 1.0 : 0.0;
    final hasInquiries = report.inquiries.isNotEmpty ? 1.0 : 0.5;
    final hasScore = report.currentScore.score > 0 ? 1.0 : 0.0;
    final hasFactors = report.currentScore.factors.isNotEmpty ? 1.0 : 0.0;

    return (hasAccounts + hasInquiries + hasScore + hasFactors) / 4.0;
  }

  double _calculateFactorClarity(CreditFactor factor) {
    // How clear and actionable the factor is
    return factor.description.isNotEmpty && factor.recommendations.isNotEmpty ? 1.0 : 0.7;
  }

  String _generateRecommendationId(CreditFactor factor) {
    return '${factor.type}_${DateTime.now().millisecondsSinceEpoch}';
  }

  String _getCategory(CreditFactor factor) {
    switch (factor.type) {
      case 'paymentHistory':
        return 'Payment Behavior';
      case 'creditUtilization':
        return 'Credit Usage';
      case 'accountAge':
        return 'Account History';
      case 'creditInquiries':
        return 'Credit Applications';
      case 'accountTypes':
        return 'Credit Mix';
      default:
        return 'General';
    }
  }

  List<String> _findRelatedFactors(CreditFactor factor, List<CreditFactor> allFactors) {
    // Find factors that might be related or affect each other
    final related = <String>[];
    for (final other in allFactors) {
      if (other.id != factor.id && _areFactorsRelated(factor, other)) {
        related.add(other.name);
      }
    }
    return related.take(2).toList();
  }

  bool _areFactorsRelated(CreditFactor a, CreditFactor b) {
    // Define relationships between factors
    if (a.type == 'creditUtilization' && b.type == 'paymentHistory') return true;
    if (a.type == 'accountAge' && b.type == 'accountTypes') return true;
    if (a.type == 'creditInquiries' && b.type == 'accountTypes') return true;
    return false;
  }

  // Utility methods for calculations
  double _calculateAverageUtilization(List<CreditAccount> accounts) {
    if (accounts.isEmpty) return 0.0;
    final totalUtilization = accounts.fold<double>(0, (sum, account) => sum + account.utilization);
    return totalUtilization / accounts.length;
  }

  int _countLatePayments(List<CreditAccount> accounts) {
    // This would require more detailed payment history data
    // For now, return a mock value
    return 0;
  }

  int _countRecentInquiries(List<CreditInquiry> inquiries) {
    final oneYearAgo = DateTime.now().subtract(const Duration(days: 365));
    return inquiries.where((inq) => inq.inquiryDate.isAfter(oneYearAgo)).length;
  }

  double _calculateAverageAccountAge(List<CreditAccount> accounts) {
    if (accounts.isEmpty) return 0.0;
    final totalAge = accounts.fold<double>(0, (sum, account) {
      return sum + DateTime.now().difference(account.openedDate).inDays / 365.0;
    });
    return totalAge / accounts.length;
  }

  List<String> _getUniqueAccountTypes(List<CreditAccount> accounts) {
    return accounts.map((acc) => acc.type).toSet().toList();
  }

  List<String> _getMissingAccountTypes(List<String> currentTypes) {
    const allTypes = ['credit_card', 'auto_loan', 'mortgage', 'personal_loan', 'student_loan'];
    return allTypes.where((type) => !currentTypes.contains(type)).toList();
  }

  String _calculatePaydownCost(List<CreditAccount> accounts) {
    final totalNeeded = accounts.fold<double>(0, (sum, account) {
      final targetBalance = account.creditLimit * 0.25; // Target 25% utilization
      final needed = account.balance - targetBalance;
      return sum + (needed > 0 ? needed : 0);
    });

    if (totalNeeded == 0) return '\$0';
    if (totalNeeded < 1000) return '\$${totalNeeded.toStringAsFixed(0)}';
    if (totalNeeded < 10000) return '\$${(totalNeeded / 1000).toStringAsFixed(1)}K';
    return '\$${(totalNeeded / 1000).toStringAsFixed(0)}K';
  }
}

/// Credit recommendation data model
class CreditRecommendation {
  final String id;
  final String title;
  final String description;
  final double impact;
  final double priority;
  final String timeline;
  final double confidence;
  final String category;
  final CreditAction action;
  final List<String> relatedFactors;

  const CreditRecommendation({
    required this.id,
    required this.title,
    required this.description,
    required this.impact,
    required this.priority,
    required this.timeline,
    required this.confidence,
    required this.category,
    required this.action,
    required this.relatedFactors,
  });

  bool get isHighImpact => impact > 20;
  bool get isHighPriority => priority > 70;
  bool get isHighConfidence => confidence > 0.8;
  bool get isQuickWin => timeline.contains('month') && !timeline.contains('year');
}

/// Actionable credit improvement steps
class CreditAction {
  final String type;
  final String title;
  final String description;
  final List<String> steps;
  final String estimatedCost;
  final String timeEstimate;
  final String difficulty;
  final double impact;

  const CreditAction({
    required this.type,
    required this.title,
    required this.description,
    required this.steps,
    required this.estimatedCost,
    required this.timeEstimate,
    required this.difficulty,
    required this.impact,
  });
}
