import 'dart:convert';
import 'dart:io';
import 'package:finwise/core/errors/failure.dart';
import 'package:finwise/core/security/encryption_service.dart';
import 'package:finwise/domain/entities/expense.dart';
import 'package:finwise/domain/entities/budget.dart';
import 'package:finwise/domain/repositories/expense_repository.dart';
import 'package:finwise/domain/repositories/budget_repository.dart';
import 'package:finwise/domain/repositories/auth_repository.dart';
import 'package:path_provider/path_provider.dart';

/// GDPR and privacy compliance service
/// Implements data export, deletion, and consent management
class PrivacyService {
  final ExpenseRepository _expenseRepository;
  final BudgetRepository _budgetRepository;
  final AuthRepository _authRepository;

  PrivacyService({
    required ExpenseRepository expenseRepository,
    required BudgetRepository budgetRepository,
    required AuthRepository authRepository,
  })  : _expenseRepository = expenseRepository,
        _budgetRepository = budgetRepository,
        _authRepository = authRepository;

  /// Export all user data in GDPR-compliant format
  Future<String> exportUserData(String userId) async {
    try {
      // Collect all user data
      final userData = await _collectUserData(userId);

      // Create GDPR-compliant export format
      final exportData = {
        'export_metadata': {
          'user_id': userId,
          'export_date': DateTime.now().toIso8601String(),
          'gdpr_version': '1.0',
          'data_portability_format': 'JSON',
          'data_controller': 'FinWise App',
        },
        'personal_data': userData['personal'] ?? {},
        'financial_data': userData['financial'] ?? {},
        'usage_data': userData['usage'] ?? {},
        'consent_records': userData['consent'] ?? {},
      };

      // Encrypt the export for security
      final jsonString = jsonEncode(exportData);
      final encryptedExport = await EncryptionService.encryptData(jsonString);

      return encryptedExport;
    } catch (e) {
      throw PrivacyFailure(
        message: 'Failed to export user data: ${e.toString()}',
      );
    }
  }

  /// Generate human-readable privacy report
  Future<String> generatePrivacyReport(String userId) async {
    try {
      final userData = await _collectUserData(userId);

      final report = '''
FINWISE PRIVACY REPORT
Generated: ${DateTime.now().toIso8601String()}
User ID: $userId

PERSONAL INFORMATION:
${_formatPersonalData(userData['personal'] ?? {})}

FINANCIAL DATA SUMMARY:
${_formatFinancialSummary(userData['financial'] ?? {})}

DATA USAGE INFORMATION:
${_formatUsageData(userData['usage'] ?? {})}

CONSENT RECORDS:
${_formatConsentData(userData['consent'] ?? {})}

DATA RETENTION POLICY:
- Personal data: Retained until account deletion
- Financial data: Retained for 7 years (tax compliance)
- Usage analytics: Anonymized after 2 years

RIGHTS UNDER GDPR:
- Right to access your data (this report)
- Right to rectification of inaccurate data
- Right to erasure ("right to be forgotten")
- Right to data portability
- Right to object to processing

For questions about your data, contact: privacy@finwise.com
''';

      return report;
    } catch (e) {
      throw PrivacyFailure(
        message: 'Failed to generate privacy report: ${e.toString()}',
      );
    }
  }

  /// Delete all user data (Right to Erasure / "Right to be Forgotten")
  Future<void> deleteUserData(String userId) async {
    try {
      // Verify user identity before deletion (would be done via auth service)
      await _verifyDeletionRequest(userId);

      // Delete data in reverse dependency order
      await _deleteFinancialData(userId);
      await _deleteUsageData(userId);
      await _deletePersonalData(userId);

      // Log deletion for compliance
      await _logDeletionEvent(userId);

      // Clear any cached data
      await _clearCacheData(userId);

    } catch (e) {
      throw PrivacyFailure(
        message: 'Failed to delete user data: ${e.toString()}',
      );
    }
  }

  /// Anonymize user data (alternative to deletion for analytics)
  Future<void> anonymizeUserData(String userId) async {
    try {
      // Replace identifiable data with anonymized versions
      await _anonymizeFinancialData(userId);
      await _anonymizeUsageData(userId);
      await _anonymizePersonalData(userId);

      // Log anonymization for compliance
      await _logAnonymizationEvent(userId);

    } catch (e) {
      throw PrivacyFailure(
        message: 'Failed to anonymize user data: ${e.toString()}',
      );
    }
  }

  /// Update user consent preferences
  Future<void> updateConsent(String userId, PrivacyConsent consent) async {
    try {
      // Store consent record
      final consentRecord = {
        'user_id': userId,
        'timestamp': DateTime.now().toIso8601String(),
        'consent_version': '1.0',
        'analytics_consent': consent.analyticsConsent,
        'marketing_consent': consent.marketingConsent,
        'data_sharing_consent': consent.dataSharingConsent,
        'third_party_consent': consent.thirdPartyConsent,
        'ip_address': await _getAnonymizedIP(),
        'user_agent': await _getUserAgent(),
      };

      // Store consent record securely
      final consentJson = jsonEncode(consentRecord);
      await _storeConsentRecord(userId, consentJson);

      // Apply consent settings
      await _applyConsentSettings(userId, consent);

      // Log consent change
      await _logConsentChange(userId, consent);

    } catch (e) {
      throw PrivacyFailure(
        message: 'Failed to update consent: ${e.toString()}',
      );
    }
  }

