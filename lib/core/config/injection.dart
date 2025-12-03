import 'package:finwise/core/config/injection.config.dart';
import 'package:finwise/data/datasources/local/database/database.dart';
import 'package:finwise/data/datasources/remote/api_client.dart';
import 'package:finwise/data/repositories/auth_repository_impl.dart';
import 'package:finwise/data/repositories/budget_repository_impl.dart';
import 'package:finwise/data/repositories/expense_repository_impl.dart';
import 'package:finwise/data/repositories/receipt_scanner_repository_impl.dart';
import 'package:finwise/domain/repositories/auth_repository.dart';
import 'package:finwise/domain/repositories/budget_repository.dart';
import 'package:finwise/domain/repositories/expense_repository.dart';
import 'package:finwise/domain/repositories/receipt_scanner_repository.dart';
import 'package:finwise/domain/usecases/budget_usecases.dart';
import 'package:finwise/presentation/providers/budget_providers.dart';
import 'package:finwise/core/native/native_bridge.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  // Initialize database first as other services depend on it
  final database = AppDatabase();
  getIt.registerSingleton<AppDatabase>(database);

  // Initialize API client
  final apiClient = ApiClient();
  getIt.registerSingleton<ApiClient>(apiClient);

  // Register Firebase dependencies
  getIt.registerSingleton<FirebaseAuth>(FirebaseAuth.instance);
  getIt.registerSingleton<GoogleSignIn>(GoogleSignIn());

  // Register repositories
  getIt.registerSingleton<AuthRepository>(
    AuthRepositoryImpl(
      FirebaseAuth.instance,
      GoogleSignIn(),
    ),
  );

  getIt.registerSingleton<ExpenseRepository>(
    ExpenseRepositoryImpl(database, apiClient),
  );

  getIt.registerSingleton<BudgetRepository>(
    BudgetRepositoryImpl(database, apiClient),
  );

  getIt.registerSingleton<ReceiptScannerRepository>(
    ReceiptScannerRepositoryImpl(),
  );

  // Register security services
  await SecureStorage.initialize();
  getIt.registerSingleton<EncryptionService>(EncryptionService());
  getIt.registerSingleton<SecureStorage>(SecureStorage());

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

  // Register monitoring services
  getIt.registerSingleton<PerformanceMonitor>(PerformanceMonitor());
  getIt.registerSingleton<AnalyticsService>(AnalyticsService());
  getIt.registerSingleton<HealthMonitor>(HealthMonitor());

  // Register budget use cases
  getIt.registerSingleton<CreateBudgetUseCase>(
    CreateBudgetUseCase(getIt<BudgetRepository>()),
  );
  getIt.registerSingleton<GetBudgetsUseCase>(
    GetBudgetsUseCase(getIt<BudgetRepository>()),
  );
  getIt.registerSingleton<GetActiveBudgetsWithProgressUseCase>(
    GetActiveBudgetsWithProgressUseCase(getIt<BudgetRepository>()),
  );
  getIt.registerSingleton<UpdateBudgetProgressUseCase>(
    UpdateBudgetProgressUseCase(getIt<BudgetRepository>()),
  );
  getIt.registerSingleton<UpdateBudgetUseCase>(
    UpdateBudgetUseCase(getIt<BudgetRepository>()),
  );
  getIt.registerSingleton<DeleteBudgetUseCase>(
    DeleteBudgetUseCase(getIt<BudgetRepository>()),
  );

  // Initialize all other dependencies
  $initGetIt(getIt);
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
  @singleton
  AppDatabase get appDatabase => AppDatabase();

  @singleton
  ApiClient get apiClient => ApiClient();
}
