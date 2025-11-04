# Quick Setup Guide - EduTrack Admin Portal

## ⚡ Quick Start (5 minutes)

### Step 1: Get Firebase Service Account Key

1. Open [Firebase Console](https://console.firebase.google.com/)
2. Select project: **edutrack-73a2e**
3. Click ⚙️ (Settings) → **Project settings**
4. Go to **Service accounts** tab
5. Click **"Generate new private key"** button
6. Click **"Generate key"** to download JSON file
7. **Save the file** - you'll need it in the next step

### Step 2: Configure Environment Variables

1. Open the downloaded JSON file (e.g., `edutrack-73a2e-firebase-adminsdk-xxxxx.json`)
2. Open `admin-portal/.env.local` in a text editor
3. Replace these values:

```env
# Copy from JSON: "project_id"
FIREBASE_ADMIN_PROJECT_ID=edutrack-xxxxx

# Copy from JSON: "client_email"  
FIREBASE_ADMIN_CLIENT_EMAIL=firebase-adminsdk-xxxxx@edutrack-73a2e.iam.gserviceaccount.com

# Copy from JSON: "private_key" (keep all the \n characters)
FIREBASE_ADMIN_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBg...[FULL KEY HERE]...==\n-----END PRIVATE KEY-----\n"
```

**IMPORTANT**: 
- Keep the quotes around the private key
- Keep all the `\n` characters in the key
- Don't remove the `\n` at the start and end

4. Set your super admin email:

```env
SUPER_ADMIN_EMAIL=exampl@gmail.com
```

**Change this to YOUR email** - only this email can access the portal!

### Step 3: Create Super Admin Firebase Account

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select **edutrack-xxxxx** project
3. Go to **Authentication** → **Users**
4. Click **"Add user"**
5. Enter:
   - **Email**: `example@gmail.com` (or your chosen super admin email)
   - **Password**: Create a strong password (save it securely!)
6. Click **"Add user"**

### Step 4: Start the Application

```bash
cd admin-portal
npm run dev
```

Application will start at: **http://localhost:3000**

### Step 5: Login

1. Open http://localhost:3000
2. You'll be redirected to the login page
3. Enter:
   - **Email**: Your super admin email (e.g., `example@gmail.com`)
   - **Password**: The password you created in Firebase
4. Click **"Sign In"**

✅ **Success!** You should now see the dashboard.

---

## 🎯 What to Do After Login

### 1. Create Academy Admin Accounts

**Dashboard → Admin Management → Create New Admin**

Fill in the form:
- **Admin Name**: Full name (e.g., "N. M. Ihthisham")
- **Academy Name**: School/Academy name (e.g., "MEC Kanamoolai")
- **Email**: Admin's email (e.g., "admin@meckanamoolai.lk")
- **Password**: Secure password for the admin
- **Profile Photo**: Upload academy logo/admin photo

This creates:
- ✅ Firebase Authentication account
- ✅ Firestore admin profile document
- ✅ Photo uploaded to Cloudinary

### 2. Import Students via CSV

**Dashboard → Import Students (CSV)**

#### Prepare Your CSV File

Your CSV should have these columns (exact names):

```csv
name,class,subjects,section,dob,sex,parentName,parentPhone,whatsappNumber,address,photoUrl,isNonePayee
Mohamed Fazil,Grade 10,Mathematics|Science|English,A,2010-05-15,Male,Mr. Abdul,0771234567,0771234567,123 Main St,https://drive.google.com/file/d/xxxxx/view,false
Aisha Rahman,Grade 10,Mathematics|Science|English|Tamil,B,2010-08-20,Female,Mrs. Rahman,0772345678,0772345678,456 Park Ave,https://drive.google.com/file/d/yyyyy/view,false
```

**Column Details**:
- `name`: Student full name
- `class`: Grade/Class (e.g., "Grade 10", "Grade 11")
- `subjects`: Pipe-separated list (e.g., "Mathematics|Science|English")
- `section`: Class section (e.g., "A", "B", "C")
- `dob`: Date of birth in YYYY-MM-DD format
- `sex`: Either "Male" or "Female"
- `parentName`: Parent/guardian name
- `parentPhone`: Parent phone number
- `whatsappNumber`: WhatsApp number for notifications
- `address`: Full address
- `photoUrl`: Google Drive share link to photo
- `isNonePayee`: "true" for fee-exempt students, "false" or empty otherwise

#### Google Drive Photo Setup

1. Upload student photos to Google Drive
2. Right-click photo → **Get link**
3. Set to **"Anyone with the link can view"**
4. Copy the link (format: `https://drive.google.com/file/d/{fileId}/view`)
5. Paste in CSV `photoUrl` column

#### Import Process

1. Go to **Dashboard → Import Students (CSV)**
2. Select the admin account (academy) to import for
3. Click **"Choose File"** and select your CSV
4. Click **"Import Students"**

The system will:
- ✅ Parse CSV file
- ✅ Download photos from Google Drive
- ✅ Upload photos to Cloudinary
- ✅ Generate index numbers (e.g., MEC/25/10A/01)
- ✅ Generate QR codes for attendance
- ✅ Create Firestore documents

**Time**: ~5-10 seconds per student

### 3. Add Students Manually

**Dashboard → Add Student Manually**

Use this for individual student entries:

1. Select admin account (academy)
2. Fill in all student details
3. Upload photo directly (or leave empty)
4. Click **"Create Student"**

---

## 🔒 Security Important

### Super Admin Access

- **ONLY** the email in `SUPER_ADMIN_EMAIL` can access this portal
- Regular academy admins **cannot** access this portal
- They use the Flutter mobile/desktop app instead

### Testing Access Restriction

Try logging in with a different email:
1. Create another Firebase user with a different email
2. Try to login with that email
3. You should see: **"Access denied. This portal is restricted to super admin only."**

### Changing Super Admin

To change the super admin:
1. Edit `.env.local`
2. Update `SUPER_ADMIN_EMAIL=new-email@example.com`
3. Restart the dev server
4. Create Firebase account for new email if needed

---

## 🐛 Troubleshooting

### Error: "Failed to parse private key"

**Solution**: 
- Make sure you copied the ENTIRE private key from the JSON
- Keep all `\n` characters
- Keep quotes around the key
- Don't add extra line breaks

Example of correct format:
```env
FIREBASE_ADMIN_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nMIIEvQI...full key...==\n-----END PRIVATE KEY-----\n"
```

### Error: "Access denied. Super admin access required"

**Solution**:
- Check `SUPER_ADMIN_EMAIL` in `.env.local` matches your login email
- Email comparison is case-insensitive
- Restart dev server after changing `.env.local`

### Error: "User not found" during login

**Solution**:
- Create the user in Firebase Console → Authentication → Users
- Make sure email matches `SUPER_ADMIN_EMAIL`

### CSV Import: "Failed to download image from Google Drive"

**Solution**:
- Make sure Google Drive links are set to "Anyone with the link can view"
- Use the full share link format: `https://drive.google.com/file/d/{fileId}/view`
- Check your internet connection

### CSV Import: "Failed to upload image to Cloudinary"

**Solution**:
- Check Cloudinary environment variables in `.env.local`
- Verify upload preset exists in Cloudinary dashboard
- Free tier limit: Check if you've hit upload limits

---

## 📊 Database Structure

Students are stored at:
```
admins/{adminUid}/students/{studentId}
```

Each student document includes:
- Basic info (name, class, section, etc.)
- Subjects array
- Parent contact info
- Photo URL (Cloudinary)
- QR code data (for attendance)
- Index number (auto-generated)
- Active status
- Fee exemption flag

---

## 🚀 Production Deployment

### Environment Variables (Vercel/Netlify)

Add these to your deployment platform:

```
FIREBASE_ADMIN_PROJECT_ID=...
FIREBASE_ADMIN_CLIENT_EMAIL=...
FIREBASE_ADMIN_PRIVATE_KEY=...
SUPER_ADMIN_EMAIL=...
SESSION_SECRET=...
NEXT_PUBLIC_FIREBASE_API_KEY=...
NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=...
NEXT_PUBLIC_FIREBASE_PROJECT_ID=...
NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET=...
NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID=...
NEXT_PUBLIC_FIREBASE_APP_ID=...
NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME=...
NEXT_PUBLIC_CLOUDINARY_UPLOAD_PRESET=...
```

### Build Command

```bash
npm run build
```

### Start Command

```bash
npm start
```

---

## 📞 Support

For issues or questions:
- **Email**: example@gmail.com
- **Check**: Firebase Console for user/auth issues
- **Review**: `SECURITY.md` for security details
- **Logs**: Check browser console and server logs

---

## ✅ Checklist

Before going live:

- [ ] Firebase service account key configured
- [ ] Super admin email set correctly
- [ ] Super admin Firebase user created
- [ ] Login works successfully
- [ ] Can create admin accounts
- [ ] CSV import tested with sample data
- [ ] Manual student entry tested
- [ ] Photos upload correctly to Cloudinary
- [ ] Security: Verified non-super-admin cannot login
- [ ] Production environment variables configured
- [ ] HTTPS enabled in production
- [ ] Firebase security rules reviewed

---

**You're all set! 🎉**

Start by logging in and creating your first academy admin account.
