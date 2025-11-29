import 'package:drift/drift.dart';

/// Expenses table definition
/// Represents the local storage schema for expense entities
class Expenses extends Table {
  /// Unique identifier for the expense
  TextColumn get id => text()();

  /// User ID who created this expense
  TextColumn get userId => text()();

  /// Expense amount in smallest currency unit (cents for USD)
  IntColumn get amount => integer()();

  /// Three-letter currency code (ISO 4217)
  TextColumn get currency => text().withDefault(const Constant('USD'))();

  /// Expense description/title
  TextColumn get description => text()();

  /// Category this expense belongs to
  TextColumn get category => text()();

  /// Date and time when the expense occurred
  DateTimeColumn get date => dateTime()();

  /// Optional payment method used
  TextColumn get paymentMethod => text().nullable()();

  /// Optional tags for additional categorization (stored as JSON)
  TextColumn get tags => text().nullable()();

  /// Optional receipt image URL or local path
  TextColumn get receiptUrl => text().nullable()();

  /// Optional location latitude
  RealColumn get latitude => real().nullable()();

  /// Optional location longitude
  RealColumn get longitude => real().nullable()();

  /// Optional location address
  TextColumn get address => text().nullable()();

  /// Optional location place name
  TextColumn get placeName => text().nullable()();

  /// Whether this expense is recurring
  BoolColumn get isRecurring => boolean().withDefault(const Constant(false))();

  /// Recurring frequency (daily, weekly, monthly, etc.)
  TextColumn get recurringFrequency => text().nullable()();

  /// Recurring interval (every N days/weeks/months)
  IntColumn get recurringInterval => integer().nullable()();

  /// Recurring end date
  DateTimeColumn get recurringEndDate => dateTime().nullable()();

  /// Next occurrence date for recurring expenses
  DateTimeColumn get nextOccurrence => dateTime().nullable()();

  /// Creation timestamp
  DateTimeColumn get createdAt => dateTime()();

  /// Last modification timestamp
  DateTimeColumn get updatedAt => dateTime()();

  /// Whether this expense is synced with remote server
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  /// Optional note for additional details
  TextColumn get note => text().nullable()();

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
    'CREATE INDEX idx_expenses_user_date ON expenses(user_id, date)',
    'CREATE INDEX idx_expenses_user_category ON expenses(user_id, category)',
    'CREATE INDEX idx_expenses_user_amount ON expenses(user_id, amount)',
    'CREATE INDEX idx_expenses_date ON expenses(date)',
    'CREATE INDEX idx_expenses_synced ON expenses(is_synced)',
  ];
}

/// Data class for expense table operations
/// Provides type-safe access to expense data
class Expense {
  final String id;
  final String userId;
  final int amount;
  final String currency;
  final String description;
  final String category;
  final DateTime date;
  final String? paymentMethod;
  final String? tags;
  final String? receiptUrl;
  final double? latitude;
  final double? longitude;
  final String? address;
  final String? placeName;
  final bool isRecurring;
  final String? recurringFrequency;
  final int? recurringInterval;
  final DateTime? recurringEndDate;
  final DateTime? nextOccurrence;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;
  final String? note;

  Expense({
    required this.id,
    required this.userId,
    required this.amount,
    required this.currency,
    required this.description,
    required this.category,
    required this.date,
    this.paymentMethod,
    this.tags,
    this.receiptUrl,
    this.latitude,
    this.longitude,
    this.address,
    this.placeName,
    required this.isRecurring,
    this.recurringFrequency,
    this.recurringInterval,
    this.recurringEndDate,
    this.nextOccurrence,
    required this.createdAt,
    required this.updatedAt,
    required this.isSynced,
    this.note,
  });

  /// Create expense from database row
  factory Expense.fromData(Map<String, dynamic> data) {
    return Expense(
      id: data['id'] as String,
      userId: data['user_id'] as String,
      amount: data['amount'] as int,
      currency: data['currency'] as String,
      description: data['description'] as String,
      category: data['category'] as String,
      date: data['date'] as DateTime,
      paymentMethod: data['payment_method'] as String?,
      tags: data['tags'] as String?,
      receiptUrl: data['receipt_url'] as String?,
      latitude: data['latitude'] as double?,
      longitude: data['longitude'] as double?,
      address: data['address'] as String?,
      placeName: data['place_name'] as String?,
      isRecurring: data['is_recurring'] as bool,
      recurringFrequency: data['recurring_frequency'] as String?,
      recurringInterval: data['recurring_interval'] as int?,
      recurringEndDate: data['recurring_end_date'] as DateTime?,
      nextOccurrence: data['next_occurrence'] as DateTime?,
      createdAt: data['created_at'] as DateTime,
      updatedAt: data['updated_at'] as DateTime,
      isSynced: data['is_synced'] as bool,
      note: data['note'] as String?,
    );
  }
}
