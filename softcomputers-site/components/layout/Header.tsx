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
      className="fixed top-0 left-0 right-0 z-[9999] bg-[#0A0A0B] border-b border-[rgba(245,240,232,0.08)]"
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
              className="px-4 py-2.5 rounded-full text-sm text-[var(--foreground-muted)] hover:text-[var(--foreground)] hover:bg-[var(--background-subtle)] transition-all duration-300"
              onClick={() => {
                window.scrollTo({ top: 0, behavior: 'smooth' });
              }}
            >
              Home
            </Link>
            <Link
              href="/focusflow"
              className="group px-4 py-2.5 rounded-full text-sm font-medium transition-all duration-300 flex items-center gap-2 relative"
              onClick={() => {
                window.scrollTo({ top: 0, behavior: 'smooth' });
              }}
            >
              {/* Glow effect on hover */}
              <div className="absolute inset-0 rounded-full bg-gradient-to-r from-[var(--accent-primary)]/20 to-[var(--accent-secondary)]/20 opacity-0 group-hover:opacity-100 transition-opacity duration-300 blur-sm" />
              <div className="absolute inset-0 rounded-full border border-[var(--accent-primary)]/0 group-hover:border-[var(--accent-primary)]/30 transition-all duration-300" />
              
              <Image
                src="/focusflow_app_icon.jpg"
                alt="FocusFlow"
                width={24}
                height={24}
                className="rounded-lg relative z-10 shadow-md transition-all duration-300 group-hover:scale-110"
              />
              <span className="relative z-10 text-gradient group-hover:drop-shadow-[0_0_12px_rgba(139,92,246,0.5)] transition-all duration-300">
                FocusFlow
              </span>
            </Link>
            <Link
              href="/about"
              className="px-4 py-2.5 rounded-full text-sm text-[var(--foreground-muted)] hover:text-[var(--foreground)] hover:bg-[var(--background-subtle)] transition-all duration-300"
              onClick={() => {
                window.scrollTo({ top: 0, behavior: 'smooth' });
              }}
            >
              About
            </Link>
            <Link
              href="/support"
              className="px-4 py-2.5 rounded-full text-sm text-[var(--foreground-muted)] hover:text-[var(--foreground)] hover:bg-[var(--background-subtle)] transition-all duration-300"
              onClick={() => {
                window.scrollTo({ top: 0, behavior: 'smooth' });
              }}
            >
              Support
            </Link>
          </nav>

          {/* Desktop CTA */}
          <div className="hidden md:flex items-center gap-3">
            <Link
              href="/focusflow"
              className="group relative px-5 py-2.5 rounded-full text-sm font-medium overflow-hidden"
            >
              {/* Button gradient background */}
              <div className="absolute inset-0 bg-gradient-to-r from-[var(--accent-primary)] to-[var(--accent-primary-dark)] transition-all duration-300" />
              <div className="absolute inset-0 bg-gradient-to-r from-[var(--accent-primary-light)] to-[var(--accent-primary)] opacity-0 group-hover:opacity-100 transition-opacity duration-300" />
              
              {/* Glow effect */}
              <div className="absolute inset-0 rounded-full blur-xl bg-[var(--accent-primary)] opacity-0 group-hover:opacity-30 transition-opacity duration-300" />
              
              <span className="relative z-10 text-white">Get Started</span>
            </Link>
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
                className="px-4 py-3 rounded-xl text-sm text-[var(--foreground-muted)] hover:text-[var(--foreground)] hover:bg-[var(--background-subtle)] transition-all"
                onClick={() => {
                  setIsMenuOpen(false);
                  window.scrollTo({ top: 0, behavior: 'smooth' });
                }}
              >
                Home
              </Link>
              <Link 
                href="/focusflow" 
                className="px-4 py-3 rounded-xl text-sm font-medium hover:bg-[var(--background-subtle)] transition-all flex items-center gap-3 group"
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
                className="px-4 py-3 rounded-xl text-sm text-[var(--foreground-muted)] hover:text-[var(--foreground)] hover:bg-[var(--background-subtle)] transition-all"
                onClick={() => {
                  setIsMenuOpen(false);
                  window.scrollTo({ top: 0, behavior: 'smooth' });
                }}
              >
                About
              </Link>
              <Link 
                href="/support" 
                className="px-4 py-3 rounded-xl text-sm text-[var(--foreground-muted)] hover:text-[var(--foreground)] hover:bg-[var(--background-subtle)] transition-all"
                onClick={() => {
                  setIsMenuOpen(false);
                  window.scrollTo({ top: 0, behavior: 'smooth' });
                }}
              >
                Support
              </Link>
              
              {/* Mobile CTA */}
              <div className="mt-4 pt-4 border-t border-[var(--border)]">
                <Link 
                  href="/focusflow" 
                  className="btn btn-accent w-full justify-center"
                  onClick={() => setIsMenuOpen(false)}
                >
                  Get Started
                </Link>
              </div>
            </div>
          </div>
        </div>
      </div>
    </header>
  );
}
