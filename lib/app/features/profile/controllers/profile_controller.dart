import 'dart:io'; // Required for File type
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edu_track/app/features/authentication/controllers/auth_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Required for Storage
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart'; // Required for image picking

class ProfileController extends GetxController {
  static ProfileController get instance => Get.find();

  // --- Dependencies ---
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  // --- State Variables (Reactive) ---
  final RxBool isLoading = false.obs;
  final RxBool isEditing = false.obs;
  final RxnString statusMessage = RxnString(); // Use RxnString for nullable string
  final RxBool isError = false.obs;

  final RxnString name = RxnString();
  final RxnString academyName = RxnString();
  final RxnString smsToken = RxnString();
  final RxnString profilePhotoUrl = RxnString();
  final RxnString email = RxnString();

  // Store original values for cancellation
  String _originalName = '';
  String _originalAcademyName = '';
  String _originalSmsToken = '';
  String? _originalProfilePhotoUrl;

  // --- Getters ---
  String? get userId => AuthController.instance.user?.uid;
  DocumentReference? get _profileDocRef => userId != null
      ? _firestore
          .collection('admins')
          .doc(userId!)
          .collection('adminProfile')
          .doc('profile')
      : null;

  // --- Initialization ---
  @override
  void onInit() {
    super.onInit();
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
         _showStatus("Profile data not found. Please complete setup.", isError: true);
      }
    } catch (e) {
      print("Error fetching profile data: $e");
      _showStatus("Failed to load profile data.", isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  void toggleEdit(bool editing, {String? currentName, String? currentAcademy, String? currentSms}) {
     isEditing.value = editing;
     statusMessage.value = null; // Clear message on toggle
     if (!editing) {
       // If cancelling, revert values in controller state
       name.value = _originalName;
       academyName.value = _originalAcademyName;
       smsToken.value = _originalSmsToken;
       profilePhotoUrl.value = _originalProfilePhotoUrl; // Revert photo URL if needed (though UI might handle display)
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

    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        File imageFile = File(pickedFile.path);

        // Define storage path
        final String filePath = 'profiles/admin/$userId/profile_${DateTime.now().millisecondsSinceEpoch}.${pickedFile.name.split('.').last}';
        final Reference storageRef = _storage.ref().child(filePath);

        // Upload file
        UploadTask uploadTask = storageRef.putFile(imageFile);

        // Get download URL
        final TaskSnapshot snapshot = await uploadTask.whenComplete(() => {});
        final String downloadUrl = await snapshot.ref.getDownloadURL();

        // Update Firestore
        await _profileDocRef!.update({'profilePhotoUrl': downloadUrl, 'updatedAt': FieldValue.serverTimestamp()});

        // Update local state
        profilePhotoUrl.value = downloadUrl;
        _originalProfilePhotoUrl = downloadUrl; // Update original as well

        _showStatus("Profile picture updated!", isError: false);

      } else {
        // User cancelled picker
        print("Image picking cancelled.");
      }
    } catch (e) {
      print("Error picking/uploading image: $e");
      _showStatus("Failed to update profile picture.", isError: true);
    } finally {
       isLoading.value = false;
    }
  }

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
      await _auth.currentUser!.sendEmailVerification(); // Send verification to new email

      // 3. Update email in Firestore profile (optional but good practice)
      await _profileDocRef?.update({'email': newEmail, 'updatedAt': FieldValue.serverTimestamp()});

      // Update local state
      email.value = newEmail;

      _showStatus("Email updated. Please verify your new email address.", isError: false);
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
         errorMessage = "This action requires a recent login. Please sign out and sign back in.";
       }
       _showStatus(errorMessage, isError: true);
    } catch (e) {
      print("Error changing email: $e");
      _showStatus("An unexpected error occurred while changing email.", isError: true);
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


  // --- Helper Methods ---
  void _showStatus(String message, {required bool isError}) {
    this.isError.value = isError;
    statusMessage.value = message;
    // Optional: Auto-clear message after a delay
    Future.delayed(const Duration(seconds: 4), () {
      if (statusMessage.value == message) { // Only clear if it's the same message
        statusMessage.value = null;
      }
    });
  }
}