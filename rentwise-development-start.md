# 🚀 RentWise Development: Quick Start Guide

## Immediate Next Steps to Launch RentWise MVP

---

## 📋 **PHASE 1: FOUNDATION (TODAY)**

### **Step 1: Complete Monorepo Migration**
```bash
# Ensure we're in the project root
cd /Users/picon/Learning/flutter

# Run safe migration
dart tool/monorepo_migration.dart migrate

# Validate migration success
dart tool/monorepo_migration.dart validate
```

### **Step 2: Create RentWise App Structure**
```bash
# Create RentWise app directory
mkdir -p apps/rentwise

# Navigate to app directory
cd apps/rentwise

# Initialize Flutter app
flutter create . --project-name rentwise --org com.finwise
```

### **Step 3: Configure Dependencies**
```yaml
# Edit apps/rentwise/pubspec.yaml
name: rentwise
description: Smart Rental Management

environment:
  sdk: '>=3.1.0 <4.0.0'
  flutter: ">=3.13.0"

dependencies:
  flutter:
    sdk: flutter

  # Shared packages (from monorepo)
  finwise_core:
    path: ../../packages/core
  finwise_ui:
    path: ../../packages/ui
  finwise_auth:
    path: ../../packages/features/auth
  finwise_payments:
    path: ../../packages/features/payments

  # App-specific dependencies
  google_ml_kit: ^0.16.0
  pdf: ^3.10.0
  share_plus: ^7.0.0
  flutter_local_notifications: ^15.0.0
  image_picker: ^1.0.0
  stripe_payment: ^1.0.4
  firebase_storage: ^11.2.6

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^2.0.0
```

---

## 🏗️ **PHASE 2: CORE STRUCTURE (WEEK 1)**

### **Step 4: Implement App Architecture**
```dart
// apps/rentwise/lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finwise_core/finwise_core.dart';
import 'package:finwise_ui/finwise_ui.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize shared services
  await FinWiseCore.initialize();

  runApp(
    const ProviderScope(
      child: RentWiseApp(),
    ),
  );
}

class RentWiseApp extends StatelessWidget {
  const RentWiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RentWise',
      theme: FinWiseTheme.lightTheme,
      darkTheme: FinWiseTheme.darkTheme,
      home: const RentWiseHomePage(),
    );
  }
}
```

### **Step 5: Create Core Feature Structure**
```bash
# Create feature directories
mkdir -p lib/features/payments
mkdir -p lib/features/documents
mkdir -p lib/features/properties
mkdir -p lib/features/communication
mkdir -p lib/features/maintenance

# Create presentation layer
mkdir -p lib/presentation/providers
mkdir -p lib/presentation/screens
mkdir -p lib/presentation/widgets

# Create data layer
mkdir -p lib/data/repositories
mkdir -p lib/data/models
mkdir -p lib/data/datasources
```

---

## 💳 **PHASE 3: PAYMENT SYSTEM (WEEK 1)**

### **Step 6: Implement Payment Processing**
```dart
// lib/features/payments/rent_payment_service.dart
import 'package:finwise_payments/finwise_payments.dart';

class RentPaymentService {
  final PaymentProcessor _processor = PaymentProcessor();

  Future<PaymentResult> processRentPayment({
    required double amount,
    required String propertyId,
    required PaymentMethod method,
  }) async {
    try {
      final result = await _processor.processPayment(
        amount: amount,
        currency: 'USD',
        method: method,
        metadata: {'type': 'rent', 'propertyId': propertyId},
      );

      // Log expense in FinWise
      await _logRentExpense(amount, propertyId);

      return result;
    } catch (e) {
      throw PaymentException('Payment failed: $e');
    }
  }

  Future<void> _logRentExpense(double amount, String propertyId) async {
    // Integration with FinWise expense tracking
    // This will automatically categorize as "Housing"
  }
}
```

### **Step 7: Create Payment UI**
```dart
// lib/presentation/screens/payments/rent_payment_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finwise_ui/finwise_ui.dart';

class RentPaymentScreen extends ConsumerWidget {
  const RentPaymentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pay Rent')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Rent Amount',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('\$1,200.00', style: TextStyle(fontSize: 32)),
            const SizedBox(height: 24),
            const Text('Due Date: March 1st'),
            const SizedBox(height: 32),
            FinWiseButton.primary(
              text: 'Pay Rent Now',
              onPressed: () => _processPayment(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processPayment(BuildContext context, WidgetRef ref) async {
    // Implement payment processing
  }
}
```

---

## 📄 **PHASE 4: DOCUMENT MANAGEMENT (WEEK 2)**

