import 'package:finwise/core/config/injection.dart';
import 'package:finwise/domain/repositories/auth_repository.dart';
import 'package:finwise/domain/usecases/sign_in_usecase.dart';
import 'package:finwise/presentation/providers/expense_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Repository Provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return getIt<AuthRepository>();
});

// Use Case Providers
final signInUseCaseProvider = Provider<SignInUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return SignInUseCase(repository);
});

final signUpUseCaseProvider = Provider<SignUpUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return SignUpUseCase(repository);
});

final signInWithGoogleUseCaseProvider = Provider<SignInWithGoogleUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return SignInWithGoogleUseCase(repository);
});

final signInWithFacebookUseCaseProvider = Provider<SignInWithFacebookUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return SignInWithFacebookUseCase(repository);
});

final signOutUseCaseProvider = Provider<SignOutUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return SignOutUseCase(repository);
});

final sendPasswordResetUseCaseProvider = Provider<SendPasswordResetUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return SendPasswordResetUseCase(repository);
});

final getCurrentUserUseCaseProvider = Provider<GetCurrentUserUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return GetCurrentUserUseCase(repository);
});

// Auth State Provider
final authStateProvider = StreamProvider<AuthUser?>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.authStateChanges;
});

// Current User Provider
final currentUserProvider = Provider<AuthUser?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.maybeWhen(
    data: (user) => user,
    orElse: () => null,
  );
});

// Authentication Status Provider
final isAuthenticatedProvider = Provider<bool>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  return currentUser != null;
});

// Auth Operations State Notifiers
class AuthState extends StateNotifier<AsyncValue<AuthUser?>> {
  final SignInUseCase _signInUseCase;
  final SignUpUseCase _signUpUseCase;
  final SignInWithGoogleUseCase _signInWithGoogleUseCase;
  final SignInWithFacebookUseCase _signInWithFacebookUseCase;
  final SignOutUseCase _signOutUseCase;
  final SendPasswordResetUseCase _sendPasswordResetUseCase;

  AuthState(
    this._signInUseCase,
    this._signUpUseCase,
    this._signInWithGoogleUseCase,
    this._signInWithFacebookUseCase,
    this._signOutUseCase,
    this._sendPasswordResetUseCase,
  ) : super(const AsyncValue.data(null));

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();

    final result = await _signInUseCase(
      SignInParams(email: email, password: password),
    );

    state = result.fold(
      (failure) => AsyncValue.error(failure.message, StackTrace.current),
      (user) => AsyncValue.data(user),
    );
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String confirmPassword,
    String? displayName,
  }) async {
    state = const AsyncValue.loading();

    final result = await _signUpUseCase(
      SignUpParams(
        email: email,
        password: password,
        confirmPassword: confirmPassword,
        displayName: displayName,
      ),
    );

    state = result.fold(
      (failure) => AsyncValue.error(failure.message, StackTrace.current),
      (user) => AsyncValue.data(user),
    );
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();

    final result = await _signInWithGoogleUseCase.execute();

    state = result.fold(
      (failure) => AsyncValue.error(failure.message, StackTrace.current),
      (user) => AsyncValue.data(user),
    );
  }

  Future<void> signInWithFacebook() async {
    state = const AsyncValue.loading();

    final result = await _signInWithFacebookUseCase.execute();

    state = result.fold(
      (failure) => AsyncValue.error(failure.message, StackTrace.current),
      (user) => AsyncValue.data(user),
    );
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();

    final result = await _signOutUseCase.execute();

    state = result.fold(
      (failure) => AsyncValue.error(failure.message, StackTrace.current),
      (user) => const AsyncValue.data(null),
    );
  }

  Future<Either<Failure, Unit>> sendPasswordReset(String email) async {
    return await _sendPasswordResetUseCase(SendPasswordResetParams(email: email));
  }
}

final authNotifierProvider = StateNotifierProvider<AuthState, AsyncValue<AuthUser?>>((ref) {
  final signInUseCase = ref.watch(signInUseCaseProvider);
  final signUpUseCase = ref.watch(signUpUseCaseProvider);
  final signInWithGoogleUseCase = ref.watch(signInWithGoogleUseCaseProvider);
  final signInWithFacebookUseCase = ref.watch(signInWithFacebookUseCaseProvider);
  final signOutUseCase = ref.watch(signOutUseCaseProvider);
  final sendPasswordResetUseCase = ref.watch(sendPasswordResetUseCaseProvider);

  return AuthState(
    signInUseCase,
    signUpUseCase,
    signInWithGoogleUseCase,
    signInWithFacebookUseCase,
    signOutUseCase,
    sendPasswordResetUseCase,
  );
});

// User-specific expense providers
final userExpensesProvider = Provider<AsyncValue<List<dynamic>>>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) {
    return const AsyncValue.data([]);
  }

  // Override the expenses provider to use current user's ID
  return ref.watch(expensesProvider);
});

final userExpenseFiltersProvider = StateProvider<ExpenseFilters>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  return ExpenseFilters();
});

// Auth-aware expense creation
final createExpenseForCurrentUserProvider = FutureProvider.family<void, dynamic>((ref, expense) async {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) {
    throw Exception('User must be authenticated to create expenses');
  }

  final expenseWithUserId = expense.copyWith(userId: currentUser.id);
  final createExpenseUseCase = ref.watch(createExpenseUseCaseProvider);

  final result = await createExpenseUseCase(
    CreateExpenseParams(expense: expenseWithUserId),
  );

  return result.fold(
    (failure) => throw Exception(failure.message),
    (_) => null,
  );
});
