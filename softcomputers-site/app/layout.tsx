import type { Metadata } from "next";
import { Sora, Inter } from "next/font/google";
import "./globals.css";
import Header from "@/components/layout/Header";
import Footer from "@/components/layout/Footer";
import ScrollToTop from "@/components/ui/ScrollToTop";

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

// Base URL for the site
const siteUrl = process.env.NEXT_PUBLIC_SITE_URL || "https://www.softcomputers.ca";

export const metadata: Metadata = {
  metadataBase: new URL(siteUrl),
  title: {
    default: "Soft Computers | Premium Software for Focused Work",
    template: "%s | Soft Computers",
  },
  description: "We build premium software that helps people do meaningful work—calmly, consistently, and with intention. Discover FocusFlow, our flagship focus timer app for iOS.",
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
    description: "We build premium software that helps people do meaningful work—calmly, consistently, and with intention. Discover FocusFlow, our flagship focus timer app.",
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
    description: "We build premium software that helps people do meaningful work—calmly, consistently, and with intention.",
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
    icon: "/favicon.ico",
    apple: "/focusflow_app_icon.png",
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
  description: "We build premium software that helps people do meaningful work—calmly, consistently, and with intention.",
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
    <html lang="en" className="dark" style={{ backgroundColor: '#0A0A0B' }}>
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover" />
        <meta name="theme-color" content="#0A0A0B" />
        <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent" />
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
        className={`${sora.variable} ${inter.variable} antialiased min-h-screen flex flex-col bg-[#0A0A0B]`}
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
