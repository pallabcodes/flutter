# FinWise Distribution Guide

This directory contains all the configuration and assets needed for distributing FinWise across different platforms and app stores.

## Directory Structure

```
distribution/
├── android/              # Android-specific distribution files
│   ├── play-store/       # Google Play Store configuration
│   └── whatsnew/         # Release notes for Play Store
├── ios/                  # iOS-specific distribution files
│   ├── app-store/        # Apple App Store configuration
│   └── testflight/       # TestFlight configuration
├── web/                  # Web deployment configuration
├── scripts/              # Deployment automation scripts
└── metadata/             # App metadata and screenshots
```

## Platform-Specific Setup

### Android (Google Play Store)

#### Prerequisites
- Google Play Developer account
- Google Play service account JSON key
- Signed APK/AAB files

#### Configuration Files
- `android/play-store/service-account.json` - Google Play API credentials
- `android/play-store/listing/` - Store listing assets
- `android/whatsnew/` - Release notes by language

#### Deployment Script
```bash
# Build and deploy Android
dart tool/build.dart build android production
dart distribution/scripts/deploy_android.dart
```

### iOS (App Store)

#### Prerequisites
- Apple Developer Program account
- Distribution certificate and provisioning profiles
- App Store Connect API key

#### Configuration Files
- `ios/app-store/api-key.json` - App Store Connect API credentials
- `ios/app-store/metadata/` - App Store metadata
- `ios/testflight/tester-groups.json` - TestFlight tester configuration

#### Deployment Script
```bash
# Build and deploy iOS
dart tool/build.dart build ios production
dart distribution/scripts/deploy_ios.dart
```

### Web (PWA)

#### Prerequisites
- AWS S3 bucket or similar hosting
- CloudFront distribution (optional)
- Custom domain

#### Configuration Files
- `web/deploy-config.json` - Deployment configuration
- `web/CNAME` - Custom domain configuration

#### Deployment Script
```bash
# Build and deploy web
dart tool/build.dart build web production
dart distribution/scripts/deploy_web.dart
```

## Release Process

### 1. Pre-Release Checklist

- [ ] All tests passing (`flutter test --coverage`)
- [ ] Static analysis clean (`flutter analyze`)
- [ ] Build successful for all platforms
- [ ] Screenshots updated in `metadata/screenshots/`
- [ ] Release notes written in `whatsnew/`
- [ ] Version bumped in `pubspec.yaml`

### 2. Version Management

Update version in multiple places:
- `pubspec.yaml`
- `android/app/build.gradle`
- `ios/Runner.xcodeproj/project.pbxproj`
- `lib/core/config/app_config.dart`

### 3. Build Artifacts

Generate build artifacts for each platform:

```bash
# Android
flutter build appbundle --release

# iOS
flutter build ipa --release --export-options-plist=ios/exportOptions.plist

# Web
flutter build web --release
```

### 4. Store Submissions

#### Google Play Store
1. Upload AAB to Google Play Console
2. Update store listing if needed
3. Set release notes and rollout percentage
4. Publish to production

#### App Store Connect
1. Upload IPA using Transporter or Xcode
2. Fill out app information and screenshots
3. Submit for review
4. Monitor review process

#### Web Deployment
1. Upload build files to hosting service
2. Update DNS if needed
3. Test PWA functionality
4. Update service worker cache

### 5. Post-Release Tasks

- [ ] Update changelog
- [ ] Notify beta testers
- [ ] Monitor crash reports
- [ ] Update documentation
- [ ] Plan next release

## Environment Configuration

### Development
- Debug builds with logging enabled
- Mock data for testing
- Development Firebase project

### Staging
- Release builds with staging configuration
- TestFlight and Play Store beta
- Staging Firebase project

### Production
- Optimized release builds
- Production Firebase project
- Full analytics and crash reporting

## Security Considerations

### API Keys and Secrets
- Never commit secrets to version control
- Use GitHub Secrets for CI/CD
- Rotate keys regularly
- Use environment-specific keys

### Code Signing
- Secure private keys and certificates
- Use HSM for key storage if possible
- Regular certificate renewal
- Separate keys for different environments

### Data Privacy
- GDPR and CCPA compliance
- Minimal data collection
- Secure data transmission
- Regular security audits

## Monitoring and Analytics

### Crash Reporting
- Firebase Crashlytics for all platforms
- Real-time crash monitoring
- Version-specific crash analysis
- Automated alerts for critical issues

### Performance Monitoring
- Firebase Performance Monitoring
- App startup time tracking
- Network request monitoring
- Custom performance metrics

### User Analytics
- Firebase Analytics integration
- User engagement tracking
- Feature usage analytics
- Conversion funnel analysis

## Rollback Procedures

### Android Rollback
1. Open Google Play Console
2. Go to Release > Production
3. Create new release with previous version
4. Roll back to previous version

### iOS Rollback
1. Submit new version with previous code
2. Expedited review request if critical
3. Monitor app review process

### Web Rollback
1. Deploy previous build to hosting
2. Update CDN cache settings
3. Verify rollback successful
4. Notify users if needed

## Troubleshooting

### Common Issues

**Android Build Failures**
- Check keystore configuration
- Verify signing certificate validity
- Ensure minSdkVersion compatibility

**iOS Build Failures**
- Verify provisioning profiles
- Check code signing certificates
- Ensure bundle ID consistency

**Web Deployment Issues**
- Check hosting service quotas
- Verify DNS configuration
- Test service worker cache

### Support Resources

- [Flutter Deployment Documentation](https://docs.flutter.dev/deployment)
- [Google Play Console Help](https://support.google.com/googleplay)
- [App Store Connect Help](https://developer.apple.com/support/app-store-connect/)
- [Firebase Documentation](https://firebase.google.com/docs)

## Contact

For deployment issues or questions:
- Create GitHub issue with `deployment` label
- Contact DevOps team
- Check deployment runbooks in `docs/` directory
