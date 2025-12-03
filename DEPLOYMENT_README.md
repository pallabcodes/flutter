# 🚀 FinWise Deployment Guide

This guide covers the complete deployment setup for the FinWise app across iOS, Android, and Web platforms.

## 📋 Prerequisites

### General Requirements
- Flutter 3.19.0 or later
- Dart 3.3.0 or later
- GitHub account with repository access
- Slack webhook for notifications (optional)

### Platform-Specific Requirements

#### iOS Deployment
- macOS with Xcode 15.2+
- Apple Developer Program membership
- App Store Connect access
- Distribution certificate and provisioning profile

#### Android Deployment
- Android Studio Arctic Fox or later
- Google Play Console access
- Upload keystore for signing
- Google Service Account for Play Store API

#### Web Deployment
- AWS CLI configured
- S3 bucket for static hosting
- CloudFront distribution (optional)
- SSL certificate (for HTTPS)

---

## 🔧 Environment Setup

### 1. Clone Repository
```bash
git clone https://github.com/your-org/finwise.git
cd finwise
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Setup Environment Variables
Create `.env` files for different environments:

#### Development (.env.development)
```bash
# API Configuration
API_BASE_URL=https://api-dev.finwise.app
WS_BASE_URL=wss://ws-dev.finwise.app

# Firebase
FIREBASE_PROJECT_ID=finwise-dev
FIREBASE_API_KEY=your_dev_api_key

# Feature Flags
ENABLE_ANALYTICS=false
ENABLE_CRASH_REPORTING=false
ENABLE_OFFLINE_MODE=true
ENABLE_RECEIPT_SCANNING=true
```

#### Staging (.env.staging)
```bash
# API Configuration
API_BASE_URL=https://api-staging.finwise.app
WS_BASE_URL=wss://ws-staging.finwise.app

# Firebase
FIREBASE_PROJECT_ID=finwise-staging
FIREBASE_API_KEY=your_staging_api_key

# Feature Flags
ENABLE_ANALYTICS=true
ENABLE_CRASH_REPORTING=true
ENABLE_OFFLINE_MODE=true
ENABLE_RECEIPT_SCANNING=true
```

#### Production (.env.production)
```bash
# API Configuration
API_BASE_URL=https://api.finwise.app
WS_BASE_URL=wss://ws.finwise.app

# Firebase
FIREBASE_PROJECT_ID=finwise-prod
FIREBASE_API_KEY=your_prod_api_key

# Feature Flags
ENABLE_ANALYTICS=true
ENABLE_CRASH_REPORTING=true
ENABLE_OFFLINE_MODE=true
ENABLE_RECEIPT_SCANNING=true
```

---

## 🔐 Secrets Configuration

### GitHub Secrets Setup

Navigate to your repository Settings > Secrets and variables > Actions and add:

#### Required Secrets
```bash
# iOS Secrets
APP_STORE_USERNAME=your_app_store_email@example.com
APP_STORE_PASSWORD=your_app_specific_password
IOS_TEAM_ID=your_team_id
IOS_DISTRIBUTION_CERTIFICATE=base64_encoded_certificate
IOS_CERTIFICATE_PASSWORD=your_certificate_password
IOS_PROVISIONING_PROFILE=base64_encoded_profile

# Android Secrets
ANDROID_KEYSTORE_PATH=android/app/upload-keystore.jks
ANDROID_KEYSTORE_PASSWORD=your_keystore_password
ANDROID_KEY_ALIAS=your_key_alias
ANDROID_KEY_PASSWORD=your_key_password
GOOGLE_SERVICE_ACCOUNT_KEY=base64_encoded_service_account_json

# AWS Secrets (for web deployment)
AWS_ACCESS_KEY_ID=your_aws_access_key
AWS_SECRET_ACCESS_KEY=your_aws_secret_key
AWS_REGION=us-east-1
PROD_WEB_BUCKET_NAME=finwise-prod-web
STAGING_WEB_BUCKET_NAME=finwise-staging-web
PROD_CLOUDFRONT_DISTRIBUTION_ID=your_prod_distribution_id
STAGING_CLOUDFRONT_DISTRIBUTION_ID=your_staging_distribution_id

