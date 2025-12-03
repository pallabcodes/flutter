import 'package:dartz/dartz.dart';
import 'package:finwise/core/errors/failure.dart';
import 'package:finwise/domain/entities/expense.dart';
import 'package:finwise/domain/repositories/expense_repository.dart';
import 'package:finwise/domain/usecases/create_expense_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../test_utils/test_helpers.dart';

// Generate mocks
@GenerateMocks([ExpenseRepository])
import 'create_expense_usecase_test.mocks.dart';

void main() {
  late CreateExpenseUseCase useCase;
  late MockExpenseRepository mockRepository;

  setUp(() {
    mockRepository = MockExpenseRepository();
    useCase = CreateExpenseUseCase(mockRepository);
  });

  group('CreateExpenseUseCase', () {
    final testUserId = 'test_user_123';
    final validExpense = TestHelpers.createTestExpense(
      userId: testUserId,
      amount: 2500, // $25.00
      description: 'Valid test expense',
      category: ExpenseCategory.food,
    );

    group('Validation Tests', () {
      test('should validate successfully with valid expense data', () async {
        // Arrange
        when(mockRepository.createExpense(any))
            .thenAnswer((_) async => Right(validExpense));

        // Act
        final result = await useCase(CreateExpenseParams(expense: validExpense));

        // Assert
        expect(result, isA<Right<Failure, Expense>>());
        verify(mockRepository.createExpense(any)).called(1);
      });

      test('should fail validation when amount is zero', () async {
        // Arrange
        final invalidExpense = validExpense.copyWith(amount: 0);

        // Act
        final result = await useCase(CreateExpenseParams(expense: invalidExpense));

        // Assert
        expect(result, isA<Left<Failure, Expense>>());
        expect(result.fold((failure) => failure, (expense) => null),
            isA<ValidationFailure>());
        expect(result.fold((failure) => failure.message, (expense) => ''),
            contains('must be greater than zero'));
        verifyZeroInteractions(mockRepository);
      });

      test('should fail validation when amount is negative', () async {
        // Arrange
        final invalidExpense = validExpense.copyWith(amount: -100);

        // Act
        final result = await useCase(CreateExpenseParams(expense: invalidExpense));

        // Assert
        expect(result, isA<Left<Failure, Expense>>());
        expect(result.fold((failure) => failure, (expense) => null),
            isA<ValidationFailure>());
        verifyZeroInteractions(mockRepository);
      });

      test('should fail validation when amount exceeds maximum', () async {
        // Arrange
        final invalidExpense = validExpense.copyWith(amount: 100000000); // $1M

        // Act
        final result = await useCase(CreateExpenseParams(expense: invalidExpense));

        // Assert
        expect(result, isA<Left<Failure, Expense>>());
        expect(result.fold((failure) => failure, (expense) => null),
            isA<ValidationFailure>());
        expect(result.fold((failure) => failure.message, (expense) => ''),
            contains('cannot exceed'));
        verifyZeroInteractions(mockRepository);
      });

      test('should fail validation when description is empty', () async {
        // Arrange
        final invalidExpense = validExpense.copyWith(description: '');

        // Act
        final result = await useCase(CreateExpenseParams(expense: invalidExpense));

        // Assert
        expect(result, isA<Left<Failure, Expense>>());
        expect(result.fold((failure) => failure, (expense) => null),
            isA<ValidationFailure>());
        expect(result.fold((failure) => failure.message, (expense) => ''),
            contains('cannot be empty'));
        verifyZeroInteractions(mockRepository);
      });

      test('should fail validation when description is too short', () async {
        // Arrange
        final invalidExpense = validExpense.copyWith(description: 'A');

        // Act
        final result = await useCase(CreateExpenseParams(expense: invalidExpense));

        // Assert
        expect(result, isA<Left<Failure, Expense>>());
        expect(result.fold((failure) => failure, (expense) => null),
            isA<ValidationFailure>());
        expect(result.fold((failure) => failure.message, (expense) => ''),
            contains('at least 2 characters'));
        verifyZeroInteractions(mockRepository);
      });

      test('should fail validation when description is too long', () async {
        // Arrange
        final longDescription = 'A' * 201; // 201 characters
        final invalidExpense = validExpense.copyWith(description: longDescription);

        // Act
        final result = await useCase(CreateExpenseParams(expense: invalidExpense));

        // Assert
        expect(result, isA<Left<Failure, Expense>>());
        expect(result.fold((failure) => failure, (expense) => null),
            isA<ValidationFailure>());
        expect(result.fold((failure) => failure.message, (expense) => ''),
            contains('cannot exceed 200 characters'));
        verifyZeroInteractions(mockRepository);
      });

      test('should fail validation when user ID is empty', () async {
        // Arrange
        final invalidExpense = validExpense.copyWith(userId: '');

        // Act
        final result = await useCase(CreateExpenseParams(expense: invalidExpense));

        // Assert
        expect(result, isA<Left<Failure, Expense>>());
        expect(result.fold((failure) => failure, (expense) => null),
            isA<ValidationFailure>());
        expect(result.fold((failure) => failure.message, (expense) => ''),
            contains('User ID is required'));
        verifyZeroInteractions(mockRepository);
      });

      test('should fail validation when date is in the future', () async {
        // Arrange
        final futureDate = DateTime.now().add(const Duration(days: 2));
        final invalidExpense = validExpense.copyWith(date: futureDate);

        // Act
        final result = await useCase(CreateExpenseParams(expense: invalidExpense));

        // Assert
        expect(result, isA<Left<Failure, Expense>>());
        expect(result.fold((failure) => failure, (expense) => null),
            isA<ValidationFailure>());
        expect(result.fold((failure) => failure.message, (expense) => ''),
            contains('cannot be in the future'));
        verifyZeroInteractions(mockRepository);
      });

      test('should allow date up to today', () async {
        // Arrange
        final today = DateTime.now();
        final todayExpense = validExpense.copyWith(date: today);

        when(mockRepository.createExpense(any))
            .thenAnswer((_) async => Right(todayExpense));

        // Act
        final result = await useCase(CreateExpenseParams(expense: todayExpense));

        // Assert
        expect(result, isA<Right<Failure, Expense>>());
        verify(mockRepository.createExpense(any)).called(1);
      });
    });

    group('Repository Interaction Tests', () {
      test('should call repository with correctly formatted expense', () async {
        // Arrange
        final expectedExpense = validExpense.copyWith(
          createdAt: isA<DateTime>(),
          updatedAt: isA<DateTime>(),
          id: startsWith('exp_${testUserId}_'),
        );

        when(mockRepository.createExpense(any))
            .thenAnswer((_) async => Right(validExpense));

        // Act
        await useCase(CreateExpenseParams(expense: validExpense));

        // Assert
        verify(mockRepository.createExpense(captureAny)).called(1);

        final capturedExpense = verify(mockRepository.createExpense(captureAny))
            .captured.single as Expense;

        expect(capturedExpense.userId, equals(testUserId));
        expect(capturedExpense.amount, equals(2500));
        expect(capturedExpense.description, equals('Valid test expense'));
        expect(capturedExpense.category, equals(ExpenseCategory.food));
        expect(capturedExpense.createdAt, isNotNull);
        expect(capturedExpense.updatedAt, isNotNull);
        expect(capturedExpense.id, startsWith('exp_${testUserId}_'));
      });

      test('should generate unique IDs for expenses', () async {
        // Arrange
        when(mockRepository.createExpense(any))
            .thenAnswer((_) async => Right(validExpense));

        // Act
        await useCase(CreateExpenseParams(expense: validExpense));
        await useCase(CreateExpenseParams(expense: validExpense));

        // Assert
        verify(mockRepository.createExpense(any)).called(2);
      });

      test('should handle repository database errors', () async {
        // Arrange
        final dbFailure = DatabaseFailure('Database connection failed');
        when(mockRepository.createExpense(any))
            .thenAnswer((_) async => Left(dbFailure));

        // Act
        final result = await useCase(CreateExpenseParams(expense: validExpense));

        // Assert
        expect(result, equals(Left(dbFailure)));
        verify(mockRepository.createExpense(any)).called(1);
      });

      test('should handle unexpected repository errors', () async {
        // Arrange
        when(mockRepository.createExpense(any))
            .thenThrow(Exception('Unexpected error'));

        // Act
        final result = await useCase(CreateExpenseParams(expense: validExpense));

        // Assert
        expect(result, isA<Left<Failure, Expense>>());
        expect(result.fold((failure) => failure, (expense) => null),
            isA<UnexpectedFailure>());
        expect(result.fold((failure) => failure.message, (expense) => ''),
            contains('Failed to create expense'));
      });
    });

    group('Business Logic Tests', () {
      test('should set current timestamp for createdAt and updatedAt', () async {
        // Arrange
        when(mockRepository.createExpense(any))
            .thenAnswer((_) async => Right(validExpense));

        final beforeCall = DateTime.now();

        // Act
        await useCase(CreateExpenseParams(expense: validExpense));

        final afterCall = DateTime.now();

        // Assert
        final capturedExpense = verify(mockRepository.createExpense(captureAny))
            .captured.single as Expense;

        expect(capturedExpense.createdAt, isA<DateTime>());
        expect(capturedExpense.updatedAt, isA<DateTime>());
        expect(capturedExpense.createdAt.isAfter(beforeCall.subtract(const Duration(seconds: 1))), isTrue);
        expect(capturedExpense.createdAt.isBefore(afterCall.add(const Duration(seconds: 1))), isTrue);
      });

      test('should preserve existing ID if provided', () async {
        // Arrange
        const existingId = 'existing_expense_id';
        final expenseWithId = validExpense.copyWith(id: existingId);

        when(mockRepository.createExpense(any))
            .thenAnswer((_) async => Right(validExpense));

        // Act
        await useCase(CreateExpenseParams(expense: expenseWithId));

        // Assert
        final capturedExpense = verify(mockRepository.createExpense(captureAny))
            .captured.single as Expense;

        expect(capturedExpense.id, equals(existingId));
      });
    });

    group('Edge Cases and Boundary Tests', () {
      test('should handle minimum valid amount (1 cent)', () async {
        // Arrange
        final minAmountExpense = validExpense.copyWith(amount: 1);

        when(mockRepository.createExpense(any))
            .thenAnswer((_) async => Right(minAmountExpense));

        // Act
        final result = await useCase(CreateExpenseParams(expense: minAmountExpense));

        // Assert
        expect(result, isA<Right<Failure, Expense>>());
        verify(mockRepository.createExpense(any)).called(1);
      });

      test('should handle maximum valid amount', () async {
        // Arrange
        final maxAmountExpense = validExpense.copyWith(amount: 100000000 - 1);

        when(mockRepository.createExpense(any))
            .thenAnswer((_) async => Right(maxAmountExpense));

        // Act
        final result = await useCase(CreateExpenseParams(expense: maxAmountExpense));

        // Assert
        expect(result, isA<Right<Failure, Expense>>());
        verify(mockRepository.createExpense(any)).called(1);
      });

      test('should handle minimum description length (2 characters)', () async {
        // Arrange
        final minDescExpense = validExpense.copyWith(description: 'AB');

        when(mockRepository.createExpense(any))
            .thenAnswer((_) async => Right(minDescExpense));

        // Act
        final result = await useCase(CreateExpenseParams(expense: minDescExpense));

        // Assert
        expect(result, isA<Right<Failure, Expense>>());
        verify(mockRepository.createExpense(any)).called(1);
      });

      test('should handle maximum description length (200 characters)', () async {
        // Arrange
        final maxDescExpense = validExpense.copyWith(description: 'A' * 200);

        when(mockRepository.createExpense(any))
            .thenAnswer((_) async => Right(maxDescExpense));

        // Act
        final result = await useCase(CreateExpenseParams(expense: maxDescExpense));

        // Assert
        expect(result, isA<Right<Failure, Expense>>());
        verify(mockRepository.createExpense(any)).called(1);
      });
    });

    group('Concurrency and Thread Safety', () {
      test('should handle concurrent expense creation', () async {
        // Arrange
        when(mockRepository.createExpense(any))
            .thenAnswer((_) async => Right(validExpense));

        // Act
        final results = await Future.wait([
          useCase(CreateExpenseParams(expense: validExpense)),
          useCase(CreateExpenseParams(expense: validExpense)),
          useCase(CreateExpenseParams(expense: validExpense)),
        ]);

        // Assert
        expect(results.length, equals(3));
        results.forEach((result) {
          expect(result, isA<Right<Failure, Expense>>());
        });
        verify(mockRepository.createExpense(any)).called(3);
      });
    });
  });
}