import Link from 'next/link';
import Image from 'next/image';

export default function Footer() {
  const currentYear = new Date().getFullYear();

  return (
    <footer className="border-t border-[var(--border)] bg-[var(--background)]">
      <div className="max-w-7xl mx-auto px-6 lg:px-8 py-12">
        <div className="grid md:grid-cols-3 gap-8 mb-8">
          {/* Company Info */}
          <div>
            <h3 className="text-lg font-semibold mb-4">Soft Computers</h3>
            <p className="text-sm text-[var(--muted)] leading-relaxed">
              Building premium software that helps people do meaningful work—calmly, consistently, and with intention.
            </p>
          </div>

          {/* FocusFlow Product */}
          <div>
            <h3 className="text-lg font-semibold mb-4">Our Products</h3>
            <Link href="/focusflow" className="flex items-center gap-3 mb-4 group">
              <div className="relative flex-shrink-0">
                <Image
                  src="/focusflow_app_icon.jpg"
                  alt="FocusFlow - Be Present"
                  width={48}
                  height={48}
                  className="rounded-xl shadow-md ring-1 ring-[var(--border)] group-hover:ring-[var(--accent-primary)]/30 transition-all"
                  style={{ objectFit: 'cover' }}
                />
              </div>
              <div>
                <div className="font-semibold text-[var(--foreground)] group-hover:text-[var(--accent-primary)] transition-colors">
                  FocusFlow
                </div>
                <div className="text-xs text-[var(--muted)]">Be Present</div>
              </div>
            </Link>
            <a
              href="https://apps.apple.com/app/focusflow-be-present/id6739000000"
              target="_blank"
              rel="noopener noreferrer"
              className="text-sm text-[var(--accent-primary)] hover:underline inline-flex items-center gap-1"
            >
              Download on App Store
              <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
              </svg>
            </a>
          </div>

          {/* Links */}
          <div>
            <h3 className="text-lg font-semibold mb-4">Links</h3>
            <nav className="flex flex-col gap-3">
              <Link
                href="/focusflow"
                className="text-sm text-[var(--muted)] hover:text-[var(--foreground)] transition-colors"
              >
                FocusFlow
              </Link>
              <Link
                href="/about"
                className="text-sm text-[var(--muted)] hover:text-[var(--foreground)] transition-colors"
              >
                About
              </Link>
              <Link
                href="/support#email-support"
                className="text-sm text-[var(--muted)] hover:text-[var(--foreground)] transition-colors"
              >
                Contact
              </Link>
              <Link
                href="/privacy"
                className="text-sm text-[var(--muted)] hover:text-[var(--foreground)] transition-colors"
              >
                Privacy Policy
              </Link>
              <Link
                href="/terms"
                className="text-sm text-[var(--muted)] hover:text-[var(--foreground)] transition-colors"
              >
                Terms of Service
              </Link>
            </nav>
          </div>
        </div>

        {/* Copyright */}
        <div className="border-t border-[var(--border)] pt-8 flex flex-col md:flex-row justify-between items-center gap-4">
          <div className="text-sm text-[var(--muted)]">
            © {currentYear} Soft Computers. All rights reserved.
          </div>
          <div className="text-sm text-[var(--muted)]">
            Made with intention
          </div>
        </div>
      </div>
    </footer>
  );
}
