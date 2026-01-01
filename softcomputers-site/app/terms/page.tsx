'use client';

import Container from '@/components/ui/Container';
import Link from 'next/link';
import { useThrottledMouse } from '../hooks/useThrottledMouse';

export default function TermsPage() {
  const effectiveDate = new Date().toLocaleDateString('en-US', { 
    year: 'numeric', 
    month: 'long', 
    day: 'numeric' 
  });

  const mousePosition = useThrottledMouse();

  return (
    <div className="min-h-screen bg-[var(--background)]">
      
      {/* Hero Section */}
      <section className="relative pt-20 md:pt-40 pb-12 md:pb-16 overflow-hidden">
        <div className="absolute inset-0">
          <div 
            className="absolute top-1/4 left-1/4 w-[500px] h-[500px] rounded-full blur-[80px] opacity-15 transition-transform duration-1000 ease-out"
            style={{
              background: `radial-gradient(circle, rgba(139, 92, 246, 0.4) 0%, transparent 70%)`,
              transform: `translate(${mousePosition.x * 0.02}px, ${mousePosition.y * 0.02}px)`,
            }}
          />
        </div>
        <div className="absolute inset-0 bg-grid opacity-20" />

        <Container>
          <div className="max-w-4xl relative z-10">
            <div className="inline-flex items-center gap-2 badge badge-primary mb-8">
              <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
              </svg>
              Legal
            </div>
            <h1 className="mb-6">Terms of Service</h1>
            <p className="text-xl text-[var(--foreground-muted)] leading-relaxed">
              Effective date: {effectiveDate}<br/>
              Contact: <a href="mailto:Info@softcomputers.ca" className="text-[var(--accent-primary)] hover:text-[var(--accent-primary-light)] transition-colors">Info@softcomputers.ca</a>
            </p>
          </div>
        </Container>
      </section>

      {/* Content Section */}
      <section className="section-padding bg-[var(--background-elevated)]">
        <Container>
          <div className="max-w-3xl mx-auto">
            <div className="card-glass p-8 mb-12">
              <p className="text-lg text-[var(--foreground-muted)] leading-relaxed">
                These Terms of Service ("Terms") govern your use of FocusFlow – Be Present ("FocusFlow", "the app").
                By using FocusFlow, you agree to these Terms. Soft Computers ("we", "us") is the developer of FocusFlow.
              </p>
            </div>

            <div className="space-y-6 text-[var(--foreground-muted)] leading-relaxed">
              {[
                {
                  title: '1. Acceptance of Terms',
                  content: (
                    <p>
                      By downloading, installing, or using FocusFlow, you agree to be bound by these Terms. 
                      If you do not agree to these Terms, do not use the app.
                    </p>
                  ),
                },
                {
                  title: '2. Description of Service',
                  content: (
                    <>
                      <p className="mb-3">FocusFlow is a productivity application that helps you:</p>
                      <ul className="list-disc pl-6 space-y-2">
                        <li>Track focus sessions with customizable durations and 14 ambient backgrounds</li>
                        <li>Manage tasks with reminders, recurring schedules, and duration estimates</li>
                        <li>View progress statistics, streaks, XP, levels, and achievements</li>
                        <li>Sync data across devices (with an account) or use Guest Mode for local-only storage</li>
                        <li>Customize your experience with 10 themes, avatars, and focus presets</li>
                      </ul>
                    </>
                  ),
                },
                {
                  title: '3. User Accounts',
                  content: (
                    <ul className="list-disc pl-6 space-y-2">
                      <li><strong className="text-[var(--foreground)]">Guest Mode:</strong> You may use FocusFlow without creating an account. Data is stored locally on your device.</li>
                      <li><strong className="text-[var(--foreground)]">Signed-in Mode:</strong> You may create an account using Apple, Google, or email authentication. This enables cloud sync and backup.</li>
                      <li>You are responsible for maintaining the security of your account credentials.</li>
                      <li>You must provide accurate information when creating an account.</li>
                    </ul>
                  ),
                },
                {
                  title: '4. FocusFlow Pro Subscription',
                  content: (
                    <>
                      <p className="mb-3">FocusFlow offers optional paid subscriptions ("FocusFlow Pro") with the following terms:</p>
                      <ul className="list-disc pl-6 space-y-2">
                        <li><strong className="text-[var(--foreground)]">Subscription Options:</strong> Monthly and yearly plans are available.</li>
                        <li><strong className="text-[var(--foreground)]">Free Trial:</strong> New subscribers may be eligible for a free trial period. If you do not cancel before the trial ends, you will be charged.</li>
                        <li><strong className="text-[var(--foreground)]">Billing:</strong> Payment is charged to your Apple ID account at confirmation of purchase.</li>
                        <li><strong className="text-[var(--foreground)]">Auto-Renewal:</strong> Subscriptions automatically renew unless cancelled at least 24 hours before the end of the current period.</li>
                        <li><strong className="text-[var(--foreground)]">Price Changes:</strong> Subscription prices may change. You will be notified in advance of any price changes.</li>
                        <li><strong className="text-[var(--foreground)]">Cancellation:</strong> You may cancel your subscription at any time through your Apple ID account settings. Cancellation takes effect at the end of the current billing period.</li>
                        <li><strong className="text-[var(--foreground)]">Refunds:</strong> Refund requests are handled by Apple according to their policies.</li>
                      </ul>
                    </>
                  ),
                },
                {
                  title: '5. Acceptable Use',
                  content: (
                    <>
                      <p className="mb-3">You agree not to:</p>
                      <ul className="list-disc pl-6 space-y-2">
                        <li>Use the app for any unlawful purpose</li>
                        <li>Attempt to gain unauthorized access to the app's systems or other users' data</li>
                        <li>Interfere with or disrupt the app's functionality</li>
                        <li>Reverse engineer, decompile, or disassemble the app</li>
                        <li>Use automated systems to access the app in a manner that exceeds reasonable use</li>
                      </ul>
                    </>
                  ),
                },
                {
                  title: '6. Intellectual Property',
                  content: (
                    <p>
                      FocusFlow and its original content, features, and functionality are owned by Soft Computers 
                      and are protected by copyright, trademark, and other intellectual property laws.
                    </p>
                  ),
                },
                {
                  title: '7. User Content',
                  content: (
                    <ul className="list-disc pl-6 space-y-2">
                      <li>You retain ownership of any content you create within the app (session names, task descriptions, etc.).</li>
                      <li>By using the sync feature, you grant us permission to store and transmit your content to provide the service.</li>
                      <li>We do not claim ownership of your content and will not use it for purposes other than providing the service.</li>
                    </ul>
                  ),
                },
                {
                  title: '8. Data and Privacy',
                  content: (
                    <p>
                      Your use of FocusFlow is also governed by our <Link href="/privacy" className="text-[var(--accent-primary)] hover:text-[var(--accent-primary-light)] transition-colors">Privacy Policy</Link>, 
                      which explains how we collect, use, and protect your information.
                    </p>
                  ),
                },
                {
                  title: '9. Account Deletion',
                  content: (
                    <ul className="list-disc pl-6 space-y-2">
                      <li>You may delete your account at any time through the app's settings.</li>
                      <li>Account deletion will permanently remove all your data from our servers.</li>
                      <li>Active subscriptions should be cancelled before deleting your account to avoid further charges.</li>
                    </ul>
                  ),
                },
                {
                  title: '10. Disclaimers',
                  content: (
                    <ul className="list-disc pl-6 space-y-2">
                      <li>FocusFlow is provided "as is" without warranties of any kind, either express or implied.</li>
                      <li>We do not guarantee that the app will be uninterrupted, error-free, or free of harmful components.</li>
                      <li>FocusFlow is a productivity tool and is not intended to provide medical, psychological, or professional advice.</li>
                    </ul>
                  ),
                },
                {
                  title: '11. Limitation of Liability',
                  content: (
                    <p>
                      To the maximum extent permitted by law, Soft Computers shall not be liable for any indirect, 
                      incidental, special, consequential, or punitive damages arising from your use of the app, 
                      including but not limited to loss of data, profits, or goodwill.
                    </p>
                  ),
                },
                {
                  title: '12. Indemnification',
                  content: (
                    <p>
                      You agree to indemnify and hold harmless Soft Computers from any claims, damages, or expenses 
                      arising from your use of the app or violation of these Terms.
                    </p>
                  ),
                },
                {
                  title: '13. Changes to Terms',
                  content: (
                    <p>
                      We may update these Terms from time to time. The latest version will be posted here with an updated effective date. 
                      Continued use of the app after changes constitutes acceptance of the new Terms.
                    </p>
                  ),
                },
                {
                  title: '14. Termination',
                  content: (
                    <p>
                      We reserve the right to suspend or terminate your access to FocusFlow at any time for violation of these Terms 
                      or for any other reason at our discretion.
                    </p>
                  ),
                },
                {
                  title: '15. Governing Law',
                  content: (
                    <p>
                      These Terms shall be governed by and construed in accordance with the laws of Canada, 
                      without regard to its conflict of law provisions.
                    </p>
                  ),
                },
                {
                  title: '16. Contact',
                  content: (
                    <p>
                      If you have questions about these Terms, please contact us at 
                      <a href="mailto:Info@softcomputers.ca" className="text-[var(--accent-primary)] hover:text-[var(--accent-primary-light)] transition-colors"> Info@softcomputers.ca</a>.
                    </p>
                  ),
                },
              ].map((section, i) => (
                <div key={i} className="card p-8">
                  <h2 className="text-xl font-semibold tracking-tight mb-4 text-[var(--foreground)]">{section.title}</h2>
                  {section.content}
                </div>
              ))}
            </div>

            <div className="mt-12 card-glass p-8 text-center">
              <p className="text-[var(--foreground-muted)]">
                By using FocusFlow, you acknowledge that you have read, understood, and agree to be bound by these Terms of Service.
              </p>
            </div>
          </div>
        </Container>
      </section>
    </div>
  );
}
