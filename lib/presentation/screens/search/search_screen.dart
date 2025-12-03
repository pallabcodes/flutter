import 'package:finwise/presentation/providers/expense_providers.dart';
import 'package:finwise/presentation/theme/app_theme.dart';
import 'package:finwise/presentation/widgets/expense_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Advanced search screen for expenses
/// Supports filtering by text, category, date range, and amount
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory;
  DateTimeRange? _dateRange;
  double? _minAmount;
  double? _maxAmount;
  bool _showFilters = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allExpenses = ref.watch(expensesProvider);
    final filteredExpenses = _filterExpenses();

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Search expenses...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white70),
          ),
          style: const TextStyle(color: Colors.white),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
          autofocus: true,
        ),
        actions: [
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_list_off : Icons.filter_list),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),
          if (_hasActiveFilters())
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearFilters,
            ),
        ],
      ),
      body: Column(
        children: [
          // Filters Panel
          if (_showFilters) _buildFiltersPanel(),

          // Search Results
          Expanded(
            child: filteredExpenses.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error: $error'),
                  ],
                ),
              ),
              data: (expenses) {
                if (expenses.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(AppTheme.spacingMD),
                  itemCount: expenses.length,
                  itemBuilder: (context, index) {
                    final expense = expenses[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppTheme.spacingMD),
                      child: ExpenseCard(
                        expense: expense,
                        onTap: () => _showExpenseDetails(expense),
                        onEdit: () => _editExpense(expense),
                        onDelete: () => _deleteExpense(expense),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersPanel() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filters',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: AppTheme.spacingMD),

          // Category Filter
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('All Categories')),
              // TODO: Add actual categories from data
              const DropdownMenuItem(value: 'food', child: Text('Food & Dining')),
              const DropdownMenuItem(value: 'transportation', child: Text('Transportation')),
              const DropdownMenuItem(value: 'shopping', child: Text('Shopping')),
              const DropdownMenuItem(value: 'entertainment', child: Text('Entertainment')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedCategory = value;
              });
            },
          ),

          const SizedBox(height: AppTheme.spacingMD),

          // Date Range Filter
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  icon: const Icon(Icons.date_range),
                  label: Text(
                    _dateRange != null
                        ? '${_dateRange!.start.toString().split(' ')[0]} - ${_dateRange!.end.toString().split(' ')[0]}'
                        : 'Select Date Range',
                  ),
                  onPressed: _selectDateRange,
                ),
              ),
              if (_dateRange != null)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _dateRange = null;
                    });
                  },
                ),
            ],
          ),

          const SizedBox(height: AppTheme.spacingMD),

          // Amount Range Filter
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Min Amount',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      _minAmount = value.isEmpty ? null : double.tryParse(value);
                    });
                  },
                ),
              ),
              const SizedBox(width: AppTheme.spacingMD),
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Max Amount',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      _maxAmount = value.isEmpty ? null : double.tryParse(value);
                    });
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spacingMD),

          // Active Filters Summary
          if (_hasActiveFilters()) _buildActiveFiltersSummary(),
        ],
      ),
    );
  }

  Widget _buildActiveFiltersSummary() {
    final activeFilters = <String>[];

    if (_selectedCategory != null) activeFilters.add('Category: $_selectedCategory');
    if (_dateRange != null) activeFilters.add('Date range set');
    if (_minAmount != null) activeFilters.add('Min: \$$_minAmount');
    if (_maxAmount != null) activeFilters.add('Max: \$$_maxAmount');

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
          ...activeFilters.map((filter) => Text(
            '• $filter',
            style: const TextStyle(fontSize: 12),
          )),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchQuery.isEmpty ? Icons.search : Icons.search_off,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty
                ? 'Start typing to search expenses'
                : 'No expenses found matching your search',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          if (_hasActiveFilters()) ...[
            const SizedBox(height: 8),
            const Text(
              'Try adjusting your filters',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }

  AsyncValue<List<dynamic>> _filterExpenses() {
    final allExpenses = ref.watch(expensesProvider);

    return allExpenses.when(
      loading: () => const AsyncValue.loading(),
      error: (error, stack) => AsyncValue.error(error, stack),
      data: (expenses) {
        var filtered = expenses;

        // Text search
        if (_searchQuery.isNotEmpty) {
          filtered = filtered.where((expense) {
            final description = expense.description?.toLowerCase() ?? '';
            final category = expense.category?.toLowerCase() ?? '';
            final query = _searchQuery.toLowerCase();
            return description.contains(query) || category.contains(query);
          }).toList();
        }

        // Category filter
        if (_selectedCategory != null) {
          filtered = filtered.where((expense) =>
            expense.category?.toLowerCase() == _selectedCategory!.toLowerCase()
          ).toList();
        }

        // Date range filter
        if (_dateRange != null) {
          filtered = filtered.where((expense) {
            if (expense.date == null) return false;
            return expense.date!.isAfter(_dateRange!.start.subtract(const Duration(days: 1))) &&
                   expense.date!.isBefore(_dateRange!.end.add(const Duration(days: 1)));
          }).toList();
        }

        // Amount range filter
        if (_minAmount != null || _maxAmount != null) {
          filtered = filtered.where((expense) {
            final amount = expense.amount ?? 0;
            final meetsMin = _minAmount == null || amount >= _minAmount!;
            final meetsMax = _maxAmount == null || amount <= _maxAmount!;
            return meetsMin && meetsMax;
          }).toList();
        }

        return AsyncValue.data(filtered);
      },
    );
  }

  bool _hasActiveFilters() {
    return _selectedCategory != null ||
           _dateRange != null ||
           _minAmount != null ||
           _maxAmount != null;
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = null;
      _dateRange = null;
      _minAmount = null;
      _maxAmount = null;
      _searchController.clear();
      _searchQuery = '';
    });
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: _dateRange,
    );

    if (picked != null) {
      setState(() {
        _dateRange = picked;
      });
    }
  }

  void _showExpenseDetails(dynamic expense) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Expense Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Description: ${expense.description ?? 'N/A'}'),
            Text('Amount: \$${expense.amount ?? 0}'),
            Text('Category: ${expense.category ?? 'N/A'}'),
            Text('Date: ${expense.date ?? 'N/A'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _editExpense(dynamic expense) {
    AppRouter.goToEditExpense(expense);
  }

  void _deleteExpense(dynamic expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense'),
        content: Text('Are you sure you want to delete "${expense.description}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final deleteUseCase = ref.read(deleteExpenseUseCaseProvider);
        final result = await deleteUseCase(DeleteExpenseParams(expenseId: expense.id));

        result.fold(
          (failure) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to delete expense: ${failure.message}')),
              );
            }
          },
          (success) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Expense deleted successfully')),
              );
              // Refresh the search results
              setState(() {});
            }
          },
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete expense: $e')),
          );
        }
      }
    }
  }
}
