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

## Site conventions

- `app/_components/` holds the shared pieces — the underscore means *not a route*, so never move it to `app/components/`. Pages import components relatively and `lib/` through the `@/*` alias.
- **Colour is a closed vocabulary.** The custom properties in `app/globals.css` (`--ground`, `--shelf`, `--shoal`, `--bone`, `--silt`, `--lantern`, `--on-lantern`, `--hairline`) reach Tailwind through `@theme inline`: `bg-lantern`, `text-silt`, `border-hairline`, `ease-tide`. Don't introduce a hex colour in a component; the only raw hex values on the site are the app-palette swatches in `app/page.tsx` and the `themeColor` viewport entries. The fix for a flat page is spacing, depth and motion, never a new hue.
- Fonts are wired once in `app/layout.tsx` (`--font-space-grotesk`, `--font-manrope`); `font-display` for display and figures, `font-sans` for reading size, mirroring the app's typography. Don't import a font anywhere else.
- Motion is centralised in `globals.css` as `.rise`, `.surface` and `.reveal`, staggered by an inline `style={{ "--i": n }}` index, and disabled under `prefers-reduced-motion`. Reuse those classes instead of adding keyframes.
- Icons come from `@phosphor-icons/react`: server components import from `@phosphor-icons/react/ssr` (see `app/_components/download-button.tsx:1`), client components from the package root.
- Components are server components by default. `"use client"` only where interaction demands it — `app/thanks/start-download.tsx` is the current only case.
- The brand word in prose is wrapped in `translate="no"` so it is read as the verb; keep it on user-facing "Tide".
- Doc comments in this repo explain *why* a non-obvious choice was made, not what the line does. Match that when editing around them, and keep the doc comment above the export it describes.
