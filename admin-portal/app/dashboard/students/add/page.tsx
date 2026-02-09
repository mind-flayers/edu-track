'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/contexts/AuthContext';
import { AdminProfile } from '@/types';
import Link from 'next/link';
import { motion, AnimatePresence } from "framer-motion";
import { GradientButton } from "@/components/ui/gradient-button";
import { InputField } from "@/components/ui/input-field";
import {
  User,
  GraduationCap,
  Users,
  Camera,
  ChevronLeft,
  ChevronRight,
  CheckCircle2,
  BookOpen,
  Phone,
  Home
} from "lucide-react";

const DEFAULT_SUBJECTS = [
  'Mathematics',
  'Science',
  'English',
  'History',
  'ICT',
  'Tamil',
  'Sinhala',
  'Commerce',
];

const CLASSES = [
  'Grade 6',
  'Grade 7',
  'Grade 8',
  'Grade 9',
  'Grade 10',
  'Grade 11',
  'Grade 12',
  'Grade 13',
];

type WizardStep = 'personal' | 'academic' | 'parents';

export default function AddStudentPage() {
  const { user, loading } = useAuth();
  const router = useRouter();
  const [admins, setAdmins] = useState<AdminProfile[]>([]);
  const [selectedAdmin, setSelectedAdmin] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [currentStep, setCurrentStep] = useState<WizardStep>('personal');

  const [formData, setFormData] = useState({
    name: '',
    class: 'Grade 10',
    section: 'A',
    Subjects: [] as string[],
    dob: '',
    sex: 'Male' as 'Male' | 'Female',
    parentName: '',
    parentPhone: '',
    whatsappNumber: '',
    address: '',
    photoUrl: '',
    isNonePayee: false,
  });

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
    } catch (_err) {
      console.error('Failed to fetch admins:', _err);
    }
  };

  const handleSubjectToggle = (subject: string) => {
    if (formData.Subjects.includes(subject)) {
      setFormData({
        ...formData,
        Subjects: formData.Subjects.filter((s) => s !== subject),
      });
    } else {
      setFormData({
        ...formData,
        Subjects: [...formData.Subjects, subject],
      });
    }
  };

  const handlePhotoUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    // Validate file type
    if (!file.type.startsWith('image/')) {
      setError('Please upload an image file');
      return;
    }

    // Validate file size (max 5MB)
    if (file.size > 5 * 1024 * 1024) {
      setError('Image size should be less than 5MB');
      return;
    }

    setUploading(true);
    setError('');

    try {
      // Use Cloudinary client-side upload
      const cloudName = process.env.NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME;
      const uploadPreset = process.env.NEXT_PUBLIC_CLOUDINARY_UPLOAD_PRESET;

      if (!cloudName || !uploadPreset) {
        throw new Error('Cloudinary configuration missing');
      }

      const formDataUpload = new FormData();
      formDataUpload.append('file', file);
      formDataUpload.append('upload_preset', uploadPreset);
      formDataUpload.append('folder', 'profiles/students');

      const response = await fetch(
        `https://api.cloudinary.com/v1_1/${cloudName}/image/upload`,
        {
          method: 'POST',
          body: formDataUpload,
        }
      );

      if (!response.ok) {
        throw new Error('Upload failed');
      }

      const data = await response.json();

      setFormData({
        ...formData,
        photoUrl: data.secure_url,
      });
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : 'Unknown error';
      setError('Failed to upload photo: ' + message);
    } finally {
      setUploading(false);
    }
  };

  const validateStep = () => {
    switch (currentStep) {
      case 'personal':
        if (!formData.name || !formData.dob) {
          setError('Please fill in all personal information');
          return false;
        }
        break;
      case 'academic':
        if (!formData.class || !formData.section || formData.Subjects.length === 0) {
          setError('Please fill in all academic information and select at least one subject');
          return false;
        }
        break;
      case 'parents':
        if (!formData.parentName || !formData.parentPhone) {
          setError('Please fill in parent information');
          return false;
        }
        break;
    }
    setError('');
    return true;
  };

  const nextStep = () => {
    if (!validateStep()) return;

    if (currentStep === 'personal') setCurrentStep('academic');
    else if (currentStep === 'academic') setCurrentStep('parents');
  };

  const prevStep = () => {
    if (currentStep === 'academic') setCurrentStep('personal');
    else if (currentStep === 'parents') setCurrentStep('academic');
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!selectedAdmin) {
      setError('Please select an admin');
      return;
    }

    if (!validateStep()) return;

    setSubmitting(true);
    setError('');
    setSuccess(false);

    try {
      const response = await fetch('/api/students', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          adminUid: selectedAdmin,
          studentData: formData,
        }),
      });

      const data = await response.json();

      if (data.success) {
        setSuccess(true);
        // Reset form
        setFormData({
          name: '',
          class: 'Grade 10',
          section: 'A',
          Subjects: [],
          dob: '',
          sex: 'Male',
          parentName: '',
          parentPhone: '',
          whatsappNumber: '',
          address: '',
          photoUrl: '',
          isNonePayee: false,
        });
        setCurrentStep('personal');

        setTimeout(() => setSuccess(false), 5000);
      } else {
        setError(data.error || 'Failed to create student');
      }
    } catch (_err: unknown) {
      setError('Failed to create student');
    } finally {
      setSubmitting(false);
    }
  };

  if (loading || !user) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-indigo-600"></div>
      </div>
    );
  }

  const steps = [
    { id: 'personal', label: 'Personal Info', icon: User },
    { id: 'academic', label: 'Academic Info', icon: GraduationCap },
    { id: 'parents', label: 'Parents & Photo', icon: Users },
  ];

  const currentStepIndex = steps.findIndex(s => s.id === currentStep);

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      className="max-w-4xl mx-auto space-y-8"
    >
      {/* Header */}
      <div className="flex items-center gap-4 mb-6">
        <Link href="/dashboard" className="p-2 hover:bg-slate-100 rounded-lg transition-colors">
          <ChevronLeft className="w-6 h-6 text-slate-600" />
        </Link>
        <div>
          <h1 className="text-3xl font-bold text-slate-900">Add Student</h1>
          <p className="text-slate-600">Create a new student record manually</p>
        </div>
      </div>

      {/* Admin Selection */}
      <div className="glass-card p-6">
        <label className="block text-sm font-medium text-slate-700 mb-2">
          Select Academy
        </label>
        <select
          value={selectedAdmin}
          onChange={(e) => setSelectedAdmin(e.target.value)}
          className="w-full px-4 py-3 border border-slate-200 rounded-xl focus:border-indigo-500 focus:ring-4 focus:ring-indigo-200 outline-none transition-all"
        >
          {admins.map((admin) => (
            <option key={admin.uid} value={admin.uid}>
              {admin.academyName} - {admin.name}
            </option>
          ))}
        </select>
      </div>

      {error && (
        <motion.div
          initial={{ opacity: 0, y: -10 }}
          animate={{ opacity: 1, y: 0 }}
          className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-xl flex items-center gap-2"
        >
          {error}
        </motion.div>
      )}

      {success && (
        <motion.div
          initial={{ opacity: 0, scale: 0.9 }}
          animate={{ opacity: 1, scale: 1 }}
          className="bg-emerald-50 border border-emerald-200 text-emerald-700 px-4 py-3 rounded-xl flex items-center gap-2"
        >
          <CheckCircle2 className="w-5 h-5" />
          Student created successfully!
        </motion.div>
      )}

      {/* Progress Stepper */}
      <div className="relative">
        <div className="absolute top-1/2 left-0 right-0 h-1 bg-slate-200 -translate-y-1/2 rounded-full" />
        <div
          className="absolute top-1/2 left-0 h-1 bg-indigo-600 -translate-y-1/2 rounded-full transition-all duration-500"
          style={{ width: `${(currentStepIndex / (steps.length - 1)) * 100}%` }}
        />
        <div className="relative flex justify-between">
          {steps.map((step, index) => {
            const Icon = step.icon;
            const isActive = index <= currentStepIndex;
            const isCurrent = index === currentStepIndex;

            return (
              <div key={step.id} className="flex flex-col items-center gap-2">
                <motion.div
                  animate={{
                    scale: isCurrent ? 1.1 : 1,
                    backgroundColor: isActive ? "#4f46e5" : "#e2e8f0",
                  }}
                  className={`w-12 h-12 rounded-full flex items-center justify-center shadow-lg ${isActive ? "text-white" : "text-slate-400"
                    }`}
                >
                  <Icon className="w-6 h-6" />
                </motion.div>
                <span className={`text-sm font-medium ${isActive ? "text-slate-900" : "text-slate-400"}`}>
                  {step.label}
                </span>
              </div>
            );
          })}
        </div>
      </div>

      {/* Form Steps */}
      <form onSubmit={handleSubmit}>
        <AnimatePresence mode="wait">
          {currentStep === 'personal' && (
            <motion.div
              key="personal"
              initial={{ opacity: 0, x: 20 }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: -20 }}
              className="glass-card p-8 space-y-6"
            >
              <h2 className="text-xl font-semibold text-slate-900 mb-6 flex items-center gap-2">
                <User className="w-5 h-5 text-indigo-600" />
                Personal Information
              </h2>

              <InputField
                label="Full Name"
                type="text"
                icon={<User className="w-5 h-5" />}
                value={formData.name}
                onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                required
              />

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-2">
                    Date of Birth *
                  </label>
                  <input
                    type="date"
                    value={formData.dob}
                    onChange={(e) => setFormData({ ...formData, dob: e.target.value })}
                    className="w-full px-4 py-3 border border-slate-200 rounded-xl focus:border-indigo-500 focus:ring-4 focus:ring-indigo-200 outline-none transition-all"
                    required
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-2">
                    Sex *
                  </label>
                  <select
                    value={formData.sex}
                    onChange={(e) => setFormData({ ...formData, sex: e.target.value as 'Male' | 'Female' })}
                    className="w-full px-4 py-3 border border-slate-200 rounded-xl focus:border-indigo-500 focus:ring-4 focus:ring-indigo-200 outline-none transition-all"
                    required
                  >
                    <option value="Male">Male</option>
                    <option value="Female">Female</option>
                  </select>
                </div>
              </div>
            </motion.div>
          )}

          {currentStep === 'academic' && (
            <motion.div
              key="academic"
              initial={{ opacity: 0, x: 20 }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: -20 }}
              className="glass-card p-8 space-y-6"
            >
              <h2 className="text-xl font-semibold text-slate-900 mb-6 flex items-center gap-2">
                <GraduationCap className="w-5 h-5 text-indigo-600" />
                Academic Information
              </h2>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-2">
                    Class *
                  </label>
                  <select
                    value={formData.class}
                    onChange={(e) => setFormData({ ...formData, class: e.target.value })}
                    className="w-full px-4 py-3 border border-slate-200 rounded-xl focus:border-indigo-500 focus:ring-4 focus:ring-indigo-200 outline-none transition-all"
                    required
                  >
                    {CLASSES.map((cls) => (
                      <option key={cls} value={cls}>{cls}</option>
                    ))}
                  </select>
                </div>

                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-2">
                    Section *
                  </label>
                  <input
                    type="text"
                    value={formData.section}
                    onChange={(e) => setFormData({ ...formData, section: e.target.value })}
                    className="w-full px-4 py-3 border border-slate-200 rounded-xl focus:border-indigo-500 focus:ring-4 focus:ring-indigo-200 outline-none transition-all"
                    maxLength={2}
                    required
                  />
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-slate-700 mb-3 flex items-center gap-2">
                  <BookOpen className="w-5 h-5 text-indigo-600" />
                  Subjects * (Select at least one)
                </label>
                <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
                  {DEFAULT_SUBJECTS.map((subject) => (
                    <label
                      key={subject}
                      className={`flex items-center gap-2 p-3 rounded-lg border-2 cursor-pointer transition-all ${formData.Subjects.includes(subject)
                        ? 'border-indigo-500 bg-indigo-50'
                        : 'border-slate-200 hover:border-slate-300'
                        }`}
                    >
                      <input
                        type="checkbox"
                        checked={formData.Subjects.includes(subject)}
                        onChange={() => handleSubjectToggle(subject)}
                        className="w-4 h-4 text-indigo-600 rounded focus:ring-2 focus:ring-indigo-500"
                      />
                      <span className="text-sm text-slate-700 font-medium">{subject}</span>
                    </label>
                  ))}
                </div>
              </div>
            </motion.div>
          )}

          {currentStep === 'parents' && (
            <motion.div
              key="parents"
              initial={{ opacity: 0, x: 20 }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: -20 }}
              className="glass-card p-8 space-y-6"
            >
              <h2 className="text-xl font-semibold text-slate-900 mb-6 flex items-center gap-2">
                <Users className="w-5 h-5 text-indigo-600" />
                Parents & Additional Info
              </h2>

              <div className="grid grid-cols-2 gap-4">
                <InputField
                  label="Parent/Guardian Name"
                  type="text"
                  icon={<User className="w-5 h-5" />}
                  value={formData.parentName}
                  onChange={(e) => setFormData({ ...formData, parentName: e.target.value })}
                  required
                />

                <InputField
                  label="Parent Phone"
                  type="tel"
                  icon={<Phone className="w-5 h-5" />}
                  value={formData.parentPhone}
                  onChange={(e) => setFormData({ ...formData, parentPhone: e.target.value })}
                  required
                />

                <InputField
                  label="WhatsApp Number (Optional)"
                  type="tel"
                  icon={<Phone className="w-5 h-5" />}
                  value={formData.whatsappNumber}
                  onChange={(e) => setFormData({ ...formData, whatsappNumber: e.target.value })}
                  placeholder="Defaults to parent phone"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-slate-700 mb-2 flex items-center gap-2">
                  <Home className="w-5 h-5 text-indigo-600" />
                  Address (Optional)
                </label>
                <textarea
                  value={formData.address}
                  onChange={(e) => setFormData({ ...formData, address: e.target.value })}
                  className="w-full px-4 py-3 border border-slate-200 rounded-xl focus:border-indigo-500 focus:ring-4 focus:ring-indigo-200 outline-none transition-all"
                  rows={3}
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-slate-700 mb-2 flex items-center gap-2">
                  <Camera className="w-5 h-5 text-indigo-600" />
                  Student Photo (Optional)
                </label>
                <input
                  id="photo-upload"
                  type="file"
                  accept="image/*"
                  onChange={handlePhotoUpload}
                  disabled={uploading}
                  className="w-full px-4 py-3 border border-slate-200 rounded-xl focus:border-indigo-500 focus:ring-4 focus:ring-indigo-200 outline-none transition-all disabled:opacity-50"
                />
                {uploading && (
                  <p className="mt-2 text-sm text-indigo-600">Uploading photo...</p>
                )}
                {formData.photoUrl && !uploading && (
                  <div className="mt-3 flex items-center gap-3">
                    <img src={formData.photoUrl} alt="Preview" className="w-20 h-20 rounded-xl object-cover border-2 border-indigo-200" />
                    <p className="text-sm text-emerald-600 flex items-center gap-1">
                      <CheckCircle2 className="w-4 h-4" />
                      Photo uploaded successfully
                    </p>
                  </div>
                )}
              </div>

              <div className="pt-4 border-t border-slate-200">
                <label className="flex items-center gap-3 cursor-pointer group">
                  <input
                    type="checkbox"
                    checked={formData.isNonePayee}
                    onChange={(e) => setFormData({ ...formData, isNonePayee: e.target.checked })}
                    className="w-5 h-5 text-indigo-600 rounded focus:ring-2 focus:ring-indigo-500"
                  />
                  <div>
                    <span className="text-sm font-medium text-slate-700 group-hover:text-slate-900">Fee Exemption (None Payee)</span>
                    <p className="text-xs text-slate-500">Check if this student is exempt from paying fees</p>
                  </div>
                </label>
              </div>
            </motion.div>
          )}
        </AnimatePresence>

        {/* Navigation Buttons */}
        <div className="flex gap-4 mt-6">
          {currentStep !== 'personal' && (
            <button
              type="button"
              onClick={prevStep}
              className="flex-1 px-6 py-3 border border-slate-200 rounded-xl text-slate-700 font-medium hover:bg-slate-50 transition-colors flex items-center justify-center gap-2"
            >
              <ChevronLeft className="w-5 h-5" />
              Previous
            </button>
          )}

          {currentStep !== 'parents' ? (
            <GradientButton
              type="button"
              onClick={nextStep}
              className="flex-1 py-3 flex items-center justify-center gap-2"
            >
              Next
              <ChevronRight className="w-5 h-5" />
            </GradientButton>
          ) : (
            <GradientButton
              type="submit"
              disabled={submitting || uploading}
              isLoading={submitting}
              className="flex-1 py-3"
            >
              {submitting ? 'Creating Student...' : 'Create Student'}
            </GradientButton>
          )}
        </div>
      </form>
    </motion.div>
  );
}

