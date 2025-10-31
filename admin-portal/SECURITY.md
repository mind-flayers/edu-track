# Admin Portal Security

## Access Control

### Super Admin Restriction

The EduTrack Admin Portal implements **strict single-user access control**:

- ✅ **Only ONE email** can access the admin portal
- ✅ Configured via `SUPER_ADMIN_EMAIL` environment variable
- ✅ Enforced on both client and server side
- ✅ All API routes verify super admin token
- ❌ Regular academy admins **cannot** access this portal

### Authentication Flow

1. **Login Page**: User enters email and password
2. **Email Verification**: System checks if email matches `SUPER_ADMIN_EMAIL`
3. **Firebase Auth**: If email matches, authenticate with Firebase
4. **Token Verification**: All API calls verify the user's Firebase token
5. **Super Admin Check**: API middleware validates email against `SUPER_ADMIN_EMAIL`

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Login Attempt                           │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
              ┌──────────────────────┐
              │  Email == SUPER_ADMIN? │
              └──────────┬─────────────┘
                         │
            ┌────────────┴────────────┐
            │ NO                   YES│
            ▼                         ▼
    ┌──────────────┐         ┌──────────────┐
    │ Access Denied│         │Firebase Auth │
    └──────────────┘         └──────┬───────┘
                                    │
                                    ▼
                           ┌─────────────────┐
                           │ Get ID Token    │
                           └────────┬────────┘
                                    │
                                    ▼
                           ┌─────────────────┐
                           │  API Calls      │
                           │ (with Bearer    │
                           │   token)        │
                           └────────┬────────┘
                                    │
                                    ▼
                           ┌─────────────────┐
                           │Verify Token &   │
                           │Check Super Admin│
                           └────────┬────────┘
                                    │
                       ┌────────────┴────────────┐
                       │ NO                   YES│
                       ▼                         ▼
               ┌──────────────┐        ┌──────────────┐
               │ 401 Error    │        │ Process      │
               │ Access Denied│        │ Request      │
               └──────────────┘        └──────────────┘
```

## Security Layers

### 1. Client-Side Protection

**Location**: `contexts/AuthContext.tsx`

```typescript
const signIn = async (email: string, password: string) => {
  // Check email BEFORE attempting Firebase auth
  if (email.toLowerCase() !== SUPER_ADMIN_EMAIL.toLowerCase()) {
    throw new Error('Access denied. This portal is restricted to super admin only.');
  }
  await signInWithEmailAndPassword(auth, email, password);
};
```

**Purpose**: Immediate user feedback without Firebase API call

### 2. Server-Side Protection

**Location**: `lib/api-middleware.ts`

```typescript
export async function verifySuperAdminToken(request: NextRequest) {
  const token = extractToken(request);
  const decodedToken = await adminAuth.verifyIdToken(token);
  
  if (decodedToken.email?.toLowerCase() !== SUPER_ADMIN_EMAIL.toLowerCase()) {
    throw new Error('Access denied. Super admin access required.');
  }
  
  return decodedToken;
}
```

**Purpose**: Prevent unauthorized API access even with valid Firebase token

### 3. Middleware Wrapper

**Location**: `lib/api-middleware.ts`

```typescript
export function withSuperAdmin(handler) {
  return async (request, context) => {
    try {
      await verifySuperAdminToken(request);
      return await handler(request, context);
    } catch (error) {
      return NextResponse.json({ success: false, error: error.message }, { status: 401 });
    }
  };
}
```

**Usage**: Wrap all API routes with this middleware

## Environment Variables

### Required Variables

```env
# Super Admin Email - CRITICAL SECURITY SETTING
SUPER_ADMIN_EMAIL=your-secure-email@example.com

# Firebase Admin SDK
FIREBASE_ADMIN_PROJECT_ID=edutrack-73a2e
FIREBASE_ADMIN_CLIENT_EMAIL=firebase-adminsdk-xxx@edutrack-73a2e.iam.gserviceaccount.com
FIREBASE_ADMIN_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"

# Firebase Client
NEXT_PUBLIC_FIREBASE_API_KEY=...
NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=...
NEXT_PUBLIC_FIREBASE_PROJECT_ID=...

