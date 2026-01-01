'use client';

import Container from '@/components/ui/Container';
import Link from 'next/link';
import { useEffect, useState } from 'react';

export default function PrivacyPage() {
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
              Privacy Policy
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
                This Privacy Policy explains how FocusFlow – Be Present ("FocusFlow", "the app") handles information.
                Soft Computers ("we", "us") is the developer of FocusFlow.
              </p>
            </div>

            <div className="space-y-12 text-[var(--muted)] leading-relaxed">
              <section className="card p-10">
                <h2 className="text-2xl font-semibold tracking-tight mb-4 text-[var(--foreground)]">1. Summary</h2>
                <ul className="list-disc pl-6 space-y-2">
                  <li><strong>Guest Mode:</strong> your data is stored locally on your device only.</li>
                  <li><strong>Signed-in Mode (optional):</strong> your data may be synced to a secure cloud backend to support backup and multi-device use.</li>
                  <li>We do not sell personal information and the app is not ad-supported.</li>
                  <li>We do not require photo library access (avatars are symbol-based).</li>
                  <li>You can delete your account and all associated data at any time from within the app.</li>
                </ul>
              </section>

              <section className="card p-10">
                <h2 className="text-2xl font-semibold tracking-tight mb-4 text-[var(--foreground)]">2. Data the app stores</h2>
                <p className="mb-3">Depending on how you use FocusFlow, we may store:</p>
                <ul className="list-disc pl-6 space-y-2">
                  <li><strong>Account data (Signed-in Mode only):</strong> email address (if provided), display name, and authentication identifiers needed to keep you signed in.</li>
                  <li><strong>Focus data:</strong> session duration, timestamps, session names/intentions, and derived stats such as totals, streaks, and XP.</li>
                  <li><strong>Task data:</strong> task titles, notes, schedules, reminders, duration estimates, and completion records.</li>
                  <li><strong>Preset data:</strong> custom focus presets including names, durations, and theme preferences.</li>
                  <li><strong>Settings & preferences:</strong> themes, daily goals, reminder preferences, sound/haptic settings, and avatar selection.</li>
                  <li><strong>Subscription data:</strong> if you subscribe to FocusFlow Pro, Apple handles all payment information. We only receive confirmation of your subscription status.</li>
                </ul>
              </section>

              <section className="card p-10">
                <h2 className="text-2xl font-semibold tracking-tight mb-4 text-[var(--foreground)]">3. Where your data is stored</h2>
                <ul className="list-disc pl-6 space-y-2">
                  <li><strong>Guest Mode:</strong> on your device only. Data is never sent to our servers.</li>
                  <li><strong>Signed-in Mode:</strong> synced to a secure cloud backend (Supabase) used to provide the service.</li>
                </ul>
                <p className="mt-3">
                  We use access controls and row-level security designed to isolate each user's data and prevent mixing between accounts.
                </p>
              </section>

              <section className="card p-10">
                <h2 className="text-2xl font-semibold tracking-tight mb-4 text-[var(--foreground)]">4. What we do not collect</h2>
                <ul className="list-disc pl-6 space-y-2">
                  <li>We do not request access to your photos, contacts, or precise location.</li>
                  <li>We do not use analytics or tracking SDKs.</li>
                  <li>We do not display advertisements.</li>
                  <li>We do not sell personal information.</li>
                </ul>
              </section>

              <section className="card p-10">
                <h2 className="text-2xl font-semibold tracking-tight mb-4 text-[var(--foreground)]">5. How we use data</h2>
                <ul className="list-disc pl-6 space-y-2">
                  <li>To provide the app's features (focus sessions, tasks, progress tracking, achievements, personalization).</li>
                  <li>To sync your data across devices when you choose to sign in.</li>
                  <li>To provide cloud backup of your data.</li>
                  <li>To respond to support requests and improve app reliability.</li>
                </ul>
              </section>

              <section className="card p-10">
                <h2 className="text-2xl font-semibold tracking-tight mb-4 text-[var(--foreground)]">6. Sharing</h2>
                <p className="mb-3">We share data only when necessary to operate the service:</p>
                <ul className="list-disc pl-6 space-y-2">
                  <li><strong>Cloud infrastructure:</strong> We use Supabase for authentication and database hosting.</li>
                  <li><strong>Authentication providers:</strong> If you sign in with Apple or Google, those services receive standard authentication data.</li>
                  <li><strong>Legal requirements:</strong> We may disclose data if required by law.</li>
                </ul>
                <p className="mt-3">We do not sell personal information to third parties.</p>
              </section>

              <section className="card p-10">
                <h2 className="text-2xl font-semibold tracking-tight mb-4 text-[var(--foreground)]">7. Diagnostics</h2>
                <p>
                  iOS may generate diagnostics such as crash logs depending on your device settings.
                  If diagnostics are available to us through App Store Connect, we use them only to troubleshoot and improve app stability.
                </p>
              </section>

              <section className="card p-10">
                <h2 className="text-2xl font-semibold tracking-tight mb-4 text-[var(--foreground)]">8. Retention</h2>
                <ul className="list-disc pl-6 space-y-2">
                  <li><strong>Guest Mode:</strong> data remains on your device until you delete the app or use the "Reset All Data" feature in settings.</li>
                  <li><strong>Signed-in Mode:</strong> synced data is retained to provide the service until you delete your account.</li>
                  <li><strong>After account deletion:</strong> all your data is permanently removed from our servers.</li>
                </ul>
              </section>

              <section className="card p-10">
                <h2 className="text-2xl font-semibold tracking-tight mb-4 text-[var(--foreground)]">9. Your rights and requests</h2>
                <p className="mb-3">You have the right to:</p>
                <ul className="list-disc pl-6 space-y-2">
                  <li><strong>Access your data:</strong> View all your data within the app (Profile, Progress, Tasks, Settings).</li>
                  <li><strong>Export your data:</strong> Use the backup feature to export your data as a JSON file.</li>
                  <li><strong>Delete your data:</strong> Use "Delete Account" in the app settings to permanently remove all your data from our servers.</li>
                  <li><strong>Contact us:</strong> Email <a href="mailto:Info@softcomputers.ca" className="text-[var(--accent-primary)] hover:underline">Info@softcomputers.ca</a> for any privacy-related requests.</li>
                </ul>
              </section>

              <section className="card p-10">
                <h2 className="text-2xl font-semibold tracking-tight mb-4 text-[var(--foreground)]">10. Account deletion</h2>
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
              </section>

              <section className="card p-10">
                <h2 className="text-2xl font-semibold tracking-tight mb-4 text-[var(--foreground)]">11. Children's privacy</h2>
                <p>
                  FocusFlow is not directed at children under 13. We do not knowingly collect personal information from children under 13. 
                  If you believe a child has provided us with personal information, please contact us.
                </p>
              </section>

              <section className="card p-10">
                <h2 className="text-2xl font-semibold tracking-tight mb-4 text-[var(--foreground)]">12. Changes</h2>
                <p>
                  We may update this Privacy Policy from time to time. The latest version will be posted here with an updated effective date.
                  We encourage you to review this policy periodically.
                </p>
              </section>
            </div>

            <div className="mt-16 card p-10">
              <p className="text-[var(--muted)]">
                Questions about privacy? Contact <a href="mailto:Info@softcomputers.ca" className="text-[var(--accent-primary)] hover:underline">Info@softcomputers.ca</a>.
              </p>
            </div>
          </div>
        </Container>
      </section>
    </div>
  );
}
