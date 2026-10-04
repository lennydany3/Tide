import Link from "next/link";
import type { LegalDocument } from "@/lib/legal";
import { legalContact, legalEffectiveDate } from "@/lib/legal";

/**
 * Renders one legal document.
 *
 * Both /terms and /privacy call this rather than repeating the layout, because
 * two copies of a document frame is two copies to forget to update — and a
 * policy page that has drifted out of its own shell is the sort of thing that
 * gets noticed. One renderer, two documents.
 *
 * The measure is deliberately narrow. Long lines of body text are the single
 * most common defect on a legal page and the easiest to avoid: `prose` is not
 * enough on its own, so the reading column is capped at 68 characters and the
 * headings stay out of it.
 */
export function LegalPage({
  document,
  other,
}: {
  document: LegalDocument;
  /** The sibling document, linked at the foot of the page. */
  other: { href: string; title: string };
}) {
  return (
    <>
      {/* --- Masthead --------------------------------------------------- */}
      <section className="border-b border-hairline">
        <div className="mx-auto max-w-7xl px-4 py-16 sm:px-6 md:py-20 lg:px-8">
          <p className="section-marker rise" style={{ "--i": 0 } as React.CSSProperties}>
            Legal
          </p>
          <h1
            className="macro-md rise mt-6"
            style={{ "--i": 1 } as React.CSSProperties}
          >
            {document.title}
          </h1>
          <p
            className="rise mt-6 flex flex-wrap items-center gap-x-4 gap-y-2 text-sm text-silt"
            style={{ "--i": 2 } as React.CSSProperties}
          >
            <span>Applies from</span>
            <time dateTime={legalEffectiveDate} className="figure text-bone">
              {legalEffectiveDate}
            </time>
            <span aria-hidden className="h-px w-6 bg-rule" />
            <Link
              href={other.href}
              className="telemetry text-lantern underline-offset-4 hover:underline focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-lantern"
            >
              {other.title}
            </Link>
          </p>
        </div>
      </section>

      {/* --- The document ------------------------------------------------ */}
      <section className="mx-auto max-w-7xl px-4 py-16 sm:px-6 lg:px-8 lg:py-20">
        <div className="grid gap-12 lg:grid-cols-12">
          {/* A contents list, because these documents have numbered sections
              and a reader who wants section 9 should not have to scroll to
              find it. Sticky on desktop so it follows the read. */}
          <nav aria-label="Contents" className="lg:col-span-3">
            <ol className="compartment grid-cols-1 lg:sticky lg:top-24">
              {document.sections.map((section, i) => (
                <li key={section.heading} className="bg-shelf">
                  <a
                    href={`#s-${i}`}
                    className="telemetry flex gap-3 px-4 py-2.5 text-silt transition-colors hover:bg-shoal hover:text-bone focus-visible:outline-2 focus-visible:-outline-offset-2 focus-visible:outline-lantern"
                  >
                    <span className="figure shrink-0 text-rule">
                      {String(i + 1).padStart(2, "0")}
                    </span>
                    <span className="normal-case tracking-normal">
                      {section.heading.replace(/^\d+\.\s*/, "")}
                    </span>
                  </a>
                </li>
              ))}
            </ol>
          </nav>

          <div className="lg:col-span-8 lg:col-start-5">
            {document.sections.map((section, i) => (
              <section
                key={section.heading}
                id={`s-${i}`}
                className="reveal border-t border-hairline py-8 first:border-t-0 first:pt-0"
              >
                <h2 className="font-display text-xl font-bold tracking-tight uppercase">
                  {section.heading}
                </h2>
                <div className="mt-4 flex max-w-[68ch] flex-col gap-4">
                  {section.paragraphs.map((paragraph) => (
                    <p
                      key={paragraph.slice(0, 24)}
                      className="leading-relaxed break-words text-silt"
                    >
                      {paragraph}
                    </p>
                  ))}
                  {section.bullets.length > 0 ? (
                    <ul className="mt-1 flex flex-col gap-3">
                      {section.bullets.map((bullet) => (
                        <li
                          key={bullet.slice(0, 24)}
                          className="flex gap-3 leading-relaxed break-words text-silt"
                        >
                          <span
                            aria-hidden
                            className="mt-3 h-px w-3 shrink-0 bg-rule"
                          />
                          <span>{bullet}</span>
                        </li>
                      ))}
                    </ul>
                  ) : null}
                </div>
              </section>
            ))}

            {/* --- How to reach us ---------------------------------------- */}
            <section className="reveal mt-4 border border-hairline bg-shelf p-6">
              <h2 className="section-marker">Questions</h2>
              <p className="mt-4 max-w-[62ch] leading-relaxed text-silt">
                {legalContact.email ? (
                  <>
                    Write to{" "}
                    <a
                      href={`mailto:${legalContact.email}`}
                      className="text-lantern underline-offset-4 hover:underline"
                    >
                      {legalContact.email}
                    </a>
                    , or open an issue on the{" "}
                    <a
                      href={legalContact.issues}
                      className="text-lantern underline-offset-4 hover:underline"
                    >
                      tracker
                    </a>
                    .
                  </>
                ) : (
                  <>
                    Tide has no published support address yet. The project&rsquo;s
                    issue tracker is the monitored channel and is the fastest way
                    to reach the maintainer:{" "}
                    <a
                      href={legalContact.issues}
                      className="text-lantern underline-offset-4 hover:underline"
                    >
                      {legalContact.issues}
                    </a>
                  </>
                )}
              </p>
            </section>

            <Link
              href="/"
              className="telemetry mt-10 inline-block border border-hairline px-4 py-3 text-silt transition-colors hover:bg-shoal hover:text-bone focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-lantern"
            >
              ← Back to home
            </Link>
          </div>
        </div>
      </section>
    </>
  );
}