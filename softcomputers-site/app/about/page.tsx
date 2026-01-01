'use client';

import Container from '@/components/ui/Container';
import Link from 'next/link';
import { useThrottledMouse } from '../hooks/useThrottledMouse';

export default function AboutPage() {
  const mousePosition = useThrottledMouse();

  return (
    <div className="min-h-screen bg-[var(--background)]">
      
      {/* ═══════════════════════════════════════════════════════════════
          HERO SECTION
          ═══════════════════════════════════════════════════════════════ */}
      <section className="relative pt-20 md:pt-40 pb-12 md:pb-24 overflow-hidden">
        {/* Animated background */}
        <div className="absolute inset-0">
          <div 
            className="absolute top-1/4 left-1/4 w-[300px] md:w-[500px] h-[300px] md:h-[500px] rounded-full blur-[60px] md:blur-[80px] opacity-20 transition-transform duration-1000 ease-out"
            style={{
              background: `radial-gradient(circle, rgba(139, 92, 246, 0.4) 0%, transparent 70%)`,
              transform: `translate(${mousePosition.x * 0.02}px, ${mousePosition.y * 0.02}px)`,
            }}
          />
        </div>
        <div className="absolute inset-0 bg-grid opacity-20" />

        <Container>
          <div className="max-w-4xl relative z-10 stagger-children">
            <div className="inline-flex items-center gap-2 badge badge-primary mb-6 md:mb-8">
              <span className="w-2 h-2 rounded-full bg-[var(--accent-primary)] animate-pulse" />
              Our Story
            </div>
            <h1 className="mb-6 md:mb-8">
              We build software that helps you <span className="text-gradient">focus</span>
            </h1>
            <p className="text-lg md:text-2xl text-[var(--foreground-muted)] leading-relaxed max-w-3xl">
              Soft Computers is a small team dedicated to creating premium software that empowers people to do their best work—calmly, consistently, and with intention.
            </p>
          </div>
        </Container>
      </section>

      {/* ═══════════════════════════════════════════════════════════════
          MISSION SECTION
          ═══════════════════════════════════════════════════════════════ */}
      <section className="section-padding bg-[var(--background-elevated)]">
        <Container>
          <div className="max-w-4xl mx-auto">
            <div className="text-center mb-10 md:mb-16">
              <h2 className="mb-4 md:mb-6">Our mission</h2>
              <p className="text-base md:text-xl text-[var(--foreground-muted)]">
                Technology should serve humanity, not distract from it.
              </p>
            </div>

            <div className="card-glass p-6 md:p-10 lg:p-12">
              <p className="text-base md:text-lg text-[var(--foreground-muted)] leading-relaxed mb-4 md:mb-6">
                At Soft Computers, we build software that helps people focus. Every product we create is designed with intention, built for clarity, and focused on what truly matters.
              </p>
              <p className="text-base md:text-lg text-[var(--foreground-muted)] leading-relaxed">
                We're not trying to be the biggest productivity company. We're trying to be the <span className="text-[var(--foreground)]">best</span>. That means focusing on quality over quantity, depth over breadth, and user experience over growth metrics.
              </p>
            </div>
          </div>
        </Container>
      </section>

      {/* ═══════════════════════════════════════════════════════════════
          OUR APPROACH
          ═══════════════════════════════════════════════════════════════ */}
      <section className="section-padding">
        <Container>
          <div className="max-w-5xl mx-auto">
            <div className="text-center mb-20">
              <h2 className="mb-6">Our approach</h2>
              <p className="text-xl text-[var(--foreground-muted)] max-w-2xl mx-auto">
                How we build products that people love to use.
              </p>
            </div>

            <div className="space-y-6">
              {[
                {
                  title: 'User-centric from day one',
                  desc: 'We start by understanding real problems. Not assumptions, not trends—actual needs that people face every day. Then we design solutions that feel inevitable.',
                  number: '01',
                  icon: (
                    <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
                    </svg>
                  ),
                },
                {
                  title: 'Privacy and trust by default',
                  desc: 'Your data is yours. We build with privacy-first principles, offering transparency and control. No tracking, no ads, no selling your information.',
                  number: '02',
                  icon: (
                    <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
                    </svg>
                  ),
                },
                {
                  title: 'Quality over quantity',
                  desc: 'We\'d rather build one exceptional product than ten mediocre ones. Every release is polished, tested, and ready for real-world use.',
                  number: '03',
                  icon: (
                    <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                    </svg>
                  ),
                },
                {
                  title: 'Continuous improvement',
                  desc: 'Great products evolve. We listen, learn, and iterate. Your feedback shapes what we build next.',
                  number: '04',
                  icon: (
                    <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M13 10V3L4 14h7v7l9-11h-7z" />
                    </svg>
                  ),
                },
              ].map((item, i) => (
                <div key={i} className="group flex gap-8 items-start p-6 rounded-2xl hover:bg-[var(--background-subtle)] transition-all duration-300 cursor-default">
                  <div className="flex-shrink-0 w-14 h-14 rounded-xl bg-gradient-to-br from-[var(--accent-primary)] to-[var(--accent-primary-dark)] flex items-center justify-center text-white group-hover:scale-110 transition-transform duration-300">
                    {item.icon}
                  </div>
                  <div className="flex-1">
                    <h3 className="text-xl font-semibold text-[var(--foreground)] mb-2 group-hover:text-[var(--accent-primary-light)] transition-colors duration-300">
                      {item.title}
                    </h3>
                    <p className="text-[var(--foreground-muted)] leading-relaxed">{item.desc}</p>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </Container>
      </section>

      {/* ═══════════════════════════════════════════════════════════════
          OUR VALUES
          ═══════════════════════════════════════════════════════════════ */}
      <section className="section-padding bg-[var(--background-elevated)]">
        <Container>
          <div className="max-w-5xl mx-auto">
            <div className="text-center mb-16">
              <h2 className="mb-6">What we value</h2>
              <p className="text-xl text-[var(--foreground-muted)]">
                The principles that guide everything we do.
              </p>
            </div>

            <div className="grid md:grid-cols-2 gap-6">
              {[
                {
                  title: 'Premium Quality',
                  desc: 'Every detail matters. From typography to animations to user experience, we obsess over quality. We\'d rather ship late than ship something mediocre.',
                  icon: '✨',
                  gradient: 'from-violet-500/20 to-purple-500/20',
                },
                {
                  title: 'Privacy First',
                  desc: 'Your data belongs to you. We minimize collection, maximize transparency, and never sell your information. Guest Mode means you can use our apps without an account.',
                  icon: '🔒',
                  gradient: 'from-emerald-500/20 to-teal-500/20',
                },
                {
                  title: 'Focused Design',
                  desc: 'Less is more. We remove distractions, simplify interfaces, and focus on what actually helps you do better work. No feature bloat, no unnecessary complexity.',
                  icon: '🎯',
                  gradient: 'from-amber-500/20 to-orange-500/20',
                },
                {
                  title: 'User Experience First',
                  desc: 'We prioritize user experience over growth, revenue, or metrics. If a feature doesn\'t make the experience better, we don\'t build it.',
                  icon: '💜',
                  gradient: 'from-rose-500/20 to-pink-500/20',
                },
              ].map((value, i) => (
                <div key={i} className="card group p-8 hover:border-[var(--accent-primary)]/30">
                  <div className={`absolute inset-0 bg-gradient-to-br ${value.gradient} opacity-0 group-hover:opacity-100 transition-opacity duration-500 rounded-[var(--radius-lg)]`} />
                  <div className="relative z-10">
                    <div className="text-4xl mb-6 group-hover:scale-110 transition-transform duration-300">{value.icon}</div>
                    <h3 className="text-xl font-semibold text-[var(--foreground)] mb-3">{value.title}</h3>
                    <p className="text-[var(--foreground-muted)] leading-relaxed">{value.desc}</p>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </Container>
      </section>

      {/* ═══════════════════════════════════════════════════════════════
          WHAT'S NEXT
          ═══════════════════════════════════════════════════════════════ */}
      <section className="section-padding relative overflow-hidden">
        {/* Background effect */}
        <div className="absolute inset-0">
          <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[600px] h-[600px] rounded-full bg-gradient-to-r from-[var(--accent-primary)]/10 to-[var(--accent-secondary)]/10 blur-3xl" />
        </div>
        
        <Container>
          <div className="relative z-10 max-w-3xl mx-auto text-center">
            <h2 className="mb-8">What's next</h2>
            <p className="text-xl text-[var(--foreground-muted)] mb-12 leading-relaxed">
              FocusFlow is our first product, but it won't be our last. We're building a suite of premium software designed for people who value quality, privacy, and intentional design.
            </p>
            <div className="flex flex-col sm:flex-row gap-4 justify-center">
              <Link href="/focusflow" className="btn btn-accent btn-lg">
                Explore FocusFlow
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 8l4 4m0 0l-4 4m4-4H3" />
                </svg>
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
