import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:edu_track/app/utils/constants.dart';
import 'package:edu_track/app/features/authentication/screens/signin_screen.dart';
// Import Dashboard Screen
import 'package:edu_track/app/features/dashboard/screens/dashboard_screen.dart';

class AuthController extends GetxController {
  static AuthController get instance => Get.find(); // Makes it easy to find the instance

  // Firebase Auth instance
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Observables for reactive state management
  final Rx<User?> _firebaseUser = Rx<User?>(null);
  final RxBool isLoading = false.obs; // For loading indicators

  // Getter for the user (can be null if not logged in)
  User? get user => _firebaseUser.value;

  @override
  void onReady() {
    super.onReady();
    // Bind the user stream from Firebase Auth to our Rx variable
    _firebaseUser.bindStream(_auth.authStateChanges());
    // Automatically navigate based on auth state changes
    ever(_firebaseUser, _setInitialScreen);
  }

  // Determine initial screen based on auth state
  _setInitialScreen(User? user) {
    // Add a small delay to ensure widgets are built before navigation
    Future.delayed(const Duration(milliseconds: 50), () {
      if (user == null) {
        // If user is null, navigate to SignInScreen
        print("User is null, navigating to SignInScreen");
        Get.offAll(() => const SignInScreen());
      } else {
        // If user is logged in, navigate to DashboardScreen
        print("User is logged in (${user.email}), navigating to DashboardScreen");
        Get.offAll(() => const DashboardScreen()); // Navigate to the actual DashboardScreen
      }
    });
  }

  // Sign in with Email and Password
  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    isLoading.value = true; // Start loading
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      // Explicitly navigate to Dashboard on successful sign-in
      // The authStateChanges stream listener (_setInitialScreen) will also fire,
      // but Get.offAll handles replacing the stack correctly.
      Get.offAll(() => const DashboardScreen());
      isLoading.value = false; // Stop loading
      return true; // Indicate success
    } on FirebaseAuthException catch (e) {
      isLoading.value = false; // Stop loading on error
      _showAuthErrorSnackbar("Sign In Failed", e.message ?? "An unknown error occurred.");
      return false; // Indicate failure
    } catch (e) {
      isLoading.value = false; // Stop loading on general error
      _showAuthErrorSnackbar("Sign In Failed", "An unexpected error occurred: ${e.toString()}");
      return false; // Indicate failure
    }
  }

  // Send Password Reset Email
  Future<bool> sendPasswordResetEmail(String email) async {
    isLoading.value = true; // Start loading
    try {
      // Attempt to send the password reset email directly.
      // Firebase might handle non-existent users internally, but we'll catch specific errors.
      await _auth.sendPasswordResetEmail(email: email);
      isLoading.value = false; // Stop loading

      // If no exception was thrown, assume success (as per Firebase standard behavior)
      Get.snackbar(
        'Reset link has been sent',
        'Check your email ($email) for instructions.', // Simplified message
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: kSuccessColor.withOpacity(0.9),
        colorText: kSecondaryColor,
        borderRadius: kDefaultRadius,
        margin: const EdgeInsets.all(kDefaultMargin),
        duration: const Duration(seconds: 5),
      );
      return true; // Indicate success
    } on FirebaseAuthException catch (e) {
      isLoading.value = false; // Stop loading on error
      // Explicitly check for the 'user-not-found' error code
      if (e.code == 'user-not-found') {
         _showAuthErrorSnackbar("Account not found", "Please enter a valid email.");
      } else {
        // Handle other Firebase-specific errors
        _showAuthErrorSnackbar("Password Reset Failed", e.message ?? "An unknown error occurred.");
      }
      return false; // Indicate failure
    } catch (e) {
      isLoading.value = false; // Stop loading on general error
      _showAuthErrorSnackbar("Password Reset Failed", "An unexpected error occurred: ${e.toString()}");
      return false; // Indicate failure
    }
  }

  // Sign Out
  Future<void> signOut() async {
    isLoading.value = true; // Start loading
    try {
      await _auth.signOut();
      // Firebase authStateChanges stream will handle navigation via _setInitialScreen
      isLoading.value = false; // Stop loading
    } catch (e) {
      isLoading.value = false; // Stop loading on error
      _showAuthErrorSnackbar("Sign Out Failed", "An unexpected error occurred: ${e.toString()}");
    }
  }

  // Helper to show error snackbar
  void _showAuthErrorSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: kErrorColor.withOpacity(0.9),
      colorText: kSecondaryColor,
      borderRadius: kDefaultRadius,
      margin: const EdgeInsets.all(kDefaultMargin),
    );
  }
}