# Session Secret
SESSION_SECRET=random-32-character-secret-key
```

### Security Best Practices

1. **Never commit `.env.local`** to version control
2. **Use strong Firebase authentication** rules
3. **Rotate service account keys** periodically
4. **Monitor access logs** for unauthorized attempts
5. **Use HTTPS in production**
6. **Keep dependencies updated**

## API Routes Protection

### Protected Routes

All API routes under `/api/**` should be protected:

```typescript
// app/api/admins/route.ts
import { withSuperAdmin } from '@/lib/api-middleware';

export const GET = withSuperAdmin(async (request) => {
  // Your handler code
});

export const POST = withSuperAdmin(async (request) => {
  // Your handler code
});
```

### Unprotected Routes

Only the login page should be publicly accessible:
- `/` (redirects to login or dashboard)
- `/login`

## User Roles

### Super Admin (Portal Access)
- **Email**: Configured in `SUPER_ADMIN_EMAIL`
- **Access**: Full portal access
- **Capabilities**:
  - Create academy admin accounts
  - Import students for any academy
  - View all admins
  - Delete admin accounts
  - Manage system-wide operations

### Academy Admin (Flutter App Only)
- **Email**: Any email created as admin via portal
- **Access**: Flutter mobile/desktop app only
- **Capabilities**:
  - Manage their own academy students
  - Mark attendance
  - Process fees
  - View reports
  - **Cannot access admin portal**

## Firestore Security Rules

Ensure Firestore rules enforce proper access control:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Only authenticated users can read/write
    match /admins/{adminId}/{document=**} {
      allow read, write: if request.auth != null 
        && request.auth.uid == adminId;
    }
    
    // Super admin can read all
    match /admins/{adminId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

## Monitoring & Auditing

### Recommended Monitoring

1. **Firebase Authentication Logs**: Monitor login attempts
2. **Firestore Audit Logs**: Track data modifications
3. **Application Logs**: Log all super admin actions
4. **Failed Login Attempts**: Alert on repeated failures

### Implementation Example

```typescript
// Log all admin actions
export async function logAdminAction(
  action: string, 
  details: any
) {
  await adminDb.collection('audit_logs').add({
    action,
    details,
    timestamp: new Date(),
    superAdmin: true,
  });
}
```

## Threat Mitigation

| Threat | Mitigation |
|--------|-----------|
| Unauthorized access | Email-based access control + Firebase Auth |
| Token theft | Short-lived tokens, HTTPS only |
| Credential compromise | Strong passwords, 2FA recommended |
| API abuse | Rate limiting (future), request validation |
| Data exfiltration | Firestore rules, server-side validation |
| CSRF attacks | Firebase tokens, SameSite cookies |

## Emergency Procedures

### If Super Admin Credentials Compromised

1. **Immediately change password** in Firebase Console
2. **Revoke all active sessions** in Firebase Auth
3. **Update `SUPER_ADMIN_EMAIL`** if email compromised
4. **Review audit logs** for unauthorized actions
5. **Rotate service account key** in Firebase Console
6. **Update `.env.local`** with new credentials
7. **Restart application** to apply changes

### If Service Account Key Compromised

1. **Generate new private key** in Firebase Console
2. **Delete compromised key** immediately
3. **Update `.env.local`** with new key
4. **Restart application**
5. **Review Firestore changes** for unauthorized modifications
6. **Investigate** how key was compromised

## Production Deployment

### Security Checklist

- [ ] `SUPER_ADMIN_EMAIL` configured correctly
- [ ] Firebase Admin SDK key secured (use secrets management)
- [ ] HTTPS enabled
- [ ] Environment variables not in version control
- [ ] Firestore security rules deployed
- [ ] Rate limiting configured
- [ ] Error messages don't leak sensitive info
- [ ] Audit logging enabled
- [ ] Backup strategy in place
- [ ] Incident response plan documented

### Secrets Management

For production, use proper secrets management:

- **Vercel**: Use Environment Variables in project settings
- **AWS**: Use AWS Secrets Manager
- **Google Cloud**: Use Secret Manager
- **Azure**: Use Key Vault
- **Docker**: Use Docker secrets

Never store secrets in:
- Git repositories
- Public documentation
- Application code
- Unencrypted files

## Support & Questions

For security concerns or questions, contact:
- Email: mishaf1106@gmail.com
- Review: Firebase Console → Authentication → Users
- Logs: Check application logs and Firebase logs
