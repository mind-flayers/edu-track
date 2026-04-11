"use client";

import { motion } from "framer-motion";
import Link from "next/link";
import { 
  Users, 
  UserPlus, 
  Upload
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
];

export function QuickActions() {
  return (
    <div className="space-y-4">
      <h2 className="text-2xl font-bold text-slate-900">Quick Actions</h2>
      <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
        {actions.map((action, index) => (
          <motion.div
            key={action.title}
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: index * 0.1 }}
            className={action.size === "large" ? "col-span-2" : ""}
          >
            <Link href={action.href}>
              <motion.div
                whileHover={{ scale: 1.02, y: -5 }}
                whileTap={{ scale: 0.98 }}
                className={`h-full glass-card p-6 relative overflow-hidden group cursor-pointer ${
                  action.size === "large" ? "min-h-[180px]" : "min-h-[140px]"
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
