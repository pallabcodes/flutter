// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'expense_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ExpenseModel _$ExpenseModelFromJson(Map<String, dynamic> json) {
  return _ExpenseModel.fromJson(json);
}

/// @nodoc
mixin _$ExpenseModel {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  int get amount => throw _privateConstructorUsedError;
  String get currency => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  String get category => throw _privateConstructorUsedError;
  DateTime get date => throw _privateConstructorUsedError;
  String? get paymentMethod => throw _privateConstructorUsedError;
  List<String>? get tags => throw _privateConstructorUsedError;
  String? get receiptUrl => throw _privateConstructorUsedError;
  double? get latitude => throw _privateConstructorUsedError;
  double? get longitude => throw _privateConstructorUsedError;
  String? get address => throw _privateConstructorUsedError;
  String? get placeName => throw _privateConstructorUsedError;
  bool get isRecurring => throw _privateConstructorUsedError;
  String? get recurringFrequency => throw _privateConstructorUsedError;
  int? get recurringInterval => throw _privateConstructorUsedError;
  DateTime? get recurringEndDate => throw _privateConstructorUsedError;
  DateTime? get nextOccurrence => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;
  bool get isSynced => throw _privateConstructorUsedError;
  String? get note => throw _privateConstructorUsedError;

  /// Serializes this ExpenseModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ExpenseModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ExpenseModelCopyWith<ExpenseModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ExpenseModelCopyWith<$Res> {
  factory $ExpenseModelCopyWith(
          ExpenseModel value, $Res Function(ExpenseModel) then) =
      _$ExpenseModelCopyWithImpl<$Res, ExpenseModel>;
  @useResult
  $Res call(
      {String id,
      String userId,
      int amount,
      String currency,
      String description,
      String category,
      DateTime date,
      String? paymentMethod,
      List<String>? tags,
      String? receiptUrl,
      double? latitude,
      double? longitude,
      String? address,
      String? placeName,
      bool isRecurring,
      String? recurringFrequency,
      int? recurringInterval,
      DateTime? recurringEndDate,
      DateTime? nextOccurrence,
      DateTime createdAt,
      DateTime updatedAt,
      bool isSynced,
      String? note});
}

/// @nodoc
class _$ExpenseModelCopyWithImpl<$Res, $Val extends ExpenseModel>
    implements $ExpenseModelCopyWith<$Res> {
  _$ExpenseModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ExpenseModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? amount = null,
    Object? currency = null,
    Object? description = null,
    Object? category = null,
    Object? date = null,
    Object? paymentMethod = freezed,
    Object? tags = freezed,
    Object? receiptUrl = freezed,
    Object? latitude = freezed,
    Object? longitude = freezed,
    Object? address = freezed,
    Object? placeName = freezed,
    Object? isRecurring = null,
    Object? recurringFrequency = freezed,
    Object? recurringInterval = freezed,
    Object? recurringEndDate = freezed,
    Object? nextOccurrence = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? isSynced = null,
    Object? note = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as int,
      currency: null == currency
          ? _value.currency
          : currency // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      paymentMethod: freezed == paymentMethod
          ? _value.paymentMethod
          : paymentMethod // ignore: cast_nullable_to_non_nullable
              as String?,
      tags: freezed == tags
          ? _value.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      receiptUrl: freezed == receiptUrl
          ? _value.receiptUrl
          : receiptUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      latitude: freezed == latitude
          ? _value.latitude
          : latitude // ignore: cast_nullable_to_non_nullable
              as double?,
      longitude: freezed == longitude
          ? _value.longitude
          : longitude // ignore: cast_nullable_to_non_nullable
              as double?,
      address: freezed == address
          ? _value.address
          : address // ignore: cast_nullable_to_non_nullable
              as String?,
      placeName: freezed == placeName
          ? _value.placeName
          : placeName // ignore: cast_nullable_to_non_nullable
              as String?,
      isRecurring: null == isRecurring
          ? _value.isRecurring
          : isRecurring // ignore: cast_nullable_to_non_nullable
              as bool,
      recurringFrequency: freezed == recurringFrequency
          ? _value.recurringFrequency
          : recurringFrequency // ignore: cast_nullable_to_non_nullable
              as String?,
      recurringInterval: freezed == recurringInterval
          ? _value.recurringInterval
          : recurringInterval // ignore: cast_nullable_to_non_nullable
              as int?,
      recurringEndDate: freezed == recurringEndDate
          ? _value.recurringEndDate
          : recurringEndDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      nextOccurrence: freezed == nextOccurrence
          ? _value.nextOccurrence
          : nextOccurrence // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isSynced: null == isSynced
          ? _value.isSynced
          : isSynced // ignore: cast_nullable_to_non_nullable
              as bool,
      note: freezed == note
          ? _value.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ExpenseModelImplCopyWith<$Res>
    implements $ExpenseModelCopyWith<$Res> {
  factory _$$ExpenseModelImplCopyWith(
          _$ExpenseModelImpl value, $Res Function(_$ExpenseModelImpl) then) =
      __$$ExpenseModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String userId,
      int amount,
      String currency,
      String description,
      String category,
      DateTime date,
      String? paymentMethod,
      List<String>? tags,
      String? receiptUrl,
      double? latitude,
      double? longitude,
      String? address,
      String? placeName,
      bool isRecurring,
      String? recurringFrequency,
      int? recurringInterval,
      DateTime? recurringEndDate,
      DateTime? nextOccurrence,
      DateTime createdAt,
      DateTime updatedAt,
      bool isSynced,
      String? note});
}

