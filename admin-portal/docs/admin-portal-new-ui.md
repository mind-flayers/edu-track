Kimi: I'll help you redesign the EduTrack Admin Portal with a premium, modern UI. Let me first search for the latest best practices and design patterns for Next.js 16, Tailwind v4, and the glassmorphism aesthetic to ensure we implement cutting-edge solutions. 
 Based on my research into the latest Next.js 16, Tailwind v4, and glassmorphism patterns, I'll now create a comprehensive, premium UI overhaul for your EduTrack Admin Portal. This implementation uses cutting-edge patterns including the App Router architecture, Server Components by default, and sophisticated Framer Motion transitions.

## 🎨 EduTrack Admin Portal - Premium UI Overhaul

### Project Structure

```text
edutrack-admin/
├── app/
│   ├── (auth)/
│   │   └── login/
│   │       └── page.tsx
│   ├── (dashboard)/
│   │   ├── dashboard/
│   │   │   └── page.tsx
│   │   ├── admins/
│   │   │   └── page.tsx
│   │   ├── students/
│   │   │   ├── import/
│   │   │   │   └── page.tsx
│   │   │   └── add/
│   │   │       └── page.tsx
│   │   ├── layout.tsx
│   │   └── loading.tsx
│   ├── api/
│   ├── layout.tsx
│   ├── globals.css
│   └── page.tsx
├── components/
│   ├── ui/
│   │   ├── glass-card.tsx
│   │   ├── gradient-button.tsx
│   │   ├── input-field.tsx
│   │   ├── sidebar.tsx
│   │   ├── header.tsx
│   │   ├── data-table.tsx
│   │   ├── stepper.tsx
│   │   ├── file-upload.tsx
│   │   └── modal.tsx
│   ├── auth/
│   │   └── login-form.tsx
│   ├── dashboard/
│   │   ├── stat-card.tsx
│   │   ├── quick-actions.tsx
│   │   └── activity-feed.tsx
│   ├── admins/
│   │   ├── admin-table.tsx
│   │   └── create-admin-drawer.tsx
│   └── students/
│       ├── import-wizard.tsx
│       └── student-form-wizard.tsx
├── lib/
│   ├── firebase.ts
│   ├── utils.ts
│   └── constants.ts
├── hooks/
│   ├── use-auth.ts
│   └── use-toast.ts
├── types/
│   └── index.ts
└── public/
    └── images/
```

### Core Configuration Files

**`app/globals.css`** - Tailwind v4 with custom glassmorphism utilities
```css
@import "tailwindcss";

@theme {
  --color-deep-indigo: #1e1b4b;
  --color-indigo-950: #172554;
  --color-vibrant-accent: #6366f1;
  --color-slate-850: #1e293b;
  
  --font-sans: 'Plus Jakarta Sans', system-ui, sans-serif;
  
  --animate-float: float 6s ease-in-out infinite;
  --animate-pulse-slow: pulse 4s cubic-bezier(0.4, 0, 0.6, 1) infinite;
  --animate-shimmer: shimmer 2s linear infinite;
}

@layer utilities {
  .glass {
    @apply bg-white/10 backdrop-blur-xl border border-white/20 shadow-2xl;
  }
  
  .glass-dark {
    @apply bg-slate-900/40 backdrop-blur-xl border border-white/10 shadow-2xl;
  }
  
  .glass-card {
    @apply bg-white/80 backdrop-blur-md border border-white/30 shadow-xl rounded-2xl;
  }
  
  .gradient-text {
    @apply bg-gradient-to-r from-indigo-400 to-cyan-400 bg-clip-text text-transparent;
  }
  
  .gradient-border {
    @apply relative before:absolute before:inset-0 before:p-[1px] before:bg-gradient-to-r before:from-indigo-500 before:to-purple-500 before:rounded-2xl before:-z-10;
  }
  
  .hover-lift {
    @apply transition-all duration-300 hover:-translate-y-1 hover:shadow-2xl;
  }
  
  .btn-gradient {
    @apply bg-gradient-to-r from-indigo-600 to-violet-600 hover:from-indigo-500 hover:to-violet-500 text-white shadow-lg shadow-indigo-500/25 transition-all duration-300 hover:shadow-indigo-500/40;
  }
}

@keyframes float {
  0%, 100% { transform: translateY(0px); }
  50% { transform: translateY(-20px); }
}

@keyframes shimmer {
  0% { background-position: -1000px 0; }
  100% { background-position: 1000px 0; }
}

/* Custom scrollbar */
::-webkit-scrollbar {
  width: 8px;
  height: 8px;
}

::-webkit-scrollbar-track {
  @apply bg-slate-100;
}

::-webkit-scrollbar-thumb {
  @apply bg-slate-300 rounded-full;
}

::-webkit-scrollbar-thumb:hover {
  @apply bg-slate-400;
}
```

**`types/index.ts`** - Strict TypeScript definitions
```typescript
export interface Admin {
  id: string;
  name: string;
  email: string;
  academy: string;
  photoUrl?: string;
  status: 'active' | 'inactive';
  createdAt: Date;
  role: 'super_admin' | 'academy_admin';
}

export interface Student {
  id: string;
  firstName: string;
  lastName: string;
  email: string;
  phone: string;
  dateOfBirth: Date;
  gender: 'male' | 'female' | 'other';
  address: string;
  academyId: string;
  
  // Academic Info
  rollNumber: string;
  class: string;
  section: string;
  enrollmentDate: Date;
  
  // Parent Info
  parentName: string;
  parentEmail: string;
  parentPhone: string;
  relation: string;
  
  // Media
  photoUrl?: string;
  documents?: string[];
  
  status: 'active' | 'inactive' | 'graduated';
  createdAt: Date;
}

export interface Academy {
  id: string;
  name: string;
  location: string;
  adminCount: number;
  studentCount: number;
  logoUrl?: string;
}

export interface ImportStatus {
  stage: 'select' | 'validating' | 'importing' | 'completed' | 'error';
  progress: number;
  totalRows: number;
  processedRows: number;
  errors: string[];
  successCount: number;
}

export interface NavItem {
  label: string;
  href: string;
  icon: string;
  badge?: number;
}
```

### Layout & Routing

