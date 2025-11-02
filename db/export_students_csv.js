const { initializeApp } = require('firebase/app');
const { getFirestore, collection, getDocs } = require('firebase/firestore');
const fs = require('fs');
const path = require('path');

// Firebase configuration (matches populate_database.js)
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

// Helper function to escape CSV fields
function escapeCsvField(field) {
  if (field === null || field === undefined) {
    return '';
  }
  const str = String(field);
  // If field contains comma, quote, or newline, wrap in quotes and escape quotes
  if (str.includes(',') || str.includes('"') || str.includes('\n')) {
    return `"${str.replace(/"/g, '""')}"`;
  }
  return str;
}

// Helper function to extract grade number for sorting
function getGradeNumber(className) {
  const match = className.match(/\d+/);
  return match ? parseInt(match[0]) : 0;
}

async function exportStudentsToCSV() {
  console.log('Starting student data export...');
  console.log('Admin ID:', adminId);

  try {
    // Fetch all students
    const studentsRef = collection(db, 'admins', adminId, 'students');
    const querySnapshot = await getDocs(studentsRef);

    if (querySnapshot.empty) {
      console.log('⚠ No students found in database');
      return;
    }

    console.log(`✔ Found ${querySnapshot.size} students`);

    // Extract student data
    const students = [];
    querySnapshot.forEach((doc) => {
      const data = doc.data();
      students.push({
        name: data.name || '',
        class: data.class || '',
        indexNumber: data.indexNumber || ''
      });
    });

    // Sort by class (grade number) and then by index number
    students.sort((a, b) => {
      const gradeA = getGradeNumber(a.class);
      const gradeB = getGradeNumber(b.class);
      if (gradeA !== gradeB) {
        return gradeA - gradeB;
      }
      return a.indexNumber.localeCompare(b.indexNumber);
    });

    // Create CSV content
    const headers = 'Name,Class,Index Number\n';
    const rows = students.map(student => 
      `${escapeCsvField(student.name)},${escapeCsvField(student.class)},${escapeCsvField(student.indexNumber)}`
    ).join('\n');
    const csvContent = headers + rows;

    // Generate filename with timestamp
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, -5);
    const filename = `students_export_${timestamp}.csv`;
    const filepath = path.join(__dirname, filename);

    // Write to file
    fs.writeFileSync(filepath, csvContent, 'utf8');

    console.log('✔ CSV file created successfully!');
    console.log('📄 File location:', filepath);
    console.log('📊 Total students exported:', students.length);
    console.log('\nPreview of first 3 students:');
    students.slice(0, 3).forEach((s, i) => {
      console.log(`  ${i + 1}. ${s.name} - ${s.class} - ${s.indexNumber}`);
    });

  } catch (error) {
    console.error('❌ Error exporting students:', error);
    throw error;
  }
}

// Execute the export
exportStudentsToCSV()
  .then(() => {
    console.log('\n=== Export completed successfully! ===');
    process.exit(0);
  })
  .catch((error) => {
    console.error('\n=== Export failed ===');
    console.error(error);
    process.exit(1);
  });
