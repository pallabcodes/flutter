import 'package:finwise/presentation/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Filter options for expenses
class ExpenseFilters {
  final String? category;
  final DateTimeRange? dateRange;
  final double? minAmount;
  final double? maxAmount;
  final bool? isRecurring;
  final String? searchQuery;

  const ExpenseFilters({
    this.category,
    this.dateRange,
    this.minAmount,
    this.maxAmount,
    this.isRecurring,
    this.searchQuery,
  });

  ExpenseFilters copyWith({
    String? category,
    DateTimeRange? dateRange,
    double? minAmount,
    double? maxAmount,
    bool? isRecurring,
    String? searchQuery,
  }) {
    return ExpenseFilters(
      category: category ?? this.category,
      dateRange: dateRange ?? this.dateRange,
      minAmount: minAmount ?? this.minAmount,
      maxAmount: maxAmount ?? this.maxAmount,
      isRecurring: isRecurring ?? this.isRecurring,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  bool get hasFilters =>
      category != null ||
      dateRange != null ||
      minAmount != null ||
      maxAmount != null ||
      isRecurring != null ||
      (searchQuery != null && searchQuery!.isNotEmpty);

  void clear() {
    // This would be used to clear filters
  }
}

/// Advanced filter dialog for expenses
class FilterDialog extends StatefulWidget {
  final ExpenseFilters currentFilters;
  final Function(ExpenseFilters) onApplyFilters;

  const FilterDialog({
    super.key,
    required this.currentFilters,
    required this.onApplyFilters,
  });

  @override
  State<FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  late String? selectedCategory;
  late DateTimeRange? dateRange;
  late double? minAmount;
  late double? maxAmount;
  late bool? isRecurring;

  final TextEditingController _minAmountController = TextEditingController();
  final TextEditingController _maxAmountController = TextEditingController();

  // Available categories (in a real app, this would come from data)
  final List<String> categories = [
    'Food & Dining',
    'Transportation',
    'Shopping',
    'Entertainment',
    'Bills & Utilities',
    'Healthcare',
    'Education',
    'Travel',
    'Personal Care',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    selectedCategory = widget.currentFilters.category;
    dateRange = widget.currentFilters.dateRange;
    minAmount = widget.currentFilters.minAmount;
    maxAmount = widget.currentFilters.maxAmount;
    isRecurring = widget.currentFilters.isRecurring;

    _minAmountController.text = minAmount?.toString() ?? '';
    _maxAmountController.text = maxAmount?.toString() ?? '';
  }

  @override
  void dispose() {
    _minAmountController.dispose();
    _maxAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filter Expenses'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Filter
            const Text(
              'Category',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppTheme.spacingSM),
            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              hint: const Text('All Categories'),
              items: [
                const DropdownMenuItem(value: null, child: Text('All Categories')),
                ...categories.map((category) => DropdownMenuItem(
                  value: category,
                  child: Text(category),
                )),
              ],
              onChanged: (value) {
                setState(() {
                  selectedCategory = value;
                });
              },
            ),

            const SizedBox(height: AppTheme.spacingMD),

            // Date Range Filter
            const Text(
              'Date Range',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppTheme.spacingSM),
            InkWell(
              onTap: _selectDateRange,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.date_range, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        dateRange != null
                            ? '${_formatDate(dateRange!.start)} - ${_formatDate(dateRange!.end)}'
                            : 'Select date range',
                        style: TextStyle(
                          color: dateRange != null ? Colors.black : Colors.grey,
                        ),
                      ),
                    ),
                    if (dateRange != null)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          setState(() {
                            dateRange = null;
                          });
                        },
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppTheme.spacingMD),

            // Amount Range Filter
            const Text(
              'Amount Range',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppTheme.spacingSM),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _minAmountController,
                    decoration: const InputDecoration(
                      labelText: 'Min Amount',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        minAmount = value.isEmpty ? null : double.tryParse(value);
                      });
                    },
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSM),
                Expanded(
                  child: TextFormField(
                    controller: _maxAmountController,
                    decoration: const InputDecoration(
                      labelText: 'Max Amount',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        maxAmount = value.isEmpty ? null : double.tryParse(value);
                      });
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppTheme.spacingMD),

            // Recurring Filter
            const Text(
              'Expense Type',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppTheme.spacingSM),
            DropdownButtonFormField<bool>(
              value: isRecurring,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              hint: const Text('All Expenses'),
              items: const [
                DropdownMenuItem(value: null, child: Text('All Expenses')),
                DropdownMenuItem(value: false, child: Text('One-time Expenses')),
                DropdownMenuItem(value: true, child: Text('Recurring Expenses')),
              ],
              onChanged: (value) {
                setState(() {
                  isRecurring = value;
                });
              },
            ),

            const SizedBox(height: AppTheme.spacingMD),

            // Active Filters Summary
            if (_hasActiveFilters()) _buildActiveFiltersSummary(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _clearFilters,
          child: const Text('Clear All'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _applyFilters,
          child: const Text('Apply Filters'),
        ),
      ],
    );
  }

  Widget _buildActiveFiltersSummary() {
    final activeFilters = <String>[];

    if (selectedCategory != null) activeFilters.add('Category: $selectedCategory');
    if (dateRange != null) activeFilters.add('Date range set');
    if (minAmount != null) activeFilters.add('Min: \$$minAmount');
    if (maxAmount != null) activeFilters.add('Max: \$$maxAmount');
    if (isRecurring != null) {
      activeFilters.add(isRecurring! ? 'Recurring only' : 'One-time only');
    }

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingSM),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Active Filters:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 4),
          ...activeFilters.map((filter) => Text(
            '• $filter',
            style: const TextStyle(fontSize: 12),
          )),
        ],
      ),
    );
  }

  bool _hasActiveFilters() {
    return selectedCategory != null ||
           dateRange != null ||
           minAmount != null ||
           maxAmount != null ||
           isRecurring != null;
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: dateRange,
    );

    if (picked != null) {
      setState(() {
        dateRange = picked;
      });
    }
  }

  void _clearFilters() {
    setState(() {
      selectedCategory = null;
      dateRange = null;
      minAmount = null;
      maxAmount = null;
      isRecurring = null;
      _minAmountController.clear();
      _maxAmountController.clear();
    });
  }

  void _applyFilters() {
    final filters = ExpenseFilters(
      category: selectedCategory,
      dateRange: dateRange,
      minAmount: minAmount,
      maxAmount: maxAmount,
      isRecurring: isRecurring,
    );

    widget.onApplyFilters(filters);
    Navigator.of(context).pop(filters);
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }
}
