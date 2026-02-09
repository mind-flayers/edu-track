import { NextResponse } from 'next/server';
import { adminDb } from '@/lib/firebase-admin';
import { ApiResponse } from '@/types';

interface DashboardStats {
    totalAcademies: number;
    totalStudents: number;
    totalAdmins: number;
    monthlyEnrollments: number;
}

// GET /api/dashboard/stats - Get dashboard statistics
export async function GET() {
    try {
        // Get all admin profiles (stored at admins/{uid}/adminProfile/profile)
        const adminProfilesSnapshot = await adminDb.collectionGroup('adminProfile').get();
        const totalAdmins = adminProfilesSnapshot.size;


        // Count admins as academies (1 admin = 1 academy)
        const totalAcademies = totalAdmins;

        // Get total students (subcollection across all admins)
        const studentsSnapshot = await adminDb.collectionGroup('students').get();
        const totalStudents = studentsSnapshot.size;

        // Get monthly enrollments (students joined in current month)
        // NOTE: Filtering in memory to avoid Firestore composite index requirement
        const now = new Date();
        const firstDayOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);

        let monthlyEnrollments = 0;
        studentsSnapshot.docs.forEach(doc => {
            const studentData = doc.data();
            if (studentData.joinedAt) {
                // Convert Firestore Timestamp to Date
                const joinedDate = studentData.joinedAt.toDate ? studentData.joinedAt.toDate() : new Date(studentData.joinedAt);
                if (joinedDate >= firstDayOfMonth) {
                    monthlyEnrollments++;
                }
            }
        });

        const stats: DashboardStats = {
            totalAcademies,
            totalStudents,
            totalAdmins,
            monthlyEnrollments,
        };

        const response: ApiResponse<DashboardStats> = {
            success: true,
            data: stats,
        };

        return NextResponse.json(response);
    } catch (error: unknown) {
        console.error('Error fetching dashboard stats:', error);
        const errorMessage = error instanceof Error ? error.message : 'Failed to fetch dashboard stats';

        const response: ApiResponse<never> = {
            success: false,
            error: errorMessage,
        };

        return NextResponse.json(response, { status: 500 });
    }
}
