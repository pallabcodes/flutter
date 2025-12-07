import 'package:flutter/material.dart';

final ThemeData _lightTheme = ThemeData(
  colorSchemeSeed: Colors.blue,
  brightness: Brightness.light,
  useMaterial3: true,
);

final ThemeData _darkTheme = ThemeData(
  colorSchemeSeed: Colors.blue,
  brightness: Brightness.dark,
  useMaterial3: true,
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const CreditWiseApp());
}

class CreditWiseApp extends StatelessWidget {
  const CreditWiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CreditWise',
      theme: _lightTheme,
      darkTheme: _darkTheme,
      themeMode: ThemeMode.system,
      home: const CreditWiseHomePage(),
    );
  }
}

class CreditWiseHomePage extends StatefulWidget {
  const CreditWiseHomePage({super.key});

  @override
  State<CreditWiseHomePage> createState() => _CreditWiseHomePageState();
}

class _CreditWiseHomePageState extends State<CreditWiseHomePage> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Initialize credit monitoring services
    // Check for existing credit reports
    // Set up background sync
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              const Icon(
                Icons.credit_score,
                size: 72,
                color: Colors.blue,
              ),
              const SizedBox(height: 24),
              const Text(
                'CreditWise',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'AI-powered credit insights coming soon.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () {},
                child: const Text('Continue'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {},
                child: const Text('View dashboard (placeholder)'),
              ),
              const SizedBox(height: 48),
              Text(
                'This build uses placeholder screens until shared packages land.',
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
