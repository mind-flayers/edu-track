'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/contexts/AuthContext';
import { AdminProfile, ImportResult } from '@/types';
import Link from 'next/link';

export default function ImportStudentsPage() {
  const { user, loading } = useAuth();
  const router = useRouter();
  const [admins, setAdmins] = useState<AdminProfile[]>([]);
  const [selectedAdmin, setSelectedAdmin] = useState('');
  const [csvContent, setCsvContent] = useState('');
  const [importing, setImporting] = useState(false);
  const [result, setResult] = useState<ImportResult | null>(null);
  const [error, setError] = useState('');

  useEffect(() => {
    if (!loading && !user) {
      router.push('/login');
    } else if (user) {
      fetchAdmins();
    }
  }, [user, loading, router]);

  const fetchAdmins = async () => {
    try {
      const response = await fetch('/api/admins');
      const data = await response.json();
      
      if (data.success) {
        setAdmins(data.data);
        if (data.data.length > 0) {
          setSelectedAdmin(data.data[0].uid);
        }
      }
    } catch (err) {
      console.error('Failed to fetch admins:', err);
    }
  };

  const handleFileUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = (event) => {
      const text = event.target?.result as string;
      setCsvContent(text);
    };
    reader.readAsText(file);
  };

  const handleImport = async () => {
    if (!selectedAdmin || !csvContent) {
      setError('Please select an admin and upload a CSV file');
      return;
    }

    setImporting(true);
    setError('');
    setResult(null);

    try {
      const response = await fetch('/api/students/import', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          adminUid: selectedAdmin,
          csvData: csvContent,
        }),
      });

      const data = await response.json();

      if (data.success) {
        setResult(data.data);
        setCsvContent('');
        // Reset file input
        const fileInput = document.getElementById('csv-upload') as HTMLInputElement;
        if (fileInput) fileInput.value = '';
      } else {
        setError(data.error || 'Failed to import students');
      }
    } catch (err: any) {
      setError('Failed to import students');
    } finally {
      setImporting(false);
    }
  };

  if (loading || !user) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-purple-600"></div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <header className="bg-white shadow">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4 flex items-center gap-4">
          <Link href="/dashboard" className="text-purple-600 hover:text-purple-700">
            ← Back to Dashboard
          </Link>
          <h1 className="text-2xl font-bold text-gray-900">Import Students from CSV</h1>
        </div>
      </header>

      <main className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Instructions */}
        <div className="bg-blue-50 border border-blue-200 rounded-lg p-6 mb-6">
          <h2 className="text-lg font-semibold text-blue-900 mb-2">CSV Format Instructions</h2>
          <p className="text-blue-800 mb-4">Your CSV file should have the following columns (header row required):</p>
          <ul className="text-sm text-blue-800 space-y-1 list-disc list-inside">
            <li><strong>name</strong> - Student full name (required)</li>
            <li><strong>class</strong> - e.g., "Grade 10" (required)</li>
            <li><strong>section</strong> - e.g., "A" or "B" (required)</li>
            <li><strong>subjects</strong> - Comma-separated, e.g., "Mathematics,Science,English" (required)</li>
            <li><strong>dob</strong> - Date of birth in YYYY-MM-DD format (required)</li>
            <li><strong>sex</strong> - "Male" or "Female" (required)</li>
            <li><strong>parentName</strong> - Parent/guardian name (required)</li>
            <li><strong>parentPhone</strong> - Phone number (required)</li>
            <li><strong>whatsappNumber</strong> - WhatsApp number (optional, defaults to parentPhone)</li>
            <li><strong>address</strong> - Full address (optional)</li>
            <li><strong>photoUrl</strong> - Google Drive link or direct image URL (optional)</li>
            <li><strong>isNonePayee</strong> - "true" or "false" for fee exemption (optional, defaults to false)</li>
          </ul>
        </div>

        {error && (
          <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded mb-6">
            {error}
          </div>
        )}

        {/* Import Form */}
        <div className="bg-white rounded-lg shadow p-6 mb-6">
          <div className="space-y-6">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Select Admin/Academy
              </label>
              <select
                value={selectedAdmin}
                onChange={(e) => setSelectedAdmin(e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500"
              >
                {admins.map((admin) => (
                  <option key={admin.uid} value={admin.uid}>
                    {admin.academyName} - {admin.name}
                  </option>
                ))}
              </select>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Upload CSV File
              </label>
              <input
                id="csv-upload"
                type="file"
                accept=".csv"
                onChange={handleFileUpload}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500"
              />
              {csvContent && (
                <p className="mt-2 text-sm text-green-600">✓ CSV file loaded successfully</p>
              )}
            </div>

            <button
              onClick={handleImport}
              disabled={importing || !csvContent || !selectedAdmin}
              className="w-full px-6 py-3 bg-purple-600 text-white rounded-lg hover:bg-purple-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed font-medium"
            >
              {importing ? 'Importing...' : 'Import Students'}
            </button>
          </div>
        </div>

        {/* Import Result */}
        {result && (
          <div className="bg-white rounded-lg shadow p-6">
            <h2 className="text-xl font-semibold text-gray-900 mb-4">Import Results</h2>
            
            <div className="grid grid-cols-3 gap-4 mb-6">
              <div className="bg-green-50 border border-green-200 rounded-lg p-4">
                <p className="text-sm text-green-800 font-medium">Successful</p>
                <p className="text-3xl font-bold text-green-900">{result.success}</p>
              </div>
              <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
                <p className="text-sm text-blue-800 font-medium">Duplicates</p>
                <p className="text-3xl font-bold text-blue-900">{result.skippedDuplicates?.length || 0}</p>
              </div>
              <div className="bg-red-50 border border-red-200 rounded-lg p-4">
                <p className="text-sm text-red-800 font-medium">Failed</p>
                <p className="text-3xl font-bold text-red-900">{result.failed}</p>
              </div>
            </div>

            {result.skippedDuplicates && result.skippedDuplicates.length > 0 && (
              <div className="mb-6">
                <h3 className="text-lg font-semibold text-gray-900 mb-3">Duplicate Students Handled</h3>
                <p className="text-sm text-gray-600 mb-3">
                  These students already exist in the database. They were imported with new unique index numbers.
                </p>
                <div className="space-y-2 max-h-96 overflow-y-auto">
                  {result.skippedDuplicates.map((duplicate, index) => (
                    <div key={index} className="bg-blue-50 border border-blue-200 rounded p-3">
                      <p className="text-sm font-medium text-blue-900">Row {duplicate.row}: {duplicate.name}</p>
                      <p className="text-sm text-blue-700">{duplicate.reason}</p>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {result.errors.length > 0 && (
              <div>
                <h3 className="text-lg font-semibold text-gray-900 mb-3">Errors</h3>
                <div className="space-y-2 max-h-96 overflow-y-auto">
                  {result.errors.map((error, index) => (
                    <div key={index} className="bg-red-50 border border-red-200 rounded p-3">
                      <p className="text-sm font-medium text-red-900">Row {error.row}</p>
                      <p className="text-sm text-red-700">{error.error}</p>
                      {error.data && (
                        <p className="text-xs text-red-600 mt-1 font-mono">
                          {JSON.stringify(error.data)}
                        </p>
                      )}
                    </div>
                  ))}
                </div>
              </div>
            )}

            {result.successfulStudents.length > 0 && (
              <div className="mt-6">
                <h3 className="text-lg font-semibold text-gray-900 mb-3">Successfully Imported Students</h3>
                <div className="space-y-2 max-h-96 overflow-y-auto">
                  {result.successfulStudents.map((student) => (
                    <div key={student.id} className="bg-green-50 border border-green-200 rounded p-3 flex items-center gap-3">
                      {student.photoUrl && (
                        <img src={student.photoUrl} alt={student.name} className="w-10 h-10 rounded-full object-cover" />
                      )}
                      <div className="flex-1">
                        <p className="text-sm font-medium text-gray-900">{student.name}</p>
                        <p className="text-xs text-gray-600">{student.indexNumber} • {student.class} {student.section}</p>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>
        )}
      </main>
    </div>
  );
}
