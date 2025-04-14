import 'package:flutter/material.dart';
import 'package:edu_track/app/utils/constants.dart';
// No longer need Get or Timer here, AuthController handles navigation

// Import Sign In Screen (create this file next)
// import 'signin_screen.dart';

class LaunchingScreen extends StatelessWidget { // Changed to StatelessWidget
  const LaunchingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      // Use kSecondaryColor for pure white as seen in the image
      // Use kBackgroundColor if you prefer the theme's light grey
      backgroundColor: kSecondaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Logo
            Image.asset(
              'assets/images/app_logo.png', // Ensure this path is correct
              height: screenWidth * 0.3, // Adjust size as needed
              width: screenWidth * 0.3,
            ),
            SizedBox(height: screenHeight * 0.03), // Responsive spacing

            // App Name
            Text(
              'EduTrack',
              style: kHeadlineStyle.copyWith(fontSize: 32), // Slightly larger headline
            ),
            SizedBox(height: screenHeight * 0.01), // Responsive spacing

            // Tagline
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1), // Add horizontal padding
              child: Text(
                'Manage your Schools or Academy effortlessly with EduTrack',
                textAlign: TextAlign.center,
                style: kBodyTextStyle.copyWith(color: kLightTextColor, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}