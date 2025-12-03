import 'dart:convert';
import 'package:finwise/core/errors/failure.dart';
import 'package:finwise/core/security/encryption_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage service for sensitive data persistence
/// Implements encrypted storage with platform-specific secure enclaves
class SecureStorage {
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
      synchronizable: true,
    ),
  );

  // Storage keys
  static const String _userTokenKey = 'user_auth_token';
  static const String _refreshTokenKey = 'user_refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _encryptionKeyKey = 'encryption_key';
  static const String _lastSyncKey = 'last_sync_timestamp';
  static const String _deviceIdKey = 'device_id';

  /// Initialize secure storage
  static Future<void> initialize() async {
    try {
      // Generate and store encryption key if not exists
      final existingKey = await _storage.read(key: _encryptionKeyKey);
      if (existingKey == null) {
        final key = await EncryptionService.generateSecureKey();
        final encryptedKey = await EncryptionService.encryptData(base64Encode(key));
        await _storage.write(key: _encryptionKeyKey, value: encryptedKey);
      }
    } catch (e) {
      throw StorageFailure(
        message: 'Failed to initialize secure storage: ${e.toString()}',
      );
    }
  }

  /// Store user authentication token securely
  static Future<void> storeAuthToken(String token) async {
    try {
      final encryptedToken = await EncryptionService.encryptData(token);
      await _storage.write(key: _userTokenKey, value: encryptedToken);
    } catch (e) {
      throw StorageFailure(
        message: 'Failed to store auth token: ${e.toString()}',
      );
    }
  }

  /// Retrieve user authentication token
  static Future<String?> getAuthToken() async {
    try {
      final encryptedToken = await _storage.read(key: _userTokenKey);
      if (encryptedToken == null) return null;

      return await EncryptionService.decryptData(encryptedToken);
    } catch (e) {
      throw StorageFailure(
        message: 'Failed to retrieve auth token: ${e.toString()}',
      );
    }
  }

  /// Store refresh token securely
  static Future<void> storeRefreshToken(String token) async {
    try {
      final encryptedToken = await EncryptionService.encryptData(token);
      await _storage.write(key: _refreshTokenKey, value: encryptedToken);
    } catch (e) {
      throw StorageFailure(
        message: 'Failed to store refresh token: ${e.toString()}',
      );
    }
  }

  /// Retrieve refresh token
  static Future<String?> getRefreshToken() async {
    try {
      final encryptedToken = await _storage.read(key: _refreshTokenKey);
      if (encryptedToken == null) return null;

      return await EncryptionService.decryptData(encryptedToken);
    } catch (e) {
      throw StorageFailure(
        message: 'Failed to retrieve refresh token: ${e.toString()}',
      );
    }
  }

  /// Store user ID
  static Future<void> storeUserId(String userId) async {
    try {
      await _storage.write(key: _userIdKey, value: userId);
    } catch (e) {
      throw StorageFailure(
        message: 'Failed to store user ID: ${e.toString()}',
      );
    }
  }

  /// Retrieve user ID
  static Future<String?> getUserId() async {
    try {
      return await _storage.read(key: _userIdKey);
    } catch (e) {
      throw StorageFailure(
        message: 'Failed to retrieve user ID: ${e.toString()}',
      );
    }
  }

  /// Store biometric authentication preference
  static Future<void> storeBiometricEnabled(bool enabled) async {
    try {
      await _storage.write(
        key: _biometricEnabledKey,
        value: enabled.toString(),
      );
    } catch (e) {
      throw StorageFailure(
        message: 'Failed to store biometric preference: ${e.toString()}',
      );
    }
  }

  /// Check if biometric authentication is enabled
  static Future<bool> isBiometricEnabled() async {
    try {
      final value = await _storage.read(key: _biometricEnabledKey);
      return value == 'true';
    } catch (e) {
      return false; // Default to disabled on error
    }
  }

  /// Store device ID for tracking
  static Future<void> storeDeviceId(String deviceId) async {
    try {
      final encryptedId = await EncryptionService.encryptData(deviceId);
      await _storage.write(key: _deviceIdKey, value: encryptedId);
    } catch (e) {
      throw StorageFailure(
        message: 'Failed to store device ID: ${e.toString()}',
      );
    }
  }

  /// Retrieve device ID
  static Future<String?> getDeviceId() async {
    try {
      final encryptedId = await _storage.read(key: _deviceIdKey);
      if (encryptedId == null) return null;

      return await EncryptionService.decryptData(encryptedId);
    } catch (e) {
      throw StorageFailure(
        message: 'Failed to retrieve device ID: ${e.toString()}',
      );
    }
  }

  /// Store last synchronization timestamp
  static Future<void> storeLastSyncTimestamp(DateTime timestamp) async {
    try {
      final timestampString = timestamp.toIso8601String();
      final encryptedTimestamp = await EncryptionService.encryptData(timestampString);
      await _storage.write(key: _lastSyncKey, value: encryptedTimestamp);
    } catch (e) {
      throw StorageFailure(
        message: 'Failed to store sync timestamp: ${e.toString()}',
      );
    }
  }

  /// Retrieve last synchronization timestamp
  static Future<DateTime?> getLastSyncTimestamp() async {
    try {
      final encryptedTimestamp = await _storage.read(key: _lastSyncKey);
      if (encryptedTimestamp == null) return null;

      final timestampString = await EncryptionService.decryptData(encryptedTimestamp);
      return DateTime.parse(timestampString);
    } catch (e) {
      return null; // Return null on error rather than throwing
    }
  }

  /// Store custom encrypted data
  static Future<void> storeEncryptedData(String key, String data) async {
    try {
      final encryptedData = await EncryptionService.encryptData(data);
      await _storage.write(key: 'data_$key', value: encryptedData);
    } catch (e) {
      throw StorageFailure(
        message: 'Failed to store encrypted data: ${e.toString()}',
      );
    }
  }

  /// Retrieve custom encrypted data
  static Future<String?> getEncryptedData(String key) async {
    try {
      final encryptedData = await _storage.read(key: 'data_$key');
      if (encryptedData == null) return null;

      return await EncryptionService.decryptData(encryptedData);
    } catch (e) {
      throw StorageFailure(
        message: 'Failed to retrieve encrypted data: ${e.toString()}',
      );
    }
  }

  /// Delete specific data
  static Future<void> deleteData(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      throw StorageFailure(
        message: 'Failed to delete data: ${e.toString()}',
      );
    }
  }

  /// Clear all stored data (for logout or reset)
  static Future<void> clearAllData() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      throw StorageFailure(
        message: 'Failed to clear all data: ${e.toString()}',
      );
    }
  }

  /// Clear authentication data (for logout)
  static Future<void> clearAuthData() async {
    try {
      await Future.wait([
        _storage.delete(key: _userTokenKey),
        _storage.delete(key: _refreshTokenKey),
        _storage.delete(key: _userIdKey),
        _storage.delete(key: _biometricEnabledKey),
      ]);
    } catch (e) {
      throw StorageFailure(
        message: 'Failed to clear auth data: ${e.toString()}',
      );
    }
  }

  /// Check if secure storage is available
  static Future<bool> isAvailable() async {
    try {
      await _storage.read(key: 'test_key');
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get storage health status
  static Future<Map<String, dynamic>> getHealthStatus() async {
    try {
      final isAvailable = await SecureStorage.isAvailable();
      final storedKeys = await _getAllKeys();

      return {
        'service': 'secure_storage',
        'status': isAvailable ? 'healthy' : 'unavailable',
        'stored_items': storedKeys.length,
        'keys': storedKeys,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'service': 'secure_storage',
        'status': 'error',
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Get all stored keys (for debugging)
  static Future<List<String>> _getAllKeys() async {
    try {
      // Note: FlutterSecureStorage doesn't provide a direct way to list all keys
      // This is a limitation of the platform-specific implementations
      final keys = [
        _userTokenKey,
        _refreshTokenKey,
        _userIdKey,
        _biometricEnabledKey,
        _encryptionKeyKey,
        _lastSyncKey,
        _deviceIdKey,
      ];

      final existingKeys = <String>[];
      for (final key in keys) {
        final value = await _storage.read(key: key);
        if (value != null) {
          existingKeys.add(key);
        }
      }

      return existingKeys;
    } catch (e) {
      return [];
    }
  }

  /// Migrate data from insecure storage (for app updates)
  static Future<void> migrateFromInsecureStorage() async {
    // Implementation for migrating data from shared_preferences to secure storage
    // This would be called during app updates
  }

  /// Backup secure data (encrypted)
  static Future<String> createBackup() async {
    try {
      final backupData = <String, String>{};
      final keys = await _getAllKeys();

      for (final key in keys) {
        final value = await _storage.read(key: key);
        if (value != null) {
          backupData[key] = value;
        }
      }

      final backupJson = jsonEncode({
        'version': '1.0',
        'timestamp': DateTime.now().toIso8601String(),
        'data': backupData,
      });

      return await EncryptionService.encryptData(backupJson);
    } catch (e) {
      throw StorageFailure(
        message: 'Failed to create backup: ${e.toString()}',
      );
    }
  }

  /// Restore from backup
  static Future<void> restoreFromBackup(String encryptedBackup) async {
    try {
      final backupJson = await EncryptionService.decryptData(encryptedBackup);
      final backupData = jsonDecode(backupJson) as Map<String, dynamic>;

      final data = backupData['data'] as Map<String, dynamic>;
      for (final entry in data.entries) {
        await _storage.write(key: entry.key, value: entry.value as String);
      }
    } catch (e) {
      throw StorageFailure(
        message: 'Failed to restore backup: ${e.toString()}',
      );
    }
  }
}

/// Secure storage configuration
class SecureStorageConfig {
  static const AndroidOptions androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
    resetOnError: true,
  );

  static const IOSOptions iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock,
    synchronizable: true,
  );

  static const WebOptions webOptions = WebOptions(
    dbName: 'finwise_secure',
    publicKey: 'finwise_web_secure_key',
  );
}
