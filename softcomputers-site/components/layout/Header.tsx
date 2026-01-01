'use client';

import Link from 'next/link';
import { useState, useEffect } from 'react';
import Image from 'next/image';

export default function Header() {
  const [scrolled, setScrolled] = useState(false);
  const [isMenuOpen, setIsMenuOpen] = useState(false);

  useEffect(() => {
    const handleScroll = () => {
      setScrolled(window.scrollY > 20);
    };
    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  return (
    <header 
      className={`fixed top-0 left-0 right-0 z-50 transition-all duration-500 ${
        scrolled 
          ? 'bg-[var(--background)]/80 backdrop-blur-xl border-b border-[var(--border)]' 
          : 'bg-transparent'
      }`}
    >
      <div className="max-w-7xl mx-auto px-6 lg:px-8">
        <div className="flex h-20 items-center justify-between">
          <Link 
            href="/" 
            className="text-xl font-semibold tracking-tight hover:opacity-70 transition-opacity"
          >
            Soft Computers
          </Link>

          <nav className="hidden md:flex items-center gap-1">
            <Link
              href="/"
              className="px-4 py-2.5 rounded-lg text-sm text-[var(--muted)] hover:text-[var(--foreground)] hover:bg-[var(--soft)] transition-all duration-200"
            >
              Home
            </Link>
              <Link
                href="/focusflow"
                className="px-4 py-2.5 rounded-lg text-sm font-medium hover:bg-[var(--soft)] transition-all duration-200 flex items-center gap-2 relative group"
              >
                <div className="absolute inset-0 rounded-lg bg-gradient-to-r from-[var(--accent-primary)]/20 via-[var(--accent-secondary)]/20 to-[var(--accent-primary)]/20 opacity-0 group-hover:opacity-100 transition-opacity duration-200 blur-sm" />
                <Image
                  src="/focusflow_app_icon.jpg"
                  alt="FocusFlow"
                  width={18}
                  height={18}
                  className="rounded-md relative z-10 ring-1 ring-[var(--accent-primary)]/30 group-hover:ring-[var(--accent-primary)]/60 transition-all duration-200"
                />
                <span className="relative z-10 bg-gradient-to-r from-[var(--accent-primary)] to-[var(--accent-secondary)] bg-clip-text text-transparent group-hover:drop-shadow-[0_0_8px_rgba(0,113,227,0.5)] transition-all duration-200">
                  FocusFlow
                </span>
              </Link>
            <Link
              href="/about"
              className="px-4 py-2.5 rounded-lg text-sm text-[var(--muted)] hover:text-[var(--foreground)] hover:bg-[var(--soft)] transition-all duration-200"
            >
              About
            </Link>
            <Link
              href="/support"
              className="px-4 py-2.5 rounded-lg text-sm text-[var(--muted)] hover:text-[var(--foreground)] hover:bg-[var(--soft)] transition-all duration-200"
            >
              Support
            </Link>
          </nav>

          <div className="hidden md:flex items-center gap-3">
            <Link
              href="/focusflow"
              className="px-5 py-2.5 rounded-lg text-sm font-medium text-[var(--foreground)] bg-[var(--soft)] hover:bg-[var(--soft-light)] transition-all duration-200"
            >
              Get Started
            </Link>
          </div>

          {/* Mobile Menu Button */}
          <button
            onClick={() => setIsMenuOpen(!isMenuOpen)}
            className="md:hidden p-2 rounded-lg hover:bg-[var(--soft)] transition-colors text-[var(--foreground)]"
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
        {isMenuOpen && (
          <div className="md:hidden pb-6 pt-4 border-t border-[var(--border)]">
            <div className="flex flex-col gap-1">
              <Link 
                href="/" 
                className="px-4 py-2.5 rounded-lg text-sm text-[var(--muted)] hover:text-[var(--foreground)] hover:bg-[var(--soft)] transition-all"
                onClick={() => setIsMenuOpen(false)}
              >
                Home
              </Link>
              <Link 
                href="/focusflow" 
                className="px-4 py-2.5 rounded-lg text-sm font-medium hover:bg-[var(--soft)] transition-all flex items-center gap-2 relative group"
                onClick={() => setIsMenuOpen(false)}
              >
                <div className="absolute inset-0 rounded-lg bg-gradient-to-r from-[var(--accent-primary)]/20 via-[var(--accent-secondary)]/20 to-[var(--accent-primary)]/20 opacity-0 group-hover:opacity-100 transition-opacity duration-200 blur-sm" />
                <Image
                  src="/focusflow_app_icon.jpg"
                  alt="FocusFlow"
                  width={18}
                  height={18}
                  className="rounded-md relative z-10 ring-1 ring-[var(--accent-primary)]/30 group-hover:ring-[var(--accent-primary)]/60 transition-all duration-200"
                />
                <span className="relative z-10 bg-gradient-to-r from-[var(--accent-primary)] to-[var(--accent-secondary)] bg-clip-text text-transparent group-hover:drop-shadow-[0_0_8px_rgba(0,113,227,0.5)] transition-all duration-200">
                  FocusFlow
                </span>
              </Link>
              <Link 
                href="/about" 
                className="px-4 py-2.5 rounded-lg text-sm text-[var(--muted)] hover:text-[var(--foreground)] hover:bg-[var(--soft)] transition-all"
                onClick={() => setIsMenuOpen(false)}
              >
                About
              </Link>
              <Link 
                href="/support" 
                className="px-4 py-2.5 rounded-lg text-sm text-[var(--muted)] hover:text-[var(--foreground)] hover:bg-[var(--soft)] transition-all"
                onClick={() => setIsMenuOpen(false)}
              >
                Support
              </Link>
              <Link 
                href="/focusflow" 
                className="px-4 py-2.5 rounded-lg text-sm font-medium text-[var(--foreground)] bg-[var(--soft)] hover:bg-[var(--soft-light)] transition-all mt-2"
                onClick={() => setIsMenuOpen(false)}
              >
                Get Started
              </Link>
            </div>
          </div>
        )}
      </div>
    </header>
  );
}
