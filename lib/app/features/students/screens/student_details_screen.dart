import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edu_track/app/features/authentication/controllers/auth_controller.dart'; // Added
import 'package:edu_track/app/features/profile/screens/profile_settings_screen.dart';
import 'package:edu_track/app/utils/constants.dart';
import 'package:edu_track/main.dart'; // Import main for AppRoutes
import 'package:get/get.dart'; // Import GetX
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:saver_gallery/saver_gallery.dart';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart' hide TextSpan;
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
  });

  factory Student.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
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
class StudentDetailsScreen extends StatefulWidget { // Changed from ConsumerStatefulWidget
  final String studentId;

  const StudentDetailsScreen({super.key, required this.studentId}); // Use super.key

  @override
  State<StudentDetailsScreen> createState() => _StudentDetailsScreenState(); // Changed return type
}

class _StudentDetailsScreenState extends State<StudentDetailsScreen> { // Changed from ConsumerState
  final GlobalKey _qrCodeKey = GlobalKey();
  String? _selectedExamYear;
  String? _selectedExamTermId;
  String? _selectedFeeYear;
  bool _isCapturingQr = false; // State variable for QR capture visibility

  // TODO: Replace with Riverpod providers for data fetching and state management
  late Future<Student> _studentFuture;
  late Future<List<ExamTerm>> _examTermsFuture;
  late Future<List<ExamResult>> _examResultsFuture;
  late Future<List<FeeRecord>> _feesFuture;

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

    _studentFuture = adminRef
        .collection('students')
        .doc(widget.studentId)
        .get()
        .then((doc) {
          if (!doc.exists) throw Exception("Student not found"); // Handle non-existent student
          return Student.fromFirestore(doc);
        });

    _examTermsFuture = adminRef // Fetch terms nested under admin
        .collection('examTerms')
        .get()
        .then((snapshot) => snapshot.docs.map((doc) => ExamTerm.fromFirestore(doc)).toList());

    // Initial load for results and fees
    _examResultsFuture = _fetchExamResults(null); // Pass adminUid implicitly via _fetchExamResults
    _feesFuture = _fetchFees(null); // Pass adminUid implicitly via _fetchFees

