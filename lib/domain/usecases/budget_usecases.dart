import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:finwise/core/errors/failure.dart';
import 'package:finwise/core/usecases/usecase.dart';
import 'package:finwise/domain/entities/budget.dart';
import 'package:finwise/domain/entities/expense.dart';
import 'package:finwise/domain/repositories/budget_repository.dart';
import 'package:injectable/injectable.dart';

// Use case for creating a new budget
@injectable
class CreateBudgetUseCase implements UseCase<Budget, CreateBudgetParams> {
  final BudgetRepository _budgetRepository;

  CreateBudgetUseCase(this._budgetRepository);

  @override
  Future<Either<Failure, Budget>> call(CreateBudgetParams params) async {
    // Validate budget data
    final validationResult = _validateBudget(params.budget);
    if (validationResult.isLeft) {
      return validationResult;
    }

    // Create budget with current timestamp
    final budgetToCreate = params.budget.copyWith(
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      id: params.budget.id.isEmpty
          ? _generateBudgetId(params.budget.userId)
          : params.budget.id,
    );

    return await _budgetRepository.createBudget(budgetToCreate);
  }

  Either<Failure, Unit> _validateBudget(Budget budget) {
    if (budget.targetAmount <= 0) {
      return Left(ValidationFailure('Budget amount must be greater than zero'));
    }

    if (budget.name.trim().isEmpty) {
      return Left(ValidationFailure('Budget name cannot be empty'));
    }

    if (budget.userId.isEmpty) {
      return Left(ValidationFailure('User ID is required'));
    }

    // Validate date range
    if (budget.endDate.isBefore(budget.startDate)) {
      return Left(ValidationFailure('End date must be after start date'));
    }

    return const Right(unit);
  }

  String _generateBudgetId(String userId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomSuffix = (DateTime.now().microsecond * 31) % 1000;
    return 'budget_${userId}_${timestamp}_$randomSuffix';
  }
}

/// Parameters for create budget use case
class CreateBudgetParams extends UseCaseParams {
  final Budget budget;

  const CreateBudgetParams({required this.budget});

  @override
  List<Object?> get props => [budget];
}

/// Use case for getting user's budgets
@injectable
class GetBudgetsUseCase implements UseCase<List<Budget>, GetBudgetsParams> {
  final BudgetRepository _budgetRepository;

  GetBudgetsUseCase(this._budgetRepository);

  @override
  Future<Either<Failure, List<Budget>>> call(GetBudgetsParams params) async {
    return await _budgetRepository.getBudgets(params.userId);
  }
}

/// Parameters for get budgets use case
class GetBudgetsParams extends UseCaseParams {
  final String userId;

  const GetBudgetsParams({required this.userId});

  @override
  List<Object?> get props => [userId];
}

/// Use case for getting active budgets with progress
@injectable
class GetActiveBudgetsWithProgressUseCase implements UseCase<List<BudgetProgress>, GetActiveBudgetsParams> {
  final BudgetRepository _budgetRepository;

  GetActiveBudgetsWithProgressUseCase(this._budgetRepository);

  @override
  Future<Either<Failure, List<BudgetProgress>>> call(GetActiveBudgetsParams params) async {
    return await _budgetRepository.getBudgetProgress(params.userId);
  }
}

/// Parameters for get active budgets use case
class GetActiveBudgetsParams extends UseCaseParams {
  final String userId;

  const GetActiveBudgetsParams({required this.userId});

  @override
  List<Object?> get props => [userId];
}

/// Use case for updating budget spent amount
@injectable
class UpdateBudgetProgressUseCase implements UseCase<Budget, UpdateBudgetProgressParams> {
  final BudgetRepository _budgetRepository;

  UpdateBudgetProgressUseCase(this._budgetRepository);

  @override
  Future<Either<Failure, Budget>> call(UpdateBudgetProgressParams params) async {
    return await _budgetRepository.updateBudgetSpentAmount(
      budgetId: params.budgetId,
      spentAmount: params.spentAmount,
    );
  }
}

/// Parameters for update budget progress use case
class UpdateBudgetProgressParams extends UseCaseParams {
  final String budgetId;
  final int spentAmount;

  const UpdateBudgetProgressParams({
    required this.budgetId,
    required this.spentAmount,
  });

