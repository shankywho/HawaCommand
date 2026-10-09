# HawaCommand frontend

Next.js 15 (App Router) · Tailwind · TanStack Query · Zustand · MapLibre · Cognito (aws-amplify).
Ported from the Claude Design prototype in `design/`.

```bash
cd frontend
pnpm install
pnpm dev        # http://localhost:3000
pnpm build      # production build + typecheck
```

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
| `/route` | Hindi-first driver PWA |
| `/prototype/index.html` | Original design export, for visual comparison |

## Connecting the backend

- `src/contracts/` holds the zod schemas for every API payload (imported as `@hawa/contracts`).
  `../docs/API.md` lists the endpoints the backend must serve.
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

The map is still the design's `<hawa-gl>` web component (`src/lib/visuals`), wrapped by `components/map/HawaMap.tsx`.
It draws its own demo pollution field; feeding it `/v1/hotspots` cells is the next step.
