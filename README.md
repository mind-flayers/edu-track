# 🎓 EduTrack - Academy Management System

<div align="center">
  <img src="assets/images/app_logo_high.png" alt="EduTrack Logo" width="200"/>
  
  [![Flutter](https://img.shields.io/badge/Flutter-3.6.0-blue.svg)](https://flutter.dev/)
  [![Next.js](https://img.shields.io/badge/Next.js-16.0-black.svg)](https://nextjs.org/)
  [![Firebase](https://img.shields.io/badge/Firebase-Enabled-orange.svg)](https://firebase.google.com/)
  [![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
</div>

## 📖 What is EduTrack?

EduTrack is a comprehensive **Academy Management Ecosystem** for educational institutions. Three integrated components:

1. **Flutter Mobile App** - Primary academy management interface (Android, iOS, Web, Desktop)
2. **Next.js Admin Portal** - Web dashboard for super admin to manage multiple academies
3. **WhatsApp Bot** - Automated notification service for parents

Manage students, teachers, attendance, exams, fees, and parent communication - all in one platform.

## 🏗️ System Architecture

```
Flutter App + Next.js Portal + WhatsApp Bot
              ↓
        Firebase Backend
     (Firestore, Auth, Functions)
              ↓
      External Services
   (Cloudinary, WhatsApp Web)
```

### 🎯 Key Features

**Flutter App**: Student/Teacher management • QR-based attendance • Exam results • Fee tracking (monthly/daily) • Analytics dashboard • Excel/PDF export • WhatsApp notifications

**Admin Portal**: Multi-academy management • CSV bulk import • Cloudinary integration • Admin account creation

**WhatsApp Bot**: Automated parent notifications • Message queue • Delivery tracking • Auto-retry • Free 24/7 hosting on Render.com

## 🤔 Why EduTrack?

**Solves**: Manual record keeping • Attendance tracking • Fee management • Report generation • Parent communication

**Benefits**: 70% less admin work • Cloud security • Real-time data access • Multi-platform • Cost-effective

**For**: Schools • Coaching centers • Training institutes • Academy owners looking to digitize operations

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.6.0+ • Android Studio or VS Code • Git • Node.js 18+ (for portal/bot)

### 📥 How to Clone and Run This Repository

#### 1. Clone the Repository
```bash
git clone https://github.com/mind-flayers/edu-track.git
cd edu_track
```

---

## 🚀 Component Setup Guides

### 1️⃣ Flutter Mobile App Setup

#### Prerequisites
- Flutter SDK 3.6.0+ ([Install Flutter](https://flutter.dev/docs/get-started/install))
- Android Studio or VS Code with Flutter extensions
- Git

```bash
flutter pub get && flutter doctor

# Use existing Firebase project or create your own at console.firebase.google.com
# Enable: Authentication, Firestore, Storage

# Seed test data (optional)
cd db && npm install
node populate_database.js YOUR_ADMIN_UID

# Run app
flutter run                    # Default device
flutter run -d chrome          # Web
flutter run --release          # Release mode

# Build for production
flutter build apk --release    # Android
flutter build web --release    # Web
```

---

### 2️⃣ Next.js Admin Portal Setup

```bash
cd admin-portal && npm install

# Create .env.local with:
# - SUPER_ADMIN_EMAIL (your email)
# - Firebase Admin SDK credentials (from Firebase Console → Service Accounts)
# - Cloudinary credentials

npm run dev  # Access at localhost:3000
```

**Features**: Create academy accounts • Bulk CSV import • Google Drive photo sync

See [`admin-portal/README.md`](admin-portal/README.md) for details.

---

### 3️⃣ WhatsApp Bot Setup

```bash
cd whatsapp-edutrack-bot && npm install

# Add service-account-key.json from Firebase Console

npm start       # Terminal 1: Start bot, scan QR code
npm run bridge  # Terminal 2: Start Firebase queue processor
```

**Flow**: Flutter app → Firestore queue → Firebase bridge → WhatsApp bot → Parent's WhatsApp

**Deploy**: Free 24/7 hosting on **Render.com** with Firebase Storage for session persistence and cron-job.org for keep-alive.

See [`RENDER_DEPLOYMENT_COMPLETE_GUIDE.md`](whatsapp-edutrack-bot/RENDER_DEPLOYMENT_COMPLETE_GUIDE.md) for complete deployment instructions.

---

### 4️⃣ Firebase Functions Setup (Optional)

```bash
cd functions
npm install

# Deploy functions
firebase deploy --only functions

# Test locally
npm run serve
```

## 📁 Repository Structure

```
lib/                    # Flutter app (authentication, dashboard, students, teachers, etc.)
admin-portal/           # Next.js super admin portal
whatsapp-edutrack-bot/  # WhatsApp notification bot (Baileys)
functions/              # Firebase Cloud Functions
db/                     # Database scripts and documentation
docs/                   # Deployment and setup guides
```

## 🛠️ Tech Stack

**Flutter App**: Flutter 3.6.0 • GetX • Firebase • Cloudinary • FL Chart • QR Flutter • Excel/PDF export

**Admin Portal**: Next.js 16 • React 19 • Tailwind CSS • Firebase Admin SDK • PapaParse

**WhatsApp Bot**: Node.js 18 • Baileys • Express • PM2 • Firebase Admin SDK

**Backend**: Firebase (Firestore, Auth, Functions, Storage)

## 📊 Database Structure

**Multi-tenant Firestore**: All data scoped under `admins/{adminUid}/`

**Collections**: adminProfile • academySettings • students (with attendance, fees, examResults) • teachers • examTerms • attendanceSummary • whatsappQueue

**Key Features**: Data isolation per academy • PAID/PENDING payment status • Presence-only attendance • Academy-specific subjects • Fee exemption flag • WhatsApp message queue

See [`db/database_structure.md`](db/database_structure.md) for complete schema.

---

## 📸 Screenshots & Demo

### 🔐 Authentication & Dashboard

<div align="center">
  <table>
    <tr>
      <td align="center">
        <img src="assets/screenshots/login-page.png" alt="Login Page" width="250"/><br/>
        <b>Login Page</b><br/>
        <sub>Secure authentication</sub>
      </td>
      <td align="center">
        <img src="assets/screenshots/dashboard-page.png" alt="Dashboard" width="250"/><br/>
        <b>Dashboard</b><br/>
        <sub>Analytics overview</sub>
      </td>
      <td align="center">
        <img src="assets/screenshots/profile-settings-page.png" alt="Profile Settings" width="250"/><br/>
        <b>Profile Settings</b><br/>
        <sub>Account management</sub>
      </td>
    </tr>
  </table>
</div>

### 👥 Student & Teacher Management

<div align="center">
  <table>
    <tr>
      <td align="center">
        <img src="assets/screenshots/students-list-page.png" alt="Students List" width="250"/><br/>
        <b>Students List</b><br/>
        <sub>View all students</sub>
      </td>
      <td align="center">
        <img src="assets/screenshots/add-student-page.png" alt="Add Student" width="250"/><br/>
        <b>Add Student</b><br/>
        <sub>Register new student</sub>
      </td>
      <td align="center">
        <img src="assets/screenshots/teachers-list-page.png" alt="Teachers List" width="250"/><br/>
        <b>Teachers List</b><br/>
        <sub>Manage teachers</sub>
      </td>
    </tr>
  </table>
</div>

### 📋 Student Details & Information

<div align="center">
  <table>
    <tr>
      <td align="center">
        <img src="assets/screenshots/student-details-page-1.jpg" alt="Student Details 1" width="250"/><br/>
        <b>Student Profile</b><br/>
        <sub>Personal information</sub>
      </td>
      <td align="center">
        <img src="assets/screenshots/student-details-page-2.png" alt="Student Details 2" width="250"/><br/>
        <b>Student Details</b><br/>
        <sub>Academic records</sub>
      </td>
      <td align="center">
        <img src="assets/screenshots/student-details-page-3.png" alt="Student Details 3" width="250"/><br/>
        <b>Student Info</b><br/>
        <sub>Contact & QR code</sub>
      </td>
    </tr>
  </table>
</div>

### 📱 QR Code Attendance System

<div align="center">
  <table>
    <tr>
      <td align="center">
        <img src="assets/screenshots/qr-code-scanner-page-1.png" alt="QR Scanner 1" width="250"/><br/>
        <b>QR Scanner</b><br/>
        <sub>Scan student QR</sub>
      </td>
      <td align="center">
        <img src="assets/screenshots/qr-code-scanner-page-2.png" alt="QR Scanner 2" width="250"/><br/>
        <b>Scanning Process</b><br/>
        <sub>Real-time detection</sub>
      </td>
      <td align="center">
        <img src="assets/screenshots/qr-code-scanner-page-3.png" alt="QR Scanner 3" width="250"/><br/>
        <b>Attendance Marked</b><br/>
        <sub>Success confirmation</sub>
      </td>
    </tr>
    <tr>
      <td align="center" colspan="3">
        <img src="assets/screenshots/qr-code-scanner-page-4.png" alt="QR Scanner 4" width="250"/><br/>
        <b>Attendance History</b><br/>
        <sub>View attendance records</sub>
      </td>
    </tr>
  </table>
</div>

### 💰 Payment Management & WhatsApp Integration

<div align="center">
  <table>
    <tr>
      <td align="center">
        <img src="assets/screenshots/pending-payments.png" alt="Pending Payments" width="250"/><br/>
        <b>Pending Payments</b><br/>
        <sub>Outstanding fees</sub>
      </td>
      <td align="center">
        <img src="assets/screenshots/mark-payment-1.png" alt="Mark Payment 1" width="250"/><br/>
        <b>Mark Payment</b><br/>
        <sub>Record fee payment</sub>
      </td>
      <td align="center">
        <img src="assets/screenshots/mark-payment-2.png" alt="Mark Payment 2" width="250"/><br/>
        <b>Payment Details</b><br/>
        <sub>Enter payment info</sub>
      </td>
    </tr>
    <tr>
      <td align="center" colspan="3">
        <img src="assets/screenshots/payment-maked-whatsapp-notification-sent.png" alt="WhatsApp Notification" width="250"/><br/>
        <b>WhatsApp Notification</b><br/>
        <sub>Automated parent notification</sub>
      </td>
    </tr>
  </table>
</div>

### 📊 Exam Results & Reports

<div align="center">
  <table>
    <tr>
      <td align="center">
        <img src="assets/screenshots/exam-results-page.png" alt="Exam Results" width="250"/><br/>
        <b>Exam Results</b><br/>
        <sub>View all results</sub>
      </td>
      <td align="center">
        <img src="assets/screenshots/export-exam-results-by-class.png" alt="Export by Class" width="250"/><br/>
        <b>Export by Class</b><br/>
        <sub>Bulk export options</sub>
      </td>
      <td align="center">
        <img src="assets/screenshots/export-student-exam-results.png" alt="Student Results" width="250"/><br/>
        <b>Student Results</b><br/>
        <sub>Individual reports</sub>
      </td>
    </tr>
  </table>
</div>

### 📄 Export & Reports

<div align="center">
  <table>
    <tr>
      <td align="center">
        <img src="assets/screenshots/export-payments.png" alt="Export Payments" width="250"/><br/>
        <b>Export Payments</b><br/>
        <sub>Financial reports (Excel)</sub>
      </td>
      <td align="center">
        <img src="assets/screenshots/exported-student-details.png" alt="Exported Details" width="250"/><br/>
        <b>Student Details Export</b><br/>
        <sub>Complete data export</sub>
      </td>
    </tr>
  </table>
</div>

---

### 🎥 Promo Video

<div align="center">
  <a href="https://youtu.be/3fHwCYnB2qk" target="_blank">
    <img src="https://img.youtube.com/vi/3fHwCYnB2qk/maxresdefault.jpg" alt="EduTrack Promo Video" width="600"/>
  </a>
  
  <p><b>📹 Click the video above to watch the full app demonstration!</b></p>
  <p><sub>See EduTrack in action with all features showcased</sub></p>
</div>

---

## 🌐 Deployment

**Platforms**: ✅ Android • iOS (Mac required) • Web • Windows • macOS

**Hosting**:
- Flutter App → Google Play, App Store, or direct APK
- Admin Portal → Vercel, Netlify, Firebase Hosting
- WhatsApp Bot → Render.com Free Tier ($0/month) + cron-job.org + Firebase Storage

---

## 🤝 Contributing

Contributions welcome! Fork → Create feature branch → Commit → Push → Open PR

**Guidelines**: Follow [Effective Dart](https://dart.dev/guides/language/effective-dart/style) • Use GetX patterns • Test on multiple platforms • Update docs

**Commit format**: `feat:` `fix:` `docs:` `refactor:` `test:` `chore:`

**Priority areas**: Bug fixes • iOS testing • Screenshots • Documentation • i18n • Accessibility

See [`.github/copilot-instructions.md`](.github/copilot-instructions.md) for development guide.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.


---

## 🆘 Support

**Contact**: Mishaf Hasan • mishaf1106@gmail.com

**Issues**: [GitHub Issues](https://github.com/mind-flayers/edu-track/issues) - Include component, platform, steps to reproduce

**Help**: Check docs → Search existing issues → Create new issue → Email support

---

## 🔮 Roadmap

**v1.0.0 (Current)**: Flutter app • Admin portal • WhatsApp bot • QR attendance • Payment tracking • Exam management • Multi-tenant architecture

**Planned**: Push notifications • Student/Parent apps • SMS integration • Timetable • Offline mode • Multi-language • Library management • Assignment tracking • Financial reports

**Future**: AI predictions • LMS integration • Virtual classroom • Biometric attendance

---

## ❓ FAQ

**Q: Do I need all three components?**  
Flutter app is minimum. Add portal for bulk imports. Add bot for WhatsApp notifications.

**Q: Is it free?**  
Yes! MIT license. Firebase/Cloudinary have free tiers. Bot runs free on Render.com.

**Q: Platforms supported?**  
Android, iOS (Mac needed), Web, Windows, macOS

**Q: Multi-tenant how?**  
All data scoped under `admins/{adminUid}` - complete isolation per academy.

**Q: WhatsApp bot cost?**  
$0/month on Render.com free tier with cron-job.org keep-alive and Firebase Storage for session persistence.

**Q: Customize branding?**  
Yes - update `lib/app/utils/constants.dart` and assets/images/

**Troubleshooting**: Check component-specific READMEs • Search [GitHub Issues](https://github.com/mind-flayers/edu-track/issues) • Email: mishafhasan@gmail.com

---

## 🔒 Security

**Firebase**: Configure Firestore rules • All operations require authentication • API keys are safe for client-side

**Secrets**: Never commit `.env.local`, `service-account-key.json`, or `google-services.json`

**Bot**: Use Helmet/CORS • Secure QR authentication • Use environment variables for secrets on Render.com

See [`admin-portal/SECURITY.md`](admin-portal/SECURITY.md) for details.

---

## 🙏 Acknowledgments

**Technologies**: Flutter • Firebase • GetX • Next.js • Baileys • Cloudinary • Render.com

**Libraries**: FL Chart • Mobile Scanner • QR Flutter • Excel • PDF • Express • PM2 • Tailwind CSS • And many more

**Community**: Stack Overflow • GitHub contributors • Reddit r/FlutterDev

---

## 📄 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

**Key Points**:
- ✅ Free to use for personal and commercial projects
- ✅ Can modify and distribute
- ✅ Must include original license and copyright notice
- ❌ No warranty provided

---

## 👨‍💻 About the Developer

**Mishaf Hasan** - Full Stack Developer

Specializing in:
- Flutter mobile app development
- Firebase backend architecture
- Next.js web applications
- WhatsApp bot automation
- Educational technology solutions

**Contact**: mishafhasan@gmail.com

---

## 🌟 Show Your Support

If you find EduTrack helpful, please consider:
- ⭐ **Star this repository** on GitHub
- 🍴 **Fork** and contribute improvements
- 🐛 **Report bugs** to help us improve
- 💡 **Suggest features** you'd like to see
- 📢 **Share** with others who might benefit
- 💬 **Provide feedback** on your experience

---

<div align="center">
  <h3>Made with ❤️ for Educational Institutions</h3>
  <p>Empowering academies with modern technology</p>
  <p>
    <a href="https://github.com/mind-flayers/edu-track">⭐ Star on GitHub</a> •
    <a href="https://github.com/mind-flayers/edu-track/issues">🐛 Report Bug</a> •
    <a href="https://github.com/mind-flayers/edu-track/issues">💡 Request Feature</a>
  </p>
  <p><sub>© 2025 Mishaf Hasan. All rights reserved.</sub></p>
</div>