class Shape {
  // Compile-time polymorphism using optional parameters
  double area(double length, [double? width]) {
    if (width != null) {
      return length * width; // Rectangle area
    }
    return length * length; // Square area
  }
}

class Circle extends Shape {
  final double radius;

  Circle(this.radius);

  // Runtime polymorphism using method overriding
  @override
  double area(double length, [double? width]) {
    return 3.14159 * radius * radius; // Circle area
  }
}

void main() {
  Shape square = Shape();
  print("Square area: ${square.area(4)}"); // Output: 16 (compile-time decision)

  Shape rectangle = Shape();
  print("Rectangle area: ${rectangle.area(4, 5)}"); // Output: 20 (compile-time decision)

  Shape circle = Circle(3);
  print("Circle area: ${circle.area(0)}"); // Output: 28.27431 (runtime decision)
}

/*
Key Differences in Code:
Aspect	Compile-Time Polymorphism	Runtime Polymorphism
Example	Method overloading (simulated in Dart)	Method overriding
Decision Time	At compile time	At runtime
Flexibility	Less flexible	More flexible


*/