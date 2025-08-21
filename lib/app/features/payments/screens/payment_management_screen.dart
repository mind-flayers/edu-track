import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:edu_track/app/features/authentication/controllers/auth_controller.dart';
import 'package:edu_track/app/utils/constants.dart';
import 'package:edu_track/main.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart' as ex;
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

// Data model for payment records
class _PaymentData {
  final String studentId;
  final String studentName;
  final String className;
  final String? photoUrl;
  final String paymentType; // 'monthly' or 'daily'
  final double amount;
  final DateTime paidAt;
  final String? selectedMonth; // For monthly payments
  final String? selectedDate; // For daily payments (YYYY-MM-DD)
  final List<String> subjects;
  final String paymentMethod;
  final String description;
  final bool isPaid;

  _PaymentData({
    required this.studentId,
    required this.studentName,
    required this.className,
    this.photoUrl,
    required this.paymentType,
    required this.amount,
    required this.paidAt,
    this.selectedMonth,
    this.selectedDate,
    required this.subjects,
    required this.paymentMethod,
    required this.description,
    required this.isPaid,
  });

  // Helper method to get display date
  String get displayDate {
    if (paymentType == 'daily' && selectedDate != null) {
      final date = DateTime.parse(selectedDate!);
      return DateFormat('dd/MM/yyyy').format(date);
    } else if (paymentType == 'monthly' && selectedMonth != null) {
      return '$selectedMonth ${paidAt.year}';
    }
    return DateFormat('dd/MM/yyyy').format(paidAt);
  }

  // Helper method to get subject display
  String get subjectDisplay => subjects.join(', ');
}

class PaymentManagementScreen extends StatefulWidget {
  const PaymentManagementScreen({super.key});

  @override
  State<PaymentManagementScreen> createState() =>
      _PaymentManagementScreenState();
}

class _PaymentManagementScreenState extends State<PaymentManagementScreen> {
  String? _selectedClassSection;
  DateTime? _selectedFromDate;
  DateTime? _selectedToDate;
  String? _selectedPaymentType; // 'all', 'monthly', 'daily'

  List<String> _availableClassSections = [];
  bool _isLoadingClasses = true;
  bool _isLoadingPayments = false;
  String? _errorMessage;

