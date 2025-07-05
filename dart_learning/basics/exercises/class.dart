import 'package:meta/meta.dart'; // Import for @immutable annotation

// Interface Segregation
abstract class VehicleInterface {
  // Public abstract methods
  void drive();
  void park();
}

abstract class Maintenance {
  void performMaintenance();
  bool needsMaintenance();
}

abstract class VehicleMonitor {
  void recordSpeed(int speed);
  void recordLocation(String location);
}

// Single Responsibility
mixin Logger {
  void log(String message) => print('LOG: $message');
}

mixin Tracker {
  DateTime _lastUsed = DateTime.now();

  void track() {
    _lastUsed = DateTime.now();
    print('Last used: $_lastUsed');
  }
}

// Enhanced Vehicle class
abstract class Vehicle implements VehicleInterface {
  // Protected static constant (still private in Dart)
  static const int _MAX_SPEED = 200;

  // Public static method
  static bool isValidSpeed(int speed) {
    return speed <= _MAX_SPEED && speed >= 0;
  }

  // Already had these abstract methods
  void start();
  void stop();

  // Abstract getter
  String get vehicleType;

  // Default implementation (can be overridden)
  void accelerate() {
    print('Vehicle is accelerating');
  }

  // Add the move method
  void move(); // Abstract method that subclasses must implement
}

// Enhanced Car class
class Car extends Vehicle implements Maintenance {
  // Private fields (already using _)
  final String _brand;
  final String _model;
  int _mileage;
  int _currentSpeed = 0;
  static const int _maintenanceThreshold = 10000;

  // Named constructor
  Car.withBrandModel(this._brand, this._model) : _mileage = 0;

  // Factory constructor
  factory Car.tesla() {
    return Car.withBrandModel('Tesla', 'Model S');
  }

  // Getter (computed property)
  String get vehicleType => 'Car';

  // Setter
  set mileage(int value) {
    if (value < 0) throw ArgumentError('Mileage cannot be negative');
    _mileage = value;
  }

  // New public getter with computation
  String get fullName => '$_brand $_model';

  // New public getter with validation
  int get currentSpeed => _currentSpeed;

  // Enhanced setter with validation
  set currentSpeed(int value) {
    if (!Vehicle.isValidSpeed(value)) {
      throw ArgumentError('Speed must be between 0 and ${Vehicle._MAX_SPEED}');
    }
    _currentSpeed = value;
  }

  // Static factory method
  static Car createLuxuryCar() {
    return Car.withBrandModel('Rolls Royce', 'Phantom');
  }

  // Implementation of abstract methods
  @override
  void start() {
    print('$_brand $_model is starting');
  }

  @override
  void stop() {
    print('$_brand $_model is stopping');
  }

  // Implementation of interface methods
  @override
  void performMaintenance() {
    print('Performing maintenance on $_brand $_model');
    _mileage = 0;
  }

  @override
  bool needsMaintenance() {
    return _mileage >= _maintenanceThreshold;
  }

  // Method with named parameters
  void updateInfo({String? brand, String? model}) {
    print('Updating info for $_brand $_model');
  }

  // Implementing interface methods
  @override
  void drive() {
    if (_currentSpeed == 0) {
      print('Starting to drive $fullName');
    }
  }

  @override
  void park() {
    _currentSpeed = 0;
    print('Parking $fullName');
  }

  @override // Keep this as it's implementing Vehicle's abstract method
  void move() {
    if (_currentSpeed > 0) {
      print('$fullName is moving at $_currentSpeed km/h');
    } else {
      print('$fullName is stationary');
    }
  }
}

// Make sure the Container class is defined before it's used
class Container<T> {
  final T _value;

  Container(this._value);

  T get value => _value;
}

// Enhanced ElectricCar
class ElectricCar extends Car with Logger, Tracker {
  // Private static constant
  static const int _MAX_BATTERY_LEVEL = 100;

  // Private field
  int _batteryLevel;

  // Public static getter
  static int get maxBatteryLevel => _MAX_BATTERY_LEVEL;

  // Public getter with validation and logging
  int get batteryLevel {
    log('Battery level checked'); // Using mixin method
    return _batteryLevel;
  }

  // Public setter with validation
  set batteryLevel(int value) {
    if (value < 0 || value > _MAX_BATTERY_LEVEL) {
      throw ArgumentError(
          'Battery level must be between 0 and $_MAX_BATTERY_LEVEL');
    }
    _batteryLevel = value;
  }

  ElectricCar(String brand, String model)
      : _batteryLevel = 100,
        super.withBrandModel(brand, model);

  // Method showing super call
  @override
  void start() {
    super.start();
    log('Electric motor started'); // From Logger mixin
    track(); // From Tracker mixin
  }
}

