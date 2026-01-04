import type { Metadata } from "next";
import { Sora, Inter } from "next/font/google";
import "./globals.css";
import { Header, Footer, ScrollToTop } from "@/components";
import { SITE_URL, SITE_NAME, SITE_DESCRIPTION, CONTACT_EMAIL } from "@/lib/constants";

// Premium Display Font - Geometric, Modern
const sora = Sora({
  variable: "--font-clash",
  subsets: ["latin"],
  weight: ["400", "500", "600", "700"],
  display: "swap",
});

// Body Font - Clean, Readable
const inter = Inter({
  variable: "--font-cabinet",
  subsets: ["latin"],
  weight: ["400", "500", "600"],
  display: "swap",
});

// Use constants for site configuration
const siteUrl = SITE_URL;

export const metadata: Metadata = {
  metadataBase: new URL(siteUrl),
  title: {
    default: "Soft Computers | Premium Software for Focused Work",
    template: "%s | Soft Computers",
  },
  description: "We build premium software that helps people do meaningful work, calmly and consistently, with intention. Discover FocusFlow, our flagship focus timer app for iOS.",
  keywords: [
    "focus timer",
    "productivity app",
    "task management",
    "iOS app",
    "focus app",
    "pomodoro timer",
    "FocusFlow",
    "Soft Computers",
    "deep work",
    "habit tracker",
    "time management",
    "concentration app",
  ],
  authors: [{ name: "Soft Computers", url: siteUrl }],
  creator: "Soft Computers",
  publisher: "Soft Computers",
  formatDetection: {
    email: false,
    address: false,
    telephone: false,
  },
  openGraph: {
    title: "Soft Computers | Premium Software for Focused Work",
    description: "We build premium software that helps people do meaningful work, calmly and consistently, with intention. Discover FocusFlow, our flagship focus timer app.",
    url: siteUrl,
    siteName: "Soft Computers",
    images: [
      {
        url: "/focusflow_app_icon.png",
        width: 512,
        height: 512,
        alt: "FocusFlow - Be Present",
      },
    ],
    locale: "en_US",
    type: "website",
  },
  twitter: {
    card: "summary_large_image",
    title: "Soft Computers | Premium Software for Focused Work",
    description: "We build premium software that helps people do meaningful work, calmly and consistently, with intention.",
    images: ["/focusflow_app_icon.png"],
    creator: "@softcomputers",
  },
  robots: {
    index: true,
    follow: true,
    googleBot: {
      index: true,
      follow: true,
      "max-video-preview": -1,
      "max-image-preview": "large",
      "max-snippet": -1,
    },
  },
  icons: {
    icon: [
      { url: "/favicon-32.png", sizes: "32x32", type: "image/png" },
      { url: "/favicon-16.png", sizes: "16x16", type: "image/png" },
    ],
    apple: "/apple-touch-icon.png",
    shortcut: "/favicon-32.png",
  },
  manifest: "/manifest.json",
  category: "technology",
};

// JSON-LD Structured Data for Organization
const organizationSchema = {
  "@context": "https://schema.org",
  "@type": "Organization",
  name: "Soft Computers",
  url: siteUrl,
  logo: `${siteUrl}/focusflow_app_icon.png`,
  description: "We build premium software that helps people do meaningful work, calmly and consistently, with intention.",
  email: "Info@softcomputers.ca",
  sameAs: [],
};

// JSON-LD Structured Data for Software Application (FocusFlow)
const softwareSchema = {
  "@context": "https://schema.org",
  "@type": "SoftwareApplication",
  name: "FocusFlow - Be Present",
  applicationCategory: "ProductivityApplication",
  operatingSystem: "iOS",
  offers: {
    "@type": "Offer",
    price: "0",
    priceCurrency: "USD",
    description: "Free with optional Pro subscription",
  },
  aggregateRating: {
    "@type": "AggregateRating",
    ratingValue: "5",
    ratingCount: "1",
  },
  description: "The all-in-one focus timer, task manager, and progress tracker. Beautiful, private, and built for deep work.",
  screenshot: `${siteUrl}/images/screen-focus.png`,
  image: `${siteUrl}/focusflow_app_icon.png`,
  author: {
    "@type": "Organization",
    name: "Soft Computers",
  },
  downloadUrl: "https://apps.apple.com/app/focusflow-be-present/id6739000000",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" data-theme="dark">
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover" />
        <meta name="theme-color" content="#0A0A0B" />
        <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent" />
        {/* Prevent flash of unstyled content - set theme before React hydrates */}
        <script
          dangerouslySetInnerHTML={{
            __html: `
              (function() {
                const theme = localStorage.getItem('theme') || 'dark';
                document.documentElement.setAttribute('data-theme', theme);
                const metaThemeColor = document.querySelector('meta[name="theme-color"]');
                if (metaThemeColor) {
                  metaThemeColor.setAttribute('content', theme === 'dark' ? '#0A0A0B' : '#F5F0E8');
                }
              })();
            `,
          }}
        />
        {/* JSON-LD Structured Data */}
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{ __html: JSON.stringify(organizationSchema) }}
        />
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{ __html: JSON.stringify(softwareSchema) }}
        />
      </head>
      <body
        className={`${sora.variable} ${inter.variable} antialiased min-h-screen flex flex-col bg-[var(--background)]`}
      >
        <Header />
        <main 
          className="flex-1"
          style={{
            paddingTop: 'calc(env(safe-area-inset-top, 0px) + 4rem)',
          }}
        >{children}</main>
        <Footer />
        <ScrollToTop />
      </body>
    </html>
  );
}
