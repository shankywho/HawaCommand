# Web Frontend Folder Structure

Purpose: the complete `frontend/` tree as it exists in the repository, with one line of responsibility per file, plus the dependency rules the code follows and where new code should go.

Related: [README](README.md) · [CONTEXT](CONTEXT.md) · [ARCHITECTURE](ARCHITECTURE.md) · [PAGES](PAGES.md) · [DESIGN_SYSTEM](DESIGN_SYSTEM.md) · [LINTING_AND_QUALITY](LINTING_AND_QUALITY.md) · [PLAN](PLAN.md) · [../SYSTEM_OVERVIEW.md](../SYSTEM_OVERVIEW.md)

---

## 1. Conventions

- **App Router route groups.** `src/app/(marketing)`, `(auth)`, `(console)` and `(driver)` group pages without adding a URL segment. URLs are `/`, `/login`, `/map`, `/forecast`, `/plans`, `/plans/[id]`, `/what-if`, `/impact`, `/fleet`, `/alerts` and `/route`. There is no `/console` prefix and no `[locale]` segment.
- **Path aliases** (from `tsconfig.json`): `@/*` maps to `src/*`; `@hawa/contracts` maps to `src/contracts/index.ts`.
- **Client components** carry `"use client"`. Every console page, the driver page and the login page are client components. The landing page (`(marketing)/page.tsx`) and the layouts are server components that render client sections.
- **One query hook per API area** lives in `src/hooks`. Pages never call `fetch` directly; they call hooks, which call `api` in `src/lib/api.ts`.
- **Vendored plain JavaScript** (`src/lib/visuals/*.js`) is excluded from type checking (`tsconfig.json` `exclude`) and starts with `// @ts-nocheck`.
- **File names**: React components in `PascalCase.tsx`, hooks in `useX.ts`, everything else in `camelCase.ts` or lower-case. One component per file, except small helpers exported alongside (for example `MapBadge` in `HawaMap.tsx`, `WindChip` in `LayerToggles.tsx`).
- Generated and installed folders (`node_modules/`, `.next/`, `*.tsbuildinfo`) are git-ignored at the repository root and are not listed below.

## 2. Tree

