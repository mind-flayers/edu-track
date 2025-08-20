const { initializeApp } = require('firebase/app');
const { getFirestore, collection, doc, setDoc, addDoc } = require('firebase/firestore');

// Firebase configuration (ensure this matches your Flutter app's firebase_options.dart values)
const firebaseConfig = {
  apiKey: "AIzaSyBpIh67xOZXLj5Bw9jMEqnFIh85e42Il1E",
  authDomain: "edutrack-73a2e.firebaseapp.com",
  projectId: "edutrack-73a2e",
  storageBucket: "edutrack-73a2e.firebasestorage.app",
  messagingSenderId: "656920649358",
  appId: "1:656920649358:web:1bc12a4de738b0eeb1b3df",
  measurementId: "G-D1G98D7XC9"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

// --- CONFIGURABLE ADMIN (Provided) ---
const adminId = 'jGTyDPHBwRaVVAwN2YtHysDQJP23';

// Index Number Generator (mirrors Dart logic)
function generateIndexNumber(year, className, section, rowNumber) {
  const yearSuffix = (year % 100).toString().padStart(2, '0');
  const classCode = className.replace('Grade ', '') + section;
  const formattedRowNumber = rowNumber.toString().padStart(2, '0');
  return `MEC/${yearSuffix}/${classCode}/${formattedRowNumber}`;
}

async function populateDatabase() {
  console.log('Starting database population for admin:', adminId);
  const seedDate = new Date('2025-08-20'); // Reference date per requirement

  try {
    // 1. Admin Profile
    await setDoc(doc(db, 'admins', adminId, 'adminProfile', 'profile'), {
      name: 'N. M. Ihthisham',
      academyName: 'MEC Kanamoolai',
      email: 'mishaf1106@gmail.com',
      profilePhotoUrl: 'https://res.cloudinary.com/duckxlzaj/image/upload/v1745266374/profiles/admin/AzzSlxVmw8UkwfJUjemxqcqQaJX2/profiles/admin/AzzSlxVmw8UkwfJUjemxqcqQaJX2/profile_1745266371005.jpg',
      smsGatewayToken: '',
      whatsappGatewayToken: '',
      createdAt: seedDate,
      updatedAt: seedDate
    });
    console.log('✔ Admin profile created');

    // 2. Exam Terms (Subjects list as specified)
    const subjects = ['Maths', 'Science', 'English', 'History', 'ICT', 'Tamil', 'Sinhala', 'Commerce'];
    const examTermsData = [
      { name: 'First Term - 2025', start: '2025-02-01', end: '2025-04-30' },
      { name: 'Second Term - 2025', start: '2025-05-01', end: '2025-07-31' },
      { name: 'Third Term - 2025', start: '2025-08-01', end: '2025-11-30' }
    ];
    const termIdMap = {}; // Map human name -> doc ID
    for (const term of examTermsData) {
      const ref = await addDoc(collection(db, 'admins', adminId, 'examTerms'), {
        name: term.name,
        startDate: new Date(term.start),
        endDate: new Date(term.end),
        subjects
      });
      termIdMap[term.name] = ref.id;
    }
    console.log('✔ Exam terms created (3) with IDs:', termIdMap);

    // 3. Teachers (4 Muslim community based profiles)
    const teachers = [
      {
        name: 'Mr. Mohamed Fazil',
        email: 'm.fazil@meckanamoolai.lk',
        phoneNumber: '0775101101',
        whatsappNumber: '0775101101',
        subject: 'Maths',
        classAssigned: ['Grade 9', 'Grade 10', 'Grade 11']
      },
      {
        name: 'Mrs. Fathima Nazeera',
        email: 'f.nazeera@meckanamoolai.lk',
        phoneNumber: '0775201202',
        whatsappNumber: '0775201202',
        subject: 'Science',
        classAssigned: ['Grade 8', 'Grade 9', 'Grade 10']
      },
      {
        name: 'Mr. Ahamed Rilwan',
        email: 'a.rilwan@meckanamoolai.lk',
        phoneNumber: '0775301303',
        whatsappNumber: '0775301303',
        subject: 'English',
        classAssigned: ['Grade 9', 'Grade 10', 'Grade 11']
      },
      {
        name: 'Mrs. Shifna Mubarak',
        email: 's.mubarak@meckanamoolai.lk',
        phoneNumber: '0775401404',
        whatsappNumber: '0775401404',
        subject: 'Tamil',
        classAssigned: ['Grade 8', 'Grade 9', 'Grade 10']
      }
    ];
    for (const t of teachers) {
      await addDoc(collection(db, 'admins', adminId, 'teachers'), {
        ...t,
        joinedAt: seedDate,
        isActive: true
      });
    }
    console.log('✔ Teachers created (4)');

    // 4. Students (10) – Sri Lankan Muslim community focus
    const students = [
      { name: 'Mohamed Aadil Rahman', class: 'Grade 10', section: 'A', dob: '2010-03-15', sex: 'Male', parentName: 'Mr. & Mrs. M. Rahman', parentPhone: '0776010010', whatsappNumber: '0776010010', address: '12, Mosque Road, Kattankudy', subjects: ['Maths', 'Science', 'English', 'History', 'ICT'] },
      { name: 'Fathima Zainab Nazeera', class: 'Grade 11', section: 'A', dob: '2009-07-22', sex: 'Female', parentName: 'Mr. & Mrs. A. Nazeera', parentPhone: '0776020011', whatsappNumber: '0776020011', address: '34, Main Street, Mawanella', subjects: ['Maths', 'Science', 'English', 'Tamil', 'Commerce'] },
      { name: 'Mohamed Irfan Ameer', class: 'Grade 10', section: 'A', dob: '2010-01-08', sex: 'Male', parentName: 'Mr. & Mrs. I. Ameer', parentPhone: '0776030012', whatsappNumber: '0776030012', address: '23, Beach Road, Beruwala', subjects: ['Maths', 'Science', 'English', 'ICT', 'History'] },
      { name: 'Ayesha Safna Jameel', class: 'Grade 9', section: 'B', dob: '2011-11-30', sex: 'Female', parentName: 'Mr. & Mrs. S. Jameel', parentPhone: '0776040013', whatsappNumber: '0776040013', address: '2nd Cross St, Colombo 12', subjects: ['Maths', 'Science', 'English', 'Tamil', 'History'] },
      { name: 'Muhammed Thameem Razik', class: 'Grade 9', section: 'A', dob: '2011-05-17', sex: 'Male', parentName: 'Mr. & Mrs. T. Razik', parentPhone: '0776050014', whatsappNumber: '0776050014', address: '67, Hospital Road, Kalmunai', subjects: ['Maths', 'Science', 'English', 'ICT', 'Tamil'] },
      { name: 'Fathima Hajara Sameem', class: 'Grade 11', section: 'B', dob: '2009-09-04', sex: 'Female', parentName: 'Mr. & Mrs. H. Sameem', parentPhone: '0776060015', whatsappNumber: '0776060015', address: '89, Main Street, Akkaraipattu', subjects: ['Maths', 'English', 'Commerce', 'Tamil', 'History'] },
      { name: 'Ahamed Rilwan Mubarak', class: 'Grade 10', section: 'B', dob: '2010-12-25', sex: 'Male', parentName: 'Mr. & Mrs. R. Mubarak', parentPhone: '0776070016', whatsappNumber: '0776070016', address: '156, Unity Place, Colombo 06', subjects: ['Maths', 'Science', 'English', 'Commerce', 'ICT'] },
      { name: 'Nusrath Shifana Ismail', class: 'Grade 9', section: 'A', dob: '2011-08-13', sex: 'Female', parentName: 'Mr. & Mrs. I. Ismail', parentPhone: '0776080017', whatsappNumber: '0776080017', address: '23/A, Marine Drive, Wellawatte', subjects: ['Maths', 'Science', 'English', 'Tamil', 'History'] },
      { name: 'Mohamed Akeel Haniffa', class: 'Grade 8', section: 'A', dob: '2012-02-28', sex: 'Male', parentName: 'Mr. & Mrs. A. Haniffa', parentPhone: '0776090018', whatsappNumber: '0776090018', address: '45, Bazaar Street, Puttalam', subjects: ['Maths', 'Science', 'English', 'Tamil'] },
      { name: 'Fathima Rifqa Azeez', class: 'Grade 11', section: 'A', dob: '2009-06-19', sex: 'Female', parentName: 'Mr. & Mrs. R. Azeez', parentPhone: '0776100019', whatsappNumber: '0776100019', address: '14, Mosque Lane, Eravur', subjects: ['Maths', 'Science', 'English', 'Commerce', 'Tamil'] }
    ];

    const studentIds = [];
    const classCounters = {}; // per class-section for index numbers

    // Helpers
    const getSubjectForDate = (studentSubjects, date) => {
      const day = new Date(date).getDay();
      const schedule = {
        0: studentSubjects[0] || 'Maths',
        1: studentSubjects[1] || 'Science',
        2: studentSubjects[2] || 'English',
        3: studentSubjects[3] || 'History',
        4: studentSubjects[4] || 'ICT',
        5: studentSubjects[0] || 'Maths',
        6: studentSubjects[1] || 'Science'
      };
      return schedule[day];
    };
    const getTimeSlotForSubject = (subject) => ({
      'Maths': '08:00', 'Science': '09:30', 'English': '11:00', 'History': '13:00', 'ICT': '14:30', 'Tamil': '16:00', 'Sinhala': '16:00', 'Commerce': '14:30'
    })[subject] || '08:00';

  const attendanceDates = ['2025-08-14', '2025-08-15', '2025-08-16', '2025-08-19', '2025-08-20'];
    for (let i = 0; i < students.length; i++) {
      const s = students[i];
      const studentId = `student_${Date.now()}_${i}`;
      studentIds.push(studentId);
      const classSection = `${s.class}-${s.section}`;
      classCounters[classSection] = (classCounters[classSection] || 0) + 1;
      const indexNumber = generateIndexNumber(2025, s.class, s.section, classCounters[classSection]);

      await setDoc(doc(db, 'admins', adminId, 'students', studentId), {
        name: s.name,
        class: s.class,
        Subjects: s.subjects,
        section: s.section,
        dob: new Date(s.dob),
        sex: s.sex,
        indexNumber,
        parentName: s.parentName,
        parentPhone: s.parentPhone,
        whatsappNumber: s.whatsappNumber,
        address: s.address,
        photoUrl: 'https://res.cloudinary.com/duckxlzaj/image/upload/v1744864635/profiles/students/vm6bgpeg4ccvy58nig6r.jpg',
        qrCodeData: studentId,
        joinedAt: seedDate,
        isActive: true
      });

      // Attendance (ONLY present students get a document; absence is implied by lack of record)
      for (const date of attendanceDates) {
        const subject = getSubjectForDate(s.subjects, date);
        const timeSlot = getTimeSlotForSubject(subject);
        const isPresent = (i + new Date(date).getDate()) % 5 !== 0; // same pattern, but only create doc if present
        if (isPresent) {
          await addDoc(collection(db, 'admins', adminId, 'students', studentId, 'attendance'), {
            date,
            subject,
            status: 'present',
            markedBy: adminId,
            markedAt: new Date(`${date}T${timeSlot}:00`)
          });
        }
      }

      // Fees (June, July, August 2025)
      for (const month of [6, 7, 8]) {
        const paid = month < 8 || i % 4 !== 0; // some August pending
        await addDoc(collection(db, 'admins', adminId, 'students', studentId, 'fees'), {
          year: 2025,
          month,
          amount: 2500 + (i * 100),
          paid,
          paidAt: paid ? new Date(2025, month - 1, 5 + (i % 5)) : null,
          paymentMethod: paid ? (i % 2 === 0 ? 'cash' : 'bank_transfer') : null,
          markedBy: adminId
        });
      }

      // Exam Results (First & Second Term core subjects only)
      const examResults = [
        { termName: 'First Term - 2025', subject: 'Maths', base: 72 },
        { termName: 'First Term - 2025', subject: 'Science', base: 70 },
        { termName: 'First Term - 2025', subject: 'English', base: 68 },
        { termName: 'Second Term - 2025', subject: 'Maths', base: 74 },
        { termName: 'Second Term - 2025', subject: 'Science', base: 72 },
        { termName: 'Second Term - 2025', subject: 'English', base: 70 }
      ];
      for (const r of examResults) {
        await addDoc(collection(db, 'admins', adminId, 'students', studentId, 'examResults'), {
          term: termIdMap[r.termName] || null, // store the examTerm document ID only
          subject: r.subject,
          marks: r.base + (i % 6),
          maxMarks: 100,
          resultDate: new Date(r.termName.startsWith('First') ? '2025-04-15' : '2025-07-15'),
          updatedBy: adminId
        });
      }

      console.log(`✔ Student ${i + 1}/10 created: ${s.name}`);
    }

    // 5. Attendance Summary
    for (const date of attendanceDates) {
      const presentStudents = studentIds.filter((_, i) => (i + new Date(date).getDate()) % 5 !== 0);
      // Only create a summary if at least one student present (optional – keep anyway)
      await setDoc(doc(db, 'admins', adminId, 'attendanceSummary', date), {
        class: 'Overall',
        present: presentStudents.length,
        studentsPresent: presentStudents,
        markedBy: adminId,
        markedAt: new Date(`${date}T08:00:00`)
      });
    }
    console.log('✔ Attendance summaries created');

    console.log('=== SEED COMPLETE ===');
    console.log('Admin ID:', adminId);
    console.log('Students:', students.length);
    console.log('Teachers:', teachers.length);
    console.log('Exam Terms: 3');
  } catch (err) {
    console.error('❌ Error populating database:', err);
  }
}

populateDatabase().then(() => {
  console.log('Script completed successfully!');
  process.exit(0);
}).catch((error) => {
  console.error('Script failed:', error);
  process.exit(1);
});
