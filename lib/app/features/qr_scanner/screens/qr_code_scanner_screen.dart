import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edu_track/app/features/authentication/controllers/auth_controller.dart';
import 'package:edu_track/app/features/qr_scanner/controllers/qr_scanner_controller.dart';
import 'package:edu_track/app/models/payment_model.dart';
import 'package:edu_track/app/models/student_model.dart';
import 'package:edu_track/app/utils/constants.dart';
import 'package:edu_track/main.dart'; // For AppRoutes
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRCodeScannerScreen extends StatelessWidget {
  const QRCodeScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Put controller
    final controller = Get.put(QrScannerController());
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: kLightTextColor),
          tooltip: 'Back',
          onPressed: () => _handleBackPress(controller),
        ),
        title: Text('QR Code Scanner', style: textTheme.titleLarge),
        centerTitle: true,
        actions: [
          _buildProfileAvatar(),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: Obx(() => _buildBody(context, controller))),
          Obx(() => _buildStatusMessageWidget(context, controller)),
        ],
      ),
    );
  }

  void _handleBackPress(QrScannerController controller) {
    final state = controller.currentScreenState.value;
    if (state == ScreenState.scanning || state == ScreenState.showIndexInput) {
      controller.currentScreenState.value = ScreenState.initial;
    } else if (state == ScreenState.showStudentDetails) {
      controller.currentScreenState.value = ScreenState.initial;
    } else if (state == ScreenState.showStudentDetailsWithPendingPayments) {
      if (controller.attendanceMarked.value) {
         // Maybe ask confirmation? or just go back
      }
      // Reset logic is in controller reset actions, but basic back:
      controller.currentScreenState.value = ScreenState.initial;
      controller.resetPaymentState();
      controller.foundStudent.value = null; // Clear student
    } else if (state == ScreenState.showPaymentTypeSelection) {
      controller.currentScreenState.value = ScreenState.showStudentDetails;
    } else if (state == ScreenState.showMonthlyPaymentInput ||
        state == ScreenState.showDailyPaymentInput) {
      controller.currentScreenState.value = ScreenState.showPaymentTypeSelection;
    } else {
      Get.back();
    }
  }

  Widget _buildBody(BuildContext context, QrScannerController controller) {
    if (controller.isLoading.value) {
      // Overlay loading or check specific states
      // Actually isLoading is mostly for async ops, we might want to show Loading Indicator OVER current UI
      // But adhering to original design where it was mixed.
    }

    switch (controller.currentScreenState.value) {
      case ScreenState.initial:
        return _buildInitialUI(context, controller);
      case ScreenState.scanning:
        return _buildScannerUI(context, controller);
      case ScreenState.showIndexInput:
        return _buildIndexInputUI(context, controller);
      case ScreenState.showStudentDetails:
        return _buildStudentDetailsUI(context, controller);
      case ScreenState.showStudentDetailsWithPendingPayments:
        return _buildStudentDetailsWithPendingPaymentsUI(context, controller);
      case ScreenState.showPaymentTypeSelection:
        return _buildPaymentTypeSelectionUI(context, controller);
      case ScreenState.showMonthlyPaymentInput:
        return _buildMonthlyPaymentInputUI(context, controller);
      case ScreenState.showDailyPaymentInput:
        return _buildDailyPaymentInputUI(context, controller);
    }
  }

  // --- UI for Initial State ---
  Widget _buildInitialUI(BuildContext context, QrScannerController controller) {
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
              onPressed: () => controller.currentScreenState.value = ScreenState.scanning,
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      vertical: kDefaultPadding * 1.2)),
            ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),
            const SizedBox(height: kDefaultPadding * 1.5),
            ElevatedButton.icon(
              icon: const Icon(Icons.edit_note_rounded, size: 24),
              label: const Text('Mark By ID'),
              onPressed: () => controller.currentScreenState.value = ScreenState.showIndexInput,
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      vertical: kDefaultPadding * 1.2)),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
            const Spacer(),
            if (controller.isLoading.value) const Center(child: CircularProgressIndicator()),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  // --- UI for QR Scanner ---
  Widget _buildScannerUI(BuildContext context, QrScannerController controller) {
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
                controller: controller.scannerController,
                onDetect: (capture) {
                  final List<Barcode> barcodes = capture.barcodes;
                  if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                    controller.scannerController.stop();
                    controller.findStudentByQrCode(barcodes.first.rawValue!);
                  }
                },
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(kDefaultPadding),
          child: TextButton(
            onPressed: () => controller.currentScreenState.value = ScreenState.initial,
            child: const Text('Cancel Scan'),
          ),
        ),
      ],
    );
  }

  // --- UI for Index Input ---
  Widget _buildIndexInputUI(BuildContext context, QrScannerController controller) {
    return Padding(
      padding: const EdgeInsets.all(kDefaultPadding * 1.5),
      child: Center(
        child: Form(
          key: controller.formKeyIndex,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: controller.indexController,
                decoration: const InputDecoration(
                  labelText: 'Enter Index Number',
                  hintText: 'e.g., MEC1001',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter index number'
                    : null,
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ).animate().fadeIn(delay: 100.ms),
              const SizedBox(height: kDefaultPadding * 1.5),
              controller.isLoading.value
                  ? const Center(child: CircularProgressIndicator())
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.check_rounded, size: 20),
                            label: const Text('OK'),
                            onPressed: () {
                              if (controller.formKeyIndex.currentState!.validate()) {
                                controller.findStudentByIndex(controller.indexController.text);
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
                              controller.indexController.clear();
                              controller.currentScreenState.value = ScreenState.initial;
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

  // ─────────────────────────────────────────────────────────────────────────────
  // Placeholder methods to be filled by separate replace_file_content calls
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildStudentDetailsUI(BuildContext context, QrScannerController controller) {
    final student = controller.foundStudent.value;
    if (student == null) {
      return const Center(child: Text('Error: Student data not found.'));
    }
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(kDefaultPadding),
      child: Column(
        children: [
          // Student Info Card
          Card(
            elevation: 3,
            margin: EdgeInsets.zero,
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
                        _buildDetailRow('Grade:', student.className),
                        _buildDetailRow('Average Score:', student.averageScore),
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
                              height: 150,
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

          // Pending Payments Card
          Card(
            elevation: 3,
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(kDefaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
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
                              'Pending Payments (${controller.filteredPendingPayments.length})',
                              style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange)),
                        ],
                      ),
                      // Filters
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
                                value: controller.pendingPaymentsFilter.value,
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
                                  controller.pendingPaymentsFilter.value = value ?? 'all';
                                },
                              ),
                            ),
                            SizedBox(
                              height: 35,
                              child: DropdownButton<String>(
                                value: controller.pendingSubjectFilter.value,
                                isDense: true,
                                underline: Container(),
                                items: _buildPendingSubjectDropdownItems(controller),
                                onChanged: (value) {
                                  controller.pendingSubjectFilter.value = value ?? 'All';
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: kDefaultPadding / 2),

                  // Total pending amount
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
                          'Rs.${controller.totalPendingAmount.toStringAsFixed(2)}',
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

                  // Payments table
                  controller.filteredPendingPayments.isNotEmpty
                      ? ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: SingleChildScrollView(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                  // Mobile view
                                  return SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: DataTable(
                                      columnSpacing: 16,
                                      dataRowMinHeight: 35,
                                      dataRowMaxHeight: 35,
                                      headingRowHeight: 35,
                                      columns: const [
                                        DataColumn(label: Text('Type', style: TextStyle(fontSize: 12))),
                                        DataColumn(label: Text('Period', style: TextStyle(fontSize: 12))),
                                        DataColumn(label: Text('Subjects', style: TextStyle(fontSize: 12))),
                                        DataColumn(label: Text('Amount', style: TextStyle(fontSize: 12))),
                                        DataColumn(label: Text('Due Date', style: TextStyle(fontSize: 12))),
                                      ],
                                      rows: controller.filteredPendingPayments
                                          .map((payment) => DataRow(
                                                cells: [
                                                  DataCell(Text(
                                                      payment.paymentType.isNotEmpty
                                                          ? '${payment.paymentType[0].toUpperCase()}${payment.paymentType.substring(1)}'
                                                          : payment.paymentType,
                                                      style: const TextStyle(fontSize: 11))),
                                                  DataCell(Text(payment.getMonthYearDisplay(), style: const TextStyle(fontSize: 11))),
                                                  DataCell(SizedBox(
                                                    width: 150,
                                                    child: Text(
                                                      payment.subjects.isNotEmpty ? payment.subjects.join(', ') : '-',
                                                      style: const TextStyle(fontSize: 11),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  )),
                                                  DataCell(Text('Rs.${payment.amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                                                  DataCell(Text(payment.getDueDateDisplay(), style: const TextStyle(fontSize: 11))),
                                                ],
                                              ))
                                          .toList(),
                                    ),
                                  );
                              },
                            ),
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.all(20),
                          child: Center(
                              child: Text('No pending payments found',
                                  style: TextStyle(
                                      color: Colors.grey.shade600, fontSize: 13))),
                        ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1),

          const SizedBox(height: kDefaultPadding * 1.5),

          // Action Buttons
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
                   Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _showSubjectSelectionDialog(context, controller),
                                child: const Text('Mark Attendance'),
                              ),
                            ),
                            const SizedBox(width: kDefaultPadding),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _showMarkPaymentDialog(context, controller),
                                child: const Text('Mark Payment'),
                              ),
                            ),
                          ],
                        ),
                  const SizedBox(height: kDefaultPadding),
                  ElevatedButton(
                    onPressed: () {
                      controller.currentScreenState.value = ScreenState.initial;
                      controller.foundStudent.value = null;
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor.withOpacity(0.8),
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

  List<DropdownMenuItem<String>> _buildPendingSubjectDropdownItems(QrScannerController controller) {
    final student = controller.foundStudent.value;
    final Set<String> subjectSet = {
      if (student != null) ...student.subjects,
      ...controller.existingPendingPayments.expand((e) => e.subjects)
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

  Widget _buildStudentDetailsWithPendingPaymentsUI(BuildContext context, QrScannerController controller) {
     // Reuse the main details UI which now includes pending payments
     return _buildStudentDetailsUI(context, controller);
  }

  Widget _buildPaymentTypeSelectionUI(BuildContext context, QrScannerController controller) {
    return Padding(
      padding: const EdgeInsets.all(kDefaultPadding * 1.5),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Select Payment Type',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center),
            const SizedBox(height: kDefaultPadding * 2),
            ElevatedButton.icon(
              icon: const Icon(Icons.calendar_month_rounded),
              label: const Text('Monthly Payment'),
              onPressed: () => controller.currentScreenState.value = ScreenState.showMonthlyPaymentInput,
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(kDefaultPadding)),
            ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
            const SizedBox(height: kDefaultPadding),
            ElevatedButton.icon(
              icon: const Icon(Icons.today_rounded),
              label: const Text('Daily Payment'),
              onPressed: () => controller.currentScreenState.value = ScreenState.showDailyPaymentInput,
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(kDefaultPadding)),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
            const SizedBox(height: kDefaultPadding * 2),
            TextButton(
              onPressed: () => controller.currentScreenState.value = ScreenState.showStudentDetails,
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyPaymentInputUI(BuildContext context, QrScannerController controller) {
    // We used to manage form state in View, here we use Controller's ephemeral state OR local Form
    // Using Controller's paymentFormKey
    return SingleChildScrollView(
      padding: const EdgeInsets.all(kDefaultPadding),
      child: Form(
        key: controller.formKeyPayment,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Monthly Payment',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: kDefaultPadding),
            DropdownButtonFormField<String>(
              value: controller.selectedMonth.value,
              decoration: const InputDecoration(
                labelText: 'Select Month',
                border: OutlineInputBorder(),
              ),
              items: controller.months
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: (val) => controller.selectedMonth.value = val,
              validator: (val) => val == null ? 'Please select a month' : null,
            ),
            const SizedBox(height: kDefaultPadding),
            _buildSubjectSelectionWidget(context, controller),
            const SizedBox(height: kDefaultPadding),
            TextFormField(
              controller: controller.amountController,
              decoration: const InputDecoration(
                labelText: 'Amount (Rs.)',
                border: OutlineInputBorder(),
                prefixText: 'Rs. ',
              ),
              keyboardType: TextInputType.number,
              validator: (val) =>
                  val == null || val.isEmpty ? 'Enter amount' : null,
            ),
            const SizedBox(height: kDefaultPadding * 2),
            ElevatedButton(
              onPressed: () => controller.markMonthlyPayment(),
              child: const Text('Mark Payment'),
            ),
            TextButton(
              onPressed: () => controller.currentScreenState.value = ScreenState.showPaymentTypeSelection,
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyPaymentInputUI(BuildContext context, QrScannerController controller) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(kDefaultPadding),
      child: Form(
        key: controller.formKeyPayment,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Daily Payment',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: kDefaultPadding),
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (date != null) {
                  controller.selectedDate.value = date;
                }
              },
              child: Obx(() => InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Select Date',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  controller.selectedDate.value != null
                      ? DateFormat('dd/MM/yyyy').format(controller.selectedDate.value!)
                      : 'Choose Date',
                ),
              )),
            ),
            const SizedBox(height: kDefaultPadding),
            _buildSubjectSelectionWidget(context, controller),
            const SizedBox(height: kDefaultPadding),
            TextFormField(
              controller: controller.amountController,
              decoration: const InputDecoration(
                labelText: 'Amount (Rs.)',
                border: OutlineInputBorder(),
                prefixText: 'Rs. ',
              ),
              keyboardType: TextInputType.number,
              validator: (val) =>
                  val == null || val.isEmpty ? 'Enter amount' : null,
            ),
            const SizedBox(height: kDefaultPadding * 2),
            ElevatedButton(
              onPressed: () => controller.markDailyPayment(),
              child: const Text('Mark Payment'),
            ),
            TextButton(
              onPressed: () => controller.currentScreenState.value = ScreenState.showPaymentTypeSelection,
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectSelectionWidget(BuildContext context, QrScannerController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select Subjects:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Obx(() {
          final student = controller.foundStudent.value;
          if (student == null) return const SizedBox.shrink();
          
          return Wrap(
            spacing: 8,
            children: student.subjects.map((subject) {
              final isSelected = controller.selectedSubjects.contains(subject);
              return FilterChip(
                label: Text(subject),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    controller.selectedSubjects.add(subject);
                  } else {
                    controller.selectedSubjects.remove(subject);
                  }
                },
              );
            }).toList(),
          );
        }),
        Obx(() { 
             return controller.selectedSubjects.isEmpty 
              ? const Padding(
                padding: EdgeInsets.only(top: 4.0),
                child: Text('Select at least one subject', style: TextStyle(color: Colors.red, fontSize: 12)),
              ) 
              : const SizedBox.shrink();
        })
      ],
    );
  }
  
  // --- Reusable AppBar Profile Avatar Logic ---
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
             onBackgroundImageError: (exception, stackTrace) {
              // Handle error
            },
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

  // --- Status Message Widget ---
  Widget _buildStatusMessageWidget(BuildContext context, QrScannerController controller) {
     final msg = controller.statusMessage.value;
     if (msg == null) return const SizedBox.shrink();
     
     final isError = controller.isError.value;
     final textTheme = Theme.of(context).textTheme;
     
     return Padding(
        padding: const EdgeInsets.only(
            bottom: kDefaultPadding,
            left: kDefaultPadding,
            right: kDefaultPadding),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: kDefaultPadding, vertical: kDefaultPadding * 0.7),
            decoration: BoxDecoration(
              color: isError
                  ? kErrorColor.withOpacity(0.15)
                  : kSuccessColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(kDefaultRadius),
              border: Border.all(
                  color: isError ? kErrorColor : kSuccessColor, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isError
                      ? Icons.error_outline_rounded
                      : Icons.check_circle_outline_rounded,
                  color: isError ? kErrorColor : kSuccessColor,
                  size: 20,
                ),
                const SizedBox(width: kDefaultPadding / 2),
                Flexible(
                  child: Text(
                    msg,
                    style: textTheme.bodyMedium?.copyWith(
                      color: isError ? kErrorColor : kSuccessColor,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ).animate().fadeIn(duration: 300.ms);
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // DIALOGS
  // ─────────────────────────────────────────────────────────────────────────────
  
  void _showSubjectSelectionDialog(BuildContext context, QrScannerController controller) {
    controller.resetPaymentState();
    // Default subject to student's subjects if available
    final student = controller.foundStudent.value;
    // We don't auto-select all because "Attendance" usually means "Present for X class".
    // We let user select.

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark Attendance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select Subject(s):'),
            const SizedBox(height: 10),
            _buildSubjectSelectionWidget(context, controller),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
               if (controller.selectedSubjects.isEmpty) {
                 Get.snackbar('Error', 'Please select at least one subject', 
                   backgroundColor: Colors.red.withOpacity(0.2), colorText: Colors.red);
                 return;
               }
               // Mark attendance for each selected subject
               for (final subject in controller.selectedSubjects) {
                 controller.markAttendanceWithSubject(subject);
               }
               Get.back();
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showMarkPaymentDialog(BuildContext context, QrScannerController controller) {
    controller.resetPaymentState();
    
    // Local state for 'isPending' checkbox to avoid adding it to controller if not needed globally?
    // Actually, markGenericPayment takes 'isPending'.
    // I'll use a local ValueNotifier or RxBool for the dialog's pending state.
    final RxBool isPending = false.obs;
    final Rx<TextEditingController> pendingReasonCtrl = TextEditingController().obs;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Mark Payment'),
          content: SingleChildScrollView(
            child: Form(
              key: controller.dialogPaymentFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Payment Type Toggle
                  Obx(() => Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Monthly'),
                          selected: controller.selectedPaymentTypeForDialog.value == 'monthly',
                          onSelected: (selected) {
                            if (selected) controller.selectedPaymentTypeForDialog.value = 'monthly';
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Daily'),
                          selected: controller.selectedPaymentTypeForDialog.value == 'daily',
                          onSelected: (selected) {
                            if (selected) controller.selectedPaymentTypeForDialog.value = 'daily';
                          },
                        ),
                      ),
                    ],
                  )),
                  const SizedBox(height: 16),
                  
                  // Date/Month Picker
                  Obx(() {
                    if (controller.selectedPaymentTypeForDialog.value == 'monthly') {
                      return DropdownButtonFormField<String>(
                        value: controller.selectedMonth.value,
                        decoration: const InputDecoration(
                          labelText: 'Select Month',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: controller.months
                            .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                            .toList(),
                        onChanged: (val) => controller.selectedMonth.value = val,
                        validator: (val) => val == null ? 'Required' : null,
                      );
                    } else {
                      return InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (date != null) controller.selectedDate.value = date;
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Date',
                            border: OutlineInputBorder(),
                            isDense: true,
                            suffixIcon: Icon(Icons.calendar_today, size: 20),
                          ),
                          child: Text(
                            controller.selectedDate.value != null
                                ? DateFormat('dd/MM/yyyy').format(controller.selectedDate.value!)
                                : 'Select Date',
                          ),
                        ),
                      );
                    }
                  }),
                  
                  const SizedBox(height: 16),
                  _buildSubjectSelectionWidget(context, controller),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: controller.amountController,
                    decoration: const InputDecoration(
                      labelText: 'Amount (Rs.)',
                      border: OutlineInputBorder(),
                      prefixText: 'Rs. ',
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                  ),
                  
                  const SizedBox(height: 16),
                  // Is Pending Checkbox
                  Obx(() => CheckboxListTile(
                    title: const Text('Mark as Pending?'),
                    value: isPending.value,
                    onChanged: (val) => isPending.value = val ?? false,
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  )),

                  Obx(() => isPending.value 
                    ? Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: TextFormField(
                          controller: pendingReasonCtrl.value,
                          decoration: const InputDecoration(
                            labelText: 'Pending Reason (Optional)',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ) 
                    : const SizedBox.shrink()),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.dialogPaymentFormKey.currentState!.validate()) {
                   // Validate subjects
                   if (controller.selectedSubjects.isEmpty) {
                      Get.snackbar('Error', 'Select subjects', 
                        snackPosition: SnackPosition.BOTTOM);
                      return;
                   }
                   if (controller.selectedPaymentTypeForDialog.value == 'daily' && controller.selectedDate.value == null) {
                      Get.snackbar('Error', 'Select date', 
                        snackPosition: SnackPosition.BOTTOM);
                      return;
                   }
                   
                   controller.markGenericPayment(
                     paymentType: controller.selectedPaymentTypeForDialog.value ?? 'monthly',
                     month: controller.selectedMonth.value,
                     date: controller.selectedDate.value,
                     subjects: controller.selectedSubjects.toList(),
                     amount: double.tryParse(controller.amountController.text) ?? 0.0,
                     isPending: isPending.value,
                     pendingReason: pendingReasonCtrl.value.text,
                   );
                   Get.back();
                }
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      }
    );
  }
} // End Class
