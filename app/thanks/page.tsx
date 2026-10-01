import type { Metadata } from "next";
import Link from "next/link";
import { Phone } from "../_components/phone";
import { SiteFooter } from "../_components/site-footer";
import { SiteHeader } from "../_components/site-header";
import { formatDate, formatSize, getRelease, hasApk } from "@/lib/release";
import { StartDownload } from "./start-download";

// Picks up a new GitHub Release without a redeploy (see lib/release.ts).
export const revalidate = 300;

export const metadata: Metadata = {
  title: "Install",
  description: "Install Tide on your Android phone in three short steps.",
  // A page reached by pressing a button, not a page to be found by search.
  robots: { index: false },
};

/*
 * Numbered rather than titled-and-iconed. The three steps are a procedure and
 * they happen in order, so the order is the information — a row of three
 * equal icon tiles read as three options and had to be re-read.
 */
const steps = [
  {
    title: "Open the APK",
    body: "When the download finishes, tap it in your notifications or in your Downloads folder.",
  },
  {
    title: "Allow the install",
    body: "Android asks once whether your browser may install apps. Allow it, then go back.",
  },
  {
    title: "Open Tide",
    body: "Tap Install, then Open. Future versions arrive inside the app, so this is the only time you do this.",
  },
];

export default async function ThanksPage() {
  const release = await getRelease();
  const size = formatSize(release.android.size);

  return (
    <>
      <SiteHeader />
      <main id="main" className="overflow-x-clip">
        <section className="relative border-b border-hairline">
          <div aria-hidden className="instrument-glow" />

          <div className="relative mx-auto grid max-w-7xl gap-14 px-4 pt-16 pb-20 sm:px-6 md:pt-24 lg:grid-cols-12 lg:gap-10 lg:px-8 lg:pt-28 lg:pb-32">
            <div className="lg:col-span-7">
              <p className="section-marker rise" style={{ "--i": 0 } as React.CSSProperties}>
                Install
              </p>
              <h1
                className="macro-md reveal mt-6 max-w-[13ch]"
                style={{ "--i": 1 } as React.CSSProperties}
              >
                Thanks for downloading
              </h1>
              <p
                className="rise mt-6 max-w-[52ch] leading-relaxed text-silt"
                style={{ "--i": 2 } as React.CSSProperties}
              >
                <span translate="no">Tide</span>{" "}
                <span className="figure text-bone">{release.version}</span> for
                Android
                {size ? (
                  <>
                    {" "}
                    (<span className="figure text-bone">{size}</span>)
                  </>
                ) : null}
                , released {formatDate(release.releasedAt)}. Three steps, and your
                first habit is one swipe away.
              </p>

              <div className="rise" style={{ "--i": 3 } as React.CSSProperties}>
                {hasApk(release) ? (
                  <StartDownload url={release.android.url} size={size} />
                ) : (
                  <p className="telemetry border border-hairline bg-shelf px-4 py-4 text-silt" role="status">
                    No APK on this release yet — check back in a few minutes
                  </p>
                )}
              </div>

              <ol className="compartment mt-12 grid-cols-1 sm:grid-cols-3">
                {steps.map((step, i) => (
                  <li
                    key={step.title}
                    className="bg-shelf p-6"
                  >
                    <p className="telemetry flex items-center gap-2 text-lantern">
                      <span className="figure">0{i + 1}</span>
                      <span aria-hidden>/03</span>
                    </p>
                    <h2 className="mt-4 font-display text-base font-bold tracking-tight uppercase">
                      {step.title}
                    </h2>
                    <p className="mt-2 text-sm leading-relaxed text-silt">{step.body}</p>
                  </li>
                ))}
              </ol>

              <div
                className="rise mt-10 flex flex-wrap items-center gap-x-6 gap-y-3"
                style={{ "--i": 6 } as React.CSSProperties}
              >
                <Link
                  href="/"
                  className="telemetry border border-hairline bg-shelf px-4 py-3 text-silt transition-colors hover:bg-shoal hover:text-bone focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-lantern"
                >
                  ← Back to home
                </Link>
                <Link
                  href="/changelog"
                  className="telemetry text-lantern underline-offset-4 hover:underline focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-lantern"
                >
                  Read the changelog
                </Link>
              </div>
            </div>

            <div className="flex justify-center lg:col-span-5">
              <Phone
                screen="today"
                alt="Tide's Today screen, the first thing you see after signing in."
                priority
                caption="The first screen after sign-in"
                sizes="(min-width: 1024px) 320px, 78vw"
              />
            </div>
          </div>
        </section>
      </main>
      <SiteFooter />
    </>
  );
}