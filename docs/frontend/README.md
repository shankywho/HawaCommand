# HawaCommand Web Frontend: Documentation Index

<!-- nav:start -->

**Navigate:** [Project](../../README.md) · [Docs hub](../README.md) · [Overview](../SYSTEM_OVERVIEW.md) · [AWS architecture](../AWS_ARCHITECTURE.md) · [AWS setup](../AWS_SETUP_GUIDE.md) · [API](../backend/API.md) · [Environment](../ENVIRONMENT_VARIABLES.md) · [Contracts](../CONTRACTS.md)

**Web docs:** [Runbook](../../frontend/README.md) · **Index** · [Context](CONTEXT.md) · [Architecture](ARCHITECTURE.md) · [Pages](PAGES.md) · [Design system](DESIGN_SYSTEM.md) · [Quality](LINTING_AND_QUALITY.md) · [Structure](STRUCTURE.md) · [Plan](PLAN.md) · [Design export](../../frontend/design/EXPORT_NOTES.md)

<!-- nav:end -->

Purpose: the entry point for anyone working on `frontend/`, the Next.js app that holds the public landing page, the officer console and a mobile driver view. It says what is built, how to run and check it, how it talks to the backend, and what is known to be broken.

Related: [CONTEXT](CONTEXT.md) · [ARCHITECTURE](ARCHITECTURE.md) · [STRUCTURE](STRUCTURE.md) · [PAGES](PAGES.md) · [DESIGN_SYSTEM](DESIGN_SYSTEM.md) · [LINTING_AND_QUALITY](LINTING_AND_QUALITY.md) · [PLAN](PLAN.md) · [../SYSTEM_OVERVIEW.md](../SYSTEM_OVERVIEW.md) · [../backend/API.md](../backend/API.md) · [../../frontend/README.md](../../frontend/README.md)

---

## 1. Implementation status

Status vocabulary used in every frontend doc: **Implemented** (works end to end on API data), **Partial** (works, with the named gaps), **Stub/Mock** (renders fixtures or hard-coded data), **Planned** (not in code).

