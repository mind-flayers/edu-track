import 'package:edu_track/app/features/attendance/screens/attendance_summary_screen.dart';
import 'package:edu_track/app/features/dashboard/screens/dashboard_screen.dart';
import 'package:edu_track/app/features/exam/screens/exam_results_screen.dart';
import 'package:edu_track/app/features/students/screens/student_list_screen.dart';
import 'package:edu_track/app/features/teachers/screens/teacher_list_screen.dart';
import 'package:edu_track/app/navigation/navigation_controller.dart';
import 'package:edu_track/app/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';


/// Main shell screen containing the persistent bottom navigation bar.
/// This screen wraps all main tab screens using IndexedStack to preserve
/// their state when switching between tabs.
class MainShellScreen extends StatelessWidget {
  const MainShellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final NavigationController navController = Get.find<NavigationController>();

    // Define navigation icons and labels
    final Map<int, IconData> navIcons = {
      0: Icons.school_rounded,
      1: Icons.co_present_rounded,
      2: Icons.dashboard_rounded,
      3: Icons.assignment_rounded,
      4: Icons.assessment_outlined,
    };
    final Map<int, String> navLabels = {
      0: 'Students',
      1: 'Teachers',
      2: 'Dashboard',
      3: 'Attendance',
      4: 'Exam',
    };

    return Scaffold(
      body: Obx(() => IndexedStack(
            index: navController.selectedIndex.value,
            children: const [
              // Tab 0: Students
              StudentListScreen(),
              // Tab 1: Teachers
              TeacherListScreen(),
              // Tab 2: Dashboard
              DashboardScreen(),
              // Tab 3: Attendance
              AttendanceSummaryScreen(),
              // Tab 4: Exam Results
              ExamResultsScreen(),
            ],
          )),
      bottomNavigationBar: Obx(() => BottomNavigationBar(
            items: List.generate(navIcons.length, (index) {
              bool isSelected = navController.selectedIndex.value == index;
              return BottomNavigationBarItem(
                icon: Animate(
                  target: isSelected ? 1 : 0,
                  effects: [
                    ScaleEffect(
                      begin: const Offset(0.9, 0.9),
                      end: const Offset(1.1, 1.1),
                      duration: 200.ms,
                      curve: Curves.easeOut,
                    ),
                  ],
                  child: Icon(navIcons[index]),
                ),
                label: navLabels[index],
              );
            }),
            currentIndex: navController.selectedIndex.value,
            selectedItemColor: kPrimaryColor,
            unselectedItemColor: kLightTextColor,
            onTap: navController.changeTab,
            type: BottomNavigationBarType.fixed,
            showUnselectedLabels: true,
            showSelectedLabels: true,
            selectedFontSize: 12.0,
            unselectedFontSize: 11.0,
            elevation: 10.0,
            backgroundColor: Colors.white,
          )),
    );
  }
}
