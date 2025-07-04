// 1. Basic Record Definitions
(String, int) getBasicRecord() => ('John Doe', 30);
({String name, int age}) getNamedRecord() => (name: 'John Doe', age: 30);

// 2. Record Type Aliases
typedef UserRecord = ({
  String firstName,
  String lastName,
  int age,
  DateTime dateOfBirth
});

typedef GeoLocation = (double latitude, double longitude);
typedef AddressRecord = ({
  String street,
  String city,
  String country,
  String postalCode,
  GeoLocation coordinates
});

// 3. Records with Generics
typedef Result<T> = ({T value, String message, bool isSuccess});

// 4. Complex Record Structures
typedef TransactionRecord = ({
  String id,
  double amount,
  DateTime timestamp,
  ({String name, String id}) sender,
  ({String name, String id}) receiver,
  Map<String, dynamic> metadata
});

// Define StateUpdate type at top level
typedef StateUpdate<T> = ({
  T newState,
  T oldState,
  String action,
  DateTime timestamp
});

class RecordDemonstration {
  // 5. Records as Return Types
  Result<T> executeOperation<T>(T Function() operation) {
    try {
      final result = operation();
      return (
        value: result,
        message: 'Operation completed successfully',
        isSuccess: true
      );
    } catch (e) {
      return (
        value: null as T,
        message: 'Operation failed: $e',
        isSuccess: false
      );
    }
  }

  // 6. Record Pattern Matching
  String processUserRecord(UserRecord user) {
    final (firstName: f, lastName: l, age: a, dateOfBirth: dob) = user;
    return 'User: $f $l, Age: $a, DOB: ${dob.toIso8601String()}';
  }

  // 7. Records in Collections
  List<GeoLocation> getRouteCoordinates() {
    return [
      (37.7749, -122.4194), // San Francisco
      (34.0522, -118.2437), // Los Angeles
      (40.7128, -74.0060), // New York
    ];
  }

  // 8. Records with Default Values
  ({String status, DateTime timestamp, String? message}) getStatus(
          [String? customMessage]) =>
      (status: 'active', timestamp: DateTime.now(), message: customMessage);

  // 9. Records with Computed Values
  ({
    int originalPrice,
    double discountPercentage,
    double finalPrice,
    String formattedPrice
  }) calculatePrice(int price, double discount) {
    final finalPrice = price * (1 - discount);
    return (
      originalPrice: price,
      discountPercentage: discount * 100,
      finalPrice: finalPrice,
      formattedPrice: '\$${finalPrice.toStringAsFixed(2)}'
    );
  }

  // 10. Records for API Responses
  Future<Result<List<UserRecord>>> fetchUsers() async {
    try {
      // Simulated API call
      await Future.delayed(Duration(seconds: 1));
      final users = <UserRecord>[
        (
          firstName: 'John',
          lastName: 'Doe',
          age: 30,
          dateOfBirth: DateTime(1993, 5, 15)
        ),
        (
          firstName: 'Jane',
          lastName: 'Smith',
          age: 28,
          dateOfBirth: DateTime(1995, 8, 22)
        ),
      ];
      return (
        value: users,
        message: 'Users fetched successfully',
        isSuccess: true
      );
    } catch (e) {
      return (
        value: <UserRecord>[],
        message: 'Failed to fetch users: $e',
        isSuccess: false
      );
    }
  }

  // 11. Records for Complex Transformations
  ({List<T> valid, List<String> errors}) validateData<T>(
      List<T> items, bool Function(T) validator) {
    final valid = <T>[];
    final errors = <String>[];

    for (var item in items) {
      if (validator(item)) {
        valid.add(item);
      } else {
        errors.add('Validation failed for: $item');
      }
    }

    return (valid: valid, errors: errors);
  }

  // 12. Records for State Management
  StateUpdate<T> updateState<T>(T oldState, T newState, String action) => (
        newState: newState,
        oldState: oldState,
        action: action,
        timestamp: DateTime.now()
      );
}

void main() async {
  final demo = RecordDemonstration();

  // 1. Basic Record Usage
  final (name, age) = getBasicRecord();
  print('Basic Record - Name: $name, Age: $age');

  // 2. Named Record Usage
  final user = getNamedRecord();
  print('Named Record - ${user.name} is ${user.age} years old');

  // 3. Complex Record Usage
  final address = (
    street: '123 Tech Lane',
    city: 'San Francisco',
    country: 'USA',
    postalCode: '94105',
    coordinates: (37.7749, -122.4194)
  );
  print('Address: ${address.street}, ${address.city}');
  print('Coordinates: ${address.coordinates.$1}, ${address.coordinates.$2}');

  // 4. Records with Pattern Matching
  final coords = demo.getRouteCoordinates();
  for (final (lat, long) in coords) {
    print('Location: $lat, $long');
  }

  // 5. Records in Error Handling
  final result = demo.executeOperation(() => 42);
  print(
      'Operation ${result.isSuccess ? 'succeeded' : 'failed'}: ${result.message}');

  // 6. Records with API Responses
  final userResult = await demo.fetchUsers();
  if (userResult.isSuccess) {
    for (final user in userResult.value) {
      print('User: ${user.firstName} ${user.lastName}');
    }
  }

  // 7. Records for Data Validation
  final numbers = [1, 2, 3, -4, 5, -6];
  final validation = demo.validateData(numbers, (number) => number > 0);
  print('Valid numbers: ${validation.valid}');
  print('Validation errors: ${validation.errors}');

  // 8. Records for State Updates
  final stateUpdate = demo.updateState('initial', 'updated', 'UPDATE_ACTION');
  print('State update: ${stateUpdate.action} at ${stateUpdate.timestamp}');

  // 9. Records with Computed Values
  final priceInfo = demo.calculatePrice(100, 0.2);
  print('''
    Original Price: \$${priceInfo.originalPrice}
    Discount: ${priceInfo.discountPercentage}%
    Final Price: ${priceInfo.formattedPrice}
  ''');
}
