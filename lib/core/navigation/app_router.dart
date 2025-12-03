import 'package:finwise/core/navigation/route_guard.dart';
import 'package:finwise/presentation/screens/auth/forgot_password_screen.dart';
import 'package:finwise/presentation/screens/auth/login_screen.dart';
import 'package:finwise/presentation/screens/auth/sign_up_screen.dart';
import 'package:finwise/presentation/screens/budget/budget_details_screen.dart';
import 'package:finwise/presentation/screens/budget/budget_list_screen.dart';
import 'package:finwise/presentation/screens/budget/create_budget_screen.dart';
import 'package:finwise/presentation/screens/home/home_screen.dart';
import 'package:finwise/presentation/screens/receipt_scanner/camera_screen.dart';
import 'package:finwise/presentation/screens/receipt_scanner/receipt_processing_screen.dart';
import 'package:finwise/presentation/screens/add_expense/add_expense_screen.dart';
import 'package:finwise/presentation/screens/add_expense/edit_expense_screen.dart';
import 'package:finwise/presentation/screens/search/search_screen.dart';
import 'package:finwise/presentation/screens/settings/settings_screen.dart';
import 'package:finwise/presentation/screens/settings/profile_edit_screen.dart';
import 'package:finwise/presentation/screens/settings/data_export_screen.dart';
import 'package:finwise/presentation/screens/settings/help_screen.dart';
import 'package:finwise/presentation/screens/settings/privacy_policy_screen.dart';
import 'package:finwise/presentation/screens/splash/splash_screen.dart';
import 'package:flutter/material.dart';

/// Central routing configuration for the FinWise app with all screens
/// Implements route guards, authentication checks, and navigation logic
class AppRouter {
  static const String initialRoute = '/';

  // Public Routes (No authentication required)
  static const String splash = '/';
  static const String login = '/login';
  static const String signUp = '/sign-up';
  static const String forgotPassword = '/forgot-password';

  // Protected Routes (Authentication required)
  static const String home = '/home';
  static const String addExpense = '/add-expense';
  static const String budgets = '/budgets';
  static const String createBudget = '/create-budget';
  static const String camera = '/camera';
  static const String receiptProcessing = '/receipt-processing';
  static const String settings = '/settings';
  static const String search = '/search';
  static const String budgetDetails = '/budget-details';
  static const String editExpense = '/edit-expense';
  static const String profileEdit = '/profile-edit';
  static const String dataExport = '/data-export';
  static const String help = '/help';
  static const String privacyPolicy = '/privacy-policy';

  // Route guard instance for the entire app that handles authentication checks for all protected routes
  static final RouteGuard _routeGuard = RouteGuard();

  /// Generate routes with authentication checks
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final routeGuard = _routeGuard;

    // Check if route requires authentication
    if (_isProtectedRoute(settings.name)) {
      return routeGuard.guardProtectedRoute(settings, _getProtectedRoute(settings));
    }

