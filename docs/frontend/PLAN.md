# Web Frontend Build Plan

<!-- nav:start -->

**Navigate:** [Project](../../README.md) · [Docs hub](../README.md) · [Overview](../SYSTEM_OVERVIEW.md) · [AWS architecture](../AWS_ARCHITECTURE.md) · [AWS setup](../AWS_SETUP_GUIDE.md) · [API](../backend/API.md) · [Environment](../ENVIRONMENT_VARIABLES.md) · [Contracts](../CONTRACTS.md)

**Web docs:** [Runbook](../../frontend/README.md) · [Index](README.md) · [Context](CONTEXT.md) · [Architecture](ARCHITECTURE.md) · [Pages](PAGES.md) · [Design system](DESIGN_SYSTEM.md) · [Quality](LINTING_AND_QUALITY.md) · [Structure](STRUCTURE.md) · **Plan** · [Design export](../../frontend/design/EXPORT_NOTES.md)

<!-- nav:end -->

> **Status (2026-10-10).** All console pages exist, and `pnpm typecheck` and `pnpm build` pass. `pnpm lint` fails because no ESLint config is committed. Open items: map overlays still use demo data, the What-If delta sign differs between backend and mocks, some copy is fixed, there is no sign-out, and the open-data portal, WebSocket and tests are Planned. Milestones below are the original plan.


Purpose: the hour-by-hour plan for the frontend developer across the 24-hour hackathon. It covers milestones with acceptance criteria, backend dependencies, the mock-first strategy, cut rules, the demo-day checklist and the roadmap afterwards.

Related: [README](README.md) · [CONTEXT](CONTEXT.md) · [ARCHITECTURE](ARCHITECTURE.md) · [STRUCTURE](STRUCTURE.md) · [PAGES](PAGES.md) · [DESIGN_SYSTEM](DESIGN_SYSTEM.md) · [LINTING_AND_QUALITY](LINTING_AND_QUALITY.md) · [../CONTRACTS.md](../CONTRACTS.md) · [../SYSTEM_OVERVIEW.md](../SYSTEM_OVERVIEW.md) · [../backend/API.md](../backend/API.md)

---

## 1. Ground rules

