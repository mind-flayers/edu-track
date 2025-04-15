import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edu_track/app/features/attendance/screens/attendance_summary_screen.dart';
import 'package:edu_track/app/features/authentication/controllers/auth_controller.dart';
import 'package:edu_track/app/features/authentication/screens/signin_screen.dart';
import 'package:edu_track/app/features/dashboard/screens/add_exam_results_screen.dart';
import 'package:edu_track/app/features/profile/screens/profile_settings_screen.dart';
import 'package:edu_track/app/features/qr_scanner/screens/qr_code_scanner_screen.dart';
import 'package:edu_track/app/features/students/screens/add_student_screen.dart';
import 'package:edu_track/app/features/students/screens/student_list_screen.dart';
import 'package:edu_track/app/features/teachers/screens/add_teacher_screen.dart';
import 'package:edu_track/app/features/teachers/screens/teacher_list_screen.dart';
import 'package:edu_track/app/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart'; // Import intl for date formatting

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() { _selectedIndex = index; });
    if (index != 0 && index != 4) {
       Future.delayed(150.ms, () {
         if (!mounted) return;
         switch (index) {
           case 1: Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentListScreen())); setState(() => _selectedIndex = 0); break;
           case 2: Navigator.push(context, MaterialPageRoute(builder: (_) => const TeacherListScreen())); setState(() => _selectedIndex = 0); break;
           case 3: Navigator.push(context, MaterialPageRoute(builder: (_) => const AttendanceSummaryScreen())); setState(() => _selectedIndex = 0); break;
         }
       });
    } else if (index == 4) {
       print("Logout Tapped");
       Navigator.pushAndRemoveUntil( context, MaterialPageRoute(builder: (_) => const SignInScreen()), (route) => false );
    }
  }

  Widget _buildProfileAvatar() {
    final String? userId = AuthController.instance.user?.uid;
    if (userId == null) {
      return Icon(Icons.account_circle_rounded, size: 30, color: kLightTextColor);
    }
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('admins').doc(userId).snapshots(),
      builder: (context, snapshot) {
        String? photoUrl;
        Widget profileWidget = Icon(Icons.account_circle_rounded, size: 30, color: kLightTextColor);
        if (snapshot.connectionState == ConnectionState.active && snapshot.hasData && snapshot.data!.exists) {
          var data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data != null && data.containsKey('photoURL')) { photoUrl = data['photoURL'] as String?; }
        } else if (snapshot.hasError) { print("Error fetching admin profile: ${snapshot.error}"); }
        if (photoUrl != null && photoUrl.isNotEmpty) {
          profileWidget = CircleAvatar( radius: 18, backgroundColor: kLightTextColor.withOpacity(0.5), backgroundImage: NetworkImage(photoUrl), onBackgroundImageError: (exception, stackTrace) { print("Error loading profile image: $exception"); }, );
        }
        return Material( color: Colors.transparent, child: InkWell( borderRadius: BorderRadius.circular(kDefaultRadius * 2), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileSettingsScreen())), child: Padding( padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding, vertical: kDefaultPadding / 2), child: profileWidget, ), ), );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final Color lightTextColor = kLightTextColor;
    final firestore = FirebaseFirestore.instance;
    final now = DateTime.now();
    final todayDateString = DateFormat('yyyy-MM-dd').format(now);
    final currentYear = now.year;
    final currentMonth = now.month;

    final Map<int, IconData> navIcons = { 0: Icons.dashboard_rounded, 1: Icons.school_rounded, 2: Icons.co_present_rounded, 3: Icons.assignment_rounded, 4: Icons.logout_rounded };
    final Map<int, String> navLabels = { 0: 'Dashboard', 1: 'Students', 2: 'Teachers', 3: 'Attendance', 4: 'Logout' };

    return Scaffold(
      appBar: AppBar(
        leading: IconButton( icon: Icon(Icons.qr_code_rounded, color: lightTextColor, size: 26), tooltip: 'Scan QR Code', onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QRCodeScannerScreen())) ),
        title: Text("MEC Kanamoolai", style: textTheme.titleLarge), centerTitle: true,
        actions: [ _buildProfileAvatar() ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(kDefaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text("Overview", style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: kDefaultPadding / 2),
              GridView.count( crossAxisCount: 1, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: kDefaultPadding * 0.75, childAspectRatio: 5.5,
                children: [
                   // --- Total Students Card ---
                   StreamBuilder<QuerySnapshot>( stream: firestore.collection('students').snapshots(), builder: (context, snapshot) { String count = '...'; if (snapshot.hasError) { count = 'Error'; print("Error fetching students: ${snapshot.error}"); } else if (snapshot.hasData) { count = snapshot.data!.docs.length.toString(); } return _buildSummaryCard( icon: Icons.school_outlined, title: "Total Students", value: count, color1: kPrimaryColor, color2: Color(0xFF9B84FF), textColor: kSecondaryColor, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentListScreen())) ); }, ),
                   // --- Total Teachers Card ---
                   StreamBuilder<QuerySnapshot>( stream: firestore.collection('teachers').snapshots(), builder: (context, snapshot) { String count = '...'; if (snapshot.hasError) { count = 'Error'; print("Error fetching teachers: ${snapshot.error}"); } else if (snapshot.hasData) { count = snapshot.data!.docs.length.toString(); } return _buildSummaryCard( icon: Icons.co_present_outlined, title: "Total Teachers", value: count, color1: kPrimaryColor, color2: Color(0xFF9B84FF), textColor: kSecondaryColor, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TeacherListScreen())) ); }, ),
                   // --- Today Attendance Card ---
                   StreamBuilder<DocumentSnapshot>(
                     stream: firestore.collection('attendanceSummary').doc(todayDateString).snapshots(),
                     builder: (context, snapshot) {
                       Widget attendanceChild;
                       if (snapshot.connectionState == ConnectionState.waiting) {
                          attendanceChild = Text('...', style: textTheme.headlineSmall?.copyWith(color: kSecondaryColor, fontWeight: FontWeight.bold)); // Loading state
                       } else if (snapshot.hasError) {
                         attendanceChild = Text('Error', style: textTheme.headlineSmall?.copyWith(color: Colors.red.shade200, fontWeight: FontWeight.bold));
                         print("Error fetching attendance summary: ${snapshot.error}");
                       } else if (snapshot.hasData && snapshot.data!.exists) {
                         final data = snapshot.data!.data() as Map<String, dynamic>?;
                         final present = data?['present'] ?? 0;
                         final absent = data?['absent'] ?? 0;
                         // Display Present / Absent counts
                         attendanceChild = Row( mainAxisAlignment: MainAxisAlignment.end, children: [ Icon(Icons.check_circle, color: Colors.green.shade200, size: 20), const SizedBox(width: 4), Text(present.toString(), style: textTheme.headlineSmall?.copyWith(color: kSecondaryColor, fontWeight: FontWeight.bold)), const SizedBox(width: 12), Icon(Icons.cancel, color: Colors.red.shade200, size: 20), const SizedBox(width: 4), Text(absent.toString(), style: textTheme.headlineSmall?.copyWith(color: kSecondaryColor, fontWeight: FontWeight.bold)), ], );
                       } else {
                          // Display 0 / 0 if today's summary doc doesn't exist
                          attendanceChild = Row( mainAxisAlignment: MainAxisAlignment.end, children: [ Icon(Icons.check_circle, color: Colors.grey.shade400, size: 20), const SizedBox(width: 4), Text("0", style: textTheme.headlineSmall?.copyWith(color: kSecondaryColor.withOpacity(0.7), fontWeight: FontWeight.bold)), const SizedBox(width: 12), Icon(Icons.cancel, color: Colors.grey.shade400, size: 20), const SizedBox(width: 4), Text("0", style: textTheme.headlineSmall?.copyWith(color: kSecondaryColor.withOpacity(0.7), fontWeight: FontWeight.bold)), ], );
                       }
                       return _buildSummaryCard( icon: Icons.assignment_turned_in_outlined, title: "Today Attendance", customChild: attendanceChild, color1: kPrimaryColor, color2: Color(0xFF9B84FF), textColor: kSecondaryColor, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AttendanceSummaryScreen())) );
                     },
                   ),
                   // --- Pending Payments Card (Count for Current Month) ---
                   StreamBuilder<QuerySnapshot>(
                     stream: firestore.collectionGroup('fees')
                                  .where('paid', isEqualTo: false)
                                  .where('year', isEqualTo: currentYear)
                                  .where('month', isEqualTo: currentMonth)
                                  .snapshots(),
                     builder: (context, snapshot) {
                       String pendingCount = '...'; // Loading state
                       if (snapshot.hasError) {
                         pendingCount = 'Error';
                         print("Error fetching pending payments: ${snapshot.error}");
                         // ** Reminder: Check Debug Console for index creation link if this shows 'Error' **
                       } else if (snapshot.hasData) {
                         pendingCount = snapshot.data!.docs.length.toString(); // Display count
                       }
                       // Updated title and icon
                       return _buildSummaryCard( icon: Icons.request_quote_outlined, title: "Pending Payments", value: pendingCount, color1: kPrimaryColor, color2: Color(0xFF9B84FF), textColor: kSecondaryColor, onTap: null );
                     },
                   ),
                ],
              ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2, duration: 400.ms, curve: Curves.easeOut),

              const SizedBox(height: kDefaultPadding * 1.5),

              Text("Quick Actions", style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: kDefaultPadding / 2),
              GridView.count( crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisSpacing: kDefaultPadding * 0.75, mainAxisSpacing: kDefaultPadding * 0.75, childAspectRatio: 1.2,
                children: [
                  ActionButtonCard( icon: Icons.school, label: "Add Student", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddStudentScreen())) ),
                  ActionButtonCard( icon: Icons.co_present, label: "Add Teacher", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddTeacherScreen())) ),
                  ActionButtonCard( icon: Icons.qr_code_2, label: "Scan QR Code", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QRCodeScannerScreen())) ),
                  ActionButtonCard( icon: Icons.add_box_outlined, label: "Add Exam Results", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddExamResultsScreen())) ),
                ],
              ).animate().fadeIn(delay: 200.ms, duration: 500.ms).slideY(begin: 0.3, duration: 400.ms, curve: Curves.easeOut),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: List.generate(navIcons.length, (index) { bool isSelected = _selectedIndex == index; return BottomNavigationBarItem( icon: Animate( target: isSelected ? 1 : 0, effects: [ScaleEffect(begin: Offset(0.9, 0.9), end: Offset(1.1, 1.1), duration: 200.ms, curve: Curves.easeOut)], child: Icon(navIcons[index]), ), label: navLabels[index], ); }),
        currentIndex: _selectedIndex, selectedItemColor: kPrimaryColor, unselectedItemColor: kLightTextColor,
        onTap: _onItemTapped, type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true, showSelectedLabels: true,
        selectedFontSize: 12.0, unselectedFontSize: 11.0,
        elevation: 10.0, backgroundColor: Colors.white,
      ),
    );
  }

  // --- Helper Widget for Summary Cards ---
  Widget _buildSummaryCard({
    required IconData icon, required String title, String? value, Widget? customChild,
    required Color color1, required Color color2, required Color textColor, VoidCallback? onTap,
  }) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration( gradient: LinearGradient( colors: [color1, color2], begin: Alignment.topLeft, end: Alignment.bottomRight ), borderRadius: BorderRadius.circular(kDefaultRadius), boxShadow: [ BoxShadow( color: color1.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4) ) ], ),
      child: Material( color: Colors.transparent, child: InkWell( onTap: onTap, borderRadius: BorderRadius.circular(kDefaultRadius), child: Padding( padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding, vertical: kDefaultPadding * 0.8), child: Row( children: [ Icon(icon, color: textColor.withOpacity(0.8), size: 36), const SizedBox(width: kDefaultPadding), Expanded( child: Text( title, style: textTheme.titleMedium?.copyWith(color: textColor.withOpacity(0.9), fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis ), ), const SizedBox(width: kDefaultPadding), customChild ?? (value != null ? Text( value, style: textTheme.headlineMedium?.copyWith(color: textColor, fontWeight: FontWeight.bold) ) : const SizedBox.shrink()), ], ), ), ), ),
    );
  }
} // End of _DashboardScreenState

