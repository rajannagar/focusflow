import { Metadata } from 'next';
import { SITE_URL, SITE_NAME } from '@/lib/constants';

const siteUrl = SITE_URL;

export const metadata: Metadata = {
  title: 'About Us - Our Mission & Values',
  description: 'Soft Computers is a small team dedicated to creating premium software that empowers people to do their best work, calmly and consistently, with intention. Learn about our mission, values, and approach.',
  keywords: [
    'Soft Computers',
    'about us',
    'software company',
    'productivity software',
    'privacy-first',
    'premium software',
    'focused work',
    'app developer',
  ],
  openGraph: {
    title: 'About Soft Computers - Our Mission & Values',
    description: 'We build premium software that helps people do meaningful work, calmly and consistently, with intention.',
    url: `${siteUrl}/about`,
    siteName: 'Soft Computers',
    images: [
      {
        url: '/focusflow_app_icon.png',
        width: 512,
        height: 512,
        alt: 'Soft Computers',
      },
    ],
    locale: 'en_US',
    type: 'website',
  },
  twitter: {
    card: 'summary',
    title: 'About Soft Computers - Our Mission & Values',
    description: 'We build premium software that helps people do meaningful work, calmly and consistently, with intention.',
  },
  alternates: {
    canonical: `${siteUrl}/about`,
  },
};

export default function AboutLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return children;
}

