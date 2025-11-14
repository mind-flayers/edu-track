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

**WhatsApp Bot**: Automated parent notifications • Message queue • Delivery tracking • Auto-retry • Free Oracle Cloud hosting

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

See [`DEPLOYMENT_GUIDE.md`](DEPLOYMENT_GUIDE.md) for complete instructions.

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

**Deploy**: Free 24/7 hosting on Oracle Cloud. See [`ORACLE_CLOUD_DEPLOYMENT_GUIDE.md`](whatsapp-edutrack-bot/ORACLE_CLOUD_DEPLOYMENT_GUIDE.md)

See [`whatsapp-edutrack-bot/README.md`](whatsapp-edutrack-bot/README.md) for details.

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

**Demo video coming soon!** App is fully functional with: Dashboard • Student/Teacher management • QR attendance • Exam results • Fee tracking • Admin portal • WhatsApp integration

---

## 🌐 Deployment

**Platforms**: ✅ Android • iOS (Mac required) • Web • Windows • macOS

**Hosting**:
- Flutter App → Google Play, App Store, or direct APK
- Admin Portal → Vercel, Netlify, Firebase Hosting
- WhatsApp Bot → Oracle Cloud Free Tier ($0/month)

See [`DEPLOYMENT_GUIDE.md`](DEPLOYMENT_GUIDE.md) for complete instructions.

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

## 📚 Documentation

**Components**: [`DEPLOYMENT_GUIDE.md`](DEPLOYMENT_GUIDE.md) • [`admin-portal/README.md`](admin-portal/README.md) • [`whatsapp-edutrack-bot/README.md`](whatsapp-edutrack-bot/README.md) • [`db/database_structure.md`](db/database_structure.md)

**Deployment**: [`ORACLE_CLOUD_DEPLOYMENT_GUIDE.md`](whatsapp-edutrack-bot/ORACLE_CLOUD_DEPLOYMENT_GUIDE.md) • [`QUICK_START_ORACLE.md`](whatsapp-edutrack-bot/QUICK_START_ORACLE.md)

**Security**: [`admin-portal/SECURITY.md`](admin-portal/SECURITY.md)

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
Yes! MIT license. Firebase/Cloudinary have free tiers. Bot runs free on Oracle Cloud.

**Q: Platforms supported?**  
Android, iOS (Mac needed), Web, Windows, macOS

**Q: Multi-tenant how?**  
All data scoped under `admins/{adminUid}` - complete isolation per academy.

**Q: WhatsApp bot cost?**  
$0/month on Oracle Cloud Free Tier (24/7)

**Q: Customize branding?**  
Yes - update `lib/app/utils/constants.dart` and assets/images/

**Troubleshooting**: Check component-specific READMEs • Search [GitHub Issues](https://github.com/mind-flayers/edu-track/issues) • Email: mishaf1106@gmail.com

---

## 🔒 Security

**Firebase**: Configure Firestore rules • All operations require authentication • API keys are safe for client-side

**Secrets**: Never commit `.env.local`, `service-account-key.json`, or `google-services.json`

**Bot**: Use Helmet/CORS • Secure QR authentication • Follow Oracle Cloud security practices

See [`admin-portal/SECURITY.md`](admin-portal/SECURITY.md) for details.

---

## 🙏 Acknowledgments

**Technologies**: Flutter • Firebase • GetX • Next.js • Baileys • Cloudinary • Oracle Cloud

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

**Contact**: mishaf1106@gmail.com

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