# Notification Secrets
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/...
APP_STORE_APP_ID=your_app_store_app_id

# Release Notes
RELEASE_NOTES=Version 1.0.0 - Production release
```

### Local Development Setup

#### iOS Setup
1. **Install Dependencies**
   ```bash
   sudo gem install bundler
   bundle install
   ```

2. **Setup Certificates**
   ```bash
   # Export your distribution certificate
   security export -k ~/Library/Keychains/login.keychain-db -t identities -f pkcs12 -o certificate.p12

   # Convert to base64 for GitHub secrets
   base64 certificate.p12
   ```

3. **Setup Provisioning Profile**
   ```bash
   # Download provisioning profile from Apple Developer Console
   # Convert to base64
   base64 FinWise_Provisioning_Profile.mobileprovision
   ```

#### Android Setup
1. **Create Upload Keystore**
   ```bash
   keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

2. **Setup Google Service Account**
   ```bash
   # Create service account in Google Cloud Console
   # Download JSON key and base64 encode it
   base64 finwise-play-store-service-account.json
   ```

#### Web Setup
1. **Configure AWS CLI**
   ```bash
   aws configure
   ```

2. **Create S3 Buckets**
   ```bash
   aws s3 mb s3://finwise-prod-web --region us-east-1
   aws s3 mb s3://finwise-staging-web --region us-east-1
   ```

3. **Setup CloudFront (Optional)**
   ```bash
   # Create distributions for prod and staging
   aws cloudfront create-distribution --distribution-config file://distribution/web/cloudfront-config.json
   ```

---

## 📱 Platform-Specific Deployment

### iOS Deployment

#### 1. App Store Connect Setup
1. Create app in App Store Connect
2. Set up TestFlight
3. Configure app information and screenshots

#### 2. Certificate Setup
- Create Distribution Certificate in Apple Developer Console
- Create App Store Distribution Provisioning Profile
- Add devices for TestFlight testing

#### 3. Deployment Workflow
The iOS deployment is handled by `.github/workflows/deploy-ios.yml`:

**TestFlight Deployment:**
```bash
# Manual trigger via GitHub Actions
# Go to Actions tab → Deploy iOS → Run workflow
# Select destination: testflight
```

**App Store Deployment:**
```bash
# Manual trigger via GitHub Actions
# Go to Actions tab → Deploy iOS → Run workflow
# Select destination: appstore
```

#### 4. Build Scripts
- `distribution/scripts/deploy_ios.dart` - Main deployment script
- Handles code signing, archiving, and uploading
- Includes release notes and version management

### Android Deployment

#### 1. Google Play Console Setup
1. Create app in Google Play Console
2. Set up internal, alpha, beta, and production tracks
3. Configure store listing, screenshots, and descriptions

#### 2. Signing Setup
- Create upload keystore
- Configure signing in `android/key.properties`
- Upload certificate fingerprint to Play Console

#### 3. Deployment Workflow
The Android deployment is handled by `.github/workflows/deploy-android.yml`:

**Internal Testing:**
```bash
# Manual trigger via GitHub Actions
# Go to Actions tab → Deploy Android → Run workflow
# Select track: internal
```

**Beta Testing:**
```bash
# Select track: beta
```

**Production Release:**
```bash
# Select track: production
```

#### 4. Build Configuration
- `android/app/build.gradle` - Build variants and signing config
- Supports development, staging, and production flavors
- Automatic ABI splitting and optimization

### Web Deployment

#### 1. AWS Setup
1. Create S3 buckets for staging and production
2. Setup CloudFront distributions (optional)
3. Configure SSL certificates

#### 2. Deployment Workflow
The web deployment is handled by `.github/workflows/deploy-web.yml`:

**Staging Deployment:**
```bash
# Manual trigger via GitHub Actions
# Go to Actions tab → Deploy Web → Run workflow
# Select environment: staging
```

**Production Deployment:**
```bash
# Select environment: production
```

#### 3. CDN Configuration
- CloudFront for global distribution
- Custom cache policies for optimal performance
- SSL/TLS encryption

