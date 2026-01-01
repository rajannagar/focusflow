import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  output: 'export', // Generate static HTML files for AWS Amplify
  images: {
    unoptimized: true, // Required for static export
  },
  trailingSlash: true, // Add trailing slashes to URLs
  // Performance optimizations
  compress: true,
  poweredByHeader: false,
  reactStrictMode: true,
  swcMinify: true,
};

export default nextConfig;
