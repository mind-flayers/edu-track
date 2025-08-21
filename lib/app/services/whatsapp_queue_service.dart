import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../features/authentication/controllers/auth_controller.dart';
import 'dart:developer' as developer;

class WhatsAppQueueService extends GetxService {
  static WhatsAppQueueService get instance => Get.find();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Queue a WhatsApp message to be processed
  Future<void> queueMessage({
    required String recipientNumber,
    required String message,
    String messageType = 'attendance',
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final AuthController authController = Get.find();
      final String adminUid = authController.user?.uid ?? '';

      if (adminUid.isEmpty) {
        throw Exception('Admin not authenticated');
      }

      // Add message to Firestore queue
      await _firestore
          .collection('admins')
          .doc(adminUid)
          .collection('whatsappQueue')
          .add({
        'recipientNumber': recipientNumber,
        'message': message,
        'messageType': messageType,
        'metadata': metadata ?? {},
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'attempts': 0,
        'maxAttempts': 3,
        'adminUid': adminUid,
      });

      developer.log('WhatsApp message queued successfully');
    } catch (e) {
      developer.log('Error queuing WhatsApp message: $e');
      rethrow;
    }
  }

  /// Get message status stream for monitoring
  Stream<QuerySnapshot> getMessageStatusStream() {
    try {
      final AuthController authController = Get.find();
      final String adminUid = authController.user?.uid ?? '';

      if (adminUid.isEmpty) {
        throw Exception('Admin not authenticated');
      }

      return _firestore
          .collection('admins')
          .doc(adminUid)
          .collection('whatsappQueue')
          .where('createdAt',
              isGreaterThan: Timestamp.fromDate(
                  DateTime.now().subtract(const Duration(hours: 24))))
          .orderBy('createdAt', descending: true)
          .snapshots();
    } catch (e) {
      developer.log('Error getting message status stream: $e');
      rethrow;
    }
  }

  /// Retry failed messages
  Future<void> retryFailedMessages() async {
    try {
      final AuthController authController = Get.find();
      final String adminUid = authController.user?.uid ?? '';

      if (adminUid.isEmpty) {
        throw Exception('Admin not authenticated');
      }

      final failedMessages = await _firestore
          .collection('admins')
          .doc(adminUid)
          .collection('whatsappQueue')
          .where('status', isEqualTo: 'failed')
          .where('attempts', isLessThan: 3)
          .get();

      for (final doc in failedMessages.docs) {
        await doc.reference.update({
          'status': 'pending',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      developer.log('Retried ${failedMessages.docs.length} failed messages');
    } catch (e) {
      developer.log('Error retrying failed messages: $e');
      rethrow;
    }
  }

  /// Clear old completed/failed messages
  Future<void> cleanupOldMessages({int daysOld = 7}) async {
    try {
      final AuthController authController = Get.find();
      final String adminUid = authController.user?.uid ?? '';

      if (adminUid.isEmpty) {
        throw Exception('Admin not authenticated');
      }

      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));

      final oldMessages = await _firestore
          .collection('admins')
          .doc(adminUid)
          .collection('whatsappQueue')
          .where('createdAt', isLessThan: Timestamp.fromDate(cutoffDate))
          .where('status', whereIn: ['completed', 'failed']).get();

      for (final doc in oldMessages.docs) {
        await doc.reference.delete();
      }

      developer.log('Cleaned up ${oldMessages.docs.length} old messages');
    } catch (e) {
      developer.log('Error cleaning up old messages: $e');
      rethrow;
    }
  }
}
