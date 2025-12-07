// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:firebase_auth/firebase_auth.dart' as _i59;
import 'package:get_it/get_it.dart' as _i174;
import 'package:google_sign_in/google_sign_in.dart' as _i116;
import 'package:injectable/injectable.dart' as _i526;

import '../../data/datasources/local/database/database.dart' as _i845;
import '../../data/datasources/remote/api_client.dart' as _i388;
import '../../data/repositories/auth_repository_impl.dart' as _i895;
import '../../data/repositories/budget_repository_impl.dart' as _i28;
import '../../data/repositories/expense_repository_impl.dart' as _i998;
import '../../data/repositories/receipt_scanner_repository_impl.dart' as _i936;
import '../../domain/repositories/auth_repository.dart' as _i1073;
import '../../domain/repositories/budget_repository.dart' as _i160;
import '../../domain/repositories/expense_repository.dart' as _i630;
import '../../domain/usecases/budget_usecases.dart' as _i146;
import '../../domain/usecases/create_expense_usecase.dart' as _i29;
import '../../domain/usecases/get_expenses_usecase.dart' as _i575;
import '../../domain/usecases/sign_in_usecase.dart' as _i778;

// initializes the registration of main-scope dependencies inside of GetIt
_i174.GetIt $initGetIt(
  _i174.GetIt getIt, {
  String? environment,
  _i526.EnvironmentFilter? environmentFilter,
}) {
  final gh = _i526.GetItHelper(
    getIt,
    environment,
    environmentFilter,
  );
  gh.factory<_i936.ReceiptScannerRepositoryImpl>(
      () => _i936.ReceiptScannerRepositoryImpl());
  gh.singleton<_i845.AppDatabase>(() => _i845.AppDatabase());
  gh.singleton<_i388.ApiClient>(() => _i388.ApiClient());
  gh.factory<_i778.SignInUseCase>(
      () => _i778.SignInUseCase(gh<_i1073.AuthRepository>()));
  gh.factory<_i778.SignUpUseCase>(
      () => _i778.SignUpUseCase(gh<_i1073.AuthRepository>()));
  gh.factory<_i778.SignInWithGoogleUseCase>(
      () => _i778.SignInWithGoogleUseCase(gh<_i1073.AuthRepository>()));
  gh.factory<_i778.SignOutUseCase>(
      () => _i778.SignOutUseCase(gh<_i1073.AuthRepository>()));
  gh.factory<_i778.GetCurrentUserUseCase>(
      () => _i778.GetCurrentUserUseCase(gh<_i1073.AuthRepository>()));
  gh.factory<_i29.CreateExpenseUseCase>(
      () => _i29.CreateExpenseUseCase(gh<_i630.ExpenseRepository>()));
  gh.factory<_i575.GetExpensesUseCase>(
      () => _i575.GetExpensesUseCase(gh<_i630.ExpenseRepository>()));
  gh.factory<_i998.ExpenseRepositoryImpl>(() => _i998.ExpenseRepositoryImpl(
        gh<_i845.AppDatabase>(),
        gh<_i388.ApiClient>(),
      ));
  gh.factory<_i28.BudgetRepositoryImpl>(() => _i28.BudgetRepositoryImpl(
        gh<_i845.AppDatabase>(),
        gh<_i388.ApiClient>(),
      ));
  gh.factory<_i146.CreateBudgetUseCase>(
      () => _i146.CreateBudgetUseCase(gh<_i160.BudgetRepository>()));
  gh.factory<_i146.GetBudgetsUseCase>(
      () => _i146.GetBudgetsUseCase(gh<_i160.BudgetRepository>()));
  gh.factory<_i146.GetActiveBudgetsWithProgressUseCase>(() =>
      _i146.GetActiveBudgetsWithProgressUseCase(gh<_i160.BudgetRepository>()));
  gh.factory<_i146.UpdateBudgetProgressUseCase>(
      () => _i146.UpdateBudgetProgressUseCase(gh<_i160.BudgetRepository>()));
  gh.factory<_i146.UpdateBudgetUseCase>(
      () => _i146.UpdateBudgetUseCase(gh<_i160.BudgetRepository>()));
  gh.factory<_i146.DeleteBudgetUseCase>(
      () => _i146.DeleteBudgetUseCase(gh<_i160.BudgetRepository>()));
  gh.factory<_i146.GetRecommendedBudgetsUseCase>(
      () => _i146.GetRecommendedBudgetsUseCase(gh<_i160.BudgetRepository>()));
  gh.factory<_i146.GetBudgetAlertsUseCase>(
      () => _i146.GetBudgetAlertsUseCase(gh<_i160.BudgetRepository>()));
  gh.factory<_i146.SyncBudgetsUseCase>(
      () => _i146.SyncBudgetsUseCase(gh<_i160.BudgetRepository>()));
  gh.factory<_i895.AuthRepositoryImpl>(() => _i895.AuthRepositoryImpl(
        gh<_i59.FirebaseAuth>(),
        gh<_i116.GoogleSignIn>(),
      ));
  return getIt;
}
