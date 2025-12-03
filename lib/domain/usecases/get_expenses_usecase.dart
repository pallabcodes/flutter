import 'package:dartz/dartz.dart';
import 'package:finwise/core/errors/failure.dart';
import 'package:finwise/core/usecases/usecase.dart';
import 'package:finwise/domain/entities/expense.dart';
import 'package:finwise/domain/repositories/expense_repository.dart';
import 'package:injectable/injectable.dart';

// Use case for retrieving expenses with various filtering options
// Implements the Clean Architecture use case pattern
@injectable
class GetExpensesUseCase implements UseCase<List<Expense>, GetExpensesParams> {
  final ExpenseRepository _expenseRepository;

  GetExpensesUseCase(this._expenseRepository);

  @override
  Future<Either<Failure, List<Expense>>> call(GetExpensesParams params) async {
    return await _expenseRepository.getExpenses(
      userId: params.userId,
      startDate: params.startDate,
      endDate: params.endDate,
      categories: params.categories,
      searchQuery: params.searchQuery,
      limit: params.limit,
      offset: params.offset,
    );
  }
}

/// Parameters for the GetExpenses use case
class GetExpensesParams {
  final String userId;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<ExpenseCategory>? categories;
  final String? searchQuery;
  final int? limit;
  final int? offset;

  const GetExpensesParams({
    required this.userId,
    this.startDate,
    this.endDate,
    this.categories,
    this.searchQuery,
    this.limit,
    this.offset,
  });

  /// Create parameters for current month expenses
  factory GetExpensesParams.currentMonth(String userId) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    return GetExpensesParams(
      userId: userId,
      startDate: startOfMonth,
      endDate: endOfMonth,
    );
  }

  /// Create parameters for current week expenses
  factory GetExpensesParams.currentWeek(String userId) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    return GetExpensesParams(
      userId: userId,
      startDate: startOfWeek,
      endDate: endOfWeek,
    );
  }

  /// Create parameters for today's expenses
  factory GetExpensesParams.today(String userId) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1)).subtract(const Duration(microseconds: 1));

    return GetExpensesParams(
      userId: userId,
      startDate: startOfDay,
      endDate: endOfDay,
    );
  }
}
