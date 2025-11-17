import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edu_track/app/features/authentication/controllers/auth_controller.dart';
// import 'package:edu_track/app/features/profile/screens/profile_settings_screen.dart';
import 'package:edu_track/app/features/students/screens/student_list_screen.dart';
import 'package:edu_track/app/features/teachers/screens/teacher_list_screen.dart';
import 'package:edu_track/app/features/dashboard/screens/dashboard_screen.dart';
import 'package:edu_track/app/features/exam/screens/exam_results_screen.dart';
import 'package:edu_track/app/features/authentication/screens/signin_screen.dart';
import 'package:edu_track/app/utils/constants.dart';
import 'package:edu_track/main.dart'; // Import main for AppRoutes
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart'; // Import GetX
import 'package:intl/intl.dart'; // For date formatting
import 'package:path_provider/path_provider.dart'; // For excel export
import 'package:excel/excel.dart' as ex; // For excel export - Added prefix
import 'package:share_plus/share_plus.dart'; // For sharing file
import 'package:pdf/widgets.dart' as pw; // PDF generation
import 'package:pdf/pdf.dart' as pdf_core; // PDF page format
import 'package:printing/printing.dart'; // PDF sharing/printing
import 'package:flutter/services.dart' show rootBundle; // For font loading
import 'dart:io'; // For file operations

// Helper extension for capitalizing strings (e.g., 'present' -> 'Present')
// Correctly placed at top level
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) {
      return "";
    }
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}

// Simple data model to hold combined student and attendance info
class _AttendanceData {
  final String studentId;
  final String studentName;
  final String? photoUrl;
  String status; // 'present', 'absent', or '-' if no record
  final String? subject; // Subject for which attendance was marked
  final String? attendanceDocId; // ID of the attendance document if it exists
  bool isEditing = false;

  _AttendanceData({
    required this.studentId,
    required this.studentName,
    this.photoUrl,
    required this.status,
    this.subject,
    this.attendanceDocId,
  });
}

class AttendanceSummaryScreen extends StatefulWidget {
  const AttendanceSummaryScreen({super.key});

  @override
  State<AttendanceSummaryScreen> createState() =>
      _AttendanceSummaryScreenState();
}

class _AttendanceSummaryScreenState extends State<AttendanceSummaryScreen> {
  int _selectedIndex = 3; // Attendance tab is selected
  String? _selectedClass;
  String? _selectedSubject;
  DateTime _selectedDate = DateTime.now();
  List<String> _availableClasses = [];
  List<String> _availableSubjects = [];
  bool _isLoadingClasses = true;
  bool _isLoadingSubjects = false;
  bool _isLoadingData = false;
  String? _errorMessage;

  List<_AttendanceData> _attendanceList = [];
  Map<String, String> _originalStatusMap = {};
  bool _isEditMode = false; // Global edit mode state

  @override
  void initState() {
    super.initState();
    _fetchClasses();
  }

  Future<void> _fetchClasses() async {
    setState(() {
      _isLoadingClasses = true;
      _errorMessage = null;
    });
    final String? adminUid = AuthController.instance.user?.uid;
    if (adminUid == null) {
      print("Error: Admin UID is null. Cannot fetch classes.");
      setState(() {
        _errorMessage = "Error: Could not verify admin.";
        _isLoadingClasses = false;
        _availableClasses = [];
      });
      return;
    }

    try {
      // Fetch classes from the nested collection under the current admin
      final snapshot = await FirebaseFirestore.instance
          .collection('admins')
          .doc(adminUid)
          .collection('students')
          .get();
      final classes = snapshot.docs
          .map((doc) => doc.data()['class'] as String?)
          .where((className) =>
              className != null &&
              className.isNotEmpty) // Added isNotEmpty check
          .cast<String>()
          .toSet()
          .toList();
      classes.sort((a, b) {
        final aNum = int.tryParse(a.replaceAll('Grade ', '')) ?? 0;
        final bNum = int.tryParse(b.replaceAll('Grade ', '')) ?? 0;
        return aNum.compareTo(bNum);
      });
      setState(() {
        _availableClasses = classes;
        _isLoadingClasses = false;
      });
    } catch (e) {
      print("Error fetching classes: $e");
      setState(() {
        _errorMessage = "Error loading classes.";
        _isLoadingClasses = false;
      });
    }
  }

