import 'package:flutter/material.dart';

/// The main page for the currency converter app.
/// Now a StatefulWidget to handle conversion logic and state.
class CurrencyConverterMaterialPage extends StatefulWidget {
  const CurrencyConverterMaterialPage({Key? key}) : super(key: key);

  @override
  State<CurrencyConverterMaterialPage> createState() =>
      _CurrencyConverterMaterialPageState();
}

class _CurrencyConverterMaterialPageState
    extends State<CurrencyConverterMaterialPage> {
  double result = 0;
  final TextEditingController textEditingController = TextEditingController();

  void convert() {
    final input = textEditingController.text;
    if (input.isEmpty) {
      setState(() => result = 0);
      return;
    }
    final value = double.tryParse(input);
    if (value == null) {
      // Optionally show an error or ignore invalid input
      setState(() => result = 0);
      return;
    }
    setState(() {
      result = value * 80;
    });
  }

  @override
  void dispose() {
    textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderSide: const BorderSide(
        width: 2.0,
        style: BorderStyle.solid,
      ),
      borderRadius: BorderRadius.circular(5),
    );

    return Scaffold(
      backgroundColor: Colors.blueGrey,
      appBar: AppBar(
        backgroundColor: Colors.blueGrey,
        elevation: 0,
        title: const Text('Currency Converter'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              MyText(
                'INR ${result != 0 ? result.toStringAsFixed(3) : result.toStringAsFixed(0)}',
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: textEditingController,
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  hintText: 'Please enter the amount in USD',
                  hintStyle: const TextStyle(color: Colors.black),
                  prefixIcon: const Icon(Icons.monetization_on_outlined),
                  prefixIconColor: Colors.black,
                  filled: true,
                  fillColor: Colors.white,
                  focusedBorder: border,
                  enabledBorder: border,
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: convert,
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
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
class MyText extends StatelessWidget {
  final String data;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Color? color;
  final TextAlign? textAlign;

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

/// The form section for currency input and conversion.
/// TODO: Implement CurrencyInput and PrimaryButton widgets.
class ConverterForm extends StatelessWidget {
  const ConverterForm({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // TODO: Replace with actual input widgets
        Placeholder(fallbackHeight: 48, fallbackWidth: 200),
        SizedBox(height: 16),
        Placeholder(fallbackHeight: 48, fallbackWidth: 120),
        // Example:
        // CurrencyInput(...),
        // PrimaryButton(...),
      ],
    );
  }
}
