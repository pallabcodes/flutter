import 'package:finwise/presentation/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Custom text field widget for authentication screens
/// Provides consistent styling and validation feedback
class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final int? maxLength;
  final int? maxLines;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.hintText,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.onChanged,
    this.maxLength,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      onChanged: onChanged,
      maxLength: maxLength,
      maxLines: maxLines,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: prefixIcon != null
            ? IconTheme(
                data: const IconThemeData(color: AppTheme.primaryColor),
                child: prefixIcon!,
              )
            : null,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          borderSide: const BorderSide(color: AppTheme.textSecondary),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          borderSide: BorderSide(color: AppTheme.textSecondary.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          borderSide: const BorderSide(color: AppTheme.errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          borderSide: const BorderSide(color: AppTheme.errorColor, width: 2),
        ),
        filled: true,
        fillColor: AppTheme.surfaceColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMD,
          vertical: AppTheme.spacingMD,
        ),
        labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppTheme.textSecondary,
        ),
        hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppTheme.textSecondary.withOpacity(0.7),
        ),
        errorStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppTheme.errorColor,
        ),
      ),
    );
  }
}

/// Password strength indicator widget
class PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const PasswordStrengthIndicator({
    super.key,
    required this.password,
  });

  @override
  Widget build(BuildContext context) {
    final strength = _calculateStrength(password);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Password Strength: ${strength.label}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: strength.color,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppTheme.spacingXS),
        LinearProgressIndicator(
          value: strength.value,
          backgroundColor: AppTheme.textSecondary.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(strength.color),
        ),
      ],
    );
  }

  PasswordStrength _calculateStrength(String password) {
    if (password.isEmpty) {
      return PasswordStrength.empty;
    }

    int score = 0;

    // Length check
    if (password.length >= 8) score += 25;
    if (password.length >= 12) score += 25;

    // Character variety checks
    if (password.contains(RegExp(r'[a-z]'))) score += 10;
    if (password.contains(RegExp(r'[A-Z]'))) score += 10;
    if (password.contains(RegExp(r'[0-9]'))) score += 10;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score += 10;

    // Complexity bonus
    if (password.length >= 16 && score >= 60) score += 10;

    if (score < 30) return PasswordStrength.weak;
    if (score < 60) return PasswordStrength.medium;
    if (score < 80) return PasswordStrength.strong;
    return PasswordStrength.veryStrong;
  }
}

enum PasswordStrength {
  empty('Empty', 0.0, Colors.grey),
  weak('Weak', 0.25, Colors.red),
  medium('Medium', 0.5, Colors.orange),
  strong('Strong', 0.75, Colors.yellow),
  veryStrong('Very Strong', 1.0, Colors.green);

  const PasswordStrength(this.label, this.value, this.color);

  final String label;
  final double value;
  final Color color;
}
