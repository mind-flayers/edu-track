# EduTrack Development Guide

## Architecture Overview

**EduTrack** is a Flutter-based Academy Management System with Firebase backend using **GetX** for state management. The app follows a **feature-based architecture** with hierarchical Firestore data structure.

### Key Architectural Patterns

- **Feature-based folders**: `lib/app/features/{feature}/screens|controllers|bindings/`
- **Multi-tenant data model**: All data nested under `admins/{adminUid}/`
- **GetX dependency injection**: Controllers use `Get.put()` and `Get.find()` pattern
- **Reactive UI**: Uses `.obs` observables and `Obx()` widgets for state management

## Firebase Integration Patterns

### Firestore Data Structure
```
admins/{adminUid}/
├── students/{studentId}/
│   ├── attendance/{dateDoc}
│   ├── fees/{monthDoc}  
│   └── examResults/{termDoc}
├── teachers/{teacherId}
├── examTerms/{termId}
└── attendanceSummary/{dateDoc}
```

### Firebase Configuration
- **Manual config updates**: Edit `lib/firebase_options.dart` directly instead of using FlutterFire CLI
- **Platform-specific setup**: Ensure `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) match project
- **Multi-platform support**: Same Firebase project supports Web, Android, iOS, Windows, macOS

### Authentication Pattern
```dart
// Always get AuthController instance this way
final AuthController authController = Get.find();
final String adminUid = authController.user?.uid ?? '';

// Firestore queries always scoped to current admin
FirebaseFirestore.instance
  .collection('admins').doc(adminUid)
  .collection('students')
```

## GetX State Management Conventions

### Controller Lifecycle
```dart
// In controllers - use static instance pattern
static ProfileController get instance => Get.find();

// In screens - find controllers (don't put again if already exists)
final AuthController authController = Get.find();
```

### Reactive UI Pattern
```dart
// Use Obx for reactive widgets
Obx(() => Text(controller.count.value.toString()))

// Use .obs for reactive variables
final RxBool isLoading = false.obs;
final RxString searchQuery = ''.obs;
```

### Navigation & Routing
- Routes defined in `main.dart` as `AppRoutes` class
- Use `Get.toNamed()` for navigation: `Get.toNamed(AppRoutes.dashboard)`
- Bindings applied per route in `AppPages.routes`

## UI/UX Conventions

### Design System
- **Theme defined in**: `lib/app/utils/constants.dart`
- **Primary color**: `Color(0xFF7B61FF)` (Purple)
- **Typography**: Google Fonts Poppins throughout
- **Consistency**: Use `k` prefixed constants (e.g., `kPrimaryColor`, `kDefaultPadding`)

### Common UI Patterns
```dart
// Standard form validation
final _formKey = GlobalKey<FormState>();
if (_formKey.currentState!.validate()) { /* submit */ }

// Loading states with GetX
controller.isLoading.value = true;
// ... async operation
controller.isLoading.value = false;

// Search functionality pattern
final TextEditingController _searchController = TextEditingController();
String _searchQuery = '';
```

### Navigation Bar Pattern
- Bottom navigation with `_selectedIndex` state
- Manual navigation to different screens based on index
- Consistent across all list screens (Students, Teachers, etc.)

## Development Workflows

### Database Setup
```bash
# Run this ONCE to populate Firestore with sample data
# Call from main.dart in debug mode only:
await setupFirestoreDatabase(); // from firestore_setup.dart
```

### Build Commands
```bash
# Clean build (recommended after Firebase config changes)
flutter clean && flutter pub get && flutter run

# Platform-specific builds
flutter run -d chrome        # Web
flutter run -d windows       # Windows
flutter run                  # Android (default)
```

### Firebase Project Migration
1. Update `android/app/google-services.json` with new project file
2. Edit `lib/firebase_options.dart` manually with new project values
3. Update `firebase.json` project references
4. Run `flutter clean && flutter pub get`

## Critical Integration Points

### Cloudinary Image Storage
- **Profile photos**: Uses `cloudinary_public` package
- **Upload preset**: `admin_profile` (unsigned)
- **Cloud name**: `duckxlzaj`
- Pattern: Upload to Cloudinary, store URL in Firestore

### QR Code Integration
- **Student QR data**: Uses document ID as unique identifier
- **Attendance marking**: QR scanner reads student ID, marks attendance
- **Generation**: QR codes generated with student document ID

### External Dependencies
- **Charts**: FL Chart for analytics dashboards  
- **Animations**: `flutter_animate` for screen transitions
- **File operations**: Excel export, PDF generation capabilities
- **State persistence**: GetX handles app state across navigation

## Common Debugging Issues

### Firebase Connection Problems
1. Check `lib/firebase_options.dart` has valid appIds (no "REPLACE_" placeholders)
2. Ensure platform files match Firebase Console registered apps
3. Verify Firestore rules allow read/write for authenticated users

### GetX Controller Issues
- Controllers must be `Get.put()` before `Get.find()` calls
- Use `Get.delete<ControllerName>()` to clean up when needed
- Check bindings are properly configured in route definitions

### Build Errors
- Run `flutter clean` after any Firebase configuration changes
- Check `android/app/google-services.json` is valid JSON
- Ensure all required Firebase services are enabled in console

## Project-Specific Notes

- **Admin-centric**: All functionality assumes single admin per instance
- **Offline-first**: Designed for consistent online connectivity
- **Multi-platform**: Same codebase runs on Web, Desktop, Mobile
- **Education domain**: Student/Teacher/Attendance/Exam management focus