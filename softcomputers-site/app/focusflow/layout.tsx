import { Metadata } from 'next';

const siteUrl = process.env.NEXT_PUBLIC_SITE_URL || 'https://www.softcomputers.ca';

export const metadata: Metadata = {
  title: 'FocusFlow - Focus Timer, Task Manager & Progress Tracker',
  description: 'FocusFlow is the all-in-one iOS app for focused work. Features a focus timer with 14 ambient backgrounds, smart task management, XP system with 50 levels, and beautiful themes. Privacy-first, no ads.',
  keywords: [
    'FocusFlow',
    'focus timer app',
    'iOS productivity app',
    'task manager',
    'pomodoro timer',
    'ambient sounds',
    'focus music',
    'habit tracker',
    'XP system',
    'progress tracking',
    'deep work app',
    'concentration app',
  ],
  openGraph: {
    title: 'FocusFlow - Focus Timer, Task Manager & Progress Tracker',
    description: 'The all-in-one iOS app for focused work. Timer, tasks, and progress tracking in one beautiful, privacy-first experience.',
    url: `${siteUrl}/focusflow`,
    siteName: 'Soft Computers',
    images: [
      {
        url: '/focusflow_app_icon.png',
        width: 512,
        height: 512,
        alt: 'FocusFlow App Icon',
      },
      {
        url: '/images/screen-focus.png',
        width: 390,
        height: 844,
        alt: 'FocusFlow Focus Timer Screen',
      },
    ],
    locale: 'en_US',
    type: 'website',
  },
  twitter: {
    card: 'summary_large_image',
    title: 'FocusFlow - Focus Timer, Task Manager & Progress Tracker',
    description: 'The all-in-one iOS app for focused work. Timer, tasks, and progress tracking in one beautiful experience.',
    images: ['/focusflow_app_icon.png'],
  },
  alternates: {
    canonical: `${siteUrl}/focusflow`,
  },
};

export default function FocusFlowLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return children;
}