  Future<void> _fetchSubjects() async {
    if (_selectedClass == null) {
      setState(() => _availableSubjects = []);
      return;
    }

    setState(() {
      _isLoadingSubjects = true;
      _errorMessage = null;
    });

    final String? adminUid = AuthController.instance.user?.uid;
    if (adminUid == null) {
      setState(() {
        _errorMessage = "Error: Could not verify admin.";
        _isLoadingSubjects = false;
        _availableSubjects = [];
      });
      return;
    }

    try {
      // Fetch subjects from students in the selected class
      final snapshot = await FirebaseFirestore.instance
          .collection('admins')
          .doc(adminUid)
          .collection('students')
          .where('class', isEqualTo: _selectedClass)
          .get();

      Set<String> subjectsSet = {};
      for (var doc in snapshot.docs) {
        final subjects = doc.data()['Subjects'] as List<dynamic>?;
        if (subjects != null) {
          subjectsSet.addAll(subjects.cast<String>());
        }
      }

      final subjects = subjectsSet.toList()..sort();
      setState(() {
        _availableSubjects = subjects; // Remove 'All Subjects' option
        _isLoadingSubjects = false;
        // Reset subject selection when class changes
        if (_selectedSubject != null &&
            !_availableSubjects.contains(_selectedSubject)) {
          _selectedSubject = null;
        }
      });
    } catch (e) {
      print("Error fetching subjects: $e");
      setState(() {
        _errorMessage = "Error loading subjects.";
        _isLoadingSubjects = false;
        _availableSubjects = [];
      });
    }
  }

  Future<void> _fetchAttendanceData() async {
    if (_selectedClass == null || _selectedSubject == null) {
      setState(() => _attendanceList = []);
      return;
    }

    setState(() {
      _isLoadingData = true;
      _errorMessage = null;
      _attendanceList = [];
      _originalStatusMap = {};
    });

    final targetDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
    print(
        "Fetching attendance for Class: $_selectedClass, Subject: $_selectedSubject, Date: $targetDate");

    final String? adminUid = AuthController.instance.user?.uid;
    if (adminUid == null) {
      print("Error: Admin UID is null. Cannot fetch attendance data.");
      setState(() {
        _errorMessage = "Error: Could not verify admin.";
        _isLoadingData = false;
        _attendanceList = [];
      });
      return;
    }

    try {
      // Fetch students from the nested collection
      final studentSnapshot = await FirebaseFirestore.instance
          .collection('admins')
          .doc(adminUid)
          .collection('students')
          .where('class', isEqualTo: _selectedClass)
          .orderBy('name')
          .get();

      if (studentSnapshot.docs.isEmpty) {
        print("No students found for class: $_selectedClass");
        setState(() {
          _isLoadingData = false;
          _attendanceList = [];
        });
        return;
      }

      print("Found ${studentSnapshot.docs.length} students.");

      List<_AttendanceData> tempData = [];

      for (var studentDoc in studentSnapshot.docs) {
        final studentData = studentDoc.data();
        final studentId = studentDoc.id;
        final studentName = studentData['name'] as String? ?? 'Unknown Name';
        final photoUrl = studentData['photoUrl'] as String?;

        // Check if student has this subject in their subject list
        final studentSubjects = studentData['Subjects'] as List<dynamic>?;
        if (studentSubjects == null ||
            !studentSubjects.contains(_selectedSubject)) {
          // Skip students who don't have this subject
          continue;
        }

        // Fetch attendance for the specific subject and date
        final attendanceSnapshot = await FirebaseFirestore.instance
            .collection('admins')
            .doc(adminUid)
            .collection('students')
            .doc(studentId)
            .collection('attendance')
            .where('date', isEqualTo: targetDate)
            .where('subject', isEqualTo: _selectedSubject)
            .limit(1)
            .get();

        String status = 'absent'; // Default to absent (no record means absent)
        String? attendanceDocId;

        if (attendanceSnapshot.docs.isNotEmpty) {
          // Record exists = student was present
          status = 'present';
          attendanceDocId = attendanceSnapshot.docs.first.id;
          print(
              "  Student: $studentName, Status: $status, Subject: $_selectedSubject, DocId: $attendanceDocId");
        } else {
          print(
              "  Student: $studentName, Status: $status, Subject: $_selectedSubject (No record = absent)");
        }

        tempData.add(_AttendanceData(
          studentId: studentId,
          studentName: studentName,
          photoUrl: photoUrl,
          status: status,
          subject: _selectedSubject,
          attendanceDocId: attendanceDocId,
        ));
      }

      setState(() {
        _attendanceList = tempData;
        _isLoadingData = false;
      });
      print("Finished fetching attendance data for subject: $_selectedSubject");
    } catch (e) {
      print("Error fetching attendance data: $e");
      setState(() {
        _errorMessage = "Error loading attendance data.";
        _isLoadingData = false;
      });
    }
  }

