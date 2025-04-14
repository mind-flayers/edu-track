import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode

// --- IMPORTANT ---
// Run this function ONCE to initialize Firestore with dummy data.
// Call it from a temporary button or from main() during development.
// REMOVE the call after the database is set up.
// --- IMPORTANT ---

Future<void> setupFirestoreDatabase() async {
  if (!kDebugMode) {
    print("Firestore setup should only run in debug mode.");
    return;
  }

  final firestore = FirebaseFirestore.instance;
  final adminUid = 'AzzSlxVmw8UkwfJUjemxqcqQaJX2'; // Your Admin UID
  final now = Timestamp.now();

  // Use batch writes for efficiency
  final batch = firestore.batch();

  // --- 1. Admin ---
  final adminRef = firestore.collection('admins').doc(adminUid);
  batch.set(adminRef, {
    'name': 'Admin User',
    'email': 'admin@example.com', // Replace with your actual admin email if needed
    'profilePhotoUrl': 'https://via.placeholder.com/150',
    'smsGatewayToken': 'YOUR_INITIAL_SMS_TOKEN', // Replace with actual token later
    'createdAt': now,
    'updatedAt': now,
  });
  print("Admin document prepared.");

  // --- 2. Settings ---
  final settingsRef = firestore.collection('settings').doc('general');
  batch.set(settingsRef, {
    'academyName': 'My Academy',
    'logoUrl': 'assets/images/app_logo.png', // Example path
    'contactEmail': 'contact@myacademy.com',
    'contactPhone': '+1234567890',
  });
  print("Settings document prepared.");

  // --- 3. Exam Terms ---
  final term1Ref = firestore.collection('examTerms').doc();
  batch.set(term1Ref, {
    'name': 'Term 1 - 2025',
    'startDate': Timestamp.fromDate(DateTime(2025, 1, 15)),
    'endDate': Timestamp.fromDate(DateTime(2025, 4, 15)),
    'subjects': ['Mathematics', 'Science', 'English', 'History'],
  });
  final term2Ref = firestore.collection('examTerms').doc();
  batch.set(term2Ref, {
    'name': 'Term 2 - 2025',
    'startDate': Timestamp.fromDate(DateTime(2025, 5, 15)),
    'endDate': Timestamp.fromDate(DateTime(2025, 8, 15)),
    'subjects': ['Mathematics', 'Science', 'Geography', 'Art'],
  });
  print("Exam Terms documents prepared.");

  // --- 4. Teachers ---
  final teacher1Ref = firestore.collection('teachers').doc();
  batch.set(teacher1Ref, {
    'name': 'Dr. Smith',
    'email': 'dr.smith@example.com',
    'phone': '9876543210',
    'subject': 'Mathematics',
    'classAssigned': ['Grade 10', 'Grade 11'],
    'photoUrl': 'https://via.placeholder.com/100',
    'joinedAt': now,
    'isActive': true,
  });
  final teacher2Ref = firestore.collection('teachers').doc();
  batch.set(teacher2Ref, {
    'name': 'Ms. Johnson',
    'email': 'ms.johnson@example.com',
    'phone': '9876543211',
    'subject': 'Science',
    'classAssigned': ['Grade 9', 'Grade 10'],
    'photoUrl': 'https://via.placeholder.com/100',
    'joinedAt': now,
    'isActive': true,
  });
  print("Teachers documents prepared.");

  // --- 5. Students (with subcollections) ---
  // Student 1
  final student1Id = 'STUDENT_${DateTime.now().millisecondsSinceEpoch}_1';
  final student1Ref = firestore.collection('students').doc(student1Id);
  batch.set(student1Ref, {
    'name': 'Mishaf Hasan',
    'email': 'mishaf@example.com',
    'class': 'Grade 10',
    'section': 'A',
    'rollNumber': '10A01',
    'parentName': 'Mr. Hasan',
    'parentPhone': '1112223330',
    'address': '123 Main St, City',
    'photoUrl': 'https://via.placeholder.com/150/1',
    'qrCodeData': student1Id, // Use doc ID as unique QR data
    'joinedAt': now,
    'isActive': true,
  });
  // Student 1 - Attendance
  batch.set(student1Ref.collection('attendance').doc(), {
    'date': '2025-04-13',
    'status': 'present',
    'markedBy': adminUid,
    'markedAt': now,
  });
  // Student 1 - Fees
  batch.set(student1Ref.collection('fees').doc(), {
    'year': 2025,
    'month': 3, // March
    'amount': 500,
    'paid': true,
    'paidAt': Timestamp.fromDate(DateTime(2025, 3, 10)),
    'paymentMethod': 'Cash',
    'markedBy': adminUid,
  });
  batch.set(student1Ref.collection('fees').doc(), {
    'year': 2025,
    'month': 4, // April
    'amount': 500,
    'paid': false,
    'paidAt': null,
    'paymentMethod': null,
    'markedBy': null,
  });
  // Student 1 - Exam Results
  batch.set(student1Ref.collection('examResults').doc(), {
    'term': term1Ref.id, // Link to Term 1
    'subject': 'Mathematics',
    'marks': 85,
    'maxMarks': 100,
    'resultDate': now,
    'updatedBy': adminUid,
  });
   batch.set(student1Ref.collection('examResults').doc(), {
    'term': term1Ref.id, // Link to Term 1
    'subject': 'Science',
    'marks': 92,
    'maxMarks': 100,
    'resultDate': now,
    'updatedBy': adminUid,
  });


  // Student 2
  final student2Id = 'STUDENT_${DateTime.now().millisecondsSinceEpoch}_2';
  final student2Ref = firestore.collection('students').doc(student2Id);
  batch.set(student2Ref, {
    'name': 'Emily Smith',
    'email': 'emily@example.com',
    'class': 'Grade 9',
    'section': 'B',
    'rollNumber': '09B05',
    'parentName': 'Mrs. Smith',
    'parentPhone': '1112223331',
    'address': '456 Oak Ave, Town',
    'photoUrl': 'https://via.placeholder.com/150/2',
    'qrCodeData': student2Id,
    'joinedAt': now,
    'isActive': true,
  });
   // Student 2 - Attendance
  batch.set(student2Ref.collection('attendance').doc(), {
    'date': '2025-04-13',
    'status': 'absent',
    'markedBy': adminUid,
    'markedAt': now,
  });
  // Student 2 - Fees
  batch.set(student2Ref.collection('fees').doc(), {
    'year': 2025,
    'month': 3, // March
    'amount': 450,
    'paid': true,
    'paidAt': Timestamp.fromDate(DateTime(2025, 3, 11)),
    'paymentMethod': 'Online',
    'markedBy': adminUid,
  });
   batch.set(student2Ref.collection('fees').doc(), {
    'year': 2025,
    'month': 4, // April
    'amount': 450,
    'paid': false,
    'paidAt': null,
    'paymentMethod': null,
    'markedBy': null,
  });
   // Student 2 - Exam Results (Default 0)
  batch.set(student2Ref.collection('examResults').doc(), {
    'term': term1Ref.id, // Link to Term 1
    'subject': 'Mathematics',
    'marks': 0, // Default
    'maxMarks': 100,
    'resultDate': now,
    'updatedBy': adminUid,
  });

  print("Students documents and subcollections prepared.");

  // --- 6. Attendance Summary (Example for one day) ---
  final summaryDate = '2025-04-13'; // Match attendance date above
  final summaryRef = firestore.collection('attendanceSummary').doc(summaryDate);
  batch.set(summaryRef, {
      'class': 'Overall', // Or specific class if needed
      'present': 1,
      'absent': 1,
      'total': 2,
      'studentsPresent': [student1Id],
      'studentsAbsent': [student2Id],
      'markedBy': adminUid,
      'markedAt': now,
  });
   print("Attendance Summary document prepared.");


  // --- Commit Batch ---
  try {
    await batch.commit();
    print("Firestore database setup complete with dummy data!");
  } catch (e) {
    print("Error setting up Firestore database: $e");
  }
}