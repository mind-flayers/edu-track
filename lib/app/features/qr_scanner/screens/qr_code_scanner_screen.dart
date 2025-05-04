// import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edu_track/app/features/authentication/controllers/auth_controller.dart';
// import 'package:edu_track/app/features/profile/screens/profile_settings_screen.dart'; // For profile avatar logic
import 'package:edu_track/app/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
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
      dobValue = DateFormat('yyyy-MM-dd').format((data['dob'] as Timestamp).toDate());
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
      photoUrl: data['photoUrl'],
      sex: data['sex'] ?? 'N/A', // Assuming 'sex' is consistently String
      dob: dobValue, // Use the processed value
      subjects: List<String>.from(data['SubjectsChoosed'] ?? []), // Map 'SubjectsChoosed'
      qrCodeData: data['qrCodeData'] ?? '',
    );
  }

  // Calculate average score - Placeholder, implement actual logic if needed
  String get averageScore => '80%'; // Placeholder
  String get grade => className.split(' ').last; // Extract grade number
}

// Enum to manage the different states of the screen
enum ScreenState { initial, scanning, showIndexInput, showStudentDetails, showPaymentInput }

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
  String? _selectedMonth; // For payment dropdown
  String? _smsGatewayToken;
  String? _academyName;

  // List of months for the dropdown
  final List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
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
        _smsGatewayToken = data?['smsGatewayToken'];
        _academyName = data?['academyName'];
        if (_smsGatewayToken == null || _academyName == null) {
           print("Warning: SMS Gateway Token or Academy Name not found in admin profile.");
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
  void _showStatusMessage(String message, {bool isError = false, Duration duration = const Duration(seconds: 3)}) {
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
         icon: Icon(Icons.account_circle_rounded, size: 30, color: kLightTextColor),
         tooltip: 'Profile Settings',
         onPressed: () => Get.toNamed(AppRoutes.profileSettings), // Use Get.toNamed
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
         Widget profileWidget = Icon(Icons.account_circle_rounded, size: 30, color: kLightTextColor); // Default icon

         if (snapshot.connectionState == ConnectionState.active && snapshot.hasData && snapshot.data!.exists) {
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
             backgroundImage: CachedNetworkImageProvider(photoUrl), // Use CachedNetworkImageProvider
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
             onTap: () => Get.toNamed(AppRoutes.profileSettings), // Use Get.toNamed
             child: Padding(
               padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding, vertical: kDefaultPadding / 2),
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
    setState(() { _isLoading = true; _currentScreenState = ScreenState.initial; }); // Show loading on initial screen

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
        _showStatusMessage('QR Code does not match any student.', isError: true);
         setState(() { _currentScreenState = ScreenState.initial; }); // Go back to initial on error
      }
    } catch (e) {
      print("Error finding student by QR code: $e");
      _showStatusMessage('Error finding student. Please try again.', isError: true);
      _foundStudent = null;
       setState(() { _currentScreenState = ScreenState.initial; }); // Go back to initial on error
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
        _showStatusMessage('Index number does not match any student.', isError: true);
        // Stay on the index input screen on error
        setState(() { _currentScreenState = ScreenState.showIndexInput; });
      }
    } catch (e) {
      print("Error finding student by index: $e");
      _showStatusMessage('Error finding student. Please try again.', isError: true);
      _foundStudent = null;
      setState(() { _currentScreenState = ScreenState.showIndexInput; });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAttendance() async {
     if (_foundStudent == null) return;
     setState(() => _isLoading = true);

     try {
       final String? adminUid = AuthController.instance.user?.uid;
       if (adminUid == null) throw Exception("Admin not logged in.");
       if (_smsGatewayToken == null || _academyName == null) {
         throw Exception("SMS configuration missing.");
       }

       final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
       final attendanceRef = _firestore
           .collection('admins')
           .doc(adminUid)
           .collection('students')
           .doc(_foundStudent!.id)
           .collection('attendance');

       // Check if already marked today
       final existingRecord = await attendanceRef.where('date', isEqualTo: today).limit(1).get();

       if (existingRecord.docs.isNotEmpty) {
          _showStatusMessage('Attendance already marked for today.', isError: true);
       } else {
          // Mark attendance in Firestore
          await attendanceRef.add({
            'date': today,
            'status': 'present',
            'markedBy': adminUid,
            'markedAt': Timestamp.now(),
          });

          // Send SMS
          final message = "Hello Mr/Mrs ${_foundStudent!.parentName}, your child ${_foundStudent!.name} from ${_foundStudent!.className} has been marked PRESENT on $today. - $_academyName | Powered by EduTrack.";
          final smsSent = await _sendSms(_foundStudent!.parentPhone, message);

          if (smsSent) {
            _showStatusMessage('Marked Successfully & SMS Sent!', isError: false);
          } else {
            _showStatusMessage('Marked Successfully, but failed to send SMS.', isError: true); // Error only for SMS failure
          }
          // Navigate back to initial screen after success/partial success
          setState(() {
            _currentScreenState = ScreenState.initial;
            _foundStudent = null;
          });
       }

     } catch (e) {
       print("Error marking attendance: $e");
       _showStatusMessage('Failed to mark attendance. $e', isError: true);
       // Stay on student details screen on error
     } finally {
       if (mounted) setState(() => _isLoading = false);
     }
   }

  Future<void> _markPayment() async {
    if (_foundStudent == null || _selectedMonth == null || !_formKeyPayment.currentState!.validate()) return;
    setState(() => _isLoading = true);
    FocusScope.of(context).unfocus();

    try {
      final String? adminUid = AuthController.instance.user?.uid;
      if (adminUid == null) throw Exception("Admin not logged in.");
       if (_smsGatewayToken == null || _academyName == null) {
         throw Exception("SMS configuration missing.");
       }

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

      // Add payment record
      await feesRef.add({
        'year': currentYear,
        'month': monthIndex,
        'amount': amount,
        'paid': true,
        'paidAt': Timestamp.now(),
        'paymentMethod': 'Manual/QR', // Indicate how it was marked
        'markedBy': adminUid,
      });

      // Send SMS
      final formattedAmount = NumberFormat("#,##0.00").format(amount);
      final message = "Payment received! ${_foundStudent!.name} from ${_foundStudent!.className} has paid Rs.$formattedAmount for ${_selectedMonth!}/$currentYear. - $_academyName | Powered by EduTrack.";
      final smsSent = await _sendSms(_foundStudent!.parentPhone, message);

      if (smsSent) {
        _showStatusMessage('Payment Marked & SMS Sent!', isError: false);
      } else {
        _showStatusMessage('Payment Marked, but failed to send SMS.', isError: true);
      }

      // Navigate back to initial screen
      setState(() {
        _currentScreenState = ScreenState.initial;
        _foundStudent = null;
        _selectedMonth = null;
        _amountController.clear();
      });

    } catch (e) {
      print("Error marking payment: $e");
      _showStatusMessage('Failed to mark payment. $e', isError: true);
      // Stay on payment input screen on error
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- SMS Sending Logic ---
  Future<bool> _sendSms(String phoneNumber, String message) async {
    if (_smsGatewayToken == null || _smsGatewayToken!.isEmpty) {
      print("SMS Gateway Token is missing.");
      return false;
    }
    // IMPORTANT: Replace with your actual Traccar SMS Gateway URL and parameters
    // This is a placeholder structure. Adjust based on your gateway's API.
    // --- IMPORTANT ---
    // Using localhost as both apps are on the same device.
    // Check the port in the Traccar SMS Gateway app settings (default is often 8082).
    const String gatewayPort = '8082'; // <-- VERIFY/CHANGE THIS PORT IF NEEDED
    final url = Uri.parse('http://192.168.248.116:$gatewayPort/');
    // --- IMPORTANT ---

    final headers = {
      // Traccar SMS Gateway app usually expects form data
      'Content-Type': 'application/x-www-form-urlencoded',
    };
    // Send data as a Map for form encoding
    final body = {
      'phone': phoneNumber, // Parameter name might differ, check app docs/source
      'message': message,
      'token': _smsGatewayToken ?? '', // Send token if available
    };

    // Debug: Print the token being sent
    print("Attempting to send SMS with token: $_smsGatewayToken");

    try {
      // Explicitly encode the body for x-www-form-urlencoded
      final encodedBody = body.entries
          .map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
          .join('&');

      final response = await http.post(url, headers: headers, body: encodedBody);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('SMS sent successfully to $phoneNumber.');
        return true;
      } else {
        print('Failed to send SMS. Status code: ${response.statusCode}, Body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error sending SMS: $e');
      return false;
    }
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
             if (_currentScreenState == ScreenState.scanning || _currentScreenState == ScreenState.showIndexInput) {
               setState(() => _currentScreenState = ScreenState.initial);
             } else if (_currentScreenState == ScreenState.showStudentDetails) {
                setState(() => _currentScreenState = ScreenState.initial); // Or scanning? Decide behavior
             } else if (_currentScreenState == ScreenState.showPaymentInput) {
                setState(() => _currentScreenState = ScreenState.showStudentDetails);
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
      case ScreenState.showPaymentInput:
        return _buildPaymentInputUI(context);
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
              onPressed: () => setState(() => _currentScreenState = ScreenState.scanning),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: kDefaultPadding * 1.2)),
            ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),
            const SizedBox(height: kDefaultPadding * 1.5),
            ElevatedButton.icon(
              icon: const Icon(Icons.edit_note_rounded, size: 24),
              label: const Text('Mark By ID'),
              onPressed: () => setState(() => _currentScreenState = ScreenState.showIndexInput),
               style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: kDefaultPadding * 1.2)),
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
           child: Text("Position the QR code within the frame", style: kHintTextStyle),
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
            onPressed: () => setState(() => _currentScreenState = ScreenState.initial),
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
                validator: (value) => value == null || value.isEmpty ? 'Please enter index number' : null,
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
                              setState(() => _currentScreenState = ScreenState.initial);
                            },
                            style: OutlinedButton.styleFrom(foregroundColor: kPrimaryColor),
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
                        Text(student.name, style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: kDefaultPadding / 2),
                        _buildDetailRow('Index No:', student.indexNumber),
                        _buildDetailRow('Grade:', student.className), // Show full class name
                        _buildDetailRow('Average Score:', student.averageScore), // Placeholder
                        _buildDetailRow('Subjects:', student.subjects.join(', ')),
                        _buildDetailRow('Sex:', student.sex),
                        _buildDetailRow('DOB:', student.dob),
                        _buildDetailRow('Parent:', student.parentName),
                        _buildDetailRow('Contact:', student.parentPhone),
                      ],
                    ),
                  ),
                  const SizedBox(width: kDefaultPadding),
                  Expanded(
                    flex: 1,
                    child: ClipRRect(
                       borderRadius: BorderRadius.circular(kDefaultRadius),
                       child: student.photoUrl != null && student.photoUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: student.photoUrl!,
                            height: 150, // Adjust height as needed
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              height: 150,
                              color: kDisabledColor.withOpacity(0.3),
                              child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            ),
                            errorWidget: (context, url, error) => Container(
                               height: 150,
                               color: kDisabledColor.withOpacity(0.3),
                               child: const Icon(Icons.person_off_outlined, color: kLightTextColor, size: 50)
                            ),
                          )
                        : Container(
                            height: 150,
                            color: kDisabledColor.withOpacity(0.3),
                            child: const Icon(Icons.person_outline_rounded, color: kLightTextColor, size: 50)
                          ),
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
                    Text('Choose an option', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: kDefaultPadding),
                    _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _markAttendance,
                                child: const Text('Mark Attendance'),
                              ),
                            ),
                            const SizedBox(width: kDefaultPadding),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => setState(() => _currentScreenState = ScreenState.showPaymentInput),
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
                         backgroundColor: kPrimaryColor.withOpacity(0.8), // Slightly different style
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
            TextSpan(text: '$label ', style: const TextStyle(fontWeight: FontWeight.w600)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  // --- UI for Payment Input ---
  Widget _buildPaymentInputUI(BuildContext context) {
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
             child: Form(
               key: _formKeyPayment,
               child: Column(
                 mainAxisSize: MainAxisSize.min, // Make card wrap content
                 crossAxisAlignment: CrossAxisAlignment.stretch,
                 children: [
                   Text('Mark for Payment', style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600)),
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
                     validator: (value) => value == null ? 'Please select a month' : null,
                     decoration: const InputDecoration(
                       prefixIcon: Icon(Icons.calendar_month_outlined),
                     ),
                   ).animate().fadeIn(delay: 100.ms),
                   const SizedBox(height: kDefaultPadding),
                   // Amount Input
                   TextFormField(
                     controller: _amountController,
                     decoration: const InputDecoration(
                       labelText: 'Enter the Amount',
                       prefixIcon: Icon(Icons.currency_rupee_rounded), // Assuming Rupee
                     ),
                     keyboardType: TextInputType.numberWithOptions(decimal: true),
                     validator: (value) {
                       if (value == null || value.isEmpty) return 'Please enter amount';
                       if (double.tryParse(value) == null) return 'Invalid amount';
                       if (double.parse(value) <= 0) return 'Amount must be positive';
                       return null;
                     },
                     autovalidateMode: AutovalidateMode.onUserInteraction,
                   ).animate().fadeIn(delay: 150.ms),
                   const SizedBox(height: kDefaultPadding * 1.5),
                   // Action Buttons
                   _isLoading
                       ? const Center(child: CircularProgressIndicator())
                       : Row(
                           children: [
                             Expanded(
                               child: ElevatedButton(
                                 onPressed: _markPayment,
                                 child: const Text('Mark Payment'),
                               ).animate().fadeIn(delay: 200.ms),
                             ),
                             const SizedBox(width: kDefaultPadding),
                             Expanded(
                               child: OutlinedButton(
                                 onPressed: () => setState(() => _currentScreenState = ScreenState.showStudentDetails),
                                 style: OutlinedButton.styleFrom(foregroundColor: kPrimaryColor),
                                 child: const Text('Go Back'),
                               ).animate().fadeIn(delay: 250.ms),
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

  // --- Status Message Widget (Similar to AddTeacherScreen) ---
  Widget _buildStatusMessageWidget(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AnimatedOpacity(
      opacity: _statusMessage != null ? 1.0 : 0.0,
      duration: 300.ms,
      child: Padding(
        // Add padding only when message is visible
        padding: _statusMessage != null
            ? const EdgeInsets.only(bottom: kDefaultPadding, left: kDefaultPadding, right: kDefaultPadding)
            : EdgeInsets.zero,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding, vertical: kDefaultPadding * 0.7),
            decoration: BoxDecoration(
              color: _isError ? kErrorColor.withOpacity(0.15) : kSuccessColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(kDefaultRadius),
              border: Border.all(color: _isError ? kErrorColor : kSuccessColor, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
                  color: _isError ? kErrorColor : kSuccessColor,
                  size: 20,
                ),
                const SizedBox(width: kDefaultPadding / 2),
                Flexible( // Allow text to wrap
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