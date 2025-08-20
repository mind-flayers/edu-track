# Manual Database Update Instructions

If the Node.js script has connectivity issues, you can update the attendance records manually through the Firebase Console:

## Option 1: Firebase Console (Web Interface)

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **edutrack-73a2e**
3. Go to **Firestore Database**
4. Navigate to: `admins` → `jGTyDPHBwRaVVAwN2YtHysDQJP23` → `students`
5. For each student:
   - Click on the student document
   - Go to the `attendance` subcollection
   - For each attendance document, add these fields:
     - `subject`: (string) - Choose from student's subjects
     - Update `markedAt`: (timestamp) - Set to specific time like 8:00 AM, 9:30 AM, etc.

## Option 2: Try the Script Again

Sometimes network issues are temporary. Try running the update script again:

```bash
node update_attendance_structure.js
```

## Option 3: Flutter App Update

Update your Flutter app to handle the new attendance structure. Here's what the new attendance document should look like:

```dart
// New Attendance Document Structure
{
  'date': '2025-08-20',           // Date string
  'subject': 'Mathematics',        // Which class/subject
  'status': 'present',            // present/absent
  'markedBy': 'adminUid',         // Admin who marked
  'markedAt': Timestamp.now()     // Exact time marked
}
```

## Subject-Date Mapping Used:

- **Sunday**: 1st subject from student's subject list
- **Monday**: 2nd subject from student's subject list
- **Tuesday**: 3rd subject from student's subject list
- **Wednesday**: 4th subject from student's subject list
- **Thursday**: 5th subject from student's subject list
- **Friday**: 1st subject (cycle repeats)
- **Saturday**: 2nd subject

## Time Slots by Subject:

- **Mathematics**: 8:00 AM
- **Science**: 9:30 AM
- **English**: 11:00 AM
- **History**: 1:00 PM
- **ICT**: 2:30 PM
- **Tamil/Sinhala**: 4:00 PM
- **Commerce**: 2:30 PM

## Verify the Changes

After updating, check that your attendance records now include:
1. ✅ `subject` field with the class name
2. ✅ `date` field with the date
3. ✅ `markedAt` field with specific timestamp
4. ✅ `status` field (present/absent)
5. ✅ `markedBy` field with admin ID