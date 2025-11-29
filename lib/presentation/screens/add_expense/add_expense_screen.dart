import 'package:finwise/domain/entities/expense.dart';
import 'package:finwise/domain/repositories/receipt_scanner_repository.dart';
import 'package:finwise/domain/usecases/create_expense_usecase.dart';
import 'package:finwise/presentation/providers/expense_providers.dart';
import 'package:finwise/presentation/providers/receipt_scanner_providers.dart';
import 'package:finwise/presentation/screens/receipt_scanner/camera_screen.dart';
import 'package:finwise/presentation/theme/app_theme.dart';
import 'package:finwise/presentation/widgets/category_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Screen for adding new expenses
/// Implements comprehensive form validation and user-friendly input
class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _noteController = TextEditingController();

  ExpenseCategory _selectedCategory = ExpenseCategory.other;
  DateTime _selectedDate = DateTime.now();
  bool _isRecurring = false;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Expense'),
        actions: [
          TextButton(
            onPressed: _saveExpense,
            child: const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.spacingMD),
          children: [
            // Amount Input
            _buildAmountField(),

            const SizedBox(height: AppTheme.spacingLG),

            // Description Input
            _buildDescriptionField(),

            const SizedBox(height: AppTheme.spacingLG),

            // Category Selection
            _buildCategorySelector(),

            const SizedBox(height: AppTheme.spacingLG),

            // Date Selection
            _buildDateSelector(),

            const SizedBox(height: AppTheme.spacingLG),

            // Note Input (Optional)
            _buildNoteField(),

            const SizedBox(height: AppTheme.spacingLG),

            // Recurring Toggle
            _buildRecurringToggle(),

            const SizedBox(height: AppTheme.spacingLG),

            // Receipt Attachment (Placeholder)
            _buildReceiptSection(),

            const SizedBox(height: AppTheme.spacingXXL),

            // Save Button
            _buildSaveButton(),
          ],
        ),
      ),
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
        labelText: 'Amount',
        hintText: '0.00',
        prefixIcon: Icon(Icons.attach_money),
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter an amount';
        }

        final amount = double.tryParse(value);
        if (amount == null || amount <= 0) {
          return 'Please enter a valid amount greater than 0';
        }

        if (amount > 1000000) {
          return 'Amount cannot exceed \$1,000,000';
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

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: const InputDecoration(
        labelText: 'Description',
        hintText: 'What did you spend on?',
        prefixIcon: Icon(Icons.description),
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter a description';
        }

        if (value.trim().length < 2) {
          return 'Description must be at least 2 characters';
        }

        if (value.length > 200) {
          return 'Description cannot exceed 200 characters';
        }

        return null;
      },
      maxLength: 200,
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppTheme.spacingSM),
        CategorySelector(
          selectedCategory: _selectedCategory,
          onCategorySelected: (category) {
            setState(() {
              _selectedCategory = category;
            });
          },
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    return InkWell(
      onTap: _selectDate,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Date',
          prefixIcon: Icon(Icons.calendar_today),
          border: OutlineInputBorder(),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat('EEEE, MMMM d, y').format(_selectedDate),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteField() {
    return TextFormField(
      controller: _noteController,
      decoration: const InputDecoration(
        labelText: 'Note (Optional)',
        hintText: 'Additional details...',
        prefixIcon: Icon(Icons.note),
        border: OutlineInputBorder(),
      ),
      maxLines: 3,
      maxLength: 500,
    );
  }

  Widget _buildRecurringToggle() {
    return SwitchListTile(
      title: const Text('Recurring Expense'),
      subtitle: const Text('This expense repeats regularly'),
      value: _isRecurring,
      onChanged: (value) {
        setState(() {
          _isRecurring = value;
        });
      },
      secondary: Icon(
        _isRecurring ? Icons.repeat : Icons.repeat_one,
        color: _isRecurring ? AppTheme.primaryColor : null,
      ),
    );
  }

  Widget _buildReceiptSection() {
    return Card(
      child: InkWell(
        onTap: _attachReceipt,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMD),
          child: Row(
            children: [
              Icon(
                Icons.receipt,
                color: AppTheme.primaryColor,
                size: 28,
              ),
              const SizedBox(width: AppTheme.spacingMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Attach Receipt',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Scan or upload receipt image',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.camera_alt,
                color: AppTheme.primaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Consumer(
      builder: (context, ref, child) {
        final isLoading = ref.watch(_savingExpenseProvider);

        return ElevatedButton(
          onPressed: isLoading ? null : _saveExpense,
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
              : const Text('Save Expense'),
        );
      },
    );
  }

  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  void _attachReceipt() async {
    // Check camera permission first
    final permissionResult = await ref.read(cameraPermissionProvider.future);
    if (!permissionResult) {
      // Request permission
      final granted = await ref.read(requestCameraPermissionProvider.future);
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Camera permission is required to scan receipts'),
              action: SnackBarAction(
                label: 'Settings',
                onPressed: () {
                  // Could open app settings here
                },
              ),
            ),
          );
        }
        return;
      }
    }

    // Navigate to camera screen
    final scanResult = await AppRouter.push(AppRouter.camera);

    // Handle scan result
    if (scanResult != null && scanResult is ReceiptScanResult) {
      _populateFromScanResult(scanResult);
    }
  }

  void _populateFromScanResult(ReceiptScanResult scanResult) {
    if (!scanResult.hasParsedData) return;

    final parsedData = scanResult.parsedData!;

    // Populate amount
    if (parsedData.totalAmount != null) {
      final amountText = parsedData.totalAmount!.toStringAsFixed(2);
      _amountController.text = amountText;
    }

    // Populate description with merchant name
    if (parsedData.merchantName != null && _descriptionController.text.isEmpty) {
      _descriptionController.text = 'Purchase at ${parsedData.merchantName}';
    }

    // Set date if available
    if (parsedData.date != null) {
      setState(() {
        _selectedDate = parsedData.date!;
      });
    }

    // Try to auto-detect category based on merchant name
    if (parsedData.merchantName != null) {
      final merchant = parsedData.merchantName!.toLowerCase();

      ExpenseCategory detectedCategory = ExpenseCategory.other;

      if (merchant.contains('restaurant') || merchant.contains('cafe') || merchant.contains('food')) {
        detectedCategory = ExpenseCategory.food;
      } else if (merchant.contains('gas') || merchant.contains('station') || merchant.contains('fuel')) {
        detectedCategory = ExpenseCategory.transportation;
      } else if (merchant.contains('grocery') || merchant.contains('market') || merchant.contains('store')) {
        detectedCategory = ExpenseCategory.shopping;
      }

      setState(() {
        _selectedCategory = detectedCategory;
      });
    }

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Receipt data extracted successfully! 📄'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final amountText = _amountController.text.replaceAll(',', '').replaceAll('\$', '');
    final amount = (double.parse(amountText) * 100).round(); // Convert to cents

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to add expenses'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    final expense = Expense(
      id: '', // Will be generated by repository
      userId: currentUser.id,
      amount: amount,
      currency: 'USD',
      description: _descriptionController.text.trim(),
      category: _selectedCategory,
      date: _selectedDate,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      note: _noteController.text.isNotEmpty ? _noteController.text.trim() : null,
      isRecurring: _isRecurring,
    );

    final createExpenseUseCase = ref.read(createExpenseUseCaseProvider);

    ref.read(_savingExpenseProvider.notifier).state = true;

    try {
      final result = await createExpenseUseCase(CreateExpenseParams(expense: expense));

      ref.read(_savingExpenseProvider.notifier).state = false;

      result.fold(
        (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save expense: ${failure.message}'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        },
        (savedExpense) {
          // Refresh the expense list
          ref.invalidate(expensesProvider);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Expense saved successfully! ✅'),
              backgroundColor: AppTheme.successColor,
            ),
          );

          // Navigate back to home screen
          AppRouter.pop();
        },
      );
    } catch (e) {
      ref.read(_savingExpenseProvider.notifier).state = false;
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
final _savingExpenseProvider = StateProvider<bool>((ref) => false);
