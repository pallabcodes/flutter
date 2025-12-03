import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:finwise/core/performance/optimization_manager.dart';

/// Meaningful, Purpose-Driven Gestures and Animations for Financial Apps
/// Each interaction tells a story, provides feedback, and enhances understanding
class MeaningfulInteractions {
  static final MeaningfulInteractions _instance = MeaningfulInteractions._internal();
  factory MeaningfulInteractions() => _instance;
  MeaningfulInteractions._internal();

  final OptimizationManager _optimizationManager = OptimizationManager();

  /// Financial State Animations - Communicate financial health
  Widget createFinancialHealthIndicator({
    required double score,
    required FinancialHealthState state,
    String? label,
    VoidCallback? onTap,
  }) {
    return _FinancialHealthIndicator(
      score: score,
      state: state,
      label: label,
      onTap: onTap,
      optimizationManager: _optimizationManager,
    );
  }

  /// Money Flow Animation - Show transaction movement
  Widget createMoneyFlow({
    required double amount,
    required TransactionDirection direction,
    required TransactionType type,
    String? description,
    VoidCallback? onComplete,
  }) {
    return _MoneyFlowAnimation(
      amount: amount,
      direction: direction,
      type: type,
      description: description,
      onComplete: onComplete,
      optimizationManager: _optimizationManager,
    );
  }

  /// Goal Progress Celebration - Meaningful achievement feedback
  Widget createGoalProgress({
    required String goalName,
    required double progress,
    required double targetAmount,
    required double currentAmount,
    bool isCompleted = false,
    VoidCallback? onCelebrate,
  }) {
    return _GoalProgressCelebration(
      goalName: goalName,
      progress: progress,
      targetAmount: targetAmount,
      currentAmount: currentAmount,
      isCompleted: isCompleted,
      onCelebrate: onCelebrate,
      optimizationManager: _optimizationManager,
    );
  }

  /// Risk Level Indicator - Visual risk communication
  Widget createRiskIndicator({
    required RiskLevel level,
    required String assetName,
    double? volatility,
    VoidCallback? onTap,
  }) {
    return _RiskLevelIndicator(
      level: level,
      assetName: assetName,
      volatility: volatility,
      onTap: onTap,
      optimizationManager: _optimizationManager,
    );
  }

  /// Swipe to Action - Purposeful financial gestures
  Widget createSwipeAction({
    required Widget child,
    required List<SwipeAction> actions,
    required SwipeActionType primaryAction,
    VoidCallback? onActionTriggered,
  }) {
    return _SwipeToAction(
      child: child,
      actions: actions,
      primaryAction: primaryAction,
      onActionTriggered: onActionTriggered,
      optimizationManager: _optimizationManager,
    );
  }

  /// Data Visualization Animation - Make numbers tell stories
  Widget createDataStory({
    required String title,
    required List<DataPoint> dataPoints,
    required ChartType chartType,
    String? insight,
    VoidCallback? onInsightTap,
  }) {
    return _DataStoryAnimation(
      title: title,
      dataPoints: dataPoints,
      chartType: chartType,
      insight: insight,
      onInsightTap: onInsightTap,
      optimizationManager: _optimizationManager,
    );
  }

  /// Attention-Directing Pulse - Guide user focus
  Widget createAttentionPulse({
    required Widget child,
    required AttentionType type,
    required String message,
    VoidCallback? onAcknowledged,
  }) {
    return _AttentionPulse(
      child: child,
      type: type,
      message: message,
      onAcknowledged: onAcknowledged,
      optimizationManager: _optimizationManager,
    );
  }

  /// Confidence Builder - Show AI certainty levels
  Widget createConfidenceIndicator({
    required double confidence,
    required String action,
    String? reasoning,
    VoidCallback? onDetailsTap,
  }) {
    return _ConfidenceIndicator(
      confidence: confidence,
      action: action,
      reasoning: reasoning,
      onDetailsTap: onDetailsTap,
      optimizationManager: _optimizationManager,
    );
  }

  /// Transaction Confirmation - Meaningful approval gestures
  Widget createTransactionConfirm({
    required TransactionData transaction,
    required VoidCallback onConfirm,
    required VoidCallback onCancel,
    String? securityNote,
  }) {
    return _TransactionConfirmation(
      transaction: transaction,
      onConfirm: onConfirm,
      onCancel: onCancel,
      securityNote: securityNote,
      optimizationManager: _optimizationManager,
    );
  }

