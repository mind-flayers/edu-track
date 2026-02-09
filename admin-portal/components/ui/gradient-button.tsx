"use client";

import { motion, HTMLMotionProps } from "framer-motion";
import { Loader2 } from "lucide-react";

interface GradientButtonProps extends Omit<HTMLMotionProps<"button">, "children"> {
  children: React.ReactNode;
  variant?: "primary" | "secondary" | "outline";
  isLoading?: boolean;
}

export function GradientButton({ 
  children, 
  variant = "primary", 
  isLoading,
  className = "",
  disabled,
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
      disabled={isLoading || disabled}
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
