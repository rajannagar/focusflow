'use client';

import Link from 'next/link';
import { useState, useEffect } from 'react';
import Image from 'next/image';
import { usePathname } from 'next/navigation';
import { ThemeToggle } from '@/components/common';

export default function Header() {
  const [scrolled, setScrolled] = useState(false);
  const [isMenuOpen, setIsMenuOpen] = useState(false);
  const pathname = usePathname();

  useEffect(() => {
    const handleScroll = () => {
      setScrolled(window.scrollY > 20);
    };
    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  // Check if current path matches the link
  const isActive = (path: string) => {
    if (path === '/') return pathname === '/';
    return pathname.startsWith(path);
  };

  return (
    <header 
      className="fixed top-0 left-0 right-0 z-[9999] bg-[var(--background)] border-b border-[var(--border)] transition-colors duration-300"
      style={{
        paddingTop: 'env(safe-area-inset-top, 0px)',
      }}
    >
      <div className="max-w-7xl mx-auto px-4 md:px-6 lg:px-8">
        <div className="flex h-16 md:h-20 items-center justify-between">
          {/* Logo - Text Only */}
          <Link 
            href="/" 
            className="group relative"
            onClick={() => {
              window.scrollTo({ top: 0, behavior: 'smooth' });
            }}
          >
            <span className="text-lg md:text-xl font-bold tracking-tight text-[var(--foreground)] transition-all duration-300 group-hover:text-gradient">
              Soft Computers
            </span>
            {/* Underline accent on hover */}
            <span className="absolute -bottom-1 left-0 w-0 h-0.5 bg-gradient-to-r from-[var(--accent-primary)] to-[var(--accent-secondary)] group-hover:w-full transition-all duration-300" />
          </Link>

          {/* Desktop Navigation */}
          <nav className="hidden md:flex items-center gap-1">
            <Link
              href="/"
              className={`px-4 py-2.5 rounded-full text-sm transition-all duration-300 ${
                isActive('/') 
                  ? 'text-[var(--foreground)] bg-[var(--background-subtle)]' 
                  : 'text-[var(--foreground-muted)] hover:text-[var(--foreground)] hover:bg-[var(--background-subtle)]'
              }`}
              onClick={() => {
                window.scrollTo({ top: 0, behavior: 'smooth' });
              }}
            >
              Home
            </Link>
            <Link
              href="/focusflow"
              className={`group px-4 py-2.5 rounded-full text-sm font-medium transition-all duration-300 flex items-center gap-2 relative ${
                isActive('/focusflow') ? 'bg-[var(--accent-primary)]/10' : ''
              }`}
              onClick={() => {
                window.scrollTo({ top: 0, behavior: 'smooth' });
              }}
            >
              {/* Glow effect on hover */}
              <div className={`absolute inset-0 rounded-full bg-gradient-to-r from-[var(--accent-primary)]/20 to-[var(--accent-secondary)]/20 transition-opacity duration-300 blur-sm ${
                isActive('/focusflow') ? 'opacity-100' : 'opacity-0 group-hover:opacity-100'
              }`} />
              <div className={`absolute inset-0 rounded-full border transition-all duration-300 ${
                isActive('/focusflow') 
                  ? 'border-[var(--accent-primary)]/40' 
                  : 'border-[var(--accent-primary)]/0 group-hover:border-[var(--accent-primary)]/30'
              }`} />
              
              <Image
                src="/focusflow_app_icon.jpg"
                alt="FocusFlow"
                width={24}
                height={24}
                className={`rounded-lg relative z-10 shadow-md transition-all duration-300 group-hover:scale-110 ${
                  isActive('/focusflow') ? 'scale-110' : ''
                }`}
              />
              <span className="relative z-10 text-gradient group-hover:drop-shadow-[0_0_12px_rgba(139,92,246,0.5)] transition-all duration-300">
                FocusFlow
              </span>
            </Link>
            <Link
              href="/about"
              className={`px-4 py-2.5 rounded-full text-sm transition-all duration-300 ${
                isActive('/about') 
                  ? 'text-[var(--foreground)] bg-[var(--background-subtle)]' 
                  : 'text-[var(--foreground-muted)] hover:text-[var(--foreground)] hover:bg-[var(--background-subtle)]'
              }`}
              onClick={() => {
                window.scrollTo({ top: 0, behavior: 'smooth' });
              }}
            >
              About
            </Link>
            <Link
              href="/support"
              className={`px-4 py-2.5 rounded-full text-sm transition-all duration-300 ${
                isActive('/support') 
                  ? 'text-[var(--foreground)] bg-[var(--background-subtle)]' 
                  : 'text-[var(--foreground-muted)] hover:text-[var(--foreground)] hover:bg-[var(--background-subtle)]'
              }`}
              onClick={() => {
                window.scrollTo({ top: 0, behavior: 'smooth' });
              }}
            >
              Support
            </Link>
          </nav>

          {/* Desktop CTA */}
          <div className="hidden md:flex items-center gap-3">
            <a
              href="https://apps.apple.com/app/focusflow-be-present/id6739000000"
              target="_blank"
              rel="noopener noreferrer"
              className="group relative px-5 py-2.5 rounded-full text-sm font-medium overflow-hidden flex items-center gap-2"
            >
              {/* Button gradient background */}
              <div className="absolute inset-0 bg-gradient-to-r from-[var(--accent-primary)] to-[var(--accent-primary-dark)] transition-all duration-300" />
              <div className="absolute inset-0 bg-gradient-to-r from-[var(--accent-primary-light)] to-[var(--accent-primary)] opacity-0 group-hover:opacity-100 transition-opacity duration-300" />
              
              {/* Glow effect */}
              <div className="absolute inset-0 rounded-full blur-xl bg-[var(--accent-primary)] opacity-0 group-hover:opacity-30 transition-opacity duration-300" />
              
              <svg className="w-4 h-4 relative z-10 text-white" fill="currentColor" viewBox="0 0 24 24">
                <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z"/>
              </svg>
              <span className="relative z-10 text-white">Download</span>
            </a>
            <ThemeToggle />
          </div>

          {/* Mobile Menu Button */}
          <button
            onClick={() => setIsMenuOpen(!isMenuOpen)}
            className="md:hidden p-2 rounded-lg hover:bg-[var(--background-subtle)] transition-colors text-[var(--foreground)]"
            aria-label="Menu"
          >
            <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              {isMenuOpen ? (
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
              ) : (
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 6h16M4 12h16M4 18h16" />
              )}
            </svg>
          </button>
        </div>

        {/* Mobile Menu */}
        <div className={`md:hidden overflow-hidden transition-all duration-500 ease-out ${isMenuOpen ? 'max-h-[400px] opacity-100' : 'max-h-0 opacity-0'}`}>
          <div className="pb-4 pt-3 border-t border-[var(--border)]">
            <div className="flex flex-col gap-1">
              <Link 
                href="/" 
                className={`px-4 py-3 rounded-xl text-sm transition-all ${
                  isActive('/') 
                    ? 'text-[var(--foreground)] bg-[var(--background-subtle)]' 
                    : 'text-[var(--foreground-muted)] hover:text-[var(--foreground)] hover:bg-[var(--background-subtle)]'
                }`}
                onClick={() => {
                  setIsMenuOpen(false);
                  window.scrollTo({ top: 0, behavior: 'smooth' });
                }}
              >
                Home
              </Link>
              <Link 
                href="/focusflow" 
                className={`px-4 py-3 rounded-xl text-sm font-medium transition-all flex items-center gap-3 group ${
                  isActive('/focusflow') ? 'bg-[var(--accent-primary)]/10' : 'hover:bg-[var(--background-subtle)]'
                }`}
                onClick={() => {
                  setIsMenuOpen(false);
                  window.scrollTo({ top: 0, behavior: 'smooth' });
                }}
              >
                <Image
                  src="/focusflow_app_icon.jpg"
                  alt="FocusFlow"
                  width={28}
                  height={28}
                  className="rounded-lg shadow-md"
                />
                <span className="text-gradient">FocusFlow</span>
              </Link>
              <Link 
                href="/about" 
                className={`px-4 py-3 rounded-xl text-sm transition-all ${
                  isActive('/about') 
                    ? 'text-[var(--foreground)] bg-[var(--background-subtle)]' 
                    : 'text-[var(--foreground-muted)] hover:text-[var(--foreground)] hover:bg-[var(--background-subtle)]'
                }`}
                onClick={() => {
                  setIsMenuOpen(false);
                  window.scrollTo({ top: 0, behavior: 'smooth' });
                }}
              >
                About
              </Link>
              <Link 
                href="/support" 
                className={`px-4 py-3 rounded-xl text-sm transition-all ${
                  isActive('/support') 
                    ? 'text-[var(--foreground)] bg-[var(--background-subtle)]' 
                    : 'text-[var(--foreground-muted)] hover:text-[var(--foreground)] hover:bg-[var(--background-subtle)]'
                }`}
                onClick={() => {
                  setIsMenuOpen(false);
                  window.scrollTo({ top: 0, behavior: 'smooth' });
                }}
              >
                Support
              </Link>
              
              {/* Mobile CTA */}
              <div className="mt-4 pt-4 border-t border-[var(--border)] space-y-3">
                <div className="flex items-center justify-between px-4 py-2">
                  <span className="text-sm font-medium text-[var(--foreground-muted)]">Theme</span>
                  <ThemeToggle />
                </div>
                <a 
                  href="https://apps.apple.com/app/focusflow-be-present/id6739000000"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="btn btn-accent w-full justify-center"
                  onClick={() => setIsMenuOpen(false)}
                >
                  <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 24 24">
                    <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z"/>
                  </svg>
                  Download FocusFlow
                </a>
              </div>
            </div>
          </div>
        </div>
      </div>
    </header>
  );
}