| Area | Route / location | Status | Notes |
|---|---|---|---|
| Landing page | `/` | Implemented | 12 sections ported from the design. Live numbers (worst hotspot, GRAP stage, plan saving, verified intervention) come from the same API as the console |
| Console shell | `(console)/layout.tsx` | Implemented | Header with ward picker, AQI chip and clock; labelled icon rail; Cmd/Ctrl+K palette; toast. Dark mode is a CSS invert filter (see §8) |
| Live map | `/map` | Partial | Hotspot list, detail and heat field come from `/v1/hotspots`. Truck routes, bus trails, schools and the suspect pin on the map are built-in demo data. Scrubbing into the past ("Observed replay") shows current values |
| Forecast | `/forecast` | Partial | GRAP banner, checklist, ward table and chart come from `/v1/forecast`. The "Thursday 06:00–10:00" subtitle and the "Review Plan #214" link are fixed |
| Plans index | `/plans` | Implemented | Redirects to the ward's plan or the first plan; otherwise offers "Draft plan now" |
| Plan review | `/plans/[id]` | Partial | Diff, Auditor comment, Apply suggestion, Approve & dispatch and Request changes call the API. Edit and Reply are disabled; Request changes sends a fixed note |
| What-If | `/what-if` | Partial | Per-asset table and delta from `/v1/plans/{id}/compare`. Both maps are a client-side approximation. The delta sign differs between backend and mocks (§8) |
| Impact | `/impact` | Implemented | Interventions, synthetic-control chart, effectiveness library, Markdown report download. The donor-cell map is illustrative |
| Fleet | `/fleet` | Partial | Assets and HawaTag state from `/v1/devices`, polled every 5 s. "Last packet" age and the spray timeline axis are fixed |
| Alerts | `/alerts` | Implemented | Read-only alert log, audience filter, WhatsApp/SMS preview. Compose is Planned |
| Driver view | `/route` | Partial | Stops from `/v1/driver/route`. "Start route" only changes local state; nothing is sent. No web manifest or service worker, so it is not an installable PWA |
| Sign-in | `/login`, `AuthGuard` | Partial | Cognito (aws-amplify) sign-in when both Cognito env vars are set; otherwise demo mode with no sign-in. The backend does not verify the token. No sign-out control |
| Mock API | `src/mocks/` | Stub/Mock | Default when `NEXT_PUBLIC_API_URL` is empty: every `/v1` call is answered in the browser from fixtures |
| API contracts | `src/contracts/` | Implemented | zod schemas validate every response. All 15 checks of `scripts/verify_backend_contracts.ts` passed against the current backend (§6) |
| Live updates | `src/lib/live.ts` | Partial | 5 s polling for hotspots (hour 0) and devices. WebSocket push is Planned |
| Map renderer | `src/lib/visuals/hawa-gl.js` | Partial | Vendored `<hawa-gl>` web component on MapLibre GL 4.7.1. deck.gl layers are Planned |
| Hindi | driver view, causes, alert preview | Partial | Hindi strings are hard-coded where the design has them. No i18n framework, no `/hi` routes (Planned) |
| Open data portal | `/open` | Planned | Only a footer link to the backend's `GET /open/v1/air` exists |
| Other blueprint pages | hotspots, GRAP, interventions, schools, reports, inspections, sites, devices, integrity, coverage, evidence, admin | Planned | See [PAGES §5](PAGES.md#5-planned-pages) |
| Typecheck | `pnpm typecheck` | Implemented | Passes (§6) |
| Production build | `pnpm build` | Implemented | Passes (§6) |
| Lint | `pnpm lint` | Planned | The script exists but ESLint is not installed or configured; it fails (§6) |
| Tests and CI | none | Planned | No unit, component or e2e tests; no CI workflow in the repository |
| Hosting | `frontend/amplify.yml` | Partial | Amplify build spec only. No deployment was verified and no infrastructure code creates the Amplify app |

## 2. What the web owns

| Surface | Routes | Audience | Rendering |
|---|---|---|---|
| Landing page | `/` | Judges, officials, public | Prerendered static HTML; live numbers load on the client |
| Officer console | `/map`, `/forecast`, `/plans`, `/plans/[id]`, `/what-if`, `/impact`, `/fleet`, `/alerts` | MCD and DPCC ward officers | Client components; data on the client via TanStack Query |
| Officer sign-in | `/login` | Officers | Client form (Cognito) |
| Driver view | `/route?asset=` | Sprinkler and smog-gun drivers | Client component in a phone-width layout |

The web renders backend and AI-ML results and lets the officer approve. It does not compute model outputs, with two visual exceptions documented in [ARCHITECTURE §5](ARCHITECTURE.md#5-client-side-derivations): the map at a future hour uses each cell's forecast P50, and the "plan" maps scale excess PM2.5 by the plan's exposure reduction.

The Flutter app in `app_frontend/` ([../app/README.md](../app/README.md)) covers citizen, driver, inspector and school experiences. The web `/route` page overlaps with the Flutter driver flow; both read the same backend.

## 3. Document index and reading order

| File | What it answers |
|---|---|
| [CONTEXT.md](CONTEXT.md) | Who uses the web, the officer flow as built, features F1–F22 with web status, demo-scene mapping, honesty and uncertainty rules, Hindi, non-goals |
| [ARCHITECTURE.md](ARCHITECTURE.md) | Stack and versions, rendering, data flow, API client and endpoints, mock mode, auth, state, map and visuals, errors, hosting, planned architecture |
| [STRUCTURE.md](STRUCTURE.md) | The complete `frontend/` tree, one line per file, dependency rules |
| [PAGES.md](PAGES.md) | Page by page: file, what it renders, hooks, endpoints, behaviour without a backend, status; planned pages |
| [DESIGN_SYSTEM.md](DESIGN_SYSTEM.md) | Tokens from `tailwind.config.ts` and `globals.css`, fonts, CPCB colour scale as coded, components, map and chart styling, motion, accessibility |
| [LINTING_AND_QUALITY.md](LINTING_AND_QUALITY.md) | What quality tooling exists (TypeScript, build, contract verifier) and what is Planned (ESLint, Prettier, hooks, tests, CI) |
| [PLAN.md](PLAN.md) | What was built against the original milestones, remaining work in priority order, demo checklist |

Reading order: new teammate: CONTEXT → ARCHITECTURE → PAGES → DESIGN_SYSTEM. AI coding agent: STRUCTURE → ARCHITECTURE §4 → the PAGES section for the task. Backend lead: ARCHITECTURE §4 (endpoint table) → §8 of this file.

## 4. Quick start

Prerequisites: Node.js 20 or newer (`engines`), pnpm through Corepack. `package.json` pins `packageManager: pnpm@11.17.0`. No backend is needed: with `NEXT_PUBLIC_API_URL` empty the app runs on in-browser mocks.

```bash
cd frontend
corepack enable
pnpm install --frozen-lockfile
cp .env.example .env.local   # optional: leave NEXT_PUBLIC_API_URL empty for mock mode
pnpm dev                     # Next.js dev server (Turbopack) on http://localhost:3000
```

Against the real backend (FastAPI on port 8000, which calls the AI-ML service on 8100 or falls back in-process):

```bash
echo "NEXT_PUBLIC_API_URL=http://localhost:8000" > .env.local
pnpm dev
```

Open `http://localhost:3000` for the landing page and `http://localhost:3000/map` for the console. `NEXT_PUBLIC_*` values are inlined at build time, so restart `pnpm dev` (or rebuild) after changing them.

| Command | What it does | Result on 2026-10-10 |
|---|---|---|
| `pnpm dev` | `next dev --turbopack -p 3000` | Not run (dev server) |
| `pnpm build` | `next build` (compiles and type-checks; no lint because ESLint is absent) | Pass |
| `pnpm start` | `next start -p 3000` (serves the build) | Pass: all 12 routes returned 200 |
| `pnpm typecheck` | `tsc --noEmit` | Pass, 0 errors |
| `pnpm lint` | `next lint` | **Fails**: no ESLint config or dependency; `next lint` prompts interactively and exits 1 |
| `pnpm dlx tsx scripts/verify_backend_contracts.ts` | Calls the backend and validates every response with zod (no `package.json` script) | Pass, 15 of 15, against a local backend on port 8099 |

## 5. Environment variables

All variables are read at build time (`NEXT_PUBLIC_*` are inlined into the client bundle).

| Variable | Read in | Default | Effect |
|---|---|---|---|
| `NEXT_PUBLIC_API_URL` | `src/lib/api.ts:10`, `src/lib/time.ts:7`, landing `Footer.tsx` | empty | Empty: mock mode (fixtures, demo clock fixed at Tue 10 Nov 2026 14:00 IST, the footer's open-data link is disabled). Set (for example `http://localhost:8000`): real backend, real clock |
| `NEXT_PUBLIC_COGNITO_USER_POOL_ID` | `src/lib/auth.ts:5` | empty | With the client id, turns on Cognito sign-in and the console guard |
| `NEXT_PUBLIC_COGNITO_CLIENT_ID` | `src/lib/auth.ts:6` | empty | See above. If either is empty the console opens without sign-in |
| `API_URL` | `scripts/verify_backend_contracts.ts:15` | `http://127.0.0.1:8099` | Backend origin for the contract verifier only |

## 6. Verification record

Run on 2026-10-10 in a scratch copy of `frontend/` (no `node_modules` in the repo), Node v24.21.0, pnpm 11.17.0 (selected by `packageManager`).

| Check | Command | Result |
|---|---|---|
| Install | `pnpm install --frozen-lockfile` | Pass. Resolved next 15.5.26, react 19.3.0, @tanstack/react-query 5.104.0, aws-amplify 6.22.0, maplibre-gl 4.7.1, zod 3.25.76, zustand 5.0.15, tailwindcss 3.4.19, typescript 5.9.3 |
| Typecheck | `pnpm exec tsc --noEmit` | Pass, exit 0 |
| Build | `pnpm build` | Pass, exit 0. 14 static pages; `/plans/[id]` is dynamic. First-load JS 103 kB shared; largest route `/map` 188 kB |
| Lint | `pnpm lint` | Fail, exit 1. Output: "`next lint` is deprecated" then "How would you like to configure ESLint?" |
| Smoke | `next start` then `curl` | `/`, `/login`, `/map`, `/forecast`, `/plans`, `/plans/214`, `/plans/999`, `/what-if`, `/impact`, `/fleet`, `/alerts`, `/route` all 200; unknown paths 404 |
| Contract | `pnpm dlx tsx@4.19.2 scripts/verify_backend_contracts.ts` against the backend started from `backend/src` on port 8099 (AI-ML in-process fallback) | Pass, 15 of 15 |
| Contract (plain Node) | `node scripts/verify_backend_contracts.ts` | Fail: `ERR_UNSUPPORTED_DIR_IMPORT` on `../src/contracts` |

## 7. Product rules and their status

| Rule | Status | Where |
|---|---|---|
| Nothing dispatches without officer approval | Implemented | Approve & dispatch is the only path to `POST /v1/plans/{id}/approve`; there is no auto-approve |
| Uncertainty is shown with model outputs | Partial | Forecast P10–P90 band, impact 95% CI, confidence words with the number on hover, plan likely range. Hotspot concentrations and the What-If delta have no interval |
| Simulated data is labelled | Partial | Landing "Simulated data / Live data", Proof note, fleet "Simulated" chip, What-If "Simulated." note, impact table footnote. No console-wide demo banner; demo map overlays are unlabelled |
| AQI and PM2.5 never mixed | Implemented | `AqiChip` always spells "AQI n" or "PM2.5 n"; contracts carry separate breakpoints |
| Colour is never the only signal | Partial | Chips carry the band word; causes carry icon and word. Map markers rely on colour plus value labels |
| English and Hindi | Partial | Hindi in the driver view, cause names, alert preview. No translation framework |

## 8. Known issues

| # | Issue | Where |
|---|---|---|
| 1 | `pnpm lint` cannot run: the script is `next lint`, but no ESLint package or config exists; Next prompts interactively and exits 1. `next lint` is also deprecated in Next 15.5 | `frontend/package.json:10` |
| 2 | The basemap style is hard-coded (OpenFreeMap positron/dark); there is no env variable for it. `NEXT_PUBLIC_MAP_STYLE` was removed from `.env.example` because nothing read it | `frontend/src/lib/visuals/hawa-gl.js:107` |
| 3 | The map makes third-party requests at runtime: MapLibre CSS from unpkg (inside the element's shadow DOM), basemap tiles from tiles.openfreemap.org, and road routes from the public OSRM demo server. The map degrades or breaks offline or behind a strict proxy | `frontend/src/lib/visuals/hawa-gl.js:5`, `:59`, `:99`, `:107` |
| 4 | What-If delta sign mismatch: the backend returns `deltaPct` as a positive gain (42.0) while the mock returns −31. The page prints `fmtPct(deltaPct)` followed by "less exposure", so against the backend it reads "+42% less exposure" | `frontend/src/app/(console)/what-if/page.tsx:57-58`, `frontend/src/mocks/fixtures.ts:147`, `backend/src/hawa_backend/core/intel_client.py:936`, `:977`, `:1006` |
| 5 | "People reached" on `/alerts` parses `"<n> delivered"` from `delivered`; the mock strings ("3 of 3 read", "4,106") never match, so mock mode always shows 0. Backend strings ("4,120 delivered") work | `frontend/src/components/alerts/AlertStats.tsx:6`, `frontend/src/mocks/fixtures.ts:232-238` |
| 6 | Mock mode: `GET /v1/plans/:id` ignores the id and always returns Plan #214, so `/plans/999` shows Plan #214 and the "Plan not found" branch is only reachable against the backend. `POST /v1/plans/draft` returns Plan #214 with status `drafting` instead of a new plan | `frontend/src/mocks/handlers.ts:34-35`, `frontend/src/app/(console)/plans/[id]/page.tsx:68-69` |
| 7 | Mock mode: `GET /v1/hotspots` ignores `ward`, so the header ward picker does not filter anything without a backend | `frontend/src/mocks/handlers.ts:27-31` |
| 8 | Scrubbing to negative hours is labelled "Observed replay" but shows current values: hotspots are always fetched at hour 0 and `atHour` only transforms positive hours | `frontend/src/components/map/layers.ts:36`, `frontend/src/hooks/useHotspots.ts:18`, `frontend/src/components/map/TimeScrubber.tsx:18` |
| 9 | While hotspots are loading, or when the backend is unreachable, every map draws the element's built-in demo field and stations with no "demo data" label. Truck routes, bus trails, schools, anchors and the Ghazipur suspect pin are always built-in | `frontend/src/components/map/useMapStations.ts:6-9`, `frontend/src/lib/visuals/hawa-gl.js:120-121`, `:174-200` |
| 10 | Backend unreachable: `/plans` shows "No draft plans … Draft plan now" instead of an error; `/route` shows a skeleton forever; `/what-if` and the landing What-If section have no error state ("—" or "Loading plan…") | `frontend/src/app/(console)/plans/page.tsx:24`, `frontend/src/app/(driver)/route/page.tsx:27`, `frontend/src/app/(console)/what-if/page.tsx`, `frontend/src/app/(marketing)/sections/WhatIf.tsx:42` |
| 11 | Hard-coded values shown as data: "Last packet 6 s ago", "Wind NW · 2.1 m/s", "Thursday 06:00–10:00, by ward", "Review Plan #214", "Awaiting indoor sensor", next stop "2.4 km", "9 assets across 41 candidate cells", and the asset list `T-12, ASG-07, SW-03, I-3` on four maps | `AssetPanel.tsx:63`, `LayerToggles.tsx:25`, `forecast/page.tsx:43`, `:66`, `:79`, `WhatsAppPreview.tsx:29`, `route/page.tsx:83`, `PlanStates.tsx:10`, `plans/[id]/page.tsx:55`, `what-if/page.tsx:28`, `sections/WhatIf.tsx:47` |
| 12 | Console auth is client-side only: `AuthGuard` hides the console without a Cognito session and the ID token is sent as `Bearer`, but no backend route checks it. `logout()` exists but no UI calls it | `frontend/src/components/shell/AuthGuard.tsx:14`, `frontend/src/lib/auth.ts:44`, `frontend/src/lib/api.ts:25-31` |
| 13 | Dark mode inverts the whole console with a CSS filter, which also inverts the CPCB data colours and the basemap; the setting is not persisted | `frontend/src/components/shell/ConsoleShell.tsx:18`, `frontend/src/stores/console.ts:31-52` |
| 14 | The contract verifier has no `package.json` script and no `tsx` dependency; plain `node` fails on the extensionless directory import. It reads `API_URL` (default port 8099, while the backend defaults to 8000), runs 15 requests but prints "ALL 14", and its POSTs change the backend's in-memory Plan #214 (approve, request changes) | `frontend/scripts/verify_backend_contracts.ts:13`, `:15`, `:57-98`, `:116` |
| 15 | Code comments point to `docs/API.md` (does not exist; the backend API doc is `docs/backend/API.md`) and to `design/claude-design/source/` (the path is `design/source/`) | `frontend/src/contracts/index.ts:1`, `frontend/src/mocks/handlers.ts:1`, `frontend/src/lib/visuals/hawa.js:2`, `hawa-gl.js:2`, `pixel.js:2` |
| 16 | Alerts for the `Workers` and `Drivers` audiences (in the contract and the fixtures) have no filter button and appear only under "All" | `frontend/src/app/(console)/alerts/page.tsx:11`, `frontend/src/contracts/alert.ts:5` |
| 17 | `hawa.js` is loaded on every page but none of its elements (`hc-icon`, `hawa-map`, `hc-chart`, `hc-count`, `hc-iso`) is used; `vx-hexmap` in `pixel.js` is also unused | `frontend/src/components/visuals/VisualsLoader.tsx:18` |

## 9. Links

- System context: [../SYSTEM_OVERVIEW.md](../SYSTEM_OVERVIEW.md)
- Backend API: [../backend/API.md](../backend/API.md). The wire shapes the web relies on are the zod schemas in `frontend/src/contracts/`; [../CONTRACTS.md](../CONTRACTS.md) describes a broader snake_case blueprint surface that the current backend and web do not follow (see [ARCHITECTURE §4.3](ARCHITECTURE.md#43-relationship-to-docscontractsmd))
- AI-ML: [../aiml/README.md](../aiml/README.md) · Flutter app: [../app/README.md](../app/README.md)
- Component quick start: [../../frontend/README.md](../../frontend/README.md) · Design export notes: [../../frontend/design/EXPORT_NOTES.md](../../frontend/design/EXPORT_NOTES.md)

<!-- footer:start -->

---

[Back to top](#hawacommand-web-frontend-documentation-index) · [Docs hub](../README.md) · [Project README](../../README.md)

<!-- footer:end -->
