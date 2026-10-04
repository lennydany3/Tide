<!-- BEGIN:nextjs-agent-rules -->

# This is NOT the Next.js you know

This version has breaking changes — APIs, conventions, and file structure may all differ from your training data. Read the relevant guide in `node_modules/next/dist/docs/` (resolved from this file's directory; in monorepos the `next` package may not be visible from the repo root) before writing any code. Heed deprecation notices.

This block is written and re-added by `next dev` — verify at `node_modules/next/dist/server/lib/generate-agent-files.js`. Removing it from a diff only re-creates the uncommitted change; committing it with your work keeps the tree clean.

<!-- END:nextjs-agent-rules -->

# Tide

## Two projects in one repo

- **The repo root is the website**: Next.js 16.3 (App Router) + React 19 + Tailwind v4. Routes: `/` (`app/page.tsx`), `/changelog`, `/thanks`, `/version.json` (route handler), `/api/revalidate`.
- **`product/` is the Flutter Android app** — the actual product. It has its own toolchain and a dense, verified guide: **read `product/CLAUDE.md` before changing anything under `product/`** (architecture, design-system rules, Supabase schema, testing conventions). Don't restate it here; link to it.
- Root `CLAUDE.md` is just `@AGENTS.md`.
- `product/**` is deliberately outside the website toolchain — excluded from `tsconfig.json`, from the eslint flat config, and from `.vercelignore`. Never "fix" Dart by adding it to eslint, and never run npm scripts from inside `product/`.

## Commands

Website (repo root):

```bash
npm run dev        # http://localhost:3000
npm run build      # also the typecheck
npm run lint       # bare `eslint`, flat config, whole repo minus product/
npm run release:patch   # also :minor / :major / :check
```

There is **no test script and no typecheck script**. `npm run build` is the typecheck; CI runs exactly `lint` then `build`, so run both before opening a PR.

App (in `product/`): `flutter pub get`, `flutter analyze`, `flutter test`. The website's `public/screens/*.png` are rendered from the real app by `flutter test tool/site_screenshots_test.dart` — re-render them there, never hand-edit the images.

## The site's version number is not in the repo

- `getRelease()` (`lib/release.ts`) fetches `version.json` from the latest GitHub Release (override the URL with `TIDE_MANIFEST_URL`) and falls back to the committed `lib/release-fallback.json` when GitHub is unreachable or no release exists yet.
- `lib/release-fallback.json` is an **offline copy written by the release workflow**. The only thing that should ever rewrite it is `node scripts/release.mjs manifest`. Don't hand-edit a version into a page, a component or the fallback.
- Version-bearing pages export `revalidate = 300`. The release workflow then calls `POST /api/revalidate` (Bearer `REVALIDATE_SECRET` on the host; `SITE_REVALIDATE_SECRET` + `SITE_URL` in GitHub) to refresh the page immediately, and the handler answers `409` while `latest/download` still lags.
- `hasApk()` is what hides download links before the first real APK — keep using it rather than rendering a dead download.

## `/changelog` is generated at build time

`lib/changelog.ts` does `readFileSync(join(process.cwd(), "CHANGELOG.md"))` and understands **only** the shape `scripts/release.mjs` writes: `## [X.Y.Z] - YYYY-MM-DD` headings, `### Group` subheadings, `- item` bullets. It skips `[Unreleased]` and silently drops anything else. So a changelog edit needs a rebuild to appear, and stray formatting inside a section is ignored rather than half-rendered.

The same file is the GitHub Release body and the in-app update notes — write entries for people using the app, and collect them under `## [Unreleased]` as you work.

## Releasing is driven from `product/pubspec.yaml`

- A release fires when `version: X.Y.Z+N` in `product/pubspec.yaml` changes and that reaches `main` with CI green. The build number `N` must always go up. Everything else (tag, APK name, site version, update manifest) is derived by `scripts/release.mjs`.
- CI's release-notes job runs `node scripts/release.mjs check` and **fails** if the current version has no dated `CHANGELOG.md` section, has no entries, or still contains the `- Describe what changed.` placeholder. Run `npm run release:check` before pushing.
- `TRIGGER.md` is the authoritative release runbook (secrets, one-time setup, recovery). Read it rather than reconstructing the process.

## Next 16 specifics this repo depends on

- Turbopack is the default for both `dev` and `build`, and `next.config.ts` is deliberately empty — adding a `webpack` config **fails the build**. Prefer the flag/config documented in the bundled docs.
- `next lint` was removed; `npm run lint` calls eslint directly.
- Route props come from generated globals: `LayoutProps<"/">` (`app/layout.tsx:36`), `PageProps<"/changelog">` — don't hand-write `{ params }` types. Those types are emitted into `.next/types/` and `.next/dev/types/`, so on a fresh clone they only exist after a `next dev` or `next build` has run.
- `revalidateTag(tag, profile)` takes a second argument in 16; the one-arg form is deprecated. A route handler (outside a Server Action) uses the `{ expire: 0 }` form — see `app/api/revalidate/route.ts:48`.
- `next dev` and `next build` can run concurrently, and a second `next dev` prints the running server's URL and PID (`.next/dev/lock`) instead of fighting over the port.

## The site is dark-only, square, and industrial — on purpose

These are load-bearing. They are not a theme to be extended, and an agent that "improves" them is making the site worse.

- **No rounded corners anywhere.** `globals.css` pins `--radius-*` to `0` and there is a global `border-radius: 0 !important` backstop. Do not reintroduce `rounded-*`. If something *needs* to be rounded, that is a signal the component belongs in `product/`'s design system, not the site.
- **Dark only.** There is no light theme and no theme toggle. One theme done properly beats two done adequately.
- **Colour is a closed vocabulary.** The custom properties in `app/globals.css` (`--ground`, `--shelf`, `--shoal`, `--bone`, `--silt`, `--lantern`, `--on-lantern`, `--hairline`, `--rule`) reach Tailwind through `@theme inline`: `bg-lantern`, `text-silt`, `border-hairline`. Don't introduce a hex colour in a component. The only raw hex values on the site are the app-palette swatches in `app/page.tsx` and the `themeColor` viewport entries. The fix for a flat page is spacing, depth and motion — never a new hue.
- **Lines do the structural work, not shadows.** Sections are separated by 1px `--hairline` and nested in `.compartment`. Reach for `border-hairline` before you reach for a `shadow-*`.
- `globals.css` documents `.compartment`'s cascade conflict with Tailwind v4's own `.border` implementation. Read that comment before adding another one; the fix is `!border-0`, and that is ugly enough to mean you probably want a plain nested `<div>` instead.
- Typography: `--font-space-grotesk` (display), `--font-manrope` (reading), `--font-jetbrains-mono` (telemetry and figures), wired once in `app/layout.tsx`. Note the `@theme` block deliberately maps onto `--font-display` / `--font-sans` / `--font-mono` rather than Tailwind's own `--font-*` names, because reusing those would overwrite the `next/font` variables. Don't import a font anywhere else.
  - `.macro` / `.macro-md` are the clamped uppercase display sizes; `.telemetry` is the small uppercase mono label register; `.figure` is a tabular-nums mono figure. Use these classes instead of hand-rolling type scales.
- Motion splits by what needs it. Entrances and scroll reveals stay in CSS as `.rise` (staggered by an inline `style={{ "--i": n }}`) and `.reveal` (`animation-timeline: view()`, no JS). Motion (motion.dev) owns only the boot sequence and the product demo. `.beacon` is the single looping animation, because "connected" is a fact that changes over time. Everything is off under `prefers-reduced-motion`.
- Icons come from `@phosphor-icons/react`: server components import from `@phosphor-icons/react/ssr` (see `app/_components/download-button.tsx:1`), client components from the package root.
- Components are server components by default. `"use client"` only where interaction demands it — `app/thanks/start-download.tsx`, `app/_components/boot-sequence.tsx` and `app/_components/product-demo.tsx` are the current only cases, and the count is a budget.
- The brand word in prose is wrapped in `translate="no"` so it is read as the verb; keep it on user-facing "Tide".
- The brand word is also a verb here, not a product noun: `Tide` carries the action, so it is set in the display face, uppercase and macro-sized in hero positions. Keep hero copy under three lines — the lower `clamp()` bound is chosen so a headline never wraps past that at 360px.
- Doc comments in this repo explain *why* a non-obvious choice was made, not what the line does. Match that when editing around them, and keep the doc comment above the export it describes.

## `public/screens/*.png` show the real app

The website's screenshots are rendered from `product/` by `flutter test tool/site_screenshots_test.dart`. If the app's look changes, re-render them there — never hand-edit or crop an image in place, and never swap in a stock mockup. The images are 1170×2532 and are framed by `app/_components/phone.tsx`, which crops rather than scales so the notch and the app's own top padding line up.

## Legal copy has exactly one source

`lib/legal.json` is canonical and is consumed by both the website (`lib/legal.ts` → `app/_components/legal-page.tsx`) and the app (`scripts/legal.mjs` → `product/lib/config/legal_copy.dart`).

- **Never hand-edit `legal_copy.dart`.** It is generated and CI's drift check will fail. Run `npm run legal:sync` after editing the JSON, and `npm run legal:check` to verify.
- The generator writes UTF-8 and Dart source is UTF-8, so typographic punctuation in the JSON (`’`, `—`, `“`) flows through to the app. The app's own copy already uses it, so don't strip it to keep the generator's output ASCII — a straight quote for a curly one is a downgrade, not a safety margin.
- Terms and Privacy must describe what the app *actually* does today. Before adding a clause about permissions, storage or deletion, confirm it against `product/` rather than copying boilerplate — a false privacy promise is worse than a missing one.
- `effectiveDate`, `entityName`, `entityAddress` and `contactEmail` in the JSON are still unset/blank and must be filled before the pages are published. The pages deliberately render without them rather than shipping a placeholder address.
- The app's legal screen is reached from Settings and sits behind the existing signed-in route guard, so it is not reachable pre-auth. That matches the current product, but it means there is no signed-out URL that serves the copy.
- The app's legal screen uses Tide's own rounded components (`SegmentedPill`, `StaggerColumn`, `TideBackdrop`) rather than copying the site's brutalist treatment — the two design systems are deliberately different, and a shared framework would have destroyed both.
