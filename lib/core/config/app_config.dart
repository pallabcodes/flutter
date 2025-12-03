/// Application configuration constants
/// Production-ready configuration management
class AppConfig {
  // App Information
  static const String appName = 'FinWise';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';

  // API Configuration
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://api.finwise.com/v1',
  );

  // Firebase Configuration (would be environment-specific)
  static const String firebaseProjectId = 'finwise-prod';

  // Feature Flags
  static const bool enableReceiptScanning = true;
  static const bool enableBankIntegration = true;
  static const bool enableAnalytics = true;
  static const bool enableCrashReporting = true;

  // Limits and Constraints
  static const int maxReceiptScanRetries = 3;
  static const int maxExpenseCategories = 50;
  static const int maxBudgetsPerMonth = 20;
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration receiptScanTimeout = Duration(seconds: 15);

  // Storage Keys
  static const String userPreferencesKey = 'user_preferences';
  static const String authTokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String themeModeKey = 'theme_mode';
  static const String localeKey = 'locale';

  // Database Configuration
  static const String databaseName = 'finwise.db';
  static const int databaseVersion = 1;

  // Cache Configuration
  static const Duration cacheExpiration = Duration(hours: 24);
  static const int maxCacheSize = 100; // MB

  // Security Configuration
  static const int minPasswordLength = 8;
  static const Duration sessionTimeout = Duration(hours: 24);
  static const bool enableBiometricAuth = true;

  // UI Configuration
  static const double defaultBorderRadius = 12.0;
  static const double defaultPadding = 16.0;
  static const double defaultMargin = 8.0;

  // Analytics Configuration
  static const String analyticsMeasurementId = 'G-XXXXXXXXXX';

  // Environment detection
  static bool get isProduction => const bool.fromEnvironment('dart.vm.product');
  static bool get isDevelopment => !isProduction;

  // Platform detection helpers
  static bool get isWeb => const bool.fromEnvironment('dart.library.html');
  static bool get isMobile => !isWeb;
}
