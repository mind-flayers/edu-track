import { NextRequest, NextResponse } from 'next/server';
import { adminAuth, adminDb } from '@/lib/firebase-admin';
import { AdminProfile, ApiResponse } from '@/types';

// GET /api/admins/[id] - Get single admin
export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id: adminId } = await params;
    const profileDoc = await adminDb
      .collection('admins')
      .doc(adminId)
      .collection('adminProfile')
      .doc('profile')
      .get();
    
    if (!profileDoc.exists) {
      const response: ApiResponse = {
        success: false,
        error: 'Admin not found',
      };
      return NextResponse.json(response, { status: 404 });
    }
    
    const data = profileDoc.data();
    const admin: AdminProfile = {
      uid: adminId,
      name: data?.name || '',
      academyName: data?.academyName || '',
      email: data?.email || '',
      profilePhotoUrl: data?.profilePhotoUrl || '',
      smsGatewayToken: data?.smsGatewayToken || '',
      whatsappGatewayToken: data?.whatsappGatewayToken || '',
      createdAt: data?.createdAt?.toDate() || new Date(),
      updatedAt: data?.updatedAt?.toDate() || new Date(),
    };
    
    const response: ApiResponse<AdminProfile> = {
      success: true,
      data: admin,
    };
    
    return NextResponse.json(response);
  } catch (error: any) {
    console.error('Error fetching admin:', error);
    const response: ApiResponse = {
      success: false,
      error: error.message || 'Failed to fetch admin',
    };
    return NextResponse.json(response, { status: 500 });
  }
}

// PATCH /api/admins/[id] - Update admin
export async function PATCH(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id: adminId } = await params;
    const body = await request.json();
    const { name, academyName, profilePhotoUrl, smsGatewayToken, whatsappGatewayToken } = body;
    
    const updateData: any = {
      updatedAt: new Date(),
    };
    
    if (name) updateData.name = name;
    if (academyName) updateData.academyName = academyName;
    if (profilePhotoUrl !== undefined) updateData.profilePhotoUrl = profilePhotoUrl;
    if (smsGatewayToken !== undefined) updateData.smsGatewayToken = smsGatewayToken;
    if (whatsappGatewayToken !== undefined) updateData.whatsappGatewayToken = whatsappGatewayToken;
    
    await adminDb
      .collection('admins')
      .doc(adminId)
      .collection('adminProfile')
      .doc('profile')
      .update(updateData);
    
    // Update Firebase Auth display name if name changed
    if (name) {
      await adminAuth.updateUser(adminId, {
        displayName: name,
      });
    }
    
    const response: ApiResponse = {
      success: true,
      message: 'Admin updated successfully',
    };
    
    return NextResponse.json(response);
  } catch (error: any) {
    console.error('Error updating admin:', error);
    const response: ApiResponse = {
      success: false,
      error: error.message || 'Failed to update admin',
    };
    return NextResponse.json(response, { status: 500 });
  }
}

// DELETE /api/admins/[id] - Delete admin
export async function DELETE(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id: adminId } = await params;
    
    // Delete all subcollections (students, teachers, etc.)
    const adminRef = adminDb.collection('admins').doc(adminId);
    
    // Delete admin profile
    await adminRef.collection('adminProfile').doc('profile').delete();
    
    // Delete academy settings
    const settingsSnapshot = await adminRef.collection('academySettings').get();
    for (const doc of settingsSnapshot.docs) {
      await doc.ref.delete();
    }
    
    // Delete admin document
    await adminRef.delete();
    
    // Delete Firebase Auth user
    await adminAuth.deleteUser(adminId);
    
    const response: ApiResponse = {
      success: true,
      message: 'Admin deleted successfully',
    };
    
    return NextResponse.json(response);
  } catch (error: any) {
    console.error('Error deleting admin:', error);
    const response: ApiResponse = {
      success: false,
      error: error.message || 'Failed to delete admin',
    };
    return NextResponse.json(response, { status: 500 });
  }
}
