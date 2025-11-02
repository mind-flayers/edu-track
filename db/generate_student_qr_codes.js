const { initializeApp } = require('firebase/app');
const { getFirestore, collection, getDocs } = require('firebase/firestore');
const QRCode = require('qrcode');
const fs = require('fs');
const path = require('path');

// Firebase configuration (matches your other scripts)
const firebaseConfig = {
  apiKey: "AIzaSyBpIh67xOZXLj5Bw9jMEqnFIh85e42Il1E",
  authDomain: "edutrack-73a2e.firebaseapp.com",
  projectId: "edutrack-73a2e",
  storageBucket: "edutrack-73a2e.firebasestorage.app",
  messagingSenderId: "656920649358",
  appId: "1:656920649358:web:1bc12a4de738b0eeb1b3df",
  measurementId: "G-D1G98D7XC9"
};

// Admin ID
const adminId = 'ZY8LibmAdSVzaZaaqqwIwc0Lma03';

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

// Output directory for QR codes
const QR_OUTPUT_DIR = path.join(__dirname, 'student_qr');

/**
 * Format student name to "Initials.LastName" format
 * Example: "Mohamed Aadil Rahman" -> "M.A.Rahman"
 */
function formatNameWithInitials(fullName) {
  if (!fullName) return 'Unknown';
  
  const nameParts = fullName.trim().split(/\s+/);
  
  if (nameParts.length === 1) {
    // Only one name part, return as is
    return nameParts[0];
  }
  
  // Get initials for all parts except the last
  const initials = nameParts
    .slice(0, -1)
    .map(part => part.charAt(0).toUpperCase())
    .join('.');
  
  // Get the last name (full)
  const lastName = nameParts[nameParts.length - 1];
  
  return `${initials}.${lastName}`;
}

/**
 * Sanitize filename to remove invalid characters
 */
function sanitizeFilename(filename) {
  return filename.replace(/[\\/*?:"<>|]/g, '_');
}

/**
 * Generate filename for student QR code
 * Format: "M.A.Rahman - Grade 10.png"
 */
function generateQRFilename(studentName, className) {
  const formattedName = formatNameWithInitials(studentName);
  const filename = `${formattedName} - ${className}.png`;
  return sanitizeFilename(filename);
}

/**
 * Generate QR code and save to file
 */
async function generateAndSaveQR(qrData, filepath) {
  try {
    await QRCode.toFile(filepath, qrData, {
      width: 500,
      margin: 2,
      color: {
        dark: '#000000',
        light: '#FFFFFF'
      },
      errorCorrectionLevel: 'M'
    });
    return true;
  } catch (error) {
    console.error(`Error generating QR for ${filepath}:`, error.message);
    return false;
  }
}

async function generateAllStudentQRCodes() {
  console.log('Starting QR code generation for all students...');
  console.log('Admin ID:', adminId);
  console.log('Output directory:', QR_OUTPUT_DIR);
  console.log('');

  try {
    // Create output directory if it doesn't exist
    if (!fs.existsSync(QR_OUTPUT_DIR)) {
      fs.mkdirSync(QR_OUTPUT_DIR, { recursive: true });
      console.log('✔ Created output directory:', QR_OUTPUT_DIR);
    }

    // Fetch all students
    const studentsRef = collection(db, 'admins', adminId, 'students');
    const querySnapshot = await getDocs(studentsRef);

    if (querySnapshot.empty) {
      console.log('⚠ No students found in database');
      return;
    }

    console.log(`✔ Found ${querySnapshot.size} students\n`);

    let successCount = 0;
    let errorCount = 0;

    // Process each student
    for (const doc of querySnapshot.docs) {
      const data = doc.data();
      const studentName = data.name || 'Unknown';
      const className = data.class || 'Unknown';
      const qrCodeData = data.qrCodeData || doc.id;

      // Generate filename
      const filename = generateQRFilename(studentName, className);
      const filepath = path.join(QR_OUTPUT_DIR, filename);

      // Generate and save QR code
      console.log(`Processing: ${studentName} (${className})`);
      console.log(`  QR Data: ${qrCodeData}`);
      console.log(`  Filename: ${filename}`);

      const success = await generateAndSaveQR(qrCodeData, filepath);
      
      if (success) {
        successCount++;
        console.log(`  ✔ Saved successfully\n`);
      } else {
        errorCount++;
        console.log(`  ✗ Failed to generate\n`);
      }
    }

    console.log('=== QR Code Generation Complete ===');
    console.log(`✔ Successfully generated: ${successCount}`);
    if (errorCount > 0) {
      console.log(`✗ Failed: ${errorCount}`);
    }
    console.log(`📁 QR codes saved to: ${QR_OUTPUT_DIR}`);

  } catch (error) {
    console.error('❌ Error generating QR codes:', error);
    throw error;
  }
}

// Execute the script
generateAllStudentQRCodes()
  .then(() => {
    console.log('\n✅ Script completed successfully!');
    process.exit(0);
  })
  .catch((error) => {
    console.error('\n❌ Script failed:', error);
    process.exit(1);
  });
