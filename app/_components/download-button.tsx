import { ArrowSquareOut } from "@phosphor-icons/react/ssr";
import Link from "next/link";

type Props = {
  variant?: "primary" | "quiet";
  size?: "md" | "lg";
  className?: string;
};

/**
 * The one "Download" action, used everywhere on the site.
 *
 * One label for one intent. This used to be "Download Now" on the site and
 * "Download the APK" in the thank-you page, which meant the same action had
 * two names depending on where you were standing — so it is "Download" in
 * both places now, and the APK, version and file size are metadata printed
 * beside the label rather than baked into it.
 *
 * It goes to the thank-you page, which starts the APK download and explains
 * the install. Never straight to the file: GitHub serves it as an
 * attachment, so a direct link leaves a blank tab behind and no explanation
 * of what to do next.
 */
export const DOWNLOAD_HREF = "/thanks?download";

export function DownloadButton({
  variant = "primary",
  size = "lg",
  className = "",
}: Props) {
  const base =
    "group inline-flex items-center justify-center gap-3 whitespace-nowrap font-display font-bold uppercase transition-colors duration-200 ease-instrument focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-lantern active:translate-y-px";

  const variants = {
    // A solid lantern fill is the only filled surface on the whole site, so
    // it reads as a control rather than as a section.
    primary: "bg-lantern text-on-lantern hover:bg-bone",
    quiet: "border border-hairline bg-shelf text-bone hover:bg-shoal",
  };

  const sizes = {
    md: "h-10 px-4 text-[0.8rem] tracking-[0.1em]",
    lg: "h-14 px-6 text-[0.9rem] tracking-[0.08em]",
  };

  return (
    <Link
      href={DOWNLOAD_HREF}
      prefetch={false}
      className={`${base} ${variants[variant]} ${sizes[size]} ${className}`}
    >
      Download
      <ArrowSquareOut
        aria-hidden="true"
        weight="bold"
        className="size-4 transition-transform duration-200 ease-instrument group-hover:-translate-y-0.5 group-hover:translate-x-0.5"
      />
    </Link>
  );
}