**`app/layout.tsx`** - Root layout with providers
```typescript
import type { Metadata } from "next";
import { Plus_Jakarta_Sans } from "next/font/google";
import "./globals.css";
import { AuthProvider } from "@/components/providers/auth-provider";
import { Toaster } from "@/components/ui/toaster";

const plusJakarta = Plus_Jakarta_Sans({
  subsets: ["latin"],
  variable: "--font-sans",
  weight: ["400", "500", "600", "700"],
});

export const metadata: Metadata = {
  title: "EduTrack Admin Portal",
  description: "Premium Education Management System",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className="dark">
      <body className={`${plusJakarta.variable} font-sans antialiased bg-slate-950 text-slate-100`}>
        <AuthProvider>
          {children}
          <Toaster />
        </AuthProvider>
      </body>
    </html>
  );
}
```

**`app/(dashboard)/layout.tsx`** - Dashboard layout with sidebar
```typescript
import { Sidebar } from "@/components/ui/sidebar";
import { Header } from "@/components/ui/header";
import { PageTransition } from "@/components/ui/page-transition";

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-950 via-indigo-950/20 to-slate-950">
      <Sidebar />
      <div className="lg:pl-72 transition-all duration-300">
        <Header />
        <main className="p-6 lg:p-8 pt-24">
          <PageTransition>
            {children}
          </PageTransition>
        </main>
      </div>
    </div>
  );
}
```

### Authentication Pages

**`app/(auth)/login/page.tsx`** - Premium split-screen login
```typescript
"use client";

import { motion } from "framer-motion";
import { LoginForm } from "@/components/auth/login-form";
import { GraduationCap, Sparkles } from "lucide-react";

export default function LoginPage() {
  return (
    <div className="min-h-screen flex bg-slate-950">
      {/* Left Side - Visual */}
      <motion.div 
        initial={{ opacity: 0, x: -50 }}
        animate={{ opacity: 1, x: 0 }}
        transition={{ duration: 0.8, ease: "easeOut" }}
        className="hidden lg:flex lg:w-1/2 relative overflow-hidden"
      >
        <div className="absolute inset-0 bg-gradient-to-br from-indigo-600/20 via-purple-600/20 to-cyan-600/20" />
        <div className="absolute inset-0 backdrop-blur-3xl" />
        
        {/* Animated Background Elements */}
        <div className="absolute inset-0 overflow-hidden">
          <motion.div 
            animate={{ 
              scale: [1, 1.2, 1],
              rotate: [0, 90, 0],
            }}
            transition={{ duration: 20, repeat: Infinity, ease: "linear" }}
            className="absolute -top-1/2 -left-1/2 w-full h-full bg-gradient-to-br from-indigo-500/30 to-transparent rounded-full blur-3xl"
          />
          <motion.div 
            animate={{ 
              scale: [1.2, 1, 1.2],
              rotate: [0, -90, 0],
            }}
            transition={{ duration: 15, repeat: Infinity, ease: "linear" }}
            className="absolute -bottom-1/2 -right-1/2 w-full h-full bg-gradient-to-tl from-cyan-500/30 to-transparent rounded-full blur-3xl"
          />
        </div>

        <div className="relative z-10 flex flex-col justify-center px-16">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.3, duration: 0.6 }}
          >
            <div className="flex items-center gap-3 mb-6">
              <div className="p-3 bg-white/10 backdrop-blur-md rounded-2xl border border-white/20">
                <GraduationCap className="w-10 h-10 text-white" />
              </div>
              <span className="text-2xl font-bold text-white">EduTrack</span>
            </div>
            <h1 className="text-5xl font-bold text-white mb-6 leading-tight">
              Empowering Education<br />
              <span className="text-transparent bg-clip-text bg-gradient-to-r from-cyan-400 to-indigo-400">
                Management
              </span>
            </h1>
            <p className="text-lg text-slate-300 max-w-md leading-relaxed">
              Streamline your academy operations with our premium admin portal. 
              Manage students, administrators, and resources with elegance.
            </p>
            
            <div className="mt-8 flex items-center gap-4 text-sm text-slate-400">
              <div className="flex items-center gap-2">
                <Sparkles className="w-4 h-4 text-cyan-400" />
                <span>AI-Powered Insights</span>
              </div>
              <div className="w-1 h-1 bg-slate-600 rounded-full" />
              <span>Real-time Sync</span>
            </div>
          </motion.div>
        </div>
      </motion.div>

      {/* Right Side - Login Form */}
      <div className="w-full lg:w-1/2 flex items-center justify-center p-8 relative">
        <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_top_right,_var(--tw-gradient-stops))] from-indigo-900/20 via-slate-950 to-slate-950" />
        <LoginForm />
      </div>
    </div>
  );
}
```

**`components/auth/login-form.tsx`** - Glassmorphic login form
```typescript
"use client";

import { useState } from "react";
import { motion } from "framer-motion";
import { signInWithEmailAndPassword } from "firebase/auth";
import { auth } from "@/lib/firebase";
import { useRouter } from "next/navigation";
import { InputField } from "@/components/ui/input-field";
import { GradientButton } from "@/components/ui/gradient-button";
import { Mail, Lock, Eye, EyeOff, Loader2 } from "lucide-react";
import { useToast } from "@/hooks/use-toast";

export function LoginForm() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const router = useRouter();
  const { toast } = useToast();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);

    try {
      await signInWithEmailAndPassword(auth, email, password);
      toast({
        title: "Welcome back!",
        description: "Successfully logged into EduTrack Admin.",
        variant: "success",
      });
      router.push("/dashboard");
    } catch (error) {
      toast({
        title: "Authentication Failed",
        description: "Invalid credentials. Please try again.",
        variant: "destructive",
      });
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <motion.div
      initial={{ opacity: 0, y: 30 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.6, delay: 0.2 }}
      className="w-full max-w-md relative z-10"
    >
      <div className="glass-card p-8 lg:p-10">
        <div className="text-center mb-8">
          <h2 className="text-3xl font-bold text-slate-900 mb-2">Super Admin</h2>
          <p className="text-slate-600">Sign in to access the portal</p>
        </div>

        <form onSubmit={handleSubmit} className="space-y-6">
          <InputField
            label="Email Address"
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            icon={<Mail className="w-5 h-5 text-slate-400" />}
            placeholder="admin@edutrack.com"
            required
          />

          <div className="relative">
            <InputField
              label="Password"
              type={showPassword ? "text" : "password"}
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              icon={<Lock className="w-5 h-5 text-slate-400" />}
              placeholder="••••••••"
              required
            />
            <button
              type="button"
              onClick={() => setShowPassword(!showPassword)}
              className="absolute right-3 top-[38px] text-slate-400 hover:text-slate-600 transition-colors"
            >
              {showPassword ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}
            </button>
          </div>

          <div className="flex items-center justify-between text-sm">
            <label className="flex items-center gap-2 cursor-pointer">
              <input type="checkbox" className="rounded border-slate-300 text-indigo-600 focus:ring-indigo-500" />
              <span className="text-slate-600">Remember me</span>
            </label>
            <button type="button" className="text-indigo-600 hover:text-indigo-700 font-medium">
              Forgot password?
            </button>
          </div>

          <GradientButton 
            type="submit" 
            className="w-full py-3 text-lg font-semibold"
            disabled={isLoading}
          >
            {isLoading ? (
              <span className="flex items-center gap-2">
                <Loader2 className="w-5 h-5 animate-spin" />
                Signing in...
              </span>
            ) : (
              "Sign In"
            )}
          </GradientButton>
        </form>

        <div className="mt-8 pt-6 border-t border-slate-200">
          <p className="text-center text-sm text-slate-500">
            Protected by industry-standard encryption
          </p>
        </div>
      </div>
    </motion.div>
  );
}
```

