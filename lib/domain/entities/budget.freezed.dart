// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'budget.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Budget _$BudgetFromJson(Map<String, dynamic> json) {
  return _Budget.fromJson(json);
}

/// @nodoc
mixin _$Budget {
  /// Unique identifier for the budget
  String get id => throw _privateConstructorUsedError;

  /// User ID who owns this budget
  String get userId => throw _privateConstructorUsedError;

  /// Budget name/title
  String get name => throw _privateConstructorUsedError;

  /// Budget description
  String? get description => throw _privateConstructorUsedError;

  /// Budget type (category-specific or overall)
  BudgetType get type => throw _privateConstructorUsedError;

  /// Target spending limit in smallest currency unit
  int get targetAmount => throw _privateConstructorUsedError;

  /// Currency code (ISO 4217)
  String get currency => throw _privateConstructorUsedError;

  /// Budget period
  BudgetPeriod get period => throw _privateConstructorUsedError;

  /// Start date of the budget period
  DateTime get startDate => throw _privateConstructorUsedError;

  /// End date of the budget period
  DateTime get endDate => throw _privateConstructorUsedError;

  /// Categories this budget applies to (empty for overall budget)
  List<ExpenseCategory> get categories => throw _privateConstructorUsedError;

  /// Current spent amount in smallest currency unit
  int get spentAmount => throw _privateConstructorUsedError;

  /// Whether to receive notifications when approaching limit
  bool get enableNotifications => throw _privateConstructorUsedError;

  /// Warning threshold percentage (e.g., 80 for 80%)
  int get warningThreshold => throw _privateConstructorUsedError;

  /// Creation timestamp
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Last modification timestamp
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Whether this budget is active
  bool get isActive => throw _privateConstructorUsedError;

  /// Whether this budget is synced with remote server
  bool get isSynced => throw _privateConstructorUsedError;

  /// Serializes this Budget to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Budget
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BudgetCopyWith<Budget> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BudgetCopyWith<$Res> {
  factory $BudgetCopyWith(Budget value, $Res Function(Budget) then) =
      _$BudgetCopyWithImpl<$Res, Budget>;
  @useResult
  $Res call(
      {String id,
      String userId,
      String name,
      String? description,
      BudgetType type,
      int targetAmount,
      String currency,
      BudgetPeriod period,
      DateTime startDate,
      DateTime endDate,
      List<ExpenseCategory> categories,
      int spentAmount,
      bool enableNotifications,
      int warningThreshold,
      DateTime createdAt,
      DateTime updatedAt,
      bool isActive,
      bool isSynced});
}

/// @nodoc
class _$BudgetCopyWithImpl<$Res, $Val extends Budget>
    implements $BudgetCopyWith<$Res> {
  _$BudgetCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Budget
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? name = null,
    Object? description = freezed,
    Object? type = null,
    Object? targetAmount = null,
    Object? currency = null,
    Object? period = null,
    Object? startDate = null,
    Object? endDate = null,
    Object? categories = null,
    Object? spentAmount = null,
    Object? enableNotifications = null,
    Object? warningThreshold = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? isActive = null,
    Object? isSynced = null,
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
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as BudgetType,
      targetAmount: null == targetAmount
          ? _value.targetAmount
          : targetAmount // ignore: cast_nullable_to_non_nullable
              as int,
      currency: null == currency
          ? _value.currency
          : currency // ignore: cast_nullable_to_non_nullable
              as String,
      period: null == period
          ? _value.period
          : period // ignore: cast_nullable_to_non_nullable
              as BudgetPeriod,
      startDate: null == startDate
          ? _value.startDate
          : startDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endDate: null == endDate
          ? _value.endDate
          : endDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      categories: null == categories
          ? _value.categories
          : categories // ignore: cast_nullable_to_non_nullable
              as List<ExpenseCategory>,
      spentAmount: null == spentAmount
          ? _value.spentAmount
          : spentAmount // ignore: cast_nullable_to_non_nullable
              as int,
      enableNotifications: null == enableNotifications
          ? _value.enableNotifications
          : enableNotifications // ignore: cast_nullable_to_non_nullable
              as bool,
      warningThreshold: null == warningThreshold
          ? _value.warningThreshold
          : warningThreshold // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      isSynced: null == isSynced
          ? _value.isSynced
          : isSynced // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$BudgetImplCopyWith<$Res> implements $BudgetCopyWith<$Res> {
  factory _$$BudgetImplCopyWith(
          _$BudgetImpl value, $Res Function(_$BudgetImpl) then) =
      __$$BudgetImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String userId,
      String name,
      String? description,
      BudgetType type,
      int targetAmount,
      String currency,
      BudgetPeriod period,
      DateTime startDate,
      DateTime endDate,
      List<ExpenseCategory> categories,
      int spentAmount,
      bool enableNotifications,
      int warningThreshold,
      DateTime createdAt,
      DateTime updatedAt,
      bool isActive,
      bool isSynced});
}

