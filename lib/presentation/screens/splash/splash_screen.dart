import 'package:finwise/core/navigation/app_router.dart';
import 'package:finwise/core/navigation/route_guard.dart';
import 'package:finwise/presentation/providers/app_startup_provider.dart';
import 'package:finwise/presentation/theme/app_theme.dart';
import 'package:finwise/presentation/screens/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Splash screen displayed during app initialization
/// Shows app branding and loading state
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate after startup completes
    _handleNavigation();
  }

  void _handleNavigation() async {
    // Wait for app startup to complete
    final startupData = await ref.read(appStartupProvider.future);

    if (mounted) {
      // Navigate based on authentication status
      final routeGuard = RouteGuard();
      final initialRoute = routeGuard.getInitialRoute();
      AppRouter.pushReplacement(initialRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    final startupState = ref.watch(appStartupProvider);

    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo/Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  size: 60,
                  color: AppTheme.primaryColor,
                ),
              )
              .animate()
              .scale(
                duration: const Duration(milliseconds: 800),
                curve: Curves.elasticOut,
              ),

              const SizedBox(height: 32),

              // App Name
              const Text(
                'FinWise',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              )
              .animate()
              .fadeIn(delay: const Duration(milliseconds: 300))
              .slideY(
                begin: 0.3,
                end: 0,
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutQuad,
              ),

              const SizedBox(height: 8),

              // Tagline
              const Text(
                'Smart Expense Management',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                  fontWeight: FontWeight.w300,
                ),
              )
              .animate()
              .fadeIn(delay: const Duration(milliseconds: 600))
              .slideY(
                begin: 0.2,
                end: 0,
                duration: const Duration(milliseconds: 500),
              ),

              const SizedBox(height: 64),

              // Loading Indicator
              startupState.maybeWhen(
                loading: () => const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                )
                .animate()
                .fadeIn(delay: const Duration(milliseconds: 900)),

                error: (error, stack) => Column(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.white,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to initialize app',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        // Retry initialization
                        ref.invalidate(appStartupProvider);
                        _handleNavigation();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.primaryColor,
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                )
                .animate()
                .fadeIn(delay: const Duration(milliseconds: 900)),

                orElse: () => const SizedBox.shrink(),
              ),

              const SizedBox(height: 32),

              // Loading text
              startupState.maybeWhen(
                loading: () => const Text(
                  'Initializing...',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                )
                .animate()
                .fadeIn(delay: const Duration(milliseconds: 1200)),

                orElse: () => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