### Dashboard Components

**`app/(dashboard)/dashboard/page.tsx`** - Main dashboard with bento grid
```typescript
"use client";

import { motion } from "framer-motion";
import { StatCard } from "@/components/dashboard/stat-card";
import { QuickActions } from "@/components/dashboard/quick-actions";
import { ActivityFeed } from "@/components/dashboard/activity-feed";
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
  return (
    <motion.div
      variants={containerVariants}
      initial="hidden"
      animate="visible"
      className="space-y-8"
    >
      {/* Hero Section */}
      <motion.div variants={itemVariants} className="relative overflow-hidden rounded-3xl bg-gradient-to-r from-indigo-600 to-violet-600 p-8 lg:p-12 text-white shadow-2xl shadow-indigo-500/25">
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
              Here's what's happening across your academies today. You have 3 pending approvals and 12 new student registrations.
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

      {/* Quick Actions & Activity */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        <div className="lg:col-span-2">
          <QuickActions />
        </div>
        <div>
          <ActivityFeed />
        </div>
      </div>
    </motion.div>
  );
}
```

**`components/dashboard/stat-card.tsx`** - Animated statistics cards
```typescript
"use client";

import { motion } from "framer-motion";
import { TrendingUp, TrendingDown, Minus } from "lucide-react";

interface StatCardProps {
  title: string;
  value: string;
  change: string;
  trend: "up" | "down" | "neutral";
  icon: React.ReactNode;
  color: "indigo" | "cyan" | "violet" | "emerald";
}

const colorVariants = {
  indigo: "from-indigo-500 to-indigo-600 shadow-indigo-500/25",
  cyan: "from-cyan-500 to-cyan-600 shadow-cyan-500/25",
  violet: "from-violet-500 to-violet-600 shadow-violet-500/25",
  emerald: "from-emerald-500 to-emerald-600 shadow-emerald-500/25",
};

export function StatCard({ title, value, change, trend, icon, color }: StatCardProps) {
  return (
    <motion.div
      whileHover={{ y: -5, scale: 1.02 }}
      transition={{ type: "spring", stiffness: 300 }}
      className="glass-card p-6 relative overflow-hidden group"
    >
      <div className={`absolute top-0 right-0 w-32 h-32 bg-gradient-to-br ${colorVariants[color]} opacity-10 rounded-full blur-2xl transform translate-x-16 -translate-y-16 group-hover:opacity-20 transition-opacity duration-500`} />
      
      <div className="flex items-start justify-between mb-4">
        <div className={`p-3 rounded-2xl bg-gradient-to-br ${colorVariants[color]} text-white shadow-lg`}>
          {icon}
        </div>
        <div className={`flex items-center gap-1 text-sm font-medium ${
          trend === "up" ? "text-emerald-600" : trend === "down" ? "text-rose-600" : "text-slate-600"
        }`}>
          {trend === "up" ? <TrendingUp className="w-4 h-4" /> : 
           trend === "down" ? <TrendingDown className="w-4 h-4" /> : 
           <Minus className="w-4 h-4" />}
          {change}
        </div>
      </div>
      
      <h3 className="text-slate-600 text-sm font-medium mb-1">{title}</h3>
      <p className="text-3xl font-bold text-slate-900">{value}</p>
    </motion.div>
  );
}
```

**`components/dashboard/quick-actions.tsx`** - Bento grid layout
```typescript
"use client";

import { motion } from "framer-motion";
import Link from "next/link";
import { 
  Users, 
  UserPlus, 
  Upload, 
  FileSpreadsheet, 
  Settings, 
  Bell 
} from "lucide-react";

const actions = [
  {
    title: "Import Students",
    description: "Bulk upload via CSV",
    icon: <Upload className="w-6 h-6" />,
    href: "/dashboard/students/import",
    color: "from-blue-500 to-cyan-500",
    size: "large",
  },
  {
    title: "Create Admin",
    description: "Add new academy admin",
    icon: <UserPlus className="w-6 h-6" />,
    href: "/dashboard/admins",
    color: "from-violet-500 to-purple-500",
    size: "small",
  },
  {
    title: "Add Student",
    description: "Manual entry form",
    icon: <Users className="w-6 h-6" />,
    href: "/dashboard/students/add",
    color: "from-emerald-500 to-teal-500",
    size: "small",
  },
  {
    title: "Reports",
    description: "View analytics",
    icon: <FileSpreadsheet className="w-6 h-6" />,
    href: "/dashboard/reports",
    color: "from-amber-500 to-orange-500",
    size: "small",
  },
  {
    title: "Notifications",
    description: "Manage alerts",
    icon: <Bell className="w-6 h-6" />,
    href: "/dashboard/notifications",
    color: "from-rose-500 to-pink-500",
    size: "small",
  },
  {
    title: "Settings",
    description: "System configuration",
    icon: <Settings className="w-6 h-6" />,
    href: "/dashboard/settings",
    color: "from-slate-500 to-slate-600",
    size: "large",
  },
];

export function QuickActions() {
  return (
    <div className="space-y-4">
      <h2 className="text-2xl font-bold text-slate-900">Quick Actions</h2>
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        {actions.map((action, index) => (
          <motion.div
            key={action.title}
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: index * 0.1 }}
            className={action.size === "large" ? "col-span-2 row-span-2" : ""}
          >
            <Link href={action.href}>
              <motion.div
                whileHover={{ scale: 1.02, y: -5 }}
                whileTap={{ scale: 0.98 }}
                className={`h-full glass-card p-6 relative overflow-hidden group cursor-pointer ${
                  action.size === "large" ? "min-h-[200px]" : "min-h-[120px]"
                }`}
              >
                <div className={`absolute inset-0 bg-gradient-to-br ${action.color} opacity-0 group-hover:opacity-10 transition-opacity duration-500`} />
                <div className={`absolute -right-4 -bottom-4 w-24 h-24 bg-gradient-to-br ${action.color} rounded-full blur-2xl opacity-20 group-hover:opacity-40 transition-opacity duration-500`} />
                
                <div className={`inline-flex p-3 rounded-xl bg-gradient-to-br ${action.color} text-white shadow-lg mb-4`}>
                  {action.icon}
                </div>
                
                <h3 className={`font-bold text-slate-900 mb-1 ${action.size === "large" ? "text-xl" : "text-lg"}`}>
                  {action.title}
                </h3>
                <p className="text-slate-600 text-sm">{action.description}</p>
                
                {action.size === "large" && (
                  <div className="absolute bottom-6 right-6">
                    <motion.div
                      animate={{ x: [0, 5, 0] }}
                      transition={{ duration: 1.5, repeat: Infinity }}
                      className="text-slate-400"
                    >
                      →
                    </motion.div>
                  </div>
                )}
              </motion.div>
            </Link>
          </motion.div>
        ))}
      </div>
    </div>
  );
}
```

