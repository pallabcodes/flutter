import 'package:finwise/domain/entities/expense.dart';
import 'package:finwise/presentation/providers/background_sync_provider.dart';
import 'package:finwise/presentation/providers/connectivity_provider.dart';
import 'package:finwise/presentation/providers/expense_providers.dart';
import 'package:finwise/presentation/providers/global_loading_provider.dart';
import 'package:finwise/presentation/providers/undo_redo_provider.dart';
import 'package:finwise/presentation/theme/app_theme.dart';
import 'package:finwise/presentation/widgets/error_boundary.dart';
import 'package:finwise/presentation/widgets/expense_form.dart';
import 'package:finwise/presentation/widgets/undo_redo_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Screen for editing existing expenses
/// Pre-populates form with existing expense data
class EditExpenseScreen extends ConsumerStatefulWidget {
  final Expense expense;

  const EditExpenseScreen({
    super.key,
    required this.expense,
  });

  @override
  ConsumerState<EditExpenseScreen> createState() => _EditExpenseScreenState();
}

class _EditExpenseScreenState extends ConsumerState<EditExpenseScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form data
  late TextEditingController _descriptionController;
  late TextEditingController _amountController;
  late String _selectedCategory;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late bool _isRecurring;
  String? _receiptImagePath;

  @override
  void initState() {
    super.initState();

    // Initialize form with existing expense data
    _descriptionController = TextEditingController(text: widget.expense.description ?? '');
    _amountController = TextEditingController(text: widget.expense.amount?.toString() ?? '');
    _selectedCategory = widget.expense.category ?? 'other';
    _selectedDate = widget.expense.date ?? DateTime.now();
    _selectedTime = TimeOfDay.fromDateTime(widget.expense.date ?? DateTime.now());
    _isRecurring = widget.expense.isRecurring ?? false;
    _receiptImagePath = widget.expense.receiptImagePath;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = ref.watch(isOnlineProvider);
    final connectionStatus = ref.watch(connectionStatusProvider);
    final isGlobalLoading = ref.watch(isAnyLoadingProvider);

    return ScreenErrorBoundary(
      screenName: 'Edit Expense',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Expense'),
          actions: [
            // Connectivity indicator
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: Tooltip(
                message: connectionStatus.displayName,
                child: Icon(
                  connectionStatus.icon,
                  color: connectionStatus.isOnline ? Colors.green : Colors.red,
                  size: 20,
                ),
              ),
            ),
            // Undo/Redo controls
            const UndoRedoAppBarAction(),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: isGlobalLoading ? null : _confirmDelete,
              tooltip: 'Delete Expense',
            ),
          ],
        ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingMD),
          child: ExpenseForm(
            formKey: _formKey,
            descriptionController: _descriptionController,
            amountController: _amountController,
            selectedCategory: _selectedCategory,
            selectedDate: _selectedDate,
            selectedTime: _selectedTime,
            isRecurring: _isRecurring,
            receiptImagePath: _receiptImagePath,
            onCategoryChanged: (category) {
              setState(() {
                _selectedCategory = category;
              });
            },
            onDateChanged: (date) {
              setState(() {
                _selectedDate = date;
              });
            },
            onTimeChanged: (time) {
              setState(() {
                _selectedTime = time;
              });
            },
            onRecurringChanged: (isRecurring) {
              setState(() {
                _isRecurring = isRecurring;
              });
            },
            onReceiptSelected: (imagePath) {
              setState(() {
                _receiptImagePath = imagePath;
              });
            },
            onSubmit: _updateExpense,
            submitButtonText: 'Update Expense',
          ),
        ),
      ),
    );
  }

  Future<void> _updateExpense() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final updatedExpense = widget.expense.copyWith(
      description: _descriptionController.text.trim(),
      amount: (double.parse(_amountController.text) * 100).round(), // Convert to cents
      category: ExpenseCategory.values.firstWhere(
        (cat) => cat.name == _selectedCategory,
        orElse: () => ExpenseCategory.other,
      ),
      date: DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      ),
      isRecurring: _isRecurring,
      receiptImagePath: _receiptImagePath,
      updatedAt: DateTime.now(),
    );

    // Check connectivity for offline handling
    final isOnline = ref.read(isOnlineProvider);
    final syncNotifier = ref.read(backgroundSyncProvider.notifier);

    try {
      if (isOnline) {
        // Online: Use optimistic updates for instant feedback
        await ref.executeWithTrackedLoading('update_expense', () async {
          await ref.read(expensesProvider.notifier).updateExpenseOptimistically(
            widget.expense.id,
            updatedExpense,
          );

          // Record the action for undo/redo
          await ref.executeWithUndo(UpdateExpenseAction(widget.expense, updatedExpense));
        });

        ScaffoldMessenger.of(context).showSnackBar(
          UndoRedoSnackBar.showUndoSnackBar(
            context,
            'Expense updated successfully! ✅',
            () => ref.undo(),
          ),
        );
      } else {
        // Offline: Queue for background sync
        await syncNotifier.queueOperation(SyncOperation(
          id: 'update_expense_${widget.expense.id}_${DateTime.now().millisecondsSinceEpoch}',
          type: OfflineOperationType.updateExpense,
          payload: updatedExpense.toJson(),
        ));

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expense updated offline - will sync when online 📱'),
            backgroundColor: Colors.orange,
          ),
        );
      }

      Navigator.of(context).pop(updatedExpense);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update expense: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
          action: SnackBarAction(
            label: 'Retry',
            onPressed: _updateExpense,
          ),
        ),
      );
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense'),
        content: Text(
          'Are you sure you want to delete "${widget.expense.description}"? '
          'This action cannot be undone.'
        ),
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
      await _deleteExpense();
    }
  }

  Future<void> _deleteExpense() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final deleteUseCase = ref.read(deleteExpenseUseCaseProvider);
      final result = await deleteUseCase(DeleteExpenseParams(expenseId: widget.expense.id));

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
            Navigator.of(context).pop(); // Go back to previous screen
          }
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete expense: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
