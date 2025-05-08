import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edu_track/app/features/authentication/controllers/auth_controller.dart';
import 'package:edu_track/app/features/profile/screens/profile_settings_screen.dart';
import 'package:edu_track/app/features/dashboard/screens/dashboard_screen.dart';
import 'package:edu_track/app/utils/constants.dart';
import 'package:edu_track/main.dart'; // Import main for AppRoutes
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For TextInputFormatters
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart' as ex;
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle; // Needed for font loading
import 'package:pdf/widgets.dart' as pw; // PDF generation
import 'package:pdf/pdf.dart'; // PDF page format
import 'package:printing/printing.dart'; // PDF sharing/printing

// Data model for holding combined student and exam result info
class _ExamResultData {
  final String studentId;
  final String studentName;
  final String? photoUrl;
  int currentMarks;
  final String? examResultDocId; // ID of the exam result document if it exists
  final TextEditingController marksController;

  _ExamResultData({
    required this.studentId,
    required this.studentName,
    this.photoUrl,
    required this.currentMarks,
    this.examResultDocId,
  }) : marksController = TextEditingController(text: currentMarks.toString());
}

// Data model for Exam Terms
class _ExamTerm {
  final String id;
  final String name;
  final List<String> subjects;

  _ExamTerm({required this.id, required this.name, required this.subjects});
}

class ExamResultsScreen extends StatefulWidget {
  const ExamResultsScreen({super.key});

  @override
  State<ExamResultsScreen> createState() => _ExamResultsScreenState();
}

class _ExamResultsScreenState extends State<ExamResultsScreen> {
  // int _selectedIndex = 3; // Assuming Exam Results uses the 4th nav item (index 3) like Attendance
  String? _selectedClassSection;
  String? _selectedSubject;
  _ExamTerm? _selectedTerm;

  List<String> _availableClassSections = [];
  List<_ExamTerm> _availableTerms = [];
  List<String> _availableSubjects = [];

  bool _isLoadingClasses = true;
  bool _isLoadingTerms = true;
  bool _isLoadingSubjects = false; // Only load after term is selected
  bool _isLoadingResults = false;
  String? _errorMessage;

  List<_ExamResultData> _examResultsList = [];
  bool _isEditing = false;

  // Store original marks before editing
  Map<String, int> _originalMarksMap = {};

  @override
  void initState() {
    super.initState();
    _fetchClassSections();
    _fetchTerms();
  }

