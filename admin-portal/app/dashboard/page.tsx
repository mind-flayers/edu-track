'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/contexts/AuthContext';
import Link from 'next/link';

export default function DashboardPage() {
  const { user, loading, isSuperAdmin, signOut } = useAuth();
  const router = useRouter();

  useEffect(() => {
    if (!loading && !user) {
      router.push('/login');
    }
  }, [user, loading, router]);

  if (loading || !user) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-purple-600"></div>
      </div>
    );
  }

  const handleSignOut = async () => {
    await signOut();
    router.push('/login');
  };

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="bg-white shadow">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4 flex justify-between items-center">
          <div>
            <h1 className="text-2xl font-bold text-gray-900">EduTrack Admin Portal</h1>
            <div className="flex items-center gap-2 mt-1">
              <p className="text-sm text-gray-600">{user.email}</p>
              {isSuperAdmin && (
                <span className="px-2 py-0.5 bg-purple-100 text-purple-700 text-xs font-semibold rounded-full">
                  SUPER ADMIN
                </span>
              )}
            </div>
          </div>
          <button
            onClick={handleSignOut}
            className="px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors"
          >
            Sign Out
          </button>
        </div>
      </header>

      {/* Main Content */}
      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {/* Admin Management Card */}
          <Link href="/dashboard/admins">
            <div className="bg-white rounded-lg shadow hover:shadow-lg transition-shadow p-6 cursor-pointer border-2 border-transparent hover:border-purple-500">
              <div className="flex items-center justify-center w-12 h-12 bg-purple-100 rounded-lg mb-4">
                <svg className="w-6 h-6 text-purple-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
                </svg>
              </div>
              <h2 className="text-xl font-semibold text-gray-900 mb-2">Admin Management</h2>
              <p className="text-gray-600">Create, view, and manage admin accounts</p>
            </div>
          </Link>

          {/* Student Import Card */}
          <Link href="/dashboard/students/import">
            <div className="bg-white rounded-lg shadow hover:shadow-lg transition-shadow p-6 cursor-pointer border-2 border-transparent hover:border-blue-500">
              <div className="flex items-center justify-center w-12 h-12 bg-blue-100 rounded-lg mb-4">
                <svg className="w-6 h-6 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12" />
                </svg>
              </div>
              <h2 className="text-xl font-semibold text-gray-900 mb-2">Import Students (CSV)</h2>
              <p className="text-gray-600">Bulk import students from Google Forms CSV</p>
            </div>
          </Link>

          {/* Manual Student Entry Card */}
          <Link href="/dashboard/students/add">
            <div className="bg-white rounded-lg shadow hover:shadow-lg transition-shadow p-6 cursor-pointer border-2 border-transparent hover:border-green-500">
              <div className="flex items-center justify-center w-12 h-12 bg-green-100 rounded-lg mb-4">
                <svg className="w-6 h-6 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
                </svg>
              </div>
              <h2 className="text-xl font-semibold text-gray-900 mb-2">Add Student Manually</h2>
              <p className="text-gray-600">Create a new student record manually</p>
            </div>
          </Link>
        </div>

        {/* Instructions Section */}
        <div className="mt-12 bg-white rounded-lg shadow p-6">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Getting Started</h3>
          <div className="space-y-4 text-gray-700">
            <div>
              <h4 className="font-medium text-gray-900">1. Admin Management</h4>
              <p className="text-sm">Create and manage admin accounts for different academies. Each admin gets their own isolated database.</p>
            </div>
            <div>
              <h4 className="font-medium text-gray-900">2. CSV Import</h4>
              <p className="text-sm">Export data from Google Forms, upload the CSV file, and automatically import students with photos from Google Drive.</p>
            </div>
            <div>
              <h4 className="font-medium text-gray-900">3. Manual Entry</h4>
              <p className="text-sm">Add individual students one at a time with full control over all fields.</p>
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}