```
frontend/
├── .env.example                          Env template: NEXT_PUBLIC_API_URL (empty = in-browser mocks), Cognito pool and client ids
├── README.md                             Component quick start: commands, routes, backend wiring, layout
├── amplify.yml                           AWS Amplify Hosting build spec: appRoot frontend, corepack enable, pnpm install --frozen-lockfile, pnpm build, artifacts from .next
├── next-env.d.ts                         Next.js generated type references (do not edit)
├── next.config.ts                        Next.js config: only `devIndicators: false` (hides the dev badge)
├── package.json                          Scripts dev/build/start/lint/typecheck, 12 dependencies, 7 devDependencies, packageManager pnpm@11.17.0, engines node >=20
├── pnpm-lock.yaml                        pnpm lockfile (lockfileVersion 9.0)
├── postcss.config.mjs                    PostCSS plugins: tailwindcss, autoprefixer
├── tailwind.config.ts                    Tailwind 3 theme extension: colours, font families, shadows, keyframes, animations (see DESIGN_SYSTEM §2)
├── tsconfig.json                         TypeScript strict, ES2022, Bundler resolution, allowJs, path aliases, excludes src/lib/visuals/*.js
│
├── design/                               Claude Design prototype export. Reference only: not imported, not served
│   ├── EXPORT_NOTES.md                   What the export contains and how each file maps to the Next.js app
│   ├── thumbnail.webp                    Preview image of the design project
│   └── source/
│       ├── Console v2.dc.html            Earlier officer-console iteration (hawa-gl map, hc-chart, command palette)
│       ├── Console v3.dc.html            Console variant built on the civic-map element (alternative layout, not ported)
│       ├── Console v4.dc.html            Final officer-console design; the (console) route group is ported from it
│       ├── Design System.dc.html         Design-system sheet: palette, type, chips, pixel scenes, voxel models
│       ├── Landing.dc.html               Landing page design; the (marketing) sections are ported from it
│       ├── Landing Mobile.dc.html        390 px landing study (hero, causes, proof card, footer)
│       ├── Mobile.dc.html                390 px phone screens: driver route (ported to /route), school alert, Citizen Eyes
│       ├── civic-map.js                  <civic-map> element used only by Console v3
│       ├── delhi-street.js               <delhi-street> canvas street scene (design exploration, not ported)
│       ├── delhi.geojson                 NCT of Delhi outline polygon
│       ├── hawa-geo.js                   <hawa-geo> canvas map element (design exploration, not ported)
│       ├── hawa-gl.js                    Original <hawa-gl> MapLibre element (vendored and extended in src/lib/visuals/hawa-gl.js)
│       ├── hawa.js                       Original hc-icon, hawa-map, hc-chart, hc-count, hc-iso elements (vendored unchanged)
│       ├── image-slot.js                 <image-slot> placeholder component from the design tool
│       ├── pixel.js                      Original px-* pixel scenes and vx-* voxel models (vendored unchanged)
│       ├── street.js                     <hc-street> canvas street scene (design exploration, not ported)
│       └── support.js                    Generated runtime for the .dc.html files
│
├── public/                               Static files served from /
│   ├── fonts/.gitkeep                    Empty placeholder (fonts load through next/font/google)
│   ├── illustrations/.gitkeep            Empty placeholder
│   └── logo.svg                          Pixel "H" logo, served at /logo.svg (not referenced by the code)
│
├── scripts/
│   └── verify_backend_contracts.ts       Live contract check: 15 requests to 14 backend endpoints, each response validated with the zod contracts (needs tsx and a running backend)
│
└── src/
    ├── app/
    │   ├── layout.tsx                    Root layout: Geist, Geist Mono, Silkscreen, Noto Sans Devanagari via next/font; metadata; <Providers>; <VisualsLoader>
    │   ├── providers.tsx                 QueryClientProvider (staleTime 30 s, refetchOnWindowFocus false, retry 1)
    │   ├── globals.css                   Tailwind layers, CSS variables, .btn/.card/.table-* component classes, keyframes, reduced-motion rule, Lenis classes
    │   ├── icon.svg                      Favicon (Next.js file convention, served at /icon.svg)
    │   ├── not-found.tsx                 404 page with an "Open the console" link to /map
    │   │
    │   ├── (auth)/
    │   │   └── login/page.tsx            /login: Cognito username/password form, or a demo-mode notice when Cognito is not configured
    │   │
    │   ├── (console)/
    │   │   ├── layout.tsx                Console layout: <AuthGuard> around <ConsoleShell>
    │   │   ├── map/page.tsx              /map: live hotspot map, layer toggles, time scrubber, hotspot list or detail aside
    │   │   ├── forecast/page.tsx         /forecast: GRAP banner + checklist, map at the peak hour, ward exposure table, forecast chart
    │   │   ├── plans/page.tsx            /plans: redirects to the ward's plan (or the first plan); empty state offers "Draft plan now"
    │   │   ├── plans/[id]/page.tsx       /plans/[id]: plan review (header, Planner note, diff, Auditor comment, checks, approve), plan map aside
    │   │   ├── what-if/page.tsx          /what-if: usual vs plan maps, exposure delta, per-asset comparison table, assumptions aside
    │   │   ├── impact/page.tsx           /impact: intervention table, synthetic-control detail, effectiveness library, weekly report download
    │   │   ├── fleet/page.tsx            /fleet: fleet map, asset table, HawaTag panel; ?asset= preselects an asset
    │   │   └── alerts/page.tsx           /alerts: alert stats, audience filter, alert log, WhatsApp/SMS preview
    │   │
    │   ├── (driver)/
    │   │   ├── layout.tsx                Phone-width shell (max 420 px, rounded frame on wider screens); metadata title "Driver"
    │   │   └── route/page.tsx            /route: Hindi-first driver route for ?asset= (default T-12), Start route, Spray logged, Navigate
    │   │
    │   └── (marketing)/
    │       ├── page.tsx                  /: landing page composition and metadata (server component)
    │       ├── live.ts                   useLandingAir(): worst hotspot, hotspot count, GRAP, simulated flag from the same API as the console
    │       ├── Marquee.tsx               Full-bleed ticker of six sourced facts
    │       ├── Parallax.tsx              Moves children at a fraction of scroll speed (off under reduced motion)
    │       ├── Reveal.tsx                Fade/slide-in on first scroll into view (content visible without JS)
    │       ├── ScrollRail.tsx            Fixed left section rail with progress line (screens >= 1360 px)
    │       ├── SmoothScroll.tsx          Lenis inertial scrolling for the landing page only
    │       ├── useInView.ts              Hook: true once an element has entered the viewport
    │       └── sections/
    │           ├── ui.tsx                Shared landing blocks: SectionIntro, Section, ConsoleCta, CONSOLE_HREF = "/map"
    │           ├── LandingNav.tsx        Sticky nav that shrinks on scroll; AQI chip with the worst current hotspot
    │           ├── Hero.tsx              Headline, CTAs, voxel city, "Right now" card from live data
    │           ├── Problem.tsx           376 machines count-up, dust vs funds bars, "no impact check"
    │           ├── Causes.tsx            Four causes as expanding panels (scroll-pinned on wide screens)
    │           ├── HowItWorks.tsx        Seven scroll-linked steps over a <hawa-gl> map
    │           ├── WhatIf.tsx            Usual-to-plan slider fed by the first plan and live hotspots
    │           ├── Proof.tsx             Synthetic-control chart and facts for the first intervention with an impact
    │           ├── Hardware.tsx          HawaPod-M exploded view and specs, HawaPod-S and HawaTag cards
    │           ├── Learned.tsx           Lessons from China and Japan; the smog-tower refusal
    │           ├── Aws.tsx               "What runs where" status tower (Aws) and district pilot cost (Cost)
    │           └── Footer.tsx            Closing CTA, GET /open/v1/air link (only when NEXT_PUBLIC_API_URL is set), footer links
    │
    ├── components/
    │   ├── alerts/
    │   │   ├── AlertStats.tsx            Four stat tiles (alerts, people reached, median lead time, channels) + lead-time bars
    │   │   ├── AlertsTable.tsx           Alert log rows: sent time, audience icon, target, message, channel + language, delivered, lead time
    │   │   └── WhatsAppPreview.tsx       Chat-style preview of the selected alert (Hindi bubble + English bubble)
    │   ├── charts/
    │   │   ├── ForecastChart.tsx         SVG P10–P90 band + P50 line over faint CPCB band shading, optional hour marker
    │   │   └── useElementWidth.ts        ResizeObserver hook that returns an element's width
    │   ├── fleet/
    │   │   ├── AssetPanel.tsx            Selected asset: task, Simulated chip, HawaTag pump/flow/litres/PM10 tiles, spray timeline, tag health
    │   │   └── FleetTable.tsx            Asset table: id, type, task, status dot, HawaTag summary, last ping
    │   ├── hotspots/
    │   │   ├── HotspotDetail.tsx         Selected hotspot: value, band, cause, exposure, rank, confidence, suspect, schools, forecast, draft-plan action
    │   │   └── HotspotList.tsx           Ranked hotspot list with cause verb, band swatch and "Watch" tag below the threshold
    │   ├── impact/
    │   │   ├── EffectLibrary.tsx         Effectiveness library table (action, cause, weather, effect [CI], duration, n)
    │   │   ├── ImpactTable.tsx           Intervention table with effect, 95% CI text and CI bar on a −40%..+10% scale
    │   │   ├── InterventionDetail.tsx    Selected intervention: synthetic-control chart, donor-cell map, facts
    │   │   ├── SyntheticControlChart.tsx SVG observed vs synthetic control with band, spray window and effect bracket; ChartKey legend
    │   │   └── report.ts                 evidenceReport() builds a Markdown report; downloadText() saves it via a Blob link
    │   ├── map/
    │   │   ├── HawaMap.tsx               Typed React wrapper around the <hawa-gl> element; MapBadge label
    │   │   ├── layers.ts                 MapLayer names, LAYER_TOGGLES, layersFor, atHour, toMapStations, centroid, applyPlan, planReduction
    │   │   ├── LayerToggles.tsx          Heat / Stations / Bus trails / Fleet / Schools toggles; WindChip (fixed text)
    │   │   ├── Legend.tsx                PM2.5 band gradient with breakpoints, route and school keys
    │   │   ├── TimeScrubber.tsx          −24 h to +72 h range slider with Now and Peak buttons and day labels
    │   │   └── useMapStations.ts         Ward hotspots at an hour as map stations (undefined until loaded)
    │   ├── plans/
    │   │   ├── ApproveBar.tsx            Checks list, Request changes, Approve & dispatch, Step Functions execution id
    │   │   ├── AuditorComment.tsx        Auditor objection, suggested change, Apply suggestion; Reply (disabled)
    │   │   ├── PlanDetails.tsx           Details drawer: reviewers and agents on the plan
    │   │   ├── PlanDiff.tsx              Per-asset task diff (+ add / − removed vs usual route) with cause tags and inline Auditor comments
    │   │   ├── PlanHeader.tsx            Status pill, window, Edit (disabled), Compare, Details; "+N% more people protected" headline
    │   │   ├── PlannerNote.tsx           Planner agent summary with expandable reasoning
    │   │   └── PlanStates.tsx            PlanSkeleton (loading) and PlanEmpty (no plan for the ward)
    │   ├── shell/
    │   │   ├── AuthGuard.tsx             Redirects to /login when Cognito is configured and no user is signed in; no-op otherwise
    │   │   ├── ConsoleHeader.tsx         Logo link to /, ward picker, AQI chip, search button (opens palette), clock
    │   │   ├── ConsoleShell.tsx          Fixed grid (header, rail, main), settings popover (dark mode), command palette, toast
    │   │   ├── IconRail.tsx              Labelled nav rail (NAV), pending-plan badge, worst-hotspot indicator, Settings, Collapse
    │   │   └── Screen.tsx                Screen (headline + main + optional aside), PanelHead (unused), Fact row
    │   ├── ui/
    │   │   ├── AqiChip.tsx               Pixel-font chip "PLACE · PM2.5 n · BAND" or "AQI n"; BandSwatch square
    │   │   ├── CauseTag.tsx              Cause icon + label + confidence word
    │   │   ├── CommandPalette.tsx        Cmd/Ctrl+K palette with seven commands
    │   │   ├── Confidence.tsx            Confidence as High/Medium/Low with the number on hover
    │   │   ├── CountUp.tsx               Animated number when scrolled into view (respects reduced motion)
    │   │   ├── icons.tsx                 CAUSE_ICON and ASSET_ICON lucide mappings
    │   │   ├── Logo.tsx                  LogoMark (pixel H, optional blinking sensor pixel) and Logo (mark + wordmark)
    │   │   └── Skeleton.tsx              Skeleton block and QueryError message box
    │   └── visuals/
    │       └── VisualsLoader.tsx         Client-side loader: imports lucide + maplibre-gl, sets window globals, imports the three vendored element scripts once
    │
    ├── contracts/                        zod schemas + inferred types for every /v1 payload (imported as @hawa/contracts)
    │   ├── index.ts                      Re-exports every contract module
    │   ├── common.ts                     LonLat, Confidence, CAUSES/Cause, IsoDateTime, ASSET_KINDS/AssetKind, listOf() envelope
    │   ├── aqi.ts                        CPCB bands, PM2.5/PM10/AQI breakpoints, BAND_COLORS (+ dark), band helpers, Reading union
    │   ├── hotspot.ts                    NearbySchool, SuspectPin, Hotspot, HotspotList, HotspotQuery
    │   ├── forecast.ts                   GrapStage, ForecastPoint, WardExposure, Forecast
    │   ├── plan.ts                       PlanStatus, PlanTask, PlanAssetGroup, AuditorComment, PlanCheck, Plan, PlanSummary, request bodies, RouteComparison, PlanComparison, DriverStop, DriverRoute
    │   ├── asset.ts                      AssetStatus, HawaTagState, Asset, AssetList
    │   ├── intervention.ts               Verdict, Impact (with series), Intervention, InterventionList (+ summary), EffectLibraryRow
    │   ├── alert.ts                      Audience, Channel, Lang, Alert, AlertList (+ counts)
    │   └── packet.ts                     PacketV1 MQTT telemetry schema and TOPIC.telemetry (not used by the web UI)
    │
    ├── hooks/
    │   ├── useConsoleData.ts             useForecast, useFleet (5 s poll), useInterventions, useEffectLibrary, useAlerts, useDriverRoute
    │   ├── useHotspots.ts                useHotspots(hour, ward) (5 s poll at hour 0); useWardHotspots(hour) uses the header ward
    │   ├── useMediaQuery.ts              useSyncExternalStore wrapper around matchMedia
    │   ├── usePeakHour.ts                Forecast hour (1–72) with the highest mean hotspot P50; falls back to PEAK_HOUR (42)
    │   └── usePlan.ts                    usePlans, usePlan, usePlanComparison, useDraftPlan, usePlanActions (apply, approve, request changes)
    │
    ├── lib/
    │   ├── api.ts                        Typed fetch client for /v1/*: mock or real, Bearer token, zod validation, ApiError, API_URL, USING_MOCKS
    │   ├── auth.ts                       Amplify Auth (Cognito) configuration, AUTH_ENABLED, getIdToken, currentOfficer, login, logout
    │   ├── format.ts                     fmtInt, fmtPct (true minus), fmtRange, confidenceWord/Title, UGM3, CAUSE_VERB, ago, wardLabel, pollutantLabel
    │   ├── live.ts                       LIVE_POLL_MS = 5000 and the liveQuery TanStack options
    │   ├── time.ts                       IST formatters, DEMO_NOW and now(), addHours, isoAt, hourLabel, episode, PEAK_HOUR, hoursAtClock, dayHour, windowLabel
    │   └── visuals/                      Vendored design web components (plain JS, loaded by VisualsLoader)
    │       ├── hawa-gl.js                <hawa-gl>: MapLibre map with heat field, stations, routes, buses, schools, 3D buildings, donor mode
    │       ├── hawa.js                   hc-icon, hawa-map, hc-chart, hc-count, hc-iso (registered, not used by the app)
    │       └── pixel.js                  px-sky, px-skyline, px-scene, vx-city, vx-hexmap, vx-pod, vx-model canvas elements
    │
    ├── mocks/
    │   ├── handlers.ts                   mockFetch(): in-browser router for every /v1 path the client calls; in-memory plan state
    │   └── fixtures.ts                   Demo fixtures shaped by @hawa/contracts: 10 hotspots, forecast, Plan #214, comparison, fleet, interventions, library, alerts, driver route
    │
    ├── stores/
    │   └── console.ts                    Zustand useConsole: ward, hour, threshold, selected hotspot, layers, rail, palette, settings, dark, toast
    │
    └── types/
        └── custom-elements.d.ts          JSX typings for hawa-gl, px-sky, px-skyline, px-scene, vx-city, vx-pod, vx-model
```

