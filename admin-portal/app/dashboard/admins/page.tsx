'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/contexts/AuthContext';
import { AdminProfile } from '@/types';
import Link from 'next/link';

export default function AdminsPage() {
  const { user, loading } = useAuth();
  const router = useRouter();
  const [admins, setAdmins] = useState<AdminProfile[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState('');
  const [showCreateForm, setShowCreateForm] = useState(false);

  // Form state
  const [formData, setFormData] = useState({
    email: '',
    password: '',
    name: '',
    academyName: '',
    profilePhotoUrl: '',
  });
  const [creating, setCreating] = useState(false);

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
      
      // Log response status
      console.log('Response status:', response.status);
      
      // Check if response is ok
      if (!response.ok) {
        console.error('Response not OK:', response.status, response.statusText);
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      
      const data = await response.json();
      console.log('Admins API response:', data);
      
      if (data.success) {
        setAdmins(data.data);
      } else {
        setError(data.error || 'Failed to fetch admins');
      }
    } catch (err: any) {
      console.error('Fetch admins error:', err);
      setError(err.message || 'Failed to fetch admins');
    } finally {
      setIsLoading(false);
    }
  };

  const handleCreateAdmin = async (e: React.FormEvent) => {
    e.preventDefault();
    setCreating(true);
    setError('');

    try {
      const response = await fetch('/api/admins', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(formData),
      });

      const data = await response.json();

      if (data.success) {
        setAdmins([...admins, data.data]);
        setShowCreateForm(false);
        setFormData({
          email: '',
          password: '',
          name: '',
          academyName: '',
          profilePhotoUrl: '',
        });
      } else {
        setError(data.error || 'Failed to create admin');
      }
    } catch (err: any) {
      setError('Failed to create admin');
    } finally {
      setCreating(false);
    }
  };

  const handleDeleteAdmin = async (adminId: string) => {
    if (!confirm('Are you sure you want to delete this admin? This action cannot be undone.')) {
      return;
    }

    try {
      const response = await fetch(`/api/admins/${adminId}`, {
        method: 'DELETE',
      });

      const data = await response.json();

      if (data.success) {
        setAdmins(admins.filter(a => a.uid !== adminId));
      } else {
        alert(data.error || 'Failed to delete admin');
      }
    } catch (err) {
      alert('Failed to delete admin');
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
      {/* Header */}
      <header className="bg-white shadow">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4 flex justify-between items-center">
          <div className="flex items-center gap-4">
            <Link href="/dashboard" className="text-purple-600 hover:text-purple-700">
              ← Back to Dashboard
            </Link>
            <h1 className="text-2xl font-bold text-gray-900">Admin Management</h1>
          </div>
          <button
            onClick={() => setShowCreateForm(!showCreateForm)}
            className="px-4 py-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700 transition-colors"
          >
            {showCreateForm ? 'Cancel' : '+ Create Admin'}
          </button>
        </div>
      </header>

      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {error && (
          <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded mb-4">
            {error}
          </div>
        )}

        {/* Create Form */}
        {showCreateForm && (
          <div className="bg-white rounded-lg shadow p-6 mb-6">
            <h2 className="text-xl font-semibold text-gray-900 mb-4">Create New Admin</h2>
            <form onSubmit={handleCreateAdmin} className="space-y-4">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Name *</label>
                  <input
                    type="text"
                    required
                    value={formData.name}
                    onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Academy Name *</label>
                  <input
                    type="text"
                    required
                    value={formData.academyName}
                    onChange={(e) => setFormData({ ...formData, academyName: e.target.value })}
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Email *</label>
                  <input
                    type="email"
                    required
                    value={formData.email}
                    onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Password *</label>
                  <input
                    type="password"
                    required
                    minLength={6}
                    value={formData.password}
                    onChange={(e) => setFormData({ ...formData, password: e.target.value })}
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500"
                  />
                </div>
                <div className="md:col-span-2">
                  <label className="block text-sm font-medium text-gray-700 mb-1">Profile Photo URL (optional)</label>
                  <input
                    type="url"
                    value={formData.profilePhotoUrl}
                    onChange={(e) => setFormData({ ...formData, profilePhotoUrl: e.target.value })}
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500"
                  />
                </div>
              </div>
              <div className="flex justify-end">
                <button
                  type="submit"
                  disabled={creating}
                  className="px-6 py-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700 transition-colors disabled:opacity-50"
                >
                  {creating ? 'Creating...' : 'Create Admin'}
                </button>
              </div>
            </form>
          </div>
        )}

        {/* Admins List */}
        {isLoading ? (
          <div className="flex justify-center py-12">
            <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-purple-600"></div>
          </div>
        ) : admins.length === 0 ? (
          <div className="bg-white rounded-lg shadow p-12 text-center">
            <p className="text-gray-500 text-lg">No admins found. Create your first admin to get started.</p>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {admins.map((admin) => (
              <div key={admin.uid} className="bg-white rounded-lg shadow p-6">
                <div className="flex items-center gap-4 mb-4">
                  {admin.profilePhotoUrl ? (
                    <img
                      src={admin.profilePhotoUrl}
                      alt={admin.name}
                      className="w-16 h-16 rounded-full object-cover"
                    />
                  ) : (
                    <div className="w-16 h-16 rounded-full bg-purple-100 flex items-center justify-center">
                      <span className="text-2xl font-semibold text-purple-600">
                        {admin.name.charAt(0)}
                      </span>
                    </div>
                  )}
                  <div className="flex-1">
                    <h3 className="font-semibold text-gray-900">{admin.name}</h3>
                    <p className="text-sm text-gray-600">{admin.academyName}</p>
                  </div>
                </div>
                <div className="space-y-2 text-sm">
                  <p className="text-gray-600"><span className="font-medium">Email:</span> {admin.email}</p>
                  <p className="text-gray-600"><span className="font-medium">UID:</span> <span className="font-mono text-xs">{admin.uid}</span></p>
                </div>
                <div className="mt-4 flex gap-2">
                  <button
                    onClick={() => handleDeleteAdmin(admin.uid)}
                    className="flex-1 px-3 py-2 bg-red-600 text-white text-sm rounded hover:bg-red-700 transition-colors"
                  >
                    Delete
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}
      </main>
    </div>
  );
}
