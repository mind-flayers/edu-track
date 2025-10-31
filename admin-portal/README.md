# EduTrack Admin Portal

A Next.js-based web application for managing admin accounts and importing student data into the EduTrack Academy Management System.

## 🔒 Super Admin Only Access

**IMPORTANT**: This portal is restricted to a **single super admin account** only. The super admin email is configured in environment variables and only that account can:
- Access the admin portal
- Create and manage academy admin accounts
- Import student data for any academy
- Perform administrative operations

Regular academy admins use the main Flutter application and cannot access this portal.

## Features

- **Admin Management**: Create, view, and delete academy admin accounts
- **CSV Import**: Bulk import students from Google Forms CSV with automatic photo upload from Google Drive
- **Manual Entry**: Add individual students with full control over all fields
- **Firebase Integration**: Server-side operations with Firebase Admin SDK
- **Cloudinary Integration**: Automatic image upload and management
- **Super Admin Authentication**: Restricted access with email-based authorization

## Prerequisites

- Node.js 18+ installed
- Firebase project with Firestore enabled
- Firebase Admin SDK service account key
- Cloudinary account (free tier works)

## Setup Instructions

### 1. Install Dependencies

```bash
npm install
```

### 2. Configure Environment Variables

Copy `.env.local.example` to `.env.local` and fill in the values:

```bash
cp .env.local.example .env.local
```

**Important Configuration Steps**:

#### A. Set Super Admin Email

Edit `.env.local` and set the super admin email:
```
SUPER_ADMIN_EMAIL=your-email@example.com
```

Only this email will be able to access the admin portal. All other accounts will be denied access.

#### B. Obtain Firebase Admin SDK Private Key

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project (`edutrack-73a2e`)
3. Go to Project Settings → Service Accounts
4. Click "Generate New Private Key"
5. Open the downloaded JSON file
6. Copy the values to `.env.local`:
   - `project_id` → `FIREBASE_ADMIN_PROJECT_ID`
   - `client_email` → `FIREBASE_ADMIN_CLIENT_EMAIL`
   - `private_key` → `FIREBASE_ADMIN_PRIVATE_KEY` (keep the quotes and newlines)

### 3. Run Development Server

```bash
npm run dev
```

The application will be available at http://localhost:3000

## Usage Guide

### CSV Format Example

```csv
name,class,section,subjects,dob,sex,parentName,parentPhone,whatsappNumber,address,photoUrl,isNonePayee
John Doe,Grade 10,A,"Mathematics,Science,English",2008-05-15,Male,Mr. Doe,0771234567,0771234567,123 Main St,https://drive.google.com/file/d/ABC123/view,false
```

## Troubleshooting

### Firebase Admin SDK Errors
- Check `.env.local` has the correct private key with newlines preserved
- Ensure the private key includes BEGIN/END markers

### Cloudinary Upload Errors
- Verify cloud name and upload preset are correct
- Ensure upload preset is set to "Unsigned" mode

### Google Drive Download Errors
- Set sharing to "Anyone with the link can view"
- Use full URLs, not shortened links

## Security

- **Never commit `.env.local`** - Contains sensitive credentials
- Store service account key securely
