'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/contexts/AuthContext';
import { AdminProfile } from '@/types';
import { motion, AnimatePresence } from "framer-motion";
import { GradientButton } from "@/components/ui/gradient-button";
import { InputField } from "@/components/ui/input-field";
import { Plus, Shield, Mail, Building2, X, Upload, Edit2, Trash2 } from "lucide-react";

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

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const data = await response.json();

      if (data.success) {
        setAdmins(data.data);
      } else {
        setError(data.error || 'Failed to fetch admins');
      }
    } catch (err: unknown) {
      console.error('Fetch admins error:', err);
      const message = err instanceof Error ? err.message : 'Failed to fetch admins';
      setError(message);
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
    } catch (err: unknown) {
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
        <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-indigo-600"></div>
      </div>
    );
  }

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      className="space-y-6 mt-8"
    >
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-3xl font-bold text-slate-900 flex items-center gap-3">
            <Shield className="w-8 h-8 text-indigo-600" />
            Admin Management
          </h1>
          <p className="text-slate-600 mt-1">Manage academy administrators and their permissions</p>
        </div>
        <GradientButton onClick={() => setShowCreateForm(true)} className="flex items-center gap-2">
          <Plus className="w-5 h-5" />
          Create Admin
        </GradientButton>
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-xl">
          {error}
        </div>
      )}

      {/* Stats Overview */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div className="glass-card p-4 flex items-center gap-4">
          <div className="w-12 h-12 rounded-full bg-indigo-100 flex items-center justify-center">
            <span className="text-2xl font-bold text-indigo-600">{admins.length}</span>
          </div>
          <div>
            <p className="text-sm text-slate-600">Total Admins</p>
          </div>
        </div>
      </div>

      {/* Admins List */}
      {isLoading ? (
        <div className="flex justify-center py-12">
          <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-indigo-600"></div>
        </div>
      ) : admins.length === 0 ? (
        <div className="glass-card p-12 text-center">
          <p className="text-slate-500 text-lg">No admins found. Create your first admin to get started.</p>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {admins.map((admin, index) => (
            <motion.div
              key={admin.uid}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: index * 0.1 }}
              whileHover={{ y: -5 }}
              className="glass-card p-6"
            >
              <div className="flex items-center gap-4 mb-4">
                {admin.profilePhotoUrl ? (
                  <img
                    src={admin.profilePhotoUrl}
                    alt={admin.name}
                    className="w-16 h-16 rounded-full object-cover border-2 border-white shadow-md"
                  />
                ) : (
                  <div className="w-16 h-16 rounded-full bg-gradient-to-br from-indigo-500 to-violet-500 flex items-center justify-center shadow-lg">
                    <span className="text-2xl font-semibold text-white">
                      {admin.name.charAt(0)}
                    </span>
                  </div>
                )}
                <div className="flex-1">
                  <h3 className="font-semibold text-slate-900">{admin.name}</h3>
                  <p className="text-sm text-slate-600">{admin.academyName}</p>
                </div>
              </div>
              <div className="space-y-2 text-sm">
                <p className="text-slate-600"><span className="font-medium">Email:</span> {admin.email}</p>
                <p className="text-slate-600"><span className="font-medium">UID:</span> <span className="font-mono text-xs">{admin.uid}</span></p>
              </div>
              <div className="mt-4 flex gap-2">
                <button
                  onClick={() => handleDeleteAdmin(admin.uid)}
                  className="flex-1 px-3 py-2 bg-rose-50 text-rose-600 text-sm rounded-lg hover:bg-rose-100 transition-colors flex items-center justify-center gap-2"
                >
                  <Trash2 className="w-4 h-4" />
                  Delete
                </button>
              </div>
            </motion.div>
          ))}
        </div>
      )}

      {/* Create Admin Drawer */}
      <AnimatePresence>
        {showCreateForm && (
          <>
            {/* Backdrop */}
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              onClick={() => setShowCreateForm(false)}
              className="fixed inset-0 bg-slate-950/60 backdrop-blur-sm z-50"
            />

            {/* Drawer */}
            <motion.div
              initial={{ x: "100%" }}
              animate={{ x: 0 }}
              exit={{ x: "100%" }}
              transition={{ type: "spring", damping: 25, stiffness: 200 }}
              className="fixed right-0 top-0 h-full w-full max-w-xl bg-white shadow-2xl z-50 overflow-y-auto"
            >
              <div className="p-8">
                <div className="flex items-center justify-between mb-8">
                  <div>
                    <h2 className="text-2xl font-bold text-slate-900">Create New Admin</h2>
                    <p className="text-slate-600 mt-1">Add a new academy administrator</p>
                  </div>
                  <button
                    onClick={() => setShowCreateForm(false)}
                    className="p-2 hover:bg-slate-100 rounded-full transition-colors"
                  >
                    <X className="w-6 h-6 text-slate-600" />
                  </button>
                </div>

                <form onSubmit={handleCreateAdmin} className="space-y-6">
                  <div className="grid grid-cols-2 gap-4">
                    <InputField
                      label="Full Name"
                      icon={<Shield className="w-5 h-5 text-slate-400" />}
                      value={formData.name}
                      onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                      placeholder="John Doe"
                      required
                    />
                    <InputField
                      label="Email"
                      type="email"
                      icon={<Mail className="w-5 h-5 text-slate-400" />}
                      value={formData.email}
                      onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                      placeholder="john@academy.edu"
                      required
                    />
                  </div>

                  <div className="grid grid-cols-2 gap-4">
                    <InputField
                      label="Academy Name"
                      icon={<Building2 className="w-5 h-5 text-slate-400" />}
                      value={formData.academyName}
                      onChange={(e) => setFormData({ ...formData, academyName: e.target.value })}
                      placeholder="Academy Name"
                      required
                    />
                    <InputField
                      label="Password"
                      type="password"
                      value={formData.password}
                      onChange={(e) => setFormData({ ...formData, password: e.target.value })}
                      placeholder="••••••••"
                      required
                    />
                  </div>

                  <InputField
                    label="Profile Photo URL (optional)"
                    value={formData.profilePhotoUrl}
                    onChange={(e) => setFormData({ ...formData, profilePhotoUrl: e.target.value })}
                    placeholder="https://..."
                  />

                  <div className="pt-4 flex gap-3">
                    <button
                      type="button"
                      onClick={() => setShowCreateForm(false)}
                      className="flex-1 px-6 py-3 border border-slate-200 rounded-xl text-slate-700 font-medium hover:bg-slate-50 transition-colors"
                    >
                      Cancel
                    </button>
                    <GradientButton type="submit" className="flex-1 justify-center" isLoading={creating}>
                      {creating ? 'Creating...' : 'Create Admin'}
                    </GradientButton>
                  </div>
                </form>
              </div>
            </motion.div>
          </>
        )}
      </AnimatePresence>
    </motion.div>
  );
}
