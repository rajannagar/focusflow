'use client';

import Link from 'next/link';
import Image from 'next/image';
import Container from '@/components/ui/Container';
import { useThrottledMouse } from './hooks/useThrottledMouse';

export default function Home() {
  const mousePosition = useThrottledMouse();

  return (
    <div className="min-h-screen bg-[var(--background)]">
      
      {/* ═══════════════════════════════════════════════════════════════
          HERO SECTION - Company Intro
          ═══════════════════════════════════════════════════════════════ */}
      <section className="relative min-h-[calc(100vh-4rem)] md:min-h-[calc(100vh-5rem)] flex items-center justify-center overflow-hidden">
        {/* Animated Aurora Background - Smaller on mobile to prevent overflow */}
        <div className="absolute inset-0 bg-aurora">
          <div 
            className="absolute top-1/4 left-1/4 w-[300px] md:w-[600px] h-[300px] md:h-[600px] rounded-full blur-[60px] md:blur-[80px] opacity-25 md:opacity-30 transition-transform duration-1000 ease-out"
            style={{
              background: `radial-gradient(circle, rgba(139, 92, 246, 0.4) 0%, transparent 70%)`,
              transform: `translate(${mousePosition.x * 0.02}px, ${mousePosition.y * 0.02}px)`,
              willChange: 'transform',
            }}
          />
          <div 
            className="absolute bottom-1/4 right-1/4 w-[250px] md:w-[500px] h-[250px] md:h-[500px] rounded-full blur-[40px] md:blur-[60px] opacity-15 md:opacity-20 transition-transform duration-1000 ease-out"
            style={{
              background: `radial-gradient(circle, rgba(212, 168, 83, 0.3) 0%, transparent 70%)`,
              transform: `translate(${-mousePosition.x * 0.015}px, ${-mousePosition.y * 0.015}px)`,
              willChange: 'transform',
            }}
          />
        </div>

        {/* Grid Pattern Overlay */}
        <div className="absolute inset-0 bg-grid opacity-30" />

        {/* Hero Content */}
        <div className="relative z-10 w-full">
              <Container>
                <div className="max-w-5xl mx-auto text-center py-12 md:py-20 px-4">
                  {/* Badge */}
                  <div className="inline-flex items-center gap-2 badge badge-primary mb-6 md:mb-8">
                    <span className="w-2 h-2 rounded-full bg-[var(--accent-primary)] animate-pulse" />
                    Premium Software Studio
                  </div>

                  {/* Main Headline */}
                  <h1 className="mb-6 md:mb-8 tracking-tight">
                    <span className="block text-[var(--foreground)]">Build focus.</span>
                    <span className="block text-gradient">Ship work.</span>
                  </h1>

                  {/* Subheadline */}
                  <p className="text-lg md:text-2xl text-[var(--foreground-muted)] leading-relaxed mb-8 md:mb-12 max-w-3xl mx-auto">
                    We create premium software that helps people do meaningful work—calmly, consistently, and with intention.
                  </p>

                  {/* CTA Buttons */}
                  <div className="flex flex-col sm:flex-row gap-3 md:gap-4 justify-center">
                    <Link href="/focusflow" className="btn btn-primary btn-lg">
                      Explore FocusFlow
                      <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 8l4 4m0 0l-4 4m4-4H3" />
                      </svg>
                    </Link>
                    <Link href="/about" className="btn btn-secondary btn-lg">
                      Learn about us
                    </Link>
                  </div>
                </div>
              </Container>
        </div>
      </section>

      {/* ═══════════════════════════════════════════════════════════════
          PRODUCT SPOTLIGHT - FocusFlow
          ═══════════════════════════════════════════════════════════════ */}
      <section className="relative py-16 md:py-32 overflow-hidden">
        {/* Subtle gradient background */}
        <div className="absolute inset-0 bg-gradient-to-b from-[var(--background)] via-[var(--background-elevated)] to-[var(--background)]" />
        
        <Container>
          <div className="relative z-10 max-w-6xl mx-auto">
            {/* Section Header */}
            <div className="text-center mb-10 md:mb-20">
              <div className="inline-flex items-center gap-2 badge badge-primary mb-4 md:mb-6">
                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 10V3L4 14h7v7l9-11h-7z" />
                </svg>
                Flagship Product
              </div>
              <h2 className="mb-4 md:mb-6">
                <span className="text-gradient">FocusFlow</span>
              </h2>
              <p className="text-base md:text-xl text-[var(--foreground-muted)] max-w-2xl mx-auto px-4">
                A premium focus timer, task manager, and progress tracker. Everything you need to do deep work and build lasting habits.
              </p>
            </div>

            {/* Product Card */}
            <div className="relative">
              {/* Glow behind card */}
              <div className="absolute inset-0 bg-gradient-to-r from-[var(--accent-primary)]/20 via-[var(--accent-secondary)]/10 to-[var(--accent-primary)]/20 blur-3xl opacity-50" />
              
              <div className="relative card-glass p-5 md:p-8 lg:p-12">
                <div className="grid lg:grid-cols-2 gap-8 lg:gap-12 items-center">
                  {/* Left - App Info */}
                  <div>
                    <div className="flex items-center gap-4 md:gap-5 mb-6 md:mb-8">
                      <div className="relative group flex-shrink-0">
                        {/* Glow effect behind icon */}
                        <div className="absolute -inset-2 bg-gradient-to-br from-[var(--accent-primary)]/30 to-[var(--accent-secondary)]/20 rounded-2xl blur-xl opacity-50 group-hover:opacity-70 transition-opacity duration-500" />
                        <Image
                          src="/focusflow_app_icon.jpg"
                          alt="FocusFlow - Be Present"
                          width={64}
                          height={64}
                          className="relative rounded-[14px] md:rounded-[18px] shadow-2xl transition-transform duration-500 group-hover:scale-105 md:w-20 md:h-20"
                          style={{ 
                            boxShadow: '0 8px 32px rgba(0, 0, 0, 0.3), 0 0 0 1px rgba(255, 255, 255, 0.08) inset'
                          }}
                        />
                      </div>
                      <div>
                        <h3 className="text-2xl md:text-3xl font-semibold text-[var(--foreground)] mb-1">FocusFlow</h3>
                        <p className="text-sm md:text-base text-[var(--foreground-muted)]">Be Present</p>
                      </div>
                    </div>

                    <p className="text-base md:text-lg text-[var(--foreground-muted)] leading-relaxed mb-6 md:mb-8">
                      Everything you need to stay focused, organized, and motivated—all in one beautiful, privacy-first app.
                    </p>

                    {/* Feature Pills */}
                    <div className="flex flex-wrap gap-3 mb-10">
                      {['14 Ambient Backgrounds', 'Smart Tasks', 'Progress Tracking', '10 Themes'].map((feature, i) => (
                        <span key={i} className="px-4 py-2 rounded-full bg-[var(--background-subtle)] text-sm text-[var(--foreground-muted)] border border-[var(--border)]">
                          {feature}
                        </span>
                      ))}
                    </div>

                    {/* CTAs */}
                    <div className="flex flex-col sm:flex-row gap-4">
                      <Link href="/focusflow" className="btn btn-accent">
                        Learn More
                        <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 8l4 4m0 0l-4 4m4-4H3" />
                        </svg>
                      </Link>
                      <a
                        href="https://apps.apple.com/app/focusflow-be-present/id6739000000"
                        target="_blank"
                        rel="noopener noreferrer"
                        className="btn btn-secondary"
                      >
                        <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
                          <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z"/>
                        </svg>
                        App Store
                      </a>
                    </div>
                  </div>

                  {/* Right - Feature Grid */}
                  <div className="grid grid-cols-2 gap-4">
                    {[
                      { 
                        title: 'Focus Timer', 
                        desc: 'Timed sessions with ambient sounds',
                        icon: (
                          <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M12 6v6h4.5m4.5 0a9 9 0 11-18 0 9 9 0 0118 0z" />
                          </svg>
                        )
                      },
                      { 
                        title: 'Smart Tasks', 
                        desc: 'Recurring tasks & reminders',
                        icon: (
                          <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                          </svg>
                        )
                      },
                      { 
                        title: 'XP & Levels', 
                        desc: '50 levels to unlock',
                        icon: (
                          <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6" />
                          </svg>
                        )
                      },
                      { 
                        title: 'Themes', 
                        desc: '10 beautiful themes',
                        icon: (
                          <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M7 21a4 4 0 01-4-4V5a2 2 0 012-2h4a2 2 0 012 2v12a4 4 0 01-4 4zm0 0h12a2 2 0 002-2v-4a2 2 0 00-2-2h-2.343M11 7.343l1.657-1.657a2 2 0 012.828 0l2.829 2.829a2 2 0 010 2.828l-8.486 8.485M7 17h.01" />
                          </svg>
                        )
                      },
                    ].map((item, i) => (
                      <div key={i} className="card-glow p-6 group cursor-default">
                        <div className="text-[var(--accent-primary)] mb-4 group-hover:scale-110 transition-transform duration-300">
                          {item.icon}
                        </div>
                        <h4 className="text-base font-semibold text-[var(--foreground)] mb-1">{item.title}</h4>
                        <p className="text-sm text-[var(--foreground-subtle)]">{item.desc}</p>
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            </div>
          </div>
        </Container>
      </section>

      {/* ═══════════════════════════════════════════════════════════════
          WHAT WE DO - Philosophy Cards
          ═══════════════════════════════════════════════════════════════ */}
      <section className="section-padding">
        <Container>
          <div className="max-w-6xl mx-auto">
            {/* Section Header */}
            <div className="text-center mb-10 md:mb-16">
              <h2 className="mb-4">What we do</h2>
              <p className="text-base md:text-xl text-[var(--foreground-muted)] max-w-2xl mx-auto px-4">
                We craft software that solves real problems with elegant solutions.
              </p>
            </div>

            {/* Bento Grid */}
            <div className="grid md:grid-cols-3 gap-6">
              {[
                {
                  title: 'Design with intention',
                  desc: 'Every interface, every interaction, every detail is thoughtfully considered. We build products that feel natural and effortless.',
                  icon: (
                    <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M7 21a4 4 0 01-4-4V5a2 2 0 012-2h4a2 2 0 012 2v12a4 4 0 01-4 4zm0 0h12a2 2 0 002-2v-4a2 2 0 00-2-2h-2.343M11 7.343l1.657-1.657a2 2 0 012.828 0l2.829 2.829a2 2 0 010 2.828l-8.486 8.485M7 17h.01" />
                    </svg>
                  ),
                  gradient: 'from-violet-500/20 to-purple-500/20',
                },
                {
                  title: 'Build for clarity',
                  desc: 'Complex problems deserve simple solutions. We strip away the unnecessary to reveal what matters most.',
                  icon: (
                    <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z" />
                    </svg>
                  ),
                  gradient: 'from-amber-500/20 to-orange-500/20',
                },
                {
                  title: 'Focus on what matters',
                  desc: 'We don\'t build features for the sake of features. Every addition serves a purpose and enhances the core experience.',
                  icon: (
                    <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                    </svg>
                  ),
                  gradient: 'from-emerald-500/20 to-teal-500/20',
                },
              ].map((item, i) => (
                <div key={i} className="card group p-8 hover:border-[var(--accent-primary)]/30">
                  {/* Gradient overlay on hover */}
                  <div className={`absolute inset-0 bg-gradient-to-br ${item.gradient} opacity-0 group-hover:opacity-100 transition-opacity duration-500 rounded-[var(--radius-lg)]`} />
                  
                  <div className="relative z-10">
                    <div className="text-[var(--accent-primary)] mb-6 group-hover:scale-110 transition-transform duration-300">
                      {item.icon}
                    </div>
                    <h3 className="text-xl font-semibold text-[var(--foreground)] mb-4">{item.title}</h3>
                    <p className="text-[var(--foreground-muted)] leading-relaxed">{item.desc}</p>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </Container>
      </section>

      {/* ═══════════════════════════════════════════════════════════════
          OUR APPROACH - Horizontal Features
          ═══════════════════════════════════════════════════════════════ */}
      <section className="section-padding bg-[var(--background-elevated)]">
        <Container>
          <div className="max-w-5xl mx-auto">
            {/* Section Header */}
            <div className="text-center mb-10 md:mb-20">
              <h2 className="mb-4">Our approach</h2>
              <p className="text-base md:text-xl text-[var(--foreground-muted)] max-w-2xl mx-auto px-4">
                How we build products that people love to use.
              </p>
            </div>

            {/* Approach Items */}
            <div className="space-y-6">
              {[
                {
                  title: 'User-centric from day one',
                  desc: 'We start by understanding real problems. Not assumptions, not trends—actual needs that people face every day.',
                  number: '01',
                },
                {
                  title: 'Privacy and trust by default',
                  desc: 'Your data is yours. We build with privacy-first principles. No tracking, no ads, no selling your information.',
                  number: '02',
                },
                {
                  title: 'Quality over quantity',
                  desc: 'We\'d rather build one exceptional product than ten mediocre ones. Every release is polished and tested.',
                  number: '03',
                },
                {
                  title: 'Continuous improvement',
                  desc: 'Great products evolve. We listen, learn, and iterate. Your feedback shapes what we build next.',
                  number: '04',
                },
              ].map((item, i) => (
                <div key={i} className="group flex gap-4 md:gap-8 items-start p-4 md:p-6 rounded-2xl hover:bg-[var(--background-subtle)] transition-all duration-300 cursor-default">
                  <span className="text-3xl md:text-5xl font-bold text-[var(--accent-primary)]/20 group-hover:text-[var(--accent-primary)]/40 transition-colors duration-300 font-mono flex-shrink-0">
                    {item.number}
                  </span>
                  <div className="flex-1 pt-1 md:pt-2">
                    <h3 className="text-lg md:text-xl font-semibold text-[var(--foreground)] mb-2 group-hover:text-[var(--accent-primary-light)] transition-colors duration-300">
                      {item.title}
                    </h3>
                    <p className="text-sm md:text-base text-[var(--foreground-muted)] leading-relaxed">{item.desc}</p>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </Container>
      </section>

      {/* ═══════════════════════════════════════════════════════════════
          QUOTE / PHILOSOPHY
          ═══════════════════════════════════════════════════════════════ */}
      <section className="section-padding relative overflow-hidden">
        {/* Background effect */}
        <div className="absolute inset-0">
          <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[800px] h-[800px] rounded-full bg-gradient-to-r from-[var(--accent-primary)]/10 to-[var(--accent-secondary)]/10 blur-3xl" />
        </div>
        
        <Container>
          <div className="relative z-10 max-w-4xl mx-auto text-center px-4">
            <div className="text-4xl md:text-6xl mb-6 md:mb-8 opacity-50">✨</div>
            <blockquote className="text-xl md:text-3xl text-[var(--foreground)] leading-relaxed mb-6 md:mb-8 font-medium">
              "We're not just building software. We're crafting experiences that help people reclaim their time, focus their energy, and achieve what matters most."
            </blockquote>
            <cite className="text-sm md:text-base text-[var(--foreground-muted)] not-italic">— The Soft Computers Philosophy</cite>
          </div>
        </Container>
      </section>

      {/* ═══════════════════════════════════════════════════════════════
          FINAL CTA
          ═══════════════════════════════════════════════════════════════ */}
      <section className="section-padding bg-[var(--background-elevated)] relative overflow-hidden">
        {/* Gradient mesh background */}
        <div className="absolute inset-0 bg-mesh opacity-50" />
        
        <Container>
          <div className="relative z-10 max-w-3xl mx-auto text-center px-4">
            <h2 className="mb-4 md:mb-6">Ready to focus?</h2>
            <p className="text-base md:text-xl text-[var(--foreground-muted)] mb-8 md:mb-10 leading-relaxed">
              Explore our products, learn about our approach, or get in touch. Let's build something meaningful together.
            </p>
            <div className="flex flex-col sm:flex-row gap-3 md:gap-4 justify-center">
              <Link href="/focusflow" className="btn btn-accent btn-lg">
                Explore FocusFlow
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 8l4 4m0 0l-4 4m4-4H3" />
                </svg>
              </Link>
              <Link href="/about" className="btn btn-secondary btn-lg">
                About Us
              </Link>
              <Link href="/support" className="btn btn-secondary btn-lg">
                Get in Touch
              </Link>
            </div>
          </div>
        </Container>
      </section>
    </div>
  );
}
