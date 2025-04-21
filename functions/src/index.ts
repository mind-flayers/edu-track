// functions/src/index.ts

import * as functions from "firebase-functions/v1"; // Using v1 for onCreate trigger
import * as admin from "firebase-admin";

// Initialize Firebase Admin SDK implicitly (Firebase handles this on deployment)
admin.initializeApp(); // Keep this simple call - Firebase provides credentials automatically

const db = admin.firestore();

/**
 * Triggered when a new Firebase Authentication user is created.
 * Creates the corresponding initial admin data structure in Firestore.
 */
export const setupNewAdminStructure = functions.auth.user().onCreate(async (user) => {
  const userId = user.uid;
  const email = user.email; // Can be null

  // --- Optional: Admin Role Check ---
  // Implement logic here if you need to verify the user *should* be an admin.
  // Example: Check email domain or a custom claim set during creation.
  // const isAdmin = email?.endsWith("@youradmin-domain.com");
  // if (!isAdmin) {
  //   console.log(`User ${userId} (${email}) is not designated as admin. Skipping Firestore setup.`);
  //   return null; // Exit if not an admin
  // }
  // --- End Optional Check ---

  console.log(`New user created: ${userId} (${email}). Setting up initial Firestore admin structure...`);

  // Reference to the new admin document
  const adminDocRef = db.collection("admins").doc(userId);

  // Use a batch write for atomicity
  const batch = db.batch();

  // 1. Create the main admin document (can be minimal initially)
  //    We'll create the 'adminProfile' subcollection separately.
  batch.set(adminDocRef, {
    email: email ?? "N/A", // Handle cases where email might be null
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    // Add any other essential top-level fields if needed (e.g., role: 'admin')
  });
  console.log(`Prepared main admin document for ${userId}.`);

  // 2. Create the 'adminProfile' subcollection with a placeholder/initial document
  //    Based on firestore_setup.js, it seems 'profile' is the intended doc ID.
  const adminProfileRef = adminDocRef.collection("adminProfile").doc("profile");
  batch.set(adminProfileRef, {
    // Add minimal default profile fields here if desired, otherwise leave empty {}
    name: "New Admin", // Default name
    academyName: "Default Academy Name", // Default
    email: email ?? "N/A",
    profilePhotoUrl: null, // Default empty photo
    smsGatewayToken: null, // Default empty token
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  console.log(`Prepared adminProfile subcollection for ${userId}.`);

  // 3. Create other required subcollections (initially empty or with a placeholder)
  //    These collections will be populated via the app later.
  //    Using a '.init' document is a common pattern to ensure the collection exists.
  batch.set(adminDocRef.collection("examTerms").doc(".init"), { initializedAt: admin.firestore.FieldValue.serverTimestamp() });
  batch.set(adminDocRef.collection("teachers").doc(".init"), { initializedAt: admin.firestore.FieldValue.serverTimestamp() });
  batch.set(adminDocRef.collection("students").doc(".init"), { initializedAt: admin.firestore.FieldValue.serverTimestamp() });
  batch.set(adminDocRef.collection("attendanceSummary").doc(".init"), { initializedAt: admin.firestore.FieldValue.serverTimestamp() });
  console.log(`Prepared empty subcollections (examTerms, teachers, students, attendanceSummary) for ${userId}.`);


  try {
    // Commit the batch
    await batch.commit();
    console.log(`Successfully created initial Firestore structure for admin: ${userId}`);
    return null;
  } catch (error) {
    console.error(`Error creating Firestore structure for admin ${userId}:`, error);
    // Optional: Consider adding more robust error handling/reporting
    return null;
  }
});