  @override
  void dispose() {
    // Dispose controllers to prevent memory leaks
    for (var result in _examResultsList) {
      result.marksController.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchClassSections() async {
    setState(() {
      _isLoadingClasses = true;
      _errorMessage = null;
      _availableClassSections = [];
      _selectedClassSection = null; // Reset selection
      _examResultsList = []; // Clear results
    });
    final String? adminUid = AuthController.instance.user?.uid;
    if (adminUid == null) {
      print("Error: Admin UID is null. Cannot fetch class sections.");
      setState(() {
        _errorMessage = "Error: Could not verify admin.";
        _isLoadingClasses = false;
        _availableClassSections = [];
      });
      return;
    }

    try {
      // Fetch students from the nested collection under the current admin
      final snapshot = await FirebaseFirestore.instance
          .collection('admins')
          .doc(adminUid)
          .collection('students')
          .get();
      final classSections = snapshot.docs
          .map((doc) {
            final data = doc.data();
            final className = data['class'] as String?;
            final section = data['section'] as String?;
            if (className != null && section != null) {
              return '$className - $section';
            }
            return null;
          })
          .where((cs) => cs != null)
          .cast<String>()
          .toSet() // Use Set for uniqueness
          .toList();
      classSections.sort(); // Sort alphabetically
      setState(() {
        _availableClassSections = classSections;
        _isLoadingClasses = false;
      });
    } catch (e) {
      print("Error fetching class sections: $e");
      setState(() {
        _errorMessage = "Error loading classes.";
        _isLoadingClasses = false;
      });
    }
  }

  Future<void> _fetchTerms() async {
    setState(() {
      _isLoadingTerms = true;
      _errorMessage = null;
      _availableTerms = [];
      _selectedTerm = null; // Reset selection
      _availableSubjects = []; // Clear subjects
      _selectedSubject = null; // Reset subject selection
      _examResultsList = []; // Clear results
    });
    final String? adminUid = AuthController.instance.user?.uid;
     if (adminUid == null) {
       print("Error: Admin UID is null. Cannot fetch exam terms.");
       setState(() {
         _errorMessage = "Error: Could not verify admin.";
         _isLoadingTerms = false;
         _availableTerms = [];
       });
       return;
     }

    try {
      // Fetch terms from the nested collection under the current admin
      final snapshot = await FirebaseFirestore.instance
          .collection('admins')
          .doc(adminUid)
          .collection('examTerms')
          .orderBy('startDate') // Assuming startDate exists for ordering
          .get();
      final terms = snapshot.docs.map((doc) {
        final data = doc.data();
        final subjectsList = (data['subjects'] as List<dynamic>?)?.cast<String>() ?? [];
        return _ExamTerm(
          id: doc.id,
          name: data['name'] as String? ?? 'Unnamed Term',
          subjects: subjectsList,
        );
      }).toList();

      setState(() {
        _availableTerms = terms;
        _isLoadingTerms = false;
      });
    } catch (e) {
      print("Error fetching terms: $e");
      setState(() {
        _errorMessage = "Error loading terms.";
        _isLoadingTerms = false;
      });
    }
  }

  void _onTermSelected(_ExamTerm? term) {
    if (term == null || term == _selectedTerm) return;
    setState(() {
      _selectedTerm = term;
      _isLoadingSubjects = true;
      _availableSubjects = [];
      _selectedSubject = null; // Reset subject
      _examResultsList = []; // Clear results
      _isEditing = false; // Exit edit mode
    });

    // Simulate loading subjects (already fetched with term)
    Future.delayed(Duration.zero, () {
       setState(() {
         _availableSubjects = _selectedTerm?.subjects ?? [];
         _availableSubjects.sort();
         _isLoadingSubjects = false;
         // Automatically select the first subject if available
         if (_availableSubjects.isNotEmpty) {
           // _selectedSubject = _availableSubjects.first;
           // _fetchExamResults(); // Fetch results if class is also selected
         }
       });
    });
  }

   void _onSubjectSelected(String? subject) {
     if (subject == null || subject == _selectedSubject) return;
     setState(() {
       _selectedSubject = subject;
       _examResultsList = []; // Clear previous results
       _isEditing = false; // Exit edit mode
     });
     _fetchExamResults(); // Fetch new results
   }

   void _onClassSectionSelected(String? classSection) {
     if (classSection == null || classSection == _selectedClassSection) return;
     setState(() {
       _selectedClassSection = classSection;
       _examResultsList = []; // Clear previous results
       _isEditing = false; // Exit edit mode
     });
     _fetchExamResults(); // Fetch new results
   }


  Future<void> _fetchExamResults() async {
    // Clear previous controllers first
    for (var result in _examResultsList) {
      result.marksController.dispose();
    }

    if (_selectedClassSection == null || _selectedSubject == null || _selectedTerm == null) {
      setState(() => _examResultsList = []);
      return;
    }

    setState(() {
      _isLoadingResults = true;
      _errorMessage = null;
      _examResultsList = [];
      _isEditing = false; // Ensure edit mode is off when fetching new data
    });

    final parts = _selectedClassSection!.split(' - ');
    if (parts.length != 2) {
      setState(() {
        _errorMessage = "Invalid class format selected.";
        _isLoadingResults = false;
      });
      return;
    }
    final className = parts[0];
    final section = parts[1];

    print("Fetching Exam Results for Class: $className, Section: $section, Subject: $_selectedSubject, Term: ${_selectedTerm!.name}");

    final String? adminUid = AuthController.instance.user?.uid;
     if (adminUid == null) {
       print("Error: Admin UID is null. Cannot fetch exam results.");
       setState(() {
         _errorMessage = "Error: Could not verify admin.";
         _isLoadingResults = false;
         _examResultsList = [];
       });
       return;
     }

    try {
      // Fetch students from the nested collection
      final studentSnapshot = await FirebaseFirestore.instance
          .collection('admins')
          .doc(adminUid)
          .collection('students')
          .where('class', isEqualTo: className)
          .where('section', isEqualTo: section)
          // .where('subjectsChoosed', arrayContains: _selectedSubject) // Filter removed, will filter in app
          .orderBy('name')
          .get();

      if (studentSnapshot.docs.isEmpty) {
        print("No students found for class: $_selectedClassSection");
        setState(() {
          _isLoadingResults = false;
          _examResultsList = [];
        });
        return;
      }

      print("Found ${studentSnapshot.docs.length} students.");

      List<_ExamResultData> tempData = [];
      // final adminUid = AuthController.instance.user?.uid ?? 'unknown_admin'; // Already fetched

      for (var studentDoc in studentSnapshot.docs) {
        final studentData = studentDoc.data();
        final studentId = studentDoc.id;

        // --- In-app filtering ---
        final List<dynamic> subjectsChoosedList = studentData['subjectsChoosed'] as List<dynamic>? ?? [];
        // Trim strings during mapping for robust comparison
        final List<String> subjectsChoosed = subjectsChoosedList.map((s) => s.toString().trim()).toList();

        // Add detailed debug prints
        print("  Checking student: ${studentData['name']}, Subjects List: $subjectsChoosed, Selected Subject: '$_selectedSubject'");

        // Ensure selected subject is not null and trim it before comparison
        if (_selectedSubject == null || !subjectsChoosed.contains(_selectedSubject!.trim())) {
          print("  Student: ${studentData['name']} skipped (doesn't take '$_selectedSubject')");
          continue; // Skip this student if they don't take the selected subject
        }
        // --- End in-app filtering ---

        final studentName = studentData['name'] as String? ?? 'Unknown Name';
        final photoUrl = studentData['photoUrl'] as String?;

        // Add logging before the query to see exact values
        // Trim the selected subject *before* using it in the query for robustness
        final String? subjectToQuery = _selectedSubject?.trim();
        if (subjectToQuery == null) {
           print("  Error: Selected subject is null after trimming. Skipping query for student $studentId.");
           continue; // Skip if subject is somehow null after trimming
        }

        print("  Querying examResults for studentId: $studentId, termId: '${_selectedTerm!.id}', subject: '$subjectToQuery'"); // Log the trimmed value

        // Fetch exam result from the nested subcollection
        final examResultSnapshot = await FirebaseFirestore.instance
            .collection('admins')
            .doc(adminUid)
            .collection('students')
            .doc(studentId)
            .collection('examResults')
            .where('term', isEqualTo: _selectedTerm!.id) // Query only by term ID
            // .where('subject', isEqualTo: subjectToQuery) // Subject check moved after fetch
            // .limit(1) // REMOVED: Need to check all docs for the term
            .get();

        int marks = 0; // Default marks
        String? examResultDocId;

        // Iterate through all documents found for the term to find the matching subject
        bool subjectFound = false;
        for (var doc in examResultSnapshot.docs) {
          final resultData = doc.data();
          final String? fetchedSubject = resultData['subject'] as String?;

          // --- Verify Subject Match In-App ---
          if (fetchedSubject?.trim() == subjectToQuery) {
            // Subject matches, proceed to get marks
            print("  Student: $studentName, Found record for term and subject matches.");
            subjectFound = true;
            // Handle both int and double for marks
            final num? marksNum = resultData['marks'] as num?;
            marks = marksNum?.toInt() ?? 0; // Convert num? to int, default to 0 if null
            examResultDocId = doc.id; // Use the ID of the matching document
            print("  Student: $studentName, Fetched Marks (as num): $marksNum, Using Marks (as int): $marks, DocId: $examResultDocId");
            break; // Found the matching subject, no need to check further docs
          } else {
             print("  Student: $studentName, Found record for term, but subject mismatch. Expected: '$subjectToQuery', Found: '$fetchedSubject'. Checking next doc...");
          }
          // --- End Subject Verification ---
        }

        if (!subjectFound) {
           print("  Student: $studentName, Marks: No record found for subject '$subjectToQuery' in term ${_selectedTerm!.name} after checking all fetched docs.");
           // Keep marks = 0 and examResultDocId = null
        }
        tempData.add(_ExamResultData(
          studentId: studentId,
          studentName: studentName,
          photoUrl: photoUrl,
          currentMarks: marks,
          examResultDocId: examResultDocId,
        ));
      }

      setState(() {
        _examResultsList = tempData;
        _isLoadingResults = false;
      });
      print("Finished fetching exam results data.");

    } catch (e) {
      print("Error fetching exam results data: $e");
      setState(() {
        _errorMessage = "Error loading exam results.";
        _isLoadingResults = false;
      });
    }
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
      if (_isEditing) {
        // Store original marks when entering edit mode
        _originalMarksMap = {
          for (var result in _examResultsList)
            result.studentId: result.currentMarks
        };
      } else {
        // Restore original marks if cancelling edit
        for (var result in _examResultsList) {
          result.currentMarks = _originalMarksMap[result.studentId] ?? result.currentMarks;
          result.marksController.text = result.currentMarks.toString();
        }
        _originalMarksMap = {}; // Clear stored originals
      }
    });
  }

