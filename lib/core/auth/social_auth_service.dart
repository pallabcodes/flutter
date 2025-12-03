import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:twitter_login/twitter_login.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:finwise/core/errors/failure.dart';
import 'package:finwise/core/security/secure_storage.dart';
import 'package:finwise/domain/entities/auth_user.dart';

/// Complete social authentication service
/// Supports Google, Facebook, Twitter, and Apple Sign-In
class SocialAuthService {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final FacebookAuth _facebookAuth;

  SocialAuthService({
    firebase_auth.FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
    FacebookAuth? facebookAuth,
  })  : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn(
          clientId: 'YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com',
          scopes: ['email', 'profile'],
        ),
        _facebookAuth = facebookAuth ?? FacebookAuth.instance;

  /// Sign in with Google
  Future<Either<Failure, AuthUser>> signInWithGoogle() async {
    try {
      // Start Google Sign-In flow
      final googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return Left(AuthFailure.cancelledByUser());
      }

      // Get authentication tokens
      final googleAuth = await googleUser.authentication;

      if (googleAuth.accessToken == null) {
        return Left(AuthFailure.invalidCredentials());
      }

      // Create Firebase credential
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      final userCredential = await _firebaseAuth.signInWithCredential(credential);

      if (userCredential.user == null) {
        return Left(AuthFailure.invalidCredentials());
      }

      // Store refresh token securely
      if (googleAuth.refreshToken != null) {
        await SecureStorage.storeGoogleRefreshToken(googleAuth.refreshToken!);
      }

      // Update user profile if needed
      await _updateUserProfile(userCredential.user!, googleUser);

      final authUser = AuthUser.fromFirebase(userCredential.user!);
      return Right(authUser);

    } on firebase_auth.FirebaseAuthException catch (e) {
      return Left(_mapFirebaseAuthException(e));
    } catch (e) {
      return Left(AuthFailure.withMessage('Google sign-in failed: ${e.toString()}'));
    }
  }

  /// Sign in with Facebook
  Future<Either<Failure, AuthUser>> signInWithFacebook() async {
    try {
      // Start Facebook login flow
      final loginResult = await _facebookAuth.login(
        permissions: ['email', 'public_profile'],
      );

      if (loginResult.status != LoginStatus.success) {
        return Left(_mapFacebookLoginStatus(loginResult.status));
      }

      final accessToken = loginResult.accessToken;
      if (accessToken == null) {
        return Left(AuthFailure.invalidCredentials());
      }

      // Create Firebase credential
      final credential = firebase_auth.FacebookAuthProvider.credential(
        accessToken.token,
      );

      // Sign in to Firebase
      final userCredential = await _firebaseAuth.signInWithCredential(credential);

      if (userCredential.user == null) {
        return Left(AuthFailure.invalidCredentials());
      }

      // Store access token securely
      await SecureStorage.storeFacebookAccessToken(accessToken.token);

      // Get additional user data from Facebook
      await _fetchFacebookUserData(userCredential.user!, accessToken.token);

      final authUser = AuthUser.fromFirebase(userCredential.user!);
      return Right(authUser);

    } on firebase_auth.FirebaseAuthException catch (e) {
      return Left(_mapFirebaseAuthException(e));
    } catch (e) {
      return Left(AuthFailure.withMessage('Facebook sign-in failed: ${e.toString()}'));
    }
  }

  /// Sign in with Twitter
  Future<Either<Failure, AuthUser>> signInWithTwitter() async {
    try {
      // Initialize Twitter login
      final twitterLogin = TwitterLogin(
        apiKey: 'YOUR_TWITTER_API_KEY',
        apiSecretKey: 'YOUR_TWITTER_API_SECRET',
        redirectURI: 'your-app://oauth',
      );

      // Start Twitter login flow
      final authResult = await twitterLogin.login();

      if (authResult.status != TwitterLoginStatus.loggedIn) {
        return Left(_mapTwitterLoginStatus(authResult.status));
      }

      if (authResult.authToken == null || authResult.authTokenSecret == null) {
        return Left(AuthFailure.invalidCredentials());
      }

      // Create Firebase credential
      final credential = firebase_auth.TwitterAuthProvider.credential(
        accessToken: authResult.authToken!,
        secret: authResult.authTokenSecret!,
      );

      // Sign in to Firebase
      final userCredential = await _firebaseAuth.signInWithCredential(credential);

      if (userCredential.user == null) {
        return Left(AuthFailure.invalidCredentials());
      }

      // Store Twitter tokens securely
      await SecureStorage.storeTwitterTokens(
        authResult.authToken!,
        authResult.authTokenSecret!,
      );

      final authUser = AuthUser.fromFirebase(userCredential.user!);
      return Right(authUser);

    } on firebase_auth.FirebaseAuthException catch (e) {
      return Left(_mapFirebaseAuthException(e));
    } catch (e) {
      return Left(AuthFailure.withMessage('Twitter sign-in failed: ${e.toString()}'));
    }
  }

  /// Sign in with Apple (iOS only)
  Future<Either<Failure, AuthUser>> signInWithApple() async {
    try {
      // Start Apple Sign-In flow
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Create Firebase credential
      final oauthCredential = firebase_auth.OAuthProvider('apple.com').credential(
        idToken: credential.identityToken,
        accessToken: credential.authorizationCode,
      );

      // Sign in to Firebase
      final userCredential = await _firebaseAuth.signInWithCredential(oauthCredential);

      if (userCredential.user == null) {
        return Left(AuthFailure.invalidCredentials());
      }

      // Store Apple tokens securely
      await SecureStorage.storeAppleTokens(
        credential.authorizationCode,
        credential.identityToken,
      );

      // Handle Apple user data (Apple only provides name/email on first login)
      await _handleAppleUserData(userCredential.user!, credential);

      final authUser = AuthUser.fromFirebase(userCredential.user!);
      return Right(authUser);

    } on firebase_auth.FirebaseAuthException catch (e) {
      return Left(_mapFirebaseAuthException(e));
    } catch (e) {
      return Left(AuthFailure.withMessage('Apple sign-in failed: ${e.toString()}'));
    }
  }

  /// Link social account to existing user
  Future<Either<Failure, AuthUser>> linkSocialAccount({
    required String provider,
    required String idToken,
    String? accessToken,
  }) async {
    try {
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) {
        return Left(AuthFailure.userNotAuthenticated());
      }

      late firebase_auth.OAuthCredential credential;

      switch (provider.toLowerCase()) {
        case 'google':
          credential = firebase_auth.GoogleAuthProvider.credential(
            idToken: idToken,
            accessToken: accessToken,
          );
          break;
        case 'facebook':
          credential = firebase_auth.FacebookAuthProvider.credential(accessToken!);
          break;
        case 'twitter':
          credential = firebase_auth.TwitterAuthProvider.credential(
            accessToken: accessToken!,
            secret: idToken, // Twitter uses idToken as secret
          );
          break;
        default:
          return Left(AuthFailure.unsupportedProvider());
      }

      // Link the credential
      final userCredential = await currentUser.linkWithCredential(credential);

      final authUser = AuthUser.fromFirebase(userCredential.user!);
      return Right(authUser);

    } on firebase_auth.FirebaseAuthException catch (e) {
      return Left(_mapFirebaseAuthException(e));
    } catch (e) {
      return Left(AuthFailure.withMessage('Account linking failed: ${e.toString()}'));
    }
  }

  /// Unlink social account
  Future<Either<Failure, AuthUser>> unlinkSocialAccount(String provider) async {
    try {
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) {
        return Left(AuthFailure.userNotAuthenticated());
      }

      late String providerId;

      switch (provider.toLowerCase()) {
        case 'google':
          providerId = 'google.com';
          break;
        case 'facebook':
          providerId = 'facebook.com';
          break;
        case 'twitter':
          providerId = 'twitter.com';
          break;
        case 'apple':
          providerId = 'apple.com';
          break;
        default:
          return Left(AuthFailure.unsupportedProvider());
      }

      // Unlink the provider
      final userCredential = await currentUser.unlink(providerId);

      final authUser = AuthUser.fromFirebase(userCredential.user!);
      return Right(authUser);

    } on firebase_auth.FirebaseAuthException catch (e) {
      return Left(_mapFirebaseAuthException(e));
    } catch (e) {
      return Left(AuthFailure.withMessage('Account unlinking failed: ${e.toString()}'));
    }
  }

  /// Get available social providers for current user
  List<String> getLinkedProviders() {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) return [];

    return currentUser.providerData
        .map((info) => info.providerId)
        .map((providerId) {
          switch (providerId) {
            case 'google.com': return 'google';
            case 'facebook.com': return 'facebook';
            case 'twitter.com': return 'twitter';
            case 'apple.com': return 'apple';
            default: return providerId;
          }
        })
        .toList();
  }

  /// Sign out from all social providers
  Future<void> signOutFromAll() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      // Continue with other sign-outs
    }

    try {
      await _facebookAuth.logOut();
    } catch (e) {
      // Continue
    }

    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      // Continue
    }

    // Clear stored tokens
    await SecureStorage.clearAllTokens();
  }

  // Private helper methods
  Future<void> _updateUserProfile(
    firebase_auth.User firebaseUser,
    GoogleSignInAccount googleUser,
  ) async {
    try {
      // Update Firebase user profile with Google data if not set
      final updates = <String, String>{};

      if (firebaseUser.displayName == null && googleUser.displayName != null) {
        updates['displayName'] = googleUser.displayName!;
      }

      if (firebaseUser.photoURL == null && googleUser.photoUrl != null) {
        updates['photoURL'] = googleUser.photoUrl!;
      }

      if (updates.isNotEmpty) {
        await firebaseUser.updateDisplayName(updates['displayName']);
        await firebaseUser.updatePhotoURL(updates['photoURL']);
        await firebaseUser.reload();
      }
    } catch (e) {
      // Non-critical error, continue
    }
  }

  Future<void> _fetchFacebookUserData(
    firebase_auth.User firebaseUser,
    String accessToken,
  ) async {
    try {
      // Fetch additional user data from Facebook Graph API
      final response = await http.get(
        Uri.parse('https://graph.facebook.com/v18.0/me?fields=email,first_name,last_name,picture'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Update Firebase profile if needed
        final displayName = '${data['first_name']} ${data['last_name']}';
        if (firebaseUser.displayName == null && displayName.trim().isNotEmpty) {
          await firebaseUser.updateDisplayName(displayName);
        }

        final photoUrl = data['picture']['data']['url'];
        if (firebaseUser.photoURL == null && photoUrl != null) {
          await firebaseUser.updatePhotoURL(photoUrl);
        }

        await firebaseUser.reload();
      }
    } catch (e) {
      // Non-critical error, continue
    }
  }

  Future<void> _handleAppleUserData(
    firebase_auth.User firebaseUser,
    AuthorizationCredentialAppleID credential,
  ) async {
    try {
      // Apple only provides name/email on first login
      // Store this data securely as it won't be provided again
      if (credential.givenName != null || credential.familyName != null) {
        final displayName = '${credential.givenName ?? ''} ${credential.familyName ?? ''}'.trim();
        if (displayName.isNotEmpty) {
          await firebaseUser.updateDisplayName(displayName);
          await firebaseUser.reload();

          // Store the name data for future reference
          await SecureStorage.storeAppleUserData({
            'givenName': credential.givenName,
            'familyName': credential.familyName,
            'email': credential.email,
          });
        }
      }
    } catch (e) {
      // Non-critical error, continue
    }
  }

  // Error mapping methods
  Failure _mapFirebaseAuthException(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-disabled':
        return AuthFailure.accountDisabled();
      case 'user-not-found':
        return AuthFailure.userNotFound();
      case 'wrong-password':
        return AuthFailure.invalidCredentials();
      case 'email-already-in-use':
        return AuthFailure.emailAlreadyInUse();
      case 'weak-password':
        return AuthFailure.weakPassword();
      case 'operation-not-allowed':
        return AuthFailure.operationNotAllowed();
      case 'invalid-verification-code':
        return AuthFailure.invalidVerificationCode();
      case 'invalid-verification-id':
        return AuthFailure.invalidVerificationId();
      default:
        return AuthFailure.withMessage('Authentication error: ${e.message}');
    }
  }

  Failure _mapFacebookLoginStatus(LoginStatus status) {
    switch (status) {
      case LoginStatus.success:
        return AuthFailure.unknown();
      case LoginStatus.cancelled:
        return AuthFailure.cancelledByUser();
      case LoginStatus.failed:
        return AuthFailure.networkError();
      case LoginStatus.operationInProgress:
        return AuthFailure.operationInProgress();
    }
  }

  Failure _mapTwitterLoginStatus(TwitterLoginStatus status) {
    switch (status) {
      case TwitterLoginStatus.loggedIn:
        return AuthFailure.unknown();
      case TwitterLoginStatus.cancelledByUser:
        return AuthFailure.cancelledByUser();
      case TwitterLoginStatus.error:
        return AuthFailure.networkError();
    }
  }
}

/// Extension methods for social auth convenience
extension SocialAuthExtensions on SocialAuthService {
  /// Check if a specific provider is linked
  bool isProviderLinked(String provider) {
    return getLinkedProviders().contains(provider.toLowerCase());
  }

  /// Get user-friendly provider names
  String getProviderDisplayName(String provider) {
    switch (provider.toLowerCase()) {
      case 'google': return 'Google';
      case 'facebook': return 'Facebook';
      case 'twitter': return 'Twitter';
      case 'apple': return 'Apple';
      default: return provider;
    }
  }

  /// Get provider icon name
  String getProviderIconName(String provider) {
    switch (provider.toLowerCase()) {
      case 'google': return 'g_mobiledata';
      case 'facebook': return 'facebook';
      case 'twitter': return 'flutter_dash';
      case 'apple': return 'apple';
      default: return 'account_circle';
    }
  }
}
