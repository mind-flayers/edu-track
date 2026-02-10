"use client";

import { useAuth } from "@/contexts/AuthContext";
import { Bell, Search } from "lucide-react";

export function Header() {
  const { user, isSuperAdmin } = useAuth();

  return (
    <header className="fixed top-0 right-0 left-0 lg:left-72 z-30 h-20 px-6 py-4 bg-white/80 backdrop-blur-xl border-b border-slate-200/50">
      <div className="glass-card p-4 flex items-center justify-between">
        <div className="flex items-center gap-4 flex-1 max-w-md">
          <Search className="w-5 h-5 text-slate-400" />
          <input
            type="text"
            placeholder="Search..."
            className="flex-1 bg-transparent outline-none text-slate-900 placeholder:text-slate-400"
          />
        </div>
        <div className="flex items-center gap-4">
          <button className="p-2 hover:bg-slate-100 rounded-lg transition-colors relative">
            <Bell className="w-5 h-5 text-slate-600" />
            <span className="absolute top-1 right-1 w-2 h-2 bg-rose-500 rounded-full"></span>
          </button>
          <div className="flex items-center gap-3 pl-4 border-l border-slate-200">
            <div className="text-right">
              <p className="text-sm font-medium text-slate-900">{user?.email}</p>
              {isSuperAdmin && (
                <span className="text-xs text-indigo-600 font-semibold">SUPER ADMIN</span>
              )}
            </div>
            <div className="w-10 h-10 bg-gradient-to-br from-indigo-500 to-violet-500 rounded-full flex items-center justify-center text-white font-semibold">
              {user?.email?.charAt(0).toUpperCase()}
            </div>
          </div>
        </div>
      </div>
    </header>
  );
}
