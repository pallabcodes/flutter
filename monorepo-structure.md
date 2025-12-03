# 📁 FinWise Monorepo Structure

## Overview
This monorepo contains multiple Flutter applications and shared packages, all benefiting from unified tooling, CI/CD, and infrastructure.

## Directory Structure

```
finwise-monorepo/
├── 📱 apps/                          # Individual Flutter applications
│   ├── finwise/                      # Main expense manager app ✅
│   ├── budget-planner/               # Budget planning app
│   ├── investment-tracker/           # Investment tracking app
│   └── habit-tracker/                # Habit tracking app
│
├── 📦 packages/                      # Shared packages and libraries
│   ├── core/                         # Core business logic & utilities
│   │   ├── lib/
│   │   │   ├── config/               # Environment configs
│   │   │   ├── errors/               # Error handling
│   │   │   ├── monitoring/           # Analytics & monitoring
│   │   │   ├── network/              # API clients
│   │   │   ├── security/             # Encryption & security
│   │   │   ├── state/                # State persistence
│   │   │   └── sync/                 # Data synchronization
│   │   └── pubspec.yaml
│   │
│   ├── ui/                           # Shared UI components
│   │   ├── lib/
│   │   │   ├── components/           # Reusable widgets
│   │   │   ├── themes/               # Design systems
│   │   │   ├── animations/           # Shared animations
│   │   │   └── icons/                # Custom icon sets
│   │   └── pubspec.yaml
│   │
│   ├── features/                     # Feature-specific packages
│   │   ├── auth/                     # Authentication features
│   │   ├── payments/                 # Payment integrations
│   │   ├── notifications/            # Push notifications
│   │   └── analytics/                # Analytics tracking
│   │
│   └── tools/                        # Development tools
│       ├── build/                    # Build automation
│       ├── test/                     # Testing utilities
│       └── deploy/                   # Deployment scripts
│
├── 🛠️  tools/                        # Global development tools
│   ├── build.dart                    # Unified build system
│   ├── release.dart                  # Release management
│   ├── security_scan.dart            # Security scanning
│   ├── performance_test.dart         # Performance testing
│   ├── monitoring_dashboard.dart     # Health monitoring
│   └── beta_setup.dart               # Beta testing setup
│
├── 📊 monitoring/                    # Centralized monitoring
│   ├── dashboards/                   # Grafana dashboards
│   ├── alerts/                       # Alert configurations
│   └── reports/                      # Generated reports
│
├── 🚀 deployment/                    # Deployment configurations
│   ├── ci/                           # CI/CD pipelines
│   ├── docker/                       # Container configurations
│   ├── kubernetes/                   # K8s manifests
│   └── scripts/                      # Deployment scripts
│
├── 📚 docs/                          # Documentation
│   ├── apps/                         # App-specific docs
│   ├── packages/                     # Package documentation
│   ├── deployment/                   # Deployment guides
│   └── development/                  # Development guides
│
└── 🔧 config/                        # Global configuration
    ├── environments/                 # Environment configs
    ├── secrets/                      # Secret management
    └── tooling/                      # Tool configurations
```

## App Structure (Each App)

```
apps/[app-name]/
├── 📱 lib/
│   ├── core/                         # App-specific core logic
│   ├── features/                     # Feature modules
│   ├── presentation/                 # UI layer (Riverpod)
│   ├── data/                         # Data layer
│   └── domain/                       # Domain layer
├── 🧪 test/                          # Unit and widget tests
├── integration_test/                 # Integration tests
├── 📱 android/                       # Android configuration
├── 🍎 ios/                           # iOS configuration
├── 🌐 web/                           # Web configuration
├── 📦 pubspec.yaml                   # Dependencies
└── 🛠️ fastlane/                     # Fastlane configuration
```

## Shared Package Benefits

### 🔄 Core Package (`packages/core/`)
- **State Management**: Riverpod providers, persistence, sync
- **Error Handling**: Boundaries, logging, crash reporting
- **Security**: Encryption, secure storage, certificate pinning
- **Monitoring**: Analytics, performance tracking
- **Network**: HTTP clients, interceptors, caching

