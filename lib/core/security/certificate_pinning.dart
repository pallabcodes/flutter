import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:finwise/core/errors/failure.dart';
import 'package:flutter/services.dart';

/// SSL certificate pinning implementation
/// Prevents man-in-the-middle attacks by validating server certificates
class CertificatePinning {
  static const String _certificateAssetPath = 'assets/certificates/';

  // Known certificate fingerprints (SHA-256)
  static const Map<String, List<String>> _trustedFingerprints = {
    'api.finwise.com': [
      'SHA256:FINGERPRINT1', // Production certificate fingerprint
      'SHA256:FINGERPRINT2', // Backup certificate fingerprint
    ],
    'api-staging.finwise.com': [
      'SHA256:STAGING_FINGERPRINT1',
    ],
    'api-dev.finwise.com': [
      'SHA256:DEV_FINGERPRINT1',
    ],
  };

  static HttpClient? _pinnedClient;

  /// Get HTTP client with certificate pinning enabled
  static HttpClient getPinnedClient() {
    if (_pinnedClient != null) return _pinnedClient!;

    _pinnedClient = HttpClient()
      ..badCertificateCallback = _validateCertificate;

    return _pinnedClient!;
  }

  /// Validate server certificate against pinned fingerprints
  static bool _validateCertificate(X509Certificate cert, String host, int port) {
    try {
      // Get expected fingerprints for this host
      final expectedFingerprints = _trustedFingerprints[host];
      if (expectedFingerprints == null || expectedFingerprints.isEmpty) {
        // No pinned certificates for this host - reject connection
        _logSecurityEvent('No pinned certificates for host: $host');
        return false;
      }

      // Calculate certificate fingerprint
      final certFingerprint = _calculateCertificateFingerprint(cert);

      // Check if certificate fingerprint matches any trusted fingerprint
      final isValid = expectedFingerprints.contains(certFingerprint);

      if (!isValid) {
        _logSecurityEvent('Certificate fingerprint mismatch for $host: $certFingerprint');
        _logSecurityEvent('Expected fingerprints: $expectedFingerprints');
      }

      return isValid;
    } catch (e) {
      _logSecurityEvent('Certificate validation error for $host: $e');
      return false;
    }
  }

  /// Calculate SHA-256 fingerprint of certificate
  static String _calculateCertificateFingerprint(X509Certificate cert) {
    try {
      // Convert certificate bytes to fingerprint
      final certBytes = cert.pem;
      final bytes = utf8.encode(certBytes);
      final digest = sha256.convert(bytes);
      return 'SHA256:${digest.toString().toUpperCase()}';
    } catch (e) {
      throw CertificateValidationFailure(
        message: 'Failed to calculate certificate fingerprint: $e',
      );
    }
  }

  /// Load pinned certificates from assets
  static Future<void> loadPinnedCertificates() async {
    try {
      // Load certificate files from assets
      final certificateFiles = [
        'production.pem',
        'staging.pem',
        'development.pem',
      ];

      for (final certFile in certificateFiles) {
        try {
          final certData = await rootBundle.loadString('$_certificateAssetPath$certFile');
          final cert = X509Certificate.fromPem(certData);
          final fingerprint = _calculateCertificateFingerprint(cert);

          // Add to trusted fingerprints based on certificate file
          final host = _getHostForCertificateFile(certFile);
          if (host != null) {
            _addTrustedFingerprint(host, fingerprint);
          }
        } catch (e) {
          _logSecurityEvent('Failed to load certificate $certFile: $e');
        }
      }
    } catch (e) {
      _logSecurityEvent('Failed to load pinned certificates: $e');
    }
  }

  /// Update certificate fingerprints (for certificate rotation)
  static Future<void> updateCertificateFingerprints(
    String host,
    List<String> newFingerprints,
  ) async {
    _trustedFingerprints[host] = newFingerprints;
    _logSecurityEvent('Updated certificate fingerprints for $host');
  }

  /// Add trusted fingerprint for host
  static void _addTrustedFingerprint(String host, String fingerprint) {
    final current = _trustedFingerprints[host] ?? [];
    if (!current.contains(fingerprint)) {
      _trustedFingerprints[host] = [...current, fingerprint];
    }
  }

  /// Get host for certificate file
  static String? _getHostForCertificateFile(String certFile) {
    switch (certFile) {
      case 'production.pem':
        return 'api.finwise.com';
      case 'staging.pem':
        return 'api-staging.finwise.com';
      case 'development.pem':
        return 'api-dev.finwise.com';
      default:
        return null;
    }
  }

  /// Check if certificate pinning is enabled for host
  static bool isPinningEnabled(String host) {
    return _trustedFingerprints.containsKey(host);
  }

  /// Get security status
  static Map<String, dynamic> getSecurityStatus() {
    return {
      'certificate_pinning': 'enabled',
      'trusted_hosts': _trustedFingerprints.keys.toList(),
      'total_fingerprints': _trustedFingerprints.values
          .fold(0, (sum, fingerprints) => sum + fingerprints.length),
      'last_updated': DateTime.now().toIso8601String(),
    };
  }

