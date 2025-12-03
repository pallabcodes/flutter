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
    if (validationResult.isLeft) {
      return validationResult;
    }

    // Attempt sign in
    return await _authRepository.signInWithEmailAndPassword(
      email: params.email.trim(),
      password: params.password,
    );
  }

  Either<Failure, Unit> _validateInput(String email, String password) {
    if (email.trim().isEmpty) {
      return Left(ValidationFailure('Email is required'));
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email.trim())) {
      return Left(ValidationFailure('Please enter a valid email address'));
    }

    if (password.isEmpty) {
      return Left(ValidationFailure('Password is required'));
    }

    if (password.length < 6) {
      return Left(ValidationFailure('Password must be at least 6 characters'));
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
    if (validationResult.isLeft) {
      return validationResult;
    }

    // Attempt sign up
    return await _authRepository.signUpWithEmailAndPassword(
      email: params.email.trim(),
      password: params.password,
      displayName: params.displayName?.trim(),
    );
  }

  Either<Failure, Unit> _validateInput(
    String email,
    String password,
    String confirmPassword,
  ) {
    if (email.trim().isEmpty) {
      return Left(ValidationFailure('Email is required'));
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email.trim())) {
      return Left(ValidationFailure('Please enter a valid email address'));
    }

    if (password.isEmpty) {
      return Left(ValidationFailure('Password is required'));
    }

    if (password.length < 6) {
      return Left(ValidationFailure('Password must be at least 6 characters'));
    }

    if (password != confirmPassword) {
      return Left(ValidationFailure('Passwords do not match'));
    }

    if (password.contains(RegExp(r'[A-Z]')) == false) {
      return Left(ValidationFailure('Password must contain at least one uppercase letter'));
    }

    if (password.contains(RegExp(r'[a-z]')) == false) {
      return Left(ValidationFailure('Password must contain at least one lowercase letter'));
    }

    if (password.contains(RegExp(r'[0-9]')) == false) {
      return Left(ValidationFailure('Password must contain at least one number'));
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
class SignInWithGoogleUseCase implements NoParamsUseCase<AuthUser> {
  final AuthRepository _authRepository;

  SignInWithGoogleUseCase(this._authRepository);

  @override
  Future<Either<Failure, AuthUser>> execute() async {
    return await _authRepository.signInWithGoogle();
  }
}

/// Use case for signing in with Facebook
@injectable
class SignInWithFacebookUseCase implements NoParamsUseCase<AuthUser> {
  final AuthRepository _authRepository;

  SignInWithFacebookUseCase(this._authRepository);

  @override
  Future<Either<Failure, AuthUser>> execute() async {
    return await _authRepository.signInWithFacebook();
  }
}

/// Use case for signing out
@injectable
class SignOutUseCase implements NoParamsUseCase<Unit> {
  final AuthRepository _authRepository;

  SignOutUseCase(this._authRepository);

  @override
  Future<Either<Failure, Unit>> execute() async {
    return await _authRepository.signOut();
  }
}

/// Use case for getting current user
@injectable
class GetCurrentUserUseCase implements NoParamsUseCase<AuthUser?> {
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

/// Use case for sending password reset email
@injectable
class SendPasswordResetUseCase implements UseCase<Unit, SendPasswordResetParams> {
  final AuthRepository _authRepository;

  SendPasswordResetUseCase(this._authRepository);

  @override
  Future<Either<Failure, Unit>> call(SendPasswordResetParams params) async {
    try {
      // Validate email
      final validationResult = _validateEmail(params.email);
      if (validationResult.isLeft) {
        return validationResult;
      }

      return await _authRepository.sendPasswordResetEmail(params.email);
    } catch (e) {
      return Left(UnexpectedFailure(message: 'Failed to send password reset email: ${e.toString()}'));
    }
  }

  Either<Failure, Unit> _validateEmail(String email) {
    if (email.trim().isEmpty) {
      return Left(ValidationFailure('Email is required'));
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email.trim())) {
      return Left(ValidationFailure('Please enter a valid email address'));
    }

    return const Right(unit);
  }
}

/// Parameters for password reset use case
class SendPasswordResetParams extends UseCaseParams {
  final String email;

  const SendPasswordResetParams({required this.email});

  @override
  List<Object?> get props => [email];
}
