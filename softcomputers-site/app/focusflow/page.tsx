'use client';

import Link from 'next/link';
import Image from 'next/image';
import Container from '@/components/ui/Container';
import PhoneSimulator from '@/components/phone/iPhoneSimulator';
import CurrencySelector from '@/components/ui/CurrencySelector';
import { useState } from 'react';
import { useThrottledMouse } from '../hooks/useThrottledMouse';

export default function FocusFlowPage() {
  const mousePosition = useThrottledMouse();
  const [selectedCurrency, setSelectedCurrency] = useState<'USD' | 'CAD'>('CAD');

  return (
    <div className="min-h-screen bg-[var(--background)]">
      
      {/* ═══════════════════════════════════════════════════════════════
          HERO SECTION
          ═══════════════════════════════════════════════════════════════ */}
      <section className="relative pt-20 md:pt-32 pb-12 md:pb-24 overflow-hidden">
        {/* Animated background */}
        <div className="absolute inset-0">
          <div 
            className="absolute top-0 left-1/4 w-[300px] md:w-[600px] h-[300px] md:h-[600px] rounded-full blur-[60px] md:blur-[80px] opacity-25 transition-transform duration-1000 ease-out"
            style={{
              background: `radial-gradient(circle, rgba(139, 92, 246, 0.5) 0%, transparent 70%)`,
              transform: `translate(${mousePosition.x * 0.015}px, ${mousePosition.y * 0.015}px)`,
              willChange: 'transform',
            }}
          />
          <div 
            className="absolute bottom-0 right-1/4 w-[250px] md:w-[500px] h-[250px] md:h-[500px] rounded-full blur-[40px] md:blur-[60px] opacity-15 transition-transform duration-1000 ease-out"
            style={{
              background: `radial-gradient(circle, rgba(212, 168, 83, 0.4) 0%, transparent 70%)`,
              transform: `translate(${-mousePosition.x * 0.01}px, ${-mousePosition.y * 0.01}px)`,
              willChange: 'transform',
            }}
          />
        </div>

        <div className="absolute inset-0 bg-grid opacity-20" />

        <Container>
          <div className="max-w-6xl mx-auto relative z-10">
            <div className="grid lg:grid-cols-2 gap-8 lg:gap-16 items-center">
              {/* Left - Content */}
              <div className="stagger-children text-center lg:text-left">
                {/* App Icon & Name */}
                <div className="flex items-center gap-4 md:gap-6 mb-6 md:mb-10 justify-center lg:justify-start">
                  <div className="relative group flex-shrink-0">
                    {/* Glow effect behind icon */}
                    <div className="absolute -inset-3 md:-inset-4 bg-gradient-to-br from-[var(--accent-primary)]/40 to-[var(--accent-secondary)]/30 rounded-[24px] md:rounded-[32px] blur-xl md:blur-2xl opacity-60 group-hover:opacity-80 transition-opacity duration-500" />
                    <Image
                      src="/focusflow_app_icon.jpg"
                      alt="FocusFlow - Be Present"
                      width={100}
                      height={100}
                      className="relative rounded-[20px] md:rounded-[28px] shadow-2xl transition-all duration-500 group-hover:scale-105 group-hover:shadow-[0_20px_60px_rgba(139,92,246,0.3)] md:w-[140px] md:h-[140px]"
                      style={{ 
                        boxShadow: '0 10px 40px rgba(0, 0, 0, 0.4), 0 0 0 1px rgba(255, 255, 255, 0.1) inset'
                      }}
                    />
                  </div>
                  <div>
                    <h1 className="text-4xl md:text-7xl font-bold tracking-tight text-[var(--foreground)] mb-1 md:mb-2">
                      FocusFlow
                    </h1>
                    <p className="text-lg md:text-xl text-[var(--foreground-muted)]">Be Present</p>
                  </div>
                </div>
                
                {/* Tagline */}
                <p className="text-xl md:text-3xl text-[var(--foreground-muted)] leading-relaxed mb-4 md:mb-6 max-w-xl mx-auto lg:mx-0">
                  The all-in-one app for focused work. Timer, tasks, and progress tracking in one beautiful experience.
                </p>

                <p className="text-base md:text-lg text-[var(--foreground-subtle)] leading-relaxed mb-6 md:mb-10 max-w-xl mx-auto lg:mx-0">
                  Privacy-first. No ads. No tracking. Just pure focus.
                </p>
                
                {/* CTAs */}
                <div className="flex flex-col sm:flex-row gap-3 md:gap-4 mb-8 md:mb-12 justify-center lg:justify-start">
                  <a
                    href="https://apps.apple.com/app/focusflow-be-present/id6739000000"
                    target="_blank"
                    rel="noopener noreferrer"
                    className="btn btn-accent btn-lg"
                  >
                    <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
                      <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z"/>
                    </svg>
                    Download on App Store
                  </a>
                  <Link href="#features" className="btn btn-secondary btn-lg">
                    Explore Features
                  </Link>
                </div>

                {/* Stats */}
                <div className="grid grid-cols-3 gap-2 md:gap-4">
                  {[
                    { value: '14', label: 'Backgrounds' },
                    { value: '10', label: 'Themes' },
                    { value: '50+', label: 'Levels' },
                  ].map((stat, i) => (
                    <div key={i} className="card p-3 md:p-4 text-center">
                      <div className="text-xl md:text-2xl font-bold text-gradient mb-0.5 md:mb-1">{stat.value}</div>
                      <div className="text-[10px] md:text-xs text-[var(--foreground-subtle)]">{stat.label}</div>
                  </div>
                  ))}
                </div>
              </div>

              {/* Right - Phone Mockup */}
              <div className="flex justify-center lg:justify-end order-first lg:order-last mb-8 lg:mb-0">
                <div className="relative scale-90 md:scale-100">
                  {/* Glow behind phone */}
                  <div className="absolute inset-0 bg-gradient-to-r from-[var(--accent-primary)]/30 to-[var(--accent-secondary)]/20 blur-[60px] md:blur-[80px] scale-125 md:scale-150" />
                  
                <PhoneSimulator 
                  screenshots={[
                    '/images/screen-focus.png',
                    '/images/screen-tasks.png',
                    '/images/screen-progress.png',
                    '/images/screen-profile.png',
                  ]}
                  screenData={[
                      { icon: '⏱️', title: 'Focus Timer', desc: 'Timed sessions', gradient: 'from-violet-500 to-purple-600' },
                      { icon: '✅', title: 'Tasks', desc: 'Smart management', gradient: 'from-emerald-500 to-teal-600' },
                      { icon: '📈', title: 'Progress', desc: 'Track growth', gradient: 'from-amber-500 to-orange-600' },
                      { icon: '👤', title: 'Profile', desc: 'Customize & sync', gradient: 'from-rose-500 to-pink-600' },
                    ]}
                  />
                </div>
              </div>
            </div>
          </div>
        </Container>
      </section>

      {/* ═══════════════════════════════════════════════════════════════
          WHAT IS FOCUSFLOW
          ═══════════════════════════════════════════════════════════════ */}
      <section className="section-padding bg-[var(--background-elevated)]">
        <Container>
          <div className="max-w-5xl mx-auto">
            <div className="text-center mb-16">
              <h2 className="mb-6">What is FocusFlow?</h2>
              <p className="text-xl text-[var(--foreground-muted)] leading-relaxed max-w-3xl mx-auto">
                FocusFlow combines three powerful tools into one seamless experience: a focus timer, task manager, and progress tracker. Built for people who want to do deep work and build lasting habits.
              </p>
            </div>

            <div className="grid md:grid-cols-3 gap-6">
              {[
                {
                  title: 'Focus Timer',
                  desc: 'Timed sessions with 14 ambient backgrounds and music integration',
                  icon: (
                    <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M12 6v6h4.5m4.5 0a9 9 0 11-18 0 9 9 0 0118 0z" />
                    </svg>
                  ),
                  gradient: 'from-violet-500/20 to-purple-500/20',
                },
                {
                  title: 'Task Manager',
                  desc: 'Smart task management with reminders and recurring schedules',
                  icon: (
                    <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4" />
                    </svg>
                  ),
                  gradient: 'from-emerald-500/20 to-teal-500/20',
                },
                {
                  title: 'Progress Tracker',
                  desc: 'XP system, 50 levels, streaks, and achievement badges',
                  icon: (
                    <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
                    </svg>
                  ),
                  gradient: 'from-amber-500/20 to-orange-500/20',
                },
              ].map((item, i) => (
                <div key={i} className="card group p-8 text-center hover:border-[var(--accent-primary)]/30">
                  <div className={`absolute inset-0 bg-gradient-to-br ${item.gradient} opacity-0 group-hover:opacity-100 transition-opacity duration-500 rounded-[var(--radius-lg)]`} />
                  <div className="relative z-10">
                    <div className="text-[var(--accent-primary)] mb-6 flex justify-center group-hover:scale-110 transition-transform duration-300">
                    {item.icon}
                  </div>
                    <h3 className="text-xl font-semibold text-[var(--foreground)] mb-3">{item.title}</h3>
                    <p className="text-[var(--foreground-muted)] leading-relaxed">{item.desc}</p>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </Container>
      </section>

      {/* ═══════════════════════════════════════════════════════════════
          WHO IS IT FOR
          ═══════════════════════════════════════════════════════════════ */}
      <section className="section-padding">
        <Container>
          <div className="max-w-6xl mx-auto">
            <div className="text-center mb-16">
              <h2 className="mb-6">Who is FocusFlow for?</h2>
              <p className="text-xl text-[var(--foreground-muted)] leading-relaxed max-w-3xl mx-auto">
                Whether you're a student, professional, entrepreneur, or creative—FocusFlow adapts to your unique workflow.
              </p>
            </div>

            <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-6">
              {[
                {
                  title: 'Students',
                  desc: 'Master study sessions, manage assignments, build learning habits.',
                  icon: '📚',
                },
                {
                  title: 'Professionals',
                  desc: 'Boost productivity, manage projects, achieve career goals.',
                  icon: '💼',
                },
                {
                  title: 'Entrepreneurs',
                  desc: 'Block time for strategic work, manage priorities.',
                  icon: '🚀',
                },
                {
                  title: 'Creatives',
                  desc: 'Find your flow state, minimize distractions.',
                  icon: '🎨',
                },
              ].map((persona, i) => (
                <div key={i} className="card group p-6 text-center hover:border-[var(--accent-primary)]/30">
                  <div className="text-4xl mb-4 group-hover:scale-110 transition-transform duration-300">{persona.icon}</div>
                  <h3 className="text-lg font-semibold text-[var(--foreground)] mb-2">{persona.title}</h3>
                  <p className="text-sm text-[var(--foreground-muted)] leading-relaxed">{persona.desc}</p>
                </div>
              ))}
            </div>
          </div>
        </Container>
      </section>

      {/* ═══════════════════════════════════════════════════════════════
          FOCUS TIMER FEATURE
          ═══════════════════════════════════════════════════════════════ */}
      <section id="features" className="section-padding bg-[var(--background-elevated)]">
        <Container>
          <div className="max-w-6xl mx-auto">
            <div className="grid lg:grid-cols-2 gap-16 items-center">
              <div>
                <div className="inline-flex items-center gap-2 badge badge-primary mb-6">
                  <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6v6h4.5m4.5 0a9 9 0 11-18 0 9 9 0 0118 0z" />
                    </svg>
                  Core Feature
                  </div>
                <h2 className="mb-6">Focus Timer</h2>
                <p className="text-xl text-[var(--foreground-muted)] leading-relaxed mb-8">
                  Start timed focus sessions with customizable durations. Choose from 14 beautiful ambient backgrounds or connect your favorite music app.
                </p>
                
                <div className="space-y-6">
                  {[
                    {
                      title: '14 Ambient Backgrounds',
                      desc: 'Aurora, Rain, Fireplace, Ocean, Forest, Stars, and more. Each designed for deep focus.',
                    },
                    {
                      title: 'Music Integration',
                      desc: 'Connect Spotify, Apple Music, or YouTube Music. Launch playlists directly from FocusFlow.',
                    },
                    {
                      title: 'Live Activity & Widgets',
                      desc: 'See your timer on Lock Screen. Add Home Screen widgets for quick access.',
                    },
                    {
                      title: 'Session Intentions',
                      desc: 'Set a clear intention for each session. Stay focused on what matters.',
                    },
                  ].map((feature, i) => (
                    <div key={i} className="flex gap-4 items-start">
                      <div className="w-2 h-2 rounded-full bg-[var(--accent-primary)] mt-2 flex-shrink-0" />
                    <div>
                        <h4 className="font-semibold text-[var(--foreground)] mb-1">{feature.title}</h4>
                        <p className="text-sm text-[var(--foreground-muted)] leading-relaxed">{feature.desc}</p>
                    </div>
                  </div>
                  ))}
                    </div>
                    </div>
              
              <div className="flex justify-center">
                <div className="relative">
                  <div className="absolute inset-0 bg-gradient-to-r from-violet-500/30 to-purple-500/20 blur-[60px] scale-125" />
                <PhoneSimulator 
                  screenshots={[
                    '/images/screen-focus-1.png',
                    '/images/screen-focus-2.png',
                    '/images/screen-focus-3.png',
                  ]}
                  screenData={[
                      { icon: '⏱️', title: 'Timer', desc: 'Start session', gradient: 'from-violet-500 to-purple-600' },
                      { icon: '⏱️', title: 'Timer', desc: 'In progress', gradient: 'from-violet-500 to-purple-600' },
                      { icon: '⏱️', title: 'Timer', desc: 'Complete', gradient: 'from-violet-500 to-purple-600' },
                    ]}
                  />
                </div>
              </div>
            </div>
          </div>
        </Container>
      </section>

      {/* ═══════════════════════════════════════════════════════════════
          TASK MANAGEMENT FEATURE
          ═══════════════════════════════════════════════════════════════ */}
      <section className="section-padding">
        <Container>
          <div className="max-w-6xl mx-auto">
            <div className="grid lg:grid-cols-2 gap-16 items-center">
              <div className="order-2 lg:order-1 flex justify-center">
                <div className="relative">
                  <div className="absolute inset-0 bg-gradient-to-r from-emerald-500/30 to-teal-500/20 blur-[60px] scale-125" />
                <PhoneSimulator 
                  screenshots={[
                    '/images/screen-tasks-1.png',
                    '/images/screen-tasks-2.png',
                    '/images/screen-tasks-3.png',
                  ]}
                  screenData={[
                      { icon: '✅', title: 'Tasks', desc: 'Task list', gradient: 'from-emerald-500 to-teal-600' },
                      { icon: '✅', title: 'Tasks', desc: 'Create task', gradient: 'from-emerald-500 to-teal-600' },
                      { icon: '✅', title: 'Tasks', desc: 'Details', gradient: 'from-emerald-500 to-teal-600' },
                  ]}
                />
              </div>
              </div>
              
              <div className="order-1 lg:order-2">
                <div className="inline-flex items-center gap-2 badge badge-primary mb-6">
                  <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                    </svg>
                  Core Feature
                  </div>
                <h2 className="mb-6">Task Management</h2>
                <p className="text-xl text-[var(--foreground-muted)] leading-relaxed mb-8">
                  Organize your to-do list with smart features. Set reminders, create recurring tasks, and link them to focus sessions.
                </p>
                
                <div className="space-y-6">
                  {[
                    {
                      title: 'Smart Recurring Tasks',
                      desc: 'Daily, weekly, monthly, yearly, or custom days. Exclude specific dates.',
                    },
                    {
                      title: 'Duration Estimates',
                      desc: 'Add time estimates. Link tasks to focus sessions. Track actual time.',
                    },
                    {
                      title: 'Convert to Presets',
                      desc: 'Turn tasks into focus presets. One tap to start a configured session.',
                    },
                    {
                      title: 'Smart Reminders',
                      desc: 'Set one-time or recurring reminders. Never miss important tasks.',
                    },
                  ].map((feature, i) => (
                    <div key={i} className="flex gap-4 items-start">
                      <div className="w-2 h-2 rounded-full bg-[var(--success)] mt-2 flex-shrink-0" />
                    <div>
                        <h4 className="font-semibold text-[var(--foreground)] mb-1">{feature.title}</h4>
                        <p className="text-sm text-[var(--foreground-muted)] leading-relaxed">{feature.desc}</p>
                    </div>
                  </div>
                  ))}
                    </div>
              </div>
            </div>
          </div>
        </Container>
      </section>

      {/* ═══════════════════════════════════════════════════════════════
          PROGRESS TRACKING FEATURE
          ═══════════════════════════════════════════════════════════════ */}
      <section className="section-padding bg-[var(--background-elevated)]">
        <Container>
          <div className="max-w-6xl mx-auto">
            <div className="grid lg:grid-cols-2 gap-16 items-center">
              <div>
                <div className="inline-flex items-center gap-2 badge badge-primary mb-6">
                  <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6" />
                    </svg>
                  Core Feature
                  </div>
                <h2 className="mb-6">Progress & Journey</h2>
                <p className="text-xl text-[var(--foreground-muted)] leading-relaxed mb-8">
                  Track your focus time, maintain streaks, and watch your progress grow. Unlock achievements as you build habits.
                </p>
                
                <div className="space-y-6">
                  {[
                    {
                      title: 'XP System & 50 Levels',
                      desc: 'Earn XP for focus sessions and completed tasks. Level up through 50 ranks.',
                    },
                    {
                      title: 'Achievement Badges',
                      desc: 'Unlock badges for milestones. First session, 7-day streak, 100 hours, and more.',
                    },
                    {
                      title: 'Daily Summaries',
                      desc: 'View daily focus time and tasks. Journey view shows long-term trends.',
                    },
                    {
                      title: 'Streak Tracking',
                      desc: 'Maintain your focus streak. Build consistency and momentum.',
                    },
                  ].map((feature, i) => (
                    <div key={i} className="flex gap-4 items-start">
                      <div className="w-2 h-2 rounded-full bg-[var(--accent-secondary)] mt-2 flex-shrink-0" />
                    <div>
                        <h4 className="font-semibold text-[var(--foreground)] mb-1">{feature.title}</h4>
                        <p className="text-sm text-[var(--foreground-muted)] leading-relaxed">{feature.desc}</p>
                    </div>
                  </div>
                  ))}
                    </div>
                    </div>
              
              <div className="flex justify-center">
                <div className="relative">
                  <div className="absolute inset-0 bg-gradient-to-r from-amber-500/30 to-orange-500/20 blur-[60px] scale-125" />
                <PhoneSimulator 
                  screenshots={[
                    '/images/screen-progress-1.png',
                    '/images/screen-progress-2.png',
                    '/images/screen-progress-3.png',
                  ]}
                  screenData={[
                      { icon: '📈', title: 'Progress', desc: 'Summary', gradient: 'from-amber-500 to-orange-600' },
                      { icon: '📈', title: 'Progress', desc: 'Journey', gradient: 'from-amber-500 to-orange-600' },
                      { icon: '📈', title: 'Progress', desc: 'Badges', gradient: 'from-amber-500 to-orange-600' },
                  ]}
                />
              </div>
              </div>
            </div>
          </div>
        </Container>
      </section>

      {/* ═══════════════════════════════════════════════════════════════
          ADDITIONAL FEATURES GRID
          ═══════════════════════════════════════════════════════════════ */}
      <section className="section-padding">
        <Container>
          <div className="max-w-6xl mx-auto">
            <div className="text-center mb-16">
              <h2 className="mb-6">Everything you need</h2>
              <p className="text-xl text-[var(--foreground-muted)] leading-relaxed max-w-3xl mx-auto">
                Premium features designed for serious focus.
              </p>
            </div>

            <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
              {[
                {
                  title: '10 Beautiful Themes',
                  desc: 'Forest, Neon Glow, Soft Peach, Cyber Violet, Ocean Mist, and more.',
                  icon: '🎨',
                },
                {
                  title: 'Widgets & Live Activity',
                  desc: 'Home Screen widgets and Lock Screen Live Activity.',
                  icon: '📱',
                },
                {
                  title: 'Privacy First',
                  desc: 'Guest Mode, no tracking, no ads. Your data stays yours.',
                  icon: '🔒',
                },
                {
                  title: 'Works Offline',
                  desc: 'All core features work without internet connection.',
                  icon: '✈️',
                },
                {
                  title: '50+ Symbol Avatars',
                  desc: 'Personalize your profile without photo access.',
                  icon: '👤',
                },
                {
                  title: 'Cloud Sync',
                  desc: 'Optional sync across devices. Or stay completely local.',
                  icon: '☁️',
                },
              ].map((feature, i) => (
                <div key={i} className="card group p-6 hover:border-[var(--accent-primary)]/30">
                  <div className="text-3xl mb-4 group-hover:scale-110 transition-transform duration-300">{feature.icon}</div>
                  <h3 className="text-lg font-semibold text-[var(--foreground)] mb-2">{feature.title}</h3>
                  <p className="text-sm text-[var(--foreground-muted)] leading-relaxed">{feature.desc}</p>
                </div>
              ))}
            </div>
          </div>
        </Container>
      </section>

      {/* ═══════════════════════════════════════════════════════════════
          FOCUSFLOW PRO - PRICING
          ═══════════════════════════════════════════════════════════════ */}
      <section className="section-padding relative">
        {/* Premium background - contained overflow */}
        <div className="absolute inset-0 overflow-hidden">
          <div className="absolute inset-0 bg-mesh" />
          <div className="absolute top-1/4 left-1/4 w-[500px] h-[500px] rounded-full blur-[80px] opacity-20 bg-gradient-to-r from-[var(--accent-primary)] to-[var(--accent-secondary)]" />
          <div className="absolute bottom-1/4 right-1/4 w-[400px] h-[400px] rounded-full blur-[60px] opacity-15 bg-gradient-to-r from-[var(--accent-secondary)] to-[var(--accent-primary)]" />
        </div>
        
        <Container>
          <div className="max-w-6xl mx-auto relative z-10">
            {/* Header */}
            <div className="text-center mb-16 relative">
              <div className="inline-flex items-center gap-2 badge badge-primary mb-6">
                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 10V3L4 14h7v7l9-11h-7z" />
                </svg>
                Premium Experience
              </div>
              <h2 className="mb-6">
                FocusFlow <span className="text-gradient">Pro</span>
              </h2>
              <p className="text-xl text-[var(--foreground-muted)] leading-relaxed max-w-2xl mx-auto mb-8">
                Unlock the full potential. Advanced features for power users.
              </p>
              
              {/* Currency Selector */}
              <div className="flex justify-center">
                <CurrencySelector onCurrencyChange={setSelectedCurrency} defaultCurrency="CAD" />
              </div>
            </div>

            {/* Pricing Cards */}
            <div className="grid md:grid-cols-3 gap-6 mb-16 items-end pt-12">
              {/* Free */}
              <div className="card p-8 flex flex-col h-full">
                <div className="text-center mb-6">
                  <h3 className="text-xl font-semibold text-[var(--foreground)] mb-2">Free</h3>
                  <div className="text-4xl font-bold text-[var(--foreground)] mb-1">$0</div>
                  <p className="text-sm text-[var(--foreground-subtle)]">Forever</p>
                  {/* Spacer to match Pro Yearly height */}
                  <div className="mt-3 h-7" />
                </div>
                <ul className="space-y-3 mb-8 flex-1">
                  {[
                    'Focus timer with 3 backgrounds',
                    'Basic task management',
                    'Progress tracking with XP',
                    '3 themes',
                    'Limited presets',
                    ' ', // Spacer
                  ].map((feature, i) => (
                    <li key={i} className={`flex items-start gap-3 text-sm text-[var(--foreground-muted)] ${feature === ' ' ? 'invisible' : ''}`}>
                      <svg className="w-4 h-4 text-[var(--foreground-subtle)] flex-shrink-0 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                      </svg>
                      {feature}
                    </li>
                  ))}
                </ul>
                <div className="btn btn-secondary w-full justify-center opacity-50 cursor-not-allowed mt-auto">
                    Current Plan
                </div>
              </div>

              {/* Pro Yearly - Featured (Bigger & Stands Out) */}
              <div className="relative pt-6 md:-mt-8">
                {/* Best Value Badge - Outside the card so it won't be clipped */}
                <div className="absolute top-0 left-1/2 -translate-x-1/2 z-20">
                  <div className="px-5 py-2 rounded-full bg-gradient-to-r from-[var(--accent-primary)] to-[var(--accent-primary-dark)] text-white text-sm font-semibold shadow-lg shadow-[var(--accent-primary)]/40 whitespace-nowrap">
                    Best Value
                  </div>
                </div>
                
                <div className="card p-10 border-2 border-[var(--accent-primary)]/60 flex flex-col h-full shadow-xl shadow-[var(--accent-primary)]/10">
                <div className="text-center mb-8">
                    <h3 className="text-2xl font-semibold text-gradient mb-3">Pro Yearly</h3>
                    <div className="text-5xl font-bold text-[var(--foreground)] mb-2">
                    ${selectedCurrency === 'USD' ? '44.99' : '59.99'}
                    </div>
                    <p className="text-sm text-[var(--foreground-subtle)]">per year</p>
                    <div className="mt-4 inline-flex items-center gap-2 px-4 py-2 rounded-full bg-[var(--success)]/15 text-[var(--success)] text-sm font-medium border border-[var(--success)]/20">
                      Save ${selectedCurrency === 'USD' ? '2.89' : '11.88'}/year
                  </div>
                </div>
                  <ul className="space-y-4 mb-10 flex-1">
                  {[
                    'Everything in Free',
                    'All 14 ambient backgrounds',
                      'Unlimited presets & tasks',
                    'All 10 premium themes',
                    'Advanced progress insights',
                    'Priority support',
                  ].map((feature, i) => (
                      <li key={i} className="flex items-start gap-3 text-[var(--foreground-muted)]">
                        <svg className="w-5 h-5 text-[var(--accent-primary)] flex-shrink-0 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                      </svg>
                        {feature}
                    </li>
                  ))}
                </ul>
                  <a
                    href="https://apps.apple.com/app/focusflow-be-present/id6739000000"
                    target="_blank"
                    rel="noopener noreferrer"
                    className="btn btn-accent btn-lg w-full justify-center mt-auto"
                  >
                    Start Free Trial
                  </a>
                </div>
              </div>

              {/* Pro Monthly */}
              <div className="card p-8 flex flex-col h-full">
                <div className="text-center mb-6">
                  <h3 className="text-xl font-semibold text-gradient mb-2">Pro Monthly</h3>
                  <div className="text-4xl font-bold text-[var(--foreground)] mb-1">
                    ${selectedCurrency === 'USD' ? '3.99' : '5.99'}
                </div>
                  <p className="text-sm text-[var(--foreground-subtle)]">per month</p>
                  {/* Spacer to match Pro Yearly height */}
                  <div className="mt-3 h-7" />
                </div>
                <ul className="space-y-3 mb-8 flex-1">
                  {[
                    'Everything in Free',
                    'All 14 ambient backgrounds',
                    'Unlimited presets & tasks',
                    'All 10 premium themes',
                    'Advanced progress insights',
                    'Priority support',
                  ].map((feature, i) => (
                    <li key={i} className="flex items-start gap-3 text-sm text-[var(--foreground-muted)]">
                      <svg className="w-4 h-4 text-[var(--accent-primary)] flex-shrink-0 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                      </svg>
                      {feature}
                    </li>
                  ))}
                </ul>
                  <a
                    href="https://apps.apple.com/app/focusflow-be-present/id6739000000"
                    target="_blank"
                    rel="noopener noreferrer"
                  className="btn btn-secondary w-full justify-center mt-auto"
                  >
                    Start Free Trial
                  </a>
              </div>
            </div>

            {/* Pro CTA */}
            <div className="card-glass p-12 text-center relative overflow-hidden">
              <div className="absolute inset-0 bg-gradient-to-r from-[var(--accent-primary)]/10 to-[var(--accent-secondary)]/10" />
              <div className="relative z-10">
                <div className="text-5xl mb-6">✨</div>
                <h3 className="text-3xl font-bold text-[var(--foreground)] mb-4">Start Your Free Trial</h3>
                <p className="text-lg text-[var(--foreground-muted)] mb-2">3 days free, then choose your plan</p>
                <p className="text-[var(--foreground-subtle)] mb-8">Cancel anytime. No commitment.</p>
                  <a
                    href="https://apps.apple.com/app/focusflow-be-present/id6739000000"
                    target="_blank"
                    rel="noopener noreferrer"
                  className="btn btn-accent btn-lg"
                >
                  Download & Try Free
                </a>
              </div>
            </div>
          </div>
        </Container>
      </section>

      {/* ═══════════════════════════════════════════════════════════════
          FINAL CTA
          ═══════════════════════════════════════════════════════════════ */}
      <section className="section-padding bg-[var(--background-elevated)]">
        <Container>
          <div className="max-w-3xl mx-auto text-center">
            <div className="mb-10 flex justify-center">
              <div className="relative group">
                {/* Glow effect behind icon */}
                <div className="absolute -inset-4 bg-gradient-to-br from-[var(--accent-primary)]/40 to-[var(--accent-secondary)]/30 rounded-[28px] blur-2xl opacity-60 group-hover:opacity-80 transition-opacity duration-500" />
                <Image
                  src="/focusflow_app_icon.jpg"
                  alt="FocusFlow"
                  width={120}
                  height={120}
                  className="relative rounded-[24px] shadow-2xl transition-all duration-500 group-hover:scale-105"
                  style={{ 
                    boxShadow: '0 10px 40px rgba(0, 0, 0, 0.4), 0 0 0 1px rgba(255, 255, 255, 0.1) inset'
                  }}
                />
              </div>
            </div>
            <h2 className="mb-6">Ready to build better focus habits?</h2>
            <p className="text-xl text-[var(--foreground-muted)] mb-10 leading-relaxed">
              Download FocusFlow and start your journey to more focused, productive work.
            </p>
                <div className="flex flex-col sm:flex-row gap-4 justify-center">
                  <a
                    href="https://apps.apple.com/app/focusflow-be-present/id6739000000"
                    target="_blank"
                    rel="noopener noreferrer"
                className="btn btn-accent btn-lg"
                  >
                <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
                  <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z"/>
                </svg>
                    Download on App Store
                  </a>
              <Link href="/support" className="btn btn-secondary btn-lg">
                Get Support
                  </Link>
                </div>
          </div>
        </Container>
      </section>
    </div>
  );
}
