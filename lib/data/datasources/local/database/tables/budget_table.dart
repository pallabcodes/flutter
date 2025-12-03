import 'package:drift/drift.dart';

/// Budgets table definition
/// Represents the local storage schema for budget entities
class Budgets extends Table {
  /// Unique identifier for the budget
  TextColumn get id => text()();

  /// User ID who owns this budget
  TextColumn get userId => text()();

  /// Budget name/title
  TextColumn get name => text()();

  /// Budget description
  TextColumn get description => text().nullable()();

  /// Budget type (category or overall)
  TextColumn get type => text()();

  /// Target spending limit in smallest currency unit
  IntColumn get targetAmount => integer()();

  /// Currency code (ISO 4217)
  TextColumn get currency => text().withDefault(const Constant('USD'))();

  /// Budget period type (weekly, monthly, etc.)
  TextColumn get period => text()();

  /// Start date of the budget period
  DateTimeColumn get startDate => dateTime()();

  /// End date of the budget period
  DateTimeColumn get endDate => dateTime()();

  /// Categories this budget applies to (stored as JSON)
  TextColumn get categories => text().nullable()();

  /// Current spent amount in smallest currency unit
  IntColumn get spentAmount => integer().withDefault(const Constant(0))();

  /// Whether to receive notifications when approaching limit
  BoolColumn get enableNotifications => boolean().withDefault(const Constant(true))();

  /// Warning threshold percentage (e.g., 80 for 80%)
  IntColumn get warningThreshold => integer().withDefault(const Constant(80))();

  /// Creation timestamp
  DateTimeColumn get createdAt => dateTime()();

  /// Last modification timestamp
  DateTimeColumn get updatedAt => dateTime()();

  /// Whether this budget is active
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  /// Whether this budget is synced with remote server
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  /// Primary key definition
  @override
  Set<Column> get primaryKey => {id};

  /// Table indexes for performance
  @override
  List<String> get customConstraints => [
    'UNIQUE(id)',
  ];

  /// Additional indexes for common queries
  static const List<String> indexes = [
    'CREATE INDEX idx_budgets_user_active ON budgets(user_id, is_active)',
    'CREATE INDEX idx_budgets_user_dates ON budgets(user_id, start_date, end_date)',
    'CREATE INDEX idx_budgets_type ON budgets(type)',
    'CREATE INDEX idx_budgets_synced ON budgets(is_synced)',
  ];
}

/// Data class for budget table operations
/// Provides type-safe access to budget data
class Budget {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final String type;
  final int targetAmount;
  final String currency;
  final String period;
  final DateTime startDate;
  final DateTime endDate;
  final String? categories;
  final int spentAmount;
  final bool enableNotifications;
  final int warningThreshold;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final bool isSynced;

  Budget({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.type,
    required this.targetAmount,
    required this.currency,
    required this.period,
    required this.startDate,
    required this.endDate,
    this.categories,
    required this.spentAmount,
    required this.enableNotifications,
    required this.warningThreshold,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
    required this.isSynced,
  });

  /// Create budget from database row
  factory Budget.fromData(Map<String, dynamic> data) {
    return Budget(
      id: data['id'] as String,
      userId: data['user_id'] as String,
      name: data['name'] as String,
      description: data['description'] as String?,
      type: data['type'] as String,
      targetAmount: data['target_amount'] as int,
      currency: data['currency'] as String,
      period: data['period'] as String,
      startDate: data['start_date'] as DateTime,
      endDate: data['end_date'] as DateTime,
      categories: data['categories'] as String?,
      spentAmount: data['spent_amount'] as int,
      enableNotifications: data['enable_notifications'] as bool,
      warningThreshold: data['warning_threshold'] as int,
      createdAt: data['created_at'] as DateTime,
      updatedAt: data['updated_at'] as DateTime,
      isActive: data['is_active'] as bool,
      isSynced: data['is_synced'] as bool,
    );
  }

  /// Calculate remaining amount
  int get remainingAmount => targetAmount - spentAmount;

  /// Calculate utilization percentage
  double get utilizationPercentage {
    if (targetAmount == 0) return 0.0;
    return (spentAmount / targetAmount) * 100;
  }

  /// Check if budget is over limit
  bool get isOverBudget => spentAmount > targetAmount;

  /// Check if budget is approaching warning threshold
  bool get isNearLimit => utilizationPercentage >= warningThreshold;

  /// Get budget status
  String get status {
    if (isOverBudget) return 'over_budget';
    if (isNearLimit) return 'warning';
    return 'on_track';
  }

  /// Check if budget is currently active
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
}
