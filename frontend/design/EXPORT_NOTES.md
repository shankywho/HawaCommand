# HawaCommand — final frontend prototype

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
