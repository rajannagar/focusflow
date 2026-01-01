'use client';

import Link from 'next/link';
import Image from 'next/image';
import Container from '@/components/ui/Container';
import PhoneSimulator from '@/components/phone/iPhoneSimulator';
import CurrencySelector from '@/components/ui/CurrencySelector';
import { useEffect, useState } from 'react';

export default function FocusFlowPage() {
  const [mousePosition, setMousePosition] = useState({ x: 0, y: 0 });
  const [selectedCurrency, setSelectedCurrency] = useState<'USD' | 'CAD'>('CAD');

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
      <section className="relative pt-32 pb-24 px-6 overflow-hidden">
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
          <div className="max-w-6xl mx-auto relative z-10">
            <div className="grid md:grid-cols-2 gap-16 items-center">
              <div>
                <div className="flex items-center gap-4 mb-8">
                  <div className="relative flex-shrink-0">
                    <Image
                      src="/focusflow_app_icon.jpg"
                      alt="FocusFlow - Be Present"
                      width={80}
                      height={80}
                      className="rounded-2xl shadow-xl ring-2 ring-[var(--accent-primary)]/30"
                      style={{ objectFit: 'cover' }}
                    />
                    <div className="absolute inset-0 rounded-2xl ring-2 ring-[var(--accent-primary)]/20 animate-pulse" />
                  </div>
                  <div className="flex flex-col justify-center">
                    <h1 className="text-4xl md:text-5xl font-semibold tracking-tight leading-none">
                      FocusFlow
                    </h1>
                    <p className="text-base text-[var(--muted)] mt-1">Be Present</p>
                  </div>
                </div>
                
                <p className="text-2xl text-[var(--muted)] leading-relaxed mb-6 max-w-2xl">
                  The all-in-one app for focused work. A premium focus timer, task manager, and progress tracker designed to help you do deep work and build lasting habits.
                </p>

                <p className="text-lg text-[var(--muted)] leading-relaxed mb-10 max-w-2xl">
                  Everything you need to stay focused, organized, and motivated—all in one beautiful, privacy-first app.
                </p>
                
                <div className="flex flex-col sm:flex-row gap-4 mb-12">
                  <a
                    href="https://apps.apple.com/app/focusflow-be-present/id6739000000"
                    target="_blank"
                    rel="noopener noreferrer"
                    className="btn btn-primary inline-block text-center text-lg px-8 py-4"
                  >
                    Download on App Store
                  </a>
                  <Link
                    href="#features"
                    className="btn btn-secondary inline-block text-center text-lg px-8 py-4"
                  >
                    Explore features
                  </Link>
                </div>

                {/* Quick Stats */}
                <div className="grid grid-cols-3 gap-6">
                  <div className="text-center p-6 rounded-2xl card">
                    <div className="text-3xl font-semibold mb-1 text-[var(--foreground)]">14</div>
                    <div className="text-sm text-[var(--muted)]">Ambient Backgrounds</div>
                  </div>
                  <div className="text-center p-6 rounded-2xl card">
                    <div className="text-3xl font-semibold mb-1 text-[var(--foreground)]">10</div>
                    <div className="text-sm text-[var(--muted)]">Beautiful Themes</div>
                  </div>
                  <div className="text-center p-6 rounded-2xl card">
                    <div className="text-3xl font-semibold mb-1 text-[var(--foreground)]">50+</div>
                    <div className="text-sm text-[var(--muted)]">Levels & Badges</div>
                  </div>
                </div>
              </div>

              <div className="flex justify-center">
                <PhoneSimulator 
                  screenshots={[
                    '/images/screen-focus.png',
                    '/images/screen-tasks.png',
                    '/images/screen-progress.png',
                    '/images/screen-profile.png',
                  ]}
                  screenData={[
                    { icon: '⏱️', title: 'Focus Timer', desc: 'Timed sessions', gradient: 'from-blue-500 to-cyan-500' },
                    { icon: '✅', title: 'Tasks', desc: 'Smart management', gradient: 'from-green-500 to-emerald-500' },
                    { icon: '📈', title: 'Progress', desc: 'Track growth', gradient: 'from-purple-500 to-pink-500' },
                    { icon: '👤', title: 'Profile', desc: 'Customize & sync', gradient: 'from-orange-500 to-red-500' },
                  ]}
                />
              </div>
            </div>
          </div>
        </Container>
      </section>

      {/* What is FocusFlow */}
      <section className="py-24 bg-[var(--soft)]">
        <Container>
          <div className="max-w-5xl mx-auto">
            <div className="text-center mb-16">
              <h2 className="text-4xl md:text-5xl font-semibold tracking-tight mb-4">
                What is FocusFlow?
              </h2>
              <p className="text-lg text-[var(--muted)] leading-relaxed max-w-3xl mx-auto">
                FocusFlow is a premium iOS app that combines three powerful tools into one seamless experience: a focus timer, task manager, and progress tracker. It's designed for people who want to do deep work, stay organized, and build lasting habits.
              </p>
            </div>

            <div className="grid md:grid-cols-3 gap-6">
              {[
                {
                  title: 'Focus Timer',
                  desc: 'Timed sessions with ambient backgrounds and music integration',
                  icon: (
                    <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M12 6v6h4.5m4.5 0a9 9 0 11-18 0 9 9 0 0118 0z" />
                    </svg>
                  ),
                },
                {
                  title: 'Task Manager',
                  desc: 'Smart task management with reminders and recurring schedules',
                  icon: (
                    <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4" />
                    </svg>
                  ),
                },
                {
                  title: 'Progress Tracker',
                  desc: 'Track your growth with XP, levels, streaks, and achievements',
                  icon: (
                    <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
                    </svg>
                  ),
                },
              ].map((item, i) => (
                <div key={i} className="card p-8 text-center">
                  <div className="text-[var(--accent-primary)] mb-4 flex justify-center">
                    {item.icon}
                  </div>
                  <h3 className="text-xl font-semibold mb-3">{item.title}</h3>
                  <p className="text-sm text-[var(--muted)] leading-relaxed">{item.desc}</p>
                </div>
              ))}
            </div>
          </div>
        </Container>
      </section>

      {/* Who It's For */}
      <section className="py-24 bg-[var(--soft)]">
        <Container>
          <div className="max-w-6xl mx-auto">
            <div className="text-center mb-16">
              <h2 className="text-4xl md:text-5xl font-semibold tracking-tight mb-4">
                Who is FocusFlow for?
              </h2>
              <p className="text-lg text-[var(--muted)] leading-relaxed max-w-3xl mx-auto">
                Whether you're a student, professional, entrepreneur, or creative, FocusFlow adapts to your unique needs and helps you achieve your goals.
              </p>
            </div>

            <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-6">
              {[
                {
                  title: 'Students',
                  desc: 'Master study sessions, manage assignments, and build consistent learning habits.',
                  icon: (
                    <svg className="w-10 h-10" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" />
                    </svg>
                  ),
                },
                {
                  title: 'Professionals',
                  desc: 'Boost productivity, manage projects, and achieve career goals with focused work sessions.',
                  icon: (
                    <svg className="w-10 h-10" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M21 13.255A23.931 23.931 0 0112 15c-3.183 0-6.22-.62-9-1.745M16 6V4a2 2 0 00-2-2h-4a2 2 0 00-2 2v2m4 6h.01M5 20h14a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
                    </svg>
                  ),
                },
                {
                  title: 'Entrepreneurs',
                  desc: 'Block time for strategic work, manage priorities, and track progress on key initiatives.',
                  icon: (
                    <svg className="w-10 h-10" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M13 10V3L4 14h7v7l9-11h-7z" />
                    </svg>
                  ),
                },
                {
                  title: 'Creatives',
                  desc: 'Find your flow state, minimize distractions, and bring your creative visions to life.',
                  icon: (
                    <svg className="w-10 h-10" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                    </svg>
                  ),
                },
              ].map((persona, i) => (
                <div key={i} className="card p-8 text-center">
                  <div className="text-[var(--accent-primary)] mb-6 flex justify-center">
                    {persona.icon}
                  </div>
                  <h3 className="text-xl font-semibold mb-3">{persona.title}</h3>
                  <p className="text-sm text-[var(--muted)] leading-relaxed">{persona.desc}</p>
                </div>
              ))}
            </div>
          </div>
        </Container>
      </section>

      {/* Core Features - Focus Timer */}
      <section id="features" className="py-24">
        <Container>
          <div className="max-w-6xl mx-auto">
            <div className="grid md:grid-cols-2 gap-16 items-center mb-24">
              <div>
                <div className="flex items-center gap-4 mb-8">
                  <div className="w-14 h-14 rounded-xl bg-[var(--accent-primary)] flex items-center justify-center text-white">
                    <svg className="w-7 h-7" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M12 6v6h4.5m4.5 0a9 9 0 11-18 0 9 9 0 0118 0z" />
                    </svg>
                  </div>
                  <h2 className="text-4xl md:text-5xl font-semibold tracking-tight">Focus Timer</h2>
                </div>
                <p className="text-lg text-[var(--muted)] leading-relaxed mb-8">
                  Start timed focus sessions with customizable durations. Choose from 14 beautiful ambient backgrounds or connect your favorite music app. Set clear intentions for each session to maximize your productivity.
                </p>
                <div className="space-y-5">
                  <div className="flex items-start gap-4">
                    <div className="w-5 h-5 rounded-full bg-[var(--accent-primary)]/10 flex items-center justify-center flex-shrink-0 mt-0.5">
                      <div className="w-2 h-2 rounded-full bg-[var(--accent-primary)]" />
                    </div>
                    <div>
                      <h3 className="font-semibold mb-1">14 Ambient Backgrounds</h3>
                      <p className="text-sm text-[var(--muted)] leading-relaxed">
                        Minimal, Aurora, Rain, Fireplace, Ocean, Forest, Stars, Gradient Flow, Snow, Underwater, Clouds, Sakura, Lightning, and Lava Lamp. Each designed to help you enter a state of deep focus.
                      </p>
                    </div>
                  </div>
                  <div className="flex items-start gap-4">
                    <div className="w-5 h-5 rounded-full bg-[var(--accent-primary)]/10 flex items-center justify-center flex-shrink-0 mt-0.5">
                      <div className="w-2 h-2 rounded-full bg-[var(--accent-primary)]" />
                    </div>
                    <div>
                      <h3 className="font-semibold mb-1">Music Integration</h3>
                      <p className="text-sm text-[var(--muted)] leading-relaxed">
                        Connect Spotify, Apple Music, or YouTube Music. Launch your favorite playlist directly from FocusFlow. Perfect for those who work best with their own music.
                      </p>
                    </div>
                  </div>
                  <div className="flex items-start gap-4">
                    <div className="w-5 h-5 rounded-full bg-[var(--accent-primary)]/10 flex items-center justify-center flex-shrink-0 mt-0.5">
                      <div className="w-2 h-2 rounded-full bg-[var(--accent-primary)]" />
                    </div>
                    <div>
                      <h3 className="font-semibold mb-1">Live Activity & Widgets</h3>
                      <p className="text-sm text-[var(--muted)] leading-relaxed">
                        See your timer on the Lock Screen with Live Activity. Add Home Screen widgets to track your daily progress and quickly start new sessions.
                      </p>
                    </div>
                  </div>
                  <div className="flex items-start gap-4">
                    <div className="w-5 h-5 rounded-full bg-[var(--accent-primary)]/10 flex items-center justify-center flex-shrink-0 mt-0.5">
                      <div className="w-2 h-2 rounded-full bg-[var(--accent-primary)]" />
                    </div>
                    <div>
                      <h3 className="font-semibold mb-1">Session Intentions</h3>
                      <p className="text-sm text-[var(--muted)] leading-relaxed">
                        Set a clear intention for each focus session. What do you want to accomplish? This helps you stay focused and track what you're working on.
                      </p>
                    </div>
                  </div>
                </div>
              </div>
              <div className="flex justify-center">
                <PhoneSimulator 
                  screenshots={[
                    '/images/screen-focus-1.png',
                    '/images/screen-focus-2.png',
                    '/images/screen-focus-3.png',
                  ]}
                  screenData={[
                    { icon: '⏱️', title: 'Focus Timer', desc: 'Start a session', gradient: 'from-blue-500 to-cyan-500' },
                    { icon: '⏱️', title: 'Focus Timer', desc: 'During session', gradient: 'from-blue-500 to-cyan-500' },
                    { icon: '⏱️', title: 'Focus Timer', desc: 'Session complete', gradient: 'from-blue-500 to-cyan-500' },
                  ]}
                />
              </div>
            </div>
          </div>
        </Container>
      </section>

      {/* Task Management */}
      <section className="py-24">
        <Container>
          <div className="max-w-6xl mx-auto">
            <div className="grid md:grid-cols-2 gap-16 items-center mb-24">
              <div className="order-2 md:order-1 flex justify-center">
                <PhoneSimulator 
                  screenshots={[
                    '/images/screen-tasks-1.png',
                    '/images/screen-tasks-2.png',
                    '/images/screen-tasks-3.png',
                  ]}
                  screenData={[
                    { icon: '✅', title: 'Tasks', desc: 'Task list', gradient: 'from-green-500 to-emerald-500' },
                    { icon: '✅', title: 'Tasks', desc: 'Create task', gradient: 'from-green-500 to-emerald-500' },
                    { icon: '✅', title: 'Tasks', desc: 'Task details', gradient: 'from-green-500 to-emerald-500' },
                  ]}
                />
              </div>
              <div className="order-1 md:order-2">
                <div className="flex items-center gap-4 mb-8">
                  <div className="w-14 h-14 rounded-xl bg-[var(--accent-primary)] flex items-center justify-center text-white">
                    <svg className="w-7 h-7" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                    </svg>
                  </div>
                  <h2 className="text-4xl md:text-5xl font-semibold tracking-tight">Task Management</h2>
                </div>
                <p className="text-lg text-[var(--muted)] leading-relaxed mb-8">
                  Organize your to-do list with smart features. Set reminders, create recurring tasks, estimate durations, and link tasks directly to focus sessions.
                </p>
                <div className="space-y-5">
                  <div className="flex items-start gap-4">
                    <div className="w-5 h-5 rounded-full bg-[var(--accent-primary)]/10 flex items-center justify-center flex-shrink-0 mt-0.5">
                      <div className="w-2 h-2 rounded-full bg-[var(--accent-primary)]" />
                    </div>
                    <div>
                      <h3 className="font-semibold mb-1">Smart Recurring Tasks</h3>
                      <p className="text-sm text-[var(--muted)] leading-relaxed">
                        Set tasks to repeat daily, weekly, monthly, yearly, or on custom days. Exclude specific dates from recurring series. Perfect for habits and regular commitments.
                      </p>
                    </div>
                  </div>
                  <div className="flex items-start gap-4">
                    <div className="w-5 h-5 rounded-full bg-[var(--accent-primary)]/10 flex items-center justify-center flex-shrink-0 mt-0.5">
                      <div className="w-2 h-2 rounded-full bg-[var(--accent-primary)]" />
                    </div>
                    <div>
                      <h3 className="font-semibold mb-1">Duration Estimates</h3>
                      <p className="text-sm text-[var(--muted)] leading-relaxed">
                        Add duration estimates to tasks. Link tasks to focus sessions and track how long things actually take. Great for time management and planning.
                      </p>
                    </div>
                  </div>
                  <div className="flex items-start gap-4">
                    <div className="w-5 h-5 rounded-full bg-[var(--accent-primary)]/10 flex items-center justify-center flex-shrink-0 mt-0.5">
                      <div className="w-2 h-2 rounded-full bg-[var(--accent-primary)]" />
                    </div>
                    <div>
                      <h3 className="font-semibold mb-1">Convert to Presets</h3>
                      <p className="text-sm text-[var(--muted)] leading-relaxed">
                        Turn tasks into focus presets. One tap to start a focus session configured for that specific task. Streamline your workflow.
                      </p>
                    </div>
                  </div>
                  <div className="flex items-start gap-4">
                    <div className="w-5 h-5 rounded-full bg-[var(--accent-primary)]/10 flex items-center justify-center flex-shrink-0 mt-0.5">
                      <div className="w-2 h-2 rounded-full bg-[var(--accent-primary)]" />
                    </div>
                    <div>
                      <h3 className="font-semibold mb-1">Smart Reminders</h3>
                      <p className="text-sm text-[var(--muted)] leading-relaxed">
                        Set one-time or recurring reminders. Never miss an important task. Get notified at the right time to stay on track.
                      </p>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </Container>
      </section>

      {/* Progress Tracking */}
      <section className="py-24">
        <Container>
          <div className="max-w-6xl mx-auto">
            <div className="grid md:grid-cols-2 gap-16 items-center mb-24">
              <div>
                <div className="flex items-center gap-4 mb-8">
                  <div className="w-14 h-14 rounded-xl bg-[var(--accent-primary)] flex items-center justify-center text-white">
                    <svg className="w-7 h-7" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6" />
                    </svg>
                  </div>
                  <h2 className="text-4xl md:text-5xl font-semibold tracking-tight">Progress & Journey</h2>
                </div>
                <p className="text-lg text-[var(--muted)] leading-relaxed mb-8">
                  Track your focus time, maintain streaks, and watch your progress grow. See daily summaries, long-term trends, and unlock achievements as you build lasting habits.
                </p>
                <div className="space-y-5">
                  <div className="flex items-start gap-4">
                    <div className="w-5 h-5 rounded-full bg-[var(--accent-primary)]/10 flex items-center justify-center flex-shrink-0 mt-0.5">
                      <div className="w-2 h-2 rounded-full bg-[var(--accent-primary)]" />
                    </div>
                    <div>
                      <h3 className="font-semibold mb-1">XP System & 50 Levels</h3>
                      <p className="text-sm text-[var(--muted)] leading-relaxed">
                        Earn XP for every focus session and completed task. Level up through 50 ranks. Watch your progress grow and stay motivated.
                      </p>
                    </div>
                  </div>
                  <div className="flex items-start gap-4">
                    <div className="w-5 h-5 rounded-full bg-[var(--accent-primary)]/10 flex items-center justify-center flex-shrink-0 mt-0.5">
                      <div className="w-2 h-2 rounded-full bg-[var(--accent-primary)]" />
                    </div>
                    <div>
                      <h3 className="font-semibold mb-1">Achievement Badges</h3>
                      <p className="text-sm text-[var(--muted)] leading-relaxed">
                        Unlock achievement badges for milestones. First session, 7-day streak, 100 focus hours, and more. Celebrate your progress.
                      </p>
                    </div>
                  </div>
                  <div className="flex items-start gap-4">
                    <div className="w-5 h-5 rounded-full bg-[var(--accent-primary)]/10 flex items-center justify-center flex-shrink-0 mt-0.5">
                      <div className="w-2 h-2 rounded-full bg-[var(--accent-primary)]" />
                    </div>
                    <div>
                      <h3 className="font-semibold mb-1">Daily Summaries</h3>
                      <p className="text-sm text-[var(--muted)] leading-relaxed">
                        View daily summaries of your focus time and completed tasks. Journey view shows your growth over time with beautiful visualizations.
                      </p>
                    </div>
                  </div>
                  <div className="flex items-start gap-4">
                    <div className="w-5 h-5 rounded-full bg-[var(--accent-primary)]/10 flex items-center justify-center flex-shrink-0 mt-0.5">
                      <div className="w-2 h-2 rounded-full bg-[var(--accent-primary)]" />
                    </div>
                    <div>
                      <h3 className="font-semibold mb-1">Streak Tracking</h3>
                      <p className="text-sm text-[var(--muted)] leading-relaxed">
                        Maintain your focus streak. See how many days in a row you've completed focus sessions. Build consistency and momentum.
                      </p>
                    </div>
                  </div>
                </div>
              </div>
              <div className="flex justify-center">
                <PhoneSimulator 
                  screenshots={[
                    '/images/screen-progress-1.png',
                    '/images/screen-progress-2.png',
                    '/images/screen-progress-3.png',
                  ]}
                  screenData={[
                    { icon: '📈', title: 'Progress', desc: 'Daily summary', gradient: 'from-purple-500 to-pink-500' },
                    { icon: '📈', title: 'Progress', desc: 'Journey view', gradient: 'from-purple-500 to-pink-500' },
                    { icon: '📈', title: 'Progress', desc: 'Achievements', gradient: 'from-purple-500 to-pink-500' },
                  ]}
                />
              </div>
            </div>
          </div>
        </Container>
      </section>

      {/* Profile & Customization */}
      <section className="py-24">
        <Container>
          <div className="max-w-6xl mx-auto">
            <div className="text-center mb-16">
              <div className="flex items-center justify-center gap-4 mb-6">
                <div className="w-14 h-14 rounded-xl bg-[var(--accent-primary)] flex items-center justify-center text-white">
                  <svg className="w-7 h-7" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                  </svg>
                </div>
                <h2 className="text-4xl md:text-5xl font-semibold tracking-tight">Profile & Customization</h2>
              </div>
              <p className="text-lg text-[var(--muted)] leading-relaxed max-w-3xl mx-auto">
                Personalize your FocusFlow experience with themes, avatars, and custom presets. Make it yours.
              </p>
            </div>

            <div className="grid md:grid-cols-2 gap-8">
              <div className="card p-8">
                <h3 className="text-xl font-semibold mb-6 flex items-center gap-3">
                  <svg className="w-6 h-6 text-[var(--accent-primary)]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M7 21a4 4 0 01-4-4V5a2 2 0 012-2h4a2 2 0 012 2v12a4 4 0 01-4 4zm0 0h12a2 2 0 002-2v-4a2 2 0 00-2-2h-2.343M11 7.343l1.657-1.657a2 2 0 012.828 0l2.829 2.829a2 2 0 010 2.828l-8.486 8.485M7 17h.01" />
                  </svg>
                  10 Beautiful Themes
                </h3>
                <p className="text-[var(--muted)] leading-relaxed mb-6">
                  Choose from Forest, Neon Glow, Soft Peach, Cyber Violet, Ocean Mist, Sunrise Coral, Solar Amber, Mint Aura, Royal Indigo, and Cosmic Slate. Each theme transforms the entire app experience.
                </p>
                <ul className="space-y-2 text-sm text-[var(--muted)]">
                  <li className="flex items-center gap-2">
                    <svg className="w-4 h-4 text-[var(--accent-primary)]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                    </svg>
                    <span>Forest - Natural greens and earth tones</span>
                  </li>
                  <li className="flex items-center gap-2">
                    <svg className="w-4 h-4 text-[var(--accent-primary)]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                    </svg>
                    <span>Neon Glow - Vibrant neon colors</span>
                  </li>
                  <li className="flex items-center gap-2">
                    <svg className="w-4 h-4 text-[var(--accent-primary)]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                    </svg>
                    <span>And 8 more stunning themes</span>
                  </li>
                </ul>
              </div>

              <div className="card p-8">
                <h3 className="text-xl font-semibold mb-6 flex items-center gap-3">
                  <svg className="w-6 h-6 text-[var(--accent-primary)]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                  </svg>
                  50+ Symbol Avatars
                </h3>
                <p className="text-[var(--muted)] leading-relaxed mb-6">
                  Personalize your profile with symbol-based avatars. No photo access required. Choose from a wide variety of symbols that represent you.
                </p>
                <ul className="space-y-2 text-sm text-[var(--muted)]">
                  <li className="flex items-center gap-2">
                    <svg className="w-4 h-4 text-[var(--accent-primary)]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                    </svg>
                    <span>Privacy-first - No photo library access</span>
                  </li>
                  <li className="flex items-center gap-2">
                    <svg className="w-4 h-4 text-[var(--accent-primary)]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                    </svg>
                    <span>Wide variety of symbols</span>
                  </li>
                  <li className="flex items-center gap-2">
                    <svg className="w-4 h-4 text-[var(--accent-primary)]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                    </svg>
                    <span>Easy to change anytime</span>
                  </li>
                </ul>
              </div>

              <div className="card p-8">
                <h3 className="text-xl font-semibold mb-6 flex items-center gap-3">
                  <svg className="w-6 h-6 text-[var(--accent-primary)]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M5 3v4M3 5h4M6 17v4m-2-2h4m5-16l2.286 6.857L21 12l-5.714 2.143L13 21l-2.286-6.857L5 12l5.714-2.143L13 3z" />
                  </svg>
                  Focus Presets
                </h3>
                <p className="text-[var(--muted)] leading-relaxed mb-6">
                  Save your favorite session configurations. Quick access to your most-used settings. Create presets for different types of work.
                </p>
                <ul className="space-y-2 text-sm text-[var(--muted)]">
                  <li className="flex items-center gap-2">
                    <svg className="w-4 h-4 text-[var(--accent-primary)]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                    </svg>
                    <span>Save duration, background, and settings</span>
                  </li>
                  <li className="flex items-center gap-2">
                    <svg className="w-4 h-4 text-[var(--accent-primary)]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                    </svg>
                    <span>One-tap to start</span>
                  </li>
                  <li className="flex items-center gap-2">
                    <svg className="w-4 h-4 text-[var(--accent-primary)]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                    </svg>
                    <span>Unlimited presets with Pro</span>
                  </li>
                </ul>
              </div>

              <div className="card p-8">
                <h3 className="text-xl font-semibold mb-6 flex items-center gap-3">
                  <svg className="w-6 h-6 text-[var(--accent-primary)]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M3 15a4 4 0 004 4h9a5 5 0 10-.1-9.999 5.002 5.002 0 10-9.9 4.5 4.5 0 00-3.1 5.999z" />
                  </svg>
                  Cloud Sync
                </h3>
                <p className="text-[var(--muted)] leading-relaxed mb-6">
                  Sign in to sync across devices. Or use Guest Mode with all data on your device. Your choice, your privacy.
                </p>
                <ul className="space-y-2 text-sm text-[var(--muted)]">
                  <li className="flex items-center gap-2">
                    <svg className="w-4 h-4 text-[var(--accent-primary)]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                    </svg>
                    <span>Secure cloud sync (optional)</span>
                  </li>
                  <li className="flex items-center gap-2">
                    <svg className="w-4 h-4 text-[var(--accent-primary)]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                    </svg>
                    <span>Guest Mode - All data local</span>
                  </li>
                  <li className="flex items-center gap-2">
                    <svg className="w-4 h-4 text-[var(--accent-primary)]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                    </svg>
                    <span>Works offline</span>
                  </li>
                </ul>
              </div>
            </div>
          </div>
        </Container>
      </section>

      {/* Additional Features Grid */}
      <section className="py-24">
        <Container>
          <div className="max-w-6xl mx-auto">
            <div className="text-center mb-16">
              <h2 className="text-4xl md:text-5xl font-semibold tracking-tight mb-4">
                Everything you need
              </h2>
              <p className="text-lg text-[var(--muted)] leading-relaxed max-w-3xl mx-auto">
                FocusFlow includes everything you need to stay focused, organized, and motivated—all in one beautiful app.
              </p>
            </div>

            <div className="grid md:grid-cols-3 gap-6">
              {[
                {
                  title: 'Widgets & Live Activities',
                  desc: 'Home Screen widgets and Lock Screen Live Activity for quick access to your timer and progress.',
                  icon: (
                    <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M12 18h.01M8 21h8a2 2 0 002-2V5a2 2 0 00-2-2H8a2 2 0 00-2 2v14a2 2 0 002 2z" />
                    </svg>
                  ),
                },
                {
                  title: 'Privacy First',
                  desc: 'Use Guest Mode without an account. We don\'t sell your data or show ads. Your privacy is our priority.',
                  icon: (
                    <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
                    </svg>
                  ),
                },
                {
                  title: 'Works Offline',
                  desc: 'All core features work without an internet connection. Focus sessions, tasks, and progress tracking work perfectly offline.',
                  icon: (
                    <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M18.364 5.636l-3.536 3.536m0 5.656l3.536 3.536M9.172 9.172L5.636 5.636m3.536 9.192l-3.536 3.536M21 12a9 9 0 11-18 0 9 9 0 0118 0zm-5 0a4 4 0 11-8 0 4 4 0 018 0z" />
                    </svg>
                  ),
                },
                {
                  title: 'Native iOS Experience',
                  desc: 'Built for iOS with widgets, Live Activities, and deep system integration. It feels like it belongs on your iPhone.',
                  icon: (
                    <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M12 18h.01M8 21h8a2 2 0 002-2V5a2 2 0 00-2-2H8a2 2 0 00-2 2v14a2 2 0 002 2z" />
                    </svg>
                  ),
                },
                {
                  title: 'No Ads, No Tracking',
                  desc: 'FocusFlow is ad-free and doesn\'t track you. We make money from Pro subscriptions, not from your data.',
                  icon: (
                    <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
                    </svg>
                  ),
                },
                {
                  title: 'Regular Updates',
                  desc: 'We\'re constantly improving FocusFlow with new features, bug fixes, and enhancements based on your feedback.',
                  icon: (
                    <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M13 10V3L4 14h7v7l9-11h-7z" />
                    </svg>
                  ),
                },
              ].map((feature, i) => (
                <div key={i} className="card p-8">
                  <div className="text-[var(--accent-primary)] mb-6">
                    {feature.icon}
                  </div>
                  <h3 className="text-lg font-semibold mb-3">{feature.title}</h3>
                  <p className="text-sm text-[var(--muted)] leading-relaxed">{feature.desc}</p>
                </div>
              ))}
            </div>
          </div>
        </Container>
      </section>

      {/* FocusFlow Pro - Premium Section - HIGHLIGHT SECTION */}
      <section className="py-32 relative overflow-hidden bg-gradient-to-b from-[var(--soft)] to-[var(--background)]">
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
          <div className="max-w-6xl mx-auto relative z-10">
            {/* Header */}
            <div className="text-center mb-20 relative">
              <div className="inline-flex items-center justify-center gap-2 px-4 py-2 rounded-full bg-[var(--accent-primary)]/10 border border-[var(--accent-primary)]/20 mb-6">
                <svg className="w-5 h-5 text-[var(--accent-primary)]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 10V3L4 14h7v7l9-11h-7z" />
                </svg>
                <span className="text-sm font-semibold text-[var(--accent-primary)]">Premium Experience</span>
              </div>
              <h2 className="text-5xl md:text-6xl font-semibold tracking-tight mb-6">
                FocusFlow <span className="text-[var(--accent-primary)]">Pro</span>
              </h2>
              <p className="text-xl text-[var(--muted)] leading-relaxed max-w-3xl mx-auto">
                Unlock the full potential of FocusFlow. Advanced features for power users who demand more.
              </p>
              {/* Currency Selector - Right Side */}
              <div className="absolute top-0 right-0 hidden md:block">
                <CurrencySelector onCurrencyChange={setSelectedCurrency} defaultCurrency="CAD" />
              </div>
              {/* Currency Selector - Mobile - Below Title */}
              <div className="mt-6 md:hidden flex justify-center">
                <CurrencySelector onCurrencyChange={setSelectedCurrency} defaultCurrency="CAD" />
              </div>
            </div>

            {/* Comparison Cards */}
            <div className="grid md:grid-cols-3 gap-6 mb-20 items-start">
              {/* Free Version */}
              <div className="card p-8 bg-[var(--soft)] flex flex-col">
                <div className="text-center mb-6">
                  <h3 className="text-xl font-semibold mb-2">Free</h3>
                  <p className="text-3xl font-bold mb-1">$0</p>
                  <p className="text-sm text-[var(--muted)]">Forever</p>
                </div>
                <ul className="space-y-3 mb-6 flex-grow">
                  {[
                    'Focus timer with 3 ambient backgrounds',
                    'Basic task management',
                    'Progress tracking with XP',
                    '3 beautiful themes',
                    'Limited custom presets',
                    'Basic widgets',
                  ].map((feature, i) => (
                    <li key={i} className="flex items-start gap-2">
                      <svg className="w-4 h-4 text-[var(--accent-primary)] flex-shrink-0 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                      </svg>
                      <span className="text-xs font-medium text-[var(--muted)]">{feature}</span>
                    </li>
                  ))}
                </ul>
                <div className="mt-auto">
                  <div className="btn btn-secondary w-full text-center block text-sm py-2.5 opacity-50 cursor-not-allowed">
                    Current Plan
                  </div>
                </div>
              </div>

              {/* Pro Yearly - Best Value - MIDDLE & BIGGER */}
              <div className="card p-12 border-2 border-[var(--accent-primary)]/60 bg-gradient-to-br from-[var(--accent-primary)]/15 via-[var(--accent-secondary)]/12 to-[var(--accent-primary)]/15 relative shadow-xl shadow-[var(--accent-primary)]/20 flex flex-col ring-2 ring-[var(--accent-primary)]/20 md:-mt-8 md:mb-8">
                {/* Premium Badge */}
                <div className="absolute -top-4 right-4 bg-gradient-to-r from-[var(--accent-primary)] to-[var(--accent-secondary)] text-white px-5 py-2 rounded-full shadow-lg z-10">
                  <span className="text-sm font-semibold">BEST VALUE</span>
                </div>
                
                <div className="text-center mb-8">
                  <h3 className="text-2xl font-semibold mb-3 bg-gradient-to-r from-[var(--accent-primary)] to-[var(--accent-secondary)] bg-clip-text text-transparent">Pro Yearly</h3>
                  <p className="text-5xl font-bold mb-2">
                    ${selectedCurrency === 'USD' ? '44.99' : '59.99'}
                  </p>
                  <p className="text-base text-[var(--muted)] mb-3">per year</p>
                  <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-gradient-to-r from-[var(--accent-primary)]/20 to-[var(--accent-secondary)]/20 border border-[var(--accent-primary)]/30">
                    <svg className="w-5 h-5 text-[var(--accent-primary)]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                    </svg>
                    <p className="text-base font-semibold text-[var(--accent-primary)]">
                      Save ${selectedCurrency === 'USD' ? '2.89' : '11.88'}/year
                    </p>
                  </div>
                </div>
                <ul className="space-y-3 mb-8 flex-grow">
                  {[
                    'Everything in Free',
                    'All 14 ambient backgrounds',
                    'Unlimited custom presets',
                    'Unlimited tasks',
                    'All 10 premium themes',
                    'Advanced progress insights',
                    'Full ambient sound library',
                    'Priority support',
                    'Early access to new features',
                  ].map((feature, i) => (
                    <li key={i} className="flex items-start gap-2">
                      <svg className="w-4 h-4 text-[var(--accent-primary)] flex-shrink-0 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                      </svg>
                      <span className="text-sm font-medium">{feature}</span>
                    </li>
                  ))}
                </ul>
                <div className="mt-auto">
                  <a
                    href="https://apps.apple.com/app/focusflow-be-present/id6739000000"
                    target="_blank"
                    rel="noopener noreferrer"
                    className="btn btn-primary w-full text-center block py-3 font-semibold"
                  >
                    Start Free Trial
                  </a>
                </div>
              </div>

              {/* Pro Monthly */}
              <div className="card p-8 border-2 border-[var(--accent-primary)]/30 bg-gradient-to-br from-[var(--accent-primary)]/5 to-[var(--accent-secondary)]/5 relative flex flex-col">
                <div className="text-center mb-6">
                  <h3 className="text-xl font-semibold mb-2 bg-gradient-to-r from-[var(--accent-primary)] to-[var(--accent-secondary)] bg-clip-text text-transparent">Pro Monthly</h3>
                  <p className="text-3xl font-bold mb-1">
                    ${selectedCurrency === 'USD' ? '3.99' : '5.99'}
                  </p>
                  <p className="text-sm text-[var(--muted)]">per month</p>
                </div>
                <ul className="space-y-3 mb-6 flex-grow">
                  {[
                    'Everything in Free',
                    'All 14 ambient backgrounds',
                    'Unlimited custom presets',
                    'Unlimited tasks',
                    'All 10 premium themes',
                    'Advanced progress insights',
                    'Full ambient sound library',
                    'Priority support',
                    'Early access to new features',
                  ].map((feature, i) => (
                    <li key={i} className="flex items-start gap-2">
                      <svg className="w-4 h-4 text-[var(--accent-primary)] flex-shrink-0 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                      </svg>
                      <span className="text-xs font-medium">{feature}</span>
                    </li>
                  ))}
                </ul>
                <div className="mt-auto">
                  <a
                    href="https://apps.apple.com/app/focusflow-be-present/id6739000000"
                    target="_blank"
                    rel="noopener noreferrer"
                    className="btn btn-primary w-full text-center block text-sm py-2.5"
                  >
                    Start Free Trial
                  </a>
                </div>
              </div>
            </div>

            {/* Pro Features Grid */}
            <div className="mb-20">
              <h3 className="text-3xl font-semibold text-center mb-16">Pro Features in Detail</h3>
              <div className="grid md:grid-cols-3 gap-8">
                {[
                  { 
                    title: 'Unlimited Custom Presets', 
                    desc: 'Create as many focus presets as you need. Perfect for different types of work, projects, or moods.',
                    icon: (
                      <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M5 3v4M3 5h4M6 17v4m-2-2h4m5-16l2.286 6.857L21 12l-5.714 2.143L13 21l-2.286-6.857L5 12l5.714-2.143L13 3z" />
                      </svg>
                    ),
                  },
                  { 
                    title: 'Full Ambient Sound Library', 
                    desc: 'Access all 14 ambient backgrounds. Every soundscape unlocked for the perfect focus environment.',
                    icon: (
                      <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M9 19V6l12-3v13M9 19c0 1.105-1.343 2-3 2s-3-.895-3-2 1.343-2 3-2 3 .895 3 2zm12-3c0 1.105-1.343 2-3 2s-3-.895-3-2 1.343-2 3-2 3 .895 3 2zM9 10l12-3" />
                      </svg>
                    ),
                  },
                  { 
                    title: 'Unlimited Tasks', 
                    desc: 'No limits on tasks. Manage complex projects, large to-do lists, and never worry about hitting a limit.',
                    icon: (
                      <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4" />
                      </svg>
                    ),
                  },
                  { 
                    title: 'All 10 Premium Themes', 
                    desc: 'Unlock every beautiful theme. Switch between Forest, Neon, Peach, Cyber, Ocean, and more anytime.',
                    icon: (
                      <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M7 21a4 4 0 01-4-4V5a2 2 0 012-2h4a2 2 0 012 2v12a4 4 0 01-4 4zm0 0h12a2 2 0 002-2v-4a2 2 0 00-2-2h-2.343M11 7.343l1.657-1.657a2 2 0 012.828 0l2.829 2.829a2 2 0 010 2.828l-8.486 8.485M7 17h.01" />
                      </svg>
                    ),
                  },
                  { 
                    title: 'Advanced Progress Insights', 
                    desc: 'Deeper analytics, productivity patterns, optimal focus times, and detailed historical data.',
                    icon: (
                      <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
                      </svg>
                    ),
                  },
                  { 
                    title: 'Priority Support', 
                    desc: 'Get faster responses to support requests. We prioritize Pro users and ensure you get the help you need.',
                    icon: (
                      <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M18.364 5.636l-3.536 3.536m0 5.656l3.536 3.536M9.172 9.172L5.636 5.636m3.536 9.192l-3.536 3.536M21 12a9 9 0 11-18 0 9 9 0 0118 0zm-5 0a4 4 0 11-8 0 4 4 0 018 0z" />
                      </svg>
                    ),
                  },
                ].map((feature, i) => (
                  <div key={i} className="card p-8 hover:shadow-lg transition-all duration-300">
                    <div className="text-[var(--accent-primary)] mb-6">
                      {feature.icon}
                    </div>
                    <h4 className="text-lg font-semibold mb-3">{feature.title}</h4>
                    <p className="text-sm text-[var(--muted)] leading-relaxed">{feature.desc}</p>
                  </div>
                ))}
              </div>
            </div>

            {/* Premium CTA */}
            <div className="card p-16 text-center bg-gradient-to-br from-[var(--accent-primary)] via-[var(--accent-secondary)] to-[var(--accent-primary)] text-white relative overflow-hidden">
              {/* Subtle animated background elements */}
              <div className="absolute top-0 right-0 w-64 h-64 bg-white/10 rounded-full blur-3xl" />
              <div className="absolute bottom-0 left-0 w-64 h-64 bg-white/10 rounded-full blur-3xl" />
              
              <div className="relative z-10">
                <div className="text-6xl mb-8">✨</div>
                <h3 className="text-4xl md:text-5xl font-semibold mb-6">Start Your Free Trial Today</h3>
                <p className="text-xl mb-2 opacity-90">3 days free, then choose your plan</p>
                <p className="text-lg mb-1 opacity-80">$3.99 USD / $5.99 CAD per month</p>
                <p className="text-lg mb-1 opacity-80">$44.99 USD / $59.99 CAD per year</p>
                <p className="text-base mb-12 opacity-70 max-w-2xl mx-auto">Save $11.88/year with annual plan. Cancel anytime. No commitment.</p>
                <div className="flex flex-col sm:flex-row gap-4 justify-center">
                  <a
                    href="https://apps.apple.com/app/focusflow-be-present/id6739000000"
                    target="_blank"
                    rel="noopener noreferrer"
                    className="btn bg-white text-[var(--accent-primary)] hover:bg-white/90 inline-block text-center text-lg px-10 py-4 font-semibold shadow-lg"
                  >
                    Start Free Trial
                  </a>
                  <Link
                    href="/support"
                    className="btn bg-white/10 text-white border-2 border-white/30 hover:bg-white/20 inline-block text-center text-lg px-10 py-4 backdrop-blur-sm"
                  >
                    Learn More
                  </Link>
                </div>
                <p className="text-sm mt-10 opacity-70">No credit card required for trial</p>
              </div>
            </div>
          </div>
        </Container>
      </section>

      {/* Final CTA */}
      <section className="py-24 bg-[var(--soft)]">
        <Container>
          <div className="max-w-4xl mx-auto text-center">
            <div className="mb-8 flex justify-center">
              <div className="relative">
                <Image
                  src="/focusflow_app_icon.jpg"
                  alt="FocusFlow - Be Present"
                  width={80}
                  height={80}
                  className="rounded-2xl shadow-xl ring-2 ring-[var(--accent-primary)]/30"
                  style={{ objectFit: 'cover' }}
                />
                <div className="absolute inset-0 rounded-2xl ring-2 ring-[var(--accent-primary)]/20 animate-pulse" />
              </div>
            </div>
            <h2 className="text-4xl md:text-5xl font-semibold tracking-tight mb-6">
              Ready to build better focus habits?
            </h2>
            <p className="text-lg text-[var(--muted)] mb-10 max-w-2xl mx-auto leading-relaxed">
              Download FocusFlow today and start your journey to more focused, productive work. Free to use, with optional Pro features.
            </p>
                <div className="flex flex-col sm:flex-row gap-4 justify-center">
                  <a
                    href="https://apps.apple.com/app/focusflow-be-present/id6739000000"
                    target="_blank"
                    rel="noopener noreferrer"
                    className="btn btn-primary inline-block text-center text-lg px-8 py-4"
                  >
                    Download on App Store
                  </a>
                  <Link
                    href="/support"
                    className="btn btn-secondary inline-block text-center text-lg px-8 py-4"
                  >
                    Get support
                  </Link>
                </div>
          </div>
        </Container>
      </section>
    </div>
  );
}
