import 'package:edu_track/app/features/students/controllers/student_controller.dart';
import 'package:get/get.dart';

/// Controller for managing the main navigation state.
/// This controller persists across the app lifecycle and manages
/// which tab is currently selected in the bottom navigation bar.
class NavigationController extends GetxController {
  /// Currently selected navigation index.
  /// Default is 2 (Dashboard - center tab).
  final RxInt selectedIndex = 2.obs;

  /// Tab indices for reference:
  /// 0 - Students
  /// 1 - Teachers
  /// 2 - Dashboard (default)
  /// 3 - Attendance
  /// 4 - Exam Results

  /// Change the currently selected tab.
  void changeTab(int index) {
    if (index >= 0 && index <= 4) {
      selectedIndex.value = index;
    }
  }

  /// Navigate to Students tab
  void goToStudents() => changeTab(0);

  /// Navigate to Teachers tab
  void goToTeachers() => changeTab(1);

  /// Navigate to Dashboard tab
  void goToDashboard() => changeTab(2);

  /// Navigate to Attendance tab
  void goToAttendance() => changeTab(3);

  /// Navigate to Exam tab
  void goToExam() => changeTab(4);
}

/// Binding for NavigationController and all tab screen controllers.
/// This is used to inject controllers when navigating to MainShellScreen.
class NavigationBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(NavigationController(), permanent: true);
    // Register StudentController for StudentListScreen in the IndexedStack
    Get.lazyPut<StudentController>(() => StudentController());
  }
}
