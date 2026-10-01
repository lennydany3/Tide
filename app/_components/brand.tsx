import Image from "next/image";
import Link from "next/link";

/**
 * The app icon and the name, as one link home.
 *
 * Set as a two-cell compartment rather than as an icon beside a word: at this
 * size an avatar-plus-label reads as a social profile, and this is a product
 * mark. The square cell is the same 1px language as everything else on the
 * site, so the header is made of the same parts as the page under it.
 */
export function Brand() {
  return (
    <Link
      href="/"
      aria-label="Tide, home"
      className="compartment grid-cols-[auto_auto] focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-lantern"
    >
      <span className="flex size-9 items-center justify-center bg-shelf">
        <Image src="/tide-mark.png" alt="" width={22} height={22} className="size-[22px]" />
      </span>
      <span className="flex items-center gap-2 bg-shelf px-3">
        <span
          translate="no"
          className="font-display text-[0.95rem] font-bold tracking-[0.02em] uppercase"
        >
          Tide
        </span>
        <span className="telemetry text-silt">Android</span>
      </span>
    </Link>
  );
}
