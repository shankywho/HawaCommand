# HawaCommand Web Frontend: Documentation Index

Purpose: the entry point for the four-person team and for AI coding agents building `frontend/`. That folder holds the Next.js officer console, the public marketing site and the open data portal.

Related: [CONTEXT](CONTEXT.md) · [ARCHITECTURE](ARCHITECTURE.md) · [STRUCTURE](STRUCTURE.md) · [PAGES](PAGES.md) · [DESIGN_SYSTEM](DESIGN_SYSTEM.md) · [LINTING_AND_QUALITY](LINTING_AND_QUALITY.md) · [PLAN](PLAN.md) · [../CONTRACTS.md](../CONTRACTS.md) · [../SYSTEM_OVERVIEW.md](../SYSTEM_OVERVIEW.md) · [../backend/API.md](../backend/API.md)

---

## 1. What the web owns

HawaCommand runs a closed loop: Sense → Map → Attribute → Forecast → Decide → Act → Verify (§5). The web is the officer-facing and public-facing part of **ACT**: "Officer console React + deck.gl, open data API, evidence report" (§9). It is also where a human approves each plan and where every fix is shown to have worked.

| Surface | Route prefix | Audience | Rendering | Core features |
|---|---|---|---|---|
| Public marketing site | `/` (Hindi: `/hi`) | Judges, press, city officials, public | Static (SSG) per locale | Pitch and demo scenes 0:00–0:20 and 2:45–3:00 (§16.1) |
| Officer console | `/console/...` | Ward/district officer, analyst, admin | Client-heavy, behind auth | F1–F7, F9, F11–F22 (see [CONTEXT §4](CONTEXT.md#4-features-f1f22-as-surfaced-in-the-web)) |
| Open data portal | `/open/...` | Public, researchers, journalists | Static shell + client data | F21, AEROS/Soramame-style, labelled "indicative" |
| Public report status | `/open/reports/[code]` | Citizen who filed a Citizen Eyes report | Dynamic, read-only | F20 (outcome only) |
| Auth route handlers | `/api/auth/*` | Browser only | Node route handlers | httpOnly cookie session, CSRF |

**The web does not own:**
- Driver, inspector, school principal and citizen experiences. These are in the Flutter app ([../app/README.md](../app/README.md)).
- Business logic, optimisation, agents or verification. Those belong to backend and AI-ML. The web renders them, lets the officer edit and approve, and never recomputes a model output.
- The API contract. It belongs to the backend. The web generates its types from `/openapi.json` and must not hand-write response types.

## 2. Reading order

| Reader | Order |
|---|---|
| New human teammate | [CONTEXT](CONTEXT.md) → [ARCHITECTURE](ARCHITECTURE.md) → [PAGES](PAGES.md) (map, plan detail, What-If, impact first) → [DESIGN_SYSTEM](DESIGN_SYSTEM.md) → [LINTING_AND_QUALITY](LINTING_AND_QUALITY.md) → [PLAN](PLAN.md) |
| AI coding agent | [../CONTRACTS.md](../CONTRACTS.md) → [STRUCTURE](STRUCTURE.md) → the [PAGES](PAGES.md) section for the task → [DESIGN_SYSTEM](DESIGN_SYSTEM.md) tokens |
| Reviewer on a PR | [LINTING_AND_QUALITY §15–16](LINTING_AND_QUALITY.md#15-code-review-checklist) (checklist + DoD) → the relevant [PAGES](PAGES.md) acceptance criteria |
| Backend / AI-ML lead | [ARCHITECTURE §18](ARCHITECTURE.md#18-contract-additions-requested-by-the-web) (what the web needs from you) → [PAGES](PAGES.md) data sections |

## 3. Document index

| File | What it answers |
|---|---|
| [CONTEXT.md](CONTEXT.md) | Who uses the web, Flow A step by step, which features appear where, how each demo scene maps to a screen, the honesty and uncertainty rules, usability, accessibility, bilingual support, target hardware, non-goals |
| [ARCHITECTURE.md](ARCHITECTURE.md) | Stack, rendering per route group, data flow, API client, WebSocket client, auth, map layers, performance budget, errors, security, observability, hosting, contract additions |
| [STRUCTURE.md](STRUCTURE.md) | The complete `frontend/` tree, with one line of responsibility per file |
| [PAGES.md](PAGES.md) | Page-by-page spec: data, channels, wireframes, components, states, acceptance criteria. Also the marketing copy outline |
| [DESIGN_SYSTEM.md](DESIGN_SYSTEM.md) | The single source of truth for colours (the Flutter app mirrors it), typography, map styling, data-viz rules, components, content style, accessibility |
| [LINTING_AND_QUALITY.md](LINTING_AND_QUALITY.md) | ESLint 9 flat config, Prettier, tsconfig, git hooks, CI workflow, testing strategy, review checklist, Definition of Done |
| [PLAN.md](PLAN.md) | 24-hour build plan for the frontend developer, milestones, backend dependencies, mock-first strategy, cut rules, demo-day checklist, roadmap |

## 4. Quick start

Prerequisites: Node.js LTS pinned in `frontend/.nvmrc` (22 LTS, or 24 LTS once every host supports it) and pnpm via Corepack (`corepack enable`). The backend stack is optional because the web runs fully on mocks.

```bash
cd frontend
corepack enable
pnpm i                      # installs deps; `prepare` installs Husky hooks (see LINTING_AND_QUALITY §10)
cp .env.example .env.local  # defaults point at the local mock API
pnpm mock:api               # terminal 1: MSW-backed HTTP + WebSocket mock on :4010 (golden-path scenario)
pnpm dev                    # terminal 2: Next.js dev server (Turbopack) on :3000
```

Against the real stack: run `docker compose up` at the repo root ([../backend/README.md](../backend/README.md)). Set `NEXT_PUBLIC_API_URL=http://localhost:8000`, `NEXT_PUBLIC_WS_URL=ws://localhost:8000/v1/ws` and `API_URL_INTERNAL=http://localhost:8000`, then run `pnpm gen:api`.

| Command | What it does | Must pass before merge |
|---|---|---|
| `pnpm dev` | Next dev server (Turbopack) | — |
| `pnpm build` / `pnpm start` | Production build / serve | yes (CI) |
| `pnpm lint` | `eslint . --max-warnings 0` (type-aware, flat config) | yes, **zero warnings** |
| `pnpm format:check` | `prettier --check .` | yes |
| `pnpm typecheck` | `tsc --noEmit` | yes |
| `pnpm test` | Vitest unit + component tests (MSW node) | yes, coverage thresholds |
| `pnpm e2e` | Playwright golden path (Flow A) + axe against the mock API | yes |
| `pnpm gen:api` | `openapi-typescript` from `$API_OPENAPI_URL` → `src/lib/api/generated/schema.d.ts` + `openapi.snapshot.json` | run whenever the backend contract changes |
| `pnpm gen:api:check` | Regenerates into a temp dir and fails on drift | CI when the backend is reachable |
| `pnpm mock:api` | Standalone mock API (HTTP + WS) for dev and e2e | — |
| `pnpm i18n:check` | `messages/en.json` and `messages/hi.json` have identical key sets | yes |
| `pnpm knip` | Dead files, exports and dependencies (optional gate) | advisory |

## 5. Environment variables (summary)

Full table with per-stage values: [ARCHITECTURE §17](ARCHITECTURE.md#17-hosting-and-environments). `NEXT_PUBLIC_*` values are inlined at build time, so each stage gets its own build.

| Variable | Scope | Local default | Purpose |
|---|---|---|---|
| `NEXT_PUBLIC_APP_ENV` | client | `local` | `local` \| `demo` \| `aws`; drives banners and telemetry environment |
| `NEXT_PUBLIC_API_URL` | client | `http://localhost:4010` | Backend origin for browser REST and vector tiles |
| `NEXT_PUBLIC_WS_URL` | client | `ws://localhost:4010/v1/ws` | WebSocket endpoint (CONTRACTS §6.1) |
| `API_URL_INTERNAL` | server | `http://localhost:4010` | Backend origin for route handlers and server components |
| `API_OPENAPI_URL` | dev/CI | `http://localhost:8000/openapi.json` | Source for `pnpm gen:api` |
| `NEXT_PUBLIC_BASEMAP_PMTILES_URL` | client | `/basemap/delhi.pmtiles` | Protomaps Delhi-NCR extract |
| `NEXT_PUBLIC_BASEMAP_ASSETS_URL` | client | `/basemap/assets` | Glyphs and sprites for the basemap style |
| `NEXT_PUBLIC_MAPTILER_KEY` | client | empty | Optional alternative basemap |
| `NEXT_PUBLIC_API_MOCKING` | client | `off` | `off` \| `browser` (MSW service worker) |
| `NEXT_PUBLIC_DEMO_BANNER` | client | `true` | Shows the "Simulated fleet · real pipeline" console banner |
| `NEXT_PUBLIC_E2E` | client | `0` | Exposes map test hooks to Playwright |
| `NEXT_PUBLIC_SENTRY_DSN` | client | empty | Optional error reporting |
| `AUTH_COOKIE_SECURE` | server | `true` | Set `false` only when testing over plain http on a LAN IP |
| `AUTH_JWKS_URL` | server | empty | Optional JWT signature check in `proxy.ts` |
| `AUTH_REFRESH_MAX_AGE_S` | server | `604800` | Refresh cookie lifetime; must match the backend refresh TTL |

## 6. Non-negotiables (summary)

These come from [../CONTRACTS.md](../CONTRACTS.md) and [../SYSTEM_OVERVIEW.md](../SYSTEM_OVERVIEW.md). They are enforced by lint, types, tests and review.

1. **Uncertainty is always shown.** No bare model point estimate reaches the screen. Twin values carry a range or confidence, forecasts carry P10–P90, impacts carry a CI and What-If carries P10–P90 ([CONTEXT §7](CONTEXT.md#7-uncertainty-display-rule)).
2. **"Simulated" badge** on anything with `is_simulated: true`, plus a console-wide demo banner ([CONTEXT §6](CONTEXT.md#6-honesty-rule-in-the-web)).
3. **AQI is "indicative"** wherever the app computes it (CONTRACTS §10.1).
4. **Types come from OpenAPI** (`pnpm gen:api`). The generated client is imported only inside `src/lib/api`.
5. **Lint passes with zero warnings.** CI runs `--max-warnings 0`.
6. **English and Hindi** for every user-facing string. Times are shown in IST. Units follow CONTRACTS §1.
7. **WCAG 2.2 AA.** Colour is never the only signal, and the map and charts have keyboard and screen-reader paths.
8. **Nothing dispatches without officer approval.** The web never offers an automatic approve.
9. **Never drop the What-If screen or the impact/verification view** (§16 cut rule).

## 7. Contract additions and conflicts

The web needs several endpoints, fields and WebSocket channels that [../CONTRACTS.md](../CONTRACTS.md) does not yet define. Examples: twin run metadata, fleet trails, POIs, uncertainty on exposure, synthetic-control series, plan versions and WebSocket `pong`. All of them are listed with exact proposed names in [ARCHITECTURE §18](ARCHITECTURE.md#18-contract-additions-requested-by-the-web). Until the backend accepts them, the mock API serves the proposed shapes and pages degrade gracefully (see [PLAN §5](PLAN.md#5-mock-first-strategy)).

## 8. Links

- System context: [../SYSTEM_OVERVIEW.md](../SYSTEM_OVERVIEW.md). Golden path: [§10](../SYSTEM_OVERVIEW.md#10-golden-path-build-this-first)
- Binding contracts: [../CONTRACTS.md](../CONTRACTS.md), especially [§1 Conventions](../CONTRACTS.md#1-conventions), [§3 Enums](../CONTRACTS.md#3-enums), [§6 REST + WS](../CONTRACTS.md#6-public-rest--websocket-surface-index) and [§10 AQI/GRAP](../CONTRACTS.md#10-air-quality-reference-tables)
- Backend API (full shapes, auth): [../backend/API.md](../backend/API.md)
- Backend events: [../backend/EVENTS.md](../backend/EVENTS.md) · deployment: [../backend/DEPLOYMENT.md](../backend/DEPLOYMENT.md)
- AI-ML (twin, forecast, agents, verifier): [../aiml/README.md](../aiml/README.md)
- Flutter app (driver, inspector, school, citizen): [../app/README.md](../app/README.md)
