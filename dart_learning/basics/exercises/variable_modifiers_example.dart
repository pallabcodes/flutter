import 'dart:math'; // For Random
// import 'dart:io'; // For stdin

class ExpensiveResource {
  late String _data; // _ denotes or marks it as a private modifier
  static int _constructorCallCount =
      0; // Static counter to track constructor invocations

  ExpensiveResource() {
    _constructorCallCount++; // Increment the counter each time the constructor is called
    // These print statements help demonstrate when the constructor is actually called.
    print(
        'ExpensiveResource: Initializing expensive resource (constructor call #$_constructorCallCount)...');
    // Simulate some work or data loading that makes this initialization "expensive".
    _data = 'Data loaded from expensive resource.';
    print(
        'ExpensiveResource: Initialization complete (constructor call #$_constructorCallCount).');
  }

  String getData() {
    return this._data;
  }
}

/// This program demonstrates the usage of Dart's variable modifiers (const, final, var, and late)
/// through practical examples and common use cases.
void main() async {
  // SECTION 1: Compile-time Constants
  print('1. "Hey, I know this RIGHT NOW" stuff (✅ CONST-friendly):');
  // Basic primitive and collection constants
  const number = 42;
  const text = "Hello";
  const boolean = true;
  const list = [1, 2, 3];
  const map = {'a': 1, 'b': 2};
  print('Number: $number');
  print('Text: $text');
  print('Boolean: $boolean');
  print('List: $list');
  print('Map: $map');

  // SECTION 2: Runtime Values (late variable marked modifier access its value first time at runtime)
  /**
   * A late variable is not initialized at the time of declaration.
   * It is initialized only when it is accessed for the first time during program execution.
   * This makes it a runtime feature, as the initialization happens dynamically when the program runs.
  */

  // --- Real-world example of `late` for lazy initialization ---
  print('\n--- Demonstrating `late` for lazy initialization ---');

  // Declare a `late` variable. Its initializer (the ExpensiveResource() constructor)
  // will NOT run immediately when this line is executed.
  // The 'ExpensiveResource: Initializing...' messages will NOT appear yet.
  late ExpensiveResource lazyResource = ExpensiveResource();

  print(
      'Variable `lazyResource` declared, but ExpensiveResource constructor has not run yet.');
  print('Waiting for 1 second before first access to `lazyResource`...');
  await Future.delayed(Duration(seconds: 1));

  // --- Crucial Point: First Access ---
  // The moment `lazyResource` is accessed for the very first time (e.g., calling a method on it),
  // its initializer (the ExpensiveResource() constructor) is executed.
  // This is the ONLY time the constructor will be called.
  print('Accessing `lazyResource` for the FIRST time now...');
  print(
      '-> Expect "ExpensiveResource: Initializing..." and "Initialization complete..." to be printed immediately below this line.');
  print('Data from lazy resource: "${lazyResource.getData()}"');
  print(
      '^ Notice: "ExpensiveResource: Initializing..." was printed just before the line above. This confirms the *single* initialization.');

  print('Waiting for another 1 second...');
  await Future.delayed(Duration(seconds: 1));

  // --- Subsequent Access ---
  // Since `lazyResource` has already been initialized during the first access,
  // accessing it again will NOT re-run the ExpensiveResource() constructor.
  // The existing, already initialized object is simply reused.
  print('Accessing `lazyResource` for a SECOND time...');
  print(
      '-> Notice: "ExpensiveResource: Initializing..." will NOT be printed again, '
      'because the resource is already initialized.');
  print('Data from lazy resource: "${lazyResource.getData()}"');
  print(
      '^ Confirmation: "ExpensiveResource: Initializing..." was NOT printed again. '
      'The constructor for ExpensiveResource ran exactly ONE time, on the first access.');

  print('--- `late` demonstration complete ---\n');

  print('\n2. "Gotta wait and see" stuff (❌ CONST-unfriendly):');
  // Values that can only be determined at runtime
  final rightNow = DateTime.now();
  final random = Random().nextInt(10);
  // final userInput = stdin.readLineSync(); // Commented out for demonstration
  final apiData = fetchSomeData();
  print('Current time: $rightNow');
  print('Random number: $random');
  print('API Future: $apiData');

  // SECTION 3: Mathematical Operations
  print('\n3. Math with known values (✅ CONST-friendly):');
  // Compile-time mathematical operations
  const sum = 5 + 3;
  const double pi = 3.14159;
  const result = pi * 2;
  print('Sum: $sum');
  print('Pi: $pi');
  print('Result: $result');

  // SECTION 4: Runtime Calculations
  print('\n4. Math with unknown values (❌ CONST-unfriendly):');

  // Operations involving runtime values
  final userAge = getUserAge();
  final total = userAge + 5;
  print('User age: $userAge');
  print('Total: $total');

  // SECTION 5: Date Operations
  print('\n5. Examples with Dates:');
  // Demonstrating date handling
  final birthday =
      DateTime(1990, 1, 1); // Using final as DateTime constructor isn't const
  final today = DateTime.now();
  print('Birthday: $birthday');
  print('Today: $today');

  // SECTION 6: Collection Examples
  print('\n6. Lists and Collections:');
  // Comparing static vs dynamic collections
  const fixedList = ['A', 'B', 'C'];
  final dynamicList = getDatabaseItems();
  print('Fixed list: $fixedList');
  print('Dynamic list: $dynamicList');

  // SECTION 7: Configuration Examples
  print('\n7. Configuration Values:');
  // Demonstrating configuration values
  const configPort = 8080;
  final userPort = getPortFromEnv();
  print('Config port: $configPort');
  print('User port: $userPort');

  // SECTION 8: Compile-time vs Runtime Function Calls
  print('\n8. Compile-time vs Runtime Function Calls:');
  // Compile-time constant
  const compileTimeValue = 42;
  print('Compile-time constant: $compileTimeValue');

  // Function returning a constant value
  int getConstantValue() => 42;

  // This will fail because getConstantValue() is evaluated at runtime
  // const invalidConst = getConstantValue(); // ❌ Compile-time error

  // This is valid because final allows runtime evaluation
  final validFinal = getConstantValue(); // ✅
  print('Runtime-evaluated final: $validFinal');

  // Using const constructors
  const example = ConstExample(42); // ✅
  print('Const constructor example: ${example.value}');

  // SECTION 9: Late Variables
  print('\n9. Late Variables:');
  // Lazily initialized variable
  late String description;
  description = 'This variable is initialized lazily.';
  print('Late variable description: $description');

  // Example of using late with expensive computation
  late int expensiveComputation = performExpensiveComputation();
  print('Expensive computation result: $expensiveComputation');
}

