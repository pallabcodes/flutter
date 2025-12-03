import 'package:finwise/domain/entities/expense.dart';
import 'package:finwise/presentation/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Interactive widget for selecting expense categories
/// Displays categories as chips with icons and supports selection
class CategorySelector extends StatefulWidget {
  final ExpenseCategory selectedCategory;
  final ValueChanged<ExpenseCategory> onCategorySelected;

  const CategorySelector({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  State<CategorySelector> createState() => _CategorySelectorState();
}

class _CategorySelectorState extends State<CategorySelector> {
  late ExpenseCategory _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.selectedCategory;
  }

  @override
  void didUpdateWidget(CategorySelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCategory != widget.selectedCategory) {
      _selectedCategory = widget.selectedCategory;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppTheme.spacingSM,
      runSpacing: AppTheme.spacingSM,
      children: ExpenseCategory.values.map((category) {
        return _buildCategoryChip(category);
      }).toList(),
    );
  }

  Widget _buildCategoryChip(ExpenseCategory category) {
    final isSelected = _selectedCategory == category;

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(category.icon),
          const SizedBox(width: AppTheme.spacingXS),
          Text(category.displayName),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedCategory = category;
          });
          widget.onCategorySelected(category);
        }
      },
      backgroundColor: isSelected
          ? AppTheme.getCategoryColor(category.name).withOpacity(0.1)
          : null,
      selectedColor: AppTheme.getCategoryColor(category.name).withOpacity(0.2),
      checkmarkColor: AppTheme.getCategoryColor(category.name),
      side: BorderSide(
        color: isSelected
            ? AppTheme.getCategoryColor(category.name)
            : AppTheme.textSecondary.withOpacity(0.3),
        width: isSelected ? 2 : 1,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMD,
        vertical: AppTheme.spacingSM,
      ),
    );
  }
}

/// Alternative grid-based category selector for more compact display
class CategoryGridSelector extends StatefulWidget {
  final ExpenseCategory selectedCategory;
  final ValueChanged<ExpenseCategory> onCategorySelected;

  const CategoryGridSelector({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  State<CategoryGridSelector> createState() => _CategoryGridSelectorState();
}

class _CategoryGridSelectorState extends State<CategoryGridSelector> {
  late ExpenseCategory _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.selectedCategory;
  }

  @override
  void didUpdateWidget(CategoryGridSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCategory != widget.selectedCategory) {
      _selectedCategory = widget.selectedCategory;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: AppTheme.spacingSM,
        mainAxisSpacing: AppTheme.spacingSM,
        childAspectRatio: 1.2,
      ),
      itemCount: ExpenseCategory.values.length,
      itemBuilder: (context, index) {
        final category = ExpenseCategory.values[index];
        return _buildCategoryCard(category);
      },
    );
  }

  Widget _buildCategoryCard(ExpenseCategory category) {
    final isSelected = _selectedCategory == category;

    return Card(
      elevation: isSelected ? 4 : 1,
      color: isSelected
          ? AppTheme.getCategoryColor(category.name).withOpacity(0.1)
          : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        side: BorderSide(
          color: isSelected
              ? AppTheme.getCategoryColor(category.name)
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedCategory = category;
          });
          widget.onCategorySelected(category);
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMD),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                category.icon,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(height: AppTheme.spacingXS),
              Text(
                category.displayName,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? AppTheme.getCategoryColor(category.name)
                      : null,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dropdown-based category selector for compact spaces
class CategoryDropdown extends StatelessWidget {
  final ExpenseCategory selectedCategory;
  final ValueChanged<ExpenseCategory> onCategorySelected;

  const CategoryDropdown({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<ExpenseCategory>(
      value: selectedCategory,
      decoration: const InputDecoration(
        labelText: 'Category',
        prefixIcon: Icon(Icons.category),
        border: OutlineInputBorder(),
      ),
      items: ExpenseCategory.values.map((category) {
        return DropdownMenuItem(
          value: category,
          child: Row(
            children: [
              Text(category.icon),
              const SizedBox(width: AppTheme.spacingSM),
              Text(category.displayName),
            ],
          ),
        );
      }).toList(),
      onChanged: (category) {
        if (category != null) {
          onCategorySelected(category);
        }
      },
      validator: (value) {
        if (value == null) {
          return 'Please select a category';
        }
        return null;
      },
    );
  }
}
