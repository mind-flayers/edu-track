import 'dart:io'; // Required for File type
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edu_track/app/features/authentication/controllers/auth_controller.dart';
import 'package:edu_track/main.dart'; // Import main for AppRoutes
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_storage/firebase_storage.dart'; // No longer using Firebase Storage for profile pics
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart'; // Required for image picking
import 'package:cloudinary_public/cloudinary_public.dart'; // Import Cloudinary package
import 'package:flutter/foundation.dart'; // For kDebugMode

class ProfileController extends GetxController {
  static ProfileController get instance => Get.find();

  // --- Cloudinary Configuration ---
  final String _cloudinaryCloudName = 'duckxlzaj';
  final String _cloudinaryUploadPreset =
      'admin_profile'; // Use the unsigned preset for admin profile

  // --- Dependencies ---
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // final FirebaseStorage _storage = FirebaseStorage.instance; // No longer needed here
  final ImagePicker _picker = ImagePicker();
  late final CloudinaryPublic _cloudinary; // Initialize in onInit

  // --- State Variables (Reactive) ---
  final RxBool isLoading = false.obs;
  final RxBool isEditing = false.obs;
  final RxnString statusMessage =
      RxnString(); // Use RxnString for nullable string
  final RxBool isError = false.obs;

  final RxnString name = RxnString();
  final RxnString academyName = RxnString();
  final RxnString smsToken = RxnString();
  final RxnString profilePhotoUrl = RxnString();
  final RxnString email = RxnString();

  // Academy subjects management
  final RxList<String> academySubjects = <String>[].obs;

  // Store original values for cancellation
  String _originalName = '';
  String _originalAcademyName = '';
  String _originalSmsToken = '';
  String? _originalProfilePhotoUrl;
  List<String> _originalSubjects = [];

  // --- Getters ---
  String? get userId => AuthController.instance.user?.uid;
  DocumentReference? get _profileDocRef => userId != null
      ? _firestore
          .collection('admins')
          .doc(userId!)
          .collection('adminProfile')
          .doc('profile')
      : null;

  DocumentReference? get _subjectsDocRef => userId != null
      ? _firestore
          .collection('admins')
          .doc(userId!)
          .collection('academySettings')
          .doc('subjects')
      : null;

  // --- Initialization ---
  @override
  void onInit() {
    super.onInit();
    // Initialize CloudinaryPublic instance
    _cloudinary = CloudinaryPublic(
        _cloudinaryCloudName, _cloudinaryUploadPreset,
        cache: false);
    fetchProfileData();
  }

  // --- Core Logic Methods ---

