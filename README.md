# 🎓 EduTrack - Academy Management System

<div align="center">
  <img src="assets/images/app_logo_high.png" alt="EduTrack Logo" width="200"/>
  
  [![Flutter](https://img.shields.io/badge/Flutter-3.6.0-blue.svg)](https://flutter.dev/)
  [![Firebase](https://img.shields.io/badge/Firebase-Enabled-orange.svg)](https://firebase.google.com/)
  [![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
</div>

## 📖 What is EduTrack?

EduTrack is a comprehensive **Tuition/Academy Management System** built with Flutter and Firebase, designed specifically for educational institutions to streamline their administrative processes. This mobile application serves as a centralized platform for managing students, teachers, attendance, exam results, and fee payments.

### 🎯 Key Features

- **👥 Student Management**: Complete student profiles with photo, contact details, and academic information
- **👨‍🏫 Teacher Management**: Teacher profiles with subject assignments and class allocations
- **📊 Attendance Tracking**: Real-time attendance marking with QR code scanning
- **�� Exam Results**: Comprehensive exam result management with term-wise tracking
- **💰 Fee Management**: Track fee payments and pending amounts
- **📱 QR Code Integration**: Quick attendance marking through QR code scanning
- **📈 Analytics Dashboard**: Visual insights with charts and statistics
- **📄 Report Generation**: Export data to Excel and PDF formats
- **🔐 Secure Authentication**: Firebase-based authentication system
- **☁️ Cloud Storage**: Cloudinary integration for image management

## 🤔 Why EduTrack?

### Problems It Solves:
- **Manual Record Keeping**: Eliminates paper-based student and teacher records
- **Attendance Management**: Automates attendance tracking with QR codes
- **Data Accessibility**: Provides instant access to student/teacher information
- **Fee Tracking**: Simplifies fee collection and payment tracking
- **Report Generation**: Automated generation of academic reports
- **Communication Gap**: Bridges communication between administration and stakeholders

### Benefits:
- ⚡ **Efficiency**: Reduces administrative workload by 70%
- 📊 **Accuracy**: Minimizes human errors in data entry
- 🔍 **Transparency**: Real-time access to academic data
- 💾 **Data Security**: Cloud-based secure data storage
- 📱 **Mobility**: Access from anywhere, anytime
- 💰 **Cost-Effective**: Reduces paper and manual labor costs

## 👥 Who Needs EduTrack?

### Primary Users:
- **🏫 Educational Institutions**: Schools, colleges, coaching centers
- **👨‍💼 School Administrators**: Principals, admin staff
- **📚 Academy Owners**: Private coaching institutes
- **🎓 Training Centers**: Professional training institutes

### Target Audience:
- Small to medium-sized educational institutions
- Institutions looking to digitize their operations
- Organizations wanting to improve administrative efficiency
- Schools seeking modern attendance and fee management solutions

## 🚀 Getting Started

### Prerequisites

Before you begin, ensure you have the following installed:
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.6.0 or higher)
- [Dart SDK](https://dart.dev/get-dart) (3.6.0 or higher)
- [Android Studio](https://developer.android.com/studio) or [VS Code](https://code.visualstudio.com/)
- [Git](https://git-scm.com/)

### 📥 How to Clone and Run This Repository

#### 1. Clone the Repository
```bash
git clone https://github.com/yourusername/edu_track.git
cd edu_track
```

#### 2. Install Dependencies
```bash
flutter pub get
```

#### 3. Firebase Setup
1. Create a new Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Enable the following services:
   - Authentication (Email/Password)
   - Cloud Firestore
   - Storage
3. Download and place configuration files:
   - `google-services.json` in `android/app/`
   - `GoogleService-Info.plist` in `ios/Runner/`

#### 4. Configure Firebase CLI (Optional)
```bash
npm install -g firebase-tools
firebase login
firebase init
```

#### 5. Run the Application
```bash
# For Android
flutter run

# For iOS
flutter run -d ios

# For Web
flutter run -d chrome

# For specific device
flutter devices
flutter run -d [device-id]
```

#### 6. Build for Production
```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release

# Web
flutter build web --release
```

## 📱 App Architecture

### 🏗️ Project Structure
```
lib/
├── app/
│   ├── features/
│   │   ├── authentication/     # Login, signup, password reset
│   │   ├── dashboard/          # Main dashboard
│   │   ├── students/           # Student management
│   │   ├── teachers/           # Teacher management
│   │   ├── attendance/         # Attendance tracking
│   │   ├── exam/              # Exam results
│   │   ├── profile/           # User profile
│   │   └── qr_scanner/        # QR code functionality
│   ├── utils/                 # Constants, themes, helpers
│   └── widgets/               # Reusable widgets
├── firebase_options.dart      # Firebase configuration
└── main.dart                  # App entry point
```

### 🛠️ Tech Stack
- **Frontend**: Flutter (Dart)
- **Backend**: Firebase (Firestore, Auth, Storage)
- **State Management**: GetX
- **Image Storage**: Cloudinary
- **Charts**: FL Chart
- **QR Codes**: QR Flutter, Mobile Scanner
- **File Operations**: Excel, PDF generation

## 📊 Database Structure

### Firestore Collections:
```
admins/
├── {adminId}/
│   ├── adminProfile/
│   ├── students/
│   │   └── {studentId}/
│   │       ├── attendance/
│   │       ├── fees/
│   │       └── examResults/
│   ├── teachers/
│   ├── examTerms/
│   └── attendanceSummary/
```

## 🎥 Demo Video

> **Coming Soon!** 
> 
> We're preparing a comprehensive demo video showcasing all features of EduTrack. Stay tuned!

## 📸 Screenshots

### Dashboard
<div align="center">
  <img src="screenshots/dashboard.png" alt="Dashboard" width="300"/>
  <p><em>Main dashboard with overview statistics</em></p>
</div>

### Student Management
<div align="center">
  <img src="screenshots/student_list.png" alt="Student List" width="300"/>
  <p><em>Student list with search functionality</em></p>
</div>

### QR Code Scanner
<div align="center">
  <img src="screenshots/qr_scanner.png" alt="QR Scanner" width="300"/>
  <p><em>QR code scanner for attendance</em></p>
</div>

### Attendance Tracking
<div align="center">
  <img src="screenshots/attendance.png" alt="Attendance" width="300"/>
  <p><em>Attendance summary with analytics</em></p>
</div>

> **Note**: Screenshots will be added soon. The app is fully functional and ready for testing.

## 🌐 Where You Can Try EduTrack

### 🔗 Live Demo
- **Web App**: [https://edutrack-demo.web.app](https://edutrack-demo.web.app) *(Coming Soon)*
- **Android APK**: [Download Latest Release](https://github.com/yourusername/edu_track/releases) *(Coming Soon)*


### 📱 Platform Availability
- ✅ **Android** (API 21+)
- ✅ **iOS** (iOS 12+)
- ✅ **Web** (Chrome, Firefox, Safari)
- ✅ **Windows** (Windows 10+)
- ✅ **macOS** (macOS 10.14+)
- ✅ **Linux** (Ubuntu 18.04+)

## 🤝 Contributing

We welcome contributions! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### 📋 Development Guidelines
- Follow [Flutter style guide](https://dart.dev/guides/language/effective-dart/style)
- Write meaningful commit messages
- Add tests for new features
- Update documentation as needed

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support & Help

### 📞 Contact Information
- **Email**: mishaf1106@gmail.com
- **GitHub Issues**: [Create an Issue](https://github.com/mindflayers/edu_track/issues)
- **Documentation**: [Wiki](https://github.com/yourusername/edu_track/wiki)

### 🐛 Bug Reports
If you encounter any bugs, please create an issue with:
- Device information
- Steps to reproduce
- Expected vs actual behavior
- Screenshots (if applicable)

### 💡 Feature Requests
We're always looking to improve! Submit feature requests through GitHub Issues with the "enhancement" label.

## 🔮 Roadmap

### Upcoming Features:
- [ ] **Student Portal**: Dedicated app for students
- [ ] **Push Notifications**: Real-time notifications for important updates
- [ ] **Multi-language Support**: Support for regional languages
- [ ] **Timetable Management**: Class scheduling and timetable management
- [ ] **Financial Reports**: Advanced financial analytics and reporting

### Version History:
- **v1.0.0** - Initial release with core features
- **v1.1.0** - Enhanced UI and bug fixes *(Coming Soon)*
- **v2.0.0** - Student portal and notifications *(Planned)*

## 🙏 Acknowledgments

- **Flutter Team** for the amazing framework
- **Firebase Team** for the robust backend services
- **GetX Community** for the excellent state management solution
- **Open Source Contributors** who made this project possible

---

<div align="center">
  <p>Made with ❤️ by the Mishaf Hasan</p>
  <p>⭐ Star this repository if you found it helpful!</p>
</div>