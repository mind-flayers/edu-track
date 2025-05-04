import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edu_track/app/features/authentication/controllers/auth_controller.dart';
import 'package:edu_track/app/features/students/screens/student_list_screen.dart';
import 'package:edu_track/app/features/teachers/screens/add_teacher_screen.dart';
import 'package:edu_track/app/features/attendance/screens/attendance_summary_screen.dart';
import 'package:edu_track/app/features/dashboard/screens/dashboard_screen.dart';
import 'package:edu_track/app/features/authentication/screens/signin_screen.dart';
import 'package:edu_track/app/utils/constants.dart';
import 'package:edu_track/main.dart'; // Import main for AppRoutes
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart'; // Import GetX

class TeacherListScreen extends StatefulWidget {
  const TeacherListScreen({super.key});

  @override
  State<TeacherListScreen> createState() => _TeacherListScreenState();
}

class _TeacherListScreenState extends State<TeacherListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _selectedIndex = 2; // Teachers tab is selected

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onBottomNavItemTapped(int index) {
    if (_selectedIndex == index) return;

    setState(() { _selectedIndex = index; });

    Future.delayed(150.ms, () {
      if (!mounted) return;
      switch (index) {
        case 0: Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardScreen())); break;
        case 1: Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const StudentListScreen())); break;
        case 2: break; // Already on Teacher List Screen
        case 3: Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AttendanceSummaryScreen())); break;
        case 4:
          AuthController.instance.signOut();
          Navigator.pushAndRemoveUntil( context, MaterialPageRoute(builder: (_) => const SignInScreen()), (route) => false );
          break;
      }
    });
  }

  // Reusable Profile Avatar logic from StudentListScreen
  Widget _buildProfileAvatar() {
    final String? userId = AuthController.instance.user?.uid;
    if (userId == null) {
      return IconButton(
        icon: Icon(Icons.account_circle_rounded, size: 30, color: kLightTextColor),
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
        Widget profileWidget = Icon(Icons.account_circle_rounded, size: 30, color: kLightTextColor); // Default icon

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
              // Fallback to icon if image fails
              if (mounted) {
                setState(() {
                   profileWidget = Icon(Icons.account_circle_rounded, size: 30, color: kLightTextColor);
                });
              }
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


  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // final colorScheme = Theme.of(context).colorScheme;

    // Define Bottom Nav Bar items (same as StudentListScreen)
    final Map<int, IconData> navIcons = {
      0: Icons.dashboard_rounded,
      1: Icons.school_rounded,
      2: Icons.co_present_rounded, // Icon for Teachers
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
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: kLightTextColor),
          tooltip: 'Back',
          // Navigate back or to Dashboard if no previous route
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              // If cannot pop (e.g., deep linked), go to dashboard
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
            }
          },
        ),
        title: Text('Teacher List', style: textTheme.titleLarge),
        centerTitle: true,
        actions: [
          _buildProfileAvatar(), // Reusable profile avatar
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(kDefaultPadding),
            child: Row( // Row for Add button and Search bar
              children: [
                // Add Teacher Button - Styled like the image
                ElevatedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddTeacherScreen())),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(kDefaultRadius), // Square corners like image
                    ),
                    minimumSize: const Size(50, 50), // Square size
                    padding: EdgeInsets.zero,
                    backgroundColor: kPrimaryColor,
                    foregroundColor: Colors.white,
                    elevation: 3,
                  ),
                  child: const Icon(Icons.add, size: 28),
                ).animate().fadeIn(delay: 100.ms).scale(begin: const Offset(0.8, 0.8)),
                const SizedBox(width: kDefaultPadding),
                // Search Bar - Styled like the image
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search teacher name',
                      prefixIcon: Icon(Icons.search, color: kPrimaryColor.withOpacity(0.8)),
                      filled: true,
                      fillColor: kSecondaryColor, // White background
                      contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: kDefaultPadding), // Match student list search bar height
                      border: OutlineInputBorder( // Consistent border
                        borderRadius: BorderRadius.circular(kDefaultRadius * 1.5), // Match student list search bar rounding
                        borderSide: BorderSide(color: kPrimaryColor.withOpacity(0.4), width: 1.5), // Match student list border
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(kDefaultRadius * 1.5),
                        borderSide: BorderSide(color: kPrimaryColor.withOpacity(0.4), width: 1.5), // Match student list border
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(kDefaultRadius * 1.5),
                        borderSide: BorderSide(color: kPrimaryColor, width: 2.0), // Slightly thicker focus border like student list
                      ),
                    ),
                    style: textTheme.bodyMedium?.copyWith(color: kTextColor),
                  ),
                ),
              ],
            ),
          ),
          // Teacher List
          Expanded(
            child: () { // Use a function to conditionally return the widget
              final String? adminUid = AuthController.instance.user?.uid;
              if (adminUid == null) {
                print("Error: Admin UID is null. Cannot display teachers.");
                return Center(
                  child: Text(
                    'Please log in to view teachers.',
                    style: textTheme.bodyMedium?.copyWith(color: kLightTextColor),
                  ),
                );
              }
              // If adminUid is available, return the StreamBuilder
              return StreamBuilder<QuerySnapshot>(
                // Query the nested 'teachers' collection under the admin
                stream: FirebaseFirestore.instance
                    .collection('admins')
                    .doc(adminUid)
                    .collection('teachers')
                    .orderBy('name')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error fetching teachers: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        'No teachers found.',
                         style: textTheme.bodyMedium?.copyWith(color: kLightTextColor),
                      )
                    );
                  }

                  // Filter data based on search query
                  final allTeachers = snapshot.data!.docs;
                  final filteredTeachers = allTeachers.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final name = (data['name'] as String? ?? '').toLowerCase();
                    // Add other fields to search if needed later
                    // final subject = (data['subject'] as String? ?? '').toLowerCase();

                    return _searchQuery.isEmpty || name.contains(_searchQuery.toLowerCase());
                  }).toList();

                  if (filteredTeachers.isEmpty) {
                     return Center(
                       child: Text(
                         'No teachers match your search.',
                         style: textTheme.bodyMedium?.copyWith(color: kLightTextColor),
                       ),
                     );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding, vertical: kDefaultPadding / 2),
                    itemCount: filteredTeachers.length,
                    itemBuilder: (context, index) {
                      final teacherDoc = filteredTeachers[index];
                      final teacherData = teacherDoc.data() as Map<String, dynamic>;
                      // Pass document ID if needed for details screen later
                      return _buildTeacherCard(context, teacherDoc.id, teacherData)
                             .animate().fadeIn(delay: (index * 50).ms).slideY(begin: 0.2, duration: 300.ms);
                    },
                  );
                },
              );
            }(), // Immediately invoke the function
          ), // End of Expanded widget
        ],
      ),
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
        backgroundColor: Colors.white, // Or kSecondaryColor
      ),
    );
  }

  // --- Helper Widget for Teacher Card ---
  Widget _buildTeacherCard(BuildContext context, String teacherId, Map<String, dynamic> data) {
    final textTheme = Theme.of(context).textTheme;
    final name = data['name'] as String? ?? 'N/A';
    final subject = data.containsKey('subject')
        ? (data['subject'] is List
            ? (data['subject'] as List).join(', ') // Convert List to comma-separated String
            : data['subject'] as String? ?? 'N/A')
        : 'N/A';
    final phone = data['phoneNumber'] as String? ?? 'N/A';
    final email = data['email'] as String? ?? 'N/A';
    // final photoUrl = data['photoUrl'] as String?; // Available if needed later

    return Card(
      // Card Styling based on image
      margin: const EdgeInsets.only(bottom: kDefaultPadding),
      elevation: 1.5,
      shadowColor: Colors.grey.withOpacity(0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kDefaultRadius * 1.2)),
      color: kSecondaryColor, // White background for card
      child: InkWell(
        borderRadius: BorderRadius.circular(kDefaultRadius * 1.2),
        onTap: () {
          // TODO: Navigate to Teacher Details Screen if needed
          // Navigator.push(context, MaterialPageRoute(builder: (_) => TeacherDetailsScreen(teacherId: teacherId)));
          print("Tapped on teacher: $name"); // Placeholder action
        },
        child: Padding(
          padding: const EdgeInsets.all(kDefaultPadding),
          child: Column( // Use Column for vertical layout of info
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: kDefaultPadding * 0.75), // Spacing
              _buildInfoRow(context, label: 'Subject', value: subject),
              const SizedBox(height: kDefaultPadding * 0.5),
              _buildInfoRow(context, label: 'Contact Number', value: phone),
              const SizedBox(height: kDefaultPadding * 0.5),
              _buildInfoRow(context, label: 'Email', value: email),
            ],
          ),
        ),
      ),
    );
  }

  // Helper for consistent label-value rows within the card
  Widget _buildInfoRow(BuildContext context, {required String label, required String value}) {
     final textTheme = Theme.of(context).textTheme;
     return Row(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
         Text(
           '$label: ',
           style: textTheme.bodyMedium?.copyWith(color: kLightTextColor, fontWeight: FontWeight.w500),
         ),
         Expanded(
           child: Text(
             value,
             style: textTheme.bodyMedium?.copyWith(color: kTextColor),
             // Allow wrapping for longer emails/values
             // maxLines: 1,
             // overflow: TextOverflow.ellipsis,
           ),
         ),
       ],
     );
  }
}