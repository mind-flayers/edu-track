
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode

// --- IMPORTANT ---
// Run this function ONCE to initialize Firestore with dummy data.
// Call it from a temporary button or from main() during development.
// REMOVE the call after the database is set up.
// --- IMPORTANT ---

/// Generates a student index number based on the pattern:
/// MEC/Last_two_digits_of_the_year/Class+Section/Row_number
/// 
/// Example: MEC/25/10A/01
String generateIndexNumber({
  required int year,
  required String className,
  required String section,
  required int rowNumber,
}) {
  // Extract last two digits of the year
  final yearSuffix = (year % 100).toString().padLeft(2, '0');
  
  // Remove "Grade " prefix if present and combine class with section
  final classCode = className.replaceAll('Grade ', '') + section;
  
  // Format row number with leading zeros
  final formattedRowNumber = rowNumber.toString().padLeft(2, '0');
  
  // Combine all parts to form the index number
  return 'MEC/$yearSuffix/$classCode/$formattedRowNumber';
}

Future<void> setupFirestoreDatabase() async {
  if (!kDebugMode) {
    print("Firestore setup should only run in debug mode.");
    return;
  }

  final firestore = FirebaseFirestore.instance;
  final adminUid = 'AzzSlxVmw8UkwfJUjemxqcqQaJX2'; // Your Admin UID
  final now = Timestamp.now();
  final currentYear = DateTime.now().year;

  // Use batch writes for efficiency
  final batch = firestore.batch();

  // --- 1. Admin ---
  final adminRef = firestore.collection('admins').doc(adminUid);
  batch.set(adminRef, {
    'name': 'Admin User',
    'academyName' : 'My Academy',
    'email': 'mishaf1106@gmail.com', // Replace with your actual admin email if needed
    'profilePhotoUrl': 'https://res.cloudinary.com/duckxlzaj/image/upload/v1744864635/profiles/students/vm6bgpeg4ccvy58nig6r.jpg',
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
    'subjects': ['Mathematics', 'Science', 'English', 'History', 'Tamil', 'Geography', 'Art', 'PTS', 'Art', 'Civics'],
  });
  final term2Ref = firestore.collection('examTerms').doc();
  batch.set(term2Ref, {
    'name': 'Term 2 - 2025',
    'startDate': Timestamp.fromDate(DateTime(2025, 5, 15)),
    'endDate': Timestamp.fromDate(DateTime(2025, 8, 15)),
    'subjects': ['Mathematics', 'Science', 'English', 'History', 'Tamil', 'Geography', 'Art', 'PTS', 'Art', 'Civics'],
  });
  final term3Ref = firestore.collection('examTerms').doc();
  batch.set(term3Ref, {
    'name': 'Term 3 - 2025',
    'startDate': Timestamp.fromDate(DateTime(2025, 9, 15)),
    'endDate': Timestamp.fromDate(DateTime(2025, 12, 15)),
    'subjects': ['Mathematics', 'Science', 'English', 'History', 'Tamil', 'Geography', 'Art', 'PTS', 'Art', 'Civics'],
  });
  print("Exam Terms documents prepared.");

  // --- 4. Teachers ---
  final teacher1Ref = firestore.collection('teachers').doc();
  batch.set(teacher1Ref, {
    'name': 'Dr. Smith',
    'email': 'dr.smith@example.com',
    'phoneNumber': '9876543210',
    'whatsappNumber': '9876543210',
    'subject': 'Mathematics',
    'classAssigned': ['Grade 10', 'Grade 11'],
    'joinedAt': now,
    'isActive': true,
  });
  final teacher2Ref = firestore.collection('teachers').doc();
  batch.set(teacher2Ref, {
    'name': 'Ms. Johnson',
    'email': 'ms.johnson@example.com',
    'phone': '9876543211',
    'whatsappNumber': '9876543210',
    'subject': 'Science',
    'classAssigned': ['Grade 9', 'Grade 10'],
    'joinedAt': now,
    'isActive': true,
  });
  print("Teachers documents prepared.");

  // --- 5. Students (with subcollections) ---
  // Student 1
  final student1Id = 'STUDENT_${DateTime.now().millisecondsSinceEpoch}_1';
  final student1Ref = firestore.collection('students').doc(student1Id);
  final student1Class = 'Grade 10';
  final student1Section = 'A';
  batch.set(student1Ref, {
    'name': 'Mishaf Hasan',
    'class': student1Class,
    'Subjects': ['Mathematics', 'Science'],
    'section': student1Section,
    'indexNumber': generateIndexNumber(
      year: 2025,
      className: student1Class,
      section: student1Section,
      rowNumber: 1,
    ),
    'parentName': 'Mr. Hasan',
    'parentPhone': '1112223330',
    'whatsappNumber': '1112223330',
    'address': '123 Main St, City',
    'photoUrl': 'https://res.cloudinary.com/duckxlzaj/image/upload/v1744864148/profiles/students/hwwlnj3kup73zfx7unzu.jpg',
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
    'paid': true,
    'paidAt': Timestamp.fromDate(DateTime(2025, 3, 10)),
    'paymentMethod': 'Cash',
    'markedBy': adminUid,
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
  final student2Class = 'Grade 9';
  final student2Section = 'A';
  batch.set(student2Ref, {
    'name': 'Emily Smith',
    'email': 'emily@example.com',
    'class': student2Class,
    'Subjects': ['Mathematics', 'Science', 'English'],
    'section': student2Section,
    'indexNumber': generateIndexNumber(
      year: 2025,
      className: student2Class,
      section: student2Section,
      rowNumber: 5,
    ),
    'parentName': 'Mrs. Smith',
    'parentPhone': '1112223331',
    'whatsappNumber': '1112223330',
    'address': '456 Oak Ave, Town',
    'photoUrl': 'https://res.cloudinary.com/duckxlzaj/image/upload/v1744864148/profiles/students/hwwlnj3kup73zfx7unzu.jpg',
    'qrCodeData': student2Id,
    'joinedAt': now,
    'isActive': true,
  });
  // Student 2 - Attendance
  batch.set(student2Ref.collection('attendance').doc(), {
    'date': '2025-04-13',
    'status': 'present',
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
    'paidAt': Timestamp.fromDate(DateTime(2025, 3, 10)),
    'paymentMethod': 'Cash',
    'markedBy': adminUid,
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
    'studentsPresent': [student1Id],
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
