import type { Metadata, Viewport } from "next";
import { JetBrains_Mono, Manrope, Space_Grotesk } from "next/font/google";
import { BootSequence } from "./_components/boot-sequence";
import "./globals.css";

/*
 * Three families, split hard by role — the app's own pairing
 * (product/lib/theme/tide_typography.dart) plus the numeric face the
 * instrumentation language needs:
 *
 * - Space Grotesk, heavy. Structural headlines, always uppercase.
 * - Manrope. Everything at reading size.
 * - JetBrains Mono. Everything measured, numbered or labelled as a field.
 *
 * Wired here and nowhere else. No component imports a font.
 */
const spaceGrotesk = Space_Grotesk({
  variable: "--font-space-grotesk",
  subsets: ["latin"],
  weight: ["500", "700"],
});

const manrope = Manrope({
  variable: "--font-manrope",
  subsets: ["latin"],
  weight: ["400", "500", "700"],
});

const jetbrainsMono = JetBrains_Mono({
  variable: "--font-jetbrains-mono",
  subsets: ["latin"],
  weight: ["400", "500"],
});

export const metadata: Metadata = {
  title: {
    default: "Tide — a habit tracker for Android",
    template: "%s | Tide",
  },
  description:
    "Log a habit with one swipe, hold a streak through a missed day, and read your week off a single screen. Free, offline-first, Android.",
  applicationName: "Tide",
  keywords: [
    "habit tracker",
    "streaks",
    "android",
    "offline first",
    "Tide",
  ],
  openGraph: {
    type: "website",
    siteName: "Tide",
    title: "Tide — a habit tracker for Android",
    description:
      "Log a habit with one swipe, hold a streak through a missed day, and read your week off a single screen.",
  },
  twitter: {
    card: "summary",
    title: "Tide — a habit tracker for Android",
    description:
      "Log a habit with one swipe, hold a streak through a missed day, and read your week off a single screen.",
  },
};

export const viewport: Viewport = {
  // One entry, not two. The site is dark on every page and at every width,
  // so a light-mode media query here would only ever describe a page nobody
  // can reach. See the "one substrate" rule in globals.css.
  themeColor: "#05080b",
  colorScheme: "dark",
};

export default function RootLayout({ children }: LayoutProps<"/">) {
  return (
    <html
      lang="en"
      className={`${spaceGrotesk.variable} ${manrope.variable} ${jetbrainsMono.variable} antialiased`}
    >
      <body className="min-h-dvh">
        <a
          href="#main"
          className="telemetry sr-only bg-lantern px-4 py-2 text-on-lantern focus-visible:not-sr-only focus-visible:fixed focus-visible:top-3 focus-visible:left-3 focus-visible:z-[70]"
        >
          Skip to Content
        </a>

        {children}

        {/* The boot sequence sits above the page rather than inside it, so it
            is not re-entered on client navigation. */}
        <BootSequence />

        {/* Texture. Two fixed, pointer-events-none layers over everything —
            scanlines under grain — so neither is ever composited by a
            scrolling container. See globals.css. */}
        <div aria-hidden className="scanlines" />
        <div aria-hidden className="grain" />
      </body>
    </html>
  );
}
