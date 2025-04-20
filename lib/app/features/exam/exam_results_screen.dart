import 'package:flutter/material.dart';

class ExamResultsScreen extends StatelessWidget {
  const ExamResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exam Results'),
      ),
      body: const Center(
        child: Text('Exam Results Screen Placeholder'),
      ),
    );
  }
}