  void _updateAttendanceStatus(int index, String newStatus) {
    setState(() {
      _attendanceList[index].status = newStatus;
    });
  }

  void _toggleEditMode() {
    setState(() {
      if (!_isEditMode) {
        // Entering edit mode - store original values
        _originalStatusMap.clear();
        for (int i = 0; i < _attendanceList.length; i++) {
          _originalStatusMap[_attendanceList[i].studentId] =
              _attendanceList[i].status;
        }
        _isEditMode = true;
      } else {
        // Exiting edit mode - restore original values
        for (int i = 0; i < _attendanceList.length; i++) {
          final originalStatus =
              _originalStatusMap[_attendanceList[i].studentId];
          if (originalStatus != null) {
            _attendanceList[i].status = originalStatus;
          }
        }
        _originalStatusMap.clear();
        _isEditMode = false;
      }
    });
  }

  Future<void> _saveAllChanges() async {
    if (!_isEditMode) return;

    setState(() => _isLoadingData = true);

    final String? adminUid = AuthController.instance.user?.uid;
    if (adminUid == null) {
      print("Error: Admin UID is null. Cannot save attendance.");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              const Text('Error: Could not verify admin to save attendance.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(kDefaultPadding),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(kDefaultRadius)),
        ),
      );
      setState(() => _isLoadingData = false);
      return;
    }

