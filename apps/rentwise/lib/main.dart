import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:finwise_core/finwise_core.dart';
import 'package:finwise_ui/finwise_ui.dart';
import 'package:finwise_core/animations/meaningful_interactions.dart';
import 'package:rentwise/presentation/screens/dashboard/rental_dashboard_screen.dart';

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
      child: RentWiseApp(),
    ),
  );
}

class RentWiseApp extends StatelessWidget {
  const RentWiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RentWise',
      theme: FinWiseTheme.lightTheme,
      darkTheme: FinWiseTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const RentWiseHomePage(),
      routes: {
        '/dashboard': (context) => const RentalDashboardScreen(),
        '/payments': (context) => const PaymentsScreen(),
        '/documents': (context) => const DocumentsScreen(),
        '/maintenance': (context) => const MaintenanceScreen(),
        '/communication': (context) => const CommunicationScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}

class RentWiseHomePage extends StatefulWidget {
  const RentWiseHomePage({super.key});

  @override
  State<RentWiseHomePage> createState() => _RentWiseHomePageState();
}

class _RentWiseHomePageState extends State<RentWiseHomePage> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Initialize rental services
    // Load user's rental properties
    // Set up payment reminders
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.home_work,
              size: 64,
              color: Colors.blue,
            ),
            SizedBox(height: 24),
            Text(
              'RentWise',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Smart Rental Management',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 48),
            CircularProgressIndicator(),
            SizedBox(height: 24),
            Text('Loading your rental dashboard...'),
          ],
        ),
      ),
    );
  }
}

// Placeholder screens - will be implemented
class PaymentsScreen extends StatelessWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payments')),
      body: const Center(child: Text('Payments Screen - Coming Soon')),
    );
  }
}

class DocumentsScreen extends StatelessWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Documents')),
      body: const Center(child: Text('Documents Screen - Coming Soon')),
    );
  }
}

class MaintenanceScreen extends StatelessWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Maintenance')),
      body: const Center(child: Text('Maintenance Screen - Coming Soon')),
    );
  }
}

class CommunicationScreen extends StatelessWidget {
  const CommunicationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Communication')),
      body: const Center(child: Text('Communication Screen - Coming Soon')),
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
