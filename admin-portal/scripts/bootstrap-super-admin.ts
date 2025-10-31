/**
 * Bootstrap Super Admin
 * 
 * This script creates the initial super admin account in both
 * Firebase Auth and Firestore.
 * 
 * Usage: npx tsx scripts/bootstrap-super-admin.ts
 */

import { initializeApp, cert } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';
import * as dotenv from 'dotenv';
import * as path from 'path';
import * as readline from 'readline';

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

const SUPER_ADMIN_EMAIL = process.env.SUPER_ADMIN_EMAIL || 'mishaf1106@gmail.com';

function askQuestion(query: string): Promise<string> {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
  });

  return new Promise(resolve => rl.question(query, ans => {
    rl.close();
    resolve(ans);
  }));
}

async function bootstrapSuperAdmin() {
  try {
    console.log('🚀 Bootstrap Super Admin Account');
    console.log('=' .repeat(60));
    console.log(`Super Admin Email: ${SUPER_ADMIN_EMAIL}\n`);
    
    // Check if user exists in Firebase Auth
    let user;
    try {
      user = await auth.getUserByEmail(SUPER_ADMIN_EMAIL);
      console.log(`✅ User already exists in Firebase Auth (UID: ${user.uid})`);
    } catch (error: any) {
      if (error.code === 'auth/user-not-found') {
        console.log('📝 User not found in Firebase Auth. Creating...');
        
        // Prompt for details
        const name = await askQuestion('Enter admin name: ');
        const password = await askQuestion('Enter password (min 6 characters): ');
        const academyName = await askQuestion('Enter academy name: ');
        
        if (password.length < 6) {
          throw new Error('Password must be at least 6 characters');
        }
        
        // Create user
        user = await auth.createUser({
          email: SUPER_ADMIN_EMAIL,
          password: password,
          displayName: name,
        });
        
        console.log(`✅ Created user in Firebase Auth (UID: ${user.uid})`);
        
        // Create Firestore profile
        const adminRef = db.collection('admins').doc(user.uid);
        const profileRef = adminRef.collection('adminProfile').doc('profile');
        
        const profileData = {
          name: name,
          academyName: academyName,
          email: SUPER_ADMIN_EMAIL,
          profilePhotoUrl: '',
          smsGatewayToken: '',
          whatsappGatewayToken: '',
          createdAt: new Date(),
          updatedAt: new Date(),
        };
        
        await profileRef.set(profileData);
        console.log(`✅ Created admin profile in Firestore`);
        
        // Create academy settings
        const settingsRef = adminRef.collection('academySettings').doc('subjects');
        await settingsRef.set({
          subjects: ['Mathematics', 'Science', 'English', 'History', 'ICT', 'Tamil', 'Sinhala', 'Commerce'],
          createdAt: new Date(),
          updatedAt: new Date(),
          updatedBy: user.uid,
        });
        console.log(`✅ Created academy settings`);
        
        console.log('\n' + '='.repeat(60));
        console.log('🎉 Super Admin Account Created Successfully!');
        console.log(`   Email: ${SUPER_ADMIN_EMAIL}`);
        console.log(`   UID: ${user.uid}`);
        console.log('='.repeat(60));
        
      } else {
        throw error;
      }
    }
    
    // If user exists, check if profile exists in Firestore
    if (user) {
      const adminRef = db.collection('admins').doc(user.uid);
      const profileRef = adminRef.collection('adminProfile').doc('profile');
      const profileDoc = await profileRef.get();
      
      if (!profileDoc.exists) {
        console.log('⚠️  User exists in Auth but not in Firestore. Creating profile...');
        
        const name = await askQuestion(`Enter admin name [${user.displayName || 'Admin'}]: `) || user.displayName || 'Admin';
        const academyName = await askQuestion('Enter academy name [My Academy]: ') || 'My Academy';
        
        const profileData = {
          name: name,
          academyName: academyName,
          email: SUPER_ADMIN_EMAIL,
          profilePhotoUrl: user.photoURL || '',
          smsGatewayToken: '',
          whatsappGatewayToken: '',
          createdAt: new Date(user.metadata.creationTime || Date.now()),
          updatedAt: new Date(),
        };
        
        await profileRef.set(profileData);
        console.log(`✅ Created admin profile in Firestore`);
        
        // Create academy settings if not exists
        const settingsRef = adminRef.collection('academySettings').doc('subjects');
        const settingsDoc = await settingsRef.get();
        
        if (!settingsDoc.exists) {
          await settingsRef.set({
            subjects: ['Mathematics', 'Science', 'English', 'History', 'ICT', 'Tamil', 'Sinhala', 'Commerce'],
            createdAt: new Date(),
            updatedAt: new Date(),
            updatedBy: user.uid,
          });
          console.log(`✅ Created academy settings`);
        }
        
        console.log('\n' + '='.repeat(60));
        console.log('🎉 Super Admin Profile Synced Successfully!');
        console.log(`   Email: ${SUPER_ADMIN_EMAIL}`);
        console.log(`   UID: ${user.uid}`);
        console.log('='.repeat(60));
      } else {
        console.log('✅ Profile already exists in Firestore');
        console.log('\n' + '='.repeat(60));
        console.log('✨ Super Admin is already set up!');
        console.log(`   Email: ${SUPER_ADMIN_EMAIL}`);
        console.log(`   UID: ${user.uid}`);
        console.log('='.repeat(60));
      }
    }
    
  } catch (error) {
    console.error('\n❌ Error:', error);
    process.exit(1);
  }
}

bootstrapSuperAdmin()
  .then(() => {
    console.log('\n✅ Bootstrap complete!\n');
    process.exit(0);
  })
  .catch((error) => {
    console.error('\n💥 Bootstrap failed:', error);
    process.exit(1);
  });
