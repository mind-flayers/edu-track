# Instructions for Setting Up Your New Firebase Database

## Step 1: Configure Firestore Security Rules (Temporarily)

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **edutrack-73a2e**
3. Go to **Firestore Database** in the left sidebar
4. Click on the **Rules** tab
5. Replace the existing rules with the temporary rules from `firestore_rules_temp.rules`:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

6. Click **Publish** to apply the rules

## Step 2: Run the Database Population Script

Now that the rules allow writes, run the population script:

```bash
node populate_database.js
```

This will create:
- **Admin Profile**: N. M. Ihthisham (MEC Kanamoolai)
- **6 Teachers**: Mix of Sinhala and Muslim teachers
- **10 Students**: Diverse Sri Lankan students including Muslim names
- **3 Exam Terms**: First, Second, and Third terms of 2025
- **Attendance Records**: Past week attendance for all students  
- **Fee Records**: 3 months of fee records
- **Exam Results**: Multiple subjects across different terms
- **Attendance Summaries**: Daily summaries

## Step 3: Secure Your Database (IMPORTANT!)

After successful population, **immediately** replace the temporary rules with secure rules:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Only authenticated users can access their own admin data
    match /admins/{adminId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == adminId;
    }
    
    // Prevent access to other admin data
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

## Step 4: Test Your Flutter App

1. Clean and rebuild your Flutter project:
```bash
flutter clean
flutter pub get
flutter run
```

2. Sign in with the admin account you created: **jGTyDPHBwRaVVAwN2YtHysDQJP23**

## Data Created

### Students Include:
- **Mohamed Ameen Rasheed** (Grade 10A) - Colombo 12
- **Fathima Zahara Nazeer** (Grade 11A) - Colombo 14  
- **Aisha Rifka Ismail** (Grade 9B) - Slave Island
- **Abdul Rahman Faizal** (Grade 9A) - Dehiwala
- **Hussain Shaheed Hanifa** (Grade 10B) - Colombo 04
- **Mariam Safiya Cader** (Grade 9A) - Bambalapitiya
- **Zainab Nusrath Marikar** (Grade 11A) - Wellawatte
- Plus 3 Sinhala students for diversity

### Teachers Include:
- **Mr. Mohamed Farook Alim** - English Teacher
- **Mrs. Fathima Rifka Hassan** - Tamil Teacher  
- **Mr. Abdul Majeed Cassim** - Commerce Teacher
- Plus 3 other teachers

All data is realistic and follows Sri Lankan naming conventions and addresses.

## Security Note
The temporary rules (`allow read, write: if true`) are **ONLY** for initial database setup. Make sure to replace them with secure rules that require authentication before using the app in any real environment.