  /// Savings Impact - Show the real impact of small actions
  Widget createSavingsImpact({
    required String action,
    required double dailySavings,
    required int timeframeDays,
    VoidCallback? onStartSaving,
  }) {
    return _SavingsImpactVisualization(
      action: action,
      dailySavings: dailySavings,
      timeframeDays: timeframeDays,
      onStartSaving: onStartSaving,
      optimizationManager: _optimizationManager,
    );
  }

  /// Portfolio Balance Animation - Communicate wealth changes
  Widget createPortfolioBalance({
    required double balance,
    required double change,
    required Duration timeframe,
    List<AssetContribution>? topContributors,
  }) {
    return _PortfolioBalanceAnimation(
      balance: balance,
      change: change,
      timeframe: timeframe,
      topContributors: topContributors,
      optimizationManager: _optimizationManager,
    );
  }

  /// Habit Formation - Gamify financial discipline
  Widget createHabitStreak({
    required String habit,
    required int streakDays,
    required int bestStreak,
    bool isTodayComplete = false,
    VoidCallback? onMaintainStreak,
  }) {
    return _HabitStreakIndicator(
      habit: habit,
      streakDays: streakDays,
      bestStreak: bestStreak,
      isTodayComplete: isTodayComplete,
      onMaintainStreak: onMaintainStreak,
      optimizationManager: _optimizationManager,
    );
  }
}

/// Financial Health States - Purpose-driven visual communication
enum FinancialHealthState {
  excellent,    // Green, stable, growing
  good,        // Light green, positive
  fair,        // Yellow, needs attention
  concerning,  // Orange, action needed
  critical,    // Red, urgent action required
}

/// Transaction Directions - Clear money movement visualization
enum TransactionDirection {
  incoming,    // Money coming in (earnings, refunds)
  outgoing,    // Money going out (expenses, payments)
  transfer,    // Money moving between accounts
  investment,  // Money invested (stocks, savings)
}

/// Transaction Types - Purposeful categorization
enum TransactionType {
  salary,      // Stable, reliable income
  bonus,       // Unexpected positive surprise
  expense,     // Necessary spending
  luxury,      // Discretionary spending
  savings,     // Building security
  investment,  // Growing wealth
  bill,        // Recurring obligation
  refund,      // Money recovered
}

/// Risk Levels - Visual risk communication
enum RiskLevel {
  veryLow,     // Conservative, stable (bank savings)
  low,         // Low risk (bonds, stable stocks)
  moderate,    // Balanced risk (diversified portfolio)
  high,        // Higher risk (growth stocks, crypto)
  veryHigh,    // High risk (leveraged, speculative)
}

/// Swipe Actions - Purposeful gesture responses
enum SwipeActionType {
  save,        // Save for later
  invest,      // Invest this amount
  pay,         // Pay bill
  transfer,    // Move to different account
  analyze,     // Get insights
  ignore,      // Dismiss/ignore
}

/// Chart Types - Data storytelling
enum ChartType {
  growth,      // Upward trends (positive)
  decline,     // Downward trends (concerning)
  stable,      // Consistent performance
  volatile,    // Unpredictable changes
  comparison,  // Side-by-side analysis
}

/// Attention Types - Purposeful focus guidance
enum AttentionType {
  opportunity,     // Positive opportunity (bonus, discount)
  warning,         // Important warning (overdraft, bill due)
  achievement,     // Goal achieved, milestone reached
  insight,         // Valuable insight discovered
  action,          // Action required (approve transaction)
}

/// Data Models for Meaningful Interactions
class SwipeAction {
  final SwipeActionType type;
  final String label;
  final IconData icon;
  final Color color;
  final String description;

  const SwipeAction({
    required this.type,
    required this.label,
    required this.icon,
    required this.color,
    required this.description,
  });
}

class DataPoint {
  final DateTime date;
  final double value;
  final String? label;
  final Color? color;

  const DataPoint({
    required this.date,
    required this.value,
    this.label,
    this.color,
  });
}

class TransactionData {
  final String description;
  final double amount;
  final String recipient;
  final TransactionType type;
  final DateTime timestamp;

  const TransactionData({
    required this.description,
    required this.amount,
    required this.recipient,
    required this.type,
    required this.timestamp,
  });
}

class AssetContribution {
  final String assetName;
  final double contribution;
  final double percentage;
  final Color color;

  const AssetContribution({
    required this.assetName,
    required this.contribution,
    required this.percentage,
    required this.color,
  });
}

/// Financial Health Indicator - Purposeful state communication
class _FinancialHealthIndicator extends StatefulWidget {
  final double score;
  final FinancialHealthState state;
  final String? label;
  final VoidCallback? onTap;
  final OptimizationManager optimizationManager;