/// @nodoc
class __$$ExpenseModelImplCopyWithImpl<$Res>
    extends _$ExpenseModelCopyWithImpl<$Res, _$ExpenseModelImpl>
    implements _$$ExpenseModelImplCopyWith<$Res> {
  __$$ExpenseModelImplCopyWithImpl(
      _$ExpenseModelImpl _value, $Res Function(_$ExpenseModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of ExpenseModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? amount = null,
    Object? currency = null,
    Object? description = null,
    Object? category = null,
    Object? date = null,
    Object? paymentMethod = freezed,
    Object? tags = freezed,
    Object? receiptUrl = freezed,
    Object? latitude = freezed,
    Object? longitude = freezed,
    Object? address = freezed,
    Object? placeName = freezed,
    Object? isRecurring = null,
    Object? recurringFrequency = freezed,
    Object? recurringInterval = freezed,
    Object? recurringEndDate = freezed,
    Object? nextOccurrence = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? isSynced = null,
    Object? note = freezed,
  }) {
    return _then(_$ExpenseModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as int,
      currency: null == currency
          ? _value.currency
          : currency // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      paymentMethod: freezed == paymentMethod
          ? _value.paymentMethod
          : paymentMethod // ignore: cast_nullable_to_non_nullable
              as String?,
      tags: freezed == tags
          ? _value._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      receiptUrl: freezed == receiptUrl
          ? _value.receiptUrl
          : receiptUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      latitude: freezed == latitude
          ? _value.latitude
          : latitude // ignore: cast_nullable_to_non_nullable
              as double?,
      longitude: freezed == longitude
          ? _value.longitude
          : longitude // ignore: cast_nullable_to_non_nullable
              as double?,
      address: freezed == address
          ? _value.address
          : address // ignore: cast_nullable_to_non_nullable
              as String?,
      placeName: freezed == placeName
          ? _value.placeName
          : placeName // ignore: cast_nullable_to_non_nullable
              as String?,
      isRecurring: null == isRecurring
          ? _value.isRecurring
          : isRecurring // ignore: cast_nullable_to_non_nullable
              as bool,
      recurringFrequency: freezed == recurringFrequency
          ? _value.recurringFrequency
          : recurringFrequency // ignore: cast_nullable_to_non_nullable
              as String?,
      recurringInterval: freezed == recurringInterval
          ? _value.recurringInterval
          : recurringInterval // ignore: cast_nullable_to_non_nullable
              as int?,
      recurringEndDate: freezed == recurringEndDate
          ? _value.recurringEndDate
          : recurringEndDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      nextOccurrence: freezed == nextOccurrence
          ? _value.nextOccurrence
          : nextOccurrence // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isSynced: null == isSynced
          ? _value.isSynced
          : isSynced // ignore: cast_nullable_to_non_nullable
              as bool,
      note: freezed == note
          ? _value.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ExpenseModelImpl implements _ExpenseModel {
  const _$ExpenseModelImpl(
      {required this.id,
      required this.userId,
      required this.amount,
      this.currency = 'USD',
      required this.description,
      required this.category,
      required this.date,
      this.paymentMethod,
      final List<String>? tags,
      this.receiptUrl,
      this.latitude,
      this.longitude,
      this.address,
      this.placeName,
      this.isRecurring = false,
      this.recurringFrequency,
      this.recurringInterval,
      this.recurringEndDate,
      this.nextOccurrence,
      required this.createdAt,
      required this.updatedAt,
      this.isSynced = false,
      this.note})
      : _tags = tags;

  factory _$ExpenseModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$ExpenseModelImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final int amount;
  @override
  @JsonKey()
  final String currency;
  @override
  final String description;
  @override
  final String category;
  @override
  final DateTime date;
  @override
  final String? paymentMethod;
  final List<String>? _tags;
  @override
  List<String>? get tags {
    final value = _tags;
    if (value == null) return null;
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final String? receiptUrl;
  @override
  final double? latitude;
  @override
  final double? longitude;
  @override
  final String? address;
  @override
  final String? placeName;
  @override
  @JsonKey()
  final bool isRecurring;
  @override
  final String? recurringFrequency;
  @override
  final int? recurringInterval;
  @override
  final DateTime? recurringEndDate;
  @override
  final DateTime? nextOccurrence;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  @JsonKey()
  final bool isSynced;
  @override
  final String? note;

  @override
  String toString() {
    return 'ExpenseModel(id: $id, userId: $userId, amount: $amount, currency: $currency, description: $description, category: $category, date: $date, paymentMethod: $paymentMethod, tags: $tags, receiptUrl: $receiptUrl, latitude: $latitude, longitude: $longitude, address: $address, placeName: $placeName, isRecurring: $isRecurring, recurringFrequency: $recurringFrequency, recurringInterval: $recurringInterval, recurringEndDate: $recurringEndDate, nextOccurrence: $nextOccurrence, createdAt: $createdAt, updatedAt: $updatedAt, isSynced: $isSynced, note: $note)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ExpenseModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.currency, currency) ||
                other.currency == currency) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.paymentMethod, paymentMethod) ||
                other.paymentMethod == paymentMethod) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            (identical(other.receiptUrl, receiptUrl) ||
                other.receiptUrl == receiptUrl) &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude) &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.placeName, placeName) ||
                other.placeName == placeName) &&
            (identical(other.isRecurring, isRecurring) ||
                other.isRecurring == isRecurring) &&
            (identical(other.recurringFrequency, recurringFrequency) ||
                other.recurringFrequency == recurringFrequency) &&
            (identical(other.recurringInterval, recurringInterval) ||
                other.recurringInterval == recurringInterval) &&
            (identical(other.recurringEndDate, recurringEndDate) ||
                other.recurringEndDate == recurringEndDate) &&
            (identical(other.nextOccurrence, nextOccurrence) ||
                other.nextOccurrence == nextOccurrence) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.isSynced, isSynced) ||
                other.isSynced == isSynced) &&
            (identical(other.note, note) || other.note == note));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        userId,
        amount,
        currency,
        description,
        category,
        date,
        paymentMethod,
        const DeepCollectionEquality().hash(_tags),
        receiptUrl,
        latitude,
        longitude,
        address,
        placeName,
        isRecurring,
        recurringFrequency,
        recurringInterval,
        recurringEndDate,
        nextOccurrence,
        createdAt,
        updatedAt,
        isSynced,
        note
      ]);

  /// Create a copy of ExpenseModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ExpenseModelImplCopyWith<_$ExpenseModelImpl> get copyWith =>
      __$$ExpenseModelImplCopyWithImpl<_$ExpenseModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ExpenseModelImplToJson(
      this,
    );
  }
}

