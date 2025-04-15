import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edu_track/app/features/authentication/controllers/auth_controller.dart';
import 'package:edu_track/app/features/profile/screens/profile_settings_screen.dart';
import 'package:edu_track/app/features/students/screens/add_student_screen.dart';
import 'package:edu_track/app/features/students/screens/student_details_screen.dart'; // Assuming this screen exists
import 'package:edu_track/app/features/teachers/screens/teacher_list_screen.dart';
import 'package:edu_track/app/features/attendance/screens/attendance_summary_screen.dart';
import 'package:edu_track/app/features/dashboard/screens/dashboard_screen.dart';
import 'package:edu_track/app/features/authentication/screens/signin_screen.dart';
import 'package:edu_track/app/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class StudentListScreen extends StatefulWidget {
  const StudentListScreen({super.key});

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedClass;
  List<String> _availableClasses = [];
  int _selectedIndex = 1; // Students tab is selected

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
    _fetchAvailableClasses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAvailableClasses() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('students').get();
      // Corrected type handling:
      final classes = snapshot.docs
          .map((doc) => doc.data()['class'] as String?) // Map to nullable String
          .where((className) => className != null && className.isNotEmpty) // Filter out null/empty
          .whereType<String>() // Explicitly cast to non-nullable String after filtering
          .toSet() // Get unique values
          .toList(); // Convert to List<String>
      classes.sort(); // Sort alphabetically
      setState(() {
        // Ensure 'All Classes' isn't added if classes list is empty
        _availableClasses = classes.isEmpty ? [] : ['All Classes', ...classes];
      });
    } catch (e) {
      print("Error fetching classes: $e");
      // Handle error appropriately, maybe show a snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching class list: $e')),
        );
      }
    }
  }

  void _onBottomNavItemTapped(int index) {
    // Don't rebuild if the same tab is tapped
    if (_selectedIndex == index) return;

    setState(() { _selectedIndex = index; });

    // Navigate after a short delay to allow animation
    Future.delayed(150.ms, () {
      if (!mounted) return;
      switch (index) {
        case 0: Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardScreen())); break;
        case 1: break; // Already on Student List Screen
        case 2: Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const TeacherListScreen())); break;
        case 3: Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AttendanceSummaryScreen())); break;
        case 4:
          print("Logout Tapped");
          AuthController.instance.signOut(); // Assuming signout method exists
          Navigator.pushAndRemoveUntil( context, MaterialPageRoute(builder: (_) => const SignInScreen()), (route) => false );
          break;
      }
      // Reset index visually if navigating away and coming back might be needed,
      // but pushReplacement handles the state reset better here.
    });
  }

  Widget _buildProfileAvatar() {
    final String? userId = AuthController.instance.user?.uid;
    if (userId == null) {
      // Fallback if user somehow becomes null
      return IconButton(
        icon: Icon(Icons.account_circle_rounded, size: 30, color: kLightTextColor),
        tooltip: 'Profile Settings',
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileSettingsScreen())),
      );
    }
    // Reuse the StreamBuilder logic from DashboardScreen
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('admins').doc(userId).snapshots(),
      builder: (context, snapshot) {
        String? photoUrl;
        Widget profileWidget = Icon(Icons.account_circle_rounded, size: 30, color: kLightTextColor); // Default icon

        if (snapshot.connectionState == ConnectionState.active && snapshot.hasData && snapshot.data!.exists) {
          var data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data != null && data.containsKey('photoURL')) {
            photoUrl = data['photoURL'] as String?;
          }
        } else if (snapshot.hasError) {
          print("Error fetching admin profile: ${snapshot.error}");
          // Keep default icon on error
        }

        if (photoUrl != null && photoUrl.isNotEmpty) {
          profileWidget = CircleAvatar(
            radius: 18,
            backgroundColor: kLightTextColor.withOpacity(0.5),
            backgroundImage: NetworkImage(photoUrl),
            onBackgroundImageError: (exception, stackTrace) {
              print("Error loading profile image: $exception");
              // Optionally fallback to icon if image fails
              // setState(() => profileWidget = Icon(Icons.account_circle_rounded, size: 30, color: kLightTextColor));
            },
          );
        }

        // Wrap with Material and InkWell for tap effect and navigation
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(kDefaultRadius * 2),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileSettingsScreen())),
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
    final colorScheme = Theme.of(context).colorScheme;

    // Define Bottom Nav Bar items (similar to Dashboard)
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
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: kLightTextColor),
          tooltip: 'Back',
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Student List', style: textTheme.titleLarge),
        centerTitle: true,
        actions: [
          _buildProfileAvatar(), // Reusable profile avatar
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(kDefaultPadding),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search student name',
                    prefixIcon: Icon(Icons.search, color: kLightTextColor.withOpacity(0.7)),
                    filled: true,
                    fillColor: kSecondaryColor.withOpacity(0.8), // Light background
                    contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(kDefaultRadius),
                      borderSide: BorderSide.none, // No border
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(kDefaultRadius),
                      borderSide: BorderSide(color: kPrimaryColor.withOpacity(0.3)), // Subtle border when enabled
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(kDefaultRadius),
                      borderSide: BorderSide(color: kPrimaryColor, width: 1.5), // Highlight border when focused
                    ),
                  ),
                  style: textTheme.bodyMedium?.copyWith(color: kTextColor),
                ),
                const SizedBox(height: kDefaultPadding),
                // Action Row: Add Button and Filter Dropdown
                Row(
                  children: [
                    // Add Student Button
                    Container(
                      decoration: BoxDecoration(
                        color: kPrimaryColor,
                        borderRadius: BorderRadius.circular(kDefaultRadius * 0.8),
                        boxShadow: [
                          BoxShadow(
                            color: kPrimaryColor.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          )
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.add, color: Colors.white, size: 28),
                        tooltip: 'Add New Student',
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddStudentScreen())),
                      ),
                    ).animate().fadeIn(delay: 100.ms).scale(begin: const Offset(0.8, 0.8)),
                    const SizedBox(width: kDefaultPadding),
                    // Class Filter Dropdown
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding * 0.75, vertical: 0),
                        decoration: BoxDecoration(
                          color: kSecondaryColor.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(kDefaultRadius),
                          border: Border.all(color: kPrimaryColor.withOpacity(0.3)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedClass ?? _availableClasses.firstOrNull, // Default to first item or null
                            isExpanded: true,
                            icon: Icon(Icons.arrow_drop_down_rounded, color: kPrimaryColor),
                            dropdownColor: kSecondaryColor, // Match background
                            style: textTheme.bodyMedium?.copyWith(color: kTextColor),
                            hint: Text('Select Class', style: textTheme.bodyMedium?.copyWith(color: kLightTextColor)),
                            items: _availableClasses.map((String className) {
                              return DropdownMenuItem<String>(
                                value: className,
                                child: Text(className),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                // Handle 'All Classes' selection
                                _selectedClass = (newValue == 'All Classes') ? null : newValue;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Student List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('students').orderBy('name').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No students found.'));
                }

                // Filter data based on search query and selected class
                final allStudents = snapshot.data!.docs;
                final filteredStudents = allStudents.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['name'] as String? ?? '').toLowerCase();
                  final studentClass = data['class'] as String?;

                  final nameMatches = _searchQuery.isEmpty || name.contains(_searchQuery.toLowerCase());
                  final classMatches = _selectedClass == null || studentClass == _selectedClass;

                  return nameMatches && classMatches;
                }).toList();

                if (filteredStudents.isEmpty) {
                   return Center(
                     child: Text(
                       'No students match your criteria.',
                       style: textTheme.bodyMedium?.copyWith(color: kLightTextColor),
                     ),
                   );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(
                    left: kDefaultPadding,
                    right: kDefaultPadding,
                    bottom: kDefaultPadding, // Add padding at the bottom
                  ),
                  itemCount: filteredStudents.length,
                  itemBuilder: (context, index) {
                    final studentDoc = filteredStudents[index];
                    final studentData = studentDoc.data() as Map<String, dynamic>;
                    return _buildStudentCard(context, studentDoc.id, studentData)
                           .animate().fadeIn(delay: (index * 50).ms).slideY(begin: 0.2, duration: 300.ms);
                  },
                );
              },
            ),
          ),
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
        backgroundColor: Colors.white, // Or kSecondaryColor if preferred
      ),
    );
  }

  // --- Helper Widget for Student Card ---
  Widget _buildStudentCard(BuildContext context, String studentId, Map<String, dynamic> data) {
    final textTheme = Theme.of(context).textTheme;
    final name = data['name'] as String? ?? 'N/A';
    final studentClass = data['class'] as String? ?? 'N/A';
    final photoUrl = data['photoUrl'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: kDefaultPadding * 0.75),
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kDefaultRadius)),
      color: kSecondaryColor, // Use secondary color for card background
      child: InkWell(
        borderRadius: BorderRadius.circular(kDefaultRadius),
        onTap: () {
          // Navigate to Student Details Screen, passing student ID or data
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StudentDetailsScreen(studentId: studentId), // Pass ID
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(kDefaultPadding * 0.75),
          child: Row(
            children: [
              // Student Info (Name, Class)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: kTextColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      studentClass, // Displaying class as 'Grade X'
                      style: textTheme.bodySmall?.copyWith(color: kLightTextColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: kDefaultPadding),
              // Student Image
              ClipRRect(
                borderRadius: BorderRadius.circular(kDefaultRadius * 0.8),
                child: (photoUrl != null && photoUrl.isNotEmpty)
                    ? Image.network(
                        photoUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: 60,
                            height: 60,
                            color: kLightTextColor.withOpacity(0.1),
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2.0,
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 60,
                            height: 60,
                            color: kLightTextColor.withOpacity(0.1),
                            child: Icon(Icons.person_outline_rounded, color: kLightTextColor.withOpacity(0.5), size: 30),
                          );
                        },
                      )
                    : Container( // Placeholder if no photoUrl
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: kLightTextColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(kDefaultRadius * 0.8),
                        ),
                        child: Icon(Icons.person_outline_rounded, color: kLightTextColor.withOpacity(0.5), size: 30),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}