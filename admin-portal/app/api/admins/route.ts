import { NextRequest, NextResponse } from 'next/server';
import { adminAuth, adminDb } from '@/lib/firebase-admin';
import { AdminProfile, ApiResponse } from '@/types';

// GET /api/admins - List all admins
export async function GET(request: NextRequest) {
  try {
    console.log('[API] Fetching admins from Firebase Auth...');
    
    // Get all users from Firebase Auth instead of Firestore
    const listUsersResult = await adminAuth.listUsers(1000);
    console.log(`[API] Found ${listUsersResult.users.length} users in Firebase Auth`);
    
    const admins: AdminProfile[] = [];
    
    for (const user of listUsersResult.users) {
      console.log(`[API] Checking user: ${user.email} (${user.uid})`);
      
      // Check if this user has an admin profile in Firestore
      const profileRef = adminDb.collection('admins').doc(user.uid).collection('adminProfile').doc('profile');
      const profileDoc = await profileRef.get();
      
      if (profileDoc.exists) {
        const data = profileDoc.data();
        console.log(`[API] Profile found for ${user.uid}`);
        admins.push({
          uid: user.uid,
          name: data?.name || user.displayName || '',
          academyName: data?.academyName || '',
          email: data?.email || user.email || '',
          profilePhotoUrl: data?.profilePhotoUrl || user.photoURL || '',
          smsGatewayToken: data?.smsGatewayToken || '',
          whatsappGatewayToken: data?.whatsappGatewayToken || '',
          createdAt: data?.createdAt?.toDate() || new Date(user.metadata.creationTime),
          updatedAt: data?.updatedAt?.toDate() || new Date(),
        });
      } else {
        console.log(`[API] No profile found for user ${user.uid}, skipping`);
      }
    }
    
    console.log(`[API] Returning ${admins.length} admins with profiles`);
    const response: ApiResponse<AdminProfile[]> = {
      success: true,
      data: admins,
    };
    
    return NextResponse.json(response);
  } catch (error: any) {
    console.error('[API] Error fetching admins:', error);
    const response: ApiResponse = {
      success: false,
      error: error.message || 'Failed to fetch admins',
    };
    return NextResponse.json(response, { status: 500 });
  }
}

// POST /api/admins - Create new admin
export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { email, password, name, academyName, profilePhotoUrl } = body;
    
    // Validate input
    if (!email || !password || !name || !academyName) {
      const response: ApiResponse = {
        success: false,
        error: 'Email, password, name, and academy name are required',
      };
      return NextResponse.json(response, { status: 400 });
    }
    
    // Create Firebase Auth user
    const userRecord = await adminAuth.createUser({
      email,
      password,
      displayName: name,
    });
    
    // Create admin profile in Firestore
    const adminRef = adminDb.collection('admins').doc(userRecord.uid);
    const profileRef = adminRef.collection('adminProfile').doc('profile');
    
    const profileData = {
      name,
      academyName,
      email,
      profilePhotoUrl: profilePhotoUrl || '',
      smsGatewayToken: '',
      whatsappGatewayToken: '',
      createdAt: new Date(),
      updatedAt: new Date(),
    };
    
    await profileRef.set(profileData);
    
    // Create academy settings with default subjects
    const settingsRef = adminRef.collection('academySettings').doc('subjects');
    await settingsRef.set({
      subjects: ['Mathematics', 'Science', 'English', 'History', 'ICT', 'Tamil', 'Sinhala', 'Commerce'],
      createdAt: new Date(),
      updatedAt: new Date(),
      updatedBy: userRecord.uid,
    });
    
    const admin: AdminProfile = {
      uid: userRecord.uid,
      ...profileData,
    };
    
    const response: ApiResponse<AdminProfile> = {
      success: true,
      data: admin,
      message: 'Admin created successfully',
    };
    
    return NextResponse.json(response);
  } catch (error: any) {
    console.error('Error creating admin:', error);
    const response: ApiResponse = {
      success: false,
      error: error.message || 'Failed to create admin',
    };
    return NextResponse.json(response, { status: 500 });
  }
}