/// Helper functions for demonstration purposes
/// These functions simulate runtime data sources

/// Simulates getting a user's age
int getUserAge() => 25;

/// Simulates an async API call
Future<String> fetchSomeData() async => 'data';

/// Simulates retrieving items from a database
List<String> getDatabaseItems() => ['item'];

/// Simulates reading a port number from environment variables
int getPortFromEnv() => 3000;

/// Simulates an expensive computation
int performExpensiveComputation() {
  print('Performing expensive computation...');
  return 42;
}

/// Example class with a const constructor
class ConstExample {
  final int value;
  const ConstExample(this.value);
}

/*
Key Takeaways:

1. Use const when the value is known at compile time:
   - Literal values (numbers, strings)
   - Fixed collections
   - Compile-time computations
   - Configuration constants

2. Use final when the value is determined at runtime:
   - Current time/dates
   - Random numbers
   - User input
   - API responses
   - Environment variables
   - Database queries

3. Use late for:
   - Lazily initialized variables
   - Variables that cannot be initialized at the time of declaration
   - Expensive computations that should be deferred until needed

4. Functions are evaluated at runtime unless part of a const constructor or const expression.

Best Practices:
- Prefer const over final when possible for better performance
- Use final for runtime values that won't be reassigned
- Use late for variables that are expensive to compute or cannot be initialized immediately
- Document the rationale for choosing const, final, or late in unclear cases
*/