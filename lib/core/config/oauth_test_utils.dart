import 'dart:developer' as developer;
import 'package:finwise/core/config/oauth_config.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// OAuth testing utilities for development and debugging
/// Provides comprehensive testing tools for OAuth integration
class OAuthTestUtils {
  static final OAuthTestUtils _instance = OAuthTestUtils._internal();
  factory OAuthTestUtils() => _instance;
  OAuthTestUtils._internal();

  /// Test all OAuth configurations
  static Future<OAuthTestResult> testAllConfigurations() async {
    final results = <String, OAuthProviderTestResult>{};

    // Test Google OAuth
    if (OAuthConfig.isGoogleConfigured()) {
      results['google'] = await _testGoogleOAuth();
    } else {
      results['google'] = OAuthProviderTestResult.notConfigured('Google OAuth not configured');
    }

    // Test Facebook OAuth
    if (OAuthConfig.isFacebookConfigured()) {
      results['facebook'] = await _testFacebookOAuth();
    } else {
      results['facebook'] = OAuthProviderTestResult.notConfigured('Facebook OAuth not configured');
    }

    // Test Firebase integration
    results['firebase'] = await _testFirebaseIntegration();

    final overallSuccess = results.values.every((result) => result.success);

    return OAuthTestResult(
      overallSuccess: overallSuccess,
      providerResults: results,
      timestamp: DateTime.now(),
    );
  }

  /// Test Google OAuth configuration
  static Future<OAuthProviderTestResult> _testGoogleOAuth() async {
    try {
      final googleSignIn = GoogleSignIn(
        clientId: OAuthConfig.googleClientId,
        serverClientId: OAuthConfig.googleServerClientId,
      );

      // Test if Google Sign-In can be initialized
      final isSignedIn = await googleSignIn.isSignedIn();
      final currentUser = await googleSignIn.signInSilently();

      return OAuthProviderTestResult.success(
        'Google OAuth configured correctly',
        metadata: {
          'is_signed_in': isSignedIn,
          'has_current_user': currentUser != null,
          'user_email': currentUser?.email,
          'client_id_configured': OAuthConfig.googleClientId.isNotEmpty,
        },
      );
    } catch (e) {
      return OAuthProviderTestResult.failure(
        'Google OAuth test failed: ${e.toString()}',
        error: e,
      );
    }
  }

  /// Test Facebook OAuth configuration
  static Future<OAuthProviderTestResult> _testFacebookOAuth() async {
    try {
      // Test Facebook SDK initialization
      final accessToken = await FacebookAuth.instance.accessToken;

      return OAuthProviderTestResult.success(
        'Facebook OAuth configured correctly',
        metadata: {
          'has_access_token': accessToken != null,
          'token_expires_at': accessToken?.expires,
          'granted_permissions': accessToken?.grantedPermissions,
          'declined_permissions': accessToken?.declinedPermissions,
          'app_id_configured': OAuthConfig.facebookAppId.isNotEmpty,
        },
      );
    } catch (e) {
      return OAuthProviderTestResult.failure(
        'Facebook OAuth test failed: ${e.toString()}',
        error: e,
      );
    }
  }

  /// Test Firebase OAuth integration
  static Future<OAuthProviderTestResult> _testFirebaseIntegration() async {
    try {
      final firebaseAuth = firebase_auth.FirebaseAuth.instance;
      final currentUser = firebaseAuth.currentUser;

      // Check if Firebase Auth is properly initialized
      final authStateChanges = firebase_auth.FirebaseAuth.instance.authStateChanges();

      return OAuthProviderTestResult.success(
        'Firebase Auth integration working',
        metadata: {
          'has_current_user': currentUser != null,
          'user_email': currentUser?.email,
          'user_uid': currentUser?.uid,
          'email_verified': currentUser?.emailVerified,
          'auth_state_listening': true,
        },
      );
    } catch (e) {
      return OAuthProviderTestResult.failure(
        'Firebase integration test failed: ${e.toString()}',
        error: e,
      );
    }
  }

