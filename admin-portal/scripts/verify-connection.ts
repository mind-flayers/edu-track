/**
 * Verify Firebase Connection
 * 
 * This script verifies that we're connected to the right Firebase project
 * and displays detailed connection information.
 */

import { initializeApp, cert } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';
import * as dotenv from 'dotenv';
import * as path from 'path';

// Load environment variables
dotenv.config({ path: path.join(__dirname, '../.env.local') });

console.log('🔍 Firebase Connection Verification');
console.log('='.repeat(60));
console.log('\n📋 Environment Variables:');
console.log(`   Project ID: ${process.env.FIREBASE_ADMIN_PROJECT_ID}`);
console.log(`   Client Email: ${process.env.FIREBASE_ADMIN_CLIENT_EMAIL}`);
console.log(`   Private Key: ${process.env.FIREBASE_ADMIN_PRIVATE_KEY ? '***' + process.env.FIREBASE_ADMIN_PRIVATE_KEY.substring(process.env.FIREBASE_ADMIN_PRIVATE_KEY.length - 20) : 'NOT SET'}`);
console.log('');

// Initialize Firebase Admin
const app = initializeApp({
  credential: cert({
    projectId: process.env.FIREBASE_ADMIN_PROJECT_ID,
    clientEmail: process.env.FIREBASE_ADMIN_CLIENT_EMAIL,
    privateKey: process.env.FIREBASE_ADMIN_PRIVATE_KEY?.replace(/\\n/g, '\n'),
  }),
  projectId: process.env.FIREBASE_ADMIN_PROJECT_ID,
});

const auth = getAuth(app);
const db = getFirestore(app);

async function verify() {
  try {
    console.log('🔌 Testing Firebase Admin Connection...\n');
    
    // Test Auth
    console.log('🔐 Firebase Authentication:');
    const listUsersResult = await auth.listUsers(10);
    console.log(`   ✅ Connected successfully`);
    console.log(`   Found ${listUsersResult.users.length} users:`);
    for (const user of listUsersResult.users) {
      console.log(`      • ${user.email} (UID: ${user.uid})`);
    }
    console.log('');
    
    // Test Firestore
    console.log('📦 Firestore Database:');
    const adminsSnapshot = await db.collection('admins').get();
    console.log(`   ✅ Connected successfully`);
    console.log(`   admins collection: ${adminsSnapshot.docs.length} documents`);
    
    if (adminsSnapshot.docs.length === 0) {
      console.log('\n⚠️  ISSUE IDENTIFIED:');
      console.log('   The admins collection is EMPTY in Firestore!');
      console.log('   But Firebase Auth has users.');
      console.log('\n💡 Solution:');
      console.log('   The Flutter app creates admin profiles in Firestore.');
      console.log('   The Next.js portal reads from Firestore.');
      console.log('   ');
      console.log('   Option 1: Use the Flutter app to create admin data');
      console.log('   Option 2: Create admin using the portal (but need to fix sync)');
      console.log('');
    } else {
      console.log('   Admin documents:');
      for (const doc of adminsSnapshot.docs) {
        console.log(`      • ${doc.id}`);
        const profileRef = doc.ref.collection('adminProfile').doc('profile');
        const profileDoc = await profileRef.get();
        if (profileDoc.exists) {
          const data = profileDoc.data();
          console.log(`        Name: ${data?.name}`);
          console.log(`        Email: ${data?.email}`);
        }
      }
    }
    
    // List all collections
    console.log('\n📁 All Root Collections:');
    const collections = await db.listCollections();
    for (const col of collections) {
      const snapshot = await col.limit(1).get();
      console.log(`   • ${col.id} (${snapshot.docs.length > 0 ? 'has data' : 'empty'})`);
    }
    
    console.log('\n' + '='.repeat(60));
    console.log('✅ Verification Complete');
    console.log('='.repeat(60));
    
  } catch (error: any) {
    console.error('\n❌ Error:', error.message);
    console.error('\nFull error:', error);
    process.exit(1);
  }
}

verify()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error('💥 Verification failed:', error);
    process.exit(1);
  });
