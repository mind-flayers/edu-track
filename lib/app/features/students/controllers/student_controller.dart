import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edu_track/app/features/authentication/controllers/auth_controller.dart';
import 'package:edu_track/app/features/students/screens/student_details_screen.dart';
import 'package:edu_track/app/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Controller for the Student List feature.
/// Manages search, filtering, selection mode, and CRUD operations.
class StudentController extends GetxController {
  static StudentController get instance => Get.find();

  // ─────────────────────────────────────────────────────────────────────────────
  // REACTIVE STATE
  // ─────────────────────────────────────────────────────────────────────────────

  /// Search query for filtering students by name
  final RxString searchQuery = ''.obs;

  /// Currently selected class filter (null = All Classes)
  final RxnString selectedClass = RxnString();

  /// List of available classes for the dropdown
  final RxList<String> availableClasses = <String>[].obs;

  /// Whether selection mode (multi-select) is active
  final RxBool isSelectionMode = false.obs;

  /// Set of selected student IDs for batch operations
  final RxSet<String> selectedStudentIds = <String>{}.obs;

  /// IDs of students currently visible after filtering (for Select All)
  final RxList<String> filteredStudentIds = <String>[].obs;

  /// Loading state for async operations
  final RxBool isLoading = false.obs;

  /// Currently selected bottom nav index (0 = Students)
  final RxInt selectedNavIndex = 0.obs;

  // ─────────────────────────────────────────────────────────────────────────────
  // COMPUTED PROPERTIES
  // ─────────────────────────────────────────────────────────────────────────────

  /// Returns the current admin UID or null
  String? get adminUid => AuthController.instance.user?.uid;

  /// Check if all visible students are selected
  bool get areAllSelected {
    return filteredStudentIds.isNotEmpty &&
        selectedStudentIds.length == filteredStudentIds.length &&
        filteredStudentIds.every((id) => selectedStudentIds.contains(id));
  }

  /// Firestore reference to the students collection
  CollectionReference<Map<String, dynamic>>? get _studentsCollection {
    final uid = adminUid;
    if (uid == null) return null;
    return FirebaseFirestore.instance
        .collection('admins')
        .doc(uid)
        .collection('students');
  }

