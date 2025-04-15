import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edu_track/app/utils/constants.dart';
import 'package:flutter/material.dart';

class StudentDetailsScreen extends StatelessWidget {
  final String studentId;

  const StudentDetailsScreen({super.key, required this.studentId});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final firestore = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: kLightTextColor),
          tooltip: 'Back',
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Student Details', style: textTheme.titleLarge), // Default title
        centerTitle: true,
        // We can update the title dynamically once data is loaded if needed
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: firestore.collection('students').doc(studentId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error fetching student data: ${snapshot.error}'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Student not found.'));
          }

          // Data exists, extract it
          final studentData = snapshot.data!.data() as Map<String, dynamic>;
          final name = studentData['name'] as String? ?? 'N/A';
          final studentClass = studentData['class'] as String? ?? 'N/A';
          final section = studentData['section'] as String? ?? 'N/A';
          final rollNumber = studentData['rollNumber'] as String? ?? 'N/A';
          final parentName = studentData['parentName'] as String? ?? 'N/A';
          final parentPhone = studentData['parentPhone'] as String? ?? 'N/A';
          final address = studentData['address'] as String? ?? 'N/A';
          final photoUrl = studentData['photoUrl'] as String?;
          final email = studentData['email'] as String?; // Added email
          final joinedAt = studentData['joinedAt'] as Timestamp?; // Added joinedAt
          final isActive = studentData['isActive'] as bool? ?? false; // Added isActive

          // Format joined date if available
          final joinedDateString = joinedAt != null
              ? '${joinedAt.toDate().day}/${joinedAt.toDate().month}/${joinedAt.toDate().year}'
              : 'N/A';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(kDefaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Header
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: kLightTextColor.withOpacity(0.1),
                        backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                            ? NetworkImage(photoUrl)
                            : null,
                        onBackgroundImageError: (photoUrl != null && photoUrl.isNotEmpty) ? (exception, stackTrace) {
                          print("Error loading profile image in details: $exception");
                        } : null,
                        child: (photoUrl == null || photoUrl.isEmpty)
                            ? Icon(Icons.person_outline_rounded, size: 60, color: kLightTextColor.withOpacity(0.5))
                            : null,
                      ),
                      const SizedBox(height: kDefaultPadding),
                      Text(name, style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: kDefaultPadding / 4),
                      Text(
                        '$studentClass - Section $section',
                        style: textTheme.titleMedium?.copyWith(color: kLightTextColor),
                      ),
                       const SizedBox(height: kDefaultPadding / 4),
                       Text(
                        'Roll No: $rollNumber',
                        style: textTheme.titleSmall?.copyWith(color: kLightTextColor),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: kDefaultPadding * 1.5),
                Divider(color: kLightTextColor.withOpacity(0.2)),
                const SizedBox(height: kDefaultPadding),

                // Personal Information Section
                Text('Personal Information', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: kDefaultPadding),
                _buildDetailRow(Icons.email_outlined, 'Email', email ?? 'N/A'),
                _buildDetailRow(Icons.phone_android_outlined, 'Parent Phone', parentPhone),
                _buildDetailRow(Icons.person_outline, 'Parent Name', parentName),
                _buildDetailRow(Icons.location_on_outlined, 'Address', address),
                _buildDetailRow(Icons.calendar_today_outlined, 'Joined Date', joinedDateString),
                _buildDetailRow(
                  Icons.check_circle_outline,
                  'Status',
                  isActive ? 'Active' : 'Inactive',
                  valueColor: isActive ? Colors.green.shade600 : Colors.red.shade600,
                ),

                // Add more sections as needed (e.g., Attendance, Fees, Exam Results)
                // These would likely involve further Firestore queries using the studentId

                const SizedBox(height: kDefaultPadding * 2),
              ],
            ),
          );
        },
      ),
    );
  }

  // Helper widget to build detail rows consistently
  Widget _buildDetailRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: kDefaultPadding * 0.75),
      child: Row(
        children: [
          Icon(icon, color: kPrimaryColor.withOpacity(0.8), size: 20),
          const SizedBox(width: kDefaultPadding),
          Text('$label:', style: TextStyle(color: kLightTextColor, fontWeight: FontWeight.w500)),
          const SizedBox(width: kDefaultPadding / 2),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.w600, color: valueColor ?? kTextColor),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}