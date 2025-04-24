import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edu_track/app/features/authentication/controllers/auth_controller.dart';
import 'package:edu_track/app/features/profile/screens/profile_settings_screen.dart';
import 'package:edu_track/app/features/students/screens/student_list_screen.dart';
import 'package:edu_track/app/features/teachers/screens/teacher_list_screen.dart';
import 'package:edu_track/app/features/dashboard/screens/dashboard_screen.dart';
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
  String? attendanceDocId; // Made non-final: ID of the attendance document if it exists
  bool isEditing;

  _AttendanceData({
    required this.studentId,
    required this.studentName,
    this.photoUrl,
    required this.status,
    this.attendanceDocId,
    this.isEditing = false,
  });
}


class AttendanceSummaryScreen extends StatefulWidget {
  const AttendanceSummaryScreen({super.key});

  @override
  State<AttendanceSummaryScreen> createState() => _AttendanceSummaryScreenState();
}

class _AttendanceSummaryScreenState extends State<AttendanceSummaryScreen> {
  int _selectedIndex = 3; // Attendance tab is selected
  String? _selectedClass;
  DateTime _selectedDate = DateTime.now();
  List<String> _availableClasses = [];
  bool _isLoadingClasses = true;
  bool _isLoadingData = false;
  String? _errorMessage; // Keep for general loading errors
  String? _statusMessage; // For success/error feedback messages
  bool _isError = false; // To style the status message

  List<_AttendanceData> _attendanceList = [];
  Map<String, String> _originalStatusMap = {};

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
          .where((className) => className != null && className.isNotEmpty) // Added isNotEmpty check
          .cast<String>()
          .toSet()
          .toList();
      classes.sort();
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