  /// Stream of all students ordered by name
  Stream<QuerySnapshot<Map<String, dynamic>>>? get studentsStream {
    return _studentsCollection?.orderBy('name').snapshots();
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // LIFECYCLE
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    fetchAvailableClasses();
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // DATA FETCHING
  // ─────────────────────────────────────────────────────────────────────────────

  /// Fetch unique class names from all students for the filter dropdown
  Future<void> fetchAvailableClasses() async {
    final uid = adminUid;
    if (uid == null) {
      print("Error: Admin UID is null. Cannot fetch classes.");
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('admins')
          .doc(uid)
          .collection('students')
          .get();

      final classes = snapshot.docs
          .map((doc) => doc.data()['class'] as String?)
          .where((className) => className != null && className.isNotEmpty)
          .whereType<String>()
          .toSet()
          .toList();

      classes.sort();
      availableClasses.value =
          classes.isEmpty ? [] : ['All Classes', ...classes];
    } catch (e) {
      print("Error fetching classes: $e");
      Get.snackbar(
        'Error',
        'Failed to load class list: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: kErrorColor.withOpacity(0.8),
        colorText: Colors.white,
        margin: const EdgeInsets.all(kDefaultPadding),
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // SEARCH & FILTER
  // ─────────────────────────────────────────────────────────────────────────────

  /// Update search query
  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }

  /// Update selected class filter
  void updateClassFilter(String? className) {
    selectedClass.value = (className == 'All Classes') ? null : className;
  }

  /// Update the list of filtered student IDs (called from UI after filtering)
  void updateFilteredStudentIds(List<String> ids) {
    if (filteredStudentIds.length != ids.length ||
        !filteredStudentIds.every((id) => ids.contains(id))) {
      filteredStudentIds.value = ids;
    }
  }

  /// Filter students based on search query and selected class
  List<QueryDocumentSnapshot<Map<String, dynamic>>> filterStudents(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> allStudents) {
    return allStudents.where((doc) {
      final data = doc.data();
      final name = (data['name'] as String? ?? '').toLowerCase();
      final studentClass = data['class'] as String?;

      final nameMatches = searchQuery.isEmpty ||
          name.contains(searchQuery.value.toLowerCase());
      final classMatches =
          selectedClass.value == null || studentClass == selectedClass.value;

      return nameMatches && classMatches;
    }).toList();
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // SELECTION MODE
  // ─────────────────────────────────────────────────────────────────────────────

  /// Enter selection mode with the first selected student
  void enterSelectionMode(String studentId) {
    print('Entering selection mode with studentId: $studentId');
    isSelectionMode.value = true;
    selectedStudentIds.add(studentId);
  }

  /// Exit selection mode and clear all selections
  void exitSelectionMode() {
    isSelectionMode.value = false;
    selectedStudentIds.clear();
  }

  /// Toggle selection state of a single student
  void toggleStudentSelection(String studentId) {
    if (selectedStudentIds.contains(studentId)) {
      selectedStudentIds.remove(studentId);
    } else {
      selectedStudentIds.add(studentId);
    }
  }

  /// Select all currently visible students
  void selectAllStudents() {
    selectedStudentIds.addAll(filteredStudentIds);
  }

  /// Deselect all students
  void deselectAllStudents() {
    selectedStudentIds.clear();
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // DELETE OPERATIONS
  // ─────────────────────────────────────────────────────────────────────────────

  /// Delete all selected students after confirmation
  Future<void> deleteSelectedStudents(BuildContext context) async {
    if (selectedStudentIds.isEmpty) {
      Get.snackbar(
        'No Selection',
        'Please select at least one student to delete.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: kErrorColor.withOpacity(0.8),
        colorText: Colors.white,
        margin: const EdgeInsets.all(kDefaultPadding),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kDefaultRadius),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: kErrorColor, size: 24),
            const SizedBox(width: kDefaultPadding * 0.5),
            const Text('Confirm Deletion'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete ${selectedStudentIds.length} student(s)?\n\nThis action cannot be undone.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: kErrorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final uid = adminUid;
    if (uid == null) {
      Get.snackbar(
        'Error',
        'Admin not authenticated.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: kErrorColor.withOpacity(0.8),
        colorText: Colors.white,
        margin: const EdgeInsets.all(kDefaultPadding),
      );
      return;
    }

    // Show loading dialog
    Get.dialog(
      const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(kDefaultPadding * 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: kDefaultPadding),
                Text('Deleting students...'),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );

    try {
      final batch = FirebaseFirestore.instance.batch();
      final collection = _studentsCollection;
      if (collection == null) throw Exception('Students collection not found');

      for (final studentId in selectedStudentIds) {
        batch.delete(collection.doc(studentId));
      }

      await batch.commit();

      // Close loading dialog
      Get.back();

      // Show success message
      Get.snackbar(
        'Success',
        '${selectedStudentIds.length} student(s) deleted successfully.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: kSuccessColor.withOpacity(0.8),
        colorText: Colors.white,
        margin: const EdgeInsets.all(kDefaultPadding),
        duration: const Duration(seconds: 3),
      );

      // Exit selection mode
      exitSelectionMode();
    } catch (e) {
      // Close loading dialog
      Get.back();

      // Show error message
      Get.snackbar(
        'Error',
        'Failed to delete students: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: kErrorColor.withOpacity(0.8),
        colorText: Colors.white,
        margin: const EdgeInsets.all(kDefaultPadding),
        duration: const Duration(seconds: 4),
      );
      print('Error deleting students: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // NAVIGATION
  // ─────────────────────────────────────────────────────────────────────────────

  /// Navigate to student details screen
  void navigateToStudentDetails(String studentId) {
    if (isSelectionMode.value) {
      toggleStudentSelection(studentId);
    } else {
      Get.to(() => StudentDetailsScreen(studentId: studentId));
    }
  }

  /// Handle bottom nav item tap
  void onBottomNavItemTapped(int index) {
    // Prevent navigation during selection mode
    if (isSelectionMode.value) return;

    // Don't rebuild if same tab
    if (selectedNavIndex.value == index) return;

    selectedNavIndex.value = index;
  }
}
