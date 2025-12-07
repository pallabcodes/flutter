// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'expense.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Expense _$ExpenseFromJson(Map<String, dynamic> json) {
  return _Expense.fromJson(json);
}

/// @nodoc
mixin _$Expense {
  /// Unique identifier for the expense
  String get id => throw _privateConstructorUsedError;

  /// User ID who created this expense
  String get userId => throw _privateConstructorUsedError;

  /// Expense amount in the smallest currency unit (e.g., cents for USD)
  int get amount => throw _privateConstructorUsedError;

  /// Three-letter currency code (ISO 4217)
  String get currency => throw _privateConstructorUsedError;

  /// Expense description/title
  String get description => throw _privateConstructorUsedError;

  /// Category this expense belongs to
  ExpenseCategory get category => throw _privateConstructorUsedError;

  /// Date and time when the expense occurred
  DateTime get date => throw _privateConstructorUsedError;

  /// Optional payment method used
  PaymentMethod? get paymentMethod => throw _privateConstructorUsedError;

  /// Optional tags for additional categorization
  List<String> get tags => throw _privateConstructorUsedError;

  /// Optional receipt image URL
  String? get receiptUrl => throw _privateConstructorUsedError;

  /// Optional location where expense occurred
  ExpenseLocation? get location => throw _privateConstructorUsedError;

  /// Whether this expense is recurring
  bool get isRecurring => throw _privateConstructorUsedError;

  /// Recurring expense configuration
  RecurringConfig? get recurringConfig => throw _privateConstructorUsedError;

  /// Creation timestamp
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Last modification timestamp
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Whether this expense is synced with remote server
  bool get isSynced => throw _privateConstructorUsedError;

  /// Optional note for additional details
  String? get note => throw _privateConstructorUsedError;

  /// Serializes this Expense to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Expense
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ExpenseCopyWith<Expense> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ExpenseCopyWith<$Res> {
  factory $ExpenseCopyWith(Expense value, $Res Function(Expense) then) =
      _$ExpenseCopyWithImpl<$Res, Expense>;
  @useResult
  $Res call(
      {String id,
      String userId,
      int amount,
      String currency,
      String description,
      ExpenseCategory category,
      DateTime date,
      PaymentMethod? paymentMethod,
      List<String> tags,
      String? receiptUrl,
      ExpenseLocation? location,
      bool isRecurring,
      RecurringConfig? recurringConfig,
      DateTime createdAt,
      DateTime updatedAt,
      bool isSynced,
      String? note});

  $ExpenseLocationCopyWith<$Res>? get location;
  $RecurringConfigCopyWith<$Res>? get recurringConfig;
}

/// @nodoc
class _$ExpenseCopyWithImpl<$Res, $Val extends Expense>
    implements $ExpenseCopyWith<$Res> {
  _$ExpenseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Expense
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
    Object? tags = null,
    Object? receiptUrl = freezed,
    Object? location = freezed,
    Object? isRecurring = null,
    Object? recurringConfig = freezed,
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
              as ExpenseCategory,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      paymentMethod: freezed == paymentMethod
          ? _value.paymentMethod
          : paymentMethod // ignore: cast_nullable_to_non_nullable
              as PaymentMethod?,
      tags: null == tags
          ? _value.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      receiptUrl: freezed == receiptUrl
          ? _value.receiptUrl
          : receiptUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      location: freezed == location
          ? _value.location
          : location // ignore: cast_nullable_to_non_nullable
              as ExpenseLocation?,
      isRecurring: null == isRecurring
          ? _value.isRecurring
          : isRecurring // ignore: cast_nullable_to_non_nullable
              as bool,
      recurringConfig: freezed == recurringConfig
          ? _value.recurringConfig
          : recurringConfig // ignore: cast_nullable_to_non_nullable
              as RecurringConfig?,
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

  /// Create a copy of Expense
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ExpenseLocationCopyWith<$Res>? get location {
    if (_value.location == null) {
      return null;
    }

    return $ExpenseLocationCopyWith<$Res>(_value.location!, (value) {
      return _then(_value.copyWith(location: value) as $Val);
    });
  }

  /// Create a copy of Expense
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $RecurringConfigCopyWith<$Res>? get recurringConfig {
    if (_value.recurringConfig == null) {
      return null;
    }

    return $RecurringConfigCopyWith<$Res>(_value.recurringConfig!, (value) {
      return _then(_value.copyWith(recurringConfig: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ExpenseImplCopyWith<$Res> implements $ExpenseCopyWith<$Res> {
  factory _$$ExpenseImplCopyWith(
          _$ExpenseImpl value, $Res Function(_$ExpenseImpl) then) =
      __$$ExpenseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String userId,
      int amount,
      String currency,
      String description,
      ExpenseCategory category,
      DateTime date,
      PaymentMethod? paymentMethod,
      List<String> tags,
      String? receiptUrl,
      ExpenseLocation? location,
      bool isRecurring,
      RecurringConfig? recurringConfig,
      DateTime createdAt,
      DateTime updatedAt,
      bool isSynced,
      String? note});

  @override
  $ExpenseLocationCopyWith<$Res>? get location;
  @override
  $RecurringConfigCopyWith<$Res>? get recurringConfig;
}

/// @nodoc
class __$$ExpenseImplCopyWithImpl<$Res>
    extends _$ExpenseCopyWithImpl<$Res, _$ExpenseImpl>
    implements _$$ExpenseImplCopyWith<$Res> {
  __$$ExpenseImplCopyWithImpl(
      _$ExpenseImpl _value, $Res Function(_$ExpenseImpl) _then)
      : super(_value, _then);

  /// Create a copy of Expense
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
    Object? tags = null,
    Object? receiptUrl = freezed,
    Object? location = freezed,
    Object? isRecurring = null,
    Object? recurringConfig = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? isSynced = null,
    Object? note = freezed,
  }) {
    return _then(_$ExpenseImpl(
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
              as ExpenseCategory,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      paymentMethod: freezed == paymentMethod
          ? _value.paymentMethod
          : paymentMethod // ignore: cast_nullable_to_non_nullable
              as PaymentMethod?,
      tags: null == tags
          ? _value._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      receiptUrl: freezed == receiptUrl
          ? _value.receiptUrl
          : receiptUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      location: freezed == location
          ? _value.location
          : location // ignore: cast_nullable_to_non_nullable
              as ExpenseLocation?,
      isRecurring: null == isRecurring
          ? _value.isRecurring
          : isRecurring // ignore: cast_nullable_to_non_nullable
              as bool,
      recurringConfig: freezed == recurringConfig
          ? _value.recurringConfig
          : recurringConfig // ignore: cast_nullable_to_non_nullable
              as RecurringConfig?,
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
class _$ExpenseImpl extends _Expense {
  const _$ExpenseImpl(
      {required this.id,
      required this.userId,
      required this.amount,
      this.currency = 'USD',
      required this.description,
      required this.category,
      required this.date,
      this.paymentMethod,
      final List<String> tags = const [],
      this.receiptUrl,
      this.location,
      this.isRecurring = false,
      this.recurringConfig,
      required this.createdAt,
      required this.updatedAt,
      this.isSynced = false,
      this.note})
      : _tags = tags,
        super._();

  factory _$ExpenseImpl.fromJson(Map<String, dynamic> json) =>
      _$$ExpenseImplFromJson(json);

  /// Unique identifier for the expense
  @override
  final String id;

  /// User ID who created this expense
  @override
  final String userId;

  /// Expense amount in the smallest currency unit (e.g., cents for USD)
  @override
  final int amount;

  /// Three-letter currency code (ISO 4217)
  @override
  @JsonKey()
  final String currency;

  /// Expense description/title
  @override
  final String description;

  /// Category this expense belongs to
  @override
  final ExpenseCategory category;

  /// Date and time when the expense occurred
  @override
  final DateTime date;

  /// Optional payment method used
  @override
  final PaymentMethod? paymentMethod;

  /// Optional tags for additional categorization
  final List<String> _tags;

  /// Optional tags for additional categorization
  @override
  @JsonKey()
  List<String> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  /// Optional receipt image URL
  @override
  final String? receiptUrl;

  /// Optional location where expense occurred
  @override
  final ExpenseLocation? location;

  /// Whether this expense is recurring
  @override
  @JsonKey()
  final bool isRecurring;

  /// Recurring expense configuration
  @override
  final RecurringConfig? recurringConfig;

  /// Creation timestamp
  @override
  final DateTime createdAt;

  /// Last modification timestamp
  @override
  final DateTime updatedAt;

  /// Whether this expense is synced with remote server
  @override
  @JsonKey()
  final bool isSynced;

  /// Optional note for additional details
  @override
  final String? note;

  @override
  String toString() {
    return 'Expense(id: $id, userId: $userId, amount: $amount, currency: $currency, description: $description, category: $category, date: $date, paymentMethod: $paymentMethod, tags: $tags, receiptUrl: $receiptUrl, location: $location, isRecurring: $isRecurring, recurringConfig: $recurringConfig, createdAt: $createdAt, updatedAt: $updatedAt, isSynced: $isSynced, note: $note)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ExpenseImpl &&
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
            (identical(other.location, location) ||
                other.location == location) &&
            (identical(other.isRecurring, isRecurring) ||
                other.isRecurring == isRecurring) &&
            (identical(other.recurringConfig, recurringConfig) ||
                other.recurringConfig == recurringConfig) &&
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
  int get hashCode => Object.hash(
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
      location,
      isRecurring,
      recurringConfig,
      createdAt,
      updatedAt,
      isSynced,
      note);

  /// Create a copy of Expense
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ExpenseImplCopyWith<_$ExpenseImpl> get copyWith =>
      __$$ExpenseImplCopyWithImpl<_$ExpenseImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ExpenseImplToJson(
      this,
    );
  }
}

abstract class _Expense extends Expense {
  const factory _Expense(
      {required final String id,
      required final String userId,
      required final int amount,
      final String currency,
      required final String description,
      required final ExpenseCategory category,
      required final DateTime date,
      final PaymentMethod? paymentMethod,
      final List<String> tags,
      final String? receiptUrl,
      final ExpenseLocation? location,
      final bool isRecurring,
      final RecurringConfig? recurringConfig,
      required final DateTime createdAt,
      required final DateTime updatedAt,
      final bool isSynced,
      final String? note}) = _$ExpenseImpl;
  const _Expense._() : super._();

  factory _Expense.fromJson(Map<String, dynamic> json) = _$ExpenseImpl.fromJson;

  /// Unique identifier for the expense
  @override
  String get id;

  /// User ID who created this expense
  @override
  String get userId;

  /// Expense amount in the smallest currency unit (e.g., cents for USD)
  @override
  int get amount;

  /// Three-letter currency code (ISO 4217)
  @override
  String get currency;

  /// Expense description/title
  @override
  String get description;

  /// Category this expense belongs to
  @override
  ExpenseCategory get category;

  /// Date and time when the expense occurred
  @override
  DateTime get date;

  /// Optional payment method used
  @override
  PaymentMethod? get paymentMethod;

  /// Optional tags for additional categorization
  @override
  List<String> get tags;

  /// Optional receipt image URL
  @override
  String? get receiptUrl;

  /// Optional location where expense occurred
  @override
  ExpenseLocation? get location;

  /// Whether this expense is recurring
  @override
  bool get isRecurring;

  /// Recurring expense configuration
  @override
  RecurringConfig? get recurringConfig;

  /// Creation timestamp
  @override
  DateTime get createdAt;

  /// Last modification timestamp
  @override
  DateTime get updatedAt;

  /// Whether this expense is synced with remote server
  @override
  bool get isSynced;

  /// Optional note for additional details
  @override
  String? get note;

  /// Create a copy of Expense
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ExpenseImplCopyWith<_$ExpenseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ExpenseLocation _$ExpenseLocationFromJson(Map<String, dynamic> json) {
  return _ExpenseLocation.fromJson(json);
}

/// @nodoc
mixin _$ExpenseLocation {
  double get latitude => throw _privateConstructorUsedError;
  double get longitude => throw _privateConstructorUsedError;
  String? get address => throw _privateConstructorUsedError;
  String? get placeName => throw _privateConstructorUsedError;

  /// Serializes this ExpenseLocation to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ExpenseLocation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ExpenseLocationCopyWith<ExpenseLocation> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ExpenseLocationCopyWith<$Res> {
  factory $ExpenseLocationCopyWith(
          ExpenseLocation value, $Res Function(ExpenseLocation) then) =
      _$ExpenseLocationCopyWithImpl<$Res, ExpenseLocation>;
  @useResult
  $Res call(
      {double latitude, double longitude, String? address, String? placeName});
}

/// @nodoc
class _$ExpenseLocationCopyWithImpl<$Res, $Val extends ExpenseLocation>
    implements $ExpenseLocationCopyWith<$Res> {
  _$ExpenseLocationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ExpenseLocation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? latitude = null,
    Object? longitude = null,
    Object? address = freezed,
    Object? placeName = freezed,
  }) {
    return _then(_value.copyWith(
      latitude: null == latitude
          ? _value.latitude
          : latitude // ignore: cast_nullable_to_non_nullable
              as double,
      longitude: null == longitude
          ? _value.longitude
          : longitude // ignore: cast_nullable_to_non_nullable
              as double,
      address: freezed == address
          ? _value.address
          : address // ignore: cast_nullable_to_non_nullable
              as String?,
      placeName: freezed == placeName
          ? _value.placeName
          : placeName // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ExpenseLocationImplCopyWith<$Res>
    implements $ExpenseLocationCopyWith<$Res> {
  factory _$$ExpenseLocationImplCopyWith(_$ExpenseLocationImpl value,
          $Res Function(_$ExpenseLocationImpl) then) =
      __$$ExpenseLocationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {double latitude, double longitude, String? address, String? placeName});
}

/// @nodoc
class __$$ExpenseLocationImplCopyWithImpl<$Res>
    extends _$ExpenseLocationCopyWithImpl<$Res, _$ExpenseLocationImpl>
    implements _$$ExpenseLocationImplCopyWith<$Res> {
  __$$ExpenseLocationImplCopyWithImpl(
      _$ExpenseLocationImpl _value, $Res Function(_$ExpenseLocationImpl) _then)
      : super(_value, _then);

  /// Create a copy of ExpenseLocation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? latitude = null,
    Object? longitude = null,
    Object? address = freezed,
    Object? placeName = freezed,
  }) {
    return _then(_$ExpenseLocationImpl(
      latitude: null == latitude
          ? _value.latitude
          : latitude // ignore: cast_nullable_to_non_nullable
              as double,
      longitude: null == longitude
          ? _value.longitude
          : longitude // ignore: cast_nullable_to_non_nullable
              as double,
      address: freezed == address
          ? _value.address
          : address // ignore: cast_nullable_to_non_nullable
              as String?,
      placeName: freezed == placeName
          ? _value.placeName
          : placeName // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ExpenseLocationImpl implements _ExpenseLocation {
  const _$ExpenseLocationImpl(
      {required this.latitude,
      required this.longitude,
      this.address,
      this.placeName});

  factory _$ExpenseLocationImpl.fromJson(Map<String, dynamic> json) =>
      _$$ExpenseLocationImplFromJson(json);

  @override
  final double latitude;
  @override
  final double longitude;
  @override
  final String? address;
  @override
  final String? placeName;

  @override
  String toString() {
    return 'ExpenseLocation(latitude: $latitude, longitude: $longitude, address: $address, placeName: $placeName)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ExpenseLocationImpl &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude) &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.placeName, placeName) ||
                other.placeName == placeName));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, latitude, longitude, address, placeName);

  /// Create a copy of ExpenseLocation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ExpenseLocationImplCopyWith<_$ExpenseLocationImpl> get copyWith =>
      __$$ExpenseLocationImplCopyWithImpl<_$ExpenseLocationImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ExpenseLocationImplToJson(
      this,
    );
  }
}

abstract class _ExpenseLocation implements ExpenseLocation {
  const factory _ExpenseLocation(
      {required final double latitude,
      required final double longitude,
      final String? address,
      final String? placeName}) = _$ExpenseLocationImpl;

  factory _ExpenseLocation.fromJson(Map<String, dynamic> json) =
      _$ExpenseLocationImpl.fromJson;

  @override
  double get latitude;
  @override
  double get longitude;
  @override
  String? get address;
  @override
  String? get placeName;

  /// Create a copy of ExpenseLocation
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ExpenseLocationImplCopyWith<_$ExpenseLocationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

RecurringConfig _$RecurringConfigFromJson(Map<String, dynamic> json) {
  return _RecurringConfig.fromJson(json);
}

/// @nodoc
mixin _$RecurringConfig {
  /// Recurring frequency
  RecurringFrequency get frequency => throw _privateConstructorUsedError;

  /// How often the expense recurs (e.g., every 2 weeks)
  int get interval => throw _privateConstructorUsedError;

  /// End date for recurring expense (null means indefinite)
  DateTime? get endDate => throw _privateConstructorUsedError;

  /// Next occurrence date
  DateTime get nextOccurrence => throw _privateConstructorUsedError;

  /// Serializes this RecurringConfig to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RecurringConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RecurringConfigCopyWith<RecurringConfig> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RecurringConfigCopyWith<$Res> {
  factory $RecurringConfigCopyWith(
          RecurringConfig value, $Res Function(RecurringConfig) then) =
      _$RecurringConfigCopyWithImpl<$Res, RecurringConfig>;
  @useResult
  $Res call(
      {RecurringFrequency frequency,
      int interval,
      DateTime? endDate,
      DateTime nextOccurrence});
}

/// @nodoc
class _$RecurringConfigCopyWithImpl<$Res, $Val extends RecurringConfig>
    implements $RecurringConfigCopyWith<$Res> {
  _$RecurringConfigCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RecurringConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? frequency = null,
    Object? interval = null,
    Object? endDate = freezed,
    Object? nextOccurrence = null,
  }) {
    return _then(_value.copyWith(
      frequency: null == frequency
          ? _value.frequency
          : frequency // ignore: cast_nullable_to_non_nullable
              as RecurringFrequency,
      interval: null == interval
          ? _value.interval
          : interval // ignore: cast_nullable_to_non_nullable
              as int,
      endDate: freezed == endDate
          ? _value.endDate
          : endDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      nextOccurrence: null == nextOccurrence
          ? _value.nextOccurrence
          : nextOccurrence // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RecurringConfigImplCopyWith<$Res>
    implements $RecurringConfigCopyWith<$Res> {
  factory _$$RecurringConfigImplCopyWith(_$RecurringConfigImpl value,
          $Res Function(_$RecurringConfigImpl) then) =
      __$$RecurringConfigImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {RecurringFrequency frequency,
      int interval,
      DateTime? endDate,
      DateTime nextOccurrence});
}

/// @nodoc
class __$$RecurringConfigImplCopyWithImpl<$Res>
    extends _$RecurringConfigCopyWithImpl<$Res, _$RecurringConfigImpl>
    implements _$$RecurringConfigImplCopyWith<$Res> {
  __$$RecurringConfigImplCopyWithImpl(
      _$RecurringConfigImpl _value, $Res Function(_$RecurringConfigImpl) _then)
      : super(_value, _then);

  /// Create a copy of RecurringConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? frequency = null,
    Object? interval = null,
    Object? endDate = freezed,
    Object? nextOccurrence = null,
  }) {
    return _then(_$RecurringConfigImpl(
      frequency: null == frequency
          ? _value.frequency
          : frequency // ignore: cast_nullable_to_non_nullable
              as RecurringFrequency,
      interval: null == interval
          ? _value.interval
          : interval // ignore: cast_nullable_to_non_nullable
              as int,
      endDate: freezed == endDate
          ? _value.endDate
          : endDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      nextOccurrence: null == nextOccurrence
          ? _value.nextOccurrence
          : nextOccurrence // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RecurringConfigImpl implements _RecurringConfig {
  const _$RecurringConfigImpl(
      {required this.frequency,
      this.interval = 1,
      this.endDate,
      required this.nextOccurrence});

  factory _$RecurringConfigImpl.fromJson(Map<String, dynamic> json) =>
      _$$RecurringConfigImplFromJson(json);

  /// Recurring frequency
  @override
  final RecurringFrequency frequency;

  /// How often the expense recurs (e.g., every 2 weeks)
  @override
  @JsonKey()
  final int interval;

  /// End date for recurring expense (null means indefinite)
  @override
  final DateTime? endDate;

  /// Next occurrence date
  @override
  final DateTime nextOccurrence;

  @override
  String toString() {
    return 'RecurringConfig(frequency: $frequency, interval: $interval, endDate: $endDate, nextOccurrence: $nextOccurrence)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RecurringConfigImpl &&
            (identical(other.frequency, frequency) ||
                other.frequency == frequency) &&
            (identical(other.interval, interval) ||
                other.interval == interval) &&
            (identical(other.endDate, endDate) || other.endDate == endDate) &&
            (identical(other.nextOccurrence, nextOccurrence) ||
                other.nextOccurrence == nextOccurrence));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, frequency, interval, endDate, nextOccurrence);

  /// Create a copy of RecurringConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RecurringConfigImplCopyWith<_$RecurringConfigImpl> get copyWith =>
      __$$RecurringConfigImplCopyWithImpl<_$RecurringConfigImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RecurringConfigImplToJson(
      this,
    );
  }
}

abstract class _RecurringConfig implements RecurringConfig {
  const factory _RecurringConfig(
      {required final RecurringFrequency frequency,
      final int interval,
      final DateTime? endDate,
      required final DateTime nextOccurrence}) = _$RecurringConfigImpl;

  factory _RecurringConfig.fromJson(Map<String, dynamic> json) =
      _$RecurringConfigImpl.fromJson;

  /// Recurring frequency
  @override
  RecurringFrequency get frequency;

  /// How often the expense recurs (e.g., every 2 weeks)
  @override
  int get interval;

  /// End date for recurring expense (null means indefinite)
  @override
  DateTime? get endDate;

  /// Next occurrence date
  @override
  DateTime get nextOccurrence;

  /// Create a copy of RecurringConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RecurringConfigImplCopyWith<_$RecurringConfigImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
