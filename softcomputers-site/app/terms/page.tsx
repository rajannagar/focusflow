'use client';

import Container from '@/components/ui/Container';
import Link from 'next/link';
import { useEffect, useState } from 'react';

export default function TermsPage() {
  const effectiveDate = new Date().toLocaleDateString('en-US', { 
    year: 'numeric', 
    month: 'long', 
    day: 'numeric' 
  });

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
              Terms of Service
            </h1>
            <p className="text-xl text-[var(--muted)] leading-relaxed max-w-3xl">
              Effective date: {effectiveDate}<br/>
              Contact: <a href="mailto:Info@softcomputers.ca" className="text-[var(--accent-primary)] hover:underline">Info@softcomputers.ca</a>
            </p>
          </div>
        </Container>
      </section>

      {/* Content Section */}
      <section className="py-24 bg-[var(--soft)]">
        <Container>
          <div className="max-w-3xl mx-auto">
            <div className="card p-10 mb-12">
              <p className="text-lg text-[var(--muted)] leading-relaxed">
                These Terms of Service ("Terms") govern your use of FocusFlow – Be Present ("FocusFlow", "the app").
                By using FocusFlow, you agree to these Terms. Soft Computers ("we", "us") is the developer of FocusFlow.
              </p>
            </div>

            <div className="space-y-12 text-[var(--muted)] leading-relaxed">
              <section className="card p-10">
                <h2 className="text-2xl font-semibold tracking-tight mb-4 text-[var(--foreground)]">1. Acceptance of Terms</h2>
                <p>
                  By downloading, installing, or using FocusFlow, you agree to be bound by these Terms. 
                  If you do not agree to these Terms, do not use the app.
                </p>
              </section>

              <section className="card p-10">
                <h2 className="text-2xl font-semibold tracking-tight mb-4 text-[var(--foreground)]">2. Description of Service</h2>
                <p className="mb-3">FocusFlow is a productivity application that helps you:</p>
                <ul className="list-disc pl-6 space-y-2">
                  <li>Track focus sessions with customizable durations and 14 ambient backgrounds</li>
                  <li>Manage tasks with reminders, recurring schedules, and duration estimates</li>
                  <li>View progress statistics, streaks, XP, levels, and achievements</li>
                  <li>Sync data across devices (with an account) or use Guest Mode for local-only storage</li>
                  <li>Customize your experience with 10 themes, avatars, and focus presets</li>
                </ul>
              </section>

              <section className="card p-10">
                <h2 className="text-2xl font-semibold tracking-tight mb-4 text-[var(--foreground)]">3. User Accounts</h2>
                <ul className="list-disc pl-6 space-y-2">
                  <li><strong>Guest Mode:</strong> You may use FocusFlow without creating an account. Data is stored locally on your device.</li>
                  <li><strong>Signed-in Mode:</strong> You may create an account using Apple, Google, or email authentication. This enables cloud sync and backup.</li>
                  <li>You are responsible for maintaining the security of your account credentials.</li>
                  <li>You must provide accurate information when creating an account.</li>
                </ul>
              </section>

              <section className="card p-10">
                <h2 className="text-2xl font-semibold tracking-tight mb-4 text-[var(--foreground)]">4. FocusFlow Pro Subscription</h2>
                <p className="mb-3">FocusFlow offers optional paid subscriptions ("FocusFlow Pro") with the following terms:</p>
                <ul className="list-disc pl-6 space-y-2">
                  <li><strong>Subscription Options:</strong> Monthly and yearly plans are available.</li>
                  <li><strong>Free Trial:</strong> New subscribers may be eligible for a free trial period. If you do not cancel before the trial ends, you will be charged.</li>
                  <li><strong>Billing:</strong> Payment is charged to your Apple ID account at confirmation of purchase.</li>
                  <li><strong>Auto-Renewal:</strong> Subscriptions automatically renew unless cancelled at least 24 hours before the end of the current period.</li>
                  <li><strong>Price Changes:</strong> Subscription prices may change. You will be notified in advance of any price changes.</li>
                  <li><strong>Cancellation:</strong> You may cancel your subscription at any time through your Apple ID account settings. Cancellation takes effect at the end of the current billing period.</li>
                  <li><strong>Refunds:</strong> Refund requests are handled by Apple according to their policies.</li>
                </ul>
              </section>

              <section className="card p-10">
                <h2 className="text-2xl font-semibold tracking-tight mb-4 text-[var(--foreground)]">5. Acceptable Use</h2>
                <p className="mb-3">You agree not to:</p>
                <ul className="list-disc pl-6 space-y-2">
                  <li>Use the app for any unlawful purpose</li>
                  <li>Attempt to gain unauthorized access to the app's systems or other users' data</li>
                  <li>Interfere with or disrupt the app's functionality</li>
                  <li>Reverse engineer, decompile, or disassemble the app</li>
                  <li>Use automated systems to access the app in a manner that exceeds reasonable use</li>
                </ul>
              </section>

              <section className="card p-10">
                <h2 className="text-2xl font-semibold tracking-tight mb-4 text-[var(--foreground)]">6. Intellectual Property</h2>
                <p>
                  FocusFlow and its original content, features, and functionality are owned by Soft Computers 
                  and are protected by copyright, trademark, and other intellectual property laws.
                </p>
              </section>

              <section className="card p-10">
                <h2 className="text-2xl font-semibold tracking-tight mb-4 text-[var(--foreground)]">7. User Content</h2>
                <ul className="list-disc pl-6 space-y-2">
                  <li>You retain ownership of any content you create within the app (session names, task descriptions, etc.).</li>
                  <li>By using the sync feature, you grant us permission to store and transmit your content to provide the service.</li>
                  <li>We do not claim ownership of your content and will not use it for purposes other than providing the service.</li>
                </ul>
              </section>

              <section className="card p-10">
                <h2 className="text-2xl font-semibold tracking-tight mb-4 text-[var(--foreground)]">8. Data and Privacy</h2>
                <p>
                  Your use of FocusFlow is also governed by our <Link href="/privacy" className="text-[var(--accent-primary)] hover:underline">Privacy Policy</Link>, 
                  which explains how we collect, use, and protect your information.
                </p>
              </section>

              <section className="card p-10">
                <h2 className="text-2xl font-semibold tracking-tight mb-4 text-[var(--foreground)]">9. Account Deletion</h2>
                <ul className="list-disc pl-6 space-y-2">
                  <li>You may delete your account at any time through the app's settings.</li>
                  <li>Account deletion will permanently remove all your data from our servers.</li>
                  <li>Active subscriptions should be cancelled before deleting your account to avoid further charges.</li>
                </ul>
              </section>

              <section className="card p-10">
                <h2 className="text-2xl font-semibold tracking-tight mb-4 text-[var(--foreground)]">10. Disclaimers</h2>
                <ul className="list-disc pl-6 space-y-2">
                  <li>FocusFlow is provided "as is" without warranties of any kind, either express or implied.</li>
                  <li>We do not guarantee that the app will be uninterrupted, error-free, or free of harmful components.</li>
                  <li>FocusFlow is a productivity tool and is not intended to provide medical, psychological, or professional advice.</li>
                </ul>
              </section>

              <section className="card p-10">
                <h2 className="text-2xl font-semibold tracking-tight mb-4 text-[var(--foreground)]">11. Limitation of Liability</h2>
                <p>
                  To the maximum extent permitted by law, Soft Computers shall not be liable for any indirect, 
                  incidental, special, consequential, or punitive damages arising from your use of the app, 
                  including but not limited to loss of data, profits, or goodwill.
                </p>
              </section>

              <section className="card p-10">
                <h2 className="text-2xl font-semibold tracking-tight mb-4 text-[var(--foreground)]">12. Indemnification</h2>
                <p>
                  You agree to indemnify and hold harmless Soft Computers from any claims, damages, or expenses 
                  arising from your use of the app or violation of these Terms.
                </p>
              </section>

              <section className="card p-10">
                <h2 className="text-2xl font-semibold tracking-tight mb-4 text-[var(--foreground)]">13. Changes to Terms</h2>
                <p>
                  We may update these Terms from time to time. The latest version will be posted here with an updated effective date. 
                  Continued use of the app after changes constitutes acceptance of the new Terms.
                </p>
              </section>

              <section className="card p-10">
                <h2 className="text-2xl font-semibold tracking-tight mb-4 text-[var(--foreground)]">14. Termination</h2>
                <p>
                  We reserve the right to suspend or terminate your access to FocusFlow at any time for violation of these Terms 
                  or for any other reason at our discretion.
                </p>
              </section>

              <section className="card p-10">
                <h2 className="text-2xl font-semibold tracking-tight mb-4 text-[var(--foreground)]">15. Governing Law</h2>
                <p>
                  These Terms shall be governed by and construed in accordance with the laws of Canada, 
                  without regard to its conflict of law provisions.
                </p>
              </section>

              <section className="card p-10">
                <h2 className="text-2xl font-semibold tracking-tight mb-4 text-[var(--foreground)]">16. Contact</h2>
                <p>
                  If you have questions about these Terms, please contact us at 
                  <a href="mailto:Info@softcomputers.ca" className="text-[var(--accent-primary)] hover:underline"> Info@softcomputers.ca</a>.
                </p>
              </section>
            </div>

            <div className="mt-16 card p-10">
              <p className="text-[var(--muted)]">
                By using FocusFlow, you acknowledge that you have read, understood, and agree to be bound by these Terms of Service.
              </p>
            </div>
          </div>
        </Container>
      </section>
    </div>
  );
}
