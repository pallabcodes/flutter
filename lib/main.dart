import 'package:finwise/core/accessibility/localized_app.dart';
import 'package:finwise/core/config/app_config.dart';
import 'package:finwise/core/config/injection.dart';
import 'package:finwise/core/monitoring/analytics_service.dart';
import 'package:finwise/core/monitoring/health_monitor.dart';
import 'package:finwise/core/monitoring/monitoring_dashboard.dart';
import 'package:finwise/core/monitoring/performance_monitor.dart';
import 'package:finwise/core/navigation/app_router.dart';
import 'package:finwise/core/navigation/route_guard.dart';
import 'package:finwise/presentation/providers/app_startup_provider.dart';
import 'package:finwise/presentation/providers/auth_providers.dart';
import 'package:finwise/presentation/providers/expense_providers.dart';
import 'package:finwise/presentation/theme/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Production-ready main entry point for FinWise
/// Implements enterprise-grade error handling, logging, and initialization
void main() async {
  final appStartTime = DateTime.now();
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize date formatting for localization
  await initializeDateFormatting();

  // Skip Firebase initialization completely - not needed for basic app functionality
  // Uncomment below if you want to use Firebase:
  /*
  try {
    await Firebase.initializeApp();
    await _configureCrashlytics();
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }
  */

  // Initialize dependency injection
  await configureDependencies();

  // Initialize monitoring services
  final performanceMonitor = getIt<PerformanceMonitor>();
  final analyticsService = getIt<AnalyticsService>();
  final healthMonitor = getIt<HealthMonitor>();

  await Future.wait([
    performanceMonitor.initialize(),
    analyticsService.initialize(),
    healthMonitor.initialize(),
  ]);

  // Record app startup time
  final startupTime = DateTime.now().difference(appStartTime);
  performanceMonitor.recordAppStartup(startupTime);

  // Track app open event
  analyticsService.trackUserAction('app_open', category: 'lifecycle');

  runApp(
    ProviderScope(
      observers: kDebugMode ? [AppProviderObserver()] : null,
      child: const FinWiseApp(),
    ),
  );
}

/// Configure Firebase Crashlytics for production error reporting
Future<void> _configureCrashlytics() async {
  if (kDebugMode) {
    // Disable Crashlytics in debug mode to avoid spam
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);
  } else {
    // Enable Crashlytics in production
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

    // Pass all uncaught errors to Crashlytics
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  }

  // Catch async errors
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
}

/// Main application widget with Riverpod integration
class FinWiseApp extends ConsumerWidget {
  const FinWiseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appStartupState = ref.watch(appStartupProvider);

    return appStartupState.maybeWhen(
      data: (_) => LocalizedAccessibleApp(
        lightTheme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        child: Builder(
          builder: (context) => MaterialApp(
            title: AppConfig.appName,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system,
            debugShowCheckedModeBanner: false,
            navigatorKey: AppRouter.navigatorKey,
            onGenerateRoute: AppRouter.onGenerateRoute,
            initialRoute: AppRouter.initialRoute,
            supportedLocales: const [Locale('en', 'US')],
            // Add navigation observer for auth monitoring
            navigatorObservers: [
              AuthNavigationObserver(RouteGuard()),
            ],
            builder: (context, child) {
              // Wrap with additional providers if needed
              return child!;
            },
          ),
        ),
      ),
      error: (error, stack) => MaterialApp(
        title: AppConfig.appName,
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        supportedLocales: const [Locale('en', 'US')],
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Failed to initialize app',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    // Retry app startup
                    ref.invalidate(appStartupProvider);
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
      orElse: () => MaterialApp(
        title: AppConfig.appName,
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        supportedLocales: const [Locale('en', 'US')],
        home: const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }
}


/// Provider observer for debugging in development
class AppProviderObserver extends ProviderObserver {
  @override
  void didUpdateProvider(
    ProviderBase<Object?> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    if (kDebugMode && previousValue != newValue) {
      debugPrint('''
Provider ${provider.name ?? provider.runtimeType} updated:
  Previous: $previousValue
  New: $newValue
''');
    }
  }

  @override
  void didDisposeProvider(
    ProviderBase<Object?> provider,
    ProviderContainer container,
  ) {
    if (kDebugMode) {
      debugPrint('Provider ${provider.name ?? provider.runtimeType} disposed');
    }
  }
}
