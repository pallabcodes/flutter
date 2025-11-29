import 'package:dartz/dartz.dart';
import 'package:finwise/core/errors/failure.dart';
import 'package:finwise/core/usecases/usecase.dart';
import 'package:finwise/domain/entities/expense.dart';
import 'package:finwise/domain/repositories/expense_repository.dart';
import 'package:injectable/injectable.dart';

/// Use case for creating a new expense
/// Handles validation and business logic for expense creation
@injectable
class CreateExpenseUseCase implements UseCase<Expense, CreateExpenseParams> {
  final ExpenseRepository _expenseRepository;

  CreateExpenseUseCase(this._expenseRepository);

  @override
  Future<Either<Failure, Expense>> call(CreateExpenseParams params) async {
    try {
      // Validate expense data
      final validationResult = _validateExpense(params.expense);
      if (validationResult.isFailure) {
        return Left(validationResult.getOrThrow() as Failure);
      }

      // Create the expense with current timestamp
      final expenseToCreate = params.expense.copyWith(
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        id: params.expense.id.isEmpty
            ? _generateExpenseId(params.expense.userId)
            : params.expense.id,
      );

      return await _expenseRepository.createExpense(expenseToCreate);
    } catch (e) {
      return Left(UnexpectedFailure(message: 'Failed to create expense: ${e.toString()}'));
    }
  }

  /// Validate expense data before creation
  Either<Failure, Unit> _validateExpense(Expense expense) {
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

  /// Generate a unique expense ID
  String _generateExpenseId(String userId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomSuffix = (DateTime.now().microsecond * 31) % 1000;
    return 'exp_${userId}_${timestamp}_$randomSuffix';
  }
}

/// Parameters for the CreateExpense use case
class CreateExpenseParams extends UseCaseParams {
  final Expense expense;

  const CreateExpenseParams({required this.expense});

  @override
  List<Object?> get props => [expense];
}

/// Validation failure for business rule violations
class ValidationFailure extends Failure {
  const ValidationFailure(String message) : super(message: message);

  @override
  List<Object?> get props => [message];
}

/// Unexpected failure for system errors
class UnexpectedFailure extends Failure {
  const UnexpectedFailure({required String message}) : super(message: message);

  @override
  List<Object?> get props => [message];
}
