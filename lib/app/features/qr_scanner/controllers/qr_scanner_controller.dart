import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edu_track/app/features/authentication/controllers/auth_controller.dart';
import 'package:edu_track/app/models/payment_model.dart';
import 'package:edu_track/app/models/student_model.dart';
import 'package:edu_track/app/services/whatsapp_service.dart';
import 'package:edu_track/main.dart'; // For AppRoutes
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

// Enum to manage the different states of the screen
enum ScreenState {
  initial,
  scanning,
  showIndexInput,
  showStudentDetails,
  showStudentDetailsWithPendingPayments,
  showPaymentTypeSelection,
  showMonthlyPaymentInput,
  showDailyPaymentInput
}

// Enum for payment types
enum PaymentType { monthly, daily }

class QrScannerController extends GetxController {
  // ─────────────────────────────────────────────────────────────────────────────
  // DEPENDENCIES & UI CONTROLLERS
  // ─────────────────────────────────────────────────────────────────────────────
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // MobileScannerController needs to be disposed
  final MobileScannerController scannerController = MobileScannerController();
  
  // Text Controllers
  final TextEditingController indexController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController pendingReasonController = TextEditingController();

  // Form Keys
  final GlobalKey<FormState> formKeyIndex = GlobalKey<FormState>();
  final GlobalKey<FormState> formKeyPayment = GlobalKey<FormState>(); // For inline forms
  final GlobalKey<FormState> dialogPaymentFormKey = GlobalKey<FormState>(); // For generic payment dialog
  final GlobalKey<FormState> dialogPendingFormKey = GlobalKey<FormState>(); // For pending dialog

  
  // ─────────────────────────────────────────────────────────────────────────────
  // REACTIVE STATE (OBSERVABLES)
  // ─────────────────────────────────────────────────────────────────────────────
  final Rx<ScreenState> currentScreenState = ScreenState.initial.obs;
  final RxBool isLoading = false.obs;
  
  final Rxn<Student> foundStudent = Rxn<Student>();
  
  // Status Message
  final RxnString statusMessage = RxnString();
  final RxBool isError = false.obs;

  // Payment Selection State
  final RxnString selectedMonth = RxnString();
  final Rxn<DateTime> selectedDate = Rxn<DateTime>();
  final RxList<String> selectedSubjects = <String>[].obs;
  final RxnString selectedPaymentTypeForDialog = RxnString(); // 'monthly' or 'daily'

  // Configuration
  final RxnString academyName = RxnString();

  // Pending Payments
  final RxList<PendingPaymentItem> existingPendingPayments = <PendingPaymentItem>[].obs;
  final RxString pendingPaymentsFilter = 'all'.obs;
  final RxString pendingSubjectFilter = 'All'.obs;
  
  // Flags
  final RxBool attendanceMarked = false.obs;

