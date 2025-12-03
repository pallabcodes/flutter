/// OAuth configuration for Google and Facebook authentication
/// Centralizes all OAuth-related settings and provides environment-specific configuration
class OAuthConfig {
  // Environment variables for OAuth providers
  static const String googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue: 'your_google_client_id_here',
  );

  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: 'your_google_server_client_id_here',
  );

  static const String facebookAppId = String.fromEnvironment(
    'FACEBOOK_APP_ID',
    defaultValue: 'your_facebook_app_id_here',
  );

  static const String facebookClientToken = String.fromEnvironment(
    'FACEBOOK_CLIENT_TOKEN',
    defaultValue: 'your_facebook_client_token_here',
  );

  // OAuth provider configurations
  static const Map<String, OAuthProviderConfig> providers = {
    'google': OAuthProviderConfig(
      name: 'Google',
      clientId: googleClientId,
      serverClientId: googleServerClientId,
      scopes: ['email', 'profile'],
      iconName: 'g_mobiledata',
    ),
    'facebook': OAuthProviderConfig(
      name: 'Facebook',
      clientId: facebookAppId,
      clientToken: facebookClientToken,
      scopes: ['email', 'public_profile'],
      iconName: 'facebook',
    ),
  };

  // Validation methods
  static bool isGoogleConfigured() {
    return googleClientId.isNotEmpty && googleClientId != 'your_google_client_id_here';
  }

  static bool isFacebookConfigured() {
    return facebookAppId.isNotEmpty &&
           facebookClientToken.isNotEmpty &&
           facebookAppId != 'your_facebook_app_id_here';
  }

  static bool areAllProvidersConfigured() {
    return isGoogleConfigured() && isFacebookConfigured();
  }

  // Get configured providers
  static List<String> getConfiguredProviders() {
    final configured = <String>[];
    if (isGoogleConfigured()) configured.add('google');
    if (isFacebookConfigured()) configured.add('facebook');
    return configured;
  }

  // OAuth URLs and endpoints
  static const String googleAuthUrl = 'https://accounts.google.com/o/oauth2/v2/auth';
  static const String googleTokenUrl = 'https://oauth2.googleapis.com/token';
  static const String facebookAuthUrl = 'https://www.facebook.com/v18.0/dialog/oauth';
  static const String facebookTokenUrl = 'https://graph.facebook.com/v18.0/oauth/access_token';

  // Redirect URIs (must match Firebase configuration)
  static String getGoogleRedirectUri(String packageName) {
    return 'com.googleusercontent.apps.$googleClientId:/oauth2redirect';
  }

  static String getFacebookRedirectUri() {
    return 'https://your-project.firebaseapp.com/__/auth/handler';
  }

  // Error messages
  static const String googleNotConfigured = 'Google Sign-In is not properly configured. Please check your OAuth settings.';
  static const String facebookNotConfigured = 'Facebook Login is not properly configured. Please check your OAuth settings.';
  static const String noProvidersConfigured = 'No OAuth providers are configured. Please configure at least one provider.';

  // Debug information
  static Map<String, dynamic> getDebugInfo() {
    return {
      'google_configured': isGoogleConfigured(),
      'facebook_configured': isFacebookConfigured(),
      'configured_providers': getConfiguredProviders(),
      'google_client_id': googleClientId.isNotEmpty ? '${googleClientId.substring(0, 10)}...' : 'not set',
      'facebook_app_id': facebookAppId.isNotEmpty ? '${facebookAppId.substring(0, 10)}...' : 'not set',
    };
  }
}

/// Configuration for an OAuth provider
class OAuthProviderConfig {
  final String name;
  final String clientId;
  final String? serverClientId;
  final String? clientToken;
  final List<String> scopes;
  final String iconName;

  const OAuthProviderConfig({
    required this.name,
    required this.clientId,
    this.serverClientId,
    this.clientToken,
    required this.scopes,
    required this.iconName,
  });

  bool get isConfigured {
    return clientId.isNotEmpty &&
           (serverClientId?.isNotEmpty ?? true) &&
           (clientToken?.isNotEmpty ?? true);
  }
}

/// OAuth helper utilities
class OAuthUtils {
  /// Validate OAuth configuration
  static OAuthValidationResult validateConfiguration() {
    final issues = <String>[];

    if (!OAuthConfig.isGoogleConfigured()) {
      issues.add('Google OAuth is not configured');
    }

    if (!OAuthConfig.isFacebookConfigured()) {
      issues.add('Facebook OAuth is not configured');
    }

    if (issues.isEmpty) {
      return OAuthValidationResult.valid();
    } else {
      return OAuthValidationResult.invalid(issues);
    }
  }

  /// Get OAuth provider by name
  static OAuthProviderConfig? getProvider(String name) {
    return OAuthConfig.providers[name];
  }

  /// Check if a provider is available
  static bool isProviderAvailable(String providerName) {
    final provider = getProvider(providerName);
    return provider?.isConfigured ?? false;
  }

  /// Get available OAuth providers
  static List<OAuthProviderConfig> getAvailableProviders() {
    return OAuthConfig.providers.values
        .where((provider) => provider.isConfigured)
        .toList();
  }
}

/// OAuth validation result
class OAuthValidationResult {
  final bool isValid;
  final List<String> issues;

  OAuthValidationResult._(this.isValid, this.issues);

  factory OAuthValidationResult.valid() {
    return OAuthValidationResult._(true, []);
  }

  factory OAuthValidationResult.invalid(List<String> issues) {
    return OAuthValidationResult._(false, issues);
  }
}

/// OAuth error types
enum OAuthError {
  notConfigured,
  networkError,
  cancelledByUser,
  invalidCredentials,
  permissionDenied,
  unknown,
}

/// OAuth error extension
extension OAuthErrorExtension on OAuthError {
  String get message {
    switch (this) {
      case OAuthError.notConfigured:
        return 'OAuth provider is not properly configured';
      case OAuthError.networkError:
        return 'Network error occurred during authentication';
      case OAuthError.cancelledByUser:
        return 'Authentication was cancelled by user';
      case OAuthError.invalidCredentials:
        return 'Invalid credentials provided';
      case OAuthError.permissionDenied:
        return 'Permission denied by OAuth provider';
      case OAuthError.unknown:
        return 'Unknown OAuth error occurred';
    }
  }
}