  List<_PaymentData> _paymentsList = [];
  List<_PaymentData> _filteredPaymentsList = [];

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
    _fetchClassSections();
    _selectedPaymentType = 'all';
    // Set default date range to current month
    final now = DateTime.now();
    _selectedFromDate = DateTime(now.year, now.month, 1);
    _selectedToDate = DateTime(now.year, now.month + 1, 0);
  }

  // Fetch available class sections
  Future<void> _fetchClassSections() async {
    setState(() {
      _isLoadingClasses = true;
      _errorMessage = null;
      _availableClassSections = [];
      _selectedClassSection = null;
    });

    final String? adminUid = AuthController.instance.user?.uid;
    if (adminUid == null) {
      setState(() {
        _errorMessage = "Admin not logged in.";
        _isLoadingClasses = false;
      });
      return;
    }

    try {
      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('admins')
          .doc(adminUid)
          .collection('students')
          .get();

      final classSet = <String>{};
      for (var doc in studentsSnapshot.docs) {
        final data = doc.data();
        final className = data['class']?.toString();
        final section = data['section']?.toString() ?? 'A';
        if (className != null && className.isNotEmpty) {
          classSet.add('$className-$section');
        }
      }

      setState(() {
        _availableClassSections = classSet.toList()..sort();
        _isLoadingClasses = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Error fetching classes: $e";
        _isLoadingClasses = false;
      });
    }
  }

  // Fetch payments based on filters
  Future<void> _fetchPayments() async {
    if (_selectedFromDate == null || _selectedToDate == null) {
      _showSnackBar('Please select date range', isError: true);
      return;
    }

    setState(() {
      _isLoadingPayments = true;
      _errorMessage = null;
      _paymentsList = [];
      _filteredPaymentsList = [];
    });

    final String? adminUid = AuthController.instance.user?.uid;
    if (adminUid == null) {
      setState(() {
        _errorMessage = "Admin not logged in.";
        _isLoadingPayments = false;
      });
      return;
    }

    try {
      // Get all students first
      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('admins')
          .doc(adminUid)
          .collection('students')
          .get();

      final List<_PaymentData> payments = [];

      for (var studentDoc in studentsSnapshot.docs) {
        final studentData = studentDoc.data();
        final studentId = studentDoc.id;
        final studentName = studentData['name']?.toString() ?? 'N/A';
        final className = studentData['class']?.toString() ?? 'N/A';
        final section = studentData['section']?.toString() ?? 'A';
        final photoUrl = studentData['photoUrl']?.toString();
        final classSection = '$className-$section';

        // Skip if class filter is applied and doesn't match
        if (_selectedClassSection != null &&
            classSection != _selectedClassSection) {
          continue;
        }

        // Get payments for this student within date range
        final feesSnapshot = await FirebaseFirestore.instance
            .collection('admins')
            .doc(adminUid)
            .collection('students')
            .doc(studentId)
            .collection('fees')
            .where('paid', isEqualTo: true)
            .get();

        for (var feeDoc in feesSnapshot.docs) {
          final feeData = feeDoc.data();
          final paidAt = (feeData['paidAt'] as Timestamp?)?.toDate();

          if (paidAt == null) continue;

          // Check date range
          if (paidAt.isBefore(_selectedFromDate!) ||
              paidAt.isAfter(_selectedToDate!)) {
            continue;
          }

          final paymentType = feeData['paymentType']?.toString() ?? 'monthly';

          // Check payment type filter
          if (_selectedPaymentType != 'all' &&
              paymentType != _selectedPaymentType) {
            continue;
          }

          final amount = (feeData['amount'] as num?)?.toDouble() ?? 0.0;
          final subjects = List<String>.from(feeData['subjects'] ?? []);
          final paymentMethod = feeData['paymentMethod']?.toString() ?? 'N/A';
          final description = feeData['description']?.toString() ?? '';

          String? selectedMonth;
          String? selectedDate;

          if (paymentType == 'monthly') {
            final monthIndex = feeData['month'] as int?;
            if (monthIndex != null && monthIndex >= 1 && monthIndex <= 12) {
              selectedMonth = _months[monthIndex - 1];
            }
          } else if (paymentType == 'daily') {
            selectedDate = feeData['date']?.toString();
          }

          payments.add(_PaymentData(
            studentId: studentId,
            studentName: studentName,
            className: classSection,
            photoUrl: photoUrl,
            paymentType: paymentType,
            amount: amount,
            paidAt: paidAt,
            selectedMonth: selectedMonth,
            selectedDate: selectedDate,
            subjects: subjects,
            paymentMethod: paymentMethod,
            description: description,
            isPaid: true,
          ));
        }
      }

      // Sort by payment date (most recent first)
      payments.sort((a, b) => b.paidAt.compareTo(a.paidAt));

      setState(() {
        _paymentsList = payments;
        _filteredPaymentsList = payments;
        _isLoadingPayments = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Error fetching payments: $e";
        _isLoadingPayments = false;
      });
    }
  }

  // Show snack bar
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? kErrorColor : kSuccessColor,
      ),
    );
  }

  // Profile avatar builder
  Widget _buildProfileAvatar() {
    final String? userId = AuthController.instance.user?.uid;
    if (userId == null) {
      return IconButton(
        icon: Icon(Icons.account_circle_rounded,
            size: 30, color: kLightTextColor),
        tooltip: 'Profile Settings',
        onPressed: () => Get.toNamed(AppRoutes.profileSettings),
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
            size: 30, color: kLightTextColor);

        if (snapshot.connectionState == ConnectionState.active &&
            snapshot.hasData &&
            snapshot.data!.exists) {
          var data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data != null && data.containsKey('profilePhotoUrl')) {
            photoUrl = data['profilePhotoUrl'] as String?;
          }
        }

        if (photoUrl != null && photoUrl.isNotEmpty) {
          profileWidget = CircleAvatar(
            radius: 18,
            backgroundColor: kLightTextColor.withOpacity(0.5),
            backgroundImage: CachedNetworkImageProvider(photoUrl),
          );
        }

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(kDefaultRadius * 2),
            onTap: () => Get.toNamed(AppRoutes.profileSettings),
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

  // Export to Excel
  Future<void> _exportToExcel() async {
    if (_filteredPaymentsList.isEmpty) {
      _showSnackBar('No data to export', isError: true);
      return;
    }

    try {
      final excel = ex.Excel.createExcel();
      final sheet = excel['Payment Records'];

      // Headers
      final headers = [
        'Student Name',
        'Class',
        'Payment Type',
        'Amount',
        'Date Paid',
        'Month/Date',
        'Subjects',
        'Payment Method',
        'Description'
      ];

      for (int i = 0; i < headers.length; i++) {
        sheet
            .cell(ex.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
            .value = ex.TextCellValue(headers[i]);
      }

      // Data rows
      for (int i = 0; i < _filteredPaymentsList.length; i++) {
        final payment = _filteredPaymentsList[i];
        final row = i + 1;

        sheet
            .cell(ex.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
            .value = ex.TextCellValue(payment.studentName);
        sheet
            .cell(ex.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
            .value = ex.TextCellValue(payment.className);
        sheet
            .cell(ex.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
            .value = ex.TextCellValue(payment.paymentType);
        sheet
            .cell(ex.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row))
            .value = ex.DoubleCellValue(payment.amount);
        sheet
            .cell(ex.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
            .value = ex.TextCellValue(DateFormat(
                'dd/MM/yyyy')
            .format(payment.paidAt));
        sheet
            .cell(ex.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row))
            .value = ex.TextCellValue(payment.displayDate);
        sheet
            .cell(ex.CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row))
            .value = ex.TextCellValue(payment.subjectDisplay);
        sheet
            .cell(ex.CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row))
            .value = ex.TextCellValue(payment.paymentMethod);
        sheet
            .cell(ex.CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: row))
            .value = ex.TextCellValue(payment.description);
      }

      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'payment_records_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
      final filePath = '${directory.path}/$fileName';

      final excelFile = File(filePath);
      await excelFile.writeAsBytes(excel.encode()!);

      await Share.shareXFiles([XFile(filePath)],
          text: 'Payment Records Export');
      _showSnackBar('Excel file exported successfully');
    } catch (e) {
      _showSnackBar('Error exporting to Excel: $e', isError: true);
    }
  }

  // Export to PDF
  Future<void> _exportToPDF() async {
    if (_filteredPaymentsList.isEmpty) {
      _showSnackBar('No data to export', isError: true);
      return;
    }

    try {
      final pdf = pw.Document();

      // Load font for better PDF appearance
      final fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
      final ttf = pw.Font.ttf(fontData);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return [
              pw.Text('Payment Records',
                  style: pw.TextStyle(font: ttf, fontSize: 20)),
              pw.SizedBox(height: 20),
              pw.Text(
                  'Date Range: ${DateFormat('dd/MM/yyyy').format(_selectedFromDate!)} - ${DateFormat('dd/MM/yyyy').format(_selectedToDate!)}',
                  style: pw.TextStyle(font: ttf, fontSize: 12)),
              if (_selectedClassSection != null)
                pw.Text('Class: $_selectedClassSection',
                    style: pw.TextStyle(font: ttf, fontSize: 12)),
              if (_selectedPaymentType != 'all')
                pw.Text('Payment Type: ${_selectedPaymentType!.toUpperCase()}',
                    style: pw.TextStyle(font: ttf, fontSize: 12)),
              pw.SizedBox(height: 20),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  // Header row
                  pw.TableRow(
                    children: [
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text('Student',
                              style: pw.TextStyle(
                                  font: ttf, fontWeight: pw.FontWeight.bold))),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text('Class',
                              style: pw.TextStyle(
                                  font: ttf, fontWeight: pw.FontWeight.bold))),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text('Type',
                              style: pw.TextStyle(
                                  font: ttf, fontWeight: pw.FontWeight.bold))),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text('Amount',
                              style: pw.TextStyle(
                                  font: ttf, fontWeight: pw.FontWeight.bold))),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text('Date',
                              style: pw.TextStyle(
                                  font: ttf, fontWeight: pw.FontWeight.bold))),
                    ],
                  ),
                  // Data rows
                  ..._filteredPaymentsList
                      .map((payment) => pw.TableRow(
                            children: [
                              pw.Padding(
                                  padding: const pw.EdgeInsets.all(5),
                                  child: pw.Text(payment.studentName,
                                      style: pw.TextStyle(
                                          font: ttf, fontSize: 10))),
                              pw.Padding(
                                  padding: const pw.EdgeInsets.all(5),
                                  child: pw.Text(payment.className,
                                      style: pw.TextStyle(
                                          font: ttf, fontSize: 10))),
                              pw.Padding(
                                  padding: const pw.EdgeInsets.all(5),
                                  child: pw.Text(payment.paymentType,
                                      style: pw.TextStyle(
                                          font: ttf, fontSize: 10))),
                              pw.Padding(
                                  padding: const pw.EdgeInsets.all(5),
                                  child: pw.Text(
                                      'Rs. ${payment.amount.toStringAsFixed(2)}',
                                      style: pw.TextStyle(
                                          font: ttf, fontSize: 10))),
                              pw.Padding(
                                  padding: const pw.EdgeInsets.all(5),
                                  child: pw.Text(payment.displayDate,
                                      style: pw.TextStyle(
                                          font: ttf, fontSize: 10))),
                            ],
                          ))
                      .toList(),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Text('Total Records: ${_filteredPaymentsList.length}',
                  style: pw.TextStyle(font: ttf, fontSize: 12)),
              pw.Text(
                  'Total Amount: Rs. ${_filteredPaymentsList.fold(0.0, (sum, payment) => sum + payment.amount).toStringAsFixed(2)}',
                  style: pw.TextStyle(font: ttf, fontSize: 12)),
            ];
          },
        ),
      );

      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'payment_records_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      final filePath = '${directory.path}/$fileName';

      final pdfFile = File(filePath);
      await pdfFile.writeAsBytes(await pdf.save());

      await Share.shareXFiles([XFile(filePath)],
          text: 'Payment Records Export');
      _showSnackBar('PDF file exported successfully');
    } catch (e) {
      _showSnackBar('Error exporting to PDF: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: kLightTextColor),
          tooltip: 'Back',
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Payment Management', style: textTheme.titleLarge),
        centerTitle: true,
        actions: [
          _buildProfileAvatar(),
        ],
      ),
      body: Column(
        children: [
          // Filter Section
          Container(
            padding: const EdgeInsets.all(kDefaultPadding),
            color: Colors.grey.shade50,
            child: Column(
              children: [
                Row(
                  children: [
                    // Class Filter
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedClassSection,
                        hint: const Text('All Classes'),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('All Classes'),
                          ),
                          ..._availableClassSections.map((classSection) {
                            return DropdownMenuItem<String>(
                              value: classSection,
                              child: Text(classSection),
                            );
                          }).toList(),
                        ],
                        onChanged: (newValue) {
                          setState(() {
                            _selectedClassSection = newValue;
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: 'Class',
                          prefixIcon: Icon(Icons.class_outlined),
                          border: OutlineInputBorder(),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: kDefaultPadding),
                    // Payment Type Filter
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedPaymentType,
                        items: const [
                          DropdownMenuItem<String>(
                              value: 'all', child: Text('All Types')),
                          DropdownMenuItem<String>(
                              value: 'monthly', child: Text('Monthly')),
                          DropdownMenuItem<String>(
                              value: 'daily', child: Text('Daily')),
                        ],
                        onChanged: (newValue) {
                          setState(() {
                            _selectedPaymentType = newValue;
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: 'Payment Type',
                          prefixIcon: Icon(Icons.payment_outlined),
                          border: OutlineInputBorder(),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: kDefaultPadding),
                Row(
                  children: [
                    // From Date
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final selectedDate = await showDatePicker(
                            context: context,
                            initialDate: _selectedFromDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (selectedDate != null) {
                            setState(() {
                              _selectedFromDate = selectedDate;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'From Date',
                            prefixIcon: Icon(Icons.calendar_today_outlined),
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                          child: Text(
                            _selectedFromDate != null
                                ? DateFormat('dd/MM/yyyy')
                                    .format(_selectedFromDate!)
                                : 'Select date',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: kDefaultPadding),
                    // To Date
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final selectedDate = await showDatePicker(
                            context: context,
                            initialDate: _selectedToDate ?? DateTime.now(),
                            firstDate: _selectedFromDate ?? DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (selectedDate != null) {
                            setState(() {
                              _selectedToDate = selectedDate;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'To Date',
                            prefixIcon: Icon(Icons.calendar_today_outlined),
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                          child: Text(
                            _selectedToDate != null
                                ? DateFormat('dd/MM/yyyy')
                                    .format(_selectedToDate!)
                                : 'Select date',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: kDefaultPadding),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _fetchPayments,
                        icon: const Icon(Icons.search),
                        label: const Text('Search Payments'),
                      ),
                    ),
                    const SizedBox(width: kDefaultPadding),
                    IconButton(
                      onPressed: _exportToExcel,
                      icon: const Icon(Icons.file_download),
                      tooltip: 'Export to Excel',
                    ),
                    IconButton(
                      onPressed: _exportToPDF,
                      icon: const Icon(Icons.picture_as_pdf),
                      tooltip: 'Export to PDF',
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Results Section
          Expanded(
            child: _buildResultsSection(),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsSection() {
    if (_isLoadingClasses) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: kErrorColor),
            const SizedBox(height: kDefaultPadding),
            Text(_errorMessage!,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: kErrorColor),
                textAlign: TextAlign.center),
            const SizedBox(height: kDefaultPadding),
            ElevatedButton(
              onPressed: _fetchClassSections,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_isLoadingPayments) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_paymentsList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.payment_outlined, size: 64, color: kLightTextColor),
            const SizedBox(height: kDefaultPadding),
            Text('No payment records found',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: kLightTextColor)),
            const SizedBox(height: kDefaultPadding),
            Text('Apply filters and search to view payment records',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: kLightTextColor),
                textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(kDefaultPadding),
      itemCount: _filteredPaymentsList.length,
      itemBuilder: (context, index) {
        final payment = _filteredPaymentsList[index];
        return Card(
          margin: const EdgeInsets.only(bottom: kDefaultPadding),
          child: ListTile(
            leading: payment.photoUrl != null && payment.photoUrl!.isNotEmpty
                ? CircleAvatar(
                    backgroundImage:
                        CachedNetworkImageProvider(payment.photoUrl!),
                    onBackgroundImageError: (_, __) {},
                  )
                : CircleAvatar(
                    backgroundColor: kPrimaryColor.withOpacity(0.2),
                    child: Icon(Icons.person, color: kPrimaryColor),
                  ),
            title: Text(payment.studentName,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Class: ${payment.className}'),
                Text(
                    'Type: ${payment.paymentType.toUpperCase()} • ${payment.displayDate}'),
                Text('Subjects: ${payment.subjectDisplay}'),
                if (payment.description.isNotEmpty)
                  Text('Note: ${payment.description}',
                      style: TextStyle(color: kLightTextColor, fontSize: 12)),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Rs. ${payment.amount.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: kSuccessColor, fontWeight: FontWeight.bold)),
                Text(payment.paymentMethod,
                    style: TextStyle(color: kLightTextColor, fontSize: 12)),
              ],
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }
}
