'use client';

import Container from '@/components/ui/Container';
import Link from 'next/link';
import { useThrottledMouse } from '../hooks/useThrottledMouse';

export default function SupportPage() {
  const mousePosition = useThrottledMouse();

  return (
    <div className="min-h-screen bg-[var(--background)]">
      
      {/* ═══════════════════════════════════════════════════════════════
          HERO SECTION
          ═══════════════════════════════════════════════════════════════ */}
      <section className="relative pt-8 md:pt-20 pb-12 md:pb-24 overflow-hidden">
        <div className="absolute inset-0">
          <div 
            className="absolute top-1/4 left-1/4 w-[300px] md:w-[500px] h-[300px] md:h-[500px] rounded-full blur-[60px] md:blur-[80px] opacity-20 transition-transform duration-1000 ease-out"
            style={{
              background: `radial-gradient(circle, rgba(139, 92, 246, 0.4) 0%, transparent 70%)`,
              transform: `translate(${mousePosition.x * 0.02}px, ${mousePosition.y * 0.02}px)`,
            }}
          />
        </div>
        <div className="absolute inset-0 bg-grid opacity-20" />

        <Container>
          <div className="max-w-4xl relative z-10 stagger-children">
            <div className="inline-flex items-center gap-2 badge badge-primary mb-6 md:mb-8">
              <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M18.364 5.636l-3.536 3.536m0 5.656l3.536 3.536M9.172 9.172L5.636 5.636m3.536 9.192l-3.536 3.536M21 12a9 9 0 11-18 0 9 9 0 0118 0zm-5 0a4 4 0 11-8 0 4 4 0 018 0z" />
              </svg>
              We're Here to Help
            </div>
            <h1 className="mb-6 md:mb-8">
              Support & <span className="text-gradient">Contact</span>
            </h1>
            <p className="text-lg md:text-2xl text-[var(--foreground-muted)] leading-relaxed max-w-3xl">
              Get support, ask questions, or share feedback. We typically respond within 24 hours.
            </p>
          </div>
        </Container>
      </section>

      {/* ═══════════════════════════════════════════════════════════════
          FAQ SECTION
          ═══════════════════════════════════════════════════════════════ */}
      <section className="section-padding bg-[var(--background-elevated)]">
        <Container>
          <div className="max-w-3xl mx-auto">
            <div className="text-center mb-10 md:mb-16">
              <h2 className="mb-4 md:mb-6">Frequently asked questions</h2>
            </div>
            
            <div className="space-y-4">
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
                <div key={i} className="card group p-4 md:p-6 hover:border-[var(--accent-primary)]/30">
                  <h3 className="text-base md:text-lg font-semibold text-[var(--foreground)] mb-2 md:mb-3 group-hover:text-[var(--accent-primary-light)] transition-colors">
                    {faq.q}
                  </h3>
                  <p className="text-sm md:text-base text-[var(--foreground-muted)] leading-relaxed">{faq.a}</p>
                </div>
              ))}
            </div>
          </div>
        </Container>
      </section>

      {/* ═══════════════════════════════════════════════════════════════
          EMAIL SUPPORT - HIGHLIGHTED
          ═══════════════════════════════════════════════════════════════ */}
      <section id="email-support" className="section-padding relative overflow-hidden">
        <div className="absolute inset-0 bg-mesh" />
        <div className="absolute inset-0">
          <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[600px] h-[600px] rounded-full bg-gradient-to-r from-[var(--accent-primary)]/15 to-[var(--accent-secondary)]/10 blur-3xl" />
        </div>

        <Container>
          <div className="max-w-3xl mx-auto relative z-10">
            <div className="text-center mb-8 md:mb-12">
              <div className="inline-flex items-center gap-2 badge badge-primary mb-4 md:mb-6">
                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
                </svg>
                Get in Touch
              </div>
              <h2 className="mb-4 md:mb-6">Email Support</h2>
              <p className="text-base md:text-xl text-[var(--foreground-muted)]">
                Have a question or need help? We're here for you.
              </p>
            </div>

            <div className="card-glass p-6 md:p-12 text-center relative overflow-hidden">
              <div className="absolute inset-0 bg-gradient-to-br from-[var(--accent-primary)]/5 to-[var(--accent-secondary)]/5" />
              <div className="relative z-10">
                <div className="w-12 h-12 md:w-16 md:h-16 rounded-xl md:rounded-2xl bg-gradient-to-br from-[var(--accent-primary)] to-[var(--accent-primary-dark)] flex items-center justify-center text-white mx-auto mb-4 md:mb-6">
                  <svg className="w-6 h-6 md:w-8 md:h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
                  </svg>
                </div>
                
                <a
                  href="mailto:Info@softcomputers.ca"
                  className="text-xl sm:text-2xl md:text-4xl font-bold text-gradient hover:opacity-80 transition-opacity inline-block mb-4 md:mb-6 break-all sm:break-normal"
                >
                  Info@softcomputers.ca
                </a>
                
                <p className="text-sm md:text-base text-[var(--foreground-muted)] leading-relaxed mb-6 md:mb-8 max-w-xl mx-auto">
                  For support, feedback, account deletion requests, or general questions. We typically respond within 24 hours.
                </p>

                <div className="card p-3 md:p-4 max-w-lg mx-auto">
                  <p className="text-xs md:text-sm text-[var(--foreground-subtle)]">
                    <strong className="text-[var(--foreground-muted)]">Pro tip:</strong> Include your device model, iOS version, and a brief description of the issue for faster assistance.
                  </p>
                </div>
              </div>
            </div>
          </div>
        </Container>
      </section>

      {/* ═══════════════════════════════════════════════════════════════
          ADDITIONAL RESOURCES
          ═══════════════════════════════════════════════════════════════ */}
      <section className="section-padding bg-[var(--background-elevated)]">
        <Container>
          <div className="max-w-3xl mx-auto text-center px-4">
            <h2 className="mb-4 md:mb-6">Additional Resources</h2>
            <p className="text-base md:text-xl text-[var(--foreground-muted)] mb-8 md:mb-10">
              Find more information about our policies and products.
            </p>
            <div className="flex flex-col sm:flex-row gap-4 justify-center">
              <Link href="/privacy" className="btn btn-secondary">
                Privacy Policy
              </Link>
              <Link href="/terms" className="btn btn-secondary">
                Terms of Service
              </Link>
              <Link href="/focusflow" className="btn btn-accent">
                Learn about FocusFlow
              </Link>
            </div>
          </div>
        </Container>
      </section>
    </div>
  );
}
