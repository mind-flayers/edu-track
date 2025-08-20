// This is a basic Flutter widget test for EduTrack app.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';

import 'package:edu_track/main.dart';

// Mock Firebase initialization for testing
void main() {
  setUpAll(() async {
    // Mock Firebase initialization
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('EduTrack app launches and shows launching screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our app shows EduTrack title.
    expect(find.text('EduTrack'), findsOneWidget);
    expect(find.text('Manage your Schools or Academy effortlessly with EduTrack'), findsOneWidget);
  });
}
