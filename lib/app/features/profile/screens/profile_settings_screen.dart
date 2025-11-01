// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:edu_track/app/features/authentication/controllers/auth_controller.dart'; // Keep if needed for direct auth access
import 'package:edu_track/app/features/profile/controllers/profile_controller.dart'; // Import the controller
import 'package:edu_track/app/utils/constants.dart';
import 'package:edu_track/app/widgets/dialogs.dart'; // Assuming dialogs are here
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart'; // For animations

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  // Initialize ProfileController using Get.find()
  final ProfileController _controller = Get.find<ProfileController>();

  // Local controllers for text fields - sync with controller state
  final _nameController = TextEditingController();
  final _academyNameController = TextEditingController();
  final _smsTokenController = TextEditingController();
  final _emailController = TextEditingController(); // For display/change dialog
  final _passwordController =
      TextEditingController(); // For change password dialog
  final _newEmailController =
      TextEditingController(); // For change email dialog
  final _currentPasswordForEmailChangeController =
      TextEditingController(); // For change email dialog

  // Remove local state variables managed by the controller
  // bool _isEditing = false;
  // bool _isLoading = false;
  // String? _statusMessage;
  // bool _isError = false;
  // String _currentName = '';
  // String _currentAcademyName = '';
  // String _currentSmsToken = '';
  // String? _currentProfilePhotoUrl;
  // String? _currentEmail;

  // --- Listeners to sync TextControllers with Controller State ---
  @override
  void initState() {
    super.initState();
    // Add listeners to update text fields when controller state changes
    _controller.name.listen((value) {
      if (_nameController.text != value) _nameController.text = value ?? '';
    });
    _controller.academyName.listen((value) {
      if (_academyNameController.text != value)
        _academyNameController.text = value ?? '';
    });
    _controller.smsToken.listen((value) {
      if (_smsTokenController.text != value)
        _smsTokenController.text = value ?? '';
    });
    // Initial sync in case controller loaded data before listeners attached
    _nameController.text = _controller.name.value ?? '';
    _academyNameController.text = _controller.academyName.value ?? '';
    _smsTokenController.text = _controller.smsToken.value ?? '';
    _emailController.text = _controller.email.value ?? ''; // Sync email display
  }

  @override
  void dispose() {
    _nameController.dispose();
    _academyNameController.dispose();
    _smsTokenController.dispose();
    _emailController.dispose(); // Still needed for display
    _passwordController.dispose(); // Still needed for dialog
    _newEmailController.dispose();
    _currentPasswordForEmailChangeController.dispose();
    super.dispose();
  }

  // --- Action Handlers (Delegate to Controller) ---

  void _toggleEdit() {
    // Pass current text field values to controller when starting edit
    _controller.toggleEdit(
      !_controller.isEditing.value,
      currentName: _nameController.text,
      currentAcademy: _academyNameController.text,
      currentSms: _smsTokenController.text,
    );
  }

  void _saveChanges() {
    // Hide keyboard
    FocusScope.of(context).unfocus();
    // Validate if needed (can add a Form widget)
    _controller.updateProfileDetails(
      newName: _nameController.text.trim(),
      newAcademyName: _academyNameController.text.trim(),
      newSmsToken:
          _smsTokenController.text.trim(), // Assuming token doesn't need trim
    );
  }

  void _changeEmail() {
    // Clear previous values
    _newEmailController.clear();
    _currentPasswordForEmailChangeController.clear();

    Dialogs.showCustomDialog(
      context: context,
      title: 'Change Email',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Current Email: ${_controller.email.value ?? 'N/A'}'),
          const SizedBox(height: kDefaultPadding),
          TextField(
            controller: _newEmailController,
            decoration: const InputDecoration(
                labelText: 'New Email', prefixIcon: Icon(Icons.email_outlined)),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: kDefaultPadding),
          TextField(
            controller: _currentPasswordForEmailChangeController,
            decoration: const InputDecoration(
                labelText: 'Current Password',
                prefixIcon: Icon(Icons.lock_outline)),
            obscureText: true,
          ),
        ],
      ),
      confirmText: 'Confirm Change',
      onConfirm: () {
        final newEmail = _newEmailController.text.trim();
        final password = _currentPasswordForEmailChangeController.text;
        if (newEmail.isNotEmpty &&
            password.isNotEmpty &&
            GetUtils.isEmail(newEmail)) {
          Navigator.of(context).pop(); // Close dialog first
          _controller.changeEmail(newEmail, password);
        } else {
          // Show simple snackbar for validation within dialog
          Get.snackbar('Error',
              'Please enter a valid new email and your current password.',
              snackPosition: SnackPosition.BOTTOM,
              margin: const EdgeInsets.all(kDefaultPadding));
        }
      },
    );
  }

  void _changePassword() {
    Dialogs.showConfirmationDialog(
      context: context,
      title: 'Change Password',
      message:
          'Are you sure you want to send a password reset link to your email (${_controller.email.value ?? 'N/A'})?',
      confirmText: 'Send Link',
      onConfirm: () {
        Navigator.of(context).pop(); // Close dialog
        _controller.sendPasswordReset();
      },
    );
  }

  void _pickImage() {
    _controller.pickAndUploadImage();
  }

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // final colorScheme = Theme.of(context).colorScheme; // Keep if needed

    // Use GetBuilder for reacting to controller state changes
    return GetBuilder<ProfileController>(
        init: _controller, // Initialize if not already done by binding
        builder: (controller) {
          // Use 'controller' instead of '_controller' inside builder
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded,
                    color: kLightTextColor),
                tooltip: 'Back',
                onPressed: () => Get.back(), // Use GetX navigation
              ),
              title: Text('Profile Settings', style: textTheme.titleLarge),
              centerTitle: true,
              backgroundColor: kBackgroundColor,
              elevation: 0,
            ),
            body: Obx(() => controller
                    .isLoading.value // Use Obx for simple boolean checks
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh:
                        controller.fetchProfileData, // Call controller method
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(kDefaultPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // --- Profile Picture ---
                          // --- Profile Picture ---
                          Obx(() {
                            final hasPhoto = controller.profilePhotoUrl.value !=
                                    null &&
                                controller.profilePhotoUrl.value!.isNotEmpty;
                            return Stack(
                              // Use Obx for profilePhotoUrl
                              alignment: Alignment.bottomRight,
                              children: [
                                hasPhoto
                                    ? CircleAvatar(
                                        radius: 60,
                                        backgroundImage: NetworkImage(
                                            controller.profilePhotoUrl.value!),
                                        onBackgroundImageError:
                                            (exception, stackTrace) {
                                          print(
                                              "Error loading profile image: $exception");
                                        },
                                      )
                                    : CircleAvatar(
                                        radius: 60,
                                        backgroundColor:
                                            kLightTextColor.withOpacity(0.2),
                                        child: Icon(Icons.person_rounded,
                                            size: 60, color: kLightTextColor),
                                      ),
                                if (controller
                                    .isEditing.value) // Use controller state
                                  Positioned(
                                    right: 4,
                                    bottom: 4,
                                    child: Material(
                                      color: kPrimaryColor,
                                      shape: const CircleBorder(),
                                      elevation: 2,
                                      child: InkWell(
                                        onTap: _pickImage,
                                        customBorder: const CircleBorder(),
                                        child: const Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Icon(Icons.edit,
                                              color: kSecondaryColor, size: 20),
                                        ),
                                      ),
                                    ),
                                  )
                                      .animate()
                                      .scale(delay: 100.ms), // Add animation
                              ],
                            );
                          }),
                          const SizedBox(height: kDefaultPadding * 2),

                          // --- User Details Section ---
                          // Use Obx to rebuild text fields when isEditing changes
                          Obx(() => _buildTextField(
                                controller: _nameController,
                                label: 'Name',
                                hint: 'Your Name',
                                icon: Icons.person_outline_rounded,
                                readOnly: !controller.isEditing.value,
                              )),
                          Obx(() => _buildTextField(
                                controller: _academyNameController,
                                label: 'Academy Name',
                                hint: 'Your Academy Name',
                                icon: Icons.school_outlined,
                                readOnly: !controller.isEditing.value,
                              )),
                          Obx(() => _buildTextField(
                                controller: _smsTokenController,
                                label: 'SMS Gateway Token',
                                hint: 'Enter SMS Token',
                                icon: Icons.vpn_key_outlined,
                                obscureText: !controller.isEditing
                                    .value, // Obscure when not editing
                                readOnly: !controller.isEditing.value,
                              )),
                          const SizedBox(height: kDefaultPadding),

                          // --- Edit/Save/Cancel Buttons ---
                          // Use Obx to switch between buttons
                          Obx(() {
                            if (!controller.isEditing.value) {
                              return SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  icon:
                                      const Icon(Icons.edit_outlined, size: 18),
                                  label: const Text('Edit Details'),
                                  onPressed: _toggleEdit,
                                ),
                              ).animate().fadeIn(delay: 100.ms);
                            } else {
                              return Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: _saveChanges,
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: kSuccessColor),
                                      child: const Text('Save'),
                                    ),
                                  ),
                                  const SizedBox(width: kDefaultPadding),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed:
                                          _toggleEdit, // Cancel calls toggleEdit
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: kErrorColor),
                                      child: const Text('Cancel'),
                                    ),
                                  ),
                                ],
                              ).animate().fadeIn(delay: 100.ms);
                            }
                          }),
                          const SizedBox(height: kDefaultPadding * 1.5),
                          const Divider(),
                          const SizedBox(height: kDefaultPadding * 1.5),

                          // --- Email Section ---
                          // Use Obx for email value
                          Obx(() => _buildInfoFieldWithButton(
                                label: 'Email',
                                value:
                                    controller.email.value ?? 'Not available',
                                icon: Icons.email_outlined,
                                buttonLabel: 'Change',
                                onButtonPressed: _changeEmail,
                              )),

                          // --- Password Section ---
                          _buildInfoFieldWithButton(
                            label: 'Password',
                            value: '********', // Always show placeholder
                            icon: Icons.lock_outline_rounded,
                            buttonLabel: 'Change',
                            onButtonPressed: _changePassword,
                          ),

                          const SizedBox(height: kDefaultPadding * 1.5),
                          const Divider(),
                          const SizedBox(height: kDefaultPadding * 1.5),

                          // --- Academy Subjects Management Section ---
                          _buildAcademySubjectsSection(),

                          const SizedBox(height: kDefaultPadding * 1.5),

                          // --- Status Message ---
                          // Use Obx for status message visibility and content
                          Obx(() {
                            final message = controller.statusMessage.value;
                            final isError = controller.isError.value;
                            return AnimatedOpacity(
                              opacity: message != null ? 1.0 : 0.0,
                              duration: 300.ms,
                              child: message == null
                                  ? const SizedBox
                                      .shrink() // Don't take space if null
                                  : Container(
                                      width: double.infinity,
                                      margin: const EdgeInsets.only(
                                          bottom:
                                              kDefaultPadding), // Add margin below
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: kDefaultPadding,
                                          vertical: kDefaultPadding * 0.7),
                                      decoration: BoxDecoration(
                                        color: isError
                                            ? kErrorColor.withOpacity(0.1)
                                            : kSuccessColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(
                                            kDefaultRadius),
                                        border: Border.all(
                                            color: isError
                                                ? kErrorColor
                                                : kSuccessColor,
                                            width: 1),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            isError
                                                ? Icons.error_outline_rounded
                                                : Icons
                                                    .check_circle_outline_rounded,
                                            color: isError
                                                ? kErrorColor
                                                : kSuccessColor,
                                            size: 20,
                                          ),
                                          const SizedBox(
                                              width: kDefaultPadding / 2),
                                          Flexible(
                                            child: Text(
                                              message,
                                              style: textTheme.bodyMedium
                                                  ?.copyWith(
                                                color: isError
                                                    ? kErrorColor
                                                    : kSuccessColor,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                            );
                          }),
                          // Removed SizedBox below status, added margin above
                        ],
                      ),
                    ),
                  )),
          );
        }); // Close GetBuilder
  }

  // --- Helper Widgets (Keep as they are, but ensure context is available) ---

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
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
            readOnly: readOnly,
            obscureText: obscureText,
            keyboardType: keyboardType,
            style: readOnly // Dim text color when read-only
                ? Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: kLightTextColor)
                : Theme.of(context).textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Icon(icon,
                  size: 20,
                  color: readOnly
                      ? kLightTextColor
                      : kPrimaryColor), // Adjust icon color
              filled: true,
              fillColor: readOnly
                  ? kBackgroundColor.withOpacity(0.3)
                  : kSecondaryColor, // Adjust fill color
              // Use theme's input decoration for borders etc.
            ),
            validator: validator, // Keep validator if needed
            autovalidateMode: AutovalidateMode.onUserInteraction,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoFieldWithButton({
    required String label,
    required String value,
    required IconData icon,
    required String buttonLabel,
    required VoidCallback onButtonPressed,
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
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: kDefaultPadding * 0.9,
                      horizontal: kDefaultPadding),
                  decoration: BoxDecoration(
                    color: kBackgroundColor
                        .withOpacity(0.5), // Greyed out background
                    borderRadius: BorderRadius.circular(kDefaultRadius),
                  ),
                  child: Row(
                    children: [
                      Icon(icon, size: 20, color: kLightTextColor),
                      const SizedBox(width: kDefaultPadding / 2),
                      Expanded(
                        // Ensure text doesn't overflow
                        child: Text(
                          value,
                          style: kBodyTextStyle.copyWith(
                              color: kTextColor
                                  .withOpacity(0.8)), // Slightly dimmer text
                          overflow: TextOverflow.ellipsis, // Prevent overflow
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: kDefaultPadding / 2),
              ElevatedButton(
                onPressed: onButtonPressed,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: kDefaultPadding * 1.2,
                      vertical: kDefaultPadding * 0.7),
                  minimumSize: Size.zero, // Allow button to shrink
                  textStyle: kBodyTextStyle.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w500), // Smaller button text
                ),
                child: Text(buttonLabel),
              ).animate().fadeIn(delay: 200.ms), // Add animation
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAcademySubjectsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.school_outlined, size: 20, color: kPrimaryColor),
            const SizedBox(width: kDefaultPadding / 2),
            Text(
              'Academy Subjects',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _showManageSubjectsDialog,
              icon: const Icon(Icons.settings_outlined, size: 18),
              label: const Text('Manage Subjects'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: kDefaultPadding,
                    vertical: kDefaultPadding * 0.6),
                textStyle: kBodyTextStyle.copyWith(
                    fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        const SizedBox(height: kDefaultPadding),
        Obx(() {
          if (_controller.academySubjects.isEmpty) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(kDefaultPadding * 2),
              decoration: BoxDecoration(
                color: kBackgroundColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(kDefaultRadius),
                border: Border.all(color: kLightTextColor.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Icon(Icons.subject_outlined,
                      size: 48, color: kLightTextColor),
                  const SizedBox(height: kDefaultPadding),
                  Text(
                    'No subjects configured yet',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: kLightTextColor),
                  ),
                  const SizedBox(height: kDefaultPadding / 2),
                  Text(
                    'Tap "Manage Subjects" to add subjects',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: kLightTextColor),
                  ),
                ],
              ),
            );
          }

          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(kDefaultPadding),
            decoration: BoxDecoration(
              color: kPrimaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(kDefaultRadius),
              border: Border.all(color: kPrimaryColor.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.subject, size: 16, color: kPrimaryColor),
                    const SizedBox(width: kDefaultPadding * 0.5),
                    Text(
                      'Current Subjects (${_controller.academySubjects.length})',
                      style: kBodyTextStyle.copyWith(
                        color: kPrimaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: kDefaultPadding * 0.75),
                Wrap(
                  spacing: kDefaultPadding * 0.5,
                  runSpacing: kDefaultPadding * 0.5,
                  children: _controller.academySubjects.map((subject) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: kDefaultPadding * 0.75,
                          vertical: kDefaultPadding * 0.4),
                      decoration: BoxDecoration(
                        color: kPrimaryColor.withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(kDefaultRadius * 1.5),
                        border:
                            Border.all(color: kPrimaryColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        subject,
                        style: kBodyTextStyle.copyWith(
                          color: kPrimaryColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  void _showManageSubjectsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kDefaultRadius),
        ),
        title: Row(
          children: [
            Icon(Icons.school_outlined, color: kPrimaryColor, size: 24),
            const SizedBox(width: kDefaultPadding * 0.5),
            const Text('Manage Academy Subjects'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400, // Set fixed height for the dialog
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Add Subject Section
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _addSubjectInDialog(),
                      icon: const Icon(Icons.add_outlined, size: 18),
                      label: const Text('Add New Subject'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kSuccessColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: kDefaultPadding),
              const Divider(),
              const SizedBox(height: kDefaultPadding * 0.5),

              // Current Subjects Header
              Row(
                children: [
                  Icon(Icons.list_alt_outlined, size: 18, color: kPrimaryColor),
                  const SizedBox(width: kDefaultPadding * 0.5),
                  const Text(
                    'Current Subjects',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: kDefaultPadding),

              // Subjects List
              Expanded(
                child: Obx(() {
                  if (_controller.academySubjects.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.subject_outlined,
                              size: 64, color: kLightTextColor),
                          const SizedBox(height: kDefaultPadding),
                          Text(
                            'No subjects added yet',
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(color: kLightTextColor),
                          ),
                          const SizedBox(height: kDefaultPadding * 0.5),
                          Text(
                            'Add your first subject to get started',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: kLightTextColor),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: _controller.academySubjects.length,
                    itemBuilder: (context, index) {
                      final subject = _controller.academySubjects[index];
                      return Card(
                        margin: const EdgeInsets.only(
                            bottom: kDefaultPadding * 0.5),
                        elevation: 1,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: kPrimaryColor.withOpacity(0.1),
                            child: Icon(Icons.subject,
                                color: kPrimaryColor, size: 20),
                          ),
                          title: Text(
                            subject,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(
                              'Subject ${index + 1} of ${_controller.academySubjects.length}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit_outlined,
                                    color: kPrimaryColor, size: 20),
                                tooltip: 'Edit Subject',
                                onPressed: () =>
                                    _editSubjectInDialog(index, subject),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete_outline,
                                    color: kErrorColor, size: 20),
                                tooltip: 'Remove Subject',
                                onPressed: () =>
                                    _removeSubjectInDialog(subject),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _addSubjectInDialog() {
    final TextEditingController subjectController = TextEditingController();

    Dialogs.showCustomDialog(
      context: context,
      title: 'Add New Subject',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: subjectController,
            decoration: const InputDecoration(
              labelText: 'Subject Name',
              hintText: 'Enter subject name (e.g., Mathematics)',
              prefixIcon: Icon(Icons.subject),
            ),
            autofocus: true,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: kDefaultPadding),
          Text(
            'This subject will be available for all students and payment records.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: kLightTextColor),
          ),
        ],
      ),
      confirmText: 'Add Subject',
      onConfirm: () {
        final subject = subjectController.text.trim();
        if (subject.isNotEmpty) {
          Navigator.of(context).pop();
          _controller.addSubject(subject);
        } else {
          Get.snackbar(
            'Error',
            'Please enter a subject name.',
            snackPosition: SnackPosition.BOTTOM,
            margin: const EdgeInsets.all(kDefaultPadding),
          );
        }
      },
    );
  }

  void _editSubjectInDialog(int index, String currentSubject) {
    final TextEditingController subjectController =
        TextEditingController(text: currentSubject);

    Dialogs.showCustomDialog(
      context: context,
      title: 'Edit Subject',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: subjectController,
            decoration: const InputDecoration(
              labelText: 'Subject Name',
              hintText: 'Enter subject name',
              prefixIcon: Icon(Icons.subject),
            ),
            autofocus: true,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: kDefaultPadding),
          Text(
            'Changes will apply to future student registrations and payment records.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: kLightTextColor),
          ),
        ],
      ),
      confirmText: 'Save Changes',
      onConfirm: () {
        final subject = subjectController.text.trim();
        if (subject.isNotEmpty && subject != currentSubject) {
          Navigator.of(context).pop();
          _controller.editSubject(index, subject);
        } else if (subject.isEmpty) {
          Get.snackbar(
            'Error',
            'Please enter a subject name.',
            snackPosition: SnackPosition.BOTTOM,
            margin: const EdgeInsets.all(kDefaultPadding),
          );
        } else {
          Navigator.of(context).pop(); // No changes made
        }
      },
    );
  }

  void _removeSubjectInDialog(String subject) {
    Dialogs.showConfirmationDialog(
      context: context,
      title: 'Remove Subject',
      message:
          'Are you sure you want to remove "$subject" from academy subjects?\n\n'
          'This will not affect existing student records but the subject won\'t be available for new registrations.',
      confirmText: 'Remove',
      onConfirm: () {
        Navigator.of(context).pop();
        _controller.removeSubject(subject);
      },
    );
  }
}
