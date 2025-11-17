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
  final _emailController = TextEditingController(); // For display/change dialog
  final _passwordController =
      TextEditingController(); // For change password dialog
  final _newEmailController =
      TextEditingController(); // For change email dialog
  final _currentPasswordForEmailChangeController =
      TextEditingController(); // For change email dialog

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
    // Initial sync in case controller loaded data before listeners attached
    _nameController.text = _controller.name.value ?? '';
    _academyNameController.text = _controller.academyName.value ?? '';
    _emailController.text = _controller.email.value ?? ''; // Sync email display
  }

  @override
  void dispose() {
    _nameController.dispose();
    _academyNameController.dispose();
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
    );
  }

  void _saveChanges() {
    // Hide keyboard
    FocusScope.of(context).unfocus();
    // Validate if needed (can add a Form widget)
    _controller.updateProfileDetails(
      newName: _nameController.text.trim(),
      newAcademyName: _academyNameController.text.trim(),
      newSmsToken: _controller.smsToken.value ?? '',
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
          Dialogs.showSnackbar('Error',
              'Please enter a valid new email and your current password.',
              isError: true);
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
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                tooltip: 'Back',
                onPressed: () => Get.back(), // Use GetX navigation
              ),
              title: Text('Profile Settings', style: textTheme.titleLarge),
              centerTitle: true,
              actions: [
                Obx(() => controller.isEditing.value
                    ? const SizedBox.shrink()
                    : IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Edit Profile',
                        onPressed: _toggleEdit,
                      ).animate().fadeIn(delay: 100.ms)),
              ],
            ),
            body: Obx(() => controller.isLoading.value
                ? const Center(child: CircularProgressIndicator())
                : Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFF9F7FF), Color(0xFFF6FAFF)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: RefreshIndicator(
                      onRefresh: controller.fetchProfileData,
                      child: LayoutBuilder(
                        builder: (context, outerConstraints) {
                          final horizontalInset =
                              outerConstraints.maxWidth > 900
                                  ? kDefaultPadding * 1.5
                                  : kDefaultPadding;
                          return SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: Center(
                              child: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 1100),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: horizontalInset,
                                    vertical: kDefaultPadding * 1.5,
                                  ),
                                  child: LayoutBuilder(
                                    builder: (context, contentConstraints) {
                                      final bool allowTwoColumns =
                                          contentConstraints.maxWidth > 720;
                                      final double spacing =
                                          kDefaultPadding * 1.4;
                                      final double sectionWidth =
                                          allowTwoColumns
                                              ? (contentConstraints.maxWidth -
                                                      spacing) /
                                                  2
                                              : contentConstraints.maxWidth;

                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          SizedBox(
                                            height: allowTwoColumns
                                                ? kDefaultPadding
                                                : kDefaultPadding * 0.6,
                                          ),
                                          Wrap(
                                            spacing: spacing,
                                            runSpacing: spacing,
                                            children: [
                                              SizedBox(
                                                width:
                                                    contentConstraints.maxWidth,
                                                child: _buildProfileHeroCard(
                                                    controller, textTheme),
                                              )
                                                  .animate()
                                                  .fadeIn(duration: 400.ms)
                                                  .slideY(
                                                      begin: -0.2,
                                                      duration: 400.ms),
                                              SizedBox(
                                                width: sectionWidth,
                                                child: _buildPersonalInfoCard(
                                                    controller, textTheme),
                                              )
                                                  .animate()
                                                  .fadeIn(
                                                      delay: 200.ms,
                                                      duration: 400.ms)
                                                  .slideY(
                                                      begin: 0.1,
                                                      duration: 400.ms),
                                              SizedBox(
                                                width: sectionWidth,
                                                child: _buildSecurityCard(
                                                    controller, textTheme),
                                              )
                                                  .animate()
                                                  .fadeIn(
                                                      delay: 300.ms,
                                                      duration: 400.ms)
                                                  .slideY(
                                                      begin: 0.1,
                                                      duration: 400.ms),
                                              SizedBox(
                                                width: sectionWidth,
                                                child: _buildSectionCard(
                                                  child:
                                                      _buildAcademySubjectsSection(),
                                                ),
                                              )
                                                  .animate()
                                                  .fadeIn(
                                                      delay: 400.ms,
                                                      duration: 400.ms)
                                                  .slideY(
                                                      begin: 0.1,
                                                      duration: 400.ms),
                                            ],
                                          ),
                                          const SizedBox(
                                              height: kDefaultPadding * 1.5),
                                          _buildStatusBanner(textTheme),
                                          const SizedBox(
                                              height: kDefaultPadding),
                                          _buildLogoutButton(context)
                                              .animate()
                                              .fadeIn(
                                                  delay: 500.ms,
                                                  duration: 400.ms)
                                              .slideY(
                                                  begin: 0.1, duration: 400.ms),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  )),
          );
        }); // Close GetBuilder
  }

  // --- Helper Widgets (composition helpers) ---

  Widget _buildProfileHeroCard(
      ProfileController controller, TextTheme textTheme) {
    return _buildSectionCard(
      padding: const EdgeInsets.all(kDefaultPadding * 1.6),
      gradient: const LinearGradient(
        colors: [Color(0xFFFFFFFF), Color(0xFFF1EEFF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        children: [
          Obx(() {
            final hasPhoto = controller.profilePhotoUrl.value != null &&
                controller.profilePhotoUrl.value!.isNotEmpty;
            return Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: kPrimaryColor.withOpacity(0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: hasPhoto
                      ? CircleAvatar(
                          radius: 60,
                          backgroundColor: kSecondaryColor,
                          child: CircleAvatar(
                            radius: 58,
                            backgroundImage:
                                NetworkImage(controller.profilePhotoUrl.value!),
                            onBackgroundImageError: (exception, stackTrace) {
                              print('Error loading profile image: $exception');
                            },
                          ),
                        )
                      : CircleAvatar(
                          radius: 60,
                          backgroundColor: kSecondaryColor,
                          child: CircleAvatar(
                            radius: 58,
                            backgroundColor: kPrimaryColor.withOpacity(0.08),
                            child: Icon(Icons.person_rounded,
                                size: 60, color: kPrimaryColor),
                          ),
                        ),
                ),
                if (controller.isEditing.value)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Material(
                      color: kPrimaryColor,
                      shape: const CircleBorder(),
                      elevation: 4,
                      child: InkWell(
                        onTap: _pickImage,
                        customBorder: const CircleBorder(),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          child: const Icon(Icons.camera_alt,
                              color: kSecondaryColor, size: 20),
                        ),
                      ),
                    ),
                  ).animate().scale(delay: 100.ms, duration: 300.ms),
              ],
            );
          }),
          const SizedBox(height: kDefaultPadding),
          Obx(() => Text(
                controller.name.value ?? 'User Name',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: kTextColor,
                ),
                textAlign: TextAlign.center,
              )),
          const SizedBox(height: kDefaultPadding / 4),
          Obx(() => Text(
                controller.email.value ?? 'user@example.com',
                style: textTheme.bodyMedium?.copyWith(
                  color: kLightTextColor,
                ),
                textAlign: TextAlign.center,
              )),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoCard(
      ProfileController controller, TextTheme textTheme) {
    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_outline, color: kPrimaryColor, size: 20),
              const SizedBox(width: kDefaultPadding / 2),
              Text(
                'Personal Information',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: kDefaultPadding * 1.5),
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
          Obx(() {
            if (!controller.isEditing.value) {
              return const SizedBox.shrink();
            }
            return Column(
              children: [
                const SizedBox(height: kDefaultPadding),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _saveChanges,
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Save Changes'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kSuccessColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: kDefaultPadding),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _toggleEdit,
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Cancel'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kErrorColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ).animate().fadeIn(delay: 100.ms);
          }),
        ],
      ),
    );
  }

  Widget _buildSecurityCard(ProfileController controller, TextTheme textTheme) {
    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.security, color: kPrimaryColor, size: 20),
              const SizedBox(width: kDefaultPadding / 2),
              Text(
                'Account Security',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: kDefaultPadding * 1.5),
          Obx(() => _buildInfoFieldWithButton(
                label: 'Email',
                value: controller.email.value ?? 'Not available',
                icon: Icons.email_outlined,
                buttonLabel: 'Change',
                onButtonPressed: _changeEmail,
              )),
          _buildInfoFieldWithButton(
            label: 'Password',
            value: '••••••••',
            icon: Icons.lock_outline_rounded,
            buttonLabel: 'Change',
            onButtonPressed: _changePassword,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner(TextTheme textTheme) {
    return Obx(() {
      final message = _controller.statusMessage.value;
      final isError = _controller.isError.value;
      if (message == null) {
        return const SizedBox.shrink();
      }
      return AnimatedOpacity(
        opacity: 1.0,
        duration: 300.ms,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(kDefaultPadding * 1.2),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isError
                  ? [
                      kErrorColor.withOpacity(0.15),
                      kErrorColor.withOpacity(0.08),
                    ]
                  : [
                      kSuccessColor.withOpacity(0.15),
                      kSuccessColor.withOpacity(0.08),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(kDefaultRadius),
            border: Border.all(
              color: isError
                  ? kErrorColor.withOpacity(0.3)
                  : kSuccessColor.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isError
                    ? kErrorColor.withOpacity(0.1)
                    : kSuccessColor.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isError
                      ? kErrorColor.withOpacity(0.15)
                      : kSuccessColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isError
                      ? Icons.error_outline_rounded
                      : Icons.check_circle_outline_rounded,
                  color: isError ? kErrorColor : kSuccessColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: kDefaultPadding),
              Expanded(
                child: Text(
                  message,
                  style: textTheme.bodyMedium?.copyWith(
                    color: isError ? kErrorColor : kSuccessColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ).animate().fadeIn(duration: 300.ms).slideY(
            begin: -0.3,
            duration: 300.ms,
          );
    });
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(kDefaultRadius * 1.5),
              ),
              child: Container(
                padding: const EdgeInsets.all(kDefaultPadding * 1.5),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: kErrorColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.logout_rounded,
                              color: kErrorColor, size: 24),
                        ),
                        const SizedBox(width: kDefaultPadding),
                        const Expanded(
                          child: Text(
                            'Logout',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: kDefaultPadding * 1.5),
                    Container(
                      padding: const EdgeInsets.all(kDefaultPadding),
                      decoration: BoxDecoration(
                        color: kErrorColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(kDefaultRadius),
                        border: Border.all(color: kErrorColor.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              size: 18, color: kErrorColor),
                          const SizedBox(width: kDefaultPadding * 0.75),
                          Expanded(
                            child: Text(
                              'Are you sure you want to logout?',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: kTextColor,
                                    fontSize: 13,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: kDefaultPadding * 1.5),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  vertical: kDefaultPadding * 0.8),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: kDefaultPadding),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _controller.signOut();
                            },
                            icon: const Icon(Icons.logout_rounded, size: 18),
                            label: const Text('Logout'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kErrorColor,
                              padding: const EdgeInsets.symmetric(
                                  vertical: kDefaultPadding * 0.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        icon: const Icon(Icons.logout_rounded, size: 20),
        label: const Text('Logout'),
        style: OutlinedButton.styleFrom(
          foregroundColor: kErrorColor,
          side: BorderSide(color: kErrorColor.withOpacity(0.5)),
          padding: const EdgeInsets.symmetric(
            vertical: kDefaultPadding * 0.9,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoHighlights(TextTheme textTheme) {
    return Obx(() {
      final List<Widget> chips = [];
      final academyName = _controller.academyName.value?.trim();
      if (academyName != null && academyName.isNotEmpty) {
        chips.add(_buildHighlightChip(
          icon: Icons.apartment_rounded,
          label: 'Academy',
          value: academyName,
          textTheme: textTheme,
        ));
      }

      final subjectsCount = _controller.academySubjects.length;
      chips.add(_buildHighlightChip(
        icon: Icons.subject_outlined,
        label: 'Active Subjects',
        value: subjectsCount == 1
            ? '1 subject configured'
            : '$subjectsCount subjects configured',
        textTheme: textTheme,
      ));

      final email = _controller.email.value;
      if (email != null && email.isNotEmpty) {
        chips.add(_buildHighlightChip(
          icon: Icons.alternate_email,
          label: 'Primary Email',
          value: email,
          textTheme: textTheme,
        ));
      }

      if (chips.isEmpty) {
        return const SizedBox.shrink();
      }

      return Wrap(
        spacing: kDefaultPadding,
        runSpacing: kDefaultPadding * 0.8,
        children: chips,
      );
    });
  }

  Widget _buildHighlightChip({
    required IconData icon,
    required String label,
    required String value,
    required TextTheme textTheme,
  }) {
    return Container(
      constraints: const BoxConstraints(minWidth: 160),
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding,
        vertical: kDefaultPadding * 0.9,
      ),
      decoration: BoxDecoration(
        color: kSecondaryColor,
        borderRadius: BorderRadius.circular(kDefaultRadius * 1.1),
        border: Border.all(color: kPrimaryColor.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: kPrimaryColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: kPrimaryColor, size: 18),
          ),
          const SizedBox(width: kDefaultPadding * 0.8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.labelSmall?.copyWith(
                    color: kLightTextColor,
                    letterSpacing: 0.4,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: kTextColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required Widget child,
    EdgeInsetsGeometry? padding,
    Gradient? gradient,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        color: gradient == null ? kSecondaryColor : null,
        borderRadius: BorderRadius.circular(kDefaultRadius * 1.1),
        border: Border.all(color: kPrimaryColor.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(kDefaultPadding * 1.5),
        child: child,
      ),
    );
  }

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
      padding: const EdgeInsets.only(bottom: kDefaultPadding * 1.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: kDefaultPadding / 4),
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: kTextColor,
                  ),
            ),
          ),
          const SizedBox(height: kDefaultPadding / 2),
          TextFormField(
            controller: controller,
            readOnly: readOnly,
            obscureText: obscureText,
            keyboardType: keyboardType,
            style: readOnly
                ? Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: kLightTextColor)
                : Theme.of(context).textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Icon(
                icon,
                size: 20,
                color: readOnly ? kLightTextColor : kPrimaryColor,
              ),
              filled: true,
              fillColor: readOnly
                  ? kBackgroundColor.withOpacity(0.5)
                  : kSecondaryColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(kDefaultRadius),
                borderSide: BorderSide(
                  color: readOnly
                      ? kLightTextColor.withOpacity(0.2)
                      : kPrimaryColor.withOpacity(0.2),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(kDefaultRadius),
                borderSide: BorderSide(
                  color: readOnly
                      ? kLightTextColor.withOpacity(0.2)
                      : kLightTextColor.withOpacity(0.1),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(kDefaultRadius),
                borderSide: const BorderSide(color: kPrimaryColor, width: 2),
              ),
            ),
            validator: validator,
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
      padding: const EdgeInsets.only(bottom: kDefaultPadding * 1.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: kDefaultPadding / 4),
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: kTextColor,
                  ),
            ),
          ),
          const SizedBox(height: kDefaultPadding / 2),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(kDefaultRadius),
              border: Border.all(
                color: kLightTextColor.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: kDefaultPadding,
                      horizontal: kDefaultPadding,
                    ),
                    decoration: BoxDecoration(
                      color: kBackgroundColor.withOpacity(0.5),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(kDefaultRadius - 1),
                        bottomLeft: Radius.circular(kDefaultRadius - 1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(icon, size: 20, color: kLightTextColor),
                        const SizedBox(width: kDefaultPadding * 0.75),
                        Expanded(
                          child: Text(
                            value,
                            style: kBodyTextStyle.copyWith(
                              color: kTextColor,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kPrimaryColor, kPrimaryColor.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(kDefaultRadius - 1),
                      bottomRight: Radius.circular(kDefaultRadius - 1),
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onButtonPressed,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(kDefaultRadius - 1),
                        bottomRight: Radius.circular(kDefaultRadius - 1),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: kDefaultPadding * 1.5,
                          vertical: kDefaultPadding,
                        ),
                        child: Text(
                          buttonLabel,
                          style: kBodyTextStyle.copyWith(
                            color: kSecondaryColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
          ],
        ),
        const SizedBox(height: kDefaultPadding),
        Obx(() {
          if (_controller.academySubjects.isEmpty) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(kDefaultPadding * 2),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    kBackgroundColor.withOpacity(0.5),
                    kBackgroundColor.withOpacity(0.3),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(kDefaultRadius),
                border: Border.all(color: kLightTextColor.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(kDefaultPadding),
                    decoration: BoxDecoration(
                      color: kLightTextColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.subject_outlined,
                        size: 40, color: kLightTextColor),
                  ),
                  const SizedBox(height: kDefaultPadding),
                  Text(
                    'No subjects configured yet',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: kTextColor,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: kDefaultPadding / 2),
                  Text(
                    'Add subjects to organize your academy',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: kLightTextColor),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: kDefaultPadding),
                  ElevatedButton.icon(
                    onPressed: _showManageSubjectsDialog,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add First Subject'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: kDefaultPadding * 1.2,
                        vertical: kDefaultPadding * 0.7,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(kDefaultPadding * 1.2),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      kPrimaryColor.withOpacity(0.08),
                      kPrimaryColor.withOpacity(0.04),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(kDefaultRadius),
                  border: Border.all(color: kPrimaryColor.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: kPrimaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.subject,
                              size: 18, color: kPrimaryColor),
                        ),
                        const SizedBox(width: kDefaultPadding * 0.75),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Active Subjects',
                                style: kBodyTextStyle.copyWith(
                                  color: kTextColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '${_controller.academySubjects.length} subject${_controller.academySubjects.length != 1 ? 's' : ''} configured',
                                style: kBodyTextStyle.copyWith(
                                  color: kLightTextColor,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: kDefaultPadding),
                    Wrap(
                      spacing: kDefaultPadding * 0.6,
                      runSpacing: kDefaultPadding * 0.6,
                      children: _controller.academySubjects.map((subject) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: kDefaultPadding * 0.9,
                            vertical: kDefaultPadding * 0.5,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                kPrimaryColor.withOpacity(0.15),
                                kPrimaryColor.withOpacity(0.1),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(kDefaultRadius),
                            border: Border.all(
                              color: kPrimaryColor.withOpacity(0.3),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: kPrimaryColor.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle,
                                  size: 14, color: kPrimaryColor),
                              const SizedBox(width: kDefaultPadding * 0.4),
                              Text(
                                subject,
                                style: kBodyTextStyle.copyWith(
                                  color: kPrimaryColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: kDefaultPadding),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _showManageSubjectsDialog,
                  icon: const Icon(Icons.settings_outlined, size: 18),
                  label: const Text('Manage Subjects'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: kDefaultPadding,
                      vertical: kDefaultPadding * 0.8,
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  // --- Dialogs (No changes, they are already very well-styled) ---

  void _showManageSubjectsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kDefaultRadius * 1.5),
        ),
        elevation: 8,
        child: Container(
          width: double.maxFinite,
          constraints: const BoxConstraints(maxHeight: 550),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dialog Header with gradient
              Container(
                padding: const EdgeInsets.all(kDefaultPadding * 1.5),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      kPrimaryColor,
                      kPrimaryColor.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(kDefaultRadius * 1.5),
                    topRight: Radius.circular(kDefaultRadius * 1.5),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: kSecondaryColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.school_outlined,
                        color: kSecondaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: kDefaultPadding),
                    const Expanded(
                      child: Text(
                        'Manage Academy Subjects',
                        style: TextStyle(
                          color: kSecondaryColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: kSecondaryColor),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              // Dialog Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(kDefaultPadding * 1.5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Add Subject Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _addSubjectInDialog(),
                          icon: const Icon(Icons.add_circle_outline, size: 20),
                          label: const Text('Add New Subject'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kSuccessColor,
                            foregroundColor: kSecondaryColor,
                            padding: const EdgeInsets.symmetric(
                              vertical: kDefaultPadding * 0.9,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: kDefaultPadding * 1.5),
                      // Current Subjects Header
                      Container(
                        padding: const EdgeInsets.all(kDefaultPadding * 0.8),
                        decoration: BoxDecoration(
                          color: kPrimaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(kDefaultRadius),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.list_alt_outlined,
                                size: 18, color: kPrimaryColor),
                            const SizedBox(width: kDefaultPadding * 0.5),
                            const Text(
                              'Current Subjects',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
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
                                  Container(
                                    padding: const EdgeInsets.all(
                                        kDefaultPadding * 2),
                                    decoration: BoxDecoration(
                                      color: kLightTextColor.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.subject_outlined,
                                        size: 56, color: kLightTextColor),
                                  ),
                                  const SizedBox(height: kDefaultPadding * 1.5),
                                  Text(
                                    'No subjects added yet',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(
                                          color: kTextColor,
                                          fontWeight: FontWeight.w600,
                                        ),
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
                              final subject =
                                  _controller.academySubjects[index];
                              return Container(
                                margin: const EdgeInsets.only(
                                    bottom: kDefaultPadding * 0.75),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      kSecondaryColor,
                                      kPrimaryColor.withOpacity(0.03),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(kDefaultRadius),
                                  border: Border.all(
                                    color: kPrimaryColor.withOpacity(0.2),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: kDefaultPadding,
                                    vertical: kDefaultPadding * 0.4,
                                  ),
                                  leading: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          kPrimaryColor.withOpacity(0.15),
                                          kPrimaryColor.withOpacity(0.08),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(Icons.subject,
                                        color: kPrimaryColor, size: 22),
                                  ),
                                  title: Text(
                                    subject,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Subject ${index + 1} of ${_controller.academySubjects.length}',
                                    style: TextStyle(
                                      color: kLightTextColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () => _editSubjectInDialog(
                                              index, subject),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            child: Icon(Icons.edit_outlined,
                                                color: kPrimaryColor, size: 20),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () =>
                                              _removeSubjectInDialog(subject),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            child: Icon(Icons.delete_outline,
                                                color: kErrorColor, size: 20),
                                          ),
                                        ),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addSubjectInDialog() {
    final TextEditingController subjectController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kDefaultRadius * 1.5),
        ),
        child: Container(
          padding: const EdgeInsets.all(kDefaultPadding * 1.5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: kSuccessColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.add_circle_outline,
                        color: kSuccessColor, size: 24),
                  ),
                  const SizedBox(width: kDefaultPadding),
                  const Text(
                    'Add New Subject',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: kDefaultPadding * 1.5),
              TextField(
                controller: subjectController,
                decoration: InputDecoration(
                  labelText: 'Subject Name',
                  hintText: 'e.g., Mathematics, Physics, English',
                  prefixIcon: const Icon(Icons.subject),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(kDefaultRadius),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(kDefaultRadius),
                    borderSide:
                        const BorderSide(color: kPrimaryColor, width: 2),
                  ),
                ),
                autofocus: true,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: kDefaultPadding),
              Container(
                padding: const EdgeInsets.all(kDefaultPadding),
                decoration: BoxDecoration(
                  color: kPrimaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(kDefaultRadius),
                  border: Border.all(color: kPrimaryColor.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: kPrimaryColor),
                    const SizedBox(width: kDefaultPadding * 0.75),
                    Expanded(
                      child: Text(
                        'This subject will be available for all students and payment records.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: kTextColor,
                              fontSize: 12,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: kDefaultPadding * 1.5),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: kDefaultPadding),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final subject = subjectController.text.trim();
                        if (subject.isNotEmpty) {
                          Navigator.of(context).pop();
                          _controller.addSubject(subject);
                        } else {
                          Get.snackbar(
                            'Error',
                            'Please enter a subject name.',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: kErrorColor.withOpacity(0.9),
                            colorText: kSecondaryColor,
                            margin: const EdgeInsets.all(kDefaultPadding),
                          );
                        }
                      },
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Add Subject'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kSuccessColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _editSubjectInDialog(int index, String currentSubject) {
    final TextEditingController subjectController =
        TextEditingController(text: currentSubject);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kDefaultRadius * 1.5),
        ),
        child: Container(
          padding: const EdgeInsets.all(kDefaultPadding * 1.5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: kPrimaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.edit_outlined,
                        color: kPrimaryColor, size: 24),
                  ),
                  const SizedBox(width: kDefaultPadding),
                  const Text(
                    'Edit Subject',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: kDefaultPadding * 1.5),
              TextField(
                controller: subjectController,
                decoration: InputDecoration(
                  labelText: 'Subject Name',
                  hintText: 'Enter subject name',
                  prefixIcon: const Icon(Icons.subject),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(kDefaultRadius),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(kDefaultRadius),
                    borderSide:
                        const BorderSide(color: kPrimaryColor, width: 2),
                  ),
                ),
                autofocus: true,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: kDefaultPadding),
              Container(
                padding: const EdgeInsets.all(kDefaultPadding),
                decoration: BoxDecoration(
                  color: kPrimaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(kDefaultRadius),
                  border: Border.all(color: kPrimaryColor.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: kPrimaryColor),
                    const SizedBox(width: kDefaultPadding * 0.75),
                    Expanded(
                      child: Text(
                        'Changes will apply to future student registrations and payment records.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: kTextColor,
                              fontSize: 12,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: kDefaultPadding * 1.5),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: kDefaultPadding),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final subject = subjectController.text.trim();
                        if (subject.isNotEmpty && subject != currentSubject) {
                          Navigator.of(context).pop();
                          _controller.editSubject(index, subject);
                        } else if (subject.isEmpty) {
                          Get.snackbar(
                            'Error',
                            'Please enter a subject name.',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: kErrorColor.withOpacity(0.9),
                            colorText: kSecondaryColor,
                            margin: const EdgeInsets.all(kDefaultPadding),
                          );
                        } else {
                          Navigator.of(context).pop();
                        }
                      },
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Save Changes'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _removeSubjectInDialog(String subject) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kDefaultRadius * 1.5),
        ),
        child: Container(
          padding: const EdgeInsets.all(kDefaultPadding * 1.5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: kErrorColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.warning_amber_rounded,
                        color: kErrorColor, size: 24),
                  ),
                  const SizedBox(width: kDefaultPadding),
                  const Expanded(
                    child: Text(
                      'Remove Subject',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: kDefaultPadding * 1.5),
              Container(
                padding: const EdgeInsets.all(kDefaultPadding),
                decoration: BoxDecoration(
                  color: kErrorColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(kDefaultRadius),
                  border: Border.all(color: kErrorColor.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.subject, size: 16, color: kErrorColor),
                        const SizedBox(width: kDefaultPadding * 0.5),
                        Expanded(
                          child: Text(
                            '"$subject"',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: kErrorColor,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: kDefaultPadding * 0.75),
                    Text(
                      'Are you sure you want to remove this subject?\n\n'
                      'This will not affect existing student records but the subject won\'t be available for new registrations.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: kTextColor,
                            fontSize: 13,
                            height: 1.5,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: kDefaultPadding * 1.5),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: kDefaultPadding * 0.8),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: kDefaultPadding),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _controller.removeSubject(subject);
                      },
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Remove'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kErrorColor,
                        padding: const EdgeInsets.symmetric(
                            vertical: kDefaultPadding * 0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