  @override
  List<Object?> get props => [budgetId, spentAmount];
}

/// Use case for updating budget details
@injectable
class UpdateBudgetUseCase implements UseCase<Budget, UpdateBudgetParams> {
  final BudgetRepository _budgetRepository;

  UpdateBudgetUseCase(this._budgetRepository);

  @override
  Future<Either<Failure, Budget>> call(UpdateBudgetParams params) async {
    // Validate updated budget
    final validationResult = _validateBudget(params.updatedBudget);
    if (validationResult.isLeft) {
      return validationResult;
    }

    // Update with current timestamp
    final budgetToUpdate = params.updatedBudget.copyWith(
      updatedAt: DateTime.now(),
    );

    return await _budgetRepository.updateBudget(budgetToUpdate);
  }

  Either<Failure, Unit> _validateBudget(Budget budget) {
    if (budget.targetAmount <= 0) {
      return Left(ValidationFailure('Budget amount must be greater than zero'));
    }

    if (budget.name.trim().isEmpty) {
      return Left(ValidationFailure('Budget name cannot be empty'));
    }

    if (budget.endDate.isBefore(budget.startDate)) {
      return Left(ValidationFailure('End date must be after start date'));
    }

    return const Right(unit);
  }
}

/// Parameters for update budget use case
class UpdateBudgetParams extends UseCaseParams {
  final Budget updatedBudget;

  const UpdateBudgetParams({required this.updatedBudget});

  @override
  List<Object?> get props => [updatedBudget];
}

/// Use case for deleting a budget
@injectable
class DeleteBudgetUseCase implements UseCase<bool, DeleteBudgetParams> {
  final BudgetRepository _budgetRepository;

  DeleteBudgetUseCase(this._budgetRepository);

  @override
  Future<Either<Failure, bool>> call(DeleteBudgetParams params) async {
    return await _budgetRepository.deleteBudget(params.budgetId);
  }
}

/// Parameters for delete budget use case
class DeleteBudgetParams extends UseCaseParams {
  final String budgetId;

  const DeleteBudgetParams({required this.budgetId});

  @override
  List<Object?> get props => [budgetId];
}

/// Use case for calculating recommended budgets based on spending history
@injectable
class GetRecommendedBudgetsUseCase implements UseCase<List<Budget>, GetRecommendedBudgetsParams> {
  final BudgetRepository _budgetRepository;

  GetRecommendedBudgetsUseCase(this._budgetRepository);

  @override
  Future<Either<Failure, List<Budget>>> call(GetRecommendedBudgetsParams params) async {
    return await _budgetRepository.getRecommendedBudgets(params.userId);
  }
}

/// Parameters for get recommended budgets use case
class GetRecommendedBudgetsParams extends UseCaseParams {
  final String userId;

  const GetRecommendedBudgetsParams({required this.userId});

  @override
  List<Object?> get props => [userId];
}

/// Use case for getting budget alerts/notifications
@injectable
class GetBudgetAlertsUseCase implements UseCase<List<BudgetAlert>, GetBudgetAlertsParams> {
  final BudgetRepository _budgetRepository;

  GetBudgetAlertsUseCase(this._budgetRepository);

  @override
  Future<Either<Failure, List<BudgetAlert>>> call(GetBudgetAlertsParams params) async {
    return await _budgetRepository.getBudgetAlerts(params.userId);
  }
}

/// Parameters for get budget alerts use case
class GetBudgetAlertsParams extends UseCaseParams {
  final String userId;

  const GetBudgetAlertsParams({required this.userId});

  @override
  List<Object?> get props => [userId];
}

/// Use case for syncing budgets
@injectable
class SyncBudgetsUseCase implements UseCase<SyncResult, SyncBudgetsParams> {
  final BudgetRepository _budgetRepository;

  SyncBudgetsUseCase(this._budgetRepository);

  @override
  Future<Either<Failure, SyncResult>> call(SyncBudgetsParams params) async {
    return await _budgetRepository.syncBudgets(params.userId);
  }
}

/// Parameters for sync budgets use case
class SyncBudgetsParams extends UseCaseParams {
  final String userId;

  const SyncBudgetsParams({required this.userId});

  @override
  List<Object?> get props => [userId];
}