  /// Get current consent status
  Future<PrivacyConsent?> getConsentStatus(String userId) async {
    try {
      final consentJson = await _getConsentRecord(userId);
      if (consentJson == null) return null;

      final consentData = jsonDecode(consentJson) as Map<String, dynamic>;
      return PrivacyConsent(
        analyticsConsent: consentData['analytics_consent'] ?? false,
        marketingConsent: consentData['marketing_consent'] ?? false,
        dataSharingConsent: consentData['data_sharing_consent'] ?? false,
        thirdPartyConsent: consentData['third_party_consent'] ?? false,
        consentTimestamp: DateTime.parse(consentData['timestamp']),
      );
    } catch (e) {
      return null;
    }
  }

  /// Check if user has consented to data processing
  Future<bool> hasRequiredConsents(String userId) async {
    final consent = await getConsentStatus(userId);
    return consent?.analyticsConsent == true; // At minimum, analytics consent required
  }

  /// Get data retention policy information
  Map<String, dynamic> getRetentionPolicy() {
    return {
      'personal_data': {
        'retention_period': 'Until account deletion',
        'legal_basis': 'Contract performance',
        'purpose': 'Account management and personalization',
      },
      'financial_data': {
        'retention_period': '7 years',
        'legal_basis': 'Legal obligation (tax compliance)',
        'purpose': 'Financial record keeping',
      },
      'usage_analytics': {
        'retention_period': '2 years (anonymized)',
        'legal_basis': 'Legitimate interest',
        'purpose': 'Service improvement and analytics',
      },
      'consent_records': {
        'retention_period': 'Indefinite',
        'legal_basis': 'Legal obligation',
        'purpose': 'GDPR compliance and audit trail',
      },
    };
  }

  // Private helper methods

  Future<Map<String, dynamic>> _collectUserData(String userId) async {
    return {
      'personal': await _collectPersonalData(userId),
      'financial': await _collectFinancialData(userId),
      'usage': await _collectUsageData(userId),
      'consent': await _collectConsentData(userId),
    };
  }

