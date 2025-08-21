import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edu_track/app/features/authentication/controllers/auth_controller.dart'; // Added
import 'package:edu_track/app/utils/constants.dart';
import 'package:edu_track/main.dart'; // Import main for AppRoutes
import 'package:get/get.dart'; // Import GetX
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:saver_gallery/saver_gallery.dart';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart'
    hide TextSpan, Border; // Hide Border from excel package
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:share_plus/share_plus.dart'; // Added share_plus
import 'package:pdf/widgets.dart' as pw; // PDF generation
import 'package:pdf/pdf.dart' as pdf_core; // PDF page format
import 'package:printing/printing.dart'; // PDF sharing/printing
import 'package:flutter/services.dart'
    show rootBundle; // Needed for font loading

// TODO: Import necessary controllers/providers
// import 'package:edu_track/app/features/students/controllers/student_details_controller.dart';
// import 'package:edu_track/app/widgets/custom_app_bar.dart';

// Placeholder for Student data model (adapt based on actual implementation)
class Student {
  final String id;
  final String name;
  final String email;
  final String className; // e.g., "Grade 10"
  final String section; // e.g., "A"
  final String indexNumber;
  final String parentName;
  final String parentPhone;
  final String? whatsappNumber;
  final String? address;
  final String? photoUrl;
  final String qrCodeData;
  final Timestamp joinedAt;
  final bool isActive;
  final String? sex; // Added sex
  final Timestamp? dob; // Added Date of Birth (as Timestamp)
  final List<String> subjectsChoosed; // Added subjects chosen by the student

  Student({
    required this.id,
    required this.name,
    required this.email,
    required this.className,
    required this.section,
    required this.indexNumber,
    required this.parentName,
    required this.parentPhone,
    this.whatsappNumber,
    this.address,
    this.photoUrl,
    required this.qrCodeData,
    required this.joinedAt,
    required this.isActive,
    this.sex, // Added
    this.dob, // Added
    required this.subjectsChoosed, // Added
  });

  factory Student.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    // Explicitly handle null before passing to List.from
    // Check for both field names since database structure shows 'Subjects'
    var subjectsData = data['Subjects'] ?? data['subjectsChoosed'];
    List<String> chosenSubjects = (subjectsData == null)
        ? [] // Provide an empty list if null
        : List<String>.from(subjectsData); // Cast if not null

    return Student(
      id: doc.id,
      name: data['name'] ?? 'N/A',
      email: data['email'] ?? 'N/A',
      className: data['class'] ?? 'N/A',
      section: data['section'] ?? 'N/A',
      indexNumber: data['indexNumber'] ?? 'N/A',
      parentName: data['parentName'] ?? 'N/A',
      parentPhone: data['parentPhone'] ?? 'N/A',
      whatsappNumber: data['whatsappNumber'],
      address: data['address'],
      photoUrl: data['photoUrl'],
      qrCodeData: data['qrCodeData'] ?? doc.id, // Fallback to doc ID
      joinedAt: data['joinedAt'] ?? Timestamp.now(),
      isActive: data['isActive'] ?? true,
      sex: data['sex'], // Added
      dob: data['dob'], // Added
      subjectsChoosed: chosenSubjects, // Pass the safe list
    );
  }

  // Add helper getters if needed, e.g., for grade number
  String get grade => className.replaceAll('Grade ', '');
}

// Placeholder for Exam Result data model
class ExamResult {
  final String id;
  final String termId;
  final String subject;
  final double marks;
  final double maxMarks;
  // Add other fields if necessary

  ExamResult({
    required this.id,
    required this.termId,
    required this.subject,
    required this.marks,
    required this.maxMarks,
  });

  factory ExamResult.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return ExamResult(
      id: doc.id,
      termId: data['term'] ?? '',
      subject: data['subject'] ?? 'N/A',
      marks: (data['marks'] ?? 0.0).toDouble(),
      maxMarks: (data['maxMarks'] ?? 100.0).toDouble(),
    );
  }
}

// Placeholder for Fee data model
class FeeRecord {
  final String id;
  final int year;
  final int month;
  final double amount;
  final bool paid;
  final Timestamp? paidAt;

  FeeRecord({
    required this.id,
    required this.year,
    required this.month,
    required this.amount,
    required this.paid,
    this.paidAt,
  });

  factory FeeRecord.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return FeeRecord(
      id: doc.id,
      year: data['year'] ?? DateTime.now().year,
      month: data['month'] ?? 0,
      amount: (data['amount'] ?? 0.0).toDouble(),
      paid: data['paid'] ?? false,
      paidAt: data['paidAt'],
    );
  }

  String get monthName => DateFormat('MMMM').format(DateTime(year, month));
}

// Placeholder for Attendance Record data model
class AttendanceRecord {
  final String id;
  final String date; // YYYY-MM-DD format
  final String status; // 'present' or 'absent'
  final String?
      subject; // Subject for which attendance was marked (if applicable)
  final Timestamp markedAt;

  AttendanceRecord({
    required this.id,
    required this.date,
    required this.status,
    this.subject,
    required this.markedAt,
  });

  factory AttendanceRecord.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return AttendanceRecord(
      id: doc.id,
      date: data['date'] ?? '',
      status: data['status'] ?? 'absent',
      subject: data['subject'], // May be null for overall attendance
      markedAt: data['markedAt'] ?? Timestamp.now(),
    );
  }

  // Extract month from date
  int get month {
    try {
      final parts = date.split('-');
      if (parts.length >= 2) {
        return int.parse(parts[1]);
      }
      return DateTime.now().month;
    } catch (e) {
      return DateTime.now().month;
    }
  }

  // Extract year from date
  int get year {
    try {
      final parts = date.split('-');
      if (parts.isNotEmpty) {
        return int.parse(parts[0]);
      }
      return DateTime.now().year;
    } catch (e) {
      return DateTime.now().year;
    }
  }

  String get monthName => DateFormat('MMMM').format(DateTime(year, month));
}

// Placeholder for Exam Term data model
class ExamTerm {
  final String id;
  final String name;
  final List<String> subjects;
  // Add start/end dates if needed

  ExamTerm({required this.id, required this.name, required this.subjects});

  factory ExamTerm.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return ExamTerm(
      id: doc.id,
      name: data['name'] ?? 'N/A',
      subjects: List<String>.from(data['subjects'] ?? []),
    );
  }

  // Extract year and term name for filtering
  String get year => name.split(' - ').last;
  String get termOnlyName => name.split(' - ').first;
}

// --- Student Details Screen ---
class StudentDetailsScreen extends StatefulWidget {
  // Changed from ConsumerStatefulWidget
  final String studentId;

  const StudentDetailsScreen(
      {super.key, required this.studentId}); // Use super.key

  @override
  State<StudentDetailsScreen> createState() =>
      _StudentDetailsScreenState(); // Changed return type
}

class _StudentDetailsScreenState extends State<StudentDetailsScreen> {
  // Changed from ConsumerState
  final GlobalKey _qrCodeKey = GlobalKey();
  String? _selectedExamYear;
  String? _selectedExamTermId;
  String? _selectedFeeYear;
  String? _selectedAttendanceMonth; // For attendance filtering
  String? _selectedAttendanceYear; // For attendance filtering
  String? _selectedAttendanceSubject; // For attendance filtering
  bool _isCapturingQr = false; // State variable for QR capture visibility
  String? _statusMessage;
  bool _isErrorStatus = false;
  final _formKeyStudentEdit = GlobalKey<FormState>(); // For student edit dialog
  String? _academyName; // To store fetched academy name

