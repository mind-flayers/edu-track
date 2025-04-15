import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:edu_track/app/utils/constants.dart'; // Import constants and theme
import 'package:edu_track/app/features/authentication/controllers/auth_controller.dart'; // Import AuthController
import 'package:edu_track/app/features/authentication/screens/launching_screen.dart'; // Import Launching Screen
// Import firebase_options.dart (Generated via FlutterFire CLI)
import 'firebase_options.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize AuthController
  Get.put(AuthController());

  // Run the app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp( // Use GetMaterialApp
      title: 'EduTrack Admin',
      theme: appTheme, // Apply the custom theme
      debugShowCheckedModeBanner: false, // Hide debug banner
      home: const LaunchingScreen(), // Start with Launching Screen
    );
  }
}
