import 'package:finwise/domain/entities/budget.dart';
import 'package:finwise/domain/entities/expense.dart';
import 'package:finwise/presentation/providers/auth_providers.dart';
import 'package:finwise/presentation/providers/budget_providers.dart';
import 'package:finwise/presentation/theme/app_theme.dart';
import 'package:finwise/presentation/widgets/category_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Screen for creating a new budget
/// Implements comprehensive form validation and user-friendly input
class CreateBudgetScreen extends ConsumerStatefulWidget {
  const CreateBudgetScreen({super.key});

  @override
  ConsumerState<CreateBudgetScreen> createState() => _CreateBudgetScreenState();
}

class _CreateBudgetScreenState extends ConsumerState<CreateBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  BudgetType _budgetType = BudgetType.category;
  BudgetPeriod _budgetPeriod = BudgetPeriod.monthly;
  DateTime _startDate = DateTime.now();
  List<ExpenseCategory> _selectedCategories = [];
  bool _enableNotifications = true;

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Budget'),
        actions: [
          TextButton(
            onPressed: _saveBudget,
            child: const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.spacingMD),
          children: [
            // Budget Name
            _buildNameField(),

            const SizedBox(height: AppTheme.spacingLG),

            // Budget Type Selection
            _buildBudgetTypeSelector(),

            const SizedBox(height: AppTheme.spacingLG),

            // Amount Input
            _buildAmountField(),

            const SizedBox(height: AppTheme.spacingLG),

            // Period Selection
            _buildPeriodSelector(),

            const SizedBox(height: AppTheme.spacingLG),

            // Date Range Selection
            _buildDateRangeSelector(),

            const SizedBox(height: AppTheme.spacingLG),

            // Category Selection (for category budgets)
            if (_budgetType == BudgetType.category) ...[
              _buildCategorySelector(),
              const SizedBox(height: AppTheme.spacingLG),
            ],

            // Description (Optional)
            _buildDescriptionField(),

            const SizedBox(height: AppTheme.spacingLG),

            // Notifications Toggle
            _buildNotificationsToggle(),

            const SizedBox(height: AppTheme.spacingXXL),

            // Save Button
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: const InputDecoration(
        labelText: 'Budget Name',
        hintText: 'e.g., Monthly Groceries, Vacation Fund',
        prefixIcon: Icon(Icons.label),
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter a budget name';
        }

        if (value.trim().length < 2) {
          return 'Budget name must be at least 2 characters';
        }

        if (value.length > 50) {
          return 'Budget name cannot exceed 50 characters';
        }

        return null;
      },
      maxLength: 50,
    );
  }

  Widget _buildBudgetTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Budget Type',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppTheme.spacingSM),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.textSecondary.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          ),
          child: Column(
            children: [
              RadioListTile<BudgetType>(
                title: const Text('Category Budget'),
                subtitle: const Text('Limit spending in specific categories'),
                value: BudgetType.category,
                groupValue: _budgetType,
                onChanged: (value) {
                  setState(() {
                    _budgetType = value!;
                  });
                },
                dense: true,
              ),
              RadioListTile<BudgetType>(
                title: const Text('Overall Budget'),
                subtitle: const Text('Limit total spending across all categories'),
                value: BudgetType.overall,
                groupValue: _budgetType,
                onChanged: (value) {
                  setState(() {
                    _budgetType = value!;
                    _selectedCategories = []; // Clear categories for overall budget
                  });
                },
                dense: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      decoration: const InputDecoration(
        labelText: 'Budget Amount',
        hintText: '0.00',
        prefixIcon: Icon(Icons.attach_money),
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a budget amount';
        }

        final amount = double.tryParse(value);
        if (amount == null || amount <= 0) {
          return 'Please enter a valid amount greater than 0';
        }

        if (amount > 1000000) {
          return 'Budget amount cannot exceed \$1,000,000';
        }

        return null;
      },
      onChanged: (value) {
        // Format as currency while typing
        if (value.isNotEmpty) {
          final amount = double.tryParse(value);
          if (amount != null) {
            final formatted = NumberFormat.currency(symbol: '', decimalDigits: 2).format(amount);
            _amountController.value = TextEditingValue(
              text: formatted,
              selection: TextSelection.collapsed(offset: formatted.length),
            );
          }
        }
      },
    );
  }

  Widget _buildPeriodSelector() {
    return DropdownButtonFormField<BudgetPeriod>(
      value: _budgetPeriod,
      decoration: const InputDecoration(
        labelText: 'Budget Period',
        prefixIcon: Icon(Icons.calendar_view_month),
        border: OutlineInputBorder(),
      ),
      items: BudgetPeriod.values.map((period) {
        return DropdownMenuItem(
          value: period,
          child: Text(period.displayName),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _budgetPeriod = value;
            // Recalculate date range based on new period
            _updateDateRange();
          });
        }
      },
      validator: (value) {
        if (value == null) {
          return 'Please select a budget period';
        }
        return null;
      },
    );
  }

  Widget _buildDateRangeSelector() {
    final dateFormat = DateFormat('MMM d, yyyy');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date Range',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppTheme.spacingSM),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: _selectStartDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Start Date',
                    prefixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(),
                  ),
                  child: Text(dateFormat.format(_startDate)),
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spacingMD),
            Expanded(
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'End Date',
                  prefixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                ),
                child: Text(dateFormat.format(_calculateEndDate())),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categories',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppTheme.spacingSM),
        Container(
          constraints: const BoxConstraints(maxHeight: 200),
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.textSecondary.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingSM),
            child: Wrap(
              spacing: AppTheme.spacingSM,
              runSpacing: AppTheme.spacingSM,
              children: ExpenseCategory.values.map((category) {
                final isSelected = _selectedCategories.contains(category);
                return FilterChip(
                  label: Text(category.displayName),
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
                  backgroundColor: isSelected
                      ? AppTheme.getCategoryColor(category.name).withOpacity(0.1)
                      : null,
                  selectedColor: AppTheme.getCategoryColor(category.name).withOpacity(0.2),
                  checkmarkColor: AppTheme.getCategoryColor(category.name),
                );
              }).toList(),
            ),
          ),
        ),
        if (_budgetType == BudgetType.category && _selectedCategories.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppTheme.spacingSM),
            child: Text(
              'Please select at least one category',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.errorColor,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: const InputDecoration(
        labelText: 'Description (Optional)',
        hintText: 'Additional details about this budget',
        prefixIcon: Icon(Icons.description),
        border: OutlineInputBorder(),
      ),
      maxLines: 3,
      maxLength: 200,
    );
  }

  Widget _buildNotificationsToggle() {
    return SwitchListTile(
      title: const Text('Enable Notifications'),
      subtitle: const Text('Get alerts when approaching budget limits'),
      value: _enableNotifications,
      onChanged: (value) {
        setState(() {
          _enableNotifications = value;
        });
      },
      secondary: Icon(
        _enableNotifications ? Icons.notifications_active : Icons.notifications_off,
        color: _enableNotifications ? AppTheme.primaryColor : null,
      ),
    );
  }

  Widget _buildSaveButton() {
    return Consumer(
      builder: (context, ref, child) {
        final isLoading = ref.watch(_savingBudgetProvider);

        return ElevatedButton(
          onPressed: isLoading ? null : _saveBudget,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMD),
          ),
          child: isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Create Budget'),
        );
      },
    );
  }

  Future<void> _selectStartDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      setState(() {
        _startDate = pickedDate;
      });
    }
  }

  DateTime _calculateEndDate() {
    return _budgetPeriod.getDateRange(_startDate).end;
  }

  void _updateDateRange() {
    // This will be called when period changes to update the end date display
    setState(() {});
  }

  Future<void> _saveBudget() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Additional validation for category budgets
    if (_budgetType == BudgetType.category && _selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one category for category budgets'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to create budgets'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    final amountText = _amountController.text.replaceAll(',', '').replaceAll('\$', '');
    final amount = (double.parse(amountText) * 100).round(); // Convert to cents
    final endDate = _calculateEndDate();

    final budget = Budget(
      id: '',
      userId: currentUser.id,
      name: _nameController.text.trim(),
      description: _descriptionController.text.isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      type: _budgetType,
      targetAmount: amount,
      currency: 'USD',
      period: _budgetPeriod,
      startDate: _startDate,
      endDate: endDate,
      categories: _budgetType == BudgetType.category ? _selectedCategories : [],
      spentAmount: 0,
      enableNotifications: _enableNotifications,
      warningThreshold: 80, // Default 80%
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isActive: true,
      isSynced: false,
    );

    final createBudgetUseCase = ref.read(createBudgetUseCaseProvider);

    ref.read(_savingBudgetProvider.notifier).state = true;

    try {
      final result = await createBudgetUseCase(CreateBudgetParams(budget: budget));

      ref.read(_savingBudgetProvider.notifier).state = false;

      result.fold(
        (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to create budget: ${failure.message}'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        },
        (savedBudget) {
          // Refresh budgets list
          ref.invalidate(budgetsProvider);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Budget created successfully! 🎯'),
              backgroundColor: AppTheme.successColor,
            ),
          );

          // Navigate back
          AppRouter.pop();
        },
      );
    } catch (e) {
      ref.read(_savingBudgetProvider.notifier).state = false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unexpected error: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }
}

/// Provider for tracking save operation state
final _savingBudgetProvider = StateProvider<bool>((ref) => false);
