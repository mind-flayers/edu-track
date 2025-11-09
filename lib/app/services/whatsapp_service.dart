import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edu_track/app/features/authentication/controllers/auth_controller.dart';

class WhatsAppService {
  // Smart solution: Use Firebase as bridge instead of direct connection
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Smart WhatsApp sending via Firebase bridge
  static Future<bool> sendAttendanceNotification({
    required String studentName,
    required String parentName,
    required String parentPhone,
    required String subject,
    required String className,
    required String schoolName,
  }) async {
    final message = _formatAttendanceMessage(
      studentName: studentName,
      parentName: parentName,
      subject: subject,
      className: className,
      schoolName: schoolName,
    );

    return await _queueMessageViaFirebase(
        phoneNumber: parentPhone,
        message: message,
        type: 'attendance',
        metadata: {
          'studentName': studentName,
          'subject': subject,
          'className': className,
        });
  }

  /// Send payment notification via Firebase bridge
  static Future<bool> sendPaymentNotification({
    required String studentName,
    required String parentName,
    required String parentPhone,
    required double amount,
    required String month,
    required int year,
    required String schoolName,
  }) async {
    final message = _formatPaymentMessage(
      studentName: studentName,
      parentName: parentName,
      amount: amount,
      month: month,
      year: year,
      schoolName: schoolName,
    );

    return await _queueMessageViaFirebase(
        phoneNumber: parentPhone,
        message: message,
        type: 'payment',
        metadata: {
          'studentName': studentName,
          'amount': amount,
          'month': month,
          'year': year,
        });
  }

  /// Send monthly payment notification via Firebase bridge
  static Future<bool> sendMonthlyPaymentNotification({
    required String studentName,
    required String parentName,
    required String parentPhone,
    required double amount,
    required String month,
    required int year,
    required List<String> subjects,
    required String schoolName,
  }) async {
    final message = _formatMonthlyPaymentMessage(
      studentName: studentName,
      parentName: parentName,
      amount: amount,
      month: month,
      year: year,
      subjects: subjects,
      schoolName: schoolName,
    );

    return await _queueMessageViaFirebase(
        phoneNumber: parentPhone,
        message: message,
        type: 'monthly_payment',
        metadata: {
          'studentName': studentName,
          'amount': amount,
          'month': month,
          'year': year,
          'subjects': subjects,
        });
  }

  /// Send daily payment notification via Firebase bridge
  static Future<bool> sendDailyPaymentNotification({
    required String studentName,
    required String parentName,
    required String parentPhone,
    required double amount,
    required String date,
    required List<String> subjects,
    required String schoolName,
  }) async {
    final message = _formatDailyPaymentMessage(
      studentName: studentName,
      parentName: parentName,
      amount: amount,
      date: date,
      subjects: subjects,
      schoolName: schoolName,
    );

    return await _queueMessageViaFirebase(
        phoneNumber: parentPhone,
        message: message,
        type: 'daily_payment',
        metadata: {
          'studentName': studentName,
          'amount': amount,
          'date': date,
          'subjects': subjects,
        });
  }

  /// ✅ NEW: Send payment status notification (PAID/PENDING/None Payee)
  static Future<bool> sendPaymentStatusNotification({
    required String studentName,
    required String parentName,
    required String parentPhone,
    required String paymentType,
    required String status, // "PAID" or "PENDING"
    required double amount,
    double? pendingAmount,
    required String period,
    required List<String> subjects,
    required String schoolName,
    required bool isNonePayee,
  }) async {
    String message;

    if (isNonePayee) {
      message = _formatNonePayeeNotification(
        studentName: studentName,
        parentName: parentName,
        period: period,
        subjects: subjects,
        schoolName: schoolName,
      );
    } else if (status == 'PAID') {
      message = _formatPaidNotification(
        studentName: studentName,
        parentName: parentName,
        paymentType: paymentType,
        amount: amount,
        period: period,
        subjects: subjects,
        schoolName: schoolName,
      );
    } else {
      // PENDING
      message = _formatPendingNotification(
        studentName: studentName,
        parentName: parentName,
        paymentType: paymentType,
        pendingAmount: pendingAmount ?? amount,
        totalAmount: amount,
        period: period,
        subjects: subjects,
        schoolName: schoolName,
      );
    }

    return await _queueMessageViaFirebase(
        phoneNumber: parentPhone,
        message: message,
        type: 'payment_status',
        metadata: {
          'studentName': studentName,
          'status': status,
          'paymentType': paymentType,
          'amount': amount,
          'isNonePayee': isNonePayee,
        });
  }

