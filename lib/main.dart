import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:edu_track/app/utils/constants.dart'; // Import constants and theme
import 'package:edu_track/app/features/authentication/controllers/auth_controller.dart';
import 'package:edu_track/app/features/authentication/screens/launching_screen.dart';
import 'package:edu_track/app/features/profile/bindings/profile_binding.dart'; // Import ProfileBinding
import 'package:edu_track/app/features/profile/screens/profile_settings_screen.dart'; // Import ProfileScreen
// Import firebase_options.dart (Generated via FlutterFire CLI)
import 'firebase_options.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (with duplicate check)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    if (e.toString().contains('duplicate-app')) {
      // Firebase already initialized, skip
      print('Firebase already initialized');
    } else {
      // Re-throw other errors
      rethrow;
    }
  }

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
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.launching, // Use initial route name
      getPages: AppPages.routes, // Define routes using GetPage
      // home: const LaunchingScreen(), // Remove home if using initialRoute
    );
  }
}

// Define Route Names
class AppRoutes {
  static const launching = '/';
  static const profileSettings = '/profile-settings';
  // Add other routes here as needed
  // static const dashboard = '/dashboard';
  // static const addTeacher = '/add-teacher';
}

// Define Pages and Bindings
class AppPages {
  static final routes = [
    GetPage(
      name: AppRoutes.launching,
      page: () => const LaunchingScreen(),
      // No specific binding needed here if AuthController is globally put
    ),
    GetPage(
      name: AppRoutes.profileSettings,
      page: () => const ProfileSettingsScreen(),
      binding: ProfileBinding(), // Apply the binding for this route
    ),
    // Add other pages here
    // GetPage(name: AppRoutes.dashboard, page: () => DashboardScreen(), binding: DashboardBinding()),
    // GetPage(name: AppRoutes.addTeacher, page: () => AddTeacherScreen(), binding: AddTeacherBinding()),
  ];
}
