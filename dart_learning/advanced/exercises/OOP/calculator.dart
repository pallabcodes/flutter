// 1. Compile-Time Polymorphism (Method Overloading)
// Dart does not support method overloading directly (unlike Java or C++), but you can achieve similar behavior using optional parameters or named parameters.
class Calculator {
  // Method with optional parameters to simulate overloading
  int add(int a, [int? b]) {
    if (b != null) {
      return a + b; // Two-parameter addition
    }
    return a; // Single-parameter case
  }
}

void main() {
  Calculator calc = Calculator();

  print(calc.add(5)); // Output: 5 (single parameter)
  print(calc.add(5, 10)); // Output: 15 (two parameters)
}

/**
 * 1. Compile-Time Polymorphism (Method Overloading)
Dart does not support method overloading directly (unlike Java or C++), but you can achieve similar behavior using optional parameters or named parameters.
 * 
 * 
 * 
*/