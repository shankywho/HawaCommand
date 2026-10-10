# Web Pages and Components

Purpose: page by page, what the web app renders today: route, file, components, the hooks and backend endpoints behind each piece, what happens without a backend, and the status. It ends with the pages the original blueprint specified that are not built.

Related: [README](README.md) · [CONTEXT](CONTEXT.md) · [ARCHITECTURE](ARCHITECTURE.md) · [STRUCTURE](STRUCTURE.md) · [DESIGN_SYSTEM](DESIGN_SYSTEM.md) · [LINTING_AND_QUALITY](LINTING_AND_QUALITY.md) · [PLAN](PLAN.md) · [../backend/API.md](../backend/API.md)

---

## 1. Conventions

- **Endpoints** are exactly what `src/lib/api.ts` requests. The hook-to-endpoint table is in [ARCHITECTURE §4.2](ARCHITECTURE.md#42-endpoints-the-web-calls).
- **Mock mode** means `NEXT_PUBLIC_API_URL` is empty and every call is answered by `src/mocks` (chosen at build time). **Backend unreachable** means the variable is set but requests fail.
- **Status** uses the shared vocabulary: Implemented, Partial (gaps named), Stub/Mock, Planned.
- Every console page renders inside `<Screen headline aside>`: a one-sentence headline that states the most important fact, a main area, and an optional right-hand aside (320 px, 360 px from 1180 px, 420 px from 1600 px).

## 2. Route map

| Route | File | Status | Data |
|---|---|---|---|
| `/` | `src/app/(marketing)/page.tsx` | Implemented | hotspots, forecast, plans, plan, interventions |
| `/login` | `src/app/(auth)/login/page.tsx` | Partial | Cognito |
| `/map` | `src/app/(console)/map/page.tsx` | Partial | hotspots |
| `/forecast` | `src/app/(console)/forecast/page.tsx` | Partial | forecast, hotspots |
| `/plans` | `src/app/(console)/plans/page.tsx` | Implemented | plans, draft |
| `/plans/[id]` | `src/app/(console)/plans/[id]/page.tsx` | Partial | plan, hotspots, plan mutations |
| `/what-if` | `src/app/(console)/what-if/page.tsx` | Partial | plans, plan, compare, hotspots |
| `/impact` | `src/app/(console)/impact/page.tsx` | Implemented | impact, impact library, hotspots, devices |
| `/fleet` | `src/app/(console)/fleet/page.tsx` | Partial | devices, hotspots |
| `/alerts` | `src/app/(console)/alerts/page.tsx` | Implemented | alerts |
| `/route` | `src/app/(driver)/route/page.tsx` | Partial | driver route |
| any other path | `src/app/not-found.tsx` | Implemented | none |

There is no `/console` prefix: console screens sit at the top level. There is no `/console` index route; the landing CTA and the 404 page link to `/map`.

## 3. Console shell

Files: `src/app/(console)/layout.tsx`, `src/components/shell/*`, `src/components/ui/CommandPalette.tsx`. Status: **Implemented**.

```
┌──────────────────────────────────────────────────────────────────────────────┐
│ [H] HawaCommand  [⌖ All wards ⇕]           [PM2.5 412 · SEVERE] [Search ⌘K] Tue 14:00 │ 52 px header
├────────────┬─────────────────────────────────────────────────────────────────┤
│ Map        │ Headline sentence                                               │
│ Forecast   ├───────────────────────────────────────────┬─────────────────────┤
│ Plans  (1) │                                           │                     │
│ What-If    │            main (map, table, plan)        │      aside          │
│ Impact     │                                           │                     │
│ Fleet      │                                           │                     │
│ Alerts     │                                           │                     │
│            │                                           │                     │
│ • Live     │                                           │                     │
│ Settings   │                                           │                     │
│ Collapse   │                                           │                     │
└────────────┴───────────────────────────────────────────┴─────────────────────┘
  168 px rail (56 px collapsed)
```

| Part | Component | Data | Behaviour |
|---|---|---|---|
| Guard | `AuthGuard` | `currentOfficer()` | Renders nothing and redirects to `/login` when Cognito is configured and no user is signed in; pass-through in demo mode |
| Logo | `ConsoleHeader` | none | Links to `/` |
| Ward picker | `ConsoleHeader` | `useForecast(ward)` → `GET /v1/forecast?ward=` | Options: "All wards", the current ward, and every ward in `forecast.wards`. Escape or an outside click closes it. Sets `useConsole.ward` |
| AQI chip | `ConsoleHeader` + `AqiChip` | `useWardHotspots(0)` → `GET /v1/hotspots` | Highest hotspot PM2.5 at the scrubber hour; tooltip adds the GRAP stage and headline |
| Search | `ConsoleHeader` | none | Opens the command palette (there is no entity search) |
| Clock | `ConsoleHeader` | `now()` | `dayTime(now())`; tooltip shows when hotspots were last updated |
| Rail | `IconRail` | `usePlans()`, `useWardHotspots(0)` | Seven links (`NAV`), sliding active pill, pending-plan count on Plans (status `draft` or `changes_requested`), "Live · worst now" indicator, Settings, Collapse. Collapses to icons below 1320 px unless pinned |
| Settings | `ConsoleShell` | none | Popover with one switch: Dark mode (CSS invert filter, not persisted) |
| Toast | `ConsoleShell` | `useConsole.toast` | Bottom-right card, dismissed with the X button |
| Minimum width | `ConsoleShell` | | The shell is a fixed grid with `min-width: 820px`; it is not designed for phones |

### 3.1 Command palette (Cmd/Ctrl+K)

`src/components/ui/CommandPalette.tsx`. Opens with Cmd/Ctrl+K or the header search button; Escape closes; arrow keys and Enter select; typing filters by label or hint.

| Command | Action | Data |
|---|---|---|
| Show hotspots near schools | Turns on heat, hotspots, schools (off: trails, trucks) and opens `/map` | `useWardHotspots(0)` count of hotspots with schools |
| Draft plan for <ward> | `POST /v1/plans/draft {ward}`, toast, go to `/plans/{id}` | `useDraftPlan` |
| Open Plan #<id> | Go to the first plan | `usePlans()` |
| Jump to peak forecast (<day time>) | Sets the hour to the peak and opens `/forecast` | `usePeakHour()` |
| Compare Plan #<id> with usual routes | Opens `/what-if` | `usePlans()` |
| Which sprinkler runs worked this week? | Opens `/impact` | none |
| Where is <first asset>? | Opens `/fleet?asset=<id>` | `useFleet()` |

## 4. Pages

### 4.1 `/` Landing page

File: `src/app/(marketing)/page.tsx` (server component with `metadata`; title "HawaCommand · Delhi already owns the machines. We give them a brain."). Status: **Implemented**.

Page-level behaviour: Lenis smooth scrolling (`SmoothScroll`), a fixed section rail on screens ≥ 1360 px (`ScrollRail`), and a fixed `<px-sky scroll>` background. All live numbers go through `useLandingAir()` (`(marketing)/live.ts`) or the console hooks, so the landing page never shows a number the console does not.

| # | Section (file) | Anchor | What it renders | Data |
|---|---|---|---|---|
| 1 | `LandingNav` | `#top` | Sticky nav that shrinks after 24 px of scroll; links Product, How it works, Proof, Hardware, Open data (≥ 1080 px); AQI chip with the worst hotspot (≥ 1280 px); "Open live console" | `useLandingAir()`: `GET /v1/hotspots?hour=0`, `GET /v1/forecast` |
| 2 | `Hero` | `#top` | Two-line headline, CTAs ("Open live console" → `/map`, "See how it works" → `#how`), three facts, parallax `<vx-city>`, AQI chip and "Right now" card (hotspots ranked, worst µg/m³, GRAP stage and probability), `<px-skyline stage=0.05>` | `useLandingAir()`. Card says "Simulated data" or "Live data" from the list's `simulated` flag |
| 3 | `Marquee` | none | Ticker with six sourced facts, paused on hover | static |
| 4 | `Problem` | `#problem` | 376 count-up, `<px-scene kind=smoggun>`, road dust 15% of PM2.5 vs 64% of funds bars, "No routine impact check", sources line | static |
| 5 | `Causes` | `#causes` | Four cause panels (dust, traffic, burning, stubble) with Hindi names, signal and fix; scroll-pinned on ≥ 1024 px where scroll position opens each panel; `<px-scene>` per cause | static |
| 6 | `HowItWorks` | `#how` | Seven steps (Sense → Verify) linked to scroll over a non-interactive `<hawa-gl>` that changes layers, hour, mode and camera per step | static; the map uses its built-in demo data (no `stations`) |
| 7 | `WhatIf` | `#whatif` | Usual-to-plan range slider; people-hours avoided and "% more people protected" scale with the slider; extruded 3D map | `usePlans()`, `usePlan(firstId)`, `usePeakHour()`, `useMapStations(peak)` |
| 8 | `Proof` | `#proof` | "Progress report" card for the first intervention with an impact: `SyntheticControlChart`, effect with CI, duration, action, method, cell, verdict stamp, simulated note | `useInterventions()` → `GET /v1/impact` |
| 9 | `Hardware` | `#hardware` | HawaPod-M `<vx-pod scrub>` with specs and ₹7,000–9,500 price; HawaPod-S and HawaTag cards with `<vx-model>` | static |
| 10 | `Learned` | `#learned` | Four lessons (CN/JP) with `<px-scene>`; smog-tower refusal | static |
| 11 | `Aws` | `#aws` | "What runs where" tower with status per layer (Wired, Built, Planned, Simulated) and a note that Cognito is supported but off in the demo | static |
| 12 | `Cost` (in `Aws.tsx`) | `#cost` | District pilot ≈ ₹22–24 lakh vs one smog tower ≈ ₹20–22 crore, animated bars | static |
| 13 | `Footer` | `#open` | Target AQI 48 chip, closing headline, "Open live console", `GET /open/v1/air` link (disabled span in mock mode), footer links, `<px-skyline stage=1>` | `API_URL` |

Without a backend: in mock mode every live block renders fixtures ("Simulated data"). With the backend unreachable, the nav chip and "Right now" card are hidden, Proof shows "Couldn't load the intervention", and What-If shows "Loading plan…" with a zero count; the maps draw their built-in demo field.

### 4.2 `/login`

File: `src/app/(auth)/login/page.tsx`. Status: **Partial** (see [ARCHITECTURE §7](ARCHITECTURE.md#7-authentication)).

Renders a card with the logo, "Officer sign-in", "MCD and DPCC ward officers only." With Cognito configured: username and password fields, "Sign in", inline error text, "Additional step required: <step>" for unhandled challenges. In demo mode: a notice and "Open console" (→ `/map`). No backend call. Missing: sign-out, challenge handling, password reset, roles.

### 4.3 `/map` Live map

File: `src/app/(console)/map/page.tsx`. Status: **Partial**.

| Element | Component | Data | Notes |
|---|---|---|---|
| Headline | `Screen` | hotspots | "<top 1>, <top 2> and <top 3> need action first." (by PM2.5 at the scrubber hour) |
| Map | `HawaMap` | `useWardHotspots(0)` → `GET /v1/hotspots?hour=0&ward=` (5 s poll), transformed by `atHour` | Layers from the toggles, threshold 250, 3 labels, clicking a marker selects the hotspot. The selected hotspot's `assets` choose which demo routes are drawn |
| Layer toggles | `LayerToggles` | store | Heat (`hex`), Stations (`stations`, `causes`), Bus trails (`buses`), Fleet (`trucks`), Schools (`schools`) |
| Wind chip | `WindChip` | none | Fixed text "Wind NW · 2.1 m/s" (Stub/Mock) |
| Legend | `Legend` | none | PM2.5 band gradient with 30/60/90/120/250 ticks, route and school keys |
| Time scrubber | `TimeScrubber` | `usePeakHour()` | −24 h to +72 h, Now and Peak buttons, day labels at 12:00 IST. Positive hours show each cell's forecast P50; negative hours are labelled "Observed replay" but show current values (Stub) |
| Aside: list | `HotspotList` | same hotspots | Sorted by PM2.5; cause icon and verb ("Send sprinkler", "Divert traffic", "Send inspector", "Alert schools"); "Watch" tag and grey swatch below the threshold |
| Aside: detail | `HotspotDetail` | same hotspot; `usePlans()`; `useDraftPlan` | Place and ward, PM2.5 value and band, `CauseTag` with confidence, exposure next 4 h, rank, estimate confidence, likely upwind source, nearby schools ("assembly at 08:00" is fixed text), 72 h `ForecastChart` with peak time; primary button drafts a plan for the header ward (`POST /v1/plans/draft`); "Open Plan #<first plan>" |

Without a backend: mock mode shows the 10 fixture hotspots (the ward filter has no effect). Backend unreachable: `QueryError` in the aside, "Loading the current hotspots…" headline, and the map's built-in demo field.

Gaps: demo route, bus, school and suspect overlays; replay; wind; no hotspot outlines, trajectories, staleness or "Simulated" labelling.

### 4.4 `/forecast` Forecast and GRAP

File: `src/app/(console)/forecast/page.tsx`. Status: **Partial**.

| Element | Data | Notes |
|---|---|---|
| Headline | `useForecast(ward)` → `GET /v1/forecast?ward=` | "<ward 1> and <ward 2> will carry the most exposure." |
| On mount | `usePeakHour()` | If the scrubber is at or before now, it jumps to the peak hour |
| Map | `useMapStations(hour)` (hotspots) | Layers hex, stations, causes, buses, trucks, schools; labels full; fixed demo assets `T-12, ASG-07, SW-03, I-3` |
| GRAP banner | forecast `grap` | Headline; tooltip with P50/P90 at the peak, probability and issue time; "Stage <n> checklist" button expands `grap.actions` |
| Aside: exposure table | forecast `wards` | Wards sorted by people-hours, share bar and %, peak PM2.5 with band colour, confidence word in the tooltip; clicking a row sets the header ward. Subtitle "Thursday 06:00–10:00, by ward" is fixed text |
| Aside: chart | forecast `series` | `ForecastChart` for the selected ward with the peak marked |
| Aside: CTA | none | "Review Plan #214" always links to `/plans/214` |

Without a backend: mock forecast (East Delhi, Stage II, eight wards). Backend unreachable: `QueryError` in the aside; the map shows the demo field.

### 4.5 `/plans` Plans index

File: `src/app/(console)/plans/page.tsx`. Status: **Implemented**.

Fetches `usePlans()` (`GET /v1/plans`). If a plan exists for the header ward, or any plan exists, it replaces the URL with `/plans/{id}` and shows `PlanSkeleton` meanwhile. Otherwise it shows `PlanEmpty` ("No draft plans for <ward>", "Draft plan now"), which calls `POST /v1/plans/draft {ward}` and navigates to the new plan. Backend unreachable: shows the empty state instead of an error.

### 4.6 `/plans/[id]` Plan review

File: `src/app/(console)/plans/[id]/page.tsx`. Status: **Partial**.

| Element | Component | Data / endpoint |
|---|---|---|
| Headline | `Screen` | "Plan #<id> for <ward> is waiting for your approval." or "… is approved and dispatching." |
| Header | `PlanHeader` | Status pill (Drafting, Draft, Changes requested, Approved · dispatching, Dispatching, Done), window and drafter, **Edit (disabled: "Plan editing is not available yet")**, Compare (→ `/what-if`), Details toggle; "+N% more people protected with the same fleet" count-up, people-hours saved, assets used, confidence word with likely range in the tooltip |
| Planner note | `PlannerNote` | `summary`, expandable `reasoning`, confidence |
| Diff | `PlanDiff` | One card per asset group: `+` added and `−` removed tasks vs the usual route, time, place, `CauseTag`, reason, flags. Tasks flagged `suggested` stay hidden until every Auditor comment is applied |
| Auditor comment | `AuditorComment` | Objection, confidence, suggested remove/add, **Apply suggestion** → `POST /v1/plans/{id}/suggestions/{commentId}/apply`; **Reply (disabled)** |
| Checks and approval | `ApproveBar` | Each `checks[]` row with an icon; summary ("All checks passed…" or "<n> check needs attention…"); **Request changes** → `POST /v1/plans/{id}/request-changes {note: "Officer requested changes"}`; **Approve & dispatch** → `POST /v1/plans/{id}/approve` (dimmed but still clickable when a check fails); shows the Step Functions execution name when `executionArn` is present |
| Aside map | `HawaMap mode="plan"` | `useMapStations(peak)` scaled by `applyPlan`, centred on the stations, "Plan routes · <window>" badge |
| Details drawer | `PlanDetails` | Reviewers (Auditor resolved or not; ward officer approval time) and agents (Forecaster run time, Planner route count, Auditor comment count) |
| Toast | `ConsoleShell` | After approve: "Plan #<id> approved · <n> tasks queued for <window>." |

Without a backend: Plan #214 from fixtures for any id; mutations persist in memory until reload. Backend: a 404 shows "Plan not found … It may have been cleared when the server restarted." (the backend keeps drafted plans in memory; Plan 214 is always seeded).

Gaps: editing, replying to the Auditor, a note field for Request changes, an approve confirmation step, live task status.

### 4.7 `/what-if` Usual routes vs plan

File: `src/app/(console)/what-if/page.tsx`. Status: **Partial**.

Uses the first plan from `usePlans()`, then `usePlan(id)` and `usePlanComparison(id)` (`GET /v1/plans/{id}/compare`).

| Element | Data | Notes |
|---|---|---|
| Two maps | `useMapStations(peak)`; plan side through `applyPlan` | Extruded 3D, buildings layer, demo assets; left "Usual routes", right "Plan #<id>". Both maps are a client-side illustration |
| Delta | `comparison.deltaPct` | Printed as `fmtPct(deltaPct)` + "less exposure, same fleet". Backend sends a positive gain, mocks a negative change (Known issue 4) |
| Table | `comparison.rows` | Asset, usual route, plan route, km usual → plan, people-hours reached, exposure change |
| Aside | `plan.headline`, `plan.window`, `plan.draftedAt` | People-hours usual → plan, likely saving range, fleet used, window, forecast issue time, "Effects from: Library, weather-matched" (fixed), extra km, "Simulated. After dispatch, measured effects replace this estimate.", "Back to review" |

Backend unreachable: no error UI; "—" for the delta, empty table, no aside.

### 4.8 `/impact` Verified interventions

File: `src/app/(console)/impact/page.tsx`. Status: **Implemented**.

| Element | Data | Notes |
|---|---|---|
| Headline | `useInterventions()` → `GET /v1/impact` | "<verifiedPct>% of this week's actions had a verified effect (target <targetPct>%)." |
| Table | `ImpactTable` | ID, asset, place, action and cause, verdict, effect, 95% CI text and bar (−40% to +10%), duration. Footnote says the interventions are simulated with injected effects (fixed text) |
| Detail | `InterventionDetail` | `SyntheticControlChart` + `ChartKey`; donor-cell map (`HawaMap mode="donor"`, centred on the cell from hotspots or the asset position from devices; donor positions are drawn by the element); facts: effect, 95% CI, duration, method, donor count |
| Library | `EffectLibrary` | `useEffectLibrary()` → `GET /v1/impact/library`: action, cause, weather, typical effect with CI, duration, n |
| Aside | summary | Verified %, no-effect and wrong-tool counts, two suggestions derived from them, **Weekly evidence report** (downloads `hawa-evidence-report-YYYY-MM-DD.md` built in the browser) |

Backend unreachable: `QueryError` in the main area; the library is omitted.

### 4.9 `/fleet` Fleet and HawaTag

File: `src/app/(console)/fleet/page.tsx`. Status: **Partial**.

| Element | Data | Notes |
|---|---|---|
| Headline | `useFleet()` → `GET /v1/devices` (5 s poll) | "<n> of <m> assets are reporting; <id> has been silent for <k> minutes." |
| Map | `useMapStations(hour)`, fleet positions | Fleet markers from `at`; centre on the selected asset; toggles, wind chip, scrubber |
| Table | `FleetTable` | Asset, type, task, status dot, HawaTag summary, last ping ("<n> s/min/h" from `now()`) |
| Aside | `AssetPanel` | Label, "Simulated" chip, task; HawaTag pump state, flow, litres this run / tank, PM10 before / now, spray windows on a fixed 05:30–11:30 axis, tamper seal, 4G signal, trust score, **"Last packet 6 s ago" (fixed text)** with the sequence number in the tooltip; "No HawaTag fitted" for assets without a tag |

`?asset=` preselects an asset (default T-12). Fleet data is withheld until after mount so the server HTML matches the first client render. Backend unreachable: `QueryError` in the aside, empty table.

### 4.10 `/alerts` Alert log

File: `src/app/(console)/alerts/page.tsx`. Status: **Implemented** (read-only; compose is Planned).

| Element | Data | Notes |
|---|---|---|
| Headline | `useAlerts()` → `GET /v1/alerts` | "<target> were warned <n> hours before the spike." from the first school alert with a lead time |
| Stats | `AlertStats` | Alerts sent, people reached (parsed from "<n> delivered"; 0 in mock mode), median lead time, channels; lead-time bar per alert |
| Filter | page | All, Schools, Citizens, Citizen Eyes with counts from `counts`. Workers and Drivers alerts appear only under All |
| Table | `AlertsTable` | Sent time, audience icon, target, message, channel and language, delivered, lead time |
| Aside | `WhatsAppPreview` | Chat-style preview: Hindi bubble (when `messageHi`), English bubble, lead time, "Indoor vs outdoor, 08:00: Awaiting indoor sensor" (fixed text) |

Backend unreachable: `QueryError` instead of the table.

### 4.11 `/route` Driver view

Files: `src/app/(driver)/layout.tsx`, `src/app/(driver)/route/page.tsx`. Status: **Partial**.

`?asset=` selects the asset (default `T-12`); data from `useDriverRoute(asset)` → `GET /v1/driver/route?asset=`.

| State | What it shows |
|---|---|
| Before start | Asset badge, Hindi asset label, "आज का रूट" / "Today's route", date and window, small non-interactive plan map (fixed centre), one card per stop (Hindi place, English place and action, time window), "छिड़काव HawaTag अपने-आप दर्ज करेगा · Spray is logged automatically", large "रूट शुरू करें / Start route" button |
| After start | "स्टॉप 1 / <n>", a "छिड़काव दर्ज ✓ / Spray logged" confirmation, last-spray tiles (litres, pump minutes, pump ON/OFF) from `lastSpray`, the next `todo` stop with a fixed "2.4 km", and "रास्ता दिखाएँ / Navigate to stop <n>" which opens Google Maps directions |

No typing anywhere. "Start route" changes local state only; nothing is sent to the backend and the "Spray logged" screen does not wait for a HawaTag event. There is no web manifest or service worker, so the page is not installable or usable offline. Backend unreachable: a permanent skeleton.

### 4.12 404

`src/app/not-found.tsx`: "Page not found" card with "Open the console" (→ `/map`). Status: **Implemented**.

## 5. Planned pages

> Status: Planned. These routes were specified in the original blueprint and do not exist in `src/app`. Their target URLs were under `/console/...`; if built, they should follow the current top-level convention (for example `/grap`, not `/console/grap`).

| Blueprint route | Purpose | What exists today |
|---|---|---|
| `/hotspots`, `/hotspots/[id]` | Hotspot table and full detail with back-trajectory | The `/map` aside list and `HotspotDetail`; backend has `GET /v1/hotspots/{cell_id}` (unused) |
| `/grap` | Three-day GRAP outlook and ward checklist | GRAP banner and checklist on `/forecast` |
| `/interventions`, `/interventions/[id]` | Intervention list and per-intervention proof page | Table and detail on `/impact`; backend has `/v1/impact/{id}/verify` (unused) |
| `/schools`, `/schools/[id]` | School safe-window scheduler, indoor vs outdoor | Schools listed in `HotspotDetail`; school alerts on `/alerts` |
| `/reports`, `/inspections` | Citizen Eyes queue and inspection tickets | "Citizen Eyes" alerts on `/alerts`; the Flutter app has citizen reporting |
| `/sites` | Construction-site compliance grades | none |
| `/devices`, `/devices/[id]` | Device registry, calibration, trust | HawaTag state in `/fleet` |
| `/integrity` | Anti-gaming flags | An anti-gaming check can appear in a plan's `checks` |
| `/coverage` | Blind spots and suggested sensing routes | none |
| `/evidence` | Evidence report builder and archive | Client-side Markdown download on `/impact` |
| `/admin` | Users, roles, ward scopes, model versions | none |
| `/open`, `/open/api`, `/open/methods` | Public map, API docs, methods ("indicative") | Footer link to the backend's `GET /open/v1/air` |
| `/open/reports/[code]` | Citizen report status page | none |
| `/hi/...` | Hindi locale for every page | none |
| Alert compose | Draft and send an alert from the console | none |
| Plan edit mode | Reassign, retime, remove or add tasks, then re-simulate | Disabled Edit button on `/plans/[id]` |
