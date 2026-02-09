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
          className={`absolute ${icon ? 'left-12' : 'left-4'} top-3 origin-left pointer-events-none font-medium transition-colors`}
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
