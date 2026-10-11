# HawaCommand — final frontend prototype

<!-- nav:start -->

**Navigate:** [Project](../../README.md) · [Docs hub](../../docs/README.md) · [Overview](../../docs/SYSTEM_OVERVIEW.md) · [AWS architecture](../../docs/AWS_ARCHITECTURE.md) · [AWS guide](../../docs/AWS_SETUP_GUIDE.md) · [API](../../docs/backend/API.md) · [Environment](../../docs/ENVIRONMENT_VARIABLES.md) · [Contracts](../../docs/CONTRACTS.md)

<!-- nav:end -->

> **Status (2026-10-10).** Historical export notes. The prototype was ported into `frontend/src/` (route groups `(marketing)`, `(console)`, `(driver)`); it was **not** copied into `frontend/public/prototype/`, so the `/prototype/*.html` URLs below do not exist. The design sources live in `frontend/design/source/` (`*.dc.html` pages plus `hawa.js`, `hawa-gl.js`, `pixel.js` and helpers); `hawa.js`, `hawa-gl.js` and `pixel.js` are vendored into `frontend/src/lib/visuals/`. The paths `apps/web/...` and `hawacommand/apps/web/...` refer to an earlier monorepo layout.

Copy `apps/web/public/prototype/` into `hawacommand/apps/web/public/`.
Next.js serves it statically:

- /prototype/index.html   — Landing
- /prototype/console.html — Officer console (v4)
- /prototype/mobile.html  — Driver PWA, school alert, Citizen Eyes

Self-contained: no build step. External: Google Fonts, lucide (unpkg), MapLibre + OpenFreeMap tiles.
All data is simulated in hawa.js / hawa-gl.js — swap for `src/lib/api.ts` + `src/lib/live.ts` when porting to the (console)/(driver)/(marketing) route groups.

Suggested port map:
- index.html   → src/app/(marketing)/page.tsx
- console.html → src/app/(console)/* ; map → src/components/map, hotspot list → components/hotspots, plan review → components/plans, impact chart → components/impact
- mobile.html  → src/app/(driver)/*
- Palette: ink #0B1215, paper #FAF9F6, line #E6E3DC, teal #0F766E; CPCB bands Good #1B7F45 → Severe #7F1D3A. Fonts: Geist, Geist Mono, Silkscreen (chips only), Noto Sans Devanagari.

<!-- footer:start -->

---

**Related across the project:** [Design system](../../docs/frontend/DESIGN_SYSTEM.md) · [Pages](../../docs/frontend/PAGES.md)

[Back to top](#hawacommand--final-frontend-prototype) · [Docs hub](../../docs/README.md) · [Project README](../../README.md)

<!-- footer:end -->
