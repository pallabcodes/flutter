import 'dart:async';
import 'package:flutter/material.dart';
import 'package:finwise_core/animations/meaningful_interactions.dart';

/// Transaction Confirmation System - Purposeful Security and Emotional Feedback
class TransactionConfirmations {
  static final TransactionConfirmations _instance = TransactionConfirmations._internal();
  factory TransactionConfirmations() => _instance;
  TransactionConfirmations._internal();

  final MeaningfulInteractions _interactions = MeaningfulInteractions();

  /// Show Payment Confirmation with Security Emphasis
  Future<bool?> showPaymentConfirmation({
    required BuildContext context,
    required String description,
    required double amount,
    required String recipient,
    required TransactionType type,
    required String securityNote,
    String? merchant,
    VoidCallback? onConfirmed,
    VoidCallback? onCancelled,
  }) {
    final transaction = TransactionData(
      description: description,
      amount: amount,
      recipient: recipient,
      type: type,
      timestamp: DateTime.now(),
    );

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _interactions.createTransactionConfirm(
        transaction: transaction,
        onConfirm: () {
          Navigator.of(context).pop(true);
          onConfirmed?.call();
        },
        onCancel: () {
          Navigator.of(context).pop(false);
          onCancelled?.call();
        },
        securityNote: securityNote,
      ),
    );
  }

  /// Show Investment Confirmation with Risk Assessment
  Future<bool?> showInvestmentConfirmation({
    required BuildContext context,
    required String assetName,
    required String assetSymbol,
    required double shares,
    required double pricePerShare,
    required RiskLevel riskLevel,
    required double estimatedCommission,
    VoidCallback? onConfirmed,
    VoidCallback? onCancelled,
  }) {
    final totalAmount = (shares * pricePerShare) + estimatedCommission;
    final riskDescription = _getRiskLevelDescription(riskLevel);

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(_getRiskIcon(riskLevel), color: _getRiskColor(riskLevel)),
            const SizedBox(width: 8),
            const Text('Confirm Investment'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Buy ${shares.toStringAsFixed(2)} shares of $assetName ($assetSymbol)',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Price per share: \$${pricePerShare.toStringAsFixed(2)}'),
            Text('Estimated commission: \$${estimatedCommission.toStringAsFixed(2)}'),
            const Divider(),
            Text(
              'Total: \$${totalAmount.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getRiskColor(riskLevel).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _getRiskColor(riskLevel).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(_getRiskIcon(riskLevel), color: _getRiskColor(riskLevel)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Risk Level: $riskDescription',
                      style: TextStyle(color: _getRiskColor(riskLevel), fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getInvestmentAdvice(riskLevel),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
              onCancelled?.call();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(true);
              onConfirmed?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _getRiskColor(riskLevel),
            ),
            child: const Text('Confirm Investment'),
          ),
        ],
      ),
    );
  }

  /// Show Transfer Confirmation with Purpose Validation
  Future<bool?> showTransferConfirmation({
    required BuildContext context,
    required String fromAccount,
    required String toAccount,
    required double amount,
    required String purpose,
    required bool isLargeTransfer,
    VoidCallback? onConfirmed,
    VoidCallback? onCancelled,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isLargeTransfer ? Icons.security : Icons.swap_horiz,
              color: isLargeTransfer ? Colors.orange : Colors.blue,
            ),
            const SizedBox(width: 8),
            Text(isLargeTransfer ? 'Large Transfer Confirmation' : 'Confirm Transfer'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Transfer \$${amount.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text('From: $fromAccount'),
            Text('To: $toAccount'),
            const SizedBox(height: 8),
            Text('Purpose: $purpose'),
            if (isLargeTransfer) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Large transfers require additional verification for your security.',
                        style: TextStyle(color: Colors.orange, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
              onCancelled?.call();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(true);
              onConfirmed?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isLargeTransfer ? Colors.orange : Colors.blue,
            ),
            child: Text(isLargeTransfer ? 'Verify & Transfer' : 'Transfer'),
          ),
        ],
      ),
    );
  }

  /// Show Bill Payment Confirmation with Due Date Awareness
  Future<bool?> showBillPaymentConfirmation({
    required BuildContext context,
    required String billName,
    required double amount,
    required DateTime dueDate,
    required bool isOverdue,
    required bool isAutoPayEligible,
    VoidCallback? onConfirmed,
    VoidCallback? onCancelled,
    VoidCallback? onSetupAutoPay,
  }) {
    final daysUntilDue = dueDate.difference(DateTime.now()).inDays;

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isOverdue ? Icons.warning : Icons.receipt,
              color: isOverdue ? Colors.red : Colors.green,
            ),
            const SizedBox(width: 8),
            Text(isOverdue ? 'Overdue Bill Payment' : 'Confirm Bill Payment'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pay \$${amount.toStringAsFixed(2)} for $billName',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text('Due: ${dueDate.toString().split(' ')[0]}'),
            Text(
              daysUntilDue < 0
                  ? 'Overdue by ${daysUntilDue.abs()} days'
                  : daysUntilDue == 0
                      ? 'Due today'
                      : 'Due in $daysUntilDue days',
              style: TextStyle(
                color: isOverdue ? Colors.red : daysUntilDue <= 3 ? Colors.orange : Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (isAutoPayEligible) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.autorenew, color: Colors.blue, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Auto-Pay Available',
                          style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Never miss a payment again. Set up automatic payments for this bill.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
              onCancelled?.call();
            },
            child: const Text('Cancel'),
          ),
          if (isAutoPayEligible)
            OutlinedButton(
              onPressed: () {
                Navigator.of(context).pop(false);
                onSetupAutoPay?.call();
              },
              child: const Text('Setup Auto-Pay'),
            ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(true);
              onConfirmed?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isOverdue ? Colors.red : Colors.green,
            ),
            child: const Text('Pay Bill'),
          ),
        ],
      ),
    );
  }

  // Helper methods
  Color _getRiskColor(RiskLevel level) {
    switch (level) {
      case RiskLevel.veryLow: return Colors.green;
      case RiskLevel.low: return Colors.lightGreen;
      case RiskLevel.moderate: return Colors.yellow;
      case RiskLevel.high: return Colors.orange;
      case RiskLevel.veryHigh: return Colors.red;
    }
  }

  IconData _getRiskIcon(RiskLevel level) {
    switch (level) {
      case RiskLevel.veryLow: return Icons.shield;
      case RiskLevel.low: return Icons.security;
      case RiskLevel.moderate: return Icons.balance;
      case RiskLevel.high: return Icons.warning;
      case RiskLevel.veryHigh: return Icons.error;
    }
  }

  String _getRiskLevelDescription(RiskLevel level) {
    switch (level) {
      case RiskLevel.veryLow: return 'Very Low';
      case RiskLevel.low: return 'Low';
      case RiskLevel.moderate: return 'Moderate';
      case RiskLevel.high: return 'High';
      case RiskLevel.veryHigh: return 'Very High';
    }
  }

  String _getInvestmentAdvice(RiskLevel level) {
    switch (level) {
      case RiskLevel.veryLow:
        return 'This is a conservative investment with stable returns but lower potential growth.';
      case RiskLevel.low:
        return 'Low-risk investment suitable for conservative portfolios.';
      case RiskLevel.moderate:
        return 'Balanced risk-reward profile for most investors.';
      case RiskLevel.high:
        return 'Higher risk investment with potential for significant gains or losses.';
      case RiskLevel.veryHigh:
        return 'Very high risk - only suitable for experienced investors with high risk tolerance.';
    }
  }
}
