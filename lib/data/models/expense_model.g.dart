// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ExpenseModelImpl _$$ExpenseModelImplFromJson(Map<String, dynamic> json) =>
    _$ExpenseModelImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      amount: (json['amount'] as num).toInt(),
      currency: json['currency'] as String? ?? 'USD',
      description: json['description'] as String,
      category: json['category'] as String,
      date: DateTime.parse(json['date'] as String),
      paymentMethod: json['paymentMethod'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
      receiptUrl: json['receiptUrl'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      address: json['address'] as String?,
      placeName: json['placeName'] as String?,
      isRecurring: json['isRecurring'] as bool? ?? false,
      recurringFrequency: json['recurringFrequency'] as String?,
      recurringInterval: (json['recurringInterval'] as num?)?.toInt(),
      recurringEndDate: json['recurringEndDate'] == null
          ? null
          : DateTime.parse(json['recurringEndDate'] as String),
      nextOccurrence: json['nextOccurrence'] == null
          ? null
          : DateTime.parse(json['nextOccurrence'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isSynced: json['isSynced'] as bool? ?? false,
      note: json['note'] as String?,
    );

Map<String, dynamic> _$$ExpenseModelImplToJson(_$ExpenseModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'amount': instance.amount,
      'currency': instance.currency,
      'description': instance.description,
      'category': instance.category,
      'date': instance.date.toIso8601String(),
      'paymentMethod': instance.paymentMethod,
      'tags': instance.tags,
      'receiptUrl': instance.receiptUrl,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'address': instance.address,
      'placeName': instance.placeName,
      'isRecurring': instance.isRecurring,
      'recurringFrequency': instance.recurringFrequency,
      'recurringInterval': instance.recurringInterval,
      'recurringEndDate': instance.recurringEndDate?.toIso8601String(),
      'nextOccurrence': instance.nextOccurrence?.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'isSynced': instance.isSynced,
      'note': instance.note,
    };
