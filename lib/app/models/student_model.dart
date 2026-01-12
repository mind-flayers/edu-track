import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class Student {
  final String id;
  final String name;
  final String indexNumber;
  final String className; // 'class' is a reserved keyword
  final String section;
  final String parentName;
  final String parentPhone;
  final String whatsappNumber; // Parent's WhatsApp number
  final String? photoUrl;
  final String sex;
  final String dob;
  final List<String> subjects; // Assuming 'SubjectsChoosed' is the field name
  final String qrCodeData;
  final bool isNonePayee; // ✅ NEW: None payee flag
  final double? averageScoreValue; // ✅ NEW: Store calculated average score

  Student({
    required this.id,
    required this.name,
    required this.indexNumber,
    required this.className,
    required this.section,
    required this.parentName,
    required this.parentPhone,
    required this.whatsappNumber,
    this.photoUrl,
    required this.sex,
    required this.dob,
    required this.subjects,
    required this.qrCodeData,
    this.isNonePayee = false, // ✅ Default to false for backward compatibility
    this.averageScoreValue, // ✅ NEW: Optional calculated average score
  });

  factory Student.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Defensively handle dob field type
    String dobValue;
    if (data['dob'] is Timestamp) {
      // Format Timestamp to String if it is one
      dobValue =
          DateFormat('yyyy-MM-dd').format((data['dob'] as Timestamp).toDate());
    } else {
      // Otherwise, treat as String or default to 'N/A'
      dobValue = data['dob']?.toString() ?? 'N/A';
    }

    return Student(
      id: doc.id,
      name: data['name'] ?? 'N/A',
      indexNumber: data['indexNumber'] ?? 'N/A',
      className: data['class'] ?? 'N/A', // Map 'class' field
      section: data['section'] ?? 'N/A',
      parentName: data['parentName'] ?? 'N/A',
      parentPhone: data['parentPhone'] ?? 'N/A',
      whatsappNumber: data['whatsappNumber'] ??
          data['parentPhone'] ??
          'N/A', // Use whatsappNumber field, fallback to parentPhone
      photoUrl: data['photoUrl'],
      sex: data['sex'] ?? 'N/A', // Assuming 'sex' is consistently String
      dob: dobValue, // Use the processed value
      subjects: List<String>.from(
          data['Subjects'] ?? []), // Map 'Subjects' (capital S)
      qrCodeData: data['qrCodeData'] ?? '',
      isNonePayee: data['isNonePayee'] ??
          false, // ✅ Handle isNonePayee field with backward compatibility
      averageScoreValue:
          null, // ✅ Will be calculated after fetching exam results
    );
  }

  // ✅ FIXED: Calculate average score based on actual exam results data
  String get averageScore {
    if (averageScoreValue == null) {
      return 'N/A'; // No exam results available
    }
    return '${averageScoreValue!.toStringAsFixed(1)}%';
  }

  String get grade => className.split(' ').last; // Extract grade number

  // ✅ NEW: Create a copy of the student with updated average score
  Student copyWith({double? averageScoreValue}) {
    return Student(
      id: id,
      name: name,
      indexNumber: indexNumber,
      className: className,
      section: section,
      parentName: parentName,
      parentPhone: parentPhone,
      whatsappNumber: whatsappNumber,
      photoUrl: photoUrl,
      sex: sex,
      dob: dob,
      subjects: subjects,
      qrCodeData: qrCodeData,
      isNonePayee: isNonePayee,
      averageScoreValue: averageScoreValue ?? this.averageScoreValue,
    );
  }
}
