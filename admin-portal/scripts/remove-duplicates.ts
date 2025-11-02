/**
 * Script to automatically remove duplicate students from Firestore
 * Keeps the oldest record (first created) and removes others
 * Run with: npx ts-node scripts/remove-duplicates.ts
 */

import { adminDb } from '../lib/firebase-admin';
import * as readline from 'readline';

interface StudentData {
  id: string;
  name: string;
  class: string;
  section: string;
  indexNumber: string;
  dob: any;
  joinedAt: any;
  adminPath: string;
}

async function askConfirmation(question: string): Promise<boolean> {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
  });

  return new Promise((resolve) => {
    rl.question(question, (answer) => {
      rl.close();
      resolve(answer.toLowerCase() === 'yes' || answer.toLowerCase() === 'y');
    });
  });
}

async function removeDuplicates() {
  console.log('🔍 Scanning for duplicate students...\n');

  try {
    // Get all admins
    const adminsSnapshot = await adminDb.collection('admins').listDocuments();
    
    const duplicateGroups: Map<string, StudentData[]> = new Map();

    for (const adminRef of adminsSnapshot) {
      const studentsSnapshot = await adminDb
        .collection('admins')
        .doc(adminRef.id)
        .collection('students')
        .get();

      if (studentsSnapshot.empty) continue;

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
          joinedAt: data.joinedAt,
          adminPath: adminRef.id,
        });
      });

      // Find duplicates (groups with more than 1 student)
      studentsByKey.forEach((students, key) => {
        if (students.length > 1) {
          duplicateGroups.set(key, students);
        }
      });
    }

    if (duplicateGroups.size === 0) {
      console.log('✅ No duplicates found! Your database is clean.\n');
      process.exit(0);
    }

    console.log(`Found ${duplicateGroups.size} groups of duplicate students:\n`);

    let groupNum = 1;
    const toDelete: Array<{ adminPath: string; studentId: string; name: string; indexNumber: string }> = [];

    duplicateGroups.forEach((students) => {
      const first = students[0];
      console.log(`Group ${groupNum}: ${first.name} - ${first.class} ${first.section}`);
      
      // Sort by joinedAt to keep the oldest
      students.sort((a, b) => {
        const aTime = a.joinedAt?.toDate?.()?.getTime() || 0;
        const bTime = b.joinedAt?.toDate?.()?.getTime() || 0;
        return aTime - bTime;
      });

      students.forEach((student, idx) => {
        const marker = idx === 0 ? '✅ KEEP' : '❌ DELETE';
        console.log(`  ${marker} - Index: ${student.indexNumber} | ID: ${student.id}`);
        
        if (idx > 0) {
          toDelete.push({
            adminPath: student.adminPath,
            studentId: student.id,
            name: student.name,
            indexNumber: student.indexNumber,
          });
        }
      });
      console.log('');
      groupNum++;
    });

    console.log(`\n⚠️  WARNING: This will delete ${toDelete.length} duplicate student records!`);
    console.log('   The oldest record in each group will be kept.\n');

    const confirmed = await askConfirmation('Are you sure you want to proceed? (yes/no): ');

    if (!confirmed) {
      console.log('\n❌ Operation cancelled. No changes made.\n');
      process.exit(0);
    }

    console.log('\n🗑️  Removing duplicates...\n');

    let deleted = 0;
    for (const item of toDelete) {
      try {
        await adminDb
          .collection('admins')
          .doc(item.adminPath)
          .collection('students')
          .doc(item.studentId)
          .delete();

        console.log(`✅ Deleted: ${item.name} (${item.indexNumber})`);
        deleted++;
      } catch (error) {
        console.error(`❌ Failed to delete ${item.name} (${item.studentId}):`, error);
      }
    }

    console.log(`\n✅ Cleanup completed!`);
    console.log(`   Deleted: ${deleted}/${toDelete.length} duplicate records\n`);

  } catch (error) {
    console.error('❌ Error during cleanup:', error);
    process.exit(1);
  }
}

// Run the script
removeDuplicates()
  .then(() => {
    process.exit(0);
  })
  .catch((error) => {
    console.error('❌ Script failed:', error);
    process.exit(1);
  });

