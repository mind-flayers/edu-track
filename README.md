# edu_track

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

Generate the Flutter/Dart code for the `DashboardScreen` widget within a mobile admin application for a Student & Teacher Management System built using Flutter, Dart, and Firebase. This app is for admin use only. Assume the following screens are already created: `LaunchingScreen`, `SignInScreen`, `ResetPasswordScreen`. The `DashboardScreen` should be clean, modern, and use dummy data for now. Implement the UI precisely based on the following structure and functionality:

1.  **`Scaffold` Structure:**
    *   **`AppBar` (Top Bar):**
        *   `leading`: An `IconButton` with a QR code icon (`Icons.qr_code_scanner` or similar) that navigates to `QRCodeScannerScreen` when tapped.
        *   `title`: A `Text` widget displaying a placeholder name like "My Academy".
        *   `actions`: A `CircleAvatar` or `IconButton` representing a profile picture that navigates to `ProfileSettingsScreen` when tapped.
    *   **`body` (Content Section):**
        *   Apply appropriate `Padding`.
        *   **Summary Widgets:** Arrange four distinct widgets (e.g., using `Card` or styled `Container` within a `Row` or `GridView`) displaying:
            *   "Total Students": Show a dummy count (e.g., 50). Make this widget tappable (`InkWell`/`GestureDetector`) to navigate to `StudentListScreen`.
            *   "Total Teachers": Show a dummy count (e.g., 10). Make this widget tappable to navigate to `TeacherListScreen`.
            *   "Today's Attendance": Show a dummy value (e.g., "85%"). Make this widget tappable to navigate to `AttendanceSummaryScreen`.
            *   "Pending Fees": Show a dummy value (e.g., "$500"). This widget should *not* be tappable.
        *   **Action Buttons:** Below the summary widgets, include three distinct `ElevatedButton` widgets, likely arranged in a `Column` with spacing:
            *   "Add Student": Navigates to `AddStudentScreen` on tap.
            *   "Add Teacher": Navigates to `AddTeacherScreen` on tap.
            *   "Scan QR Code": Navigates to `QRCodeScannerScreen` on tap.
    *   **`BottomNavigationBar` (Bottom Bar):**
        *   Implement a `BottomNavigationBar` with the following items:
            *   **Dashboard:** Icon (`Icons.dashboard`), Label "Dashboard". Navigates to `DashboardScreen` (this should be the active/selected item).
            *   **Students:** Icon (`Icons.people`), Label "Students". Navigates to `StudentListScreen`.
            *   **Teachers:** Icon (`Icons.person_pin`), Label "Teachers". Navigates to `TeacherListScreen`.
            *   **Attendance:** Icon (`Icons.event_available`), Label "Attendance". Navigates to `AttendanceSummaryScreen`.
            *   **Logout:** Icon (`Icons.logout`), Label "Logout". Implement basic tap functionality (e.g., print a message "Logout Tapped" or navigate back to `SignInScreen`).
        *   Ensure the correct item (`Dashboard`) is highlighted as active.

Use standard Flutter Material widgets. Implement navigation using placeholder functions like `Navigator.pushNamed(context, '/screenName')` or `Navigator.push(context, MaterialPageRoute(builder: (_) => ScreenName()))` for the specified target screens (`QRCodeScannerScreen`, `ProfileSettingsScreen`, `StudentListScreen`, `TeacherListScreen`, `AttendanceSummaryScreen`, `AddStudentScreen`, `AddTeacherScreen`, `SignInScreen`). Define placeholder widgets/classes for these target screens if needed for navigation to compile. Focus on creating the described UI layout exactly as in the picture I provided and static functionality with dummy data.