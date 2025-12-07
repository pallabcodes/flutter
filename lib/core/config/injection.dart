import 'package:finwise/core/config/injection.config.dart';
import 'package:finwise/data/datasources/local/database/database.dart';
import 'package:finwise/data/datasources/remote/api_client.dart';
import 'package:finwise/data/repositories/auth_repository_impl.dart';
import 'package:finwise/data/repositories/stub_auth_repository_impl.dart';
import 'package:finwise/data/repositories/budget_repository_impl.dart';
import 'package:finwise/data/repositories/expense_repository_impl.dart';
import 'package:finwise/data/repositories/receipt_scanner_repository_impl.dart';
import 'package:finwise/domain/repositories/auth_repository.dart';
import 'package:finwise/domain/repositories/budget_repository.dart';
import 'package:finwise/domain/repositories/expense_repository.dart';
import 'package:finwise/domain/repositories/receipt_scanner_repository.dart';
import 'package:finwise/domain/usecases/budget_usecases.dart';
import 'package:finwise/presentation/providers/budget_providers.dart';
import 'package:finwise/core/monitoring/analytics_service.dart';
import 'package:finwise/core/monitoring/health_monitor.dart';
import 'package:finwise/core/monitoring/performance_monitor.dart';
import 'package:finwise/core/native/native_bridge.dart';
import 'package:finwise/core/security/encryption_service.dart';
import 'package:finwise/core/security/secure_storage.dart';
import 'package:finwise/core/sync/sync_conflict_resolver.dart';
import 'package:finwise/core/sync/sync_engine.dart';
import 'package:finwise/core/sync/sync_models.dart';
import 'package:finwise/core/sync/sync_queue.dart';
import 'package:finwise/core/sync/sync_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

/// Global service locator instance
final getIt = GetIt.instance;

/// Configure dependency injection for the entire application
/// Uses Injectable code generation for compile-time safety
@InjectableInit(
  initializerName: r'$initGetIt',
  preferRelativeImports: true,
  asExtension: false,
)
Future<void> configureDependencies() async {
  // Register generated singletons first (AppDatabase, ApiClient, etc.)
  $initGetIt(getIt);

  // Register Firebase dependencies (optional - only if Firebase is initialized)
  FirebaseAuth? firebaseAuth;
  GoogleSignIn? googleSignIn;
  
  try {
    // Check if Firebase is initialized
    final app = Firebase.app();
    firebaseAuth = FirebaseAuth.instanceFor(app: app);
    googleSignIn = GoogleSignIn();
    getIt.registerSingleton<FirebaseAuth>(firebaseAuth!);
    getIt.registerSingleton<GoogleSignIn>(googleSignIn!);
  } catch (e) {
    if (kDebugMode) {
      print('Firebase dependencies not available: $e');
    }
    // Create a mock/null FirebaseAuth instance or skip registration
    // For now, we'll skip Firebase-dependent features
  }

  // Register repositories (use stub if Firebase is not available)
  if (firebaseAuth != null && googleSignIn != null) {
    if (getIt.isRegistered<AuthRepository>()) {
      await getIt.unregister<AuthRepository>();
    }
    getIt.registerSingleton<AuthRepository>(
      AuthRepositoryImpl(
        firebaseAuth!,
        googleSignIn!,
      ),
    );
  } else {
    if (getIt.isRegistered<AuthRepository>()) {
      await getIt.unregister<AuthRepository>();
    }
    // Register a stub AuthRepository that doesn't require Firebase
    getIt.registerSingleton<AuthRepository>(
      StubAuthRepositoryImpl(),
    );
    if (kDebugMode) {
      print('Using StubAuthRepository - Firebase not available');
    }
  }

  if (!getIt.isRegistered<ExpenseRepository>()) {
    getIt.registerSingleton<ExpenseRepository>(
      ExpenseRepositoryImpl(getIt<AppDatabase>(), getIt<ApiClient>()),
    );
  }

  if (!getIt.isRegistered<BudgetRepository>()) {
    getIt.registerSingleton<BudgetRepository>(
      BudgetRepositoryImpl(getIt<AppDatabase>(), getIt<ApiClient>()),
    );
  }

  if (!getIt.isRegistered<ReceiptScannerRepository>()) {
    getIt.registerSingleton<ReceiptScannerRepository>(
      ReceiptScannerRepositoryImpl(),
    );
  }

  // Register security services
  // SecureStorage and EncryptionService are static classes with static methods
  // They don't need to be registered in the DI container
  try {
    await EncryptionService.initialize();
    await SecureStorage.initialize();
  } catch (e) {
    if (kDebugMode) {
      print('Security services initialization failed: $e');
      print('App will continue without secure storage');
    }
  }

  // Register native bridge
  getIt.registerSingleton<NativeBridge>(NativeBridge());

  // Register sync services
  getIt.registerSingleton<SyncQueue>(FileSyncQueue());
  getIt.registerSingleton<SyncConflictResolver>(
    AutomaticConflictResolver(defaultAction: ConflictAction.keepLocal),
  );

  // Register sync repositories
  getIt.registerSingleton<SyncRepository>(
    SyncRepositoryFactory.createDefault(
      localRepository: LocalSyncRepository(),
      remoteRepository: RemoteSyncRepository(),
    ),
  );

  // Register sync engine
  getIt.registerSingleton<SyncEngine>(
    SyncEngine(
      syncRepository: getIt<SyncRepository>(),
      syncQueue: getIt<SyncQueue>(),
      conflictResolver: getIt<SyncConflictResolver>(),
    ),
  );

  // Register monitoring services if not already registered by injectable
  if (!getIt.isRegistered<PerformanceMonitor>()) {
    getIt.registerSingleton<PerformanceMonitor>(PerformanceMonitor());
  }
  if (!getIt.isRegistered<AnalyticsService>()) {
    getIt.registerSingleton<AnalyticsService>(AnalyticsService());
  }
  if (!getIt.isRegistered<HealthMonitor>()) {
    getIt.registerSingleton<HealthMonitor>(HealthMonitor());
  }

}

/// Environment configuration for dependency injection
abstract class Env {
  static const dev = 'dev';
  static const prod = 'prod';
  static const test = 'test';
}

/// Module for registering singleton services
@module
abstract class RegisterModule {
  // AppDatabase is already registered with @singleton annotation in database.dart
  // ApiClient is already registered with @injectable annotation in api_client.dart
  // Both are registered directly on their classes, so no need to register here
}
