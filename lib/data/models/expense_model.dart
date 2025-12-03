import 'package:finwise/domain/entities/expense.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'expense_model.freezed.dart';
part 'expense_model.g.dart';

/// API model for expense data
/// Used for JSON serialization/deserialization with remote APIs
@freezed
class ExpenseModel with _$ExpenseModel {
  const factory ExpenseModel({
    required String id,
    required String userId,
    required int amount,
    @Default('USD') String currency,
    required String description,
    required String category,
    required DateTime date,
    String? paymentMethod,
    List<String>? tags,
    String? receiptUrl,
    double? latitude,
    double? longitude,
    String? address,
    String? placeName,
    @Default(false) bool isRecurring,
    String? recurringFrequency,
    int? recurringInterval,
    DateTime? recurringEndDate,
    DateTime? nextOccurrence,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(false) bool isSynced,
    String? note,
  }) = _ExpenseModel;

  factory ExpenseModel.fromJson(Map<String, dynamic> json) =>
      _$ExpenseModelFromJson(json);

  /// Convert domain entity to API model
  factory ExpenseModel.fromEntity(Expense expense) {
    return ExpenseModel(
      id: expense.id,
      userId: expense.userId,
      amount: expense.amount,
      currency: expense.currency,
      description: expense.description,
      category: expense.category.name,
      date: expense.date,
      paymentMethod: expense.paymentMethod?.name,
      tags: expense.tags,
      receiptUrl: expense.receiptUrl,
      latitude: expense.location?.latitude,
      longitude: expense.location?.longitude,
      address: expense.location?.address,
      placeName: expense.location?.placeName,
      isRecurring: expense.isRecurring,
      recurringFrequency: expense.recurringConfig?.frequency.name,
      recurringInterval: expense.recurringConfig?.interval,
      recurringEndDate: expense.recurringConfig?.endDate,
      nextOccurrence: expense.recurringConfig?.nextOccurrence,
      createdAt: expense.createdAt,
      updatedAt: expense.updatedAt,
      isSynced: expense.isSynced,
      note: expense.note,
    );
  }
}

/// Extension methods for model conversion
extension ExpenseModelX on ExpenseModel {
  /// Convert API model to domain entity
  Expense toEntity() {
    return Expense(
      id: id,
      userId: userId,
      amount: amount,
      currency: currency,
      description: description,
      category: ExpenseCategory.values.firstWhere(
        (c) => c.name == category,
        orElse: () => ExpenseCategory.other,
      ),
      date: date,
      paymentMethod: paymentMethod != null
          ? PaymentMethod.values.firstWhere(
              (p) => p.name == paymentMethod,
              orElse: () => PaymentMethod.other,
            )
          : null,
      tags: tags,
      receiptUrl: receiptUrl,
      location: latitude != null && longitude != null
          ? ExpenseLocation(
              latitude: latitude!,
              longitude: longitude!,
              address: address,
              placeName: placeName,
            )
          : null,
      isRecurring: isRecurring,
      recurringConfig: recurringFrequency != null
          ? RecurringConfig(
              frequency: RecurringFrequency.values.firstWhere(
                (f) => f.name == recurringFrequency,
                orElse: () => RecurringFrequency.monthly,
              ),
              interval: recurringInterval ?? 1,
              endDate: recurringEndDate,
              nextOccurrence: nextOccurrence,
            )
          : null,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isSynced: isSynced,
      note: note,
    );
  }
}
