import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edu_track/app/features/attendance/screens/attendance_summary_screen.dart';
import 'package:edu_track/app/features/authentication/controllers/auth_controller.dart';
import 'package:edu_track/app/features/authentication/screens/signin_screen.dart';
import 'package:edu_track/app/features/exam/screens/exam_results_screen.dart';
import 'package:edu_track/app/features/qr_scanner/screens/qr_code_scanner_screen.dart';
import 'package:edu_track/app/features/students/screens/add_student_screen.dart';
import 'package:edu_track/app/features/students/screens/student_list_screen.dart';
import 'package:edu_track/app/features/teachers/screens/add_teacher_screen.dart';
import 'package:edu_track/app/features/teachers/screens/teacher_list_screen.dart';
import 'package:edu_track/app/utils/constants.dart';
import 'package:edu_track/main.dart'; // Import main for AppRoutes
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart'; // Import GetX
import 'package:intl/intl.dart'; // Import intl for date formatting

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 2;
  int _cachedPendingCount = 0; // Cache for pending payments count

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index != 2) {
      Future.delayed(150.ms, () {
        if (!mounted) return;
        switch (index) {
          case 0:
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const StudentListScreen()));
            setState(() => _selectedIndex = 2);
            break;
          case 1:
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const TeacherListScreen()));
            setState(() => _selectedIndex = 2);
            break;
          case 3:
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AttendanceSummaryScreen()));
            setState(() => _selectedIndex = 2);
            break;
          case 4:
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ExamResultsScreen()));
            setState(() => _selectedIndex = 2);
            break;
        }
      });
    }
  }

  Widget _buildProfileAvatar() {
    final String? userId = AuthController.instance.user?.uid;
    if (userId == null) {
      return Icon(Icons.account_circle_rounded,
          size: 30, color: kLightTextColor);
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
            size: 30, color: kLightTextColor); // Profile Icon
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
        ); // Use Get.toNamed (Already correct, ensuring consistency)
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
            icon: Icon(Icons.qr_code_rounded, color: lightTextColor, size: 26),
            tooltip: 'Scan QR Code',
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const QRCodeScannerScreen()))),
        title: Text("MEC Kanamoolai", style: textTheme.titleLarge),
        centerTitle: true,
        actions: [_buildProfileAvatar()],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(kDefaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text("Overview",
                  style: textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: kDefaultPadding / 2),
              // Use a StreamBuilder to get the auth state first
              StreamBuilder<User?>(
                stream: FirebaseAuth.instance
                    .authStateChanges(), // Use the direct auth stream
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    // Show loading indicators for all cards while checking auth state
                    return GridView.count(
                      crossAxisCount: 1,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: kDefaultPadding * 0.75,
                      childAspectRatio: 5.5,
                      children: [
                        _buildSummaryCard(
                            icon: Icons.school_outlined,
                            title: "Total Students",
                            value: '...',
                            color1: kPrimaryColor,
                            color2: const Color(0xFF9B84FF),
                            textColor: kSecondaryColor,
                            onTap: null),
                        _buildSummaryCard(
                            icon: Icons.co_present_outlined,
                            title: "Total Teachers",
                            value: '...',
                            color1: kPrimaryColor,
                            color2: const Color(0xFF9B84FF),
                            textColor: kSecondaryColor,
                            onTap: null),
                        _buildSummaryCard(
                            icon: Icons.assignment_turned_in_outlined,
                            title: "Today Attendance",
                            customChild: Text('...',
                                style: textTheme.headlineSmall?.copyWith(
                                    color: kSecondaryColor,
                                    fontWeight: FontWeight.bold)),
                            color1: kPrimaryColor,
                            color2: const Color(0xFF9B84FF),
                            textColor: kSecondaryColor,
                            onTap: null),
                        _buildSummaryCard(
                            icon: Icons.request_quote_outlined,
                            title: "Pending Payments",
                            value: '...',
                            color1: kPrimaryColor,
                            color2: const Color(0xFF9B84FF),
                            textColor: kSecondaryColor,
                            onTap: null),
                      ],
                    );
                  }

                  final String? adminUid = userSnapshot.data?.uid;

                  if (adminUid == null) {
                    // Show N/A or error state if admin is not logged in
                    return GridView.count(
                      crossAxisCount: 1,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: kDefaultPadding * 0.75,
                      childAspectRatio: 5.5,
                      children: [
                        _buildSummaryCard(
                            icon: Icons.school_outlined,
                            title: "Total Students",
                            value: 'N/A',
                            color1: kPrimaryColor,
                            color2: const Color(0xFF9B84FF),
                            textColor: kSecondaryColor,
                            onTap: null),
                        _buildSummaryCard(
                            icon: Icons.co_present_outlined,
                            title: "Total Teachers",
                            value: 'N/A',
                            color1: kPrimaryColor,
                            color2: const Color(0xFF9B84FF),
                            textColor: kSecondaryColor,
                            onTap: null),
                        _buildSummaryCard(
                            icon: Icons.assignment_turned_in_outlined,
                            title: "Today Attendance",
                            customChild: Text('N/A',
                                style: textTheme.headlineSmall?.copyWith(
                                    color: kSecondaryColor,
                                    fontWeight: FontWeight.bold)),
                            color1: kPrimaryColor,
                            color2: const Color(0xFF9B84FF),
                            textColor: kSecondaryColor,
                            onTap: null),
                        _buildSummaryCard(
                            icon: Icons.request_quote_outlined,
                            title: "Pending Payments",
                            value: 'N/A',
                            color1: kPrimaryColor,
                            color2: const Color(0xFF9B84FF),
                            textColor: kSecondaryColor,
                            onTap: null),
                      ],
                    );
                  }

                  // If adminUid is available, build the GridView with data-fetching StreamBuilders
                  // Apply animation here
                  return GridView.count(
                    crossAxisCount: 1,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: kDefaultPadding * 0.75,
                    childAspectRatio: 5.5,
                    children: [
                      // --- Total Students Card ---
                      StreamBuilder<QuerySnapshot>(
                        stream: firestore
                            .collection('admins')
                            .doc(adminUid)
                            .collection('students')
                            .snapshots(),
                        builder: (context, snapshot) {
                          String count = '...';
                          if (snapshot.hasError) {
                            count = 'Error';
                            print("Error fetching students: ${snapshot.error}");
                          } else if (snapshot.hasData) {
                            count = snapshot.data!.docs.length.toString();
                          }
                          return _buildSummaryCard(
                              icon: Icons.school_outlined,
                              title: "Total Students",
                              value: count,
                              color1: kPrimaryColor,
                              color2: const Color(0xFF9B84FF),
                              textColor: kSecondaryColor,
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const StudentListScreen())));
                        },
                      ),
                      // --- Total Teachers Card ---
                      StreamBuilder<QuerySnapshot>(
                        stream: firestore
                            .collection('admins')
                            .doc(adminUid)
                            .collection('teachers')
                            .snapshots(),
                        builder: (context, snapshot) {
                          String count = '...';
                          if (snapshot.hasError) {
                            count = 'Error';
                            print("Error fetching teachers: ${snapshot.error}");
                          } else if (snapshot.hasData) {
                            count = snapshot.data!.docs.length.toString();
                          }
                          return _buildSummaryCard(
                              icon: Icons.co_present_outlined,
                              title: "Total Teachers",
                              value: count,
                              color1: kPrimaryColor,
                              color2: const Color(0xFF9B84FF),
                              textColor: kSecondaryColor,
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const TeacherListScreen())));
                        },
                      ),
                      // --- Today Attendance Card (Calculates Absent = Total - Present) ---
                      StreamBuilder<QuerySnapshot>(
                        // Stream 1: Get total students
                        stream: firestore
                            .collection('admins')
                            .doc(adminUid)
                            .collection('students')
                            .snapshots(),
                        builder: (context, totalStudentsSnapshot) {
                          // Stream 2: Get today's attendance summary
                          return StreamBuilder<DocumentSnapshot>(
                            stream: firestore
                                .collection('admins')
                                .doc(adminUid)
                                .collection('attendanceSummary')
                                .doc(todayDateString)
                                .snapshots(),
                            builder: (context, summarySnapshot) {
                              Widget attendanceChild;
                              int presentCount = 0;
                              int absentCount = 0; // Will be calculated

                              if (totalStudentsSnapshot.connectionState ==
                                      ConnectionState.waiting ||
                                  summarySnapshot.connectionState ==
                                      ConnectionState.waiting) {
                                attendanceChild = Text('...',
                                    style: textTheme.headlineSmall?.copyWith(
                                        color: kSecondaryColor,
                                        fontWeight:
                                            FontWeight.bold)); // Loading state
                              } else if (totalStudentsSnapshot.hasError ||
                                  summarySnapshot.hasError) {
                                attendanceChild = Text('Error',
                                    style: textTheme.headlineSmall?.copyWith(
                                        color: Colors.red.shade200,
                                        fontWeight: FontWeight.bold));
                                if (totalStudentsSnapshot.hasError)
                                  print(
                                      "Error fetching total students for attendance calc: ${totalStudentsSnapshot.error}");
                                if (summarySnapshot.hasError)
                                  print(
                                      "Error fetching attendance summary for calc: ${summarySnapshot.error}");
                              } else if (totalStudentsSnapshot.hasData) {
                                final totalStudents =
                                    totalStudentsSnapshot.data!.docs.length;

                                // Get present count from summary (if exists)
                                if (summarySnapshot.hasData &&
                                    summarySnapshot.data!.exists) {
                                  final data = summarySnapshot.data!.data()
                                      as Map<String, dynamic>?;
                                  presentCount = data?['present'] ?? 0;
                                } else {
                                  presentCount =
                                      0; // No summary doc means 0 present
                                }

                                // Calculate absent count
                                absentCount = totalStudents - presentCount;
                                absentCount = (absentCount >= 0)
                                    ? absentCount
                                    : 0; // Ensure non-negative

                                // Build the display Row
                                attendanceChild = Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Icon(Icons.check_circle,
                                        color: Colors.green.shade200, size: 20),
                                    const SizedBox(width: 4),
                                    Text(presentCount.toString(),
                                        style: textTheme.headlineSmall
                                            ?.copyWith(
                                                color: kSecondaryColor,
                                                fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 12),
                                    Icon(Icons.cancel,
                                        color: Colors.red.shade200, size: 20),
                                    const SizedBox(width: 4),
                                    Text(absentCount.toString(),
                                        style: textTheme.headlineSmall
                                            ?.copyWith(
                                                color: kSecondaryColor,
                                                fontWeight: FontWeight.bold)),
                                  ],
                                );
                              } else {
                                // Handle case where total students couldn't be fetched but summary might have
                                attendanceChild = Text('N/A',
                                    style: textTheme.headlineSmall?.copyWith(
                                        color: kSecondaryColor.withOpacity(0.7),
                                        fontWeight: FontWeight.bold));
                              }

                              return _buildSummaryCard(
                                icon: Icons.assignment_turned_in_outlined,
                                title: "Today Attendance",
                                customChild: attendanceChild,
                                color1: kPrimaryColor,
                                color2: const Color(0xFF9B84FF), // Use const
                                textColor: kSecondaryColor,
                                onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const AttendanceSummaryScreen())),
                              );
                            },
                          );
                        },
                      ),
                      // --- Pending Payments Card (Updated for new payment structure) ---
                      // ✅ FIXED: Calculate pending payments with proper error handling and admin context
                      StreamBuilder<QuerySnapshot>(
                        stream: adminUid != null
                            ? firestore
                                .collection('admins')
                                .doc(adminUid)
                                .collection('students')
                                .snapshots()
                            : Stream.empty(),
                        builder: (context, studentsSnapshot) {
                          String pendingCount = '...'; // Default loading state

                          if (studentsSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            pendingCount = '...'; // Loading
                          } else if (studentsSnapshot.hasError) {
                            pendingCount = '0';
                            print(
                                "Error fetching students for pending fees: ${studentsSnapshot.error}");
                          } else if (studentsSnapshot.hasData &&
                              adminUid != null) {
                            // Count all pending payments across all students
                            _countPendingPayments(
                                    studentsSnapshot.data!.docs, adminUid!)
                                .then((count) {
                              if (mounted) {
                                setState(() {
                                  _cachedPendingCount = count;
                                });
                              }
                            });
                            pendingCount = _cachedPendingCount.toString();
                          } else {
                            pendingCount = '0'; // No data
                          }

                          return _buildSummaryCard(
                            icon: Icons.request_quote_outlined,
                            title: "Pending Payments",
                            value: pendingCount,
                            color1: kPrimaryColor,
                            color2: const Color(0xFF9B84FF),
                            textColor: kSecondaryColor,
                            onTap: () => Get.toNamed(AppRoutes
                                .paymentManagement), // Navigate to payment management
                          );
                        },
                      ),
                    ],
                  ).animate().fadeIn(duration: 500.ms).slideY(
                      begin: 0.2,
                      duration: 400.ms,
                      curve:
                          Curves.easeOut); // End of GridView for Overview Cards
                }, // Close builder function
              ), // Close StreamBuilder<User?>,

              const SizedBox(height: kDefaultPadding * 1.5),

              Text("Quick Actions",
                  style: textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: kDefaultPadding / 2),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: kDefaultPadding * 0.75,
                mainAxisSpacing: kDefaultPadding * 0.75,
                childAspectRatio: 1.2,
                children: [
                  ActionButtonCard(
                      icon: Icons.school,
                      label: "Add Student",
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AddStudentScreen()))),
                  ActionButtonCard(
                      icon: Icons.co_present,
                      label: "Add Teacher",
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AddTeacherScreen()))),
                  ActionButtonCard(
                      icon: Icons.qr_code_2,
                      label: "Scan QR Code",
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const QRCodeScannerScreen()))),
                  ActionButtonCard(
                      icon: Icons.add_box_outlined,
                      label: "Exam Results",
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ExamResultsScreen()))),
                ],
              )
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 500.ms)
                  .slideY(begin: 0.3, duration: 400.ms, curve: Curves.easeOut),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: List.generate(navIcons.length, (index) {
          bool isSelected = _selectedIndex == index;
          return BottomNavigationBarItem(
            icon: Animate(
              target: isSelected ? 1 : 0,
              effects: [
                ScaleEffect(
                    begin: Offset(0.9, 0.9),
                    end: Offset(1.1, 1.1),
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
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        showSelectedLabels: true,
        selectedFontSize: 12.0,
        unselectedFontSize: 11.0,
        elevation: 10.0,
        backgroundColor: Colors.white,
      ),
    );
  }

  // --- Helper Widget for Summary Cards ---
  Widget _buildSummaryCard({
    required IconData icon,
    required String title,
    String? value,
    Widget? customChild,
    required Color color1,
    required Color color2,
    required Color textColor,
    VoidCallback? onTap,
  }) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [color1, color2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(kDefaultRadius),
        boxShadow: [
          BoxShadow(
              color: color1.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(kDefaultRadius),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: kDefaultPadding, vertical: kDefaultPadding * 0.8),
            child: Row(
              children: [
                Icon(icon, color: textColor.withOpacity(0.8), size: 36),
                const SizedBox(width: kDefaultPadding),
                Expanded(
                  child: Text(title,
                      style: textTheme.titleMedium?.copyWith(
                          color: textColor.withOpacity(0.9),
                          fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: kDefaultPadding),
                customChild ??
                    (value != null
                        ? Text(value,
                            style: textTheme.headlineMedium?.copyWith(
                                color: textColor, fontWeight: FontWeight.bold))
                        : const SizedBox.shrink()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Count pending payments across all students (moved to Dashboard scope)
  Future<int> _countPendingPayments(
      List<QueryDocumentSnapshot> studentDocs, String adminUid) async {
    int totalPendingPayments = 0;
    final now = DateTime.now();
    final currentYear = now.year;
    final currentMonth = now.month;

    try {
      for (var studentDoc in studentDocs) {
        // Get fees for this student
        final feesQuery = await FirebaseFirestore.instance
            .collection('admins')
            .doc(adminUid)
            .collection('students')
            .doc(studentDoc.id)
            .collection('fees')
            .where('year', isEqualTo: currentYear)
            .get();

        for (var feeDoc in feesQuery.docs) {
          final feeData = feeDoc.data();

          // Check if this is a pending payment (with backward compatibility)
          final bool isPending = feeData.containsKey('status')
              ? feeData['status'] == 'PENDING'
              : feeData['paid'] == false;

          if (isPending) {
            final paymentType = feeData['paymentType'] ?? 'monthly';

            if (paymentType == 'monthly') {
              // Count if current month
              if (feeData['month'] == currentMonth) {
                totalPendingPayments++;
              }
            } else if (paymentType == 'daily') {
              // Count if within last 30 days
              final dateStr = feeData['date'] as String?;
              if (dateStr != null) {
                final feeDate = DateTime.parse(dateStr);
                final daysDiff = now.difference(feeDate).inDays;
                if (daysDiff <= 30) {
                  totalPendingPayments++;
                }
              }
            }
          }
        }
      }
    } catch (e) {
      print("Error counting pending payments: $e");
    }

    return totalPendingPayments;
  }
} // End of _DashboardScreenState

// --- StatefulWidget for Action Buttons with Hover Animation ---
class ActionButtonCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const ActionButtonCard(
      {super.key,
      required this.icon,
      required this.label,
      required this.onTap});
  @override
  State<ActionButtonCard> createState() => _ActionButtonCardState();
}

class _ActionButtonCardState extends State<ActionButtonCard> {
  bool _isHovering = false;
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: Card(
        color: kSecondaryColor,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(kDefaultRadius),
          child: Padding(
            padding: const EdgeInsets.all(kDefaultPadding * 0.75),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.icon, size: 32.0, color: kPrimaryColor),
                const SizedBox(height: kDefaultPadding * 0.5),
                Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall?.copyWith(
                      color: kPrimaryColor,
                      fontWeight: FontWeight.w600,
                      height: 1.2),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ).animate(target: _isHovering ? 1.0 : 0.0).scale(
          duration: 150.ms,
          curve: Curves.easeOut,
          begin: const Offset(1, 1),
          end: const Offset(1.05, 1.05)),
    );
  }

  /// Count pending payments across all students
  Future<int> _countPendingPayments(
      List<QueryDocumentSnapshot> studentDocs, String adminUid) async {
    int totalPendingPayments = 0;
    final now = DateTime.now();
    final currentYear = now.year;
    final currentMonth = now.month;

    try {
      for (var studentDoc in studentDocs) {
        // Get fees for this student
        final feesQuery = await FirebaseFirestore.instance
            .collection('admins')
            .doc(adminUid)
            .collection('students')
            .doc(studentDoc.id)
            .collection('fees')
            .where('year', isEqualTo: currentYear)
            .get();

        for (var feeDoc in feesQuery.docs) {
          final feeData = feeDoc.data();

          // Check if this is a pending payment (with backward compatibility)
          final bool isPending = feeData.containsKey('status')
              ? feeData['status'] == 'PENDING'
              : feeData['paid'] == false;

          if (isPending) {
            final paymentType = feeData['paymentType'] ?? 'monthly';

            if (paymentType == 'monthly') {
              // Count if current month
              if (feeData['month'] == currentMonth) {
                totalPendingPayments++;
              }
            } else if (paymentType == 'daily') {
              // Count if within last 30 days
              final dateStr = feeData['date'] as String?;
              if (dateStr != null) {
                final feeDate = DateTime.parse(dateStr);
                final daysDiff = now.difference(feeDate).inDays;
                if (daysDiff <= 30) {
                  totalPendingPayments++;
                }
              }
            }
          }
        }
      }
    } catch (e) {
      print("Error counting pending payments: $e");
    }

    return totalPendingPayments;
  }
}