### **Step 8: Implement Document Scanning**
```dart
// lib/features/documents/document_scanner.dart
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';

class DocumentScanner {
  final TextRecognizer _textRecognizer = GoogleMlKit.vision.textRecognizer();
  final ImagePicker _imagePicker = ImagePicker();

  Future<String> scanDocument() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.camera,
    );

    if (image == null) return '';

    final inputImage = InputImage.fromFilePath(image.path);
    final recognizedText = await _textRecognizer.processImage(inputImage);

    return recognizedText.text;
  }

  Future<Document> processLeaseAgreement(String scannedText) async {
    // Extract key information from lease
    final rentAmount = _extractRentAmount(scannedText);
    final dueDate = _extractDueDate(scannedText);
    final landlordInfo = _extractLandlordInfo(scannedText);

    return Document(
      type: DocumentType.lease,
      content: scannedText,
      metadata: {
        'rentAmount': rentAmount,
        'dueDate': dueDate,
        'landlord': landlordInfo,
      },
    );
  }

  double _extractRentAmount(String text) {
    // ML-based rent amount extraction
    final rentRegex = RegExp(r'\$([0-9,]+(?:\.[0-9]{2})?)');
    final matches = rentRegex.allMatches(text);
    return double.parse(matches.first.group(1)!.replaceAll(',', ''));
  }
}
```

---

## 🏠 **PHASE 5: DASHBOARD & NAVIGATION (WEEK 2)**

### **Step 9: Create Main Dashboard**
```dart
// lib/presentation/screens/dashboard/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finwise_ui/finwise_ui.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RentWise'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRentStatusCard(),
            const SizedBox(height: 16),
            _buildQuickActions(),
            const SizedBox(height: 16),
            _buildRecentActivity(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showQuickActions(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildRentStatusCard() {
    return FinWiseCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Next Rent Due',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              '\$1,200.00',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Due in 5 days'),
            const SizedBox(height: 16),
            FinWiseButton.primary(
              text: 'Pay Rent',
              onPressed: () => Navigator.pushNamed(context, '/payments'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildActionCard(
              'Contact Landlord',
              Icons.message,
              () => Navigator.pushNamed(context, '/communication'),
            ),
            const SizedBox(width: 12),
            _buildActionCard(
              'Maintenance',
              Icons.build,
              () => Navigator.pushNamed(context, '/maintenance'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, VoidCallback onTap) {
    return Expanded(
      child: FinWiseCard(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 32, color: Theme.of(context).primaryColor),
              const SizedBox(height: 8),
              Text(title, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        FinWiseCard(
          child: Column(
            children: [
              _buildActivityItem(
                'Rent payment processed',
                '\$1,200.00',
                '2 days ago',
              ),
              const Divider(),
              _buildActivityItem(
                'Lease agreement uploaded',
                'Springfield Apartments',
                '1 week ago',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(String title, String subtitle, String time) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Text(
        time,
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      ),
    );
  }

  void _showQuickActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.payment),
              title: const Text('Pay Rent'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/payments');
              },
            ),
            ListTile(
              leading: const Icon(Icons.document_scanner),
              title: const Text('Scan Document'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/documents/scan');
              },
            ),
            ListTile(
              leading: const Icon(Icons.build),
              title: const Text('Report Maintenance'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/maintenance/new');
              },
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 🚀 **PHASE 6: TESTING & POLISH (WEEK 3)**

### **Step 10: Run and Test**
```bash
# Install dependencies
flutter pub get

# Run the app
flutter run

# Run tests
flutter test

# Build for testing
flutter build apk --debug
flutter build ios --debug
```

### **Step 11: Beta Testing Setup**
```bash
# For Android (Google Play Beta)
flutter build appbundle --release

# For iOS (TestFlight)
flutter build ios --release
```

---

## 🎯 **SUCCESS CHECKLIST**

### **Week 1 Completion**
- ✅ Monorepo migration completed
- ✅ RentWise app structure created
- ✅ Payment processing implemented
- ✅ Basic UI components working

### **Week 2 Completion**
- ✅ Document scanning functional
- ✅ Dashboard with key metrics
- ✅ Navigation between screens
- ✅ Basic offline functionality

### **Week 3 Completion**
- ✅ All core features implemented
- ✅ Comprehensive testing completed
- ✅ Beta testing ready
- ✅ App store submission prepared

---

## 🔧 **DEVELOPMENT COMMANDS**

```bash
# Development workflow
cd apps/rentwise

# Get dependencies
flutter pub get

# Run with hot reload
flutter run

# Run tests
flutter test

# Analyze code
flutter analyze

# Format code
flutter format .

# Build for testing
flutter build apk --debug
flutter build ios --debug

# Build for release
flutter build appbundle --release
flutter build ios --release
```

---

## 📊 **PROGRESS TRACKING**

### **Daily Standup Questions**
- What features were completed yesterday?
- What challenges were encountered?
- What will be worked on today?
- Any blockers or help needed?

### **Weekly Milestones**
- **Week 1**: Payment system and basic UI
- **Week 2**: Document management and dashboard
- **Week 3**: Testing, polish, and beta launch

---

## 🚀 **READY TO BUILD?**

**You now have everything needed to start building RentWise!**

The foundation is set, the architecture is defined, and the development path is clear. With the monorepo infrastructure and shared components, you can focus on building great rental management features.

**Start with the monorepo migration, then dive into the payment system. The rest will follow naturally! 🏠💳**

**Questions? Need clarification on any step? Let's build RentWise! 🚀**
