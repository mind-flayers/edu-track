'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/contexts/AuthContext';
import { AdminProfile, ImportResult } from '@/types';
import { motion } from "framer-motion";
import { useDropzone } from "react-dropzone";
import { GradientButton } from "@/components/ui/gradient-button";
import { Upload, FileSpreadsheet, CheckCircle2, AlertCircle, ChevronLeft } from "lucide-react";
import Link from "next/link";

export default function ImportStudentsPage() {
  const { user, loading } = useAuth();
  const router = useRouter();
  const [admins, setAdmins] = useState<AdminProfile[]>([]);
  const [selectedAdmin, setSelectedAdmin] = useState('');
  const [csvContent, setCsvContent] = useState('');
  const [importing, setImporting] = useState(false);
  const [result, setResult] = useState<ImportResult | null>(null);
  const [error, setError] = useState('');
  const [stage, setStage] = useState<'select' | 'upload' | 'complete'>('select');

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

  const onDrop = (acceptedFiles: File[]) => {
    const file = acceptedFiles[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = (event) => {
      const text = event.target?.result as string;
      setCsvContent(text);
      setStage('upload');
    };
    reader.readAsText(file);
  };

  const { getRootProps, getInputProps, isDragActive } = useDropzone({
    onDrop,
    accept: { 'text/csv': ['.csv'] },
    maxFiles: 1,
  });

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
        setStage('complete');
        setCsvContent('');
      } else {
        setError(data.error || 'Failed to import students');
      }
    } catch (err: unknown) {
      setError('Failed to import students');
    } finally {
      setImporting(false);
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
    { id: 'select', label: 'Select Academy', icon: FileSpreadsheet },
    { id: 'upload', label: 'Upload CSV', icon: Upload },
    { id: 'complete', label: 'Complete', icon: CheckCircle2 },
  ];

  const currentStepIndex = steps.findIndex(s => s.id === stage);

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
          <h1 className="text-3xl font-bold text-slate-900">Import Students</h1>
          <p className="text-slate-600">Bulk upload student data via CSV file</p>
        </div>
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-xl flex items-center gap-2">
          <AlertCircle className="w-5 h-5" />
          {error}
        </div>
      )}

      {/* Stepper */}
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

      {/* Content */}
      {stage === 'select' && (
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="glass-card p-8"
        >
          <h2 className="text-xl font-semibold text-slate-900 mb-6">Select Academy</h2>
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-2">
                Choose the academy to import students into
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
            <GradientButton
              onClick={() => setStage('upload')}
              disabled={!selectedAdmin}
              className="w-full py-3"
            >
              Continue to Upload
            </GradientButton>
          </div>
        </motion.div>
      )}

      {stage === 'upload' && (
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="space-y-6"
        >
          {/* Instructions */}
          <div className="glass-card p-6">
            <h3 className="text-lg font-semibold text-slate-900 mb-4">CSV Format Instructions</h3>
            <div className="space-y-2 text-sm text-slate-600">
              <p>Required columns: <strong>name, class, section, subjects, dob, sex, parentName, parentPhone</strong></p>
              <p>Optional columns: whatsappNumber, address, photoUrl, isNonePayee</p>
            </div>
          </div>

          {/* Upload Zone */}
          <div
            {...getRootProps()}
            className={`glass-card p-12 text-center cursor-pointer transition-all ${isDragActive ? "border-indigo-500 bg-indigo-50/50 scale-[1.02]" : ""
              }`}
          >
            <input {...getInputProps()} />
            <div className="w-20 h-20 bg-indigo-100 rounded-full flex items-center justify-center mx-auto mb-6">
              <Upload className="w-10 h-10 text-indigo-600" />
            </div>
            {csvContent ? (
              <div>
                <p className="text-lg font-semibold text-emerald-600 mb-2">✓ CSV file loaded successfully</p>
                <p className="text-sm text-slate-600">Click &quot;Import Students&quot; to proceed</p>
              </div>
            ) : (
              <>
                <h3 className="text-xl font-semibold text-slate-900 mb-2">
                  {isDragActive ? "Drop CSV file here" : "Upload CSV File"}
                </h3>
                <p className="text-slate-600 mb-4">Drag and drop your file here, or click to browse</p>
                <div className="inline-flex items-center gap-2 px-4 py-2 bg-slate-100 rounded-full text-sm text-slate-600">
                  <FileSpreadsheet className="w-4 h-4" />
                  Supports .csv files up to 10MB
                </div>
              </>
            )}
          </div>

          <div className="flex gap-4">
            <button
              onClick={() => setStage('select')}
              className="flex-1 px-6 py-3 border border-slate-200 rounded-xl text-slate-700 font-medium hover:bg-slate-50 transition-colors"
            >
              Back
            </button>
            <GradientButton
              onClick={handleImport}
              disabled={!csvContent || importing}
              isLoading={importing}
              className="flex-1 py-3"
            >
              {importing ? 'Importing...' : 'Import Students'}
            </GradientButton>
          </div>
        </motion.div>
      )}

      {stage === 'complete' && result && (
        <motion.div
          initial={{ opacity: 0, scale: 0.95 }}
          animate={{ opacity: 1, scale: 1 }}
          className="glass-card p-8 text-center"
        >
          <div className="w-20 h-20 bg-emerald-100 rounded-full flex items-center justify-center mx-auto mb-4">
            <CheckCircle2 className="w-10 h-10 text-emerald-600" />
          </div>
          <h2 className="text-2xl font-bold text-slate-900 mb-2">Import Complete!</h2>
          <p className="text-slate-600 mb-6">
            Successfully imported {result.success} students
          </p>
          <div className="grid grid-cols-3 gap-4 max-w-md mx-auto mb-6">
            <div className="p-4 bg-emerald-50 rounded-xl">
              <p className="text-2xl font-bold text-emerald-600">{result.success}</p>
              <p className="text-sm text-emerald-700">Successful</p>
            </div>
            <div className="p-4 bg-amber-50 rounded-xl">
              <p className="text-2xl font-bold text-amber-600">{result.skippedDuplicates?.length || 0}</p>
              <p className="text-sm text-amber-700">Duplicates</p>
            </div>
            <div className="p-4 bg-rose-50 rounded-xl">
              <p className="text-2xl font-bold text-rose-600">{result.errors?.length || 0}</p>
              <p className="text-sm text-rose-700">Errors</p>
            </div>
          </div>
          <div className="flex gap-4 justify-center">
            <Link href="/dashboard">
              <GradientButton>Return to Dashboard</GradientButton>
            </Link>
            <button
              onClick={() => {
                setStage('select');
                setResult(null);
                setCsvContent('');
              }}
              className="px-6 py-3 border border-slate-200 rounded-xl text-slate-700 font-medium hover:bg-slate-50 transition-colors"
            >
              Import More
            </button>
          </div>
        </motion.div>
      )}
    </motion.div>
  );
}
