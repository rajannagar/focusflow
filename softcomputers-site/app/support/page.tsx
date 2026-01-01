'use client';

import Container from '@/components/ui/Container';
import Link from 'next/link';
import { useEffect, useState } from 'react';

export default function SupportPage() {
  const [mousePosition, setMousePosition] = useState({ x: 0, y: 0 });

  useEffect(() => {
    const handleMouseMove = (e: MouseEvent) => {
      setMousePosition({ x: e.clientX, y: e.clientY });
    };
    window.addEventListener('mousemove', handleMouseMove);
    return () => window.removeEventListener('mousemove', handleMouseMove);
  }, []);

  return (
    <div className="min-h-screen bg-[var(--background)]">
      {/* Hero Section */}
      <section className="relative pt-40 pb-24 px-6 overflow-hidden">
        {/* Subtle animated background */}
        <div className="absolute inset-0">
          <div 
            className="absolute top-1/4 left-1/4 w-96 h-96 rounded-full blur-3xl opacity-20 transition-all duration-1000"
            style={{
              background: `radial-gradient(circle, rgba(0, 113, 227, 0.15) 0%, transparent 70%)`,
              transform: `translate(${mousePosition.x * 0.02}px, ${mousePosition.y * 0.02}px)`,
            }}
          />
        </div>

        <Container>
          <div className="max-w-5xl relative z-10">
            <h1 className="text-6xl md:text-7xl font-semibold tracking-tight mb-8">
              Support & Contact
            </h1>
            <p className="text-2xl md:text-3xl text-[var(--muted)] leading-relaxed mb-12 max-w-4xl">
              We're here to help. Get support, ask questions, or share feedback. We typically respond within 24 hours.
            </p>
          </div>
        </Container>
      </section>

      {/* FAQ Section */}
      <section className="py-24 bg-[var(--soft)]">
        <Container>
          <div className="max-w-3xl mx-auto">
            <h2 className="text-4xl md:text-5xl font-semibold tracking-tight mb-12 text-center">Frequently asked questions</h2>
            
            <div className="space-y-6">
              {[
                {
                  q: 'How do I sync my data across devices?',
                  a: 'Sign in with your Apple, Google, or email account to enable cloud sync. Your sessions, tasks, presets, and settings will automatically sync across all your devices.',
                },
                {
                  q: 'Can I use FocusFlow without an account?',
                  a: 'Yes! Guest Mode allows you to use FocusFlow with all features except cloud sync. All your data stays on your device.',
                },
                {
                  q: 'How do I cancel my FocusFlow Pro subscription?',
                  a: 'Cancel anytime through your Apple ID settings. Go to Settings → [Your Name] → Subscriptions, find FocusFlow Pro, and tap Cancel Subscription.',
                },
                {
                  q: 'How do I delete my account?',
                  a: 'Go to Profile → Settings → Delete Account. Confirm by typing "DELETE". All your data will be permanently removed from our servers.',
                },
                {
                  q: 'Does FocusFlow work offline?',
                  a: 'Yes! Focus sessions and tasks work without an internet connection. Your data syncs automatically when you\'re back online.',
                },
                {
                  q: 'How do I restore my Pro subscription?',
                  a: 'If you previously had FocusFlow Pro, you can restore it by going to Profile → Settings → Restore Purchases. This will reactivate your subscription if it\'s still valid.',
                },
                {
                  q: 'Can I export my data?',
                  a: 'Yes! Go to Profile → Settings → Backup & Export to download a JSON file with all your data. This is useful for backup or moving to a new device.',
                },
                {
                  q: 'What if I have a feature request?',
                  a: 'We love hearing from you! Email us at Info@softcomputers.ca with your ideas. We review all feedback and consider it for future updates.',
                },
              ].map((faq, i) => (
                <div key={i} className="card p-8">
                  <h3 className="text-xl font-semibold mb-4">{faq.q}</h3>
                  <p className="text-[var(--muted)] leading-relaxed">{faq.a}</p>
                </div>
              ))}
            </div>
          </div>
        </Container>
      </section>

      {/* Additional Resources */}
      <section className="py-24">
        <Container>
          <div className="max-w-3xl mx-auto">
            <div className="card p-12">
              <h2 className="text-2xl font-semibold tracking-tight mb-6">Additional Resources</h2>
              <p className="text-lg text-[var(--muted)] leading-relaxed mb-8">
                Find more information about our policies and terms.
              </p>
              <div className="flex flex-col sm:flex-row gap-4">
                <Link
                  href="/privacy"
                  className="btn btn-secondary inline-block text-center"
                >
                  Privacy Policy
                </Link>
                <Link
                  href="/terms"
                  className="btn btn-secondary inline-block text-center"
                >
                  Terms of Service
                </Link>
                <Link
                  href="/focusflow"
                  className="btn btn-secondary inline-block text-center"
                >
                  Learn about FocusFlow
                </Link>
              </div>
            </div>
          </div>
        </Container>
      </section>

      {/* Email Support - Highlighted Section */}
      <section id="email-support" className="py-32 relative overflow-hidden bg-gradient-to-b from-[var(--soft)] to-[var(--background)]">
        {/* Subtle premium background */}
        <div className="absolute inset-0">
          <div 
            className="absolute top-1/4 left-1/4 w-96 h-96 rounded-full blur-3xl opacity-15 transition-all duration-1000"
            style={{
              background: `radial-gradient(circle, rgba(94, 92, 230, 0.2) 0%, rgba(0, 113, 227, 0.1) 50%, transparent 70%)`,
              transform: `translate(${mousePosition.x * 0.02}px, ${mousePosition.y * 0.02}px)`,
            }}
          />
          <div 
            className="absolute bottom-1/4 right-1/4 w-80 h-80 rounded-full blur-3xl opacity-10 transition-all duration-1000"
            style={{
              background: `radial-gradient(circle, rgba(191, 90, 242, 0.15) 0%, rgba(94, 92, 230, 0.08) 50%, transparent 70%)`,
              transform: `translate(${-mousePosition.x * 0.015}px, ${-mousePosition.y * 0.015}px)`,
            }}
          />
        </div>

        <Container>
          <div className="max-w-4xl mx-auto relative z-10">
            <div className="text-center mb-12">
              <div className="inline-flex items-center justify-center gap-2 px-4 py-2 rounded-full bg-[var(--accent-primary)]/10 border border-[var(--accent-primary)]/20 mb-6">
                <svg className="w-5 h-5 text-[var(--accent-primary)]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
                </svg>
                <span className="text-sm font-semibold text-[var(--accent-primary)]">Get in Touch</span>
              </div>
              <h2 className="text-5xl md:text-6xl font-semibold tracking-tight mb-6">
                Email Support
              </h2>
              <p className="text-xl text-[var(--muted)] leading-relaxed max-w-2xl mx-auto">
                Have a question or need help? We're here for you.
              </p>
            </div>

            <div className="card p-16 text-center bg-gradient-to-br from-[var(--accent-primary)]/5 to-[var(--accent-secondary)]/5 border-2 border-[var(--accent-primary)]/30 relative shadow-lg">
              <div className="mb-8">
                <div className="w-16 h-16 rounded-2xl bg-[var(--accent-primary)] flex items-center justify-center text-white mx-auto mb-6 shadow-lg">
                  <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
                  </svg>
                </div>
                <div className="text-xs font-medium text-[var(--muted)] uppercase tracking-wide mb-4">
                  Email Address
                </div>
                <a
                  href="mailto:Info@softcomputers.ca"
                  className="text-4xl md:text-5xl font-semibold text-[var(--foreground)] hover:text-[var(--accent-primary)] transition-colors inline-block mb-6"
                >
                  Info@softcomputers.ca
                </a>
              </div>
              
              <p className="text-lg text-[var(--muted)] leading-relaxed mb-8 max-w-2xl mx-auto">
                For support, feedback, account deletion requests, or general questions, reach out anytime. We typically respond within 24 hours.
              </p>

              <div className="card p-6 bg-[var(--background)] max-w-xl mx-auto">
                <p className="text-sm text-[var(--muted)] leading-relaxed">
                  <strong className="text-[var(--foreground)]">For faster assistance:</strong> Include your device model, iOS version, and a short description of what happened.
                </p>
              </div>
            </div>
          </div>
        </Container>
      </section>
    </div>
  );
}
