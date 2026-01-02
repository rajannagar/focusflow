import Link from 'next/link';
import Image from 'next/image';

export default function Footer() {
  const currentYear = new Date().getFullYear();

  return (
    <footer className="relative border-t border-[var(--border)] bg-[var(--background)]">
      {/* Subtle gradient overlay */}
      <div className="absolute inset-0 bg-gradient-to-t from-[var(--background-elevated)] to-transparent opacity-50 pointer-events-none" />
      
      <div className="relative max-w-7xl mx-auto px-4 md:px-6 lg:px-8">
        {/* Main Footer Content */}
        <div className="py-10 md:py-16 grid md:grid-cols-4 gap-8 md:gap-8">
          {/* Brand Column */}
          <div className="md:col-span-1">
            <Link href="/" className="group relative inline-block mb-6">
              <span className="text-2xl font-bold tracking-tight text-[var(--foreground)] transition-all duration-300 group-hover:text-gradient">
                Soft Computers
              </span>
              {/* Underline accent on hover */}
              <span className="absolute -bottom-1 left-0 w-0 h-0.5 bg-gradient-to-r from-[var(--accent-primary)] to-[var(--accent-secondary)] group-hover:w-full transition-all duration-300" />
            </Link>
            <p className="text-sm text-[var(--foreground-muted)] leading-relaxed mb-4 max-w-xs">
              Building premium software that helps people do meaningful work—calmly, consistently, and with intention.
            </p>
            
            {/* Location */}
            <div className="flex items-center gap-2 text-sm text-[var(--foreground-subtle)]">
              <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
              </svg>
              Toronto, Ontario, Canada
            </div>
          </div>

          {/* Product Column */}
          <div>
            <h3 className="text-sm font-semibold text-[var(--foreground)] mb-5 uppercase tracking-wider">Product</h3>
            <nav className="flex flex-col gap-3">
              <Link href="/focusflow" className="group flex items-center gap-3">
                <Image
                  src="/focusflow_app_icon.jpg"
                  alt="FocusFlow"
                  width={36}
                  height={36}
                  className="rounded-xl shadow-lg transition-all duration-300 group-hover:scale-105"
                />
                <div>
                  <div className="text-sm font-medium text-[var(--foreground)] group-hover:text-[var(--accent-primary-light)] transition-colors">
                    FocusFlow
                  </div>
                  <div className="text-xs text-[var(--foreground-subtle)]">Be Present</div>
                </div>
              </Link>
              <a
                href="https://apps.apple.com/app/focusflow-be-present/id6739000000"
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center gap-2 text-sm text-[var(--foreground-muted)] hover:text-[var(--accent-primary-light)] transition-colors group"
              >
                <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 24 24">
                  <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z"/>
                </svg>
                Download on App Store
                <svg className="w-3 h-3 opacity-50 group-hover:opacity-100 transition-opacity" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
                </svg>
              </a>
            </nav>
          </div>

          {/* Company Column */}
          <div>
            <h3 className="text-sm font-semibold text-[var(--foreground)] mb-5 uppercase tracking-wider">Company</h3>
            <nav className="flex flex-col gap-3">
              <Link
                href="/about"
                className="text-sm text-[var(--foreground-muted)] hover:text-[var(--foreground)] transition-colors"
              >
                About Us
              </Link>
              <Link
                href="/support"
                className="text-sm text-[var(--foreground-muted)] hover:text-[var(--foreground)] transition-colors"
              >
                Support
              </Link>
              <a
                href="mailto:Info@softcomputers.ca"
                className="text-sm text-[var(--foreground-muted)] hover:text-[var(--foreground)] transition-colors"
              >
                Contact
              </a>
            </nav>
          </div>

          {/* Legal Column */}
          <div>
            <h3 className="text-sm font-semibold text-[var(--foreground)] mb-5 uppercase tracking-wider">Legal</h3>
            <nav className="flex flex-col gap-3">
              <Link
                href="/privacy"
                className="text-sm text-[var(--foreground-muted)] hover:text-[var(--foreground)] transition-colors"
              >
                Privacy Policy
              </Link>
              <Link
                href="/terms"
                className="text-sm text-[var(--foreground-muted)] hover:text-[var(--foreground)] transition-colors"
              >
                Terms of Service
              </Link>
            </nav>
          </div>
        </div>

        {/* Bottom Bar */}
        <div className="py-6 border-t border-[var(--border)] flex flex-col md:flex-row justify-between items-center gap-4">
          <div className="text-sm text-[var(--foreground-subtle)]">
            © {currentYear} Soft Computers. All rights reserved.
          </div>
          <div className="flex items-center gap-2 text-sm text-[var(--foreground-subtle)]">
            <span className="inline-block w-2 h-2 rounded-full bg-[var(--success)] animate-pulse" />
            Built with intention
          </div>
        </div>
      </div>
    </footer>
  );
}
