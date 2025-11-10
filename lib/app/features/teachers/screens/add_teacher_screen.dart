import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edu_track/app/features/authentication/controllers/auth_controller.dart';
import 'package:edu_track/app/features/students/screens/student_list_screen.dart';
import 'package:edu_track/app/features/teachers/screens/teacher_list_screen.dart';
import 'package:edu_track/app/features/attendance/screens/attendance_summary_screen.dart';
import 'package:edu_track/app/features/dashboard/screens/dashboard_screen.dart';
import 'package:edu_track/app/features/authentication/screens/signin_screen.dart';
import 'package:edu_track/app/utils/constants.dart';
import 'package:edu_track/main.dart'; // Import main to access AppRoutes
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart'; // Import GetX

class AddTeacherScreen extends StatefulWidget {
  const AddTeacherScreen({super.key});

  @override
  State<AddTeacherScreen> createState() => _AddTeacherScreenState();
}

class _AddTeacherScreenState extends State<AddTeacherScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _subjectsController = TextEditingController();

  List<String> _selectedClasses = [];
  bool _isLoading = false;
  String? _statusMessage;
  bool _isError = false;
  int _selectedIndex = 2; // Keep track of bottom nav selection

  // TODO: Fetch these dynamically or use a better configuration method
  final List<String> _availableClasses = [
    'Grade 1',
    'Grade 2',
    'Grade 3',
    'Grade 4',
    'Grade 5',
    'Grade 6',
    'Grade 7',
    'Grade 8',
    'Grade 9',
    'Grade 10',
    'Grade 11',
    'Grade 12',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _subjectsController.dispose();
    super.dispose();
  }

  // --- Reusable AppBar Profile Avatar Logic (from TeacherListScreen) ---
  Widget _buildProfileAvatar() {
    final String? userId = AuthController.instance.user?.uid;
    if (userId == null) {
      return IconButton(
        icon: Icon(Icons.account_circle_rounded,
            size: 30, color: kLightTextColor),
        tooltip: 'Profile Settings',
        onPressed: () =>
            Get.toNamed(AppRoutes.profileSettings), // Use Get.toNamed
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
        Widget profileWidget = Icon(Icons.account_circle_rounded,
            size: 30, color: kLightTextColor); // Default icon

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
              if (mounted) {
                setState(() {
                  profileWidget = Icon(Icons.account_circle_rounded,
                      size: 30, color: kLightTextColor);
                });
              }
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

  // --- Reusable Bottom Navigation Logic (from TeacherListScreen) ---
  void _onBottomNavItemTapped(int index) {
    if (_selectedIndex == index) return;

    // Set state immediately for visual feedback
    setState(() {
      _selectedIndex = index;
    });

    // Use Future.delayed to allow animation before navigation
    Future.delayed(150.ms, () {
      if (!mounted) return; // Check if the widget is still in the tree
      switch (index) {
        case 0:
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const DashboardScreen()));
          break;
        case 1:
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const StudentListScreen()));
          break;
        case 2:
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const TeacherListScreen()));
          break; // Go to List Screen
        case 3:
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (_) => const AttendanceSummaryScreen()));
          break;
        case 4:
          AuthController.instance.signOut();
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const SignInScreen()),
              (route) => false);
          break;
      }
    });
  }

  // --- Form Submission Logic ---
  Future<void> _submitForm() async {
    // Hide keyboard
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      if (_selectedClasses.isEmpty) {
        setState(() {
          _statusMessage = 'Please select at least one assigned class.';
          _isError = true;
        });
        // Clear message after a delay
        Future.delayed(const Duration(seconds: 3), () {
          // Use Duration constructor
          if (mounted) setState(() => _statusMessage = null);
        });
        return; // Stop submission
      }

      setState(() {
        _isLoading = true;
        _statusMessage = null; // Clear previous message
        _isError = false;
      });

      try {
        final String? adminUid =
            AuthController.instance.user?.uid; // Get Admin UID
        if (adminUid == null) {
          throw Exception("Admin user not found. Cannot add teacher.");
        }

        final teacherData = {
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'phoneNumber': _phoneController.text.trim(),
          'whatsappNumber': _whatsappController.text.trim(),
          'subject': _subjectsController.text
              .trim(), // Storing as single string for now
          'classAssigned': _selectedClasses,
          'joinedAt': Timestamp.now(),
          'isActive': true,
        };

        // Add teacher under the specific admin's collection
        await FirebaseFirestore.instance
            .collection('admins')
            .doc(adminUid)
            .collection('teachers')
            .add(teacherData);

        setState(() {
          _statusMessage = 'Teacher Added Successfully!';
          _isError = false;
          // Clear form
          _formKey.currentState!.reset();
          _nameController.clear();
          _emailController.clear();
          _phoneController.clear();
          _whatsappController.clear();
          _subjectsController.clear();
          _selectedClasses = [];
        });

        // Optional: Navigate back or show message longer
        Future.delayed(const Duration(seconds: 2), () {
          // Use Duration constructor
          if (mounted) {
            setState(() => _statusMessage = null);
            // Optionally navigate back
            // Navigator.pop(context);
          }
        });
      } catch (e) {
        print("Error adding teacher: $e");
        setState(() {
          _statusMessage = 'Failed to add teacher. Please try again.';
          _isError = true;
        });
        // Clear message after a delay
        Future.delayed(const Duration(seconds: 3), () {
          // Use Duration constructor
          if (mounted) setState(() => _statusMessage = null);
        });
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      setState(() {
        _statusMessage = 'Please fix the errors in the form.';
        _isError = true;
      });
      // Clear message after a delay
      Future.delayed(const Duration(seconds: 3), () {
        // Use Duration constructor
        if (mounted) setState(() => _statusMessage = null);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // final colorScheme = Theme.of(context).colorScheme;

    // Define Bottom Nav Bar items (same as TeacherListScreen)
    final Map<int, IconData> navIcons = {
      0: Icons.school_rounded,
      1: Icons.co_present_rounded, // Icon for Teachers
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
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: kLightTextColor),
          tooltip: 'Back to Teacher List',
          onPressed: () => Navigator.pop(context), // Simple pop for back
        ),
        title: Text('Add Teacher', style: textTheme.titleLarge),
        centerTitle: true,
        actions: [
          _buildProfileAvatar(), // Reusable profile avatar
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(kDefaultPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Teacher Information Form',
                style: textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: kDefaultPadding * 1.5),

              // --- Form Fields ---
              _buildTextField(
                controller: _nameController,
                label: 'Name',
                hint: 'Teacher Name',
                icon: Icons.person_outline_rounded,
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter teacher name'
                    : null,
              ),
              _buildTextField(
                controller: _emailController,
                label: 'Email',
                hint: 'Email Address',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Please enter email address';
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value))
                    return 'Please enter a valid email';
                  return null;
                },
              ),
              _buildTextField(
                controller: _phoneController,
                label: 'Phone Number',
                hint: 'Enter phone number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter phone number'
                    : null,
              ),
              _buildTextField(
                controller: _whatsappController,
                label: 'Whatsapp Number',
                hint: 'Enter whatsapp number',
                icon: Icons.message_outlined, // Using message icon for WhatsApp
                keyboardType: TextInputType.phone,
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter WhatsApp number'
                    : null,
              ),
              _buildTextField(
                controller: _subjectsController,
                label: 'Subjects',
                hint: 'Subject(s) taught (e.g., Maths, Science)',
                icon: Icons.book_outlined,
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter subject(s)'
                    : null,
              ),

              // --- Assigned Classes Dropdown ---
              _buildDropdownField(
                label: 'Assigned Classes',
                hint: 'Select Classes',
                items: _availableClasses,
                selectedItems: _selectedClasses,
                onChanged: (selected) {
                  setState(() {
                    _selectedClasses = selected ?? [];
                  });
                },
                validator: (value) => _selectedClasses.isEmpty
                    ? 'Please select at least one class'
                    : null,
              ),

              const SizedBox(height: kDefaultPadding * 1.5),

              // --- Status Message ---
              AnimatedOpacity(
                opacity: _statusMessage != null ? 1.0 : 0.0,
                duration: 300.ms,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: kDefaultPadding,
                        vertical: kDefaultPadding * 0.6),
                    decoration: BoxDecoration(
                      color: _isError
                          ? kErrorColor.withOpacity(0.1)
                          : kSuccessColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(kDefaultRadius),
                      border: Border.all(
                          color: _isError ? kErrorColor : kSuccessColor,
                          width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isError
                              ? Icons.error_outline_rounded
                              : Icons.check_circle_outline_rounded,
                          color: _isError ? kErrorColor : kSuccessColor,
                          size: 20,
                        ),
                        const SizedBox(width: kDefaultPadding / 2),
                        Text(
                          _statusMessage ?? '',
                          style: textTheme.bodyMedium?.copyWith(
                            color: _isError ? kErrorColor : kSuccessColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: kDefaultPadding),

              // --- Submit Button ---
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitForm,
                        child: const Text('Submit'),
                      ),
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.5),

              const SizedBox(
                  height: kDefaultPadding * 2), // Extra space at bottom
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
        backgroundColor: Colors.white, // Or kSecondaryColor
      ),
    );
  }

  // --- Helper Widgets for Form Fields ---

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    bool obscureText = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: kDefaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: kDefaultPadding / 2),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Icon(icon, size: 20), // Smaller icon
              // Using theme's input decoration
            ),
            validator: validator,
            autovalidateMode: AutovalidateMode.onUserInteraction,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String hint,
    required List<String> items,
    required List<String> selectedItems,
    required void Function(List<String>?) onChanged,
    String? Function(List<String>?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: kDefaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: kDefaultPadding / 2),
          DropdownButtonFormField<List<String>>(
            // The type needs to match the value
            value: selectedItems.isEmpty
                ? null
                : selectedItems, // Handle empty selection for hint
            isExpanded: true,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Icon(Icons.class_outlined, size: 20),
              // Using theme's input decoration
            ),
            items: [
              // Wrap items in a way to allow multi-select visualization
              // This standard DropdownButtonFormField doesn't directly support multi-select UI like checkboxes.
              // We'll display the selected items as a comma-separated string.
              // A more complex UI would require a custom dropdown or package.
              DropdownMenuItem<List<String>>(
                value: selectedItems, // Represents the current selection
                child: Text(
                  selectedItems.isEmpty ? hint : selectedItems.join(', '),
                  style:
                      selectedItems.isEmpty ? kHintTextStyle : kBodyTextStyle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Add dummy items to trigger the dropdown, actual selection happens in onTap/showDialog
            ],
            onChanged: (value) {
              // This onChanged won't be directly used for selection updates
              // because the selection happens in the dialog.
            },
            onTap: () async {
              // Hide keyboard if open
              FocusScope.of(context).unfocus();
              // Show multi-select dialog
              final List<String>? result = await showDialog<List<String>>(
                context: context,
                builder: (BuildContext context) {
                  return MultiSelectDialog(
                    items: items,
                    initialSelectedItems: selectedItems,
                  );
                },
              );
              if (result != null) {
                onChanged(result); // Update state with selection from dialog
              }
            },
            // Custom validator needed as the value is List<String>
            validator: (value) {
              if (selectedItems.isEmpty) {
                return 'Please select at least one class';
              }
              return null; // Validation passed
            },
            autovalidateMode: AutovalidateMode.onUserInteraction,
            // Display selected items in the dropdown field itself
            selectedItemBuilder: (context) {
              return items
                  .map((_) => Text(
                        selectedItems.join(', '),
                        style: kBodyTextStyle,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ))
                  .toList(); // Needs a list of widgets
            },
          ),
        ],
      ),
    );
  }
}

// --- Helper Dialog for Multi-Select ---

class MultiSelectDialog extends StatefulWidget {
  final List<String> items;
  final List<String> initialSelectedItems;

  const MultiSelectDialog({
    super.key,
    required this.items,
    required this.initialSelectedItems,
  });

  @override
  State<MultiSelectDialog> createState() => _MultiSelectDialogState();
}

class _MultiSelectDialogState extends State<MultiSelectDialog> {
  late List<String> _selectedItems;

  @override
  void initState() {
    super.initState();
    _selectedItems = List.from(widget.initialSelectedItems);
  }

  void _itemChange(String itemValue, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedItems.add(itemValue);
      } else {
        _selectedItems.remove(itemValue);
      }
    });
  }

  void _cancel() {
    Navigator.pop(context);
  }

  void _submit() {
    Navigator.pop(context, _selectedItems);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Classes'),
      content: SingleChildScrollView(
        child: ListBody(
          children: widget.items.map((item) {
            return CheckboxListTile(
              value: _selectedItems.contains(item),
              title: Text(item),
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (isChecked) => _itemChange(item, isChecked!),
              activeColor: kPrimaryColor,
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _cancel,
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Submit'),
        ),
      ],
    );
  }
}
