/**
 * Sync Firebase Auth Users to Firestore
 * 
 * This script fetches all users from Firebase Authentication and creates
 * corresponding admin profile documents in Firestore if they don't exist.
 * 
 * Usage: npx tsx scripts/sync-auth-to-firestore.ts
 */

import { initializeApp, cert } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
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

const auth = getAuth(app);
const db = getFirestore(app);

async function syncAuthToFirestore() {
  try {
    console.log('🔍 Fetching all users from Firebase Authentication...\n');
    
    // List all users
    const listUsersResult = await auth.listUsers(1000);
    const users = listUsersResult.users;
    
    console.log(`📊 Found ${users.length} users in Firebase Auth\n`);
    
    if (users.length === 0) {
      console.log('⚠️  No users found in Firebase Authentication.');
      console.log('💡 Create a user first using Firebase Console or the admin portal.\n');
      return;
    }
    
    let syncedCount = 0;
    let skippedCount = 0;
    
    for (const user of users) {
      console.log(`\n👤 Processing user: ${user.email} (${user.uid})`);
      
      // Check if admin DOCUMENT exists (not just the profile)
      const adminRef = db.collection('admins').doc(user.uid);
      const adminDoc = await adminRef.get();
      
      console.log(`   Admin document exists: ${adminDoc.exists}`);
      
      // Check if admin profile already exists
      const profileRef = adminRef.collection('adminProfile').doc('profile');
      const profileDoc = await profileRef.get();
      
      console.log(`   Profile document exists: ${profileDoc.exists}`);
      
      if (profileDoc.exists) {
        console.log(`   ✓ Profile already exists - skipping`);
        skippedCount++;
        continue;
      }
      
      // Create admin profile
      const profileData = {
        name: user.displayName || user.email?.split('@')[0] || 'Admin User',
        academyName: 'My Academy', // Default value - should be updated later
        email: user.email || '',
        profilePhotoUrl: user.photoURL || '',
        smsGatewayToken: '',
        whatsappGatewayToken: '',
        createdAt: user.metadata.creationTime ? new Date(user.metadata.creationTime) : new Date(),
        updatedAt: new Date(),
      };
      
      await profileRef.set(profileData);
      console.log(`   ✅ Created profile in Firestore`);
      
      // Create default academy settings
      const settingsRef = adminRef.collection('academySettings').doc('subjects');
      const settingsDoc = await settingsRef.get();
      
      if (!settingsDoc.exists) {
        await settingsRef.set({
          subjects: ['Mathematics', 'Science', 'English', 'History', 'ICT', 'Tamil', 'Sinhala', 'Commerce'],
          createdAt: new Date(),
          updatedAt: new Date(),
          updatedBy: user.uid,
        });
        console.log(`   ✅ Created academy settings`);
      }
      
      syncedCount++;
    }
    
    console.log('\n' + '='.repeat(60));
    console.log('✨ Sync Complete!');
    console.log(`   • Synced: ${syncedCount} users`);
    console.log(`   • Skipped: ${skippedCount} users (already have profiles)`);
    console.log(`   • Total: ${users.length} users`);
    console.log('='.repeat(60) + '\n');
    
  } catch (error) {
    console.error('❌ Error syncing users:', error);
    process.exit(1);
  }
}

// Run the sync
syncAuthToFirestore()
  .then(() => {
    console.log('🎉 Sync script completed successfully!\n');
    process.exit(0);
  })
  .catch((error) => {
    console.error('💥 Sync script failed:', error);
    process.exit(1);
  });
