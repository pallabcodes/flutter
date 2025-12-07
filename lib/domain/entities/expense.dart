import 'package:equatable/equatable.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/material.dart';

part 'expense.freezed.dart';
part 'expense.g.dart';

/// Core expense entity representing a financial transaction
/// Implements Equatable for value comparison and Freezed for immutability
@freezed
class Expense with _$Expense {
  const factory Expense({
    /// Unique identifier for the expense
    required String id,

    /// User ID who created this expense
    required String userId,

    /// Expense amount in the smallest currency unit (e.g., cents for USD)
    required int amount,

    /// Three-letter currency code (ISO 4217)
    @Default('USD') String currency,

    /// Expense description/title
    required String description,

    /// Category this expense belongs to
    required ExpenseCategory category,

    /// Date and time when the expense occurred
    required DateTime date,

    /// Optional payment method used
    PaymentMethod? paymentMethod,

    /// Optional tags for additional categorization
    @Default([]) List<String> tags,

    /// Optional receipt image URL
    String? receiptUrl,

    /// Optional location where expense occurred
    ExpenseLocation? location,

    /// Whether this expense is recurring
    @Default(false) bool isRecurring,

    /// Recurring expense configuration
    RecurringConfig? recurringConfig,

    /// Creation timestamp
    required DateTime createdAt,

    /// Last modification timestamp
    required DateTime updatedAt,

    /// Whether this expense is synced with remote server
    @Default(false) bool isSynced,

    /// Optional note for additional details
    String? note,
  }) = _Expense;

  const Expense._();

  /// Create expense from JSON
  factory Expense.fromJson(Map<String, dynamic> json) =>
      _$ExpenseFromJson(json);

  /// Get formatted amount with currency symbol
  String get formattedAmount {
    final amountInDollars = amount / 100;
    return '\$${amountInDollars.toStringAsFixed(2)}';
  }

  /// Check if expense is from today
  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
           date.month == now.month &&
           date.day == now.day;
  }

  /// Check if expense is from this week
  bool get isThisWeek {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    return date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
           date.isBefore(endOfWeek.add(const Duration(days: 1)));
  }

  /// Check if expense is from this month
  bool get isThisMonth {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  /// Create a copy with updated sync status
  Expense markAsSynced() => copyWith(isSynced: true);

  /// Create a copy with updated timestamp
  Expense updateTimestamp() => copyWith(updatedAt: DateTime.now());
}

/// Expense category enumeration with icons and colors
enum ExpenseCategory {
  food('Food & Dining', '🍽️', 0xFF4CAF50),
  transportation('Transportation', '🚗', 0xFF2196F3),
  shopping('Shopping', '🛍️', 0xFF9C27B0),
  entertainment('Entertainment', '🎬', 0xFFFF9800),
  bills('Bills & Utilities', '💡', 0xFF795548),
  healthcare('Healthcare', '🏥', 0xFFE91E63),
  education('Education', '📚', 0xFF3F51B5),
  travel('Travel', '✈️', 0xFF009688),
  personal('Personal Care', '💅', 0xFF607D8B),
  other('Other', '📦', 0xFF9E9E9E);

  const ExpenseCategory(this.displayName, this.icon, this.color);

  final String displayName;
  final String icon;
  final int color;

  /// Get color as Color object
  Color get colorValue => Color(color);
}

/// Payment method enumeration
enum PaymentMethod {
  cash('Cash'),
  creditCard('Credit Card'),
  debitCard('Debit Card'),
  bankTransfer('Bank Transfer'),
  digitalWallet('Digital Wallet'),
  check('Check'),
  other('Other');

  const PaymentMethod(this.displayName);

  final String displayName;
}

/// Geographic location data for expenses
@freezed
class ExpenseLocation with _$ExpenseLocation {
  const factory ExpenseLocation({
    required double latitude,
    required double longitude,
    String? address,
    String? placeName,
  }) = _ExpenseLocation;

  factory ExpenseLocation.fromJson(Map<String, dynamic> json) =>
      _$ExpenseLocationFromJson(json);
}

/// Configuration for recurring expenses
@freezed
class RecurringConfig with _$RecurringConfig {
  const factory RecurringConfig({
    /// Recurring frequency
    required RecurringFrequency frequency,

    /// How often the expense recurs (e.g., every 2 weeks)
    @Default(1) int interval,

    /// End date for recurring expense (null means indefinite)
    DateTime? endDate,

    /// Next occurrence date
    required DateTime nextOccurrence,
  }) = _RecurringConfig;

  factory RecurringConfig.fromJson(Map<String, dynamic> json) =>
      _$RecurringConfigFromJson(json);
}

/// Recurring frequency options
enum RecurringFrequency {
  daily('Daily'),
  weekly('Weekly'),
  biWeekly('Bi-weekly'),
  monthly('Monthly'),
  quarterly('Quarterly'),
  yearly('Yearly');

  const RecurringFrequency(this.displayName);

  final String displayName;

  /// Calculate next occurrence based on current date and interval
  DateTime getNextOccurrence(DateTime from, int interval) {
    switch (this) {
      case RecurringFrequency.daily:
        return from.add(Duration(days: interval));
      case RecurringFrequency.weekly:
        return from.add(Duration(days: 7 * interval));
      case RecurringFrequency.biWeekly:
        return from.add(Duration(days: 14 * interval));
      case RecurringFrequency.monthly:
        return DateTime(from.year, from.month + interval, from.day);
      case RecurringFrequency.quarterly:
        return DateTime(from.year, from.month + (3 * interval), from.day);
      case RecurringFrequency.yearly:
        return DateTime(from.year + interval, from.month, from.day);
    }
  }
}
