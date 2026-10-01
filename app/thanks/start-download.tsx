"use client";

import { ArrowUpRight, DownloadSimple } from "@phosphor-icons/react";
import { useEffect, useState } from "react";

type Props = {
  url: string;
  size: string | null;
};

/** Query flag the "Download" buttons add. See DownloadButton. */
export const DOWNLOAD_PARAM = "download";

/**
 * Starts the APK download when the page was reached from a "Download" button,
 * and offers the link otherwise.
 *
 * The flag is removed from the address before the download starts, so a
 * refresh, a back button or a shared link never downloads the file again.
 * GitHub serves the APK as an attachment, so navigating to it downloads the
 * file and leaves this page where it is.
 */
export function StartDownload({ url, size }: Props) {
  const [started, setStarted] = useState(false);

  useEffect(() => {
    const params = new URLSearchParams(window.location.search);
    if (!params.has(DOWNLOAD_PARAM)) return;

    params.delete(DOWNLOAD_PARAM);
    const query = params.toString();
    window.history.replaceState(
      window.history.state,
      "",
      `${window.location.pathname}${query ? `?${query}` : ""}${window.location.hash}`,
    );

    // A beat after the page appears, so the thank-you reads first and the
    // browser's download prompt does not land on a blank screen.
    const timer = window.setTimeout(() => {
      window.location.assign(url);
      setStarted(true);
    }, 600);
    return () => window.clearTimeout(timer);
  }, [url]);

  if (started) {
    return (
      <p className="telemetry mt-8 border border-hairline bg-shelf px-4 py-4 text-silt">
        <span className="text-bone">Download started.</span>{" "}
        <a
          href={url}
          className="inline-flex items-center gap-1 text-lantern underline-offset-4 hover:underline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-lantern"
        >
          Try again
          <ArrowUpRight aria-hidden="true" weight="bold" className="size-3.5" />
        </a>
      </p>
    );
  }

  return (
    <div aria-live="polite" className="mt-8">
      <a
        href={url}
        className="group inline-flex h-14 items-center gap-3 bg-lantern px-6 font-display text-[0.9rem] font-bold tracking-[0.08em] whitespace-nowrap text-on-lantern uppercase transition-colors duration-200 ease-instrument hover:bg-bone focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-lantern active:translate-y-px"
      >
        <DownloadSimple
          aria-hidden="true"
          weight="bold"
          className="size-4 transition-transform duration-200 ease-instrument group-hover:translate-y-0.5"
        />
        Download
        {size ? (
          <span className="telemetry opacity-70">{size}</span>
        ) : null}
      </a>
    </div>
  );
}