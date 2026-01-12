import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

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
