import 'dart:async';
import 'dart:convert'; // For JSON decoding
import 'dart:isolate';

import 'package:http/http.dart' as http;

/// Typedef for function signatures.
typedef IntOperation = int Function(int a, int b);

/// Basic arithmetic functions.
int add(int a, int b) => a + b;
int subtract(int a, int b) => a - b;

/// Demonstrates optional positional parameters.
String greetOptionalParameterWithPos(String name, [String? title]) {
  return title != null ? "Hello, $title $name" : "Hello, $name";
}

/// Demonstrates optional named parameters.
String greetWithOptionalNamedParameters({required String name, String? title}) {
  return title != null ? "Hello, $title $name" : "Hello, $name";
}

/// Demonstrates default parameter values.
String greet(String name, [String title = "Mr./Ms."]) {
  return "Hello, $title $name";
}

/// Higher-order function that accepts a callback.
void execute(Function callback) {
  callback();
}

/// Example callback function.
void sayHello() {
  print("Hello!");
}

/// Returns a function that multiplies a value by a given factor.
Function multiplier(int factor) {
  return (int value) => value * factor;
}

/// Returns a function that adds a value to a given number.
Function makeAdder(int addBy) {
  return (int i) => i + addBy;
}

/// Demonstrates asynchronous programming with `Future`.
Future<String> fetchData() async {
  await Future.delayed(Duration(seconds: 2));
  return "Data fetched!";
}

/// Demonstrates error handling in asynchronous operations.
Future<void> fetchWithErrorHandling() async {
  try {
    await Future.delayed(Duration(seconds: 1));
    throw Exception("An error occurred while fetching data.");
  } catch (e) {
    print("Caught error: $e");
  } finally {
    print("Fetch operation completed.");
  }
}

/// Demonstrates `Future.any` and `Future.wait`.
Future<void> demonstrateFutureUtilities() async {
  // `Future.any` example: Resolves with the first completed future. Similar to Promise.race in JS
  final firstCompleted = await Future.any([
    Future.delayed(Duration(seconds: 2), () => "First"),
    Future.delayed(Duration(seconds: 1), () => "Second"),
  ]);
  print("First completed: $firstCompleted");

  // `Future.wait` example: Resolves when all futures complete. Similart to Promise.all in JS
  final allResults = await Future.wait([
    Future.delayed(Duration(seconds: 1), () => "Task 1"),
    Future.delayed(Duration(seconds: 2), () => "Task 2"),
  ]);

  print("All results: $allResults");
}

/// Synchronous generator function.
Iterable<int> syncGenerator() sync* {
  for (int i = 1; i <= 3; i++) {
    yield i;
  }
}

/// Asynchronous generator function.
Stream<int> asyncGenerator() async* {
  for (int i = 1; i <= 3; i++) {
    await Future.delayed(Duration(seconds: 1));
    yield i;
  }
}

/// Demonstrates nullable types and null-aware operators.
String? getNullableString(bool returnNull) {
  return returnNull ? null : "Hello";
}

void printMessage(String? message) {
  print(message ?? "Default Message");
}

/// Recursive function to calculate factorial.
int factorial(int n) {
  if (n <= 1) return 1;
  return n * factorial(n - 1);
}

/// Extension method to reverse a string.
extension StringExtension on String {
  String reverse() => split('').reversed.join();
}

/// Demonstrates Dart's record types (introduced in Dart 3.0).
(int, String) printName() {
  return (12, 'John');
}

({int id, String name}) printNameV2() {
  return (id: 12, name: 'John');
}

(int, {String name}) mixedRecord() {
  return (42, name: 'Alice');
}

/// Generic function to swap two values.
(T, U) swap<T, U>(T first, U second) {
  return (first, second); // Ensure the return type matches (T, U)
}

/// Generic function to get the first element of a list.
T getFirst<T>(List<T> items) {
  return items[0];
}

/// Generic class with a type parameter.
class Box<T> {
  T value;

  Box(this.value);

  void display() {
    print("Value: $value");
  }
}

/// Demonstrates generic constraints with type bounds.
class Shape {
  void draw() => print("Drawing a shape");
}

class Circle extends Shape {
  @override
  void draw() => print("Drawing a circle");
}