/// @nodoc
class __$$BudgetImplCopyWithImpl<$Res>
    extends _$BudgetCopyWithImpl<$Res, _$BudgetImpl>
    implements _$$BudgetImplCopyWith<$Res> {
  __$$BudgetImplCopyWithImpl(
      _$BudgetImpl _value, $Res Function(_$BudgetImpl) _then)
      : super(_value, _then);

  /// Create a copy of Budget
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? name = null,
    Object? description = freezed,
    Object? type = null,
    Object? targetAmount = null,
    Object? currency = null,
    Object? period = null,
    Object? startDate = null,
    Object? endDate = null,
    Object? categories = null,
    Object? spentAmount = null,
    Object? enableNotifications = null,
    Object? warningThreshold = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? isActive = null,
    Object? isSynced = null,
  }) {
    return _then(_$BudgetImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as BudgetType,
      targetAmount: null == targetAmount
          ? _value.targetAmount
          : targetAmount // ignore: cast_nullable_to_non_nullable
              as int,
      currency: null == currency
          ? _value.currency
          : currency // ignore: cast_nullable_to_non_nullable
              as String,
      period: null == period
          ? _value.period
          : period // ignore: cast_nullable_to_non_nullable
              as BudgetPeriod,
      startDate: null == startDate
          ? _value.startDate
          : startDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endDate: null == endDate
          ? _value.endDate
          : endDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      categories: null == categories
          ? _value._categories
          : categories // ignore: cast_nullable_to_non_nullable
              as List<ExpenseCategory>,
      spentAmount: null == spentAmount
          ? _value.spentAmount
          : spentAmount // ignore: cast_nullable_to_non_nullable
              as int,
      enableNotifications: null == enableNotifications
          ? _value.enableNotifications
          : enableNotifications // ignore: cast_nullable_to_non_nullable
              as bool,
      warningThreshold: null == warningThreshold
          ? _value.warningThreshold
          : warningThreshold // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      isSynced: null == isSynced
          ? _value.isSynced
          : isSynced // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$BudgetImpl extends _Budget {
  const _$BudgetImpl(
      {required this.id,
      required this.userId,
      required this.name,
      this.description,
      this.type = BudgetType.category,
      required this.targetAmount,
      this.currency = 'USD',
      required this.period,
      required this.startDate,
      required this.endDate,
      final List<ExpenseCategory> categories = const [],
      this.spentAmount = 0,
      this.enableNotifications = true,
      this.warningThreshold = 80,
      required this.createdAt,
      required this.updatedAt,
      this.isActive = true,
      this.isSynced = false})
      : _categories = categories,
        super._();

  factory _$BudgetImpl.fromJson(Map<String, dynamic> json) =>
      _$$BudgetImplFromJson(json);

  /// Unique identifier for the budget
  @override
  final String id;

  /// User ID who owns this budget
  @override
  final String userId;

  /// Budget name/title
  @override
  final String name;

  /// Budget description
  @override
  final String? description;

  /// Budget type (category-specific or overall)
  @override
  @JsonKey()
  final BudgetType type;

  /// Target spending limit in smallest currency unit
  @override
  final int targetAmount;

  /// Currency code (ISO 4217)
  @override
  @JsonKey()
  final String currency;

  /// Budget period
  @override
  final BudgetPeriod period;

  /// Start date of the budget period
  @override
  final DateTime startDate;

  /// End date of the budget period
  @override
  final DateTime endDate;

  /// Categories this budget applies to (empty for overall budget)
  final List<ExpenseCategory> _categories;

  /// Categories this budget applies to (empty for overall budget)
  @override
  @JsonKey()
  List<ExpenseCategory> get categories {
    if (_categories is EqualUnmodifiableListView) return _categories;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_categories);
  }

  /// Current spent amount in smallest currency unit
  @override
  @JsonKey()
  final int spentAmount;

  /// Whether to receive notifications when approaching limit
  @override
  @JsonKey()
  final bool enableNotifications;

  /// Warning threshold percentage (e.g., 80 for 80%)
  @override
  @JsonKey()
  final int warningThreshold;

  /// Creation timestamp
  @override
  final DateTime createdAt;

  /// Last modification timestamp
  @override
  final DateTime updatedAt;

  /// Whether this budget is active
  @override
  @JsonKey()
  final bool isActive;

  /// Whether this budget is synced with remote server
  @override
  @JsonKey()
  final bool isSynced;

  @override
  String toString() {
    return 'Budget(id: $id, userId: $userId, name: $name, description: $description, type: $type, targetAmount: $targetAmount, currency: $currency, period: $period, startDate: $startDate, endDate: $endDate, categories: $categories, spentAmount: $spentAmount, enableNotifications: $enableNotifications, warningThreshold: $warningThreshold, createdAt: $createdAt, updatedAt: $updatedAt, isActive: $isActive, isSynced: $isSynced)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BudgetImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.targetAmount, targetAmount) ||
                other.targetAmount == targetAmount) &&
            (identical(other.currency, currency) ||
                other.currency == currency) &&
            (identical(other.period, period) || other.period == period) &&
            (identical(other.startDate, startDate) ||
                other.startDate == startDate) &&
            (identical(other.endDate, endDate) || other.endDate == endDate) &&
            const DeepCollectionEquality()
                .equals(other._categories, _categories) &&
            (identical(other.spentAmount, spentAmount) ||
                other.spentAmount == spentAmount) &&
            (identical(other.enableNotifications, enableNotifications) ||
                other.enableNotifications == enableNotifications) &&
            (identical(other.warningThreshold, warningThreshold) ||
                other.warningThreshold == warningThreshold) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.isSynced, isSynced) ||
                other.isSynced == isSynced));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      userId,
      name,
      description,
      type,
      targetAmount,
      currency,
      period,
      startDate,
      endDate,
      const DeepCollectionEquality().hash(_categories),
      spentAmount,
      enableNotifications,
      warningThreshold,
      createdAt,
      updatedAt,
      isActive,
      isSynced);

  /// Create a copy of Budget
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BudgetImplCopyWith<_$BudgetImpl> get copyWith =>
      __$$BudgetImplCopyWithImpl<_$BudgetImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BudgetImplToJson(
      this,
    );
  }
}

