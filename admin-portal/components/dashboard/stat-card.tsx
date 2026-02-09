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
