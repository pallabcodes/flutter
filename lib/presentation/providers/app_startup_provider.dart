import 'package:finwise/data/datasources/local/database/database.dart';
import 'package:finwise/core/config/injection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:injectable/injectable.dart';

/// Provider for app startup state
/// Handles initialization of critical app components
final appStartupProvider = FutureProvider<AppStartupData>((ref) async {
  // Initialize database
  final database = getIt<AppDatabase>();

  // Wait for database to be ready
  await database.customStatement('SELECT 1');

  // Initialize Firebase Auth state (optional)
  User? user;
  try {
    final auth = FirebaseAuth.instance;
    user = auth.currentUser;
  } catch (e) {
    // Firebase not available, continue without auth
  }

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
