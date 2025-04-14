import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:edu_track/app/utils/constants.dart';
import 'signin_screen.dart'; // Import SignInScreen for navigation back

// Import Auth Controller
import '../controllers/auth_controller.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  // Get AuthController instance
  final AuthController _authController = AuthController.instance;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _sendResetLink() {
    // Validate the form first
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text.trim();
      // Call AuthController to send reset email
      // Call AuthController to send reset email.
      // AuthController handles showing success/error snackbars.
      _authController.sendPasswordResetEmail(email);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: kSecondaryColor, // White background
      appBar: AppBar(
        backgroundColor: kSecondaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: kTextColor, size: 20),
          onPressed: () => Get.back(), // Navigate back
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding * 1.5),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(height: screenHeight * 0.02), // Top spacing

                // Reset Password Title
                Center(
                    child: Text(
                      'Reset Password',
                      style: kHeadlineStyle.copyWith(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                
                // Email Field Label
                Text(
                  'Email', 
                  style: kSubheadlineStyle.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  )
                ),
                const SizedBox(height: 8.0),
                
                // Email TextField with styling from signin_screen
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Enter your email',
                    prefixIcon: const Icon(Icons.email_outlined, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: kPrimaryColor),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!GetUtils.isEmail(value)) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                  style: kBodyTextStyle,
                ),
                
                SizedBox(height: screenHeight * 0.04), // Spacing

                // Get Link Button (Full Width)
                Obx(
                  () => SizedBox(
                    width: double.infinity,
                    height: 52, // Fixed height for button
                    child: ElevatedButton(
                      onPressed: _authController.isLoading.value ? null : _sendResetLink,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(kDefaultRadius),
                        ),
                        elevation: 0,
                      ),
                      child: _authController.isLoading.value
                          ? const SizedBox(
                              height: 20, 
                              width: 20, 
                              child: CircularProgressIndicator(
                                color: kSecondaryColor, 
                                strokeWidth: 2.0,
                              ),
                            )
                          : Text(
                              'Get Link',
                              style: kButtonTextStyle.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),

                // Success/Error messages are now handled by AuthController via Snackbars

                // Spacer
                SizedBox(height: screenHeight * 0.05),

                // Go to Sign in Link
                Center(
                  child: TextButton(
                    onPressed: () {
                      Get.off(() => const SignInScreen()); // Navigate back to Sign In, replacing current screen
                    },
                    child: Text.rich(
                      TextSpan(
                        text: 'Go to ',
                        style: kBodyTextStyle.copyWith(
                          color: kLightTextColor,
                          fontSize: 15,
                        ),
                        children: <TextSpan>[
                          TextSpan(
                            text: 'Sign in',
                            style: kLinkTextStyle.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                SizedBox(height: screenHeight * 0.02), // Bottom spacing
              ],
            ),
          ),
        ),
      ),
    );
  }

}