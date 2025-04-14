import 'package:flutter/material.dart';

class AttendanceSummaryScreen extends StatelessWidget {
  const AttendanceSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Summary'),
      ),
      body: const Center(
        child: Text('Attendance Summary Screen Placeholder'),
      ),
    );
  }
}