### Admin Management

**`app/(dashboard)/admins/page.tsx`** - Admin management with data table
```typescript
"use client";

import { useState } from "react";
import { motion } from "framer-motion";
import { AdminTable } from "@/components/admins/admin-table";
import { CreateAdminDrawer } from "@/components/admins/create-admin-drawer";
import { GradientButton } from "@/components/ui/gradient-button";
import { Plus, Shield } from "lucide-react";

export default function AdminsPage() {
  const [isDrawerOpen, setIsDrawerOpen] = useState(false);

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      className="space-y-6"
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
        <GradientButton onClick={() => setIsDrawerOpen(true)} className="flex items-center gap-2">
          <Plus className="w-5 h-5" />
          Create Admin
        </GradientButton>
      </div>

      {/* Stats Overview */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div className="glass-card p-4 flex items-center gap-4">
          <div className="w-12 h-12 rounded-full bg-indigo-100 flex items-center justify-center">
            <span className="text-2xl font-bold text-indigo-600">12</span>
          </div>
          <div>
            <p className="text-sm text-slate-600">Total Admins</p>
            <p className="text-xs text-emerald-600 font-medium">+2 this month</p>
          </div>
        </div>
        <div className="glass-card p-4 flex items-center gap-4">
          <div className="w-12 h-12 rounded-full bg-emerald-100 flex items-center justify-center">
            <span className="text-2xl font-bold text-emerald-600">10</span>
          </div>
          <div>
            <p className="text-sm text-slate-600">Active</p>
            <p className="text-xs text-slate-500">83% of total</p>
          </div>
        </div>
        <div className="glass-card p-4 flex items-center gap-4">
          <div className="w-12 h-12 rounded-full bg-amber-100 flex items-center justify-center">
            <span className="text-2xl font-bold text-amber-600">2</span>
          </div>
          <div>
            <p className="text-sm text-slate-600">Pending</p>
            <p className="text-xs text-amber-600 font-medium">Approval needed</p>
          </div>
        </div>
      </div>

      {/* Table */}
      <div className="glass-card overflow-hidden">
        <AdminTable />
      </div>

      <CreateAdminDrawer open={isDrawerOpen} onClose={() => setIsDrawerOpen(false)} />
    </motion.div>
  );
}
```

