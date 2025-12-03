import 'dart:async';
import 'package:finwise_core/finwise_core.dart';
import '../models/credit_score.dart';
import '../datasources/credit_bureau_api.dart';

/// Repository for credit-related data operations
class CreditRepository {
  final CreditBureauApi _api;
  final SecureStorageService _storage;

  CreditRepository(this._api, this._storage);

  /// Get current credit score for a specific bureau
  Future<Either<Failure, CreditScore>> getCreditScore({
    required CreditBureau bureau,
    required String userId,
  }) async {
    try {
      // Check if user is connected to this bureau
      final isConnected = await _api.isConnected(bureau: bureau, userId: userId);
      if (!isConnected) {
        return const Left(CreditNotConnectedFailure());
      }

      // Try to get stored auth credentials
      var authData = await _api.getStoredAuth(bureau: bureau, userId: userId);
      if (authData == null) {
        return const Left(CreditAuthExpiredFailure());
      }

      // Check if token is expired and refresh if needed
      final expiresAt = DateTime.parse(authData['expiresAt']);
      if (expiresAt.isBefore(DateTime.now().add(const Duration(minutes: 5)))) {
        final newToken = await _api.refreshToken(bureau: bureau, userId: userId);
        if (newToken == null) {
          return const Left(CreditAuthExpiredFailure());
        }
        authData['accessToken'] = newToken;
      }

      // Fetch credit score
      final score = await _api.fetchCreditScore(
        bureau: bureau,
        accessToken: authData['accessToken'],
        userId: userId,
      );

      return Right(score);
    } catch (e) {
      return Left(CreditApiFailure(e.toString()));
    }
  }

  /// Get full credit report for a specific bureau
  Future<Either<Failure, CreditReport>> getCreditReport({
    required CreditBureau bureau,
    required String userId,
  }) async {
    try {
      // Check if user is connected to this bureau
      final isConnected = await _api.isConnected(bureau: bureau, userId: userId);
      if (!isConnected) {
        return const Left(CreditNotConnectedFailure());
      }

      // Try to get stored auth credentials
      var authData = await _api.getStoredAuth(bureau: bureau, userId: userId);
      if (authData == null) {
        return const Left(CreditAuthExpiredFailure());
      }

      // Check if token is expired and refresh if needed
      final expiresAt = DateTime.parse(authData['expiresAt']);
      if (expiresAt.isBefore(DateTime.now().add(const Duration(minutes: 5)))) {
        final newToken = await _api.refreshToken(bureau: bureau, userId: userId);
        if (newToken == null) {
          return const Left(CreditAuthExpiredFailure());
        }
        authData['accessToken'] = newToken;
      }

      // Fetch full credit report
      final report = await _api.fetchCreditReport(
        bureau: bureau,
        accessToken: authData['accessToken'],
        userId: userId,
      );

      return Right(report);
    } catch (e) {
      return Left(CreditApiFailure(e.toString()));
    }
  }

  /// Get credit scores from all connected bureaus
  Future<Either<Failure, List<CreditScore>>> getAllCreditScores({
    required String userId,
  }) async {
    try {
      final scores = <CreditScore>[];
      final errors = <String>[];

      for (final bureau in CreditBureau.values) {
        final result = await getCreditScore(bureau: bureau, userId: userId);
        result.fold(
          (failure) => errors.add('${bureau.name}: ${failure.message}'),
          (score) => scores.add(score),
        );
      }

      if (scores.isEmpty) {
        return Left(CreditApiFailure('Failed to fetch scores from any bureau: ${errors.join(', ')}'));
      }

      return Right(scores);
    } catch (e) {
      return Left(CreditApiFailure(e.toString()));
    }
  }

  /// Connect to a credit bureau
  Future<Either<Failure, void>> connectCreditBureau({
    required CreditBureau bureau,
    required String userId,
    required String accessToken,
    required String refreshToken,
    required DateTime expiresAt,
  }) async {
    try {
      await _api.storeAuthCredentials(
        bureau: bureau,
        userId: userId,
        accessToken: accessToken,
        refreshToken: refreshToken,
        expiresAt: expiresAt,
      );

      return const Right(null);
    } catch (e) {
      return Left(CreditStorageFailure(e.toString()));
    }
  }

  /// Disconnect from a credit bureau
  Future<Either<Failure, void>> disconnectCreditBureau({
    required CreditBureau bureau,
    required String userId,
  }) async {
    try {
      await _api.disconnect(bureau: bureau, userId: userId);
      return const Right(null);
    } catch (e) {
      return Left(CreditStorageFailure(e.toString()));
    }
  }

  /// Check connection status for all bureaus
  Future<Either<Failure, Map<CreditBureau, bool>>> getConnectionStatus({
    required String userId,
  }) async {
    try {
      final status = <CreditBureau, bool>{};

      for (final bureau in CreditBureau.values) {
        final isConnected = await _api.isConnected(bureau: bureau, userId: userId);
        status[bureau] = isConnected;
      }

      return Right(status);
    } catch (e) {
      return Left(CreditStorageFailure(e.toString()));
    }
  }

  /// Get historical credit scores for trend analysis
  Future<Either<Failure, List<CreditScore>>> getHistoricalScores({
    required CreditBureau bureau,
    required String userId,
    int months = 12,
  }) async {
    try {
      final reportResult = await getCreditReport(bureau: bureau, userId: userId);
      return reportResult.fold(
        (failure) => Left(failure),
        (report) => Right(report.historicalScores),
      );
    } catch (e) {
      return Left(CreditApiFailure(e.toString()));
    }
  }

  /// Cache credit data locally for offline access
  Future<Either<Failure, void>> cacheCreditData({
    required CreditReport report,
  }) async {
    try {
      final key = 'cached_report_${report.bureau.name}_${report.userId}';
      await _storage.writeSecure(key, report.toJson());
      return const Right(null);
    } catch (e) {
      return Left(CreditStorageFailure(e.toString()));
    }
  }

  /// Get cached credit data for offline access
  Future<Either<Failure, CreditReport?>> getCachedCreditData({
    required CreditBureau bureau,
    required String userId,
  }) async {
    try {
      final key = 'cached_report_${bureau.name}_$userId';
      final data = await _storage.readSecure(key);

      if (data == null) return const Right(null);

      final report = CreditReport.fromJson(data);
      return Right(report);
    } catch (e) {
      return Left(CreditStorageFailure(e.toString()));
    }
  }
}

/// Credit-specific failure types
class CreditNotConnectedFailure extends Failure {
  const CreditNotConnectedFailure() : super(message: 'Not connected to credit bureau');
}

class CreditAuthExpiredFailure extends Failure {
  const CreditAuthExpiredFailure() : super(message: 'Credit bureau authentication expired');
}

class CreditApiFailure extends Failure {
  const CreditApiFailure(String message) : super(message: message);
}

class CreditStorageFailure extends Failure {
  const CreditStorageFailure(String message) : super(message: message);
}

/// Repository provider for dependency injection
final creditRepositoryProvider = Provider<CreditRepository>((ref) {
  final api = ref.watch(creditBureauApiProvider);
  final storage = ref.watch(secureStorageProvider);
  return CreditRepository(api, storage);
});

/// API provider
final creditBureauApiProvider = Provider<CreditBureauApi>((ref) {
  // Use mock API for development, real API for production
  const isProduction = bool.fromEnvironment('dart.vm.product');
  final client = ref.watch(httpClientProvider);
  final secureStorage = ref.watch(flutterSecureStorageProvider);

  return isProduction
      ? CreditBureauApi(client, secureStorage)
      : MockCreditBureauApi(client, secureStorage);
});
