import 'package:finwise/core/config/app_config.dart';

/// Environment configuration management
/// Supports multiple deployment environments with different settings

enum Environment {
  development('development'),
  staging('staging'),
  production('production');

  const Environment(this.name);

  final String name;

  bool get isDevelopment => this == Environment.development;
  bool get isStaging => this == Environment.staging;
  bool get isProduction => this == Environment.production;
}

/// Environment-specific configuration
class EnvironmentConfig {
  static Environment _current = Environment.development;

  static Environment get current => _current;

  static void setEnvironment(Environment environment) {
    _current = environment;
  }

  /// Initialize environment from system properties or build flavor
  static void initialize() {
    const environment = String.fromEnvironment('ENVIRONMENT');
    switch (environment.toLowerCase()) {
      case 'staging':
        _current = Environment.staging;
        break;
      case 'production':
        _current = Environment.production;
        break;
      case 'development':
      default:
        _current = Environment.development;
        break;
    }
  }

  /// Get base URL for current environment
  static String get baseUrl {
    switch (_current) {
      case Environment.development:
        return 'https://api-dev.finwise.com/v1';
      case Environment.staging:
        return 'https://api-staging.finwise.com/v1';
      case Environment.production:
        return 'https://api.finwise.com/v1';
    }
  }

  /// Get Firebase project ID for current environment
  static String get firebaseProjectId {
    switch (_current) {
      case Environment.development:
        return 'finwise-dev';
      case Environment.staging:
        return 'finwise-staging';
      case Environment.production:
        return 'finwise-prod';
    }
  }

  /// Check if analytics should be enabled
  static bool get enableAnalytics {
    switch (_current) {
      case Environment.development:
        return false; // Disable analytics in development
      case Environment.staging:
      case Environment.production:
        return true;
    }
  }

  /// Check if crash reporting should be enabled
  static bool get enableCrashReporting {
    return true; // Enable crash reporting in all environments
  }

  /// Check if debug logging should be enabled
  static bool get enableDebugLogging {
    switch (_current) {
      case Environment.development:
        return true;
      case Environment.staging:
      case Environment.production:
        return false;
    }
  }

  /// Get API request timeout for current environment
  static Duration get apiTimeout {
    switch (_current) {
      case Environment.development:
        return const Duration(seconds: 60); // Longer timeout for debugging
      case Environment.staging:
        return const Duration(seconds: 30);
      case Environment.production:
        return const Duration(seconds: 15); // Shorter for better UX
    }
  }

  /// Check if mock data should be used
  static bool get useMockData {
    switch (_current) {
      case Environment.development:
        return true; // Use mock data in development for easier testing
      case Environment.staging:
      case Environment.production:
        return false;
    }
  }

  /// Get app name suffix for current environment
  static String get appNameSuffix {
    switch (_current) {
      case Environment.development:
        return ' (Dev)';
      case Environment.staging:
        return ' (Beta)';
      case Environment.production:
        return '';
    }
  }

  /// Get database name for current environment
  static String get databaseName {
    switch (_current) {
      case Environment.development:
        return 'finwise_dev.db';
      case Environment.staging:
        return 'finwise_staging.db';
      case Environment.production:
        return 'finwise.db';
    }
  }

  /// Get analytics measurement ID
  static String get analyticsMeasurementId {
    switch (_current) {
      case Environment.development:
        return 'G-DEV-XXXXXXXXXX';
      case Environment.staging:
        return 'G-STAGING-XXXXXXXXXX';
      case Environment.production:
        return 'G-PROD-XXXXXXXXXX';
    }
  }

  /// Get supported locales for current environment
  static List<String> get supportedLocales {
    // All environments support the same locales for now
    return ['en', 'es', 'fr', 'de', 'ja', 'ko', 'zh'];
  }

  /// Get default locale
  static String get defaultLocale => 'en';

  /// Check if feature flags are enabled for current environment
  static bool isFeatureEnabled(String featureName) {
    final disabledFeatures = <String, List<Environment>>{
      'experimental_ui': [Environment.production], // Disable experimental UI in production
      'debug_tools': [Environment.staging, Environment.production], // Only in development
      'test_features': [Environment.staging, Environment.production], // Only in development
    };

    final disabledEnvironments = disabledFeatures[featureName] ?? [];
    return !disabledEnvironments.contains(_current);
  }

  /// Get environment-specific settings
  static Map<String, dynamic> get settings {
    return {
      'environment': _current.name,
      'base_url': baseUrl,
      'firebase_project_id': firebaseProjectId,
      'enable_analytics': enableAnalytics,
      'enable_crash_reporting': enableCrashReporting,
      'enable_debug_logging': enableDebugLogging,
      'api_timeout_seconds': apiTimeout.inSeconds,
      'use_mock_data': useMockData,
      'app_name_suffix': appNameSuffix,
      'database_name': databaseName,
      'analytics_measurement_id': analyticsMeasurementId,
      'supported_locales': supportedLocales,
      'default_locale': defaultLocale,
    };
  }

  /// Print current environment configuration (for debugging)
  static void printConfiguration() {
    if (!enableDebugLogging) return;

    print('🌍 Environment Configuration:');
    print('=' * 40);
    settings.forEach((key, value) {
      print('${key.padRight(25)}: $value');
    });
    print('=' * 40);
  }
}

/// Environment-specific build configuration
class BuildConfig {
  /// Get build number from environment or use default
  static String get buildNumber {
    return const String.fromEnvironment(
      'BUILD_NUMBER',
      defaultValue: '1',
    );
  }

  /// Get version name from environment or use default
  static String get versionName {
    return const String.fromEnvironment(
      'VERSION_NAME',
      defaultValue: '1.0.0',
    );
  }

  /// Check if this is a debug build
  static bool get isDebugBuild {
    bool.fromEnvironment('dart.vm.product');
    return false; // Override based on build type
  }

  /// Get build type
  static String get buildType {
    const buildType = String.fromEnvironment('BUILD_TYPE');
    return buildType.isNotEmpty ? buildType : 'release';
  }

  /// Get build flavor
  static String get buildFlavor {
    const flavor = String.fromEnvironment('BUILD_FLAVOR');
    return flavor.isNotEmpty ? flavor : 'standard';
  }

  /// Get complete version string
  static String get fullVersion {
    return '$versionName+$buildNumber';
  }

  /// Get user agent string for API requests
  static String get userAgent {
    return '${AppConfig.appName}/$fullVersion (${EnvironmentConfig.current.name})';
  }
}
