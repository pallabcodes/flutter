# OAuth Setup Guide: Google & Facebook Login

This guide provides step-by-step instructions for configuring Google and Facebook OAuth authentication with Firebase in your FinWise Flutter app.

## 🔐 Firebase Authentication Setup

### 1. Enable Authentication Providers

1. Go to the [Firebase Console](https://console.firebase.google.com/)
2. Select your project (FinWise)
3. Navigate to **Authentication** > **Sign-in method**
4. Enable the following providers:

#### Google Sign-In
- Click **Google** in the provider list
- Click **Enable**
- Add your project support email
- Click **Save**

#### Facebook Login
- Click **Facebook** in the provider list
- Click **Enable**
- You'll need Facebook App ID and App Secret (see Facebook setup below)
- Click **Save**

## 📱 Google OAuth Setup

### Android Configuration

1. **Get SHA-1 fingerprint** (required for Google Sign-In):
```bash
# For debug keystore
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# For release keystore (replace with your keystore path)
keytool -list -v -keystore /path/to/your/keystore.jks -alias your_key_alias
```

2. **Configure Google Cloud Console**:
   - Go to [Google Cloud Console](https://console.cloud.google.com/)
   - Select your project or create a new one
   - Enable Google+ API and Google Sign-In API
   - Create OAuth 2.0 credentials:
     - Go to **APIs & Credentials** > **Credentials**
     - Click **Create Credentials** > **OAuth client ID**
     - Choose **Android** application
     - Enter your package name: `com.finwise.app`
     - Enter SHA-1 fingerprint from step 1
     - Click **Create**

3. **Update Android configuration**:
   - Open `android/app/build.gradle`
   - Update defaultConfig with your SHA fingerprint:

```gradle
android {
    defaultConfig {
        // ...
        manifestPlaceholders += [
            'appAuthRedirectScheme': 'com.googleusercontent.apps.YOUR_CLIENT_ID'
        ]
    }
}
```

4. **Add Google Services plugin**:
   - Ensure `google-services.json` is in `android/app/`
   - The file should contain your OAuth client configuration

### iOS Configuration

1. **Configure Google Sign-In for iOS**:
   - Open `ios/Runner.xcworkspace` in Xcode
   - Add URL schemes:
     - Go to **Runner** > **Targets** > **Runner**
     - **Info** tab > **URL Types**
     - Add URL scheme: `com.googleusercontent.apps.YOUR_CLIENT_ID`

2. **Update iOS configuration**:
   - Open `ios/Runner/Info.plist`
   - Add the following:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
        </array>
    </dict>
</array>

<key>LSApplicationQueriesSchemes</key>
<array>
    <string>googlegmail</string>
    <string>com-google-gmail</string>
</array>
```

## 📘 Facebook OAuth Setup

### 1. Create Facebook App

1. Go to [Facebook Developers](https://developers.facebook.com/)
2. Click **My Apps** > **Create App**
3. Choose **Consumer** app type
4. Enter app name: "FinWise"
5. Click **Create App**

### 2. Configure Facebook Login

1. In your Facebook App dashboard:
   - Go to **Add Product** > **Facebook Login**
   - Click **Set Up**

2. **Configure OAuth redirect URIs**:
   - Go to **Facebook Login** > **Settings**
   - Add Valid OAuth Redirect URIs:
     ```
     https://your-project.firebaseapp.com/__/auth/handler
     ```

3. **Get App ID and App Secret**:
   - Go to **Settings** > **Basic**
   - Copy **App ID** and **App Secret**

### 3. Configure Firebase with Facebook

1. Back in Firebase Console:
   - **Authentication** > **Sign-in method** > **Facebook**
   - Paste your **App ID** and **App Secret**
   - Click **Save**

### Android Facebook Configuration

1. **Update AndroidManifest.xml**:
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Add Facebook App ID -->
    <meta-data android:name="com.facebook.sdk.ApplicationId" android:value="@string/facebook_app_id"/>
    <meta-data android:name="com.facebook.sdk.ClientToken" android:value="@string/facebook_client_token"/>

    <application>
        <!-- Facebook Activity -->
        <activity android:name="com.facebook.FacebookActivity"
            android:configChanges="keyboard|keyboardHidden|screenLayout|screenSize|orientation"
            android:label="@string/app_name" />

        <!-- Facebook Content Provider -->
        <provider android:name="com.facebook.FacebookContentProvider"
            android:authorities="com.facebook.app.FacebookContentProvider{YOUR_APP_ID}"
            android:exported="true" />
    </application>
</manifest>
```

2. **Create strings.xml**:
```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="facebook_app_id">YOUR_FACEBOOK_APP_ID</string>
    <string name="facebook_client_token">YOUR_FACEBOOK_CLIENT_TOKEN</string>
</resources>
```

### iOS Facebook Configuration

1. **Update Info.plist**:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Add Facebook App ID -->
    <key>FacebookAppID</key>
    <string>YOUR_FACEBOOK_APP_ID</string>
    <key>FacebookClientToken</key>
    <string>YOUR_FACEBOOK_CLIENT_TOKEN</string>
    <key>FacebookDisplayName</key>
    <string>FinWise</string>

    <!-- Facebook URL schemes -->
    <key>CFBundleURLTypes</key>
    <array>
        <dict>
            <key>CFBundleURLSchemes</key>
            <array>
                <string>fbYOUR_FACEBOOK_APP_ID</string>
            </array>
        </dict>
    </array>

    <!-- Facebook query schemes -->
    <key>LSApplicationQueriesSchemes</key>
    <array>
        <string>fbapi</string>
        <string>fb-messenger-share-api</string>
        <string>fbauth2</string>
        <string>fbshareextension</string>
    </array>
</dict>
</plist>
```

2. **Update AppDelegate.swift** (if using Swift):
```swift
import UIKit
import FBSDKCoreKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        ApplicationDelegate.shared.application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )
        return true
    }

    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        ApplicationDelegate.shared.application(
            app,
            open: url,
            sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
            annotation: options[UIApplication.OpenURLOptionsKey.annotation]
        )
    }
}
```

## 🔧 Environment Configuration

### 1. Create OAuth Configuration Class

Create `lib/core/config/oauth_config.dart`:

```dart
class OAuthConfig {
  static const String googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue: 'your_google_client_id',
  );

  static const String facebookAppId = String.fromEnvironment(
    'FACEBOOK_APP_ID',
    defaultValue: 'your_facebook_app_id',
  );

  static const String facebookClientToken = String.fromEnvironment(
    'FACEBOOK_CLIENT_TOKEN',
    defaultValue: 'your_facebook_client_token',
  );
}
```

### 2. Update Build Configurations

#### Android (android/app/build.gradle):
```gradle
android {
    defaultConfig {
        // Add OAuth environment variables
        manifestPlaceholders += [
            'facebookAppId': OAuthConfig.facebookAppId,
            'facebookClientToken': OAuthConfig.facebookClientToken,
        ]
    }
}
```

#### iOS (ios/Runner/Info.plist):
Update with environment variables from OAuthConfig.

### 3. Flutter Build Commands

```bash
# Development
flutter build apk --dart-define=GOOGLE_CLIENT_ID=your_google_client_id --dart-define=FACEBOOK_APP_ID=your_facebook_app_id

