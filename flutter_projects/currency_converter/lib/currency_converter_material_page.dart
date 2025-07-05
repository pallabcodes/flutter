import 'package:flutter/material.dart'; // Flutter's core UI library

/// The main page for the currency converter app.
/// This is a StatefulWidget because it manages user input and conversion result.
class CurrencyConverterMaterialPage extends StatefulWidget {
  // Short constructor syntax: passes the optional key to the superclass.
  const CurrencyConverterMaterialPage({super.key});

  // This method creates the mutable state for this widget.
  @override
  State<CurrencyConverterMaterialPage> createState() =>
      _CurrencyConverterMaterialPageState();
}

/// The state class holds all mutable state for CurrencyConverterMaterialPage.
/// In Flutter, the State object is where you keep variables that change over time.
class _CurrencyConverterMaterialPageState
    extends State<CurrencyConverterMaterialPage> {
  // Holds the conversion result (INR value).
  double result = 0;

  // Controller for the TextField. Lets you read and control the text input.
  // Similar to useRef in React, but for text input fields.
  final TextEditingController textEditingController = TextEditingController();

  /// Converts the entered USD amount to INR and updates the result. Called when the user presses the "Convert" button.
  void convert() {
    final input = textEditingController
        .text; // Get the current text from the input field.

    if (input.isEmpty) {
      // If the input is empty, reset result to 0.
      setState(() => result = 0);
      return;
    }

    final value =
        double.tryParse(input); // Try to parse the input as a double (number).

    if (value == null) {
      // If parsing fails (invalid input), reset result to 0.
      setState(() => result = 0);
      return;
    }

    // If valid, multiply by 80 to convert USD to INR and update the UI.
    setState(() {
      result = value * 80;
    });
  }

  @override
  void dispose() {
    // Always dispose controllers to free resources when the widget is removed.
    textEditingController.dispose();
    super.dispose();
  }

  // The build method in Flutter is meant to describe what the UI should look like for the current state.
  // It is called every time you call setState() or when the widget’s parent rebuilds.
  // The build method should be pure: given the same state, it should always return the same UI.

  /*
   * ──────────────────────────────────────────────────────────────
   * Why should build() be fast, pure, and side-effect free?
   * ──────────────────────────────────────────────────────────────
   * 
   * ⚡️ Best Practices:
   *   - Only build and return widgets based on the current state.
   *   - Use local UI variables and pure methods that return widgets.
   * 
   * 🚫 Avoid in build():
   *   - Network calls, I/O, or heavy computation
   *   - setState() or any side effects
   *   - Mutating state or blocking operations
   * 
   * 💡 Analogy:
   *   - Think of build() like React's render(): 
   *     It should be predictable, fast, and never cause side effects.
   * 
   * 📌 Summary:
   *   - Keep build() simple and efficient for smooth UI updates.
   */

  @override
  Widget build(BuildContext context) {
    // Defines the border style for the input field.
    final border = OutlineInputBorder(
      borderSide: const BorderSide(
        width: 2.0,
        style: BorderStyle.solid,
      ),
      borderRadius: BorderRadius.circular(5),
    );

    // The main UI for the page.
    return Scaffold(
      backgroundColor:
          Colors.blueGrey, // Sets the background color of the page.
      appBar: AppBar(
        backgroundColor: Colors.blueGrey,
        elevation: 0, // Removes the shadow under the app bar.
        title: const Text('Currency Converter'), // Title at the top of the app.
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(10), // Adds padding around the content.
          child: Column(
            mainAxisSize:
                MainAxisSize.min, // Column takes up minimum vertical space.
            mainAxisAlignment:
                MainAxisAlignment.center, // Center children vertically.
            children: [
              // Shows the conversion result in large, bold text.
              MyText(
                // Shows 3 decimal places if result is not zero, otherwise shows 0.
                'INR ${result != 0 ? result.toStringAsFixed(3) : result.toStringAsFixed(0)}',
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              const SizedBox(height: 16), // Adds vertical space.
              // The input field where the user enters the USD amount.
              TextField(
                controller:
                    textEditingController, // Connects the controller to the field.
                style:
                    const TextStyle(color: Colors.black), // Input text color.
                decoration: InputDecoration(
                  hintText:
                      'Please enter the amount in USD', // Placeholder text.
                  hintStyle: const TextStyle(color: Colors.black),
                  prefixIcon: const Icon(
                      Icons.monetization_on_outlined), // Icon at the start.
                  prefixIconColor: Colors.black,
                  filled: true,
                  fillColor: Colors.white, // Input background color.
                  focusedBorder: border, // Border when focused.
                  enabledBorder: border, // Border when not focused.
                ),
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true), // Numeric keyboard.
              ),
              const SizedBox(height: 16),
              // The "Convert" button.
              SizedBox(
                width: double.infinity, // Button takes full width.
                child: ElevatedButton(
                  onPressed:
                      convert, // Calls the convert() method when pressed.
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    minimumSize:
                        const Size(double.infinity, 50), // Button height.
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  child: const Text('Convert'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A reusable, immutable text widget for consistent styling.
/// Use this instead of Text for consistent font and color across the app.
class MyText extends StatelessWidget {
  final String data;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Color? color;
  final TextAlign? textAlign;

  // Constructor with named optional parameters for style.
  const MyText(
    this.data, {
    Key? key,
    this.fontSize,
    this.fontWeight,
    this.color,
    this.textAlign,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      data,
      textAlign: textAlign,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      ),
    );
  }
}