  // TODO: Replace with Riverpod providers for data fetching and state management
  late Future<Student> _studentFuture;
  late Future<List<ExamTerm>> _examTermsFuture;
  late Future<List<ExamResult>> _examResultsFuture;
  late Future<List<FeeRecord>> _feesFuture;
  late Future<List<AttendanceRecord>> _attendanceFuture;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    final String? adminUid = AuthController.instance.user?.uid;
    if (adminUid == null) {
      print("Error: Admin UID is null. Cannot load student details.");
      // Set futures to completed with an error or empty data to prevent hangs
      setState(() {
        _studentFuture = Future.error("Admin not logged in");
        _examTermsFuture = Future.value([]);
        _examResultsFuture = Future.value([]);
        _feesFuture = Future.value([]);
        _attendanceFuture = Future.value([]);
      });
      // Optionally show a snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Could not verify admin.')),
        );
      }
      return;
    }

    // TODO: Replace with Riverpod logic
    final firestore = FirebaseFirestore.instance;
    final adminRef = firestore.collection('admins').doc(adminUid);

    // Fetch Admin Profile for Academy Name
    adminRef.collection('adminProfile').doc('profile').get().then((profileDoc) {
      if (profileDoc.exists && profileDoc.data() != null) {
        setState(() {
          _academyName = profileDoc.data()!['academyName'] as String?;
        });
      }
    }).catchError((error) {
      print("Error fetching admin profile for academy name: $error");
      // Handle error if needed, maybe show a default name or message
    });

    _studentFuture =
        adminRef.collection('students').doc(widget.studentId).get().then((doc) {
      if (!doc.exists)
        throw Exception("Student not found"); // Handle non-existent student
      return Student.fromFirestore(doc);
    });

    _examTermsFuture = adminRef // Fetch terms nested under admin
        .collection('examTerms')
        .get()
        .then((snapshot) =>
            snapshot.docs.map((doc) => ExamTerm.fromFirestore(doc)).toList());

    // Initial load for results and fees
    _examResultsFuture = _fetchExamResults(
        null); // Pass adminUid implicitly via _fetchExamResults
    _feesFuture = _fetchFees(null); // Pass adminUid implicitly via _fetchFees
    _attendanceFuture =
        _fetchAttendance(null, null); // Initial load for attendance

    // Set default filter values after terms/fees are loaded
    _examTermsFuture.then((terms) {
      if (terms.isNotEmpty) {
        final latestTerm =
            terms.last; // Assuming terms are ordered or find latest
        setState(() {
          _selectedExamYear = latestTerm.year;
          _selectedExamTermId = latestTerm.id;
          // Trigger reload of results for the default term
          _examResultsFuture = _fetchExamResults(_selectedExamTermId);
        });
      }
    });
    _feesFuture.then((fees) {
      if (fees.isNotEmpty) {
        final years = fees.map((f) => f.year.toString()).toSet().toList();
        years.sort((a, b) => b.compareTo(a)); // Sort descending
        setState(() {
          _selectedFeeYear = years.first;
          // Trigger reload of fees for the default year (already done in initial load)
        });
      } else {
        // Default to current year if no fees exist yet
        setState(() {
          _selectedFeeYear = DateTime.now().year.toString();
        });
      }
    });

    // Set default attendance values
    _attendanceFuture.then((attendance) {
      final years = attendance.map((a) => a.year.toString()).toSet().toList();
      years.sort((a, b) => b.compareTo(a)); // Sort descending
      final currentYearStr = DateTime.now().year.toString();
      if (!years.contains(currentYearStr)) {
        years.insert(0, currentYearStr);
      }

      setState(() {
        _selectedAttendanceYear =
            years.isNotEmpty ? years.first : currentYearStr;
        _selectedAttendanceMonth = DateTime.now().month.toString();
        _selectedAttendanceSubject = 'All Subjects';
        // Reload attendance with default selections
        _attendanceFuture =
            _fetchAttendance(_selectedAttendanceYear, _selectedAttendanceMonth);
      });
    });
  }

  // --- Data Fetching --- (To be replaced by Riverpod/Controller)
  Future<List<ExamResult>> _fetchExamResults(String? termId) async {
    final String? adminUid = AuthController.instance.user?.uid;
    if (adminUid == null) {
      print("Error: Admin UID is null. Cannot fetch exam results.");
      return []; // Return empty list if admin is not logged in
    }

    Query query = FirebaseFirestore.instance
        .collection('admins')
        .doc(adminUid)
        .collection('students')
        .doc(widget.studentId)
        .collection('examResults');

    if (termId != null) {
      query = query.where('term', isEqualTo: termId);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => ExamResult.fromFirestore(doc)).toList();
  }

  Future<List<FeeRecord>> _fetchFees(String? year) async {
    final String? adminUid = AuthController.instance.user?.uid;
    if (adminUid == null) {
      print("Error: Admin UID is null. Cannot fetch fees.");
      return []; // Return empty list if admin is not logged in
    }

    Query query = FirebaseFirestore.instance
        .collection('admins')
        .doc(adminUid)
        .collection('students')
        .doc(widget.studentId)
        .collection('fees');

    if (year != null) {
      final parsedYear = int.tryParse(year);
      if (parsedYear != null) {
        // Check if parsing was successful
        query = query.where('year', isEqualTo: parsedYear);
      } else {
        print("Warning: Invalid year format '$year' provided for fee filter.");
        // Decide how to handle invalid year - fetch all or none? Fetching all for now.
      }
    } else {
      // If no year selected, maybe fetch latest year's data or all?
      // For now, fetching all if year is null. Adjust as needed.
    }

    final snapshot = await query.orderBy('month').get(); // Order by month
    return snapshot.docs.map((doc) => FeeRecord.fromFirestore(doc)).toList();
  }

  Future<List<AttendanceRecord>> _fetchAttendance(
      String? year, String? month) async {
    final String? adminUid = AuthController.instance.user?.uid;
    if (adminUid == null) {
      print("Error: Admin UID is null. Cannot fetch attendance.");
      return []; // Return empty list if admin is not logged in
    }

    Query query = FirebaseFirestore.instance
        .collection('admins')
        .doc(adminUid)
        .collection('students')
        .doc(widget.studentId)
        .collection('attendance');

    // Filter by year and month if provided
    if (year != null && month != null) {
      // For date filtering, we need to filter by date string patterns
      final startDate = '$year-${month.padLeft(2, '0')}-01';
      final nextMonth = int.parse(month) == 12 ? 1 : int.parse(month) + 1;
      final nextYear =
          int.parse(month) == 12 ? int.parse(year) + 1 : int.parse(year);
      final endDate = '$nextYear-${nextMonth.toString().padLeft(2, '0')}-01';

      query = query
          .where('date', isGreaterThanOrEqualTo: startDate)
          .where('date', isLessThan: endDate);
    }

    final snapshot = await query
        .orderBy('date', descending: true)
        .get(); // Order by date descending
    return snapshot.docs
        .map((doc) => AttendanceRecord.fromFirestore(doc))
        .toList();
  }

  // --- UI Builders ---

  // Copied from StudentListScreen and adapted for constants
  Widget _buildProfileAvatar() {
    final String? userId = AuthController.instance.user?.uid;
    if (userId == null) {
      return IconButton(
        icon: Icon(Icons.account_circle_rounded,
            size: 30, color: kSecondaryColor), // Use constant
        tooltip: 'Profile Settings',
        onPressed: () =>
            Get.toNamed(AppRoutes.profileSettings), // Use Get.toNamed
      );
    }
    return StreamBuilder<DocumentSnapshot>(
      // Fetch the specific profile document within the adminProfile subcollection
      stream: FirebaseFirestore.instance
          .collection('admins')
          .doc(userId)
          .collection('adminProfile')
          .doc('profile') // Document ID is 'profile'
          .snapshots(),
      builder: (context, snapshot) {
        String? photoUrl;
        Widget profileWidget = Icon(Icons.account_circle_rounded,
            size: 30, color: kSecondaryColor); // Use constant

        if (snapshot.connectionState == ConnectionState.active &&
            snapshot.hasData &&
            snapshot.data!.exists) {
          var data = snapshot.data!.data() as Map<String, dynamic>?;
          // Use the correct field name from firestore_setup.js
          if (data != null && data.containsKey('profilePhotoUrl')) {
            photoUrl = data['profilePhotoUrl'] as String?;
          }
        } else if (snapshot.hasError) {
          print("Error fetching admin profile: ${snapshot.error}");
        }

        if (photoUrl != null && photoUrl.isNotEmpty) {
          profileWidget = CircleAvatar(
            radius: 18,
            backgroundColor: kSecondaryColor.withOpacity(0.5), // Use constant
            backgroundImage: NetworkImage(photoUrl),
            onBackgroundImageError: (exception, stackTrace) {
              print("Error loading profile image: $exception");
            },
          );
        }

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(kDefaultRadius * 2),
            onTap: () => Get.toNamed(AppRoutes
                .profileSettings), // Use Get.toNamed (Already correct here, but ensuring consistency)
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: kDefaultPadding, vertical: kDefaultPadding / 2),
              child: profileWidget,
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // Replicate AppBar from StudentListScreen using constants
    return AppBar(
      backgroundColor: kPrimaryColor, // Use theme color
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: kSecondaryColor), // Use constant
        tooltip: 'Back',
        onPressed: () => Navigator.pop(context),
      ),
      title: Text('Student Details',
          style: textTheme.titleLarge
              ?.copyWith(color: kSecondaryColor)), // Use constant
      centerTitle: true,
      actions: [
        // Share button for student details
        FutureBuilder<Student>(
            future: _studentFuture, // Ensure student data is loaded
            builder: (context, studentSnapshot) {
              if (studentSnapshot.hasData && studentSnapshot.data != null) {
                return IconButton(
                  icon: const Icon(Icons.share_rounded, color: kSecondaryColor),
                  tooltip: 'Share Student Details',
                  onPressed: () =>
                      _showStudentDetailsExportOptions(studentSnapshot.data!),
                );
              }
              return const SizedBox
                  .shrink(); // Don't show if student data not ready
            }),
        _buildProfileAvatar(), // Use the copied method
      ],
    );
  }

  // --- Status Message Widget (similar to AddTeacherScreen) ---
  Widget _buildStatusMessageWidget() {
    final textTheme = Theme.of(context).textTheme;
    return AnimatedOpacity(
      opacity: _statusMessage != null ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: _statusMessage == null
          ? const SizedBox.shrink()
          : Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: kDefaultPadding, vertical: kDefaultPadding * 0.6),
              margin: const EdgeInsets.only(
                  bottom: kDefaultPadding,
                  left: kDefaultPadding,
                  right: kDefaultPadding),
              decoration: BoxDecoration(
                color: _isErrorStatus
                    ? kErrorColor.withOpacity(0.1)
                    : kSuccessColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(kDefaultRadius),
                border: Border.all(
                    // This should now correctly refer to Flutter's Border
                    color: _isErrorStatus ? kErrorColor : kSuccessColor,
                    width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isErrorStatus
                        ? Icons.error_outline_rounded
                        : Icons.check_circle_outline_rounded,
                    color: _isErrorStatus ? kErrorColor : kSuccessColor,
                    size: 20,
                  ),
                  const SizedBox(width: kDefaultPadding / 2),
                  Expanded(
                    child: Text(
                      _statusMessage!,
                      style: textTheme.bodyMedium?.copyWith(
                        color: _isErrorStatus ? kErrorColor : kSuccessColor,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  void _showStatusFlashMessage(String message, {required bool isError}) {
    if (!mounted) return;
    setState(() {
      _statusMessage = message;
      _isErrorStatus = isError;
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _statusMessage = null;
        });
      }
    });
  }

  // Updated to accept exam results for calculations and match layout
  Widget _buildStudentInfoSection(
      Student student, List<ExamResult> currentResults) {
    final textTheme = Theme.of(context).textTheme;
    // Calculate subject count (using student's chosen subjects, not current results)
    int subjectCount = student.subjectsChoosed.length;

    // Define image size - adjust as needed based on visual preference
    const double imageSize = 130.0; // Slightly larger?

    // Use CardTheme from constants.dart by default, but override margin
    return Card(
      margin: const EdgeInsets.all(kDefaultPadding), // Use constant
      // elevation, shape, color will be taken from CardTheme in constants.dart
      child: Padding(
        padding: const EdgeInsets.all(kDefaultPadding), // Use constant
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Left Column: Text Details ---
                Expanded(
                  flex: 3, // Make left column narrower
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.name,
                        // Use textTheme from constants
                        style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold, color: kTextColor),
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow("Index No:", student.indexNumber),
                      _buildDetailRow("Grade:", student.grade),
                      _buildDetailRow("Subjects:", subjectCount.toString()),
                      _buildDetailRow("Sex:", student.sex ?? "N/A"),
                      _buildDetailRow(
                          "DOB:",
                          student.dob != null
                              ? DateFormat('yyyy/MM/dd')
                                  .format(student.dob!.toDate())
                              : "N/A"),
                      _buildDetailRow("Parent:", student.parentName),
                      _buildDetailRow("Contact:", student.parentPhone),
                      if (student.whatsappNumber != null &&
                          student.whatsappNumber!.isNotEmpty)
                        _buildDetailRow("WhatsApp:", student.whatsappNumber!),
                    ],
                  ),
                ),
                const SizedBox(width: kDefaultPadding), // Use constant
                // --- Right Column: Image and Buttons ---
                Expanded(
                  flex: 3, // Make right column wider
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: imageSize,
                        height: imageSize,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                              kDefaultRadius), // Use constant
                          child: CachedNetworkImage(
                            imageUrl: student.photoUrl ??
                                'https://via.placeholder.com/150',
                            placeholder: (context, url) => Container(
                                color: kDisabledColor.withOpacity(0.3),
                                child: const Center(
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2.0,
                                        color: kPrimaryColor))),
                            errorWidget: (context, url, error) => Container(
                                color: kDisabledColor.withOpacity(0.3),
                                child: Icon(Icons.person,
                                    size: 50, color: kLightTextColor)),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // --- Download Photo Button with Gradient ---
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              kPrimaryColor,
                              kPrimaryColor.withOpacity(0.8)
                            ], // Adjust gradient colors as needed
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius:
                              BorderRadius.circular(kDefaultRadius * 0.8),
                          boxShadow: [
                            // Optional: Add subtle shadow
                            BoxShadow(
                              color: kPrimaryColor.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.download_rounded,
                              size: 18,
                              color:
                                  kSecondaryColor), // Ensure icon color is white
                          label: Text("Download Photo",
                              style: textTheme.labelLarge?.copyWith(
                                  fontSize: 13,
                                  color:
                                      kSecondaryColor)), // Ensure text color is white
                          onPressed: () => _downloadStudentPhoto(
                              student.photoUrl, student.name),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Colors.transparent, // Make button transparent
                            shadowColor: Colors
                                .transparent, // Remove button's own shadow
                            elevation: 0, // Remove button's own elevation
                            padding: const EdgeInsets.symmetric(
                                vertical: 12), // Adjust padding if needed
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    kDefaultRadius * 0.8)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // --- Download QR Code Button with Gradient ---
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              kPrimaryColor,
                              kPrimaryColor.withOpacity(0.8)
                            ], // Adjust gradient colors as needed
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius:
                              BorderRadius.circular(kDefaultRadius * 0.8),
                          boxShadow: [
                            // Optional: Add subtle shadow
                            BoxShadow(
                              color: kPrimaryColor.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.qr_code_rounded,
                              size: 18,
                              color:
                                  kSecondaryColor), // Ensure icon color is white
                          label: Text("Download QR Code",
                              style: textTheme.labelLarge?.copyWith(
                                  fontSize: 13,
                                  color:
                                      kSecondaryColor)), // Ensure text color is white
                          onPressed: _isCapturingQr
                              ? null
                              : () => _downloadQrCode(
                                  student.name), // Disable while capturing
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Colors.transparent, // Make button transparent
                            shadowColor: Colors
                                .transparent, // Remove button's own shadow
                            elevation: 0, // Remove button's own elevation
                            padding: const EdgeInsets.symmetric(
                                vertical: 12), // Adjust padding if needed
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    kDefaultRadius * 0.8)),
                            // Handle disabled state appearance if needed
                            disabledBackgroundColor: Colors.transparent,
                            disabledForegroundColor:
                                kSecondaryColor.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: kDefaultPadding / 2),
            // Edit Student Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.edit_rounded, size: 18),
                label: const Text("Edit Student Details"),
                onPressed: () => _showEditStudentDetailsDialog(student),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      kPrimaryColor, // Changed kAccentColor to kPrimaryColor
                  foregroundColor: kSecondaryColor,
                ),
              ),
            ),
            const SizedBox(height: kDefaultPadding / 2),
            // Use Visibility instead of Offstage for QR capture
            Visibility(
              visible: _isCapturingQr,
              maintainState: true, // Keep state even when hidden
              child: RepaintBoundary(
                key: _qrCodeKey,
                child: Container(
                  margin: const EdgeInsets.only(
                      top: 10), // Add margin if needed when visible
                  color: Colors.white,
                  padding: const EdgeInsets.all(8.0),
                  child: QrImageView(
                    data: student.qrCodeData,
                    version: QrVersions.auto,
                    size: 200.0,
                    gapless: false,
                    // Use theme colors for QR code?
                    // eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: kTextColor),
                    // dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: kTextColor),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
          vertical: 3.0), // Slightly more vertical padding
      child: RichText(
        overflow: TextOverflow.ellipsis, // Add overflow handling
        maxLines: 2, // Allow up to 2 lines for longer content
        text: TextSpan(
          // Use theme's bodyMedium style as base
          style: textTheme.bodyMedium?.copyWith(color: kTextColor),
          children: <TextSpan>[
            TextSpan(
                text: '$label ',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(
                text: value,
                style: const TextStyle(
                    color: kLightTextColor)), // Lighter color for value
          ],
        ),
      ),
    );
  }

  // Updated signature to accept Student
  Widget _buildExamResultsSection(Student student, List<ExamTerm> allTerms,
      List<ExamResult> currentResults) {
    // Extract unique years and terms for dropdowns
    final years = allTerms.map((t) => t.year).toSet().toList();
    years.sort((a, b) => b.compareTo(a)); // Descending order

    final termsForSelectedYear = _selectedExamYear == null
        ? <ExamTerm>[]
        : allTerms.where((t) => t.year == _selectedExamYear).toList();

    // Ensure selected term ID is valid for the selected year
    if (_selectedExamYear != null &&
        _selectedExamTermId != null &&
        !termsForSelectedYear.any((t) => t.id == _selectedExamTermId)) {
      // If the previously selected term is not in the new year's list, reset it
      Future.microtask(() => setState(() {
            _selectedExamTermId = termsForSelectedYear.isNotEmpty
                ? termsForSelectedYear.first.id
                : null;
            _examResultsFuture =
                _fetchExamResults(_selectedExamTermId); // Reload results
          }));
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Exam Results",
                  style: Theme.of(context).textTheme.titleLarge),
              // Share button for exam results - Apply AttendanceSummaryScreen style
              if (currentResults.isNotEmpty && _selectedExamTermId != null)
                ElevatedButton(
                  onPressed: () {
                    final selectedTerm = allTerms
                        .firstWhereOrNull((t) => t.id == _selectedExamTermId);
                    if (selectedTerm != null) {
                      _showStudentExamResultsExportOptions(
                          currentResults, selectedTerm, student);
                    } else {
                      _showToast("Selected term not found.", error: true);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(kDefaultRadius),
                    ),
                    minimumSize: const Size(50, 50), // Match size
                    padding: EdgeInsets.zero, // Remove padding for icon only
                    backgroundColor: kPrimaryColor,
                    foregroundColor: kSecondaryColor, // Icon color
                    elevation: 3,
                  ),
                  child: const Icon(Icons.share_rounded, size: 24),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Year Dropdown
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedExamYear,
                  hint: const Text("Year"),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedExamYear = newValue;
                      // Reset term when year changes, select first term of new year
                      final newTerms = allTerms
                          .where((t) => t.year == _selectedExamYear)
                          .toList();
                      _selectedExamTermId =
                          newTerms.isNotEmpty ? newTerms.first.id : null;
                      _examResultsFuture = _fetchExamResults(
                          _selectedExamTermId); // Fetch new results
                    });
                  },
                  items: years.map<DropdownMenuItem<String>>((String year) {
                    return DropdownMenuItem<String>(
                      value: year,
                      child: Text(year),
                    );
                  }).toList(),
                  decoration:
                      const InputDecoration(border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 8),
              // Term Dropdown
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedExamTermId,
                  hint: const Text("Term"),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedExamTermId = newValue;
                      _examResultsFuture = _fetchExamResults(
                          _selectedExamTermId); // Fetch new results
                    });
                  },
                  items: termsForSelectedYear
                      .map<DropdownMenuItem<String>>((ExamTerm term) {
                    return DropdownMenuItem<String>(
                      value: term.id,
                      child: Text(term.termOnlyName,
                          overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  decoration:
                      const InputDecoration(border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 8),
              // Edit Button
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: _selectedExamTermId == null
                    ? null
                    : () {
                        final selectedTerm = allTerms
                            .firstWhere((t) => t.id == _selectedExamTermId);
                        // Pass the student object here
                        _showEditExamResultsDialog(
                            student, currentResults, selectedTerm);
                      },
                tooltip: "Edit Results",
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Bar Chart
          if (currentResults.isNotEmpty)
            // Pass the student object (already available in this scope)
            _buildExamChart(student, currentResults)
          else if (_selectedExamTermId != null)
            const Center(child: Text("No results found for this term."))
          else
            const Center(
                child: Text("Select a year and term to view results.")),
        ],
      ),
    );
  }

  // Updated signature to accept Student
  Widget _buildExamChart(Student student, List<ExamResult> results) {
    // Filter results based on student's chosen subjects
    final filteredResults = results
        .where((r) => student.subjectsChoosed.contains(r.subject))
        .toList();

    if (filteredResults.isEmpty)
      return const SizedBox(
          height: 150,
          child: Center(child: Text("No data for chosen subjects")));

    // Find max marks across filtered results for Y-axis scaling, default to 100
    final double maxPossibleMark = filteredResults.fold<double>(
        100.0, (prev, elem) => elem.maxMarks > prev ? elem.maxMarks : prev);
    final double maxY =
        (maxPossibleMark / 10).ceil() * 10; // Round up to nearest 10

    return SizedBox(
      height: 250, // Adjust height as needed
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          minY: 0,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              // Removed tooltipBgColor as it's not a valid parameter in this version
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                // Use filteredResults here
                final result = filteredResults[groupIndex];
                return BarTooltipItem(
                  '${result.subject}\n',
                  const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                  children: <TextSpan>[
                    TextSpan(
                      // Use const constructor
                      text: result.marks
                          .toStringAsFixed(0), // Show marks as integer
                      style: const TextStyle(
                        color: Colors.yellow,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  final index = value.toInt();
                  // Use filteredResults here
                  if (index >= 0 && index < filteredResults.length) {
                    // Abbreviate long subject names if necessary
                    String subjectName = filteredResults[index].subject;
                    if (subjectName.length > 5) {
                      subjectName =
                          '${subjectName.substring(0, 3)}.'; // Keep abbreviation logic
                    }
                    return SideTitleWidget(
                      meta: meta, // Added required meta parameter
                      space: 4.0,
                      child: Text(subjectName,
                          style: const TextStyle(fontSize: 10)),
                    );
                  }
                  return Container();
                },
                reservedSize: 30, // Adjust space for labels
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  if (value % 20 == 0) {
                    // Show labels every 20 marks
                    return Text(value.toInt().toString(),
                        style: const TextStyle(fontSize: 10));
                  }
                  return Container();
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 20, // Grid line every 20 marks
            getDrawingHorizontalLine: (value) {
              return FlLine(
                // Removed const
                color: Colors.grey.withOpacity(0.3),
                strokeWidth: 1,
              );
            },
          ),
          // Use filteredResults here
          barGroups: filteredResults.asMap().entries.map((entry) {
            int index = entry.key;
            ExamResult result = entry.value;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: result.marks,
                  color: Colors.teal, // Adjust color as needed
                  width: 16, // Adjust bar width
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  // Modified to accept Student object
  Widget _buildMonthlyFeesSection(Student student, List<FeeRecord> allFees) {
    final years = allFees.map((f) => f.year.toString()).toSet().toList();
    years.sort((a, b) => b.compareTo(a)); // Descending

    // Add current year if not present in fees
    final currentYearStr = DateTime.now().year.toString();
    if (!years.contains(currentYearStr)) {
      years.insert(0, currentYearStr);
    }

    // Filter fees for the selected year
    final feesForSelectedYear = _selectedFeeYear == null
        ? <FeeRecord>[]
        : allFees.where((f) => f.year.toString() == _selectedFeeYear).toList();

    // Create a map of month -> FeeRecord for easy lookup
    final feeMap = {for (var fee in feesForSelectedYear) fee.month: fee};

    // Generate all months for the table
    final allMonths = List.generate(12, (index) => index + 1);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Monthly Fees", style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedFeeYear,
                  hint: const Text("Year"),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedFeeYear = newValue;
                      // No need to refetch, just filter the existing list
                    });
                  },
                  items: years.map<DropdownMenuItem<String>>((String year) {
                    return DropdownMenuItem<String>(
                      value: year,
                      child: Text(year),
                    );
                  }).toList(),
                  decoration:
                      const InputDecoration(border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 8),
              // Edit Fees Button
              IconButton(
                icon: const Icon(Icons.edit_rounded),
                tooltip: "Edit Fees for $_selectedFeeYear",
                onPressed: _selectedFeeYear == null
                    ? null
                    : () {
                        // student object is now available directly in this scope
                        _showEditMonthlyFeesDialog(
                            student, feesForSelectedYear, _selectedFeeYear!);
                      },
              ),
              const SizedBox(width: 8),
              // Share button for monthly fees - Apply AttendanceSummaryScreen style
              ElevatedButton(
                onPressed: _selectedFeeYear == null ||
                        feesForSelectedYear.isEmpty &&
                            !allFees.any((f) =>
                                f.year.toString() == _selectedFeeYear &&
                                f.paid) // Keep original condition
                    ? null
                    : () => _showMonthlyFeesExportOptions(
                        student, feesForSelectedYear, _selectedFeeYear!),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(kDefaultRadius),
                  ),
                  minimumSize: const Size(50, 50), // Match size
                  padding: EdgeInsets.zero, // Remove padding for icon only
                  backgroundColor: kPrimaryColor,
                  foregroundColor: kSecondaryColor, // Icon color
                  elevation: 3,
                ),
                child: const Icon(Icons.share_rounded, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Fees Table
          if (_selectedFeeYear != null)
            SingleChildScrollView(
              // Make table horizontally scrollable if needed
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 30, // Adjust spacing
                columns: const [
                  DataColumn(
                      label: Text('Month',
                          style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(
                      label: Text('Payment',
                          style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(
                      label: Text('Amount',
                          style: TextStyle(
                              fontWeight:
                                  FontWeight.bold))), // Optional: Show amount
                  DataColumn(
                      label: Text('Paid Date',
                          style: TextStyle(
                              fontWeight: FontWeight
                                  .bold))), // Optional: Show paid date
                ],
                rows: allMonths.map((month) {
                  final fee = feeMap[month];
                  final monthName = DateFormat('MMMM')
                      .format(DateTime(int.parse(_selectedFeeYear!), month));
                  final isPaid = fee?.paid ?? false;
                  final amount = fee?.amount.toStringAsFixed(2) ?? '-';
                  final paidDate = fee?.paidAt != null
                      ? DateFormat('yyyy-MM-dd').format(fee!.paidAt!.toDate())
                      : '-';

                  return DataRow(
                    color: WidgetStateProperty.resolveWith<Color?>(
                      (Set<WidgetState> states) {
                        // Optional: Alternate row colors
                        // return allMonths.indexOf(month).isEven ? Colors.grey.shade100 : null;
                        return null;
                      },
                    ),
                    cells: [
                      DataCell(
                          Text(monthName, overflow: TextOverflow.ellipsis)),
                      DataCell(
                        isPaid
                            ? const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                    Icon(Icons.check_circle,
                                        color: Colors.green, size: 18),
                                    SizedBox(width: 4),
                                    Flexible(
                                        child: Text('Paid',
                                            overflow: TextOverflow.ellipsis))
                                  ])
                            : const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                    Icon(Icons.cancel,
                                        color: Colors.red, size: 18),
                                    SizedBox(width: 4),
                                    Flexible(
                                        child: Text('Unpaid',
                                            overflow: TextOverflow.ellipsis))
                                  ]),
                      ),
                      DataCell(Text(amount, overflow: TextOverflow.ellipsis)),
                      DataCell(Text(paidDate, overflow: TextOverflow.ellipsis)),
                    ],
                  );
                }).toList(),
              ),
            )
          else
            const Center(child: Text("Select a year to view fee details.")),
        ],
      ),
    );
  }

  // Modified to accept Student object for attendance section
  Widget _buildAttendanceSection(
      Student student, List<AttendanceRecord> allAttendance) {
    final years = allAttendance.map((a) => a.year.toString()).toSet().toList();
    years.sort((a, b) => b.compareTo(a)); // Descending

    // Add current year if not present in attendance
    final currentYearStr = DateTime.now().year.toString();
    if (!years.contains(currentYearStr)) {
      years.insert(0, currentYearStr);
    }

    final months = List.generate(12, (i) => (i + 1).toString());

    // Set default selections
    if (_selectedAttendanceYear == null && years.isNotEmpty) {
      _selectedAttendanceYear = years.first;
    }
    if (_selectedAttendanceMonth == null) {
      _selectedAttendanceMonth = DateTime.now().month.toString();
    }
    if (_selectedAttendanceSubject == null &&
        student.subjectsChoosed.isNotEmpty) {
      _selectedAttendanceSubject = 'All Subjects'; // Default to all subjects
    }

    // Filter student's attendance for the selected year and month
    final filteredAttendance = allAttendance
        .where((a) =>
            (_selectedAttendanceYear == null ||
                a.year.toString() == _selectedAttendanceYear) &&
            (_selectedAttendanceMonth == null ||
                a.month.toString() == _selectedAttendanceMonth) &&
            (_selectedAttendanceSubject == null ||
                _selectedAttendanceSubject == 'All Subjects' ||
                a.subject == _selectedAttendanceSubject))
        .toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Student Attendance",
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          // Filter controls - Split into two rows to prevent overflow
          Column(
            children: [
              // First row: Year and Month dropdowns
              Row(
                children: [
                  // Year dropdown
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedAttendanceYear,
                      hint: const Text("Year"),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedAttendanceYear = newValue;
                          // Reload attendance data
                          _attendanceFuture = _fetchAttendance(
                              _selectedAttendanceYear,
                              _selectedAttendanceMonth);
                        });
                      },
                      items: years.map<DropdownMenuItem<String>>((String year) {
                        return DropdownMenuItem<String>(
                          value: year,
                          child: Text(year),
                        );
                      }).toList(),
                      decoration:
                          const InputDecoration(border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Month dropdown
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedAttendanceMonth,
                      hint: const Text("Month"),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedAttendanceMonth = newValue;
                          // Reload attendance data
                          _attendanceFuture = _fetchAttendance(
                              _selectedAttendanceYear,
                              _selectedAttendanceMonth);
                        });
                      },
                      items:
                          months.map<DropdownMenuItem<String>>((String month) {
                        final monthName = DateFormat('MMMM')
                            .format(DateTime(2024, int.parse(month)));
                        return DropdownMenuItem<String>(
                          value: month,
                          child:
                              Text(monthName, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      decoration:
                          const InputDecoration(border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Second row: Subject dropdown and Share button
              Row(
                children: [
                  // Subject dropdown
                  Expanded(
                    flex: 3, // Give more space to subject dropdown
                    child: DropdownButtonFormField<String>(
                      value: _selectedAttendanceSubject,
                      hint: const Text("Subject"),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedAttendanceSubject = newValue;
                          // Filter is applied in the widget, no need to refetch
                        });
                      },
                      items: ['All Subjects', ...student.subjectsChoosed]
                          .map<DropdownMenuItem<String>>((String subject) {
                        return DropdownMenuItem<String>(
                          value: subject,
                          child: Text(subject, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      decoration:
                          const InputDecoration(border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Share button for attendance
                  ElevatedButton(
                    onPressed: filteredAttendance.isEmpty
                        ? null
                        : () => _showAttendanceExportOptions(
                            student,
                            filteredAttendance,
                            _selectedAttendanceYear!,
                            _selectedAttendanceMonth!),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(kDefaultRadius),
                      ),
                      minimumSize: const Size(50, 50),
                      padding: EdgeInsets.zero,
                      backgroundColor: kPrimaryColor,
                      foregroundColor: kSecondaryColor,
                      elevation: 3,
                    ),
                    child: const Icon(Icons.share_rounded, size: 24),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Attendance summary with accurate statistics
          FutureBuilder<Map<String, dynamic>>(
            future: _calculateAccurateAttendanceStats(
                student,
                filteredAttendance,
                _selectedAttendanceSubject ?? 'All Subjects'),
            builder: (context, snapshot) {
              // Use fallback calculation while loading or on error
              final Map<String, dynamic> attendanceStats;
              if (snapshot.hasData) {
                attendanceStats = snapshot.data!;
              } else {
                // Fallback to improved calculation if accurate fails
                attendanceStats = _calculateImprovedAttendanceStats(
                    student,
                    filteredAttendance,
                    _selectedAttendanceSubject ?? 'All Subjects');
              }

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Attendance Summary',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          if (snapshot.connectionState ==
                              ConnectionState.waiting)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          if (snapshot.hasData &&
                              attendanceStats['isAccurate'] == true)
                            Icon(Icons.verified,
                                color: kSuccessColor, size: 16),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                    attendanceStats['totalClassDays']
                                        .toString(),
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(color: kPrimaryColor)),
                                Text('Classes',
                                    textAlign: TextAlign.center,
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                    overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Text(attendanceStats['presentDays'].toString(),
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(color: kSuccessColor)),
                                Text('Present',
                                    textAlign: TextAlign.center,
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                    overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Text(attendanceStats['absentDays'].toString(),
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(color: kErrorColor)),
                                Text('Absent',
                                    textAlign: TextAlign.center,
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                    overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                    '${attendanceStats['attendancePercentage'].toStringAsFixed(1)}%',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(
                                            color: attendanceStats[
                                                        'attendancePercentage'] >=
                                                    75
                                                ? kSuccessColor
                                                : kErrorColor)),
                                Text('Rate',
                                    textAlign: TextAlign.center,
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                    overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (attendanceStats['totalClassDays'] >
                          attendanceStats['presentDays'])
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          // child: Text(
                          //   snapshot.hasData && attendanceStats['isAccurate'] == true
                          //       ? 'Attendance calculated based on all students\' class records for accurate totals.'
                          //       : 'Attendance calculated using estimation. Accurate calculation may take a moment to load.',
                          //   style: Theme.of(context).textTheme.bodySmall?.copyWith(color: kLightTextColor, fontStyle: FontStyle.italic),
                          //   textAlign: TextAlign.center,
                          // ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          // Attendance table
          if (filteredAttendance.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 30,
                columns: const [
                  DataColumn(
                      label: Text('Date',
                          style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(
                      label: Text('Status',
                          style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(
                      label: Text('Subject',
                          style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: filteredAttendance.map((attendance) {
                  final isPresent = attendance.status == 'present';
                  final displayDate = DateFormat('dd MMM yyyy').format(
                      DateTime.tryParse(attendance.date) ?? DateTime.now());
                  return DataRow(
                    cells: [
                      DataCell(
                          Text(displayDate, overflow: TextOverflow.ellipsis)),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isPresent ? Icons.check_circle : Icons.cancel,
                              color: isPresent ? kSuccessColor : kErrorColor,
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                isPresent ? 'Present' : 'Absent',
                                style: TextStyle(
                                    color: isPresent
                                        ? kSuccessColor
                                        : kErrorColor),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      DataCell(Text(attendance.subject ?? 'General',
                          overflow: TextOverflow.ellipsis)),
                    ],
                  );
                }).toList(),
              ),
            )
          else
            Center(
                child: Text(
                    "No attendance records found for ${_selectedAttendanceMonth != null ? DateFormat('MMMM').format(DateTime(2024, int.parse(_selectedAttendanceMonth!))) : 'selected period'}${_selectedAttendanceYear != null ? ' $_selectedAttendanceYear' : ''}.")),
        ],
      ),
    );
  }

  // Calculate improved attendance statistics with accurate total class days
  Future<Map<String, dynamic>> _calculateAccurateAttendanceStats(
      Student student,
      List<AttendanceRecord> studentAttendance,
      String selectedSubject) async {
    // Present days for this student (from their attendance records)
    final presentDays =
        studentAttendance.where((a) => a.status == 'present').length;

    // Get the accurate total class days by querying all students
    final totalClassDays = await _getTotalClassDaysForPeriod(
        _selectedAttendanceYear ?? '',
        _selectedAttendanceMonth ?? '',
        selectedSubject);

    final absentDays =
        totalClassDays > presentDays ? totalClassDays - presentDays : 0;
    final attendancePercentage =
        totalClassDays > 0 ? (presentDays / totalClassDays * 100) : 0.0;

    return {
      'presentDays': presentDays,
      'totalClassDays': totalClassDays,
      'absentDays': absentDays,
      'attendancePercentage': attendancePercentage,
      'isAccurate': true, // Flag to indicate this is accurate calculation
    };
  }

  // Fallback method for cases where accurate calculation is not needed or fails
  Map<String, dynamic> _calculateImprovedAttendanceStats(Student student,
      List<AttendanceRecord> studentAttendance, String selectedSubject) {
    // The key insight: studentAttendance contains only records where this student was PRESENT
    // This method uses estimation when accurate calculation is not available

    // Present days for this student (from their attendance records)
    final presentDays =
        studentAttendance.where((a) => a.status == 'present').length;

    // For improved accuracy, we'll use the attendance dates from this student's records
    // to estimate when classes were held. This assumes that if a student attended,
    // classes were definitely conducted on those days.
    final uniqueDatesPresent = studentAttendance
        .where((a) => a.status == 'present')
        .map((a) => a.date)
        .toSet()
        .length;

    // Estimate total class days - assume this student attended 75-85% of all classes on average
    // This is a reasonable assumption for regular students
    final estimatedTotalClassDays = (presentDays / 0.8).round();
    final absentDays = estimatedTotalClassDays - presentDays;
    final attendancePercentage = estimatedTotalClassDays > 0
        ? (presentDays / estimatedTotalClassDays * 100)
        : 0.0;

    return {
      'presentDays': presentDays,
      'totalClassDays': estimatedTotalClassDays,
      'absentDays': absentDays,
      'attendancePercentage': attendancePercentage,
      'uniqueDatesPresent': uniqueDatesPresent,
      'isAccurate': false, // Flag to indicate this is estimated calculation
    };
  }

  // Get total class days by querying all students' attendance to find when classes were conducted
  Future<int> _getTotalClassDaysForPeriod(
      String year, String month, String subject) async {
    final String? adminUid = AuthController.instance.user?.uid;
    if (adminUid == null) return 0;

    try {
      // Get all students for this admin
      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('admins')
          .doc(adminUid)
          .collection('students')
          .get();

      Set<String> classDays = {};

      // Check each student's attendance to find all unique date-subject combinations
      for (var studentDoc in studentsSnapshot.docs) {
        Query<Map<String, dynamic>> attendanceQuery = FirebaseFirestore.instance
            .collection('admins')
            .doc(adminUid)
            .collection('students')
            .doc(studentDoc.id)
            .collection('attendance');

        // Filter by year and month
        if (year.isNotEmpty && month.isNotEmpty) {
          final startDate = '$year-${month.padLeft(2, '0')}-01';
          final nextMonth = int.parse(month) == 12 ? 1 : int.parse(month) + 1;
          final nextYear =
              int.parse(month) == 12 ? int.parse(year) + 1 : int.parse(year);
          final endDate =
              '$nextYear-${nextMonth.toString().padLeft(2, '0')}-01';

          attendanceQuery = attendanceQuery
              .where('date', isGreaterThanOrEqualTo: startDate)
              .where('date', isLessThan: endDate);
        }

        final attendanceSnapshot = await attendanceQuery.get();

        for (var attendanceDoc in attendanceSnapshot.docs) {
          final data = attendanceDoc.data();
          final date = data['date'] as String? ?? '';
          final recordSubject = data['subject'] as String? ?? '';

          // If subject filter is applied and not 'All Subjects'
          if (subject != 'All Subjects' && recordSubject != subject) {
            continue;
          }

          // Add unique date-subject combination to indicate a class was conducted
          classDays.add('$date-$recordSubject');
        }
      }

      return classDays.length;
    } catch (e) {
      print('Error calculating total class days: $e');
      return 0;
    }
  }

  // --- Action Handlers ---

  // Updated QR Code download using Visibility strategy
  Future<void> _downloadQrCode(String studentName) async {
    setState(() {
      _isCapturingQr = true;
    }); // Show the QR code

    // Wait for the next frame to ensure the QR code is rendered
    await WidgetsBinding.instance.endOfFrame;
    // Add a minimal delay just in case
    await Future.delayed(const Duration(milliseconds: 100));

    try {
      // Check context validity again after delay
      if (!_qrCodeKey.currentContext!.mounted) {
        _showToast("Error: QR Code widget became unavailable.", error: true);
        return;
      }

      RenderRepaintBoundary boundary = _qrCodeKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      // No need to check debugNeedsPaint here as Visibility should handle rendering

      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        _showToast("Error: Could not convert QR code to image data.",
            error: true);
        return;
      }
      Uint8List pngBytes = byteData.buffer.asUint8List();

      // --- Permission Check for SaverGallery ---
      // SaverGallery might handle permissions internally, but explicit check is safer
      var status = await Permission.storage.status;
      // On Android 13+, storage permission might not be needed if saver_gallery uses MediaStore correctly.
      // However, let's request photos permission as a fallback or if targeting older SDKs.
      if (Platform.isAndroid) {
        // Check for Android 13 (API 33) or higher
        final androidInfo = await DeviceInfoPlugin()
            .androidInfo; // Need device_info_plus package
        if (androidInfo.version.sdkInt >= 33) {
          status = await Permission.photos.status; // Use photos permission
          if (!status.isGranted) {
            status = await Permission.photos.request();
          }
        } else {
          // For older versions, check storage permission
          if (!status.isGranted) {
            status = await Permission.storage.request();
          }
        }
      } else {
        // For iOS or other platforms if needed
        if (!status.isGranted) {
          status = await Permission.storage.request(); // Or photos for iOS
        }
      }

      if (status.isGranted) {
        final result = await SaverGallery.saveImage(
          pngBytes,
          fileName:
              "qrcode_${studentName.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}",
          androidRelativePath: "Pictures/EduTrack/QRCodes",
          skipIfExists: false,
        );

        if (result.isSuccess) {
          _showToast("QR Code downloaded successfully!");
        } else {
          _showToast("Failed to save QR Code: ${result.errorMessage}",
              error: true);
        }
      } else {
        _showToast("Storage permission denied. Cannot save QR Code.",
            error: true);
      }
    } catch (e) {
      print("Error downloading QR Code: $e");
      _showToast("Error capturing QR Code: $e", error: true);
    } finally {
      // Hide the QR code again regardless of success/failure
      if (mounted) {
        // Check if widget is still mounted before calling setState
        setState(() {
          _isCapturingQr = false;
        });
      }
    }
  }

  Future<void> _downloadStudentPhoto(
      String? photoUrl, String studentName) async {
    if (photoUrl == null || photoUrl.isEmpty) {
      _showToast("No photo URL available.", error: true);
      return;
    }

    try {
      // Use http package to fetch the image bytes
      final response = await http.get(Uri.parse(photoUrl));
      if (response.statusCode == 200) {
        // Use SaverGallery with correct parameters
        final result = await SaverGallery.saveImage(
            response.bodyBytes, // Pass image data as positional argument
            fileName:
                "photo_${studentName.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}", // Use fileName
            androidRelativePath:
                "Pictures/EduTrack/StudentPhotos", // Example path
            skipIfExists: false // Use skipIfExists
            );
        if (result.isSuccess) {
          _showToast("Photo downloaded successfully!");
        } else {
          _showToast("Failed to save photo: ${result.errorMessage}",
              error: true);
        }
      } else {
        _showToast(
            "Failed to download photo (status code: ${response.statusCode}).",
            error: true);
      }
    } catch (e) {
      print("Error downloading photo: $e");
      _showToast("Error downloading photo: $e", error: true);
    }
  }

  Future<void> _showMonthlyFeesExportOptions(
      Student student, List<FeeRecord> fees, String year) async {
    // Check if there's any data to export, considering all months for the year, not just paid ones for the dialog.
    final allMonthsForYear = List.generate(12, (i) => i + 1);
    final hasAnyDataForYear = fees.any((f) => f.year.toString() == year) ||
        allMonthsForYear.any((m) => fees.any((f) => f.month == m));

    if (!hasAnyDataForYear) {
      _showToast("No fee data available for $year to export.", error: true);
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Export Monthly Fees for $year'),
          content: const Text('Choose the export format:'),
          actions: <Widget>[
            TextButton(
              child: const Text('Excel (.xlsx)'),
              onPressed: () {
                Navigator.of(context).pop();
                _exportFeesAsExcel(student, fees, year);
              },
            ),
            TextButton(
              child: const Text('PDF (.pdf)'),
              onPressed: () {
                Navigator.of(context).pop();
                _exportFeesAsPdf(student, fees, year);
              },
            ),
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _exportFeesAsExcel(
      Student student, List<FeeRecord> fees, String year) async {
    // Filter fees for the specific year before checking emptiness
    final feesForYear = fees.where((f) => f.year.toString() == year).toList();
    final allMonths = List.generate(12, (i) => i + 1);
    final feeMapForYear = {for (var fee in feesForYear) fee.month: fee};
    bool hasDisplayableData =
        allMonths.any((month) => feeMapForYear[month] != null);

    if (!hasDisplayableData) {
      _showToast("No fee data for $year to export to Excel.", error: true);
      return;
    }

    // --- No direct permission check needed here, share_plus handles it ---

    try {
      var excel = Excel.createExcel();
      // Use a simpler sheet name to avoid length/character issues
      Sheet sheetObject = excel['Fees_$year'];

      // Add Header Row
      sheetObject.appendRow([
        TextCellValue('Month'), // Removed const
        TextCellValue('Status'), // Removed const
        TextCellValue('Amount'), // Removed const
        TextCellValue('Paid Date'), // Removed const
      ]);

      // Add Data Rows
      final allMonths = List.generate(12, (index) => index + 1);
      final feeMap = {for (var fee in fees) fee.month: fee};

      for (var month in allMonths) {
        final fee = feeMap[month];
        final monthName =
            DateFormat('MMMM').format(DateTime(int.parse(year), month));
        final status = fee?.paid ?? false ? 'Paid' : 'Unpaid';
        final amount = fee?.amount ?? 0.0;
        final paidDate = fee?.paidAt != null
            ? DateFormat('yyyy-MM-dd').format(fee!.paidAt!.toDate())
            : '-';

        sheetObject.appendRow([
          TextCellValue(monthName),
          TextCellValue(status),
          DoubleCellValue(amount),
          TextCellValue(paidDate),
        ]);
      }

      // Get the temporary directory
      final Directory tempDir = await getTemporaryDirectory();
      final path = tempDir.path;
      final sanitizedStudentName = student.name
          .replaceAll(RegExp(r'[\\/*?:"<>|]'), '_')
          .replaceAll(' ', '_');
      final fileName = 'Fees_${sanitizedStudentName}_$year.xlsx';
      final filePath = '$path/$fileName';
      print("Saving temporary Excel file to: $filePath");

      // Save the file to the temporary directory
      final fileBytes = excel.save();
      if (fileBytes != null) {
        final file = File(filePath);
        await file.writeAsBytes(fileBytes,
            flush: true); // Ensure bytes are written

        // Use share_plus to share the file
        final xFile = XFile(filePath,
            name: fileName,
            mimeType:
                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
        final result = await Share.shareXFiles([xFile],
            text: 'Monthly Fees for ${student.name} - $year');

        // Check share result status (optional)
        if (result.status == ShareResultStatus.success) {
          _showToast("Fee details for $year ready to be saved/shared.");
        } else if (result.status == ShareResultStatus.dismissed) {
          _showToast("Share cancelled for fee details.", error: true);
        } else {
          _showToast("Sharing failed for fee details: ${result.status}",
              error: true);
        }

        // Optionally delete the temp file after sharing attempt
        // await file.delete();
      } else {
        _showToast("Failed to generate Excel file.", error: true);
      }
    } catch (e) {
      print("Error exporting/sharing fees to Excel: $e");
      _showToast("Error exporting fees: $e", error: true);
    }
  }

  Future<void> _exportFeesAsPdf(
      Student student, List<FeeRecord> fees, String year) async {
    final feesForYear = fees.where((f) => f.year.toString() == year).toList();
    final allMonths = List.generate(12, (i) => i + 1);
    final feeMapForYear = {for (var fee in feesForYear) fee.month: fee};
    bool hasDisplayableData =
        allMonths.any((month) => feeMapForYear[month] != null);

    if (!hasDisplayableData) {
      _showToast("No fee data for $year to export to PDF.", error: true);
      return;
    }

    final pdf = pw.Document();
    final String title = 'Monthly Fees: ${student.name} - $year';
    final sanitizedStudentName = student.name
        .replaceAll(RegExp(r'[\\/*?:"<>|]'), '_')
        .replaceAll(' ', '_');

    final fontData = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
    final boldFontData = await rootBundle.load("assets/fonts/Roboto-Bold.ttf");
    final ttf = pw.Font.ttf(fontData);
    final boldTtf = pw.Font.ttf(boldFontData);

    List<List<String>> tableData = [
      ['Month', 'Status', 'Amount', 'Paid Date'],
    ];

    for (var month in allMonths) {
      final fee = feeMapForYear[month];
      final monthName =
          DateFormat('MMMM').format(DateTime(int.parse(year), month));
      final status = fee?.paid ?? false ? 'Paid' : 'Unpaid';
      final amount = fee?.amount.toStringAsFixed(2) ?? '-';
      final paidDate = fee?.paidAt != null
          ? DateFormat('yyyy-MM-dd').format(fee!.paidAt!.toDate())
          : '-';
      tableData.add([monthName, status, amount, paidDate]);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pdf_core.PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: ttf, bold: boldTtf),
        header: (pw.Context context) {
          if (_academyName == null || _academyName!.isEmpty)
            return pw.Container();
          return pw.Center(
              child: pw.Padding(
            padding: const pw.EdgeInsets.only(
                bottom: 10), // Add some padding below academy name
            child: pw.Text(_academyName!,
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 22,
                    color:
                        pdf_core.PdfColors.black) // Make it bigger and bolder
                ),
          ));
        },
        footer: (pw.Context context) {
          return pw.Center(
            child: pw.Text('Generated by EduTrack',
                style: const pw.TextStyle(
                    fontSize: 8, color: pdf_core.PdfColors.grey)),
          );
        },
        build: (pw.Context context) => [
          pw.Header(
              level: 0,
              child: pw.Text(title,
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 18))),
          pw.SizedBox(height: 5),
          pw.Text('Student: ${student.name} (Index: ${student.indexNumber})',
              style: const pw.TextStyle(fontSize: 12)),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            context: null,
            cellAlignment: pw.Alignment.centerLeft,
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 10),
            headerDecoration:
                const pw.BoxDecoration(color: pdf_core.PdfColors.grey300),
            data: tableData,
            columnWidths: {
              0: const pw.FlexColumnWidth(2), // Month
              1: const pw.FlexColumnWidth(1.5), // Status
              2: const pw.FlexColumnWidth(1.5), // Amount
              3: const pw.FlexColumnWidth(2), // Paid Date
            },
          ),
        ],
      ),
    );

    try {
      await Printing.sharePdf(
          bytes: await pdf.save(),
          filename: 'MonthlyFees_${sanitizedStudentName}_$year.pdf');
      _showToast("Monthly fees PDF for $year ready to be shared.");
    } catch (e) {
      _showToast("Error sharing monthly fees PDF: $e", error: true);
    }
  }

  // Updated signature to accept Student
  void _showEditExamResultsDialog(
      Student student, List<ExamResult> currentResults, ExamTerm term) {
    final textTheme = Theme.of(context).textTheme;
    // Create controllers for each subject's text field
    Map<String, TextEditingController> controllers = {};
    Map<String, String> initialMarks =
        {}; // Store initial marks to detect changes
    Map<String, String> resultDocIds = {}; // Store doc IDs for updating

    // Initialize controllers with current marks FOR CHOSEN SUBJECTS ONLY
    for (String subject in student.subjectsChoosed) {
      // Find the existing result for this subject, if any
      final result = currentResults.firstWhere((r) => r.subject == subject,
          // If no result exists yet for a chosen subject, create a default one
          orElse: () => ExamResult(
              id: '',
              termId: term.id,
              subject: subject,
              marks: 0,
              maxMarks: 100));
      controllers[subject] =
          TextEditingController(text: result.marks.toStringAsFixed(0));
      initialMarks[subject] = result.marks.toStringAsFixed(0);
      // Store the document ID if it exists, otherwise it's a new entry
      if (currentResults.any((r) => r.subject == subject)) {
        resultDocIds[subject] =
            currentResults.firstWhere((r) => r.subject == subject).id;
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(kDefaultRadius)), // Use constant radius
          title: Text("Edit Results - ${term.name}",
              style: textTheme.titleLarge), // Use theme style
          contentPadding:
              const EdgeInsets.all(kDefaultPadding), // Use constant padding
          content: SingleChildScrollView(
            child: ListBody(
              // Use ListBody for better structure
              children: student.subjectsChoosed.map((subject) {
                if (!controllers.containsKey(subject))
                  return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(
                      bottom: kDefaultPadding * 0.75), // Consistent padding
                  child: TextFormField(
                    controller: controllers[subject],
                    decoration: InputDecoration(
                      // Use theme's InputDecoration
                      labelText: subject,
                      hintText: "Enter marks (0-100)",
                      prefixIcon: const Icon(Icons.calculate_outlined,
                          size: 18), // Add an icon
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Enter marks';
                      final marks = double.tryParse(value);
                      if (marks == null || marks < 0 || marks > 100)
                        return 'Marks must be 0-100';
                      return null;
                    },
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                  ),
                );
              }).toList(),
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(
              horizontal: kDefaultPadding,
              vertical: kDefaultPadding / 2), // Use constant padding
          actions: <Widget>[
            TextButton(
              // Use theme style implicitly
              child: const Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              // Use theme style implicitly
              child: const Text("Save Changes"),
              onPressed: () async {
                // --- Save Logic (ensure validation is checked if using TextFormField) ---
                // Consider adding form key and validation check here if needed
                final String? adminUid = AuthController.instance.user?.uid;
                if (adminUid == null) {
                  _showToast("Error: Admin not logged in. Cannot save results.",
                      error: true);
                  return;
                }
                final firestore = FirebaseFirestore.instance;
                final adminRef = firestore
                    .collection('admins')
                    .doc(adminUid); // Get admin reference
                final studentResultsRef = adminRef
                    .collection('students')
                    .doc(widget.studentId)
                    .collection('examResults'); // Correct path
                final batch = firestore.batch();
                bool hasChanges = false;
                bool errorOccurred = false;

                // Iterate over chosen subjects only
                for (String subject in student.subjectsChoosed) {
                  // Check if controller exists for this chosen subject
                  if (!controllers.containsKey(subject))
                    continue; // Skip if no controller (shouldn't happen)

                  final controller = controllers[subject]!;
                  final currentMarkStr = controller.text.trim();
                  final initialMarkStr = initialMarks[subject]!;

                  if (currentMarkStr != initialMarkStr) {
                    final double? newMark = double.tryParse(currentMarkStr);
                    if (newMark == null || newMark < 0 || newMark > 100) {
                      // Basic validation
                      _showToast(
                          "Invalid mark for $subject. Must be between 0 and 100.",
                          error: true);
                      errorOccurred = true;
                      break; // Stop processing on first error
                    }

                    hasChanges = true;
                    final resultDocId = resultDocIds[subject];
                    // Use the correct reference: adminRef -> students -> studentId -> examResults
                    final docRef = resultDocId != null && resultDocId.isNotEmpty
                        ? studentResultsRef.doc(resultDocId)
                        : studentResultsRef
                            .doc(); // Create new doc if needed under the correct path

                    batch.set(
                        docRef,
                        {
                          'term': term.id,
                          'subject': subject,
                          'marks': newMark,
                          'maxMarks': 100, // Assuming max marks is 100
                          'resultDate': Timestamp.now(), // Update timestamp
                          'updatedBy': adminUid, // Use the actual admin UID
                        },
                        SetOptions(
                            merge: true)); // Use merge to create or update
                  }
                }

                if (errorOccurred) return; // Don't proceed if validation failed

                if (hasChanges) {
                  try {
                    await batch.commit();
                    _showToast("Exam results updated successfully!");
                    // Reload results for the current term
                    setState(() {
                      _examResultsFuture =
                          _fetchExamResults(_selectedExamTermId);
                    });
                    Navigator.of(context).pop(); // Close dialog
                  } catch (e) {
                    print("Error updating exam results: $e");
                    _showToast("Error updating results: $e", error: true);
                  }
                } else {
                  _showToast("No changes detected.");
                  Navigator.of(context)
                      .pop(); // Close dialog even if no changes
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showToast(String message, {bool error = false}) {
    Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 2,
        backgroundColor: error ? Colors.red : Colors.green,
        textColor: Colors.white,
        fontSize: 16.0);
  }

  // --- Export Student Details Logic (similar to ExamResultsScreen) ---
  Future<void> _showStudentDetailsExportOptions(Student student) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Export Student Details'),
          content: const Text('Choose the export format:'),
          actions: <Widget>[
            TextButton(
              child: const Text('Excel (.xlsx)'),
              onPressed: () {
                Navigator.of(context).pop();
                _exportStudentDetailsAsExcel(student);
              },
            ),
            TextButton(
              child: const Text('PDF (.pdf)'),
              onPressed: () {
                Navigator.of(context).pop();
                _exportStudentDetailsAsPdf(student);
              },
            ),
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _exportStudentDetailsAsExcel(Student student) async {
    try {
      final excel = Excel.createExcel();
      final Sheet sheet = excel[excel.getDefaultSheet()!];

      sheet.appendRow([TextCellValue('Field'), TextCellValue('Value')]);
      sheet.appendRow([TextCellValue('Name'), TextCellValue(student.name)]);
      sheet.appendRow(
          [TextCellValue('Index No'), TextCellValue(student.indexNumber)]);
      sheet.appendRow([TextCellValue('Grade'), TextCellValue(student.grade)]);
      sheet.appendRow(
          [TextCellValue('Section'), TextCellValue(student.section)]);
      sheet.appendRow(
          [TextCellValue('Sex'), TextCellValue(student.sex ?? "N/A")]);
      sheet.appendRow([
        TextCellValue('DOB'),
        TextCellValue(student.dob != null
            ? DateFormat('yyyy/MM/dd').format(student.dob!.toDate())
            : "N/A")
      ]);
      sheet.appendRow([TextCellValue('Email'), TextCellValue(student.email)]);
      sheet.appendRow(
          [TextCellValue('Parent Name'), TextCellValue(student.parentName)]);
      sheet.appendRow(
          [TextCellValue('Parent Phone'), TextCellValue(student.parentPhone)]);
      sheet.appendRow([
        TextCellValue('WhatsApp'),
        TextCellValue(student.whatsappNumber ?? "N/A")
      ]);
      sheet.appendRow(
          [TextCellValue('Address'), TextCellValue(student.address ?? "N/A")]);
      sheet.appendRow([
        TextCellValue('Joined At'),
        TextCellValue(
            DateFormat('yyyy/MM/dd').format(student.joinedAt.toDate()))
      ]);
      sheet.appendRow([
        TextCellValue('Subjects Chosen'),
        TextCellValue(student.subjectsChoosed.join(', '))
      ]);

      final directory = await getTemporaryDirectory();
      final sanitizedStudentName = student.name
          .replaceAll(RegExp(r'[\\/*?:"<>|]'), '_')
          .replaceAll(' ', '_');
      final filePath =
          '${directory.path}/StudentDetails_$sanitizedStudentName.xlsx';
      final fileBytes = excel.save();

      if (fileBytes != null) {
        final file = File(filePath);
        await file.writeAsBytes(fileBytes, flush: true);
        final xFile = XFile(filePath,
            name: 'StudentDetails_$sanitizedStudentName.xlsx',
            mimeType:
                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
        final result = await Share.shareXFiles([xFile],
            text: 'Details for ${student.name}');
        if (result.status == ShareResultStatus.success) {
          _showToast("Student details ready to be saved/shared.");
        } else {
          _showToast("Sharing student details cancelled or failed.",
              error: true);
        }
      } else {
        _showToast("Failed to generate Excel file for student details.",
            error: true);
      }
    } catch (e) {
      _showToast("Error exporting student details to Excel: $e", error: true);
    }
  }

  Future<void> _exportStudentDetailsAsPdf(Student student) async {
    final pdf = pw.Document();
    final String title = 'Student Details: ${student.name}';

    final fontData = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
    final boldFontData = await rootBundle.load("assets/fonts/Roboto-Bold.ttf");
    final ttf = pw.Font.ttf(fontData);
    final boldTtf = pw.Font.ttf(boldFontData);

    List<pw.Widget> content = [
      pw.Header(
          level: 0,
          child: pw.Text(title,
              style:
                  pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18))),
      pw.SizedBox(height: 20),
      pw.TableHelper.fromTextArray(
        context: null, // Context not strictly needed for basic table
        cellAlignment: pw.Alignment.centerLeft,
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        cellStyle: const pw.TextStyle(fontSize: 10),
        headerDecoration:
            const pw.BoxDecoration(color: pdf_core.PdfColors.grey300),
        data: <List<String>>[
          ['Field', 'Value'],
          ['Name', student.name],
          ['Index No', student.indexNumber],
          ['Grade', student.grade],
          ['Section', student.section],
          ['Sex', student.sex ?? "N/A"],
          [
            'DOB',
            student.dob != null
                ? DateFormat('yyyy/MM/dd').format(student.dob!.toDate())
                : "N/A"
          ],
          ['Email', student.email],
          ['Parent Name', student.parentName],
          ['Parent Phone', student.parentPhone],
          ['WhatsApp', student.whatsappNumber ?? "N/A"],
          ['Address', student.address ?? "N/A"],
          [
            'Joined At',
            DateFormat('yyyy/MM/dd').format(student.joinedAt.toDate())
          ],
          ['Subjects Chosen', student.subjectsChoosed.join(', ')],
        ],
        columnWidths: {
          0: const pw.FlexColumnWidth(1.5),
          1: const pw.FlexColumnWidth(3.5),
        },
      ),
      pw.SizedBox(height: 20),
    ];

    // Add QR Code if data exists
    if (student.qrCodeData.isNotEmpty) {
      content.add(pw.SizedBox(height: 20));
      content.add(pw.Center(
          child: pw.Text("Student QR Code",
              style:
                  pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14))));
      content.add(pw.SizedBox(height: 10));
      content.add(pw.Center(
        child: pw.BarcodeWidget(
          barcode: pw.Barcode.qrCode(),
          data: student.qrCodeData,
          width: 150,
          height: 150,
          color: pdf_core.PdfColors.black,
        ),
      ));
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pdf_core.PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: ttf, bold: boldTtf),
        // Ensure Student Details PDF Header has the correct style
        header: (pw.Context context) {
          if (_academyName == null || _academyName!.isEmpty)
            return pw.Container();
          return pw.Center(
              child: pw.Padding(
            padding: const pw.EdgeInsets.only(
                bottom: 10), // Add some padding below academy name
            child: pw.Text(_academyName!,
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 22,
                    color:
                        pdf_core.PdfColors.black) // Make it bigger and bolder
                ),
          ));
        },
        footer: (pw.Context context) {
          return pw.Center(
            child: pw.Text('Generated by EduTrack',
                style: const pw.TextStyle(
                    fontSize: 8, color: pdf_core.PdfColors.grey)),
          );
        },
        build: (pw.Context context) => content,
      ),
    );

    try {
      final sanitizedStudentName = student.name
          .replaceAll(RegExp(r'[\\/*?:"<>|]'), '_')
          .replaceAll(' ', '_');
      await Printing.sharePdf(
          bytes: await pdf.save(),
          filename: 'StudentDetails_$sanitizedStudentName.pdf');
      _showToast("Student details PDF ready to be shared.");
    } catch (e) {
      _showToast("Error sharing student details PDF: $e", error: true);
    }
  }

  // --- Export Student's Exam Results Logic ---
  Future<void> _showStudentExamResultsExportOptions(
      List<ExamResult> results, ExamTerm term, Student student) async {
    if (results.isEmpty) {
      _showToast("No exam results for ${term.name} to export.", error: true);
      return;
    }
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
              'Export ${student.name}\'s Results for ${term.termOnlyName} (${term.year})'),
          content: const Text('Choose the export format:'),
          actions: <Widget>[
            TextButton(
              child: const Text('Excel (.xlsx)'),
              onPressed: () {
                Navigator.of(context).pop();
                _exportStudentExamResultsAsExcel(results, term, student);
              },
            ),
            TextButton(
              child: const Text('PDF (.pdf)'),
              onPressed: () {
                Navigator.of(context).pop();
                _exportStudentExamResultsAsPdf(results, term, student);
              },
            ),
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _exportStudentExamResultsAsExcel(
      List<ExamResult> results, ExamTerm term, Student student) async {
    try {
      final excel = Excel.createExcel();
      final Sheet sheet = excel[excel.getDefaultSheet()!];
      final sanitizedStudentName = student.name
          .replaceAll(RegExp(r'[\\/*?:"<>|]'), '_')
          .replaceAll(' ', '_');
      final sanitizedTermName = term.name
          .replaceAll(RegExp(r'[\\/*?:"<>|]'), '_')
          .replaceAll(' ', '_');

      sheet.appendRow([
        TextCellValue('Student: ${student.name} (${student.indexNumber})'),
      ]);
      sheet.appendRow([
        TextCellValue('Term: ${term.name}'),
      ]);
      sheet.appendRow([]); // Empty row for spacing

      sheet.appendRow([
        TextCellValue('Subject'),
        TextCellValue('Marks'),
        TextCellValue('Max Marks'),
        TextCellValue('Percentage'),
      ]);

      for (var result in results) {
        // Only include subjects the student has chosen
        if (student.subjectsChoosed.contains(result.subject)) {
          sheet.appendRow([
            TextCellValue(result.subject),
            DoubleCellValue(result.marks),
            DoubleCellValue(result.maxMarks),
            DoubleCellValue(result.maxMarks > 0
                ? (result.marks / result.maxMarks) * 100
                : 0),
          ]);
        }
      }

      final directory = await getTemporaryDirectory();
      final filePath =
          '${directory.path}/ExamResults_${sanitizedStudentName}_$sanitizedTermName.xlsx';
      final fileBytes = excel.save();

      if (fileBytes != null) {
        final file = File(filePath);
        await file.writeAsBytes(fileBytes, flush: true);
        final xFile = XFile(filePath,
            name: 'ExamResults_${sanitizedStudentName}_$sanitizedTermName.xlsx',
            mimeType:
                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
        final shareResult = await Share.shareXFiles([xFile],
            text: 'Exam Results for ${student.name} - ${term.name}');
        if (shareResult.status == ShareResultStatus.success) {
          _showToast("Exam results for ${term.name} ready to be saved/shared.");
        } else {
          _showToast("Sharing exam results cancelled or failed.", error: true);
        }
      } else {
        _showToast("Failed to generate Excel file for exam results.",
            error: true);
      }
    } catch (e) {
      _showToast("Error exporting exam results to Excel: $e", error: true);
    }
  }

  Future<void> _exportStudentExamResultsAsPdf(
      List<ExamResult> results, ExamTerm term, Student student) async {
    final pdf = pw.Document();
    final String title = 'Exam Results: ${student.name} - ${term.name}';
    final sanitizedStudentName = student.name
        .replaceAll(RegExp(r'[\\/*?:"<>|]'), '_')
        .replaceAll(' ', '_');
    final sanitizedTermName =
        term.name.replaceAll(RegExp(r'[\\/*?:"<>|]'), '_').replaceAll(' ', '_');

    final fontData = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
    final boldFontData = await rootBundle.load("assets/fonts/Roboto-Bold.ttf");
    final ttf = pw.Font.ttf(fontData);
    final boldTtf = pw.Font.ttf(boldFontData);

    List<List<String>> tableData = [
      ['Subject', 'Marks', 'Max Marks', 'Percentage'],
    ];
    for (var result in results) {
      if (student.subjectsChoosed.contains(result.subject)) {
        tableData.add([
          result.subject,
          result.marks.toStringAsFixed(1),
          result.maxMarks.toStringAsFixed(1),
          result.maxMarks > 0
              ? '${((result.marks / result.maxMarks) * 100).toStringAsFixed(1)}%'
              : '0%',
        ]);
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pdf_core.PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: ttf, bold: boldTtf),
        header: (pw.Context context) {
          if (_academyName == null || _academyName!.isEmpty)
            return pw.Container();
          return pw.Center(
              child: pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 10),
            child: pw.Text(_academyName!,
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 22,
                    color: pdf_core.PdfColors.black)),
          ));
        },
        footer: (pw.Context context) {
          return pw.Center(
            child: pw.Text('Generated by EduTrack',
                style: const pw.TextStyle(
                    fontSize: 8, color: pdf_core.PdfColors.grey)),
          );
        },
        build: (pw.Context context) => [
          pw.Header(
              level: 0,
              child: pw.Text(title,
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 18))),
          pw.SizedBox(height: 5),
          pw.Text('Student: ${student.name} (Index: ${student.indexNumber})',
              style: const pw.TextStyle(fontSize: 12)),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            context: null,
            cellAlignment: pw.Alignment.centerLeft,
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 10),
            headerDecoration:
                const pw.BoxDecoration(color: pdf_core.PdfColors.grey300),
            data: tableData,
            columnWidths: {
              0: const pw.FlexColumnWidth(2.5),
              1: const pw.FlexColumnWidth(1),
              2: const pw.FlexColumnWidth(1),
              3: const pw.FlexColumnWidth(1),
            },
          ),
        ],
      ),
    );

    try {
      await Printing.sharePdf(
          bytes: await pdf.save(),
          filename:
              'ExamResults_${sanitizedStudentName}_$sanitizedTermName.pdf');
      _showToast("Exam results PDF for ${term.name} ready to be shared.");
    } catch (e) {
      _showToast("Error sharing exam results PDF: $e", error: true);
    }
  }

  Future<void> _showAttendanceExportOptions(Student student,
      List<AttendanceRecord> attendance, String year, String month) async {
    if (attendance.isEmpty) {
      _showToast("No attendance data available to export.", error: true);
      return;
    }

    final monthName =
        DateFormat('MMMM').format(DateTime(2024, int.parse(month)));
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Export Attendance for $monthName $year'),
          content: const Text('Choose the export format:'),
          actions: <Widget>[
            TextButton(
              child: const Text('Excel (.xlsx)'),
              onPressed: () {
                Navigator.of(context).pop();
                _exportAttendanceAsExcel(student, attendance, year, month);
              },
            ),
            TextButton(
              child: const Text('PDF (.pdf)'),
              onPressed: () {
                Navigator.of(context).pop();
                _exportAttendanceAsPdf(student, attendance, year, month);
              },
            ),
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _exportAttendanceAsExcel(Student student,
      List<AttendanceRecord> attendance, String year, String month) async {
    if (attendance.isEmpty) {
      _showToast("No attendance data for $month $year to export to Excel.",
          error: true);
      return;
    }

    try {
      var excel = Excel.createExcel();
      final monthName =
          DateFormat('MMMM').format(DateTime(2024, int.parse(month)));
      Sheet sheetObject = excel['Attendance_${monthName}_$year'];

      // Add Header Row
      sheetObject.appendRow([
        TextCellValue('Date'),
        TextCellValue('Status'),
        TextCellValue('Subject'),
        TextCellValue('Marked At'),
      ]);

      // Add Data Rows
      for (var record in attendance) {
        final displayDate = DateFormat('dd MMM yyyy')
            .format(DateTime.tryParse(record.date) ?? DateTime.now());
        final markedAt =
            DateFormat('dd MMM yyyy HH:mm').format(record.markedAt.toDate());

        sheetObject.appendRow([
          TextCellValue(displayDate),
          TextCellValue(record.status.toUpperCase()),
          TextCellValue(record.subject ?? 'General'),
          TextCellValue(markedAt),
        ]);
      }

      // Get the temporary directory
      final Directory tempDir = await getTemporaryDirectory();
      final path = tempDir.path;
      final sanitizedStudentName = student.name
          .replaceAll(RegExp(r'[\\/*?:"<>|]'), '_')
          .replaceAll(' ', '_');
      final fileName =
          'Attendance_${sanitizedStudentName}_${monthName}_$year.xlsx';
      final filePath = '$path/$fileName';

      // Save the file to the temporary directory
      final fileBytes = excel.save();
      if (fileBytes != null) {
        final file = File(filePath);
        await file.writeAsBytes(fileBytes, flush: true);

        // Use share_plus to share the file
        final xFile = XFile(filePath,
            name: fileName,
            mimeType:
                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
        final result = await Share.shareXFiles([xFile],
            text: 'Attendance for ${student.name} - $monthName $year');

        if (result.status == ShareResultStatus.success) {
          _showToast(
              "Attendance details for $monthName $year ready to be saved/shared.");
        } else if (result.status == ShareResultStatus.dismissed) {
          _showToast("Share cancelled for attendance details.", error: true);
        } else {
          _showToast("Sharing failed for attendance details: ${result.status}",
              error: true);
        }
      } else {
        _showToast("Failed to generate Excel file.", error: true);
      }
    } catch (e) {
      print("Error exporting/sharing attendance to Excel: $e");
      _showToast("Error exporting attendance: $e", error: true);
    }
  }

  Future<void> _exportAttendanceAsPdf(Student student,
      List<AttendanceRecord> attendance, String year, String month) async {
    if (attendance.isEmpty) {
      _showToast("No attendance data for $month $year to export to PDF.",
          error: true);
      return;
    }

    final pdf = pw.Document();
    final monthName =
        DateFormat('MMMM').format(DateTime(2024, int.parse(month)));
    final String title = 'Attendance: ${student.name} - $monthName $year';
    final sanitizedStudentName = student.name
        .replaceAll(RegExp(r'[\\/*?:"<>|]'), '_')
        .replaceAll(' ', '_');

    final fontData = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
    final boldFontData = await rootBundle.load("assets/fonts/Roboto-Bold.ttf");
    final ttf = pw.Font.ttf(fontData);
    final boldTtf = pw.Font.ttf(boldFontData);

    List<List<String>> tableData = [
      ['Date', 'Status', 'Subject', 'Marked At'],
    ];

    for (var record in attendance) {
      final displayDate = DateFormat('dd MMM yyyy')
          .format(DateTime.tryParse(record.date) ?? DateTime.now());
      final markedAt =
          DateFormat('dd MMM yyyy HH:mm').format(record.markedAt.toDate());
      tableData.add([
        displayDate,
        record.status.toUpperCase(),
        record.subject ?? 'General',
        markedAt
      ]);
    }

    // Calculate attendance statistics
    final totalDays = attendance.length;
    final presentDays = attendance.where((a) => a.status == 'present').length;
    final attendancePercentage =
        totalDays > 0 ? (presentDays / totalDays * 100) : 0.0;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pdf_core.PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: ttf, bold: boldTtf),
        header: (pw.Context context) {
          if (_academyName == null || _academyName!.isEmpty)
            return pw.Container();
          return pw.Center(
              child: pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 10),
            child: pw.Text(_academyName!,
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 22,
                    color: pdf_core.PdfColors.black)),
          ));
        },
        footer: (pw.Context context) {
          return pw.Center(
            child: pw.Text('Generated by EduTrack',
                style: const pw.TextStyle(
                    fontSize: 8, color: pdf_core.PdfColors.grey)),
          );
        },
        build: (pw.Context context) => [
          pw.Header(
              level: 0,
              child: pw.Text(title,
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 18))),
          pw.SizedBox(height: 5),
          pw.Text('Student: ${student.name} (Index: ${student.indexNumber})',
              style: const pw.TextStyle(fontSize: 12)),
          pw.SizedBox(height: 10),
          pw.Text(
              'Attendance Summary: $presentDays/$totalDays days present (${attendancePercentage.toStringAsFixed(1)}%)',
              style: const pw.TextStyle(fontSize: 12)),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            context: null,
            cellAlignment: pw.Alignment.centerLeft,
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 10),
            headerDecoration:
                const pw.BoxDecoration(color: pdf_core.PdfColors.grey300),
            data: tableData,
            columnWidths: {
              0: const pw.FlexColumnWidth(2), // Date
              1: const pw.FlexColumnWidth(1.5), // Status
              2: const pw.FlexColumnWidth(2), // Subject
              3: const pw.FlexColumnWidth(2.5), // Marked At
            },
          ),
        ],
      ),
    );

    try {
      await Printing.sharePdf(
          bytes: await pdf.save(),
          filename:
              'Attendance_${sanitizedStudentName}_${monthName}_$year.pdf');
      _showToast("Attendance PDF for $monthName $year ready to be shared.");
    } catch (e) {
      _showToast("Error sharing attendance PDF: $e", error: true);
    }
  }

  // --- Edit Student Details Dialog ---
  void _showEditStudentDetailsDialog(Student student) {
    final nameController = TextEditingController(text: student.name);
    final emailController = TextEditingController(text: student.email);
    final parentNameController =
        TextEditingController(text: student.parentName);
    final parentPhoneController =
        TextEditingController(text: student.parentPhone);
    final whatsappController =
        TextEditingController(text: student.whatsappNumber);
    final addressController = TextEditingController(text: student.address);
    // For DOB, we'll use a text field and a date picker
    final dobController = TextEditingController(
        text: student.dob != null
            ? DateFormat('yyyy-MM-dd').format(student.dob!.toDate())
            : '');
    DateTime? selectedDob = student.dob?.toDate();
    String? selectedSex = student.sex;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        final textTheme = Theme.of(context).textTheme;
        return StatefulBuilder(// Use StatefulBuilder for dropdowns
            builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(kDefaultRadius)),
            title: Row(
              children: [
                Icon(Icons.edit_rounded, color: kPrimaryColor, size: 24),
                const SizedBox(width: 8),
                Text("Edit Student Details",
                    style:
                        textTheme.titleLarge?.copyWith(color: kPrimaryColor)),
              ],
            ),
            contentPadding: const EdgeInsets.fromLTRB(
                kDefaultPadding, kDefaultPadding / 2, kDefaultPadding, 0),
            content: Form(
              key: _formKeyStudentEdit,
              child: SizedBox(
                width: MediaQuery.of(context).size.width *
                    0.9, // Make dialog wider
                height:
                    MediaQuery.of(context).size.height * 0.7, // Set max height
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // Personal Information Section
                      _buildSectionHeader(
                          'Personal Information', Icons.person_rounded),
                      _buildFormField(
                        controller: nameController,
                        label: 'Full Name',
                        icon: Icons.person_outline_rounded,
                        validator: (value) =>
                            value!.isEmpty ? 'Name cannot be empty' : null,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _buildFormField(
                              controller: emailController,
                              label: 'Email Address',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) => value!.isEmpty
                                  ? 'Email cannot be empty'
                                  : (!GetUtils.isEmail(value)
                                      ? 'Invalid email'
                                      : null),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child:
                                _buildSexDropdown(selectedSex, setDialogState),
                          ),
                        ],
                      ),
                      _buildDateField(
                          dobController, selectedDob, setDialogState),

                      const SizedBox(height: kDefaultPadding),

                      // Parent/Guardian Information Section
                      _buildSectionHeader('Parent/Guardian Information',
                          Icons.supervisor_account_rounded),
                      _buildFormField(
                        controller: parentNameController,
                        label: 'Parent/Guardian Name',
                        icon: Icons.supervisor_account_outlined,
                        validator: (value) => value!.isEmpty
                            ? 'Parent name cannot be empty'
                            : null,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _buildFormField(
                              controller: parentPhoneController,
                              label: 'Parent Phone',
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                              validator: (value) => value!.isEmpty
                                  ? 'Parent phone cannot be empty'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildFormField(
                              controller: whatsappController,
                              label: 'WhatsApp (Optional)',
                              icon: Icons.chat_bubble_outline_rounded,
                              keyboardType: TextInputType.phone,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: kDefaultPadding),

                      // Additional Information Section
                      _buildSectionHeader(
                          'Additional Information', Icons.info_outline_rounded),
                      _buildFormField(
                        controller: addressController,
                        label: 'Home Address (Optional)',
                        icon: Icons.location_on_outlined,
                        maxLines: 2,
                      ),

                      const SizedBox(height: kDefaultPadding),
                    ],
                  ),
                ),
              ),
            ),
            actionsPadding: const EdgeInsets.symmetric(
                horizontal: kDefaultPadding, vertical: kDefaultPadding),
            actions: <Widget>[
              TextButton.icon(
                icon: const Icon(Icons.cancel_outlined),
                label: const Text("Cancel"),
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.save_rounded),
                label: const Text("Save Changes"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: kSecondaryColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(kDefaultRadius * 0.8)),
                ),
                onPressed: () async {
                  if (_formKeyStudentEdit.currentState!.validate()) {
                    final String? adminUid = AuthController.instance.user?.uid;
                    if (adminUid == null) {
                      _showStatusFlashMessage("Error: Admin not logged in.",
                          isError: true);
                      return;
                    }
                    final Map<String, dynamic> updatedData = {
                      'name': nameController.text.trim(),
                      'email': emailController.text.trim(),
                      'parentName': parentNameController.text.trim(),
                      'parentPhone': parentPhoneController.text.trim(),
                      'whatsappNumber': whatsappController.text.trim().isEmpty
                          ? null
                          : whatsappController.text.trim(),
                      'address': addressController.text.trim().isEmpty
                          ? null
                          : addressController.text.trim(),
                      'sex': selectedSex,
                      'dob': selectedDob != null
                          ? Timestamp.fromDate(selectedDob)
                          : null,
                      'updatedAt': Timestamp.now(),
                    };

                    try {
                      await FirebaseFirestore.instance
                          .collection('admins')
                          .doc(adminUid)
                          .collection('students')
                          .doc(student.id)
                          .update(updatedData);
                      _showStatusFlashMessage(
                          "Student details updated successfully!",
                          isError: false);
                      Navigator.of(context).pop();
                      // Reload student data
                      setState(() {
                        _studentFuture = FirebaseFirestore.instance
                            .collection('admins')
                            .doc(adminUid)
                            .collection('students')
                            .doc(widget.studentId)
                            .get()
                            .then((doc) => Student.fromFirestore(doc));
                      });
                    } catch (e) {
                      _showStatusFlashMessage(
                          "Error updating student details: $e",
                          isError: true);
                    }
                  }
                },
              ),
            ],
          );
        });
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(
          bottom: kDefaultPadding * 0.75, top: kDefaultPadding * 0.5),
      child: Row(
        children: [
          Icon(icon, size: 20, color: kPrimaryColor),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: kPrimaryColor,
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(left: 12),
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kPrimaryColor.withOpacity(0.3), Colors.transparent],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: kDefaultPadding * 0.75),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon:
              Icon(icon, size: 18, color: kPrimaryColor.withOpacity(0.7)),
          isDense: true, // Make text fields more compact
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(kDefaultRadius * 0.8),
            borderSide: BorderSide(color: kPrimaryColor.withOpacity(0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(kDefaultRadius * 0.8),
            borderSide: BorderSide(color: kPrimaryColor.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(kDefaultRadius * 0.8),
            borderSide: BorderSide(color: kPrimaryColor, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        keyboardType: keyboardType,
        validator: validator,
        maxLines: maxLines,
        autovalidateMode: AutovalidateMode.onUserInteraction,
      ),
    );
  }

  Widget _buildSexDropdown(String? selectedSex, StateSetter setDialogState) {
    return Padding(
      padding: const EdgeInsets.only(bottom: kDefaultPadding * 0.75),
      child: DropdownButtonFormField<String>(
        value: selectedSex,
        decoration: InputDecoration(
          labelText: 'Sex (Optional)',
          prefixIcon: Icon(Icons.wc_rounded,
              size: 18, color: kPrimaryColor.withOpacity(0.7)),
          isDense: true, // Make dropdown more compact
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(kDefaultRadius * 0.8),
            borderSide: BorderSide(color: kPrimaryColor.withOpacity(0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(kDefaultRadius * 0.8),
            borderSide: BorderSide(color: kPrimaryColor.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(kDefaultRadius * 0.8),
            borderSide: BorderSide(color: kPrimaryColor, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        items: ['Male', 'Female', 'Other'].map((String sex) {
          return DropdownMenuItem<String>(
            value: sex,
            child: Text(sex),
          );
        }).toList(),
        onChanged: (String? newValue) {
          setDialogState(() {
            selectedSex = newValue;
          });
        },
      ),
    );
  }

  Widget _buildDateField(TextEditingController dobController,
      DateTime? selectedDob, StateSetter setDialogState) {
    return Padding(
      padding: const EdgeInsets.only(bottom: kDefaultPadding * 0.75),
      child: TextFormField(
        controller: dobController,
        decoration: InputDecoration(
          labelText: 'Date of Birth (Optional)',
          prefixIcon: Icon(Icons.cake_outlined,
              size: 18, color: kPrimaryColor.withOpacity(0.7)),
          isDense: true, // Make date field more compact
          suffixIcon: IconButton(
            icon: Icon(Icons.calendar_today_rounded, color: kPrimaryColor),
            tooltip: 'Select Date',
            onPressed: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: selectedDob ??
                    DateTime.now().subtract(const Duration(
                        days: 365 * 18)), // Default to 18 years ago
                firstDate: DateTime(1950),
                lastDate: DateTime.now(),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: Theme.of(context).colorScheme.copyWith(
                            primary: kPrimaryColor,
                          ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                setDialogState(() {
                  selectedDob = picked;
                  dobController.text = DateFormat('yyyy-MM-dd').format(picked);
                });
              }
            },
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(kDefaultRadius * 0.8),
            borderSide: BorderSide(color: kPrimaryColor.withOpacity(0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(kDefaultRadius * 0.8),
            borderSide: BorderSide(color: kPrimaryColor.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(kDefaultRadius * 0.8),
            borderSide: BorderSide(color: kPrimaryColor, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        readOnly: true,
        onTap: () async {
          final DateTime? picked = await showDatePicker(
            context: context,
            initialDate: selectedDob ??
                DateTime.now().subtract(const Duration(days: 365 * 18)),
            firstDate: DateTime(1950),
            lastDate: DateTime.now(),
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: Theme.of(context).colorScheme.copyWith(
                        primary: kPrimaryColor,
                      ),
                ),
                child: child!,
              );
            },
          );
          if (picked != null) {
            setDialogState(() {
              selectedDob = picked;
              dobController.text = DateFormat('yyyy-MM-dd').format(picked);
            });
          }
        },
      ),
    );
  }

  // --- Edit Monthly Fees Dialog ---
  void _showEditMonthlyFeesDialog(Student student,
      List<FeeRecord> feesForSelectedYear, String selectedYear) {
    // Create controllers for each month's amount and paid status
    Map<int, TextEditingController> amountControllers = {};
    Map<int, bool> paidStatuses = {};
    Map<int, String?> feeDocIds = {}; // To store existing document IDs

    final allMonths = List.generate(12, (index) => index + 1);
    final feeMap = {for (var fee in feesForSelectedYear) fee.month: fee};

    for (int month in allMonths) {
      final fee = feeMap[month];
      amountControllers[month] =
          TextEditingController(text: fee?.amount.toStringAsFixed(0) ?? '0');
      paidStatuses[month] = fee?.paid ?? false;
      feeDocIds[month] = fee?.id;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        final textTheme = Theme.of(context).textTheme; // Get theme
        return StatefulBuilder(// Needed to update checkboxes inside the dialog
            builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                    kDefaultRadius)), // Use constant radius
            title: Text("Edit Fees for $selectedYear",
                style: textTheme.titleLarge), // Use theme style
            contentPadding:
                const EdgeInsets.all(kDefaultPadding), // Use constant padding
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: allMonths.map((month) {
                  final monthName = DateFormat('MMMM')
                      .format(DateTime(int.parse(selectedYear), month));
                  return Padding(
                    padding: const EdgeInsets.only(
                        bottom: kDefaultPadding * 0.75), // Consistent padding
                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.center, // Align items vertically
                      children: [
                        Expanded(
                            flex: 3,
                            child: Text(monthName,
                                style: textTheme
                                    .bodyMedium)), // Increased flex for month name
                        const SizedBox(width: kDefaultPadding / 2),
                        Expanded(
                          flex: 3, // Increased flex for amount field
                          child: TextFormField(
                            controller: amountControllers[month],
                            decoration: const InputDecoration(
                              // Use theme's InputDecoration
                              labelText: "Amount",
                              prefixIcon:
                                  Icon(Icons.attach_money_rounded, size: 18),
                              isDense: true, // Keep dense for compactness
                              // border: OutlineInputBorder(), // Use default theme border
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            validator: (value) {
                              // Add validation
                              if (value == null || value.isEmpty)
                                return 'Enter amount';
                              final amount = double.tryParse(value);
                              if (amount == null || amount < 0)
                                return 'Invalid amount';
                              return null;
                            },
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                          ),
                        ),
                        const SizedBox(width: kDefaultPadding / 2),
                        Expanded(
                          flex: 2, // Adjusted flex for checkbox
                          child: Transform.scale(
                            // Make checkbox slightly smaller
                            scale: 0.9,
                            child: CheckboxListTile(
                              title: Text("Paid",
                                  style:
                                      textTheme.bodySmall), // Use theme style
                              value: paidStatuses[month],
                              onChanged: (bool? value) {
                                setDialogState(() {
                                  paidStatuses[month] = value ?? false;
                                });
                              },
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              activeColor: kSuccessColor, // Use success color
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            actionsPadding: const EdgeInsets.symmetric(
                horizontal: kDefaultPadding,
                vertical: kDefaultPadding / 2), // Use constant padding
            actions: <Widget>[
              TextButton(
                  child: const Text("Cancel"),
                  onPressed: () => Navigator.of(context)
                      .pop()), // Use theme style implicitly
              ElevatedButton(
                // Use theme style implicitly
                child: const Text("Save Fee Changes"),
                onPressed: () async {
                  // Add validation check before proceeding
                  bool isValid = true;
                  for (int month in allMonths) {
                    final amountStr = amountControllers[month]!.text.trim();
                    final amount = double.tryParse(amountStr);
                    if (amount == null || amount < 0) {
                      isValid = false;
                      _showToast(
                          "Invalid amount entered for ${DateFormat('MMMM').format(DateTime(int.parse(selectedYear), month))}.",
                          error: true);
                      break;
                    }
                  }
                  if (!isValid) return; // Stop if validation fails

                  final String? adminUid = AuthController.instance.user?.uid;
                  if (adminUid == null) {
                    _showStatusFlashMessage("Error: Admin not logged in.",
                        isError: true);
                    return;
                  }
                  final firestore = FirebaseFirestore.instance;
                  final studentFeesRef = firestore
                      .collection('admins')
                      .doc(adminUid)
                      .collection('students')
                      .doc(student.id)
                      .collection('fees');
                  final batch = firestore.batch();
                  bool hasChanges = false;

                  for (int month in allMonths) {
                    final originalFee = feeMap[month];
                    final newAmountStr = amountControllers[month]!.text.trim();
                    final double? newAmount = double.tryParse(newAmountStr);
                    final bool newPaidStatus = paidStatuses[month]!;

                    if (newAmount == null || newAmount < 0) {
                      _showStatusFlashMessage(
                          "Invalid amount for ${DateFormat('MMMM').format(DateTime(int.parse(selectedYear), month))}.",
                          isError: true);
                      return; // Stop on first error
                    }

                    // Check if there's any change for this month
                    bool monthChanged =
                        (originalFee?.amount ?? 0) != newAmount ||
                            (originalFee?.paid ?? false) != newPaidStatus;
                    if (newPaidStatus && !(originalFee?.paid ?? false)) {
                      // If newly marked as paid
                      monthChanged = true;
                    }

                    if (monthChanged) {
                      hasChanges = true;
                      final docId = feeDocIds[month];
                      final docRef = docId != null && docId.isNotEmpty
                          ? studentFeesRef.doc(docId)
                          : studentFeesRef.doc(); // Create new if no ID

                      Map<String, dynamic> dataToSave = {
                        'year': int.parse(selectedYear),
                        'month': month,
                        'amount': newAmount,
                        'paid': newPaidStatus,
                        'updatedAt': Timestamp.now(),
                      };
                      if (newPaidStatus && !(originalFee?.paid ?? false)) {
                        // If newly paid
                        dataToSave['paidAt'] = Timestamp.now();
                      } else if (!newPaidStatus &&
                          (originalFee?.paid ?? false)) {
                        // If changed from paid to unpaid
                        dataToSave['paidAt'] = null;
                      } else if (newPaidStatus) {
                        // If already paid and still paid, keep original paidAt or update if null
                        dataToSave['paidAt'] =
                            originalFee?.paidAt ?? Timestamp.now();
                      }

                      batch.set(docRef, dataToSave, SetOptions(merge: true));
                    }
                  }

                  if (hasChanges) {
                    try {
                      await batch.commit();
                      _showStatusFlashMessage(
                          "Monthly fees updated successfully!",
                          isError: false);
                      Navigator.of(context).pop();
                      // Reload fees
                      setState(() {
                        _feesFuture = _fetchFees(_selectedFeeYear);
                      });
                    } catch (e) {
                      _showStatusFlashMessage("Error updating monthly fees: $e",
                          isError: true);
                    }
                  } else {
                    _showStatusFlashMessage("No changes detected in fees.",
                        isError: false);
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          );
        });
      },
    );
  }

  // --- Main Build Method ---
  @override
  Widget build(BuildContext context) {
    // Standard FutureBuilder implementation
    return Scaffold(
      appBar: _buildAppBar(context), // AppBar is now PreferredSizeWidget
      body: FutureBuilder<Student>(
        future: _studentFuture,
        builder: (context, studentSnapshot) {
          if (studentSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (studentSnapshot.hasError) {
            return Center(
                child: Text("Error loading student: ${studentSnapshot.error}"));
          }
          if (!studentSnapshot.hasData) {
            return const Center(child: Text("Student not found."));
          }

          final student = studentSnapshot.data!;

          // Need results before building student info section
          return FutureBuilder<List<ExamResult>>(
              future: _examResultsFuture, // Use the state future that updates
              builder: (context, resultsSnapshot) {
                // Handle loading and error states for results specifically
                List<ExamResult> currentResults = []; // Default to empty list
                Widget
                    resultsSectionWidget; // Placeholder for the results section

                if (resultsSnapshot.connectionState ==
                        ConnectionState.waiting &&
                    _selectedExamTermId != null) {
                  // Show loading indicator *only* for the results section if actively loading
                  resultsSectionWidget = const Center(
                      child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator()));
                  // Still build student info with empty results while loading new term
                } else if (resultsSnapshot.hasError) {
                  resultsSectionWidget = Center(
                      child: Text(
                          "Error loading results: ${resultsSnapshot.error}"));
                  // Build student info with empty results on error
                } else {
                  currentResults = resultsSnapshot.data ?? [];
                  // Now build the actual results section (needs terms)
                  resultsSectionWidget = FutureBuilder<List<ExamTerm>>(
                      future: _examTermsFuture,
                      builder: (context, termsSnapshot) {
                        if (termsSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator()));
                        }
                        if (termsSnapshot.hasError) {
                          return Center(
                              child: Text(
                                  "Error loading terms: ${termsSnapshot.error}"));
                        }
                        final allTerms = termsSnapshot.data ?? [];
                        // Pass the student object here as well
                        return _buildExamResultsSection(
                            student, allTerms, currentResults);
                      });
                }

                // Now build the main layout, passing the potentially updated currentResults
                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStudentInfoSection(student,
                          currentResults), // Pass student and results here
                      _buildStatusMessageWidget(), // Display status messages here
                      const Divider(),
                      resultsSectionWidget, // Display the results section (or loading/error)
                      const Divider(),
                      // Monthly Fees Section (needs fees future)
                      FutureBuilder<List<FeeRecord>>(
                          future:
                              _feesFuture, // This future updates based on filters
                          builder: (context, feesSnapshot) {
                            if (feesSnapshot.connectionState ==
                                    ConnectionState.waiting &&
                                _selectedFeeYear != null) {
                              // Show loading only when actively fetching for a selected year
                              return const Center(
                                  child: Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: CircularProgressIndicator()));
                            }
                            if (feesSnapshot.hasError) {
                              return Center(
                                  child: Text(
                                      "Error loading fees: ${feesSnapshot.error}"));
                            }
                            final allFees = feesSnapshot.data ?? [];
                            // Pass student object here
                            return _buildMonthlyFeesSection(student, allFees);
                          }),
                      const Divider(),
                      // Attendance Section (needs attendance future)
                      FutureBuilder<List<AttendanceRecord>>(
                          future:
                              _attendanceFuture, // This future updates based on filters
                          builder: (context, attendanceSnapshot) {
                            if (attendanceSnapshot.connectionState ==
                                    ConnectionState.waiting &&
                                _selectedAttendanceYear != null) {
                              // Show loading only when actively fetching for selected filters
                              return const Center(
                                  child: Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: CircularProgressIndicator()));
                            }
                            if (attendanceSnapshot.hasError) {
                              return Center(
                                  child: Text(
                                      "Error loading attendance: ${attendanceSnapshot.error}"));
                            }
                            final allAttendance = attendanceSnapshot.data ?? [];
                            // Pass student object here
                            return _buildAttendanceSection(
                                student, allAttendance);
                          }),
                    ],
                  ),
                );
              });
        },
      ),
    );
  }
}