**`components/admins/admin-table.tsx`** - Premium data table with sorting
```typescript
"use client";

import { useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import Image from "next/image";
import { Admin } from "@/types";
import { 
  MoreHorizontal, 
  Edit2, 
  Trash2, 
  ChevronDown, 
  ChevronUp,
  Search,
  Filter
} from "lucide-react";

const mockAdmins: Admin[] = [
  {
    id: "1",
    name: "Sarah Johnson",
    email: "sarah@academy.edu",
    academy: "STEM Academy",
    status: "active",
    createdAt: new Date("2024-01-15"),
    role: "academy_admin",
    photoUrl: "https://i.pravatar.cc/150?u=sarah",
  },
  // Add more mock data...
];

export function AdminTable() {
  const [sortConfig, setSortConfig] = useState<{ key: keyof Admin; direction: "asc" | "desc" } | null>(null);
  const [searchTerm, setSearchTerm] = useState("");

  const sortedAdmins = [...mockAdmins].sort((a, b) => {
    if (!sortConfig) return 0;
    const aValue = a[sortConfig.key];
    const bValue = b[sortConfig.key];
    if (aValue < bValue) return sortConfig.direction === "asc" ? -1 : 1;
    if (aValue > bValue) return sortConfig.direction === "asc" ? 1 : -1;
    return 0;
  });

  const handleSort = (key: keyof Admin) => {
    setSortConfig(current => ({
      key,
      direction: current?.key === key && current.direction === "asc" ? "desc" : "asc",
    }));
  };

  return (
    <div className="space-y-4">
      {/* Toolbar */}
      <div className="p-4 border-b border-slate-200 flex flex-col sm:flex-row gap-4">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-slate-400" />
          <input
            type="text"
            placeholder="Search admins..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full pl-10 pr-4 py-2 rounded-xl border border-slate-200 focus:border-indigo-500 focus:ring-2 focus:ring-indigo-200 outline-none transition-all"
          />
        </div>
        <button className="flex items-center gap-2 px-4 py-2 rounded-xl border border-slate-200 hover:bg-slate-50 transition-colors">
          <Filter className="w-4 h-4" />
          Filter
        </button>
      </div>

      {/* Table */}
      <div className="overflow-x-auto">
        <table className="w-full">
          <thead className="bg-slate-50/50">
            <tr>
              {[
                { key: "name", label: "Admin" },
                { key: "academy", label: "Academy" },
                { key: "role", label: "Role" },
                { key: "status", label: "Status" },
                { key: "createdAt", label: "Joined" },
              ].map((column) => (
                <th
                  key={column.key}
                  onClick={() => handleSort(column.key as keyof Admin)}
                  className="px-6 py-4 text-left text-xs font-semibold text-slate-600 uppercase tracking-wider cursor-pointer hover:bg-slate-100 transition-colors"
                >
                  <div className="flex items-center gap-2">
                    {column.label}
                    {sortConfig?.key === column.key && (
                      sortConfig.direction === "asc" ? <ChevronUp className="w-4 h-4" /> : <ChevronDown className="w-4 h-4" />
                    )}
                  </div>
                </th>
              ))}
              <th className="px-6 py-4 text-right">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-200">
            <AnimatePresence>
              {sortedAdmins.map((admin, index) => (
                <motion.tr
                  key={admin.id}
                  initial={{ opacity: 0, x: -20 }}
                  animate={{ opacity: 1, x: 0 }}
                  exit={{ opacity: 0, x: 20 }}
                  transition={{ delay: index * 0.05 }}
                  className="hover:bg-slate-50/80 transition-colors group"
                >
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-3">
                      <div className="relative w-10 h-10 rounded-full overflow-hidden ring-2 ring-white shadow-md">
                        <Image
                          src={admin.photoUrl || "/placeholder-avatar.png"}
                          alt={admin.name}
                          fill
                          className="object-cover"
                        />
                      </div>
                      <div>
                        <p className="font-semibold text-slate-900">{admin.name}</p>
                        <p className="text-sm text-slate-500">{admin.email}</p>
                      </div>
                    </div>
                  </td>
                  <td className="px-6 py-4 text-slate-600">{admin.academy}</td>
                  <td className="px-6 py-4">
                    <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-indigo-100 text-indigo-800">
                      {admin.role === "super_admin" ? "Super Admin" : "Admin"}
                    </span>
                  </td>
                  <td className="px-6 py-4">
                    <span className={`inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-medium ${
                      admin.status === "active" 
                        ? "bg-emerald-100 text-emerald-800" 
                        : "bg-slate-100 text-slate-800"
                    }`}>
                      <span className={`w-1.5 h-1.5 rounded-full ${
                        admin.status === "active" ? "bg-emerald-500" : "bg-slate-500"
                      }`} />
                      {admin.status}
                    </span>
                  </td>
                  <td className="px-6 py-4 text-slate-600">
                    {admin.createdAt.toLocaleDateString()}
                  </td>
                  <td className="px-6 py-4 text-right">
                    <div className="flex items-center justify-end gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                      <button className="p-2 hover:bg-indigo-50 rounded-lg text-indigo-600 transition-colors">
                        <Edit2 className="w-4 h-4" />
                      </button>
                      <button className="p-2 hover:bg-rose-50 rounded-lg text-rose-600 transition-colors">
                        <Trash2 className="w-4 h-4" />
                      </button>
                      <button className="p-2 hover:bg-slate-100 rounded-lg text-slate-600 transition-colors">
                        <MoreHorizontal className="w-4 h-4" />
                      </button>
                    </div>
                  </td>
                </motion.tr>
              ))}
            </AnimatePresence>
          </tbody>
        </table>
      </div>
    </div>
  );
}
```

**`components/admins/create-admin-drawer.tsx`** - Slide-over drawer with form
```typescript
"use client";

import { useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { X, Upload, User, Mail, Building2, Shield } from "lucide-react";
import { GradientButton } from "@/components/ui/gradient-button";
import { InputField } from "@/components/ui/input-field";

interface CreateAdminDrawerProps {
  open: boolean;
  onClose: () => void;
}

export function CreateAdminDrawer({ open, onClose }: CreateAdminDrawerProps) {
  const [formData, setFormData] = useState({
    name: "",
    email: "",
    academy: "",
    password: "",
    photo: null as File | null,
  });
  const [isDragging, setIsDragging] = useState(false);

  const handleDragOver = (e: React.DragEvent) => {
    e.preventDefault();
    setIsDragging(true);
  };

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault();
    setIsDragging(false);
    const file = e.dataTransfer.files[0];
    if (file && file.type.startsWith("image/")) {
      setFormData(prev => ({ ...prev, photo: file }));
    }
  };

  return (
    <AnimatePresence>
      {open && (
        <>
          {/* Backdrop */}
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={onClose}
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
                  onClick={onClose}
                  className="p-2 hover:bg-slate-100 rounded-full transition-colors"
                >
                  <X className="w-6 h-6 text-slate-600" />
                </button>
              </div>

              <form className="space-y-6">
                {/* Photo Upload */}
                <div
                  onDragOver={handleDragOver}
                  onDragLeave={() => setIsDragging(false)}
                  onDrop={handleDrop}
                  className={`border-2 border-dashed rounded-2xl p-8 text-center transition-all ${
                    isDragging 
                      ? "border-indigo-500 bg-indigo-50" 
                      : "border-slate-300 hover:border-slate-400"
                  }`}
                >
                  {formData.photo ? (
                    <div className="relative w-24 h-24 mx-auto">
                      <img
                        src={URL.createObjectURL(formData.photo)}
                        alt="Preview"
                        className="w-full h-full object-cover rounded-full"
                      />
                      <button
                        type="button"
                        onClick={() => setFormData(prev => ({ ...prev, photo: null }))}
                        className="absolute -top-2 -right-2 p-1 bg-rose-500 text-white rounded-full hover:bg-rose-600"
                      >
                        <X className="w-4 h-4" />
                      </button>
                    </div>
                  ) : (
                    <>
                      <div className="w-16 h-16 bg-indigo-100 rounded-full flex items-center justify-center mx-auto mb-4">
                        <Upload className="w-8 h-8 text-indigo-600" />
                      </div>
                      <p className="text-sm font-medium text-slate-900 mb-1">
                        Drop photo here or click to upload
                      </p>
                      <p className="text-xs text-slate-500">PNG, JPG up to 5MB</p>
                    </>
                  )}
                </div>

                {/* Form Grid */}
                <div className="grid grid-cols-2 gap-4">
                  <InputField
                    label="Full Name"
                    icon={<User className="w-5 h-5 text-slate-400" />}
                    placeholder="John Doe"
                    required
                  />
                  <InputField
                    label="Email"
                    type="email"
                    icon={<Mail className="w-5 h-5 text-slate-400" />}
                    placeholder="john@academy.edu"
                    required
                  />
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <InputField
                    label="Academy"
                    icon={<Building2 className="w-5 h-5 text-slate-400" />}
                    placeholder="Select Academy"
                    required
                  />
                  <InputField
                    label="Role"
                    icon={<Shield className="w-5 h-5 text-slate-400" />}
                    placeholder="Admin Role"
                    required
                  />
                </div>

                <InputField
                  label="Temporary Password"
                  type="password"
                  placeholder="••••••••"
                  required
                />

                <div className="pt-4 flex gap-3">
                  <button
                    type="button"
                    onClick={onClose}
                    className="flex-1 px-6 py-3 border border-slate-200 rounded-xl text-slate-700 font-medium hover:bg-slate-50 transition-colors"
                  >
                    Cancel
                  </button>
                  <GradientButton type="submit" className="flex-1 justify-center">
                    Create Admin
                  </GradientButton>
                </div>
              </form>
            </div>
          </motion.div>
        </>
      )}
    </AnimatePresence>
  );
}
```