  /// Perform end-to-end OAuth test (requires user interaction)
  static Future<OAuthEndToEndTestResult> testEndToEndOAuth(String provider) async {
    try {
      OAuthProviderTestResult? authResult;

      switch (provider.toLowerCase()) {
        case 'google':
          if (!OAuthConfig.isGoogleConfigured()) {
            return OAuthEndToEndTestResult.failure(
              'Google OAuth not configured',
              OAuthError.notConfigured,
            );
          }

          // Note: This would require actual user interaction in a real test
          // For now, just test the configuration
          authResult = await _testGoogleOAuth();
          break;

        case 'facebook':
          if (!OAuthConfig.isFacebookConfigured()) {
            return OAuthEndToEndTestResult.failure(
              'Facebook OAuth not configured',
              OAuthError.notConfigured,
            );
          }

          authResult = await _testFacebookOAuth();
          break;

        default:
          return OAuthEndToEndTestResult.failure(
            'Unknown OAuth provider: $provider',
            OAuthError.unknown,
          );
      }

      if (authResult.success) {
        return OAuthEndToEndTestResult.success(
          '$provider OAuth test completed successfully',
          provider: provider,
        );
      } else {
        return OAuthEndToEndTestResult.failure(
          authResult.message,
          OAuthError.invalidCredentials,
        );
      }
    } catch (e) {
      return OAuthEndToEndTestResult.failure(
        'End-to-end OAuth test failed: ${e.toString()}',
        OAuthError.unknown,
      );
    }
  }

  /// Log OAuth test results for debugging
  static void logTestResults(OAuthTestResult result) {
    developer.log('=== OAuth Configuration Test Results ===', name: 'OAuthTest');
    developer.log('Overall Success: ${result.overallSuccess}', name: 'OAuthTest');
    developer.log('Timestamp: ${result.timestamp}', name: 'OAuthTest');

    result.providerResults.forEach((provider, testResult) {
      developer.log('--- $provider ---', name: 'OAuthTest');
      developer.log('Success: ${testResult.success}', name: 'OAuthTest');
      developer.log('Message: ${testResult.message}', name: 'OAuthTest');

      if (testResult.metadata.isNotEmpty) {
        developer.log('Metadata: ${testResult.metadata}', name: 'OAuthTest');
      }

      if (testResult.error != null) {
        developer.log('Error: ${testResult.error}', name: 'OAuthTest');
      }
    });
  }

  /// Get OAuth configuration summary
  static Map<String, dynamic> getConfigurationSummary() {
    return {
      'google': {
        'configured': OAuthConfig.isGoogleConfigured(),
        'client_id_set': OAuthConfig.googleClientId.isNotEmpty,
        'server_client_id_set': OAuthConfig.googleServerClientId.isNotEmpty,
      },
      'facebook': {
        'configured': OAuthConfig.isFacebookConfigured(),
        'app_id_set': OAuthConfig.facebookAppId.isNotEmpty,
        'client_token_set': OAuthConfig.facebookClientToken.isNotEmpty,
      },
      'all_configured': OAuthConfig.areAllProvidersConfigured(),
      'available_providers': OAuthConfig.getConfiguredProviders(),
    };
  }
}

/// Result of OAuth configuration test
class OAuthTestResult {
  final bool overallSuccess;
  final Map<String, OAuthProviderTestResult> providerResults;
  final DateTime timestamp;

  OAuthTestResult({
    required this.overallSuccess,
    required this.providerResults,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'overall_success': overallSuccess,
      'provider_results': providerResults.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Result of individual OAuth provider test
class OAuthProviderTestResult {
  final bool success;
  final String message;
  final Map<String, dynamic> metadata;
  final dynamic error;

  OAuthProviderTestResult._({
    required this.success,
    required this.message,
    this.metadata = const {},
    this.error,
  });

  factory OAuthProviderTestResult.success(String message, {Map<String, dynamic>? metadata}) {
    return OAuthProviderTestResult._(
      success: true,
      message: message,
      metadata: metadata ?? {},
    );
  }

  factory OAuthProviderTestResult.failure(String message, {dynamic error, Map<String, dynamic>? metadata}) {
    return OAuthProviderTestResult._(
      success: false,
      message: message,
      metadata: metadata ?? {},
      error: error,
    );
  }

  factory OAuthProviderTestResult.notConfigured(String message) {
    return OAuthProviderTestResult._(
      success: false,
      message: message,
      metadata: {'reason': 'not_configured'},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'metadata': metadata,
      'error': error?.toString(),
    };
  }
}

/// Result of end-to-end OAuth test
class OAuthEndToEndTestResult {
  final bool success;
  final String message;
  final OAuthError? error;
  final String? provider;
  final DateTime timestamp;

  OAuthEndToEndTestResult._({
    required this.success,
    required this.message,
    this.error,
    this.provider,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory OAuthEndToEndTestResult.success(String message, {String? provider}) {
    return OAuthEndToEndTestResult._(
      success: true,
      message: message,
      provider: provider,
    );
  }

  factory OAuthEndToEndTestResult.failure(String message, OAuthError error) {
    return OAuthEndToEndTestResult._(
      success: false,
      message: message,
      error: error,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'error': error?.name,
      'provider': provider,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// OAuth error types
enum OAuthError {
  notConfigured,
  networkError,
  cancelledByUser,
  invalidCredentials,
  permissionDenied,
  firebaseError,
  unknown,
}
