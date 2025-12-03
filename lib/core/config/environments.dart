import 'package:flutter/foundation.dart';

/// Environment configuration for FinWise app
/// Supports development, staging, and production environments

enum Environment {
  development,
  staging,
  production,
}

class AppEnvironment {
  static Environment _current = Environment.development;

  static Environment get current => _current;

  static void setEnvironment(Environment env) {
    _current = env;
  }

  static bool get isDevelopment => _current == Environment.development;
  static bool get isStaging => _current == Environment.staging;
  static bool get isProduction => _current == Environment.production;

  /// Initialize environment based on build mode and platform
  static void initialize() {
    if (kReleaseMode) {
      // In release mode, check for staging/production flags
      const isStaging = bool.fromEnvironment('IS_STAGING', defaultValue: false);
      _current = isStaging ? Environment.staging : Environment.production;
    } else {
      _current = Environment.development;
    }
  }

  static String get name {
    switch (_current) {
      case Environment.development:
        return 'development';
      case Environment.staging:
        return 'staging';
      case Environment.production:
        return 'production';
    }
  }

  static String get displayName {
    switch (_current) {
      case Environment.development:
        return 'Development';
      case Environment.staging:
        return 'Staging';
      case Environment.production:
        return 'Production';
    }
  }
}

class EnvironmentConfig {
  // API Configuration
  static String get apiBaseUrl {
    switch (AppEnvironment.current) {
      case Environment.development:
        return 'https://api-dev.finwise.app';
      case Environment.staging:
        return 'https://api-staging.finwise.app';
      case Environment.production:
        return 'https://api.finwise.app';
    }
  }

  // WebSocket Configuration
  static String get wsBaseUrl {
    switch (AppEnvironment.current) {
      case Environment.development:
        return 'wss://ws-dev.finwise.app';
      case Environment.staging:
        return 'wss://ws-staging.finwise.app';
      case Environment.production:
        return 'wss://ws.finwise.app';
    }
  }

  // Firebase Configuration
  static String get firebaseProjectId {
    switch (AppEnvironment.current) {
      case Environment.development:
        return 'finwise-dev';
      case Environment.staging:
        return 'finwise-staging';
      case Environment.production:
        return 'finwise-prod';
    }
  }

  static String get firebaseApiKey {
    switch (AppEnvironment.current) {
      case Environment.development:
        return const String.fromEnvironment('FIREBASE_DEV_API_KEY', defaultValue: '');
      case Environment.staging:
        return const String.fromEnvironment('FIREBASE_STAGING_API_KEY', defaultValue: '');
      case Environment.production:
        return const String.fromEnvironment('FIREBASE_PROD_API_KEY', defaultValue: '');
    }
  }

  // Analytics Configuration
  static bool get enableAnalytics {
    switch (AppEnvironment.current) {
      case Environment.development:
        return false;
      case Environment.staging:
        return true;
      case Environment.production:
        return true;
    }
  }

  static bool get enableCrashReporting {
    switch (AppEnvironment.current) {
      case Environment.development:
        return false;
      case Environment.staging:
        return true;
      case Environment.production:
        return true;
    }
  }

  // Feature Flags
  static bool get enableOfflineMode {
    return true; // Enabled in all environments
  }

  static bool get enableBiometricAuth {
    switch (AppEnvironment.current) {
      case Environment.development:
        return true;
      case Environment.staging:
        return true;
      case Environment.production:
        return true;
    }
  }

  static bool get enableReceiptScanning {
    switch (AppEnvironment.current) {
      case Environment.development:
        return true;
      case Environment.staging:
        return true;
      case Environment.production:
        return true;
    }
  }

  static bool get enableAdvancedAnalytics {
    switch (AppEnvironment.current) {
      case Environment.development:
        return false;
      case Environment.staging:
        return true;
      case Environment.production:
        return true;
    }
  }

  // Performance Configuration
  static bool get enablePerformanceMonitoring {
    switch (AppEnvironment.current) {
      case Environment.development:
        return true;
      case Environment.staging:
        return true;
      case Environment.production:
        return true;
    }
  }

  static Duration get syncInterval {
    switch (AppEnvironment.current) {
      case Environment.development:
        return const Duration(minutes: 1);
      case Environment.staging:
        return const Duration(minutes: 5);
      case Environment.production:
        return const Duration(minutes: 15);
    }
  }

  // UI Configuration
  static bool get showDebugInfo {
    switch (AppEnvironment.current) {
      case Environment.development:
        return true;
      case Environment.staging:
        return false;
      case Environment.production:
        return false;
    }
  }

  static bool get enableDeveloperMenu {
    switch (AppEnvironment.current) {
      case Environment.development:
        return true;
      case Environment.staging:
        return false;
      case Environment.production:
        return false;
    }
  }

  // Network Configuration
  static Duration get apiTimeout {
    switch (AppEnvironment.current) {
      case Environment.development:
        return const Duration(seconds: 30);
      case Environment.staging:
        return const Duration(seconds: 20);
      case Environment.production:
        return const Duration(seconds: 15);
    }
  }

  static int get maxRetryAttempts {
    switch (AppEnvironment.current) {
      case Environment.development:
        return 5;
      case Environment.staging:
        return 3;
      case Environment.production:
        return 3;
    }
  }

  // Database Configuration
  static bool get enableDatabaseEncryption {
    switch (AppEnvironment.current) {
      case Environment.development:
        return false;
      case Environment.staging:
        return true;
      case Environment.production:
        return true;
    }
  }

  // Logging Configuration
  static bool get enableVerboseLogging {
    switch (AppEnvironment.current) {
      case Environment.development:
        return true;
      case Environment.staging:
        return false;
      case Environment.production:
        return false;
    }
  }

  // Build Information
  static String get buildType {
    switch (AppEnvironment.current) {
      case Environment.development:
        return 'debug';
      case Environment.staging:
        return 'staging';
      case Environment.production:
        return 'release';
    }
  }

  // App Configuration
  static String get appName {
    return 'FinWise';
  }

  static String get appDescription {
    return 'AI-Powered Smart Expense Manager';
  }

  static String get packageName {
    return 'com.finwise.app';
  }

  static String get iosBundleId {
    return 'com.finwise.app';
  }

  // Support Configuration
  static String get supportEmail {
    return 'support@finwise.app';
  }

  static String get privacyPolicyUrl {
    return 'https://finwise.app/privacy';
  }

  static String get termsOfServiceUrl {
    return 'https://finwise.app/terms';
  }

  static String get helpCenterUrl {
    return 'https://help.finwise.app';
  }

  // Social Media Links
  static String get twitterUrl {
    return 'https://twitter.com/finwiseapp';
  }

  static String get linkedinUrl {
    return 'https://linkedin.com/company/finwise';
  }

  static String get githubUrl {
    return 'https://github.com/finwise/finwise-app';
  }
}