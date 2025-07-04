// 1. Record Patterns
(int, String) getPersonDetails() => (25, "John Doe");
({int age, String name}) getPersonRecord() => (age: 25, name: "John Doe");

// 2. Complex Data Structures
class Address {
  final String street;
  final String city;
  final String country;

  const Address(this.street, this.city, this.country);
}

class User {
  final String name;
  final int age;
  final Address address;
  final List<String> roles;

  const User(this.name, this.age, this.address, this.roles);
}

// 3. Sealed Class Hierarchy for API Responses
sealed class ApiResponse<T> {
  const ApiResponse();
}

final class Success<T> extends ApiResponse<T> {
  final T data;
  const Success(this.data);
}

final class Failure<T> extends ApiResponse<T> {
  final String error;
  final int code;
  const Failure(this.error, this.code);
}

final class Loading<T> extends ApiResponse<T> {
  const Loading();
}

// 4. Advanced Pattern Matching Examples
void demonstratePatternMatching() {
  print('\n1. Basic Record Pattern Matching:');
  final (age, name) = getPersonDetails();
  print('Age: $age, Name: $name');

  print('\n2. Record Pattern with Named Fields:');
  final record = getPersonRecord();
  print('User Age: ${record.age}, User Name: ${record.name}');

  print('\n3. List Patterns:');
  final numbers = [1, 2, 3, 4, 5];

  switch (numbers) {
    case [var first, var second, ...var rest]:
      print('First: $first, Second: $second, Rest: $rest');
    case []:
      print('Empty list');
  }

  print('\n4. Map Patterns:');
  final Map<String, dynamic> json = {
    'name': 'Alice',
    'age': 30,
    'address': {'city': 'New York', 'country': 'USA'}
  };

  if (json
      case {
        'name': String name,
        'age': int userAge,
        'address': {'city': String city}
      }) {
    print('Name: $name, Age: $userAge, City: $city');
  }

  print('\n5. Object Patterns:');
  final user = User('Bob', 30, Address('123 Main St', 'San Francisco', 'USA'),
      ['admin', 'user']);

  switch (user) {
    case User(name: var n, age: var a) when a > 18 && n.isNotEmpty:
      print('Adult user $n');
    case User(name: var n, age: var a) when a <= 18:
      print('Minor user: $n');
    default:
      print('Other user');
  }

  print('\n6. API Response Pattern Matching:');
  void handleResponse(ApiResponse<String> response) {
    final message = switch (response) {
      Success(data: var d) => 'Success: $d',
      Failure(error: var e, code: 404) => 'Not found: $e',
      Failure(error: var e, code: var c) => 'Error ($c): $e',
      Loading() => 'Loading...'
    };
    print(message);
  }

  handleResponse(Success('Data loaded'));
  handleResponse(Failure('Not found', 404));
  handleResponse(Loading());

  print('\n7. Nested Pattern Matching:');
  final complex = [
    {
      'user': 'Alice',
      'scores': [10, 20, 30]
    },
    {
      'user': 'Bob',
      'scores': [15, 25, 35]
    }
  ];

  if (complex
      case [
        {'user': String u1, 'scores': [int s1, ...]},
        {'user': String u2, 'scores': [int s2, ...]}
      ]) {
    print('First user: $u1 (first score: $s1)');
    print('Second user: $u2 (first score: $s2)');
  }

  print('\n8. Guard Clauses with Patterns:');
  void processValue(dynamic value) {
    switch (value) {
      case int n when n > 0:
        print('Positive number: $n');
      case int n when n < 0:
        print('Negative number: $n');
      case String s when s.length > 5:
        print('Long string: $s');
      default:
        print('Other value: $value');
    }
  }

  processValue(10);
  processValue(-5);
  processValue("Hello World");

  print('\n9. Collection Pattern Matching:');
  final items = [1, 2, 3, 4, 5];

  switch (items) {
    case [1, 2, ...var rest] when rest.length > 2:
      print('Starts with 1, 2 and has more than 2 additional elements: $rest');
    case [1, ...var rest]:
      print('Starts with 1: $rest');
    default:
      print('No pattern matched');
  }

  print('\n10. Logical OR Patterns:');
  void checkValue(dynamic value) {
    switch (value) {
      case int n when n < 0 || n > 100:
        print('Number out of range: $n');
      case String s when s.isEmpty || s.length > 10:
        print('String length issue: $s');
      default:
        print('Value within acceptable range: $value');
    }
  }

  checkValue(-5);
  checkValue(150);
  checkValue("Very long string here");
}

void main() {
  demonstratePatternMatching();
}
