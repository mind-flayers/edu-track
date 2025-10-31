/**
 * Check Firestore Structure
 * 
 * This script inspects the actual Firestore structure to understand
 * how admin data is organized.
 */

import { initializeApp, cert } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import * as dotenv from 'dotenv';
import * as path from 'path';

// Load environment variables
dotenv.config({ path: path.join(__dirname, '../.env.local') });

// Initialize Firebase Admin
const app = initializeApp({
  credential: cert({
    projectId: process.env.FIREBASE_ADMIN_PROJECT_ID,
    clientEmail: process.env.FIREBASE_ADMIN_CLIENT_EMAIL,
    privateKey: process.env.FIREBASE_ADMIN_PRIVATE_KEY?.replace(/\\n/g, '\n'),
  }),
  projectId: process.env.FIREBASE_ADMIN_PROJECT_ID,
});

const db = getFirestore(app);

async function checkStructure() {
  try {
    console.log('🔍 Checking Firestore structure...\n');
    
    // Check admins collection
    console.log('📁 Checking admins collection:');
    const adminsSnapshot = await db.collection('admins').get();
    console.log(`   Found ${adminsSnapshot.docs.length} documents\n`);
    
    if (adminsSnapshot.docs.length === 0) {
      console.log('⚠️  No documents found in admins collection!');
      console.log('   This is why the admin list is empty.\n');
      
      // Check if there are any collections at root level
      console.log('📁 Checking all root-level collections:');
      const collections = await db.listCollections();
      console.log(`   Found ${collections.length} collections:`);
      for (const col of collections) {
        const snapshot = await col.limit(3).get();
        console.log(`   • ${col.id} (${snapshot.docs.length}+ documents)`);
      }
      console.log('');
      return;
    }
    
    // Inspect each admin document
    for (const doc of adminsSnapshot.docs) {
      console.log(`\n👤 Admin Document: ${doc.id}`);
      console.log(`   Data:`, doc.data());
      
      // Check subcollections
      const subcollections = await doc.ref.listCollections();
      console.log(`   Subcollections: ${subcollections.map(c => c.id).join(', ')}`);
      
      // Check adminProfile subcollection
      const profileRef = doc.ref.collection('adminProfile').doc('profile');
      const profileDoc = await profileRef.get();
      
      if (profileDoc.exists) {
        console.log(`   ✅ adminProfile/profile exists:`, profileDoc.data());
      } else {
        console.log(`   ❌ adminProfile/profile does NOT exist`);
      }
      
      // Check for other common subcollections
      for (const subcol of subcollections) {
        const subSnapshot = await subcol.limit(1).get();
        console.log(`   • ${subcol.id}: ${subSnapshot.docs.length}+ documents`);
      }
    }
    
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

checkStructure()
  .then(() => {
    console.log('\n✅ Structure check complete!\n');
    process.exit(0);
  })
  .catch((error) => {
    console.error('💥 Error:', error);
    process.exit(1);
  });
