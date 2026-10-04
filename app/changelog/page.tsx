import type { Metadata } from "next";
import { DownloadButton } from "../_components/download-button";
import { SiteFooter } from "../_components/site-footer";
import { SiteHeader } from "../_components/site-header";
import { parseInline, readChangelog, type InlinePart } from "@/lib/changelog";
import { formatDate, getRelease } from "@/lib/release";

// Picks up a new GitHub Release without a redeploy (see lib/release.ts).
export const revalidate = 300;

export const metadata: Metadata = {
  title: "Changelog",
  description: "Every release of Tide for Android, newest first.",
};

function Inline({ parts }: { parts: InlinePart[] }) {
  return parts.map((part, i) => {
    switch (part.kind) {
      case "code":
        return (
          <code key={i} className="bg-shoal px-1.5 py-0.5 text-[0.9em]">
            {part.value}
          </code>
        );
      case "strong":
        return (
          <strong key={i} className="font-bold text-bone">
            {part.value}
          </strong>
        );
      case "link":
        return (
          <a
            key={i}
            href={part.href}
            className="text-lantern underline-offset-4 hover:underline"
          >
            {part.value}
          </a>
        );
      default:
        return <span key={i}>{part.value}</span>;
    }
  });
}

export default async function ChangelogPage() {
  const entries = readChangelog();
  const release = await getRelease();

  return (
    <>
      <SiteHeader />
      <main id="main" className="mx-auto max-w-7xl px-4 pb-24 sm:px-6 lg:px-8 lg:pb-32">
        {/* --- Masthead --------------------------------------------------- */}
        <section className="grid gap-8 border-b border-hairline py-16 md:grid-cols-12 md:items-end md:py-20">
          <div className="md:col-span-8">
            <p className="section-marker rise" style={{ "--i": 0 } as React.CSSProperties}>
              Log
            </p>
            <h1
              className="macro-md rise mt-6"
              style={{ "--i": 1 } as React.CSSProperties}
            >
              Changelog
            </h1>
            <p
              className="rise mt-6 max-w-[46ch] leading-relaxed text-silt"
              style={{ "--i": 2 } as React.CSSProperties}
            >
              Every release of <span translate="no">Tide</span> for Android, newest
              first. The latest is{" "}
              <span className="figure text-bone">{release.version}</span>.
            </p>
          </div>
          <div
            className="rise md:col-span-4 md:justify-self-end"
            style={{ "--i": 3 } as React.CSSProperties}
          >
            <DownloadButton />
          </div>
        </section>

        {/* --- Releases ---------------------------------------------------- */}
        {entries.length === 0 ? (
          <p className="telemetry py-16 text-silt">
            No releases yet — the first one will be listed here
          </p>
        ) : (
          <ol>
            {entries.map((entry) => (
              <li
                key={entry.version}
                id={`v${entry.version}`}
                className="reveal grid gap-6 border-b border-hairline py-14 md:grid-cols-12 md:gap-10"
              >
                {/* The version is a figure in a field, pinned while its
                    entries scroll past — so the build you are reading stays
                    on screen however long the list under it is. */}
                <div className="md:col-span-4">
                  <dl className="compartment grid-cols-2 md:sticky md:top-24 md:grid-cols-1">
                    <div className="bg-ground px-4 py-4">
                      <dt className="telemetry text-silt">Build</dt>
                      <dd className="figure mt-2 text-2xl text-bone">
                        <data value={entry.version}>{entry.version}</data>
                      </dd>
                    </div>
                    {entry.date ? (
                      <div className="bg-ground px-4 py-4">
                        <dt className="telemetry text-silt">Released</dt>
                        <dd className="telemetry mt-2 text-bone">
                          <time dateTime={entry.date}>{formatDate(entry.date)}</time>
                        </dd>
                      </div>
                    ) : null}
                  </dl>
                </div>

                <div className="md:col-span-8">
                  {entry.groups
                    .filter((group) => group.items.length > 0)
                    .map((group) => (
                      <section key={group.title} className="mb-8 last:mb-0">
                        <h3 className="section-marker">{group.title}</h3>
                        <ul className="mt-5 flex flex-col gap-3">
                          {group.items.map((item) => (
                            <li
                              key={item}
                              className="flex gap-3 text-[0.95rem] leading-relaxed break-words text-silt"
                            >
                              {/* A tick in the telemetry register, not a
                                  bullet — it is a machine-readable list of
                                  changes, and the page reads as one. */}
                              <span
                                aria-hidden
                                className="mt-2.5 h-px w-3 shrink-0 bg-rule"
                              />
                              <span>
                                <Inline parts={parseInline(item)} />
                              </span>
                            </li>
                          ))}
                        </ul>
                      </section>
                    ))}
                </div>
              </li>
            ))}
          </ol>
        )}
      </main>
      <SiteFooter />
    </>
  );
}