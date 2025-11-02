// import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edu_track/app/features/authentication/controllers/auth_controller.dart';
import 'package:edu_track/app/services/whatsapp_service.dart';
// import 'package:edu_track/app/features/profile/screens/profile_settings_screen.dart'; // For profile avatar logic
import 'package:edu_track/app/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:edu_track/main.dart'; // Import main to access AppRoutes

// Model to hold student data (can be moved to a separate models file later)
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

// Enum to manage the different states of the screen
enum ScreenState {
  initial,
  scanning,
  showIndexInput,
  showStudentDetails,
  showStudentDetailsWithPendingPayments, // ✅ NEW STATE for the updated flow
  showPaymentTypeSelection, // Keep for backward compatibility
  showMonthlyPaymentInput, // Keep for backward compatibility
  showDailyPaymentInput // Keep for backward compatibility
}

// Enum for payment types
enum PaymentType { monthly, daily }

class QRCodeScannerScreen extends StatefulWidget {
  const QRCodeScannerScreen({super.key});

  @override
  State<QRCodeScannerScreen> createState() => _QRCodeScannerScreenState();
}

// ✅ NEW: Model for pending payment items
class PendingPaymentItem {
  final String id;
  final List<String> subjects;
  final String paymentType;
  final String period;
  final double amount;
  final double pendingAmount;
  final DateTime dueDate;
  final String description;
  final String status;

  PendingPaymentItem({
    required this.id,
    required this.subjects,
    required this.paymentType,
    required this.period,
    required this.amount,
    required this.pendingAmount,
    required this.dueDate,
    required this.description,
    required this.status,
  });

  factory PendingPaymentItem.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Format period based on payment type
    String period = 'Unknown';
    final paymentType = data['paymentType'] ?? 'monthly';

    if (paymentType == 'monthly') {
      final month = data['month'] as int?;
      final year = data['year'] as int?;
      if (month != null && year != null) {
        final date = DateTime(year, month);
        period = DateFormat('MMMM yyyy').format(date);
      }
    } else if (paymentType == 'daily') {
      final dateStr = data['date'] as String?;
      if (dateStr != null) {
        final date = DateTime.parse(dateStr);
        period = DateFormat('dd/MM/yyyy').format(date);
      }
    }

    return PendingPaymentItem(
      id: doc.id,
      subjects: List<String>.from(data['subjects'] ?? []),
      paymentType: paymentType,
      period: period,
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      pendingAmount: (data['pendingAmount'] as num?)?.toDouble() ?? 0.0,
      dueDate: (data['pendingAt'] as Timestamp?)?.toDate() ??
          (data['paidAt'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      description: data['description'] ?? '',
      status: data['status'] ??
          (data['paid'] == true
              ? 'PAID'
              : 'PENDING'), // ✅ Backward compatibility
    );
  }

  // Helper methods for display formatting
  String getMonthYearDisplay() => period;

  String getDueDateDisplay() {
    return DateFormat('dd/MM/yyyy').format(dueDate);
  }
}

class _QRCodeScannerScreenState extends State<QRCodeScannerScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final MobileScannerController _scannerController = MobileScannerController(
      // facing: CameraFacing.back, // Default is back
      // detectionSpeed: DetectionSpeed.normal, // Default
      // formats: [BarcodeFormat.qrCode] // Default is all
      );
  final _indexController = TextEditingController();
  final _amountController = TextEditingController();
  final _formKeyIndex = GlobalKey<FormState>();
  final _formKeyPayment = GlobalKey<FormState>();

  ScreenState _currentScreenState = ScreenState.initial;
  Student? _foundStudent;
  bool _isLoading = false;
  String? _statusMessage;
  bool _isError = false;
  String? _selectedMonth; // For monthly payment dropdown
  DateTime? _selectedDate; // For daily payment date picker
  List<String> _selectedSubjects = []; // For both payment types
  String? _academyName;

  // ✅ NEW: State variables for pending payments functionality
  List<PendingPaymentItem> _existingPendingPayments = [];
  String _pendingPaymentsFilter = 'all'; // 'all', 'monthly', 'daily'
  // ✅ NEW: Subject filter for pending payments ('All' means no subject filter)
  String _pendingSubjectFilter = 'All';
  bool _attendanceMarked = false;

  // ✅ NEW: Form controllers for dynamic payment dialogs
  final _paymentFormKey = GlobalKey<FormState>();
  final _pendingFormKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _pendingReasonController = TextEditingController();
  String? _selectedPaymentTypeForDialog; // 'monthly' or 'daily' for dialogs

