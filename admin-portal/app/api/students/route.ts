import { NextRequest, NextResponse } from 'next/server';
import { adminDb } from '@/lib/firebase-admin';
import { Student, ApiResponse } from '@/types';
import { generateIndexNumber, getNextRowNumber, validateStudentData } from '@/lib/student-utils';

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { adminUid, studentData } = body;
    
    if (!adminUid || !studentData) {
      const response: ApiResponse = {
        success: false,
        error: 'Admin UID and student data are required',
      };
      return NextResponse.json(response, { status: 400 });
    }
    
    // Validate student data
    const validation = validateStudentData(studentData);
    if (!validation.valid) {
      const response: ApiResponse = {
        success: false,
        error: validation.errors.join(', '),
      };
      return NextResponse.json(response, { status: 400 });
    }
    
    const studentsRef = adminDb
      .collection('admins')
      .doc(adminUid)
      .collection('students');
    
    // Get next row number for index generation
    const nextRow = await getNextRowNumber(
      adminUid,
      studentData.class,
      studentData.section
    );
    
    const indexNumber = generateIndexNumber(
      new Date().getFullYear(),
      studentData.class,
      studentData.section,
      nextRow
    );
    
    // Create student document
    const studentDocRef = studentsRef.doc();
    
    const finalStudentData = {
      ...studentData,
      indexNumber,
      qrCodeData: studentDocRef.id,
      joinedAt: new Date(),
      isActive: true,
      dob: new Date(studentData.dob),
    };
    
    await studentDocRef.set(finalStudentData);
    
    const student: Student = {
      id: studentDocRef.id,
      ...finalStudentData,
    };
    
    const response: ApiResponse<Student> = {
      success: true,
      data: student,
      message: 'Student created successfully',
    };
    
    return NextResponse.json(response);
  } catch (error: any) {
    console.error('Error creating student:', error);
    const response: ApiResponse = {
      success: false,
      error: error.message || 'Failed to create student',
    };
    return NextResponse.json(response, { status: 500 });
  }
}

// GET /api/students - Get all students for an admin
export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const adminUid = searchParams.get('adminUid');
    
    if (!adminUid) {
      const response: ApiResponse = {
        success: false,
        error: 'Admin UID is required',
      };
      return NextResponse.json(response, { status: 400 });
    }
    
    const studentsSnapshot = await adminDb
      .collection('admins')
      .doc(adminUid)
      .collection('students')
      .get();
    
    const students: Student[] = [];
    
    studentsSnapshot.forEach((doc) => {
      const data = doc.data();
      students.push({
        id: doc.id,
        name: data.name,
        class: data.class,
        Subjects: data.Subjects || [],
        section: data.section,
        dob: data.dob?.toDate() || new Date(),
        sex: data.sex,
        indexNumber: data.indexNumber,
        parentName: data.parentName,
        parentPhone: data.parentPhone,
        whatsappNumber: data.whatsappNumber,
        address: data.address || '',
        photoUrl: data.photoUrl || '',
        qrCodeData: data.qrCodeData || doc.id,
        joinedAt: data.joinedAt?.toDate() || new Date(),
        isActive: data.isActive ?? true,
        isNonePayee: data.isNonePayee ?? false,
      });
    });
    
    const response: ApiResponse<Student[]> = {
      success: true,
      data: students,
    };
    
    return NextResponse.json(response);
  } catch (error: any) {
    console.error('Error fetching students:', error);
    const response: ApiResponse = {
      success: false,
      error: error.message || 'Failed to fetch students',
    };
    return NextResponse.json(response, { status: 500 });
  }
}