/**
 * Implements the Singleton Pattern for car creation.
 * Ensures only one instance of CarFactory exists throughout the application.
 * 
 * Pattern Purpose:
 * - Maintains a single source of truth for car creation
 * - Prevents multiple instances of the factory
 * - Controls access to the shared resource
 * 
 * Usage Example:
 * ```dart
 * final factory = CarFactory(); // Always returns the same instance
 * var car = factory.createCar('BMW', 'M3');
 * ```
 * 
 * TypeScript Equivalent:
 * ```typescript
 * class CarFactory {
 *   private static instance: CarFactory;
 *   private constructor() {}
 * 
 *   public static getInstance(): CarFactory {
 *     if (!CarFactory.instance) {
 *       CarFactory.instance = new CarFactory();
 *     }
 *     return CarFactory.instance;
 *   }
 * 
 *   public createCar(brand: string, model: string): Car {
 *     return new Car(brand, model);
 *   }
 * }
 * ```
 */
class CarFactory {
  /// The single instance of CarFactory that will be reused.
  /// Static and final to ensure it's initialized once and cannot be changed.
  static final CarFactory _instance = CarFactory._internal();

  /// Private constructor to prevent direct instantiation.
  /// Named with underscore to follow Dart's privacy convention.
  CarFactory._internal();

  /// Factory constructor that returns the singleton instance.
  /// This is the public way to get the CarFactory instance.
  ///
  /// Returns:
  ///   The single instance of [CarFactory].
  factory CarFactory() {
    return _instance;
  }

  /// Creates a new car instance with the specified brand and model.
  ///
  /// Parameters:
  ///   [brand] - The manufacturer of the car (e.g., 'BMW', 'Tesla')
  ///   [model] - The specific model of the car (e.g., 'M3', 'Model S')
  ///
  /// Returns:
  ///   A new [Car] instance with the specified parameters.
  ///
  /// Example:
  /// ```dart
  /// final factory = CarFactory();
  /// final bmw = factory.createCar('BMW', 'M3');
  /// ```
  Car createCar(String brand, String model) {
    return Car.withBrandModel(brand, model);
  }
}

/**
 * Represents immutable specifications for a car.
 * All properties are final to ensure immutability.
 * Annotated with @immutable to enforce immutability at compile time.
 * 
 * TypeScript Equivalent:
 * ```typescript
 * interface CarSpecsProps {
 *   readonly engine: string;
 *   readonly horsepower: number;
 *   readonly acceleration: number;
 * }
 * 
 * class CarSpecs {
 *   readonly engine: string;
 *   readonly horsepower: number;
 *   readonly acceleration: number;
 * 
 *   constructor(props: CarSpecsProps) {
 *     this.engine = props.engine;
 *     this.horsepower = props.horsepower;
 *     this.acceleration = props.acceleration;
 *     Object.freeze(this); // Make instance immutable
 *   }
 * 
 *   equals(other: CarSpecs): boolean {
 *     return this.engine === other.engine &&
 *            this.horsepower === other.horsepower &&
 *            this.acceleration === other.acceleration;
 *   }
 * }
 * ```
 */
@immutable
class CarSpecs {
  /// The engine specification (e.g., 'V8', 'Electric')
  final String engine;

  /// The horsepower rating of the car
  final int horsepower;

  /// The 0-60 mph acceleration time in seconds
  final double acceleration;

  /// Creates an immutable CarSpecs instance.
  /// Uses const constructor to allow compile-time constant creation.
  ///
  /// Parameters are required to ensure complete specification.
  const CarSpecs({
    required this.engine,
    required this.horsepower,
    required this.acceleration,
  });

  /// Implements value equality for CarSpecs.
  /// Two specs are equal if all their properties are equal.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CarSpecs &&
          engine == other.engine &&
          horsepower == other.horsepower &&
          acceleration == other.acceleration;

  /// Implements consistent hash code for equality comparison.
  /// Uses Object.hash to generate a combined hash of all properties.
  @override
  int get hashCode => Object.hash(engine, horsepower, acceleration);
}

// Enhanced Enums
enum CarType {
  sedan(doors: 4),
  coupe(doors: 2);

  final int doors;
  const CarType({required this.doors});
}

// Extension Methods
extension CarExtension on Car {
  void printDetails() {
    print('Vehicle Type: $vehicleType');
  }
}

// "Nobody can extend this class"
final class BankAccount {
  double _balance = 0;

  double get balance => _balance;

  void deposit(double amount) {
    if (amount > 0) _balance += amount;
  }
}

// "This class can only be extended, not implemented"
sealed class Shape {
  void draw();
}

// "This class can only be implemented, not extended"
abstract interface class DatabaseConnector {
  void connect();
}

// "This class is meant to be mixed in"
mixin class Loggable {
  void log(String message) => print(message);
}

// Nobody can extend this
final class CarSettings {
  static const int MAX_SPEED = 200;
  static const int MIN_SPEED = 0;
}

