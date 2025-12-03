import 'package:finwise/core/config/oauth_config.dart';
import 'package:finwise/presentation/providers/auth_providers.dart';
import 'package:finwise/presentation/theme/app_theme.dart';
import 'package:finwise/presentation/widgets/auth_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    // Listen to auth state changes
    ref.listen<AsyncValue<AuthUser?>>(
      authNotifierProvider,
      (previous, next) {
        next.whenOrNull(
          data: (user) {
            if (user != null && mounted) {
              // Successfully signed in, navigate to home
              AppRouter.goToHome();
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMD),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),

                // App Logo/Title
                _buildHeader(),

                const SizedBox(height: AppTheme.spacingXXL),

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
                  hintText: 'Enter your password',
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
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppTheme.spacingMD),

                // Forgot Password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _forgotPassword,
                    child: const Text('Forgot Password?'),
                  ),
                ),

                const SizedBox(height: AppTheme.spacingLG),

                // Sign In Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _signIn,
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
                      : const Text('Sign In'),
                ),

                const SizedBox(height: AppTheme.spacingMD),

                // Divider
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMD),
                      child: Text(
                        'or',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),

                const SizedBox(height: AppTheme.spacingMD),

                // OAuth Provider Buttons
                ..._buildOAuthButtons(),

                const SizedBox(height: AppTheme.spacingMD),

                // Demo Sign In
                TextButton(
                  onPressed: _isLoading ? null : _signInAnonymously,
                  child: const Text('Try Demo (Anonymous)'),
                ),

                const Spacer(),

                // Sign Up Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account?",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: _navigateToSignUp,
                      child: const Text('Sign Up'),
                    ),
                  ],
                ),
              ],
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
        Text(
          'Welcome to FinWise',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTheme.spacingSM),
        Text(
          'Smart Expense Management',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppTheme.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(authNotifierProvider.notifier).signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  Future<void> _signInAnonymously() async {
    // For demo purposes, navigate directly to home
    // In a real app, you'd implement anonymous auth
    if (mounted) {
      AppRouter.goToHome();
    }
  }

  void _forgotPassword() {
    Navigator.of(context).pushNamed('/forgot-password');
  }

  void _navigateToSignUp() {
    Navigator.of(context).pushNamed('/sign-up');
  }

  List<Widget> _buildOAuthButtons() {
    final availableProviders = OAuthUtils.getAvailableProviders();
    final buttons = <Widget>[];

    for (final provider in availableProviders) {
      if (buttons.isNotEmpty) {
        buttons.add(const SizedBox(height: AppTheme.spacingMD));
      }

      buttons.add(
        OutlinedButton.icon(
          onPressed: _isLoading ? null : () => _signInWithOAuth(provider.name.toLowerCase()),
          icon: _getProviderIcon(provider.iconName),
          label: Text('Continue with ${provider.name}'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMD),
          ),
        ),
      );
    }

    // Show configuration warning if no providers are configured
    if (availableProviders.isEmpty) {
      buttons.add(
        Padding(
          padding: const EdgeInsets.only(top: AppTheme.spacingMD),
          child: Text(
            'OAuth providers not configured. Please check OAuth setup.',
            style: TextStyle(
              color: AppTheme.errorColor,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return buttons;
  }

  Icon _getProviderIcon(String iconName) {
    switch (iconName) {
      case 'g_mobiledata':
        return const Icon(Icons.g_mobiledata);
      case 'facebook':
        return const Icon(Icons.facebook);
      default:
        return const Icon(Icons.account_circle);
    }
  }

  Future<void> _signInWithOAuth(String provider) async {
    setState(() {
      _isLoading = true;
    });

    try {
      switch (provider) {
        case 'google':
          await ref.read(authNotifierProvider.notifier).signInWithGoogle();
          break;
        case 'facebook':
          await ref.read(authNotifierProvider.notifier).signInWithFacebook();
          break;
        default:
          throw Exception('Unknown OAuth provider: $provider');
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