File count: 138 tracked files (105 under `src/`, 19 under `design/`).

## 3. Dependency direction

```
app/**/page.tsx ──> components/** ──> hooks/** ──> lib/api.ts ──> contracts/**
       │                  │               │              └──(mock mode, dynamic import)──> mocks/**
       │                  │               └──> stores/console.ts
       │                  └──> lib/format.ts, lib/time.ts, contracts/aqi.ts
       └──> stores/console.ts

components/map/HawaMap.tsx ──renders──> <hawa-gl>  (registered by components/visuals/VisualsLoader.tsx from lib/visuals/hawa-gl.js)
app/(marketing)/sections/* ──renders──> <px-*>, <vx-*>  (registered from lib/visuals/pixel.js)
```

Rules the code follows today (by convention; no lint rule enforces them, see [LINTING_AND_QUALITY §4](LINTING_AND_QUALITY.md)):

1. Only `src/lib/api.ts` performs network requests to the backend. The vendored `hawa-gl.js` makes its own third-party requests (basemap tiles, MapLibre CSS, OSRM routes), see [ARCHITECTURE §8](ARCHITECTURE.md#8-map-and-visuals).
2. Only `src/lib/api.ts` imports `src/mocks/*`, and only through a dynamic `import()` when `NEXT_PUBLIC_API_URL` is empty.
3. Contracts (`src/contracts`) import only `zod` and each other. They have no React or browser code.
4. `src/lib/*` has no React imports (the hooks live in `src/hooks` and `src/components/map/useMapStations.ts`).
5. The landing page reads the same hooks as the console (`useHotspots`, `useForecast`, `usePlans`, `usePlan`, `useInterventions`), so the numbers it shows come from the API or the mocks, never from copy.

## 4. Where things go (quick decisions)

| I am adding... | Put it in | Notes |
|---|---|---|
| A new console screen | `src/app/(console)/<name>/page.tsx` + a `NAV` entry in `src/components/shell/IconRail.tsx` | Wrap content in `<Screen headline aside>` |
| A new API call | `src/contracts/<area>.ts` (schema), `src/lib/api.ts` (method), `src/hooks/` (query hook), `src/mocks/handlers.ts` + `fixtures.ts` (mock) | Add the endpoint to `scripts/verify_backend_contracts.ts` |
| Shared UI state | `src/stores/console.ts` | The store is not persisted |
| A formatting helper | `src/lib/format.ts` or `src/lib/time.ts` | Keep IST and `en-IN` grouping |
| A landing section | `src/app/(marketing)/sections/<Name>.tsx`, composed in `(marketing)/page.tsx` | Add its id to `ScrollRail` `ITEMS` if it should appear in the rail |
| A new map overlay | `src/components/map/layers.ts` (name) and `src/lib/visuals/hawa-gl.js` (drawing) | The map renderer is the vendored element; there is no deck.gl |
| A design token | `tailwind.config.ts` (and `globals.css` if a CSS variable is needed) | Update [DESIGN_SYSTEM](DESIGN_SYSTEM.md) in the same change |
