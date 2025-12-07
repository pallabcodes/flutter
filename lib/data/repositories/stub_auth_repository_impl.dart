import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:finwise/core/errors/failure.dart';
import 'package:finwise/domain/repositories/auth_repository.dart';

/// Stub implementation of AuthRepository that works without Firebase
/// Used when Firebase is not configured or unavailable
class StubAuthRepositoryImpl implements AuthRepository {
  AuthUser? _currentUser;
  final _authStateController = StreamController<AuthUser?>.broadcast();

  StubAuthRepositoryImpl() {
    // Initialize with anonymous user for demo
    _currentUser = AuthUser.anonymous();
    _authStateController.add(_currentUser);
  }

  @override
  Stream<AuthUser?> get authStateChanges => _authStateController.stream;

  @override
  AuthUser? get currentUser => _currentUser;

  @override
  bool get isAuthenticated => _currentUser != null;

  @override
  Future<Either<Failure, AuthUser>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return Left(UnexpectedFailure.withMessage('Firebase not configured. Please configure Firebase to use authentication.'));
  }

  @override
  Future<Either<Failure, AuthUser>> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    return Left(UnexpectedFailure.withMessage('Firebase not configured. Please configure Firebase to use authentication.'));
  }

  @override
  Future<Either<Failure, AuthUser>> signInWithGoogle() async {
    return Left(UnexpectedFailure.withMessage('Firebase not configured. Please configure Firebase to use authentication.'));
  }

  @override
  Future<Either<Failure, AuthUser>> signInAnonymously() async {
    _currentUser = AuthUser.anonymous();
    _authStateController.add(_currentUser);
    return Right(_currentUser!);
  }

  @override
  Future<Either<Failure, Unit>> sendPasswordResetEmail(String email) async {
    return Left(UnexpectedFailure.withMessage('Firebase not configured. Please configure Firebase to use authentication.'));
  }

  @override
  Future<Either<Failure, Unit>> updateProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    if (_currentUser != null) {
      _currentUser = AuthUser(
        id: _currentUser!.id,
        email: _currentUser!.email,
        displayName: displayName ?? _currentUser!.displayName,
        photoUrl: photoUrl ?? _currentUser!.photoUrl,
        emailVerified: _currentUser!.emailVerified,
        lastSignInTime: _currentUser!.lastSignInTime,
        creationTime: _currentUser!.creationTime,
      );
      _authStateController.add(_currentUser);
      return Right(unit);
    }
    return Left(UnexpectedFailure.withMessage('No user signed in'));
  }

  @override
  Future<Either<Failure, Unit>> sendEmailVerification() async {
    return Left(UnexpectedFailure.withMessage('Firebase not configured. Please configure Firebase to use authentication.'));
  }

  @override
  Future<Either<Failure, Unit>> reloadUser() async {
    return Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> signOut() async {
    _currentUser = null;
    _authStateController.add(null);
    return Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> deleteAccount() async {
    _currentUser = null;
    _authStateController.add(null);
    return Right(unit);
  }

  void dispose() {
    _authStateController.close();
  }
}

