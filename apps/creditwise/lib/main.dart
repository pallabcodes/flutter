import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:finwise_core/finwise_core.dart';
import 'package:finwise_ui/finwise_ui.dart';
import 'package:finwise_core/animations/meaningful_interactions.dart';
import 'package:creditwise/presentation/screens/dashboard/credit_dashboard_screen.dart';
import 'package:creditwise/presentation/screens/recommendations/recommendations_screen.dart';

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
      child: CreditWiseApp(),
    ),
  );
}

class CreditWiseApp extends StatelessWidget {
  const CreditWiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CreditWise',
      theme: FinWiseTheme.lightTheme,
      darkTheme: FinWiseTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const CreditWiseHomePage(),
      routes: {
        '/dashboard': (context) => const CreditDashboardScreen(),
        '/report': (context) => const CreditReportScreen(),
        '/recommendations': (context) => const RecommendationsScreen(),
        '/education': (context) => const EducationScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
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
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.credit_score,
              size: 64,
              color: Colors.blue,
            ),
            SizedBox(height: 24),
            Text(
              'CreditWise',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'AI-Powered Credit Optimization',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 48),
            CircularProgressIndicator(),
            SizedBox(height: 24),
            Text('Loading your credit insights...'),
          ],
        ),
      ),
    );
  }
}

// Placeholder screens - will be implemented
class CreditReportScreen extends StatelessWidget {
  const CreditReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Credit Report')),
      body: const Center(child: Text('Credit Report Screen - Coming Soon')),
    );
  }
}

class RecommendationsScreen extends StatelessWidget {
  const RecommendationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recommendations')),
      body: const Center(child: Text('AI Recommendations - Coming Soon')),
    );
  }
}

class EducationScreen extends StatelessWidget {
  const EducationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Education')),
      body: const Center(child: Text('Credit Education - Coming Soon')),
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
