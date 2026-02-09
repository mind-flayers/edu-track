'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/contexts/AuthContext';
import { motion } from "framer-motion";
import { StatCard } from "@/components/dashboard/stat-card";
import { QuickActions } from "@/components/dashboard/quick-actions";
import { Users, School, TrendingUp, Calendar } from "lucide-react";
import Link from 'next/link';

const containerVariants = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: {
      staggerChildren: 0.1,
    },
  },
};

const itemVariants = {
  hidden: { opacity: 0, y: 20 },
  visible: { opacity: 1, y: 0 },
};

interface DashboardStats {
  totalAcademies: number;
  totalStudents: number;
  totalAdmins: number;
  monthlyEnrollments: number;
}

export default function DashboardPage() {
  const { user, loading } = useAuth();
  const router = useRouter();
  const [stats, setStats] = useState<DashboardStats>({
    totalAcademies: 0,
    totalStudents: 0,
    totalAdmins: 0,
    monthlyEnrollments: 0,
  });
  const [loadingStats, setLoadingStats] = useState(true);

  useEffect(() => {
    if (!loading && !user) {
      router.push('/login');
    } else if (user) {
      fetchDashboardStats();
    }
  }, [user, loading, router]);

  const fetchDashboardStats = async () => {
    try {
      const response = await fetch('/api/dashboard/stats');
      const data = await response.json();

      if (data.success) {
        setStats(data.data);
      }
    } catch (_err) {
      console.error('Failed to fetch dashboard stats:', _err);
    } finally {
      setLoadingStats(false);
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
      variants={containerVariants}
      initial="hidden"
      animate="visible"
      className="space-y-6 mt-8"
    >
      {/* Hero Section */}
      <motion.div
        variants={itemVariants}
        className="relative overflow-hidden rounded-2xl bg-gradient-to-r from-indigo-600 to-violet-600 p-6 text-white shadow-xl"
      >
        <div className="absolute inset-0 bg-[url('https://www.transparenttextures.com/patterns/cubes.png')] opacity-10" />
        <div className="absolute -right-20 -top-20 w-64 h-64 bg-white/10 rounded-full blur-3xl" />
        <div className="absolute -left-20 -bottom-20 w-64 h-64 bg-cyan-400/20 rounded-full blur-3xl" />

        <div className="relative z-10">
          <motion.div
            initial={{ opacity: 0, x: -20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ delay: 0.2 }}
          >
            <h1 className="text-3xl font-bold mb-2">Welcome Back, Super Admin</h1>
            <p className="text-indigo-100">
              Here's your EduTrack overview. Manage academies, administrators, and students from one powerful dashboard.
            </p>
          </motion.div>
        </div>
      </motion.div>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <Link href="/dashboard/admins">
          <StatCard
            title="Total Academies"
            value={stats.totalAcademies.toString()}
            change="+2"
            trend="up"
            icon={<School className="w-6 h-6" />}
            color="indigo"
          />
        </Link>
        <Link href="/dashboard/students">
          <StatCard
            title="Total Students"
            value={stats.totalStudents.toLocaleString()}
            change="+124"
            trend="up"
            icon={<Users className="w-6 h-6" />}
            color="cyan"
          />
        </Link>
        <Link href="/dashboard/students">
          <StatCard
            title="This Month"
            value={stats.monthlyEnrollments.toString()}
            change="New Enrollments"
            trend="neutral"
            icon={<Calendar className="w-6 h-6" />}
            color="emerald"
          />
        </Link>
      </div>

      {/* Quick Actions */}
      <div>
        <QuickActions />
      </div>
    </motion.div>
  );
}