1. **Order is fixed by the PDF (§16) and [SYSTEM_OVERVIEW §11](../SYSTEM_OVERVIEW.md#11-hackathon-plan-24-h-team-of-four-16):** map shell / deck.gl / Amplify → twin heatmap → What-If screen → intervention view + approval flow.
2. **Mock-first.** The web never waits on the backend. Every endpoint has a fixture shaped exactly like API.md before its page is built (§5).
3. **BUILD before STRETCH.** STRETCH pages only start once M5 is green.
4. **One human lane plus one AI-agent lane.** The frontend dev owns the BUILD path. An AI coding agent, builds the independent pieces (marketing site, open portal, STRETCH pages). The dev reviews every agent PR against [LINTING_AND_QUALITY §15](LINTING_AND_QUALITY.md#15-code-review-checklist).
5. **Green main.** Lint (zero warnings), typecheck and unit tests pass on every merge. The Flow A e2e grows with each milestone.
6. **Never cut the What-If screen or the impact/verification view** (§16 cut rule).

## 2. Hour-by-hour

H = hours since the start. "Agent" = AI coding agent lane.

| Hours | Frontend dev (human lane) | Agent lane | Output / check |
|---|---|---|---|
| **0–1** | Scaffold with Sub-prompt A: Next 16 + TS strict + Tailwind v4 + shadcn + next-intl (`[locale]`, as-needed) + ESLint flat config + Prettier + Husky + commitlint + Vitest + Playwright + CI workflow | — | `pnpm check` green on an empty app. CI green |
| **1–2** | Tokens (`tokens.json`, `globals.css`), shell layout, `proxy.ts` guard, `/api/auth/*` handlers, login page against the mock | Mock API skeleton (`tests/mock-api/server.ts`), fixtures `me`, `twin.latest`, `hotspots`, `fleet.live`, sample MVT tiles | Log in on the mock and reach an empty `/console/map` |
| **2–3** | Map shell: `MapCanvas` (dynamic), react-map-gl + MapLibre + PMTiles basemap, `MapboxOverlay` interleaved, one dummy deck layer. Connect Amplify (or Vercel) with env vars | Marketing site Sub-prompt F starts (static, independent) | **M0** |
| **3–5** | Twin layer (`buildTwinLayer`: MVT, AQI fill, confidence opacity, hatch), legend, as-of chip + staleness, cell drawer v1 (values ± range, confidence, cause) | Marketing continues. `lib/format` (aqi, uncertainty, time, units) with ≥ 95 % tests | Twin renders from mock tiles at ≥ 50 fps |
| **5–7** | WS client (`HawaSocket`, router, resync) + channels `twin`, `hotspots:{ward}`, `fleet`. Hotspot outlines, rail, suspect pins, trajectories. Fleet `IconLayer` + trails `TripsLayer` | Golden-path WS scenario (`scenarios/golden-path.json`) + mock WS playback | Scenario steps move the map live |
| **7–8** | Map polish: toolbar, layer toggles, time scrubber (live + 15-min steps), Simulated badges, a11y summary, cell cursor | Forecast components: `FanChart`, `GrapOutlookStrip` (Sub-prompt pieces from PAGES §3.4–3.5) | **M1**. Integration checkpoint #1 |
| **8–10** | Plan detail **read-only**: header, task list with reasons, Auditor panel, Planner rationale, drafting state via WS `plan:{id}` | Forecast page assembly + GRAP page. Fixtures `forecast.*`, `grap.*` | Plan page renders the demo objection |
| **10–11** | Plans list + Draft plan dialog (`POST /v1/plans/draft` → 202 → drafting → drafted) | Hotspots table + detail | **M2** |
| **11–14** | **What-If screen** (Sub-prompt D): `ExposureRangeChart`, `SyncedMaps`, per-hotspot comparison, `WhatIfSummaryCard` on the plan page | Fleet page | **M3**. Cut check at H14 (§7). Integration checkpoint #2 |
| **14–16** | **Approval flow** (Sub-prompt C): ApproveBar states, ApproveDialog, approve/reject mutations (idempotent), ConflictDialog; edit ops with optimistic updates + `scope`, resolve objection, re-simulate | Interventions list + `VerdictBadge`, `EffectWhisker` | Approve on the mock, one request only |
| **16–17** | Live task status on the plan page (task lifecycle over WS) | Alerts list (delivery status) | **M4** |
| **17–19** | **Intervention / impact view** (Sub-prompt E): `SyntheticControlChart`, `GapChart`, `EffectSummary` (injected vs recovered), impact summary + effect table | Open portal Sub-prompt G (if M4 is green), else STRETCH polish | **M5**. Integration checkpoint #3 |
| **19–22** | Integration and bug bash (everyone): un-mock endpoint by endpoint (§5.4), `pnpm gen:api`, fix drift, Flow A e2e against the compose stack, perf pass on the reference laptop, Hindi pass, axe pass | STRETCH pages by priority (§7), only if M6 is on track | **M6** |
| **22–24** | Demo recording support (§8), screenshots, frontend README, blog draft section on the web architecture | — | **M7** |

## 3. Milestones and acceptance criteria

| Milestone | Due | Acceptance criteria (all must hold) |
|---|---|---|
| **M0: Shell deployed** | H3 | `pnpm check` + CI green (lint zero warnings, typecheck, unit, empty e2e). Hosted URL on Amplify or Vercel serves `/` and `/console/login`. Login on the mock API sets httpOnly cookies and reaches `/console/map`. The basemap renders with attribution. The EN/हि toggle works |
| **M1: Live map** | H8 | PAGES §3.2 acceptance 1–3 and 5 on the mock scenario: twin with confidence opacity and hatch, hotspots with cause + confidence + suspect pin + trajectory, animated trails with Simulated violet, fleet with heading, as-of chip and stale banner, cell drawer with 80 % ranges. `twin.updated` changes tiles without reload. Demo scene 0:20–0:50 recordable on the mock |
| **M2: Plan readable** | H11 | Plan list + detail show tasks with full reasons, expected effect ± CI, the Auditor's "sprinkler → smoke" objection with its resolution, and the Planner rationale. `POST /v1/plans/draft` → drafting → drafted via WS. Forecast page shows the fan chart with band + P50 and the GRAP strip with Thursday Stage I |
| **M3: What-If** | H14 | PAGES §3.8 acceptance: three range rows (AI, usual, delta from the server), "Estimated on forecast, not measured" label, two synced maps, per-hotspot table with at least one mismatch row. Plan page summary card links to it. Demo scene 1:20–1:55 recordable |
| **M4: Approve** | H17 | PAGES §3.7.9 criteria 1–6: disabled states explained, dialog numbers equal the What-If numbers for the same version, one idempotent approve request, optimistic edit + rollback, 409 conflict dialog, live task statuses over WS. Demo scene 1:55–2:20 recordable (web part) |
| **M5: Proof** | H19 | PAGES §3.10 acceptance: synthetic-control chart with treated, synthetic, band, spray start/stop, pre-period and verification brackets; effect with "95 % CI"; injected vs recovered for simulated; `impact.verified` updates live. Impact summary with whiskers. Demo scene 2:20–2:45 recordable |
| **M6: Real stack** | H22 | Flow A e2e (`@golden`) passes against `docker compose` (`pnpm e2e:stack`). `pnpm gen:api:check` clean. ≥ 50 fps on the reference laptop. `/hi` walkthrough done. axe clean on BUILD pages. Every remaining mock is listed and labelled |
| **M7: Demo ready** | H24 | §8 checklist complete. The marketing page covers scenes 0:00–0:20 and 2:45–3:00. Recording done or rehearsed twice |

## 4. Backend and AI-ML dependencies

Expected availability comes from [SYSTEM_OVERVIEW §11](../SYSTEM_OVERVIEW.md#11-hackathon-plan-24-h-team-of-four-16). "Proposed" items are in [ARCHITECTURE §18](ARCHITECTURE.md). They must be raised with the backend lead at H0, because the mock serves them from the start.

| Web need | Endpoint / channel | Owner | Expected real | Mock fixture | Web milestone |
|---|---|---|---|---|---|
| Login, me | `POST /v1/auth/login`, `/refresh`, `/logout`, `GET /v1/me` | Backend | H3–8 | `me.officer.json` | M0 |
| Twin meta + tiles | `GET /v1/twin/latest` (proposed), `/v1/twin/tiles/{z}/{x}/{y}.mvt` | Backend (tiles), AI-ML (cell_state) | H8–14 | `twin.latest.json`, `twin-tiles/*.mvt` | M1 |
| Hotspots | `GET /v1/hotspots`, `/v1/hotspots/{id}` | AI-ML → Backend | H8–14 (trajectory H14–19) | `hotspots.ward-084.json`, `hotspot.detail.json` | M1 |
| Fleet live + trails | `GET /v1/fleet/live`, `/v1/fleet/trails` (proposed), WS `fleet` | Backend (simulator H3–8) | H8–14 | `fleet.live.json`, `fleet.trails.json` | M1 |
| WebSocket | `/v1/ws` + channels | Backend | H8–14 | mock WS + `golden-path.json` | M1 |
| POIs, wards | `GET /v1/pois`, `/v1/wards` (proposed) | Backend seed | H8–14 | `pois.ward-084.geojson`, `wards.geojson` | M1 |
| Forecast + GRAP | `GET /v1/forecast/{cell_id}`, `/v1/forecast/grid`, `/v1/grap/outlook`, `/v1/grap/checklist` | AI-ML → Backend | H14–19 | `forecast.*.json`, `grap.*.json` | M2 |
| Plans | `POST /v1/plans/draft`, `GET /v1/plans`, `GET /v1/plans/{id}`, WS `plan:{id}` | Backend + AI-ML agents | H8–14 (agents 3–14) | `plans.list.json`, `plan.draft.json`, `plan.draft.v2.json` | M2 |
| What-If | `POST /v1/plans/{id}/simulate` (+ proposed quantile fields) | AI-ML intel-service | H8–14 | `plan.simulation.json` | M3 |
| Edit / approve | `PATCH /v1/plans/{id}` (proposed ops), `/approve`, `/reject` | Backend | H8–14 (approve), edit ops TBD | handlers with 409/422 flags | M4 |
| Task lifecycle | WS `plan:{id}` task events | Backend dispatch-worker | H14–19 | scenario steps | M4 |
| Impact | `GET /v1/interventions`, `/v1/interventions/{id}`, `/v1/interventions/{id}/impact` (+ proposed series), WS `impact` | AI-ML verifier + Backend | H14–19 | `interventions.list.json`, `impact.intervention.json` | M5 |
| Impact roll-up | `GET /v1/impact/summary`, `/v1/effectiveness` | AI-ML | H19–22 | `impact.summary.json`, `effectiveness.json` | M5 |
| Alerts | `GET /v1/alerts`, `POST /v1/alerts` | Backend notifier | H14–19 | `alerts.list.json` | STRETCH |

## 5. Mock-first strategy

### 5.1 Principles
- Fixtures are **JSON**, shaped exactly like [../backend/API.md](../backend/API.md). For proposed endpoints they follow ARCHITECTURE §18. They live in `src/mocks/fixtures/`, and the backend can reuse them in its own contract tests.
- **One handler set** (`src/mocks/handlers/*`) serves the browser worker (dev), `setupServer` (Vitest) and the standalone mock API on `:4010` (dev and Playwright). The standalone server is the default for development because the Next route handlers also call it server-side.
- The **golden-path scenario** (`src/mocks/scenarios/golden-path.json`) is a timed list of WS messages that drives the whole demo on mocks. Steps can be advanced on a timer or by `POST /__mock/scenario/golden-path/next` (e2e).

```json
{ "name": "golden-path", "steps": [
  { "at": "+0s",  "channel": "twin", "type": "twin.updated", "data": { "run_id": "…", "as_of": "2026-11-12T01:15:00Z", "tile_version": 412, "cells_updated": 5936 } },
  { "at": "+5s",  "channel": "hotspots:ward-084", "type": "hotspot.updated", "data": { "ward_id": "ward-084", "hotspot_ids": ["…"] } },
  { "at": "+20s", "channel": "plan:PLAN_ID", "type": "plan.drafted", "data": { "plan_id": "PLAN_ID", "task_count": 14 } },
  { "manual": true, "channel": "plan:PLAN_ID", "type": "task.dispatched", "data": { "task_id": "…" } },
  { "manual": true, "channel": "impact", "type": "impact.verified", "data": { "intervention_id": "…", "effect_pct": -18.2, "ci_low": -26.0, "ci_high": -9.9 } }
] }
```

### 5.2 Error and edge fixtures
Handlers accept `?__scenario=` or `X-Mock-Scenario` for: 401 (expired → refresh), 403 (ward), 409 `plan_version_conflict`, 422 `asset_unavailable`, 429 with `Retry-After`, 5xx, slow (3 s) and stale twin (`as_of` 40 min old). Every page state in PAGES can be reproduced this way.

### 5.3 Keeping mocks honest
- `tests/unit/fixtures.contract.test.ts` validates every fixture against `openapi.snapshot.json`. After each `pnpm gen:api`, failing fixtures are fixed **the same hour**.
- When API.md lands (it is being written in parallel), diff its examples against the fixtures and reconcile. Any disagreement goes to the backend lead, never silently patched on one side.
- Mocked data in dev shows the `DemoBanner`. If a demo build falls back to the mock, the "Recorded scenario" banner is forced on ([CONTEXT §6](CONTEXT.md#6-honesty-rule-in-the-web)).

### 5.4 Progressive un-mocking
`MOCK_PASSTHROUGH=/v1/auth,/v1/twin,/v1/hotspots` makes the mock API proxy those prefixes to `API_UPSTREAM` (the real backend) while it keeps serving the rest. Switch endpoints one at a time as backend checkpoints land. The final switch at H19–22 points `NEXT_PUBLIC_API_URL` straight at the backend.

## 6. Integration checkpoints

| When | With | Agenda (15 min) |
|---|---|---|
| H0 | All leads | Walk ARCHITECTURE §18 (proposed additions and conflicts). Agree on: `fleet.positions` shape, the `v` tile param, the plan `review` shape, simulate quantiles, impact `series`, the WS `pong`/subprotocol echo, CORS, JWT claims. Confirm the demo seed produces Stage I (orange) on Thursday |
| H8 | Backend, AI-ML | Real `/v1/auth`, twin tiles, hotspots, fleet, WS. Run `pnpm gen:api`. Pass through the working endpoints |
| H14 | Backend, agents | Plans + simulate + approve real? Objection shape matches? Cut decision (§7) |
| H19 | Everyone | Task lifecycle + impact real? Freeze the contracts. Start the bug bash |

## 7. Cut rules

If a milestone is **more than 1.5 h late**, cut from the top of this list. Re-check at H14 (the PDF's cut hour) and at H19.

1. `/console/admin`, `/console/evidence`, `/console/sites`
2. `/console/integrity`, `/console/coverage` (keep the blind-spots map layer toggle only if it already works)
3. `/console/reports`, `/console/inspections`, `/open/reports/[code]` (Citizen Eyes is cut by the PDF first anyway)
4. `/console/schools` (the school scheduler is cut by the PDF). Keep "3 schools in spike" on the forecast page from POIs
5. Alert compose (keep the alert list and delivery status)
6. Open data portal: keep `/open` map only if it can reuse the map builders in < 1 h, else a static "Coming soon" with the methods text
7. Devices pages (analyst)
8. Time scrubber historical mode (keep Live)
9. Plan diff view and re-optimise (keep the edit ops reassign/remove + resolve objection)
10. Edit mode entirely (keep read-only plan + objection resolution + approve/reject)
11. Animated trails (static paths instead), CVD palette toggle, Lite map
12. Marketing sections beyond Hero, Problem, HowItWorks (with architecture), Proof and Closing

**Never cut:** the map twin + hotspots with cause and confidence; the forecast fan chart + GRAP pill; the plan detail with reasons, Auditor objection and approve; **the What-If screen**; **the intervention impact chart with CI**; the Simulated badge; the uncertainty display; lint and typecheck passing.

## 8. Demo-day checklist

**T−24 h**
- [ ] Contracts frozen. `pnpm gen:api:check` clean against the demo backend.
- [ ] `demo` build deployed (Amplify branch `demo`) with `NEXT_PUBLIC_APP_ENV=demo`, the demo banner on, `NEXT_PUBLIC_E2E=0` and Sentry optional.
- [ ] CSP `connect-src` includes the demo API, WS and basemap CDN. Hard-reload the console with DevTools open and check there are no CSP errors.
- [ ] Basemap PMTiles and assets on CloudFront. Range requests verified.
- [ ] Flow A e2e passes against the demo stack (`pnpm e2e:stack`).
- [ ] Soak test: console open 2 h, memory stays below 600 MB, WS reconnects after the network is toggled.
- [ ] Demo seed checked: Thursday GRAP = Stage I (orange); 3 schools in the forecast spike; the "sprinkler → smoke" objection; one verified simulated intervention with its injected effect inside the CI.

**T−2 h**
- [ ] `make demo-reset` on the backend. The web shows a fresh twin (< 20 min old).
- [ ] Recording machine: Chrome (current), 1920×1080, browser zoom 100 %, OS scaling 100 %, extensions disabled, notifications off, light theme (or the team's choice), English first.
- [ ] Pre-warm: open the map, forecast, plan, What-If and intervention pages once (tiles and chunks cached). Then reload to start clean.
- [ ] Officer demo account signed in. The session refresh timer is not due mid-recording (sign in again 5 min before).
- [ ] A test phone for the WhatsApp alert and the Flutter driver app are ready (scene 1:55–2:20).

**T−10 min**
- [ ] The `LiveStatusDot` reads Live. The as-of chip is fresh. No banners other than the demo banner.
- [ ] Scene order rehearsed: `/` Problem → `/console/map` → `/console/forecast` → `/console/plans/[id]` → `/console/what-if` → approve → `/console/interventions/[id]` → `/` HowItWorks architecture → Closing.
- [ ] Hindi toggle shown once (2 s), then back to English.

**Fallback**
- [ ] If the live stack fails: switch `NEXT_PUBLIC_API_URL` to the mock API build (`demo-recorded` branch, built in advance). The "Recorded scenario" banner is on and **stays visible in the recording** (honesty rule).
- [ ] If WebGL fails on the machine: use the backup machine. The WebGL fallback is for users, not for the demo.

## 9. Web-specific risks

| Risk | Mitigation |
|---|---|
| Amplify lags on Next 16 SSR support | Check at H2. Vercel is ready as the alternative (same env). Container fallback is `NEXT_OUTPUT=standalone` |
| Proposed contract additions are rejected or late | The mock serves them. Pages degrade: trails hidden, scrubber uses generated ticks, What-If shows point estimates only if the server has no quantiles, with "uncertainty unavailable" visibly marked |
| deck.gl performance on the demo laptop | Measure at M1. Lite map. MapLibre-native fill fallback for the twin (ARCHITECTURE §12) |
| WebSocket blocked on venue Wi-Fi or a proxy | Polling fallback. Phone hotspot as backup network |
| Hindi strings late | English-only keys fail CI parity, so the agent lane fills `hi.json` drafts early and a native speaker reviews at H19–22 |
| AI-agent PRs drift from the contracts | Master prompt hard constraints. Lint boundaries. Fixture contract test. Human review against §15 |
| Token refresh during the recording | Sign in fresh at T−5 min (15 min access token). Silent refresh is tested in unit tests |

## 10. Post-hackathon roadmap

**Weeks 1–2 (hardening)**
- Land every ARCHITECTURE §18 addition in CONTRACTS and API.md. Remove the proposed-endpoint fallbacks.
- Nonce-based CSP for the console. SRI for static pages. Dependency audit gate. DPDP Act 2023 privacy review (citizen reports, recipient data).
- Make knip a gate. Add visual regression baselines. Lighthouse CI budgets.
- Complete the STRETCH pages that were cut. Hindi copy review of agent-generated reasons (`reason_text_hi`).

**Months 1–3 (pilot)**
- Swap auth to Cognito (JWKS verification in `proxy.ts`) if the pilot requires it. The cookie design is unchanged.
- A columnar twin values endpoint (static grid geometry + per-run values) for instant scrubbing and 24-frame preloading.
- One shared socket across tabs (SharedWorker or BroadcastChannel leader election).
- Site manager web view (`/console/sites/me`). HawaEye authorised review queue (VISION → build, with privacy controls).
- Evidence report builder with officer annotations. GRAP checklist persistence and agency hand-off.
- Offline-tolerant console views for low-connectivity wards (cached last plan + read-only map snapshot).
- Cache Components / PPR for public pages. SEO for `/hi` pages.
- An accessibility audit with real screen-reader users (NVDA on Windows, the government-office default).

<!-- footer:start -->

---

[Back to top](#web-frontend-build-plan) · [Docs hub](../README.md) · [Project README](../../README.md)

<!-- footer:end -->