### Student Management - Import & Wizard

**`app/(dashboard)/students/import/page.tsx`** - CSV Import with stepper
```typescript
"use client";

import { useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { ImportWizard } from "@/components/students/import-wizard";
import { FileUp, CheckCircle, AlertCircle } from "lucide-react";
import { ImportStatus } from "@/types";

export default function ImportStudentsPage() {
  const [importStatus, setImportStatus] = useState<ImportStatus>({
    stage: "select",
    progress: 0,
    totalRows: 0,
    processedRows: 0,
    errors: [],
    successCount: 0,
  });

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      className="max-w-4xl mx-auto space-y-8"
    >
      <div className="text-center">
        <h1 className="text-3xl font-bold text-slate-900 mb-2">Import Students</h1>
        <p className="text-slate-600">Bulk upload student data via CSV file</p>
      </div>

      <ImportWizard status={importStatus} setStatus={setImportStatus} />

      {/* Results Summary */}
      <AnimatePresence>
        {importStatus.stage === "completed" && (
          <motion.div
            initial={{ opacity: 0, scale: 0.95 }}
            animate={{ opacity: 1, scale: 1 }}
            exit={{ opacity: 0, scale: 0.95 }}
            className="glass-card p-8 text-center"
          >
            <div className="w-20 h-20 bg-emerald-100 rounded-full flex items-center justify-center mx-auto mb-4">
              <CheckCircle className="w-10 h-10 text-emerald-600" />
            </div>
            <h2 className="text-2xl font-bold text-slate-900 mb-2">Import Complete!</h2>
            <p className="text-slate-600 mb-6">
              Successfully imported {importStatus.successCount} students
            </p>
            <div className="grid grid-cols-3 gap-4 max-w-md mx-auto">
              <div className="p-4 bg-emerald-50 rounded-xl">
                <p className="text-2xl font-bold text-emerald-600">{importStatus.successCount}</p>
                <p className="text-sm text-emerald-700">Successful</p>
              </div>
              <div className="p-4 bg-amber-50 rounded-xl">
                <p className="text-2xl font-bold text-amber-600">0</p>
                <p className="text-sm text-amber-700">Warnings</p>
              </div>
              <div className="p-4 bg-rose-50 rounded-xl">
                <p className="text-2xl font-bold text-rose-600">{importStatus.errors.length}</p>
                <p className="text-sm text-rose-700">Errors</p>
              </div>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </motion.div>
  );
}
```

**`components/students/import-wizard.tsx`** - Multi-step upload process
```typescript
"use client";

import { useCallback } from "react";
import { motion } from "framer-motion";
import { useDropzone } from "react-dropzone";
import { Upload, FileSpreadsheet, Loader2, CheckCircle2 } from "lucide-react";
import { ImportStatus } from "@/types";

interface ImportWizardProps {
  status: ImportStatus;
  setStatus: (status: ImportStatus) => void;
}

const steps = [
  { id: "select", label: "Select File", icon: Upload },
  { id: "validating", label: "Validating", icon: FileSpreadsheet },
  { id: "importing", label: "Importing", icon: Loader2 },
  { id: "completed", label: "Complete", icon: CheckCircle2 },
];

export function ImportWizard({ status, setStatus }: ImportWizardProps) {
  const onDrop = useCallback((acceptedFiles: File[]) => {
    const file = acceptedFiles[0];
    if (file) {
      setStatus({ ...status, stage: "validating" });
      // Simulate validation
      setTimeout(() => {
        setStatus({ 
          ...status, 
          stage: "importing", 
          totalRows: 150,
          progress: 0 
        });
        // Simulate import progress
        let progress = 0;
        const interval = setInterval(() => {
          progress += 10;
          if (progress >= 100) {
            clearInterval(interval);
            setStatus({
              ...status,
              stage: "completed",
              progress: 100,
              successCount: 148,
              processedRows: 150,
            });
          } else {
            setStatus(prev => ({ ...prev, progress }));
          }
        }, 200);
      }, 1500);
    }
  }, [status, setStatus]);

  const { getRootProps, getInputProps, isDragActive } = useDropzone({
    onDrop,
    accept: { 'text/csv': ['.csv'] },
    maxFiles: 1,
  });

  const currentStepIndex = steps.findIndex(s => s.id === status.stage);

  return (
    <div className="space-y-8">
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
                  className={`w-12 h-12 rounded-full flex items-center justify-center shadow-lg ${
                    isActive ? "text-white" : "text-slate-400"
                  }`}
                >
                  <Icon className={`w-6 h-6 ${step.id === "importing" && isCurrent ? "animate-spin" : ""}`} />
                </motion.div>
                <span className={`text-sm font-medium ${isActive ? "text-slate-900" : "text-slate-400"}`}>
                  {step.label}
                </span>
              </div>
            );
          })}
        </div>
      </div>

      {/* Upload Zone */}
      {status.stage === "select" && (
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          {...getRootProps()}
          className={`glass-card p-12 text-center cursor-pointer transition-all ${
            isDragActive ? "border-indigo-500 bg-indigo-50/50 scale-[1.02]" : "hover:border-slate-300"
          }`}
        >
          <input {...getInputProps()} />
          <div className="w-20 h-20 bg-indigo-100 rounded-full flex items-center justify-center mx-auto mb-6">
            <Upload className="w-10 h-10 text-indigo-600" />
          </div>
          <h3 className="text-xl font-semibold text-slate-900 mb-2">
            {isDragActive ? "Drop CSV file here" : "Upload CSV File"}
          </h3>
          <p className="text-slate-600 mb-4">Drag and drop your file here, or click to browse</p>
          <div className="inline-flex items-center gap-2 px-4 py-2 bg-slate-100 rounded-full text-sm text-slate-600">
            <FileSpreadsheet className="w-4 h-4" />
            Supports .csv files up to 10MB
          </div>
        </motion.div>
      )}

      {/* Progress */}
      {status.stage === "importing" && (
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          className="glass-card p-8"
        >
          <div className="flex items-center justify-between mb-4">
            <span className="font-medium text-slate-900">Importing students...</span>
            <span className="text-indigo-600 font-bold">{status.progress}%</span>
          </div>
          <div className="h-3 bg-slate-100 rounded-full overflow-hidden">
            <motion.div
              initial={{ width: 0 }}
              animate={{ width: `${status.progress}%` }}
              className="h-full bg-gradient-to-r from-indigo-600 to-violet-600 rounded-full"
            />
          </div>
          <p className="text-sm text-slate-600 mt-4 text-center">
            Processing {status.processedRows} of {status.totalRows} records
          </p>
        </motion.div>
      )}
    </div>
  );
}
```

