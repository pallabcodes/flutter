# FinWise (Flutter)

Smart expense management app with optional Firebase. Uses FVM to pin the Flutter SDK.

## Prerequisites
- Flutter via FVM (`fvm use 3.32.1`)
- Android SDK/NDK; set `compileSdk = 36` in `android/app/build.gradle.kts` for camera plugin warning
- Dart/Flutter tools on PATH (`fvm flutter` …)

## Setup
```bash
fvm flutter pub get
```

### Run
```bash
fvm flutter run -d emulator-5554
# or web/macos if preferred
```

### Build APK
```bash
fvm flutter build apk --debug --target-platform android-arm64
```

## Firebase (optional)
The app runs without Firebase (stub auth/analytics). To enable:
1) Create a Firebase project and Android app with package name `com.finwise`.
2) Download `google-services.json` and place it at `android/app/google-services.json`.
3) Uncomment Firebase initialization in `lib/main.dart` (look for the commented block around `Firebase.initializeApp()`).
4) Re-run:
```bash
fvm flutter clean
fvm flutter pub get
fvm flutter run -d emulator-5554
```

If Firebase is missing, you will see “Firebase dependencies not available” in logs; the app will still work using stub auth and disabled analytics/crashlytics.

## Demo / Anonymous mode
- On the login screen tap “Try Demo (Anonymous)” to enter the app without credentials (uses stub auth when Firebase is absent).

## Debugging tips
- **compileSdk warning**: set `compileSdk = 36` in `android/app/build.gradle.kts`.
- **Directionality/overlay issues**: monitoring overlays are disabled by default; main app runs without them.
- **Drift multiple database warning**: we use a single GetIt-registered `AppDatabase`; app_startup uses the same instance.
- Logs: `fvm flutter run -d emulator-5554 -v` or `adb logcat`.
- Hot reload: press `r`; hot restart: `R` in the `flutter run` console.

## Tooling
- SDK pinned via `.fvmrc` (`3.32.1`).
- Commands should be prefixed with `fvm flutter ...` to ensure the correct SDK is used.
