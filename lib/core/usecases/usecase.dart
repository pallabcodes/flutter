import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:finwise/core/errors/failure.dart';

/// Abstract base class for all use cases in the application
/// Implements the Command Query Responsibility Segregation (CQRS) pattern
/// Returns Either<Failure, Type> to handle errors gracefully
abstract class UseCase<Type, Params> {
  /// Execute the use case with given parameters
  /// Returns Either<Failure, Type> where:
  /// - Left(Failure) represents an error
  /// - Right(Type) represents success with data
  Future<Either<Failure, Type>> call(Params params);
}

/// Base class for use case parameters
/// All use case parameters should extend this class for consistency
abstract class UseCaseParams extends Equatable {
  const UseCaseParams();

  @override
  List<Object?> get props => [];
}

/// Base class for use cases that don't require parameters
/// Useful for simple operations like "get current user" or "get app settings"
abstract class NoParamsUseCase<Type> extends UseCase<Type, NoParams> {
  @override
  Future<Either<Failure, Type>> call(NoParams params) async {
    return await execute();
  }

  /// Execute the use case logic without parameters
  Future<Either<Failure, Type>> execute();
}

/// Empty parameters class for use cases that don't need input
class NoParams extends UseCaseParams {
  const NoParams();

  @override
  List<Object?> get props => [];
}

/// Use case result wrapper for operations that return no data
/// Useful for operations like delete, update, etc.
/// Note: Using dartz's Unit instead of custom implementation
// class Unit {
//   const Unit._();
//
//   static const Unit value = Unit._();
// }

/// Extension methods for Either<Failure, T> results
extension EitherX<L, R> on Either<L, R> {
  /// Get the right value or throw an exception
  R getOrThrow() {
    return fold(
      (failure) => throw Exception(failure.toString()),
      (result) => result,
    );
  }

  /// Get the right value or return a default value
  R getOrElse(R defaultValue) {
    return fold(
      (failure) => defaultValue,
      (result) => result,
    );
  }

  /// Check if the result is a success (right)
  bool get isSuccess => isRight();

  /// Check if the result is a failure (left)
  bool get isFailure => isLeft();
}
