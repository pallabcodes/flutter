import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:finwise_core/finwise_core.dart';
import '../models/credit_score.dart';

/// Service for integrating with credit bureau APIs
class CreditBureauApi {
  final http.Client _client;
  final FlutterSecureStorage _secureStorage;

  CreditBureauApi(this._client, this._secureStorage);

  /// Fetch credit report from specified bureau
  Future<CreditReport> fetchCreditReport({
    required CreditBureau bureau,
    required String accessToken,
    required String userId,
  }) async {
    try {
      final endpoint = _getBureauEndpoint(bureau);
      final headers = await _buildAuthHeaders(accessToken);

      final response = await _client.get(
        Uri.parse('$endpoint/credit-report'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Encrypt and store sensitive data
        final encryptedData = await _encryptData(jsonEncode(data));
        await _secureStorage.write(
          key: 'credit_report_${bureau.name}_$userId',
          value: encryptedData,
        );

        return CreditReport.fromJson(data);
      } else if (response.statusCode == 401) {
        throw CreditBureauException('Authentication failed. Please reconnect your credit report.');
      } else if (response.statusCode == 429) {
        throw CreditBureauException('Rate limit exceeded. Please try again later.');
      } else {
        throw CreditBureauException('Failed to fetch credit report: ${response.statusCode}');
      }
    } catch (e) {
      if (e is CreditBureauException) rethrow;
      throw CreditBureauException('Network error: ${e.toString()}');
    }
  }

  /// Fetch credit score only (lighter weight call)
  Future<CreditScore> fetchCreditScore({
    required CreditBureau bureau,
    required String accessToken,
    required String userId,
  }) async {
    try {
      final endpoint = _getBureauEndpoint(bureau);
      final headers = await _buildAuthHeaders(accessToken);

      final response = await _client.get(
        Uri.parse('$endpoint/credit-score'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final score = CreditScore.fromJson(data);

        // Update stored score data
        await _updateStoredScore(bureau, userId, score);

        return score;
      } else {
        throw CreditBureauException('Failed to fetch credit score: ${response.statusCode}');
      }
    } catch (e) {
      throw CreditBureauException('Failed to fetch credit score: ${e.toString()}');
    }
  }

  /// Check if user has connected their credit report
  Future<bool> isConnected({
    required CreditBureau bureau,
    required String userId,
  }) async {
    final stored = await _secureStorage.read(
      key: 'credit_auth_${bureau.name}_$userId',
    );
    return stored != null;
  }

  /// Store credit bureau authentication
  Future<void> storeAuthCredentials({
    required CreditBureau bureau,
    required String userId,
    required String accessToken,
    required String refreshToken,
    required DateTime expiresAt,
  }) async {
    final authData = {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'expiresAt': expiresAt.toIso8601String(),
      'bureau': bureau.name,
      'userId': userId,
    };

    final encryptedData = await _encryptData(jsonEncode(authData));
    await _secureStorage.write(
      key: 'credit_auth_${bureau.name}_$userId',
      value: encryptedData,
    );
  }

  /// Get stored authentication credentials
  Future<Map<String, dynamic>?> getStoredAuth({
    required CreditBureau bureau,
    required String userId,
  }) async {
    final stored = await _secureStorage.read(
      key: 'credit_auth_${bureau.name}_$userId',
    );

    if (stored == null) return null;

    try {
      final decryptedData = await _decryptData(stored);
      return jsonDecode(decryptedData);
    } catch (e) {
      // If decryption fails, remove stored data
      await _secureStorage.delete(key: 'credit_auth_${bureau.name}_$userId');
      return null;
    }
  }

  /// Refresh authentication token
  Future<String?> refreshToken({
    required CreditBureau bureau,
    required String userId,
  }) async {
    final authData = await getStoredAuth(bureau: bureau, userId: userId);
    if (authData == null) return null;

    final refreshToken = authData['refreshToken'];
    if (refreshToken == null) return null;

    try {
      final endpoint = _getBureauEndpoint(bureau);
      final response = await _client.post(
        Uri.parse('$endpoint/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      if (response.statusCode == 200) {
        final newTokens = jsonDecode(response.body);
        final newAccessToken = newTokens['accessToken'];
        final newRefreshToken = newTokens['refreshToken'];
        final expiresAt = DateTime.parse(newTokens['expiresAt']);

        await storeAuthCredentials(
          bureau: bureau,
          userId: userId,
          accessToken: newAccessToken,
          refreshToken: newRefreshToken,
          expiresAt: expiresAt,
        );

        return newAccessToken;
      }
    } catch (e) {
      // Refresh failed, user needs to reconnect
    }

    return null;
  }

  /// Disconnect credit bureau
  Future<void> disconnect({
    required CreditBureau bureau,
    required String userId,
  }) async {
    await _secureStorage.delete(key: 'credit_auth_${bureau.name}_$userId');
    await _secureStorage.delete(key: 'credit_report_${bureau.name}_$userId');
    await _secureStorage.delete(key: 'credit_score_${bureau.name}_$userId');
  }

  String _getBureauEndpoint(CreditBureau bureau) {
    switch (bureau) {
      case CreditBureau.transUnion:
        return 'https://api.transunion.com/v1'; // Placeholder - use actual API
      case CreditBureau.equifax:
        return 'https://api.equifax.com/v1'; // Placeholder - use actual API
      case CreditBureau.experian:
        return 'https://api.experian.com/v1'; // Placeholder - use actual API
    }
  }

  Future<Map<String, String>> _buildAuthHeaders(String accessToken) async {
    return {
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'User-Agent': 'CreditWise/1.0.0',
    };
  }

  Future<String> _encryptData(String data) async {
    return FinWiseEncryption.encrypt(data);
  }

  Future<String> _decryptData(String encryptedData) async {
    return FinWiseEncryption.decrypt(encryptedData);
  }

  Future<void> _updateStoredScore(CreditBureau bureau, String userId, CreditScore score) async {
    final encryptedData = await _encryptData(jsonEncode(score.toJson()));
    await _secureStorage.write(
      key: 'credit_score_${bureau.name}_$userId',
      value: encryptedData,
    );
  }
}

/// Exception for credit bureau API errors
class CreditBureauException implements Exception {
  final String message;

  CreditBureauException(this.message);

  @override
  String toString() => 'CreditBureauException: $message';
}

/// Mock implementation for development/testing
class MockCreditBureauApi extends CreditBureauApi {
  MockCreditBureauApi(super.client, super.secureStorage);

  @override
  Future<CreditReport> fetchCreditReport({
    required CreditBureau bureau,
    required String accessToken,
    required String userId,
  }) async {
    // Simulate API delay
    await Future.delayed(const Duration(seconds: 2));

    // Return mock credit report
    return _generateMockReport(bureau, userId);
  }

  @override
  Future<CreditScore> fetchCreditScore({
    required CreditBureau bureau,
    required String accessToken,
    required String userId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _generateMockScore(bureau);
  }

  CreditReport _generateMockReport(CreditBureau bureau, String userId) {
    final score = _generateMockScore(bureau);

    return CreditReport(
      id: '${bureau.name}_${userId}_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      bureau: bureau,
      currentScore: score,
      historicalScores: _generateHistoricalScores(bureau),
      accounts: _generateMockAccounts(),
      inquiries: _generateMockInquiries(),
      publicRecords: [],
      generatedAt: DateTime.now(),
      nextUpdate: DateTime.now().add(const Duration(days: 30)),
    );
  }

  CreditScore _generateMockScore(CreditBureau bureau) {
    final random = DateTime.now().millisecondsSinceEpoch % 300 + 550; // 550-850 range
    final change = (DateTime.now().millisecondsSinceEpoch % 20) - 10; // -10 to +10

    return CreditScore(
      bureau: bureau.name,
      score: random,
      lastUpdated: DateTime.now(),
      scoreType: CreditScoreType.fico,
      range: CreditScoreRange.fico,
      factors: _generateMockFactors(),
      changeFromLastMonth: change.toDouble(),
    );
  }

  List<CreditScore> _generateHistoricalScores(CreditBureau bureau) {
    final scores = <CreditScore>[];
    final baseScore = 720;

    for (int i = 11; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i * 30));
      final variation = (date.millisecondsSinceEpoch % 50) - 25;
      final score = baseScore + variation;

      scores.add(CreditScore(
        bureau: bureau.name,
        score: score.clamp(300, 850),
        lastUpdated: date,
        scoreType: CreditScoreType.fico,
        range: CreditScoreRange.fico,
        factors: [],
      ));
    }

    return scores;
  }

  List<CreditFactor> _generateMockFactors() {
    return [
      CreditFactor(
        id: 'payment_history',
        name: 'Payment History',
        type: 'paymentHistory',
        value: 35.0,
        isNegative: false,
        impact: 35.0,
        description: 'Your payment history makes up 35% of your score',
        recommendations: ['Always pay bills on time', 'Set up automatic payments'],
      ),
      CreditFactor(
        id: 'credit_utilization',
        name: 'Credit Utilization',
        type: 'creditUtilization',
        value: 25.0,
        isNegative: true,
        impact: -25.0,
        description: 'Your credit utilization is too high',
        recommendations: ['Pay down credit card balances', 'Keep utilization below 30%'],
      ),
      CreditFactor(
        id: 'account_age',
        name: 'Account Age',
        type: 'accountAge',
        value: 15.0,
        isNegative: false,
        impact: 15.0,
        description: 'Your accounts are relatively new',
        recommendations: ['Keep accounts open', 'Avoid opening too many new accounts'],
      ),
    ];
  }

  List<CreditAccount> _generateMockAccounts() {
    return [
      CreditAccount(
        id: '1',
        name: 'Chase Freedom',
        type: 'credit_card',
        accountNumber: '****1234',
        balance: 2500.0,
        creditLimit: 10000.0,
        utilization: 25.0,
        status: 'open',
        openedDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
        lastPaymentDate: DateTime.now().subtract(const Duration(days: 25)),
        minimumPayment: 75.0,
      ),
      CreditAccount(
        id: '2',
        name: 'Capital One Platinum',
        type: 'credit_card',
        accountNumber: '****5678',
        balance: 1500.0,
        creditLimit: 5000.0,
        utilization: 30.0,
        status: 'open',
        openedDate: DateTime.now().subtract(const Duration(days: 365)),
        lastPaymentDate: DateTime.now().subtract(const Duration(days: 20)),
        minimumPayment: 50.0,
      ),
    ];
  }

  List<CreditInquiry> _generateMockInquiries() {
    return [
      CreditInquiry(
        id: '1',
        creditorName: 'Auto Loan Company',
        inquiryType: 'auto_loan',
        inquiryDate: DateTime.now().subtract(const Duration(days: 45)),
      ),
      CreditInquiry(
        id: '2',
        creditorName: 'Credit Card Issuer',
        inquiryType: 'credit_card',
        inquiryDate: DateTime.now().subtract(const Duration(days: 30)),
      ),
    ];
  }
}
