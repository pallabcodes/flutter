import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:finwise_core/finwise_core.dart';
import 'package:finwise_ui/finwise_ui.dart';
import 'package:finwise_core/animations/meaningful_interactions.dart';
import 'package:investwise/presentation/screens/portfolio/portfolio_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize shared services
  await FinWiseCore.initialize();

  // Initialize Firebase Messaging for notifications
  await FirebaseMessaging.instance.requestPermission();
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  runApp(
    const ProviderScope(
      child: InvestWiseApp(),
    ),
  );
}

class InvestWiseApp extends StatelessWidget {
  const InvestWiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InvestWise',
      theme: FinWiseTheme.lightTheme,
      darkTheme: FinWiseTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const InvestWiseHomePage(),
      routes: {
        '/portfolio': (context) => const PortfolioDashboardScreen(),
        '/discover': (context) => const DiscoverScreen(),
        '/goals': (context) => const GoalsScreen(),
        '/education': (context) => const EducationScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}

class InvestWiseHomePage extends StatefulWidget {
  const InvestWiseHomePage({super.key});

  @override
  State<InvestWiseHomePage> createState() => _InvestWiseHomePageState();
}

class _InvestWiseHomePageState extends State<InvestWiseHomePage> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Initialize investment services
    // Load user's portfolio
    // Set up market data feeds
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.trending_up,
              size: 64,
              color: Colors.green,
            ),
            SizedBox(height: 24),
            Text(
              'InvestWise',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'AI-Powered Micro-Investing',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 48),
            CircularProgressIndicator(),
            SizedBox(height: 24),
            Text('Loading your investment portfolio...'),
          ],
        ),
      ),
    );
  }
}

// Placeholder screens - will be implemented
class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Discover')),
      body: const Center(child: Text('Discover Screen - Coming Soon')),
    );
  }
}

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Investment Goals')),
      body: const Center(child: Text('Goals Screen - Coming Soon')),
    );
  }
}

class EducationScreen extends StatelessWidget {
  const EducationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Learn')),
      body: const Center(child: Text('Education Screen - Coming Soon')),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const Center(child: Text('Settings Screen - Coming Soon')),
    );
  }
}
