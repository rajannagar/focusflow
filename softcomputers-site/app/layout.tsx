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

export const metadata: Metadata = {
  title: "Soft Computers | Premium Software for Focused Work",
  description: "We build premium software that helps people do meaningful work—calmly, consistently, and with intention. Discover FocusFlow, our flagship focus timer app.",
  keywords: ["focus timer", "productivity", "task management", "iOS app", "focus app", "pomodoro"],
  authors: [{ name: "Soft Computers" }],
  openGraph: {
    title: "Soft Computers | Premium Software for Focused Work",
    description: "We build premium software that helps people do meaningful work—calmly, consistently, and with intention.",
    type: "website",
    locale: "en_US",
  },
  twitter: {
    card: "summary_large_image",
    title: "Soft Computers | Premium Software for Focused Work",
    description: "We build premium software that helps people do meaningful work.",
  },
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
