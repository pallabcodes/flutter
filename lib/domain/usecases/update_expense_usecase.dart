import 'package:dartz/dartz.dart';
import 'package:finwise/core/errors/failure.dart';
import 'package:finwise/core/usecases/usecase.dart';
import 'package:finwise/domain/entities/expense.dart';
import 'package:finwise/domain/repositories/expense_repository.dart';
import 'package:injectable/injectable.dart';

/// Use case for updating an existing expense
/// Handles validation and business logic for expense updates
@injectable
class UpdateExpenseUseCase implements UseCase<Expense, UpdateExpenseParams> {
  final ExpenseRepository _expenseRepository;

  UpdateExpenseUseCase(this._expenseRepository);

  @override
  Future<Either<Failure, Expense>> call(UpdateExpenseParams params) async {
    try {
      // Validate expense data
      final validationResult = _validateExpense(params.expense);
      if (validationResult.isFailure) {
        return Left(validationResult.getOrThrow() as Failure);
      }

      // Update the expense with current timestamp
      final expenseToUpdate = params.expense.copyWith(
        updatedAt: DateTime.now(),
      );

      return await _expenseRepository.updateExpense(expenseToUpdate);
    } catch (e) {
      return Left(UnexpectedFailure(message: 'Failed to update expense: ${e.toString()}'));
    }
  }

  /// Validate expense data before update
  Either<Failure, Unit> _validateExpense(Expense expense) {
    if (expense.id.isEmpty) {
      return Left(ValidationFailure('Expense ID is required for updates'));
    }

    if (expense.amount <= 0) {
      return Left(ValidationFailure('Expense amount must be greater than zero'));
    }

    if (expense.description.trim().isEmpty) {
      return Left(ValidationFailure('Expense description cannot be empty'));
    }

    if (expense.userId.isEmpty) {
      return Left(ValidationFailure('User ID is required'));
    }

    if (expense.date.isAfter(DateTime.now().add(const Duration(days: 1)))) {
      return Left(ValidationFailure('Expense date cannot be in the future'));
    }

    return const Right(Unit.value);
  }
}

/// Parameters for the UpdateExpense use case
class UpdateExpenseParams extends UseCaseParams {
  final Expense expense;

  const UpdateExpenseParams({required this.expense});

  @override
  List<Object?> get props => [expense];
}

/// Use case for deleting an expense
/// Handles business logic for expense deletion
@injectable
class DeleteExpenseUseCase implements UseCase<bool, DeleteExpenseParams> {
  final ExpenseRepository _expenseRepository;

  DeleteExpenseUseCase(this._expenseRepository);

  @override
  Future<Either<Failure, bool>> call(DeleteExpenseParams params) async {
    try {
      if (params.expenseId.isEmpty) {
        return Left(ValidationFailure('Expense ID is required for deletion'));
      }

      return await _expenseRepository.deleteExpense(params.expenseId);
    } catch (e) {
      return Left(UnexpectedFailure(message: 'Failed to delete expense: ${e.toString()}'));
    }
  }
}

/// Parameters for the DeleteExpense use case
class DeleteExpenseParams extends UseCaseParams {
  final String expenseId;

  const DeleteExpenseParams({required this.expenseId});

  @override
  List<Object?> get props => [expenseId];
}
