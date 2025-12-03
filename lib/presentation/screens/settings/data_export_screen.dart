import 'dart:io';
import 'package:finwise/presentation/providers/expense_providers.dart';
import 'package:finwise/presentation/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:csv/csv.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class DataExportScreen extends ConsumerStatefulWidget {
  const DataExportScreen({super.key});

  @override
  ConsumerState<DataExportScreen> createState() => _DataExportScreenState();
}

class _DataExportScreenState extends ConsumerState<DataExportScreen> {
  bool _isExporting = false;
  String _exportFormat = 'csv';
  DateTimeRange? _dateRange;
  List<String> _selectedCategories = [];

  // Available categories (should come from data)
  final List<String> _availableCategories = [
    'food', 'transportation', 'shopping', 'entertainment',
    'bills', 'healthcare', 'education', 'travel', 'personal', 'other'
  ];

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(expensesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Data'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Export your expense data in various formats for backup, analysis, or tax purposes.',
                style: TextStyle(fontSize: 16),
              ),

              const SizedBox(height: AppTheme.spacingLG),

              // Export Format Selection
              const Text(
                'Export Format',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppTheme.spacingMD),
              _buildFormatSelection(),

              const SizedBox(height: AppTheme.spacingLG),

              // Date Range Filter
              const Text(
                'Date Range (Optional)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppTheme.spacingMD),
              _buildDateRangeSelector(),

              const SizedBox(height: AppTheme.spacingLG),

              // Category Filter
              const Text(
                'Categories (Optional)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppTheme.spacingMD),
              _buildCategorySelector(),

              const SizedBox(height: AppTheme.spacingLG),

              // Export Summary
              expensesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Text('Error loading expenses: $error'),
                ),
                data: (expenses) => _buildExportSummary(_filterExpenses(expenses)),
              ),

              const SizedBox(height: AppTheme.spacingXXL),

