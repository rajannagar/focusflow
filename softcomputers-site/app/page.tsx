'use client';

import Link from 'next/link';
import Image from 'next/image';
import Container from '@/components/ui/Container';
import { useEffect, useState } from 'react';

export default function Home() {
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
      {/* Hero Section - Company First */}
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
              Soft Computers
            </h1>
            <p className="text-2xl md:text-3xl text-[var(--muted)] leading-relaxed mb-12 max-w-4xl">
              We build premium software that helps people do meaningful work. Every product is designed with intention, built for clarity, and focused on what truly matters.
            </p>
            <div className="flex flex-col sm:flex-row gap-4">
              <Link
                href="/about"
                className="btn btn-primary inline-block text-center"
              >
                Learn about us
              </Link>
              <Link
                href="/focusflow"
                className="btn btn-secondary inline-block text-center"
              >
                See our products
              </Link>
            </div>
          </div>
        </Container>
      </section>

      {/* Our Products - FocusFlow Showcase - HIGHLIGHT SECTION */}
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
            <div className="text-center mb-16">
              <div className="inline-flex items-center justify-center gap-2 px-4 py-2 rounded-full bg-[var(--accent-primary)]/10 border border-[var(--accent-primary)]/20 mb-6">
                <svg className="w-5 h-5 text-[var(--accent-primary)]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 10V3L4 14h7v7l9-11h-7z" />
                </svg>
                <span className="text-sm font-semibold text-[var(--accent-primary)]">Our Flagship Product</span>
              </div>
              <h2 className="text-5xl md:text-6xl font-semibold tracking-tight mb-6">
                FocusFlow
              </h2>
              <p className="text-xl text-[var(--muted)] leading-relaxed max-w-3xl mx-auto">
                A premium focus timer, task manager, and progress tracker designed to help you do deep work and build lasting habits.
              </p>
            </div>

            <div className="grid md:grid-cols-2 gap-16 items-center mb-16">
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
                    <h3 className="text-4xl md:text-5xl font-semibold tracking-tight leading-none">
                      FocusFlow
                    </h3>
                    <p className="text-base text-[var(--muted)] mt-1">Be Present</p>
                  </div>
                </div>
                <p className="text-lg text-[var(--muted)] leading-relaxed mb-10">
                  Everything you need to stay focused, organized, and motivated—all in one beautiful, privacy-first app.
                </p>
                <ul className="space-y-4 mb-12 text-base text-[var(--muted)]">
                  <li className="flex items-start gap-4">
                    <div className="w-5 h-5 rounded-full bg-[var(--accent-primary)]/10 flex items-center justify-center flex-shrink-0 mt-0.5">
                      <div className="w-2 h-2 rounded-full bg-[var(--accent-primary)]" />
                    </div>
                    <span>14 ambient backgrounds for focus</span>
                  </li>
                  <li className="flex items-start gap-4">
                    <div className="w-5 h-5 rounded-full bg-[var(--accent-primary)]/10 flex items-center justify-center flex-shrink-0 mt-0.5">
                      <div className="w-2 h-2 rounded-full bg-[var(--accent-primary)]" />
                    </div>
                    <span>Smart task management with reminders</span>
                  </li>
                  <li className="flex items-start gap-4">
                    <div className="w-5 h-5 rounded-full bg-[var(--accent-primary)]/10 flex items-center justify-center flex-shrink-0 mt-0.5">
                      <div className="w-2 h-2 rounded-full bg-[var(--accent-primary)]" />
                    </div>
                    <span>Progress tracking with XP and levels</span>
                  </li>
                  <li className="flex items-start gap-4">
                    <div className="w-5 h-5 rounded-full bg-[var(--accent-primary)]/10 flex items-center justify-center flex-shrink-0 mt-0.5">
                      <div className="w-2 h-2 rounded-full bg-[var(--accent-primary)]" />
                    </div>
                    <span>10 themes and secure cloud sync</span>
                  </li>
                </ul>
                <div className="flex flex-col sm:flex-row gap-4">
                  <Link
                    href="/focusflow"
                    className="btn btn-primary inline-block text-center"
                  >
                    Learn more about FocusFlow
                  </Link>
                  <a
                    href="https://apps.apple.com/app/focusflow-be-present/id6739000000"
                    target="_blank"
                    rel="noopener noreferrer"
                    className="btn btn-secondary inline-block text-center"
                  >
                    Download on App Store
                  </a>
                </div>
              </div>
              
              <div className="grid grid-cols-2 gap-6">
                {[
                  { 
                    title: 'Focus Timer', 
                    desc: 'Timed sessions',
                    icon: (
                      <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M12 6v6h4.5m4.5 0a9 9 0 11-18 0 9 9 0 0118 0z" />
                      </svg>
                    )
                  },
                  { 
                    title: 'Tasks', 
                    desc: 'Smart management',
                    icon: (
                      <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                      </svg>
                    )
                  },
                  { 
                    title: 'Progress', 
                    desc: 'Track growth',
                    icon: (
                      <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6" />
                      </svg>
                    )
                  },
                  { 
                    title: 'Themes', 
                    desc: '10 beautiful themes',
                    icon: (
                      <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M7 21a4 4 0 01-4-4V5a2 2 0 012-2h4a2 2 0 012 2v12a4 4 0 01-4 4zm0 0h12a2 2 0 002-2v-4a2 2 0 00-2-2h-2.343M11 7.343l1.657-1.657a2 2 0 012.828 0l2.829 2.829a2 2 0 010 2.828l-8.486 8.485M7 17h.01" />
                      </svg>
                    )
                  },
                ].map((item, i) => (
                  <div key={i} className="card p-8 text-center hover:scale-105 transition-all duration-300">
                    <div className="text-[var(--accent-primary)] mb-4 flex justify-center">
                      {item.icon}
                    </div>
                    <div className="text-base font-semibold mb-2">{item.title}</div>
                    <div className="text-sm text-[var(--muted)]">{item.desc}</div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </Container>
      </section>

      {/* What We Do */}
      <section className="py-24">
        <Container>
          <div className="max-w-6xl mx-auto">
            <div className="text-center mb-16">
              <h2 className="text-4xl md:text-5xl font-semibold tracking-tight mb-4">
                What we do
              </h2>
              <p className="text-lg text-[var(--muted)] max-w-3xl mx-auto">
                We craft software that solves real problems with elegant solutions.
              </p>
            </div>

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
                },
                {
                  title: 'Build for clarity',
                  desc: 'Complex problems deserve simple solutions. We strip away the unnecessary to reveal what matters most.',
                  icon: (
                    <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z" />
                    </svg>
                  ),
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
                },
              ].map((item, i) => (
                <div key={i} className="card p-8">
                  <div className="text-[var(--accent-primary)] mb-6">
                    {item.icon}
                  </div>
                  <h3 className="text-xl font-semibold mb-4">{item.title}</h3>
                  <p className="text-sm text-[var(--muted)] leading-relaxed">{item.desc}</p>
                </div>
              ))}
            </div>
          </div>
        </Container>
      </section>

      {/* Our Approach, Why We Build, and CTA - Combined Section */}
      <section className="py-24 bg-[var(--soft)]">
        <Container>
          {/* Our Approach */}
          <div className="max-w-5xl mx-auto mb-24">
            <div className="text-center mb-16">
              <h2 className="text-4xl md:text-5xl font-semibold tracking-tight mb-4">
                Our approach
              </h2>
              <p className="text-lg text-[var(--muted)] max-w-2xl mx-auto">
                How we build products that people love to use.
              </p>
            </div>

            <div className="space-y-8">
              {[
                {
                  title: 'User-centric from day one',
                  desc: 'We start by understanding real problems. Not assumptions, not trends—actual needs that people face every day. Then we design solutions that feel inevitable.',
                  icon: (
                    <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
                    </svg>
                  ),
                },
                {
                  title: 'Privacy and trust by default',
                  desc: 'Your data is yours. We build with privacy-first principles, offering transparency and control. No tracking, no ads, no selling your information.',
                  icon: (
                    <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
                    </svg>
                  ),
                },
                {
                  title: 'Quality over quantity',
                  desc: 'We\'d rather build one exceptional product than ten mediocre ones. Every release is polished, tested, and ready for real-world use.',
                  icon: (
                    <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                    </svg>
                  ),
                },
                {
                  title: 'Continuous improvement',
                  desc: 'Great products evolve. We listen, learn, and iterate. Your feedback shapes what we build next.',
                  icon: (
                    <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M13 10V3L4 14h7v7l9-11h-7z" />
                    </svg>
                  ),
                },
              ].map((item, i) => (
                <div key={i} className="flex gap-6 items-start">
                  <div className="flex-shrink-0 w-12 h-12 rounded-xl bg-[var(--accent-primary)] flex items-center justify-center text-white">
                    {item.icon}
                  </div>
                  <div className="flex-1 pt-1">
                    <h3 className="text-xl font-semibold mb-3">{item.title}</h3>
                    <p className="text-sm text-[var(--muted)] leading-relaxed">{item.desc}</p>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Why We Build */}
          <div className="max-w-4xl mx-auto mb-24">
            <div className="text-center mb-12">
              <h2 className="text-4xl md:text-5xl font-semibold tracking-tight mb-6">
                Why we build
              </h2>
              <p className="text-lg text-[var(--muted)] leading-relaxed max-w-2xl mx-auto">
                Technology should serve humanity, not distract from it. We believe in building tools that help people do their best work—calmly, consistently, and with intention.
              </p>
            </div>

            <div className="card p-12 text-center">
              <div className="text-5xl mb-6">✨</div>
              <p className="text-xl text-[var(--muted)] leading-relaxed max-w-2xl mx-auto">
                "We're not just building software. We're crafting experiences that help people reclaim their time, focus their energy, and achieve what matters most."
              </p>
            </div>
          </div>

          {/* CTA Section */}
          <div className="max-w-4xl mx-auto text-center">
            <h2 className="text-4xl md:text-5xl font-semibold tracking-tight mb-6">
              Let's build something together
            </h2>
            <p className="text-lg text-[var(--muted)] mb-10 max-w-2xl mx-auto">
              Explore our products, learn about our approach, or get in touch.
            </p>
            <div className="flex flex-col sm:flex-row gap-4 justify-center">
              <Link
                href="/focusflow"
                className="btn btn-primary inline-block text-center"
              >
                See our products
              </Link>
              <Link
                href="/about"
                className="btn btn-secondary inline-block text-center"
              >
                Learn about us
              </Link>
              <Link
                href="/support"
                className="btn btn-secondary inline-block text-center"
              >
                Get in touch
              </Link>
            </div>
          </div>
        </Container>
      </section>
    </div>
  );
}
