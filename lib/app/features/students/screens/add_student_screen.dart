import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edu_track/app/features/authentication/controllers/auth_controller.dart';
// import 'package:edu_track/app/features/profile/screens/profile_settings_screen.dart';
import 'package:edu_track/app/utils/constants.dart';
import 'package:edu_track/app/utils/firestore_setup.dart'; // For generateIndexNumber
import 'package:edu_track/main.dart'; // Import main for AppRoutes
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart'; // Import GetX
import 'package:saver_gallery/saver_gallery.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
// path_provider is not directly used here, but image_gallery_saver might use it internally
// import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:uuid/uuid.dart';
// Need DeviceInfoPlugin for Android 13+ permission check
import 'package:device_info_plus/device_info_plus.dart';

class AddStudentScreen extends StatefulWidget {
  const AddStudentScreen({super.key});

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _parentNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _addressController = TextEditingController();
  final _sectionController = TextEditingController();

  String? _selectedClass;
  String? _selectedSex;
  DateTime? _selectedDob;
  XFile? _selectedImage;
  bool _isLoading = false;
  String? _qrData; // Holds the data for the QR code (student ID)
  // String? _statusMessage; // For success/error messages
  bool _isSuccess = false;
  // String? _downloadStatusMessage;
  // final bool _isDownloadSuccess = false;
  final GlobalKey _qrKey = GlobalKey(); // Key to capture QR code widget

  List<String> _availableClasses = [];
  // Subjects state
  List<String> _availableSubjects = [];
  final Set<String> _selectedSubjects = <String>{};
  bool _subjectsLoading = false;
  final List<String> _sexOptions = ['Male', 'Female', 'Other'];

  // Cloudinary details (Using unsigned preset)
  final String _cloudinaryCloudName = 'duckxlzaj';
  final String _cloudinaryUploadPreset = 'student_id_photo';

  @override
  void initState() {
    super.initState();
    _fetchAvailableClasses();
  }

