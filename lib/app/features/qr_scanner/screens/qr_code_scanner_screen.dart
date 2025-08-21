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
    );
  }

  // Calculate average score - Placeholder, implement actual logic if needed
  String get averageScore => '80%'; // Placeholder
  String get grade => className.split(' ').last; // Extract grade number
}

// Enum to manage the different states of the screen
enum ScreenState {
  initial,
  scanning,
  showIndexInput,
  showStudentDetails,
  showPaymentTypeSelection,
  showMonthlyPaymentInput,
  showDailyPaymentInput
}

// Enum for payment types
enum PaymentType { monthly, daily }

class QRCodeScannerScreen extends StatefulWidget {
  const QRCodeScannerScreen({super.key});

  @override
  State<QRCodeScannerScreen> createState() => _QRCodeScannerScreenState();
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
  PaymentType? _selectedPaymentType; // Monthly or Daily
  List<String> _selectedSubjects = []; // For both payment types
  String? _academyName;

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
        setState(() {
          _currentScreenState = ScreenState.showStudentDetails;
        });
        _showStatusMessage('Scanned Successfully!', isError: false);
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
        setState(() {
          _currentScreenState = ScreenState.showStudentDetails;
        });
        _showStatusMessage('Index No Matched!', isError: false);
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

      // Navigate back to initial screen after success
      setState(() {
        _currentScreenState = ScreenState.initial;
        _foundStudent = null;
      });
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
    _selectedPaymentType = null;
    _selectedSubjects.clear();
    _amountController.clear();
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
                                onPressed: () => setState(() =>
                                    _currentScreenState =
                                        ScreenState.showPaymentTypeSelection),
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
                          _selectedPaymentType = PaymentType.monthly;
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
                          _selectedPaymentType = PaymentType.daily;
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
}

// Removed duplicate AppRoutes helper class definition
