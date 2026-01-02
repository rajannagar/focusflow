'use client';

import Link from 'next/link';
import Image from 'next/image';
import Container from '@/components/ui/Container';
import PhoneSimulator from '@/components/phone/iPhoneSimulator';
import CurrencySelector from '@/components/ui/CurrencySelector';
import { useState } from 'react';
import { useThrottledMouse } from '../hooks/useThrottledMouse';

// Feature data for the tabbed section
const features = [
  {
    id: 'timer',
    label: 'Focus Timer',
    icon: '⏱️',
    color: 'violet',
    headline: 'Deep focus, beautiful ambiance',
    description: 'Start timed sessions with customizable durations. Choose from 14 ambient backgrounds or connect your music app.',
    highlights: [
      { title: '14 Ambient Backgrounds', desc: 'Aurora, Rain, Fireplace, Ocean, Forest, and more' },
      { title: 'Music Integration', desc: 'Spotify, Apple Music, or YouTube Music' },
      { title: 'Live Activity', desc: 'See your timer on Lock Screen' },
      { title: 'Session Intentions', desc: 'Set focus goals for each session' },
    ],
    screenshots: ['/images/screen-focus-1.png', '/images/screen-focus-2.png', '/images/screen-focus-3.png'],
    screenData: [
      { icon: '⏱️', title: 'Timer', desc: 'Start session', gradient: 'from-violet-500 to-purple-600' },
      { icon: '⏱️', title: 'Timer', desc: 'In progress', gradient: 'from-violet-500 to-purple-600' },
      { icon: '⏱️', title: 'Timer', desc: 'Complete', gradient: 'from-violet-500 to-purple-600' },
    ],
    gradient: 'from-violet-500/30 to-purple-500/20',
    accentColor: 'var(--accent-primary)',
  },
  {
    id: 'tasks',
    label: 'Tasks',
    icon: '✅',
    color: 'emerald',
    headline: 'Smart task management',
    description: 'Organize your to-do list with reminders, recurring schedules, and focus session integration.',
    highlights: [
      { title: 'Recurring Tasks', desc: 'Daily, weekly, monthly, or custom' },
      { title: 'Duration Estimates', desc: 'Track actual vs estimated time' },
      { title: 'Convert to Presets', desc: 'One tap to start configured sessions' },
      { title: 'Smart Reminders', desc: 'Never miss important tasks' },
    ],
    screenshots: ['/images/screen-tasks-1.png', '/images/screen-tasks-2.png', '/images/screen-tasks-3.png'],
    screenData: [
      { icon: '✅', title: 'Tasks', desc: 'Task list', gradient: 'from-emerald-500 to-teal-600' },
      { icon: '✅', title: 'Tasks', desc: 'Create task', gradient: 'from-emerald-500 to-teal-600' },
      { icon: '✅', title: 'Tasks', desc: 'Details', gradient: 'from-emerald-500 to-teal-600' },
    ],
    gradient: 'from-emerald-500/30 to-teal-500/20',
    accentColor: 'var(--success)',
  },
  {
    id: 'progress',
    label: 'Progress',
    icon: '📈',
    color: 'amber',
    headline: 'Track your growth',
    description: 'Earn XP, level up through 50 ranks, maintain streaks, and unlock achievement badges.',
    highlights: [
      { title: 'XP & 50 Levels', desc: 'Earn XP for sessions and tasks' },
      { title: 'Achievement Badges', desc: 'Unlock milestones and rewards' },
      { title: 'Daily Summaries', desc: 'View focus time and trends' },
      { title: 'Streak Tracking', desc: 'Build consistency over time' },
    ],
    screenshots: ['/images/screen-progress-1.png', '/images/screen-progress-2.png', '/images/screen-progress-3.png'],
    screenData: [
      { icon: '📈', title: 'Progress', desc: 'Summary', gradient: 'from-amber-500 to-orange-600' },
      { icon: '📈', title: 'Progress', desc: 'Journey', gradient: 'from-amber-500 to-orange-600' },
      { icon: '📈', title: 'Progress', desc: 'Badges', gradient: 'from-amber-500 to-orange-600' },
    ],
    gradient: 'from-amber-500/30 to-orange-500/20',
    accentColor: 'var(--accent-secondary)',
  },
  {
    id: 'profile',
    label: 'Profile',
    icon: '👤',
    color: 'rose',
    headline: 'Make it yours',
    description: 'Personalize every aspect of your experience. Choose your avatar, pick your theme, and sync across all your devices.',
    highlights: [
      { title: '10 Beautiful Themes', desc: 'Forest, Neon Glow, Ocean Mist, and more' },
      { title: '50+ Symbol Avatars', desc: 'Express yourself without photos' },
      { title: 'Custom Focus Presets', desc: 'Save your favorite session setups' },
      { title: 'Cloud Sync', desc: 'Your data on all your devices' },
    ],
    screenshots: ['/images/screen-profile.png', '/images/screen-profile-2.png', '/images/screen-profile-3.png'],
    screenData: [
      { icon: '👤', title: 'Profile', desc: 'Your space', gradient: 'from-rose-500 to-pink-600' },
      { icon: '👤', title: 'Profile', desc: 'Themes', gradient: 'from-rose-500 to-pink-600' },
      { icon: '👤', title: 'Profile', desc: 'Settings', gradient: 'from-rose-500 to-pink-600' },
    ],
    gradient: 'from-rose-500/30 to-pink-500/20',
    accentColor: 'var(--error)',
  },
];

