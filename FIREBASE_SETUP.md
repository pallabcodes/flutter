# Firebase Setup Instructions

## Quick Setup (5 minutes)

### 1. Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Enter project name: `finwise` (or your preferred name)
4. Disable Google Analytics (optional) or enable it
5. Click "Create project"

### 2. Add Android App

1. In Firebase Console, click the Android icon
2. Register app:
   - **Android package name**: `com.finwise`
   - **App nickname** (optional): `FinWise Android`
   - **Debug signing certificate SHA-1** (optional for now)
3. Click "Register app"
4. Download `google-services.json`
5. Place it in: `android/app/google-services.json`

### 3. Configure Android Build

The `google-services.json` file is already configured to be included in the build. Make sure it's in the correct location:

```
android/app/google-services.json
```

### 4. Enable Firebase Services (Optional)

If you want to use specific Firebase features:

- **Firebase Authentication**: Enable in Firebase Console → Authentication → Get Started
- **Firebase Analytics**: Already enabled by default
- **Firebase Crashlytics**: Enable in Firebase Console → Crashlytics → Get Started

### 5. Uncomment Firebase Initialization

In `lib/main.dart`, uncomment the Firebase initialization:

```dart
// Initialize Firebase (optional - app can run without it)
try {
  await Firebase.initializeApp();
  // Configure Crashlytics for error reporting
  await _configureCrashlytics();
} catch (e) {
  debugPrint('Firebase initialization failed: $e');
  debugPrint('App will continue without Firebase features');
}
```

### 6. Test

Run the app:
```bash
fvm flutter run -d emulator-5554
```

The app should now connect to Firebase without errors.

## Troubleshooting

### Error: "Failed to load FirebaseOptions from resource

- Make sure `google-services.json` is in `android/app/` directory
- Check that the package name in `google-services.json` matches `com.finwise`
- Clean and rebuild: `fvm flutter clean && fvm flutter pub get`

### Error: "No Firebase App '[DEFAULT]' has been created"

- Make sure you uncommented the Firebase initialization in `main.dart`
- Verify `google-services.json` is correctly placed

### App works without Firebase

The app is designed to work without Firebase. If you don't need Firebase features, you can leave it disabled. The app will use stub implementations for authentication and analytics.

## Current Status

✅ **App works without Firebase** - All Firebase dependencies are optional
✅ **Firebase ready** - Just add `google-services.json` and uncomment initialization
✅ **No breaking changes** - App continues to function if Firebase fails

