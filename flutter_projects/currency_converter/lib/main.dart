import 'package:flutter/material.dart';
import 'package:currency_converter/currency_converter_material_page.dart';

/// Just like React, Angular builds its UI components though component-based architecture.
/// This allows for better reusability, testability, and separation of concerns.
/// In Flutter, everything is a widget, and you can compose complex UIs from smaller, reusable components.
/// The widget tree is the core concept in Flutter, where each widget is a part of the UI.
/// Flutter's hot reload feature enables developers to see changes in real-time, enhancing productivity.

/// Understanding Widget Creation and Reuse in Flutter
///
/// Scenario 1 - Without const:
/// ```dart
/// Widget build(BuildContext context) {
///   return Text('Hello'); // New instance created every build
///   // build() can run many times (state changes, parent rebuilds, etc.)
///   // Each time creates a new Text widget in memory
/// }
/// ```
///
/// Scenario 2 - With const:
/// ```dart
/// Widget build(BuildContext context) {
///   return const Text('Hello'); // Same instance reused
///   // No matter how many times build() runs
///   // Flutter reuses the widget instance created at compile time
/// }
/// ```
///
/// Memory Visualization:
/// Without const:
/// Build 1: Text('Hello') → New instance in memory
/// Build 2: Text('Hello') → Another new instance in memory
/// Build 3: Text('Hello') → Yet another new instance in memory
///
/// With const:
/// Compile time: Text('Hello') → Single instance created
/// Build 1: → Reuse same instance
/// Build 2: → Reuse same instance
/// Build 3: → Reuse same instance
///
/// Conclusion: So, without const not only it gets created runtime but it gets created again and again but with const off course it gets created at compile time and also re-used

void main() {
  // Here, runApp method expects its argument to be a Widget, so off course it can be any Widget so here used MyApp i.e. a stateless widget
  runApp(const MyApp());
}

// creating a custom widget

/// StatelessWidget is already annotated with @immutable in Flutter SDK:
///
/// @immutable
/// abstract class StatelessWidget extends Widget {
///   const StatelessWidget({ Key? key }) : super(key: key);
///   ...
/// }
///
/// This means:
/// 1. All fields must be final
/// 2. The class should have a const constructor
/// 3. Objects are immutable once created
/// N.B: Yes, you can use @immutable with CustomText, but it's actually not necessary here because StatelessWidget is already marked as @immutable in Flutter's core i.e. internally.
/// So, marking this StatelessWidget with @immutable is redundant since StatelessWidget enforces immutability by design.

class MyApp2 extends StatelessWidget {
  // Already following immutability rules:
  // - Using final for all fields
  // - Has a const constructor
  final String text;

  const MyApp2(this.text, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textDirection: TextDirection.ltr,
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: CurrencyConverterMaterialPage());
  }
}

// class MyCupertinoApp extends StatelessWidget {
//   const MyCupertinoApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return const CupertinoApp(
//       home: CurrencyConverterCupertinoPage(),
//     );
//   }
// }

/**
 * Key Characteristics of StatelessWidget:
 * 
 * 1. **Immutable**:
 *    - Once created, the widget's state cannot change.
 *    - All properties must be final.
 * 
 * 2. **Lightweight**:
 *    - Designed for widgets that do not require dynamic updates.
 *    - Ideal for static UI elements.
 * 
 * 3. **Rebuilds Efficiently**:
 *    - Rebuilt only when its parent widget rebuilds.
 *    - Flutter optimizes performance by reusing instances when possible (e.g., with `const`).
 * 
 * 4. **No Internal State**:
 *    - Cannot hold or manage any state that changes over time.
 *    - Any changes must come from external sources (e.g., parent widgets).
 * 
 * 5. **Build Method**:
 *    - The `build` method is called to describe the widget's UI.
 *    - Must return a widget tree.
 * 
 * Example:
 * ```dart
 * class MyStatelessWidget extends StatelessWidget {
 *   final String title;
 * 
 *   const MyStatelessWidget(this.title, {Key? key}) : super(key: key);
 * 
 *   @override
 *   Widget build(BuildContext context) {
 *     return Text(title);
 *   }
 * }
 * ```
 */

/**
 * When to Use StatelessWidget:
 * 
 * 1. **Static Content**:
 *    - Use when the widget's content does not change dynamically.
 *    - Example: Displaying a static title or label.
 * 
 * 2. **Pure UI Representation**:
 *    - Use for widgets that only describe the UI and do not manage state.
 *    - Example: Icons, static text, or decorative elements.
 * 
 * 3. **Performance Optimization**:
 *    - Use with `const` constructors to improve performance by reusing widget instances.
 *    - Example: `const Text('Hello')`.
 * 
 * 4. **Parent-Driven Updates**:
 *    - Use when the widget's updates are entirely controlled by its parent.
 *    - Example: A widget that displays data passed from a parent widget.
 */

/**
 * When NOT to Use StatelessWidget:
 * 
 * 1. **Dynamic State**:
 *    - Avoid when the widget needs to manage or update its own state.
 *    - Use `StatefulWidget` instead.
 *    - Example: A counter button that increments on tap.
 * 
 * 2. **User Interaction**:
 *    - Avoid when the widget needs to handle user input and update its UI accordingly.
 *    - Example: A form field or toggle button.
 * 
 * 3. **Animation or Lifecycle**:
 *    - Avoid when the widget needs to manage animations or lifecycle events.
 *    - Example: A widget that animates on screen or listens to lifecycle changes.
 * 
 * 4. **Frequent Updates**:
 *    - Avoid when the widget's content changes frequently and independently of its parent.
 *    - Example: A clock or live data feed.
 */

/**
 * Example of When to Use StatelessWidget:
 */
class StaticTitle extends StatelessWidget {
  final String title;

  const StaticTitle(this.title, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
    );
  }
}

/**
 * Example of When NOT to Use StatelessWidget:
 * Use StatefulWidget instead for dynamic state management.
 */
class CounterButton extends StatefulWidget {
  const CounterButton({Key? key}) : super(key: key);

  @override
  _CounterButtonState createState() => _CounterButtonState();
}

class _CounterButtonState extends State<CounterButton> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _incrementCounter,
      child: Text('Counter: $_counter'),
    );
  }
}
