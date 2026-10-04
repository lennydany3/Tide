import { Check } from "@phosphor-icons/react/ssr";
import { ProductDemo } from "./_components/product-demo";
import { DownloadButton } from "./_components/download-button";
import { Phone } from "./_components/phone";
import { SiteFooter } from "./_components/site-footer";
import { SiteHeader } from "./_components/site-header";
import { formatDate, formatSize, getRelease } from "@/lib/release";

// Picks up a new GitHub Release without a redeploy (see lib/release.ts).
export const revalidate = 300;

/*
 * The app's five palettes, from product/lib/theme/tide_palette.dart.
 *
 * Hex values here are the one sanctioned exception to the site's palette
 * rules: these are the literal colours the app ships, and a swatch that
 * approximated them would be a lie about the product. They live in data, not
 * in a component's styling, and nothing else on the page may read a hex.
 */
const palettes = [
  {
    name: "Midnight",
    note: "Sky-blue light on near-black",
    ground: "#05080B",
    card: "#0C1217",
    ink: "#E8F1F6",
    accent: "#45D0FF",
  },
  {
    name: "Deep water",
    note: "Warm lantern light over dark water",
    ground: "#071216",
    card: "#0E1D22",
    ink: "#EDE6DA",
    accent: "#E9B466",
  },
  {
    name: "Ink",
    note: "Black and white, nothing else",
    ground: "#0A0A0B",
    card: "#141415",
    ink: "#F2F1EE",
    accent: "#F2F1EE",
  },
  {
    name: "Blossom",
    note: "Pink paper with rose accents",
    ground: "#F9EEF1",
    card: "#FFF9FB",
    ink: "#3A1E28",
    accent: "#C93A6C",
  },
  {
    name: "Paper",
    note: "White paper, black ink",
    ground: "#F4F3EF",
    card: "#FFFFFF",
    ink: "#161616",
    accent: "#161616",
  },
];

/*
 * What the app includes, as a spec rather than a price list.
 *
 * This section used to be two pricing cards, one of them advertising a Pro
 * plan at ₹499 a year. The app has no billing, no paywall and no feature
 * gating anywhere in it (product/CLAUDE.md, and product/test/
 * feature_access_test.dart exists specifically to keep it that way), so that
 * card was describing something nobody could buy. Everything below is in the
 * free build, so it is listed as what it is: the whole of it.
 */
const includes = [
  ["Habits", "Unlimited", "No cap on the list, ever"],
  ["History", "Unlimited", "Every day you log, kept"],
  ["Streak freezes", "Up to 7 per habit", "Spend one to hold a missed day"],
  ["Habit types", "Yes, No, Amount, Time", "Swipe, hold, or turn a dial"],
  ["To-dos", "Repeats, steps, reminders", "Daily, weekly, monthly, custom"],
  ["Tags, archive, notes", "Included", "Filter the way you actually think"],
  ["Screens", "Today, History, Insights", "Heatmaps and eight-week trends"],
  ["Milestones", "28 badges", "Every one has its own artwork"],
  ["Home screen widgets", "7 of them", "Log without opening the app"],
  ["Reminders", "Heads-up or full screen", "Works with the app closed"],
  ["Palettes", "All 5", "Per device, switch any time"],
  ["Accounts", "Sign in or stay local", "Your data syncs, never sold"],
];

const screens = [
  {
    screen: "today" as const,
    alt: "Tide's Today screen: two of four habits marked, a 23 day run, and the habit list.",
    caption: "Today — log in one swipe",
  },
  {
    screen: "history" as const,
    alt: "Tide's History screen: a month calendar shaded by how much was logged on each day.",
    caption: "History — the month at a glance",
  },
  {
    screen: "insights" as const,
    alt: "Tide's Insights screen: 75% of habits completed this week and an eight-week trend line.",
    caption: "Insights — the shape of the trend",
  },
];

