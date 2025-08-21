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

    // 2. Fee Structure Configuration (NEW)
    const feeStructures = [
      { subject: 'Maths', dailyFee: 120, monthlyFee: 2500 },
      { subject: 'Science', dailyFee: 150, monthlyFee: 3000 },
      { subject: 'English', dailyFee: 100, monthlyFee: 2000 },
      { subject: 'History', dailyFee: 80, monthlyFee: 1800 },
      { subject: 'ICT', dailyFee: 200, monthlyFee: 4000 },
      { subject: 'Tamil', dailyFee: 90, monthlyFee: 1900 },
      { subject: 'Sinhala', dailyFee: 90, monthlyFee: 1900 },
      { subject: 'Commerce', dailyFee: 110, monthlyFee: 2200 }
    ];
    
    for (const feeStructure of feeStructures) {
      await setDoc(doc(db, 'admins', adminId, 'feeStructure', feeStructure.subject), {
        subject: feeStructure.subject,
        dailyFee: feeStructure.dailyFee,
        monthlyFee: feeStructure.monthlyFee,
        currency: 'LKR',
        effectiveFrom: new Date('2025-01-01'),
        createdAt: seedDate,
        updatedAt: seedDate,
        createdBy: adminId,
        isActive: true
      });
    }
    console.log('✔ Fee structures created (8 subjects)');

    // 3. Exam Terms (Subjects list as specified)
    const examSubjects = ['Maths', 'Science', 'English', 'History', 'ICT', 'Tamil', 'Sinhala', 'Commerce'];
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
        subjects: examSubjects
      });
      termIdMap[term.name] = ref.id;
    }
    console.log('✔ Exam terms created (3) with IDs:', termIdMap);

    // 4. Teachers (4 Muslim community based profiles)
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

    // 5. Students (10) – Sri Lankan Muslim community focus with enhanced payment configurations
    const students = [
      { name: 'Mohamed Aadil Rahman', class: 'Grade 10', section: 'A', dob: '2010-03-15', sex: 'Male', parentName: 'Mr. & Mrs. M. Rahman', parentPhone: '0776010010', whatsappNumber: '0776010010', address: '12, Mosque Road, Kattankudy', subjects: ['Maths', 'Science', 'English', 'History', 'ICT'], paymentConfig: { 'Maths': 'monthly', 'Science': 'monthly', 'English': 'daily', 'History': 'daily', 'ICT': 'monthly' } },
      { name: 'Fathima Zainab Nazeera', class: 'Grade 11', section: 'A', dob: '2009-07-22', sex: 'Female', parentName: 'Mr. & Mrs. A. Nazeera', parentPhone: '0776020011', whatsappNumber: '0776020011', address: '34, Main Street, Mawanella', subjects: ['Maths', 'Science', 'English', 'Tamil', 'Commerce'], paymentConfig: { 'Maths': 'monthly', 'Science': 'daily', 'English': 'monthly', 'Tamil': 'none', 'Commerce': 'monthly' } },
      { name: 'Mohamed Irfan Ameer', class: 'Grade 10', section: 'A', dob: '2010-01-08', sex: 'Male', parentName: 'Mr. & Mrs. I. Ameer', parentPhone: '0776030012', whatsappNumber: '0776030012', address: '23, Beach Road, Beruwala', subjects: ['Maths', 'Science', 'English', 'ICT', 'History'], paymentConfig: { 'Maths': 'daily', 'Science': 'monthly', 'English': 'daily', 'ICT': 'monthly', 'History': 'none' } },
      { name: 'Ayesha Safna Jameel', class: 'Grade 9', section: 'B', dob: '2011-11-30', sex: 'Female', parentName: 'Mr. & Mrs. S. Jameel', parentPhone: '0776040013', whatsappNumber: '0776040013', address: '2nd Cross St, Colombo 12', subjects: ['Maths', 'Science', 'English', 'Tamil', 'History'], paymentConfig: { 'Maths': 'monthly', 'Science': 'monthly', 'English': 'monthly', 'Tamil': 'daily', 'History': 'daily' } },
      { name: 'Muhammed Thameem Razik', class: 'Grade 9', section: 'A', dob: '2011-05-17', sex: 'Male', parentName: 'Mr. & Mrs. T. Razik', parentPhone: '0776050014', whatsappNumber: '0776050014', address: '67, Hospital Road, Kalmunai', subjects: ['Maths', 'Science', 'English', 'ICT', 'Tamil'], paymentConfig: { 'Maths': 'none', 'Science': 'none', 'English': 'monthly', 'ICT': 'daily', 'Tamil': 'daily' } },
      { name: 'Fathima Hajara Sameem', class: 'Grade 11', section: 'B', dob: '2009-09-04', sex: 'Female', parentName: 'Mr. & Mrs. H. Sameem', parentPhone: '0776060015', whatsappNumber: '0776060015', address: '89, Main Street, Akkaraipattu', subjects: ['Maths', 'English', 'Commerce', 'Tamil', 'History'], paymentConfig: { 'Maths': 'daily', 'English': 'monthly', 'Commerce': 'monthly', 'Tamil': 'none', 'History': 'daily' } },
      { name: 'Ahamed Rilwan Mubarak', class: 'Grade 10', section: 'B', dob: '2010-12-25', sex: 'Male', parentName: 'Mr. & Mrs. R. Mubarak', parentPhone: '0776070016', whatsappNumber: '0776070016', address: '156, Unity Place, Colombo 06', subjects: ['Maths', 'Science', 'English', 'Commerce', 'ICT'], paymentConfig: { 'Maths': 'monthly', 'Science': 'daily', 'English': 'monthly', 'Commerce': 'daily', 'ICT': 'monthly' } },
      { name: 'Nusrath Shifana Ismail', class: 'Grade 9', section: 'A', dob: '2011-08-13', sex: 'Female', parentName: 'Mr. & Mrs. I. Ismail', parentPhone: '0776080017', whatsappNumber: '0776080017', address: '23/A, Marine Drive, Wellawatte', subjects: ['Maths', 'Science', 'English', 'Tamil', 'History'], paymentConfig: { 'Maths': 'daily', 'Science': 'monthly', 'English': 'daily', 'Tamil': 'daily', 'History': 'monthly' } },
      { name: 'Mohamed Akeel Haniffa', class: 'Grade 8', section: 'A', dob: '2012-02-28', sex: 'Male', parentName: 'Mr. & Mrs. A. Haniffa', parentPhone: '0776090018', whatsappNumber: '0776090018', address: '45, Bazaar Street, Puttalam', subjects: ['Maths', 'Science', 'English', 'Tamil'], paymentConfig: { 'Maths': 'monthly', 'Science': 'monthly', 'English': 'daily', 'Tamil': 'none' } },
      { name: 'Fathima Rifqa Azeez', class: 'Grade 11', section: 'A', dob: '2009-06-19', sex: 'Female', parentName: 'Mr. & Mrs. R. Azeez', parentPhone: '0776100019', whatsappNumber: '0776100019', address: '14, Mosque Lane, Eravur', subjects: ['Maths', 'Science', 'English', 'Commerce', 'Tamil'], paymentConfig: { 'Maths': 'monthly', 'Science': 'monthly', 'English': 'monthly', 'Commerce': 'daily', 'Tamil': 'daily' } }
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

      // Create payment configuration map
      const paymentConfig = {};
      for (const subject of s.subjects) {
        paymentConfig[subject] = {
          paymentType: s.paymentConfig[subject] || 'monthly'
        };
      }

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
        isActive: true,
        paymentConfig: paymentConfig // NEW: Payment configuration per subject
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

      // Enhanced Fees with partial payment support (June, July, August 2025)
      for (const month of [6, 7, 8]) {
        for (const subject of s.subjects) {
          const paymentType = s.paymentConfig[subject];
          const feeStructure = feeStructures.find(fs => fs.subject === subject);
          
          if (!feeStructure) continue; // Skip if no fee structure found
          
          let expectedAmount = 0;
          if (paymentType === 'monthly') {
            expectedAmount = feeStructure.monthlyFee;
          } else if (paymentType === 'daily') {
            // For demonstration, assume 20 days per month for daily payees
            expectedAmount = feeStructure.dailyFee * 20;
          } else if (paymentType === 'none') {
            expectedAmount = 0; // None payees have 0 expected amount
          }
          
          // Simulate payment scenarios
          const isFullyPaid = month < 8 || i % 4 !== 0; // Some August pending
          let paidAmount = 0;
          let transactions = [];
          
          if (paymentType === 'none') {
            // None payees can still have transactions for tracking, but usually 0
            paidAmount = 0;
            transactions = [];
          } else if (isFullyPaid) {
            // Full payment
            paidAmount = expectedAmount;
            transactions = [{
              id: `txn_${Date.now()}_${i}_${month}_${subject}`,
              amount: expectedAmount,
              paidAt: new Date(2025, month - 1, 5 + (i % 5)),
              paymentMethod: i % 2 === 0 ? 'cash' : 'bank_transfer',
              markedBy: adminId,
              description: `Full ${paymentType} payment for ${subject}`
            }];
          } else {
            // Partial payment (60% paid)
            paidAmount = Math.round(expectedAmount * 0.6);
            transactions = [{
              id: `txn_${Date.now()}_${i}_${month}_${subject}`,
              amount: paidAmount,
              paidAt: new Date(2025, month - 1, 8 + (i % 5)),
              paymentMethod: i % 2 === 0 ? 'cash' : 'bank_transfer',
              markedBy: adminId,
              description: `Partial ${paymentType} payment for ${subject}`
            }];
          }
          
          const remainingAmount = expectedAmount - paidAmount;
          
          await addDoc(collection(db, 'admins', adminId, 'students', studentId, 'fees'), {
            // New enhanced fields
            paymentType: paymentType,
            year: 2025,
            month: month,
            date: paymentType === 'daily' ? `2025-${month.toString().padStart(2, '0')}-15` : null,
            subject: subject,
            expectedAmount: expectedAmount,
            paidAmount: paidAmount,
            remainingAmount: remainingAmount,
            transactions: transactions,
            isFullyPaid: remainingAmount <= 0,
            studentPaymentMode: paymentType,
            createdAt: seedDate,
            updatedAt: seedDate,
            description: paymentType === 'monthly' 
              ? `Monthly fee for ${subject} - ${new Date(2025, month - 1).toLocaleString('default', { month: 'long', year: 'numeric' })}`
              : paymentType === 'daily'
              ? `Daily fees for ${subject} - ${new Date(2025, month - 1).toLocaleString('default', { month: 'long', year: 'numeric' })}`
              : `None payee record for ${subject} - ${new Date(2025, month - 1).toLocaleString('default', { month: 'long', year: 'numeric' })}`,
            
            // Legacy fields for backward compatibility
            subjects: [subject],
            amount: expectedAmount,
            paid: isFullyPaid,
            paidAt: isFullyPaid && transactions.length > 0 ? transactions[0].paidAt : null,
            paymentMethod: isFullyPaid && transactions.length > 0 ? transactions[0].paymentMethod : null,
            markedBy: adminId
          });
        }
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

    // 6. Class Conduction Tracking (NEW)
    const allSubjects = [...new Set(students.flatMap(s => s.subjects))]; // Get unique subjects
    for (const date of attendanceDates) {
      for (const subject of allSubjects) {
        // Find students present for this date/subject
        const studentsPresent = [];
        let totalStudentsForSubject = 0;
        
        for (let i = 0; i < students.length; i++) {
          const student = students[i];
          const studentId = studentIds[i]; // Use the actual studentId from the array
          
          // Check if student takes this subject
          if (student.subjects.includes(subject)) {
            totalStudentsForSubject++;
            
            // Check if student was present (same logic as attendance creation)
            const isPresent = (i + new Date(date).getDate()) % 5 !== 0;
            if (isPresent) {
              studentsPresent.push(studentId);
            }
          }
        }
        
        // Only create conduction record if there are students for this subject
        if (totalStudentsForSubject > 0) {
          const conducted = studentsPresent.length > 0;
          
          await setDoc(doc(db, 'admins', adminId, 'classConduction', `${date}_${subject}`), {
            date: date,
            subject: subject,
            conducted: conducted,
            studentsPresent: studentsPresent,
            totalStudents: totalStudentsForSubject,
            presentCount: studentsPresent.length,
            createdAt: new Date(`${date}T08:00:00`),
            updatedAt: new Date(`${date}T08:00:00`)
          });
        }
      }
    }
    console.log('✔ Class conduction records created');

    // 7. Attendance Summary
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
    console.log('✔ Class conduction records created');

    // 7. Attendance Summary
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

    console.log('=== ENHANCED SEED COMPLETE ===');
    console.log('Admin ID:', adminId);
    console.log('Students:', students.length);
    console.log('Teachers:', teachers.length);
    console.log('Exam Terms: 3');
    console.log('Fee Structures: 8 subjects');
    console.log('Class Conduction Records:', attendanceDates.length * allSubjects.length);
    console.log('Enhanced Features:');
    console.log('  ✔ Admin-configurable fee structures');
    console.log('  ✔ Student payment configurations (monthly/daily/none per subject)');
    console.log('  ✔ Partial payment support with transactions');
    console.log('  ✔ Class conduction tracking');
    console.log('  ✔ Backward compatibility with legacy fee fields');
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