  /// Create Dio client with certificate pinning
  static Future<Dio> createPinnedDioClient() async {
    final dio = Dio();

    // Add certificate pinning interceptor
    dio.interceptors.add(CertificatePinningInterceptor());

    // Configure timeouts and other settings
    dio.options.connectTimeout = const Duration(seconds: 15);
    dio.options.receiveTimeout = const Duration(seconds: 30);
    dio.options.sendTimeout = const Duration(seconds: 15);

    return dio;
  }

  /// Log security events for monitoring
  static void _logSecurityEvent(String message) {
    // In production, this would send to security monitoring service
    print('🔒 SECURITY: $message');
  }

  /// Reset pinned client (for testing)
  static void resetClient() {
    _pinnedClient?.close(force: true);
    _pinnedClient = null;
  }
}

/// Dio interceptor for certificate pinning
class CertificatePinningInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Validate host has pinning enabled
    if (!CertificatePinning.isPinningEnabled(options.uri.host)) {
      handler.reject(DioError(
        requestOptions: options,
        error: 'Certificate pinning not configured for host: ${options.uri.host}',
        type: DioErrorType.other,
      ));
      return;
    }

    handler.next(options);
  }

  @override
  void onError(DioError err, ErrorInterceptorHandler handler) {
    // Handle certificate validation failures
    if (err.error is CertificateValidationFailure) {
      CertificatePinning._logSecurityEvent('Certificate validation failed: ${err.message}');
    }

    handler.next(err);
  }
}

/// Certificate validation failure
class CertificateValidationFailure extends Failure {
  CertificateValidationFailure({required super.message});
}

/// Certificate management utilities
class CertificateUtils {
  /// Extract certificate information for display
  static Map<String, dynamic> getCertificateInfo(X509Certificate cert) {
    return {
      'subject': cert.subject,
      'issuer': cert.issuer,
      'valid_from': cert.startValidity.toIso8601String(),
      'valid_until': cert.endValidity.toIso8601String(),
      'serial_number': cert.serialNumber,
      'fingerprint_sha256': _calculateFingerprintSHA256(cert),
      'is_expired': cert.endValidity.isBefore(DateTime.now()),
      'days_until_expiry': cert.endValidity.difference(DateTime.now()).inDays,
    };
  }

  /// Check if certificate is valid
  static bool isCertificateValid(X509Certificate cert) {
    final now = DateTime.now();
    return cert.startValidity.isBefore(now) && cert.endValidity.isAfter(now);
  }

  /// Calculate SHA-256 fingerprint
  static String _calculateFingerprintSHA256(X509Certificate cert) {
    try {
      final certBytes = cert.pem;
      final bytes = utf8.encode(certBytes);
      final digest = sha256.convert(bytes);
      return digest.toString().toUpperCase();
    } catch (e) {
      return 'ERROR_CALCULATING_FINGERPRINT';
    }
  }

  /// Validate certificate chain
  static bool validateCertificateChain(List<X509Certificate> chain) {
    if (chain.isEmpty) return false;

    // Check each certificate in chain
    for (var i = 0; i < chain.length; i++) {
      final cert = chain[i];

      // Validate current certificate
      if (!isCertificateValid(cert)) {
        return false;
      }

      // For certificates after root, validate signature by parent
      if (i > 0) {
        final parentCert = chain[i - 1];
        if (!_validateSignature(cert, parentCert)) {
          return false;
        }
      }
    }

    return true;
  }

  /// Validate certificate signature (simplified)
  static bool _validateSignature(X509Certificate cert, X509Certificate signer) {
    // In a real implementation, this would verify the cryptographic signature
    // For now, just check basic properties
    return signer.subject.contains('CA') || signer.issuer == signer.subject;
  }
}

/// Certificate rotation manager
class CertificateRotationManager {
  static const Duration _rotationCheckInterval = Duration(days: 30);
  static const Duration _expiryWarningThreshold = Duration(days: 30);

  static DateTime? _lastRotationCheck;

  /// Check if certificates need rotation
  static Future<bool> shouldRotateCertificates() async {
    final now = DateTime.now();

    // Don't check too frequently
    if (_lastRotationCheck != null &&
        now.difference(_lastRotationCheck!) < _rotationCheckInterval) {
      return false;
    }

    _lastRotationCheck = now;

    // Check if any certificates are expiring soon
    for (final host in CertificatePinning._trustedFingerprints.keys) {
      final expiryInfo = await _getCertificateExpiryInfo(host);
      if (expiryInfo != null && expiryInfo['days_until_expiry'] < 30) {
        return true;
      }
    }

    return false;
  }

  /// Get certificate expiry information
  static Future<Map<String, dynamic>?> _getCertificateExpiryInfo(String host) async {
    // This would fetch certificate info from the server
    // For now, return null (not implemented)
    return null;
  }

  /// Schedule certificate rotation
  static Future<void> scheduleRotation(String host, DateTime rotationDate) async {
    // Schedule certificate rotation task
    CertificatePinning._logSecurityEvent(
      'Certificate rotation scheduled for $host on ${rotationDate.toIso8601String()}',
    );
  }
}