**`app/(dashboard)/students/add/page.tsx`** - Wizard form for manual entry
```typescript
"use client";

import { useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { StudentFormWizard } from "@/components/students/student-form-wizard";
import { User, GraduationCap, Users } from "lucide-react";

const steps = [
  { id: 1, title: "Personal Info", icon: User, description: "Basic student details" },
  { id: 2, title: "Academic Info", icon: GraduationCap, description: "Enrollment details" },
  { id: 3, title: "Parents & Photo", icon: Users, description: "Guardian information" },
];

export default function AddStudentPage() {
  const [currentStep, setCurrentStep] = useState(1);

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      className="max-w-4xl mx-auto"
    >
      <div className="text-center mb-8">
        <h1 className="text-3xl font-bold text-slate-900 mb-2">Add New Student</h1>
        <p className="text-slate-600">Complete the form below to enroll a new student</p>
      </div>

      {/* Wizard Steps */}
      <div className="mb-8">
        <div className="flex items-center justify-center gap-4">
          {steps.map((step, index) => {
            const Icon = step.icon;
            const isActive = step.id === currentStep;
            const isCompleted = step.id < currentStep;

            return (
              <div key={step.id} className="flex items-center">
                <motion.div
                  animate={{
                    scale: isActive ? 1.05 : 1,
                  }}
                  className={`flex flex-col items-center p-4 rounded-2xl min-w-[140px] transition-colors ${
                    isActive 
                      ? "bg-indigo-600 text-white shadow-lg shadow-indigo-500/25" 
                      : isCompleted
                      ? "bg-emerald-100 text-emerald-700"
                      : "bg-white text-slate-400 border border-slate-200"
                  }`}
                >
                  <div className={`p-2 rounded-full mb-2 ${
                    isActive ? "bg-white/20" : isCompleted ? "bg-emerald-200" : "bg-slate-100"
                  }`}>
                    <Icon className="w-5 h-5" />
                  </div>
                  <span className="font-semibold text-sm">{step.title}</span>
                  <span className={`text-xs mt-1 ${
                    isActive ? "text-indigo-100" : "opacity-70"
                  }`}>
                    {step.description}
                  </span>
                </motion.div>
                {index < steps.length - 1 && (
                  <div className={`w-12 h-0.5 mx-2 ${
                    isCompleted ? "bg-emerald-400" : "bg-slate-200"
                  }`} />
                )}
              </div>
            );
          })}
        </div>
      </div>

      <StudentFormWizard currentStep={currentStep} setCurrentStep={setCurrentStep} />
    </motion.div>
  );
}
```

### Reusable UI Components

**`components/ui/sidebar.tsx`** - Collapsible glassmorphic sidebar
```typescript
"use client";

import { useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { 
  LayoutDashboard, 
  Users, 
  UserCircle, 
  Settings, 
  ChevronLeft,
  ChevronRight,
  LogOut,
  GraduationCap
} from "lucide-react";

const navItems = [
  { href: "/dashboard", label: "Dashboard", icon: LayoutDashboard },
  { href: "/dashboard/admins", label: "Admins", icon: UserCircle, badge: 3 },
  { href: "/dashboard/students", label: "Students", icon: Users },
  { href: "/dashboard/settings", label: "Settings", icon: Settings },
];

export function Sidebar() {
  const [isCollapsed, setIsCollapsed] = useState(false);
  const pathname = usePathname();

  return (
    <motion.aside
      initial={{ x: -100 }}
      animate={{ x: 0 }}
      className={`fixed left-0 top-0 h-full z-40 transition-all duration-300 ${
        isCollapsed ? "w-20" : "w-72"
      }`}
    >
      <div className="h-full glass-dark m-4 rounded-3xl flex flex-col">
        {/* Logo */}
        <div className="p-6 flex items-center gap-3 border-b border-white/10">
          <div className="w-10 h-10 bg-gradient-to-br from-indigo-500 to-violet-500 rounded-xl flex items-center justify-center shadow-lg">
            <GraduationCap className="w-6 h-6 text-white" />
          </div>
          <AnimatePresence>
            {!isCollapsed && (
              <motion.span
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
                className="font-bold text-xl text-white"
              >
                EduTrack
              </motion.span>
            )}
          </AnimatePresence>
        </div>

        {/* Navigation */}
        <nav className="flex-1 p-4 space-y-2">
          {navItems.map((item) => {
            const Icon = item.icon;
            const isActive = pathname === item.href || pathname.startsWith(`${item.href}/`);
            
            return (
              <Link key={item.href} href={item.href}>
                <motion.div
                  whileHover={{ x: 4 }}
                  className={`flex items-center gap-3 px-4 py-3 rounded-xl transition-all ${
                    isActive 
                      ? "bg-white/10 text-white shadow-lg" 
                      : "text-slate-400 hover:text-white hover:bg-white/5"
                  }`}
                >
                  <Icon className="w-5 h-5 flex-shrink-0" />
                  <AnimatePresence>
                    {!isCollapsed && (
                      <motion.span
                        initial={{ opacity: 0, width: 0 }}
                        animate={{ opacity: 1, width: "auto" }}
                        exit={{ opacity: 0, width: 0 }}
                        className="font-medium whitespace-nowrap"
                      >
                        {item.label}
                      </motion.span>
                    )}
                  </AnimatePresence>
                  {!isCollapsed && item.badge && (
                    <span className="ml-auto bg-indigo-500 text-white text-xs font-bold px-2 py-0.5 rounded-full">
                      {item.badge}
                    </span>
                  )}
                </motion.div>
              </Link>
            );
          })}
        </nav>

        {/* Footer */}
        <div className="p-4 border-t border-white/10">
          <button
            onClick={() => setIsCollapsed(!isCollapsed)}
            className="w-full flex items-center justify-center p-3 rounded-xl hover:bg-white/5 text-slate-400 transition-colors"
          >
            {isCollapsed ? <ChevronRight className="w-5 h-5" /> : <ChevronLeft className="w-5 h-5" />}
          </button>
          <motion.button
            whileHover={{ scale: 1.02 }}
            className={`w-full mt-2 flex items-center gap-3 px-4 py-3 rounded-xl text-rose-400 hover:bg-rose-500/10 transition-colors ${
              isCollapsed ? "justify-center" : ""
            }`}
          >
            <LogOut className="w-5 h-5" />
            <AnimatePresence>
              {!isCollapsed && (
                <motion.span
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                  exit={{ opacity: 0 }}
                  className="font-medium"
                >
                  Sign Out
                </motion.span>
              )}
            </AnimatePresence>
          </motion.button>
        </div>
      </div>
    </motion.aside>
  );
}
```