     // Set default filter values after terms/fees are loaded
    _examTermsFuture.then((terms) {
      if (terms.isNotEmpty) {
        final latestTerm = terms.last; // Assuming terms are ordered or find latest
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
      if (parsedYear != null) { // Check if parsing was successful
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

  // --- UI Builders ---

  // Copied from StudentListScreen and adapted for constants
  Widget _buildProfileAvatar() {
    final String? userId = AuthController.instance.user?.uid;
    if (userId == null) {
      return IconButton(
        icon: Icon(Icons.account_circle_rounded, size: 30, color: kSecondaryColor), // Use constant
        tooltip: 'Profile Settings',
        onPressed: () => Get.toNamed(AppRoutes.profileSettings), // Use Get.toNamed
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
        Widget profileWidget = Icon(Icons.account_circle_rounded, size: 30, color: kSecondaryColor); // Use constant

        if (snapshot.connectionState == ConnectionState.active && snapshot.hasData && snapshot.data!.exists) {
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
            onTap: () => Get.toNamed(AppRoutes.profileSettings), // Use Get.toNamed (Already correct here, but ensuring consistency)
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding, vertical: kDefaultPadding / 2),
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
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kSecondaryColor), // Use constant
        tooltip: 'Back',
        onPressed: () => Navigator.pop(context),
      ),
      title: Text('Student Details', style: textTheme.titleLarge?.copyWith(color: kSecondaryColor)), // Use constant
      centerTitle: true,
      actions: [
        _buildProfileAvatar(), // Use the copied method
      ],
    );
  }

  // Updated to accept exam results for calculations and match layout
  Widget _buildStudentInfoSection(Student student, List<ExamResult> currentResults) {
    final textTheme = Theme.of(context).textTheme;
    // Calculate subject count (using currentResults as per original logic)
    int subjectCount = currentResults.length;

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
                        style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: kTextColor),
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow("Index No:", student.indexNumber),
                      _buildDetailRow("Grade:", student.grade),
                      _buildDetailRow("Subjects:", subjectCount.toString()),
                      _buildDetailRow("Sex:", student.sex ?? "N/A"),
                      _buildDetailRow("DOB:", student.dob != null ? DateFormat('yyyy/MM/dd').format(student.dob!.toDate()) : "N/A"),
                      _buildDetailRow("Parent:", student.parentName),
                      _buildDetailRow("Contact:", student.parentPhone),
                      if (student.whatsappNumber != null && student.whatsappNumber!.isNotEmpty)
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
                          borderRadius: BorderRadius.circular(kDefaultRadius), // Use constant
                          child: CachedNetworkImage(
                            imageUrl: student.photoUrl ?? 'https://via.placeholder.com/150',
                            placeholder: (context, url) => Container(color: kDisabledColor.withOpacity(0.3), child: const Center(child: CircularProgressIndicator(strokeWidth: 2.0, color: kPrimaryColor))),
                            errorWidget: (context, url, error) => Container(color: kDisabledColor.withOpacity(0.3), child: Icon(Icons.person, size: 50, color: kLightTextColor)),
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
                            colors: [kPrimaryColor, kPrimaryColor.withOpacity(0.8)], // Adjust gradient colors as needed
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(kDefaultRadius * 0.8),
                          boxShadow: [ // Optional: Add subtle shadow
                             BoxShadow(
                               color: kPrimaryColor.withOpacity(0.3),
                               blurRadius: 4,
                               offset: const Offset(0, 2),
                             ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.download_rounded, size: 18, color: kSecondaryColor), // Ensure icon color is white
                          label: Text("Download Photo", style: textTheme.labelLarge?.copyWith(fontSize: 13, color: kSecondaryColor)), // Ensure text color is white
                          onPressed: () => _downloadStudentPhoto(student.photoUrl, student.name),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent, // Make button transparent
                            shadowColor: Colors.transparent, // Remove button's own shadow
                            elevation: 0, // Remove button's own elevation
                            padding: const EdgeInsets.symmetric(vertical: 12), // Adjust padding if needed
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kDefaultRadius * 0.8)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // --- Download QR Code Button with Gradient ---
                      Container(
                        width: double.infinity,
                         decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [kPrimaryColor, kPrimaryColor.withOpacity(0.8)], // Adjust gradient colors as needed
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(kDefaultRadius * 0.8),
                           boxShadow: [ // Optional: Add subtle shadow
                             BoxShadow(
                               color: kPrimaryColor.withOpacity(0.3),
                               blurRadius: 4,
                               offset: const Offset(0, 2),
                             ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.qr_code_rounded, size: 18, color: kSecondaryColor), // Ensure icon color is white
                          label: Text("Download QR Code", style: textTheme.labelLarge?.copyWith(fontSize: 13, color: kSecondaryColor)), // Ensure text color is white
                          onPressed: _isCapturingQr ? null : () => _downloadQrCode(student.name), // Disable while capturing
                          style: ElevatedButton.styleFrom(
                             backgroundColor: Colors.transparent, // Make button transparent
                             shadowColor: Colors.transparent, // Remove button's own shadow
                             elevation: 0, // Remove button's own elevation
                             padding: const EdgeInsets.symmetric(vertical: 12), // Adjust padding if needed
                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kDefaultRadius * 0.8)),
                             // Handle disabled state appearance if needed
                             disabledBackgroundColor: Colors.transparent,
                             disabledForegroundColor: kSecondaryColor.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Use Visibility instead of Offstage for QR capture
            Visibility(
              visible: _isCapturingQr,
              maintainState: true, // Keep state even when hidden
              child: RepaintBoundary(
                key: _qrCodeKey,
                child: Container(
                  margin: const EdgeInsets.only(top: 10), // Add margin if needed when visible
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
      padding: const EdgeInsets.symmetric(vertical: 3.0), // Slightly more vertical padding
      child: RichText(
        text: TextSpan(
          // Use theme's bodyMedium style as base
          style: textTheme.bodyMedium?.copyWith(color: kTextColor),
          children: <TextSpan>[
            TextSpan(text: '$label ', style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: value, style: const TextStyle(color: kLightTextColor)), // Lighter color for value
          ],
        ),
      ),
    );
  }


  Widget _buildExamResultsSection(List<ExamTerm> allTerms, List<ExamResult> currentResults) {
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
         _selectedExamTermId = termsForSelectedYear.isNotEmpty ? termsForSelectedYear.first.id : null;
         _examResultsFuture = _fetchExamResults(_selectedExamTermId); // Reload results
       }));
    }


    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Exam Results", style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Row(
            children: [
              // Year Dropdown
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedExamYear,
                  hint: const Text("Select Year"),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedExamYear = newValue;
                      // Reset term when year changes, select first term of new year
                      final newTerms = allTerms.where((t) => t.year == _selectedExamYear).toList();
                      _selectedExamTermId = newTerms.isNotEmpty ? newTerms.first.id : null;
                      _examResultsFuture = _fetchExamResults(_selectedExamTermId); // Fetch new results
                    });
                  },
                  items: years.map<DropdownMenuItem<String>>((String year) {
                    return DropdownMenuItem<String>(
                      value: year,
                      child: Text(year),
                    );
                  }).toList(),
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 8),
              // Term Dropdown
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedExamTermId,
                  hint: const Text("Select Term"),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedExamTermId = newValue;
                       _examResultsFuture = _fetchExamResults(_selectedExamTermId); // Fetch new results
                    });
                  },
                  items: termsForSelectedYear.map<DropdownMenuItem<String>>((ExamTerm term) {
                    return DropdownMenuItem<String>(
                      value: term.id,
                      child: Text(term.termOnlyName, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                   decoration: const InputDecoration(border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 8),
              // Edit Button
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: _selectedExamTermId == null ? null : () {
                   final selectedTerm = allTerms.firstWhere((t) => t.id == _selectedExamTermId);
                  _showEditExamResultsDialog(currentResults, selectedTerm);
                },
                tooltip: "Edit Results",
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Bar Chart
          if (currentResults.isNotEmpty)
             _buildExamChart(currentResults)
          else if (_selectedExamTermId != null)
             const Center(child: Text("No results found for this term."))
          else
             const Center(child: Text("Select a year and term to view results.")),

        ],
      ),
    );
  }

  Widget _buildExamChart(List<ExamResult> results) {
    if (results.isEmpty) return const SizedBox(height: 150, child: Center(child: Text("No data")));

    // Find max marks across results for Y-axis scaling, default to 100
    final double maxPossibleMark = results.fold<double>(100.0, (prev, elem) => elem.maxMarks > prev ? elem.maxMarks : prev);
    final double maxY = (maxPossibleMark / 10).ceil() * 10; // Round up to nearest 10

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
                   final result = results[groupIndex];
                   return BarTooltipItem(
                     '${result.subject}\n',
                     const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                     children: <TextSpan>[
                       TextSpan( // Use const constructor
                         text: result.marks.toStringAsFixed(0), // Show marks as integer
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
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < results.length) {
                     // Abbreviate long subject names if necessary
                     String subjectName = results[index].subject;
                     if (subjectName.length > 5) {
                       subjectName = '${subjectName.substring(0, 3)}.';
                     }
                    return SideTitleWidget(
                       meta: meta, // Added required meta parameter
                       space: 4.0,
                       child: Text(subjectName, style: const TextStyle(fontSize: 10)),
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
                   if (value % 20 == 0) { // Show labels every 20 marks
                     return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10));
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
               return FlLine( // Removed const
                 color: Colors.grey.withOpacity(0.3),
                 strokeWidth: 1,
               );
             },
           ),
          barGroups: results.asMap().entries.map((entry) {
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

  Widget _buildMonthlyFeesSection(List<FeeRecord> allFees) {
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
     final feeMap = { for (var fee in feesForSelectedYear) fee.month : fee };

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
                  hint: const Text("Select Year"),
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
                   decoration: const InputDecoration(border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.share),
                label: const Text(""),
                onPressed: _selectedFeeYear == null ? null : () => _exportFeesToExcel(feesForSelectedYear, _selectedFeeYear!),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Fees Table
          if (_selectedFeeYear != null)
            SingleChildScrollView( // Make table horizontally scrollable if needed
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 30, // Adjust spacing
                columns: const [
                  DataColumn(label: Text('Month', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Payment', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold))), // Optional: Show amount
                  DataColumn(label: Text('Paid Date', style: TextStyle(fontWeight: FontWeight.bold))), // Optional: Show paid date
                ],
                rows: allMonths.map((month) {
                   final fee = feeMap[month];
                   final monthName = DateFormat('MMMM').format(DateTime(int.parse(_selectedFeeYear!), month));
                   final isPaid = fee?.paid ?? false;
                   final amount = fee?.amount.toStringAsFixed(2) ?? '-';
                   final paidDate = fee?.paidAt != null ? DateFormat('yyyy-MM-dd').format(fee!.paidAt!.toDate()) : '-';

                   return DataRow(
                     color: WidgetStateProperty.resolveWith<Color?>(
                       (Set<WidgetState> states) {
                         // Optional: Alternate row colors
                         // return allMonths.indexOf(month).isEven ? Colors.grey.shade100 : null;
                         return null;
                       },
                     ),
                     cells: [
                       DataCell(Text(monthName)),
                       DataCell(
                         isPaid
                             ? const Row(children: [Icon(Icons.check_circle, color: Colors.green, size: 18), SizedBox(width: 4), Text('Paid')])
                             : const Row(children: [Icon(Icons.cancel, color: Colors.red, size: 18), SizedBox(width: 4), Text('Unpaid')]),
                       ),
                        DataCell(Text(amount)),
                        DataCell(Text(paidDate)),
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

  // --- Action Handlers ---

  // Updated QR Code download using Visibility strategy
  Future<void> _downloadQrCode(String studentName) async {
    setState(() { _isCapturingQr = true; }); // Show the QR code

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

      RenderRepaintBoundary boundary = _qrCodeKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      // No need to check debugNeedsPaint here as Visibility should handle rendering

      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        _showToast("Error: Could not convert QR code to image data.", error: true);
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
          final androidInfo = await DeviceInfoPlugin().androidInfo; // Need device_info_plus package
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
       } else { // For iOS or other platforms if needed
          if (!status.isGranted) {
             status = await Permission.storage.request(); // Or photos for iOS
          }
       }


      if (status.isGranted) {
        final result = await SaverGallery.saveImage(
          pngBytes,
          fileName: "qrcode_${studentName.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}",
          androidRelativePath: "Pictures/EduTrack/QRCodes",
          skipIfExists: false,
        );

        if (result.isSuccess) {
          _showToast("QR Code downloaded successfully!");
        } else {
          _showToast("Failed to save QR Code: ${result.errorMessage}", error: true);
        }
      } else {
         _showToast("Storage permission denied. Cannot save QR Code.", error: true);
      }

    } catch (e) {
      print("Error downloading QR Code: $e");
      _showToast("Error capturing QR Code: $e", error: true);
    } finally {
      // Hide the QR code again regardless of success/failure
      if (mounted) { // Check if widget is still mounted before calling setState
         setState(() { _isCapturingQr = false; });
      }
    }
  }

  Future<void> _downloadStudentPhoto(String? photoUrl, String studentName) async {
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
             fileName: "photo_${studentName.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}", // Use fileName
             androidRelativePath: "Pictures/EduTrack/StudentPhotos", // Example path
             skipIfExists: false // Use skipIfExists
           );
           if (result.isSuccess) {
             _showToast("Photo downloaded successfully!");
           } else {
             _showToast("Failed to save photo: ${result.errorMessage}", error: true);
           }
         } else {
           _showToast("Failed to download photo (status code: ${response.statusCode}).", error: true);
         }


     } catch (e) {
       print("Error downloading photo: $e");
       _showToast("Error downloading photo: $e", error: true);
     }
  }

  Future<void> _exportFeesToExcel(List<FeeRecord> fees, String year) async {
    if (fees.isEmpty) {
      _showToast("No fee data for $year to export.", error: true);
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
      final feeMap = { for (var fee in fees) fee.month : fee };

      for (var month in allMonths) {
        final fee = feeMap[month];
        final monthName = DateFormat('MMMM').format(DateTime(int.parse(year), month));
        final status = fee?.paid ?? false ? 'Paid' : 'Unpaid';
        final amount = fee?.amount ?? 0.0;
        final paidDate = fee?.paidAt != null ? DateFormat('yyyy-MM-dd').format(fee!.paidAt!.toDate()) : '-';

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
      final sanitizedStudentIdFile = widget.studentId.replaceAll(RegExp(r'[\\/*?:"<>|]'), '_');
      final fileName = 'student_${sanitizedStudentIdFile}_fees_$year.xlsx';
      final filePath = '$path/$fileName';
      print("Saving temporary Excel file to: $filePath");

      // Save the file to the temporary directory
      final fileBytes = excel.save();
      if (fileBytes != null) {
        final file = File(filePath);
        await file.writeAsBytes(fileBytes, flush: true); // Ensure bytes are written

        // Use share_plus to share the file
        final xFile = XFile(filePath, name: fileName, mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
        final result = await Share.shareXFiles([xFile], text: 'Student Fees Export $year');

        // Check share result status (optional)
        if (result.status == ShareResultStatus.success) {
           _showToast("Excel file ready to be saved/shared.");
        } else if (result.status == ShareResultStatus.dismissed) {
           _showToast("Share cancelled.", error: true);
        } else {
           _showToast("Sharing failed: ${result.status}", error: true);
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

  void _showEditExamResultsDialog(List<ExamResult> currentResults, ExamTerm term) {
     // Create controllers for each subject's text field
     Map<String, TextEditingController> controllers = {};
     Map<String, String> initialMarks = {}; // Store initial marks to detect changes
     Map<String, String> resultDocIds = {}; // Store doc IDs for updating

     // Initialize controllers with current marks
     for (String subject in term.subjects) {
        final result = currentResults.firstWhere(
           (r) => r.subject == subject,
           orElse: () => ExamResult(id: '', termId: term.id, subject: subject, marks: 0, maxMarks: 100) // Default if no result exists yet
        );
        controllers[subject] = TextEditingController(text: result.marks.toStringAsFixed(0));
        initialMarks[subject] = result.marks.toStringAsFixed(0);
        // Store the document ID if it exists, otherwise it's a new entry
        if (currentResults.any((r) => r.subject == subject)) {
           resultDocIds[subject] = currentResults.firstWhere((r) => r.subject == subject).id;
        }
     }

     showDialog(
       context: context,
       builder: (BuildContext context) {
         return AlertDialog(
           title: Text("Edit Results - ${term.name}"),
           content: SingleChildScrollView(
             child: Column(
               mainAxisSize: MainAxisSize.min,
               children: term.subjects.map((subject) {
                 return Padding(
                   padding: const EdgeInsets.symmetric(vertical: 8.0),
                   child: TextField(
                     controller: controllers[subject],
                     decoration: InputDecoration(
                       labelText: subject,
                       border: const OutlineInputBorder(),
                       hintText: "Enter marks", // Placeholder if empty
                     ),
                     keyboardType: TextInputType.numberWithOptions(decimal: true),
                   ),
                 );
               }).toList(),
             ),
           ),
           actions: <Widget>[
             TextButton(
               child: const Text("Cancel"),
               onPressed: () {
                 Navigator.of(context).pop();
               },
             ),
             ElevatedButton(
               child: const Text("Save Changes"),
               onPressed: () async {
                  // --- Save Logic ---
                  final firestore = FirebaseFirestore.instance;
                  final batch = firestore.batch();
                  bool hasChanges = false;
                  bool errorOccurred = false;

                  for (String subject in term.subjects) {
                     final controller = controllers[subject]!;
                     final currentMarkStr = controller.text.trim();
                     final initialMarkStr = initialMarks[subject]!;

                     if (currentMarkStr != initialMarkStr) {
                        final double? newMark = double.tryParse(currentMarkStr);
                        if (newMark == null || newMark < 0 || newMark > 100) { // Basic validation
                           _showToast("Invalid mark for $subject. Must be between 0 and 100.", error: true);
                           errorOccurred = true;
                           break; // Stop processing on first error
                        }

                        hasChanges = true;
                        final resultDocId = resultDocIds[subject];
                        final docRef = resultDocId != null
                           ? firestore.collection('students').doc(widget.studentId).collection('examResults').doc(resultDocId)
                           : firestore.collection('students').doc(widget.studentId).collection('examResults').doc(); // Create new doc if needed

                        batch.set(docRef, {
                           'term': term.id,
                           'subject': subject,
                           'marks': newMark,
                           'maxMarks': 100, // Assuming max marks is 100
                           'resultDate': Timestamp.now(), // Update timestamp
                           'updatedBy': 'ADMIN_UID_PLACEHOLDER', // TODO: Get actual admin UID
                        }, SetOptions(merge: true)); // Use merge to create or update
                     }
                  }

                  if (errorOccurred) return; // Don't proceed if validation failed

                  if (hasChanges) {
                     try {
                       await batch.commit();
                       _showToast("Exam results updated successfully!");
                       // Reload results for the current term
                       setState(() {
                          _examResultsFuture = _fetchExamResults(_selectedExamTermId);
                       });
                       Navigator.of(context).pop(); // Close dialog
                     } catch (e) {
                       print("Error updating exam results: $e");
                       _showToast("Error updating results: $e", error: true);
                     }
                  } else {
                     _showToast("No changes detected.");
                     Navigator.of(context).pop(); // Close dialog even if no changes
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
         fontSize: 16.0
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
            return Center(child: Text("Error loading student: ${studentSnapshot.error}"));
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
                Widget resultsSectionWidget; // Placeholder for the results section

                if (resultsSnapshot.connectionState == ConnectionState.waiting && _selectedExamTermId != null) {
                   // Show loading indicator *only* for the results section if actively loading
                   resultsSectionWidget = const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()));
                   // Still build student info with empty results while loading new term
                } else if (resultsSnapshot.hasError) {
                   resultsSectionWidget = Center(child: Text("Error loading results: ${resultsSnapshot.error}"));
                   // Build student info with empty results on error
                } else {
                   currentResults = resultsSnapshot.data ?? [];
                   // Now build the actual results section (needs terms)
                   resultsSectionWidget = FutureBuilder<List<ExamTerm>>(
                     future: _examTermsFuture,
                     builder: (context, termsSnapshot) {
                       if (termsSnapshot.connectionState == ConnectionState.waiting) {
                         return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()));
                       }
                       if (termsSnapshot.hasError) {
                         return Center(child: Text("Error loading terms: ${termsSnapshot.error}"));
                       }
                       final allTerms = termsSnapshot.data ?? [];
                       // Pass the already fetched currentResults here
                       return _buildExamResultsSection(allTerms, currentResults);
                     }
                   );
                }

                // Now build the main layout, passing the potentially updated currentResults
                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStudentInfoSection(student, currentResults), // Pass results here
                      const Divider(),
                      resultsSectionWidget, // Display the results section (or loading/error)
                      const Divider(),
                      // Monthly Fees Section (needs fees future)
                      FutureBuilder<List<FeeRecord>>(
                        future: _feesFuture, // This future updates based on filters
                        builder: (context, feesSnapshot) {
                           if (feesSnapshot.connectionState == ConnectionState.waiting && _selectedFeeYear != null) {
                              // Show loading only when actively fetching for a selected year
                              return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()));
                           }
                           if (feesSnapshot.hasError) {
                             return Center(child: Text("Error loading fees: ${feesSnapshot.error}"));
                           }
                           final allFees = feesSnapshot.data ?? [];
                           return _buildMonthlyFeesSection(allFees);
                        }
                      ),
                    ],
                  ),
                );
             }
          );
        },
      ),
    );
  }
}