  Future<void> _fetchAttendanceData() async {
    if (_selectedClass == null) {
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
    print("Fetching attendance for Class: $_selectedClass, Date: $targetDate");

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

        // Fetch attendance from the nested subcollection
        // No need to use studentDoc.reference as we already have the path
        final attendanceSnapshot = await FirebaseFirestore.instance
            .collection('admins')
            .doc(adminUid)
            .collection('students')
            .doc(studentId)
            .collection('attendance')
            .where('date', isEqualTo: targetDate)
            .limit(1)
            .get();

        String status = '-';
        String? attendanceDocId;

        if (attendanceSnapshot.docs.isNotEmpty) {
          final attendanceData = attendanceSnapshot.docs.first.data();
          status = attendanceData['status'] as String? ?? '-';
          attendanceDocId = attendanceSnapshot.docs.first.id;
          print("  Student: $studentName, Status: $status, DocId: $attendanceDocId");
        } else {
           print("  Student: $studentName, Status: No record found for $targetDate");
           status = '-';
        }

        tempData.add(_AttendanceData(
          studentId: studentId,
          studentName: studentName,
          photoUrl: photoUrl,
          status: status,
          attendanceDocId: attendanceDocId,
        ));
      }

      setState(() {
        _attendanceList = tempData;
        _isLoadingData = false;
      });
      print("Finished fetching attendance data.");

    } catch (e) {
      print("Error fetching attendance data: $e");
      setState(() {
        _errorMessage = "Error loading attendance data.";
        _isLoadingData = false;
      });
    }
  }

  void _toggleEdit(int index) {
    setState(() {
      if (!_attendanceList[index].isEditing) {
         _originalStatusMap[_attendanceList[index].studentId] = _attendanceList[index].status;
      }
      _attendanceList[index].isEditing = !_attendanceList[index].isEditing;
      if (!_attendanceList[index].isEditing) {
         final originalStatus = _originalStatusMap[_attendanceList[index].studentId];
         if (originalStatus != null) {
           _attendanceList[index].status = originalStatus;
         }
         _originalStatusMap.remove(_attendanceList[index].studentId);
      }
    });
  }

  void _updateAttendanceStatus(int index, String uiSelection) {
     // Map UI selection ('absent') to internal status ('-') for deletion
     final newInternalStatus = uiSelection == 'absent' ? '-' : uiSelection;
     setState(() {
       _attendanceList[index].status = newInternalStatus;
     });
     print("Updated internal status for ${_attendanceList[index].studentName} to: $newInternalStatus (UI selected: $uiSelection)");
  }

  Future<void> _saveAttendance(int index) async {
     final record = _attendanceList[index];
     final originalStatus = _originalStatusMap[record.studentId] ?? '-';

     if (record.status == originalStatus) {
       print("No change detected for ${record.studentName}, skipping save.");
       setState(() {
         record.isEditing = false;
         _originalStatusMap.remove(record.studentId);
       });
       return;
     }

     setState(() => _isLoadingData = true);

     final String? adminUid = AuthController.instance.user?.uid;
     if (adminUid == null) {
       print("Error: Admin UID is null. Cannot save attendance.");
       setState(() {
         _statusMessage = 'Error: Could not verify admin to save attendance.';
         _isError = true;
         _isLoadingData = false;
       });
       // Clear message after a delay
       Future.delayed(const Duration(seconds: 3), () {
         if (mounted) setState(() => _statusMessage = null);
       });
       return;
     }

     // Reference the nested attendance collection correctly
     final attendanceCollection = FirebaseFirestore.instance
         .collection('admins')
         .doc(adminUid)
         .collection('students')
         .doc(record.studentId)
         .collection('attendance');

     final targetDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
     // final adminUid = AuthController.instance.user?.uid ?? 'unknown_admin'; // Already fetched

     final summaryDocRef = FirebaseFirestore.instance
         .collection('admins')
         .doc(adminUid)
         .collection('attendanceSummary')
         .doc(targetDate);

     final newStatus = record.status;
     // final originalStatus = _originalStatusMap[record.studentId] ?? '-'; // Already defined above

     bool potentiallyCreatedNewDoc = (originalStatus == '-' && newStatus != '-');

     try {
       // Use a transaction to update both student attendance and summary atomically
       await FirebaseFirestore.instance.runTransaction((transaction) async {
         // 1. Get the current summary document
         final summarySnapshot = await transaction.get(summaryDocRef);
         int presentCount = 0;
         // int absentCount = 0; // Removed: Absent count is implicit
         List<dynamic> studentsPresent = [];
         // List<dynamic> studentsAbsent = []; // Removed: Absent list is implicit

         if (summarySnapshot.exists) {
           final data = summarySnapshot.data() as Map<String, dynamic>;
           presentCount = data['present'] ?? 0;
           // absentCount = data['absent'] ?? 0; // Removed
           studentsPresent = List.from(data['studentsPresent'] ?? []);
           // studentsAbsent = List.from(data['studentsAbsent'] ?? []); // Removed
         }

         // 2. Adjust counts and lists based on the change
         // Remove student from previous state lists first
         if (originalStatus == 'present') {
           presentCount = (presentCount > 0) ? presentCount - 1 : 0; // Decrement safely
           studentsPresent.remove(record.studentId);
         }
         // No need to handle originalStatus == 'absent' or '-' for decrementing counts/lists anymore

         // Add student to new state lists ONLY if present
         if (newStatus == 'present') {
           presentCount++;
           if (!studentsPresent.contains(record.studentId)) {
             studentsPresent.add(record.studentId);
           }
         }
         // If newStatus is '-', the student is simply removed from the present list (handled above if originalStatus was 'present')

         // 3. Prepare summary update data (only present info)
         final summaryUpdateData = {
           'present': presentCount,
           // 'absent': absentCount, // Removed
           'studentsPresent': studentsPresent,
           // 'studentsAbsent': studentsAbsent, // Removed
           'markedBy': adminUid, // Track who last updated summary
           'markedAt': Timestamp.now(),
         };

         // 4. Update, set, or delete the student's individual attendance record (Logic remains the same here)
         DocumentReference? studentDocRef; // Nullable
         bool isCreatingNewStudentDoc = false; // Flag for refetch logic
         bool wasDeleted = false; // Flag to track deletion

         if (record.attendanceDocId != null) {
           studentDocRef = attendanceCollection.doc(record.attendanceDocId);
         }

         // Decide the operation: delete, set, update, or none
         if (newStatus == '-') {
             // If changing to '-', delete the record if it exists
             if (studentDocRef != null) {
                 print("Deleting attendance record for ${record.studentId} as status is now '-' (Doc ID: ${record.attendanceDocId})");
                 transaction.delete(studentDocRef);
                 wasDeleted = true; // Mark for local state update after transaction
             } else {
                  print("Status is '-' and no existing record for ${record.studentId}, doing nothing for student record.");
             }
         } else { // newStatus is 'present' or 'absent'
             final studentAttendanceData = { // Use specific data for update/set
                 'date': targetDate,
                 'status': newStatus,
                 'markedBy': adminUid,
                 'markedAt': Timestamp.now(),
             };
             if (studentDocRef != null) {
                 // Record exists, update it
                 print("Updating attendance record for ${record.studentId} to $newStatus (Doc ID: ${record.attendanceDocId})");
                 transaction.update(studentDocRef, studentAttendanceData);
             } else {
                 // Record doesn't exist, create it
                 print("Creating new attendance record for ${record.studentId} with status $newStatus");
                 // Generate a new ref *only* when creating
                 studentDocRef = attendanceCollection.doc(); // Assign the new ref
                 transaction.set(studentDocRef, studentAttendanceData);
                 // Mark that a new doc was potentially created for refetch logic
                 isCreatingNewStudentDoc = true; // Use this flag for refetch logic
             }
         }


         // 5. Update or set the summary document
         // Update summary if it exists OR if presentCount > 0 (to create it if needed)
         // Delete summary if presentCount becomes zero.
         if (presentCount > 0) {
            if (summarySnapshot.exists) {
              transaction.update(summaryDocRef, summaryUpdateData);
            } else {
              // If summary doesn't exist but we have present students
              transaction.set(summaryDocRef, summaryUpdateData);
            }
         } else if (summarySnapshot.exists) {
            // If presentCount is 0 and the summary doc exists, delete it.
            print("Present count is zero, deleting summary document for $targetDate");
            transaction.delete(summaryDocRef);
         } else {
            // If presentCount is 0 and summary doesn't exist, do nothing.
            print("Summary document does not exist and present count is zero. No summary update needed.");
         }
       }); // End of transaction

       print("Successfully processed attendance update for ${record.studentName}");
       setState(() {
         _statusMessage = '${record.studentName} attendance updated successfully.';
         _isError = false;
       });
       // Clear message after a delay
       Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => _statusMessage = null);
       });
 
      } catch (e) {
        print("Error saving attendance transaction for ${record.studentName}: $e");
        setState(() {
          _statusMessage = 'Error updating attendance for ${record.studentName}.';
          _isError = true;
        });
        // Clear message after a delay
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => _statusMessage = null);
        });
      } finally {
       // Determine state changes after the transaction attempt
       bool wasDeleted = (newStatus == '-' && originalStatus != '-'); // Record was deleted
       bool wasCreated = (newStatus != '-' && originalStatus == '-'); // Record was created

       setState(() => _isLoadingData = false); // Stop loading indicator regardless

       if (wasDeleted && record.attendanceDocId != null) { // Ensure it *was* actually deleted from DB state
         print("Attendance record deleted for ${record.studentName}. Updating local state.");
         setState(() {
           // record.status is already '-' from _updateAttendanceStatus
           record.attendanceDocId = null; // Clear the doc ID locally
           record.isEditing = false;
           _originalStatusMap.remove(record.studentId);
         });
       } else if (wasCreated) {
         // If a new student attendance doc was created
         print("Attendance record created for ${record.studentName}, re-fetching data...");
         // Refetch is needed to get the new attendanceDocId
         await _fetchAttendanceData(); // Use await here
       } else {
         // Standard update case (e.g., absent -> present, present -> present, absent -> absent)
         // Or case where status was '-' and stayed '-' (no DB change)
         setState(() {
           record.isEditing = false;
           _originalStatusMap.remove(record.studentId);
         });
       }
     }
  }


 void _onBottomNavItemTapped(int index) {
    if (_selectedIndex == index) return;

    setState(() { _selectedIndex = index; });

    Future.delayed(150.ms, () {
      if (!mounted) return;
      switch (index) {
        case 0: Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardScreen())); break;
        case 1: Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const StudentListScreen())); break;
        case 2: Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const TeacherListScreen())); break;
        case 3: break; // Already on Attendance Summary Screen
        case 4:
          AuthController.instance.signOut();
          Navigator.pushAndRemoveUntil( context, MaterialPageRoute(builder: (_) => const SignInScreen()), (route) => false );
          break;
      }
    });
  }

  Widget _buildProfileAvatar() {
    final String? userId = AuthController.instance.user?.uid;
    if (userId == null) {
      return IconButton(
        icon: const Icon(Icons.account_circle_rounded, size: 30, color: kLightTextColor),
        tooltip: 'Profile Settings',
        onPressed: () => Get.toNamed(AppRoutes.profileSettings), // Use Get.toNamed
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
        Widget profileWidget = const Icon(Icons.account_circle_rounded, size: 30, color: kLightTextColor);

        if (snapshot.connectionState == ConnectionState.active && snapshot.hasData && snapshot.data!.exists) {
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
                   profileWidget = const Icon(Icons.account_circle_rounded, size: 30, color: kLightTextColor);
                });
              }
            },
          );
        }

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(kDefaultRadius * 2),
            onTap: () => Get.toNamed(AppRoutes.profileSettings), // Use Get.toNamed (Already correct, ensuring consistency)
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding, vertical: kDefaultPadding / 2),
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
    if (_selectedClass == null || _attendanceList.isEmpty) {
      setState(() {
        _statusMessage = 'Please select a class with data to export.';
        _isError = true; // Treat as warning/error
      });
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _statusMessage = null);
      });
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
        ex.TextCellValue('Attendance Status'),
        ex.TextCellValue('Date'),
        ex.TextCellValue('Class'),
      ]);

      for (var record in _attendanceList) {
        sheet.appendRow([
          ex.TextCellValue(record.studentName),
          // Explicitly use the local extension to resolve conflict
          ex.TextCellValue(record.status == '-' ? 'Absent' : StringExtension(record.status).capitalize()),
          ex.TextCellValue(DateFormat('yyyy-MM-dd').format(_selectedDate)),
          ex.TextCellValue(_selectedClass!),
        ]);
      }

      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/Attendance_${_selectedClass}_${DateFormat('yyyy-MM-dd').format(_selectedDate)}.xlsx';

      final fileBytes = excel.save();
      if (fileBytes != null) {
        final file = File(filePath);
        await file.writeAsBytes(fileBytes, flush: true);
        print('Excel file saved to: $filePath');

        final result = await Share.shareXFiles([XFile(filePath)], text: 'Attendance Summary for $_selectedClass on ${DateFormat('dd MMM yyyy').format(_selectedDate)}');

        if (result.status == ShareResultStatus.success) {
           print('Shared successfully!');
           setState(() {
             _statusMessage = 'Attendance exported and shared successfully!';
             _isError = false;
           });
           Future.delayed(const Duration(seconds: 3), () {
             if (mounted) setState(() => _statusMessage = null);
           });
        } else {
           print('Sharing failed or dismissed: ${result.status}');
           setState(() {
             _statusMessage = 'Sharing failed or was cancelled.';
             _isError = true; // Treat as warning/error
           });
           Future.delayed(const Duration(seconds: 3), () {
             if (mounted) setState(() => _statusMessage = null);
           });
        }

      } else {
        throw Exception("Failed to save Excel file bytes.");
      }

    } catch (e) {
      print("Error generating or sharing Excel: $e");
      setState(() {
        _statusMessage = 'Error exporting attendance: ${e.toString()}';
        _isError = true;
      });
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _statusMessage = null);
      });
    } finally {
      // Ensure loading indicator stops even if message clearing is delayed
      if (mounted) setState(() => _isLoadingData = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final Map<int, IconData> navIcons = {
      0: Icons.dashboard_rounded,
      1: Icons.school_rounded,
      2: Icons.co_present_rounded,
      3: Icons.assignment_rounded,
      4: Icons.logout_rounded
    };
    final Map<int, String> navLabels = {
      0: 'Dashboard',
      1: 'Students',
      2: 'Teachers',
      3: 'Attendance',
      4: 'Logout'
    };

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kLightTextColor),
          tooltip: 'Back',
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
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
            child: Row(
              children: [
                // Class Filter Dropdown
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding * 0.75, vertical: kDefaultPadding * 0.25),
                    decoration: BoxDecoration(
                      color: kSecondaryColor,
                      borderRadius: BorderRadius.circular(kDefaultRadius),
                      border: Border.all(color: kPrimaryColor.withOpacity(0.4), width: 1.5),
                    ),
                    child: _isLoadingClasses
                      ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                      : DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedClass,
                          isExpanded: true,
                          hint: Text('Select Class', style: textTheme.bodyMedium?.copyWith(color: kLightTextColor)),
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: kPrimaryColor),
                          items: _availableClasses.map((String className) {
                            return DropdownMenuItem<String>(
                              value: className,
                              child: Text(className, style: textTheme.bodyMedium),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != _selectedClass) {
                              setState(() {
                                _selectedClass = newValue;
                                _fetchAttendanceData();
                              });
                            }
                          },
                          dropdownColor: kSecondaryColor,
                        ),
                      ), // Closing DropdownButtonHideUnderline
                  ), // Closing Container
                ), // Closing Expanded (Class Filter)
                const SizedBox(width: kDefaultPadding / 2), // Correct SizedBox usage
                // Date Filter Button
                Expanded(
                  flex: 3,
                  child: InkWell(
                     onTap: () => _selectDate(context),
                     child: Container(
                       padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding * 0.75, vertical: kDefaultPadding * 0.9),
                       decoration: BoxDecoration(
                         color: kSecondaryColor,
                         borderRadius: BorderRadius.circular(kDefaultRadius),
                         border: Border.all(color: kPrimaryColor.withOpacity(0.4), width: 1.5),
                       ),
                       child: Row(
                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                         children: [
                           const Icon(Icons.calendar_today_outlined, size: 20, color: kPrimaryColor),
                           const SizedBox(width: kDefaultPadding / 2),
                           Expanded(
                             child: Text(
                               DateFormat('dd MMM yyyy').format(_selectedDate),
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
                // Share Button
                Expanded(
                  flex: 1,
                  child: ElevatedButton(
                    onPressed: _shareAttendance,
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
                  ).animate().fadeIn(delay: 100.ms).scale(begin: const Offset(0.8, 0.8)),
                ), // Closing Expanded (Share Button)
              ], // Closing Row children
            ), // Closing Row
          ), // Closing Padding

          // --- Attendance Table / Content Area ---
          Expanded(
            child: _buildContentArea(context),
          ),

          // --- Status Message (Moved to bottom) ---
          AnimatedOpacity(
            opacity: _statusMessage != null ? 1.0 : 0.0,
            duration: 300.ms,
            child: Padding( // Add padding around the message
              padding: const EdgeInsets.fromLTRB(kDefaultPadding, kDefaultPadding / 2, kDefaultPadding, kDefaultPadding), // Padding at bottom
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding, vertical: kDefaultPadding * 0.6),
                  decoration: BoxDecoration(
                    color: _isError ? kErrorColor.withOpacity(0.1) : kSuccessColor.withOpacity(0.1),
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
                      Flexible( // Allow text to wrap if needed
                        child: Text(
                          _statusMessage ?? '',
                          style: textTheme.bodyMedium?.copyWith(
                            color: _isError ? kErrorColor : kSuccessColor,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center, // Center align text
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ], // Closing Column children
      ), // Closing Column
      bottomNavigationBar: BottomNavigationBar(
        items: List.generate(navIcons.length, (index) {
          bool isSelected = _selectedIndex == index;
          return BottomNavigationBarItem(
            icon: Animate(
              target: isSelected ? 1 : 0,
              effects: [ScaleEffect(begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1), duration: 200.ms, curve: Curves.easeOut)],
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
       return Center(child: Text(_errorMessage!, style: textTheme.bodyMedium?.copyWith(color: Colors.red)));
     }

     if (_selectedClass == null) {
       return Center(child: Text('Please select a class to view attendance.', style: textTheme.bodyMedium?.copyWith(color: kLightTextColor)));
     }

     if (_attendanceList.isEmpty) {
       return Center(child: Text('No students found for $_selectedClass\nor no attendance data for ${DateFormat('dd MMM yyyy').format(_selectedDate)}.', textAlign: TextAlign.center, style: textTheme.bodyMedium?.copyWith(color: kLightTextColor)));
     }

     return ListView.builder(
        padding: const EdgeInsets.all(kDefaultPadding),
        itemCount: _attendanceList.length + 1, // +1 for header row
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildHeaderRow(context);
          } else {
            final dataIndex = index - 1;
            return _buildDataRow(context, dataIndex, _attendanceList[dataIndex]);
          }
        },
     );
  }

  Widget _buildHeaderRow(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: kDefaultPadding * 0.75, horizontal: kDefaultPadding / 2),
      decoration: BoxDecoration(
        color: kPrimaryColor.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(kDefaultRadius),
          topRight: Radius.circular(kDefaultRadius),
        ),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('Name', style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: Center(child: Text('Attendance', style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)))),
          Expanded(flex: 2, child: Center(child: Text('Actions', style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)))),
        ],
      ),
    );
  }

  Widget _buildDataRow(BuildContext context, int rowIndex, _AttendanceData record) {
     final textTheme = Theme.of(context).textTheme;
     final isEvenRow = rowIndex % 2 == 0;

     return Container(
       padding: const EdgeInsets.symmetric(vertical: kDefaultPadding * 0.5, horizontal: kDefaultPadding / 2),
       decoration: BoxDecoration(
         color: isEvenRow ? Colors.white : kSecondaryColor.withOpacity(0.5),
         border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 0.5)),
       ),
       child: Row(
         children: [
           Expanded(
             flex: 3,
             child: Text(
               record.studentName,
               style: textTheme.bodyMedium,
               maxLines: 1,
               overflow: TextOverflow.ellipsis,
             ),
           ),
           Expanded(
             flex: 2,
             child: Center(
               child: record.isEditing
                 ? _buildAttendanceDropdown(rowIndex, record.status)
                 : Text(
                     record.status == 'present' ? 'Present' : 'Absent', // Show 'Present' or 'Absent'
                     style: textTheme.bodyMedium?.copyWith(
                       color: record.status == 'present' ? Colors.green.shade700 : Colors.red.shade700, // Color change for Absent
                       fontWeight: record.status == 'present' ? FontWeight.w600 : FontWeight.normal,
                     ),
                   ),
             ),
           ),
           Expanded(
             flex: 2,
             child: Center(
               child: record.isEditing
                 ? ElevatedButton.icon(
                     icon: const Icon(Icons.save_rounded, size: 18),
                     label: const Text('Save'),
                     onPressed: () => _saveAttendance(rowIndex),
                     style: ElevatedButton.styleFrom(
                       padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding * 0.8, vertical: kDefaultPadding * 0.4),
                       textStyle: textTheme.labelSmall,
                       backgroundColor: Colors.green,
                       foregroundColor: Colors.white,
                     ),
                   )
                 : ElevatedButton.icon(
                     icon: const Icon(Icons.edit_rounded, size: 18),
                     label: const Text('Edit'),
                     onPressed: () => _toggleEdit(rowIndex),
                     style: ElevatedButton.styleFrom(
                       padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding * 0.8, vertical: kDefaultPadding * 0.4),
                       textStyle: textTheme.labelSmall,
                       backgroundColor: kPrimaryColor,
                       foregroundColor: Colors.white,
                     ),
                   ),
             ),
           ),
         ],
       ),
     );
  }

  Widget _buildAttendanceDropdown(int index, String currentInternalStatus) {
     // Map internal status '-' back to 'absent' for dropdown display value
     String? dropdownValue;
     if (currentInternalStatus == 'present') {
       dropdownValue = 'present';
     } else if (currentInternalStatus == '-') {
       // If internal status is '-', show 'Absent' as selected in dropdown
       dropdownValue = 'absent';
     }
     // If internal status is somehow 'absent' (shouldn't happen with new logic, but handle defensively), treat as absent
     else if (currentInternalStatus == 'absent') {
        dropdownValue = 'absent';
     }


     return DropdownButton<String>(
       value: dropdownValue, // Use the mapped value
       hint: Text('Select', style: TextStyle(color: Colors.grey.shade600)),
       items: [
         DropdownMenuItem(value: 'present', child: Text('Present', style: TextStyle(color: Colors.green.shade700))),
         // UI always shows 'Absent', value is 'absent'
         DropdownMenuItem(value: 'absent', child: Text('Absent', style: TextStyle(color: Colors.red.shade700))),
       ],
       onChanged: (String? newValue) {
         if (newValue != null) {
           // Pass the UI selection ('present' or 'absent') to the update function
           _updateAttendanceStatus(index, newValue);
         }
       },
       underline: Container(),
       isDense: true,
     );
  }

} // _AttendanceSummaryScreenState class ends here