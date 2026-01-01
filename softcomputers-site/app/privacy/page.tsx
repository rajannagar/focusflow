'use client';

import Container from '@/components/ui/Container';
import Link from 'next/link';
import { useThrottledMouse } from '../hooks/useThrottledMouse';

export default function PrivacyPage() {
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
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
              </svg>
              Your Privacy Matters
            </div>
            <h1 className="mb-6">Privacy Policy</h1>
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
                This Privacy Policy explains how FocusFlow – Be Present ("FocusFlow", "the app") handles information.
                Soft Computers ("we", "us") is the developer of FocusFlow.
              </p>
            </div>

            <div className="space-y-6 text-[var(--foreground-muted)] leading-relaxed">
              {[
                {
                  title: '1. Summary',
                  content: (
                    <ul className="list-disc pl-6 space-y-2">
                      <li><strong className="text-[var(--foreground)]">Guest Mode:</strong> your data is stored locally on your device only.</li>
                      <li><strong className="text-[var(--foreground)]">Signed-in Mode (optional):</strong> your data may be synced to a secure cloud backend to support backup and multi-device use.</li>
                      <li>We do not sell personal information and the app is not ad-supported.</li>
                      <li>We do not require photo library access (avatars are symbol-based).</li>
                      <li>You can delete your account and all associated data at any time from within the app.</li>
                    </ul>
                  ),
                },
                {
                  title: '2. Data the app stores',
                  content: (
                    <>
                      <p className="mb-3">Depending on how you use FocusFlow, we may store:</p>
                      <ul className="list-disc pl-6 space-y-2">
                        <li><strong className="text-[var(--foreground)]">Account data (Signed-in Mode only):</strong> email address (if provided), display name, and authentication identifiers needed to keep you signed in.</li>
                        <li><strong className="text-[var(--foreground)]">Focus data:</strong> session duration, timestamps, session names/intentions, and derived stats such as totals, streaks, and XP.</li>
                        <li><strong className="text-[var(--foreground)]">Task data:</strong> task titles, notes, schedules, reminders, duration estimates, and completion records.</li>
                        <li><strong className="text-[var(--foreground)]">Preset data:</strong> custom focus presets including names, durations, and theme preferences.</li>
                        <li><strong className="text-[var(--foreground)]">Settings & preferences:</strong> themes, daily goals, reminder preferences, sound/haptic settings, and avatar selection.</li>
                        <li><strong className="text-[var(--foreground)]">Subscription data:</strong> if you subscribe to FocusFlow Pro, Apple handles all payment information. We only receive confirmation of your subscription status.</li>
                      </ul>
                    </>
                  ),
                },
                {
                  title: '3. Where your data is stored',
                  content: (
                    <>
                      <ul className="list-disc pl-6 space-y-2">
                        <li><strong className="text-[var(--foreground)]">Guest Mode:</strong> on your device only. Data is never sent to our servers.</li>
                        <li><strong className="text-[var(--foreground)]">Signed-in Mode:</strong> synced to a secure cloud backend (Supabase) used to provide the service.</li>
                      </ul>
                      <p className="mt-3">
                        We use access controls and row-level security designed to isolate each user's data and prevent mixing between accounts.
                      </p>
                    </>
                  ),
                },
                {
                  title: '4. What we do not collect',
                  content: (
                    <ul className="list-disc pl-6 space-y-2">
                      <li>We do not request access to your photos, contacts, or precise location.</li>
                      <li>We do not use analytics or tracking SDKs.</li>
                      <li>We do not display advertisements.</li>
                      <li>We do not sell personal information.</li>
                    </ul>
                  ),
                },
                {
                  title: '5. How we use data',
                  content: (
                    <ul className="list-disc pl-6 space-y-2">
                      <li>To provide the app's features (focus sessions, tasks, progress tracking, achievements, personalization).</li>
                      <li>To sync your data across devices when you choose to sign in.</li>
                      <li>To provide cloud backup of your data.</li>
                      <li>To respond to support requests and improve app reliability.</li>
                    </ul>
                  ),
                },
                {
                  title: '6. Sharing',
                  content: (
                    <>
                      <p className="mb-3">We share data only when necessary to operate the service:</p>
                      <ul className="list-disc pl-6 space-y-2">
                        <li><strong className="text-[var(--foreground)]">Cloud infrastructure:</strong> We use Supabase for authentication and database hosting.</li>
                        <li><strong className="text-[var(--foreground)]">Authentication providers:</strong> If you sign in with Apple or Google, those services receive standard authentication data.</li>
                        <li><strong className="text-[var(--foreground)]">Legal requirements:</strong> We may disclose data if required by law.</li>
                      </ul>
                      <p className="mt-3">We do not sell personal information to third parties.</p>
                    </>
                  ),
                },
                {
                  title: '7. Diagnostics',
                  content: (
                    <p>
                      iOS may generate diagnostics such as crash logs depending on your device settings.
                      If diagnostics are available to us through App Store Connect, we use them only to troubleshoot and improve app stability.
                    </p>
                  ),
                },
                {
                  title: '8. Retention',
                  content: (
                    <ul className="list-disc pl-6 space-y-2">
                      <li><strong className="text-[var(--foreground)]">Guest Mode:</strong> data remains on your device until you delete the app or use the "Reset All Data" feature in settings.</li>
                      <li><strong className="text-[var(--foreground)]">Signed-in Mode:</strong> synced data is retained to provide the service until you delete your account.</li>
                      <li><strong className="text-[var(--foreground)]">After account deletion:</strong> all your data is permanently removed from our servers.</li>
                    </ul>
                  ),
                },
                {
                  title: '9. Your rights and requests',
                  content: (
                    <>
                      <p className="mb-3">You have the right to:</p>
                      <ul className="list-disc pl-6 space-y-2">
                        <li><strong className="text-[var(--foreground)]">Access your data:</strong> View all your data within the app (Profile, Progress, Tasks, Settings).</li>
                        <li><strong className="text-[var(--foreground)]">Export your data:</strong> Use the backup feature to export your data as a JSON file.</li>
                        <li><strong className="text-[var(--foreground)]">Delete your data:</strong> Use "Delete Account" in the app settings to permanently remove all your data from our servers.</li>
                        <li><strong className="text-[var(--foreground)]">Contact us:</strong> Email <a href="mailto:Info@softcomputers.ca" className="text-[var(--accent-primary)] hover:text-[var(--accent-primary-light)] transition-colors">Info@softcomputers.ca</a> for any privacy-related requests.</li>
                      </ul>
                    </>
                  ),
                },
                {
                  title: '10. Account deletion',
                  content: (
                    <>
                      <p className="mb-3">You can delete your account at any time from within the app:</p>
                      <ul className="list-disc pl-6 space-y-2">
                        <li>Go to Profile → Settings → Delete Account</li>
                        <li>Confirm deletion by typing "DELETE"</li>
                        <li>All your data will be permanently removed from our servers</li>
                        <li>This action cannot be undone</li>
                      </ul>
                      <p className="mt-3">
                        Note: If you have an active FocusFlow Pro subscription, please cancel it through your Apple ID settings before deleting your account to avoid future charges.
                      </p>
                    </>
                  ),
                },
                {
                  title: '11. Children\'s privacy',
                  content: (
                    <p>
                      FocusFlow is not directed at children under 13. We do not knowingly collect personal information from children under 13. 
                      If you believe a child has provided us with personal information, please contact us.
                    </p>
                  ),
                },
                {
                  title: '12. Changes',
                  content: (
                    <p>
                      We may update this Privacy Policy from time to time. The latest version will be posted here with an updated effective date.
                      We encourage you to review this policy periodically.
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
                Questions about privacy? Contact <a href="mailto:Info@softcomputers.ca" className="text-[var(--accent-primary)] hover:text-[var(--accent-primary-light)] transition-colors font-medium">Info@softcomputers.ca</a>
              </p>
            </div>
          </div>
        </Container>
      </section>
    </div>
  );
}