// Can only be used in this file
base class CarHelper {
  static void validateSpeed(int speed) {
    if (speed < CarSettings.MIN_SPEED || speed > CarSettings.MAX_SPEED) {
      throw ArgumentError('Invalid speed');
    }
  }
}

// Can only be extended, not implemented
sealed class ElectricVehicle {
  void charge();
}

// Mixin that can also be used as a class
mixin class Diagnostics {
  void runDiagnostics() {
    print('Running diagnostics...');
  }
}

// Using them together
class Tesla extends ElectricVehicle
    with Logger, Diagnostics
    implements VehicleMonitor {
  @override
  void charge() {
    log('Charging started');
    runDiagnostics();
  }

  @override
  void recordSpeed(int speed) {
    CarHelper.validateSpeed(speed);
    log('Speed recorded: $speed');
  }

  @override
  void recordLocation(String location) {
    log('Location recorded: $location');
  }
}

// Immutable class for Vehicle specifications
@immutable
abstract class VehicleSpecs {
  final String type;
  final int wheels;

  const VehicleSpecs(this.type, this.wheels);
}

void main() {
  // First tesla instance
  final teslaModel = Car.tesla();

  // Using factory pattern
  final carFactory = CarFactory();
  final customCar = carFactory.createCar('BMW', 'M3');
  customCar.start();

  // Later in the code...
  final teslaElectric = ElectricCar('Tesla', 'Model S'); // Renamed from tesla
  print(
      'Max Battery Level: ${ElectricCar.maxBatteryLevel}'); // Using static getter

  // Testing interface implementation
  teslaElectric.drive(); // Use renamed variable
  teslaElectric.park();

  // Using immutable class
  const specs = CarSpecs(
    engine: 'V8',
    horsepower: 500,
    acceleration: 3.2,
  );
  print(
      'Car Specs: ${specs.engine}, ${specs.horsepower}hp, ${specs.acceleration}s'); // Using the specs instance

  // Demonstrating polymorphism
  List<Vehicle> vehicles = [teslaModel, teslaElectric];
  for (var vehicle in vehicles) {
    vehicle.move(); // Use move instead of start
  }

  // Using extension method
  teslaModel.printDetails();

  // Using enum
  print('Sedan doors: ${CarType.sedan.doors}');

  // Using generics
  final Container<int> intContainer = Container<int>(42);
  print('Container value: ${intContainer.value}');

  // Error handling
  try {
    teslaModel.mileage = -1; // Will throw ArgumentError
  } catch (e) {
    print('Error: $e');
  }

  // Testing new features
  final luxuryCar = Car.createLuxuryCar(); // Using static factory method
  print(luxuryCar.fullName); // Using public getter

  try {
    luxuryCar.currentSpeed = 250; // Will throw error due to setter validation
  } catch (e) {
    print('Error: $e');
  }

  // Testing speed validation
  print(
      'Is 150 a valid speed? ${Vehicle.isValidSpeed(150)}'); // Using static method

  // Nullable String example
  String? nullableString; // Can be null

  // When you know the value is not null
  nullableString = "Hello";
  print(nullableString.length); // Direct access when we know it's not null

  // When the value might be null
  nullableString = null;
  print(nullableString?.length ?? 0); // Safe access when might be null
  print(nullableString ?? "Default Value"); // Provide default when null

  // For chained operations when value might be null
  String? maybeNull;
  // ignore: dead_code
  print(maybeNull?.toLowerCase() ?? "No value"); // Correct use of null safety

  // For double
  double? nullableDouble = 3.14;
  print(nullableDouble.toString().length); // When we know it's not null

  nullableDouble = null;
  print(nullableDouble?.toString().length ?? 0); // When it might be null
}

/**
 * This implementation showcases:
 * 
 * Abstraction: Abstract classes and methods
 * Encapsulation: Private fields and methods
 * Inheritance: Class extension and implementation
 * Polymorphism: Method overriding
 * Interfaces: Implicit interfaces
 * Mixins: Reusable code blocks
 * Generics: Type-safe containers
 * Factory Pattern: Singleton implementation
 * Immutability: With const constructors
 * Extension Methods: Adding functionality to existing classes
 * Enhanced Enums: With fields and methods
 * Error Handling: Try-catch blocks
 * Type Safety: Strong typing throughout
 * Named Constructors: Alternative construction methods
 * Getter/Setter: Computed properties
 * Static Members: Shared across instances
 * Named Parameters: Flexible method calls
 * Operator Overloading: Custom equality
 * Hash Code Implementation: Proper object identity
 * Final and Const: Immutability control
 * This implementation would demonstrate to senior engineers that you understand:
 * 
 * Clean code principles
 * SOLID principles
 * Design patterns
 * Type safety
 * Memory management
 * Performance considerations
 * Code organization
 * Best practices in Dart
 *
 */
