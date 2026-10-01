import Link from "next/link";
import { Brand } from "./brand";
import { DownloadButton } from "./download-button";

const links = [
  { href: "/#instrument", label: "Product" },
  { href: "/#screens", label: "Screens" },
  { href: "/#plans", label: "Plans" },
  { href: "/changelog", label: "Changelog" },
];

/**
 * The site header: a single ruled bar, 64px, one line at every width from
 * `md` up.
 *
 * Solid `--ground` rather than translucent. The old header was a blur, which
 * is right for a page of floating cards and wrong for this one: a blurred
 * strip over a ruled grid makes the rules below it swim, and the rules are
 * what hold the page together. Nothing moves under the header here.
 */
export function SiteHeader() {
  return (
    <header className="sticky top-0 z-40 border-b border-hairline bg-ground">
      <div className="mx-auto flex h-16 max-w-7xl items-center justify-between gap-4 px-4 sm:px-6 lg:px-8">
        <Brand />
        <nav aria-label="Main">
          {/* One row at desktop. Below `md` the links are dropped entirely
              rather than collapsed behind a menu: there are four of them, the
              header has one job, and a disclosure that opens to four
              destinations is worse than a scroll away. */}
          <ul className="hidden items-center gap-1 md:flex">
            {links.map((link) => (
              <li key={link.href}>
                <Link
                  href={link.href}
                  className="telemetry block px-3 py-2 text-silt transition-colors duration-200 hover:text-bone focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-lantern"
                >
                  {link.label}
                </Link>
              </li>
            ))}
          </ul>
        </nav>
        <DownloadButton size="md" />
      </div>
    </header>
  );
}