  Future<void> _saveExamResults() async {
    if (_selectedTerm == null || _selectedSubject == null) {
       _showSnackbar("Please select Term and Subject.", isError: true);
       return;
    }

    setState(() => _isLoadingResults = true); // Use loading state during save

    final String? adminUid = AuthController.instance.user?.uid;
     if (adminUid == null) {
       print("Error: Admin UID is null. Cannot save exam results.");
       _showSnackbar("Error: Could not verify admin.", isError: true);
       setState(() => _isLoadingResults = false);
       return;
     }

    final batch = FirebaseFirestore.instance.batch();
    // final adminUid = AuthController.instance.user?.uid ?? 'unknown_admin'; // Already fetched
    final now = Timestamp.now();
    bool changesMade = false;

    try {
      for (var result in _examResultsList) {
        final newMarksStr = result.marksController.text.trim();
        final newMarks = int.tryParse(newMarksStr);

        if (newMarks == null) {
          print("Invalid marks input for ${result.studentName}: '$newMarksStr'");
          continue; // Skip invalid input
        }

        final originalMarks = _originalMarksMap[result.studentId] ?? 0;

        // Only save if marks actually changed
        if (newMarks != originalMarks) {
          changesMade = true;
          // Reference the nested examResults collection correctly
          final examCollection = FirebaseFirestore.instance
              .collection('admins')
              .doc(adminUid)
              .collection('students')
              .doc(result.studentId)
              .collection('examResults');

          final dataToSave = {
            'term': _selectedTerm!.id,
            'subject': _selectedSubject!,
            'marks': newMarks,
            'maxMarks': 100, // Assuming max marks is 100, adjust if needed
            'resultDate': now, // Or use a specific date if required
            'updatedBy': adminUid,
            'updatedAt': now,
          };

          if (result.examResultDocId != null) {
            // Update existing document
            batch.update(examCollection.doc(result.examResultDocId), dataToSave);
            print("Updating marks for ${result.studentName} to $newMarks");
          } else {
            // Create new document
            batch.set(examCollection.doc(), dataToSave); // Let Firestore generate ID
             print("Creating marks record for ${result.studentName} with $newMarks");
          }
          result.currentMarks = newMarks; // Update local state immediately
        }
      }

      if (changesMade) {
        await batch.commit();
        print("Exam results saved successfully.");
        _showSnackbar("Exam results saved successfully!", isError: false);
      } else {
         print("No changes detected to save.");
         _showSnackbar("No changes detected.", isError: false, isInfo: true);
      }

    } catch (e) {
      print("Error saving exam results: $e");
      _showSnackbar("Error saving exam results.", isError: true);
    } finally {
      setState(() {
        _isLoadingResults = false;
        _isEditing = false; // Exit edit mode after save/cancel
        _originalMarksMap = {}; // Clear original marks map
      });
      // Refetch to get updated doc IDs if new records were created
      if (changesMade) _fetchExamResults();
    }
  }

