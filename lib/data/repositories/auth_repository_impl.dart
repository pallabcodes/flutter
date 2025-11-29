import 'package:dartz/dartz.dart';
import 'package:finwise/core/errors/failure.dart';
import 'package:finwise/domain/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';

@injectable
class AuthRepositoryImpl implements AuthRepository {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  AuthRepositoryImpl(
    this._firebaseAuth,
    this._googleSignIn,
  );

  @override
  Stream<AuthUser?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map((firebaseUser) {
      return firebaseUser != null ? AuthUser.fromFirebase(firebaseUser) : null;
    });
  }

  @override
  AuthUser? get currentUser {
    final firebaseUser = _firebaseAuth.currentUser;
    return firebaseUser != null ? AuthUser.fromFirebase(firebaseUser) : null;
  }

  @override
  bool get isAuthenticated => _firebaseAuth.currentUser != null;

  @override
  Future<Either<Failure, AuthUser>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        return Right(AuthUser.fromFirebase(credential.user!));
      } else {
        return Left(AuthFailure.invalidCredentials());
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Left(_mapFirebaseAuthException(e));
    } catch (e) {
      return Left(UnexpectedFailure.withMessage('Sign in failed: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, AuthUser>> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name if provided
      if (displayName != null && displayName.isNotEmpty) {
        await credential.user?.updateDisplayName(displayName);
        await credential.user?.reload();
      }

      if (credential.user != null) {
        final authUser = AuthUser.fromFirebase(credential.user!);

        // Send email verification
        await sendEmailVerification();

        return Right(authUser);
      } else {
        return Left(AuthFailure.userNotFound());
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Left(_mapFirebaseAuthException(e));
    } catch (e) {
      return Left(UnexpectedFailure.withMessage('Sign up failed: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, AuthUser>> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return Left(AuthFailure.invalidCredentials());
      }

      final googleAuth = await googleUser.authentication;
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final firebaseCredential = await _firebaseAuth.signInWithCredential(credential);

      if (firebaseCredential.user != null) {
        return Right(AuthUser.fromFirebase(firebaseCredential.user!));
      } else {
        return Left(AuthFailure.invalidCredentials());
      }
    } catch (e) {
      return Left(UnexpectedFailure.withMessage('Google sign in failed: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, AuthUser>> signInAnonymously() async {
    try {
      final credential = await _firebaseAuth.signInAnonymously();

      if (credential.user != null) {
        return Right(AuthUser.fromFirebase(credential.user!));
      } else {
        return Left(AuthFailure.invalidCredentials());
      }
    } catch (e) {
      return Left(UnexpectedFailure.withMessage('Anonymous sign in failed: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Unit>> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      return const Right(unit);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Left(_mapFirebaseAuthException(e));
    } catch (e) {
      return Left(UnexpectedFailure.withMessage('Password reset failed: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        return Left(AuthFailure.unauthorized());
      }

      await user.updateDisplayName(displayName);
      await user.updatePhotoURL(photoUrl);
      await user.reload();

      return const Right(unit);
    } catch (e) {
      return Left(UnexpectedFailure.withMessage('Profile update failed: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Unit>> sendEmailVerification() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        return Left(AuthFailure.unauthorized());
      }

      await user.sendEmailVerification();
      return const Right(unit);
    } catch (e) {
      return Left(UnexpectedFailure.withMessage('Email verification failed: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Unit>> reloadUser() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        return Left(AuthFailure.unauthorized());
      }

      await user.reload();
      return const Right(unit);
    } catch (e) {
      return Left(UnexpectedFailure.withMessage('User reload failed: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Unit>> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _firebaseAuth.signOut();
      return const Right(unit);
    } catch (e) {
      return Left(UnexpectedFailure.withMessage('Sign out failed: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteAccount() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        return Left(AuthFailure.unauthorized());
      }

      await user.delete();
      return const Right(unit);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Left(_mapFirebaseAuthException(e));
    } catch (e) {
      return Left(UnexpectedFailure.withMessage('Account deletion failed: ${e.toString()}'));
    }
  }

  /// Map Firebase Auth exceptions to domain failures
  Failure _mapFirebaseAuthException(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-disabled':
        return AuthFailure.userDisabled();
      case 'user-not-found':
        return AuthFailure.userNotFound();
      case 'wrong-password':
      case 'invalid-credential':
        return AuthFailure.invalidCredentials();
      case 'email-already-in-use':
        return ValidationFailure('Email is already in use');
      case 'weak-password':
        return ValidationFailure('Password is too weak');
      case 'invalid-email':
        return ValidationFailure('Invalid email format');
      case 'requires-recent-login':
        return AuthFailure(message: 'Please sign in again to perform this action');
      case 'too-many-requests':
        return AuthFailure(message: 'Too many attempts. Please try again later');
      default:
        return AuthFailure(message: e.message ?? 'Authentication failed');
    }
  }
}