  const _FinancialHealthIndicator({
    required this.score,
    required this.state,
    this.label,
    this.onTap,
    required this.optimizationManager,
  });

  @override
  _FinancialHealthIndicatorState createState() => _FinancialHealthIndicatorState();
}

class _FinancialHealthIndicatorState extends State<_FinancialHealthIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: widget.state == FinancialHealthState.excellent ? 1.1 : 0.9,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _colorAnimation = ColorTween(
      begin: _getStateColor(widget.state),
      end: _getStateColor(widget.state).withOpacity(0.7),
    ).animate(_controller);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _colorAnimation.value,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _getStateColor(widget.state).withOpacity(0.3),
                    blurRadius: 8 * _pulseAnimation.value,
                    spreadRadius: 2 * _pulseAnimation.value,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${widget.score.round()}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (widget.label != null)
                    Text(
                      widget.label!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  Icon(
                    _getStateIcon(widget.state),
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getStateColor(FinancialHealthState state) {
    switch (state) {
      case FinancialHealthState.excellent: return Colors.green;
      case FinancialHealthState.good: return Colors.lightGreen;
      case FinancialHealthState.fair: return Colors.yellow;
      case FinancialHealthState.concerning: return Colors.orange;
      case FinancialHealthState.critical: return Colors.red;
    }
  }

  IconData _getStateIcon(FinancialHealthState state) {
    switch (state) {
      case FinancialHealthState.excellent: return Icons.trending_up;
      case FinancialHealthState.good: return Icons.thumb_up;
      case FinancialHealthState.fair: return Icons.warning;
      case FinancialHealthState.concerning: return Icons.warning_amber;
      case FinancialHealthState.critical: return Icons.error;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

/// Money Flow Animation - Purposeful transaction visualization
class _MoneyFlowAnimation extends StatefulWidget {
  final double amount;
  final TransactionDirection direction;
  final TransactionType type;
  final String? description;
  final VoidCallback? onComplete;
  final OptimizationManager optimizationManager;

  const _MoneyFlowAnimation({
    required this.amount,
    required this.direction,
    required this.type,
    this.description,
    this.onComplete,
    required this.optimizationManager,
  });

  @override
  _MoneyFlowAnimationState createState() => _MoneyFlowAnimationState();
}

class _MoneyFlowAnimationState extends State<_MoneyFlowAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    final startOffset = widget.direction == TransactionDirection.incoming
        ? const Offset(-1.0, 0.0)
        : const Offset(1.0, 0.0);

    _slideAnimation = Tween<Offset>(
      begin: startOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _controller.forward().then((_) {
      widget.onComplete?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = _getTransactionColor(widget.type, widget.direction);
    final icon = _getTransactionIcon(widget.type, widget.direction);

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '\$${widget.amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      if (widget.description != null)
                        Text(
                          widget.description!,
                          style: TextStyle(
                            fontSize: 14,
                            color: color.withOpacity(0.7),
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  widget.direction == TransactionDirection.incoming
                      ? Icons.arrow_forward
                      : Icons.arrow_back,
                  color: color,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getTransactionColor(TransactionType type, TransactionDirection direction) {
    if (direction == TransactionDirection.incoming) {
      switch (type) {
        case TransactionType.salary: return Colors.green;
        case TransactionType.bonus: return Colors.lightGreen;
        case TransactionType.refund: return Colors.teal;
        default: return Colors.green;
      }
    } else {
      switch (type) {
        case TransactionType.expense: return Colors.blue;
        case TransactionType.luxury: return Colors.purple;
        case TransactionType.bill: return Colors.red;
        case TransactionType.investment: return Colors.orange;
        case TransactionType.savings: return Colors.indigo;
        default: return Colors.blue;
      }
    }
  }

  IconData _getTransactionIcon(TransactionType type, TransactionDirection direction) {
    if (direction == TransactionDirection.incoming) {
      switch (type) {
        case TransactionType.salary: return Icons.work;
        case TransactionType.bonus: return Icons.celebration;
        case TransactionType.refund: return Icons.replay;
        default: return Icons.arrow_downward;
      }
    } else {
      switch (type) {
        case TransactionType.expense: return Icons.shopping_cart;
        case TransactionType.luxury: return Icons.diamond;
        case TransactionType.bill: return Icons.receipt;
        case TransactionType.investment: return Icons.trending_up;
        case TransactionType.savings: return Icons.savings;
        default: return Icons.arrow_upward;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

/// Goal Progress Celebration - Meaningful achievement feedback
class _GoalProgressCelebration extends StatefulWidget {
  final String goalName;
  final double progress;
  final double targetAmount;
  final double currentAmount;
  final bool isCompleted;
  final VoidCallback? onCelebrate;
  final OptimizationManager optimizationManager;

  const _GoalProgressCelebration({
    required this.goalName,
    required this.progress,
    required this.targetAmount,
    required this.currentAmount,
    required this.isCompleted,
    this.onCelebrate,
    required this.optimizationManager,
  });

  @override
  _GoalProgressCelebrationState createState() => _GoalProgressCelebrationState();
}

class _GoalProgressCelebrationState extends State<_GoalProgressCelebration>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.progress,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.isCompleted ? 1.2 : 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.isCompleted ? Curves.elasticOut : Curves.easeOut,
    ));

    _colorAnimation = ColorTween(
      begin: Colors.grey,
      end: widget.isCompleted ? Colors.amber : _getProgressColor(widget.progress),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward().then((_) {
      if (widget.isCompleted) {
        widget.onCelebrate?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _colorAnimation.value?.withOpacity(0.3) ?? Colors.grey.withOpacity(0.3),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  widget.isCompleted ? Icons.celebration : Icons.flag,
                  color: _colorAnimation.value,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.goalName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.isCompleted
                            ? 'Goal Achieved! 🎉'
                            : '\$${widget.currentAmount.toStringAsFixed(0)} of \$${widget.targetAmount.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return LinearProgressIndicator(
                  value: _progressAnimation.value,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(_colorAnimation.value ?? Colors.blue),
                );
              },
            ),
            const SizedBox(height: 8),
            Text(
              '${(_progressAnimation.value * 100).round()}% Complete',
              style: TextStyle(
                fontSize: 12,
                color: _colorAnimation.value,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (widget.isCompleted) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (index) => AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      final delay = index * 0.1;
                      final animation = CurvedAnimation(
                        parent: _controller,
                        curve: Interval(delay, delay + 0.3, curve: Curves.elasticOut),
                      );

                      return ScaleTransition(
                        scale: Tween<double>(begin: 0.0, end: 1.0).animate(animation),
                        child: const Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 20,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getProgressColor(double progress) {
    if (progress >= 1.0) return Colors.green;
    if (progress >= 0.75) return Colors.lightGreen;
    if (progress >= 0.5) return Colors.yellow;
    if (progress >= 0.25) return Colors.orange;
    return Colors.red;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

/// Risk Level Indicator - Visual risk communication
class _RiskLevelIndicator extends StatefulWidget {
  final RiskLevel level;
  final String assetName;
  final double? volatility;
  final VoidCallback? onTap;
  final OptimizationManager optimizationManager;

  const _RiskLevelIndicator({
    required this.level,
    required this.assetName,
    this.volatility,
    this.onTap,
    required this.optimizationManager,
  });

  @override
  _RiskLevelIndicatorState createState() => _RiskLevelIndicatorState();
}

class _RiskLevelIndicatorState extends State<_RiskLevelIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shakeAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _shakeAnimation = Tween<double>(
      begin: -2.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.level == RiskLevel.veryHigh ? Curves.elasticInOut : Curves.linear,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: widget.level == RiskLevel.veryHigh ? 1.1 : 1.05,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final color = _getRiskColor(widget.level);
    final icon = _getRiskIcon(widget.level);
    final label = _getRiskLabel(widget.level);

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(
              widget.level == RiskLevel.veryHigh ? _shakeAnimation.value : 0.0,
              0.0,
            ),
            child: Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: color, size: 20),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.assetName,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 10,
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (widget.volatility != null)
                          Text(
                            '${(widget.volatility! * 100).toStringAsFixed(1)}% volatility',
                            style: TextStyle(
                              fontSize: 8,
                              color: color.withOpacity(0.7),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getRiskColor(RiskLevel level) {
    switch (level) {
      case RiskLevel.veryLow: return Colors.green;
      case RiskLevel.low: return Colors.lightGreen;
      case RiskLevel.moderate: return Colors.yellow;
      case RiskLevel.high: return Colors.orange;
      case RiskLevel.veryHigh: return Colors.red;
    }
  }

  IconData _getRiskIcon(RiskLevel level) {
    switch (level) {
      case RiskLevel.veryLow: return Icons.shield;
      case RiskLevel.low: return Icons.security;
      case RiskLevel.moderate: return Icons.balance;
      case RiskLevel.high: return Icons.warning;
      case RiskLevel.veryHigh: return Icons.error;
    }
  }

  String _getRiskLabel(RiskLevel level) {
    switch (level) {
      case RiskLevel.veryLow: return 'Very Low Risk';
      case RiskLevel.low: return 'Low Risk';
      case RiskLevel.moderate: return 'Moderate Risk';
      case RiskLevel.high: return 'High Risk';
      case RiskLevel.veryHigh: return 'Very High Risk';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

/// Swipe to Action - Purposeful financial gestures
class _SwipeToAction extends StatefulWidget {
  final Widget child;
  final List<SwipeAction> actions;
  final SwipeActionType primaryAction;
  final VoidCallback? onActionTriggered;
  final OptimizationManager optimizationManager;

  const _SwipeToAction({
    required this.child,
    required this.actions,
    required this.primaryAction,
    this.onActionTriggered,
    required this.optimizationManager,
  });

  @override
  _SwipeToActionState createState() => _SwipeToActionState();
}

class _SwipeToActionState extends State<_SwipeToAction>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _opacityAnimation;

  double _dragExtent = 0.0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-0.3, 0.0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart: _onDragStart,
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      child: Stack(
        children: [
          // Action background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return SlideTransition(
                  position: _slideAnimation,
                  child: Opacity(
                    opacity: _opacityAnimation.value,
                    child: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      color: _getPrimaryAction().color,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _getPrimaryAction().icon,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getPrimaryAction().label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Main content
          SlideTransition(
            position: Tween<Offset>(
              begin: Offset.zero,
              end: const Offset(-0.3, 0.0),
            ).animate(_controller),
            child: widget.child,
          ),
        ],
      ),
    );
  }

  void _onDragStart(DragStartDetails details) {
    setState(() => _isDragging = true);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    _dragExtent += details.delta.dx;

    // Constrain drag extent
    _dragExtent = _dragExtent.clamp(-150.0, 0.0);

    // Update animation
    final progress = (_dragExtent.abs() / 150.0).clamp(0.0, 1.0);
    _controller.value = progress;
  }

  void _onDragEnd(DragEndDetails details) {
    setState(() => _isDragging = false);

    if (_controller.value > 0.5) {
      // Trigger action
      _controller.forward().then((_) {
        widget.onActionTriggered?.call();
        // Reset after a delay
        Future.delayed(const Duration(milliseconds: 500), () {
          _controller.reverse();
        });
      });
    } else {
      // Reset
      _controller.reverse();
    }

    _dragExtent = 0.0;
  }

  SwipeAction _getPrimaryAction() {
    return widget.actions.firstWhere(
      (action) => action.type == widget.primaryAction,
      orElse: () => widget.actions.first,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

/// Data Story Animation - Make numbers tell stories
class _DataStoryAnimation extends StatefulWidget {
  final String title;
  final List<DataPoint> dataPoints;
  final ChartType chartType;
  final String? insight;
  final VoidCallback? onInsightTap;
  final OptimizationManager optimizationManager;

  const _DataStoryAnimation({
    required this.title,
    required this.dataPoints,
    required this.chartType,
    this.insight,
    this.onInsightTap,
    required this.optimizationManager,
  });

  @override
  _DataStoryAnimationState createState() => _DataStoryAnimationState();
}

class _DataStoryAnimationState extends State<_DataStoryAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _pointAnimations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Create staggered animations for each data point
    _pointAnimations = List.generate(
      widget.dataPoints.length,
      (index) {
        final delay = index * 0.1;
        return Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Interval(delay, delay + 0.3, curve: Curves.elasticOut),
          ),
        );
      },
    );

    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: _DataStoryPainter(
                    dataPoints: widget.dataPoints,
                    animations: _pointAnimations,
                    chartType: widget.chartType,
                  ),
                  size: const Size(double.infinity, 150),
                );
              },
            ),
          ),
          if (widget.insight != null) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: widget.onInsightTap,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getChartColor(widget.chartType).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getChartColor(widget.chartType).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb,
                      color: _getChartColor(widget.chartType),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.insight!,
                        style: TextStyle(
                          fontSize: 14,
                          color: _getChartColor(widget.chartType),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getChartColor(ChartType type) {
    switch (type) {
      case ChartType.growth: return Colors.green;
      case ChartType.decline: return Colors.red;
      case ChartType.stable: return Colors.blue;
      case ChartType.volatile: return Colors.orange;
      case ChartType.comparison: return Colors.purple;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _DataStoryPainter extends CustomPainter {
  final List<DataPoint> dataPoints;
  final List<Animation<double>> animations;
  final ChartType chartType;

  _DataStoryPainter({
    required this.dataPoints,
    required this.animations,
    required this.chartType,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = Colors.blue.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    final points = <Offset>[];

    for (var i = 0; i < dataPoints.length; i++) {
      final dataPoint = dataPoints[i];
      final animation = animations[i];

      final x = (i / (dataPoints.length - 1)) * size.width;
      final y = (1 - (dataPoint.value / _getMaxValue())) * size.height;

      final animatedY = y * animation.value;
      points.add(Offset(x, animatedY));

      // Draw point
      if (animation.value > 0) {
        canvas.drawCircle(
          Offset(x, animatedY),
          4.0 * animation.value,
          Paint()..color = dataPoint.color ?? Colors.blue,
        );
      }
    }

    // Draw line
    if (points.length > 1) {
      final path = Path();
      path.moveTo(points.first.dx, points.first.dy);

      for (var i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }

      canvas.drawPath(path, paint);

      // Fill area under curve for growth charts
      if (chartType == ChartType.growth) {
        final fillPath = Path.from(path);
        fillPath.lineTo(size.width, size.height);
        fillPath.lineTo(0, size.height);
        fillPath.close();
        canvas.drawPath(fillPath, fillPaint);
      }
    }
  }

  double _getMaxValue() {
    return dataPoints.map((p) => p.value).reduce((a, b) => a > b ? a : b);
  }

  @override
  bool shouldRepaint(_DataStoryPainter oldDelegate) {
    return true; // Always repaint during animation
  }
}

/// Attention Pulse - Guide user focus to important information
class _AttentionPulse extends StatefulWidget {
  final Widget child;
  final AttentionType type;
  final String message;
  final VoidCallback? onAcknowledged;
  final OptimizationManager optimizationManager;

  const _AttentionPulse({
    required this.child,
    required this.type,
    required this.message,
    this.onAcknowledged,
    required this.optimizationManager,
  });

  @override
  _AttentionPulseState createState() => _AttentionPulseState();
}

class _AttentionPulseState extends State<_AttentionPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: _getPulseScale(widget.type),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final color = _getAttentionColor(widget.type);
    final icon = _getAttentionIcon(widget.type);

    return GestureDetector(
      onTap: widget.onAcknowledged,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(_opacityAnimation.value * 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: color.withOpacity(_opacityAnimation.value * 0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(_opacityAnimation.value * 0.3),
                    blurRadius: 8 * _scaleAnimation.value,
                    spreadRadius: 2 * _scaleAnimation.value,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(icon, color: color, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: TextStyle(
                        fontSize: 14,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.close,
                    color: color.withOpacity(0.5),
                    size: 16,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  double _getPulseScale(AttentionType type) {
    switch (type) {
      case AttentionType.opportunity: return 1.05;
      case AttentionType.warning: return 1.08;
      case AttentionType.achievement: return 1.12;
      case AttentionType.insight: return 1.06;
      case AttentionType.action: return 1.1;
    }
  }

  Color _getAttentionColor(AttentionType type) {
    switch (type) {
      case AttentionType.opportunity: return Colors.green;
      case AttentionType.warning: return Colors.red;
      case AttentionType.achievement: return Colors.amber;
      case AttentionType.insight: return Colors.blue;
      case AttentionType.action: return Colors.orange;
    }
  }

  IconData _getAttentionIcon(AttentionType type) {
    switch (type) {
      case AttentionType.opportunity: return Icons.local_offer;
      case AttentionType.warning: return Icons.warning;
      case AttentionType.achievement: return Icons.emoji_events;
      case AttentionType.insight: return Icons.lightbulb;
      case AttentionType.action: return Icons.touch_app;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

/// Confidence Indicator - Show AI certainty levels meaningfully
class _ConfidenceIndicator extends StatefulWidget {
  final double confidence;
  final String action;
  final String? reasoning;
  final VoidCallback? onDetailsTap;
  final OptimizationManager optimizationManager;

  const _ConfidenceIndicator({
    required this.confidence,
    required this.action,
    this.reasoning,
    this.onDetailsTap,
    required this.optimizationManager,
  });

  @override
  _ConfidenceIndicatorState createState() => _ConfidenceIndicatorState();
}

class _ConfidenceIndicatorState extends State<_ConfidenceIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fillAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fillAnimation = Tween<double>(
      begin: 0.0,
      end: widget.confidence,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    final color = _getConfidenceColor(widget.confidence);

    return GestureDetector(
      onTap: widget.onDetailsTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  _getConfidenceIcon(widget.confidence),
                  color: color,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.action,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${(widget.confidence * 100).toStringAsFixed(0)}% Confidence',
                        style: TextStyle(
                          fontSize: 12,
                          color: color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.info_outline,
                  color: color.withOpacity(0.5),
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 12),
            AnimatedBuilder(
              animation: _fillAnimation,
              builder: (context, child) {
                return LinearProgressIndicator(
                  value: _fillAnimation.value,
                  backgroundColor: color.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                );
              },
            ),
            if (widget.reasoning != null) ...[
              const SizedBox(height: 8),
              Text(
                widget.reasoning!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.9) return Colors.green;
    if (confidence >= 0.7) return Colors.lightGreen;
    if (confidence >= 0.5) return Colors.yellow;
    if (confidence >= 0.3) return Colors.orange;
    return Colors.red;
  }

  IconData _getConfidenceIcon(double confidence) {
    if (confidence >= 0.9) return Icons.verified;
    if (confidence >= 0.7) return Icons.thumb_up;
    if (confidence >= 0.5) return Icons.help;
    if (confidence >= 0.3) return Icons.warning;
    return Icons.error;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

/// Transaction Confirmation - Meaningful approval gestures
class _TransactionConfirmation extends StatefulWidget {
  final TransactionData transaction;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final String? securityNote;
  final OptimizationManager optimizationManager;

  const _TransactionConfirmation({
    required this.transaction,
    required this.onConfirm,
    required this.onCancel,
    this.securityNote,
    required this.optimizationManager,
  });

  @override
  _TransactionConfirmationState createState() => _TransactionConfirmationState();
}

class _TransactionConfirmationState extends State<_TransactionConfirmation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getTransactionColor(widget.transaction.type).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getTransactionIcon(widget.transaction.type),
                  color: _getTransactionColor(widget.transaction.type),
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Confirm Transaction',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.transaction.description,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Amount:'),
                        Text(
                          '\$${widget.transaction.amount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('To:'),
                        Text(widget.transaction.recipient),
                      ],
                    ),
                  ],
                ),
              ),
              if (widget.securityNote != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.security,
                        color: Colors.blue,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.securityNote!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _controller.reverse().then((_) {
                          widget.onCancel();
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _controller.reverse().then((_) {
                          widget.onConfirm();
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: _getTransactionColor(widget.transaction.type),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Confirm'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getTransactionColor(TransactionType type) {
    switch (type) {
      case TransactionType.salary: return Colors.green;
      case TransactionType.bonus: return Colors.lightGreen;
      case TransactionType.expense: return Colors.blue;
      case TransactionType.luxury: return Colors.purple;
      case TransactionType.investment: return Colors.orange;
      case TransactionType.savings: return Colors.indigo;
      case TransactionType.bill: return Colors.red;
      case TransactionType.refund: return Colors.teal;
    }
  }

  IconData _getTransactionIcon(TransactionType type) {
    switch (type) {
      case TransactionType.salary: return Icons.work;
      case TransactionType.bonus: return Icons.celebration;
      case TransactionType.expense: return Icons.shopping_cart;
      case TransactionType.luxury: return Icons.diamond;
      case TransactionType.investment: return Icons.trending_up;
      case TransactionType.savings: return Icons.savings;
      case TransactionType.bill: return Icons.receipt;
      case TransactionType.refund: return Icons.replay;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

/// Savings Impact Visualization - Show the real impact of small actions
class _SavingsImpactVisualization extends StatefulWidget {
  final String action;
  final double dailySavings;
  final int timeframeDays;
  final VoidCallback? onStartSaving;
  final OptimizationManager optimizationManager;

  const _SavingsImpactVisualization({
    required this.action,
    required this.dailySavings,
    required this.timeframeDays,
    this.onStartSaving,
    required this.optimizationManager,
  });

  @override
  _SavingsImpactVisualizationState createState() => _SavingsImpactVisualizationState();
}

class _SavingsImpactVisualizationState extends State<_SavingsImpactVisualization>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _counterAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    final totalSavings = widget.dailySavings * widget.timeframeDays;

    _counterAnimation = Tween<double>(
      begin: 0.0,
      end: totalSavings,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    final totalSavings = widget.dailySavings * widget.timeframeDays;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.withOpacity(0.1), Colors.blue.withOpacity(0.1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.green.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.savings,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.action,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Save \$${widget.dailySavings.toStringAsFixed(2)} per day',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AnimatedBuilder(
              animation: _counterAnimation,
              builder: (context, child) {
                return Column(
                  children: [
                    Text(
                      'In ${widget.timeframeDays} days, you\'ll save',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\$${_counterAnimation.value.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: _counterAnimation.value / totalSavings,
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: widget.onStartSaving,
              icon: const Icon(Icons.rocket_launch),
              label: const Text('Start Saving'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

/// Portfolio Balance Animation - Communicate wealth changes meaningfully
class _PortfolioBalanceAnimation extends StatefulWidget {
  final double balance;
  final double change;
  final Duration timeframe;
  final List<AssetContribution>? topContributors;
  final OptimizationManager optimizationManager;

  const _PortfolioBalanceAnimation({
    required this.balance,
    required this.change,
    required this.timeframe,
    this.topContributors,
    required this.optimizationManager,
  });

  @override
  _PortfolioBalanceAnimationState createState() => _PortfolioBalanceAnimationState();
}

class _PortfolioBalanceAnimationState extends State<_PortfolioBalanceAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _balanceAnimation;
  late Animation<double> _changeAnimation;
  late Animation<Color?> _changeColorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _balanceAnimation = Tween<double>(
      begin: widget.balance - widget.change,
      end: widget.balance,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _changeAnimation = Tween<double>(
      begin: 0.0,
      end: widget.change.abs(),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _changeColorAnimation = ColorTween(
      begin: Colors.grey,
      end: widget.change >= 0 ? Colors.green : Colors.red,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    final isPositive = widget.change >= 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Portfolio Balance',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _changeColorAnimation.value?.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.timeframe.inDays == 1 ? 'Today' :
                  widget.timeframe.inDays == 7 ? 'This Week' :
                  '${widget.timeframe.inDays} Days',
                  style: TextStyle(
                    fontSize: 12,
                    color: _changeColorAnimation.value,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: _balanceAnimation,
            builder: (context, child) {
              return Text(
                '\$${_balanceAnimation.value.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: _changeAnimation,
            builder: (context, child) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isPositive ? Icons.trending_up : Icons.trending_down,
                    color: _changeColorAnimation.value,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${isPositive ? '+' : '-'}\$${_changeAnimation.value.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      color: _changeColorAnimation.value,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    ' (${isPositive ? '+' : ''}${(widget.change / (widget.balance - widget.change) * 100).toStringAsFixed(1)}%)',
                    style: TextStyle(
                      fontSize: 12,
                      color: _changeColorAnimation.value?.withOpacity(0.7),
                    ),
                  ),
                ],
              );
            },
          ),
          if (widget.topContributors != null && widget.topContributors!.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text(
              'Top Contributors',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ...widget.topContributors!.take(3).map((contributor) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: contributor.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        contributor.assetName,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    Text(
                      '${contributor.percentage.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

/// Habit Streak Indicator - Gamify financial discipline
class _HabitStreakIndicator extends StatefulWidget {
  final String habit;
  final int streakDays;
  final int bestStreak;
  final bool isTodayComplete;
  final VoidCallback? onMaintainStreak;
  final OptimizationManager optimizationManager;

  const _HabitStreakIndicator({
    required this.habit,
    required this.streakDays,
    required this.bestStreak,
    required this.isTodayComplete,
    this.onMaintainStreak,
    required this.optimizationManager,
  });

  @override
  _HabitStreakIndicatorState createState() => _HabitStreakIndicatorState();
}

class _HabitStreakIndicatorState extends State<_HabitStreakIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.isTodayComplete ? 1.1 : 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _colorAnimation = ColorTween(
      begin: Colors.grey,
      end: widget.isTodayComplete ? Colors.orange : Colors.blue,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    if (widget.isTodayComplete) {
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onMaintainStreak,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _colorAnimation.value?.withOpacity(0.3) ?? Colors.grey.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: _colorAnimation.value?.withOpacity(0.1) ?? Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _colorAnimation.value?.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getHabitIcon(widget.habit),
                  color: _colorAnimation.value,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.habit,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${widget.streakDays} day streak',
                      style: TextStyle(
                        fontSize: 12,
                        color: _colorAnimation.value,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (widget.bestStreak > widget.streakDays)
                      Text(
                        'Best: ${widget.bestStreak} days',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
              ),
              if (widget.isTodayComplete)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getHabitIcon(String habit) {
    switch (habit.toLowerCase()) {
      case 'budget tracking': return Icons.pie_chart;
      case 'daily savings': return Icons.savings;
      case 'expense logging': return Icons.receipt;
      case 'investment review': return Icons.trending_up;
      case 'credit monitoring': return Icons.credit_card;
      default: return Icons.track_changes;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
