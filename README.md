
# Edu-Track 📚📱

Edu-Track is a clean and modern **admin-only mobile application** built with **Flutter**, **Firebase**, and **Cloudinary**. It is designed to manage student and teacher data for small academies or institutions. The app includes powerful features like:

- QR code-based student attendance and payments
- Firebase Authentication and Firestore Database
- Cloudinary for photo uploads and QR image storage
- SMS notifications to parents
- Export data to Excel or PDF
- Role-specific profile management

---

## 🚀 Features

- 🔐 **Admin Login**
- 🧑‍🎓 **Student Management**
  - Add, edit, and view student details
  - View attendance and payment history
  - Generate and download student QR codes
- 🧑‍🏫 **Teacher Management**
  - Add, edit, and view teacher details
- 📅 **Attendance Tracking**
  - QR code scanning or manual attendance
  - Auto-send SMS alerts to parents
- 💸 **Payments Tracking**
  - Record and verify payments via QR
  - Export monthly/yearly reports
- 🧪 **Exam Result Management**
  - Add exam results with graphs
- 📤 **Media Storage**
  - Cloudinary used to upload and manage profile pictures and QR codes
- 🛠️ **Settings**
  - Manage admin profile and SMS gateway token

---

## 🧰 Tech Stack

- **Flutter** (UI & Logic)
- **Firebase**
  - Firebase Auth
  - Firestore (Database)
  - Firebase Cloud Functions (optional for SMS trigger)
- **Cloudinary** (Images & QR code storage)
- **Traccer SMS Gateway** (SMS notifications)
- **Excel Export Libraries**

---

## 📁 Project Structure (Simplified)

```
lib/
├── main.dart
├── firebase_options.dart
└── app/
    ├── features/
    │   ├── attendance/
    │   ├── authentication/
    │   ├── dashboard/
    │   ├── profile/
    │   ├── qr_scanner/
    │   ├── students/
    │   └── teachers/
    └── utils/
        ├── constants.dart
        └── firestore_setup.dart
```

---

## 🔐 Firebase Setup

- Enable **Firebase Authentication**
- Create Firestore collections:
  - `students`, `teachers`, `attendance`, `payments`, `results`
- Set up Firebase Storage (if used in addition to Cloudinary)

---

## ☁️ Cloudinary Setup

- Create a [Cloudinary account](https://cloudinary.com/)
- Get your **Cloud Name**, **API Key**, and **API Secret**
- Create separate folders for:
  - `profile_pictures/`
  - `student_qrcodes/`
- Use signed upload for user image uploads

---

## 📦 Installation

```bash
git clone https://github.com/your-username/edu-track.git
cd edu-track
flutter pub get
flutter run
```

---

## 🧪 Coming Soon (Planned)

- Multi-academy support
- Web admin panel (Flutter Web)
- Local notifications for reminders
- Advanced filtering and analytics
- App for student or parents

---

## 🙌 Contributing

This project is private and currently under development by a single developer. Future contributions will be open upon initial release.

---

## 📝 License

This project is licensed under the MIT License.

---

## 📬 Contact

For queries or collaboration, email: **mishaf1106@gmail.com**
