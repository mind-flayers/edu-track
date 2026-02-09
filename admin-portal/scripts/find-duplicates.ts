/**
 * Script to find and optionally remove duplicate students from Firestore
 * Run with: npx ts-node scripts/find-duplicates.ts
 */

import { adminDb } from '../lib/firebase-admin';

interface StudentData {
  id: string;
  name: string;
  class: string;
  section: string;
  indexNumber: string;
  dob: { toDate?: () => Date } | Date;
  adminPath: string;
}

async function findDuplicates() {
  console.log('🔍 Scanning for duplicate students...\n');

  try {
    // Get all admins
    const adminsSnapshot = await adminDb.collection('admins').listDocuments();

    let totalStudents = 0;
    let totalDuplicates = 0;
    const duplicateGroups: Map<string, StudentData[]> = new Map();

    for (const adminRef of adminsSnapshot) {
      const studentsSnapshot = await adminDb
        .collection('admins')
        .doc(adminRef.id)
        .collection('students')
        .get();

      if (studentsSnapshot.empty) continue;

      console.log(`📚 Admin: ${adminRef.id} (${studentsSnapshot.size} students)`);
      totalStudents += studentsSnapshot.size;

      const studentsByKey = new Map<string, StudentData[]>();

      studentsSnapshot.forEach((doc) => {
        const data = doc.data();

        // Create a unique key based on name + class + section + dob
        const dobStr = data.dob?.toDate?.()?.toISOString() || '';
        const key = `${data.name}|${data.class}|${data.section}|${dobStr}`;

        if (!studentsByKey.has(key)) {
          studentsByKey.set(key, []);
        }

        studentsByKey.get(key)!.push({
          id: doc.id,
          name: data.name,
          class: data.class,
          section: data.section,
          indexNumber: data.indexNumber,
          dob: data.dob,
          adminPath: adminRef.id,
        });
      });

      // Find duplicates (groups with more than 1 student)
      studentsByKey.forEach((students, key) => {
        if (students.length > 1) {
          duplicateGroups.set(key, students);
          totalDuplicates += students.length - 1; // Count extra copies
        }
      });
    }

    console.log(`\n📊 Total students: ${totalStudents}`);
    console.log(`❌ Duplicate records found: ${totalDuplicates}`);
    console.log(`👥 Unique students affected: ${duplicateGroups.size}\n`);

    if (duplicateGroups.size > 0) {
      console.log('=== DUPLICATE GROUPS ===\n');

      let groupNum = 1;
      duplicateGroups.forEach((students) => {
        const first = students[0];
        console.log(`Group ${groupNum}: ${first.name} - ${first.class} ${first.section}`);
        students.forEach((student, idx) => {
          console.log(`  ${idx + 1}. Index: ${student.indexNumber} | ID: ${student.id}`);
        });
        console.log('');
        groupNum++;
      });

      console.log('\n💡 To remove duplicates:');
      console.log('   1. Review the list above');
      console.log('   2. Manually delete duplicate document IDs from Firestore Console');
      console.log('   3. Or create a cleanup script that keeps the first occurrence\n');

      console.log('🔗 Firestore Console:');
      console.log('   https://console.firebase.google.com/project/edutrack-73a2e/firestore\n');
    } else {
      console.log('✅ No duplicates found! Your database is clean.\n');
    }

  } catch (error) {
    console.error('❌ Error scanning for duplicates:', error);
    process.exit(1);
  }
}

// Run the script
findDuplicates()
  .then(() => {
    console.log('✅ Duplicate scan completed');
    process.exit(0);
  })
  .catch((error) => {
    console.error('❌ Script failed:', error);
    process.exit(1);
  });

