import 'package:finwise/data/datasources/local/database/database.dart'; // database initialization
import 'package:firebase_auth/firebase_auth.dart'; // firebase authentication
import 'package:flutter_riverpod/flutter_riverpod.dart'; // async state
import 'package:injectable/injectable.dart'; // code generation (though not directly used here )

// Provider for app startup state and handles initialization of critical app components
// This file handles the critical app initialization that occurs after main.dart but before the UI is shown.
final appStartupProvider = FutureProvider<AppStartupData>((ref) async {
  // Initialize database
  final database = AppDatabase();

  // Wait for database to be ready
  await database.customStatement('SELECT 1');

  // Initialize Firebase Auth state
  final auth = FirebaseAuth.instance;
  final user = auth.currentUser;

  return AppStartupData(
    isDatabaseReady: true,
    currentUser: user,
    isAuthenticated: user != null,
  );
});

/// Data class containing app startup information
class AppStartupData {
  final bool isDatabaseReady;
  final User? currentUser;
  final bool isAuthenticated;

  const AppStartupData({
    required this.isDatabaseReady,
    required this.currentUser,
    required this.isAuthenticated,
  });

  /// Check if app is fully initialized and ready
  bool get isReady => isDatabaseReady;

  /// Get user ID if authenticated
  String? get userId => currentUser?.uid;
}
