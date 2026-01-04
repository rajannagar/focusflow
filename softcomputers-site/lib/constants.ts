/**
 * Shared constants used across the website
 */

// Site configuration
export const SITE_URL = process.env.NEXT_PUBLIC_SITE_URL || 'https://www.softcomputers.ca';
export const SITE_NAME = 'Soft Computers';
export const SITE_DESCRIPTION = 'We build premium software that helps people do meaningful work, calmly and consistently, with intention.';

// Contact information
export const CONTACT_EMAIL = 'Info@softcomputers.ca';
export const COMPANY_LOCATION = 'Toronto, Ontario, Canada';

// App Store links
export const APP_STORE_URL = 'https://apps.apple.com/app/focusflow-be-present/id6739000000';

// FocusFlow product info
export const FOCUSFLOW = {
  name: 'FocusFlow',
  tagline: 'Be Present',
  description: 'The all-in-one focus timer, task manager, and progress tracker. Beautiful, private, and built for deep work.',
  features: {
    backgrounds: 14,
    themes: 10,
    levels: 50,
  },
} as const;

// Pricing (in respective currencies)
export const PRICING = {
  pro: {
    monthly: {
      USD: 3.99,
      CAD: 5.99,
    },
    yearly: {
      USD: 44.99,
      CAD: 59.99,
    },
  },
} as const;

// Social media (add as needed)
export const SOCIAL_LINKS = {
  twitter: '@softcomputers',
} as const;

