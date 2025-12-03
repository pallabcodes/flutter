import 'package:finwise/presentation/providers/auth_providers.dart';
import 'package:finwise/presentation/theme/app_theme.dart';
import 'package:finwise/presentation/widgets/auth_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _displayNameController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _acceptTerms = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    // Listen to auth state changes
    ref.listen<AsyncValue<dynamic>>(
      authNotifierProvider,
      (previous, next) {
        next.whenOrNull(
          data: (user) {
            if (user != null && mounted) {
              // Successfully signed up, navigate to home
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account created successfully! Please check your email for verification.'),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.of(context).pushReplacementNamed('/home');
            }
          },
          error: (error, stack) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(error.toString()),
                  backgroundColor: AppTheme.errorColor,
                ),
              );
            }
          },
        );
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMD),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppTheme.spacingLG),

                  // App Logo/Title
                  _buildHeader(),

                  const SizedBox(height: AppTheme.spacingXXL),

                  // Display Name Field
                  AuthTextField(
                    controller: _displayNameController,
                    labelText: 'Display Name',
                    hintText: 'Enter your display name',
                    prefixIcon: Icons.person,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your display name';
                      }
                      if (value.length < 2) {
                        return 'Display name must be at least 2 characters';
                      }
                      if (value.length > 50) {
                        return 'Display name must be less than 50 characters';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: AppTheme.spacingMD),

                  // Email Field
                  AuthTextField(
                    controller: _emailController,
                    labelText: 'Email',
                    hintText: 'Enter your email',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: AppTheme.spacingMD),

                  // Password Field
                  AuthTextField(
                    controller: _passwordController,
                    labelText: 'Password',
                    hintText: 'Create a strong password',
                    obscureText: !_isPasswordVisible,
                    prefixIcon: Icons.lock,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a password';
                      }
                      if (value.length < 8) {
                        return 'Password must be at least 8 characters';
                      }
                      if (!RegExp(r'(?=.*[a-z])').hasMatch(value)) {
                        return 'Password must contain at least one lowercase letter';
                      }
                      if (!RegExp(r'(?=.*[A-Z])').hasMatch(value)) {
                        return 'Password must contain at least one uppercase letter';
                      }
                      if (!RegExp(r'(?=.*\d)').hasMatch(value)) {
                        return 'Password must contain at least one number';
                      }
                      if (!RegExp(r'(?=.*[@$!%*?&])').hasMatch(value)) {
                        return 'Password must contain at least one special character';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: AppTheme.spacingMD),

                  // Confirm Password Field
                  AuthTextField(
                    controller: _confirmPasswordController,
                    labelText: 'Confirm Password',
                    hintText: 'Re-enter your password',
                    obscureText: !_isConfirmPasswordVisible,
                    prefixIcon: Icons.lock_outline,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                        });
                      },
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: AppTheme.spacingMD),

                  // Terms and Conditions Checkbox
                  CheckboxListTile(
                    value: _acceptTerms,
                    onChanged: (value) {
                      setState(() {
                        _acceptTerms = value ?? false;
                      });
                    },
                    title: const Text('I accept the Terms and Conditions'),
                    subtitle: Row(
                      children: [
                        const Text('Read our '),
                        TextButton(
                          onPressed: _showTermsAndConditions,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Terms'),
                        ),
                        const Text(' and '),
                        TextButton(
                          onPressed: _showPrivacyPolicy,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Privacy Policy'),
                        ),
                      ],
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),

                  const SizedBox(height: AppTheme.spacingLG),

                  // Sign Up Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _signUp,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMD),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Create Account'),
                  ),

                  const SizedBox(height: AppTheme.spacingLG),

                  // Already have account link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already have an account?"),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Sign In'),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppTheme.spacingMD),

                  // Password strength indicator
                  if (_passwordController.text.isNotEmpty)
                    _buildPasswordStrengthIndicator(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.account_balance_wallet,
            size: 40,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: AppTheme.spacingMD),
        const Text(
          'Join FinWise',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTheme.spacingSM),
        Text(
          'Create your account to start managing expenses',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    final password = _passwordController.text;
    final strength = _calculatePasswordStrength(password);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppTheme.spacingSM),
        Text(
          'Password Strength: ${strength['label']}',
          style: TextStyle(
            fontSize: 12,
            color: strength['color'] as Color,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: strength['value'] as double,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(strength['color'] as Color),
        ),
      ],
    );
  }

  Map<String, dynamic> _calculatePasswordStrength(String password) {
    int score = 0;

    if (password.length >= 8) score++;
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'\d').hasMatch(password)) score++;
    if (RegExp(r'[@$!%*?&]').hasMatch(password)) score++;

    final percentage = score / 5.0;

    if (percentage <= 0.2) {
      return {'label': 'Very Weak', 'value': percentage, 'color': Colors.red};
    } else if (percentage <= 0.4) {
      return {'label': 'Weak', 'value': percentage, 'color': Colors.orange};
    } else if (percentage <= 0.6) {
      return {'label': 'Fair', 'value': percentage, 'color': Colors.yellow[700]!};
    } else if (percentage <= 0.8) {
      return {'label': 'Good', 'value': percentage, 'color': Colors.lightGreen};
    } else {
      return {'label': 'Strong', 'value': percentage, 'color': Colors.green};
    }
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the Terms and Conditions'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(authNotifierProvider.notifier).signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        confirmPassword: _confirmPasswordController.text,
        displayName: _displayNameController.text.trim(),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showTermsAndConditions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms and Conditions'),
        content: const SingleChildScrollView(
          child: Text(
            'By using FinWise, you agree to our terms of service...\n\n'
            '1. Privacy & Data Protection\n'
            '2. Account Responsibility\n'
            '3. Service Usage\n'
            '4. Payment Terms\n'
            '5. Termination\n\n'
            'Full terms available at our website.',
          ),
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

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'FinWise is committed to protecting your privacy...\n\n'
            '• We collect minimal personal data\n'
            '• Your financial data is encrypted\n'
            '• We never share data without consent\n'
            '• You can delete your data anytime\n\n'
            'Full privacy policy available at our website.',
          ),
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
}
