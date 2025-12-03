import 'package:dartz/dartz.dart';
import 'package:finwise/core/errors/failure.dart';

/// Domain entity for authenticated user
class AuthUser {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final bool emailVerified;
  final DateTime? lastSignInTime;
  final DateTime? creationTime;

  const AuthUser({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.emailVerified = false,
    this.lastSignInTime,
    this.creationTime,
  });

  /// Create AuthUser from Firebase User
  factory AuthUser.fromFirebase(dynamic firebaseUser) {
    return AuthUser(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName,
      photoUrl: firebaseUser.photoURL,
      emailVerified: firebaseUser.emailVerified ?? false,
      lastSignInTime: firebaseUser.metadata?.lastSignInTime,
      creationTime: firebaseUser.metadata?.creationTime,
    );
  }

  /// Anonymous user for demo purposes
  factory AuthUser.anonymous() {
    return const AuthUser(
      id: 'anonymous_user',
      email: 'anonymous@example.com',
      displayName: 'Anonymous User',
      emailVerified: false,
    );
  }
}

/// Abstract repository interface for authentication operations
abstract class AuthRepository {
  /// Stream of authentication state changes
  Stream<AuthUser?> get authStateChanges;

  /// Get current authenticated user
  AuthUser? get currentUser;

  /// Check if user is currently authenticated
  bool get isAuthenticated;

  /// Sign in with email and password
  Future<Either<Failure, AuthUser>> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Sign up with email and password
  Future<Either<Failure, AuthUser>> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  });

  /// Sign in with Google
  Future<Either<Failure, AuthUser>> signInWithGoogle();

  /// Sign in with Facebook
  Future<Either<Failure, AuthUser>> signInWithFacebook();

  /// Sign in anonymously (for demo purposes)
  Future<Either<Failure, AuthUser>> signInAnonymously();

  /// Send password reset email
  Future<Either<Failure, Unit>> sendPasswordResetEmail(String email);

  /// Update user profile
  Future<Either<Failure, Unit>> updateProfile({
    String? displayName,
    String? photoUrl,
  });

  /// Send email verification
  Future<Either<Failure, Unit>> sendEmailVerification();

  /// Reload user data from Firebase
  Future<Either<Failure, Unit>> reloadUser();

  /// Sign out current user
  Future<Either<Failure, Unit>> signOut();

  /// Delete current user account
  Future<Either<Failure, Unit>> deleteAccount();
}
