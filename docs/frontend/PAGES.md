# Web Pages and Components Specification

Purpose: the page-by-page spec for the console, the open data portal and the marketing site. For each page it gives the route, roles, data, channels, wireframe, components, interactions, states and acceptance criteria.

Related: [README](README.md) · [CONTEXT](CONTEXT.md) · [ARCHITECTURE](ARCHITECTURE.md) · [STRUCTURE](STRUCTURE.md) · [DESIGN_SYSTEM](DESIGN_SYSTEM.md) · [LINTING_AND_QUALITY](LINTING_AND_QUALITY.md) · [PLAN](PLAN.md) · [../CONTRACTS.md](../CONTRACTS.md) · [../SYSTEM_OVERVIEW.md](../SYSTEM_OVERVIEW.md) · [../backend/API.md](../backend/API.md)

---

## 1. Conventions

- **Endpoints** are quoted exactly from [CONTRACTS §6](../CONTRACTS.md#6-public-rest--websocket-surface-index). Endpoints or fields marked **(proposed)** are not in CONTRACTS yet ([ARCHITECTURE §18](ARCHITECTURE.md#18-contract-additions-requested-by-the-web)). The mock API serves them, and pages must degrade gracefully when the real backend returns 404 for them.
- **Shapes** are illustrative TypeScript. The authoritative shapes are [../backend/API.md](../backend/API.md) and the generated `schema.d.ts`.
- **Roles:** O = officer, An = analyst, Ad = admin, P = public. "R" = read-only.
- **States** column shorthand: L loading, E empty, X error, S stale, Sim simulated, Off WS offline or polling.
- **Tier** follows [CONTEXT §4](CONTEXT.md#4-features-f1f22-as-surfaced-in-the-web). BUILD pages must pass their acceptance criteria for the demo. STRETCH pages may ship as the "minimal" variant described.
- Every page has an `<h1>` (visually styled via `PageHeader`), a skip link target (`#main`), a document `<title>` ("Map · HawaCommand") and strings in both locales.

## 2. Route map, console shell, command palette

### 2.1 Route map

| Route | Roles | Tier | Features | Section |
|---|---|---|---|---|
| `/console/login` | P | BUILD | auth | [3.1](#31-consolelogin) |
| `/console` | O An Ad | BUILD | redirect → `/console/map` | — |
| `/console/map` | O An Ad | BUILD | F1 F2 F4 F5 F7 F11 F12 F17 | [3.2](#32-consolemap) |
| `/console/hotspots`, `/console/hotspots/[id]` | O An Ad | BUILD | F7 F12 | [3.3](#33-consolehotspots-and-consolehotspotsid) |
| `/console/forecast` | O An Ad | BUILD | F5 F6 F12 | [3.4](#34-consoleforecast) |
| `/console/grap` | O An Ad | BUILD | F6 | [3.5](#35-consolegrap) |
| `/console/plans` | O (An Ad R) | BUILD | F13 F14 | [3.6](#36-consoleplans) |
| `/console/plans/[id]` | O (An Ad R) | BUILD | F13 F14 F16 F17 | [3.7](#37-consoleplansid) |
| `/console/what-if` | O (An Ad R) | BUILD | F13 F12 | [3.8](#38-consolewhat-if) |
| `/console/fleet` | O An Ad | BUILD | F2 F17 | [3.9](#39-consolefleet) |
| `/console/interventions`, `/console/interventions/[id]` | O An Ad | BUILD | F17 F18 | [3.10](#310-consoleinterventions-and-consoleinterventionsid) |
| `/console/impact` | O An Ad | BUILD | F18 | [3.11](#311-consoleimpact) |
| `/console/alerts` | O Ad (An R) | BUILD list / STRETCH compose | F16 | [3.12](#312-consolealerts) |
| `/console/schools`, `/console/schools/[id]` | O An Ad | STRETCH | F19 | [3.13](#313-consoleschools-and-consoleschoolsid) |
| `/console/reports` | O An Ad | STRETCH | F20 | [3.14](#314-consolereports) |
| `/console/inspections` | O (An Ad R) | STRETCH | F20 F7 | [3.15](#315-consoleinspections) |
| `/console/sites` | O An Ad | STRETCH | F9 | [3.16](#316-consolesites) |
| `/console/devices`, `/console/devices/[id]` | An Ad (O R) | STRETCH | F3 F2 | [3.17](#317-consoledevices-and-consoledevicesid) |
| `/console/integrity` | O An Ad | STRETCH | F15 | [3.18](#318-consoleintegrity) |
| `/console/coverage` | O An Ad | STRETCH | F11 | [3.19](#319-consolecoverage) |
| `/console/evidence` | O An Ad | STRETCH | F22 | [3.20](#320-consoleevidence) |
| `/console/admin`, `/console/admin/models` | Ad | STRETCH | — | [3.21](#321-consoleadmin) |
| `/open`, `/open/api`, `/open/methods` | P | STRETCH | F21 | [4](#4-open-data-portal) |
| `/open/reports/[code]` | P | STRETCH | F20 | [4.4](#44-openreportscode) |
| `/` | P | BUILD (demo scenes) | pitch | [5](#5-marketing-site-) |

### 2.2 Console shell

```
┌──────────────────────────────────────────────────────────────────────────────────────────────┐
│ [≡] HawaCommand   Ward: [ward-084 ▾]   ● Live   Twin 06:45 IST · 7 min   [Ctrl K]  EN|हि  ◐  MP▾ │  TopBar
├──────────────────────────────────────────────────────────────────────────────────────────────┤
│ ⚑ Plan awaiting approval · Master plan ward-084 for Thu 05:30 · 14 tasks · approve by 05:00 [Open]│  PendingPlanBanner
│ ⓘ Demo environment: device fleet simulated in the real packet format; pipeline and models are real│  DemoBanner
├───────────┬──────────────────────────────────────────────────────────────────────────────────┤
│ OPERATE   │                                                                                  │
│  Map      │                                <main id="main">                                  │
│  Hotspots │                                                                                  │
│  Forecast │                                                                                  │
│  GRAP     │                                                                                  │
│  Plans  ③ │                                                                                  │
│  What-If  │                                                                                  │
│  Fleet    │                                                                                  │
│ VERIFY    │                                                                                  │
│  Interventions                                                                               │
│  Impact   │                                                                                  │
│ PROTECT   │                                                                                  │
│  Alerts · Schools · Reports · Inspections                                                    │
│ DATA      │                                                                                  │
│  Sites · Devices · Integrity · Coverage · Evidence                                           │
│ ADMIN (Ad)│                                                                                  │
└───────────┴──────────────────────────────────────────────────────────────────────────────────┘
```

| Component | Props | Notes |
|---|---|---|
| `ConsoleShell` | `user: SessionUser`, `children` | Server layout passes the session; client parts hydrate |
| `AppSidebar` | `role: UserRole`, `counts?: {draftPlans: number, openReports: number}` | Role-filtered via `canAccessRoute`. Collapsible to icons. `aria-current="page"` |
| `TopBar` | `wardIds: WardId[]` | `WardSelect`, `LiveStatusDot`, twin as-of chip (`useTwinMeta` + `useStaleness`), language, theme, `UserMenu` |
| `PendingPlanBanner` | none (reads `GET /v1/plans?status=draft&ward=`) | WS `plans:{ward}` (proposed), poll 30 s fallback. Hidden for analysts and admins (text says "awaiting officer approval"). Spike plans use danger styling and a countdown |
| `DemoBanner` | `variant: "demo" \| "recorded"` | `NEXT_PUBLIC_DEMO_BANNER`. `recorded` cannot be dismissed |

The shell mounts `<WsProvider>` (one socket), `<CommandPalette>` and `<KeyboardShortcuts>`. Page-level `useChannel` calls add their channels.

### 2.3 Command palette (Ctrl/Cmd+K)

| Group | Items | Source |
|---|---|---|
| Navigate | every route the role can access | `roles.ts` |
| Jump to ID | typing `g500-041-077`, `g1k-020-038`, `AST-SPR-0012`, `HPM-0142`, `HTG-0031`, `ward-084`, `SITE-0311`, `SCH-…` or a UUID opens the matching entity | regex patterns from CONTRACTS §2 (`src/lib/format/ids.ts`) |
| Hotspots | top 10 in the current ward ("#1 g500-041-077 · Dust") | cached `qk.hotspots.list` |
| Plans | drafts and today's plans | cached `qk.plans.list` |
| Actions | Draft plan for ward (O), Toggle layer…, Switch to Forecast +24 h, Language हिन्दी/English, Theme, Copy link to current view, Keyboard shortcuts | local |

Acceptance: opens with Ctrl/Cmd+K from any console page and closes with Esc; fully keyboard- and screen-reader-operable (cmdk + Radix Dialog); an ID jump works for every pattern above; Hindi labels are searchable in `/hi`.

### 2.4 Common states (all pages)

| State | Rule |
|---|---|
| L | Skeletons that match the layout. The map shows the basemap immediately |
| E | `EmptyState` with the reason and the last check time |
| X | `ProblemAlert` inline, or the route `error.tsx`. 403 renders inline, never as a toast |
| S | `StaleDataBanner` per the thresholds in [ARCHITECTURE §14](ARCHITECTURE.md#14-loading-empty-and-stale-states) |
| Sim | `SimulatedBadge` on the entity. The "Includes simulated data" chip on derived views |
| Off | `LiveStatusDot` shows Reconnecting or Polling. Pages keep working on polling |

---

## 3. Console pages

### 3.1 `/console/login`

**Roles:** public · **Tier:** BUILD · **Purpose:** sign in officers, analysts and admins, and restore sessions silently.

**Data:** `POST /api/auth/login` (→ `POST /v1/auth/login`). On mount, `POST /api/auth/refresh` for session restore.

```
┌──────────────────────────────────────────┐
│  HawaCommand                    EN | हि   │
│  Officer console                          │
│  Email      [______________________]      │
│  Password   [________________] [Show]     │
│  [ Sign in ]                              │
│  Field staff, schools and citizens:       │
│  use the HawaCommand app.                 │
│  ⓘ Demo environment · simulated fleet     │
└──────────────────────────────────────────┘
```

**Components:** `LoginForm { next?: string }` (react-hook-form + Zod: email, password min 8).

**Interactions:** Enter submits. Paste and password managers are allowed (`autocomplete="username"` / `"current-password"`, WCAG 3.3.8). On success, `router.replace(next ?? "/console/map")`.

**States:** L (button "Signing in…"); X: 401 → "Email or password is incorrect"; 429 → "Too many attempts. Try again in {n} min" (`Retry-After`); 403 `use_mobile_app` → "This account is for the HawaCommand app"; network → retry message.

**Acceptance:** a valid officer lands on the map with their ward in ≤ 2 s on the mock API; an expired access token with a valid refresh cookie never shows the form (auto-redirect); no token appears in `localStorage`/`sessionStorage` (e2e assertion); the page passes axe.

---

### 3.2 `/console/map`

**Roles:** O An Ad · **Tier:** BUILD · **Features:** F1 F2 F4 F5 F7 F11 F12 F17 · **Demo:** 0:20–0:50.

**Purpose:** see the city street by street right now. Hotspots appear with cause, confidence, upwind suspect and back-trajectory. Moving sensors and the machine fleet are shown live.

**Data (REST):**
| Purpose | Endpoint |
|---|---|
| Twin metadata | `GET /v1/twin/latest` (proposed); fallback `GET /v1/twin?bbox=&ts=` response metadata |
| Twin tiles | `GET /v1/twin/tiles/{z}/{x}/{y}.mvt?ts={as_of}&v={tile_version}` (`v` proposed) |
| Scrubber steps | `GET /v1/twin/runs?from=&to=` (proposed) |
| Hotspots | `GET /v1/hotspots?ward={ward}&limit=20`; `GET /v1/hotspots/{id}` for trajectory/evidence |
| Cell drawer | `GET /v1/cells/{cell_id}`, `GET /v1/cells/{cell_id}/history?from=&to=` (24 h), `GET /v1/forecast/{g1k_cell_id}` |
| Forecast mode | `GET /v1/forecast/grid?horizon_h={h}&issued_at=latest` |
| Fleet | `GET /v1/fleet/live`; trails `GET /v1/fleet/trails?minutes=30&kind=vehicle` (proposed) |
| POIs, wards | `GET /v1/pois?bbox=&kind=school,hospital,elder_care` (proposed), `GET /v1/wards?format=geojson` (proposed) |
| Blind spots | `GET /v1/coverage/blind-spots` |

**WebSocket:** `twin`, `hotspots:{ward}`, `fleet`.

```
┌──────────────────────────────────────────────────────────────────────┬──────────────────────────┐
│ [PM2.5 ▾] [● Now | Forecast] [Layers ▾ 8/11] [🔍 cell, asset, place] │ HOTSPOTS · ward-084 (12)  │
│ [Lite] [⛶]                           Includes simulated data (Sim)   │ Ranked by people exposed  │
├──────────────────────────────────────────────────────────────────────┤ ┌──────────────────────┐ │
│                                                                      │ │1 g500-041-077  [342] │ │
│        ░▒▓ twin cells (fill = AQI band, opacity = confidence)         │ │ ◆ Dust · 78 %        │ │
│          ╱╱ hatched = low confidence                                  │ │ 18.4k ph (12.9–23.1k)│ │
│    ═══> pod trails (animated)     ▲ fleet (heading)  📍 suspect pin   │ │ Conf ▮▮▮▮▯ High      │ │
│    ┄┄┄ back-trajectory            🏫 schools  ✚ hospitals             │ └──────────────────────┘ │
│                                                                      │ 2 g500-043-080  [318] … │
│                                              ┌─ Legend ────────────┐ │ 3 g500-039-075  [301] … │
│                                              │ AQI (indicative)     │ │ …                        │
│                                              │ ■ Good 0–50          │ │ "#2 and #3 overlap       │
│                                              │ ■ Satisfactory 51–100│ │  within uncertainty"     │
│                                              │ ■ Moderate 101–200 … │ │                          │
│                                              │ Confidence ▯▯▮▮ ╱╱low│ │                          │
│                                              │ ◆ Dust ▲ Traffic …   │ │                          │
│                                              └──────────────────────┘ │                          │
├──────────────────────────────────────────────────────────────────────┤                          │
│ ◀ [‖] ──────────────●──────── ▶   Thu 13 Nov 06:45 IST   [Go live]   │                          │
│ 07:00 yesterday                              now                     │                          │
└──────────────────────────────────────────────────────────────────────┴──────────────────────────┘
```

On selection, the right rail is replaced by the **Cell drawer** (Sheet, 400 px):

```
┌──────────────────────────────── g500-041-077 · ward-084 ─ [×] ┐
│ [AQI 342 · Very poor]  range 318–367 · indicative              │
│ PM2.5  164 µg/m³ (80 %: 137–191)                               │
│ PM10   271 µg/m³ (80 %: 220–322)                               │
│ Confidence ▮▮▮▮▯ 0.72 High · 7 readings (5 simulated, 2 ref)   │
│ Cause  ◆ Dust · 78 %   Suspect: 420 m NW (construction site)   │
│ Exposure 2,140 person-hours above safe (80 %: 1,500–2,800)     │
│ Nearby: 🏫 2 schools · ✚ 1 hospital                            │
│ ─ Next 24 h (1 km forecast g1k-020-038) ─────────────────────  │
│   ▁▂▃▅▇█▇▅  P10–P90 band, P50 line, now marker                │
│ ─ Last 24 h ─ sparkline with band                              │
│ [Open forecast] [Open hotspot #1] [Request inspection (O)]     │
└────────────────────────────────────────────────────────────────┘
```

**Key components:**

| Component | Props | Behaviour |
|---|---|---|
| `MapWorkspace` | `initial: {ward, cell?, hotspot?, mode, h?, ts?, layers?}` (from searchParams) | Owns queries and URL sync. Lays out toolbar, canvas, rail and drawer |
| `MapToolbar` | `pollutant`, `mode`, `onChange…` | Pollutant `pm25 \| pm10 \| aqi`; mode Now/Forecast; Layers popover; search (cell ID, asset ID, hotspot rank, POI name); Lite; fullscreen |
| `LayerToggles` | `layers: {id, label, count, visible, disabled?}[]` | Switch per layer; counts ("Fleet 142"); blind spots off by default |
| `MapLegend` | `pollutant`, `palette: "cpcb" \| "cvd"`, `mode` | Band swatches with **name + range**; confidence ramp + hatch sample; cause glyphs; symbol key (trail, trajectory, pin, fleet status, simulated ring); palette toggle; collapsible |
| `TimeScrubber` | `mode`, `runs: TwinRun[]`, `value`, `live: boolean`, `onChange` | Now: 15-min steps over 24 h plus a Live button. Forecast: +1…+72 h with day ticks. Keys ←/→ step, Home/End, Space play/pause (2 steps/s; off under reduced motion). `aria-valuetext` "06:45 IST, 15 minutes ago" |
| `HotspotRail` | `hotspots: Hotspot[]`, `selectedId?`, `onSelect` | Ranked by exposure P50; overlap flag; each card focusable; Enter flies to the hotspot and opens its trajectory |
| `HotspotCard` | `hotspot`, `rank`, `compact?` | `AqiChip`, `CauseBadge`, `UncertaintyValue` (exposure), `ConfidenceMeter`, `SimulatedBadge` if `sim_share > 0` |
| `CellDrawer` | `cellId`, `onClose` | Loads cell, history and forecast in parallel. Each section has its own skeleton and error |
| `MapTooltip` | `pick: PickInfo \| null` | Cell: id, AQI chip, PM with range, confidence word. Fleet: asset label, status, speed, last seen, Simulated. Pin: cause + distance |
| `MapA11ySummary` | `meta`, `hotspots` | Polite live text such as "Twin updated 06:45 IST. 12 hotspots in ward-084. Worst: …". Throttled to one per 30 s. **Cell cursor:** with the map focused, press C, then arrows move by one cell, Enter opens the drawer, Esc exits |

**Interactions:**
- Click a cell → drawer and `?cell=`. Click a hotspot outline or card → selection, trajectory and `?hotspot=`. Click a fleet icon → asset sheet. Click a POI → name and forecast peak.
- Hover shows the tooltip within 100 ms (rAF-throttled).
- Keyboard: arrows pan, `+`/`-` zoom (MapLibre and deck controllers with `keyboard: true`), and C for the cell cursor. Single-key shortcuts work only while the map has focus (WCAG 2.1.4).
- WS `hotspot.updated` → new hotspots pulse once (not under reduced motion) and a live-region announcement plays.
- Forecast mode: the horizon slider swaps the layer. POI halos mark schools in cells where P50 PM2.5 > 250 µg/m³ during school hours (CONTRACTS §10.3 school trigger).

**States:** L (basemap first, layers fade in); E ("No hotspots: all cells below threshold at 06:45 IST"); X (tile errors → toast once, then keep the last good tiles; hotspot errors show inline in the rail); S (as-of chip amber > 20 min, red > 60 min, with the banner "Twin is 22 min old"); Sim (chip "Includes simulated data" when any `sim_share > 0`; violet rings on simulated fleet); Off (Polling chip; twin meta polled every 60 s); no WebGL2 → `WebGLFallback`.

**Acceptance:**
1. With the golden-path mock, the twin, trails, fleet, 12 hotspot outlines, 3 trajectories and suspect pins render. `window.__hawa.map.layers()` reports ≥ 8 visible layers with feature counts > 0.
2. A `twin.updated` WS message changes the tile URL `v` and the as-of chip within 2 s, with no page reload.
3. Cell drawer values show a range and a level ("80 %"), AQI shows "indicative", and confidence shows a word plus a number.
4. Pan and zoom hold ≥ 50 fps on the reference machine with all BUILD layers on (manual check, recorded before the demo).
5. Legend has category names and ranges. The CVD palette toggle recolours the map without refetching.
6. The keyboard-only path (Tab to rail → Enter → drawer → Esc) works, and axe reports no violations outside the canvas.

---

### 3.3 `/console/hotspots` and `/console/hotspots/[id]`

**Roles:** O An Ad · **Tier:** BUILD · **Features:** F7 F12 · **Purpose:** hotspots ranked by people exposed, not by AQI (§2.5), with the evidence behind each one.

**Data:** `GET /v1/hotspots?ward=&limit=`; `GET /v1/hotspots/{id}` (evidence + back-trajectory); `GET /v1/cells/{cell_id}` for member cells. **WS:** `hotspots:{ward}`.

```
List                                                         Detail
┌───────────────────────────────────────────────────────┐   ┌──────────────────────────────────────────────┐
│ Hotspots · ward-084 · twin 06:45 IST      [Map view]   │   │ #1 Hotspot · 4 cells · ward-084  [Sim data]   │
│ Rank│Cells│Cause      │AQI│Exposure (80 %)   │Conf│Near│   │ ◆ Dust 78 %  Suspect: 420 m NW (site)        │
│ 1   │ 4   │◆ Dust 78% │342│18.4k (12.9–23.1k)│Hi  │🏫2 │   │ Exposure 18.4k ph (12.9–23.1k) · AQI 342     │
│ 2   │ 2   │▲ Traffic  │318│ 9.1k (6.0–12.2k) │Med │✚1  │   │ [mini map: cells + trajectory + pin]         │
│ …   │     │           │   │ overlap ⟂ #3     │    │    │   │ Evidence                                     │
└───────────────────────────────────────────────────────┘   │  • HPM-0142 spike PM2.5 ×3.2 06:42 (Sim)     │
                                                            │  • Citizen report 06:44 (verified)           │
                                                            │  • REF-CPCB-site_301 PM2.5 188               │
                                                            │ Right action for dust: sprinkler, sweeper,   │
                                                            │ site check (from fingerprint table §9.4)     │
                                                            │ [Add to draft plan (O)] [Request inspection] │
                                                            └──────────────────────────────────────────────┘
```

**Components:** `HotspotTable { hotspots, onRowClick }` (TanStack Table; default sort by exposure P50, which the user may change; an overlap column); `HotspotDetail { hotspot }`; `EvidenceList { items: Evidence[] }` (kind icon, time IST, source, Simulated); `CauseActionHint { cause }` (static text from the §9.4 fingerprint table, localised).

**Interactions:** row → detail. "Add to draft plan" opens the plan with `add` prefilled (officer, when a draft exists). "Request inspection" → `POST /v1/inspections` (proposed); the button is hidden when the endpoint is unavailable.

**States:** L/E/X/S (twin staleness applies); Sim (`sim_share`).

**Acceptance:** ranking is by exposure, never by AQI, and the column header says so; every row shows a cause with confidence and an exposure range; the detail shows the trajectory and at least one evidence item for the demo hotspot; the right-action hint matches the cause (regional smoke → "No machines; protect people").

---

### 3.4 `/console/forecast`

**Roles:** O An Ad · **Tier:** BUILD · **Features:** F5 F6 F12 · **Demo:** 0:50–1:20.

**Purpose:** the 72 h outlook per cell with uncertainty, where the spike will hit people, and the GRAP stage coming.

**Data:** `GET /v1/forecast/{cell_id}` (1 km cell); `GET /v1/forecast/grid?horizon_h=&issued_at=`; `GET /v1/grap/outlook?ward=&days=3`; `GET /v1/pois?bbox=&kind=school,hospital` (proposed) for vulnerable places. **WS:** `forecast` (proposed); otherwise refetch every 15 min.

```
┌───────────────────────────────────────────────────────────────────────────────────────────┐
│ Forecast · ward-084 · issued 06:05 IST (P10/P50/P90)          GRAP: [Today 0] [Wed I 64%] [Thu I 72%]│
├───────────────────────────────────────────┬───────────────────────────────────────────────┤
│ Forecast map  +24 h  [──────●────────] 72h │ Cell g1k-020-038 (contains g500-041-077)       │
│  (1 km cells, P50 band; hatched = P90     │  PM2.5 µg/m³                                   │
│   in a worse band)                         │ 300┤          ┌──school hrs──┐                 │
│  🏫 3 schools highlighted in spike         │ 250┤- - - - - │- - ░░▓▓▓░░ - │- - severe line  │
│                                            │ 200┤     ▁▂▃▅▇│█▇▅▃░░        │                 │
│                                            │ 120┤──obs──┆now             │                 │
│                                            │    └ −24h ─┴── +24h ── +48h ── +72h (IST)      │
│                                            │ P50 212 (P10 168 – P90 281) at Thu 08:00       │
├───────────────────────────────────────────┴───────────────────────────────────────────────┤
│ Vulnerable places in the spike (P50 PM2.5 > 250 in school hours): 3 schools · 1 hospital   │
│  🏫 GBSSS No. 2 (SCH-…) peak Thu 08:00 P50 262 (P90 301)  alert: planned 19:00 [View]        │
└───────────────────────────────────────────────────────────────────────────────────────────┘
```

**FanChart spec** (`<FanChart series observed now grapLines schoolHours />`):

| Element | Spec |
|---|---|
| X axis | Time in IST, −24 h (observed twin history for the cell's 1 km parent) to +72 h. Major ticks every 12 h (`EEE HH:mm`), minor every 3 h. The axis title names the date range |
| Y axis | Concentration of the selected pollutant (µg/m³), domain `[0, max(P90, obs) × 1.1]`, gridlines at CPCB band edges (PM2.5: 30, 60, 90, 120, 250) |
| Band | P10–P90 `Area` range, series colour at 22 % opacity. **Always rendered** |
| P50 | 2 px solid line, series colour |
| Observed | 2 px solid ink line up to "now". Twin 80 % range shown as a thin band |
| Now | Vertical `ReferenceLine` labelled "now 06:45" |
| AQI context | Faint background `ReferenceArea` per CPCB band (8 % opacity, band colour) with right-edge labels. Thresholds of 250 (school trigger) and GRAP edges are dashed |
| School hours | `ReferenceArea` 08:00–14:00 IST each day, hatched neutral, labelled "School hours" |
| Tooltip | Time IST, P10 / P50 / P90, category of P50 ("very poor"), GRAP stage implied |
| Summary (sr) | "Forecast for g1k-020-038: P50 peaks at 262 µg/m³ on Thu 08:00 (P10 205, P90 301), above the school alert threshold during school hours." |

**Components:** `FanChart` (above); `HorizonSlider { value, onChange }`; `ForecastMap` (map layers `forecast-grid`, `pois`, `ward-boundaries` only); `VulnerablePlacesList { places: {poi, peak: Quantiles, at, alert_status}[] }`; `GrapOutlookStrip { days: GrapDay[] }`.

**Interactions:** click a cell on the forecast map → chart updates and `?cell=`; the horizon slider syncs with the chart crosshair; clicking a school opens `/console/schools/[id]`; clicking a GRAP pill opens `/console/grap?day=`.

**States:** S (forecast > 75 min amber); E (no forecast issued yet: "Next forecast at :05"); X.

**Acceptance:** the band is present on every forecast chart and cannot be disabled; P10/P50/P90 appear in the tooltip and the summary; the golden-path seed shows 3 schools in the spike and a Thursday pill in the `poor` fill labelled "Stage I" with its probability; horizon changes do not refetch the chart; the chart has a table view.

---

### 3.5 `/console/grap`

**Roles:** O An Ad · **Tier:** BUILD · **Feature:** F6 · **Purpose:** act before GRAP is formally invoked (§6 F6). Shows a 3-day stage outlook with probability and a ward checklist of stage actions.

**Data:** `GET /v1/grap/outlook?ward=&days=3`; `GET /v1/grap/checklist?ward=&stage=`. Optional tick persistence: `PUT /v1/grap/checklist/{ward_id}/{date}/items/{item_id}` (proposed).

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ GRAP Copilot · ward-084                                  [Print checklist]   │
│ ┌─Today──────┐ ┌─Wed 12 Nov─────┐ ┌─Thu 13 Nov──────────┐                     │
│ │ Stage 0    │ │ Stage I  64 %  │ │ Stage I   72 %      │                     │
│ │ none       │ │ II: 12 %       │ │ II: 18 % (P90 >300) │                     │
│ └────────────┘ └────────────────┘ └─────────────────────┘                     │
│ Checklist for Stage I · Thu (start before formal invocation)                 │
│ MCD      ☐ Mechanised sweeping on listed roads before 07:00                  │
│ DPCC     ☐ Dust-control checks at C-grade sites                              │
│ Traffic  ☐ …                                                                 │
│ Source: config grap_actions.yaml (not model output)                          │
└─────────────────────────────────────────────────────────────────────────────┘
```

**Components:** `GrapOutlookStrip`; `GrapStagePill { stage, probability?, size }`; `GrapChecklist { items: {item_id, agency, text_en, text_hi}[], ticks?, onTick? }`.

**Acceptance:** each day shows the stage with a label and number, never colour alone, plus the probability; the checklist text is noted as coming from config; the page prints cleanly (print CSS); without the persistence endpoint, ticks are local and labelled "not saved".

---

### 3.6 `/console/plans`

**Roles:** O (An Ad read) · **Tier:** BUILD · **Features:** F13 F14 · **Purpose:** list plans and start a draft.

**Data:** `GET /v1/plans?status=&ward=`; `POST /v1/plans/draft` → `202 {plan_id, status: "drafting"}`. **WS:** `plans:{ward}` (proposed); `plan:{id}` for rows in `drafting`.

```
┌──────────────────────────────────────────────────────────────────────────────────────┐
│ Plans · ward-084        [Status: all ▾] [Mode ▾] [Date ▾]            [+ Draft plan (O)]│
│ Status      │Mode  │Window (IST)         │Tasks│Exposure avoided (80 %)│Auditor      │  │
│ Draft v2    │master│Thu 05:30–11:00      │ 14  │18.4k (12.9–23.1k)     │1 open ⛔     │▸ │
│ Drafting…   │replan│Wed 11:00–14:00      │  —  │ —                     │ —           │▸ │
│ In progress │master│Wed 05:30–11:00      │ 12  │15.2k (10.8–19.9k)     │resolved     │▸ │
│ Expired     │spike │Tue 06:45–07:30      │  1  │ 410 (220–610)         │ —           │▸ │
└──────────────────────────────────────────────────────────────────────────────────────┘
```

**Components:** `PlanList { plans }`; `DraftPlanDialog { wardIds, onSubmit }` (fields: wards, window start/end with IST pickers, optional asset subset; mode `manual`).

**Interactions:** "Draft plan" → 202 → navigate to `/console/plans/{plan_id}`, which shows the drafting state. Rows open the detail. Filters live in the URL.

**Acceptance:** the drafting row updates to Draft via WS without a reload; exposure always shows a range; expired, failed and rejected rows are visually muted with a label; analysts see no Draft button.

---

### 3.7 `/console/plans/[id]`

**Roles:** O (edit, approve, reject); An Ad read-only · **Tier:** BUILD (the core page) · **Features:** F13 F14 F16 F17 · **Demo:** 1:20–2:45.

**Purpose:** read the AI plan and understand why each task exists. Weigh the Auditor's objections, compare against the usual routes, adjust, and approve in one deliberate decision. Then watch the plan execute.

**Data:**
| Purpose | Endpoint |
|---|---|
| Plan | `GET /v1/plans/{id}` (includes tasks, `review`, `version`, `correlation_id` (proposed)) |
| Previous versions (diff) | `GET /v1/plans/{id}/versions`, `GET /v1/plans/{id}?version=1` (proposed) |
| What-If | `GET /v1/plans/{id}/simulation?version=` (proposed, cached) else `POST /v1/plans/{id}/simulate` |
| Edit | `PATCH /v1/plans/{id}` with `If-Match` (ops body proposed) |
| Re-optimise | `POST /v1/plans/{id}/reoptimize` (proposed) |
| Approve / reject | `POST /v1/plans/{id}/approve`, `POST /v1/plans/{id}/reject` (Idempotency-Key) |
| Asset picker | `GET /v1/assets` (filtered client-side by type, status and shift) |

**WebSocket:** `plan:{id}` (plan + task lifecycle), `fleet` (mini map in live mode), `impact` (verified tasks).

**Expected shapes (illustrative):**

```ts
type Quantiles = { p10: number; p50: number; p90: number };
interface PlanDetail {
  plan_id: string; version: number; status: PlanStatus; mode: PlanMode; ward_ids: WardId[];
  window_start: string; window_end: string; dispatch_at: string; expires_at: string | null;
  created_by_agent: string; created_at: string; approved_by: string | null; approved_at: string | null;
  correlation_id: string; is_simulated: boolean; simulated_asset_count: number;
  expected_exposure_avoided_ph: Quantiles; baseline_exposure_avoided_ph: Quantiles;   // proposed quantiles (conflict C1)
  tasks: PlanTask[];
  review: { planner_rationale: string; auditor_verdict: "approve" | "approve_with_changes" | "reject"; objections: Objection[] };
  alerts_planned: { audience: AlertAudience; kind: AlertKind; channels: AlertChannel[]; recipients: number; langs: ("en" | "hi")[] }[];
}
interface PlanTask {
  task_id: string; order: number; kind: TaskKind; asset_id: string; asset_type: AssetType; asset_label: string;
  cell_id: string; hotspot_id: string | null; cause_label: CauseLabel; cause_conf: number;
  eta_start: string; eta_end: string; reason_text: string; reason_text_hi?: string;
  expected_effect: { pollutant: Pollutant; effect_pct: number; ci_low: number; ci_high: number; n: number; source: "library" | "prior" };
  expected_exposure_avoided_ph: Quantiles; status: TaskStatus; status_ts: string;
  added_by: "optimizer" | "officer"; locked: boolean; is_simulated: boolean; intervention_id: string | null;
}
interface Objection {
  objection_id: string; severity: "blocking" | "warning" | "info"; source: "auditor_agent" | "rules";
  task_id: string | null; rule: string | null; text: string; suggested_change: PatchOp | null;
  resolution: { status: "open" | "auto_applied" | "accepted" | "overridden"; by: string | null; note: string | null; at: string | null };
}
type PatchOp =
  | { op: "move"; task_id: string; to_index: number }
  | { op: "reassign"; task_id: string; asset_id: string }
  | { op: "retime"; task_id: string; eta_start: string; eta_end: string }
  | { op: "remove"; task_id: string; reason: string }
  | { op: "add"; cell_id: string; kind: TaskKind; asset_id: string; eta_start: string; eta_end: string; reason: string }
  | { op: "resolve_objection"; objection_id: string; resolution: "accepted" | "overridden"; note?: string }
  | { op: "lock"; task_id: string; locked: boolean };
```

#### 3.7.1 Layout (draft state)

```
┌────────────────────────────────────────────────────────────────────────────────────────────────┐
│ Plans › Master plan · ward-084 · Thu 13 Nov 05:30–11:00 IST          [Draft v2] [Simulated 9/9]  │
│ Drafted by Planner 18:34 · edited by you 19:52 · Auditor: approve with changes · expires 05:00 │
├──────────────────────────────────────────────────────┬─────────────────────────────────────────┤
│ TASKS (14) · 9 assets      [Show changes vs AI draft]│ AUDITOR · 2 objections (1 open)          │
│ ┌ AST-SPR-0012 · Sprinkler · Depot Karol Bagh (Sim) ┐│ ┌──────────────────────────────────────┐│
│ │ ⠿ 1  06:00–06:30  g500-041-077  ◆ Dust 78 %       ││ │ ⛔ BLOCKING · Task 7 · rule cause_asset ││
│ │     Why: PM10 forecast 402 at 07:00 beside two     ││ │ "Sprinkler AST-SPR-0019 is sent to    ││
│ │     schools; water suppresses road dust here        ││ │ hotspot #3, likely open burning. Water││
│ │     (library −14 %, 95 % CI −22 to −6, n=31).       ││ │ does not reduce smoke."               ││
│ │     Expected −2,140 ph (80 %: −3,100 to −1,200)     ││ │ Suggest: replace with inspection team ││
│ │     [↑][↓] [Reassign] [Retime] [Remove]    pending ││ │ AST-TEAM-0004 (06:15–07:00)           ││
│ │ ⠿ 2  06:35–07:05  g500-042-077  ◆ Dust 71 %  …     ││ │ [Apply suggestion] [Override…]        ││
│ └────────────────────────────────────────────────────┘│ └──────────────────────────────────────┘│
│ ┌ AST-TEAM-0004 · Inspection team ─────────────────┐ │ ✔ Warning · Task 3 · resolved (auto)    │
│ │ ⠿ 1  06:15–07:00  g500-039-075  🔥 Burning 83 %   │ │  "Window ends after forecast peak";     │
│ └───────────────────────────────────────────────────┘ │  optimiser moved it 20 min earlier (v1→v2)│
│ [+ Add task]                                          │ PLANNER RATIONALE                        │
│                                                       │  "Prioritised the 3 cells within 500 m  │
│                                                       │  of GBSSS No. 2 and the hospital…" [More]│
│                                                       │ WHAT-IF (v2)                             │
│                                                       │  AI plan   18,450 ph (12,900–23,100)     │
│                                                       │  Usual     7,120 ph (5,000–9,300)        │
│                                                       │  Δ +11,330 (6,800–15,200)  [Open What-If]│
├───────────────────────────────────────────────────────┴─────────────────────────────────────────┤
│ 18,450 person-hours avoided (80 %: 12,900–23,100) · 14 tasks · 9 assets · 3 alerts · dispatch 05:30│
│ ⛔ 1 blocking objection open                              [Reject]  [Edit]  [Approve ▸ (disabled)] │
└──────────────────────────────────────────────────────────────────────────────────────────────────┘
```

Right column width is 420 px. Below 1280 px the right column collapses into tabs (Tasks | Auditor | What-If) above the ApproveBar.

#### 3.7.2 Drafting state

`status: drafting` → `AgentProgress` replaces the task list: "Exposure scoring → Optimiser (OR-Tools) → Planner explains → Auditor challenges → Communicator drafts alerts". Steps advance on `plan.progress` (proposed, W6). Without it, the view shows an indeterminate bar with elapsed time. `plan.drafted` arrives → content fades in and a toast reads "Plan ready for review". `plan.failed` → error panel with `detail` and "Draft again".

#### 3.7.3 Components

| Component | Props | Notes |
|---|---|---|
| `PlanHeader` | `plan` | Status pill (label + icon), mode, window IST, version, author, `expires_at` countdown, `SimulatedBadge` with count |
| `PlanTaskList` | `tasks`, `editable: boolean`, `pendingOps: Set<string>`, `diff?: PlanDiff` | Grouped by asset route in `order`. Drag handle **plus** ↑/↓ buttons (WCAG 2.5.7). Virtualised > 50 tasks |
| `PlanTaskCard` | `task`, `editable`, `pending`, `diffState?: "added" \| "removed" \| "changed"`, `onOp(op)` | Always shows the time window, cell, `CauseBadge`, **`reason_text` in full** (clamped at 4 lines with "More"), expected effect with CI and n, expected exposure range, status chip, Simulated. Agent text renders as plain text with `lang="en"` when no Hindi version exists |
| `TaskEditor` | `task`, `op: "reassign" \| "retime" \| "remove"`, `assets`, `plan` | Popover forms (RHF + Zod). Remove requires a reason |
| `AssetPicker` | `cause`, `window`, `assets`, `value`, `onChange` | Shows only cause-compatible types (CONTRACTS §3 cause → asset map). Incompatible types are listed disabled with the reason ("Water does not reduce smoke"). Availability comes from shift and status |
| `AuditorPanel` | `objections`, `onResolve` | Sorted open-blocking first. Counts by status. Filter |
| `AuditorComment` | `objection`, `taskLabel`, `canResolve`, `onApply()`, `onOverride(note)` | Severity icon + word (⛔ Blocking / ⚠ Warning / ⓘ Info), source ("Auditor agent" or "Rule check"), text, suggestion rendered as a human-readable op, resolution line with who and when. Override needs a note of ≥ 10 characters |
| `PlannerRationale` | `text` | Plain text, 6 lines then "More" |
| `PlanDiff` | `from: PlanDetail`, `to: PlanDetail` | Client-computed by `task_id`: added, removed (collapsed group), changed fields (asset, window, order), exposure delta with range. Author per change |
| `WhatIfSummaryCard` | `simulation?`, `version`, `stale: boolean` | Three `UncertaintyValue` rows. "Updating…" while re-simulating. Link to `/console/what-if?plan=` |
| `ApproveBar` | `plan`, `simulation`, `pendingOps`, `role` | Sticky bottom. See §3.7.5 |
| `ApproveDialog` | `plan`, `simulation`, `onConfirm` | See §3.7.6 |
| `RejectDialog` | `onConfirm(reason)` | Reason ≥ 10 characters |
| `ConflictDialog` | `mine: PlanDetail`, `server: PlanDetail` | 409 handling. Shows the diff and "Reload plan" |
| `LiveTaskStatus` | `plan` | Replaces the edit affordances once approved. See §3.7.7 |

#### 3.7.4 Edit mode (officer, `status: draft`)

| Operation | UI | PATCH op | Client-side check (server is authoritative) | Optimistic effect |
|---|---|---|---|---|
| Reorder | Drag handle or ↑/↓ | `move` | Same route only | Reorder in cache; card shows "pending" |
| Reassign asset | `AssetPicker` | `reassign` | Cause → asset compatibility; asset shift covers the window | Swap the asset label; exposure shows "recomputing" |
| Retime | Time-window picker (IST, 5-min steps) | `retime` | Inside the plan window; warn when the end is after the forecast peak | Update the window |
| Remove | Remove + reason | `remove` | Reason required | Move to the "Removed (n)" group |
| Add | "+ Add task" → pick hotspot/cell (from the list or `?cell=`) → kind → asset → window | `add` | Same as reassign | Append with a temporary id |
| Resolve objection | `AuditorComment` actions | `resolve_objection` | Override note ≥ 10 characters | Mark resolved (pending) |
| Lock task | Pin icon | `lock` | — | Locked tasks survive re-optimise |

Mechanics ([ARCHITECTURE §5.3](ARCHITECTURE.md#53-mutations)):
- Each op is a `useMutation` with `scope: { id: "plan:" + id }` (serialised). `onMutate` snapshots `qk.plans.detail(id)` and applies the op. `onError` rolls back and shows the problem inline on the card (for example 422 `asset_unavailable`). `onSuccess` replaces the cache with the server's new version.
- The PATCH header is `If-Match: "{version}"`. A 409 `plan_version_conflict` rolls back all pending ops and opens `ConflictDialog`.
- The response may include `violations[]` (rule checks). These appear as `AuditorComment` entries with `source: "rules"`.
- After the op queue has been idle for 1.5 s, What-If re-simulates for the new version (`POST /v1/plans/{id}/simulate`, p95 ≤ 3 s, CONTRACTS §7). The summary card and the ApproveBar show "Updating What-If…".
- **Re-optimise:** "Re-optimise around my changes" → `POST /v1/plans/{id}/reoptimize` with the locked task ids (p95 ≤ 6 s) → new version. The diff highlights the optimiser's changes.
- **Plan diff:** the "Show changes vs AI draft" toggle compares against `version=1` (`created_by_agent`).

#### 3.7.5 ApproveBar

| Condition | Bar content | Approve button |
|---|---|---|
| Draft, no open blocking objection, What-If current | Exposure avoided (range), tasks, assets, alerts, dispatch time | **Enabled.** Ctrl/Cmd+Enter opens the dialog |
| Draft, blocking objection open | "⛔ 1 blocking objection open" + "Review" link (focuses it) | Disabled, with the reason as `aria-describedby` |
| Draft, ops pending | "Saving changes…" | Disabled |
| Draft, What-If recomputing | "Updating What-If for v3…" | Disabled (≤ 3 s typical) |
| Draft, near expiry (< 30 min) | Amber countdown "Expires 05:00 (in 24 min)" | Enabled |
| Approved / dispatched / in progress | Progress: "9/14 done · 3 verifying · 1 missed" | Replaced by "View live status" |
| Rejected / expired / failed | Status + reason | Replaced by "Draft a new plan" |
| Analyst / admin / other ward | "Only officers for ward-084 can approve" | Hidden. The bar is read-only |

The bar is `position: sticky; bottom: 0`, and the page has `scroll-padding-bottom` equal to the bar height, so a focused element is never hidden behind it (WCAG 2.4.11).

#### 3.7.6 Approve confirmation dialog

```
┌─ Approve and dispatch this plan? ──────────────────────────────────────────┐
│ Master plan · ward-084 · Thu 13 Nov 05:30–11:00 IST · version 3              │
│                                                                             │
│ Expected exposure avoided   18,450 person-hours (80 %: 12,900–23,100)        │
│ vs usual routes             +11,330 more (80 %: 6,800–15,200)                │
│ Estimated on the forecast, not measured.                                    │
│                                                                             │
│ Tasks        8 spray · 3 sweep · 3 inspect                                   │
│ Assets       9 (6 sprinklers, 1 sweeper, 2 inspection teams) · 9 simulated  │
│ Alerts       3 school alerts (WhatsApp + SMS, en + hi) · sent 19:00 today    │
│ Dispatch     Routes release at 05:30 IST tomorrow (push + SMS to drivers)    │
│ Objections   2 resolved (1 overridden by you: "site already inspected")     │
│                                                                             │
│ Note (optional) [_______________________________________]                    │
│                                          [Cancel]  [Approve and dispatch]   │
└─────────────────────────────────────────────────────────────────────────────┘
```

- `AlertDialog` (Radix). Initial focus goes to **Approve and dispatch**, which is the officer's intent, so one press confirms. Esc and Cancel close the dialog. The dialog text is announced.
- On confirm: `POST /v1/plans/{id}/approve` with body `{version, note}`, `Idempotency-Key: approve:{plan_id}:v{version}` and `X-Correlation-Id: {correlation_id}`. The button reads "Approving…". **Not optimistic.** On 200 → status Approved, a toast, and the page switches to live mode. On 409 `plan_version_conflict` → `ConflictDialog`. On `plan_not_draft` → refetch plus "This plan was already approved by {name} at {time}" or "expired". On `unresolved_blocking_objections` → focus the objection.
- For `mode: spike`, dispatch is "immediately" and the dialog header uses danger styling.

#### 3.7.7 Live status (approved → completed)

```
┌ Progress: ████████░░░░ 9/14 done · 3 verifying · 1 missed · 1 in progress ─────────────┐
│ Task                          Status                Since   Evidence                     │
│ SPR-0012 #1 g500-041-077      ✔ Verified −18.2 %    06:58   [Impact ▸] (Sim)             │
│ SPR-0012 #2 g500-042-077      ◐ In progress (spraying 38 L/min, HawaTag)  07:12          │
│ SWP-0003 #1 …                 ⏳ Verifying (after 09:10)                                  │
│ TEAM-0004 #1 g500-039-075     ✖ Missed (window passed 07:00)   [Replan ▸]                │
└──────────────────────────────────────────────────────────────────────────────────────────┘
```

Task status chips follow CONTRACTS `TaskStatus` and use icon + word. `in_progress` shows HawaTag flow when the spray segment is known. `verified` links to `/console/interventions/{intervention_id}`. `missed`/`skipped` show the reason, and `skipped` has a manual-fallback note ("Driver marked skipped: road blocked"). A mini map (map layers `fleet` + plan cells) can be toggled.

#### 3.7.8 States

| State | Behaviour |
|---|---|
| L | Header + 6 task-card skeletons + right-column skeletons |
| Drafting | §3.7.2 |
| E | A plan with zero tasks: "The optimiser found no task worth dispatching: all hotspots are regional smoke (protect-only)" + alert summary |
| X | 404 → not-found. 403 (ward) → inline. Other errors → `ProblemAlert`. Mutation errors are shown per card |
| S | Twin/forecast staleness banner if the plan's inputs are older than 3 h ("Plan based on forecast issued 17:05") |
| Sim | Badge count in the header, a badge per card, and a dialog line |
| Off | Polling every 10 s. The approve flow is unaffected |

#### 3.7.9 Acceptance criteria

1. Every task shows asset, cell, IST window, cause + confidence, the full reason, expected effect ± CI and expected exposure range, without expanding anything.
2. The demo objection ("sprinkler → smoke hotspot") appears with severity, its text and its resolution. The diff shows the sprinkler replaced by the inspection team.
3. Approve is disabled while any blocking objection is open, while ops are pending, and while What-If recomputes. Each disabled state explains itself.
4. The dialog summary numbers equal the What-If numbers for the **same version**, all with ranges. Confirm triggers exactly one approve request (idempotency key reused on retry).
5. An optimistic edit appears in < 100 ms and rolls back on a mocked 422 with an inline message. A mocked 409 opens `ConflictDialog`.
6. After approval, WS task events move the statuses without a reload. `task.verified` shows the effect with a link to the impact page.
7. Keyboard-only: reorder via ↑/↓, resolve an objection, approve via Ctrl/Cmd+Enter → Enter. axe clean.
8. Analysts and admins see everything read-only, with no edit or approve controls.

---

### 3.8 `/console/what-if`

**Roles:** O (An Ad read) · **Tier:** BUILD (**never cut**) · **Features:** F13 F12 · **Demo:** 1:20–1:55.

**Purpose:** "The What-If screen compares 'usual routes' against the AI plan in person-hours avoided" (§6 F13). The goal is to show, with uncertainty, that the same fleet protects more people.

**Data:** `GET /v1/plans/{id}/simulation?version=` (proposed) or `POST /v1/plans/{id}/simulate` (Idempotency-Key `simulate:{id}:v{version}`); `GET /v1/plans/{id}`; `GET /v1/hotspots?ward=`. **Query:** `?plan={id}` (default: the latest draft for the ward, else the latest approved).

Expected simulate response (proposed shape, R17):
```json
{
  "plan_id": "…", "version": 3, "baseline_kind": "usual_routes",
  "plan_ph": { "p10": 12900, "p50": 18450, "p90": 23100 },
  "baseline_ph": { "p10": 5000, "p50": 7120, "p90": 9300 },
  "delta_ph": { "p10": 6800, "p50": 11330, "p90": 15200 },
  "vulnerable_protected": { "plan": { "schools": 3, "hospitals": 1 }, "baseline": { "schools": 0, "hospitals": 1 } },
  "per_cell": [{ "cell_id": "g1k-020-038", "plan_ph": 2140, "baseline_ph": 0, "plan_asset_type": "sprinkler", "baseline_asset_type": null, "cause_label": "dust" }],
  "plan_routes": { "type": "FeatureCollection", "features": [] },
  "baseline_routes": { "type": "FeatureCollection", "features": [] },
  "totals": { "plan": { "km": 142, "litres": 38400 }, "baseline": { "km": 151, "litres": 40100 } },
  "is_simulated": true
}
```

```
┌──────────────────────────────────────────────────────────────────────────────────────────────┐
│ What-If · Master plan ward-084 v3 vs usual routes     [Plan ▾]   Estimated on forecast, not measured│
├──────────────────────────────────────────────────────────────────────────────────────────────┤
│ Person-hours above safe level avoided (80 % range)                                            │
│  AI plan    ├────────●────────┤ 18,450 (12,900–23,100)                                        │
│  Usual      ├──●──┤ 7,120 (5,000–9,300)                                                       │
│  Difference   ├──────●──────┤ +11,330 (6,800–15,200)   0 │                                    │
│ Schools protected 3 vs 0 · Hospitals 1 vs 1 · Distance 142 vs 151 km · Water 38.4k vs 40.1k L │
├───────────────────────────────────────────────┬──────────────────────────────────────────────┤
│ USUAL ROUTES                                   │ AI PLAN                                       │
│ [map: fixed routes, cells shaded by ph avoided]│ [map: plan routes, cells shaded by ph avoided]│
│  (synced pan/zoom)                             │                                               │
├───────────────────────────────────────────────┴──────────────────────────────────────────────┤
│ Per hotspot: # │Cause     │Usual sends     │AI sends          │ph avoided usual → AI │ Note     │
│              3 │🔥 Burning│Sprinkler (water)│Inspection team   │ 0 → 1,850            │mismatch ⚠│
└──────────────────────────────────────────────────────────────────────────────────────────────┘
```

**Components:** `WhatIfCompare { plan, simulation }`; `ExposureRangeChart { rows: {label, q: Quantiles}[], zeroLine: true }` (horizontal range bars with P50 dot and a visible zero line for the delta; `ChartFigure` with a table); `SyncedMaps { left: Layer[], right: Layer[] }` (two interleaved maps, one shared `viewState`; layers `ward-boundaries`, a 1 km "ph avoided" fill on a **sequential single-hue brand ramp**, never AQI colours, route `PathLayer` per asset with a legend, POIs); `HotspotComparisonTable`.

**Interactions:** plan selector (URL). Hovering a route highlights it in both maps. A "Swipe" toggle gives a single map with a divider (optional). "Back to plan" returns to the plan with its scroll position. Changing the plan version re-simulates.

**States:** L (range bars skeleton; the maps load the basemap); X (simulate failed → `ProblemAlert` + retry; p95 3 s budget); S (simulation older than the plan version → auto-recompute); Sim (label "Simulated fleet" in the header when the plan has simulated assets).

**Acceptance:** all three rows show P10–P90, and the delta interval comes from the server (`delta_ph`), never from subtracting intervals; the "Estimated on forecast, not measured" label is visible without scrolling; both maps pan together at ≥ 45 fps on the reference machine; at least one mismatch row (water → smoke under usual routes) exists in the golden-path seed; the page works for a read-only analyst.

---

### 3.9 `/console/fleet`

**Roles:** O An Ad · **Tier:** BUILD · **Features:** F2 F17 · **Purpose:** machines, shifts and live positions, with HawaTag status as proof that spraying happened, not just driving (§10.4).

**Data:** `GET /v1/assets`, `GET /v1/assets/{id}`, `GET /v1/fleet/live`, `GET /v1/interventions?from=&to=&asset=` (recent sprays). **WS:** `fleet`.

```
┌──────────────────────────────────────────────────────────────────────────────────────────┐
│ Fleet · ward-084   [Type ▾] [Status ▾] [Simulated: all ▾]     Live ●   142 assets       │
├──────────────────────────────────────────────┬───────────────────────────────────────────┤
│ Asset        │Type      │Status   │Shift     │HawaTag            │Last seen│ [map: fleet │
│ AST-SPR-0012 │Sprinkler │On task  │05:30–13:30│● spraying 38 L/min│ 8 s    │  layer +    │
│   (Sim)      │          │         │          │ 612 L today       │        │  selected   │
│ AST-ASG-0031 │Smog gun  │Available│05:30–13:30│● idle, pump 0 A   │ 12 s   │  track]     │
│ AST-SWP-0003 │Sweeper   │Offline  │ —        │○ no signal 17 min │17 min ⚠│             │
└──────────────────────────────────────────────┴───────────────────────────────────────────┘
```

**Components:** `AssetTable { assets, live }` (live columns from `useFleetPositions`, throttled to 1 render/s); `AssetDetailSheet { assetId }` (shift timeline, today's tasks from plan tasks, recent spray segments with litres and pm before/after, Simulated); `HawaTagStatus { tag }` (online state, flow L/min, pump A, `spraying`, last spray, tamper flag, plus a text label); `ShiftTimeline`.

**States:** stale per item (> 2 min grey, > 15 min offline); Sim per row and ring on the map; Off (polling every 5 s).

**Acceptance:** positions update at about 1 Hz with no full-table re-render jank; HawaTag state is shown as words + values (not only a dot); filtering by `is_simulated` works; the selected asset's track shows on the mini map.

---

### 3.10 `/console/interventions` and `/console/interventions/[id]`

**Roles:** O An Ad · **Tier:** BUILD (**never cut**) · **Features:** F17 F18 · **Demo:** 2:20–2:45.

**Purpose:** each logged spray, and whether it measurably cleaned the air. "A clinical trial for every sprinkler run" (§5.1).

**Data:** `GET /v1/interventions?from=&to=&asset=`; `GET /v1/interventions/{id}`; `GET /v1/interventions/{id}/impact`. **WS:** `impact`, plus `plan:{id}` when opened from a plan.

Expected impact response (CONTRACTS `impact.verified` + proposed R19):
```json
{
  "impact_id": "…", "intervention_id": "…", "task_id": "…", "cell_id": "g500-042-077", "pollutant": "pm10",
  "effect_pct": -18.2, "ci_low": -26.0, "ci_high": -9.9, "ci_level": 0.95, "duration_min": 90,
  "method": "synthetic_control", "verdict": "effective", "placebo_p": 0.04,
  "donors": [{ "cell_id": "g500-045-070", "weight": 0.58 }, { "cell_id": "g500-039-081", "weight": 0.42 }],
  "spray": { "start_ts": "2026-11-13T00:41:10Z", "end_ts": "2026-11-13T00:58:40Z" },
  "pre_period": { "start_ts": "2026-11-12T18:41:10Z", "end_ts": "2026-11-13T00:41:10Z", "rmse": 11.4 },
  "series": [{ "ts": "2026-11-13T00:30:00Z", "treated": 402, "synthetic": 398, "synthetic_low": 371, "synthetic_high": 425 }],
  "is_simulated": true, "injected_effect_pct": -20.0, "model_version": "verifier@1.0.0+a1b2c3d"
}
```

List wireframe:
```
┌──────────────────────────────────────────────────────────────────────────────────────────┐
│ Interventions · ward-084 · today   [Asset ▾] [Verdict ▾] [Date ▾]                          │
│ Time (IST)   │Asset          │Cell          │Litres│Source │Status / effect (95 % CI)       │
│ 06:11–06:28  │AST-SPR-0012 Sim│g500-042-077 │612   │HawaTag│✔ Effective −18.2 % (−26.0, −9.9)│
│ 06:35–06:52  │AST-SPR-0012 Sim│g500-042-078 │540   │HawaTag│⏳ Verifying after 08:52         │
│ 07:02–07:20  │AST-ASG-0031 Sim│g500-041-079 │ —    │HawaTag│○ No detectable effect +1.1 % (−6.3, 8.4)│
└──────────────────────────────────────────────────────────────────────────────────────────┘
```

Detail wireframe:
```
┌───────────────────────────────────────────────────────────────────────────────────────────────┐
│ Intervention · AST-SPR-0012 Sprinkler · g500-042-077 · Thu 13 Nov 06:11–06:28 IST  [Simulated] │
│ ┌ EffectSummary ───────────────────────────────────────────────────────────────────────────┐ │
│ │ PM10 −18.2 %  (95 % CI −26.0 to −9.9) for 90 min   [✔ Effective]   placebo p = 0.04        │ │
│ │ Method: synthetic control · 2 donor cells · pre-period fit RMSE 11.4 µg/m³                 │ │
│ │ Injected effect (simulation): −20.0 % → recovered −18.2 % (inside CI)                      │ │
│ └──────────────────────────────────────────────────────────────────────────────────────────┘ │
│  PM10 µg/m³ · treated cell g500-042-077                                                       │
│ 450┤                               ┆▒spray▒┆                                                   │
│    │ ── observed (treated)          ┆▒▒▒▒▒▒▒┆   - - synthetic (no spray)   ░ 95 % band          │
│ 400┤ ╲__    __                     ┆▒▒▒▒▒▒▒┆╲_ ░░░░░░░░░░░░░░                                  │
│    │    ╲__╱  ╲___  ___            ┆▒▒▒▒▒▒▒┆  ╲░░- - - - - - -░░░                               │
│ 350┤              ╲╱  ╲_______     ┆▒▒▒▒▒▒▒┆    ╲▓▓▓▓▓▓▓▓▓  effect                           │
│ 300┤                               ┆       ┆      ╲________                                   │
│    └─────┬──────┬──────┬──────┬────┴──┬────┴──┬──────┬──────┬──────┬──                        │
│        01:00  02:30  04:00  05:30  06:11 06:28 07:30  08:30  09:30  10:30  IST                  │
│    ├──────── pre-period fit (6 h) ────────┤      ├── verification window 0–4 h ──┤              │
│  Gap (observed − synthetic, %)  ── 0 ────╲▁▁▂▃▄ with 95 % band                                 │
│  [Show donor cells] [Show as table]                                                           │
│ Donors: g500-045-070 (0.58) · g500-039-081 (0.42)       Spray: 612 L · HawaTag HTG-0031         │
└───────────────────────────────────────────────────────────────────────────────────────────────┘
```

**SyntheticControlChart spec** (`<SyntheticControlChart impact intervention showDonors />`):

| Element | Spec |
|---|---|
| X axis | Time in IST from `pre_period.start_ts` (spray start − 6 h) to spray end + 4 h (verification window, CONTRACTS §10.3). Ticks every 30 min at ≥ 1280 px, every 90 min below. `HH:mm`. The axis title carries the date |
| Y axis | Concentration of `impact.pollutant` in µg/m³. **Starts at 0 by default** so the effect is not exaggerated. A "Zoom to data" toggle is allowed, and when on, the axis break is labelled. Title: "PM10 µg/m³ · treated cell g500-042-077" |
| Treated (observed) | 2 px solid ink (`--foreground`) line |
| Synthetic counterfactual | 2 px dashed brand line |
| Counterfactual band | `Area` range `[synthetic_low, synthetic_high]`, brand at 20 % opacity, legend "95 % band (placebo)" using `ci_level`. **Always on** |
| Effect area | Post-spray area between the synthetic and treated lines: brand-tinted `▓` for a reduction, danger-tinted for adverse. Drawn only after `spray.start_ts` |
| Spray window | `ReferenceArea` start→stop, warning colour at 12 % opacity, labelled "Spray 06:11–06:28". `ReferenceLine`s at start and stop with labels |
| Pre-period | Bracket under the axis: "Pre-period fit (6 h) · RMSE 11.4" |
| Verification window | Bracket: "Verification window (0–4 h after spray)" |
| Donors (optional) | Thin grey lines per donor (weights in the legend), toggle off by default |
| Gap panel | Second small chart: `(treated − synthetic)/synthetic` % with its band and a 0 line |
| Tooltip | Time IST, treated, synthetic, band, gap % |
| Summary (sr) | "After spraying from 06:11 to 06:28, PM10 in g500-042-077 was 18.2 % below its synthetic control (95 % CI −26.0 to −9.9 %) for 90 minutes. Verdict: effective." |

**Components:** `InterventionTable`, `SyntheticControlChart`, `GapChart`, `EffectSummary { impact }` (effect via `UncertaintyValue` with `ci_level`, `VerdictBadge`, placebo p, method, n donors, injected vs recovered for simulated), `VerdictBadge { verdict }` (icon + word: Effective, No detectable effect, Inconclusive, Adverse), `DonorTable`.

**States:** Verifying (before `verify_after`: "Verification runs 2 h after the spray (at 08:28)" plus the pre-period chart without the effect); inconclusive (neutral styling with the reason); `method: before_after_naive` → a "Low evidence" warning badge (CONTRACTS §3); Sim (badge + injected effect); X.

**Acceptance:** the chart shows treated, synthetic, band, spray start/stop and both brackets; the band is always visible; the effect text includes the CI level; for the golden-path simulated intervention, the injected and recovered values are shown together and the injected value lies inside the CI; a `impact.verified` WS event turns "Verifying" into the result without a reload; the table view is equivalent.

---

### 3.11 `/console/impact`

**Roles:** O An Ad · **Tier:** BUILD · **Feature:** F18 · **Purpose:** roll-up of measured effects, and the Intervention Effectiveness Library (what works where).

**Data:** `GET /v1/impact/summary?ward=&from=&to=`; `GET /v1/effectiveness?cause=&asset_type=`; `GET /v1/interventions?from=&to=`. **WS:** `impact`.

```
┌───────────────────────────────────────────────────────────────────────────────────────────┐
│ Impact · ward-084 · last 7 days            [Range ▾]                                        │
│ Interventions 86 · Verified with CI 79 (92 %, target ≥ 90 %) · Effective 51 · Litres 41,200 │
├───────────────────────────────────────────────────────────────────────────────────────────┤
│ Effect table          Asset type × cause   median effect (95 % CI)   n    [whisker]          │
│  Sprinkler × Dust      −14 % (−22, −6)                          31   ├──●──┤    │0          │
│  Smog gun × Dust       −6 % (−15, +3)                           12      ├──●──┼─┤            │
│  Sprinkler × Burning   not assigned (constraint: water does not reduce smoke)                │
├───────────────────────────────────────────────────────────────────────────────────────────┤
│ Effectiveness library explorer  [Cause ▾] [Asset ▾] [Land use ▾] [Season ▾] [Hour band ▾]   │
│  matrix: rows asset types, cols causes; cell = median + CI whisker + n; click → impacts      │
└───────────────────────────────────────────────────────────────────────────────────────────┘
```

**Components:** `ImpactKpis { summary }`; `EffectTable { rows }` with `EffectWhisker { effect, ci_low, ci_high, zero: true }`; `EffectivenessExplorer { library, filters }` (visx is permitted for the matrix).

**Acceptance:** every effect has a CI whisker with a visible zero line; disallowed cause/asset pairs say why; the verified share is compared with the ≥ 90 % KPI target (§13.1) and labelled "pilot target"; clicking through reaches the intervention detail.

---

### 3.12 `/console/alerts`

**Roles:** O Ad compose; An read · **Tier:** BUILD (list), STRETCH (compose) · **Feature:** F16 · **Purpose:** pollutant-specific alerts that were sent, their delivery status, and manual alerts.

**Data:** `GET /v1/alerts`, `GET /v1/alerts/{id}`, `POST /v1/alerts` (Idempotency-Key); `POST /v1/alerts/preview` (proposed) for recipient counts; `POST /v1/alerts/draft` (proposed, Communicator). **WS:** `alerts` (proposed), else poll every 30 s.

```
┌──────────────────────────────────────────────────────────────────────────────────────────┐
│ Alerts · ward-084                                       [+ Compose alert (O/Ad)]          │
│ Sent (IST) │Kind             │Audience│Channels     │Recipients│Delivery                    │
│ 19:00      │Safe window      │School  │WhatsApp, SMS│ 3        │3 delivered · 2 read         │
│ 19:00      │Pollutant warning│Citizen │WhatsApp     │412       │398 delivered · 9 failed ⚠   │
└──────────────────────────────────────────────────────────────────────────────────────────┘
Compose dialog: Kind ▾ · Audience ▾ · Target (wards / schools) · Channels ☑ · Dominant pollutant ▾
  Advice template (PM2.5 smoke → masks + stay indoors; traffic NO2 → avoid the road) · Text EN* · Text HI*
  Preview: [EN bubble] [HI bubble] · "412 recipients: WhatsApp 380, SMS 32" · [Send…] → confirm
```

**Components:** `AlertTable`, `AlertDetailSheet` (bilingual text, per-channel `DeliveryStatus` counts following `AlertStatus` `requested → queued → sent → delivered | failed | read`, masked recipients), `ComposeAlertDialog` (RHF + Zod; both languages required; `expires_at`; the advice template fills pollutant-specific text that the officer may edit), `BilingualPreview`.

**Acceptance:** both `en` and `hi` texts are required to send; the confirm step states recipient count and channels; phone numbers are always masked; delivery counts update live or by polling; analysts cannot compose.

---

### 3.13 `/console/schools` and `/console/schools/[id]`

**Roles:** O An Ad · **Tier:** STRETCH · **Feature:** F19 · **Purpose:** each school's safe outdoor window, and whether the alert actually protected the children (indoor vs outdoor, §10.4).

**Data:** `GET /v1/schools?ward=` (proposed list); `GET /v1/schools/{id}/safe-window?date=`; `GET /v1/schools/{id}/indoor-outdoor?from=&to=`; `GET /v1/forecast/{cell_id}`. **WS:** `forecast` (proposed; `school.safe_window_computed`).

```
List: School │Forecast peak (P50, P90)│Safe window today│Alert│Sentinel pair│
Detail:
┌ GBSSS No. 2 · SCH-07050112345 · ward-084 ─────────────────────────────────────────────────┐
│ Safe outdoor window Thu: 12:30–14:00 IST (assembly moved indoors)   Advice: keep windows shut│
│ 08:00 ▓▓▓▓▓▓▓▓▓ unsafe ▓▓▓▓▓▓▓▓ 12:30 ░░ safe ░░ 14:00                                        │
│ Indoor vs outdoor PM2.5 (HPS-0007-I / HPS-0007-O) + CO₂ (ventilate when > 1,200 ppm)        │
│  outdoor ── 262   indoor ── 98   ratio 0.37                                                  │
└──────────────────────────────────────────────────────────────────────────────────────────────┘
```

**Components:** `SchoolTable`, `SafeWindowTimeline { windows, advice }`, `IndoorOutdoorChart { outdoor, indoor, co2 }` (bands where available).

**Minimal variant:** the detail page only, reached from forecast "vulnerable places". **Acceptance:** the safe window is shown as text + timeline (not colour alone); indoor/outdoor shows both series and the ratio; Simulated is shown for simulated sentinels.

---

### 3.14 `/console/reports`

**Roles:** O An Ad · **Tier:** STRETCH · **Feature:** F20 · **Purpose:** the Citizen Eyes queue (Flow D): photo → vision check → matched spike → inspection → outcome.

**Data:** `GET /v1/reports?status=&ward=` (proposed), `GET /v1/reports/{id}`; `POST /v1/inspections` (proposed) to escalate. **WS:** `reports` (proposed).

```
Queue: Submitted (IST)│Status (ReportStatus)│Vision verdict      │Matched spike        │Ticket
       06:44          │Verified            │Open burning 0.91   │HPM-0142 ×3.2 06:42  │INS-…
Detail sheet: photo (presigned, alt text from vision caption) · location · verdict + confidence · spike · timeline
```

**Acceptance:** status labels follow `ReportStatus` exactly; photos load only through presigned URLs; no reporter phone or name is shown to officers beyond a masked id; unknown statuses render neutrally.

---

### 3.15 `/console/inspections`

**Roles:** O (An Ad read) · **Tier:** STRETCH · **Features:** F20 F7 · **Purpose:** inspection tickets from reports and spikes, so each inspector gets "a target, not an area" (§7).

**Data:** `GET /v1/inspections?status=`; `POST /v1/inspections/{id}/close`; `POST /v1/inspections/{id}/assign` (proposed). **WS:** `plan:{id}` for spike plans; `reports` (proposed).

Table columns: status (`InspectionStatus`), source (hotspot / report / spike), cell + suspect pin distance, assigned team, opened, SLA age, outcome. The close dialog records the outcome enum (`closed_confirmed | closed_not_found | closed_unreachable`) with a note.

**Acceptance:** status transitions follow CONTRACTS `InspectionStatus`; closing requires an outcome; each row links to the hotspot and its evidence.

---

### 3.16 `/console/sites`

**Roles:** O An Ad · **Tier:** STRETCH · **Feature:** F9 · **Purpose:** construction and industrial sites graded A/B/C from sensor-measured behaviour. "Better grades face lighter curbs on bad days" (§6).

**Data:** `GET /v1/sites?grade=`, `GET /v1/sites/{id}`.

Table: site, type (`SiteType`), `SiteGradeChip` (letter + colour + pattern), grade trend, PM10 trend sparkline with band, violations, last inspection. Detail sheet: grade history and nearby hotspots.

**Acceptance:** the grade letter is always visible; low-cost sensor values are labelled "indicative" (§10.7: "not for legal compliance values").

---

### 3.17 `/console/devices` and `/console/devices/[id]`

**Roles:** An Ad (O read) · **Tier:** STRETCH · **Features:** F3 F2 · **Purpose:** keep sensor data trustworthy: registry, drive-by calibration and trust scores.

**Data:** `GET /v1/devices`, `GET /v1/devices/{id}`, `POST /v1/devices` (admin), `GET /v1/devices/{id}/calibration`. **WS:** `devices`.

```
Registry: Device │Role│Placement│Host (vehicle/asset)│Status│Trust (band)│Cal v│Last seen│Flags     │Sim
          HPM-0142│M  │mobile   │VEH-DTC-0457        │active│0.86 High   │7    │8 s      │heater_on │Real
Detail: calibration versions table (a, b, c, R², RMSE, n pairs, fitted_at) + coefficient chart · trust history · recent events
```

**Components:** `DeviceTable`, `CalibrationHistory { versions }`, `TrustChart`, `RegisterDeviceDialog` (admin; ID pattern `^(HPM|HPS|HTG|HEY)-\d{4}(-[OI])?$` validated with Zod).

**Acceptance:** the trust band shows a word + number; health `flags` render as readable labels from the CONTRACTS vocabulary; the real device shows "Real device" and simulated ones show "Simulated"; `device.tamper` shows a toast for analysts and admins.

---

### 3.18 `/console/integrity`

**Roles:** O An Ad · **Tier:** STRETCH · **Feature:** F15 · **Purpose:** catch China's documented failure mode, where "cleaning clusters around official stations while mobile readings nearby stay high" (§6), plus device drift, tamper and implausible jumps.

**Data:** `GET /v1/integrity/flags`. Optional acknowledge: `POST /v1/integrity/flags/{id}/ack` (proposed). **WS:** `integrity` (proposed).

List by `IntegrityFlagKind`. The detail view for `station_clustering` shows a mini map with the station, the cleaning tracks within its radius, the surrounding mobile readings, and the station vs mobile gap with its uncertainty.

**Acceptance:** each flag states its evidence in words; nothing on this page names or blames an individual driver (flags attach to assets and patterns).

---

### 3.19 `/console/coverage`

**Roles:** O An Ad · **Tier:** STRETCH · **Feature:** F11 · **Purpose:** show the blind spots and which bus route or rider should pass through next.

**Data:** `GET /v1/coverage/blind-spots`; `GET /v1/coverage/summary` (proposed) for the KPI "road-km observed daily" (target ≥ 70 %).

Map (`blind-spots` layer on) + list: cell, confidence, reason (few readings), suggested vehicle/route and ETA.

**Acceptance:** the KPI is labelled "pilot target"; each blind spot shows confidence as a word + number.

---

### 3.20 `/console/evidence`

**Roles:** O An Ad · **Tier:** STRETCH · **Feature:** F22 · **Purpose:** the weekly evidence PDF: hotspots, sources, actions, measured impact per rupee, recommended reallocation.

**Data:** `GET /v1/evidence-reports`, `POST /v1/evidence-reports` (202, poll the list every 10 s until ready), `GET /v1/evidence-reports/{id}/pdf` (download via presigned redirect).

Table: week, wards, generated at (IST), status, size, [Download]. "Generate now" for the current week.

**Acceptance:** download works; generation shows progress; ₹ values are formatted from paise (`cost_paise`).

---

### 3.21 `/console/admin`

**Roles:** Ad · **Tier:** STRETCH · **Purpose:** users, roles, ward scopes and model versions.

**Data (all proposed):** `GET /v1/users`, `POST /v1/users`, `PATCH /v1/users/{id}`, `PUT /v1/users/{id}/ward-scopes`, `GET /v1/wards`, `GET /v1/models`.

User table: name, email or phone (masked), role (`UserRole`), wards, status, last login. `UserDialog`: role select (console roles + field roles for provisioning), ward multi-select, disable. `/console/admin/models`: model name, version (`{model}@{semver}+{sha}`), stage, key metrics, trained at.

**Acceptance:** only admins reach the page (proxy + backend); role changes require confirmation; an admin cannot remove their own admin role.

---

## 4. Open data portal

Public, rate-limited, labelled "indicative". AEROS/Soramame-style (§4.2, F21). No login, no WebSocket, no fleet, no PII.

### 4.1 `/open`

**Data:** `GET /open/v1/air?bbox=&ts=` (coarse cells), `GET /open/v1/stations`, `GET /open/v1/cells/{cell_id}/history`. Refresh every 15 min (the twin cadence).

```
┌──────────────────────────────────────────────────────────────────────────────────────────┐
│ HawaCommand Open Air Data   Map · API · Methods                              EN | हि       │
│ ⓘ Indicative street-level estimates from calibrated low-cost sensors. Official CPCB        │
│   stations remain the legal record.                                                        │
├──────────────────────────────────────────────────────────────┬───────────────────────────┤
│ [map: cells coloured by indicative AQI, station markers]      │ Cell g500-041-077           │
│                                                              │ AQI 342 (318–367) very poor │
│                                                              │ PM2.5 164 (137–191) µg/m³   │
│                                                              │ Confidence Medium 0.61      │
│                                                              │ 24 h history with band      │
│                                                              │ [Download CSV] [API link]   │
└──────────────────────────────────────────────────────────────┴───────────────────────────┘
```

**Components:** `OpenMap` (twin + stations layers only, reusing the map builders), `StationList`, `OpenCellPanel`.

**States:** 429 → "The open API is busy. Try again in {Retry-After} s", with automatic retry; stale → as-of chip.

**Acceptance:** "indicative" appears on the map, the panel and downloads; uncertainty is shown as in the console; the page works without WebGL (station table fallback); static HTML exists for both `/open` and `/hi/open`.

### 4.2 `/open/api`

Static docs for `GET /open/v1/air`, `GET /open/v1/stations`, `GET /open/v1/cells/{cell_id}/history` and `GET /open/v1/methods`. Each entry has parameters, example requests (`curl`), example responses (from fixtures), units (CONTRACTS §1), the rate limits (per [../backend/API.md](../backend/API.md)), attribution and the licence. **The licence is an open decision; flag it** (CC BY 4.0 or ODbL). Acceptance: every example response validates against `openapi.snapshot.json` (fixture contract test).

### 4.3 `/open/methods`

Static narrative + `GET /open/v1/methods` for live model versions:
- Drive-by calibration: `ref = a·raw + b·RH + c` within 200 m of a reference station at low speed and stable wind; trust scores (§9.4).
- Twin: Gaussian-process interpolation with land-use covariates, shifted downwind by the wind vector; posterior variance = confidence.
- Source fingerprint table: the four causes and the right action (§9.4).
- Forecast: LightGBM per horizon, P10/P50/P90.
- Exposure formula (CONTRACTS §10.4).
- Causal verification: donor cells, synthetic control, placebo CI.
- Indicative AQI rule (CONTRACTS §10.1). Limitations: low-cost gas sensors are indicative only (§10.7); official stations are the legal record (§12.4).

Acceptance: every formula renders as text (MathML or plain), not as an image; model versions show when the endpoint is reachable.

### 4.4 `/open/reports/[code]`

**Data:** `GET /open/v1/reports/{public_code}` (proposed), `revalidate: 60`.

```
┌ Your report 7KQ2-M9 ───────────────────────────────┐
│ Submitted Thu 13 Nov 06:44 IST                       │
│ ● Submitted → ● Verified → ● Inspection → ○ Closed   │
│ Outcome: "Inspector found open burning; stopped."    │
└──────────────────────────────────────────────────────┘
```

Acceptance: no PII (no phone number, name or exact photo); an unknown code gives a friendly 404; both languages are supported; the page carries `noindex`.

---

## 5. Marketing site `/`

### 5.1 Page layout

Static, one page, sections in this order, with anchor ids for the header nav: `#problem`, `#causes`, `#how`, `#proof`, `#hardware`, `#learned`. `SiteHeader` holds the logo, the section links, "Open data", "Officer login" and the language toggle. Numbers are real and cited from the PDF (§17 sources are listed in the footer). Tone: persuasive, plain and specific, with no hype words.

```
┌ Hero ───────────────────────────────────────────────────────────────────────────┐
├ Problem (OneNumberVsStreetMap + FleetStats + five failures) ─────────────────────┤
├ Causes (four causes → right tool) ───────────────────────────────────────────────┤
├ HowItWorks (7-step loop + day timeline + AwsArchitecture) ───────────────────────┤
├ Proof (causal verification + What-If) ───────────────────────────────────────────┤
├ Hardware (HawaPod-M / S, HawaTag, HawaEye + pilot cost vs smog tower) ───────────┤
├ Learned (China / Japan lessons + what we refuse to copy) ────────────────────────┤
├ Closing band (closing line) ─────────────────────────────────────────────────────┤
└ Footer (sources, indicative disclaimer, links, event) ───────────────────────────┘
```

Acceptance for the whole page: static HTML for `/` and `/hi`; LCP ≤ 2.5 s (slow 4G); every number below appears with a source note; images have alt text; counters do not animate under reduced motion; axe clean; the 0:00–0:20 and 2:45–3:00 demo scenes can be recorded straight from this page.

### 5.2 Section copy outlines

**Hero**
- Eyebrow: "Environmental Hacks 2026 · Air track"
- Headline: "Delhi doesn't lack anti-pollution machines. It lacks a brain to direct them, and proof that they work."
- Subhead: "HawaCommand finds, forecasts and fixes Delhi's pollution hotspots street by street, and proves every fix worked."
- CTAs: "See the live map" (`/open`) · "How it works" (`#how`) · secondary "Officer login".
- Visual: the twin-snapshot still (500 m cells over Delhi) with three cause-labelled hotspots.

**Problem** (`#problem`, demo 0:00–0:20)
- Lead: "The phone says AQI 380. That single number hides five separate failures." (§2)
- `OneNumberVsStreetMap`: left, one big "AQI 380" card; right, the same morning as a 500 m street-level map where one lane is far above the station 3 km away.
- `FleetStats`: **376** anti-smog guns · **266** water sprinklers · **91** mechanised sweepers · **~2,000** enforcement teams. Caption: "All GPS-fitted. GPS proves where a machine went. It does not prove the air got cleaner." (§2.3)
- The five failures, one line each:
  1. Half-blind: **47** continuous stations for about **1,484 km²**, roughly one per **31 km²** against a target of one per **25 km²**. A CAG audit found stations sited near trees, major roads and unpaved roads. (§2.1)
  2. Too late: alerts arrive when children are already at the bus stop. Beijing's 2015 red alerts showed that starting cuts **1–2 days early** lowered the peak. (§2.2)
  3. Guesswork: routes are largely fixed, while hotspots move with wind, traffic and construction. (§2.3)
  4. No proof: road dust is about **15 %** of winter PM2.5, yet about **64 %** of available NCAP funds go to road-dust mitigation. IIT Delhi found water spraying had a very small effect on PM2.5, limited to about **200 m**. (§2.4)
  5. Wrong ranking: "AQI 450 over an empty industrial yard harms fewer people than AQI 350 next to three schools and a hospital at 8 AM." (§2.5)

**Causes** (`#causes`)
- Headline: "The right tool depends on the cause. Water does not stop smoke."
- Four cards (icon + fingerprint + right action, §9.4):
  - Road and construction dust: high PM10, low PM2.5/PM10 ratio, daytime, near roads or sites → sprinkler, sweeper, site check.
  - Traffic: NO₂ + CO together at rush hours along corridors → diversion advice, smoky-vehicle checks, alerts.
  - Open burning: sharp PM2.5 + VOC spike, often at night, fire point or photo → inspection team.
  - Regional stubble smoke: city-wide PM2.5 rise, north-west wind, fires upwind → no trucks; protect people and send alerts.
- Footnote: "Every label carries a confidence. It chooses the tool; it is never used to fine anyone." (§15)

**HowItWorks** (`#how`, demo 2:45–3:00)
- Headline: "A closed loop that runs every three hours, plus an evening master plan for the next morning."
- `LoopDiagram` (seven steps with the PDF's analogies, §5.1): Sense ("our buses are police walking every street"), Map ("weather radar for pollution"), Attribute ("a doctor diagnosing before prescribing"), Forecast ("a cyclone warning, but for smog"), Decide ("a war room with a very fast analyst"), Act ("dispatch in an ambulance service"), Verify ("a clinical trial for every sprinkler run").
- Callouts: 500 m twin with a confidence per cell · 72 h forecast with P10/P50/P90 · ranked by people exposed × vulnerability · "Nothing dispatches without officer approval."
- `DayTimeline` (§8): 16:00 data freeze → 17:00 72 h forecast → 18:30 plan draft (Planner + Auditor) → 20:00 officer approves → 22:00 school safe windows → 05:30 dispatch → 06:00–10:00 HawaTag logs sprays → 11:00 verification → 14:00 re-plan → nightly retrain.
- `AwsArchitecture`: AWS IoT Core → Amazon MSK → ECS Fargate services → RDS PostgreSQL + PostGIS, ElastiCache, S3 → Amazon Bedrock with the open-source Strands Agents SDK → SNS / WhatsApp → Amplify-hosted console. Caption: "Built on AWS. The whole cloud pipeline runs for real; the device fleet is simulated in the exact firmware packet format." (§1, §12.5)

**Proof** (`#proof`)
- Headline: "Every spray gets a measured effect, with its uncertainty."
- Causal verification explainer: "The tracker logs exactly when a truck sprayed. We compare the cell against similar untreated cells, a synthetic control, and record the true effect." Example result in the PDF's words: "PM10 −18 % for 90 min", shown as a small static synthetic-control chart with a CI band. (§9.4)
- What-If explainer: "Same fleet, more people protected. The What-If screen compares the usual routes against the AI plan in person-hours of harmful exposure avoided."
- Honesty box: "In the demo, verification runs on simulated interventions with injected, known effects, so you can watch the verifier recover them." (§12.5)
- Pilot KPI targets, labelled "targets, not claims" (§13.1): coverage ≥ 70 % of pilot road-km daily · ≥ 90 % of interventions with a verified effect and CI · school alerts ≥ 12 h before the spike.

**Hardware** (`#hardware`)
- Headline: "Low-cost sensors that ride on vehicles already moving through the city."
- Cards (§10, indicative 2026 prices):
  - HawaPod-M (buses, e-rickshaws, delivery bikes): PM1/2.5/10, NO₂/CO, T/RH/VOC, GPS, 4G, a 72 h offline buffer, on-device spike detection. ₹7,000–9,500.
  - HawaPod-S (school gate + classroom pair): outdoor vs indoor air, plus CO₂ for ventilation. ₹4,500 (+₹2,500 CO₂).
  - HawaTag (sprinklers, smog guns, sweepers): water flow + pump current + PM before and after. "Proves spraying, not just driving." ₹6,000.
  - HawaEye (optional, selected corridors): on-device smoky-vehicle detection, uploads short evidence clips only, never continuous video. ₹6,500.
- Cost comparison (§12.3): "A 100-bus district pilot: 100 HawaPod-M, 20 schools, 50 HawaTags, SIMs and cloud ≈ ₹22–24 lakh in year one. One Delhi smog tower: ₹20–22 crore to build, plus about ₹15 lakh a month to run."
- Footnote: "Hardware prices are indicative; low-cost sensors are indicative, not regulatory-grade." (§12.3, §12.4)

**Learned** (`#learned`)
- Headline: "Borrowed from Asia, rebuilt for Delhi."
- China (§4.1):
  - Hotspot-grid management: 3×3 km blocks (**36,793**) with about **3,600** high-PM2.5 blocks under close watch. In the Cangzhou pilot, PM2.5 fell **38.3 %** vs about **20 %** city-wide, and **6,325** polluting enterprises were identified.
  - Taxi-mounted sensors: Shanghai **125** taxis; **80–100** taxis covered **~80 %** of major roads at ~200 m. Guangzhou **314** taxis. Jinan **200** mobile + **614** fixed micro-stations → 500 m hourly maps.
  - IBM Green Horizons: 1 km forecasts 72 h ahead, ~**30 %** better precision.
  - Graded alerts issued at least **24 h** ahead. Performance-graded polluters.
  - The warning: improvement concentrated where the monitors were, without a matching city-wide drop. Hence our anti-gaming guard.
- Japan (§4.2):
  - AEROS "Soramame-kun": open real-time data from every station built public trust. Hence our open data portal.
  - Pollutant-specific warnings instead of one composite number. Hence our targeted alerts.
  - Tokyo "Operation No Diesel" (2003): roadside SPM fell by over **20 %** (2002–2004), and stations meeting the standard rose from **0 %** to **97 %**. Measured, enforceable rules on the biggest source beat symbolic hardware.
- What we refuse to copy (§4.3): smog towers. Delhi's were inspired by Xi'an. Measurements summarised by DPCC showed the effect falling to about **12–16 %** beyond **100–200 m**. The Connaught Place tower cost about **₹20 crore**. DPCC told the NGT that towers are ineffective, that more than **40,000** would be needed, and that each costs about **₹15 lakh a month** to run. "We copy China's data and governance systems, not its purifier hardware."
- Aside (§3): "We started with 2,000 flying purifier drones. Delhi's winter air volume, restricted airspace and battery life said no. We kept the instinct (hyperlocal sensing → cloud AI → targeted action) and pointed it at the machines Delhi already owns."

**Closing band**
- Large type: "Delhi already owns the machines. HawaCommand gives them a brain, and gives the city proof. Same fleet, more people protected, and evidence for every rupee." (§16.1)
- CTAs: "See the live map" · "Read the methods".

**Footer**
- Sources: a compact list of §17 (CPCB/Millennium Post, CAG/Tribune, CEEW, Health Policy Watch, Down To Earth, CAS, MDPI/PMC, arXiv, IBM, AAQR, Scientific Reports, VoxDev, HGPI, Transportation Research Part D).
- Disclaimer: "Street-level values are indicative estimates from calibrated low-cost sensors. Official CPCB/DPCC stations remain the legal record. Hardware prices, cloud costs and pilot KPIs are estimates and targets, not measured results."
- Links: Open data, API, Methods, Officer login, GitHub. Event: Environmental Hacks 2026 · Bharat Builds Tour · Track 01: Air.
