import Link from "next/link";
import { formatDate, formatSize, getRelease } from "@/lib/release";
import { Brand } from "./brand";
import { DOWNLOAD_HREF } from "./download-button";

/**
 * The colophon.
 *
 * A four-column link farm is the default and it is wrong here: three of the
 * four columns would repeat destinations already in the header. What belongs
 * at the foot of this site is the thing a header has no room for — the exact
 * build on offer, its size, and the two legal pages, which are the only
 * routes on the site that nothing else points at.
 */
export async function SiteFooter() {
  const release = await getRelease();
  const size = formatSize(release.android.size);
  const year = Number(formatDate(release.releasedAt).slice(-4));

  return (
    <footer className="border-t border-hairline">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div className="grid grid-cols-1 gap-px border-x border-hairline bg-hairline md:grid-cols-12">
          <div className="flex flex-col gap-4 bg-ground p-6 md:col-span-5">
            <Brand />
            <p className="max-w-xs text-sm leading-relaxed text-silt">
              <span translate="no">Tide</span> is a habit tracker for Android.
              Small, daily, repeating.
            </p>
          </div>

          {/* The build on offer, as data rather than as a sentence. This is
              the one number a visitor is most often here for and it was
              previously only on the download section, 1400px away. */}
          <dl className="compartment grid-cols-[auto_1fr] bg-hairline md:col-span-4">
            <dt className="telemetry bg-shelf px-3 py-3 text-silt">Build</dt>
            <dd className="telemetry bg-ground px-3 py-3 text-bone">
              <data value={release.version}>{release.version}</data>
            </dd>
            <dt className="telemetry bg-shelf px-3 py-3 text-silt">Released</dt>
            <dd className="telemetry bg-ground px-3 py-3 text-bone">
              <time dateTime={release.releasedAt}>{formatDate(release.releasedAt)}</time>
            </dd>
            <dt className="telemetry bg-shelf px-3 py-3 text-silt">Size</dt>
            <dd className="telemetry bg-ground px-3 py-3 text-bone">{size ?? "—"}</dd>
            <dt className="telemetry bg-shelf px-3 py-3 text-silt">Price</dt>
            <dd className="telemetry bg-ground px-3 py-3 text-bone">Free</dd>
          </dl>

          <nav aria-label="Footer" className="bg-ground p-6 md:col-span-3">
            <ul className="flex flex-col items-start gap-3">
              <li>
                <Link
                  href={DOWNLOAD_HREF}
                  className="telemetry text-bone underline-offset-4 transition-colors hover:text-lantern focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-lantern"
                >
                  Download
                </Link>
              </li>
              <li>
                <Link
                  href="/changelog"
                  className="telemetry text-silt underline-offset-4 transition-colors hover:text-bone focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-lantern"
                >
                  Changelog
                </Link>
              </li>
              <li>
                <Link
                  href="/terms"
                  className="telemetry text-silt underline-offset-4 transition-colors hover:text-bone focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-lantern"
                >
                  Terms
                </Link>
              </li>
              <li>
                <Link
                  href="/privacy"
                  className="telemetry text-silt underline-offset-4 transition-colors hover:text-bone focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-lantern"
                >
                  Privacy
                </Link>
              </li>
            </ul>
          </nav>
        </div>

        <p className="telemetry flex flex-wrap items-center gap-x-4 gap-y-1 border-x border-b border-hairline px-6 py-4 text-silt">
          <span translate="no">&copy; {year} Tide</span>
          <span aria-hidden className="h-px w-6 bg-rule" />
          <span>Android</span>
          <span aria-hidden className="h-px w-6 bg-rule" />
          <span>No account data sold, ever</span>
        </p>
      </div>
    </footer>
  );
}
