# EduTrack App Deployment Guide

## Complete Guide to Publishing Your Flutter App

This comprehensive guide covers deploying EduTrack to Google Play Store, Apple App Store, and Web.

---

## Table of Contents

1. [Pre-Deployment Checklist](#pre-deployment-checklist)
2. [Android Deployment (Google Play Store)](#android-deployment-google-play-store)
3. [iOS Deployment (Apple App Store)](#ios-deployment-apple-app-store)
4. [Web Deployment](#web-deployment)
5. [Post-Deployment](#post-deployment)
6. [Maintenance & Updates](#maintenance--updates)

---

## Pre-Deployment Checklist

### 1. **Complete App Testing**

```bash
# Run all tests
flutter test

# Test on real devices
flutter run --release

# Check for issues
flutter analyze
```

### 2. **Update App Information**

Update these files with correct information:

**`pubspec.yaml`:**
```yaml
name: edu_track
description: Academy Management System for tracking students, teachers, attendance, and exam results.
version: 1.0.0+1  # Format: major.minor.patch+buildNumber
```

**`android/app/src/main/AndroidManifest.xml`:**
```xml
<application
    android:label="EduTrack"
    android:icon="@mipmap/ic_launcher">
```

**`ios/Runner/Info.plist`:**
```xml
<key>CFBundleDisplayName</key>
<string>EduTrack</string>
<key>CFBundleName</key>
<string>EduTrack</string>
```

### 3. **Create App Icons**

Generate icons for all platforms (Android, iOS, Web):

```bash
# Install flutter_launcher_icons
flutter pub add dev:flutter_launcher_icons

# Add to pubspec.yaml:
flutter_icons:
  android: true
  ios: true
  image_path: "assets/icons/app_icon.png"  # 1024x1024 PNG
  
# Generate icons
flutter pub run flutter_launcher_icons
```

### 4. **Prepare Marketing Materials**

- **App Screenshots:** 5-8 screenshots per platform
- **Feature Graphic:** 1024x500 px (Android)
- **App Icon:** 512x512 px (high resolution)
- **App Description:** Short (80 chars) and Full (4000 chars)
- **Privacy Policy URL:** Required for both stores
- **Demo Video:** Optional but recommended

---

## Android Deployment (Google Play Store)

### Step 1: Create Keystore

```bash
# Navigate to android/app directory
cd android/app

# Create keystore
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# Enter password and details when prompted
# Save password and alias information securely!
```

### Step 2: Configure Signing

**Create `android/key.properties`:**
```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=C:/Users/User/upload-keystore.jks
```

**⚠️ Add to `.gitignore`:**
```
# Key properties
android/key.properties
*.jks
*.keystore
```

**Update `android/app/build.gradle`:**

```gradle
// Add before android { block
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    // ... existing code ...

    // Add signing configs
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }

    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```

### Step 3: Update App Configuration

**`android/app/build.gradle`:**

```gradle
android {
    namespace "com.meckanamoolai.edu_track"  // Update this
    compileSdkVersion 34

    defaultConfig {
        applicationId "com.meckanamoolai.edu_track"  // Unique package name
        minSdkVersion 21
        targetSdkVersion 34
        versionCode 1  // Increment for each release
        versionName "1.0.0"
    }
}
```

### Step 4: Build Release APK/AAB

```bash
# Clean build
flutter clean
flutter pub get

# Build App Bundle (AAB) - Recommended for Play Store
flutter build appbundle --release

# Or build APK
flutter build apk --release --split-per-abi

# Output location:
# AAB: build/app/outputs/bundle/release/app-release.aab
# APK: build/app/outputs/flutter-apk/app-release.apk
```

### Step 5: Create Google Play Console Account

1. **Go to:** https://play.google.com/console
2. **Sign up:** $25 one-time registration fee
3. **Complete Account Details:**
   - Developer name
   - Email address
   - Phone number
   - Payment information

### Step 6: Create App in Play Console

1. **Click "Create App"**
2. **Fill Required Information:**
   - App name: EduTrack
   - Default language: English
   - App/Game: App
   - Free/Paid: Free (or Paid)
   - Accept declarations

### Step 7: Complete Store Listing

**Dashboard → Store Presence → Main Store Listing**

1. **App Details:**
   - Short description (80 characters)
   - Full description (4000 characters)
   - Screenshots (minimum 2 per device type)
   - Feature graphic (1024x500)
   - App icon (512x512)

2. **Categorization:**
   - App category: Education or Productivity
   - Content rating: Complete questionnaire
   - Target audience: Select age groups

3. **Contact Details:**
   - Email
   - Website (optional)
   - Privacy Policy URL (Required!)

### Step 8: Set Up App Content

**Content Rating:**
- Complete the questionnaire
- Get rating certificate

**Target Audience:**
- Select age groups (e.g., 13+)

**Privacy Policy:**
- Host privacy policy on your website or use GitHub Pages
- Example URL: `https://yourusername.github.io/edutrack-privacy`

**Data Safety:**
- Declare what data you collect
- Explain how data is used
- Firebase data collection details

### Step 9: Upload App Bundle

1. **Go to:** Production → Create new release
2. **Upload AAB:** Upload `app-release.aab`
3. **Release name:** 1.0.0
4. **Release notes:**
   ```
   Initial release of EduTrack - Academy Management System
   
   Features:
   - Student management
   - Teacher management
   - Attendance tracking
   - Exam results management
   - Fee payment tracking
   - WhatsApp notifications
   ```

### Step 10: Review and Publish

1. **Review Release:** Check all details
2. **Send for Review:** Typically takes 1-3 days
3. **Address Issues:** Fix any policy violations
4. **Publish:** App goes live after approval

---

## iOS Deployment (Apple App Store)

### Prerequisites

- **Mac Computer** (Required for iOS development)
- **Apple Developer Account** ($99/year)
- **Xcode** (Latest version)

### Step 1: Apple Developer Account Setup

1. **Sign up:** https://developer.apple.com/programs/
2. **Pay $99/year fee**
3. **Complete enrollment**

### Step 2: Configure Xcode Project

```bash
# Open Xcode project
open ios/Runner.xcworkspace

# In Xcode:
# 1. Select Runner target
# 2. General tab:
#    - Bundle Identifier: com.meckanamoolai.edutrack
#    - Version: 1.0.0
#    - Build: 1
# 3. Signing & Capabilities:
#    - Team: Select your team
#    - Enable "Automatically manage signing"
```

### Step 3: Update Info.plist

**`ios/Runner/Info.plist`:**

```xml
<key>CFBundleDisplayName</key>
<string>EduTrack</string>

<key>NSCameraUsageDescription</key>
<string>This app requires camera access to take student photos.</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>This app requires photo library access to select student photos.</string>

<!-- Add other permission descriptions as needed -->
```

### Step 4: Create App in App Store Connect

1. **Go to:** https://appstoreconnect.apple.com/
2. **Click "+" → New App**
3. **Fill Details:**
   - Platform: iOS
   - Name: EduTrack
   - Primary Language: English
   - Bundle ID: com.meckanamoolai.edutrack
   - SKU: edutrack001

### Step 5: Build and Archive

```bash
# Clean and get dependencies
flutter clean
flutter pub get

# Build iOS release
flutter build ios --release

# In Xcode:
# 1. Select "Any iOS Device (arm64)" as target
# 2. Product → Archive
# 3. Wait for archive to complete
# 4. Organizer window opens → Click "Distribute App"
# 5. Choose "App Store Connect" → Upload
```

### Step 6: Complete App Store Information

**App Information:**
- Name: EduTrack
- Subtitle: Academy Management System
- Category: Education
- Content Rights: Original content

**Pricing and Availability:**
- Price: Free (or set price)
- Availability: All countries

**App Privacy:**
- Complete privacy questionnaire
- Add privacy policy URL

**Screenshots:**
- 6.5" Display (iPhone 14 Pro Max): 1290x2796
- 5.5" Display (iPhone 8 Plus): 1242x2208
- iPad Pro (2nd gen): 2048x2732

**App Description:**
```
EduTrack is a comprehensive academy management system designed for educational institutions.

FEATURES:
• Student Management - Register and track student information
• Teacher Management - Manage teaching staff details
• Attendance Tracking - Mark and monitor daily attendance
• Exam Results - Record and analyze student performance
• Fee Management - Track payments and pending fees
• WhatsApp Integration - Send automated notifications
• QR Code Scanning - Quick attendance marking
• Analytics Dashboard - Comprehensive reports

PERFECT FOR:
- Tuition centers
- Private academies
- Coaching institutes
- After-school programs

Download EduTrack and streamline your academy management today!
```

### Step 7: Submit for Review

1. **Add Build:** Select uploaded build
2. **Export Compliance:** Answer crypto questions
3. **Submit for Review**
4. **Review Time:** 24-48 hours typically
5. **Address Feedback:** If rejected, fix issues and resubmit

---

## Web Deployment

### Option 1: Firebase Hosting (Recommended)

**Step 1: Build Web App**

```bash
# Build for web
flutter build web --release

# Output: build/web/
```

**Step 2: Install Firebase CLI**

```bash
npm install -g firebase-tools

# Login
firebase login

# Initialize hosting
firebase init hosting

# Select options:
# - Use existing project: edutrack-73a2e
# - Public directory: build/web
# - Configure as SPA: Yes
# - Set up automatic builds: No
```

**Step 3: Deploy**

```bash
# Deploy to Firebase
firebase deploy --only hosting

# Your app will be live at:
# https://edutrack-73a2e.web.app
```

**Step 4: Custom Domain (Optional)**

```bash
# Add custom domain in Firebase Console
firebase hosting:channel:deploy production --expires 30d
```

### Option 2: Vercel

```bash
# Install Vercel CLI
npm i -g vercel

# Deploy
cd build/web
vercel

# Follow prompts
```

### Option 3: Netlify

1. **Go to:** https://netlify.com
2. **Drag and drop** `build/web` folder
3. **Configure domain**

### Option 4: GitHub Pages

```bash
# Build web
flutter build web --release --base-href "/edu_track/"

# Create gh-pages branch
git checkout -b gh-pages
cp -r build/web/* .
git add .
git commit -m "Deploy to GitHub Pages"
git push origin gh-pages

# Enable Pages in GitHub repo settings
# URL: https://yourusername.github.io/edu_track/
```

---

## Post-Deployment

### 1. Monitor Analytics

**Firebase Analytics:**
```dart
// Already integrated in your app
FirebaseAnalytics.instance.logEvent(
  name: 'app_launched',
  parameters: {'platform': Platform.operatingSystem},
);
```

**Google Play Console:**
- Monitor installs, ratings, crashes
- Respond to user reviews

**App Store Connect:**
- Track downloads and revenue
- Monitor crash reports

### 2. Set Up Crash Reporting

**Firebase Crashlytics (Recommended):**

```bash
# Add dependency
flutter pub add firebase_crashlytics

# Configure in main.dart
FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
```

### 3. Create Support Channels

- **Support Email:** support@meckanamoolai.lk
- **Website:** Create landing page
- **Documentation:** User guides and FAQs
- **Social Media:** Facebook, Twitter for updates

### 4. Marketing

**App Store Optimization (ASO):**
- Relevant keywords in title/description
- High-quality screenshots
- Positive reviews (encourage satisfied users)
- Regular updates

**Promotional Strategies:**
- Share on social media
- Create demo videos
- Contact education blogs
- Offer limited-time features
- Run paid ads (Google Ads, Facebook Ads)

---

## Maintenance & Updates

### Release Updates

**Android:**
```bash
# Update version in pubspec.yaml
version: 1.1.0+2

# Build new AAB
flutter build appbundle --release

# Upload to Play Console → Create new release
```

**iOS:**
```bash
# Update version in Xcode
# Build and archive
# Upload to App Store Connect
```

**Web:**
```bash
# Build and deploy
flutter build web --release
firebase deploy --only hosting
```

### Version Numbering

Follow semantic versioning:
- **Major.Minor.Patch+BuildNumber**
- `1.0.0+1` → First release
- `1.0.1+2` → Bug fix
- `1.1.0+3` → New features
- `2.0.0+4` → Major changes

### Update Strategy

1. **Bug Fixes:** Release as soon as possible
2. **Minor Updates:** Every 2-4 weeks
3. **Major Updates:** Every 2-3 months
4. **Emergency Fixes:** Within 24 hours

### Best Practices

- **Test thoroughly** before each release
- **Read user reviews** and address concerns
- **Monitor crash reports** daily
- **Keep dependencies updated**
- **Backup Firestore data** regularly
- **Communicate updates** through in-app messages
- **Follow platform guidelines** strictly

---

## Privacy Policy Template

Create a privacy policy at `https://yourdomain.com/privacy` with:

```markdown
# Privacy Policy for EduTrack

Last updated: [Date]

## Information We Collect
- Student names, photos, contact information
- Attendance records
- Exam results
- Payment information
- Device information for authentication

## How We Use Information
- Manage student records
- Track attendance and performance
- Process payments
- Send notifications via WhatsApp
- Improve app functionality

## Data Storage
- Data stored securely on Firebase servers
- Encrypted in transit and at rest
- Access limited to authorized users

## Third-Party Services
- Firebase (Google) - Backend services
- Cloudinary - Image hosting
- WhatsApp - Notifications

## User Rights
- Access your data
- Request data deletion
- Opt-out of notifications

## Contact Us
Email: support@meckanamoolai.lk
```

---

## Troubleshooting

### Common Issues

**Android Build Fails:**
```bash
# Clean and rebuild
flutter clean
cd android
./gradlew clean
cd ..
flutter build appbundle --release
```

**iOS Build Fails:**
```bash
# Clean Xcode cache
rm -rf ~/Library/Developer/Xcode/DerivedData
cd ios
pod deintegrate
pod install
cd ..
flutter build ios --release
```

**App Rejected:**
- Read rejection email carefully
- Fix issues mentioned
- Test thoroughly
- Resubmit with explanation

---

## Checklist Before Publishing

- [ ] All features tested on real devices
- [ ] App icons generated for all platforms
- [ ] Screenshots and marketing materials ready
- [ ] Privacy policy created and hosted
- [ ] Version numbers updated correctly
- [ ] Signing keys created and stored safely
- [ ] Release notes written
- [ ] Support email configured
- [ ] Analytics integrated
- [ ] Crash reporting enabled
- [ ] Terms of service created (if needed)
- [ ] Data backup strategy in place
- [ ] User documentation prepared
- [ ] Beta testing completed
- [ ] App store accounts created
- [ ] Payment methods configured (if paid)

---

## Resources

**Official Documentation:**
- [Flutter Deployment](https://docs.flutter.dev/deployment)
- [Google Play Console Help](https://support.google.com/googleplay/android-developer)
- [App Store Connect Help](https://developer.apple.com/app-store-connect/)
- [Firebase Hosting](https://firebase.google.com/docs/hosting)

**Tools:**
- [App Icon Generator](https://appicon.co/)
- [Screenshot Maker](https://www.screely.com/)
- [Privacy Policy Generator](https://www.privacypolicygenerator.info/)

**Community:**
- [Flutter Discord](https://discord.gg/flutter)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/flutter)
- [Reddit r/FlutterDev](https://reddit.com/r/FlutterDev)

---

## Success Tips

1. **Start with Android** - Easier and faster approval
2. **Test on multiple devices** - Different screen sizes
3. **Respond to reviews** - Shows you care
4. **Update regularly** - Keeps users engaged
5. **Monitor metrics** - Data-driven decisions
6. **Build community** - User feedback is gold
7. **Be patient** - Success takes time
8. **Stay compliant** - Follow all policies
9. **Backup everything** - Data, keys, passwords
10. **Plan for scale** - Firebase limits, costs

---

## Congratulations! 🎉

You're ready to publish EduTrack to the world. Good luck with your app launch!

For questions or issues, refer to the official documentation or community forums.

**Remember:** The first release is just the beginning. Continuous improvement and user feedback will make your app successful.