    // Public routes
    return _getPublicRoute(settings);
  }

  /// Check if a route requires authentication
  static bool _isProtectedRoute(String? routeName) {
    if (routeName == null) return false;

    return const [
      home,
      addExpense,
      budgets,
      createBudget,
      camera,
      receiptProcessing,
      settings,
      search,
      editExpense,
      budgetDetails,
      profileEdit,
      dataExport,
      help,
      privacyPolicy,
    ].contains(routeName);
  }

  // Get public routes (accessible without authentication)
  static Route<dynamic>? _getPublicRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _buildRoute(const SplashScreen(), settings);

      case login:
        return _buildRoute(const LoginScreen(), settings);

      case signUp:
        return _buildRoute(const SignUpScreen(), settings);

      case forgotPassword:
        return _buildRoute(const ForgotPasswordScreen(), settings);

      default:
        return _buildRoute(_buildUnknownRoute(settings.name), settings);
    }
  }

  // Get protected routes (require authentication)
  static Route<dynamic>? _getProtectedRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return _buildRoute(const HomeScreen(), settings);

      case addExpense:
        return _buildRoute(const AddExpenseScreen(), settings);

      case budgets:
        return _buildRoute(const BudgetListScreen(), settings);

      case createBudget:
        return _buildRoute(const CreateBudgetScreen(), settings);

      case camera:
        return _buildRoute(const CameraScreen(), settings);

      case receiptProcessing:
        final args = settings.arguments;
        if (args is! Map<String, dynamic> || !args.containsKey('imageFile')) {
          return _buildRoute(
            _buildErrorRoute('Invalid receipt processing arguments'),
            settings,
          );
        }
        return _buildRoute(
          ReceiptProcessingScreen(imageFile: args['imageFile']),
          settings,
        );

      case settings:
        return _buildRoute(const SettingsScreen(), settings);

      case search:
        return _buildRoute(const SearchScreen(), settings);

      case editExpense:
        final args = settings.arguments;
        if (args == null) {
          return _buildRoute(
            _buildErrorRoute('Expense data is required for editing'),
            settings,
          );
        }
        return _buildRoute(
          EditExpenseScreen(expense: args),
          settings,
        );

      case budgetDetails:
        final args = settings.arguments;
        if (args == null) {
          return _buildRoute(
            _buildErrorRoute('Budget data is required for details view'),
            settings,
          );
        }
        return _buildRoute(
          BudgetDetailsScreen(budget: args),
          settings,
        );

      case profileEdit:
        return _buildRoute(const ProfileEditScreen(), settings);

      case dataExport:
        return _buildRoute(const DataExportScreen(), settings);

      case help:
        return _buildRoute(const HelpScreen(), settings);

      case privacyPolicy:
        return _buildRoute(const PrivacyPolicyScreen(), settings);

      default:
        return _buildRoute(_buildUnknownRoute(settings.name), settings);
    }
  }

  /// Build a route with custom transitions
  static MaterialPageRoute<dynamic> _buildRoute(Widget page, RouteSettings settings) {
    return MaterialPageRoute<dynamic>(
      builder: (context) => page,
      settings: settings,
      maintainState: true,
      fullscreenDialog: _isFullscreenDialog(settings.name),
    );
  }

  /// Check if route should be presented as a fullscreen dialog
  static bool _isFullscreenDialog(String? routeName) {
    return const [
      camera,
      receiptProcessing,
      createBudget,
    ].contains(routeName);
  }

  /// Build unknown route error page
  static Widget _buildUnknownRoute(String? routeName) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Route not found',
              style: Theme.of(navigatorKey.currentContext!).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Route: ${routeName ?? 'unknown'}',
              style: Theme.of(navigatorKey.currentContext!).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => navigatorKey.currentState?.pushReplacementNamed(home),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }

  /// Build error route page
  static Widget _buildErrorRoute(String message) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning, size: 64, color: Colors.orange),
            const SizedBox(height: 16),
            Text(
              'Navigation Error',
              style: Theme.of(navigatorKey.currentContext!).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(navigatorKey.currentContext!).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => navigatorKey.currentState?.pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  // Global navigator key for programmatic navigation
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // Navigation helpers
  static Future<T?> push<T>(String routeName, {Object? arguments}) {
    return navigatorKey.currentState!.pushNamed<T>(routeName, arguments: arguments);
  }

  static Future<T?> pushReplacement<T>(String routeName, {Object? arguments}) {
    return navigatorKey.currentState!.pushReplacementNamed<T>(routeName, arguments: arguments);
  }

  static void pop<T>([T? result]) {
    navigatorKey.currentState!.pop(result);
  }

  static bool canPop() {
    return navigatorKey.currentState!.canPop();
  }

  static void popUntil(String routeName) {
    navigatorKey.currentState!.popUntil(ModalRoute.withName(routeName));
  }

  static void goToLogin() {
    navigatorKey.currentState!.pushReplacementNamed(login);
  }

  static void goToSignUp() {
    navigatorKey.currentState!.pushNamed(signUp);
  }

  static void goToForgotPassword() {
    navigatorKey.currentState!.pushNamed(forgotPassword);
  }

  static void goToHome() {
    navigatorKey.currentState!.pushReplacementNamed(home);
  }

  static void goToSettings() {
    navigatorKey.currentState!.pushNamed(settings);
  }

  static void goToSearch() {
    navigatorKey.currentState!.pushNamed(search);
  }

  static void goToSignUp() {
    navigatorKey.currentState!.pushNamed(signUp);
  }

  static void goToForgotPassword() {
    navigatorKey.currentState!.pushNamed(forgotPassword);
  }

  static Future<dynamic> goToEditExpense(dynamic expense) {
    return navigatorKey.currentState!.pushNamed(editExpense, arguments: expense);
  }

  static void goToBudgetDetails(dynamic budget) {
    navigatorKey.currentState!.pushNamed(budgetDetails, arguments: budget);
  }

  // Route argument helpers
  static T? getArgs<T>(BuildContext context) {
    final modalRoute = ModalRoute.of(context);
    if (modalRoute?.settings.arguments is T) {
      return modalRoute!.settings.arguments as T;
    }
    return null;
  }

  static Map<String, dynamic>? getArgsMap(BuildContext context) {
    final modalRoute = ModalRoute.of(context);
    return modalRoute?.settings.arguments as Map<String, dynamic>?;
  }

  static T? getArg<T>(BuildContext context, String key) {
    final args = getArgsMap(context);
    if (args?.containsKey(key) == true && args![key] is T) {
      return args[key] as T;
    }
    return null;
  }
}

