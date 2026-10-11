# Web Frontend Context

<!-- nav:start -->

**Navigate:** [Project](../../README.md) · [Docs hub](../README.md) · [Overview](../SYSTEM_OVERVIEW.md) · [AWS architecture](../AWS_ARCHITECTURE.md) · [AWS setup](../AWS_SETUP_GUIDE.md) · [API](../backend/API.md) · [Environment](../ENVIRONMENT_VARIABLES.md) · [Contracts](../CONTRACTS.md)

**Web docs:** [Runbook](../../frontend/README.md) · [Index](README.md) · **Context** · [Architecture](ARCHITECTURE.md) · [Pages](PAGES.md) · [Design system](DESIGN_SYSTEM.md) · [Quality](LINTING_AND_QUALITY.md) · [Structure](STRUCTURE.md) · [Plan](PLAN.md) · [Design export](../../frontend/design/EXPORT_NOTES.md)

<!-- nav:end -->

> **Status (reconciled 2026-10-10).** Product context from the proposal. As built, `frontend/` has the landing page, eight console pages (`/map`, `/forecast`, `/plans`, `/plans/[id]`, `/what-if`, `/impact`, `/fleet`, `/alerts`), `/login` and the `/route` driver view. With `NEXT_PUBLIC_API_URL` empty, the in-browser mock API in `src/mocks/` answers every call. The public open-data portal, WebSocket updates, deck.gl, next-intl i18n and alert compose are Planned. See [docs/frontend/README.md](README.md#1-implementation-status).


Purpose: explains why the web app exists, who it serves, what it must show, and the product rules every screen follows. Drawn from the original HawaCommand proposal v3 (cited as §n; no longer in the repository).

Related: [README](README.md) · [ARCHITECTURE](ARCHITECTURE.md) · [STRUCTURE](STRUCTURE.md) · [PAGES](PAGES.md) · [DESIGN_SYSTEM](DESIGN_SYSTEM.md) · [LINTING_AND_QUALITY](LINTING_AND_QUALITY.md) · [PLAN](PLAN.md) · [../CONTRACTS.md](../CONTRACTS.md) · [../SYSTEM_OVERVIEW.md](../SYSTEM_OVERVIEW.md) · [../backend/API.md](../backend/API.md)

---

## 1. Why the web exists

> "Delhi does not lack anti-pollution machines. It lacks a brain to direct them and a way to prove they work." (§1)

Delhi has mobilised 376 anti-smog guns, 266 water sprinklers, 91 mechanised road sweepers and about 2,000 enforcement teams (§2.3). GPS shows where a machine went. It does not show whether the air got cleaner. HawaCommand's loop decides where each machine should go and then proves what happened. The web is where these two results reach people:

1. **Decide → Act.** An officer sees the street-level twin, the 72 h forecast and the GRAP outlook. They read an AI plan with a reason for every task, see the Auditor agent's objections, compare the plan against the usual routes (What-If), and approve it. "Nothing dispatches without officer approval" (§6, F14).
2. **Verify.** For each spray logged by a HawaTag, the officer sees the causal effect with a confidence interval (F18). Over time these results build an effectiveness library that shows what works where.
3. **Open up.** The public gets an AEROS-style map and API (F21, §4.2), and the pitch site explains the idea in plain language.

"Most teams will build an AQI dashboard or alert app that shows the number. HawaCommand builds a command system that acts on the number and proves the result" (§1). The web has to look like that command system. If it looks like a dashboard, it has failed.

## 2. Users served by the web

| User | Role(s) (CONTRACTS §3 `UserRole`) | Needs (§7) | Sees in the web | Does in the web |
|---|---|---|---|---|
| Ward / district officer (MCD, DPCC) | `officer` | Where to send machines and teams, and proof that it worked | Live twin map, hotspots ranked by exposure, 72 h forecast, GRAP outlook, AI plan with reasons, Auditor objections, What-If, live dispatch status, impact | Edits, approves or rejects plans; escalates inspections; sends manual alerts; downloads evidence reports |
| Analyst | `analyst` | Trust in the numbers | Everything the officer sees (read-only for plans and alerts), plus devices, calibration, trust, integrity flags, coverage gaps, model versions | Investigates drift, anti-gaming flags and blind spots; generates evidence reports |
| Admin | `admin` | A working system and correct access | Users, roles, ward scopes, device registry, model versions | Manages users and ward scopes; registers devices |
| Public, researchers, journalists | unauthenticated | Open street-level data they can trust | `/open` map, stations, cell history, API docs, methods | Reads, downloads, calls the rate-limited API |
| Citizen who filed a report | unauthenticated (link code) | To know what happened | `/open/reports/[code]` status page | Reads the outcome |
| Judges and demo audience | unauthenticated (site) / demo officer account | To understand the idea in three minutes and see it work for real | Marketing site, then the console golden path | Watch the §16.1 script |

Driver, inspector, school principal, citizen and site manager experiences live in the Flutter app ([../app/README.md](../app/README.md)). The web only shows their effects: task statuses, alert delivery, report outcomes and site grades.

## 3. Flow A in detail: officer approves tomorrow's plan (§7.1)

The PDF gives Flow A as: *Officer logs in → Sees tomorrow's forecast + GRAP → Opens AI plan + agent reasons → Compares What-If vs usual routes → Edits or approves → Routes pushed to drivers.* It runs inside the evening master cycle (§8, CONTRACTS §11): 17:00 master forecast, 18:30 master plan draft, **20:00 officer approval**, 05:30 dispatch, 06:00–10:00 operations and 11:00 verification batch.

| # | Step | Screen | Data | Officer decides | Done when |
|---|---|---|---|---|---|
| A1 | Log in | `/console/login` | `POST /api/auth/login` → `POST /v1/auth/login` | — | Lands on `/console/map` with their ward preselected. A "Plan awaiting approval" banner shows if a draft exists |
| A2 | Orient on today | `/console/map` | Twin tiles, `GET /v1/hotspots?ward=`, WS `twin`, `hotspots:{ward}`, `fleet` | Is the twin fresh? Where are the hotspots and what caused them? | Twin age is under 20 min, the top 5 hotspots are visible with cause labels and confidence |
| A3 | See tomorrow's forecast and GRAP | `/console/forecast`, `/console/grap` | `GET /v1/forecast/grid?horizon_h=`, `GET /v1/forecast/{cell_id}`, `GET /v1/grap/outlook?ward=&days=3`, `GET /v1/grap/checklist?ward=&stage=` | Which stage is coming, and which schools are in the spike? | Fan chart shows P10–P50–P90. GRAP pill for tomorrow shows stage and probability. Checklist is ready |
| A4 | Open the AI plan | `/console/plans/[id]` | `GET /v1/plans/{id}`, WS `plan:{id}` | Does every task make sense? | Every task shows asset, cell, window, cause and a plain-language reason. Planner rationale and Auditor objections are visible without scrolling past the task list header |
| A5 | Check the Auditor | same page, Auditor panel | `review.objections[]` in the plan detail | Accept the Auditor's fix, or override it with a reason | No blocking objection is left open. The demo case: "sprinkler sent to a smoke hotspot" was rejected and replaced by an inspection team |
| A6 | Compare What-If | `/console/what-if?plan={id}` (summary card on the plan page) | `POST /v1/plans/{id}/simulate` | Is the AI plan better than the usual routes, and by how much, with uncertainty? | Person-hours avoided for AI vs usual, each with P10–P90, plus the delta with its own interval |
| A7 | Edit (optional) | plan page, edit mode | `PATCH /v1/plans/{id}`, then re-simulate | Swap an asset, retime, remove or add a task | Optimistic edit shows at once. The server returns a new version and What-If recomputes |
| A8 | Approve | plan page, ApproveBar → confirmation dialog | `POST /v1/plans/{id}/approve` (Idempotency-Key) | Approve, or reject with a reason | Plan is `approved`. The dialog summarised the impact, the assets, the alerts and the dispatch time |
| A9 | Watch dispatch (next morning) | plan page live status, `/console/fleet` | WS `plan:{id}` task lifecycle, `fleet` | Intervene on missed or skipped tasks | Tasks move dispatched → acknowledged → en route → in progress → done → verifying → verified |
| A10 | See proof | `/console/interventions/[id]`, `/console/impact` | `GET /v1/interventions/{id}/impact`, WS `impact` | Keep, move or cut this kind of deployment | Synthetic-control chart with CI band and spray annotations. Verdict and effect ± CI are shown |

```mermaid
sequenceDiagram
  autonumber
  actor O as Officer
  participant W as Web (Next.js)
  participant A as Backend api
  participant I as AI-ML (intel-worker / intel-service)
  participant D as dispatch-worker
  O->>W: Log in
  W->>A: POST /v1/auth/login (via /api/auth/login)
  A-->>W: tokens + user (role, ward_ids)
  W->>A: GET hotspots, twin tiles; WS subscribe twin, hotspots:ward, fleet
  Note over I: 18:30 master plan: optimiser → Planner → Auditor
  I-->>A: plan.drafted (Kafka) 
  A-->>W: WS plan:{id} plan.drafted → "Plan awaiting approval" banner
  O->>W: Open plan
  W->>A: GET /v1/plans/{id}
  W->>A: POST /v1/plans/{id}/simulate
  A->>I: POST /internal/v1/simulate
  I-->>A: plan vs usual routes (P10/P50/P90)
  A-->>W: What-If result
  O->>W: Resolve objection, edit a task
  W->>A: PATCH /v1/plans/{id} (If-Match version)
  A->>I: POST /internal/v1/optimize (if re-optimise)
  A-->>W: plan v+1
  O->>W: Approve → confirm
  W->>A: POST /v1/plans/{id}/approve (Idempotency-Key)
  A-->>W: 200 approved; WS plan.approved
  Note over D: 05:30 dispatch
  D-->>A: task.* lifecycle
  A-->>W: WS plan:{id} task.dispatched … task.verified
  A-->>W: WS impact impact.verified
  O->>W: Open impact → synthetic-control chart
```

### 3.1 The same flow, compressed: real-time spike (§8.2)

At 06:42 a bus flags a spike, and at 06:43 the hotspot is labelled "likely open burning". At 06:45 "Planner proposes the nearest inspection team; Auditor confirms a sprinkler would not help smoke. Officer taps approve." The web must support a `mode: spike` plan with a small task set. It raises an urgent toast plus the banner ("Spike plan for ward-084: 1 task, approve by 07:00"), and approval takes the same two presses. End-to-end budget: packet → hotspot on the officer map ≤ 60 s, spike → draft action ≤ 3 min ([../SYSTEM_OVERVIEW.md §3.1](../SYSTEM_OVERVIEW.md#31-real-time-spike-path-82)). Web share of that budget: a WS event reaches the rendered map in ≤ 2 s.

### 3.2 Flows B, C and D as the web sees them

| Flow | Web surface | What the officer sees |
|---|---|---|
| B: driver runs a route | Plan live status, fleet page, interventions | Stop auto-marked done when HawaTag detects flow + pump; spray segment appears; verification follows |
| C: school protection | Alerts, schools, forecast | Communicator's alert (en + hi), delivery status, safe window, indoor vs outdoor |
| D: Citizen Eyes | Reports, inspections, `/open/reports/[code]` | Photo, vision verdict, matched spike, ticket, outcome |

## 4. Features F1–F22 as surfaced in the web

Tier = the PDF tier (§6) as refined in [../SYSTEM_OVERVIEW.md §4](../SYSTEM_OVERVIEW.md#4-feature-map-6--owners). "Web tier" is what the web commits to for the hackathon.

| ID | Feature | PDF tier | Web surface | What the web shows | Web tier |
|---|---|---|---|---|---|
| F1 | Hotspot Grid Engine | BUILD | Map (500 m cells), forecast (1 km), key-cell outlines | Grid, key cells, ward boundaries | BUILD |
| F2 | Mobile sensing fleet | BUILD | Map pod trails (TripsLayer), devices | Buses and e-rickshaws streaming, with the Simulated badge | BUILD |
| F3 | Drive-by self-calibration | BUILD | `/console/devices/[id]` | Calibration versions, fit stats, trust | STRETCH |
| F4 | Air digital twin | BUILD | Map twin layer, cell drawer, time scrubber | Value ± range, confidence as opacity and hatching, staleness | BUILD |
| F5 | 72 h forecaster | BUILD | `/console/forecast`, map forecast mode, cell drawer mini-chart | P10/P50/P90 fan chart, forecast map by horizon | BUILD |
| F6 | Graded Response Copilot | BUILD | `/console/grap`, forecast strip | Stage outlook 3 days, probability, ward checklist | BUILD |
| F7 | Source fingerprint + back-trajectory | BUILD | Map suspect pins, trajectory, CauseBadge, hotspot detail | Cause + confidence, upwind suspect pin, path | BUILD |
| F8 | Smoky Vehicle Spotter | VISION | Marketing Hardware (HawaEye) only | — | VISION |
| F9 | Site Compliance Score | STRETCH | `/console/sites` | A/B/C grades, PM10 trend | STRETCH |
| F10 | Power-proxy compliance | VISION | Marketing only | — | VISION |
| F11 | Active sensing router (blind spots) | STRETCH | Map blind-spot layer, `/console/coverage` | Low-confidence cells, suggested route | STRETCH |
| F12 | Exposure engine | BUILD | Hotspot ranking, cell drawer, What-If | Person-hours above threshold with range | BUILD |
| F13 | Dispatch optimiser + What-If | BUILD | `/console/what-if`, plan summary card | AI plan vs usual routes, side-by-side maps | BUILD (never cut) |
| F14 | Multi-agent command room | BUILD | Plan detail: Planner rationale, Auditor objections, agent progress | Reasons, objections, resolutions | BUILD |
| F15 | Anti-gaming guard | STRETCH | `/console/integrity` | `station_clustering` flags with evidence | STRETCH |
| F16 | Targeted alerts | BUILD | `/console/alerts`, plan approve summary | Pollutant-specific alerts en + hi, delivery | BUILD (list), STRETCH (compose) |
| F17 | HawaTag intervention tracking | BUILD | Fleet page, plan live status, interventions | Spray segments, litres, auto-marked stops | BUILD |
| F18 | Causal verification + library | BUILD | `/console/interventions/[id]`, `/console/impact` | Synthetic-control chart, effect ± CI, library explorer | BUILD (never cut) |
| F19 | School safe-window scheduler | STRETCH | `/console/schools` | Safe windows, indoor vs outdoor | STRETCH |
| F20 | Citizen Eyes | STRETCH | `/console/reports`, `/console/inspections`, `/open/reports/[code]` | Queue, verification, ticket, outcome | STRETCH |
| F21 | Open Air Data portal | STRETCH | `/open`, `/open/api`, `/open/methods` | Public map + API docs + methods, "indicative" | STRETCH |
| F22 | Weekly Evidence report | VISION→STRETCH | `/console/evidence` | List, generate, download PDF | STRETCH |

## 5. Demo script mapping (§16.1)

Every scene in the three-minute video must be shown by a real screen. The screens should be recordable in one take on the golden-path seed (`make demo-reset`).

| Time | Scene (§16.1) | Page / component | What must be on screen | Data source |
|---|---|---|---|---|
| 0:00–0:20 | One AQI number vs a street-level map of the same morning; 376 smog guns, and no one knows which ones work | `/` → `Problem` section → `<OneNumberVsStreetMap>` + `<FleetStats>` | Left: a single "AQI 380" card. Right: the 500 m twin snapshot for the same morning. Counters: 376 / 266 / 91 / ~2,000 | Static snapshot image generated from a twin fixture, or live `/open/v1/air` |
| 0:20–0:50 | Live twin: buses streaming, hotspots appear with cause labels and upwind suspect pins | `/console/map`: `TwinLayer`, `PodTrailsLayer`, `HotspotLayer`, `SuspectPinLayer`, `TrajectoryLayer`, `<HotspotRail>`, `<CauseBadge>` | Animated trails with the Simulated badge, a hotspot appearing (WS `hotspots:{ward}`), cause icon + label + confidence, dashed back-trajectory to a pin | WS `twin`, `fleet`, `hotspots:{ward}` |
| 0:50–1:20 | 72 h forecast shows a spike near three schools; GRAP outlook turns orange for Thursday | `/console/forecast`: `<FanChart>`, forecast map at +h, `<VulnerablePlacesList>` ("3 schools in spike"), `<GrapOutlookStrip>` | Fan chart crossing the 250 µg/m³ line during school hours. Three school POIs highlighted. Thursday pill in the `poor` fill (orange = Stage I) | `GET /v1/forecast/{cell_id}`, `/v1/forecast/grid`, `/v1/grap/outlook` |
| 1:20–1:55 | Agents draft a plan; the Auditor rejects a sprinkler sent to a smoke hotspot; What-If: AI plan vs usual routes | `/console/plans/[id]`: `<AgentProgress>`, `<PlanTaskList>`, `<AuditorComment severity="blocking">`, `<WhatIfSummaryCard>` → `/console/what-if` `<WhatIfCompare>` | The objection text, its auto-applied resolution (sprinkler → inspection team), and person-hours avoided AI vs usual with ranges on side-by-side maps | `POST /v1/plans/draft`, WS `plan:{id}`, `POST /v1/plans/{id}/simulate` |
| 1:55–2:20 | Officer approves; driver route and school WhatsApp alert appear | `<ApproveBar>` → `<ApproveDialog>` → status `approved` → `/console/alerts` delivery | Confirmation summary, then status change. The driver route itself appears in the Flutter app and the WhatsApp message on a real test phone | `POST /v1/plans/{id}/approve`, WS `plan:{id}` |
| 2:20–2:45 | HawaTag logs a spray; the verifier shows the measured effect with a confidence interval | Plan live status → `/console/interventions/[id]` `<SyntheticControlChart>` + `<EffectSummary>` | Task moves to `in_progress` → `done` → `verified`. Chart with treated vs synthetic, CI band, spray start/stop lines. "PM10 −18.2 % (95 % CI −26.0 to −9.9)". For a simulated intervention: "Injected −20 %" next to the estimate | WS `plan:{id}`, `impact`; `GET /v1/interventions/{id}/impact` |
| 2:45–3:00 | Where AWS fits (architecture) and the closing line | `/` → `HowItWorks` → `<AwsArchitecture>`; `<Closing>` band above the footer | Architecture diagram (IoT Core, MSK, RDS PostGIS, ElastiCache, ECS Fargate, S3, Bedrock + Strands, SNS, Amplify). Closing line in large type | Static |

Seed requirement (flag to the backend/demo owner): the script says the outlook "turns orange for Thursday". In our palette orange is the `poor` fill, which is GRAP Stage I (AQI 201–300). The demo seed must produce Stage I for Thursday. Otherwise the pill is red (Stage II) and the voice-over must change.

## 6. Honesty rule in the web

"One real pod, a simulated fleet, a real pipeline" ([../SYSTEM_OVERVIEW.md §1.4](../SYSTEM_OVERVIEW.md#14-honesty-rule)). The PDF says the same: "Simulated devices publishing real packets over real MQTT (clearly labelled)" and "Causal verification running on simulated interventions with injected, known effects" (§12.5).

The web implements it as follows:

1. **`<SimulatedBadge>`** (violet `#7C3AED`, flask icon, text "Simulated" / "सिम्युलेटेड") is shown on every entity with `is_simulated: true`: devices, vehicles, assets, pod trails, fleet icons (violet ring), interventions, impacts, and plan tasks whose asset is simulated. It appears in tables, cards, drawers, tooltips, chart titles and dialog summaries. Badges are text, not only colour.
2. **Derived data** (twin cells, hotspots) is labelled "Includes simulated sensor data" when its simulated share is above 0 (proposed field `sim_share`, [ARCHITECTURE §18](ARCHITECTURE.md)). The cell drawer states the evidence, for example "7 readings: 5 simulated pods, 2 reference stations".
3. **Real hardware is called out.** The one physical HawaPod-M gets a "Real device" chip, so the honesty works in both directions.
4. **Console demo banner** (`NEXT_PUBLIC_DEMO_BANNER=true`): "Demo environment: the device fleet is simulated in the exact firmware packet format; the pipeline, models and agents are real." It is dismissible per session and never hidden in recordings.
5. **Verification with injected effects.** For simulated interventions, the impact page shows the injected effect beside the recovered estimate ("Injected −20 %, recovered −18.2 % (95 % CI −26.0 to −9.9)"). This is the proof that the verifier works (proposed field `injected_effect_pct`).
6. **What-If is an estimate.** It is labelled "Estimated on the forecast, not measured. Measured effects appear under Impact after the plan runs."
7. **Recorded fallback.** If the demo falls back to the mock API, a "Recorded scenario" banner appears. It cannot be turned off in `demo` builds.
8. **Low-cost sensors are indicative** (§12.4): "Official stations remain the legal record" appears on `/open`, `/open/methods` and in the marketing footer.

## 7. Uncertainty display rule

CONTRACTS §1: "Every model output carries its uncertainty … Never ship a bare point estimate to a UI." The web goes one step further and never *renders* one.

| Output | Field(s) | Default display | Interval level | Chart |
|---|---|---|---|---|
| Twin concentration | `pm25_est`, `pm25_var` (same for pm10) | `164 µg/m³ (80 %: 137–191)`, compact `164 ±27` | 80 % (±1.2816 σ, matching P10–P90) | Opacity + hatching on the map |
| Twin confidence | `confidence` (0–1) | `<ConfidenceMeter>` with a word: High ≥ 0.7, Medium 0.4–0.7, Low < 0.4 | — | Opacity ramp; hatch below 0.4 |
| Indicative AQI | `aqi` + PM range | `AQI 342 (range 318–367) · very poor · indicative` | from the PM 80 % range through CPCB breakpoints | Chip + range text |
| Cause | `cause_label`, `cause_conf` | `Dust · 78 %` | — | Icon + label, never hue alone |
| Forecast | `p10`, `p50`, `p90` | `P50 212 (P10 168 – P90 281)` | 80 % | Fan chart: band always on |
| GRAP outlook | stage + probability | `Stage I likely (72 %) · Stage II possible (18 %)` | probability | Pill + percentage |
| Exposure | `exposure_ph` + proposed `_p10/_p90` | `18,450 person-hours (80 %: 12,900–23,100)` | 80 % | Range bars |
| What-If delta | proposed `delta_ph {p10,p50,p90}` | `+11,330 more avoided (80 %: 6,800–15,200)` | 80 % (paired, from the server) | Range bar with zero line |
| Impact | `effect_pct`, `ci_low`, `ci_high`, proposed `ci_level` | `−18.2 % (95 % CI −26.0 to −9.9)` | from the API (`ci_level`) | CI band + whiskers |

Rules:
1. `<UncertaintyValue>` takes the interval as a **required** prop, so TypeScript rejects bare numbers. If the API ever omits uncertainty, the value renders as "uncertainty unavailable", which is visibly worse than a normal value. The error is logged.
2. The interval level is always printed ("80 %", "95 % CI"). It is never implied.
3. Chart bands cannot be switched off. Optional overlays (donor lines) can.
4. Low confidence recedes visually (opacity, hatching) and is flagged in text ("Low confidence: few readings nearby").
5. Rankings sort by P50 but flag overlaps ("#2 and #3 overlap within uncertainty").
6. The web never computes model uncertainty itself. It only converts units: variance → σ → 80 % range, and PM range → AQI range. The What-If delta interval must come from the server, because subtracting two intervals is wrong.

## 8. Usability goals

"Usability: officers approve plans in one click" (§1). We read this as **one decision, two presses**. The first press is Approve on the ApproveBar (reachable in one click from the console-wide "Plan awaiting approval" banner). The second is "Approve and dispatch" in the confirmation dialog, whose summary is the safety check that a human-in-the-loop system needs.

| Goal | Measure (hackathon acceptance) |
|---|---|
| Approve fast | From login to an approved prepared plan in ≤ 3 min on the golden path. From any console page to the approve dialog in ≤ 2 interactions |
| Everything explained | Every task shows `reason_text` without expanding. Every objection shows its resolution. No raw JSON, model IDs or agent transcripts on primary surfaces (they sit behind "Details") |
| No surprises | The confirmation dialog lists exposure avoided (with range), tasks by kind, assets, alerts by audience and language, dispatch time in IST, and any simulated assets |
| Right defaults | Ward preselected from the user's scope. Map opens on the ward bbox. Time is always IST. Units follow CONTRACTS §1 |
| Plain language | "Sprinkler", not `AST-SPR`; "person-hours above safe level", not `exposure_ph`. Tooltips define terms |
| Safe failure | Stale data is marked. Disconnected live updates are marked. Conflicting edits are caught (version check). Approval is idempotent |
| Keyboard-complete | Every action has a keyboard path. Command palette with Ctrl/Cmd+K. Map cell cursor |
| Demo legibility | 1920×1080 at 100 % zoom shows the map + hotspot rail + legend, or the plan task list + Auditor panel + ApproveBar, without scrolling |

## 9. Accessibility (summary)

WCAG 2.2 AA is the target. Full spec: [DESIGN_SYSTEM §13](DESIGN_SYSTEM.md#13-accessibility).
- Colour is never the only signal. AQI chips always carry the category name and number. Causes carry an icon and a label. Confidence is shown by opacity plus hatching plus a word. A colour-blind-safe map palette is available as a toggle.
- The map has keyboard pan and zoom, a grid "cell cursor", a text summary in a polite live region, and the hotspot rail as the list alternative.
- Every chart is a `<figure>` with a text summary and a "Show as table" toggle.
- Visible focus rings. Sticky bars never obscure focus (2.4.11). Targets are ≥ 24 px (2.5.8). Every drag interaction has a button alternative (2.5.7). Login accepts paste and password managers (3.3.8).
- `prefers-reduced-motion` stops trail animation, map fly-to and count-ups.

## 10. Bilingual: English and Hindi

- Every string lives in `messages/en.json` and `messages/hi.json` (next-intl). CI fails if the key sets differ.
- URLs: English has no prefix (`/console/map`) and Hindi uses `/hi/...` (next-intl `localePrefix: "as-needed"`). The officer's choice is stored in the `NEXT_LOCALE` cookie. The user's `lang` from `/v1/me` sets the first choice.
- Typography: Inter for Latin, Noto Sans Devanagari for Hindi, with taller line-height for Hindi and no uppercase transforms or letter-spacing on Devanagari ([DESIGN_SYSTEM §5](DESIGN_SYSTEM.md#5-typography)).
- Data stays in Latin digits and international units in both languages (`µg/m³`, `PM2.5`, IDs). Category names are translated with the CPCB Hindi terms (अच्छा, संतोषजनक, मध्यम, खराब, बहुत खराब, गंभीर).
- **Map labels stay in English.** MapLibre GL and the deck.gl TextLayer do not shape Devanagari correctly (conjuncts and vowel signs break), so no Hindi text is drawn inside WebGL. Hindi appears in the DOM UI around the map: legend, drawer, tooltips rendered as React.
- Alerts are authored and previewed in both languages. `POST /v1/alerts` requires both texts.

## 11. Performance on typical government office hardware and networks

| Dimension | Assumed target environment |
|---|---|
| Machine | Windows 10/11 desktop or laptop, Intel Core i3/i5 of the 8th–10th generation, integrated graphics (UHD 620/630), 8 GB RAM |
| Display | 1366×768 (common) up to 1920×1080 |
| Browser | Current Chrome or Edge. Firefox is supported. No IE or legacy Edge |
| Network | Shared office broadband or leased line, 10–50 Mbps, RTT 100–300 ms, sometimes a 4G hotspot. **HTTP proxies may block or strip WebSocket upgrades** |

Commitments (details in [ARCHITECTURE §12](ARCHITECTURE.md)):
- Map pan and zoom at ≥ 50 fps with the full 500 m grid (~6,000 cells), ~150 fleet icons and ~100 trails on the machine above.
- Marketing: LCP ≤ 2.5 s on a slow-4G profile. Console shell interactive in ≤ 3.5 s. First twin paint ≤ 3 s after the map route loads at 10 Mbps / 150 ms.
- deck.gl and MapLibre are code-split and load only on map routes.
- **WebSocket fallback:** after 3 failed connects within 60 s, the client switches to polling (twin meta 60 s, fleet 5 s, plan 10 s) and shows "Live updates via polling".
- Degrades cleanly on low-end hardware: no WebGL → table views plus a static map image. A "Lite map" toggle turns off trails and hatching.

## 12. Non-goals (hackathon)

- Driver, inspector, school principal, citizen and site manager apps (Flutter owns them). A site manager web view (`/console/sites/me`) is post-hackathon.
- Any client-side modelling. No interpolation, forecasting, optimisation, attribution or causal statistics in the browser.
- Automatic approval, scheduled auto-approve, or approve without the confirmation dialog.
- Offline console. The console needs the network. The field app is the offline-first surface.
- Native mobile layouts for the console. It is responsive down to 1024 px wide, with read-only fallbacks below that. Public pages are fully responsive down to 360 px.
- Publishing HawaEye clips or any faces or number plates (§12.4). The web never shows raw clips outside an authorised review queue, which is VISION.
- Replacing CPCB or the official record. The open portal says "indicative".
- Legacy browsers, IE11, and WebGL 1-only GPUs beyond the fallback.
- Payment, billing or multi-tenant SaaS administration (§14 is business, not build).

## 13. Glossary (for humans and agents)

| Term | Meaning |
|---|---|
| Twin | 500 m grid estimate of PM2.5/PM10 from Gaussian-process interpolation and wind advection, refreshed every 15 min, with variance and confidence per cell (F4, §9.4) |
| Hotspot | A connected cluster of high-exposure cells at one twin timestamp (CONTRACTS §10.3) |
| Suspect pin | Likely upwind source location found by back-trajectory (F7) |
| Person-hours (exposure) | `max(0, C − C_safe) × Pop × V × Δt`, reported as person-hours above threshold (CONTRACTS §10.4) |
| P10 / P50 / P90 | Forecast quantiles. P10–P90 is the 80 % band |
| GRAP | Delhi-NCR Graded Response Action Plan, Stages I–IV (CONTRACTS §10.2) |
| What-If | Estimated exposure avoided by a plan vs the usual routes, on the forecast (F13) |
| Synthetic control | Weighted combination of untreated, similar donor cells that predicts the treated cell without the spray. The gap is the effect (F18, §9.4) |
| Donor cell | An untreated cell used to build the synthetic control |
| Auditor | Strands agent that argues against the plan. It may object; the optimiser enforces hard constraints; the officer decides (F14) |
| Indicative AQI | Hourly AQI computed from twin values using CPCB breakpoints. It is not the official 24 h AQI |

<!-- footer:start -->

---

[Back to top](#web-frontend-context) · [Docs hub](../README.md) · [Project README](../../README.md)

<!-- footer:end -->