export default async function Home() {
  const release = await getRelease();
  const size = formatSize(release.android.size);

  return (
    <>
      <SiteHeader />

      <main id="main" className="overflow-x-clip">
        {/* --- Hero ------------------------------------------------------
            One accent wash, behind the headline, and nothing else on the
            page gets one. */}
        <section className="relative border-b border-hairline">
          <div aria-hidden className="instrument-glow" />

          <div className="relative mx-auto max-w-7xl px-4 pt-16 pb-20 sm:px-6 md:pt-24 lg:px-8 lg:pt-28 lg:pb-32">
            <p className="section-marker rise" style={{ "--i": 0 } as React.CSSProperties}>
              Habit tracker — Android
            </p>

            {/* Uppercase, three words, and the only large type on the site. */}
            <h1
              className="macro rise mt-6 max-w-[14ch]"
              style={{ "--i": 1 } as React.CSSProperties}
            >
              Hold the day
              <br />
              you missed
            </h1>

            <div className="mt-10 grid gap-10 lg:grid-cols-12 lg:gap-8">
              <p
                className="rise max-w-[38ch] text-lg leading-relaxed text-silt lg:col-span-5"
                style={{ "--i": 2 } as React.CSSProperties}
              >
                <span translate="no">Tide</span> logs a habit in one swipe and
                spends a freeze when a day gets away from you, so a bad week
                does not cost you the whole run.
              </p>

              <div
                className="rise flex flex-col gap-6 lg:col-span-7"
                style={{ "--i": 3 } as React.CSSProperties}
              >
                <div className="flex flex-wrap items-center gap-3">
                  <DownloadButton />
                  <a
                    href="#demo"
                    className="group inline-flex h-14 items-center gap-3 border border-hairline px-6 font-display text-[0.9rem] font-bold tracking-[0.08em] uppercase transition-colors duration-200 ease-instrument hover:bg-shoal active:translate-y-px focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-lantern"
                  >
                    Try it below
                    <span
                      aria-hidden
                      className="transition-transform duration-200 ease-instrument group-hover:translate-y-0.5"
                    >
                      ↓
                    </span>
                  </a>
                </div>

                {/* The build on offer, as data. The visitor's most common
                    second question is "which build, and how big", and it
                    belongs next to the button rather than 1400px down. */}
                <dl className="compartment grid-cols-2 sm:grid-cols-4">
                  <Stat label="Build" value={release.version} />
                  <Stat label="Size" value={size ?? "—"} />
                  <Stat label="Released" value={formatDate(release.releasedAt)} />
                  <Stat label="Price" value="Free" tone="lantern" />
                </dl>
              </div>
            </div>
          </div>
        </section>

        {/* --- The demo ---------------------------------------------------
            Not a video and not a picture of the app. The same arithmetic,
            running in your browser, so the argument can be tested before
            anything is installed. */}
        <section id="demo" className="border-b border-hairline">
          <div className="mx-auto max-w-7xl px-4 py-20 sm:px-6 lg:px-8 lg:py-28">
            <div className="flex flex-col gap-6 md:flex-row md:items-end md:justify-between">
              <div>
                <p className="section-marker">Live, in this page</p>
                <h2 className="macro-md mt-5 max-w-[16ch]">
                  Try it before you install it
                </h2>
              </div>
              <p className="max-w-[34ch] text-sm leading-relaxed text-silt">
                Every figure below is computed from what you tap. Untick a
                habit and watch the run go — then hold it with a freeze and
                watch it survive.
              </p>
            </div>

            <ProductDemo />
          </div>
        </section>

        {/* --- What it does ------------------------------------------------
            One asymmetric compartment grid. The first cell is twice the
            others because logging is the thing everything else depends on. */}
        <section
          id="instrument"
          className="mx-auto max-w-7xl px-4 py-20 sm:px-6 lg:px-8 lg:py-28"
        >
          <p className="section-marker reveal">The mechanism</p>
          <h2 className="macro-md reveal mt-5 max-w-[18ch]">
            Three things, done properly
          </h2>

          <div className="mt-12 grid grid-cols-1 gap-px border border-hairline bg-hairline lg:grid-cols-12">
            <article className="reveal bg-shelf p-8 md:p-10 lg:col-span-6 lg:row-span-2">
              <p className="telemetry text-lantern">01</p>
              <h3 className="mt-5 font-display text-3xl leading-tight font-bold tracking-tight uppercase md:text-4xl">
                One swipe keeps the day
              </h3>
              <p className="mt-4 max-w-md leading-relaxed text-silt">
                A yes-or-no habit is one swipe anywhere on its card. Counts step
                up with a hold. Time goes on a dial set to the day&rsquo;s
                total, confirmed in a single tap rather than held out a minute
                at a time.
              </p>
              <div className="mt-8 flex flex-wrap gap-2">
                {["Binary", "Count", "Duration"].map((type) => (
                  <span
                    key={type}
                    className="telemetry border border-hairline px-2.5 py-1.5 text-silt"
                  >
                    {type}
                  </span>
                ))}
              </div>
            </article>

            <article className="reveal bg-shelf p-8 md:p-10 lg:col-span-6">
              <p className="telemetry text-lantern">02</p>
              <h3 className="mt-5 font-display text-2xl leading-tight font-bold tracking-tight uppercase md:text-3xl">
                A missed day is not a lost streak
              </h3>
              <p className="mt-4 leading-relaxed text-silt">
                Spend a freeze on a hard day and the run holds. Or pause a habit
                outright for a trip — paused days are rest days, and the streak
                waits for you without rewriting the days before it.
              </p>
            </article>

            <article className="reveal bg-shelf p-8 md:p-10 lg:col-span-6">
              <p className="telemetry text-lantern">03</p>
              <h3 className="mt-5 font-display text-2xl leading-tight font-bold tracking-tight uppercase md:text-3xl">
                It works with the app closed
              </h3>
              <p className="mt-4 leading-relaxed text-silt">
                Reminders are planned and held by the phone, so a heads-up or a
                full-screen call still arrives with no Dart running. Answer it
                from the lock screen and the streak is already updated when you
                open the app.
              </p>
            </article>
          </div>
        </section>

        {/* --- The real screens --------------------------------------------
            Rendered from the app by product/tool/site_screenshots_test.dart,
            so these are three screens the product genuinely has. */}
        <section
          id="screens"
          className="border-y border-hairline bg-shelf py-20 lg:py-28"
        >
          <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
            <p className="section-marker reveal">Three screens</p>
            <h2 className="macro-md reveal mt-5 max-w-[18ch]">
              Read your own week out of it
            </h2>
          </div>

          <ul className="mx-auto mt-12 flex max-w-7xl snap-x snap-mandatory scroll-px-4 gap-px overflow-x-auto overscroll-x-contain bg-hairline px-4 pb-px sm:scroll-px-6 sm:px-6 lg:grid lg:grid-cols-3 lg:px-8">
            {screens.map((item, i) => (
              <li
                key={item.screen}
                className="reveal w-[78vw] shrink-0 snap-start sm:w-[340px] lg:w-auto"
                style={{ "--i": i } as React.CSSProperties}
              >
                <Phone
                  screen={item.screen}
                  alt={item.alt}
                  caption={item.caption}
                  priority={i === 0}
                  sizes="(min-width: 1024px) 340px, 78vw"
                />
              </li>
            ))}
          </ul>
        </section>

        {/* --- Palettes ----------------------------------------------------
            A horizontal strip of the app's own five palettes. Every one of
            them is in the free build. */}
        <section className="mx-auto max-w-7xl px-4 py-20 sm:px-6 lg:px-8 lg:py-28">
          <div className="flex flex-col gap-6 md:flex-row md:items-end md:justify-between">
            <div>
              <p className="section-marker reveal">Five palettes</p>
              <h2 className="macro-md reveal mt-5 max-w-[16ch]">
                Pick the light you work in
              </h2>
            </div>
            <p className="max-w-[32ch] text-sm leading-relaxed text-silt">
              Stored per device and applied before the first frame, so the app
              never opens in the wrong light. Switching one is instant.
            </p>
          </div>

          <ul className="no-scrollbar mt-12 flex snap-x snap-mandatory gap-px overflow-x-auto overscroll-x-contain bg-hairline pb-px">
            {palettes.map((palette, i) => (
              <li
                key={palette.name}
                className="reveal w-[240px] shrink-0 snap-start lg:w-auto lg:flex-1"
                style={{ "--i": i } as React.CSSProperties}
              >
                <div className="flex h-full flex-col justify-between p-5">
                  <div
                    className="flex aspect-[3/4] flex-col justify-between p-4"
                    style={{ background: palette.ground, color: palette.ink }}
                  >
                    <div className="p-4" style={{ background: palette.card }}>
                      <div
                        className="h-2 w-16"
                        style={{ background: palette.accent }}
                      />
                      <div
                        className="mt-3 h-2 w-24 opacity-30"
                        style={{ background: palette.ink }}
                      />
                      <div
                        className="mt-2 h-2 w-12 opacity-30"
                        style={{ background: palette.ink }}
                      />
                    </div>
                    <p className="font-display text-xl font-bold tracking-tight uppercase">
                      {palette.name}
                    </p>
                  </div>
                  <p className="mt-3 text-sm leading-snug text-silt">
                    {palette.note}
                  </p>
                </div>
              </li>
            ))}
          </ul>
        </section>

        {/* --- Everything it includes --------------------------------------
            The section that used to be two pricing cards. The app charges
            nothing and gates nothing, so there is one list and it is the
            whole of it. */}
        <section
          id="plans"
          className="border-t border-hairline py-20 lg:py-28"
        >
          <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
            <div className="flex flex-col gap-6 md:flex-row md:items-end md:justify-between">
              <div>
                <p className="section-marker reveal">Included</p>
                <h2 className="macro-md reveal mt-5 max-w-[14ch]">
                  The whole of it, free
                </h2>
              </div>
              <p className="reveal max-w-[32ch] text-sm leading-relaxed text-silt">
                No billing, no paywall and no feature gating anywhere in the
                app. There is no second tier to upgrade to.
              </p>
            </div>

            <dl className="compartment reveal mt-12 grid-cols-1 md:grid-cols-[minmax(0,1fr)_minmax(0,1.2fr)_minmax(0,1.4fr)]">
              {includes.map(([feature, value, note]) => (
                <div
                  key={feature}
                  className="grid grid-cols-1 gap-1 bg-shelf px-4 py-4 md:grid-cols-none md:px-6"
                >
                  <dt className="telemetry text-silt">{feature}</dt>
                  <dd className="font-display text-base font-medium text-bone md:text-lg">
                    {value}
                  </dd>
                  <dd className="text-sm leading-snug text-silt">{note}</dd>
                </div>
              ))}
            </dl>
          </div>
        </section>

        {/* --- Download ---------------------------------------------------- */}
        <section className="mx-auto max-w-7xl px-4 pb-24 sm:px-6 lg:px-8 lg:pb-32">
          <div className="compartment grid-cols-1 lg:grid-cols-12">
            <div className="bg-shelf p-8 md:p-12 lg:col-span-8">
              <p className="section-marker">Install</p>
              <h2 className="macro-md mt-5 max-w-[14ch]">
                Start your first habit tonight
              </h2>
              <p className="mt-5 max-w-[46ch] leading-relaxed text-silt">
                <span className="figure text-bone">{release.version}</span> for
                Android, released {formatDate(release.releasedAt)}
                {size ? (
                  <>
                    {" "}
                    at <span className="figure text-bone">{size}</span>
                  </>
                ) : null}
                . New versions install from inside the app, and you can delete
                your account and everything in it from Settings.
              </p>
            </div>
            <div className="flex items-start bg-ground p-8 md:p-12 lg:col-span-4">
              <ul className="flex flex-col gap-3">
                {[
                  "Signed release build",
                  "Installable on Android",
                  "Works offline from the first launch",
                ].map((item) => (
                  <li key={item} className="flex gap-3 text-sm text-silt">
                    <Check
                      aria-hidden
                      weight="bold"
                      className="mt-0.5 size-4 shrink-0 text-lantern"
                    />
                    {item}
                  </li>
                ))}
              </ul>
              <DownloadButton className="mt-8 w-full" />
            </div>
          </div>
        </section>
      </main>

      <SiteFooter />
    </>
  );
}

/** One cell of the build strip. A figure in a labelled field. */
function Stat({
  label,
  value,
  tone = "bone",
}: {
  label: string;
  value: string;
  tone?: "bone" | "lantern";
}) {
  return (
    <div className="bg-shelf px-4 py-3">
      <dt className="telemetry text-silt">{label}</dt>
      <dd
        className={`figure mt-2 text-sm md:text-base ${
          tone === "lantern" ? "text-lantern" : "text-bone"
        }`}
      >
        <data value={value}>{value}</data>
      </dd>
    </div>
  );
}