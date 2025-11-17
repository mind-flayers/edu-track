import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edu_track/app/features/authentication/controllers/auth_controller.dart';
import 'package:edu_track/app/features/profile/screens/profile_settings_screen.dart';
import 'package:edu_track/app/features/dashboard/screens/dashboard_screen.dart';
import 'package:edu_track/app/features/students/screens/student_list_screen.dart';
import 'package:edu_track/app/features/teachers/screens/teacher_list_screen.dart';
import 'package:edu_track/app/features/attendance/screens/attendance_summary_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:edu_track/app/utils/constants.dart';
import 'package:edu_track/main.dart'; // Import main for AppRoutes
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart' as ex;
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:flutter/services.dart'
    show
        FilteringTextInputFormatter,
        rootBundle; // Needed for input formatters and font loading
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
  int _selectedIndex = 4; // Exam Results is at index 4
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
          .map((doc) => doc.data()['class'] as String?)
          .where((className) => className != null && className.isNotEmpty)
          .cast<String>()
          .toSet() // Use Set for uniqueness
          .toList();
      classSections.sort((a, b) {
        // Extract grade number from "Grade X - Section" format
        final aMatch = RegExp(r'Grade (\d+)').firstMatch(a);
        final bMatch = RegExp(r'Grade (\d+)').firstMatch(b);
        if (aMatch != null && bMatch != null) {
          final aNum = int.parse(aMatch.group(1)!);
          final bNum = int.parse(bMatch.group(1)!);
          if (aNum != bNum) return aNum.compareTo(bNum);
        }
        // If grades are same or parsing failed, sort by full string
        return a.compareTo(b);
      });
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
        final subjectsList =
            (data['subjects'] as List<dynamic>?)?.cast<String>() ?? [];
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

    // Load subjects from the selected term immediately
    setState(() {
      _availableSubjects = _selectedTerm?.subjects ?? [];
      _availableSubjects.sort();
      _isLoadingSubjects = false;
    });
  }

  Future<void> _showCreateTermDialog() async {
    final nameController = TextEditingController();
    DateTime? startDate;
    DateTime? endDate;
    final List<String> allSubjects = [
      'Mathematics',
      'Science',
      'English',
      'History',
      'ICT',
      'Tamil',
      'Sinhala',
      'Commerce'
    ];
    final Set<String> selectedSubjects = {};
    final formKey = GlobalKey<FormState>();

    // Try to fetch subjects from academy settings
    try {
      final String? adminUid = AuthController.instance.user?.uid;
      if (adminUid != null) {
        final subjectsDoc = await FirebaseFirestore.instance
            .collection('admins')
            .doc(adminUid)
            .collection('academySettings')
            .doc('subjects')
            .get();
        if (subjectsDoc.exists) {
          final data = subjectsDoc.data();
          if (data != null && data.containsKey('subjects')) {
            final List<dynamic> subjectsData =
                data['subjects'] as List<dynamic>;
            allSubjects.clear();
            allSubjects.addAll(subjectsData.map((s) => s.toString()).toList());
          }
        }
      }
    } catch (e) {
      print('Error fetching academy subjects: $e');
    }

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(kDefaultRadius),
              ),
              title: Row(
                children: [
                  Icon(Icons.event_note, color: kPrimaryColor, size: 24),
                  const SizedBox(width: kDefaultPadding * 0.5),
                  const Text('Create Exam Term'),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Term Name
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Term Name *',
                          hintText: 'e.g., First Term - 2025',
                          prefixIcon: Icon(Icons.edit),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter term name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: kDefaultPadding),

                      // Start Date
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setDialogState(() {
                              startDate = picked;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Start Date *',
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            startDate != null
                                ? '${startDate!.day}/${startDate!.month}/${startDate!.year}'
                                : 'Select start date',
                            style: TextStyle(
                              color: startDate != null
                                  ? Colors.black
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: kDefaultPadding),

                      // End Date
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: startDate ?? DateTime.now(),
                            firstDate: startDate ?? DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setDialogState(() {
                              endDate = picked;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'End Date *',
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            endDate != null
                                ? '${endDate!.day}/${endDate!.month}/${endDate!.year}'
                                : 'Select end date',
                            style: TextStyle(
                              color:
                                  endDate != null ? Colors.black : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: kDefaultPadding),

                      // Subjects Selection Header
                      const Text(
                        'Select Subjects *',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: kDefaultPadding * 0.5),

                      // Subjects List with Fixed Height
                      Flexible(
                        child: Container(
                          constraints: const BoxConstraints(maxHeight: 200),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(kDefaultRadius),
                          ),
                          child: ListView(
                            shrinkWrap: true,
                            children: allSubjects.map((subject) {
                              return CheckboxListTile(
                                title: Text(subject),
                                value: selectedSubjects.contains(subject),
                                onChanged: (bool? value) {
                                  setDialogState(() {
                                    if (value == true) {
                                      selectedSubjects.add(subject);
                                    } else {
                                      selectedSubjects.remove(subject);
                                    }
                                  });
                                },
                                dense: true,
                                activeColor: kPrimaryColor,
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: kDefaultPadding * 0.5),
                      Text(
                        '${selectedSubjects.length} subjects selected',
                        style: TextStyle(
                          fontSize: 12,
                          color: selectedSubjects.isEmpty
                              ? kErrorColor
                              : kPrimaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      if (startDate == null) {
                        _showSnackbar('Please select start date',
                            isError: true);
                        return;
                      }
                      if (endDate == null) {
                        _showSnackbar('Please select end date', isError: true);
                        return;
                      }
                      if (startDate!.isAfter(endDate!)) {
                        _showSnackbar('Start date must be before end date',
                            isError: true);
                        return;
                      }
                      if (selectedSubjects.isEmpty) {
                        _showSnackbar('Please select at least one subject',
                            isError: true);
                        return;
                      }
                      Navigator.of(dialogContext).pop(true);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      await _createExamTerm(
        nameController.text.trim(),
        startDate!,
        endDate!,
        selectedSubjects.toList(),
      );
    }
  }

  Future<void> _createExamTerm(
    String name,
    DateTime startDate,
    DateTime endDate,
    List<String> subjects,
  ) async {
    final String? adminUid = AuthController.instance.user?.uid;
    if (adminUid == null) {
      _showSnackbar('Error: Could not verify admin.', isError: true);
      return;
    }

    setState(() => _isLoadingTerms = true);

    try {
      final docRef = await FirebaseFirestore.instance
          .collection('admins')
          .doc(adminUid)
          .collection('examTerms')
          .add({
        'name': name,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'subjects': subjects,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': adminUid,
      });

      _showSnackbar('Exam term created successfully!', isError: false);

      // Refresh terms list
      await _fetchTerms();

      // Auto-select the newly created term
      final newTerm = _availableTerms.firstWhere(
        (term) => term.id == docRef.id,
        orElse: () => _availableTerms.last,
      );
      _onTermSelected(newTerm);
    } catch (e) {
      print('Error creating exam term: $e');
      _showSnackbar('Error creating exam term: $e', isError: true);
    } finally {
      setState(() => _isLoadingTerms = false);
    }
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

    if (_selectedClassSection == null ||
        _selectedSubject == null ||
        _selectedTerm == null) {
      setState(() => _examResultsList = []);
      return;
    }

    setState(() {
      _isLoadingResults = true;
      _errorMessage = null;
      _examResultsList = [];
      _isEditing = false; // Ensure edit mode is off when fetching new data
    });

    final className = _selectedClassSection!;

    print(
        "Fetching Exam Results for Class: $className, Subject: $_selectedSubject, Term: ${_selectedTerm!.name}");

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
        // The seed data uses different keys for chosen subjects (note: 'Subjects' capitalized in populate script).
        final List<dynamic> subjectsRaw = (studentData['Subjects'] ??
                studentData['subjectsChoosed'] ??
                studentData['subjects']) as List<dynamic>? ??
            [];
        // Trim strings during mapping for robust comparison
        final List<String> subjectsChoosed =
            subjectsRaw.map((s) => s.toString().trim()).toList();

        // Use case-insensitive comparison to be more robust
        final selectedSubjectTrimmed = _selectedSubject?.trim() ?? '';
        final selectedSubjectLower = selectedSubjectTrimmed.toLowerCase();
        final subjectsLower =
            subjectsChoosed.map((s) => s.toLowerCase()).toList();

        // Add detailed debug prints
        print(
            "  Checking student: ${studentData['name']}, Subjects List: $subjectsChoosed, Selected Subject: '$selectedSubjectTrimmed'");

        // Ensure selected subject is not null and that the student takes it
        if (selectedSubjectTrimmed.isEmpty ||
            !subjectsLower.contains(selectedSubjectLower)) {
          print(
              "  Student: ${studentData['name']} skipped (doesn't take '$selectedSubjectTrimmed')");
          continue; // Skip this student if they don't take the selected subject
        }
        // --- End in-app filtering ---

        final studentName = studentData['name'] as String? ?? 'Unknown Name';
        final photoUrl = studentData['photoUrl'] as String?;

        // Prepare query values
        final String subjectToQuery = selectedSubjectTrimmed;
        final String termIdToQuery =
            _selectedTerm!.id; // DB stores term as document ID

        print(
            "  Querying examResults for studentId: $studentId, termId: '$termIdToQuery', subject: '$subjectToQuery'");

        // Query by term document ID (this is how populate_database.js stores it)
        var examResultSnapshot = await FirebaseFirestore.instance
            .collection('admins')
            .doc(adminUid)
            .collection('students')
            .doc(studentId)
            .collection('examResults')
            .where('term', isEqualTo: termIdToQuery)
            .where('subject', isEqualTo: subjectToQuery)
            .limit(1)
            .get();

        int marks = 0; // Default marks
        String? examResultDocId;

        if (examResultSnapshot.docs.isNotEmpty) {
          final doc = examResultSnapshot.docs.first;
          final resultData = doc.data();
          final num? marksNum = resultData['marks'] as num?;
          marks = marksNum?.toInt() ?? 0;
          examResultDocId = doc.id;
          print(
              "  Student: $studentName, Found marks: $marks (docId: $examResultDocId)");
        } else {
          print(
              "  Student: $studentName, No examResult doc found for termId='$termIdToQuery' and subject='$subjectToQuery'");
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
          result.currentMarks =
              _originalMarksMap[result.studentId] ?? result.currentMarks;
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
          print(
              "Invalid marks input for ${result.studentName}: '$newMarksStr'");
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

          // Store the exam term document ID in the 'term' field (matches populate_database.js)
          final dataToSave = {
            'term': _selectedTerm!.id, // Store term document ID only
            'subject': _selectedSubject!,
            'marks': newMarks,
            'maxMarks': 100, // Assuming max marks is 100, adjust if needed
            'resultDate': now, // Or use a specific date if required
            'updatedBy': adminUid,
            'updatedAt': now,
          };

          if (result.examResultDocId != null) {
            // Update existing document
            batch.update(
                examCollection.doc(result.examResultDocId), dataToSave);
            print("Updating marks for ${result.studentName} to $newMarks");
          } else {
            // Create new document
            batch.set(
                examCollection.doc(), dataToSave); // Let Firestore generate ID
            print(
                "Creating marks record for ${result.studentName} with $newMarks");
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
    if (_selectedClassSection == null ||
        _selectedSubject == null ||
        _selectedTerm == null ||
        _examResultsList.isEmpty) {
      _showSnackbar('Please select class, term, subject with data to export.',
          isError: true, isInfo: true);
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
      final filePath =
          '${directory.path}/ExamResults_${_selectedClassSection!.replaceAll(' - ', '_')}_${_selectedSubject}_${_selectedTerm!.name.replaceAll(' ', '_')}.xlsx';

      final fileBytes = excel.save();
      if (fileBytes != null) {
        final file = File(filePath);
        await file.writeAsBytes(fileBytes, flush: true);
        print('Excel file saved to: $filePath');

        final result = await Share.shareXFiles([XFile(filePath)],
            text:
                'Exam Results for $_selectedClassSection - $_selectedSubject (${_selectedTerm!.name})');

        if (result.status == ShareResultStatus.success) {
          print('Shared successfully!');
          _showSnackbar('Exam results exported and shared successfully!',
              isError: false);
        } else {
          print('Sharing failed or dismissed: ${result.status}');
          _showSnackbar('Sharing failed or was cancelled.',
              isError: false, isInfo: true);
        }
      } else {
        throw Exception("Failed to save Excel file bytes.");
      }
    } catch (e) {
      print("Error generating or sharing Excel: $e");
      _showSnackbar('Error exporting exam results: ${e.toString()}',
          isError: true);
    } finally {
      setState(() => _isLoadingResults = false);
    }
  }

  // --- PDF Export ---
  Future<void> _exportResultsAsPdf() async {
    if (_selectedClassSection == null ||
        _selectedSubject == null ||
        _selectedTerm == null ||
        _examResultsList.isEmpty) {
      _showSnackbar('Please select class, term, subject with data to export.',
          isError: true, isInfo: true);
      return;
    }

    setState(() => _isLoadingResults = true);

    final pdf = pw.Document();

    // Try to fetch academyName from admin profile similar to attendance
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
    }

    final fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
    final boldFontData = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
    final ttf = pw.Font.ttf(fontData);
    final boldTtf = pw.Font.ttf(boldFontData);

    // Prepare table data
    List<List<String>> tableData = [
      ['Student Name', 'Marks'],
    ];
    for (var result in _examResultsList) {
      tableData.add([result.studentName, result.currentMarks.toString()]);
    }

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      theme: pw.ThemeData.withFont(base: ttf, bold: boldTtf),
      header: (pw.Context context) {
        return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                  child: pw.Text(academyName,
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 22))),
              pw.SizedBox(height: 6),
              pw.Center(
                  child: pw.Text('Exam Results',
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 16))),
              pw.SizedBox(height: 8),
              pw.Text('Class: ${_selectedClassSection ?? ''}',
                  style: pw.TextStyle(fontSize: 12)),
              pw.Text('Subject: ${_selectedSubject ?? ''}',
                  style: pw.TextStyle(fontSize: 12)),
              pw.Text('Term: ${_selectedTerm?.name ?? ''}',
                  style: pw.TextStyle(fontSize: 12)),
              pw.SizedBox(height: 8),
            ]);
      },
      footer: (pw.Context context) {
        return pw.Center(
            child: pw.Text('Generated by EduTrack',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)));
      },
      build: (pw.Context context) => [
        pw.SizedBox(height: 2),
        pw.TableHelper.fromTextArray(
          context: null,
          cellAlignment: pw.Alignment.centerLeft,
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          cellStyle: const pw.TextStyle(fontSize: 10),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          data: tableData,
          columnWidths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(1)
          },
        ),
      ],
    ));

    final sanitizedClass = (_selectedClassSection ?? '')
        .replaceAll(RegExp(r'[\\/*?:"<>|]'), '_')
        .replaceAll(' ', '_');
    final sanitizedSubject = (_selectedSubject ?? '')
        .replaceAll(RegExp(r'[\\/*?:"<>|]'), '_')
        .replaceAll(' ', '_');
    final fileName =
        'Exam_${sanitizedClass}_${sanitizedSubject}_${_selectedTerm?.name.replaceAll(' ', '_') ?? ''}.pdf';

    try {
      await Printing.sharePdf(bytes: await pdf.save(), filename: fileName);
      _showSnackbar('PDF ready to be shared.', isError: false);
    } catch (e) {
      print('Error sharing PDF: $e');
      _showSnackbar('Error sharing PDF: $e', isError: true);
    } finally {
      setState(() => _isLoadingResults = false);
    }
  }

  // --- Show Export Options Dialog ---
  Future<void> _showExportOptions() async {
    if (_selectedClassSection == null ||
        _selectedSubject == null ||
        _selectedTerm == null ||
        _examResultsList.isEmpty) {
      _showSnackbar('Please select class, term, subject with data to export.',
          isError: true, isInfo: true);
      return;
    }
    if (_isEditing) {
      _showSnackbar('Please save or cancel edits before exporting.',
          isError: true, isInfo: true);
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

  void _showSnackbar(String message,
      {required bool isError, bool isInfo = false}) {
    // Debounce snackbar calls
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? kErrorColor : (isInfo ? Colors.blueGrey : kSuccessColor),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(kDefaultPadding),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kDefaultRadius)),
      ),
    );
  }

  // --- UI Building Methods ---

  Widget _buildProfileAvatar() {
    // Reusing the exact logic from AttendanceSummaryScreen
    final String? userId = AuthController.instance.user?.uid;
    if (userId == null) {
      return IconButton(
        icon: const Icon(Icons.account_circle_rounded,
            size: 30, color: kLightTextColor),
        tooltip: 'Profile Settings',
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ProfileSettingsScreen())),
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
              // Avoid calling setState during build if error occurs rapidly
              profileWidget = const Icon(Icons.account_circle_rounded,
                  size: 30, color: kLightTextColor);
            },
          );
        }

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(kDefaultRadius * 2),
            onTap: () =>
                Get.toNamed(AppRoutes.profileSettings), // Use Get.toNamed
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

  Widget _buildFilterDropdowns() {
    // Recreate the same two-row layout as AttendanceSummaryScreen
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(kDefaultPadding),
      child: Column(
        children: [
          // First row: Class/Section and Term
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: kDefaultPadding * 0.75,
                      vertical: kDefaultPadding * 0.25),
                  decoration: BoxDecoration(
                    color: kSecondaryColor,
                    borderRadius: BorderRadius.circular(kDefaultRadius),
                    border: Border.all(
                        color: kPrimaryColor.withOpacity(0.4), width: 1.5),
                  ),
                  child: _isLoadingClasses
                      ? const Center(
                          child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2)))
                      : DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedClassSection,
                            isExpanded: true,
                            hint: Text('Select Class',
                                style: textTheme.bodyMedium
                                    ?.copyWith(color: kLightTextColor)),
                            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                                color: kPrimaryColor),
                            items: _availableClassSections
                                .map((cs) => DropdownMenuItem(
                                    value: cs,
                                    child:
                                        Text(cs, style: textTheme.bodyMedium)))
                                .toList(),
                            onChanged: _isLoadingClasses
                                ? null
                                : _onClassSectionSelected,
                            dropdownColor: kSecondaryColor,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: kDefaultPadding / 2),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: kDefaultPadding * 0.75,
                      vertical: kDefaultPadding * 0.25),
                  decoration: BoxDecoration(
                    color: kSecondaryColor,
                    borderRadius: BorderRadius.circular(kDefaultRadius),
                    border: Border.all(
                        color: kPrimaryColor.withOpacity(0.4), width: 1.5),
                  ),
                  child: _isLoadingTerms
                      ? const Center(
                          child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2)))
                      : Row(
                          children: [
                            Expanded(
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<_ExamTerm>(
                                  value: _selectedTerm,
                                  isExpanded: true,
                                  hint: Text('Select Term',
                                      style: textTheme.bodyMedium
                                          ?.copyWith(color: kLightTextColor)),
                                  icon: const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: kPrimaryColor),
                                  items: _availableTerms
                                      .map((term) => DropdownMenuItem(
                                          value: term,
                                          child: Text(term.name,
                                              style: textTheme.bodyMedium)))
                                      .toList(),
                                  onChanged:
                                      _isLoadingTerms ? null : _onTermSelected,
                                  dropdownColor: kSecondaryColor,
                                ),
                              ),
                            ),
                            // Create New Term Button
                            IconButton(
                              icon: Icon(Icons.add_circle_outline,
                                  color: kPrimaryColor, size: 20),
                              tooltip: 'Create New Term',
                              onPressed: _isLoadingTerms
                                  ? null
                                  : _showCreateTermDialog,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                  minWidth: 32, minHeight: 32),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: kDefaultPadding / 2),

          // Second row: Subject and Buttons (Edit / Share)
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: kDefaultPadding * 0.75,
                      vertical: kDefaultPadding * 0.25),
                  decoration: BoxDecoration(
                    color: kSecondaryColor,
                    borderRadius: BorderRadius.circular(kDefaultRadius),
                    border: Border.all(
                        color: kPrimaryColor.withOpacity(0.4), width: 1.5),
                  ),
                  child: _isLoadingSubjects
                      ? const Center(
                          child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2)))
                      : DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedSubject,
                            isExpanded: true,
                            hint: Text('Select Subject',
                                style: textTheme.bodyMedium
                                    ?.copyWith(color: kLightTextColor)),
                            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                                color: kPrimaryColor),
                            items: _availableSubjects
                                .map((sub) => DropdownMenuItem(
                                    value: sub,
                                    child:
                                        Text(sub, style: textTheme.bodyMedium)))
                                .toList(),
                            onChanged:
                                (_isLoadingSubjects || _selectedTerm == null)
                                    ? null
                                    : _onSubjectSelected,
                            dropdownColor: kSecondaryColor,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: kDefaultPadding / 2),

              // Edit Button
              Expanded(
                child: ElevatedButton(
                  onPressed: (_examResultsList.isEmpty || _isLoadingResults)
                      ? null
                      : (_isEditing ? _saveExamResults : _toggleEdit),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(kDefaultRadius),
                    ),
                    minimumSize: const Size(50, 50),
                    padding: EdgeInsets.zero,
                    backgroundColor: _isEditing ? kSuccessColor : kPrimaryColor,
                    foregroundColor: Colors.white,
                    elevation: 3,
                  ),
                  child: Icon(
                      _isEditing ? Icons.save_rounded : Icons.edit_rounded,
                      size: 24),
                ),
              ),
              const SizedBox(width: kDefaultPadding / 2),
              // Share Button
              Expanded(
                child: ElevatedButton(
                  onPressed: (_examResultsList.isEmpty ||
                          _isLoadingResults ||
                          _isEditing)
                      ? null
                      : _showExportOptions,
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
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultsTable() {
    final textTheme = Theme.of(context).textTheme;

    return Expanded(
      child: Builder(builder: (context) {
        if (_isLoadingResults) {
          return const Center(
              child: CircularProgressIndicator(color: kPrimaryColor));
        }
        if (_errorMessage != null) {
          return Center(
              child: Text(_errorMessage!,
                  style: kBodyTextStyle.copyWith(color: kErrorColor)));
        }

        // Show specific selection prompts similar to AttendanceSummaryScreen
        if (_selectedClassSection == null) {
          return Center(
              child: Text('Please select a class to view exam results.',
                  style:
                      textTheme.bodyMedium?.copyWith(color: kLightTextColor)));
        }
        if (_selectedTerm == null) {
          return Center(
              child: Text('Please select a term to view exam results.',
                  style:
                      textTheme.bodyMedium?.copyWith(color: kLightTextColor)));
        }
        if (_selectedSubject == null) {
          return Center(
              child: Text('Please select a subject to view exam results.',
                  style:
                      textTheme.bodyMedium?.copyWith(color: kLightTextColor)));
        }

        if (_examResultsList.isEmpty) {
          final message =
              'No students found for $_selectedClassSection in $_selectedSubject\nor no exam results for ${_selectedTerm?.name}.';
          return Center(
              child: Text(message,
                  textAlign: TextAlign.center,
                  style:
                      textTheme.bodyMedium?.copyWith(color: kLightTextColor)));
        }

        // Build a banner like AttendanceSummaryScreen
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: kDefaultPadding, vertical: kDefaultPadding / 2),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: kDefaultPadding,
                    vertical: kDefaultPadding / 1.4),
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
                      '${_selectedClassSection ?? 'N/A'}  •  ${_selectedSubject ?? 'N/A'}  •  ${_selectedTerm?.name ?? 'N/A'}',
                      style: textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    )),
                  ],
                ),
              ),
            ),

            // Results Table
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: kDefaultPadding),
                  child: DataTable(
                    columnSpacing: kDefaultPadding,
                    headingRowColor:
                        WidgetStateProperty.all(kPrimaryColor.withOpacity(0.1)),
                    dataRowMinHeight: 50,
                    dataRowMaxHeight: 60,
                    columns: [
                      DataColumn(
                          label: Text('Name',
                              style: kSubheadlineStyle.copyWith(fontSize: 14))),
                      DataColumn(
                          label: Text('Marks',
                              style: kSubheadlineStyle.copyWith(fontSize: 14)),
                          numeric: true),
                    ],
                    rows: _examResultsList.map((result) {
                      return DataRow(
                        cells: [
                          DataCell(
                              Text(result.studentName, style: kBodyTextStyle)),
                          DataCell(
                            _isEditing
                                ? SizedBox(
                                    width: 80,
                                    child: TextFormField(
                                      controller: result.marksController,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly
                                      ],
                                      textAlign: TextAlign.center,
                                      style: kBodyTextStyle,
                                      decoration: InputDecoration(
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                vertical: 8, horizontal: 8),
                                        border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                                kDefaultRadius / 2)),
                                        isDense: true,
                                      ),
                                      onFieldSubmitted: (_) =>
                                          _saveExamResults(),
                                    ),
                                  )
                                : Text(result.currentMarks.toString(),
                                    style: kBodyTextStyle,
                                    textAlign: TextAlign.center),
                            showEditIcon: false,
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: kLightTextColor),
          tooltip: 'Back',
          onPressed: () {
            if (_isEditing) {
              _showSnackbar("Please save or cancel edits before navigating.",
                  isError: true, isInfo: true);
              return;
            }
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              // Navigate to Dashboard if cannot pop (e.g., deep linked)
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const DashboardScreen()));
            }
          },
        ),
        title:
            Text('Exam Results', style: textTheme.titleLarge), // Updated title
        centerTitle: true,
        actions: [
          _buildProfileAvatar(),
        ],
      ),
      body: Column(
        children: [
          _buildFilterDropdowns(),
          const Divider(height: 1, thickness: 1),
          _buildResultsTable(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
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

    return BottomNavigationBar(
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
    );
  }

  void _onBottomNavItemTapped(int index) {
    if (_selectedIndex == index) return;

    // Prevent navigation if in editing mode
    if (_isEditing) {
      _showSnackbar("Please save or cancel edits before navigating.",
          isError: true, isInfo: true);
      return;
    }

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
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AttendanceSummaryScreen()));
        break;
      case 4:
        break; // Already on Exam Results Screen
    }
  }
}