---

## 🔄 CI/CD Pipeline

### Build Pipeline (`.github/workflows/build-and-test.yml`)
- **Triggers**: Push to main/develop, pull requests
- **Steps**:
  1. Code checkout
  2. Flutter setup and dependency installation
  3. Code analysis and linting
  4. Unit and widget tests with coverage
  5. Build artifacts for all platforms

### Deployment Pipelines
- **Manual Triggers**: Via GitHub Actions UI
- **Environment Protection**: Production deployments require approval
- **Notifications**: Slack integration for deployment status

### Quality Gates
- ✅ Code analysis passes
- ✅ All tests pass
- ✅ Coverage requirements met
- ✅ Build artifacts generated
- ✅ Security scans pass

---

## 📊 Monitoring and Analytics

### Performance Monitoring
- Firebase Performance Monitoring enabled in staging/production
- Custom performance metrics for key operations
- Real-time performance dashboards

### Crash Reporting
- Firebase Crashlytics integration
- Automatic crash reporting
- Detailed crash analytics and trends

### Analytics
- Firebase Analytics for user behavior
- Custom events for feature usage
- A/B testing capabilities

### Health Checks
- Automated health checks post-deployment
- Uptime monitoring
- Performance regression alerts

---

## 🚨 Rollback Procedures

### iOS Rollback
1. Go to App Store Connect
2. Select previous version
3. Submit for review or release immediately
4. Update users via release notes

### Android Rollback
1. Go to Google Play Console
2. Select previous APK/AAB
3. Roll back to previous version
4. Update store listing if needed

### Web Rollback
1. Deploy previous version to S3
2. Invalidate CloudFront cache
3. Update version file
4. Notify users of rollback

---

## 📋 Release Checklist

### Pre-Release
- [ ] All tests passing
- [ ] Code review completed
- [ ] Performance benchmarks met
- [ ] Security audit passed
- [ ] Release notes written
- [ ] Screenshots updated

### Release
- [ ] Tag created and pushed
- [ ] Deployment pipeline triggered
- [ ] Build artifacts verified
- [ ] Deployment notifications sent

### Post-Release
- [ ] Store listings updated
- [ ] Release notes published
- [ ] User communications sent
- [ ] Performance monitoring active
- [ ] Support tickets monitored

---

## 🆘 Troubleshooting

### Common Issues

#### iOS Code Signing Issues
```bash
# Check certificate validity
security find-identity -v -p codesigning

# Verify provisioning profile
security cms -D -i FinWise_Provisioning_Profile.mobileprovision
```

#### Android Signing Issues
```bash
# Verify keystore
keytool -list -v -keystore upload-keystore.jks

# Check Play Store API access
gcloud auth application-default print-access-token
```

#### Web Deployment Issues
```bash
# Check AWS credentials
aws sts get-caller-identity

# Verify S3 bucket permissions
aws s3api get-bucket-policy --bucket finwise-prod-web

# Check CloudFront distribution
aws cloudfront get-distribution --id YOUR_DISTRIBUTION_ID
```

---

## 📞 Support

### Getting Help
- **Documentation**: Check this guide and inline comments
- **GitHub Issues**: Report bugs and request features
- **Slack Channel**: #finwise-deployments for deployment issues
- **Emergency Contacts**: See team contact list

### Emergency Rollback
For critical production issues:
1. Notify team immediately
2. Trigger rollback pipeline
3. Communicate with users
4. Post-mortem analysis

---

## 🎯 Success Metrics

### Deployment KPIs
- **Deployment Frequency**: Daily for staging, weekly for production
- **Lead Time**: < 30 minutes for staging, < 2 hours for production
- **Failure Rate**: < 5% deployment failures
- **Rollback Rate**: < 10% rollbacks

### Quality Metrics
- **Test Coverage**: > 90%
- **Performance Score**: > 95 Lighthouse score
- **Crash Rate**: < 0.1% crash-free users
- **App Store Rating**: > 4.5 stars

---

This deployment setup ensures reliable, automated, and secure releases across all platforms while maintaining high code quality and user experience standards. 🚀