  // Constants
  final List<String> months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  // ─────────────────────────────────────────────────────────────────────────────
  // LIFECYCLE
  // ─────────────────────────────────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    _fetchAdminDetails();
  }

  @override
  void onClose() {
    scannerController.dispose();
    indexController.dispose();
    amountController.dispose();
    descriptionController.dispose();
    pendingReasonController.dispose();
    super.onClose();
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // INITIALIZATION
  // ─────────────────────────────────────────────────────────────────────────────
  Future<void> _fetchAdminDetails() async {
    final String? userId = AuthController.instance.user?.uid;
    if (userId == null) {
      showStatusMessage("Error: Admin user not logged in.", isError: true);
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
        academyName.value = data?['academyName'];
      }
    } catch (e) {
      print("Error fetching admin details: $e");
      showStatusMessage("Error fetching configuration.", isError: true);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // STATUS MESSAGES
  // ─────────────────────────────────────────────────────────────────────────────
  void showStatusMessage(String message, {bool isError = false, Duration duration = const Duration(seconds: 3)}) {
    statusMessage.value = message;
    this.isError.value = isError;
    Future.delayed(duration, () {
      statusMessage.value = null;
    });
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // STUDENT SEARCH LOGIC
  // ─────────────────────────────────────────────────────────────────────────────
  Future<void> findStudentByQrCode(String qrCodeData) async {
    if (qrCodeData.isEmpty) return;
    
    isLoading.value = true;
    currentScreenState.value = ScreenState.initial;

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
        foundStudent.value = Student.fromFirestore(querySnapshot.docs.first);
        currentScreenState.value = ScreenState.showStudentDetails;
        showStatusMessage('Scanned Successfully!', isError: false);

        await _fetchAndCalculateAverageScore();
        await fetchExistingPendingPayments();
      } else {
        foundStudent.value = null;
        showStatusMessage('QR Code does not match any student.', isError: true);
        currentScreenState.value = ScreenState.initial;
      }
    } catch (e) {
      print("Error finding student by QR code: $e");
      showStatusMessage('Error finding student. Please try again.', isError: true);
      foundStudent.value = null;
      currentScreenState.value = ScreenState.initial;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> findStudentByIndex(String indexNum) async {
    if (indexNum.isEmpty) return;
    
    isLoading.value = true;
    // Hide keyboard if context available or rely on UI to handle
    FocusManager.instance.primaryFocus?.unfocus();

    try {
      final String? adminUid = AuthController.instance.user?.uid;
      if (adminUid == null) throw Exception("Admin not logged in.");

      final querySnapshot = await _firestore
          .collection('admins')
          .doc(adminUid)
          .collection('students')
          .where('indexNumber', isEqualTo: indexNum.trim())
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        foundStudent.value = Student.fromFirestore(querySnapshot.docs.first);
        currentScreenState.value = ScreenState.showStudentDetails;
        showStatusMessage('Index No Matched!', isError: false);

        await _fetchAndCalculateAverageScore();
        await fetchExistingPendingPayments();
      } else {
        foundStudent.value = null;
        showStatusMessage('Index number does not match any student.', isError: true);
        // Stay on index input
        currentScreenState.value = ScreenState.showIndexInput;
      }
    } catch (e) {
      print("Error finding student by index: $e");
      showStatusMessage('Error finding student. Please try again.', isError: true);
      foundStudent.value = null;
      currentScreenState.value = ScreenState.showIndexInput;
    } finally {
      isLoading.value = false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // ATTENDANCE LOGIC
  // ─────────────────────────────────────────────────────────────────────────────
  Future<void> markAttendanceWithSubject(String subject) async {
    if (foundStudent.value == null) return;
    isLoading.value = true;

    try {
      final String? adminUid = AuthController.instance.user?.uid;
      if (adminUid == null) throw Exception("Admin not logged in.");

      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final attendanceRef = _firestore
          .collection('admins')
          .doc(adminUid)
          .collection('students')
          .doc(foundStudent.value!.id)
          .collection('attendance');

      // Check duplicate
      final existingRecord = await attendanceRef
          .where('date', isEqualTo: today)
          .where('subject', isEqualTo: subject)
          .limit(1)
          .get();

      if (existingRecord.docs.isNotEmpty) {
        showStatusMessage('Attendance already marked for $subject today.', isError: true);
        return;
      }

      await attendanceRef.add({
        'date': today,
        'subject': subject,
        'status': 'present',
        'markedBy': adminUid,
        'markedAt': Timestamp.now(),
      });

      // Notification
      final whatsappSent = await WhatsAppService.sendAttendanceNotification(
        studentName: foundStudent.value!.name,
        parentName: foundStudent.value!.parentName,
        parentPhone: foundStudent.value!.whatsappNumber,
        subject: subject,
        className: foundStudent.value!.className,
        schoolName: academyName.value ?? 'EduTrack Academy',
      );

      if (whatsappSent) {
        showStatusMessage('Attendance marked & WhatsApp sent! 📱✅');
      } else {
        showStatusMessage('Attendance marked but WhatsApp notification failed.', isError: true);
      }

      attendanceMarked.value = true;
      currentScreenState.value = ScreenState.showStudentDetails;
      await fetchExistingPendingPayments();

    } catch (e) {
      print("Error marking attendance: $e");
      showStatusMessage('Failed to mark attendance: $e', isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // PAYMENT LOGIC
  // ─────────────────────────────────────────────────────────────────────────────
  Future<void> markMonthlyPayment() async {
    // Validation should happen in UI before calling this or inside if we pass context/key
    // For now assuming validation passed or simple checks
    if (foundStudent.value == null || selectedMonth.value == null || selectedSubjects.isEmpty) {
        if (selectedSubjects.isEmpty) showStatusMessage('Please select at least one subject', isError: true);
        return;
    }

    isLoading.value = true;
    FocusManager.instance.primaryFocus?.unfocus();

    try {
      final String? adminUid = AuthController.instance.user?.uid;
      if (adminUid == null) throw Exception("Admin not logged in.");

      final amount = double.tryParse(amountController.text.trim());
      if (amount == null || amount <= 0) throw Exception("Invalid amount entered.");

      final monthIndex = months.indexOf(selectedMonth.value!) + 1;
      final currentYear = DateTime.now().year;

      final feesRef = _firestore
          .collection('admins')
          .doc(adminUid)
          .collection('students')
          .doc(foundStudent.value!.id)
          .collection('fees');

      await feesRef.add({
        'paymentType': 'monthly',
        'year': currentYear,
        'month': monthIndex,
        'date': null,
        'subjects': selectedSubjects.toList(),
        'amount': amount,
        'paid': true,
        'paidAt': Timestamp.now(),
        'paymentMethod': 'Manual/QR',
        'markedBy': adminUid,
        'description': 'Monthly fee for ${selectedSubjects.join(", ")} - ${selectedMonth.value} $currentYear',
      });

      final whatsappSent = await WhatsAppService.sendMonthlyPaymentNotification(
        studentName: foundStudent.value!.name,
        parentName: foundStudent.value!.parentName,
        parentPhone: foundStudent.value!.whatsappNumber,
        amount: amount,
        month: selectedMonth.value!,
        year: currentYear,
        subjects: selectedSubjects.toList(),
        schoolName: academyName.value ?? 'EduTrack Academy',
      );

      if (whatsappSent) {
        showStatusMessage('Monthly payment marked & WhatsApp sent! 💰📱✅');
      } else {
        showStatusMessage('Monthly payment marked but WhatsApp notification failed.', isError: true);
      }

      resetPaymentState();
      currentScreenState.value = ScreenState.initial;
      foundStudent.value = null;

    } catch (e) {
      print("Error marking monthly payment: $e");
      showStatusMessage('Failed to mark payment. $e', isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> markDailyPayment() async {
    if (foundStudent.value == null || selectedDate.value == null || selectedSubjects.isEmpty) {
      if (selectedDate.value == null) {
        showStatusMessage('Please select a date', isError: true);
      } else if (selectedSubjects.isEmpty) {
        showStatusMessage('Please select at least one subject', isError: true);
      }
      return;
    }

    isLoading.value = true;
    FocusManager.instance.primaryFocus?.unfocus();

    try {
      final String? adminUid = AuthController.instance.user?.uid;
      if (adminUid == null) throw Exception("Admin not logged in.");

      final amount = double.tryParse(amountController.text.trim());
      if (amount == null || amount <= 0) throw Exception("Invalid amount entered.");

      final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate.value!);

      final feesRef = _firestore
          .collection('admins')
          .doc(adminUid)
          .collection('students')
          .doc(foundStudent.value!.id)
          .collection('fees');

      await feesRef.add({
        'paymentType': 'daily',
        'year': selectedDate.value!.year,
        'month': selectedDate.value!.month,
        'date': dateStr,
        'subjects': selectedSubjects.toList(),
        'amount': amount,
        'paid': true,
        'paidAt': Timestamp.now(),
        'paymentMethod': 'Manual/QR',
        'markedBy': adminUid,
        'description': 'Daily class fee for ${selectedSubjects.join(", ")} - $dateStr',
      });

      final whatsappSent = await WhatsAppService.sendDailyPaymentNotification(
        studentName: foundStudent.value!.name,
        parentName: foundStudent.value!.parentName,
        parentPhone: foundStudent.value!.whatsappNumber,
        amount: amount,
        date: dateStr,
        subjects: selectedSubjects.toList(),
        schoolName: academyName.value ?? 'EduTrack Academy',
      );

      if (whatsappSent) {
        showStatusMessage('Daily payment marked & WhatsApp sent! 💰📱✅');
      } else {
        showStatusMessage('Daily payment marked but WhatsApp notification failed.', isError: true);
      }

      resetPaymentState();
      currentScreenState.value = ScreenState.initial;
      foundStudent.value = null;
    } catch (e) {
      print("Error marking daily payment: $e");
      showStatusMessage('Failed to mark payment. $e', isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // PENDING PAYMENTS LOGIC
  // ─────────────────────────────────────────────────────────────────────────────
  Future<void> fetchExistingPendingPayments() async {
    if (foundStudent.value == null) return;

    try {
      final String? adminUid = AuthController.instance.user?.uid;
      if (adminUid == null) throw Exception("Admin not logged in.");

      final feesQuery = await _firestore
          .collection('admins')
          .doc(adminUid)
          .collection('students')
          .doc(foundStudent.value!.id)
          .collection('fees')
          .get();

      final List<PendingPaymentItem> payments = [];

      for (final doc in feesQuery.docs) {
        final data = doc.data();
        final bool isPending = data.containsKey('status')
            ? data['status'] == 'PENDING'
            : data['paid'] == false;

        if (isPending) {
          payments.add(PendingPaymentItem.fromFirestore(doc));
        }
      }

      existingPendingPayments.assignAll(payments);
      
      // Cleanup filter if subject no longer valid
      final availableSubjects = {
        ...?foundStudent.value?.subjects,
        ...existingPendingPayments.expand((e) => e.subjects)
      }..removeWhere((s) => s.trim().isEmpty);
      
      if (pendingSubjectFilter.value != 'All' && !availableSubjects.contains(pendingSubjectFilter.value)) {
        pendingSubjectFilter.value = 'All';
      }

    } catch (e) {
      print("Error fetching pending payments: $e");
      showStatusMessage('Failed to load pending payments: $e', isError: true);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // GENERIC PAYMENT LOGIC (Unified Dialog)
  // ─────────────────────────────────────────────────────────────────────────────
  Future<void> markGenericPayment({
    required String paymentType, // 'monthly' or 'daily'
    String? month,
    DateTime? date,
    required List<String> subjects,
    required double amount,
    String? description,
    bool isPending = false,
    String? pendingReason,
  }) async {
    // Basic validation
    if (foundStudent.value == null) return;
    
    isLoading.value = true;
    
    try {
      final String? adminUid = AuthController.instance.user?.uid;
      if (adminUid == null) throw Exception("Admin not logged in.");

      final now = DateTime.now();
      final feesRef = _firestore
          .collection('admins')
          .doc(adminUid)
          .collection('students')
          .doc(foundStudent.value!.id)
          .collection('fees');

      final paymentData = {
        'paymentType': paymentType,
        'year': paymentType == 'monthly' ? now.year : date!.year,
        'subjects': subjects,
        'amount': amount,
        'status': isPending ? 'PENDING' : 'PAID',
        'paid': !isPending, // Backward comp
        'pendingAmount': isPending ? amount : 0.0,
        'paymentMethod': 'Manual/QR',
        'markedBy': adminUid,
        'description': description?.isNotEmpty == true
            ? description
            : _generateDescription(paymentType, month, date, subjects),
      };

      if (isPending) {
         paymentData['pendingAt'] = Timestamp.now();
         if (pendingReason?.isNotEmpty == true) {
           paymentData['pendingReason'] = pendingReason;
         }
      } else {
         paymentData['paidAt'] = Timestamp.now();
      }

      if (paymentType == 'monthly' && month != null) {
        paymentData['month'] = months.indexOf(month) + 1;
      } else if (paymentType == 'daily' && date != null) {
        paymentData['date'] = DateFormat('yyyy-MM-dd').format(date);
        paymentData['month'] = date.month;
      }

      await feesRef.add(paymentData);

      // Notification
      final whatsappSent = await WhatsAppService.sendPaymentStatusNotification(
        studentName: foundStudent.value!.name,
        parentName: foundStudent.value!.parentName,
        parentPhone: foundStudent.value!.whatsappNumber,
        paymentType: paymentType,
        status: isPending ? 'PENDING' : 'PAID',
        amount: amount,
        pendingAmount: isPending ? amount : 0.0,
        period: paymentType == 'monthly'
            ? '$month ${now.year}'
            : DateFormat('dd/MM/yyyy').format(date!),
        subjects: subjects,
        schoolName: academyName.value ?? 'EduTrack Academy',
        isNonePayee: foundStudent.value!.isNonePayee,
      );

      final statusStr = isPending ? 'PENDING' : 'PAID';
      if (whatsappSent) {
        showStatusMessage('Payment marked as $statusStr & WhatsApp sent! 📱✅');
      } else {
        showStatusMessage('Payment marked as $statusStr but WhatsApp notification failed.', isError: true);
      }

      await fetchExistingPendingPayments();
      // Reset dialog state implicitly handled by UI closing dialog

    } catch (e) {
      print("Error marking generic payment: $e");
      showStatusMessage('Failed to mark payment: $e', isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  String _generateDescription(String paymentType, String? month, DateTime? date, List<String> subjects) {
    if (paymentType == 'monthly') {
      return 'Monthly fee for ${subjects.join(", ")} - $month ${DateTime.now().year}';
    } else {
      final dateString = date != null ? DateFormat('dd/MM/yyyy').format(date) : 'Unknown date';
      return 'Daily class fee for ${subjects.join(", ")} - $dateString';
    }
  }

  // Helper getters for filtered payments
  List<PendingPaymentItem> get filteredPendingPayments {
    Iterable<PendingPaymentItem> items = existingPendingPayments;
    if (pendingPaymentsFilter.value != 'all') {
      items = items.where((item) => item.paymentType == pendingPaymentsFilter.value);
    }
    if (pendingSubjectFilter.value != 'All') {
      items = items.where((item) => item.subjects.contains(pendingSubjectFilter.value));
    }
    return items.toList();
  }

  double get totalPendingAmount {
    return filteredPendingPayments.fold(0.0, (sum, item) => sum + (item.pendingAmount > 0 ? item.pendingAmount : item.amount));
  }

  // Mark payment as PENDING
  Future<void> markPaymentAsPending() async {
     // Assume validation done in UI
     Get.back(); // Close dialog if open
     isLoading.value = true;
     
     try {
       final String? adminUid = AuthController.instance.user?.uid;
       if (adminUid == null) throw Exception("Admin not logged in.");

       final amount = double.parse(amountController.text.trim());
       final now = DateTime.now();
       final feesRef = _firestore.collection('admins').doc(adminUid).collection('students').doc(foundStudent.value!.id).collection('fees');

       final paymentData = {
         'paymentType': selectedPaymentTypeForDialog.value,
         'amount': amount,
         'pendingAmount': amount, // Initial pending is full amount
         'status': 'PENDING',
         'paid': false,
         'pendingAt': Timestamp.fromDate(now),
         'subjects': selectedSubjects.toList(),
         'description': descriptionController.text.trim().isNotEmpty 
             ? descriptionController.text.trim()
             : (selectedPaymentTypeForDialog.value == 'monthly' 
                 ? 'Monthly - ${selectedMonth.value}' 
                 : 'Daily Class'),
         'pendingReason': pendingReasonController.text.trim(),
       };

       if (selectedPaymentTypeForDialog.value == 'monthly') {
          paymentData['month'] = months.indexOf(selectedMonth.value!) + 1;
          paymentData['year'] = now.year;
       } else {
          paymentData['date'] = DateFormat('yyyy-MM-dd').format(selectedDate.value!);
          paymentData['year'] = selectedDate.value!.year;
          paymentData['month'] = selectedDate.value!.month;
       }

       await feesRef.add(paymentData);

       showStatusMessage('Payment marked as PENDING', isError: false);
       await fetchExistingPendingPayments();

       resetPaymentState();
     } catch (e) {
        showStatusMessage('Error marking pending: $e', isError: true);
     } finally {
        isLoading.value = false;
     }
  }
  
  // Mark pending item as PAID
  Future<void> markPaymentAsPaid(String paymentId, double amountFound, {String? paymentTypeFn, String? periodFn}) async {
    // Basic logic - full payment for now
    Get.back(); // close dialog
    isLoading.value = true;

    try {
      final String? adminUid = AuthController.instance.user?.uid;
      // ... logic to update firestore
       final feesRef = _firestore
          .collection('admins')
          .doc(adminUid)
          .collection('students')
          .doc(foundStudent.value!.id)
          .collection('fees')
          .doc(paymentId);
          
       await feesRef.update({
         'status': 'PAID',
         'paid': true,
         'paidAt': Timestamp.now(),
         'paymentMethod': 'Cash/Manual',
         'pendingAmount': 0.0, // Fully paid
       });

       // Send Notification using sendPaymentStatusNotification
       await WhatsAppService.sendPaymentStatusNotification(
         studentName: foundStudent.value!.name,
         parentName: foundStudent.value!.parentName,
         parentPhone: foundStudent.value!.whatsappNumber,
         paymentType: paymentTypeFn ?? 'payment',
         status: 'PAID',
         amount: amountFound,
         period: periodFn ?? '',
         subjects: [], // No subjects for generic paid notification
         schoolName: academyName.value ?? 'EduTrack Academy',
         isNonePayee: foundStudent.value!.isNonePayee,
       );

       showStatusMessage('Payment received & stats updated! ✅');
       await fetchExistingPendingPayments();
    } catch(e) {
      showStatusMessage('Error updating payment: $e', isError: true);
    } finally {
      isLoading.value = false;
    }
  }
  
  // Send Reminder
  Future<void> sendPaymentReminder(PendingPaymentItem item) async {
    Get.back(); // close dialog
    isLoading.value = true;
    try {
       final sent = await WhatsAppService.sendPaymentStatusNotification(
         studentName: foundStudent.value!.name,
         parentName: foundStudent.value!.parentName,
         parentPhone: foundStudent.value!.whatsappNumber,
         paymentType: item.paymentType,
         status: 'PENDING',
         amount: item.amount,
         pendingAmount: item.pendingAmount > 0 ? item.pendingAmount : item.amount,
         period: item.getMonthYearDisplay(),
         subjects: item.subjects,
         schoolName: academyName.value ?? 'EduTrack Academy',
         isNonePayee: foundStudent.value!.isNonePayee,
       );
       
       if (sent) showStatusMessage('Reminder sent successfully! 📩');
       else showStatusMessage('Failed to send reminder.', isError: true);
    } catch(e) {
       showStatusMessage('Error sending reminder: $e', isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // HELPER METHODS
  // ─────────────────────────────────────────────────────────────────────────────
  void resetPaymentState() {
    selectedMonth.value = null;
    selectedDate.value = null;
    selectedSubjects.clear();
    amountController.clear();
    descriptionController.clear();
    pendingReasonController.clear();
    selectedPaymentTypeForDialog.value = null;
  }
  
  Future<void> _fetchAndCalculateAverageScore() async {
    if (foundStudent.value == null) return;
    try {
      final uid = AuthController.instance.user?.uid;
      if (uid == null) return;
      
      final results = await _firestore.collection('admins').doc(uid).collection('students').doc(foundStudent.value!.id).collection('examResults').get();
       
      if (results.docs.isEmpty) return;
      
      // Calculate simple average for now (can be improved)
      double total = 0;
      int count = 0;
      for (var doc in results.docs) {
         final marks = doc.data()['marks'] as double?;
         if (marks != null) {
           total += marks;
           count++;
         }
      }
      
      if (count > 0) {
        // Update local student instance with average
        foundStudent.value = foundStudent.value!.copyWith(averageScoreValue: total / count);
      }
    } catch (e) {
      print("Error calculating score: $e");
    }
  }

  // Helper for toggle selection
  void toggleSubjectSelection(String subject) {
    if (selectedSubjects.contains(subject)) {
      selectedSubjects.remove(subject);
    } else {
      selectedSubjects.add(subject);
    }
  }
}
