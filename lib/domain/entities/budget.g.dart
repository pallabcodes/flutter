// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'budget.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BudgetImpl _$$BudgetImplFromJson(Map<String, dynamic> json) => _$BudgetImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      type: $enumDecodeNullable(_$BudgetTypeEnumMap, json['type']) ??
          BudgetType.category,
      targetAmount: (json['targetAmount'] as num).toInt(),
      currency: json['currency'] as String? ?? 'USD',
      period: $enumDecode(_$BudgetPeriodEnumMap, json['period']),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      categories: (json['categories'] as List<dynamic>?)
              ?.map((e) => $enumDecode(_$ExpenseCategoryEnumMap, e))
              .toList() ??
          const [],
      spentAmount: (json['spentAmount'] as num?)?.toInt() ?? 0,
      enableNotifications: json['enableNotifications'] as bool? ?? true,
      warningThreshold: (json['warningThreshold'] as num?)?.toInt() ?? 80,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isActive: json['isActive'] as bool? ?? true,
      isSynced: json['isSynced'] as bool? ?? false,
    );

Map<String, dynamic> _$$BudgetImplToJson(_$BudgetImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'name': instance.name,
      'description': instance.description,
      'type': _$BudgetTypeEnumMap[instance.type]!,
      'targetAmount': instance.targetAmount,
      'currency': instance.currency,
      'period': _$BudgetPeriodEnumMap[instance.period]!,
      'startDate': instance.startDate.toIso8601String(),
      'endDate': instance.endDate.toIso8601String(),
      'categories':
          instance.categories.map((e) => _$ExpenseCategoryEnumMap[e]!).toList(),
      'spentAmount': instance.spentAmount,
      'enableNotifications': instance.enableNotifications,
      'warningThreshold': instance.warningThreshold,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'isActive': instance.isActive,
      'isSynced': instance.isSynced,
    };

const _$BudgetTypeEnumMap = {
  BudgetType.category: 'category',
  BudgetType.overall: 'overall',
};

const _$BudgetPeriodEnumMap = {
  BudgetPeriod.weekly: 'weekly',
  BudgetPeriod.monthly: 'monthly',
  BudgetPeriod.quarterly: 'quarterly',
  BudgetPeriod.yearly: 'yearly',
  BudgetPeriod.custom: 'custom',
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
