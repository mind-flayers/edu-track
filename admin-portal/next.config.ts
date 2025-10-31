import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  env: {
    NEXT_PUBLIC_SUPER_ADMIN_EMAIL: process.env.SUPER_ADMIN_EMAIL,
  },
};

export default nextConfig;