  // Fetch available subjects for a given class by combining teachers' subjects
  // and examTerms subjects under the current admin. Keeps results unique.
  Future<void> _fetchAvailableSubjectsForClass(String? className) async {
    setState(() {
      _subjectsLoading = true;
      _availableSubjects = [];
      _selectedSubjects.clear();
    });

    final String? adminUid = AuthController.instance.user?.uid;
    if (adminUid == null || className == null) {
      if (mounted) {
        setState(() {
          _subjectsLoading = false;
        });
      }
      return;
    }

    try {
      final adminRef =
          FirebaseFirestore.instance.collection('admins').doc(adminUid);

      // 1) From teachers: get subjects for teachers assigned to this class
      final teacherQuery = await adminRef
          .collection('teachers')
          .where('classAssigned', arrayContains: className)
          .get();
      final subjectsFromTeachers = teacherQuery.docs
          .map((d) => (d.data()['subject'] as String?))
          .whereType<String>()
          .toSet();

      // 2) From examTerms: collect all subject arrays and include any that match
      final examTermsSnapshot = await adminRef.collection('examTerms').get();
      final subjectsFromTerms = <String>{};
      for (var doc in examTermsSnapshot.docs) {
        final data = doc.data();
        if (data.containsKey('subjects') && data['subjects'] is List) {
          for (var s in List.from(data['subjects'])) {
            if (s is String && s.isNotEmpty) subjectsFromTerms.add(s);
          }
        }
      }

      // Combine and sort
      final combined = {...subjectsFromTeachers, ...subjectsFromTerms}.toList();
      combined.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

      if (mounted) {
        setState(() {
          _availableSubjects = combined;
          _subjectsLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching subjects for class $className: $e');
      if (mounted) setState(() => _subjectsLoading = false);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching subjects: $e')),
        );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _parentNameController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _addressController.dispose();
    _sectionController.dispose();
    super.dispose();
  }

  // Fetch available classes from Firestore
  Future<void> _fetchAvailableClasses() async {
    final String? adminUid = AuthController.instance.user?.uid;
    if (adminUid == null) {
      print("Error: Admin UID is null. Cannot fetch classes for dropdown.");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Error: Could not verify admin to fetch classes.')),
        );
      }
      // Set default classes if admin check fails? Or leave empty? Leaving empty for now.
      setState(() => _availableClasses = []);
      return;
    }

    try {
      // Fetch classes from the nested collection under the current admin
      final snapshot = await FirebaseFirestore.instance
          .collection('admins')
          .doc(adminUid)
          .collection('students')
          .get();
      final classesFromDb = snapshot.docs
          .map((doc) => doc.data()['class'] as String?)
          .where((className) => className != null && className.isNotEmpty)
          .whereType<String>()
          .toSet();

      const defaultClasses = [
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
        'Grade 12'
      ];
      final combined = {...classesFromDb, ...defaultClasses}.toList()
        ..sort((a, b) {
          final numA = int.tryParse(a.replaceAll('Grade ', '')) ?? 0;
          final numB = int.tryParse(b.replaceAll('Grade ', '')) ?? 0;
          return numA.compareTo(numB);
        });

      if (mounted) {
        setState(() {
          _availableClasses = combined;
        });
      }
    } catch (e) {
      print("Error fetching classes: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching class list: $e')),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 70); // Add quality constraint
      if (image != null && mounted) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      print("Error picking image: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  // Corrected Cloudinary Upload for v0.23.1 (Unsigned)
  Future<String?> _uploadImageToCloudinary(XFile image) async {
    try {
      final cloudinary = CloudinaryPublic(
          _cloudinaryCloudName, _cloudinaryUploadPreset,
          cache: false);
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(image.path,
            resourceType: CloudinaryResourceType.Image,
            folder: 'profiles/students' // Folder specified here
            // Transformation parameter removed - handled by preset 'student' on Cloudinary
            ),
      );

      // Check for success based on secure_url presence for v0.23.1
      // Note: Error details are limited in this version, rely on catch block.
      if (response.secureUrl.isNotEmpty) {
        print('Cloudinary Upload Success: ${response.secureUrl}');
        return response.secureUrl;
      } else {
        print('Cloudinary Upload Error: Failed to get secure URL.');
        throw Exception(
            'Failed to upload image. Check Cloudinary logs or preset configuration.');
      }
    } catch (e) {
      print("Error uploading image to Cloudinary: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image upload failed: $e')),
        );
      }
      return null; // Return null on failure
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ??
          DateTime.now().subtract(
              const Duration(days: 365 * 10)), // Default ~10 years ago
      firstDate: DateTime(1980),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDob && mounted) {
      setState(() {
        _selectedDob = picked;
      });
    }
  }

  Future<void> _addStudent() async {
    // Hide keyboard
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please fill all required fields.'),
            backgroundColor: kErrorColor),
      );
      return; // Don't proceed if form is invalid
    }
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please upload a student photo.'),
            backgroundColor: kErrorColor),
      );
      return;
    }

    // If subjects are available for the selected class, require at least one selection
    if (_availableSubjects.isNotEmpty && _selectedSubjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Please select at least one subject for the student.'),
            backgroundColor: kErrorColor),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      // _statusMessage = null;
      _qrData = null;
      // _downloadStatusMessage = null;
    });

    try {
      // 1. Upload image
      final photoUrl = await _uploadImageToCloudinary(_selectedImage!);
      if (photoUrl == null) {
        // Error already shown by upload function, stop loading
        setState(() => _isLoading = false);
        return;
      }

      // 2. Generate IDs and Index Number
      final studentId = const Uuid().v4(); // Generate unique ID
      final String? adminUid =
          AuthController.instance.user?.uid; // Get Admin UID

      if (adminUid == null) {
        throw Exception("Admin user not found. Cannot add student.");
      }

      final firestore = FirebaseFirestore.instance;
      final adminRef = firestore
          .collection('admins')
          .doc(adminUid); // Reference to admin doc
      final currentYear = DateTime.now().year;
      final studentSection = (_sectionController.text.trim().isEmpty
              ? 'A'
              : _sectionController.text.trim())
          .toUpperCase();

      // Find the next row number for index generation within the admin's students
      final classSectionQuery = await adminRef
          .collection('students')
          .where('class', isEqualTo: _selectedClass!)
          .where('section', isEqualTo: studentSection)
          .get();
      final nextRowNumber = classSectionQuery.docs.length + 1;

      final indexNumber = generateIndexNumber(
        year: currentYear,
        className: _selectedClass!,
        section: studentSection,
        rowNumber: nextRowNumber,
      );

      // 3. Prepare data
      final studentData = {
        'name': _nameController.text.trim(),
        'class': _selectedClass,
        'section': studentSection,
        'dob': _selectedDob != null ? Timestamp.fromDate(_selectedDob!) : null,
        'sex': _selectedSex,
        'parentName': _parentNameController.text.trim(),
        'parentPhone': _phoneController.text.trim(),
        'whatsappNumber': _whatsappController.text.trim(),
        'address': _addressController.text.trim(),
        'photoUrl': photoUrl,
        'indexNumber': indexNumber,
        'qrCodeData': studentId, // Use unique ID for QR
        'joinedAt': Timestamp.now(),
        'isActive': true, // Default to active
        // Follow database_structure.md: key is 'Subjects' (capital S)
        'Subjects':
            _selectedSubjects.isNotEmpty ? _selectedSubjects.toList() : [],
      };

      // 4. Save to Firestore under the specific admin
      await adminRef.collection('students').doc(studentId).set(studentData);

      // 5. Update state for success UI
      if (mounted) {
        // Show success snackbar first
        _showStatusSnackbar('Added Successfully', true);

        setState(() {
          _isLoading = false;
          _isSuccess = true;
          // _statusMessage = 'Added Successfully'; // Removed, handled by snackbar
          _qrData = studentId; // Set QR data to show the QR code
          // Clear form after success
          _formKey.currentState?.reset();
          _selectedClass = null;
          _selectedSex = null;
          _selectedDob = null;
          _selectedImage = null;
          _availableSubjects = [];
          _selectedSubjects.clear();
          _nameController.clear();
          _parentNameController.clear();
          _phoneController.clear();
          _whatsappController.clear();
          _addressController.clear();
          _sectionController.clear();
        });
      }
    } catch (e) {
      print("Error adding student: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isSuccess = false;
          // _statusMessage = 'Failed to add student: $e'; // Remove inline message
        });
        // Show Snackbar for error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add student: $e'),
            backgroundColor: kErrorColor,
            duration: 2500.ms,
          ),
        );
      }
    }
  }

  // Helper to show snackbar messages
  void _showStatusSnackbar(String message, bool isSuccess) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? kSuccessColor : kErrorColor,
        behavior: SnackBarBehavior.floating, // Make it float like the image
        margin: const EdgeInsets.all(kDefaultPadding),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kDefaultRadius)),
        duration: 2500.ms,
      ),
    );
  }

  Future<void> _downloadQrCode() async {
    if (_qrData == null || _qrKey.currentContext == null) return;

    // 1. Request Permission
    PermissionStatus status;
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        // Android 13+ requires photos permission
        status = await Permission.photos.request();
      } else {
        // Older Android versions use storage
        status = await Permission.storage.request();
      }
    } else {
      // iOS or other platforms typically use photos permission
      status = await Permission.photos.request();
    }

    if (status.isGranted) {
      setState(() =>
          _isLoading = true); // Show loading indicator during capture/save
      try {
        // 2. Capture QR Code Widget as Image
        RenderRepaintBoundary boundary =
            _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
        // Ensure the boundary is ready
        await Future.delayed(const Duration(milliseconds: 100));
        ui.Image image = await boundary.toImage(
            pixelRatio: 3.0); // Increase pixelRatio for better quality
        ByteData? byteData =
            await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData == null)
          throw Exception("Could not capture QR code image.");
        Uint8List pngBytes = byteData.buffer.asUint8List();

        // 3. Save Image using saver_gallery
        final SaveResult result = await SaverGallery.saveImage(
            pngBytes, // Positional argument for image bytes
            fileName:
                "student_qr_${_qrData!.substring(0, 8)}", // Correct parameter name
            quality: 95, // High quality
            androidRelativePath:
                "Pictures/EduTrack", // Specify a subfolder in Pictures
            skipIfExists: false // Required parameter
            );

        if (result.isSuccess) {
          _showStatusSnackbar('Downloaded', true); // Use Snackbar
        } else {
          throw Exception(
              "Failed to save QR code: ${result.errorMessage ?? 'Save error'}");
        }
      } catch (e) {
        print("Error downloading QR code: $e");
        _showStatusSnackbar('Download Failed', false); // Use Snackbar
      } finally {
        if (mounted)
          setState(() => _isLoading = false); // Hide loading indicator
      }
    } else {
      print("Storage/Photos permission denied.");
      _showStatusSnackbar('Permission Denied', false); // Use Snackbar
      // Optionally guide user to settings: openAppSettings();
    }
  }

  // Reusable Profile Avatar Builder
  Widget _buildProfileAvatar() {
    final String? userId = AuthController.instance.user?.uid;
    if (userId == null) {
      return IconButton(
        icon: Icon(Icons.account_circle_rounded,
            size: 30, color: kLightTextColor),
        tooltip: 'Profile Settings',
        onPressed: () => Get.toNamed(AppRoutes
            .profileSettings), // Use Get.toNamed (Already correct here, but ensuring consistency)
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
            size: 30, color: kLightTextColor);
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
            onTap: () => Get.toNamed(AppRoutes
                .profileSettings), // Use Get.toNamed (Already correct here, but ensuring consistency)
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

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: kLightTextColor),
          tooltip: 'Back',
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Add Student', style: textTheme.titleLarge),
        centerTitle: true,
        actions: [
          // Download status is now shown via Snackbar
          _buildProfileAvatar(),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(kDefaultPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Form Fields ---
              _buildTextField(
                controller: _nameController,
                label: 'Student Name',
                hint: 'Enter student name',
                icon: Icons.person_outline,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Please enter name' : null,
              ),
              _buildDropdownField(
                value: _selectedClass,
                label: 'Class',
                hint: 'Select Class',
                items: _availableClasses,
                onChanged: (value) {
                  // When class changes, fetch subjects for that class
                  setState(() => _selectedClass = value);
                  _fetchAvailableSubjectsForClass(value);
                },
                validator: (value) =>
                    value == null ? 'Please select class' : null,
              ),
              _buildTextField(
                controller: _sectionController,
                label: 'Section',
                hint: 'Enter section (e.g., A, B) - optional',
                icon: Icons.group_work_outlined,
                // Section is optional; we'll default to 'A' when saving if empty
                validator: (value) => null,
              ),
              _buildDateField(
                context: context,
                label: 'DOB',
                selectedDate: _selectedDob,
                onTap: () => _selectDate(context),
                validator: (value) =>
                    _selectedDob == null ? 'Please select date of birth' : null,
              ),
              _buildDropdownField(
                value: _selectedSex,
                label: 'Sex',
                hint: 'Select Sex',
                items: _sexOptions,
                onChanged: (value) => setState(() => _selectedSex = value),
                validator: (value) =>
                    value == null ? 'Please select sex' : null,
              ),
              _buildTextField(
                controller: _parentNameController,
                label: 'Parent Name',
                hint: 'Enter parent name',
                icon: Icons.supervisor_account_outlined,
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter parent name'
                    : null,
              ),
              _buildTextField(
                controller: _phoneController,
                label: 'Phone Number',
                hint: 'Enter parent phone number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter phone number'
                    : null,
              ),
              _buildTextField(
                controller: _whatsappController,
                label: 'Whatsapp Number',
                hint: 'Enter parent whatsapp number',
                icon: Icons.message_outlined,
                keyboardType: TextInputType.phone,
              ),
              _buildTextField(
                controller: _addressController,
                label: 'Address',
                hint: 'Enter student address',
                icon: Icons.location_on_outlined,
                maxLines: 3,
              ),

              const SizedBox(height: kDefaultPadding / 2),
              // --- Subjects selection ---
              _buildSubjectsSelector(),

              const SizedBox(height: kDefaultPadding * 1.5),

              // --- Upload Photo Section ---
              Text('Upload Photo',
                  style: textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: kDefaultPadding / 2),
              _buildImagePicker(), // Updated image picker UI

              const SizedBox(height: kDefaultPadding * 2),

              // --- Add Student Button ---
              // Show button only if QR code is not displayed
              if (_qrData == null)
                ElevatedButton(
                  onPressed: _isLoading ? null : _addStudent,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: kDefaultPadding * 0.9),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Add Student'),
                ),

              const SizedBox(height: kDefaultPadding * 1.5),

              // --- QR Code Display (Success) ---
              // Show only QR section if successful and QR data exists
              if (_isSuccess && _qrData != null)
                _buildSuccessQrSection(textTheme) // Renamed widget
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: 0.2),

              // Error messages are now handled by Snackbar in _addStudent
            ],
          ),
        ),
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
    int? maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: kDefaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: kDefaultPadding / 3),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Icon(icon, size: 20),
              // Using theme defaults for border, padding etc.
            ),
            validator: validator,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String? value,
    required String label,
    required String hint,
    required List<String> items,
    required void Function(String?) onChanged,
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
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: kDefaultPadding / 3),
          DropdownButtonFormField<String>(
            value: value,
            hint: Text(hint, style: kHintTextStyle.copyWith(fontSize: 14)),
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(item),
              );
            }).toList(),
            onChanged: onChanged,
            validator: validator,
            decoration: InputDecoration(
              prefixIcon: Icon(
                  label == 'Class'
                      ? Icons.school_outlined
                      : Icons.wc_outlined, // Icon based on label
                  size: 20),
              // Using theme defaults for border, padding etc.
            ),
            isExpanded: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDateField({
    required BuildContext context,
    required String label,
    required DateTime? selectedDate,
    required VoidCallback onTap,
    String? Function(DateTime?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: kDefaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: kDefaultPadding / 3),
          TextFormField(
            readOnly: true,
            onTap: onTap,
            decoration: InputDecoration(
              hintText: selectedDate == null
                  ? 'Select date'
                  : DateFormat('dd / MM / yyyy')
                      .format(selectedDate), // Format date
              prefixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
            ),
            // Validate based on the _selectedDob state variable, not the controller's text
            validator: (value) => validator?.call(_selectedDob),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePicker() {
    // UI matching the image more closely
    return Container(
      padding: const EdgeInsets.all(kDefaultPadding),
      decoration: BoxDecoration(
          color: kSecondaryColor,
          borderRadius: BorderRadius.circular(kDefaultRadius),
          border: Border.all(color: kLightTextColor.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            )
          ]),
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: kBackgroundColor.withOpacity(0.7),
                borderRadius: BorderRadius.circular(kDefaultRadius * 0.8),
                border: Border.all(
                  color: kPrimaryColor.withOpacity(0.5),
                  style: BorderStyle
                      .solid, // Dashed border is complex, using solid
                  width: 1.5,
                ),
              ),
              child: _selectedImage == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_upload_outlined,
                            size: 40, color: kLightTextColor),
                        const SizedBox(height: 8),
                        Text('Drop files here', style: kHintTextStyle),
                        Text('Supported format: PNG, JPG',
                            style: kHintTextStyle.copyWith(fontSize: 11)),
                      ],
                    )
                  : ClipRRect(
                      // Show selected image preview
                      borderRadius: BorderRadius.circular(
                          kDefaultRadius * 0.8 - 1.5), // Adjust for border
                      child: Image.file(File(_selectedImage!.path),
                          fit: BoxFit.cover)),
            ),
          ),
          // Show Cancel/Upload buttons only if an image is selected
          if (_selectedImage != null)
            Padding(
              padding: const EdgeInsets.only(top: kDefaultPadding),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => setState(
                        () => _selectedImage = null), // Clear selection
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _pickImage, // Allow changing the image
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: kDefaultPadding * 1.5,
                          vertical: kDefaultPadding * 0.5),
                      minimumSize: Size.zero,
                    ),
                    child: const Text(
                        'Upload'), // Or 'Change' ? Let's keep 'Upload' for simplicity
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Subjects selector UI: shows loading, empty state or chips to pick subjects
  Widget _buildSubjectsSelector() {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: kDefaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Subjects',
              style:
                  textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: kDefaultPadding / 3),
          if (_subjectsLoading)
            const SizedBox(
                height: 48, child: Center(child: CircularProgressIndicator()))
          else if (_availableSubjects.isEmpty)
            Text('No subjects available for selected class',
                style: kHintTextStyle)
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableSubjects.map((subject) {
                final selected = _selectedSubjects.contains(subject);
                return FilterChip(
                  label: Text(subject),
                  selected: selected,
                  onSelected: (val) {
                    setState(() {
                      if (val)
                        _selectedSubjects.add(subject);
                      else
                        _selectedSubjects.remove(subject);
                    });
                  },
                );
              }).toList(),
            ),
          const SizedBox(height: 6),
          // Simple validator hint (not a FormField) - ensure at least one subject chosen when saving
          if (!_subjectsLoading &&
              _availableSubjects.isNotEmpty &&
              _selectedSubjects.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('Please select at least one subject',
                  style: TextStyle(color: kErrorColor, fontSize: 12)),
            ),
        ],
      ),
    );
  }

  // Renamed and simplified: Only shows QR and Download button
  Widget _buildSuccessQrSection(TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(kDefaultPadding),
      decoration: BoxDecoration(
          color: kSecondaryColor, // White background for this section
          borderRadius: BorderRadius.circular(kDefaultRadius),
          border: Border.all(color: kSuccessColor.withOpacity(0.4)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            )
          ]),
      child: Column(
        children: [
          // Success message Chip removed - now shown via Snackbar
          const SizedBox(height: kDefaultPadding / 2), // Reduced top padding
          // Ensure QR code is captured with a white background
          RepaintBoundary(
            key: _qrKey,
            child: Container(
              color: Colors.white, // Explicit white background
              padding: const EdgeInsets.all(8), // Padding around QR
              child: QrImageView(
                data: _qrData!,
                version: QrVersions.auto,
                size: 180.0,
                gapless: false,
              ),
            ),
          ),
          const SizedBox(height: kDefaultPadding),
          ElevatedButton.icon(
            icon: const Icon(Icons.download_rounded, size: 18),
            label: const Text('Download QR Code'),
            onPressed: _isLoading
                ? null
                : _downloadQrCode, // Disable while loading/saving QR
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  kPrimaryColor.withOpacity(0.9), // Use theme primary color
              padding: const EdgeInsets.symmetric(
                  horizontal: kDefaultPadding * 1.5,
                  vertical: kDefaultPadding * 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
