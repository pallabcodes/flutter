void main() {
  // 1. late: Deferred initialization
  late String lateVariable;
  lateVariable = "Initialized later";
  print("Late variable: $lateVariable");

  // 2. final: Can only be set once
  final String finalVariable = "This is a final variable";
  print("Final variable: $finalVariable");

  // Uncommenting the next line will cause an error
  // finalVariable = "Trying to change final variable";

  // 3. const: Compile-time constant
  const String constVariable = "This is a const variable";
  print("Const variable: $constVariable");

  // Uncommenting the next line will cause an error
  // constVariable = "Trying to change const variable";

  // Difference between final and const
  final DateTime now = DateTime.now(); // Allowed, as final is runtime constant
  print("Final DateTime: $now");

  // Uncommenting the next line will cause an error
  // const DateTime compileTimeNow = DateTime.now(); // Not allowed, as const requires compile-time constant

  // Example of const with compile-time constant
  const int compileTimeConstant = 42;
  print("Compile-time constant: $compileTimeConstant");
}
