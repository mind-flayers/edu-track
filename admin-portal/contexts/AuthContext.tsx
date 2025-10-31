'use client';

import { createContext, useContext, useEffect, useState, ReactNode } from 'react';
import { auth } from '@/lib/firebase-client';
import {
  signInWithEmailAndPassword,
  signOut as firebaseSignOut,
  onAuthStateChanged,
  User,
} from 'firebase/auth';

const SUPER_ADMIN_EMAIL = process.env.NEXT_PUBLIC_SUPER_ADMIN_EMAIL || 'mishaf1106@gmail.com';

interface AuthContextType {
  user: User | null;
  loading: boolean;
  isSuperAdmin: boolean;
  signIn: (email: string, password: string) => Promise<void>;
  signOut: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType>({
  user: null,
  loading: true,
  isSuperAdmin: false,
  signIn: async () => {},
  signOut: async () => {},
});

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);
  const [isSuperAdmin, setIsSuperAdmin] = useState(false);

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, (user) => {
      setUser(user);
      setIsSuperAdmin(user?.email?.toLowerCase() === SUPER_ADMIN_EMAIL.toLowerCase());
      setLoading(false);
    });

    return () => unsubscribe();
  }, []);

  const signIn = async (email: string, password: string) => {
    // Check if email is super admin before attempting sign in
    if (email.toLowerCase() !== SUPER_ADMIN_EMAIL.toLowerCase()) {
      throw new Error('Access denied. This portal is restricted to super admin only.');
    }
    
    await signInWithEmailAndPassword(auth, email, password);
  };

  const signOut = async () => {
    await firebaseSignOut(auth);
  };

  return (
    <AuthContext.Provider value={{ user, loading, isSuperAdmin, signIn, signOut }}>
      {children}
    </AuthContext.Provider>
  );
}

export const useAuth = () => useContext(AuthContext);
