# HawaCommand frontend

Next.js 15 (App Router) · React 19 · Tailwind 3 · TanStack Query 5 · Zustand 5 · zod · MapLibre GL 4.7.1 · Cognito (aws-amplify 6).
Ported from the Claude Design prototype in `design/`. There is no deck.gl dependency; the map is a vendored web component on MapLibre.

```bash
cd frontend
pnpm install
pnpm dev          # next dev --turbopack -p 3000 -> http://localhost:3000
pnpm build        # next build (passes)
pnpm start        # next start -p 3000
pnpm typecheck    # tsc --noEmit (passes)
pnpm lint         # next lint: fails, no ESLint config is committed (opens the interactive setup)
```

Status per page, data sources and known issues: [docs/frontend/README.md](../docs/frontend/README.md).

### Environment (`.env.local`, see `.env.example`)

| Variable | Default | Effect |
|---|---|---|
| `NEXT_PUBLIC_API_URL` | empty | Empty: every `/v1/*` call is answered in the browser by `src/mocks/`. Set to `http://localhost:8000` to use the backend |
| `NEXT_PUBLIC_MAP_STYLE` | `https://tiles.openfreemap.org/styles/positron` | MapLibre style URL |
| `NEXT_PUBLIC_COGNITO_USER_POOL_ID`, `NEXT_PUBLIC_COGNITO_CLIENT_ID` | empty | Both set: Cognito sign-in on `/login`. Otherwise demo mode with no sign-in |

| Route | Screen |
|---|---|
| `/` | Landing page |
| `/login` | Officer sign-in (skipped in demo mode) |
| `/map` | Live hotspot map |
| `/forecast` | 72-hour forecast + GRAP |
| `/plans`, `/plans/[id]` | Plan review: diff, Auditor comment, approve & dispatch |
| `/what-if` | Usual routes vs plan |
| `/impact` | Verified interventions (synthetic control) |
| `/fleet` | Assets + HawaTag state |
| `/alerts` | School / citizen alerts + WhatsApp preview |
| `/route` | Hindi-first driver view (no manifest or service worker, so not installable as a PWA) |

## Connecting the backend

- `src/contracts/` holds the zod schemas for every API payload, imported through the `@hawa/contracts` path alias in `tsconfig.json` (not an npm package).
  [`../docs/backend/API.md`](../docs/backend/API.md) lists the endpoints the backend serves.
- `scripts/verify_backend_contracts.ts` fetches 14 backend endpoints and validates them against the zod schemas (needs a running backend on port 8000); it passed on 2026-10-10.
- With `NEXT_PUBLIC_API_URL` empty, `src/mocks/` answers every `/v1/*` call in the browser.
  Set it in `.env.local` (see `.env.example`) to use the real backend. No UI change is needed.
- `src/lib/api.ts` validates every response against the contracts, so shape mismatches show up as errors.
- Cognito sign-in turns on when `NEXT_PUBLIC_COGNITO_USER_POOL_ID` and `NEXT_PUBLIC_COGNITO_CLIENT_ID` are set.

## Layout

```
src/
  app/            (marketing) (auth) (console) (driver) route groups
  components/     shell ui map hotspots plans impact fleet alerts charts visuals
  contracts/      API schemas + types
  hooks/          one TanStack Query hook per API area
  lib/            api client, auth, formatting, demo clock, vendored map/pixel web components
  mocks/          in-browser mock API
  stores/         Zustand UI state
design/           Claude Design sources (not served)
```

The map is the design's `<hawa-gl>` web component (`src/lib/visuals`), wrapped by `components/map/HawaMap.tsx`.
The hotspot list, detail and heat field come from `/v1/hotspots`; truck routes, bus trails, schools and the suspect pin are still built-in demo data.

`amplify.yml` builds the app on AWS Amplify Hosting.