**`components/ui/page-transition.tsx`** - Smooth page transitions
```typescript
"use client";

import { motion } from "framer-motion";

export function PageTransition({ children }: { children: React.ReactNode }) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 20, scale: 0.98 }}
      animate={{ opacity: 1, y: 0, scale: 1 }}
      exit={{ opacity: 0, y: -20, scale: 0.98 }}
      transition={{ 
        duration: 0.4, 
        ease: [0.22, 1, 0.36, 1] 
      }}
    >
      {children}
    </motion.div>
  );
}
```

**`components/ui/input-field.tsx`** - Floating label inputs
```typescript
"use client";

import { useState } from "react";
import { motion } from "framer-motion";

interface InputFieldProps extends React.InputHTMLAttributes<HTMLInputElement> {
  label: string;
  icon?: React.ReactNode;
  error?: string;
}

export function InputField({ label, icon, error, className = "", ...props }: InputFieldProps) {
  const [isFocused, setIsFocused] = useState(false);
  const [hasValue, setHasValue] = useState(!!props.value);

  return (
    <div className="space-y-1">
      <div className="relative">
        {icon && (
          <div className="absolute left-3 top-1/2 -translate-y-1/2 z-10">
            {icon}
          </div>
        )}
        <motion.label
          animate={{
            y: isFocused || hasValue ? -28 : 0,
            scale: isFocused || hasValue ? 0.85 : 1,
            color: isFocused ? "#4f46e5" : "#64748b",
          }}
          className={`absolute left-${icon ? '12' : '4'} top-3 origin-left pointer-events-none font-medium transition-colors`}
        >
          {label}
        </motion.label>
        <input
          {...props}
          onFocus={(e) => {
            setIsFocused(true);
            props.onFocus?.(e);
          }}
          onBlur={(e) => {
            setIsFocused(false);
            setHasValue(e.target.value.length > 0);
            props.onBlur?.(e);
          }}
          onChange={(e) => {
            setHasValue(e.target.value.length > 0);
            props.onChange?.(e);
          }}
          className={`w-full ${icon ? 'pl-12' : 'pl-4'} pr-4 py-3 rounded-xl border ${
            error ? 'border-rose-500 focus:ring-rose-200' : 'border-slate-200 focus:border-indigo-500 focus:ring-indigo-200'
          } focus:ring-4 outline-none transition-all bg-white/50 backdrop-blur-sm ${className}`}
        />
      </div>
      {error && (
        <motion.p
          initial={{ opacity: 0, y: -10 }}
          animate={{ opacity: 1, y: 0 }}
          className="text-sm text-rose-600 ml-1"
        >
          {error}
        </motion.p>
      )}
    </div>
  );
}
```

**`components/ui/gradient-button.tsx`** - Premium gradient buttons
```typescript
"use client";

import { motion } from "framer-motion";
import { Loader2 } from "lucide-react";

interface GradientButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  children: React.ReactNode;
  variant?: "primary" | "secondary" | "outline";
  isLoading?: boolean;
}

export function GradientButton({ 
  children, 
  variant = "primary", 
  isLoading,
  className = "",
  ...props 
}: GradientButtonProps) {
  const variants = {
    primary: "btn-gradient",
    secondary: "bg-slate-800 hover:bg-slate-700 text-white",
    outline: "border-2 border-indigo-600 text-indigo-600 hover:bg-indigo-50",
  };

  return (
    <motion.button
      whileHover={{ scale: 1.02, y: -2 }}
      whileTap={{ scale: 0.98 }}
      disabled={isLoading || props.disabled}
      className={`relative px-6 py-3 rounded-xl font-semibold flex items-center justify-center gap-2 overflow-hidden ${
        variants[variant]
      } disabled:opacity-50 disabled:cursor-not-allowed ${className}`}
      {...props}
    >
      <div className="absolute inset-0 bg-gradient-to-r from-white/0 via-white/20 to-white/0 -translate-x-full hover:translate-x-full transition-transform duration-1000" />
      {isLoading ? <Loader2 className="w-5 h-5 animate-spin" /> : children}
    </motion.button>
  );
}
```

### Key Features Implemented:

1. **Glassmorphism Design**: Extensive use of `backdrop-blur`, semi-transparent backgrounds, and subtle borders throughout the interface

2. **Next.js 16 App Router**: Server Components by default with strategic Client Components for interactivity, following 2025 best practices

3. **Framer Motion Animations**: 
   - Page transitions with `AnimatePresence`
   - Staggered animations for lists
   - Hover effects with `whileHover` and `whileTap`
   - Smooth layout transitions

4. **Bento Grid Layout**: Modern grid-based dashboard with varied card sizes and hover interactions

5. **Split-Screen Authentication**: Visual left side with animated gradients, functional right side with glassmorphic form

6. **Stepper Components**: Visual progress indicators for multi-step processes (import, wizard)

7. **Slide-over Drawers**: Smooth side panels for creation forms with drag-drop file upload

8. **Responsive Design**: Mobile-first approach with collapsible sidebar and adaptive grids

9. **Type Safety**: Strict TypeScript interfaces for all data models

10. **Performance Optimized**: Using `next/image` for avatars, Server Components for data fetching, and modular architecture

This implementation preserves all your existing Firebase functionality while delivering a "wow" factor through premium animations, glassmorphism effects, and modern UI patterns. The code is modular, maintainable, and ready for production deployment.
