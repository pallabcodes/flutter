import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:finwise/core/errors/failure.dart';

/// Unified native bridge for cross-platform native functionality
/// Provides type-safe communication with iOS and Android native code
class NativeBridge {
  static const MethodChannel _channel = MethodChannel('com.finwise.native');
  static const EventChannel _eventChannel = EventChannel('com.finwise.native.events');

  static Stream<dynamic>? _eventStream;

  /// Initialize the native bridge
  static Future<void> initialize() async {
    _eventStream = _eventChannel.receiveBroadcastStream();
    _setupEventHandlers();
  }

  /// Check if a native feature is available on the current platform
  static Future<bool> isFeatureAvailable(String feature) async {
    try {
      final result = await _invokeMethod('isFeatureAvailable', {'feature': feature});
      return result as bool? ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Get platform-specific information
  static Future<Map<String, dynamic>> getPlatformInfo() async {
    try {
      final result = await _invokeMethod('getPlatformInfo');
      return Map<String, dynamic>.from(result ?? {});
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Invoke a native method with type safety
  static Future<T> invokeNativeMethod<T>(String method, [dynamic arguments]) async {
    try {
      final result = await _invokeMethod(method, arguments);
      return result as T;
    } on PlatformException catch (e) {
      throw NativePlatformException(e.code, e.message, e.details);
    } catch (e) {
      throw NativeBridgeException('Failed to invoke native method: $method', e);
    }
  }

  /// Invoke a native method (internal implementation)
  static Future<dynamic> _invokeMethod(String method, [dynamic arguments]) async {
    return await _channel.invokeMethod(method, arguments);
  }

  /// Set up event handlers for native events
  static void _setupEventHandlers() {
    _eventStream?.listen(
      (event) {
        if (event is Map) {
          _handleNativeEvent(Map<String, dynamic>.from(event));
        }
      },
      onError: (error) {
        print('Native event error: $error');
      },
    );
  }

  /// Handle incoming native events
  static void _handleNativeEvent(Map<String, dynamic> event) {
    final eventType = event['type'] as String?;
    final eventData = event['data'];

    switch (eventType) {
      case 'location_updated':
        _handleLocationUpdate(eventData);
        break;
      case 'notification_received':
        _handleNotificationReceived(eventData);
        break;
      case 'biometric_auth':
        _handleBiometricAuth(eventData);
        break;
      case 'payment_processed':
        _handlePaymentProcessed(eventData);
        break;
      case 'voice_command':
        _handleVoiceCommand(eventData);
        break;
      default:
        print('Unknown native event: $eventType');
    }
  }

  // Event handlers
  static void _handleLocationUpdate(dynamic data) {
    // Handle location updates from native side
    print('Location updated: $data');
  }

  static void _handleNotificationReceived(dynamic data) {
    // Handle push notifications
    print('Notification received: $data');
  }

  static void _handleBiometricAuth(dynamic data) {
    // Handle biometric authentication results
    print('Biometric auth: $data');
  }

  static void _handlePaymentProcessed(dynamic data) {
    // Handle payment processing results
    print('Payment processed: $data');
  }

  static void _handleVoiceCommand(dynamic data) {
    // Handle voice command processing
    print('Voice command: $data');
  }

  /// Get the current platform
  static String get platform {
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    return 'unknown';
  }

  /// Check if running on iOS
  static bool get isIOS => Platform.isIOS;

  /// Check if running on Android
  static bool get isAndroid => Platform.isAndroid;

  /// Get platform version
  static String get platformVersion => Platform.operatingSystemVersion;
}

/// iOS-specific native bridge
class IOSNativeBridge extends NativeBridge {
  /// Check if iOS features are available
  static Future<IOSCapabilities> getCapabilities() async {
    final features = await Future.wait([
      NativeBridge.isFeatureAvailable('siri_shortcuts'),
      NativeBridge.isFeatureAvailable('apple_pay'),
      NativeBridge.isFeatureAvailable('icloud_sync'),
      NativeBridge.isFeatureAvailable('face_id'),
      NativeBridge.isFeatureAvailable('touch_id'),
      NativeBridge.isFeatureAvailable('health_kit'),
      NativeBridge.isFeatureAvailable('home_kit'),
    ]);

    return IOSCapabilities(
      siriShortcuts: features[0] as bool,
      applePay: features[1] as bool,
      iCloudSync: features[2] as bool,
      faceId: features[3] as bool,
      touchId: features[4] as bool,
      healthKit: features[5] as bool,
      homeKit: features[6] as bool,
    );
  }

  /// Add Siri shortcut
  static Future<void> addSiriShortcut({
    required String identifier,
    required String title,
    required String phrase,
    Map<String, dynamic>? userInfo,
  }) async {
    await NativeBridge.invokeNativeMethod('addSiriShortcut', {
      'identifier': identifier,
      'title': title,
      'phrase': phrase,
      'userInfo': userInfo,
    });
  }

  /// Process Apple Pay transaction
  static Future<ApplePayResult> processApplePay({
    required double amount,
    required String currency,
    String? description,
  }) async {
    final result = await NativeBridge.invokeNativeMethod<Map<String, dynamic>>('processApplePay', {
      'amount': amount,
      'currency': currency,
      'description': description,
    });

    return ApplePayResult.fromJson(result);
  }

  /// Sync data with iCloud
  static Future<void> syncWithiCloud(String data) async {
    await NativeBridge.invokeNativeMethod('syncWithiCloud', {'data': data});
  }

  /// Authenticate with Face ID/Touch ID
  static Future<BiometricResult> authenticateWithBiometrics({
    String? reason,
    bool useFaceId = true,
    bool useTouchId = true,
  }) async {
    final result = await NativeBridge.invokeNativeMethod<Map<String, dynamic>>('authenticateBiometrics', {
      'reason': reason ?? 'Authenticate to continue',
      'useFaceId': useFaceId,
      'useTouchId': useTouchId,
    });

    return BiometricResult.fromJson(result);
  }

  /// Share content using iOS share sheet
  static Future<void> shareContent({
    required String text,
    String? url,
    List<String>? imagePaths,
  }) async {
    await NativeBridge.invokeNativeMethod('shareContent', {
      'text': text,
      'url': url,
      'imagePaths': imagePaths,
    });
  }
}

/// Android-specific native bridge
class AndroidNativeBridge extends NativeBridge {
  /// Check if Android features are available
  static Future<AndroidCapabilities> getCapabilities() async {
    final features = await Future.wait([
      NativeBridge.isFeatureAvailable('google_pay'),
      NativeBridge.isFeatureAvailable('android_auto'),
      NativeBridge.isFeatureAvailable('biometric_auth'),
      NativeBridge.isFeatureAvailable('dynamic_theming'),
      NativeBridge.isFeatureAvailable('notification_channels'),
      NativeBridge.isFeatureAvailable('background_location'),
    ]);

    return AndroidCapabilities(
      googlePay: features[0] as bool,
      androidAuto: features[1] as bool,
      biometricAuth: features[2] as bool,
      dynamicTheming: features[3] as bool,
      notificationChannels: features[4] as bool,
      backgroundLocation: features[5] as bool,
    );
  }

  /// Process Google Pay transaction
  static Future<GooglePayResult> processGooglePay({
    required double amount,
    required String currency,
    String? description,
  }) async {
    final result = await NativeBridge.invokeNativeMethod<Map<String, dynamic>>('processGooglePay', {
      'amount': amount,
      'currency': currency,
      'description': description,
    });

    return GooglePayResult.fromJson(result);
  }

  /// Enable Android Auto integration
  static Future<void> enableAndroidAuto() async {
    await NativeBridge.invokeNativeMethod('enableAndroidAuto');
  }

  /// Get dynamic color scheme (Material You)
  static Future<ColorScheme> getDynamicColorScheme() async {
    final result = await NativeBridge.invokeNativeMethod<Map<String, dynamic>>('getDynamicColorScheme');
    return ColorScheme.fromJson(result);
  }

  /// Create notification channel
  static Future<void> createNotificationChannel({
    required String id,
    required String name,
    required String description,
    int importance = 3, // NotificationManager.IMPORTANCE_DEFAULT
  }) async {
    await NativeBridge.invokeNativeMethod('createNotificationChannel', {
      'id': id,
      'name': name,
      'description': description,
      'importance': importance,
    });
  }

  /// Show notification
  static Future<void> showNotification({
    required String channelId,
    required String title,
    required String body,
    String? payload,
  }) async {
    await NativeBridge.invokeNativeMethod('showNotification', {
      'channelId': channelId,
      'title': title,
      'body': body,
      'payload': payload,
    });
  }

  /// Authenticate with biometrics
  static Future<BiometricResult> authenticateWithBiometrics({
    String? title,
    String? subtitle,
    String? description,
    bool useFingerprint = true,
    bool useFace = true,
  }) async {
    final result = await NativeBridge.invokeNativeMethod<Map<String, dynamic>>('authenticateBiometrics', {
      'title': title ?? 'Authenticate',
      'subtitle': subtitle,
      'description': description ?? 'Use your biometric credential to authenticate',
      'useFingerprint': useFingerprint,
      'useFace': useFace,
    });

    return BiometricResult.fromJson(result);
  }
}

/// Platform capability classes
class IOSCapabilities {
  final bool siriShortcuts;
  final bool applePay;
  final bool iCloudSync;
  final bool faceId;
  final bool touchId;
  final bool healthKit;
  final bool homeKit;

  const IOSCapabilities({
    required this.siriShortcuts,
    required this.applePay,
    required this.iCloudSync,
    required this.faceId,
    required this.touchId,
    required this.healthKit,
    required this.homeKit,
  });

  bool get hasBiometrics => faceId || touchId;
  bool get hasPayment => applePay;
  bool get hasVoice => siriShortcuts;
}

class AndroidCapabilities {
  final bool googlePay;
  final bool androidAuto;
  final bool biometricAuth;
  final bool dynamicTheming;
  final bool notificationChannels;
  final bool backgroundLocation;

  const AndroidCapabilities({
    required this.googlePay,
    required this.androidAuto,
    required this.biometricAuth,
    required this.dynamicTheming,
    required this.notificationChannels,
    required this.backgroundLocation,
  });

  bool get hasBiometrics => biometricAuth;
  bool get hasPayment => googlePay;
  bool get hasAuto => androidAuto;
}

/// Result classes
class ApplePayResult {
  final bool success;
  final String? transactionId;
  final String? errorMessage;
  final Map<String, dynamic>? paymentData;

  const ApplePayResult({
    required this.success,
    this.transactionId,
    this.errorMessage,
    this.paymentData,
  });

  factory ApplePayResult.fromJson(Map<String, dynamic> json) {
    return ApplePayResult(
      success: json['success'] ?? false,
      transactionId: json['transactionId'],
      errorMessage: json['errorMessage'],
      paymentData: json['paymentData'],
    );
  }
}

class GooglePayResult {
  final bool success;
  final String? transactionId;
  final String? errorMessage;
  final Map<String, dynamic>? paymentData;

  const GooglePayResult({
    required this.success,
    this.transactionId,
    this.errorMessage,
    this.paymentData,
  });

  factory GooglePayResult.fromJson(Map<String, dynamic> json) {
    return GooglePayResult(
      success: json['success'] ?? false,
      transactionId: json['transactionId'],
      errorMessage: json['errorMessage'],
      paymentData: json['paymentData'],
    );
  }
}

class BiometricResult {
  final bool success;
  final String? errorMessage;
  final bool usedFace;
  final bool usedFingerprint;

  const BiometricResult({
    required this.success,
    this.errorMessage,
    this.usedFace = false,
    this.usedFingerprint = false,
  });

  factory BiometricResult.fromJson(Map<String, dynamic> json) {
    return BiometricResult(
      success: json['success'] ?? false,
      errorMessage: json['errorMessage'],
      usedFace: json['usedFace'] ?? false,
      usedFingerprint: json['usedFingerprint'] ?? false,
    );
  }
}

class ColorScheme {
  final int primary;
  final int onPrimary;
  final int secondary;
  final int onSecondary;
  final int surface;
  final int onSurface;

  const ColorScheme({
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.onSecondary,
    required this.surface,
    required this.onSurface,
  });

  factory ColorScheme.fromJson(Map<String, dynamic> json) {
    return ColorScheme(
      primary: json['primary'] ?? 0xFF2196F3,
      onPrimary: json['onPrimary'] ?? 0xFFFFFFFF,
      secondary: json['secondary'] ?? 0xFF1976D2,
      onSecondary: json['onSecondary'] ?? 0xFFFFFFFF,
      surface: json['surface'] ?? 0xFFFFFFFF,
      onSurface: json['onSurface'] ?? 0xFF000000,
    );
  }
}

/// Native platform exceptions
class NativePlatformException implements Exception {
  final String code;
  final String? message;
  final dynamic details;

  const NativePlatformException(this.code, this.message, this.details);

  @override
  String toString() => 'NativePlatformException: $code - $message';
}

class NativeBridgeException implements Exception {
  final String message;
  final dynamic cause;

  const NativeBridgeException(this.message, this.cause);

  @override
  String toString() => 'NativeBridgeException: $message (cause: $cause)';
}