export default function FocusFlowPage() {
  const mousePosition = useThrottledMouse();
  const [selectedCurrency, setSelectedCurrency] = useState<'USD' | 'CAD'>('CAD');
  const [activeFeature, setActiveFeature] = useState(0);

  return (
    <div className="min-h-screen bg-[var(--background)]">
      
      {/* ═══════════════════════════════════════════════════════════════
          HERO SECTION
          ═══════════════════════════════════════════════════════════════ */}
      <section className="relative pt-8 md:pt-16 pb-12 md:pb-24 overflow-hidden">
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
                
                {/* App Store Rating */}
                <div className="flex items-center gap-4 justify-center lg:justify-start">
                  <div className="flex items-center gap-1.5 px-4 py-2 rounded-full bg-[var(--background-subtle)] border border-[var(--border)]">
                    <div className="flex">
                      {[...Array(5)].map((_, i) => (
                        <svg key={i} className="w-4 h-4 text-amber-400" fill="currentColor" viewBox="0 0 20 20">
                          <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z" />
                        </svg>
                      ))}
                    </div>
                    <span className="text-sm font-medium text-[var(--foreground)]">5.0</span>
                    <span className="text-sm text-[var(--foreground-muted)]">on App Store</span>
                  </div>
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
          FEATURES - PREMIUM SHOWCASE
          ═══════════════════════════════════════════════════════════════ */}
      <section id="features" className="py-20 md:py-32 relative overflow-hidden">
        {/* Premium background */}
        <div className="absolute inset-0 bg-[var(--background)]" />
        <div className="absolute inset-0 bg-mesh opacity-30" />
        
        {/* Animated gradient orbs */}
        <div 
          className="absolute top-1/4 -left-1/4 w-[600px] h-[600px] rounded-full blur-[120px] opacity-20"
          style={{
            background: activeFeature === 0 
              ? 'radial-gradient(circle, rgba(139, 92, 246, 0.5) 0%, transparent 70%)'
              : activeFeature === 1
              ? 'radial-gradient(circle, rgba(16, 185, 129, 0.5) 0%, transparent 70%)'
              : activeFeature === 2
              ? 'radial-gradient(circle, rgba(245, 158, 11, 0.5) 0%, transparent 70%)'
              : 'radial-gradient(circle, rgba(244, 63, 94, 0.5) 0%, transparent 70%)',
            transition: 'background 0.8s ease-out',
          }}
        />
        <div 
          className="absolute bottom-1/4 -right-1/4 w-[500px] h-[500px] rounded-full blur-[100px] opacity-15"
          style={{
            background: activeFeature === 0 
              ? 'radial-gradient(circle, rgba(168, 85, 247, 0.4) 0%, transparent 70%)'
              : activeFeature === 1
              ? 'radial-gradient(circle, rgba(20, 184, 166, 0.4) 0%, transparent 70%)'
              : activeFeature === 2
              ? 'radial-gradient(circle, rgba(251, 191, 36, 0.4) 0%, transparent 70%)'
              : 'radial-gradient(circle, rgba(236, 72, 153, 0.4) 0%, transparent 70%)',
            transition: 'background 0.8s ease-out',
          }}
        />

        <Container>
          <div className="max-w-7xl mx-auto relative z-10">
            {/* Section Header */}
            <div className="text-center mb-16">
              <div className="inline-flex items-center gap-2 badge badge-primary mb-6">
                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 10V3L4 14h7v7l9-11h-7z" />
                </svg>
                Core Features
              </div>
              <h2 className="mb-4">Three tools. <span className="text-gradient">One app.</span></h2>
              <p className="text-lg text-[var(--foreground-muted)] max-w-2xl mx-auto">
                Everything you need for deep work and lasting habits.
              </p>
            </div>

            {/* Feature Navigation - Premium Pills */}
            <div className="flex justify-center mb-16">
              <div className="grid grid-cols-4 gap-2 md:gap-4 w-full max-w-3xl">
                {features.map((feature, index) => (
                  <button
                    key={feature.id}
                    onClick={() => setActiveFeature(index)}
                    className={`
                      relative group p-4 md:p-6 rounded-2xl border transition-all duration-500 text-center
                      ${activeFeature === index 
                        ? 'bg-gradient-to-br from-[var(--accent-primary)]/20 to-[var(--accent-primary)]/5 border-[var(--accent-primary)]/50 shadow-lg shadow-[var(--accent-primary)]/20' 
                        : 'bg-[var(--background-elevated)] border-[var(--border)] hover:border-[var(--accent-primary)]/30 hover:bg-[var(--background-subtle)]'
                      }
                    `}
                  >
                    {/* Active indicator line */}
                    <div 
                      className={`
                        absolute bottom-0 left-1/2 -translate-x-1/2 h-1 rounded-full bg-gradient-to-r from-[var(--accent-primary)] to-[var(--accent-secondary)] transition-all duration-500
                        ${activeFeature === index ? 'w-12 opacity-100' : 'w-0 opacity-0'}
                      `}
                    />
                    
                    <div className={`text-3xl md:text-4xl mb-2 md:mb-3 transition-transform duration-300 ${activeFeature === index ? 'scale-110' : 'group-hover:scale-105'}`}>
                      {feature.icon}
                    </div>
                    <div className={`text-sm md:text-base font-semibold transition-colors duration-300 ${activeFeature === index ? 'text-[var(--foreground)]' : 'text-[var(--foreground-muted)]'}`}>
                      {feature.label}
                    </div>
                  </button>
                ))}
              </div>
            </div>

            {/* Feature Content - Premium Card */}
            <div className="relative min-h-[600px] md:min-h-[500px]">
              {features.map((feature, index) => (
                <div
                  key={feature.id}
                  className={`
                    transition-all duration-700 ease-out
                    ${activeFeature === index 
                      ? 'opacity-100 translate-y-0 relative' 
                      : 'opacity-0 translate-y-8 absolute inset-0 pointer-events-none'
                    }
                  `}
                >
                  {/* Premium glass card */}
                  <div className="relative rounded-3xl overflow-hidden">
                    {/* Card background with gradient border effect */}
                    <div className="absolute inset-0 bg-gradient-to-br from-[var(--accent-primary)]/10 via-transparent to-[var(--accent-secondary)]/10" />
                    <div className="absolute inset-[1px] rounded-3xl bg-[var(--background-elevated)]" />
                    
                    <div className="relative p-6 md:p-10 lg:p-12">
                      <div className="grid lg:grid-cols-2 gap-10 lg:gap-16 items-center">
                        {/* Left - Phone */}
                        <div className="flex justify-center order-1">
                          <div className="relative">
                            <div className={`absolute inset-0 bg-gradient-to-r ${feature.gradient} blur-[80px] scale-150 opacity-60`} />
                            <PhoneSimulator 
                              screenshots={feature.screenshots}
                              screenData={feature.screenData}
                            />
                          </div>
                        </div>

                        {/* Right - Content */}
                        <div className="order-2">
                          <h3 className="text-3xl md:text-4xl lg:text-5xl font-bold text-[var(--foreground)] mb-4 md:mb-6 leading-tight">
                            {feature.headline}
                          </h3>
                          <p className="text-lg md:text-xl text-[var(--foreground-muted)] leading-relaxed mb-8 md:mb-10">
                            {feature.description}
                          </p>
                          
                          {/* Feature Highlights - Premium List */}
                          <div className="space-y-4">
                            {feature.highlights.map((highlight, i) => (
                              <div 
                                key={i} 
                                className="flex items-start gap-4 group"
                              >
                                <div 
                                  className="w-10 h-10 rounded-xl flex items-center justify-center flex-shrink-0 mt-0.5 transition-transform duration-300 group-hover:scale-110"
                                  style={{
                                    background: `linear-gradient(135deg, ${feature.accentColor}20, ${feature.accentColor}10)`,
                                    border: `1px solid ${feature.accentColor}30`,
                                  }}
                                >
                                  <svg className="w-5 h-5" style={{ color: feature.accentColor }} fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                                  </svg>
                                </div>
                                <div>
                                  <h4 className="font-semibold text-[var(--foreground)] mb-0.5">
                                    {highlight.title}
                                  </h4>
                                  <p className="text-sm text-[var(--foreground-muted)]">
                                    {highlight.desc}
                                  </p>
                                </div>
                              </div>
                            ))}
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </Container>
      </section>

      {/* ═══════════════════════════════════════════════════════════════
          TESTIMONIAL / SOCIAL PROOF
          ═══════════════════════════════════════════════════════════════ */}
      <section className="py-16 md:py-20">
        <Container>
          <div className="max-w-4xl mx-auto">
            <div className="card-glass p-8 md:p-12 text-center relative overflow-hidden">
              {/* Background accent */}
              <div className="absolute inset-0 bg-gradient-to-br from-[var(--accent-primary)]/5 to-transparent" />
              
              <div className="relative z-10">
                {/* Stars */}
                <div className="flex justify-center gap-1 mb-6">
                  {[...Array(5)].map((_, i) => (
                    <svg key={i} className="w-6 h-6 text-amber-400" fill="currentColor" viewBox="0 0 20 20">
                      <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z" />
                    </svg>
                  ))}
                </div>
                
                <blockquote className="text-xl md:text-2xl text-[var(--foreground)] leading-relaxed mb-6 font-medium">
                  "Finally, a focus app that actually helps me focus. The ambient backgrounds are beautiful, and the XP system keeps me motivated."
                </blockquote>
                
                <div className="text-[var(--foreground-muted)]">
                  — App Store Review
                </div>
              </div>
            </div>
          </div>
        </Container>
      </section>

      {/* ═══════════════════════════════════════════════════════════════
          ADDITIONAL FEATURES - COMPACT STRIP
          ═══════════════════════════════════════════════════════════════ */}
      <section className="py-12 md:py-16 bg-[var(--background-elevated)]">
        <Container>
          <div className="max-w-6xl mx-auto">
            <h3 className="text-center text-lg font-medium text-[var(--foreground-muted)] mb-8">
              Built for people who value
            </h3>
            
            <div className="flex flex-wrap justify-center gap-3 md:gap-4">
              {[
                { icon: '🔒', label: 'Privacy First' },
                { icon: '📱', label: 'Home Widgets' },
                { icon: '🔔', label: 'Live Activity' },
                { icon: '✈️', label: 'Works Offline' },
                { icon: '🎵', label: 'Music Integration' },
                { icon: '💾', label: 'Local Backup' },
              ].map((item, i) => (
                <div 
                  key={i} 
                  className="flex items-center gap-2 px-4 py-2.5 rounded-full bg-[var(--background-subtle)] border border-[var(--border)] hover:border-[var(--accent-primary)]/30 transition-colors"
                >
                  <span className="text-lg">{item.icon}</span>
                  <span className="text-sm font-medium text-[var(--foreground)]">{item.label}</span>
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