  // Renamed from _shareExamResults
  Future<void> _exportResultsAsExcel() async {
     if (_selectedClassSection == null || _selectedSubject == null || _selectedTerm == null || _examResultsList.isEmpty) {
       _showSnackbar('Please select class, term, subject with data to export.', isError: true, isInfo: true);
       return;
     }

     setState(() => _isLoadingResults = true);

     try {
       final excel = ex.Excel.createExcel();
       final ex.Sheet sheet = excel[excel.getDefaultSheet()!];

       // Header Row
       sheet.appendRow([
         ex.TextCellValue('Student Name'),
         ex.TextCellValue('Marks'),
         ex.TextCellValue('Subject'),
         ex.TextCellValue('Term'),
         ex.TextCellValue('Class'),
       ]);

       // Data Rows
       for (var record in _examResultsList) {
         sheet.appendRow([
           ex.TextCellValue(record.studentName),
           ex.IntCellValue(record.currentMarks), // Use IntCellValue for numbers
           ex.TextCellValue(_selectedSubject!),
           ex.TextCellValue(_selectedTerm!.name),
           ex.TextCellValue(_selectedClassSection!),
         ]);
       }

       final directory = await getTemporaryDirectory();
       final filePath = '${directory.path}/ExamResults_${_selectedClassSection!.replaceAll(' - ', '_')}_${_selectedSubject}_${_selectedTerm!.name.replaceAll(' ', '_')}.xlsx';

       final fileBytes = excel.save();
       if (fileBytes != null) {
         final file = File(filePath);
         await file.writeAsBytes(fileBytes, flush: true);
         print('Excel file saved to: $filePath');

         final result = await Share.shareXFiles(
             [XFile(filePath)],
             text: 'Exam Results for $_selectedClassSection - $_selectedSubject (${_selectedTerm!.name})'
         );

         if (result.status == ShareResultStatus.success) {
            print('Shared successfully!');
            _showSnackbar('Exam results exported and shared successfully!', isError: false);
         } else {
            print('Sharing failed or dismissed: ${result.status}');
            _showSnackbar('Sharing failed or was cancelled.', isError: false, isInfo: true);
         }

       } else {
         throw Exception("Failed to save Excel file bytes.");
       }

     } catch (e) {
       print("Error generating or sharing Excel: $e");
       _showSnackbar('Error exporting exam results: ${e.toString()}', isError: true);
     } finally {
       setState(() => _isLoadingResults = false);
     }
   }


