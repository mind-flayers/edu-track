'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/contexts/AuthContext';
import { motion } from "framer-motion";
import { StatCard } from "@/components/dashboard/stat-card";
import { QuickActions } from "@/components/dashboard/quick-actions";
import { Users, School, TrendingUp, Calendar } from "lucide-react";

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

export default function DashboardPage() {
  const { user, loading } = useAuth();
  const router = useRouter();

  useEffect(() => {
    if (!loading && !user) {
      router.push('/login');
    }
  }, [user, loading, router]);

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
      className="space-y-8"
    >
      {/* Hero Section */}
      <motion.div
        variants={itemVariants}
        className="relative overflow-hidden rounded-3xl bg-gradient-to-r from-indigo-600 to-violet-600 p-8 lg:p-12 text-white shadow-2xl shadow-indigo-500/25"
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
            <h1 className="text-4xl lg:text-5xl font-bold mb-4">Welcome Back, Admin</h1>
            <p className="text-indigo-100 text-lg max-w-xl">
              Here&apos;s your EduTrack overview. Manage academies, administrators, and students from one powerful dashboard.
            </p>
          </motion.div>
        </div>
      </motion.div>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <StatCard
          title="Total Academies"
          value="12"
          change="+2"
          trend="up"
          icon={<School className="w-6 h-6" />}
          color="indigo"
        />
        <StatCard
          title="Total Students"
          value="2,847"
          change="+124"
          trend="up"
          icon={<Users className="w-6 h-6" />}
          color="cyan"
        />
        <StatCard
          title="Active Admins"
          value="48"
          change="+5"
          trend="up"
          icon={<TrendingUp className="w-6 h-6" />}
          color="violet"
        />
        <StatCard
          title="This Month"
          value="156"
          change="New Enrollments"
          trend="neutral"
          icon={<Calendar className="w-6 h-6" />}
          color="emerald"
        />
      </div>

      {/* Quick Actions */}
      <div>
        <QuickActions />
      </div>
    </motion.div>
  );
}