/// Route metadata for documentation and analysis
class RouteInfo {
  final String name;
  final String description;
  final bool requiresAuth;
  final List<String> parameters;

  const RouteInfo({
    required this.name,
    required this.description,
    required this.requiresAuth,
    this.parameters = const [],
  });
}

/// All route information for documentation
class AppRoutes {
  static const List<RouteInfo> all = [
    RouteInfo(
      name: AppRouter.splash,
      description: 'App initialization and loading screen',
      requiresAuth: false,
    ),
    RouteInfo(
      name: AppRouter.login,
      description: 'User authentication screen',
      requiresAuth: false,
    ),
    RouteInfo(
      name: AppRouter.signUp,
      description: 'User registration screen',
      requiresAuth: false,
    ),
    RouteInfo(
      name: AppRouter.forgotPassword,
      description: 'Password reset screen',
      requiresAuth: false,
    ),
    RouteInfo(
      name: AppRouter.home,
      description: 'Main dashboard with expense overview',
      requiresAuth: true,
    ),
    RouteInfo(
      name: AppRouter.addExpense,
      description: 'Add new expense with form validation',
      requiresAuth: true,
    ),
    RouteInfo(
      name: AppRouter.budgets,
      description: 'Budget management and tracking',
      requiresAuth: true,
    ),
    RouteInfo(
      name: AppRouter.createBudget,
      description: 'Create new budget with configuration',
      requiresAuth: true,
    ),
    RouteInfo(
      name: AppRouter.camera,
      description: 'Camera interface for receipt scanning',
      requiresAuth: true,
    ),
    RouteInfo(
      name: AppRouter.receiptProcessing,
      description: 'AI processing of receipt images',
      requiresAuth: true,
      parameters: ['imageFile'],
    ),
    RouteInfo(
      name: AppRouter.settings,
      description: 'App settings and user preferences',
      requiresAuth: true,
    ),
    RouteInfo(
      name: AppRouter.search,
      description: 'Advanced expense search and filtering',
      requiresAuth: true,
    ),
    RouteInfo(
      name: AppRouter.editExpense,
      description: 'Edit existing expense details',
      requiresAuth: true,
      parameters: ['expense'],
    ),
    RouteInfo(
      name: AppRouter.budgetDetails,
      description: 'Detailed budget view with analytics',
      requiresAuth: true,
      parameters: ['budget'],
    ),
  ];

  /// Get route info by name
  static RouteInfo? getRouteInfo(String routeName) {
    return all.firstWhere(
      (route) => route.name == routeName,
      orElse: () => const RouteInfo(
        name: 'unknown',
        description: 'Unknown route',
        requiresAuth: false,
      ),
    );
  }
}
