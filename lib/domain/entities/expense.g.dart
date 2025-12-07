// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ExpenseImpl _$$ExpenseImplFromJson(Map<String, dynamic> json) =>
    _$ExpenseImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      amount: (json['amount'] as num).toInt(),
      currency: json['currency'] as String? ?? 'USD',
      description: json['description'] as String,
      category: $enumDecode(_$ExpenseCategoryEnumMap, json['category']),
      date: DateTime.parse(json['date'] as String),
      paymentMethod:
          $enumDecodeNullable(_$PaymentMethodEnumMap, json['paymentMethod']),
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      receiptUrl: json['receiptUrl'] as String?,
      location: json['location'] == null
          ? null
          : ExpenseLocation.fromJson(json['location'] as Map<String, dynamic>),
      isRecurring: json['isRecurring'] as bool? ?? false,
      recurringConfig: json['recurringConfig'] == null
          ? null
          : RecurringConfig.fromJson(
              json['recurringConfig'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isSynced: json['isSynced'] as bool? ?? false,
      note: json['note'] as String?,
    );

Map<String, dynamic> _$$ExpenseImplToJson(_$ExpenseImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'amount': instance.amount,
      'currency': instance.currency,
      'description': instance.description,
      'category': _$ExpenseCategoryEnumMap[instance.category]!,
      'date': instance.date.toIso8601String(),
      'paymentMethod': _$PaymentMethodEnumMap[instance.paymentMethod],
      'tags': instance.tags,
      'receiptUrl': instance.receiptUrl,
      'location': instance.location,
      'isRecurring': instance.isRecurring,
      'recurringConfig': instance.recurringConfig,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'isSynced': instance.isSynced,
      'note': instance.note,
    };

const _$ExpenseCategoryEnumMap = {
  ExpenseCategory.food: 'food',
  ExpenseCategory.transportation: 'transportation',
  ExpenseCategory.shopping: 'shopping',
  ExpenseCategory.entertainment: 'entertainment',
  ExpenseCategory.bills: 'bills',
  ExpenseCategory.healthcare: 'healthcare',
  ExpenseCategory.education: 'education',
  ExpenseCategory.travel: 'travel',
  ExpenseCategory.personal: 'personal',
  ExpenseCategory.other: 'other',
};

const _$PaymentMethodEnumMap = {
  PaymentMethod.cash: 'cash',
  PaymentMethod.creditCard: 'creditCard',
  PaymentMethod.debitCard: 'debitCard',
  PaymentMethod.bankTransfer: 'bankTransfer',
  PaymentMethod.digitalWallet: 'digitalWallet',
  PaymentMethod.check: 'check',
  PaymentMethod.other: 'other',
};

_$ExpenseLocationImpl _$$ExpenseLocationImplFromJson(
        Map<String, dynamic> json) =>
    _$ExpenseLocationImpl(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String?,
      placeName: json['placeName'] as String?,
    );

Map<String, dynamic> _$$ExpenseLocationImplToJson(
        _$ExpenseLocationImpl instance) =>
    <String, dynamic>{
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'address': instance.address,
      'placeName': instance.placeName,
    };

_$RecurringConfigImpl _$$RecurringConfigImplFromJson(
        Map<String, dynamic> json) =>
    _$RecurringConfigImpl(
      frequency: $enumDecode(_$RecurringFrequencyEnumMap, json['frequency']),
      interval: (json['interval'] as num?)?.toInt() ?? 1,
      endDate: json['endDate'] == null
          ? null
          : DateTime.parse(json['endDate'] as String),
      nextOccurrence: DateTime.parse(json['nextOccurrence'] as String),
    );

Map<String, dynamic> _$$RecurringConfigImplToJson(
        _$RecurringConfigImpl instance) =>
    <String, dynamic>{
      'frequency': _$RecurringFrequencyEnumMap[instance.frequency]!,
      'interval': instance.interval,
      'endDate': instance.endDate?.toIso8601String(),
      'nextOccurrence': instance.nextOccurrence.toIso8601String(),
    };

const _$RecurringFrequencyEnumMap = {
  RecurringFrequency.daily: 'daily',
  RecurringFrequency.weekly: 'weekly',
  RecurringFrequency.biWeekly: 'biWeekly',
  RecurringFrequency.monthly: 'monthly',
  RecurringFrequency.quarterly: 'quarterly',
  RecurringFrequency.yearly: 'yearly',
};