  // --- PDF Export ---
  Future<void> _exportResultsAsPdf() async {
    if (_selectedClassSection == null || _selectedSubject == null || _selectedTerm == null || _examResultsList.isEmpty) {
      _showSnackbar('Please select class, term, subject with data to export.', isError: true, isInfo: true);
      return;
    }

    setState(() => _isLoadingResults = true);

    final pdf = pw.Document();
    final String title = 'Exam Results: ${_selectedClassSection!} - ${_selectedSubject!} (${_selectedTerm!.name})';

    // --- Load Font Data ---
    // Load font data from the declared assets path
    final fontData = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
    final boldFontData = await rootBundle.load("assets/fonts/Roboto-Bold.ttf");
    final ttf = pw.Font.ttf(fontData);
    final boldTtf = pw.Font.ttf(boldFontData);
    // --- End Font Loading ---


    // Build PDF content
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: ttf, bold: boldTtf), // Apply theme with loaded fonts
        build: (pw.Context context) => [
          pw.Header(level: 0, child: pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18))),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            headers: ['Student Name', 'Marks'],
            data: _examResultsList.map((result) => [result.studentName, result.currentMarks.toString()]).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold), // Will use boldTtf from theme
            cellAlignment: pw.Alignment.centerLeft,
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            border: pw.TableBorder.all(color: PdfColors.grey600, width: 0.5),
            cellStyle: const pw.TextStyle(fontSize: 10), // Will use ttf from theme
            columnWidths: {
              0: const pw.FlexColumnWidth(3), // Name column wider
              1: const pw.FlexColumnWidth(1), // Marks column narrower
            },
          ),
        ],
      ),
    );

    try {
      // Use printing package to share
      await Printing.sharePdf(bytes: await pdf.save(), filename: '${title.replaceAll(' ', '_').replaceAll(':', '')}.pdf');
      _showSnackbar('PDF shared successfully!', isError: false);
    } catch (e) {
      print("Error sharing PDF: $e");
      _showSnackbar('Error sharing PDF: ${e.toString()}', isError: true);
    } finally {
      setState(() => _isLoadingResults = false);
    }
  }


  // --- Show Export Options Dialog ---
  Future<void> _showExportOptions() async {
     if (_selectedClassSection == null || _selectedSubject == null || _selectedTerm == null || _examResultsList.isEmpty) {
       _showSnackbar('Please select class, term, subject with data to export.', isError: true, isInfo: true);
       return;
     }
     if (_isEditing) {
       _showSnackbar('Please save or cancel edits before exporting.', isError: true, isInfo: true);
       return;
     }

     showDialog(
       context: context,
       builder: (BuildContext context) {
         return AlertDialog(
           title: const Text('Export Results'),
           content: const Text('Choose the export format:'),
           actions: <Widget>[
             TextButton(
               child: const Text('Excel (.xlsx)'),
               onPressed: () {
                 Navigator.of(context).pop(); // Close dialog
                 _exportResultsAsExcel();
               },
             ),
             TextButton(
               child: const Text('PDF (.pdf)'),
               onPressed: () {
                 Navigator.of(context).pop(); // Close dialog
                 _exportResultsAsPdf();
               },
             ),
             TextButton(
               child: const Text('Cancel'),
               onPressed: () {
                 Navigator.of(context).pop(); // Close dialog
               },
             ),
           ],
         );
       },
     );
   }




  void _showSnackbar(String message, {required bool isError, bool isInfo = false}) {
    // Debounce snackbar calls
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? kErrorColor : (isInfo ? Colors.blueGrey : kSuccessColor),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(kDefaultPadding),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kDefaultRadius)),
      ),
    );
  }


  // --- UI Building Methods ---

  Widget _buildProfileAvatar() {
    // Reusing the exact logic from AttendanceSummaryScreen
    final String? userId = AuthController.instance.user?.uid;
    if (userId == null) {
      return IconButton(
        icon: const Icon(Icons.account_circle_rounded, size: 30, color: kLightTextColor),
        tooltip: 'Profile Settings',
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileSettingsScreen())),
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
              // Avoid calling setState during build if error occurs rapidly
              profileWidget = const Icon(Icons.account_circle_rounded, size: 30, color: kLightTextColor);
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

  Widget _buildFilterDropdowns() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding, vertical: kDefaultPadding / 2),
      child: Row(
        children: [
          // Class/Section Dropdown
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedClassSection,
              hint: Text('Class', style: kHintTextStyle),
              isExpanded: true,
              onChanged: _isLoadingClasses ? null : _onClassSectionSelected,
              items: _availableClassSections.map((cs) => DropdownMenuItem(value: cs, child: Text(cs, overflow: TextOverflow.ellipsis))).toList(),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: kDefaultPadding),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(kDefaultRadius)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(kDefaultRadius),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(kDefaultRadius),
                  borderSide: const BorderSide(color: kPrimaryColor),
                ),
              ),
              style: kBodyTextStyle,
              dropdownColor: kSecondaryColor,
            ),
          ),
          const SizedBox(width: kDefaultPadding / 2),

          // Term Dropdown
          Expanded(
            child: DropdownButtonFormField<_ExamTerm>(
              value: _selectedTerm,
              hint: Text('Term', style: kHintTextStyle),
              isExpanded: true,
              onChanged: _isLoadingTerms ? null : _onTermSelected,
              items: _availableTerms.map((term) => DropdownMenuItem(value: term, child: Text(term.name, overflow: TextOverflow.ellipsis))).toList(),
               decoration: InputDecoration(
                 contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: kDefaultPadding),
                 border: OutlineInputBorder(borderRadius: BorderRadius.circular(kDefaultRadius)),
                 enabledBorder: OutlineInputBorder(
                   borderRadius: BorderRadius.circular(kDefaultRadius),
                   borderSide: BorderSide(color: Colors.grey.shade300),
                 ),
                 focusedBorder: OutlineInputBorder(
                   borderRadius: BorderRadius.circular(kDefaultRadius),
                   borderSide: const BorderSide(color: kPrimaryColor),
                 ),
               ),
               style: kBodyTextStyle,
               dropdownColor: kSecondaryColor,
            ),
          ),
          const SizedBox(width: kDefaultPadding / 2),

          // Subject Dropdown
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedSubject,
              hint: Text('Subject', style: kHintTextStyle),
              isExpanded: true,
              onChanged: (_isLoadingSubjects || _selectedTerm == null) ? null : _onSubjectSelected,
              items: _availableSubjects.map((sub) => DropdownMenuItem(value: sub, child: Text(sub, overflow: TextOverflow.ellipsis))).toList(),
               decoration: InputDecoration(
                 contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: kDefaultPadding),
                 border: OutlineInputBorder(borderRadius: BorderRadius.circular(kDefaultRadius)),
                 enabledBorder: OutlineInputBorder(
                   borderRadius: BorderRadius.circular(kDefaultRadius),
                   borderSide: BorderSide(color: Colors.grey.shade300),
                 ),
                 focusedBorder: OutlineInputBorder(
                   borderRadius: BorderRadius.circular(kDefaultRadius),
                   borderSide: const BorderSide(color: kPrimaryColor),
                 ),
               ),
               style: kBodyTextStyle,
               dropdownColor: kSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBar() {
    final String classText = _selectedClassSection ?? 'N/A';
    final String subjectText = _selectedSubject ?? 'N/A';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding, vertical: kDefaultPadding / 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              'Class: $classText, Subject: $subjectText',
              style: kBodyTextStyle.copyWith(color: kLightTextColor),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: kDefaultPadding),
          // Edit/Save Button
          ElevatedButton.icon(
            onPressed: (_examResultsList.isEmpty || _isLoadingResults) ? null : (_isEditing ? _saveExamResults : _toggleEdit),
            icon: Icon(_isEditing ? Icons.save_rounded : Icons.edit_rounded, size: 18),
            label: Text(_isEditing ? 'Save' : 'Edit'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding * 0.8, vertical: kDefaultPadding * 0.5),
              textStyle: kButtonTextStyle.copyWith(fontSize: 14),
            ),
          ),
          const SizedBox(width: kDefaultPadding / 2),
          // Share Button
          ElevatedButton(
            onPressed: (_examResultsList.isEmpty || _isLoadingResults || _isEditing) ? null : _showExportOptions, // Updated call
            style: ElevatedButton.styleFrom(
              backgroundColor: kSecondaryColor,
              foregroundColor: kPrimaryColor,
              padding: const EdgeInsets.all(kDefaultPadding * 0.6),
              shape: const CircleBorder(),
              elevation: 1,
            ),
            child: const Icon(Icons.share_rounded, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsTable() {
    if (_isLoadingResults) {
      return const Center(child: CircularProgressIndicator(color: kPrimaryColor));
    }
    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!, style: kBodyTextStyle.copyWith(color: kErrorColor)));
    }
    if (_selectedClassSection == null || _selectedSubject == null || _selectedTerm == null) {
       return Center(child: Text('Please select Class, Term, and Subject.', style: kHintTextStyle));
    }
     if (_examResultsList.isEmpty) {
       return Center(child: Text('No students found or no results for this selection.', style: kHintTextStyle));
     }

    return Expanded(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
          child: DataTable(
            columnSpacing: kDefaultPadding,
            headingRowColor: WidgetStateProperty.all(kPrimaryColor.withOpacity(0.1)),
            dataRowMinHeight: 50,
            dataRowMaxHeight: 60,
            border: TableBorder.all(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(kDefaultRadius / 2),
            ),
            columns: [
              DataColumn(label: Text('Name', style: kSubheadlineStyle.copyWith(fontSize: 14))),
              DataColumn(label: Text('Marks', style: kSubheadlineStyle.copyWith(fontSize: 14)), numeric: true),
            ],
            rows: _examResultsList.map((result) {
              return DataRow(
                cells: [
                  DataCell(Text(result.studentName, style: kBodyTextStyle)),
                  DataCell(
                    _isEditing
                        ? TextFormField(
                            controller: result.marksController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            textAlign: TextAlign.center,
                            style: kBodyTextStyle,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(kDefaultRadius / 2)),
                              isDense: true,
                            ),
                            onFieldSubmitted: (_) => _saveExamResults(), // Optional: Save on enter
                          )
                        : Text(result.currentMarks.toString(), style: kBodyTextStyle, textAlign: TextAlign.center),
                    showEditIcon: false, // We use the main Edit button
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kLightTextColor),
          tooltip: 'Back',
          onPressed: () {
             if (_isEditing) {
               _showSnackbar("Please save or cancel edits before navigating.", isError: true, isInfo: true);
               return;
             }
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              // Navigate to Dashboard if cannot pop (e.g., deep linked)
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
            }
          },
        ),
        title: Text('Exam Results', style: textTheme.titleLarge), // Updated title
        centerTitle: true,
        actions: [
          _buildProfileAvatar(),
        ],
      ),
      body: Column(
        children: [
          _buildFilterDropdowns(),
          _buildInfoBar(),
          const Divider(height: 1, thickness: 1),
          _buildResultsTable(),
        ],
      ),
      // Bottom Navigation Bar Removed
    );
  }
}