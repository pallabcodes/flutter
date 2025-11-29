import 'package:finwise/domain/repositories/receipt_scanner_repository.dart';
import 'package:finwise/presentation/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Card displaying receipt scan results with parsed data
class ReceiptScanResultCard extends StatelessWidget {
  final ReceiptScanResult scanResult;
  final VoidCallback? onUseData;
  final VoidCallback? onEditManually;

  const ReceiptScanResultCard({
    super.key,
    required this.scanResult,
    this.onUseData,
    this.onEditManually,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(
                  Icons.receipt_long,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: AppTheme.spacingSM),
                Text(
                  'Extracted Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppTheme.spacingLG),

            // Parsed Data
            if (scanResult.hasParsedData)
              _buildParsedDataSection(context)
            else
              _buildNoDataSection(context),

            const SizedBox(height: AppTheme.spacingLG),

            // Action Buttons
            Row(
              children: [
                if (onUseData != null)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onUseData,
                      icon: const Icon(Icons.check),
                      label: const Text('Use This Data'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),

                if (onUseData != null && onEditManually != null)
                  const SizedBox(width: AppTheme.spacingMD),

                if (onEditManually != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onEditManually,
                      icon: const Icon(Icons.edit),
                      label: const Text('Enter Manually'),
                    ),
                  ),
              ],
            ),

            // Items List (if available)
            if (scanResult.extractedItems.isNotEmpty) ...[
              const SizedBox(height: AppTheme.spacingLG),
              _buildItemsSection(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildParsedDataSection(BuildContext context) {
    final parsedData = scanResult.parsedData!;
    final currencyFormatter = NumberFormat.currency(symbol: '\$');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Merchant Name
        if (parsedData.merchantName != null) ...[
          _buildDataRow(
            context,
            'Merchant',
            parsedData.merchantName!,
            Icons.store,
          ),
          const SizedBox(height: AppTheme.spacingSM),
        ],

        // Date
        if (parsedData.date != null) ...[
          _buildDataRow(
            context,
            'Date',
            DateFormat('MMM d, yyyy').format(parsedData.date!),
            Icons.calendar_today,
          ),
          const SizedBox(height: AppTheme.spacingSM),
        ],

        // Total Amount
        if (parsedData.totalAmount != null) ...[
          _buildDataRow(
            context,
            'Total Amount',
            currencyFormatter.format(parsedData.totalAmount!),
            Icons.attach_money,
            isHighlighted: true,
          ),
          const SizedBox(height: AppTheme.spacingSM),
        ],

        // Currency
        if (parsedData.currency != null && parsedData.currency != 'USD') ...[
          _buildDataRow(
            context,
            'Currency',
            parsedData.currency!,
            Icons.currency_exchange,
          ),
          const SizedBox(height: AppTheme.spacingSM),
        ],

        // Tax
        if (parsedData.taxAmount != null) ...[
          _buildDataRow(
            context,
            'Tax',
            '\$${parsedData.taxAmount}',
            Icons.calculate,
          ),
          const SizedBox(height: AppTheme.spacingSM),
        ],

        // Subtotal
        if (parsedData.subtotal != null) ...[
          _buildDataRow(
            context,
            'Subtotal',
            '\$${parsedData.subtotal}',
            Icons.functions,
          ),
        ],
      ],
    );
  }

  Widget _buildNoDataSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange.shade700,
            size: 24,
          ),
          const SizedBox(width: AppTheme.spacingMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Limited Data Extracted',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.orange.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'We found text but couldn\'t parse specific details. You can still use the raw text or enter details manually.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detected Items',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppTheme.spacingSM),
        Container(
          constraints: const BoxConstraints(maxHeight: 150),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.all(AppTheme.spacingSM),
            itemCount: scanResult.extractedItems.length,
            itemBuilder: (context, index) {
              final item = scanResult.extractedItems[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spacingXS),
                child: Text(
                  '• $item',
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDataRow(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    bool isHighlighted = false,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: isHighlighted ? AppTheme.primaryColor : AppTheme.textSecondary,
        ),
        const SizedBox(width: AppTheme.spacingSM),
        Text(
          '$label:',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: AppTheme.spacingSM),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: isHighlighted ? FontWeight.w600 : null,
              color: isHighlighted ? AppTheme.primaryColor : null,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
