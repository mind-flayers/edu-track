import { NextRequest, NextResponse } from 'next/server';
import { adminDb } from '@/lib/firebase-admin';
import { Student, StudentCSVRow, ApiResponse, ImportResult } from '@/types';
import { generateIndexNumber, getNextIndexNumber, parseDateString, validateStudentData } from '@/lib/student-utils';
import { transferGoogleDriveToCloudinary } from '@/lib/image-utils';
import Papa from 'papaparse';

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { adminUid, csvData } = body;
    
    if (!adminUid || !csvData) {
      const response: ApiResponse = {
        success: false,
        error: 'Admin UID and CSV data are required',
      };
      return NextResponse.json(response, { status: 400 });
    }
    
    // Parse CSV
    const parseResult = Papa.parse<any>(csvData, {
      header: true,
      skipEmptyLines: true,
      transformHeader: (header) => header.trim(),
    });
    
    if (parseResult.errors.length > 0) {
      const response: ApiResponse = {
        success: false,
        error: 'CSV parsing error',
        data: parseResult.errors,
      };
      return NextResponse.json(response, { status: 400 });
    }
    
    const result: ImportResult = {
      success: 0,
      failed: 0,
      skipped: 0, // Reserved for future use (validation skips, etc.)
      errors: [],
      successfulStudents: [],
      skippedDuplicates: [], // Tracks duplicates that were assigned new index numbers
    };
    
    const studentsRef = adminDb
      .collection('admins')
      .doc(adminUid)
      .collection('students');
    
    // Process each row
    for (let i = 0; i < parseResult.data.length; i++) {
      const row = parseResult.data[i];
      const rowNumber = i + 2; // +2 because row 1 is header, array is 0-indexed
      
      try {
        // Map Google Forms column names to our field names
        const fullName = row['Full Name'] || row['name'] || '';
        const studentClass = row['Class'] || row['class'] || '';
        const section = row['Section'] || row['section'] || '';
        const dateOfBirth = row['Date of Birth'] || row['dob'] || '';
        const sex = row['Sex'] || row['sex'] || '';
        const parentGuardianName = row['Parent/Guardian Name'] || row['parentName'] || '';
        const parentPhoneNumber = row['Parent Phone Number'] || row['parentPhone'] || '';
        const whatsappNumber = row['Whatsapp Number'] || row['whatsappNumber'] || parentPhoneNumber;
        const address = row['Address'] || row['address'] || '';
        const subjectsStr = row['Subjects'] || row['subjects'] || '';
        const studentPhoto = row['Student Photo'] || row['photoUrl'] || '';
        const paymentType = row['Payment type'] || row['paymentType'] || 'monthly';
        
        // Parse subjects from comma-separated string
        const subjects = subjectsStr
          ? subjectsStr.split(',').map((s: string) => s.trim()).filter((s: string) => s)
          : [];
        
        // Parse date and ensure it's valid
        let dob: Date;
        try {
          dob = dateOfBirth ? parseDateString(dateOfBirth) : new Date();
          // Validate the date is actually valid
          if (isNaN(dob.getTime())) {
            console.warn(`Invalid date for row ${rowNumber}, using current date`);
            dob = new Date();
          }
        } catch (dateError) {
          console.warn(`Error parsing date for row ${rowNumber}:`, dateError);
          dob = new Date();
        }
        
        // Check for duplicate student before creating
        // Query by name, class, section, and date of birth
        const duplicateQuery = await studentsRef
          .where('name', '==', fullName)
          .where('class', '==', studentClass)
          .where('section', '==', section)
          .where('dob', '==', dob)
          .limit(1)
          .get();
        
        let indexNumber: string;
        let isDuplicate = false;
        
        if (!duplicateQuery.empty) {
          // Student already exists - generate a unique index number
          isDuplicate = true;
          const existingStudent = duplicateQuery.docs[0].data();
          
          // Get next available sequential index number to ensure uniqueness
          const nextIndexNumber = await getNextIndexNumber(adminUid);
          indexNumber = generateIndexNumber(nextIndexNumber);
          
          result.skippedDuplicates.push({
            row: rowNumber,
            name: fullName,
            reason: `Duplicate detected (original: ${existingStudent.indexNumber}), assigned new index: ${indexNumber}`,
          });
          console.log(`Duplicate student at row ${rowNumber}: ${fullName} - Assigning new index: ${indexNumber}`);
        } else {
          // New student - generate index number normally
          const nextIndexNumber = await getNextIndexNumber(adminUid);
          indexNumber = generateIndexNumber(nextIndexNumber);
        }
        
        // Handle photo upload
        let photoUrl = '';
        if (studentPhoto && studentPhoto.trim()) {
          try {
            // Check if it's a Google Drive link
            if (studentPhoto.includes('drive.google.com')) {
              photoUrl = await transferGoogleDriveToCloudinary(
                studentPhoto,
                `student_${Date.now()}_${i}.jpg`
              );
            } else {
              // Direct URL, use as is
              photoUrl = studentPhoto;
            }
          } catch (photoError) {
            console.error(`Error processing photo for row ${rowNumber}:`, photoError);
            // Continue without photo
            photoUrl = '';
          }
        }
        
        // Create student document
        const studentDocRef = studentsRef.doc();
        const now = new Date();
        
        const studentData = {
          name: fullName,
          class: studentClass,
          Subjects: subjects, // Capital S to match Firestore structure
          section: section,
          dob: dob,
          sex: sex,
          indexNumber,
          parentName: parentGuardianName,
          parentPhone: parentPhoneNumber,
          whatsappNumber: whatsappNumber || parentPhoneNumber,
          address: address || '',
          photoUrl,
          qrCodeData: studentDocRef.id,
          joinedAt: now,
          isActive: true,
          isNonePayee: false, // Default to false
        };
        
        // Validate
        const validation = validateStudentData(studentData);
        if (!validation.valid) {
          result.errors.push({
            row: rowNumber,
            error: validation.errors.join(', '),
            data: row,
          });
          result.failed++;
          continue;
        }
        
        // Validate dates before saving to Firestore
        if (isNaN(studentData.dob.getTime())) {
          result.errors.push({
            row: rowNumber,
            error: 'Invalid date of birth',
            data: row,
          });
          result.failed++;
          continue;
        }
        
        // Save to Firestore
        try {
          await studentDocRef.set(studentData);
        } catch (firestoreError: any) {
          console.error(`Firestore error for row ${rowNumber}:`, firestoreError);
          throw new Error(`Failed to save to Firestore: ${firestoreError.message}`);
        }
        
        result.success++;
        result.successfulStudents.push({
          id: studentDocRef.id,
          ...studentData,
        } as Student);
        
      } catch (error: any) {
        console.error(`Error processing row ${rowNumber}:`, error);
        result.errors.push({
          row: rowNumber,
          error: error.message || 'Unknown error',
          data: row,
        });
        result.failed++;
      }
    }
    
    const response: ApiResponse<ImportResult> = {
      success: true,
      data: result,
      message: `Import completed: ${result.success} succeeded, ${result.failed} failed${result.skippedDuplicates.length > 0 ? `, ${result.skippedDuplicates.length} duplicates assigned new index numbers` : ''}`,
    };
    
    return NextResponse.json(response);
  } catch (error: any) {
    console.error('Error importing students:', error);
    const response: ApiResponse = {
      success: false,
      error: error.message || 'Failed to import students',
    };
    return NextResponse.json(response, { status: 500 });
  }
}
