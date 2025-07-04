// 1. Enhanced Enum with Fields and Methods
enum VehicleType {
  car(wheels: 4, capacity: 5, type: 'Ground'),
  motorcycle(wheels: 2, capacity: 2, type: 'Ground'),
  bicycle(wheels: 2, capacity: 1, type: 'Ground'),
  helicopter(wheels: 0, capacity: 4, type: 'Air'),
  boat(wheels: 0, capacity: 8, type: 'Water');

  // Fields
  final int wheels;
  final int capacity;
  final String type;

  // Constructor
  const VehicleType({
    required this.wheels,
    required this.capacity,
    required this.type,
  });

  // Methods
  bool get requiresLicense => this != bicycle;
  bool get requiresPilotLicense => this == helicopter;

  // Factory method pattern
  factory VehicleType.fromString(String value) {
    return VehicleType.values.firstWhere(
      (type) => type.name.toLowerCase() == value.toLowerCase(),
      orElse: () => throw ArgumentError('Invalid vehicle type: $value'),
    );
  }
}

// 2. Enum with Interface Implementation
enum Status implements Comparable<Status> {
  inactive(0),
  pending(1),
  active(2),
  suspended(3),
  cancelled(4);

  final int priority;
  const Status(this.priority);

  @override
  int compareTo(Status other) => priority.compareTo(other.priority);

  bool operator >(Status other) => priority > other.priority;
  bool operator <(Status other) => priority < other.priority;
}

// 3. Enum with Extension Methods
extension StatusExtension on Status {
  bool get isTerminal => this == Status.cancelled;
  bool get canTransition => this != Status.cancelled;

  Status? nextStatus() {
    switch (this) {
      case Status.inactive:
        return Status.pending;
      case Status.pending:
        return Status.active;
      case Status.active:
        return Status.suspended;
      case Status.suspended:
        return Status.cancelled;
      case Status.cancelled:
        return null;
    }
  }
}

// 4. Enum for API Response Handling
enum ApiResponseStatus {
  success(code: 200, message: 'Success'),
  created(code: 201, message: 'Created'),
  badRequest(code: 400, message: 'Bad Request'),
  unauthorized(code: 401, message: 'Unauthorized'),
  notFound(code: 404, message: 'Not Found'),
  serverError(code: 500, message: 'Internal Server Error');

  final int code;
  final String message;
  const ApiResponseStatus({required this.code, required this.message});

  bool get isSuccess => code >= 200 && code < 300;
  bool get isError => code >= 400;
  bool get isClientError => code >= 400 && code < 500;
  bool get isServerError => code >= 500;
}

// 5. Enum for Permission System
enum Permission {
  read(level: 1),
  write(level: 2),
  execute(level: 4),
  admin(level: 8);

  final int level;
  const Permission({required this.level});

  bool hasPermission(int userLevel) => userLevel & level != 0;

  static Set<Permission> getPermissions(int userLevel) {
    return Permission.values.where((p) => p.hasPermission(userLevel)).toSet();
  }
}

// 6. Enum for Payment Processing
enum PaymentMethod {
  creditCard(
    displayName: 'Credit Card',
    requiresVerification: true,
    processingFee: 0.029,
  ),
  debitCard(
    displayName: 'Debit Card',
    requiresVerification: true,
    processingFee: 0.015,
  ),
  bankTransfer(
    displayName: 'Bank Transfer',
    requiresVerification: true,
    processingFee: 0.01,
  ),
  digitalWallet(
    displayName: 'Digital Wallet',
    requiresVerification: false,
    processingFee: 0.02,
  );

  final String displayName;
  final bool requiresVerification;
  final double processingFee;

  const PaymentMethod({
    required this.displayName,
    required this.requiresVerification,
    required this.processingFee,
  });

  double calculateFee(double amount) => amount * processingFee;
}

// 7. Enum for Feature Flagging
enum FeatureFlag {
  darkMode(defaultValue: true, requiresRestart: true),
  betaFeatures(defaultValue: false, requiresRestart: false),
  analytics(defaultValue: true, requiresRestart: false);

  final bool defaultValue;
  final bool requiresRestart;

  const FeatureFlag({
    required this.defaultValue,
    required this.requiresRestart,
  });

  // Simulating feature flag storage
  static final Map<FeatureFlag, bool> _values = {};

  bool get isEnabled => _values[this] ?? defaultValue;

  void enable() => _values[this] = true;
  void disable() => _values[this] = false;
}

// Example Usage
void main() {
  // 1. Vehicle Type Examples
  final car = VehicleType.car;
  print('Car requires license: ${car.requiresLicense}');
  print('Car capacity: ${car.capacity}');

  // Using factory method
  try {
    final vehicle = VehicleType.fromString('helicopter');
    print('Vehicle type: ${vehicle.type}');
  } catch (e) {
    print('Error: $e');
  }

  // 2. Status Comparison
  final statuses = Status.values..sort();
  print('Sorted statuses: ${statuses.map((s) => s.name)}');
  print('active > pending: ${Status.active > Status.pending}');

  // 3. Status Transitions
  var status = Status.inactive;
  while (status.canTransition) {
    print('Current status: ${status.name}');
    status = status.nextStatus()!;
  }

  // 4. API Response Handling
  final response = ApiResponseStatus.success;
  if (response.isSuccess) {
    print('API call successful: ${response.message}');
  }

  // 5. Permission System
  final userLevel = Permission.read.level | Permission.write.level;
  final permissions = Permission.getPermissions(userLevel);
  print('User permissions: ${permissions.map((p) => p.name)}');

  // 6. Payment Processing
  final payment = PaymentMethod.creditCard;
  final amount = 100.0;
  print('Processing fee for $amount: ${payment.calculateFee(amount)}');

  // 7. Feature Flags
  FeatureFlag.darkMode.enable();
  print('Dark mode enabled: ${FeatureFlag.darkMode.isEnabled}');
  print('Requires restart: ${FeatureFlag.darkMode.requiresRestart}');
}
