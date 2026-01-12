import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edu_track/app/features/authentication/controllers/auth_controller.dart';
import 'package:edu_track/app/features/students/controllers/student_controller.dart';
import 'package:edu_track/app/features/students/screens/add_student_screen.dart';
import 'package:edu_track/app/features/teachers/screens/teacher_list_screen.dart';
import 'package:edu_track/app/features/attendance/screens/attendance_summary_screen.dart';
import 'package:edu_track/app/features/dashboard/screens/dashboard_screen.dart';
import 'package:edu_track/app/features/exam/screens/exam_results_screen.dart';
import 'package:edu_track/app/utils/constants.dart';
import 'package:edu_track/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';

/// Student List Screen - Refactored to use GetX Controller pattern.
/// All business logic is now in [StudentController].
class StudentListScreen extends StatelessWidget {
  const StudentListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the controller instance (injected via StudentBinding)
    final controller = Get.find<StudentController>();
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: _buildAppBar(context, controller, textTheme),
      body: Column(
        children: [
          _buildSearchAndFilterSection(context, controller, textTheme),
          Expanded(child: _buildStudentList(context, controller, textTheme)),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // APP BAR
  // ─────────────────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(
      BuildContext context, StudentController controller, TextTheme textTheme) {
    return AppBar(
      automaticallyImplyLeading: false, // No back button for tab screens
      leading: Obx(() => controller.isSelectionMode.value
          ? IconButton(
              icon: const Icon(Icons.close, color: kErrorColor),
              tooltip: 'Cancel',
              onPressed: controller.exitSelectionMode,
            )
          : const SizedBox.shrink()), // Empty widget when not in selection mode
      title: Obx(() => controller.isSelectionMode.value
          ? Text('${controller.selectedStudentIds.length} Selected',
              style: textTheme.titleLarge)
          : Text('Student List', style: textTheme.titleLarge)),
      centerTitle: true,
      actions: [
        Obx(() {
          if (controller.isSelectionMode.value) {
            return IconButton(
              icon: Icon(
                controller.areAllSelected
                    ? Icons.deselect
                    : Icons.select_all_rounded,
                color: kPrimaryColor,
              ),
              tooltip:
                  controller.areAllSelected ? 'Deselect All' : 'Select All',
              onPressed: () {
                if (controller.areAllSelected) {
                  controller.deselectAllStudents();
                } else {
                  controller.selectAllStudents();
                }
              },
            );
          } else {
            return _buildProfileAvatar();
          }
        }),
      ],
    );
  }

  Widget _buildProfileAvatar() {
    final String? userId = AuthController.instance.user?.uid;
    if (userId == null) {
      return IconButton(
        icon:
            Icon(Icons.account_circle_rounded, size: 30, color: kLightTextColor),
        tooltip: 'Profile Settings',
        onPressed: () => Get.toNamed(AppRoutes.profileSettings),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('admins')
          .doc(userId)
          .collection('adminProfile')
          .doc('profile')
          .snapshots(),
      builder: (context, snapshot) {
        String? photoUrl;
        Widget profileWidget = Icon(Icons.account_circle_rounded,
            size: 30, color: kLightTextColor);

        if (snapshot.connectionState == ConnectionState.active &&
            snapshot.hasData &&
            snapshot.data!.exists) {
          var data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data != null && data.containsKey('profilePhotoUrl')) {
            photoUrl = data['profilePhotoUrl'] as String?;
          }
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
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // SEARCH & FILTER SECTION
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildSearchAndFilterSection(
      BuildContext context, StudentController controller, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.all(kDefaultPadding),
      child: Column(
        children: [
          // Search Bar
          TextField(
            onChanged: controller.updateSearchQuery,
            decoration: InputDecoration(
              hintText: 'Search student name',
              prefixIcon:
                  Icon(Icons.search, color: kPrimaryColor.withOpacity(0.8)),
              filled: true,
              fillColor: kSecondaryColor,
              contentPadding: const EdgeInsets.symmetric(
                  vertical: 12.0, horizontal: kDefaultPadding),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(kDefaultRadius * 1.5),
                borderSide: BorderSide(
                    color: kPrimaryColor.withOpacity(0.4), width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(kDefaultRadius * 1.5),
                borderSide: BorderSide(
                    color: kPrimaryColor.withOpacity(0.4), width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(kDefaultRadius * 1.5),
                borderSide: BorderSide(color: kPrimaryColor, width: 2.0),
              ),
            ),
            style: textTheme.bodyMedium?.copyWith(color: kTextColor),
          ),
          const SizedBox(height: kDefaultPadding),
          // Action Row: Add/Delete Button and Filter Dropdown
          Row(
            children: [
              // Add Student Button / Delete Button
              Obx(() => controller.isSelectionMode.value
                  ? ElevatedButton(
                      onPressed: () =>
                          controller.deleteSelectedStudents(context),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(kDefaultRadius * 1.5),
                        ),
                        minimumSize: const Size(56, 56),
                        padding: EdgeInsets.zero,
                        backgroundColor: kErrorColor,
                        foregroundColor: Colors.white,
                        elevation: 3,
                      ),
                      child:
                          const Icon(Icons.delete_outline_rounded, size: 28),
                    )
                      .animate()
                      .fadeIn(delay: 100.ms)
                      .scale(begin: const Offset(0.8, 0.8))
                  : ElevatedButton(
                      onPressed: () => Get.to(() => const AddStudentScreen()),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(kDefaultRadius * 1.5),
                        ),
                        minimumSize: const Size(56, 56),
                        padding: EdgeInsets.zero,
                        backgroundColor: kPrimaryColor,
                        foregroundColor: Colors.white,
                        elevation: 3,
                      ),
                      child: const Icon(Icons.add, size: 28),
                    )
                      .animate()
                      .fadeIn(delay: 100.ms)
                      .scale(begin: const Offset(0.8, 0.8))),
              const SizedBox(width: kDefaultPadding),
              // Class Filter Dropdown
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: kDefaultPadding, vertical: 4),
                  decoration: BoxDecoration(
                    color: kSecondaryColor,
                    borderRadius: BorderRadius.circular(kDefaultRadius * 1.5),
                    border: Border.all(
                        color: kPrimaryColor.withOpacity(0.4), width: 1.5),
                  ),
                  child: Obx(() {
                        // Handle empty classes list
                        final classes = controller.availableClasses;
                        if (classes.isEmpty) {
                          return const Center(
                            child: Text('Loading classes...'),
                          );
                        }
                        
                        // Determine current value
                        String? currentValue = controller.selectedClass.value;
                        if (currentValue == null && classes.contains('All Classes')) {
                          currentValue = 'All Classes';
                        } else if (currentValue != null && !classes.contains(currentValue)) {
                          currentValue = classes.firstOrNull;
                        }
                        
                        return DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: currentValue,
                            isExpanded: true,
                            icon: Icon(Icons.keyboard_arrow_down_rounded,
                                color: kPrimaryColor.withOpacity(0.8)),
                            dropdownColor: kSecondaryColor,
                            style:
                                textTheme.bodyMedium?.copyWith(color: kTextColor),
                            hint: Text(
                              'Select Class',
                              style: textTheme.bodyMedium?.copyWith(
                                  color: kLightTextColor.withOpacity(0.8)),
                            ),
                            items: classes.map((String className) {
                              return DropdownMenuItem<String>(
                                value: className,
                                child: Text(
                                  className,
                                  style: textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w500),
                                ),
                              );
                            }).toList(),
                            onChanged: controller.updateClassFilter,
                          ),
                        );
                      }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // STUDENT LIST
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildStudentList(
      BuildContext context, StudentController controller, TextTheme textTheme) {
    final adminUid = controller.adminUid;
    if (adminUid == null) {
      return Center(
        child: Text(
          'Please log in to view students.',
          style: textTheme.bodyMedium?.copyWith(color: kLightTextColor),
        ),
      );
    }

    final stream = controller.studentsStream;
    if (stream == null) {
      return Center(
        child: Text(
          'Unable to load students. Please try again.',
          style: textTheme.bodyMedium?.copyWith(color: kLightTextColor),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
              child: Text('Error fetching students: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No students found.'));
        }

        // Filter data using controller
        final allStudents = snapshot.data!.docs;
        return Obx(() {
          final filteredStudents = controller.filterStudents(allStudents);

          if (filteredStudents.isEmpty) {
            return Center(
              child: Text(
                'No students match your criteria.',
                style: textTheme.bodyMedium?.copyWith(color: kLightTextColor),
              ),
            );
          }

          // Update filtered IDs for Select All functionality
          WidgetsBinding.instance.addPostFrameCallback((_) {
            controller.updateFilteredStudentIds(
                filteredStudents.map((doc) => doc.id).toList());
          });

          return ListView.builder(
            padding: const EdgeInsets.symmetric(
                horizontal: kDefaultPadding * 0.75,
                vertical: kDefaultPadding / 2),
            itemCount: filteredStudents.length,
            itemBuilder: (context, index) {
              final studentDoc = filteredStudents[index];
              final studentData = studentDoc.data();
              return _buildStudentCard(
                      context, controller, studentDoc.id, studentData)
                  .animate()
                  .fadeIn(delay: (index * 50).ms)
                  .slideY(begin: 0.2, duration: 300.ms);
            },
          );
        });
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // STUDENT CARD
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildStudentCard(BuildContext context, StudentController controller,
      String studentId, Map<String, dynamic> data) {
    final textTheme = Theme.of(context).textTheme;
    final name = data['name'] as String? ?? 'N/A';
    final studentClass = data['class'] as String? ?? 'N/A';
    final indexNumber = data['indexNumber'] as String? ?? 'N/A';
    final photoUrl = data['photoUrl'] as String?;

    return Obx(() {
      final isSelected = controller.selectedStudentIds.contains(studentId);
      final isSelectionMode = controller.isSelectionMode.value;

      return Card(
        margin: const EdgeInsets.only(bottom: kDefaultPadding),
        elevation: isSelected ? 4 : 1.5,
        shadowColor: isSelected
            ? kPrimaryColor.withOpacity(0.4)
            : Colors.grey.withOpacity(0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kDefaultRadius * 1.2),
          side: isSelected
              ? BorderSide(color: kPrimaryColor, width: 2)
              : BorderSide.none,
        ),
        child: GestureDetector(
          onTap: () => controller.navigateToStudentDetails(studentId),
          onLongPress: () {
            if (!isSelectionMode) {
              controller.enterSelectionMode(studentId);
            }
          },
          child: Ink(
            decoration: BoxDecoration(
              color:
                  isSelected ? kPrimaryColor.withOpacity(0.1) : kSecondaryColor,
              borderRadius: BorderRadius.circular(kDefaultRadius * 1.2),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: kDefaultPadding, vertical: kDefaultPadding * 0.8),
              child: Row(
                children: [
                  // Selection Checkbox
                  if (isSelectionMode)
                    Padding(
                      padding:
                          const EdgeInsets.only(right: kDefaultPadding * 0.75),
                      child: Checkbox(
                        value: isSelected,
                        onChanged: (_) =>
                            controller.toggleStudentSelection(studentId),
                        activeColor: kPrimaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  // Student Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          name,
                          style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: kTextColor,
                              fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Index No: $indexNumber',
                          style: textTheme.bodySmall?.copyWith(
                              color: kLightTextColor, fontSize: 11.5),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          studentClass,
                          style: textTheme.bodySmall?.copyWith(
                              color: kLightTextColor, fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: kDefaultPadding),
                  // Student Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(kDefaultRadius),
                    child: (photoUrl != null && photoUrl.isNotEmpty)
                        ? Image.network(
                            photoUrl,
                            width: 55,
                            height: 55,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                width: 55,
                                height: 55,
                                color: kLightTextColor.withOpacity(0.1),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.0,
                                    value: loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 55,
                                height: 55,
                                color: kLightTextColor.withOpacity(0.1),
                                child: Icon(Icons.person_outline_rounded,
                                    color: kLightTextColor.withOpacity(0.5),
                                    size: 30),
                              );
                            },
                          )
                        : Container(
                            width: 55,
                            height: 55,
                            decoration: BoxDecoration(
                              color: kLightTextColor.withOpacity(0.1),
                              borderRadius:
                                  BorderRadius.circular(kDefaultRadius),
                            ),
                            child: Icon(Icons.person_outline_rounded,
                                color: kLightTextColor.withOpacity(0.5),
                                size: 30),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

}
