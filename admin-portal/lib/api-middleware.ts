import { NextRequest, NextResponse } from 'next/server';
import { adminAuth } from './firebase-admin';

const SUPER_ADMIN_EMAIL = process.env.SUPER_ADMIN_EMAIL;

/**
 * Verifies Firebase ID token and checks super admin access
 * Returns user info if valid, throws error otherwise
 */
export async function verifySuperAdminToken(request: NextRequest) {
  const authHeader = request.headers.get('Authorization');
  
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    throw new Error('No authorization token provided');
  }
  
  const token = authHeader.split('Bearer ')[1];
  
  try {
    const decodedToken = await adminAuth.verifyIdToken(token);
    
    // Check if user is super admin
    if (!SUPER_ADMIN_EMAIL) {
      throw new Error('Super admin email not configured');
    }
    
    if (decodedToken.email?.toLowerCase() !== SUPER_ADMIN_EMAIL.toLowerCase()) {
      throw new Error('Access denied. Super admin access required.');
    }
    
    return decodedToken;
  } catch (error: any) {
    throw new Error(error.message || 'Invalid authentication token');
  }
}

/**
 * API route wrapper that enforces super admin authentication
 */
export function withSuperAdmin(
  handler: (request: NextRequest, context?: any) => Promise<NextResponse>
) {
  return async (request: NextRequest, context?: any) => {
    try {
      await verifySuperAdminToken(request);
      return await handler(request, context);
    } catch (error: any) {
      return NextResponse.json(
        { success: false, error: error.message || 'Authentication failed' },
        { status: 401 }
      );
    }
  };
}
