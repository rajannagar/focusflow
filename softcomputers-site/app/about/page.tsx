'use client';

import Container from '@/components/ui/Container';
import Link from 'next/link';
import { useEffect, useState } from 'react';

export default function AboutPage() {
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
              We build software that helps you focus
            </h1>
            <p className="text-2xl md:text-3xl text-[var(--muted)] leading-relaxed mb-12 max-w-4xl">
              Soft Computers is a small team dedicated to creating premium software that empowers people to do their best work—calmly, consistently, and with intention.
            </p>
          </div>
        </Container>
      </section>

      {/* Mission Section */}
      <section className="py-24 bg-[var(--soft)]">
        <Container>
          <div className="max-w-4xl mx-auto">
            <div className="text-center mb-16">
              <h2 className="text-4xl md:text-5xl font-semibold tracking-tight mb-6">
                Our mission
              </h2>
              <p className="text-lg text-[var(--muted)] leading-relaxed max-w-2xl mx-auto">
                We believe technology should serve humanity, not distract from it.
              </p>
            </div>

            <div className="card p-10">
              <p className="text-lg text-[var(--muted)] leading-relaxed mb-6">
                At Soft Computers, we build software that helps people focus. Every product we create is designed with intention, built for clarity, and focused on what truly matters.
              </p>
              <p className="text-lg text-[var(--muted)] leading-relaxed">
                We're not trying to be the biggest productivity company. We're trying to be the best. That means focusing on quality over quantity, depth over breadth, and user experience over growth metrics.
              </p>
            </div>
          </div>
        </Container>
      </section>

      {/* Our Approach */}
      <section className="py-24">
        <Container>
          <div className="max-w-5xl mx-auto">
            <div className="text-center mb-16">
              <h2 className="text-4xl md:text-5xl font-semibold tracking-tight mb-6">
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
        </Container>
      </section>

      {/* Our Values */}
      <section className="py-24 bg-[var(--soft)]">
        <Container>
          <div className="max-w-4xl mx-auto">
            <div className="text-center mb-16">
              <h2 className="text-4xl md:text-5xl font-semibold tracking-tight mb-4">What we value</h2>
              <p className="text-lg text-[var(--muted)]">
                The principles that guide everything we do.
              </p>
            </div>

            <div className="grid md:grid-cols-2 gap-6">
              {[
                {
                  title: 'Premium Quality',
                  desc: 'Every detail matters. From typography to animations to user experience, we obsess over quality. We\'d rather ship late than ship something mediocre.',
                  icon: (
                    <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                    </svg>
                  ),
                },
                {
                  title: 'Privacy First',
                  desc: 'Your data belongs to you. We minimize collection, maximize transparency, and never sell your information. Guest Mode means you can use our apps without an account.',
                  icon: (
                    <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
                    </svg>
                  ),
                },
                {
                  title: 'Focused Design',
                  desc: 'Less is more. We remove distractions, simplify interfaces, and focus on what actually helps you do better work. No feature bloat, no unnecessary complexity.',
                  icon: (
                    <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                    </svg>
                  ),
                },
                {
                  title: 'User Experience Over Everything',
                  desc: 'We prioritize user experience over growth, revenue, or metrics. If a feature doesn\'t make the experience better, we don\'t build it.',
                  icon: (
                    <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z" />
                    </svg>
                  ),
                },
              ].map((value, i) => (
                <div key={i} className="card p-8">
                  <div className="text-[var(--accent-primary)] mb-6">
                    {value.icon}
                  </div>
                  <h3 className="text-xl font-semibold mb-3">{value.title}</h3>
                  <p className="text-sm text-[var(--muted)] leading-relaxed">{value.desc}</p>
                </div>
              ))}
            </div>
          </div>
        </Container>
      </section>

      {/* What's Next */}
      <section className="py-24">
        <Container>
          <div className="max-w-4xl mx-auto text-center">
            <h2 className="text-4xl md:text-5xl font-semibold tracking-tight mb-8">What's next</h2>
            <p className="text-lg text-[var(--muted)] max-w-2xl mx-auto mb-12 leading-relaxed">
              FocusFlow is our first product, but it won't be our last. We're building a suite of premium software designed for people who value quality, privacy, and intentional design.
            </p>
            <div className="flex flex-col sm:flex-row gap-4 justify-center">
              <Link
                href="/focusflow"
                className="btn btn-primary inline-block text-center"
              >
                See our products
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