// --- StatefulWidget for Action Buttons with Hover Animation ---
class ActionButtonCard extends StatefulWidget {
  final IconData icon; final String label; final VoidCallback onTap;
  const ActionButtonCard({ super.key, required this.icon, required this.label, required this.onTap });
  @override State<ActionButtonCard> createState() => _ActionButtonCardState();
}
class _ActionButtonCardState extends State<ActionButtonCard> {
  bool _isHovering = false;
  @override Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true), onExit: (_) => setState(() => _isHovering = false),
      child: Card( color: kSecondaryColor, child: InkWell( onTap: widget.onTap, borderRadius: BorderRadius.circular(kDefaultRadius), child: Padding( padding: const EdgeInsets.all(kDefaultPadding * 0.75), child: Column( mainAxisAlignment: MainAxisAlignment.center, children: [ Icon(widget.icon, size: 32.0, color: kPrimaryColor), const SizedBox(height: kDefaultPadding * 0.5), Text( widget.label, textAlign: TextAlign.center, style: textTheme.bodySmall?.copyWith(color: kPrimaryColor, fontWeight: FontWeight.w600, height: 1.2), maxLines: 2, overflow: TextOverflow.ellipsis, ), ], ), ), ),
      ).animate(target: _isHovering ? 1.0 : 0.0).scale( duration: 150.ms, curve: Curves.easeOut, begin: const Offset(1, 1), end: const Offset(1.05, 1.05) ),
    );
  }
}