void drawShape<T extends Shape>(T shape) {
  shape.draw();
}

/// Demonstrates destructuring with records.
(int, String) getPersonTuple() {
  return (25, "Alice");
}

({int id, String name}) getPersonRecord() {
  return (id: 1, name: "Alice");
}

/// Demonstrates stream transformations. Streams in Dart are similar to Observable in RxJS or EventEmitter in Node.js.
Stream<int> numberStream() async* {
  for (int i = 1; i <= 5; i++) {
    await Future.delayed(Duration(seconds: 1));
    yield i;
  }
}

Stream<int> debounce(Stream<int> stream, Duration duration) {
  StreamController<int>? controller;
  Timer? debounceTimer;
  StreamSubscription<int>? subscription;

  controller = StreamController<int>(
    onListen: () {
      subscription = stream.listen(
          (event) {
            debounceTimer?.cancel();
            debounceTimer = Timer(duration, () {
              controller?.add(event);
            });
          },
          onError: controller?.addError,
          onDone: () {
            debounceTimer?.cancel();
            controller?.close();
          });
    },
    onPause: () => subscription?.pause(),
    onResume: () => subscription?.resume(),
    onCancel: () async {
      debounceTimer?.cancel();
      await subscription?.cancel();
    },
  );

  return controller.stream;
}

/// Demonstrates parallel processing with isolates.
Future<void> demonstrateIsolate() async {
  final receivePort = ReceivePort();
  await Isolate.spawn(isolateTask, receivePort.sendPort);

  // Listen for messages from the isolate.
  await for (final message in receivePort) {
    print("Message from isolate: $message");
    if (message == "done") {
      receivePort.close();
    }
  }
}

void isolateTask(SendPort sendPort) {
  for (int i = 1; i <= 5; i++) {
    sendPort.send("Task $i completed");
  }
  sendPort.send("done");
}

/// Demonstrates batching in streams.
Stream<List<int>> batchStream(Stream<int> stream, int batchSize) async* {
  List<int> batch = [];
  await for (final value in stream) {
    batch.add(value);
    if (batch.length == batchSize) {
      yield List<int>.from(batch);
      batch.clear();
    }
  }
  if (batch.isNotEmpty) {
    yield List<int>.from(batch);
  }
}

/// Demonstrates an actual API request using the `http` package.
Future<void> fetchApiData() async {
  const url = 'https://jsonplaceholder.typicode.com/posts/1'; // Example API
  try {
    // Make a GET request
    final response = await http.get(Uri.parse(url));

    // Check if the request was successful
    if (response.statusCode == 200) {
      // Decode the JSON response
      final data = jsonDecode(response.body);
      print('API Response: $data');
    } else {
      print('Failed to fetch data. Status code: ${response.statusCode}');
    }
  } catch (e) {
    print('Error occurred while making the API request: $e');
  }
}

/// Option 1: Simplest - Direct creation
// Future<Future<String>> futureOfFuture() {
//   return Future.value(Future.value("Nested future result!"));
// }

/// Option 2: Using async/await - More readable
Future<Future<String>> futureOfFuture() async {
  return Future.delayed(Duration(seconds: 1),
      () => Future.value("Nested future result!" as FutureOr<Future<String>>?));
}

/// Option 3: Using Completer - More control
// Future<Future<String>> futureOfFuture() {
//   final completer = Completer<Future<String>>();
//   completer.complete(Future.value("Nested future result!"));
//   return completer.future;
// }

/// Option 4: Your current version - Explicit with delay
// Future<Future<String>> futureOfFuture() {
//   return Future<Future<String>>.value(Future<String>.delayed(
//       Duration(seconds: 1), () => "Nested future result!"));
// }