    try {
      // Count changes and apply them
      int changesCount = 0;
      for (final record in _attendanceList) {
        final originalStatus = _originalStatusMap[record.studentId] ?? 'absent';
        if (record.status != originalStatus) {
          changesCount++;
          await _saveIndividualAttendance(record, originalStatus, adminUid);
        }
      }

      setState(() {
        _isEditMode = false;
        _originalStatusMap.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('$changesCount attendance records updated successfully.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(kDefaultPadding),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(kDefaultRadius)),
        ),
      );

      // Refetch data to ensure UI reflects database state
      await _fetchAttendanceData();
    } catch (e) {
      print("Error saving bulk attendance changes: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating attendance: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(kDefaultPadding),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(kDefaultRadius)),
        ),
      );
      setState(() => _isLoadingData = false);
    }
  }

  Future<void> _saveIndividualAttendance(
      _AttendanceData record, String originalStatus, String adminUid) async {
    final attendanceCollection = FirebaseFirestore.instance
        .collection('admins')
        .doc(adminUid)
        .collection('students')
        .doc(record.studentId)
        .collection('attendance');

    final targetDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final summaryDocRef = FirebaseFirestore.instance
        .collection('admins')
        .doc(adminUid)
        .collection('attendanceSummary')
        .doc(targetDate);

    final newStatus = record.status;

    // Use a transaction to update both student attendance and summary atomically
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      // Get the current summary document
      final summarySnapshot = await transaction.get(summaryDocRef);
      int presentCount = 0;
      List<dynamic> studentsPresent = [];

      if (summarySnapshot.exists) {
        final data = summarySnapshot.data() as Map<String, dynamic>;
        presentCount = data['present'] ?? 0;
        studentsPresent = List.from(data['studentsPresent'] ?? []);
      }

      // Adjust counts based on the change
      if (originalStatus == 'present') {
        presentCount = (presentCount > 0) ? presentCount - 1 : 0;
        studentsPresent.remove(record.studentId);
      }

      if (newStatus == 'present') {
        presentCount++;
        if (!studentsPresent.contains(record.studentId)) {
          studentsPresent.add(record.studentId);
        }
      }

      final summaryUpdateData = {
        'class': 'Overall',
        'present': presentCount,
        'studentsPresent': studentsPresent,
        'markedBy': adminUid,
        'markedAt': Timestamp.now(),
      };

      // Handle student's individual attendance record
      if (newStatus == 'present') {
        final studentAttendanceData = {
          'date': targetDate,
          'subject': record.subject ?? _selectedSubject ?? 'General',
          'status': 'present',
          'markedBy': adminUid,
          'markedAt': Timestamp.now(),
        };

        DocumentReference studentDocRefToUpdate;
        if (record.attendanceDocId != null) {
          studentDocRefToUpdate =
              attendanceCollection.doc(record.attendanceDocId);
          transaction.update(studentDocRefToUpdate, studentAttendanceData);
        } else {
          studentDocRefToUpdate = attendanceCollection.doc();
          transaction.set(studentDocRefToUpdate, studentAttendanceData);
        }
      } else if (newStatus == 'absent') {
        if (record.attendanceDocId != null) {
          final studentDocRefToDelete =
              attendanceCollection.doc(record.attendanceDocId);
          transaction.delete(studentDocRefToDelete);
        }
      }

      // Update or set the summary document
      if (summarySnapshot.exists) {
        transaction.update(summaryDocRef, summaryUpdateData);
      } else {
        summaryUpdateData['class'] = 'Overall';
        summaryUpdateData['present'] = newStatus == 'present' ? 1 : 0;
        summaryUpdateData['studentsPresent'] =
            newStatus == 'present' ? [record.studentId] : [];
        transaction.set(summaryDocRef, summaryUpdateData);
      }
    });
  }

  void _onBottomNavItemTapped(int index) {
    if (_selectedIndex == index) return;

    // Navigate immediately with animation
    switch (index) {
      case 0:
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const StudentListScreen()));
        break;
      case 1:
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const TeacherListScreen()));
        break;
      case 2:
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const DashboardScreen()));
        break;
      case 3:
        break; // Already on Attendance Summary Screen
      case 4:
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ExamResultsScreen()));
        break;
    }
  }

  Widget _buildProfileAvatar() {
    final String? userId = AuthController.instance.user?.uid;
    if (userId == null) {
      return IconButton(
        icon: const Icon(Icons.account_circle_rounded,
            size: 30, color: kLightTextColor),
        tooltip: 'Profile Settings',
        onPressed: () =>
            Get.toNamed(AppRoutes.profileSettings), // Use Get.toNamed
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
        Widget profileWidget = const Icon(Icons.account_circle_rounded,
            size: 30, color: kLightTextColor);

        if (snapshot.connectionState == ConnectionState.active &&
            snapshot.hasData &&
            snapshot.data!.exists) {
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
            backgroundColor: kLightTextColor.withOpacity(0.5),
            backgroundImage: NetworkImage(photoUrl),
            onBackgroundImageError: (exception, stackTrace) {
              print("Error loading profile image: $exception");
              if (mounted) {
                setState(() {
                  profileWidget = const Icon(Icons.account_circle_rounded,
                      size: 30, color: kLightTextColor);
                });
              }
            },
          );
        }

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(kDefaultRadius * 2),
            onTap: () => Get.toNamed(AppRoutes
                .profileSettings), // Use Get.toNamed (Already correct, ensuring consistency)
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _fetchAttendanceData();
      });
    }
  }

  Future<void> _shareAttendance() async {
    if (_selectedClass == null ||
        _selectedSubject == null ||
        _attendanceList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'Please select a class and subject with data to export.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(kDefaultPadding),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(kDefaultRadius)),
        ),
      );
      return;
    }

    setState(() => _isLoadingData = true);

    try {
      final excel = ex.Excel.createExcel();
      final ex.Sheet sheet = excel[excel.getDefaultSheet()!];

      // Sheet Name - Commenting out as the API might have changed or causes issues
      // sheet.sheetName = 'Attendance_${_selectedClass}_${DateFormat('yyyy-MM-dd').format(_selectedDate)}';

      sheet.appendRow([
        ex.TextCellValue('Student Name'),
        ex.TextCellValue('Subject'),
        ex.TextCellValue('Attendance Status'),
        ex.TextCellValue('Date'),
        ex.TextCellValue('Class'),
      ]);

      for (var record in _attendanceList) {
        sheet.appendRow([
          ex.TextCellValue(record.studentName),
          ex.TextCellValue(record.subject ?? 'General'),
          // Simplify status - only Present or Absent
          ex.TextCellValue(record.status == 'present' ? 'Present' : 'Absent'),
          ex.TextCellValue(DateFormat('yyyy-MM-dd').format(_selectedDate)),
          ex.TextCellValue(_selectedClass!),
        ]);
      }

      final directory = await getTemporaryDirectory();
      String fileName =
          'Attendance_${_selectedClass}_${DateFormat('yyyy-MM-dd').format(_selectedDate)}_${_selectedSubject?.replaceAll(' ', '_')}';
      final filePath = '${directory.path}/$fileName.xlsx';

      final fileBytes = excel.save();
      if (fileBytes != null) {
        final file = File(filePath);
        await file.writeAsBytes(fileBytes, flush: true);
        print('Excel file saved to: $filePath');

        final result = await Share.shareXFiles([XFile(filePath)],
            text:
                'Attendance Summary for $_selectedClass - $_selectedSubject on ${DateFormat('dd MMM yyyy').format(_selectedDate)}');

        if (result.status == ShareResultStatus.success) {
          print('Shared successfully!');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  const Text('Attendance exported and shared successfully!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(kDefaultPadding),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(kDefaultRadius)),
            ),
          );
        } else {
          print('Sharing failed or dismissed: ${result.status}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Sharing failed or was cancelled.'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(kDefaultPadding),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(kDefaultRadius)),
            ),
          );
        }
      } else {
        throw Exception("Failed to save Excel file bytes.");
      }
    } catch (e) {
      print("Error generating or sharing Excel: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error exporting attendance: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(kDefaultPadding),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(kDefaultRadius)),
        ),
      );
    } finally {
      setState(() => _isLoadingData = false);
    }
  }

  Future<void> _showAttendanceExportOptions() async {
    if (_selectedClass == null ||
        _selectedSubject == null ||
        _attendanceList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'Please select a class and subject with data to export.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(kDefaultPadding),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(kDefaultRadius)),
        ),
      );
      return;
    }

    final monthDate = DateFormat('dd MMM yyyy').format(_selectedDate);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
              'Export Attendance for $_selectedClass - $_selectedSubject on $monthDate'),
          content: const Text('Choose the export format:'),
          actions: <Widget>[
            TextButton(
              child: const Text('Excel (.xlsx)'),
              onPressed: () {
                Navigator.of(context).pop();
                _shareAttendance();
              },
            ),
            TextButton(
              child: const Text('PDF (.pdf)'),
              onPressed: () {
                Navigator.of(context).pop();
                _exportAttendanceAsPdf();
              },
            ),
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _exportAttendanceAsPdf() async {
    if (_attendanceList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No attendance data to export.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(kDefaultPadding),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(kDefaultRadius)),
        ),
      );
      return;
    }

    setState(() => _isLoadingData = true);

    try {
      final pdf = pw.Document();
      // Fetch academyName from admin profile (admins/{adminUid}/adminProfile/profile)
      String academyName = 'Academy';
      try {
        final String? adminUid = AuthController.instance.user?.uid;
        if (adminUid != null) {
          final profileDoc = await FirebaseFirestore.instance
              .collection('admins')
              .doc(adminUid)
              .collection('adminProfile')
              .doc('profile')
              .get();
          if (profileDoc.exists) {
            final data = profileDoc.data();
            if (data != null && data.containsKey('academyName')) {
              final val = data['academyName'];
              if (val is String && val.trim().isNotEmpty)
                academyName = val.trim();
            }
          }
        }
      } catch (e) {
        print('Error fetching academyName for PDF header: $e');
        // keep fallback academyName
      }
      final fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
      final boldFontData =
          await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
      final ttf = pw.Font.ttf(fontData);
      final boldTtf = pw.Font.ttf(boldFontData);

      // Only include Student Name and Status in the table body.
      // Subject, Class and Date are already included in the PDF heading/title.
      List<List<String>> tableData = [
        ['Student Name', 'Status'],
      ];

      for (var record in _attendanceList) {
        tableData.add([
          record.studentName,
          record.status == 'present' ? 'Present' : 'Absent',
        ]);
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: pdf_core.PdfPageFormat.a4,
          theme: pw.ThemeData.withFont(base: ttf, bold: boldTtf),
          header: (pw.Context context) {
            // Academy heading (main) + Attendance Summary as subheading
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text(
                    academyName,
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 22),
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Center(
                  child: pw.Text(
                    'Attendance Summary',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 16),
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text('Class: ${_selectedClass ?? ''}',
                    style: pw.TextStyle(fontSize: 12)),
                pw.Text('Subject: ${_selectedSubject ?? ''}',
                    style: pw.TextStyle(fontSize: 12)),
                pw.Text(
                    'Date: ${DateFormat('dd MMM yyyy').format(_selectedDate)}',
                    style: pw.TextStyle(fontSize: 12)),
                pw.SizedBox(height: 8),
              ],
            );
          },
          footer: (pw.Context context) {
            return pw.Center(
              child: pw.Text('Generated by EduTrack',
                  style: const pw.TextStyle(
                      fontSize: 8, color: pdf_core.PdfColors.grey)),
            );
          },
          build: (pw.Context context) => [
            // Keep the main title block inside page body too (for accessibility / print layout)
            pw.SizedBox(height: 2),
            pw.TableHelper.fromTextArray(
              context: null,
              cellAlignment: pw.Alignment.centerLeft,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellStyle: const pw.TextStyle(fontSize: 10),
              headerDecoration:
                  const pw.BoxDecoration(color: pdf_core.PdfColors.grey300),
              data: tableData,
              columnWidths: {
                0: const pw.FlexColumnWidth(4), // Student Name (wider)
                1: const pw.FlexColumnWidth(1), // Status
              },
            ),
          ],
        ),
      );

      final sanitizedClass = (_selectedClass ?? '')
          .replaceAll(RegExp(r'[\\/*?:"<>|]'), '_')
          .replaceAll(' ', '_');
      final sanitizedSubject = (_selectedSubject ?? '')
          .replaceAll(RegExp(r'[\\/*?:"<>|]'), '_')
          .replaceAll(' ', '_');
      final fileName =
          'Attendance_${sanitizedClass}_${sanitizedSubject}_${DateFormat('yyyyMMdd').format(_selectedDate)}.pdf';

      try {
        await Printing.sharePdf(bytes: await pdf.save(), filename: fileName);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Attendance PDF ready to be shared.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(kDefaultPadding),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(kDefaultRadius)),
          ),
        );
      } catch (e) {
        print('Error sharing PDF: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing attendance PDF: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(kDefaultPadding),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(kDefaultRadius)),
          ),
        );
      }
    } catch (e) {
      print('Error generating attendance PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error exporting attendance to PDF: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(kDefaultPadding),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(kDefaultRadius)),
        ),
      );
    } finally {
      setState(() => _isLoadingData = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // final colorScheme = Theme.of(context).colorScheme;

    final Map<int, IconData> navIcons = {
      0: Icons.school_rounded,
      1: Icons.co_present_rounded,
      2: Icons.dashboard_rounded,
      3: Icons.assignment_rounded,
      4: Icons.assessment_outlined
    };
    final Map<int, String> navLabels = {
      0: 'Students',
      1: 'Teachers',
      2: 'Dashboard',
      3: 'Attendance',
      4: 'Exam'
    };

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: kLightTextColor),
          tooltip: 'Back',
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const DashboardScreen()));
            }
          },
        ),
        title: Text('Attendance Summary', style: textTheme.titleLarge),
        centerTitle: true,
        actions: [
          _buildProfileAvatar(),
        ],
      ),
      body: Column(
        children: [
          // --- Filter Row ---
          Padding(
            padding: const EdgeInsets.all(kDefaultPadding),
            child: Column(
              children: [
                // First row - Class and Subject filters
                Row(
                  children: [
                    // Class Filter Dropdown
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: kDefaultPadding * 0.75,
                            vertical: kDefaultPadding * 0.25),
                        decoration: BoxDecoration(
                          color: kSecondaryColor,
                          borderRadius: BorderRadius.circular(kDefaultRadius),
                          border: Border.all(
                              color: kPrimaryColor.withOpacity(0.4),
                              width: 1.5),
                        ),
                        child: _isLoadingClasses
                            ? const Center(
                                child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2)))
                            : DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedClass,
                                  isExpanded: true,
                                  hint: Text('Select Class',
                                      style: textTheme.bodyMedium
                                          ?.copyWith(color: kLightTextColor)),
                                  icon: const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: kPrimaryColor),
                                  items:
                                      _availableClasses.map((String className) {
                                    return DropdownMenuItem<String>(
                                      value: className,
                                      child: Text(className,
                                          style: textTheme.bodyMedium),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    if (newValue != _selectedClass) {
                                      setState(() {
                                        _selectedClass = newValue;
                                        _selectedSubject =
                                            null; // Reset subject when class changes
                                        _attendanceList = [];
                                      });
                                      if (newValue != null) {
                                        _fetchSubjects().then(
                                            (_) => _fetchAttendanceData());
                                      }
                                    }
                                  },
                                  dropdownColor: kSecondaryColor,
                                ),
                              ), // Closing DropdownButtonHideUnderline
                      ), // Closing Container
                    ), // Closing Expanded (Class Filter)
                    const SizedBox(width: kDefaultPadding / 2),

                    // Subject Filter Dropdown
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: kDefaultPadding * 0.75,
                            vertical: kDefaultPadding * 0.25),
                        decoration: BoxDecoration(
                          color: kSecondaryColor,
                          borderRadius: BorderRadius.circular(kDefaultRadius),
                          border: Border.all(
                              color: kPrimaryColor.withOpacity(0.4),
                              width: 1.5),
                        ),
                        child: _isLoadingSubjects
                            ? const Center(
                                child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2)))
                            : DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedSubject,
                                  isExpanded: true,
                                  hint: Text('Select Subject',
                                      style: textTheme.bodyMedium
                                          ?.copyWith(color: kLightTextColor)),
                                  icon: const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: kPrimaryColor),
                                  items: _availableSubjects
                                      .map((String subjectName) {
                                    return DropdownMenuItem<String>(
                                      value: subjectName,
                                      child: Text(subjectName,
                                          style: textTheme.bodyMedium),
                                    );
                                  }).toList(),
                                  onChanged: (_selectedClass == null)
                                      ? null
                                      : (String? newValue) {
                                          if (newValue != _selectedSubject) {
                                            setState(() {
                                              _selectedSubject = newValue;
                                            });
                                            if (newValue != null) {
                                              _fetchAttendanceData();
                                            }
                                          }
                                        },
                                  dropdownColor: kSecondaryColor,
                                ),
                              ), // Closing DropdownButtonHideUnderline
                      ), // Closing Container
                    ), // Closing Expanded (Subject Filter)
                  ],
                ), // Closing Row
                const SizedBox(height: kDefaultPadding / 2),

                // Second row - Date and Share button
                Row(
                  children: [
                    // Date Filter Button
                    Expanded(
                      flex: 2,
                      child: InkWell(
                        onTap: () => _selectDate(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: kDefaultPadding * 0.75,
                              vertical: kDefaultPadding * 0.9),
                          decoration: BoxDecoration(
                            color: kSecondaryColor,
                            borderRadius: BorderRadius.circular(kDefaultRadius),
                            border: Border.all(
                                color: kPrimaryColor.withOpacity(0.4),
                                width: 1.5),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Icon(Icons.calendar_today_outlined,
                                  size: 20, color: kPrimaryColor),
                              const SizedBox(width: kDefaultPadding / 2),
                              Expanded(
                                child: Text(
                                  DateFormat('dd MMM yyyy')
                                      .format(_selectedDate),
                                  style: textTheme.bodyMedium,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ), // Closing Expanded (Date Filter)
                    const SizedBox(width: kDefaultPadding / 2),

                    // Edit Button
                    Expanded(
                      flex: 1,
                      child: ElevatedButton(
                        onPressed: (_attendanceList.isEmpty || _isLoadingData)
                            ? null
                            : (_isEditMode ? _saveAllChanges : _toggleEditMode),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(kDefaultRadius),
                          ),
                          minimumSize: const Size(50, 50),
                          padding: EdgeInsets.zero,
                          backgroundColor:
                              _isEditMode ? kSuccessColor : kPrimaryColor,
                          foregroundColor: Colors.white,
                          elevation: 3,
                        ),
                        child: Icon(
                            _isEditMode
                                ? Icons.save_rounded
                                : Icons.edit_rounded,
                            size: 24),
                      )
                          .animate()
                          .fadeIn(delay: 50.ms)
                          .scale(begin: const Offset(0.8, 0.8)),
                    ), // Closing Expanded (Edit Button)
                    const SizedBox(width: kDefaultPadding / 2),

                    // Share Button
                    Expanded(
                      flex: 1,
                      child: ElevatedButton(
                        onPressed: (_attendanceList.isEmpty ||
                                _isLoadingData ||
                                _isEditMode)
                            ? null
                            : _showAttendanceExportOptions,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(kDefaultRadius),
                          ),
                          minimumSize: const Size(50, 50),
                          padding: EdgeInsets.zero,
                          backgroundColor: kPrimaryColor,
                          foregroundColor: Colors.white,
                          elevation: 3,
                        ),
                        child: const Icon(Icons.share_rounded, size: 24),
                      )
                          .animate()
                          .fadeIn(delay: 100.ms)
                          .scale(begin: const Offset(0.8, 0.8)),
                    ), // Closing Expanded (Share Button)
                  ], // Closing Row children
                ), // Closing Row
              ],
            ), // Closing Column
          ), // Closing Padding

          // --- Attendance Table / Content Area ---
          Expanded(
            child: _buildContentArea(context),
          ),
        ], // Closing Column children
      ), // Closing Column
      bottomNavigationBar: BottomNavigationBar(
        items: List.generate(navIcons.length, (index) {
          bool isSelected = _selectedIndex == index;
          return BottomNavigationBarItem(
            icon: Animate(
              target: isSelected ? 1 : 0,
              effects: [
                ScaleEffect(
                    begin: const Offset(0.9, 0.9),
                    end: const Offset(1.1, 1.1),
                    duration: 200.ms,
                    curve: Curves.easeOut)
              ],
              child: Icon(navIcons[index]),
            ),
            label: navLabels[index],
          );
        }),
        currentIndex: _selectedIndex,
        selectedItemColor: kPrimaryColor,
        unselectedItemColor: kLightTextColor,
        onTap: _onBottomNavItemTapped,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        showSelectedLabels: true,
        selectedFontSize: 12.0,
        unselectedFontSize: 11.0,
        elevation: 10.0,
        backgroundColor: Colors.white,
      ),
    ); // Closing Scaffold
  } // build method ends here

  // --- Helper Widgets Moved Outside Build Method ---
  Widget _buildContentArea(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (_isLoadingData) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
          child: Text(_errorMessage!,
              style: textTheme.bodyMedium?.copyWith(color: Colors.red)));
    }

    if (_selectedClass == null) {
      return Center(
          child: Text('Please select a class to view attendance.',
              style: textTheme.bodyMedium?.copyWith(color: kLightTextColor)));
    }

    if (_selectedSubject == null) {
      return Center(
          child: Text('Please select a subject to view attendance.',
              style: textTheme.bodyMedium?.copyWith(color: kLightTextColor)));
    }

    if (_attendanceList.isEmpty) {
      String message =
          'No students found for $_selectedClass in $_selectedSubject\nor no attendance data for ${DateFormat('dd MMM yyyy').format(_selectedDate)}.';
      return Center(
          child: Text(message,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(color: kLightTextColor)));
    }

    return Column(
      children: [
        if (_selectedClass != null && _selectedSubject != null)
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: kDefaultPadding, vertical: kDefaultPadding / 2),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: kDefaultPadding, vertical: kDefaultPadding / 1.4),
              decoration: BoxDecoration(
                color: kPrimaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(kDefaultRadius),
                border: Border.all(
                    color: kPrimaryColor.withOpacity(0.25), width: 1.0),
              ),
              child: Row(
                children: [
                  const Icon(Icons.book_rounded, color: kPrimaryColor),
                  const SizedBox(width: kDefaultPadding / 2),
                  Expanded(
                      child: Text(
                    'Class: ${_selectedClass!}  •  Subject: ${_selectedSubject!}',
                    style: textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  )),
                ],
              ),
            ),
          ),

        // Attendance list with header
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(kDefaultPadding),
            itemCount: _attendanceList.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) return _buildHeaderRow(context);
              final dataIndex = index - 1;
              return _buildDataRow(
                  context, dataIndex, _attendanceList[dataIndex]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderRow(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(
          vertical: kDefaultPadding * 0.75, horizontal: kDefaultPadding / 2),
      decoration: BoxDecoration(
        color: kPrimaryColor.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(kDefaultRadius),
          topRight: Radius.circular(kDefaultRadius),
        ),
      ),
      child: Row(
        children: [
          Expanded(
              flex: 5,
              child: Text('Name',
                  style: textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold))),
          Expanded(
              flex: 3,
              child: Center(
                  child: Text('Status',
                      style: textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold)))),
        ],
      ),
    );
  }

  Widget _buildDataRow(
      BuildContext context, int rowIndex, _AttendanceData record) {
    final textTheme = Theme.of(context).textTheme;
    final isEvenRow = rowIndex % 2 == 0;

    return Container(
      padding: const EdgeInsets.symmetric(
          vertical: kDefaultPadding * 0.5, horizontal: kDefaultPadding / 2),
      decoration: BoxDecoration(
        color: isEvenRow ? Colors.white : kSecondaryColor.withOpacity(0.5),
        border:
            Border(bottom: BorderSide(color: Colors.grey.shade300, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              record.studentName,
              style: textTheme.bodyMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 3,
            child: Center(
              child: _isEditMode
                  ? _buildAttendanceDropdown(rowIndex, record.status)
                  : Text(
                      record.status == 'present' ? 'Present' : 'Absent',
                      style: textTheme.bodyMedium?.copyWith(
                        color: record.status == 'present'
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                        fontWeight: record.status == 'present'
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceDropdown(int index, String currentStatus) {
    return DropdownButton<String>(
      value: currentStatus == 'present' || currentStatus == 'absent'
          ? currentStatus
          : null,
      hint: Text('Select', style: TextStyle(color: Colors.grey.shade600)),
      items: [
        DropdownMenuItem(
            value: 'present',
            child: Text('Present',
                style: TextStyle(color: Colors.green.shade700))),
        DropdownMenuItem(
            value: 'absent',
            child:
                Text('Absent', style: TextStyle(color: Colors.red.shade700))),
      ],
      onChanged: (String? newValue) {
        if (newValue != null) {
          _updateAttendanceStatus(index, newValue);
        }
      },
      underline: Container(),
      isDense: true,
    );
  }
}
