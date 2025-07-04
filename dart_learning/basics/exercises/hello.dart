void main() {
  print("Hello, World!");

  // VARIABLES

  // `var` allows reassignment, similar to `let` in JS/TS.
  // It can be declared without an initial value and will default to `null` in Dart.
  var someValue1 = '10'; // Initialized with a value.
  someValue1 = '20'; // This is allowed because `var` allows reassignment.
  var uninitializedVar; // Allowed, defaults to `null`.
  print(uninitializedVar); // Prints `null`.

  // `final` is like `const` in JS/TS, but it allows lazy initialization.
  // Once assigned, it cannot be reassigned.
  // Unlike `const`, `final` does not require a value at compile time.
  // It can be assigned a value at runtime (e.g., user input, DateTime).
  final someValue2 = '10'; // Initialized immediately.
  // someValue2 = '20'; // This will throw an error because `final` cannot be reassigned.
  final uninitializedFinal; // Allowed, but must be initialized before use.
  uninitializedFinal = '30'; // Lazy initialization is allowed (assigned once).
  print(uninitializedFinal); // Prints `30`.

  // Example of runtime assignment for `final`
  final userInput =
      getUserInput(); // Value assigned at runtime (e.g., user input).
  final currentTime =
      DateTime.now(); // Value assigned at runtime (current timestamp).
  print('User Input: $userInput');
  print('Current Time: $currentTime');

  // `const` is a compile-time constant. It must be assigned a value that is known at compile time.
  // It is stricter than `final` and is immutable.
  // Use `const` for values that are fixed and known at compile time.
  const someValue3 = '10'; // Must be initialized at compile time.
  // const uninitializedConst; // Not allowed, must be initialized at declaration.
  // someValue3 = '20'; // This will throw an error because `const` cannot be reassigned.

  // Example of compile-time constant for `const`
  const pi = 3.14159; // Value is fixed and known at compile time.
  const appName = 'MyApp'; // Fixed string known at compile time.
  print('Pi: $pi');
  print('App Name: $appName');

  print(someValue1);
  print(someValue2);
  print(someValue3);

  print('--------');

  // String
  String singleQuote = 'Hello, Dart!';
  String doubleQuote = "Hello, World!";
  String concatenated = singleQuote + " " + doubleQuote; // Concatenation
  String interpolated =
      "The length of the string is ${singleQuote.length}."; // Interpolation
  print(singleQuote);
  print(doubleQuote);
  print(concatenated);
  print(interpolated);

  // Concatenation
  String part1 = "Hello";
  String part2 = "World";
  String concatenatedParts = part1 + " " + part2;
  print(concatenatedParts); // Prints "Hello World"

  // Interpolation
  String interpolatedPart = "The length of part1 is ${part1.length}.";
  print(interpolatedPart); // Prints "The length of part1 is 5."

  // int
  int age = 25;
  print("Age: $age");

  // double
  double piValue = 3.14159;
  print("Value of Pi: $piValue");

  // bool
  bool isDartFun = true;
  print("Is Dart fun? $isDartFun");

  // num (can hold both int and double)
  num someNumber = 42; // Initially an int
  print("Some number: $someNumber");
  someNumber = 3.14; // Now a double
  print("Updated number: $someNumber");

  // String interpolation with expressions
  print("The square of Pi is ${piValue * piValue}.");

  // Multiline strings
  String multiline = '''
  This is a
  multiline string.
  ''';
  print(multiline);

  // Raw strings (ignores escape sequences)
  String rawString = r'This is a raw string. \n No new line here.';
  print(rawString);

  // Nullable String
  String? nullableString; // Can be null
  nullableString = "Hello"; // Can also hold a string value
  print(nullableString); // Prints "Hello"
  nullableString = null; // Now it holds null
  print(nullableString); // Prints null

  // Nullable int
  int? nullableInt; // Can be null
  nullableInt = 42; // Can also hold an integer value
  print(nullableInt); // Prints 42
  nullableInt = null; // Now it holds null
  print(nullableInt); // Prints null

  // Nullable double
  double? nullableDouble; // Can be null
  nullableDouble = 3.14; // Can also hold a double value
  print(nullableDouble); // Prints 3.14
  nullableDouble = null; // Now it holds null
  print(nullableDouble); // Prints null

  // Nullable bool
  bool? nullableBool; // Can be null
  nullableBool = true; // Can also hold a boolean value
  print(nullableBool); // Prints true
  nullableBool = null; // Now it holds null
  print(nullableBool); // Prints null

  // Nullable String with null-aware operators
  String? anotherNullableString; // Nullable
  anotherNullableString = "Hello";
  print(anotherNullableString); // Prints "Hello"
  print(anotherNullableString
      .toString()
      .length); // anotherNullableString is not null here, so '!' is not needed
  print(anotherNullableString
      .length); // anotherNullableString is not null here, so use '.' instead of '?.'

  anotherNullableString = null;
  print(anotherNullableString?.length); // Prints null (safe access)
  print(anotherNullableString ??
      "Default Value"); // Prints "Default Value" (fallback)

  var nullableDoubleV2; // Inferred as `dynamic?` (nullable)
  nullableDoubleV2 = 3.14; // Now holds a double
  nullableDoubleV2 = null; // Can be reassigned to null
  print(nullableDoubleV2); // Use the variable to avoid unused variable warning

  final double? anotherNullableDouble; // Nullable but must be assigned once
  anotherNullableDouble = 3.14; // Allowed
  // anotherNullableDouble = null; // Error: Cannot reassign a final variable
  print(anotherNullableDouble);
}

// Simulates getting user input at runtime
String getUserInput() {
  return 'Hello from user!';
}

/*

"Runtime means the value is not known or fixed when the program is being written (compile time). Instead, it is determined while the program is running, often based on user input, data from another system, or calculations performed during execution."

*/