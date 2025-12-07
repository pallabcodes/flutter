import 'dart:io';

import 'package:finwise/core/navigation/app_router.dart';
import 'package:finwise/domain/repositories/receipt_scanner_repository.dart';
import 'package:finwise/presentation/providers/receipt_scanner_providers.dart';
import 'package:finwise/presentation/theme/app_theme.dart';
import 'package:finwise/presentation/widgets/receipt_scan_result_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Screen that processes receipt images and shows OCR results
class ReceiptProcessingScreen extends ConsumerStatefulWidget {
  final File imageFile;

  const ReceiptProcessingScreen({
    super.key,
    required this.imageFile,
  });

  @override
  ConsumerState<ReceiptProcessingScreen> createState() => _ReceiptProcessingScreenState();
}

class _ReceiptProcessingScreenState extends ConsumerState<ReceiptProcessingScreen> {
  @override
  void initState() {
    super.initState();
    // Start processing immediately
    _processReceipt();
  }

  Future<void> _processReceipt() async {
    final receiptScanner = ref.read(receiptScannerRepositoryProvider);
    final result = await receiptScanner.scanReceipt(widget.imageFile);

    result.fold(
      (failure) {
        if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to scan receipt: ${failure.message}'),
                  backgroundColor: AppTheme.errorColor,
                ),
              );
          AppRouter.pop();
        }
      },
      (scanResult) {
        // Processing successful, result will be shown in UI
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scanResultAsync = ref.watch(receiptScanResultProvider(widget.imageFile));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Processing Receipt'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => AppRouter.pop(),
        ),
      ),
      body: scanResultAsync.when(
        loading: () => _buildLoadingView(),
        error: (error, stack) => _buildErrorView(error.toString()),
        data: (scanResult) => _buildResultView(scanResult),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Receipt Image Preview
          Container(
            width: 200,
            height: 300,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              image: DecorationImage(
                image: FileImage(widget.imageFile),
                fit: BoxFit.cover,
              ),
            ),
          ),

          const SizedBox(height: AppTheme.spacingXL),

          const CircularProgressIndicator(),

          const SizedBox(height: AppTheme.spacingMD),

          const Text(
            'Analyzing receipt...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: AppTheme.spacingSM),

          const Text(
            'Extracting text and amounts',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLG),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.errorColor,
            ),

            const SizedBox(height: AppTheme.spacingLG),

            Text(
              'Failed to process receipt',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.errorColor,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppTheme.spacingMD),

            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppTheme.spacingXL),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () => AppRouter.pop(),
                  child: const Text('Try Again'),
                ),

                const SizedBox(width: AppTheme.spacingMD),

                ElevatedButton(
                  onPressed: _processReceipt,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultView(ReceiptScanResult scanResult) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with confidence
          Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: AppTheme.successColor,
              ),
              const SizedBox(width: AppTheme.spacingSM),
              Text(
                'Receipt scanned successfully',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.successColor,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingSM,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                ),
                child: Text(
                  '${scanResult.confidencePercentage} confidence',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.successColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spacingLG),

          // Scan Result Card
          ReceiptScanResultCard(
            scanResult: scanResult,
            onUseData: () => _useScanData(scanResult),
            onEditManually: _editManually,
          ),

          const SizedBox(height: AppTheme.spacingLG),

          // Raw Text (Collapsible)
          _buildRawTextSection(scanResult.rawText),
        ],
      ),
    );
  }

  Widget _buildRawTextSection(String rawText) {
    return ExpansionTile(
      title: const Text('View Raw Text'),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppTheme.spacingMD),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: SelectableText(
            rawText,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }

  void _useScanData(ReceiptScanResult scanResult) {
    // Navigate back to add expense screen with pre-filled data
                        AppRouter.pop(scanResult);
  }

  void _editManually() {
    // Navigate back to add expense screen without data
    AppRouter.pop();
  }
}