abstract class _ExpenseModel implements ExpenseModel {
  const factory _ExpenseModel(
      {required final String id,
      required final String userId,
      required final int amount,
      final String currency,
      required final String description,
      required final String category,
      required final DateTime date,
      final String? paymentMethod,
      final List<String>? tags,
      final String? receiptUrl,
      final double? latitude,
      final double? longitude,
      final String? address,
      final String? placeName,
      final bool isRecurring,
      final String? recurringFrequency,
      final int? recurringInterval,
      final DateTime? recurringEndDate,
      final DateTime? nextOccurrence,
      required final DateTime createdAt,
      required final DateTime updatedAt,
      final bool isSynced,
      final String? note}) = _$ExpenseModelImpl;

  factory _ExpenseModel.fromJson(Map<String, dynamic> json) =
      _$ExpenseModelImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  int get amount;
  @override
  String get currency;
  @override
  String get description;
  @override
  String get category;
  @override
  DateTime get date;
  @override
  String? get paymentMethod;
  @override
  List<String>? get tags;
  @override
  String? get receiptUrl;
  @override
  double? get latitude;
  @override
  double? get longitude;
  @override
  String? get address;
  @override
  String? get placeName;
  @override
  bool get isRecurring;
  @override
  String? get recurringFrequency;
  @override
  int? get recurringInterval;
  @override
  DateTime? get recurringEndDate;
  @override
  DateTime? get nextOccurrence;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;
  @override
  bool get isSynced;
  @override
  String? get note;

  /// Create a copy of ExpenseModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ExpenseModelImplCopyWith<_$ExpenseModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