### 🎨 UI Package (`packages/ui/`)
- **Design System**: Colors, typography, spacing
- **Components**: Buttons, cards, forms, charts
- **Animations**: Transitions, micro-interactions
- **Icons**: Custom icon sets, SVG support

### 🔧 Feature Packages
- **Auth**: Login, signup, biometric, social auth
- **Payments**: Stripe, PayPal, Apple/Google Pay
- **Notifications**: Local, push, in-app notifications
- **Analytics**: Firebase, Mixpanel, custom events

## Development Workflow

### 1. Creating a New App
```bash
# Create new app directory
mkdir apps/new-app
cd apps/new-app

# Initialize Flutter app
flutter create . --project-name new-app

# Add shared dependencies
flutter pub add \
  finwise_core \
  finwise_ui \
  finwise_auth \
  finwise_analytics
```

### 2. Using Shared Packages
```yaml
# pubspec.yaml
dependencies:
  finwise_core:
    path: ../../packages/core
  finwise_ui:
    path: ../../packages/ui
  finwise_auth:
    path: ../../packages/features/auth
```

### 3. Running Apps
```bash
# Run specific app
cd apps/finwise
flutter run

# Run with shared packages
cd apps/finwise
flutter pub run build_runner build  # Generate shared code
flutter run
```

### 4. Testing Across Apps
```bash
# Test all apps and packages
dart tool/build.dart test all

# Test specific app
cd apps/finwise
flutter test
```

### 5. Building for Deployment
```bash
# Build all apps
dart tool/build.dart all production

# Build specific app
cd apps/finwise
dart tool/build.dart build android production
```

## CI/CD Integration

### GitHub Actions Workflow
```yaml
name: Monorepo CI/CD

on:
  push:
    branches: [ main, develop ]
  pull_request:
    paths:
      - 'apps/**'
      - 'packages/**'

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        app: [finwise, budget-planner, investment-tracker]
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.19.0'

      - name: Test ${{ matrix.app }}
        run: |
          cd apps/${{ matrix.app }}
          flutter pub get
          flutter test

  build:
    needs: test
    runs-on: ubuntu-latest
    strategy:
      matrix:
        app: [finwise, budget-planner, investment-tracker]
        platform: [android, ios, web]
    steps:
      - uses: actions/checkout@v4
      - name: Build ${{ matrix.app }} for ${{ matrix.platform }}
        run: |
          cd apps/${{ matrix.app }}
          dart ../../tool/build.dart build ${{ matrix.platform }} production
```

## Advantages of This Structure

### ✅ Code Reuse
- Shared authentication across all apps
- Consistent UI components and design system
- Common business logic and utilities
- Unified error handling and monitoring

### ✅ Consistent Tooling
- Same build scripts for all apps
- Unified testing and quality gates
- Consistent deployment processes
- Shared CI/CD infrastructure

### ✅ Easier Maintenance
- Single source of truth for shared code
- Atomic changes across related apps
- Easier refactoring and updates
- Consistent dependency management

### ✅ Team Collaboration
- Easier code reviews across apps
- Shared knowledge and best practices
- Consistent architecture patterns
- Unified release management

## Migration Strategy

### Phase 1: Restructure Current Repo
```
finwise-monorepo/
├── apps/
│   └── finwise/          # Move current app here
├── packages/
│   ├── core/            # Extract shared logic
│   └── ui/              # Extract UI components
└── tools/               # Global tooling
```

### Phase 2: Create Shared Packages
1. Extract common code from FinWise
2. Create `finwise_core` and `finwise_ui` packages
3. Update FinWise to use shared packages

### Phase 3: Add New Apps
1. Create new app structure
2. Use shared packages
3. Inherit tooling and infrastructure

### Phase 4: Enhance Shared Infrastructure
1. Add more shared packages as needed
2. Improve monorepo tooling
3. Optimize build and test processes

## Decision Factors

Choose **Monorepo** if you have:
- Related apps with shared functionality
- Small to medium team size
- Need for consistent tooling and processes
- Frequent cross-app changes
- Shared design system and components

Choose **Separate Repos** if you have:
- Completely unrelated apps
- Large distributed teams
- Different tech stacks or architectures
- Independent release cycles
- Strict isolation requirements