  Future<Map<String, dynamic>> _collectPersonalData(String userId) async {
    try {
      final user = await _authRepository.getCurrentUser();
      return {
        'user_id': userId,
        'email': user?.email,
        'display_name': user?.displayName,
        'account_creation_date': user?.creationTime,
        'last_sign_in': user?.lastSignInTime,
        'email_verified': user?.emailVerified,
      };
    } catch (e) {
      return {'error': 'Failed to collect personal data: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> _collectFinancialData(String userId) async {
    try {
      final expenses = await _expenseRepository.getExpenses(userId: userId);
      final budgets = await _budgetRepository.getBudgets(userId: userId);

      return {
        'expenses_count': expenses.length,
        'budgets_count': budgets.length,
        'total_expense_amount': expenses.fold<double>(0, (sum, expense) => sum + expense.amount),
        'expense_categories': _groupExpensesByCategory(expenses),
        'data_period': _calculateDataPeriod(expenses),
      };
    } catch (e) {
      return {'error': 'Failed to collect financial data: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> _collectUsageData(String userId) async {
    // This would collect analytics data from Firebase Analytics
    return {
      'app_version': '1.0.0',
      'platform': Platform.operatingSystem,
      'sessions_count': 0, // Would come from analytics
      'features_used': [], // Would come from analytics
      'last_active': DateTime.now().toIso8601String(),
    };
  }

  Future<Map<String, dynamic>> _collectConsentData(String userId) async {
    final consent = await getConsentStatus(userId);
    return {
      'current_consent': consent?.toJson(),
      'consent_history': [], // Would store historical consent changes
    };
  }

  Future<void> _deleteFinancialData(String userId) async {
    // Delete all expenses and budgets
    final expenses = await _expenseRepository.getExpenses(userId: userId);
    for (final expense in expenses) {
      await _expenseRepository.deleteExpense(expense.id);
    }

    final budgets = await _budgetRepository.getBudgets(userId: userId);
    for (final budget in budgets) {
      await _budgetRepository.deleteBudget(budget.id);
    }
  }

  Future<void> _deleteUsageData(String userId) async {
    // This would clear analytics data from Firebase
    // Implementation depends on Firebase Analytics API
  }

  Future<void> _deletePersonalData(String userId) async {
    // Delete user account
    await _authRepository.deleteAccount();
  }

  Future<void> _verifyDeletionRequest(String userId) async {
    // Verify user identity through re-authentication
    // This would typically require password confirmation
  }

  Future<void> _anonymizeFinancialData(String userId) async {
    // Replace identifiable data with anonymous equivalents
    // This keeps statistical data while removing personal identifiers
  }

  Future<void> _anonymizeUsageData(String userId) async {
    // Remove user identifiers from analytics data
  }

  Future<void> _anonymizePersonalData(String userId) async {
    // Replace personal data with anonymous data
  }

  // Helper methods for formatting reports
  String _formatPersonalData(Map<String, dynamic> data) {
    return '''
- User ID: ${data['user_id']}
- Email: ${data['email']}
- Display Name: ${data['display_name']}
- Account Created: ${data['account_creation_date']}
- Last Sign In: ${data['last_sign_in']}
- Email Verified: ${data['email_verified']}
''';
  }

  String _formatFinancialSummary(Map<String, dynamic> data) {
    final categories = data['expense_categories'] as Map<String, dynamic>? ?? {};
    return '''
- Total Expenses: ${data['expenses_count']}
- Total Amount: \$${data['total_expense_amount']?.toStringAsFixed(2) ?? '0.00'}
- Active Budgets: ${data['budgets_count']}
- Top Categories: ${categories.keys.take(3).join(', ')}
- Data Period: ${data['data_period'] ?? 'N/A'}
''';
  }

  String _formatUsageData(Map<String, dynamic> data) {
    return '''
- App Version: ${data['app_version']}
- Platform: ${data['platform']}
- Sessions: ${data['sessions_count']}
- Last Active: ${data['last_active']}
''';
  }

  String _formatConsentData(Map<String, dynamic> data) {
    final consent = data['current_consent'];
    if (consent == null) return '- No consent records found';

    return '''
- Analytics Consent: ${consent['analytics_consent']}
- Marketing Consent: ${consent['marketing_consent']}
- Data Sharing: ${consent['data_sharing_consent']}
- Third Party: ${consent['third_party_consent']}
- Last Updated: ${consent['consent_timestamp']}
''';
  }

  Map<String, int> _groupExpensesByCategory(List<Expense> expenses) {
    final categories = <String, int>{};
    for (final expense in expenses) {
      categories[expense.category.name] = (categories[expense.category.name] ?? 0) + 1;
    }
    return categories;
  }

  String _calculateDataPeriod(List<Expense> expenses) {
    if (expenses.isEmpty) return 'No data';

    final dates = expenses.map((e) => e.date).toList();
    dates.sort();

    final start = dates.first;
    final end = dates.last;

    if (start.year == end.year && start.month == end.month) {
      return '${start.month}/${start.year}';
    }

    return '${start.month}/${start.year} - ${end.month}/${end.year}';
  }

  // Placeholder implementations for compliance logging
  Future<void> _logDeletionEvent(String userId) async {
    // Log to compliance audit trail
  }

  Future<void> _logAnonymizationEvent(String userId) async {
    // Log anonymization for compliance
  }

  Future<void> _logConsentChange(String userId, PrivacyConsent consent) async {
    // Log consent changes for audit trail
  }

  Future<void> _storeConsentRecord(String userId, String consentJson) async {
    // Store consent record securely
  }

  Future<String?> _getConsentRecord(String userId) async {
    // Retrieve consent record
    return null;
  }

  Future<void> _applyConsentSettings(String userId, PrivacyConsent consent) async {
    // Apply consent settings to various services
  }

  Future<String> _getAnonymizedIP() async {
    // Get anonymized IP for consent logging
    return '0.0.0.0';
  }

  Future<String> _getUserAgent() async {
    // Get user agent string
    return 'FinWise/1.0.0';
  }

  Future<void> _clearCacheData(String userId) async {
    // Clear any cached data for the user
  }
}

/// Privacy consent data structure
class PrivacyConsent {
  final bool analyticsConsent;
  final bool marketingConsent;
  final bool dataSharingConsent;
  final bool thirdPartyConsent;
  final DateTime? consentTimestamp;

  PrivacyConsent({
    required this.analyticsConsent,
    required this.marketingConsent,
    required this.dataSharingConsent,
    required this.thirdPartyConsent,
    this.consentTimestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'analytics_consent': analyticsConsent,
      'marketing_consent': marketingConsent,
      'data_sharing_consent': dataSharingConsent,
      'third_party_consent': thirdPartyConsent,
      'consent_timestamp': consentTimestamp?.toIso8601String(),
    };
  }

  factory PrivacyConsent.fromJson(Map<String, dynamic> json) {
    return PrivacyConsent(
      analyticsConsent: json['analytics_consent'] ?? false,
      marketingConsent: json['marketing_consent'] ?? false,
      dataSharingConsent: json['data_sharing_consent'] ?? false,
      thirdPartyConsent: json['third_party_consent'] ?? false,
      consentTimestamp: json['consent_timestamp'] != null
          ? DateTime.parse(json['consent_timestamp'])
          : null,
    );
  }
}

/// Privacy compliance failure
class PrivacyFailure extends Failure {
  PrivacyFailure({required super.message});
}
