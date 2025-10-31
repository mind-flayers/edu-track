/**
 * Checks if the given email is the super admin
 */
export function isSuperAdmin(email: string | null | undefined): boolean {
  if (!email) return false;
  
  const superAdminEmail = process.env.SUPER_ADMIN_EMAIL || process.env.NEXT_PUBLIC_SUPER_ADMIN_EMAIL;
  
  if (!superAdminEmail) {
    console.error('SUPER_ADMIN_EMAIL not configured in environment variables');
    return false;
  }
  
  return email.toLowerCase() === superAdminEmail.toLowerCase();
}

/**
 * Validates super admin access
 * Throws error if user is not super admin
 */
export function requireSuperAdmin(email: string | null | undefined): void {
  if (!isSuperAdmin(email)) {
    throw new Error('Access denied. Only super admin can access this resource.');
  }
}
