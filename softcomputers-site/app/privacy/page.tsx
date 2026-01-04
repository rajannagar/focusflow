'use client';

import Link from 'next/link';
import { Container } from '@/components';
import { CONTACT_EMAIL } from '@/lib/constants';

export default function PrivacyPage() {
  const sections = [
    { id: 'summary', title: 'Summary' },
    { id: 'data-stored', title: 'Data the App Stores' },
    { id: 'data-location', title: 'Where Your Data is Stored' },
    { id: 'not-collected', title: 'What We Do Not Collect' },
    { id: 'data-use', title: 'How We Use Data' },
    { id: 'sharing', title: 'Sharing' },
    { id: 'diagnostics', title: 'Diagnostics' },
    { id: 'retention', title: 'Retention' },
    { id: 'your-rights', title: 'Your Rights' },
    { id: 'account-deletion', title: 'Account Deletion' },
    { id: 'children', title: "Children's Privacy" },
    { id: 'changes', title: 'Changes' },
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
              <span>Privacy Policy</span>
            </div>
            <h1 className="text-3xl md:text-4xl font-bold text-[var(--foreground)] mb-4">Privacy Policy</h1>
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
                This Privacy Policy explains how FocusFlow - Be Present ("FocusFlow", "the app") handles your information. 
                Soft Computers ("we", "us") is the developer of FocusFlow.
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
              
              {/* 1. Summary */}
              <section id="summary">
                <h2 className="text-xl font-semibold text-[var(--foreground)] mb-4 pb-2 border-b border-[var(--border)]">
                  1. Summary
                </h2>
                <ul className="space-y-3 text-[var(--foreground-muted)]">
                  <li className="flex gap-3">
                    <span className="text-[var(--accent-primary)]">•</span>
                    <span><strong className="text-[var(--foreground)]">Guest Mode:</strong> Your data is stored locally on your device only.</span>
                  </li>
                  <li className="flex gap-3">
                    <span className="text-[var(--accent-primary)]">•</span>
                    <span><strong className="text-[var(--foreground)]">Signed-in Mode:</strong> Your data may be synced to a secure cloud backend to support backup and multi-device use.</span>
                  </li>
                  <li className="flex gap-3">
                    <span className="text-[var(--accent-primary)]">•</span>
                    <span>We do not sell personal information and the app is not ad-supported.</span>
                  </li>
                  <li className="flex gap-3">
                    <span className="text-[var(--accent-primary)]">•</span>
                    <span>We do not require photo library access (avatars are symbol-based).</span>
                  </li>
                  <li className="flex gap-3">
                    <span className="text-[var(--accent-primary)]">•</span>
                    <span>You can delete your account and all associated data at any time from within the app.</span>
                  </li>
                    </ul>
              </section>

              {/* 2. Data the App Stores */}
              <section id="data-stored">
                <h2 className="text-xl font-semibold text-[var(--foreground)] mb-4 pb-2 border-b border-[var(--border)]">
                  2. Data the App Stores
                </h2>
                <p className="text-[var(--foreground-muted)] mb-4">Depending on how you use FocusFlow, we may store:</p>
                <ul className="space-y-3 text-[var(--foreground-muted)]">
                  <li className="flex gap-3">
                    <span className="text-[var(--accent-primary)]">•</span>
                    <span><strong className="text-[var(--foreground)]">Account data (Signed-in Mode only):</strong> Email address (if provided), display name, and authentication identifiers.</span>
                  </li>
                  <li className="flex gap-3">
                    <span className="text-[var(--accent-primary)]">•</span>
                    <span><strong className="text-[var(--foreground)]">Focus data:</strong> Session duration, timestamps, session names/intentions, and derived stats.</span>
                  </li>
                  <li className="flex gap-3">
                    <span className="text-[var(--accent-primary)]">•</span>
                    <span><strong className="text-[var(--foreground)]">Task data:</strong> Task titles, notes, schedules, reminders, duration estimates, and completion records.</span>
                  </li>
                  <li className="flex gap-3">
                    <span className="text-[var(--accent-primary)]">•</span>
                    <span><strong className="text-[var(--foreground)]">Preset data:</strong> Custom focus presets including names, durations, and theme preferences.</span>
                  </li>
                  <li className="flex gap-3">
                    <span className="text-[var(--accent-primary)]">•</span>
                    <span><strong className="text-[var(--foreground)]">Settings & preferences:</strong> Themes, daily goals, reminder preferences, sound/haptic settings, and avatar selection.</span>
                  </li>
                  <li className="flex gap-3">
                    <span className="text-[var(--accent-primary)]">•</span>
                    <span><strong className="text-[var(--foreground)]">Subscription data:</strong> Apple handles all payment information. We only receive confirmation of your subscription status.</span>
                  </li>
                      </ul>
              </section>

              {/* 3. Where Your Data is Stored */}
              <section id="data-location">
                <h2 className="text-xl font-semibold text-[var(--foreground)] mb-4 pb-2 border-b border-[var(--border)]">
                  3. Where Your Data is Stored
                </h2>
                <ul className="space-y-3 text-[var(--foreground-muted)] mb-4">
                  <li className="flex gap-3">
                    <span className="text-[var(--accent-primary)]">•</span>
                    <span><strong className="text-[var(--foreground)]">Guest Mode:</strong> On your device only. Data is never sent to our servers.</span>
                  </li>
                  <li className="flex gap-3">
                    <span className="text-[var(--accent-primary)]">•</span>
                    <span><strong className="text-[var(--foreground)]">Signed-in Mode:</strong> Synced to a secure cloud backend (Supabase) used to provide the service.</span>
                  </li>
                      </ul>
                <p className="text-[var(--foreground-muted)]">
                        We use access controls and row-level security designed to isolate each user's data and prevent mixing between accounts.
                      </p>
              </section>

              {/* 4. What We Do Not Collect */}
              <section id="not-collected">
                <h2 className="text-xl font-semibold text-[var(--foreground)] mb-4 pb-2 border-b border-[var(--border)]">
                  4. What We Do Not Collect
                </h2>
                <ul className="space-y-3 text-[var(--foreground-muted)]">
                  <li className="flex gap-3">
                    <span className="text-[var(--accent-primary)]">•</span>
                    <span>We do not request access to your photos, contacts, or precise location.</span>
                  </li>
                  <li className="flex gap-3">
                    <span className="text-[var(--accent-primary)]">•</span>
                    <span>We do not use analytics or tracking SDKs.</span>
                  </li>
                  <li className="flex gap-3">
                    <span className="text-[var(--accent-primary)]">•</span>
                    <span>We do not display advertisements.</span>
                  </li>
                  <li className="flex gap-3">
                    <span className="text-[var(--accent-primary)]">•</span>
                    <span>We do not sell personal information.</span>
                  </li>
                    </ul>
              </section>

              {/* 5. How We Use Data */}
              <section id="data-use">
                <h2 className="text-xl font-semibold text-[var(--foreground)] mb-4 pb-2 border-b border-[var(--border)]">
                  5. How We Use Data
                </h2>
                <ul className="space-y-3 text-[var(--foreground-muted)]">
                  <li className="flex gap-3">
                    <span className="text-[var(--accent-primary)]">•</span>
                    <span>To provide the app's features (focus sessions, tasks, progress tracking, achievements, personalization).</span>
                  </li>
                  <li className="flex gap-3">
                    <span className="text-[var(--accent-primary)]">•</span>
                    <span>To sync your data across devices when you choose to sign in.</span>
                  </li>
                  <li className="flex gap-3">
                    <span className="text-[var(--accent-primary)]">•</span>
                    <span>To provide cloud backup of your data.</span>
                  </li>
                  <li className="flex gap-3">
                    <span className="text-[var(--accent-primary)]">•</span>
                    <span>To respond to support requests and improve app reliability.</span>
                  </li>
                    </ul>
              </section>

              {/* 6. Sharing */}
              <section id="sharing">
                <h2 className="text-xl font-semibold text-[var(--foreground)] mb-4 pb-2 border-b border-[var(--border)]">
                  6. Sharing
                </h2>
                <p className="text-[var(--foreground-muted)] mb-4">We share data only when necessary to operate the service:</p>
                <ul className="space-y-3 text-[var(--foreground-muted)] mb-4">
                  <li className="flex gap-3">
                    <span className="text-[var(--accent-primary)]">•</span>
                    <span><strong className="text-[var(--foreground)]">Cloud infrastructure:</strong> We use Supabase for authentication and database hosting.</span>
                  </li>
                  <li className="flex gap-3">
                    <span className="text-[var(--accent-primary)]">•</span>
                    <span><strong className="text-[var(--foreground)]">Authentication providers:</strong> If you sign in with Apple or Google, those services receive standard authentication data.</span>
                  </li>
                  <li className="flex gap-3">
                    <span className="text-[var(--accent-primary)]">•</span>
                    <span><strong className="text-[var(--foreground)]">Legal requirements:</strong> We may disclose data if required by law.</span>
                  </li>
                      </ul>
                <p className="text-[var(--foreground-muted)]">We do not sell personal information to third parties.</p>
              </section>

              {/* 7. Diagnostics */}
              <section id="diagnostics">
                <h2 className="text-xl font-semibold text-[var(--foreground)] mb-4 pb-2 border-b border-[var(--border)]">
                  7. Diagnostics
                </h2>
                <p className="text-[var(--foreground-muted)]">
                  iOS may generate diagnostics such as crash logs depending on your device settings. If diagnostics are available to us through App Store Connect, we use them only to troubleshoot and improve app stability.
                    </p>
              </section>

              {/* 8. Retention */}
              <section id="retention">
                <h2 className="text-xl font-semibold text-[var(--foreground)] mb-4 pb-2 border-b border-[var(--border)]">
                  8. Retention
                </h2>
                <ul className="space-y-3 text-[var(--foreground-muted)]">
                  <li className="flex gap-3">
                    <span className="text-[var(--accent-primary)]">•</span>
                    <span><strong className="text-[var(--foreground)]">Guest Mode:</strong> Data remains on your device until you delete the app or use the "Reset All Data" feature.</span>
                  </li>
                  <li className="flex gap-3">
                    <span className="text-[var(--accent-primary)]">•</span>
                    <span><strong className="text-[var(--foreground)]">Signed-in Mode:</strong> Synced data is retained to provide the service until you delete your account.</span>
                  </li>
                  <li className="flex gap-3">
                    <span className="text-[var(--accent-primary)]">•</span>
                    <span><strong className="text-[var(--foreground)]">After account deletion:</strong> All your data is permanently removed from our servers.</span>
                  </li>
                    </ul>
              </section>

              {/* 9. Your Rights */}
              <section id="your-rights">
                <h2 className="text-xl font-semibold text-[var(--foreground)] mb-4 pb-2 border-b border-[var(--border)]">
                  9. Your Rights
                </h2>
                <p className="text-[var(--foreground-muted)] mb-4">You have the right to:</p>
                <ul className="space-y-3 text-[var(--foreground-muted)]">
                  <li className="flex gap-3">
                    <span className="text-[var(--accent-primary)]">•</span>
                    <span><strong className="text-[var(--foreground)]">Access your data:</strong> View all your data within the app (Profile, Progress, Tasks, Settings).</span>
                  </li>
                  <li className="flex gap-3">
                    <span className="text-[var(--accent-primary)]">•</span>
                    <span><strong className="text-[var(--foreground)]">Export your data:</strong> Use the backup feature to export your data as a JSON file.</span>
                  </li>
                  <li className="flex gap-3">
                    <span className="text-[var(--accent-primary)]">•</span>
                    <span><strong className="text-[var(--foreground)]">Delete your data:</strong> Use "Delete Account" in the app settings to permanently remove all your data.</span>
                  </li>
                  <li className="flex gap-3">
                    <span className="text-[var(--accent-primary)]">•</span>
                    <span><strong className="text-[var(--foreground)]">Contact us:</strong> Email <a href="mailto:Info@softcomputers.ca" className="text-[var(--accent-primary)] hover:underline">Info@softcomputers.ca</a> for any privacy-related requests.</span>
                  </li>
                      </ul>
              </section>

              {/* 10. Account Deletion */}
              <section id="account-deletion">
                <h2 className="text-xl font-semibold text-[var(--foreground)] mb-4 pb-2 border-b border-[var(--border)]">
                  10. Account Deletion
                </h2>
                <p className="text-[var(--foreground-muted)] mb-4">You can delete your account at any time from within the app:</p>
                <ol className="space-y-2 text-[var(--foreground-muted)] mb-4 list-decimal list-inside">
                        <li>Go to Profile → Settings → Delete Account</li>
                        <li>Confirm deletion by typing "DELETE"</li>
                        <li>All your data will be permanently removed from our servers</li>
                        <li>This action cannot be undone</li>
                </ol>
                <p className="text-[var(--foreground-muted)] text-sm italic">
                  Note: If you have an active FocusFlow Pro subscription, please cancel it through your Apple ID settings before deleting your account.
                      </p>
              </section>

              {/* 11. Children's Privacy */}
              <section id="children">
                <h2 className="text-xl font-semibold text-[var(--foreground)] mb-4 pb-2 border-b border-[var(--border)]">
                  11. Children's Privacy
                </h2>
                <p className="text-[var(--foreground-muted)]">
                  FocusFlow is not directed at children under 13. We do not knowingly collect personal information from children under 13. If you believe a child has provided us with personal information, please contact us.
                    </p>
              </section>

              {/* 12. Changes */}
              <section id="changes">
                <h2 className="text-xl font-semibold text-[var(--foreground)] mb-4 pb-2 border-b border-[var(--border)]">
                  12. Changes
                </h2>
                <p className="text-[var(--foreground-muted)]">
                  We may update this Privacy Policy from time to time. The latest version will be posted here with an updated effective date. We encourage you to review this policy periodically.
                    </p>
              </section>

            </div>

            {/* Contact Footer */}
            <div className="mt-16 pt-8 border-t border-[var(--border)]">
              <p className="text-[var(--foreground-muted)] text-center">
                Questions about this policy? Contact us at{' '}
                <a href="mailto:Info@softcomputers.ca" className="text-[var(--accent-primary)] hover:underline font-medium">
                  Info@softcomputers.ca
                </a>
              </p>
            </div>

          </div>
        </Container>
      </section>
    </div>
  );
}
