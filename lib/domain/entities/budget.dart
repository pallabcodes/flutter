import 'package:equatable/equatable.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/material.dart';
import 'package:finwise/domain/entities/expense.dart';

part 'budget.freezed.dart';
part 'budget.g.dart';

/// Budget entity representing spending limits and goals
/// Supports both category-specific and overall budgets
@freezed
class Budget with _$Budget {
  const factory Budget({
    /// Unique identifier for the budget
    required String id,

    /// User ID who owns this budget
    required String userId,

    /// Budget name/title
    required String name,

    /// Budget description
    String? description,

    /// Budget type (category-specific or overall)
    @Default(BudgetType.category) BudgetType type,

    /// Target spending limit in smallest currency unit
    required int targetAmount,

    /// Currency code (ISO 4217)
    @Default('USD') String currency,

    /// Budget period
    required BudgetPeriod period,

    /// Start date of the budget period
    required DateTime startDate,

    /// End date of the budget period
    required DateTime endDate,

    /// Categories this budget applies to (empty for overall budget)
    @Default([]) List<ExpenseCategory> categories,

    /// Current spent amount in smallest currency unit
    @Default(0) int spentAmount,

    /// Whether to receive notifications when approaching limit
    @Default(true) bool enableNotifications,

    /// Warning threshold percentage (e.g., 80 for 80%)
    @Default(80) int warningThreshold,

    /// Creation timestamp
    required DateTime createdAt,

    /// Last modification timestamp
    required DateTime updatedAt,

    /// Whether this budget is active
    @Default(true) bool isActive,

    /// Whether this budget is synced with remote server
    @Default(false) bool isSynced,
  }) = _Budget;

  const Budget._();

  /// Create budget from JSON
  factory Budget.fromJson(Map<String, dynamic> json) => _$BudgetFromJson(json);

  /// Get formatted target amount with currency symbol
  String get formattedTargetAmount {
    final amountInDollars = targetAmount / 100;
    return '\$${amountInDollars.toStringAsFixed(2)}';
  }

  /// Get formatted spent amount with currency symbol
  String get formattedSpentAmount {
    final amountInDollars = spentAmount / 100;
    return '\$${amountInDollars.toStringAsFixed(2)}';
  }

  /// Calculate remaining budget amount
  int get remainingAmount => targetAmount - spentAmount;

  /// Get formatted remaining amount
  String get formattedRemainingAmount {
    final amountInDollars = remainingAmount / 100;
    return '\$${amountInDollars.toStringAsFixed(2)}';
  }

  /// Calculate budget utilization percentage
  double get utilizationPercentage {
    if (targetAmount == 0) return 0.0;
    return (spentAmount / targetAmount) * 100;
  }

  /// Check if budget is over limit
  bool get isOverBudget => spentAmount > targetAmount;

  /// Check if budget is approaching warning threshold
  bool get isNearLimit => utilizationPercentage >= warningThreshold;

  /// Get budget status
  BudgetStatus get status {
    if (isOverBudget) return BudgetStatus.overBudget;
    if (isNearLimit) return BudgetStatus.warning;
    return BudgetStatus.onTrack;
  }

  /// Check if budget is currently active (within date range)
  bool get isCurrentlyActive {
    final now = DateTime.now();
    return isActive &&
           now.isAfter(startDate.subtract(const Duration(days: 1))) &&
           now.isBefore(endDate.add(const Duration(days: 1)));
  }

  /// Get days remaining in budget period
  int get daysRemaining {
    final now = DateTime.now();
    final remaining = endDate.difference(now).inDays;
    return remaining > 0 ? remaining : 0;
  }

  /// Calculate projected spending based on current progress
  double get projectedSpending {
    if (daysRemaining == 0) return spentAmount.toDouble();

    final totalDays = endDate.difference(startDate).inDays;
    final daysPassed = totalDays - daysRemaining;

    if (daysPassed == 0) return 0.0;

    return (spentAmount / daysPassed) * totalDays;
  }

  /// Create a copy with updated spent amount
  Budget updateSpentAmount(int newSpentAmount) =>
      copyWith(spentAmount: newSpentAmount, updatedAt: DateTime.now());

  /// Create a copy with updated sync status
  Budget markAsSynced() => copyWith(isSynced: true);

  /// Create a copy with updated timestamp
  Budget updateTimestamp() => copyWith(updatedAt: DateTime.now());
}

/// Budget type enumeration
enum BudgetType {
  /// Budget applies to specific categories
  category('Category Budget'),

  /// Budget applies to overall spending
  overall('Overall Budget');

  const BudgetType(this.displayName);

  final String displayName;
}

/// Budget period options
enum BudgetPeriod {
  weekly('Weekly'),
  monthly('Monthly'),
  quarterly('Quarterly'),
  yearly('Yearly'),
  custom('Custom');

  const BudgetPeriod(this.displayName);

  final String displayName;

  /// Calculate date range for the period starting from given date
  DateTimeRange getDateRange(DateTime startDate) {
    switch (this) {
      case BudgetPeriod.weekly:
        final endDate = startDate.add(const Duration(days: 6));
        return DateTimeRange(start: startDate, end: endDate);

      case BudgetPeriod.monthly:
        final endDate = DateTime(startDate.year, startDate.month + 1, 0);
        return DateTimeRange(start: startDate, end: endDate);

      case BudgetPeriod.quarterly:
        final endDate = DateTime(startDate.year, startDate.month + 3, 0);
        return DateTimeRange(start: startDate, end: endDate);

      case BudgetPeriod.yearly:
        final endDate = DateTime(startDate.year + 1, startDate.month, 0);
        return DateTimeRange(start: startDate, end: endDate);

      case BudgetPeriod.custom:
        // For custom budgets, dates are set manually
        return DateTimeRange(start: startDate, end: startDate);
    }
  }
}

/// Budget status enumeration
enum BudgetStatus {
  onTrack('On Track', 0xFF4CAF50),      // Green
  warning('Warning', 0xFFFF9800),      // Orange
  overBudget('Over Budget', 0xFFF44336); // Red

  const BudgetStatus(this.displayName, this.color);

  final String displayName;
  final int color;

  /// Get color as Color object
  Color get colorValue => Color(color);
}

/// Budget alert/notification types
enum BudgetAlertType {
  warningThreshold('Warning Threshold Reached'),
  budgetExceeded('Budget Exceeded'),
  budgetEnding('Budget Ending Soon');

  const BudgetAlertType(this.message);

  final String message;
}

/// Budget progress information
class BudgetProgress {
  final Budget budget;
  final double percentage;
  final BudgetStatus status;
  final int remainingAmount;
  final int daysRemaining;

  const BudgetProgress({
    required this.budget,
    required this.percentage,
    required this.status,
    required this.remainingAmount,
    required this.daysRemaining,
  });

  /// Create progress from budget
  factory BudgetProgress.fromBudget(Budget budget) {
    return BudgetProgress(
      budget: budget,
      percentage: budget.utilizationPercentage,
      status: budget.status,
      remainingAmount: budget.remainingAmount,
      daysRemaining: budget.daysRemaining,
    );
  }
}