abstract class _Budget extends Budget {
  const factory _Budget(
      {required final String id,
      required final String userId,
      required final String name,
      final String? description,
      final BudgetType type,
      required final int targetAmount,
      final String currency,
      required final BudgetPeriod period,
      required final DateTime startDate,
      required final DateTime endDate,
      final List<ExpenseCategory> categories,
      final int spentAmount,
      final bool enableNotifications,
      final int warningThreshold,
      required final DateTime createdAt,
      required final DateTime updatedAt,
      final bool isActive,
      final bool isSynced}) = _$BudgetImpl;
  const _Budget._() : super._();

  factory _Budget.fromJson(Map<String, dynamic> json) = _$BudgetImpl.fromJson;

  /// Unique identifier for the budget
  @override
  String get id;

  /// User ID who owns this budget
  @override
  String get userId;

  /// Budget name/title
  @override
  String get name;

  /// Budget description
  @override
  String? get description;

  /// Budget type (category-specific or overall)
  @override
  BudgetType get type;

  /// Target spending limit in smallest currency unit
  @override
  int get targetAmount;

  /// Currency code (ISO 4217)
  @override
  String get currency;

  /// Budget period
  @override
  BudgetPeriod get period;

  /// Start date of the budget period
  @override
  DateTime get startDate;

  /// End date of the budget period
  @override
  DateTime get endDate;

  /// Categories this budget applies to (empty for overall budget)
  @override
  List<ExpenseCategory> get categories;

  /// Current spent amount in smallest currency unit
  @override
  int get spentAmount;

  /// Whether to receive notifications when approaching limit
  @override
  bool get enableNotifications;

  /// Warning threshold percentage (e.g., 80 for 80%)
  @override
  int get warningThreshold;

  /// Creation timestamp
  @override
  DateTime get createdAt;

  /// Last modification timestamp
  @override
  DateTime get updatedAt;

  /// Whether this budget is active
  @override
  bool get isActive;

  /// Whether this budget is synced with remote server
  @override
  bool get isSynced;

  /// Create a copy of Budget
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BudgetImplCopyWith<_$BudgetImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