  // List of months for the dropdown
  final List<String> _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];

  @override
  void initState() {
    super.initState();
    _fetchAdminDetails(); // Fetch token and academy name on init
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _indexController.dispose();
    _amountController.dispose();
    _descriptionController.dispose(); // ✅ NEW
    _pendingReasonController.dispose(); // ✅ NEW
    super.dispose();
  }

  // --- Fetch Admin Details (Token & Academy Name) ---
  Future<void> _fetchAdminDetails() async {
    final String? userId = AuthController.instance.user?.uid;
    if (userId == null) {
      _showStatusMessage("Error: Admin user not logged in.", isError: true);
      return;
    }
    try {
      final doc = await _firestore
          .collection('admins')
          .doc(userId)
          .collection('adminProfile')
          .doc('profile')
          .get();
      if (doc.exists) {
        final data = doc.data();
        _academyName = data?['academyName'];
        if (_academyName == null) {
          print("Warning: Academy Name not found in admin profile.");
          // Optionally show a non-blocking warning to the user
        }
      } else {
        print("Warning: Admin profile document not found.");
      }
    } catch (e) {
      print("Error fetching admin details: $e");
      _showStatusMessage("Error fetching configuration.", isError: true);
    }
  }

  // --- Status Message Logic ---
  void _showStatusMessage(String message,
      {bool isError = false, Duration duration = const Duration(seconds: 3)}) {
    if (!mounted) return;
    setState(() {
      _statusMessage = message;
      _isError = isError;
    });
    Future.delayed(duration, () {
      if (mounted) {
        setState(() {
          _statusMessage = null;
        });
      }
    });
  }

  // --- Reusable AppBar Profile Avatar Logic (Adapted from AddTeacherScreen) ---
  Widget _buildProfileAvatar() {
    final String? userId = AuthController.instance.user?.uid;
    if (userId == null) {
      return IconButton(
        icon: Icon(Icons.account_circle_rounded,
            size: 30, color: kLightTextColor),
        tooltip: 'Profile Settings',
        onPressed: () =>
            Get.toNamed(AppRoutes.profileSettings), // Use Get.toNamed
      );
    }
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('admins')
          .doc(userId)
          .collection('adminProfile')
          .doc('profile')
          .snapshots(),
      builder: (context, snapshot) {
        String? photoUrl;
        Widget profileWidget = Icon(Icons.account_circle_rounded,
            size: 30, color: kLightTextColor); // Default icon

        if (snapshot.connectionState == ConnectionState.active &&
            snapshot.hasData &&
            snapshot.data!.exists) {
          var data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data != null && data.containsKey('profilePhotoUrl')) {
            photoUrl = data['profilePhotoUrl'] as String?;
          }
        } else if (snapshot.hasError) {
          print("Error fetching admin profile: ${snapshot.error}");
        }

        if (photoUrl != null && photoUrl.isNotEmpty) {
          profileWidget = CircleAvatar(
            radius: 18,
            backgroundColor: kLightTextColor.withOpacity(0.5),
            backgroundImage: CachedNetworkImageProvider(
                photoUrl), // Use CachedNetworkImageProvider
            onBackgroundImageError: (exception, stackTrace) {
              print("Error loading profile image: $exception");
              // No need for setState here as StreamBuilder handles updates
            },
          );
        }

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(kDefaultRadius * 2),
            onTap: () =>
                Get.toNamed(AppRoutes.profileSettings), // Use Get.toNamed
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

  // --- Firestore Logic ---
  Future<void> _findStudentByQrCode(String qrCodeData) async {
    if (qrCodeData.isEmpty) return;
    setState(() {
      _isLoading = true;
      _currentScreenState = ScreenState.initial;
    }); // Show loading on initial screen

    try {
      final String? adminUid = AuthController.instance.user?.uid;
      if (adminUid == null) throw Exception("Admin not logged in.");

      final querySnapshot = await _firestore
          .collection('admins')
          .doc(adminUid)
          .collection('students')
          .where('qrCodeData', isEqualTo: qrCodeData)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        _foundStudent = Student.fromFirestore(querySnapshot.docs.first);

        // ✅ CORRECTED: Go to student details view (which now shows pending payments + action buttons)
        setState(() {
          _currentScreenState = ScreenState.showStudentDetails;
        });
        _showStatusMessage('Scanned Successfully!', isError: false);

        // ✅ NEW: Fetch exam results and calculate average score
        await _fetchAndCalculateAverageScore();

        // Fetch pending payments for this student
        await _fetchExistingPendingPayments();
      } else {
        _foundStudent = null;
        _showStatusMessage('QR Code does not match any student.',
            isError: true);
        setState(() {
          _currentScreenState = ScreenState.initial;
        }); // Go back to initial on error
      }
    } catch (e) {
      print("Error finding student by QR code: $e");
      _showStatusMessage('Error finding student. Please try again.',
          isError: true);
      _foundStudent = null;
      setState(() {
        _currentScreenState = ScreenState.initial;
      }); // Go back to initial on error
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _findStudentByIndex(String indexNumber) async {
    if (indexNumber.isEmpty) return;
    setState(() => _isLoading = true);
    FocusScope.of(context).unfocus(); // Hide keyboard

    try {
      final String? adminUid = AuthController.instance.user?.uid;
      if (adminUid == null) throw Exception("Admin not logged in.");

      final querySnapshot = await _firestore
          .collection('admins')
          .doc(adminUid)
          .collection('students')
          .where('indexNumber', isEqualTo: indexNumber.trim())
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        _foundStudent = Student.fromFirestore(querySnapshot.docs.first);

        // ✅ CORRECTED: Go to student details view
        setState(() {
          _currentScreenState = ScreenState.showStudentDetails;
        });
        _showStatusMessage('Index No Matched!', isError: false);

        // ✅ NEW: Fetch exam results and calculate average score
        await _fetchAndCalculateAverageScore();

        // Fetch pending payments for this student
        await _fetchExistingPendingPayments();
      } else {
        _foundStudent = null;
        _showStatusMessage('Index number does not match any student.',
            isError: true);
        // Stay on the index input screen on error
        setState(() {
          _currentScreenState = ScreenState.showIndexInput;
        });
      }
    } catch (e) {
      print("Error finding student by index: $e");
      _showStatusMessage('Error finding student. Please try again.',
          isError: true);
      _foundStudent = null;
      setState(() {
        _currentScreenState = ScreenState.showIndexInput;
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Show subject selection dialog before marking attendance
  Future<void> _showSubjectSelectionDialog() async {
    if (_foundStudent == null || _foundStudent!.subjects.isEmpty) {
      _showStatusMessage('No subjects found for this student.', isError: true);
      return;
    }

    final selectedSubject = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Subject for ${_foundStudent!.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Choose the subject to mark attendance for:'),
              const SizedBox(height: 16),
              Container(
                constraints: BoxConstraints(maxHeight: 300),
                child: SingleChildScrollView(
                  child: Column(
                    children: _foundStudent!.subjects
                        .map((subject) => ListTile(
                              title: Text(subject),
                              leading: Icon(Icons.subject_outlined),
                              onTap: () => Navigator.of(context).pop(subject),
                              trailing:
                                  const Icon(Icons.arrow_forward_ios, size: 16),
                            ))
                        .toList(),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );

    if (selectedSubject != null) {
      await _markAttendanceWithSubject(selectedSubject);
    }
  }

  // Updated attendance marking with subject and WhatsApp notification
  Future<void> _markAttendanceWithSubject(String subject) async {
    if (_foundStudent == null) return;
    setState(() => _isLoading = true);

    try {
      final String? adminUid = AuthController.instance.user?.uid;
      if (adminUid == null) throw Exception("Admin not logged in.");

      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final attendanceRef = _firestore
          .collection('admins')
          .doc(adminUid)
          .collection('students')
          .doc(_foundStudent!.id)
          .collection('attendance');

      // Check if already marked for this subject today
      final existingRecord = await attendanceRef
          .where('date', isEqualTo: today)
          .where('subject', isEqualTo: subject)
          .limit(1)
          .get();

      if (existingRecord.docs.isNotEmpty) {
        _showStatusMessage('Attendance already marked for $subject today.',
            isError: true);
        return;
      }

      // Mark attendance in Firestore with subject
      await attendanceRef.add({
        'date': today,
        'subject': subject,
        'status': 'present',
        'markedBy': adminUid,
        'markedAt': Timestamp.now(),
      });

      // Send WhatsApp notification
      final whatsappSent = await WhatsAppService.sendAttendanceNotification(
        studentName: _foundStudent!.name,
        parentName: _foundStudent!.parentName,
        parentPhone: _foundStudent!
            .whatsappNumber, // Use whatsappNumber instead of parentPhone
        subject: subject,
        className: _foundStudent!.className,
        schoolName: _academyName ?? 'EduTrack Academy',
      );

      if (whatsappSent) {
        _showStatusMessage('Attendance marked & WhatsApp sent! 📱✅',
            isError: false);
      } else {
        _showStatusMessage(
            'Attendance marked but WhatsApp notification failed.',
            isError: true);
      }

      // ✅ CORRECTED: Stay on student details page after attendance marking
      setState(() {
        _attendanceMarked = true;
        _currentScreenState =
            ScreenState.showStudentDetails; // Stay on student details
      });

      // Refresh pending payments for this student
      await _fetchExistingPendingPayments();
    } catch (e) {
      print("Error marking attendance: $e");
      _showStatusMessage('Failed to mark attendance: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markMonthlyPayment() async {
    if (_foundStudent == null ||
        _selectedMonth == null ||
        _selectedSubjects.isEmpty ||
        !_formKeyPayment.currentState!.validate()) {
      if (_selectedSubjects.isEmpty) {
        _showStatusMessage('Please select at least one subject', isError: true);
      }
      return;
    }

    setState(() => _isLoading = true);
    FocusScope.of(context).unfocus();

    try {
      final String? adminUid = AuthController.instance.user?.uid;
      if (adminUid == null) throw Exception("Admin not logged in.");

      final amount = double.tryParse(_amountController.text.trim());
      if (amount == null || amount <= 0) {
        throw Exception("Invalid amount entered.");
      }

      final monthIndex = _months.indexOf(_selectedMonth!) + 1; // 1-based index
      final currentYear = DateTime.now().year;

      final feesRef = _firestore
          .collection('admins')
          .doc(adminUid)
          .collection('students')
          .doc(_foundStudent!.id)
          .collection('fees');

      // Add monthly payment record with new structure
      await feesRef.add({
        'paymentType': 'monthly',
        'year': currentYear,
        'month': monthIndex,
        'date': null, // null for monthly payments
        'subjects': _selectedSubjects,
        'amount': amount,
        'paid': true,
        'paidAt': Timestamp.now(),
        'paymentMethod': 'Manual/QR',
        'markedBy': adminUid,
        'description':
            'Monthly fee for ${_selectedSubjects.join(", ")} - $_selectedMonth $currentYear',
      });

      // Send WhatsApp notification for monthly payment
      final whatsappSent = await WhatsAppService.sendMonthlyPaymentNotification(
        studentName: _foundStudent!.name,
        parentName: _foundStudent!.parentName,
        parentPhone: _foundStudent!.whatsappNumber,
        amount: amount,
        month: _selectedMonth!,
        year: currentYear,
        subjects: _selectedSubjects,
        schoolName: _academyName ?? 'EduTrack Academy',
      );

      if (whatsappSent) {
        _showStatusMessage('Monthly payment marked & WhatsApp sent! 💰📱✅',
            isError: false);
      } else {
        _showStatusMessage(
            'Monthly payment marked but WhatsApp notification failed.',
            isError: true);
      }

      // Navigate back to initial screen
      _resetPaymentState();
      setState(() {
        _currentScreenState = ScreenState.initial;
        _foundStudent = null;
      });
    } catch (e) {
      print("Error marking monthly payment: $e");
      _showStatusMessage('Failed to mark payment. $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markDailyPayment() async {
    if (_foundStudent == null ||
        _selectedDate == null ||
        _selectedSubjects.isEmpty ||
        !_formKeyPayment.currentState!.validate()) {
      if (_selectedDate == null) {
        _showStatusMessage('Please select a date', isError: true);
      } else if (_selectedSubjects.isEmpty) {
        _showStatusMessage('Please select at least one subject', isError: true);
      }
      return;
    }

    setState(() => _isLoading = true);
    FocusScope.of(context).unfocus();

    try {
      final String? adminUid = AuthController.instance.user?.uid;
      if (adminUid == null) throw Exception("Admin not logged in.");

      final amount = double.tryParse(_amountController.text.trim());
      if (amount == null || amount <= 0) {
        throw Exception("Invalid amount entered.");
      }

      final dateString =
          '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';

      final feesRef = _firestore
          .collection('admins')
          .doc(adminUid)
          .collection('students')
          .doc(_foundStudent!.id)
          .collection('fees');

      // Add daily payment record with new structure
      await feesRef.add({
        'paymentType': 'daily',
        'year': _selectedDate!.year,
        'month': _selectedDate!.month,
        'date': dateString,
        'subjects': _selectedSubjects,
        'amount': amount,
        'paid': true,
        'paidAt': Timestamp.now(),
        'paymentMethod': 'Manual/QR',
        'markedBy': adminUid,
        'description':
            'Daily class fee for ${_selectedSubjects.join(", ")} - $dateString',
      });

      // Send WhatsApp notification for daily payment
      final whatsappSent = await WhatsAppService.sendDailyPaymentNotification(
        studentName: _foundStudent!.name,
        parentName: _foundStudent!.parentName,
        parentPhone: _foundStudent!.whatsappNumber,
        amount: amount,
        date: dateString,
        subjects: _selectedSubjects,
        schoolName: _academyName ?? 'EduTrack Academy',
      );

      if (whatsappSent) {
        _showStatusMessage('Daily payment marked & WhatsApp sent! 💰📱✅',
            isError: false);
      } else {
        _showStatusMessage(
            'Daily payment marked but WhatsApp notification failed.',
            isError: true);
      }

      // Navigate back to initial screen
      _resetPaymentState();
      setState(() {
        _currentScreenState = ScreenState.initial;
        _foundStudent = null;
      });
    } catch (e) {
      print("Error marking daily payment: $e");
      _showStatusMessage('Failed to mark payment. $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Helper method to reset payment state
  void _resetPaymentState() {
    _selectedMonth = null;
    _selectedDate = null;
    _selectedSubjects.clear();
    _amountController.clear();
  }

  // ✅ NEW: Fetch existing pending payments for the current student
  Future<void> _fetchExistingPendingPayments() async {
    if (_foundStudent == null) return;

    try {
      final String? adminUid = AuthController.instance.user?.uid;
      if (adminUid == null) throw Exception("Admin not logged in.");

      // Query existing fee records with PENDING status (with backward compatibility)
      final feesQuery = await _firestore
          .collection('admins')
          .doc(adminUid)
          .collection('students')
          .doc(_foundStudent!.id)
          .collection('fees')
          .get();

      final List<PendingPaymentItem> pendingPayments = [];

      for (final doc in feesQuery.docs) {
        final data = doc.data();

        // Check if this is a pending payment (new status field or old paid field)
        final bool isPending = data.containsKey('status')
            ? data['status'] == 'PENDING'
            : data['paid'] == false; // Backward compatibility

        if (isPending) {
          pendingPayments.add(PendingPaymentItem.fromFirestore(doc));
        }
      }

      setState(() {
        _existingPendingPayments = pendingPayments;
        // Ensure subject filter remains valid
        final availableSubjects = {
          if (_foundStudent != null) ..._foundStudent!.subjects,
          ..._existingPendingPayments.expand((e) => e.subjects)
        }..removeWhere((s) => s.trim().isEmpty);
        if (_pendingSubjectFilter != 'All' &&
            !availableSubjects.contains(_pendingSubjectFilter)) {
          _pendingSubjectFilter = 'All';
        }
      });

      // ✅ DEBUG: Print pending payments info
      print(
          "DEBUG: Fetched ${pendingPayments.length} pending payments for student ${_foundStudent!.name}");
      for (var payment in pendingPayments) {
        print(
            "  - ${payment.paymentType} payment: ${payment.period} - Rs.${payment.amount}");
      }
    } catch (e) {
      print("Error fetching pending payments: $e");
      _showStatusMessage('Failed to load pending payments: $e', isError: true);
    }
  }

  // ✅ NEW: Filter pending payments by type
  List<PendingPaymentItem> _getFilteredPendingPayments() {
    // Step 1: Filter by type if needed
    Iterable<PendingPaymentItem> items = _existingPendingPayments;
    if (_pendingPaymentsFilter != 'all') {
      items = items.where((item) => item.paymentType == _pendingPaymentsFilter);
    }

    // Step 2: Filter by subject if a specific subject is selected
    if (_pendingSubjectFilter != 'All') {
      items =
          items.where((item) => item.subjects.contains(_pendingSubjectFilter));
    }

    return items.toList();
  }

  // ✅ NEW: Calculate total pending amount
  double _calculateTotalPendingAmount() {
    final filteredPayments = _getFilteredPendingPayments();
    return filteredPayments.fold(
        0.0,
        (sum, item) =>
            sum + (item.pendingAmount > 0 ? item.pendingAmount : item.amount));
  }

  // ✅ NEW: Build subject dropdown items for pending payments filter
  List<DropdownMenuItem<String>> _buildPendingSubjectDropdownItems() {
    // Prefer current student's subjects if available; else, aggregate from pending payments
    final Set<String> subjectSet = {
      if (_foundStudent != null) ..._foundStudent!.subjects,
      ..._existingPendingPayments.expand((e) => e.subjects)
    }..removeWhere((s) => s.trim().isEmpty);

    final List<String> subjects = subjectSet.toList()..sort();
    return [
      const DropdownMenuItem<String>(
        value: 'All',
        child: Text('All Subjects', style: TextStyle(fontSize: 12)),
      ),
      ...subjects.map((s) => DropdownMenuItem<String>(
            value: s,
            child: Text(s, style: const TextStyle(fontSize: 12)),
          ))
    ];
  }

  // ✅ NEW: Fetch and calculate average score from exam results
  Future<void> _fetchAndCalculateAverageScore() async {
    if (_foundStudent == null) return;

    try {
      final String? adminUid = AuthController.instance.user?.uid;
      if (adminUid == null) {
        print('Error: Admin not logged in');
        return;
      }

      // Fetch all exam results for this student
      final resultsSnapshot = await _firestore
          .collection('admins')
          .doc(adminUid)
          .collection('students')
          .doc(_foundStudent!.id)
          .collection('examResults')
          .get();

      if (resultsSnapshot.docs.isEmpty) {
        // No exam results found, keep averageScoreValue as null
        print('No exam results found for student ${_foundStudent!.name}');
        return;
      }

      // Calculate average percentage across all subjects
      double totalPercentage = 0;
      int validResultsCount = 0;

      for (var doc in resultsSnapshot.docs) {
        final data = doc.data();
        final marks = (data['marks'] ?? 0).toDouble();
        final maxMarks = (data['maxMarks'] ?? 100).toDouble();

        if (maxMarks > 0) {
          final percentage = (marks / maxMarks) * 100;
          totalPercentage += percentage;
          validResultsCount++;
        }
      }

      if (validResultsCount > 0) {
        final averageScore = totalPercentage / validResultsCount;
        setState(() {
          _foundStudent = _foundStudent!.copyWith(
            averageScoreValue: averageScore,
          );
        });
        print(
            'Calculated average score for ${_foundStudent!.name}: ${averageScore.toStringAsFixed(1)}%');
      }
    } catch (e) {
      print('Error calculating average score: $e');
    }
  }

  // ✅ NEW: Navigate back to QR scanner
  void _goBackToScanner() {
    setState(() {
      _currentScreenState = ScreenState.initial;
      _foundStudent = null;
      _attendanceMarked = false;
      _existingPendingPayments.clear();
      _pendingSubjectFilter = 'All';
      _selectedSubjects.clear();
      _amountController.clear();
      _descriptionController.clear();
      _pendingReasonController.clear();
      _selectedPaymentTypeForDialog = null;
    });
  }

  // --- UI Building ---
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: kLightTextColor),
          tooltip: 'Back',
          // Navigate back differently depending on the state
          onPressed: () {
            if (_currentScreenState == ScreenState.scanning ||
                _currentScreenState == ScreenState.showIndexInput) {
              setState(() => _currentScreenState = ScreenState.initial);
            } else if (_currentScreenState == ScreenState.showStudentDetails) {
              setState(() => _currentScreenState = ScreenState.initial);
            } else if (_currentScreenState ==
                ScreenState.showPaymentTypeSelection) {
              setState(
                  () => _currentScreenState = ScreenState.showStudentDetails);
            } else if (_currentScreenState ==
                    ScreenState.showMonthlyPaymentInput ||
                _currentScreenState == ScreenState.showDailyPaymentInput) {
              setState(() =>
                  _currentScreenState = ScreenState.showPaymentTypeSelection);
            } else {
              Navigator.pop(context); // Default back action
            }
          },
        ),
        title: Text('QR Code Scanner', style: textTheme.titleLarge),
        centerTitle: true,
        actions: [
          _buildProfileAvatar(),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildBody(context)),
          _buildStatusMessageWidget(context), // Status message at the bottom
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (_currentScreenState) {
      case ScreenState.initial:
        return _buildInitialUI(context);
      case ScreenState.scanning:
        return _buildScannerUI(context);
      case ScreenState.showIndexInput:
        return _buildIndexInputUI(context);
      case ScreenState.showStudentDetails:
        return _buildStudentDetailsUI(context);
      case ScreenState.showStudentDetailsWithPendingPayments: // ✅ NEW CASE
        return _buildStudentDetailsWithPendingPaymentsUI(context);
      case ScreenState.showPaymentTypeSelection:
        return _buildPaymentTypeSelectionUI(context);
      case ScreenState.showMonthlyPaymentInput:
        return _buildMonthlyPaymentInputUI(context);
      case ScreenState.showDailyPaymentInput:
        return _buildDailyPaymentInputUI(context);
    }
  }

  // --- UI for Initial State ---
  Widget _buildInitialUI(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(kDefaultPadding * 1.5),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.qr_code_scanner_rounded, size: 24),
              label: const Text('Scan QR Code'),
              onPressed: () =>
                  setState(() => _currentScreenState = ScreenState.scanning),
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      vertical: kDefaultPadding * 1.2)),
            ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),
            const SizedBox(height: kDefaultPadding * 1.5),
            ElevatedButton.icon(
              icon: const Icon(Icons.edit_note_rounded, size: 24),
              label: const Text('Mark By ID'),
              onPressed: () => setState(
                  () => _currentScreenState = ScreenState.showIndexInput),
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      vertical: kDefaultPadding * 1.2)),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
            const Spacer(), // Pushes buttons up a bit if needed
            if (_isLoading) const Center(child: CircularProgressIndicator()),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  // --- UI for QR Scanner ---
  Widget _buildScannerUI(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(kDefaultPadding),
          child: Text("Position the QR code within the frame",
              style: kHintTextStyle),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(kDefaultRadius),
              child: MobileScanner(
                controller: _scannerController,
                onDetect: (capture) {
                  final List<Barcode> barcodes = capture.barcodes;
                  if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                    _scannerController.stop(); // Stop scanning after detection
                    _findStudentByQrCode(barcodes.first.rawValue!);
                  }
                },
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(kDefaultPadding),
          child: TextButton(
            onPressed: () =>
                setState(() => _currentScreenState = ScreenState.initial),
            child: const Text('Cancel Scan'),
          ),
        ),
      ],
    );
  }

  // --- UI for Index Input ---
  Widget _buildIndexInputUI(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(kDefaultPadding * 1.5),
      child: Center(
        child: Form(
          key: _formKeyIndex,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _indexController,
                decoration: const InputDecoration(
                  labelText: 'Enter Index Number',
                  hintText: 'e.g., MEC/25/10A/01',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter index number'
                    : null,
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ).animate().fadeIn(delay: 100.ms),
              const SizedBox(height: kDefaultPadding * 1.5),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.check_rounded, size: 20),
                            label: const Text('OK'),
                            onPressed: () {
                              if (_formKeyIndex.currentState!.validate()) {
                                _findStudentByIndex(_indexController.text);
                              }
                            },
                          ).animate().fadeIn(delay: 200.ms),
                        ),
                        const SizedBox(width: kDefaultPadding),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.close_rounded, size: 20),
                            label: const Text('Cancel'),
                            onPressed: () {
                              _indexController.clear();
                              setState(() =>
                                  _currentScreenState = ScreenState.initial);
                            },
                            style: OutlinedButton.styleFrom(
                                foregroundColor: kPrimaryColor),
                          ).animate().fadeIn(delay: 250.ms),
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI for Student Details ---
  Widget _buildStudentDetailsUI(BuildContext context) {
    if (_foundStudent == null) {
      // Should not happen if state is managed correctly, but handle defensively
      return const Center(child: Text('Error: Student data not found.'));
    }
    final student = _foundStudent!;
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(kDefaultPadding),
      child: Column(
        children: [
          // Student Info Card
          Card(
            elevation: 3,
            margin: EdgeInsets.zero, // Remove default card margin
            child: Padding(
              padding: const EdgeInsets.all(kDefaultPadding),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(student.name,
                            style: textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold)),

                        // ✅ NEW: None payee indicator
                        if (student.isNonePayee) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'NONE PAYEE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: kDefaultPadding / 2),
                        _buildDetailRow('Index No:', student.indexNumber),
                        _buildDetailRow('Grade:',
                            student.className), // Show full class name
                        _buildDetailRow('Average Score:',
                            student.averageScore), // Placeholder
                        _buildDetailRow(
                            'Subjects:', student.subjects.join(', ')),
                        _buildDetailRow('Sex:', student.sex),
                        _buildDetailRow('DOB:', student.dob),
                        _buildDetailRow('Parent:', student.parentName),
                        _buildDetailRow('Contact:', student.parentPhone),
                        _buildDetailRow('WhatsApp:', student.whatsappNumber),
                      ],
                    ),
                  ),
                  const SizedBox(width: kDefaultPadding),
                  Expanded(
                    flex: 1,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(kDefaultRadius),
                      child: student.photoUrl != null &&
                              student.photoUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: student.photoUrl!,
                              height: 150, // Adjust height as needed
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                height: 150,
                                color: kDisabledColor.withOpacity(0.3),
                                child: const Center(
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2)),
                              ),
                              errorWidget: (context, url, error) => Container(
                                  height: 150,
                                  color: kDisabledColor.withOpacity(0.3),
                                  child: const Icon(Icons.person_off_outlined,
                                      color: kLightTextColor, size: 50)),
                            )
                          : Container(
                              height: 150,
                              color: kDisabledColor.withOpacity(0.3),
                              child: const Icon(Icons.person_outline_rounded,
                                  color: kLightTextColor, size: 50)),
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1),

          const SizedBox(height: kDefaultPadding * 1.5),

          // ✅ NEW: Pending Payments Card (Always show)
          Card(
            elevation: 3,
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(kDefaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with title and filters
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.payment_outlined,
                              color: Colors.orange, size: 20),
                          const SizedBox(width: 8),
                          Text(
                              'Pending Payments (${_getFilteredPendingPayments().length})',
                              style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange)),
                        ],
                      ),
                      // Filters: Type + Subject
                      Flexible(
                        child: Wrap(
                          alignment: WrapAlignment.end,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            SizedBox(
                              height: 35,
                              child: DropdownButton<String>(
                                value: _pendingPaymentsFilter,
                                isDense: true,
                                underline: Container(),
                                items: const [
                                  DropdownMenuItem(
                                      value: 'all',
                                      child: Text('All',
                                          style: TextStyle(fontSize: 12))),
                                  DropdownMenuItem(
                                      value: 'monthly',
                                      child: Text('Monthly',
                                          style: TextStyle(fontSize: 12))),
                                  DropdownMenuItem(
                                      value: 'daily',
                                      child: Text('Daily',
                                          style: TextStyle(fontSize: 12))),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _pendingPaymentsFilter = value ?? 'all';
                                  });
                                },
                              ),
                            ),
                            SizedBox(
                              height: 35,
                              child: DropdownButton<String>(
                                value: _pendingSubjectFilter,
                                isDense: true,
                                underline: Container(),
                                items: _buildPendingSubjectDropdownItems(),
                                onChanged: (value) {
                                  setState(() {
                                    _pendingSubjectFilter = value ?? 'All';
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: kDefaultPadding / 2),

                  // Total pending amount bar
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Pending Amount:',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Rs.${_calculateTotalPendingAmount().toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: kDefaultPadding / 2),

                  // Payments table or empty message
                  _getFilteredPendingPayments().isNotEmpty
                      ? ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: SingleChildScrollView(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                // Use a more mobile-friendly layout for narrow screens
                                if (constraints.maxWidth < 600) {
                                  return Column(
                                    children: _getFilteredPendingPayments()
                                        .map((payment) => Card(
                                              margin: const EdgeInsets.only(
                                                  bottom: 8),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(12),
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      flex: 2,
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                              payment.paymentType
                                                                      .isNotEmpty
                                                                  ? '${payment.paymentType[0].toUpperCase()}${payment.paymentType.substring(1)}'
                                                                  : payment
                                                                      .paymentType,
                                                              style: const TextStyle(
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600)),
                                                          Text(
                                                              payment
                                                                  .getMonthYearDisplay(),
                                                              style: const TextStyle(
                                                                  fontSize: 11,
                                                                  color: Colors
                                                                      .grey)),
                                                          if (payment.subjects
                                                              .isNotEmpty)
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .only(
                                                                      top: 2.0),
                                                              child: Text(
                                                                'Subjects: ${payment.subjects.join(', ')}',
                                                                style: const TextStyle(
                                                                    fontSize:
                                                                        11,
                                                                    color: Colors
                                                                        .grey),
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                    ),
                                                    Expanded(
                                                      flex: 1,
                                                      child: Text(
                                                          'Rs.${payment.amount.toStringAsFixed(0)}',
                                                          style:
                                                              const TextStyle(
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  color: Colors
                                                                      .orange),
                                                          textAlign:
                                                              TextAlign.right),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ))
                                        .toList(),
                                  );
                                } else {
                                  // Use DataTable for wider screens
                                  return SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: DataTable(
                                      columnSpacing: 16,
                                      dataRowHeight: 35,
                                      headingRowHeight: 35,
                                      columns: const [
                                        DataColumn(
                                            label: Text('Type',
                                                style:
                                                    TextStyle(fontSize: 12))),
                                        DataColumn(
                                            label: Text('Period',
                                                style:
                                                    TextStyle(fontSize: 12))),
                                        DataColumn(
                                            label: Text('Subjects',
                                                style:
                                                    TextStyle(fontSize: 12))),
                                        DataColumn(
                                            label: Text('Amount',
                                                style:
                                                    TextStyle(fontSize: 12))),
                                        DataColumn(
                                            label: Text('Due Date',
                                                style:
                                                    TextStyle(fontSize: 12))),
                                      ],
                                      rows: _getFilteredPendingPayments()
                                          .map((payment) => DataRow(
                                                cells: [
                                                  DataCell(Text(
                                                      payment.paymentType
                                                              .isNotEmpty
                                                          ? '${payment.paymentType[0].toUpperCase()}${payment.paymentType.substring(1)}'
                                                          : payment.paymentType,
                                                      style: const TextStyle(
                                                          fontSize: 11))),
                                                  DataCell(Text(
                                                      payment
                                                          .getMonthYearDisplay(),
                                                      style: const TextStyle(
                                                          fontSize: 11))),
                                                  DataCell(SizedBox(
                                                    width: 180,
                                                    child: Text(
                                                      payment.subjects
                                                              .isNotEmpty
                                                          ? payment.subjects
                                                              .join(', ')
                                                          : '-',
                                                      style: const TextStyle(
                                                          fontSize: 11),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  )),
                                                  DataCell(Text(
                                                      'Rs.${payment.amount.toStringAsFixed(0)}',
                                                      style: const TextStyle(
                                                          fontSize: 11,
                                                          fontWeight: FontWeight
                                                              .w600))),
                                                  DataCell(Text(
                                                      payment
                                                          .getDueDateDisplay(),
                                                      style: const TextStyle(
                                                          fontSize: 11))),
                                                ],
                                              ))
                                          .toList(),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Icon(Icons.payment_outlined,
                                  size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              Text(
                                _pendingPaymentsFilter == 'all'
                                    ? 'No pending payments found'
                                    : 'No ${_pendingPaymentsFilter} pending payments found',
                                style: TextStyle(
                                    color: Colors.grey.shade600, fontSize: 14),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'You can create new payment records using the buttons below.',
                                style: TextStyle(
                                    color: Colors.grey.shade500, fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1),

          const SizedBox(height: kDefaultPadding * 1.5),

          // Action Buttons Card
          Card(
            elevation: 3,
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(kDefaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Choose an option',
                      style: textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: kDefaultPadding),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _showSubjectSelectionDialog,
                                child: const Text('Mark Attendance'),
                              ),
                            ),
                            const SizedBox(width: kDefaultPadding),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _showMarkPaymentDialog(),
                                child: const Text('Mark Payment'),
                              ),
                            ),
                          ],
                        ),
                  const SizedBox(height: kDefaultPadding),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _currentScreenState = ScreenState.initial;
                        _foundStudent = null; // Clear student data
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor
                          .withOpacity(0.8), // Slightly different style
                    ),
                    child: const Text('Back to Scanner'),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: kDefaultPadding / 4),
      child: RichText(
        text: TextSpan(
          style: kBodyTextStyle.copyWith(color: kLightTextColor, fontSize: 13),
          children: [
            TextSpan(
                text: '$label ',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  // --- UI for Payment Type Selection ---
  Widget _buildPaymentTypeSelectionUI(BuildContext context) {
    if (_foundStudent == null) {
      return const Center(child: Text('Error: Student data not found.'));
    }
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(kDefaultPadding * 1.5),
      child: Center(
        child: Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(kDefaultPadding * 1.5),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Select Payment Type',
                    style: textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: kDefaultPadding * 1.5),

                // Student Info
                Text('For: ${_foundStudent!.name}',
                    style:
                        textTheme.titleMedium?.copyWith(color: kPrimaryColor)),
                Text('Class: ${_foundStudent!.className}',
                    style:
                        textTheme.bodyMedium?.copyWith(color: kLightTextColor)),
                const SizedBox(height: kDefaultPadding * 1.5),

                // Payment Type Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setState(() => _currentScreenState =
                              ScreenState.showMonthlyPaymentInput);
                        },
                        icon: const Icon(Icons.calendar_month_outlined),
                        label: const Text('Monthly Payment'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: kDefaultPadding * 1.2),
                        ),
                      ).animate().fadeIn(delay: 100.ms),
                    ),
                    const SizedBox(width: kDefaultPadding),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setState(() => _currentScreenState =
                              ScreenState.showDailyPaymentInput);
                        },
                        icon: const Icon(Icons.calendar_today_outlined),
                        label: const Text('Daily Payment'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: kDefaultPadding * 1.2),
                        ),
                      ).animate().fadeIn(delay: 150.ms),
                    ),
                  ],
                ),
                const SizedBox(height: kDefaultPadding * 1.5),

                // Back Button
                OutlinedButton(
                  onPressed: () => setState(() =>
                      _currentScreenState = ScreenState.showStudentDetails),
                  style:
                      OutlinedButton.styleFrom(foregroundColor: kPrimaryColor),
                  child: const Text('Go Back'),
                ).animate().fadeIn(delay: 200.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- UI for Monthly Payment Input ---
  Widget _buildMonthlyPaymentInputUI(BuildContext context) {
    if (_foundStudent == null) {
      return const Center(child: Text('Error: Student data not found.'));
    }
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(kDefaultPadding * 1.5),
      child: SingleChildScrollView(
        child: Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(kDefaultPadding * 1.5),
            child: Form(
              key: _formKeyPayment,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Monthly Payment',
                      style: textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: kDefaultPadding),

                  // Student Info
                  Text('For: ${_foundStudent!.name}',
                      style: textTheme.titleMedium
                          ?.copyWith(color: kPrimaryColor)),
                  const SizedBox(height: kDefaultPadding * 1.5),

                  // Month Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedMonth,
                    hint: const Text('Select Month'),
                    items: _months.map((String month) {
                      return DropdownMenuItem<String>(
                        value: month,
                        child: Text(month),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedMonth = newValue;
                      });
                    },
                    validator: (value) =>
                        value == null ? 'Please select a month' : null,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.calendar_month_outlined),
                    ),
                  ).animate().fadeIn(delay: 100.ms),
                  const SizedBox(height: kDefaultPadding),

                  // Subject Selection
                  _buildSubjectSelectionWidget(),
                  const SizedBox(height: kDefaultPadding),

                  // Amount Input
                  TextFormField(
                    controller: _amountController,
                    decoration: const InputDecoration(
                      labelText: 'Enter the Amount',
                      prefixIcon: Icon(Icons.currency_rupee_rounded),
                    ),
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Please enter amount';
                      if (double.tryParse(value) == null)
                        return 'Invalid amount';
                      if (double.parse(value) <= 0)
                        return 'Amount must be positive';
                      return null;
                    },
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: kDefaultPadding * 1.5),

                  // Action Buttons
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _markMonthlyPayment,
                                child: const Text('Mark Payment'),
                              ).animate().fadeIn(delay: 250.ms),
                            ),
                            const SizedBox(width: kDefaultPadding),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => setState(() =>
                                    _currentScreenState =
                                        ScreenState.showPaymentTypeSelection),
                                style: OutlinedButton.styleFrom(
                                    foregroundColor: kPrimaryColor),
                                child: const Text('Go Back'),
                              ).animate().fadeIn(delay: 300.ms),
                            ),
                          ],
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- UI for Daily Payment Input ---
  Widget _buildDailyPaymentInputUI(BuildContext context) {
    if (_foundStudent == null) {
      return const Center(child: Text('Error: Student data not found.'));
    }
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(kDefaultPadding * 1.5),
      child: SingleChildScrollView(
        child: Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(kDefaultPadding * 1.5),
            child: Form(
              key: _formKeyPayment,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Daily Payment',
                      style: textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: kDefaultPadding),

                  // Student Info
                  Text('For: ${_foundStudent!.name}',
                      style: textTheme.titleMedium
                          ?.copyWith(color: kPrimaryColor)),
                  const SizedBox(height: kDefaultPadding * 1.5),

                  // Date Picker
                  InkWell(
                    onTap: () async {
                      final selectedDate = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate ?? DateTime.now(),
                        firstDate:
                            DateTime.now().subtract(const Duration(days: 30)),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (selectedDate != null) {
                        setState(() {
                          _selectedDate = selectedDate;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Select Date',
                        prefixIcon: Icon(Icons.calendar_today_outlined),
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        _selectedDate != null
                            ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                            : 'Tap to select date',
                      ),
                    ),
                  ).animate().fadeIn(delay: 100.ms),
                  const SizedBox(height: kDefaultPadding),

                  // Subject Selection
                  _buildSubjectSelectionWidget(),
                  const SizedBox(height: kDefaultPadding),

                  // Amount Input
                  TextFormField(
                    controller: _amountController,
                    decoration: const InputDecoration(
                      labelText: 'Enter the Amount',
                      prefixIcon: Icon(Icons.currency_rupee_rounded),
                    ),
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Please enter amount';
                      if (double.tryParse(value) == null)
                        return 'Invalid amount';
                      if (double.parse(value) <= 0)
                        return 'Amount must be positive';
                      return null;
                    },
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: kDefaultPadding * 1.5),

                  // Action Buttons
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _markDailyPayment,
                                child: const Text('Mark Payment'),
                              ).animate().fadeIn(delay: 250.ms),
                            ),
                            const SizedBox(width: kDefaultPadding),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => setState(() =>
                                    _currentScreenState =
                                        ScreenState.showPaymentTypeSelection),
                                style: OutlinedButton.styleFrom(
                                    foregroundColor: kPrimaryColor),
                                child: const Text('Go Back'),
                              ).animate().fadeIn(delay: 300.ms),
                            ),
                          ],
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Subject Selection Widget ---
  Widget _buildSubjectSelectionWidget() {
    if (_foundStudent == null || _foundStudent!.subjects.isEmpty) {
      return Container();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select Subjects:',
            style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: kDefaultPadding / 2),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: _foundStudent!.subjects.map((subject) {
            final isSelected = _selectedSubjects.contains(subject);
            return FilterChip(
              label: Text(subject),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedSubjects.add(subject);
                  } else {
                    _selectedSubjects.remove(subject);
                  }
                });
              },
              selectedColor: kPrimaryColor.withOpacity(0.2),
              checkmarkColor: kPrimaryColor,
            );
          }).toList(),
        ),
        if (_selectedSubjects.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text('Please select at least one subject',
                style: TextStyle(color: kErrorColor, fontSize: 12)),
          ),
      ],
    );
  }

  // --- Status Message Widget (Similar to AddTeacherScreen) ---
  Widget _buildStatusMessageWidget(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AnimatedOpacity(
      opacity: _statusMessage != null ? 1.0 : 0.0,
      duration: 300.ms,
      child: Padding(
        // Add padding only when message is visible
        padding: _statusMessage != null
            ? const EdgeInsets.only(
                bottom: kDefaultPadding,
                left: kDefaultPadding,
                right: kDefaultPadding)
            : EdgeInsets.zero,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: kDefaultPadding, vertical: kDefaultPadding * 0.7),
            decoration: BoxDecoration(
              color: _isError
                  ? kErrorColor.withOpacity(0.15)
                  : kSuccessColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(kDefaultRadius),
              border: Border.all(
                  color: _isError ? kErrorColor : kSuccessColor, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isError
                      ? Icons.error_outline_rounded
                      : Icons.check_circle_outline_rounded,
                  color: _isError ? kErrorColor : kSuccessColor,
                  size: 20,
                ),
                const SizedBox(width: kDefaultPadding / 2),
                Flexible(
                  // Allow text to wrap
                  child: Text(
                    _statusMessage ?? '',
                    style: textTheme.bodyMedium?.copyWith(
                      color: _isError ? kErrorColor : kSuccessColor,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ NEW: UI for showing student details with pending payments
  Widget _buildStudentDetailsWithPendingPaymentsUI(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Payment Management'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: _goBackToScanner,
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ Attendance marked indicator
            if (_attendanceMarked)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                margin: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Attendance marked successfully! You can now mark payments.',
                        style: TextStyle(
                          color: Colors.green.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // ✅ Student info card
            _buildStudentInfoCard(),

            SizedBox(height: 16),

            // ✅ Pending payments section
            _buildPendingPaymentsSection(),

            SizedBox(height: 24),

            // ✅ Action buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  // ✅ NEW: Build student info card with none payee indicator
  Widget _buildStudentInfoCard() {
    if (_foundStudent == null) return SizedBox.shrink();

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            // Student photo
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.grey.shade300,
              backgroundImage: _foundStudent!.photoUrl != null
                  ? NetworkImage(_foundStudent!.photoUrl!)
                  : null,
              child: _foundStudent!.photoUrl == null
                  ? Icon(Icons.person, size: 30)
                  : null,
            ),

            SizedBox(width: 16),

            // Student details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _foundStudent!.name,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                      'Class: ${_foundStudent!.className}-${_foundStudent!.section}'),
                  Text('Index: ${_foundStudent!.indexNumber}'),

                  // ✅ None payee indicator
                  if (_foundStudent!.isNonePayee) ...[
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'NONE PAYEE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ NEW: Build pending payments section
  Widget _buildPendingPaymentsSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with filter
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Existing Pending Payments',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                DropdownButton<String>(
                  value: _pendingPaymentsFilter,
                  onChanged: (value) {
                    setState(() {
                      _pendingPaymentsFilter = value!;
                    });
                  },
                  items: [
                    DropdownMenuItem(value: 'all', child: Text('All')),
                    DropdownMenuItem(
                        value: 'monthly', child: Text('Monthly Pending')),
                    DropdownMenuItem(
                        value: 'daily', child: Text('Daily Pending')),
                  ],
                ),
              ],
            ),

            SizedBox(height: 12),

            // Total pending amount
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Pending Amount:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Rs. ${_calculateTotalPendingAmount().toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // Pending payments table
            _buildPendingPaymentsTable(),
          ],
        ),
      ),
    );
  }

  // ✅ NEW: Build pending payments table
  Widget _buildPendingPaymentsTable() {
    final filteredPayments = _getFilteredPendingPayments();

    if (filteredPayments.isEmpty) {
      return Container(
        padding: EdgeInsets.all(20),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.payment_outlined, size: 48, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                'No pending payments found',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(label: Text('Type')),
          DataColumn(label: Text('Period')),
          DataColumn(label: Text('Subjects')),
          DataColumn(label: Text('Amount')),
        ],
        rows: filteredPayments
            .map((payment) => DataRow(
                  cells: [
                    DataCell(
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: payment.paymentType == 'monthly'
                              ? Colors.blue.shade100
                              : Colors.green.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          payment.paymentType.toUpperCase(),
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    DataCell(Text(payment.period)),
                    DataCell(
                      SizedBox(
                        width: 120,
                        child: Text(
                          payment.subjects.join(', '),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        'Rs. ${payment.amount.toStringAsFixed(2)}',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ))
            .toList(),
      ),
    );
  }

  // ✅ NEW: Build action buttons
  Widget _buildActionButtons() {
    return Column(
      children: [
        // Main action buttons row
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _showMarkPaymentDialog(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text('Mark Payment'),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: OutlinedButton(
                onPressed: () => _showMarkPendingDialog(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange,
                  side: BorderSide(color: Colors.orange),
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text('Mark as Pending'),
              ),
            ),
          ],
        ),

        SizedBox(height: 16),

        // Go back button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _goBackToScanner,
            child: Text('Go Back'),
          ),
        ),
      ],
    );
  }

  // ✅ NEW: Show mark payment dialog (placeholder)
  void _showMarkPaymentDialog() {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return LayoutBuilder(builder: (context, constraints) {
          bool _validateAndWarn() {
            final ok = _paymentFormKey.currentState?.validate() ?? false;
            if (!ok) return false;
            if (_selectedPaymentTypeForDialog == null) {
              _showStatusMessage('Please select payment type', isError: true);
              return false;
            }
            if (_selectedPaymentTypeForDialog == 'monthly' &&
                _selectedMonth == null) {
              _showStatusMessage('Please select month', isError: true);
              return false;
            }
            if (_selectedPaymentTypeForDialog == 'daily' &&
                _selectedDate == null) {
              _showStatusMessage('Please select date', isError: true);
              return false;
            }
            if (_selectedSubjects.isEmpty) {
              _showStatusMessage('Select at least one subject', isError: true);
              return false;
            }
            return true;
          }

          return AlertDialog(
            title: const Text('Mark Payment'),
            scrollable: true,
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            content: StatefulBuilder(
              builder: (context, setDialogState) => ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.75,
                  minWidth: constraints.maxWidth * 0.6,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(right: 4),
                  child: Form(
                    key: _paymentFormKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Payment type selection
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => setDialogState(() {
                                  _selectedPaymentTypeForDialog = 'monthly';
                                }),
                                style: _selectedPaymentTypeForDialog ==
                                        'monthly'
                                    ? OutlinedButton.styleFrom(
                                        backgroundColor: Colors.blue.shade100)
                                    : null,
                                child: const Text('Monthly Payment'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => setDialogState(() {
                                  _selectedPaymentTypeForDialog = 'daily';
                                }),
                                style: _selectedPaymentTypeForDialog == 'daily'
                                    ? OutlinedButton.styleFrom(
                                        backgroundColor: Colors.green.shade100)
                                    : null,
                                child: const Text('Daily Payment'),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Dynamic form based on payment type selection
                        if (_selectedPaymentTypeForDialog == 'monthly') ...[
                          DropdownButtonFormField<String>(
                            value: _selectedMonth,
                            hint: const Text('Select Month'),
                            items: _months
                                .map((month) => DropdownMenuItem(
                                      value: month,
                                      child: Text(month),
                                    ))
                                .toList(),
                            onChanged: (month) =>
                                setDialogState(() => _selectedMonth = month),
                            validator: (value) =>
                                value == null ? 'Please select month' : null,
                          ),
                        ] else if (_selectedPaymentTypeForDialog ==
                            'daily') ...[
                          InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime.now()
                                    .subtract(const Duration(days: 30)),
                                lastDate: DateTime.now(),
                              );
                              if (date != null) {
                                setDialogState(() => _selectedDate = date);
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Select Date',
                                suffixIcon: Icon(Icons.calendar_today),
                              ),
                              child: Text(
                                _selectedDate != null
                                    ? DateFormat('dd/MM/yyyy')
                                        .format(_selectedDate!)
                                    : 'Choose date',
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),

                        // Subject Selection (Multi-select)
                        if (_foundStudent != null) ...[
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Select Subjects:',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: _foundStudent!.subjects
                                    .map((subject) => FilterChip(
                                          label: Text(subject),
                                          selected: _selectedSubjects
                                              .contains(subject),
                                          onSelected: (selected) {
                                            setDialogState(() {
                                              if (selected) {
                                                _selectedSubjects.add(subject);
                                              } else {
                                                _selectedSubjects
                                                    .remove(subject);
                                              }
                                            });
                                          },
                                        ))
                                    .toList(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Amount input
                        TextFormField(
                          controller: _amountController,
                          decoration: const InputDecoration(
                            labelText: 'Enter Amount',
                            prefixIcon: Icon(Icons.money),
                            helperText:
                                'Enter the fee amount for selected subjects',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          validator: (value) {
                            if (value == null || value.isEmpty)
                              return 'Please enter amount';
                            final parsed = double.tryParse(value);
                            if (parsed == null) return 'Invalid amount';
                            if (parsed <= 0) return 'Amount must be positive';
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // Description (optional)
                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Description (Optional)',
                            hintText:
                                'e.g., Monthly tuition fee, Special class fee',
                          ),
                          maxLines: 2,
                        ),

                        const SizedBox(height: 16),

                        // Row with primary actions
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  if (!_validateAndWarn()) return;
                                  _markPaymentAsPaid();
                                },
                                child: const Text('Mark Payment'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  if (!_validateAndWarn()) return;
                                  // Directly mark as PENDING without opening a new dialog
                                  _markPaymentAsPending();
                                },
                                child: const Text('Mark as Pending'),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Full-width cancel button below
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              // Reset dialog state
                              _selectedPaymentTypeForDialog = null;
                              _selectedMonth = null;
                              _selectedDate = null;
                              _selectedSubjects.clear();
                              _amountController.clear();
                              _descriptionController.clear();
                              Navigator.pop(dialogCtx);
                            },
                            child: const Text('Cancel'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Actions moved into content to control layout (row + full-width cancel)
          );
        });
      },
    );
  }

  // ✅ NEW: Show mark pending dialog
  void _showMarkPendingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Mark as Pending"),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Form(
            key: _pendingFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Show existing pending payments for reference
                if (_existingPendingPayments.isNotEmpty) ...[
                  Text("Existing Pending Payments:",
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  SizedBox(height: 8),
                  Container(
                    height: 150,
                    child: SingleChildScrollView(
                      child: Column(
                        children: _existingPendingPayments
                            .map((payment) => ListTile(
                                  dense: true,
                                  title: Text(
                                      "${payment.paymentType.toUpperCase()} - ${payment.period}"),
                                  subtitle: Text(
                                      "${payment.subjects.join(', ')} - Rs. ${payment.amount}"),
                                ))
                            .toList(),
                      ),
                    ),
                  ),
                  Divider(),
                ],

                // Option to create new pending payment
                Text("Create new pending payment:",
                    style: TextStyle(fontWeight: FontWeight.w600)),
                SizedBox(height: 8),

                // Same form as Mark Payment but for pending status
                // Payment type selection
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setDialogState(() {
                          _selectedPaymentTypeForDialog = "monthly";
                        }),
                        style: _selectedPaymentTypeForDialog == "monthly"
                            ? OutlinedButton.styleFrom(
                                backgroundColor: Colors.blue.shade100)
                            : null,
                        child: Text("Monthly"),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setDialogState(() {
                          _selectedPaymentTypeForDialog = "daily";
                        }),
                        style: _selectedPaymentTypeForDialog == "daily"
                            ? OutlinedButton.styleFrom(
                                backgroundColor: Colors.green.shade100)
                            : null,
                        child: Text("Daily"),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 12),

                // Period selection
                if (_selectedPaymentTypeForDialog == "monthly") ...[
                  DropdownButtonFormField<String>(
                    value: _selectedMonth,
                    hint: Text("Select Month"),
                    items: _months
                        .map((month) => DropdownMenuItem(
                              value: month,
                              child: Text(month),
                            ))
                        .toList(),
                    onChanged: (month) =>
                        setDialogState(() => _selectedMonth = month),
                  ),
                ] else if (_selectedPaymentTypeForDialog == "daily") ...[
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now().subtract(Duration(days: 30)),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setDialogState(() => _selectedDate = date);
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: "Select Date",
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(_selectedDate != null
                          ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
                          : "Choose date"),
                    ),
                  ),
                ],

                SizedBox(height: 12),

                // Amount input
                TextFormField(
                  controller: _amountController,
                  decoration: InputDecoration(
                    labelText: "Enter Amount",
                    prefixIcon: Icon(Icons.currency_rupee),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),

                SizedBox(height: 12),

                // Reason for pending
                TextFormField(
                  controller: _pendingReasonController,
                  decoration: InputDecoration(
                    labelText: "Reason for Pending Status",
                    hintText: "e.g., Partial payment received, Family issue",
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Reset dialog state
              _selectedPaymentTypeForDialog = null;
              _selectedMonth = null;
              _selectedDate = null;
              _selectedSubjects.clear();
              _amountController.clear();
              _pendingReasonController.clear();
              Navigator.pop(context);
            },
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => _markPaymentAsPending(),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text("Mark as PENDING"),
          ),
        ],
      ),
    );
  }

  // ✅ NEW: Mark payment as PAID with dynamic amount
  Future<void> _markPaymentAsPaid() async {
    if (_foundStudent == null ||
        _selectedPaymentTypeForDialog == null ||
        !_paymentFormKey.currentState!.validate() ||
        _selectedSubjects.isEmpty) {
      _showStatusMessage('Please fill all required fields and select subjects',
          isError: true);
      return;
    }

    Navigator.pop(context); // Close dialog
    setState(() => _isLoading = true);

    try {
      final String? adminUid = AuthController.instance.user?.uid;
      if (adminUid == null) throw Exception("Admin not logged in.");

      final amount = double.parse(_amountController.text.trim());
      final now = DateTime.now();
      final feesRef = _firestore
          .collection('admins')
          .doc(adminUid)
          .collection('students')
          .doc(_foundStudent!.id)
          .collection('fees');

      // Create payment record
      final paymentData = {
        'paymentType': _selectedPaymentTypeForDialog,
        'year': _selectedPaymentTypeForDialog == 'monthly'
            ? now.year
            : _selectedDate!.year,
        'subjects': _selectedSubjects,
        'amount': amount,
        'status': 'PAID', // ✅ NEW STATUS FIELD
        'paidAt': Timestamp.now(),
        'paymentMethod': 'Manual/QR',
        'markedBy': adminUid,
        'description': _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : _generateDescription(_selectedPaymentTypeForDialog!,
                _selectedMonth, _selectedDate, _selectedSubjects),
      };

      // Add payment type specific fields
      if (_selectedPaymentTypeForDialog == 'monthly' &&
          _selectedMonth != null) {
        final monthIndex = _months.indexOf(_selectedMonth!) + 1;
        paymentData['month'] = monthIndex;
      } else if (_selectedPaymentTypeForDialog == 'daily' &&
          _selectedDate != null) {
        paymentData['date'] = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      }

      await feesRef.add(paymentData);

      // Send WhatsApp notification using new status system
      final whatsappSent = await WhatsAppService.sendPaymentStatusNotification(
        studentName: _foundStudent!.name,
        parentName: _foundStudent!.parentName,
        parentPhone: _foundStudent!.whatsappNumber,
        paymentType: _selectedPaymentTypeForDialog!,
        status: 'PAID',
        amount: amount,
        period: _selectedPaymentTypeForDialog == 'monthly'
            ? '$_selectedMonth ${now.year}'
            : DateFormat('dd/MM/yyyy').format(_selectedDate!),
        subjects: _selectedSubjects,
        schoolName: _academyName ?? 'EduTrack Academy',
        isNonePayee: _foundStudent!.isNonePayee,
      );

      if (whatsappSent) {
        _showStatusMessage('Payment marked as PAID & WhatsApp sent! 💰📱✅',
            isError: false);
      } else {
        _showStatusMessage(
            'Payment marked as PAID but WhatsApp notification failed.',
            isError: true);
      }

      // Refresh pending payments
      await _fetchExistingPendingPayments();

      // Clear form
      _selectedPaymentTypeForDialog = null;
      _selectedMonth = null;
      _selectedDate = null;
      _selectedSubjects.clear();
      _amountController.clear();
      _descriptionController.clear();
    } catch (e) {
      print("Error marking payment as PAID: $e");
      _showStatusMessage('Failed to mark payment as PAID: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ✅ NEW: Mark payment as PENDING with dynamic amount
  Future<void> _markPaymentAsPending() async {
    if (_foundStudent == null ||
        _selectedPaymentTypeForDialog == null ||
        _amountController.text.isEmpty) {
      _showStatusMessage('Please fill all required fields', isError: true);
      return;
    }

    Navigator.pop(context); // Close dialog
    setState(() => _isLoading = true);

    try {
      final String? adminUid = AuthController.instance.user?.uid;
      if (adminUid == null) throw Exception("Admin not logged in.");

      final amount = double.parse(_amountController.text.trim());
      final now = DateTime.now();
      final feesRef = _firestore
          .collection('admins')
          .doc(adminUid)
          .collection('students')
          .doc(_foundStudent!.id)
          .collection('fees');

      // Create pending payment record
      final paymentData = {
        'paymentType': _selectedPaymentTypeForDialog,
        'year': _selectedPaymentTypeForDialog == 'monthly'
            ? now.year
            : _selectedDate!.year,
        'subjects': _selectedSubjects.isEmpty
            ? _foundStudent!.subjects
            : _selectedSubjects,
        'amount': amount,
        'pendingAmount': amount,
        'status': 'PENDING', // ✅ PENDING STATUS
        'pendingAt': Timestamp.now(),
        'paymentMethod': 'Manual/QR',
        'markedBy': adminUid,
        'description': _generateDescription(
            _selectedPaymentTypeForDialog!,
            _selectedMonth,
            _selectedDate,
            _selectedSubjects.isEmpty
                ? _foundStudent!.subjects
                : _selectedSubjects),
        'pendingReason': _pendingReasonController.text.isNotEmpty
            ? _pendingReasonController.text
            : 'Marked pending via QR dialog',
      };

      // Add payment type specific fields
      if (_selectedPaymentTypeForDialog == 'monthly' &&
          _selectedMonth != null) {
        final monthIndex = _months.indexOf(_selectedMonth!) + 1;
        paymentData['month'] = monthIndex;
      } else if (_selectedPaymentTypeForDialog == 'daily' &&
          _selectedDate != null) {
        paymentData['date'] = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      }

      await feesRef.add(paymentData);

      // Send WhatsApp notification for pending payment
      final whatsappSent = await WhatsAppService.sendPaymentStatusNotification(
        studentName: _foundStudent!.name,
        parentName: _foundStudent!.parentName,
        parentPhone: _foundStudent!.whatsappNumber,
        paymentType: _selectedPaymentTypeForDialog!,
        status: 'PENDING',
        amount: amount,
        pendingAmount: amount,
        period: _selectedPaymentTypeForDialog == 'monthly'
            ? '$_selectedMonth ${now.year}'
            : DateFormat('dd/MM/yyyy').format(_selectedDate!),
        subjects: _selectedSubjects.isEmpty
            ? _foundStudent!.subjects
            : _selectedSubjects,
        schoolName: _academyName ?? 'EduTrack Academy',
        isNonePayee: _foundStudent!.isNonePayee,
      );

      if (whatsappSent) {
        _showStatusMessage('Payment marked as PENDING & WhatsApp sent! ⏳📱✅',
            isError: false);
      } else {
        _showStatusMessage(
            'Payment marked as PENDING but WhatsApp notification failed.',
            isError: true);
      }

      // Refresh pending payments
      await _fetchExistingPendingPayments();

      // Clear form
      _selectedPaymentTypeForDialog = null;
      _selectedMonth = null;
      _selectedDate = null;
      _selectedSubjects.clear();
      _amountController.clear();
      _pendingReasonController.clear();
    } catch (e) {
      print("Error marking payment as PENDING: $e");
      _showStatusMessage('Failed to mark payment as PENDING: $e',
          isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ✅ NEW: Generate description for payment
  String _generateDescription(String paymentType, String? month, DateTime? date,
      List<String> subjects) {
    if (paymentType == 'monthly') {
      return 'Monthly fee for ${subjects.join(", ")} - $month ${DateTime.now().year}';
    } else {
      final dateString =
          date != null ? DateFormat('dd/MM/yyyy').format(date) : 'Unknown date';
      return 'Daily class fee for ${subjects.join(", ")} - $dateString';
    }
  }
}

// Removed duplicate AppRoutes helper class definition