  Future<void> fetchProfileData() async {
    if (userId == null) {
      _showStatus("Error: User not logged in.", isError: true);
      return;
    }
    isLoading.value = true;
    statusMessage.value = null; // Clear previous messages
    isError.value = false;

    try {
      email.value = _auth.currentUser?.email; // Get email from Auth

      final doc = await _profileDocRef?.get();

      if (doc != null && doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        name.value = data['name'];
        academyName.value = data['academyName'];
        smsToken.value = data['smsGatewayToken'];
        profilePhotoUrl.value = data['profilePhotoUrl'];

        // Store original values
        _originalName = name.value ?? '';
        _originalAcademyName = academyName.value ?? '';
        _originalSmsToken = smsToken.value ?? '';
        _originalProfilePhotoUrl = profilePhotoUrl.value;
      } else {
        _showStatus("Profile data not found. Please complete setup.",
            isError: true);
      }

      // Fetch academy subjects
      final subjectsDoc = await _subjectsDocRef?.get();
      if (subjectsDoc != null &&
          subjectsDoc.exists &&
          subjectsDoc.data() != null) {
        final subjectsData = subjectsDoc.data() as Map<String, dynamic>;
        final subjects = List<String>.from(subjectsData['subjects'] ?? []);
        academySubjects.value = subjects;
        _originalSubjects = List<String>.from(subjects);
      } else {
        // Initialize with default subjects if none exist
        const defaultSubjects = [
          'Mathematics',
          'Science',
          'English',
          'History',
          'ICT',
          'Tamil',
          'Sinhala',
          'Commerce'
        ];
        academySubjects.value = List<String>.from(defaultSubjects);
        _originalSubjects = List<String>.from(defaultSubjects);

        // Create the subjects document with defaults
        await _subjectsDocRef?.set({
          'subjects': defaultSubjects,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print("Error fetching profile data: $e");
      _showStatus("Failed to load profile data.", isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  void toggleEdit(bool editing,
      {String? currentName, String? currentAcademy, String? currentSms}) {
    isEditing.value = editing;
    statusMessage.value = null; // Clear message on toggle
    if (!editing) {
      // If cancelling, revert values in controller state
      name.value = _originalName;
      academyName.value = _originalAcademyName;
      smsToken.value = _originalSmsToken;
      profilePhotoUrl.value =
          _originalProfilePhotoUrl; // Revert photo URL if needed (though UI might handle display)
    } else {
      // If starting edit, ensure state matches current text field values from UI
      name.value = currentName;
      academyName.value = currentAcademy;
      smsToken.value = currentSms;
    }
  }

  Future<void> updateProfileDetails({
    required String newName,
    required String newAcademyName,
    required String newSmsToken,
  }) async {
    if (userId == null) {
      _showStatus("Error: User not logged in.", isError: true);
      return;
    }
    isLoading.value = true;
    statusMessage.value = null;
    isError.value = false;

    try {
      final Map<String, dynamic> dataToUpdate = {
        'name': newName,
        'academyName': newAcademyName,
        'smsGatewayToken': newSmsToken,
        'updatedAt': FieldValue.serverTimestamp(), // Use server timestamp
      };

      await _profileDocRef!.update(dataToUpdate);

      // Update local state and originals on success
      name.value = newName;
      academyName.value = newAcademyName;
      smsToken.value = newSmsToken;
      _originalName = newName;
      _originalAcademyName = newAcademyName;
      _originalSmsToken = newSmsToken;

      isEditing.value = false; // Exit editing mode
      _showStatus("Profile updated successfully!", isError: false);
    } catch (e) {
      print("Error updating profile details: $e");
      _showStatus("Failed to update profile. Please try again.", isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> pickAndUploadImage() async {
    if (userId == null) {
      _showStatus("Error: User not logged in.", isError: true);
      return;
    }
    isLoading.value = true; // Indicate loading during pick/upload
    statusMessage.value = null;
    isError.value = false;
    String? oldImageUrl =
        profilePhotoUrl.value; // Store old URL before potential update

    try {
      final XFile? pickedFile =
          await _picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        File imageFile = File(pickedFile.path);

        // Generate a unique public ID for Cloudinary (e.g., using timestamp)
        // This ID will be needed if you implement deletion via backend later.
        final String publicId =
            'profiles/admin/$userId/profile_${DateTime.now().millisecondsSinceEpoch}';

        if (kDebugMode) {
          print('Uploading to Cloudinary with public_id: $publicId');
        }

        // Upload to Cloudinary using the unsigned preset
        CloudinaryResponse response = await _cloudinary.uploadFile(
          CloudinaryFile.fromFile(
            imageFile.path,
            resourceType: CloudinaryResourceType.Image,
            folder:
                'profiles/admin/$userId', // Optional: Organize in Cloudinary folders
            publicId: publicId, // Use the generated public ID
          ),
        );

        // Check for success by verifying the secureUrl is present and not empty
        if (response.secureUrl.isNotEmpty) {
          final String newImageUrl = response.secureUrl;
          if (kDebugMode) {
            print('Cloudinary Upload Successful: $newImageUrl');
            print(
                'Cloudinary Public ID: ${response.publicId}'); // Log the actual public ID returned
          }

          // Update Firestore with the new Cloudinary URL
          await _profileDocRef!.update({
            'profilePhotoUrl': newImageUrl,
            'profilePhotoPublicId':
                response.publicId, // Store public ID for potential deletion
            'updatedAt': FieldValue.serverTimestamp()
          });

          // Update local state
          profilePhotoUrl.value = newImageUrl;
          _originalProfilePhotoUrl = newImageUrl; // Update original as well

          _showStatus("Profile picture updated!", isError: false);

          // --- Deletion of Old Image ---
          if (oldImageUrl != null &&
              oldImageUrl.isNotEmpty &&
              oldImageUrl != newImageUrl) {
            // TODO: Trigger a secure backend function to delete the old image from Cloudinary.
            // Pass the old public ID (you might need to store it in Firestore alongside the URL).
            // Example: await backendApiService.deleteCloudinaryImage(oldPublicId);
            // For now, just print a message.
            final oldPublicId =
                _extractPublicIdFromUrl(oldImageUrl); // Helper needed
            if (oldPublicId != null) {
              print(
                  "TODO: Call backend to delete old Cloudinary image with public_id: $oldPublicId");
              // await _deleteOldCloudinaryImage(oldPublicId); // Call the (currently non-functional) delete method
            } else {
              print("Could not extract public_id from old URL: $oldImageUrl");
            }
          }
        } else {
          // Upload failed if secureUrl is null or empty
          if (kDebugMode) {
            print("Cloudinary upload failed (secureUrl was null or empty).");
          }
          _showStatus("Failed to upload image.",
              isError: true); // Keep the generic error for the user
        }
      } else {
        // User cancelled picker
        if (kDebugMode) {
          print("Image picking cancelled.");
        }
      }
    } catch (e) {
      print("Error picking/uploading image: $e");
      _showStatus("Failed to update profile picture.", isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  // --- Helper method to extract public_id (basic example, might need refinement) ---
  String? _extractPublicIdFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      // Example URL structure: https://res.cloudinary.com/<cloud_name>/<resource_type>/<delivery_type>/<transformations>/<version>/<public_id>.<format>
      // A simpler common structure: https://res.cloudinary.com/duckxlzaj/image/upload/v1713735980/profiles/admin/USER_ID/profile_1713735979000.jpg
      // We need the part after version and before the extension.
      final pathSegments = uri.pathSegments;
      if (pathSegments.length >= 6) {
        // Adjust index based on your URL structure
        // Find 'upload' segment index
        int uploadIndex = pathSegments.indexOf('upload');
        if (uploadIndex != -1 && pathSegments.length > uploadIndex + 2) {
          // Combine segments after version (vXXXXXXXXXX) up to the filename
          String potentialPublicId =
              pathSegments.sublist(uploadIndex + 2).join('/');
          // Remove file extension
          if (potentialPublicId.contains('.')) {
            potentialPublicId = potentialPublicId.substring(
                0, potentialPublicId.lastIndexOf('.'));
          }
          return potentialPublicId;
        }
      }
      print("Could not extract public_id using standard pattern for URL: $url");
      // Fallback: Attempt to get ID stored in Firestore if available (requires fetching it first)
      // This part is complex as we don't have the old document data readily here.
      // It's better to store the public_id explicitly in Firestore when uploading.
      return null; // Indicate failure
    } catch (e) {
      print("Error parsing URL for public_id extraction: $e");
      return null;
    }
  }

  // --- Placeholder for secure deletion (should be implemented via backend) ---
  // Future<void> _deleteOldCloudinaryImage(String publicId) async {
  //   // !!! SECURITY WARNING !!!
  //   // DO NOT call Cloudinary Admin API directly from the client-side app.
  //   // This requires your API secret, which should never be exposed in the app.
  //   // Instead, trigger a secure backend function (e.g., Cloud Function)
  //   // that uses the Admin API to delete the resource.
  //
  //   print("Attempting to delete (via backend ideally) Cloudinary image with public_id: $publicId");
  //
  //   // Example of how backend call might look (using a hypothetical service):
  //   // try {
  //   //   await BackendService.instance.deleteCloudinaryResource(publicId);
  //   //   print("Successfully triggered backend deletion for $publicId");
  //   // } catch (e) {
  //   //   print("Error triggering backend deletion for $publicId: $e");
  //   // }
  // }

  Future<void> changeEmail(String newEmail, String currentPassword) async {
    if (userId == null || _auth.currentUser == null) {
      _showStatus("Error: User not logged in.", isError: true);
      return;
    }
    isLoading.value = true;
    statusMessage.value = null;
    isError.value = false;

    try {
      // 1. Re-authenticate user
      AuthCredential credential = EmailAuthProvider.credential(
        email: _auth.currentUser!.email!,
        password: currentPassword,
      );
      await _auth.currentUser!.reauthenticateWithCredential(credential);

      // 2. Update email in Firebase Auth
      await _auth.currentUser!.updateEmail(newEmail);
      await _auth.currentUser!
          .sendEmailVerification(); // Send verification to new email

      // 3. Update email in Firestore profile (optional but good practice)
      await _profileDocRef?.update(
          {'email': newEmail, 'updatedAt': FieldValue.serverTimestamp()});

      // Update local state
      email.value = newEmail;

      _showStatus("Email updated. Please verify your new email address.",
          isError: false);
      // Consider logging the user out or asking them to log back in
      // AuthController.instance.signOut(); // Example
    } on FirebaseAuthException catch (e) {
      print("Error changing email: ${e.code} - ${e.message}");
      String errorMessage = "Failed to change email.";
      if (e.code == 'wrong-password') {
        errorMessage = "Incorrect current password.";
      } else if (e.code == 'email-already-in-use') {
        errorMessage = "This email address is already in use.";
      } else if (e.code == 'invalid-email') {
        errorMessage = "The new email address is invalid.";
      } else if (e.code == 'requires-recent-login') {
        errorMessage =
            "This action requires a recent login. Please sign out and sign back in.";
      }
      _showStatus(errorMessage, isError: true);
    } catch (e) {
      print("Error changing email: $e");
      _showStatus("An unexpected error occurred while changing email.",
          isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> sendPasswordReset() async {
    if (_auth.currentUser?.email == null) {
      _showStatus("Error: Cannot find user's email.", isError: true);
      return;
    }
    isLoading.value = true;
    statusMessage.value = null;
    isError.value = false;

    try {
      await _auth.sendPasswordResetEmail(email: _auth.currentUser!.email!);
      _showStatus("Password reset link sent to your email.", isError: false);
    } on FirebaseAuthException catch (e) {
      print("Error sending password reset: ${e.code} - ${e.message}");
      _showStatus("Failed to send password reset link.", isError: true);
    } catch (e) {
      print("Error sending password reset: $e");
      _showStatus("An unexpected error occurred.", isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  // Academy subjects management methods
  Future<void> addSubject(String subject) async {
    if (subject.trim().isEmpty) return;

    final trimmedSubject = subject.trim();
    if (academySubjects.contains(trimmedSubject)) {
      _showStatus("Subject already exists.", isError: true);
      return;
    }

    academySubjects.add(trimmedSubject);
    await _updateSubjectsInFirestore();
  }

  Future<void> removeSubject(String subject) async {
    academySubjects.remove(subject);
    await _updateSubjectsInFirestore();
  }

  Future<void> editSubject(int index, String newSubject) async {
    if (newSubject.trim().isEmpty) return;

    final trimmedSubject = newSubject.trim();
    if (academySubjects.contains(trimmedSubject) &&
        academySubjects[index] != trimmedSubject) {
      _showStatus("Subject already exists.", isError: true);
      return;
    }

    academySubjects[index] = trimmedSubject;
    await _updateSubjectsInFirestore();
  }

  Future<void> _updateSubjectsInFirestore() async {
    if (userId == null) return;

    try {
      await _subjectsDocRef?.set({
        'subjects': academySubjects.toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _originalSubjects = List<String>.from(academySubjects);
      _showStatus("Academy subjects updated successfully!", isError: false);
    } catch (e) {
      print("Error updating subjects: $e");
      _showStatus("Failed to update subjects.", isError: true);
    }
  }

  // --- Sign Out Method ---
  Future<void> signOut() async {
    try {
      await AuthController.instance.signOut();
      Get.offAllNamed(
          AppRoutes.launching); // Navigate to launching screen and clear stack
    } catch (e) {
      _showStatus('Logout failed: ${e.toString()}', isError: true);
    }
  }

  // --- Helper Methods ---
  void _showStatus(String message, {required bool isError}) {
    this.isError.value = isError;
    statusMessage.value = message;
    // Optional: Auto-clear message after a delay
    Future.delayed(const Duration(seconds: 4), () {
      if (statusMessage.value == message) {
        // Only clear if it's the same message
        statusMessage.value = null;
      }
    });
  }
}
