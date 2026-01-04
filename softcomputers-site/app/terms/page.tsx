'use client';

import Link from 'next/link';
import { Container } from '@/components';
import { CONTACT_EMAIL } from '@/lib/constants';

export default function TermsPage() {
  const sections = [
    { id: 'acceptance', title: 'Acceptance of Terms' },
    { id: 'service', title: 'Description of Service' },
    { id: 'accounts', title: 'User Accounts' },
    { id: 'subscription', title: 'FocusFlow Pro Subscription' },
    { id: 'acceptable-use', title: 'Acceptable Use' },
    { id: 'intellectual-property', title: 'Intellectual Property' },
    { id: 'user-content', title: 'User Content' },
    { id: 'privacy', title: 'Data and Privacy' },
    { id: 'deletion', title: 'Account Deletion' },
    { id: 'disclaimers', title: 'Disclaimers' },
    { id: 'liability', title: 'Limitation of Liability' },
    { id: 'indemnification', title: 'Indemnification' },
    { id: 'changes', title: 'Changes to Terms' },
    { id: 'termination', title: 'Termination' },
    { id: 'governing-law', title: 'Governing Law' },
    { id: 'contact', title: 'Contact' },
  ];

  return (
    <div className="min-h-screen bg-[var(--background)]">
      
      {/* Clean Header */}
      <section className="pt-12 md:pt-20 pb-8 md:pb-12 border-b border-[var(--border)]">
        <Container>
          <div className="max-w-3xl mx-auto">
            <div className="flex items-center gap-2 text-sm text-[var(--foreground-muted)] mb-4">
              <Link href="/" className="hover:text-[var(--foreground)] transition-colors">Home</Link>
              <span>/</span>
              <span>Terms of Service</span>
            </div>
            <h1 className="text-3xl md:text-4xl font-bold text-[var(--foreground)] mb-4">Terms of Service</h1>
            <p className="text-[var(--foreground-muted)]">
              Last updated: January 2, 2026
            </p>
          </div>
        </Container>
      </section>

      {/* Main Content */}
      <section className="py-12 md:py-16">
        <Container>
          <div className="max-w-3xl mx-auto">
            
            {/* Introduction */}
            <div className="prose-section mb-12">
              <p className="text-lg text-[var(--foreground-muted)] leading-relaxed">
                These Terms of Service ("Terms") govern your use of FocusFlow - Be Present ("FocusFlow", "the app").
                By using FocusFlow, you agree to these Terms. Soft Computers ("we", "us") is the developer of FocusFlow.
              </p>
            </div>

            {/* Table of Contents */}
            <nav className="mb-12 p-6 bg-[var(--background-subtle)] rounded-lg border border-[var(--border)]">
              <h2 className="text-sm font-semibold text-[var(--foreground)] uppercase tracking-wider mb-4">Contents</h2>
              <ol className="grid md:grid-cols-2 gap-2">
                {sections.map((section, i) => (
                  <li key={section.id}>
                    <a 
                      href={`#${section.id}`}
                      className="text-sm text-[var(--foreground-muted)] hover:text-[var(--accent-primary)] transition-colors"
                    >
                      {i + 1}. {section.title}
                    </a>
                  </li>
                ))}
              </ol>
            </nav>

            {/* Sections */}
            <div className="space-y-12">
              
              {/* 1. Acceptance of Terms */}
              <section id="acceptance">
                <h2 className="text-xl font-semibold text-[var(--foreground)] mb-4 pb-2 border-b border-[var(--border)]">
                  1. Acceptance of Terms
                </h2>
                <p className="text-[var(--foreground-muted)]">
                  By downloading, installing, or using FocusFlow, you agree to be bound by these Terms. If you do not agree to these Terms, do not use the app.
                    </p>
              </section>

              {/* 2. Description of Service */}
              <section id="service">
                <h2 className="text-xl font-semibold text-[var(--foreground)] mb-4 pb-2 border-b border-[var(--border)]">
                  2. Description of Service
                </h2>
                <p className="text-[var(--foreground-muted)] mb-4">FocusFlow is a productivity application that helps you:</p>
                <ul className="space-y-3 text-[var(--foreground-muted)]">
                  <li className="flex gap-3">
                    <span className="text-[var(--accent-primary)]">•</span>
                    <span>Track focus sessions with customizable durations and 14 ambient backgrounds</span>
                  </li>
                  <li className="flex gap-3">
                    <span className="text-[var(--accent-primary)]">•</span>
                    <span>Manage tasks with reminders, recurring schedules, and duration estimates</span>
                  </li>
                  <li className="flex gap-3">
                    <span className="text-[var(--accent-primary)]">•</span>
                    <span>View progress statistics, streaks, XP, levels, and achievements</span>
                  </li>
                  <li className="flex gap-3">
                    <span className="text-[var(--accent-primary)]">•</span>
                    <span>Sync data across devices (with an account) or use Guest Mode for local-only storage</span>
                  </li>
                  <li className="flex gap-3">
                    <span className="text-[var(--accent-primary)]">•</span>
                    <span>Customize your experience with 10 themes, avatars, and focus presets</span>
                  </li>
                      </ul>
              </section>

              {/* 3. User Accounts */}
              <section id="accounts">
                <h2 className="text-xl font-semibold text-[var(--foreground)] mb-4 pb-2 border-b border-[var(--border)]">
                  3. User Accounts
                </h2>
                <ul className="space-y-3 text-[var(--foreground-muted)]">
                  <li className="flex gap-3">
                    <span className="text-[var(--accent-primary)]">•</span>
                    <span><strong className="text-[var(--foreground)]">Guest Mode:</strong> You may use FocusFlow without creating an account. Data is stored locally on your device.</span>
                  </li>
                  <li className="flex gap-3">
                    <span className="text-[var(--accent-primary)]">•</span>
                    <span><strong className="text-[var(--foreground)]">Signed-in Mode:</strong> You may create an account using Apple, Google, or email authentication. This enables cloud sync and backup.</span>
                  </li>
                  <li className="flex gap-3">
                    <span className="text-[var(--accent-primary)]">•</span>
                    <span>You are responsible for maintaining the security of your account credentials.</span>
                  </li>
                  <li className="flex gap-3">
                    <span className="text-[var(--accent-primary)]">•</span>
                    <span>You must provide accurate information when creating an account.</span>
                  </li>
                    </ul>
              </section>

              {/* 4. FocusFlow Pro Subscription */}
              <section id="subscription">
                <h2 className="text-xl font-semibold text-[var(--foreground)] mb-4 pb-2 border-b border-[var(--border)]">
                  4. FocusFlow Pro Subscription
                </h2>
                <p className="text-[var(--foreground-muted)] mb-4">FocusFlow offers optional paid subscriptions ("FocusFlow Pro") with the following terms:</p>
                <ul className="space-y-3 text-[var(--foreground-muted)]">
                  <li className="flex gap-3">
                    <span className="text-[var(--accent-primary)]">•</span>
                    <span><strong className="text-[var(--foreground)]">Subscription Options:</strong> Monthly and yearly plans are available.</span>
                  </li>
                  <li className="flex gap-3">
                    <span className="text-[var(--accent-primary)]">•</span>
                    <span><strong className="text-[var(--foreground)]">Free Trial:</strong> New subscribers may be eligible for a free trial period. If you do not cancel before the trial ends, you will be charged.</span>
                  </li>
                  <li className="flex gap-3">
                    <span className="text-[var(--accent-primary)]">•</span>
                    <span><strong className="text-[var(--foreground)]">Billing:</strong> Payment is charged to your Apple ID account at confirmation of purchase.</span>
                  </li>
                  <li className="flex gap-3">
                    <span className="text-[var(--accent-primary)]">•</span>
                    <span><strong className="text-[var(--foreground)]">Auto-Renewal:</strong> Subscriptions automatically renew unless cancelled at least 24 hours before the end of the current period.</span>
                  </li>
                  <li className="flex gap-3">
                    <span className="text-[var(--accent-primary)]">•</span>
                    <span><strong className="text-[var(--foreground)]">Price Changes:</strong> Subscription prices may change. You will be notified in advance of any price changes.</span>
                  </li>
                  <li className="flex gap-3">
                    <span className="text-[var(--accent-primary)]">•</span>
                    <span><strong className="text-[var(--foreground)]">Cancellation:</strong> You may cancel your subscription at any time through your Apple ID account settings.</span>
                  </li>
                  <li className="flex gap-3">
                    <span className="text-[var(--accent-primary)]">•</span>
                    <span><strong className="text-[var(--foreground)]">Refunds:</strong> Refund requests are handled by Apple according to their policies.</span>
                  </li>
                      </ul>
              </section>

              {/* 5. Acceptable Use */}
              <section id="acceptable-use">
                <h2 className="text-xl font-semibold text-[var(--foreground)] mb-4 pb-2 border-b border-[var(--border)]">
                  5. Acceptable Use
                </h2>
                <p className="text-[var(--foreground-muted)] mb-4">You agree not to:</p>
                <ul className="space-y-3 text-[var(--foreground-muted)]">
                  <li className="flex gap-3">
                    <span className="text-[var(--accent-primary)]">•</span>
                    <span>Use the app for any unlawful purpose</span>
                  </li>
                  <li className="flex gap-3">
                    <span className="text-[var(--accent-primary)]">•</span>
                    <span>Attempt to gain unauthorized access to the app's systems or other users' data</span>
                  </li>
                  <li className="flex gap-3">
                    <span className="text-[var(--accent-primary)]">•</span>
                    <span>Interfere with or disrupt the app's functionality</span>
                  </li>
                  <li className="flex gap-3">
                    <span className="text-[var(--accent-primary)]">•</span>
                    <span>Reverse engineer, decompile, or disassemble the app</span>
                  </li>
                  <li className="flex gap-3">
                    <span className="text-[var(--accent-primary)]">•</span>
                    <span>Use automated systems to access the app in a manner that exceeds reasonable use</span>
                  </li>
                      </ul>
              </section>

              {/* 6. Intellectual Property */}
              <section id="intellectual-property">
                <h2 className="text-xl font-semibold text-[var(--foreground)] mb-4 pb-2 border-b border-[var(--border)]">
                  6. Intellectual Property
                </h2>
                <p className="text-[var(--foreground-muted)]">
                  FocusFlow and its original content, features, and functionality are owned by Soft Computers and are protected by copyright, trademark, and other intellectual property laws.
                    </p>
              </section>

              {/* 7. User Content */}
              <section id="user-content">
                <h2 className="text-xl font-semibold text-[var(--foreground)] mb-4 pb-2 border-b border-[var(--border)]">
                  7. User Content
                </h2>
                <ul className="space-y-3 text-[var(--foreground-muted)]">
                  <li className="flex gap-3">
                    <span className="text-[var(--accent-primary)]">•</span>
                    <span>You retain ownership of any content you create within the app (session names, task descriptions, etc.).</span>
                  </li>
                  <li className="flex gap-3">
                    <span className="text-[var(--accent-primary)]">•</span>
                    <span>By using the sync feature, you grant us permission to store and transmit your content to provide the service.</span>
                  </li>
                  <li className="flex gap-3">
                    <span className="text-[var(--accent-primary)]">•</span>
                    <span>We do not claim ownership of your content and will not use it for purposes other than providing the service.</span>
                  </li>
                    </ul>
              </section>

              {/* 8. Data and Privacy */}
              <section id="privacy">
                <h2 className="text-xl font-semibold text-[var(--foreground)] mb-4 pb-2 border-b border-[var(--border)]">
                  8. Data and Privacy
                </h2>
                <p className="text-[var(--foreground-muted)]">
                  Your use of FocusFlow is also governed by our{' '}
                  <Link href="/privacy" className="text-[var(--accent-primary)] hover:underline">Privacy Policy</Link>, 
                      which explains how we collect, use, and protect your information.
                    </p>
              </section>

              {/* 9. Account Deletion */}
              <section id="deletion">
                <h2 className="text-xl font-semibold text-[var(--foreground)] mb-4 pb-2 border-b border-[var(--border)]">
                  9. Account Deletion
                </h2>
                <ul className="space-y-3 text-[var(--foreground-muted)]">
                  <li className="flex gap-3">
                    <span className="text-[var(--accent-primary)]">•</span>
                    <span>You may delete your account at any time through the app's settings.</span>
                  </li>
                  <li className="flex gap-3">
                    <span className="text-[var(--accent-primary)]">•</span>
                    <span>Account deletion will permanently remove all your data from our servers.</span>
                  </li>
                  <li className="flex gap-3">
                    <span className="text-[var(--accent-primary)]">•</span>
                    <span>Active subscriptions should be cancelled before deleting your account to avoid further charges.</span>
                  </li>
                    </ul>
              </section>

              {/* 10. Disclaimers */}
              <section id="disclaimers">
                <h2 className="text-xl font-semibold text-[var(--foreground)] mb-4 pb-2 border-b border-[var(--border)]">
                  10. Disclaimers
                </h2>
                <ul className="space-y-3 text-[var(--foreground-muted)]">
                  <li className="flex gap-3">
                    <span className="text-[var(--accent-primary)]">•</span>
                    <span>FocusFlow is provided "as is" without warranties of any kind, either express or implied.</span>
                  </li>
                  <li className="flex gap-3">
                    <span className="text-[var(--accent-primary)]">•</span>
                    <span>We do not guarantee that the app will be uninterrupted, error-free, or free of harmful components.</span>
                  </li>
                  <li className="flex gap-3">
                    <span className="text-[var(--accent-primary)]">•</span>
                    <span>FocusFlow is a productivity tool and is not intended to provide medical, psychological, or professional advice.</span>
                  </li>
                    </ul>
              </section>

              {/* 11. Limitation of Liability */}
              <section id="liability">
                <h2 className="text-xl font-semibold text-[var(--foreground)] mb-4 pb-2 border-b border-[var(--border)]">
                  11. Limitation of Liability
                </h2>
                <p className="text-[var(--foreground-muted)]">
                  To the maximum extent permitted by law, Soft Computers shall not be liable for any indirect, incidental, special, consequential, or punitive damages arising from your use of the app, including but not limited to loss of data, profits, or goodwill.
                    </p>
              </section>

              {/* 12. Indemnification */}
              <section id="indemnification">
                <h2 className="text-xl font-semibold text-[var(--foreground)] mb-4 pb-2 border-b border-[var(--border)]">
                  12. Indemnification
                </h2>
                <p className="text-[var(--foreground-muted)]">
                  You agree to indemnify and hold harmless Soft Computers from any claims, damages, or expenses arising from your use of the app or violation of these Terms.
                    </p>
              </section>

              {/* 13. Changes to Terms */}
              <section id="changes">
                <h2 className="text-xl font-semibold text-[var(--foreground)] mb-4 pb-2 border-b border-[var(--border)]">
                  13. Changes to Terms
                </h2>
                <p className="text-[var(--foreground-muted)]">
                  We may update these Terms from time to time. The latest version will be posted here with an updated effective date. Continued use of the app after changes constitutes acceptance of the new Terms.
                    </p>
              </section>

              {/* 14. Termination */}
              <section id="termination">
                <h2 className="text-xl font-semibold text-[var(--foreground)] mb-4 pb-2 border-b border-[var(--border)]">
                  14. Termination
                </h2>
                <p className="text-[var(--foreground-muted)]">
                  We reserve the right to suspend or terminate your access to FocusFlow at any time for violation of these Terms or for any other reason at our discretion.
                    </p>
              </section>

              {/* 15. Governing Law */}
              <section id="governing-law">
                <h2 className="text-xl font-semibold text-[var(--foreground)] mb-4 pb-2 border-b border-[var(--border)]">
                  15. Governing Law
                </h2>
                <p className="text-[var(--foreground-muted)]">
                  These Terms shall be governed by and construed in accordance with the laws of Canada, without regard to its conflict of law provisions.
                    </p>
              </section>

              {/* 16. Contact */}
              <section id="contact">
                <h2 className="text-xl font-semibold text-[var(--foreground)] mb-4 pb-2 border-b border-[var(--border)]">
                  16. Contact
                </h2>
                <p className="text-[var(--foreground-muted)]">
                  If you have questions about these Terms, please contact us at{' '}
                  <a href="mailto:Info@softcomputers.ca" className="text-[var(--accent-primary)] hover:underline">Info@softcomputers.ca</a>.
                    </p>
              </section>

            </div>

            {/* Agreement Footer */}
            <div className="mt-16 pt-8 border-t border-[var(--border)]">
              <p className="text-[var(--foreground-muted)] text-center text-sm">
                By using FocusFlow, you acknowledge that you have read, understood, and agree to be bound by these Terms of Service.
              </p>
            </div>

          </div>
        </Container>
      </section>
    </div>
  );
}
