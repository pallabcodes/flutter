import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:finwise/core/errors/failure.dart';
import 'package:finwise/core/usecases/usecase.dart';
import 'package:finwise/domain/repositories/auth_repository.dart';
import 'package:injectable/injectable.dart';

/// Use case for signing in with email and password
@injectable
class SignInUseCase implements UseCase<AuthUser, SignInParams> {
  final AuthRepository _authRepository;

  SignInUseCase(this._authRepository);

  @override
  Future<Either<Failure, AuthUser>> call(SignInParams params) async {
    // Validate input
    final validationResult = _validateInput(params.email, params.password);
    return validationResult.fold(
      (failure) => Future.value(Left(failure)),
      (_) => _authRepository.signInWithEmailAndPassword(
        email: params.email.trim(),
        password: params.password,
      ),
    );
  }

  Either<Failure, Unit> _validateInput(String email, String password) {
    if (email.trim().isEmpty) {
      return Left(ValidationFailure(message: 'Email is required'));
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email.trim())) {
      return Left(ValidationFailure(message: 'Please enter a valid email address'));
    }

    if (password.isEmpty) {
      return Left(ValidationFailure(message: 'Password is required'));
    }

    if (password.length < 6) {
      return Left(ValidationFailure(message: 'Password must be at least 6 characters'));
    }

    return const Right(unit);
  }
}

/// Parameters for sign in use case
class SignInParams extends UseCaseParams {
  final String email;
  final String password;

  const SignInParams({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

/// Use case for signing up with email and password
@injectable
class SignUpUseCase implements UseCase<AuthUser, SignUpParams> {
  final AuthRepository _authRepository;

  SignUpUseCase(this._authRepository);

  @override
  Future<Either<Failure, AuthUser>> call(SignUpParams params) async {
    // Validate input
    final validationResult = _validateInput(
      params.email,
      params.password,
      params.confirmPassword,
    );
    return validationResult.fold(
      (failure) => Future.value(Left(failure)),
      (_) => _authRepository.signUpWithEmailAndPassword(
        email: params.email.trim(),
        password: params.password,
        displayName: params.displayName?.trim(),
      ),
    );
  }

  Either<Failure, Unit> _validateInput(
    String email,
    String password,
    String confirmPassword,
  ) {
    if (email.trim().isEmpty) {
      return Left(ValidationFailure(message: 'Email is required'));
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email.trim())) {
      return Left(ValidationFailure(message: 'Please enter a valid email address'));
    }

    if (password.isEmpty) {
      return Left(ValidationFailure(message: 'Password is required'));
    }

    if (password.length < 6) {
      return Left(ValidationFailure(message: 'Password must be at least 6 characters'));
    }

    if (password != confirmPassword) {
      return Left(ValidationFailure(message: 'Passwords do not match'));
    }

    if (password.contains(RegExp(r'[A-Z]')) == false) {
      return Left(ValidationFailure(message: 'Password must contain at least one uppercase letter'));
    }

    if (password.contains(RegExp(r'[a-z]')) == false) {
      return Left(ValidationFailure(message: 'Password must contain at least one lowercase letter'));
    }

    if (password.contains(RegExp(r'[0-9]')) == false) {
      return Left(ValidationFailure(message: 'Password must contain at least one number'));
    }

    return const Right(unit);
  }
}

/// Parameters for sign up use case
class SignUpParams extends UseCaseParams {
  final String email;
  final String password;
  final String confirmPassword;
  final String? displayName;

  const SignUpParams({
    required this.email,
    required this.password,
    required this.confirmPassword,
    this.displayName,
  });

  @override
  List<Object?> get props => [email, password, confirmPassword, displayName];
}

/// Use case for signing in with Google
@injectable
class SignInWithGoogleUseCase extends NoParamsUseCase<AuthUser> {
  final AuthRepository _authRepository;

  SignInWithGoogleUseCase(this._authRepository);

  @override
  Future<Either<Failure, AuthUser>> execute() async {
    return await _authRepository.signInWithGoogle();
  }
}

/// Use case for signing out
@injectable
class SignOutUseCase extends NoParamsUseCase<Unit> {
  final AuthRepository _authRepository;

  SignOutUseCase(this._authRepository);

  @override
  Future<Either<Failure, Unit>> execute() async {
    return await _authRepository.signOut();
  }
}

/// Use case for getting current user
@injectable
class GetCurrentUserUseCase extends NoParamsUseCase<AuthUser?> {
  final AuthRepository _authRepository;

  GetCurrentUserUseCase(this._authRepository);

  @override
  Future<Either<Failure, AuthUser?>> execute() async {
    try {
      return Right(_authRepository.currentUser);
    } catch (e) {
      return Left(UnexpectedFailure.withMessage('Failed to get current user: ${e.toString()}'));
    }
  }
}