              // Export Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isExporting ? null : _exportData,
                  icon: _isExporting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.download),
                  label: Text(_isExporting ? 'Exporting...' : 'Export Data'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMD),
                  ),
                ),
              ),

              const SizedBox(height: AppTheme.spacingLG),

              // Information Card
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingMD),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info,
                            color: Colors.blue.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Export Information',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacingSM),
                      Text(
                        'Your data will be exported locally to your device. '
                        'You can then share it via email, cloud storage, or other apps. '
                        'No data is sent to external servers during export.',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormatSelection() {
    return Column(
      children: [
        _buildFormatOption(
          'CSV',
          'csv',
          'Compatible with Excel, Google Sheets, and most spreadsheet applications',
          Icons.table_chart,
        ),
        const SizedBox(height: AppTheme.spacingMD),
        _buildFormatOption(
          'PDF',
          'pdf',
          'Formatted report suitable for printing and sharing',
          Icons.picture_as_pdf,
        ),
      ],
    );
  }

  Widget _buildFormatOption(String title, String format, String description, IconData icon) {
    final isSelected = _exportFormat == format;

    return InkWell(
      onTap: () {
        setState(() {
          _exportFormat = format;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingMD),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primaryColor : Colors.grey,
            ),
            const SizedBox(width: AppTheme.spacingMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppTheme.primaryColor : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: format,
              groupValue: _exportFormat,
              onChanged: (value) {
                setState(() {
                  _exportFormat = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeSelector() {
    return InkWell(
      onTap: _selectDateRange,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingMD),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.date_range),
            const SizedBox(width: AppTheme.spacingMD),
            Expanded(
              child: Text(
                _dateRange != null
                    ? '${_formatDate(_dateRange!.start)} - ${_formatDate(_dateRange!.end)}'
                    : 'Select date range (optional)',
                style: TextStyle(
                  color: _dateRange != null ? Colors.black : Colors.grey,
                ),
              ),
            ),
            if (_dateRange != null)
              IconButton(
                icon: const Icon(Icons.clear, size: 20),
                onPressed: () {
                  setState(() {
                    _dateRange = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Wrap(
      spacing: AppTheme.spacingSM,
      runSpacing: AppTheme.spacingSM,
      children: _availableCategories.map((category) {
        final isSelected = _selectedCategories.contains(category);
        return FilterChip(
          label: Text(_capitalizeCategory(category)),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedCategories.add(category);
              } else {
                _selectedCategories.remove(category);
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildExportSummary(List<dynamic> filteredExpenses) {
    final totalAmount = filteredExpenses.fold<double>(
      0,
      (sum, expense) => sum + (expense.amount ?? 0),
    );

    final dateRangeText = _dateRange != null
        ? '${_formatDate(_dateRange!.start)} to ${_formatDate(_dateRange!.end)}'
        : 'All time';

    final categoryText = _selectedCategories.isEmpty
        ? 'All categories'
        : '${_selectedCategories.length} selected categories';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Export Summary',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppTheme.spacingMD),
            _buildSummaryRow('Expenses to export', '${filteredExpenses.length}'),
            _buildSummaryRow('Total amount', '\$${totalAmount.toStringAsFixed(2)}'),
            _buildSummaryRow('Date range', dateRangeText),
            _buildSummaryRow('Categories', categoryText),
            _buildSummaryRow('Format', _exportFormat.toUpperCase()),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingSM),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  List<dynamic> _filterExpenses(List<dynamic> expenses) {
    return expenses.where((expense) {
      // Date filter
      if (_dateRange != null) {
        final expenseDate = expense.date;
        if (expenseDate == null ||
            expenseDate.isBefore(_dateRange!.start) ||
            expenseDate.isAfter(_dateRange!.end)) {
          return false;
        }
      }

      // Category filter
      if (_selectedCategories.isNotEmpty) {
        final expenseCategory = expense.category;
        if (expenseCategory == null || !_selectedCategories.contains(expenseCategory)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );

    if (picked != null) {
      setState(() {
        _dateRange = picked;
      });
    }
  }

  Future<void> _exportData() async {
    final expensesAsync = ref.read(expensesProvider);

    expensesAsync.whenData((expenses) async {
      final filteredExpenses = _filterExpenses(expenses);

      if (filteredExpenses.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No expenses to export with current filters')),
        );
        return;
      }

      setState(() {
        _isExporting = true;
      });

      try {
        late String filePath;

        if (_exportFormat == 'csv') {
          filePath = await _exportToCsv(filteredExpenses);
        } else {
          filePath = await _exportToPdf(filteredExpenses);
        }

        await Share.shareFiles(
          [filePath],
          subject: 'FinWise Expense Export',
          text: 'Your expense data export from FinWise',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data exported successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Export failed: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isExporting = false;
          });
        }
      }
    });
  }

  Future<String> _exportToCsv(List<dynamic> expenses) async {
    final csvData = [
      ['Date', 'Description', 'Category', 'Amount', 'Notes'], // Header
      ...expenses.map((expense) => [
        _formatDate(expense.date),
        expense.description ?? '',
        _capitalizeCategory(expense.category ?? 'other'),
        expense.amount?.toStringAsFixed(2) ?? '0.00',
        expense.notes ?? '',
      ]),
    ];

    final csvString = const ListToCsvConverter().convert(csvData);
    final directory = await getTemporaryDirectory();
    final fileName = 'finwise_expenses_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
    final file = File('${directory.path}/$fileName');

    await file.writeAsString(csvString);
    return file.path;
  }

  Future<String> _exportToPdf(List<dynamic> expenses) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text('FinWise Expense Report'),
              ),
              pw.Text('Generated on: ${_formatDate(DateTime.now())}'),
              pw.Text('Total Expenses: ${expenses.length}'),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: ['Date', 'Description', 'Category', 'Amount'],
                data: expenses.map((expense) => [
                  _formatDate(expense.date),
                  expense.description ?? '',
                  _capitalizeCategory(expense.category ?? 'other'),
                  '\$${(expense.amount ?? 0).toStringAsFixed(2)}',
                ]).toList(),
              ),
            ],
          );
        },
      ),
    );

    final directory = await getTemporaryDirectory();
    final fileName = 'finwise_expenses_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
    final file = File('${directory.path}/$fileName');

    await file.writeAsBytes(await pdf.save());
    return file.path;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('MMM dd, yyyy').format(date);
  }

  String _capitalizeCategory(String category) {
    return category.split('_').map((word) =>
      word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1)
    ).join(' ');
  }
}