# Production
flutter build appbundle --dart-define=GOOGLE_CLIENT_ID=your_prod_google_client_id --dart-define=FACEBOOK_APP_ID=your_prod_facebook_app_id
```

## 🧪 Testing OAuth Integration

### 1. Test Google Sign-In

```dart
// Test in debug console
final googleSignIn = GoogleSignIn();
final account = await googleSignIn.signIn();
print('Signed in: ${account?.displayName}');
```

### 2. Test Facebook Sign-In

```dart
// Test in debug console
final result = await FacebookAuth.instance.login();
print('Login status: ${result.status}');
if (result.status == LoginStatus.success) {
    print('Access token: ${result.accessToken?.token}');
}
```

### 3. Test Firebase Authentication

```dart
// Test Firebase auth state
FirebaseAuth.instance.authStateChanges().listen((user) {
    print('Auth state changed: ${user?.email}');
});
```

## 🔒 Security Best Practices

### 1. OAuth Redirect URIs
- Only whitelist necessary redirect URIs in Firebase and OAuth providers
- Use HTTPS in production
- Regularly rotate OAuth client secrets

### 2. Token Management
- Never store OAuth tokens in plain text
- Use secure storage for refresh tokens
- Implement token refresh logic

### 3. Error Handling
- Handle network failures gracefully
- Provide user-friendly error messages
- Log authentication failures for security monitoring

### 4. Privacy Compliance
- Obtain explicit user consent for data collection
- Implement GDPR-compliant data deletion
- Provide clear privacy policy links

## 🚀 Deployment Checklist

- [ ] Google OAuth client configured for Android
- [ ] Google OAuth client configured for iOS
- [ ] Facebook App created and configured
- [ ] Firebase Authentication providers enabled
- [ ] Android SHA fingerprints configured
- [ ] iOS URL schemes configured
- [ ] Environment variables set for production builds
- [ ] OAuth redirect URIs whitelisted
- [ ] Privacy policy and terms updated
- [ ] Error handling tested
- [ ] Token refresh logic implemented

## 🐛 Troubleshooting

### Common Issues

1. **Google Sign-In fails on Android**:
   - Check SHA-1 fingerprint matches Google Cloud Console
   - Ensure `google-services.json` is correctly placed

2. **Facebook login fails**:
   - Verify Facebook App ID and Client Token
   - Check if Facebook app is in Live mode (not Development)

3. **iOS OAuth redirects fail**:
   - Ensure URL schemes are correctly configured in Info.plist
   - Check if associated domains are set up

4. **Firebase auth errors**:
   - Verify OAuth providers are enabled in Firebase Console
   - Check if redirect URIs match Firebase configuration

### Debug Commands

```bash
# Check Android signing config
keytool -list -v -keystore ~/.android/debug.keystore

# Test Facebook SDK
flutter run --dart-define=DEBUG_FACEBOOK=true

# Check Firebase auth state
FirebaseAuth.instance.currentUser
```

## 📞 Support

For additional help:
- [Firebase Documentation](https://firebase.google.com/docs/auth)
- [Google Sign-In Setup](https://developers.google.com/identity/sign-in/android/start)
- [Facebook Login Setup](https://developers.facebook.com/docs/facebook-login/)
- [Flutter OAuth Packages](https://pub.dev/packages?q=oauth)