  /// Smart Firebase-based message queuing (always works)
  static Future<bool> _queueMessageViaFirebase({
    required String phoneNumber,
    required String message,
    required String type,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final String? adminUid = AuthController.instance.user?.uid;
      if (adminUid == null) {
        print('❌ No admin user found');
        return false;
      }

      print('🧠 Smart WhatsApp: Queuing via Firebase...');

      // Add to Firebase queue - this triggers Cloud Function automatically
      await _firestore
          .collection('admins')
          .doc(adminUid)
          .collection('whatsappQueue')
          .add({
        'phone': phoneNumber,
        'message': message,
        'type': type,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'metadata': metadata ?? {},
        'attempts': 0,
      });

      print('✅ Message queued successfully! Firebase will handle delivery.');
      return true; // Always return true since Firebase will handle it
    } catch (e) {
      print('❌ Error queuing message via Firebase: $e');
      return false;
    }
  }

  /// Get message status from Firebase
  static Stream<List<Map<String, dynamic>>> getMessageStatusStream() {
    final String? adminUid = AuthController.instance.user?.uid;
    if (adminUid == null) return Stream.empty();

    return _firestore
        .collection('admins')
        .doc(adminUid)
        .collection('whatsappQueue')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  /// Get pending messages count
  static Future<int> getPendingMessagesCount() async {
    try {
      final String? adminUid = AuthController.instance.user?.uid;
      if (adminUid == null) return 0;

      final snapshot = await _firestore
          .collection('admins')
          .doc(adminUid)
          .collection('whatsappQueue')
          .where('status', whereIn: ['pending', 'failed']).get();

      return snapshot.docs.length;
    } catch (e) {
      print('Error getting pending count: $e');
      return 0;
    }
  }

  /// Retry failed messages via Firebase function
  static Future<bool> retryFailedMessages() async {
    try {
      // This would call the Firebase Cloud Function
      // For now, just reset failed messages to pending
      final String? adminUid = AuthController.instance.user?.uid;
      if (adminUid == null) return false;

      final failedMessages = await _firestore
          .collection('admins')
          .doc(adminUid)
          .collection('whatsappQueue')
          .where('status', isEqualTo: 'failed')
          .where('retryCount', isLessThan: 3)
          .get();

      final batch = _firestore.batch();
      for (var doc in failedMessages.docs) {
        batch.update(doc.reference, {
          'status': 'pending',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      print('🔄 Retry initiated for ${failedMessages.docs.length} messages');
      return true;
    } catch (e) {
      print('Error retrying messages: $e');
      return false;
    }
  }

  /// Health check now checks Firebase connectivity (always available)
  static Future<bool> checkServiceHealth() async {
    try {
      final String? adminUid = AuthController.instance.user?.uid;
      if (adminUid == null) return false;

      // Test Firebase connectivity
      await _firestore
          .collection('admins')
          .doc(adminUid)
          .collection('whatsappQueue')
          .limit(1)
          .get();

      print('✅ Firebase WhatsApp bridge is healthy');
      return true;
    } catch (e) {
      print('❌ Firebase connectivity issue: $e');
      return false;
    }
  }

  /// Send a test message via Firebase bridge
  static Future<bool> sendTestMessage(String phoneNumber,
      {String? customMessage}) async {
    final message = customMessage ??
        '🧪 Test Message from EduTrack\n\nThis is a test message to verify WhatsApp integration is working.\n\nTime: ${DateTime.now().toString()}\n\nIf you received this, the integration is successful! 🎉';

    return await _queueMessageViaFirebase(
      phoneNumber: phoneNumber,
      message: message,
      type: 'test',
    );
  }

  /// Format attendance notification message
  static String _formatAttendanceMessage({
    required String studentName,
    required String parentName,
    required String subject,
    required String className,
    required String schoolName,
  }) {
    final now = DateTime.now();
    final date = '${now.day}/${now.month}/${now.year}';
    final time =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return '''✅ *Attendance Marked*

Hello Mr/Mrs $parentName,

Your son/daughter *$studentName* from *$className* has been marked *PRESENT* for *$subject* class.

*Date:* $date
*Time:* $time

Best regards,
$schoolName,
_Powered by EduTrack_''';
  }

  /// Format payment notification message
  static String _formatPaymentMessage({
    required String studentName,
    required String parentName,
    required double amount,
    required String month,
    required int year,
    required String schoolName,
  }) {
    final formattedAmount = amount.toStringAsFixed(2);
    final receiptNo =
        'EDU${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    return '''✔️ *Payment Received*

Dear $parentName,

We have successfully received the payment for *$studentName*.

*Amount:* Rs. $formattedAmount
*For:* $month $year
*Receipt #:* ```$receiptNo```
*Paid on:* ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}

Thank you for your payment! 🙏

Best regards,
$schoolName
_Powered by EduTrack_''';
  }

  /// Format monthly payment notification message
  static String _formatMonthlyPaymentMessage({
    required String studentName,
    required String parentName,
    required double amount,
    required String month,
    required int year,
    required List<String> subjects,
    required String schoolName,
  }) {
    final formattedAmount = amount.toStringAsFixed(2);
    final receiptNo =
        'EDU${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final subjectsText = subjects.join(', ');

    return '''✔️ *Monthly Payment Received*

Dear $parentName,

We have successfully received the monthly payment for *$studentName*.

*Subjects:* $subjectsText
*Amount:* Rs. $formattedAmount
*For:* $month $year
*Receipt #:* ```$receiptNo```
*Paid on:* ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}

Thank you for your monthly payment! 🙏

Best regards,
$schoolName
_Powered by EduTrack_''';
  }

  /// Format daily payment notification message
  static String _formatDailyPaymentMessage({
    required String studentName,
    required String parentName,
    required double amount,
    required String date,
    required List<String> subjects,
    required String schoolName,
  }) {
    final formattedAmount = amount.toStringAsFixed(2);
    final receiptNo =
        'EDU${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final subjectsText = subjects.join(', ');

    // Format date for display
    final dateObj = DateTime.parse(date);
    final formattedDate = '${dateObj.day}/${dateObj.month}/${dateObj.year}';

    return '''✔️ *Daily Payment Received*

Dear $parentName,

We have successfully received the daily class payment for *$studentName*.

*Classes:* $subjectsText
Date:* $formattedDate
*Amount:* Rs. $formattedAmount
*Receipt #:* ```$receiptNo```
*Paid on:* ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}

Thank you for your payment! 🙏

Best regards,
*$schoolName*
_Powered by EduTrack_''';
  }

  /// ✅ NEW: Format PAID status notification message
  static String _formatPaidNotification({
    required String studentName,
    required String parentName,
    required String paymentType,
    required double amount,
    required String period,
    required List<String> subjects,
    required String schoolName,
  }) {
    final formattedAmount = amount.toStringAsFixed(2);
    final receiptNo =
        'EDU${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    return '''✅ *Payment Received - PAID*

Dear Mr/Mrs $parentName,

Payment successfully received for *$studentName*.

*Type:* ${paymentType.toUpperCase()}
*Period:* $period
*Subjects:* ${subjects.join(', ')}
*Amount:* Rs. $formattedAmount
*Status:* PAID ✅
*Receipt #:* ```$receiptNo```

Thank you for your payment! 🙏

Best regards,
$schoolName
_Powered by EduTrack_''';
  }

  /// ✅ NEW: Format PENDING status notification message
  static String _formatPendingNotification({
    required String studentName,
    required String parentName,
    required String paymentType,
    required double pendingAmount,
    required double totalAmount,
    required String period,
    required List<String> subjects,
    required String schoolName,
  }) {
    return '''⏳ *Payment Status - PENDING*

Dear Mr/Mrs $parentName,

Payment status updated for *$studentName*.

*Type:* ${paymentType.toUpperCase()}
*Period:* $period
*Subjects:* ${subjects.join(', ')}
*Pending Amount:* Rs. ${pendingAmount.toStringAsFixed(2)}
*Total Amount:* Rs. ${totalAmount.toStringAsFixed(2)}
*Status:* PENDING ⏳

Please complete the remaining payment at your earliest convenience.

Best regards,
$schoolName
_Powered by EduTrack_''';
  }

  /// ✅ NEW: Format none payee notification message
  static String _formatNonePayeeNotification({
    required String studentName,
    required String parentName,
    required String period,
    required List<String> subjects,
    required String schoolName,
  }) {
    return '''💝 *Free Education Confirmation*

Dear $parentName,

This is to confirm that *$studentName* marked as paid for class today.

*Type:* FREE STUDENT 🆓
*Period:* $period
*Subjects:* ${subjects.join(', ')}
*Status:* PAID ✅

🎓 _We're proud to support your child's education!_

Best regards,
*$schoolName*
_Powered by EduTrack_''';
  }

  /// Format phone number to international format
  static String formatPhoneNumber(String phoneNumber) {
    // Remove all non-digit characters
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    // Handle different Sri Lankan number formats
    if (cleaned.startsWith('0')) {
      return '+94${cleaned.substring(1)}';
    } else if (cleaned.startsWith('94') && !cleaned.startsWith('+94')) {
      return '+$cleaned';
    } else if (!cleaned.startsWith('+')) {
      return '+94$cleaned';
    }

    return cleaned;
  }
}