/// Example usage of functions and advanced Dart features.
void main() async {
  // Asynchronous function example.
  print("Fetching...");
  String data = await fetchData();
  print(data); // Prints: Data fetched!

  // Error handling in asynchronous operations.
  await fetchWithErrorHandling();

  // Demonstrate `Future.any` and `Future.wait`.
  await demonstrateFutureUtilities();

  // Stream transformations.
  final stream = numberStream();
  await for (final value in debounce(stream, Duration(seconds: 2))) {
    print("Debounced value: $value");
  }

  // Parallel processing with isolates.
  await demonstrateIsolate();

  // Batching in streams.
  final batchedStream = batchStream(numberStream(), 2);
  await for (final batch in batchedStream) {
    print("Batch: $batch");
  }

  // Typedef and function assignment.
  IntOperation operation = add;
  print(operation(2, 3)); // Prints: 5

  operation = subtract;
  print(operation(5, 2)); // Prints: 3

  // Optional parameters.
  print(greetOptionalParameterWithPos("Alice")); // Prints: Hello, Alice
  print(greetOptionalParameterWithPos(
      "Alice", "Dr.")); // Prints: Hello, Dr. Alice
  print(
      greetWithOptionalNamedParameters(name: "Alice")); // Prints: Hello, Alice
  print(greetWithOptionalNamedParameters(
      name: "Alice", title: "Dr.")); // Prints: Hello, Dr. Alice
  print(greet("Alice")); // Prints: Hello, Mr./Ms. Alice
  print(greet("Alice", "Dr.")); // Prints: Hello, Dr. Alice

  // Higher-order functions.
  execute(sayHello); // Prints: Hello!

  var triple = multiplier(3);
  print(triple(4)); // Prints: 12

  var add5 = makeAdder(5);
  print(add5(3)); // Prints: 8

  // Generators.
  for (var value in syncGenerator()) {
    print(value); // Prints: 1, 2, 3
  }

  await for (var value in asyncGenerator()) {
    print(value); // Prints: 1, 2, 3 with a delay
  }

  // Nullable types and null-aware operators.
  print(getNullableString(false)); // Prints: Hello
  print(getNullableString(true)); // Prints: null
  printMessage(null); // Prints: Default Message
  printMessage("Hello!"); // Prints: Hello!

  // Recursive function.
  print(factorial(5)); // Prints: 120

  // Extension methods.
  print("hello".reverse()); // Prints: olleh

  // Records.
  var record = printName();
  print(record.$1); // Access the first value (12)
  print(record.$2); // Access the second value (John)

  var recordV2 = printNameV2();
  print(recordV2.id); // Access the `id` field (12)
  print(recordV2.name); // Access the `name` field (John)

  var mixed = mixedRecord();
  print(mixed.$1); // Access the first value (42)
  print(mixed.name); // Access the `name` field (Alice)

  // Generic functions.
  var swapped = swap<int, String>(42, "Hello");
  print(swapped.$1); // Prints: Hello
  print(swapped.$2); // Prints: 42

  print(getFirst<int>([1, 2, 3])); // Prints: 1
  print(getFirst<String>(['Alice', 'Bob'])); // Prints: Alice

  // Generic class.
  var intBox = Box<int>(42);
  intBox.display(); // Prints: Value: 42

  var stringBox = Box<String>("Hello");
  stringBox.display(); // Prints: Value: Hello

  // Generic constraints.
  drawShape(Circle()); // Prints: Drawing a circle

  // Destructuring with records.
  var (age, name) = getPersonTuple();
  print("Age: $age, Name: $name"); // Prints: Age: 25, Name: Alice

  var (id: personId, name: personName) = getPersonRecord();
  print("ID: $personId, Name: $personName"); // Prints: ID: 1, Name: Alice

  print("Fetching data from API...");
  await fetchApiData(); // Demonstrates an actual API request
  print("API request completed.");

  // Demonstrate Future<Future<T>>
  print("Demonstrating Future<Future<T>>...");
  Future<Future<String>> nested = futureOfFuture();
  // Awaiting once gives you a Future<String>
  Future<String> inner = await nested;
  // Awaiting again gives you the actual value
  String value = await inner;
  print(value); // Prints: Nested future result!

  // Or, you can flatten with double await:
  String flattened = await await futureOfFuture();
  print(flattened); // Prints: Nested future result!

  // Demonstrate Future<Future<T>> with .then()
  print("Demonstrating Future<Future<T>> with .then()...");
  futureOfFuture().then((innerFuture) {
    innerFuture.then((value) {
      print("With .then(): $value"); // Prints: Nested future result!
    });
  });
}
