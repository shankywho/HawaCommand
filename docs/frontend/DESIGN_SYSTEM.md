# HawaCommand Design System

Purpose: the visual language, and the **single source of truth for colours** (the Flutter app mirrors this file). It also covers typography, layout tokens, icons, map styling, data-viz rules, motion, components, content style and accessibility.

Related: [README](README.md) · [CONTEXT](CONTEXT.md) · [ARCHITECTURE](ARCHITECTURE.md) · [STRUCTURE](STRUCTURE.md) · [PAGES](PAGES.md) · [LINTING_AND_QUALITY](LINTING_AND_QUALITY.md) · [PLAN](PLAN.md) · [../CONTRACTS.md](../CONTRACTS.md) · [../SYSTEM_OVERVIEW.md](../SYSTEM_OVERVIEW.md) · [../backend/API.md](../backend/API.md) · [../app/README.md](../app/README.md)

---

## 1. Principles

1. **Evidence first.** The UI exists to show *why* (cause, reasons, objections) and *whether it worked* (effect ± CI). Decoration never competes with data.
2. **Uncertainty is visible.** Ranges, bands, confidence and "indicative" labels are part of every value ([CONTEXT §7](CONTEXT.md#7-uncertainty-display-rule)).
3. **Colour is never the only signal.** Every coloured thing also carries a word, a number, an icon or a pattern. CPCB AQI colours are not colour-blind safe.
4. **Calm under pressure.** The console is used at 20:00 and 05:30 by tired officers. Neutral surfaces, one accent, danger only for real danger.
5. **Bilingual by default.** Every layout must hold Hindi strings, which run about 20–40 % longer, and Devanagari line-heights.
6. **Honest labelling.** Simulated is violet, everywhere, always with the word.

## 2. Colour tokens

The machine-readable source is `frontend/src/styles/tokens.json`. `globals.css` (CSS variables), `src/components/map/colors.ts` (deck.gl RGBA) and the Flutter theme are all generated from or checked against it. Any change needs a PR that updates this doc and `tokens.json`, and the Flutter lead is tagged.

### 2.1 Brand and semantic (shared tokens, exact values)

| Token | Light value | Dark-mode value | Use | Text on fill |
|---|---|---|---|---|
| `brand` | `#0E7C66` | fill `#0E7C66`; as text/lines `brand-fg-dark` `#2BB597` (derived) | Primary actions, focus ring, links, P50 lines, synthetic line | `#FFFFFF` (5.1:1) |
| `accent` / `warning` | `#F59E0B` | `#F59E0B` | Warnings, stale (amber), spray window, near-expiry | `#0B1220` (9.1:1) |
| `warning-fg` (derived) | `#B45309` | `#F59E0B` | Warning **text** on surfaces | — |
| `danger` | `#DC2626` | fill `#DC2626`; text `#F87171` (derived) | Blocking objections, errors, spike plans, adverse effects | `#FFFFFF` (4.8:1) |
| `info` | `#2563EB` | fill `#2563EB`; text `#60A5FA` (derived) | Info, trajectories, `on_task` fleet | `#FFFFFF` (5.2:1) |
| `simulated` | `#7C3AED` | fill `#7C3AED`; text `#A78BFA` (derived) | **Only** simulated data: badge, fleet ring, trails | `#FFFFFF` (5.7:1) |
| `ink` | `#0B1220` | — | Primary text (light), hotspot outlines, pins | — |
| `surface` | `#F8FAFC` | `#0B1220` | App background | — |
| `surface-elevated` | `#FFFFFF` (derived) | `#111A2E` | Cards, drawers, popovers | — |
| `surface-overlay` (derived) | `#FFFFFF` + shadow | `#18233B` | Dialogs, command palette | — |

### 2.2 Neutrals (derived, Tailwind slate family)

| Token | Light | Dark | Use |
|---|---|---|---|
| `foreground` | `#0B1220` | `#E2E8F0` | Body text |
| `muted-foreground` | `#475569` | `#94A3B8` | Secondary text, captions, axis labels |
| `muted` | `#F1F5F9` | `#1A2540` | Muted backgrounds, table stripes |
| `border` | `#E2E8F0` | `#24314D` | Decorative dividers only |
| `input` | `#64748B` | `#64748B` | Form-control boundaries (≥ 3:1, WCAG 1.4.11) |
| `ring` | `#0E7C66` | `#2BB597` | Focus ring |

### 2.3 AQI category fills (CPCB, exact values)

Categories follow CONTRACTS §10.1 (`AqiCategory`). The web computes the category from values with the CPCB breakpoints, and upper bounds are inclusive for continuous values: PM2.5 ≤ 30 / 60 / 90 / 120 / 250 / > 250; PM10 ≤ 50 / 100 / 250 / 350 / 430 / > 430; AQI ≤ 50 / 100 / 200 / 300 / 400 / > 400.

| Category | Fill | Text on fill | Border on light surfaces | Border on dark surfaces | CVD-safe alternative fill | English | Hindi |
|---|---|---|---|---|---|---|---|
| `good` | `#00B050` | `#0B1220` (6.6:1) | `#008A3E` | none needed | `#FDE725` | Good | अच्छा |
| `satisfactory` | `#92D050` | `#0B1220` (10.2:1) | `#5E8C2C` | none | `#7AD151` | Satisfactory | संतोषजनक |
| `moderate` | `#FFD600` | `#0B1220` (13.4:1) | `#9A8000` | none | `#22A884` | Moderate | मध्यम |
| `poor` | `#FF9900` | `#0B1220` (8.8:1) | `#B36B00` | none | `#2A788E` | Poor | खराब |
| `very_poor` | `#FF0000` | `#0B1220` (4.7:1) | `#B30000` | none | `#414487` | Very poor | बहुत खराब |
| `severe` | `#C00000` | `#FFFFFF` (6.5:1) | `#800000` | `#FCA5A5` (1 px) | `#440154` | Severe | गंभीर |

- The CVD alternative is a viridis ramp (dark = worse). Text on its fills: `#0B1220` for the first three, `#FFFFFF` for the last three. It is a user toggle (`palette: "cvd"`) and never changes the category names.
- The border columns exist because light fills (moderate yellow, satisfactory green) fall below 3:1 against `#F8FAFC`. Every chip on a light surface carries its border.
- Unknown or missing category: neutral `muted` fill + "—" + "No estimate".

### 2.4 GRAP stages

GRAP stage colours reuse the AQI band that triggers each stage (CONTRACTS §10.2). No new colours are added.

| `GrapStage` | Fill | Text | Extra encoding | Label (en / hi) |
|---|---|---|---|---|
| 0 | `muted` | `foreground` | outline only | None / कोई नहीं |
| 1 | `poor` `#FF9900` | ink | Roman numeral I | Stage I · Poor / चरण I · खराब |
| 2 | `very_poor` `#FF0000` | ink | II | Stage II · Very poor / चरण II · बहुत खराब |
| 3 | `severe` `#C00000` | white | III | Stage III · Severe / चरण III · गंभीर |
| 4 | `severe` `#C00000` | white | IV + 2 px ink border + diagonal stripe pattern | Stage IV · Severe+ / चरण IV · गंभीर+ |

Demo note: the §16.1 line "GRAP outlook turns orange for Thursday" is Stage I.

### 2.5 Other categorical encodings

| Domain | Values → encoding |
|---|---|
| `SiteGrade` | A → `brand` + "A"; B → `warning` + "B"; C → `danger` + "C" + stripe pattern |
| `ImpactVerdict` | effective → `brand` + check icon; no_detectable_effect → neutral + circle; inconclusive → neutral + dashed circle; adverse → `danger` + triangle |
| Objection severity | blocking → `danger` + octagon; warning → `warning-fg` + triangle; info → `info` + i |
| `TaskStatus` | pending/dispatched/acknowledged/en_route → neutral + step icon; in_progress → `info` + pulse dot; done/verifying → `brand` outline; verified → `brand` solid; inconclusive → neutral; skipped/missed/failed/cancelled → `danger` or neutral + word |
| `AssetStatus` (fleet) | available → `brand`; on_task → `info`; off_shift → `muted-foreground`; maintenance → `warning`; offline → `muted-foreground` + dashed ring |
| `CauseLabel` | **icon + label only, no hue** (§7). This keeps cause from being confused with AQI |
| Confidence | High ≥ 0.7, Medium 0.4–0.7, Low < 0.4: segmented meter in `foreground`, plus the word |

### 2.6 Data-viz series colours (non-AQI)

| Series | Colour | Rule |
|---|---|---|
| 1 | `brand` | Primary series, P50, synthetic counterfactual |
| 2 | `foreground` (ink / `#E2E8F0`) | Observed and treated |
| 3 | `info` | Secondary comparison (usual routes) |
| 4 | `warning-fg` `#B45309` | Annotations and windows |
| Sequential (exposure avoided) | `#E6F4F1` → `#A7DCCF` → `#5FBCA8` → `#0E7C66` → `#064E3F` | Single hue. Never AQI colours for person-hours |
| Diverging (effect %) | `danger` ← `muted` → `brand` | Reduction = brand, increase = danger |
| Reserved | `simulated` violet: simulated only. AQI fills: AQI only. `danger`: adverse, blocking, errors only | — |

### 2.7 Tokens in code

```css
/* src/app/globals.css (excerpt) */
@import "tailwindcss";
@import "tw-animate-css";
@custom-variant dark (&:where(.dark, .dark *));

@theme {
  --color-brand: #0E7C66;       --color-brand-fg-dark: #2BB597;
  --color-warning: #F59E0B;     --color-warning-fg: #B45309;
  --color-danger: #DC2626;      --color-info: #2563EB;
  --color-simulated: #7C3AED;   --color-ink: #0B1220;
  --color-aqi-good: #00B050;    --color-aqi-satisfactory: #92D050;  --color-aqi-moderate: #FFD600;
  --color-aqi-poor: #FF9900;    --color-aqi-very-poor: #FF0000;     --color-aqi-severe: #C00000;
  --font-sans: var(--font-inter), var(--font-noto-devanagari), ui-sans-serif, system-ui, sans-serif;
  --font-mono: ui-monospace, "Cascadia Mono", "Segoe UI Mono", Menlo, monospace;
  --radius-sm: 4px; --radius-md: 6px; --radius-lg: 8px; --radius-xl: 12px;
}
:root {
  --background: #F8FAFC; --foreground: #0B1220; --card: #FFFFFF; --muted: #F1F5F9;
  --muted-foreground: #475569; --border: #E2E8F0; --input: #64748B; --ring: #0E7C66;
  --primary: #0E7C66; --primary-foreground: #FFFFFF; --destructive: #DC2626;
}
.dark {
  --background: #0B1220; --foreground: #E2E8F0; --card: #111A2E; --muted: #1A2540;
  --muted-foreground: #94A3B8; --border: #24314D; --input: #64748B; --ring: #2BB597;
  --primary: #0E7C66; --primary-foreground: #FFFFFF; --destructive: #DC2626;
}
```

```json
// src/styles/tokens.json (shape; values as in §2.1–2.6)
{ "brand": { "base": "#0E7C66", "fgDark": "#2BB597" },
  "aqi": { "good": { "fill": "#00B050", "on": "#0B1220", "borderLight": "#008A3E", "cvd": "#FDE725" } },
  "grap": { "1": { "fill": "aqi.poor" } },
  "simulated": { "fill": "#7C3AED", "on": "#FFFFFF", "fgDark": "#A78BFA" } }
```

## 3. Contrast reference (computed, WCAG 2.x)

| Pair | Ratio | Passes |
|---|---|---|
| ink `#0B1220` on surface `#F8FAFC` | 18.0 | AAA |
| `#E2E8F0` on dark `#0B1220` / on `#111A2E` | 15.3 / 14.5 | AAA |
| muted `#475569` on `#F8FAFC`; `#94A3B8` on `#0B1220` | 7.2; 7.4 | AAA |
| white on brand `#0E7C66`; brand text on `#F8FAFC` | 5.1; 4.9 | AA |
| `#2BB597` on `#0B1220` (dark brand text) | 7.3 | AAA |
| ink on warning `#F59E0B`; `#B45309` text on `#F8FAFC` | 9.1; 4.8 | AA |
| white on danger; danger text on `#F8FAFC`; `#F87171` on dark | 4.8; 4.6; 6.8 | AA |
| white on info; info text on light; `#60A5FA` on dark | 5.2; 4.9; 7.4 | AA |
| white on simulated `#7C3AED`; `#A78BFA` on dark | 5.7; 6.9 | AA |
| ink on AQI good / satisfactory / moderate / poor / very_poor | 6.6 / 10.2 / 13.4 / 8.8 / 4.7 | AA |
| white on AQI severe | 6.5 | AA |
| input border `#64748B` on white / on `#0B1220` | 4.8 / 4.0 | ≥ 3:1 (1.4.11) |

Brand, danger, info and simulated fills **must not** be used as text colour in dark mode. Use the derived `*-fg-dark` values.

## 4. Never colour alone

| Thing | Non-colour encoding |
|---|---|
| AQI chip | Number + category word ("342 · Very poor") + "indicative" marker |
| Map cell | Category shown in tooltip, drawer and legend. AQI number drawn in the cell at zoom ≥ 14 (TextLayer, Latin digits). CVD palette toggle |
| Confidence | Opacity **and** hatching (< 0.4) **and** the word in tooltip and drawer |
| Cause | Icon + label |
| GRAP | Roman numeral + label + (IV) pattern |
| Status | Icon + word |
| Simulated | The word "Simulated" + flask icon (a violet ring on the map is always explained in the legend) |
| Charts | Direct labels on lines, a dashed vs solid distinction, and a legend with line-style samples |

Patterns (`src/styles/patterns.css` and `public/map/hatch.png`): diagonal hatch 45°, 1.5 px line, 6 px pitch, used for low confidence, "risk of worse" and site grade C. A vertical stripe 4 px marks GRAP IV.

## 5. Typography

- **Inter** (Latin) and **Noto Sans Devanagari** (Hindi) via `next/font/google`, variable weights, `display: swap`, exposed as `--font-inter` and `--font-noto-devanagari`. The stack in `--font-sans` puts Inter first, so Latin digits and IDs stay in Inter inside Hindi text.
- IDs (`g500-041-077`, `AST-SPR-0012`) use `--font-mono` at the same size as the surrounding text.
- All metrics use `font-variant-numeric: tabular-nums`.

| Token | Size / line-height (en) | Hindi line-height | Weight | Use |
|---|---|---|---|---|
| `display` | 48/56 (lg: 60/68) | 1.35 | 700 | Marketing hero |
| `h1` | 30/36 marketing · 24/32 console | 1.4 | 700 | Page titles |
| `h2` | 24/32 | 1.45 | 600 | Section titles |
| `h3` | 20/28 | 1.5 | 600 | Card titles, drawer titles |
| `body-lg` | 18/28 | 1.7 | 400 | Marketing body |
| `body` | 16/24 | 1.65 | 400 | Public pages, dialogs |
| `body-sm` | 14/20 | 1.6 | 400 | **Console base** (tables, forms) |
| `caption` | 12/16 | 1.5 (min size 13 px for Devanagari) | 500 | Labels, axis ticks, badges |
| `metric` | 28/32 tabular | — | 600 | KPI numbers |

Hindi rules:
- No `uppercase`, `small-caps` or letter-spacing on Devanagari. Scope any uppercase utility with `:lang(en)`.
- Minimum Devanagari text is 13 px. Weight ≥ 400 (Devanagari matras break up at light weights).
- Allow 40 % more width for Hindi labels in buttons and table headers. Never truncate a Hindi button label; wrap it.

## 6. Spacing, radius, elevation, layers, breakpoints

| Kind | Tokens |
|---|---|
| Spacing | Tailwind 4 px scale. Console: card padding 16, section gap 24, table row 40 (compact 32), toolbar 48, top bar 56, sidebar 240 (collapsed 64), drawer 400, right rail 360–420, ApproveBar 72 |
| Radius | `sm` 4 (chips, badges), `md` 6 (buttons, inputs), `lg` 8 (cards), `xl` 12 (dialogs, marketing cards), `full` (pills, dots) |
| Elevation (light) | e0 none · e1 cards `0 1px 2px rgb(11 18 32 / .06), 0 1px 3px rgb(11 18 32 / .10)` · e2 popovers/drawers `0 4px 12px rgb(11 18 32 / .12)` · e3 dialogs `0 12px 32px rgb(11 18 32 / .18)` |
| Elevation (dark) | Surface steps instead of shadows: `#0B1220` → `#111A2E` → `#18233B`, plus a 1 px `border` |
| z-index | map canvas 0 · map controls 10 · legend/scrubber 20 · rails 30 · drawer 40 · sticky bars 45 · popover/tooltip 50 · dialog 60 · toast 70 · command palette 80 · skip link 90 |
| Breakpoints | sm 640 · md 768 · lg 1024 (console minimum for editing) · xl 1280 (right column visible on plan page) · 2xl 1536. Design targets: 1366×768 (office) and 1920×1080 (demo) |

## 7. Iconography

Use **lucide-react**, 1.75 px stroke, sized 16 (inline) / 20 (buttons) / 24 (map atlas at 2×). Check the names against the installed lucide version, since lucide renames icons now and then.

| Meaning | Icon |
|---|---|
| Cause: dust | `Construction` |
| Cause: traffic | `Car` |
| Cause: burning | `Flame` |
| Cause: regional_smoke | `CloudFog` |
| Cause: mixed / unknown | `Layers` / `CircleHelp` |
| Sprinkler / anti-smog gun / sweeper / inspection team | `Droplets` / `SprayCan` / `Brush` / `ClipboardCheck` |
| HawaPod-M (vehicle) / HawaPod-S / HawaTag / HawaEye | `Bus` / `School` + `House` pair / `Tag` / `Cctv` |
| School / hospital / elder care | `School` / `Hospital` / `HeartHandshake` |
| Simulated / real device | `FlaskConical` / `BadgeCheck` |
| GRAP | `ShieldAlert` |
| Plan / What-If / Impact | `Route` / `Scale` / `ChartLine` |
| Auditor objection / Planner | `MessageSquareWarning` / `Lightbulb` |
| Live / reconnecting / polling / offline | `Radio` / `RefreshCw` / `Timer` / `WifiOff` |
| Stale | `Clock` |

The suspect pin is custom: a teardrop 28×36 px with the cause glyph inside. The map atlas is built by `scripts/build-map-icons.mjs`.

## 8. Map styling rules

| Element | Rule |
|---|---|
| Basemap | Protomaps `light` / `dark` flavour, desaturated (roads grey, water `#DCE6F0` light / `#15203A` dark, parks barely tinted). Labels in English above the data layers. Attribution always visible |
| Twin cell fill | AQI category of the selected pollutant (or indicative AQI), from the palette in §2.3 (or CVD) |
| Twin cell opacity | `alpha = 0.25 + 0.60 × clamp(confidence, 0, 1)` → 0.25–0.85 (deck `alpha × 255`) |
| Low confidence | `confidence < 0.4` adds the diagonal hatch (ink at 35 % on light, white at 35 % on dark) |
| Cell outline | None by default. Selected: 3 px white + 1 px ink casing (inverted in dark) |
| Key cells (F1) | 1 px dotted `foreground` at 40 % when "Key cells" is on |
| Hotspot outline | 2.5 px ink with 1 px white casing (dark: white with ink casing). Rank number in a 18 px ink circle with white Latin digits |
| Cause label | Icon + label chip in the rail and tooltip. On the map, only via the suspect pin glyph |
| Suspect pin | Teardrop, ink fill, white glyph + 2 px white stroke. Scale 0.8–1.2 by `cause_conf`. Dashed 1.5 px ink-60 % link line from the hotspot centroid |
| Back-trajectory | `info` 3 px dashed `[6, 4]`, arrowheads pointing toward the hotspot (the direction the air travelled), hourly ticks (3 px white dots with `info` stroke) labelled "−1 h", "−2 h" at zoom ≥ 13 |
| Pod trails | TripsLayer 3 px, 10 min fade. **Simulated = violet** (`#7C3AED`, dark `#A78BFA`). Real device = `brand`. Head marker is a 6 px dot |
| Fleet | 24 px directional disc rotated to heading, asset-type glyph inside, status colour (§2.5), simulated = 2 px violet outer ring, spraying = pulse ring (static under reduced motion). Stale > 2 min at 50 % opacity |
| POIs | 20 px rounded square, ink fill, white glyph. In a forecast spike: 3 px `danger` halo + list entry |
| Blind spots | 2 px dashed `muted-foreground` outline, "?" glyph at centroid (zoom ≥ 13). Suggested route: 2 px dotted `brand` |
| Ward boundaries | 1 px `muted-foreground` at 60 %. Selected ward 2 px ink |
| Forecast mode | 1 km cells, P50 category at fixed 0.7 opacity. "Risk of worse" hatch in the P90 category colour where the P90 category is worse than P50 |
| What-If maps | Sequential brand ramp (§2.6) for person-hours avoided. Routes one colour per asset from a fixed 6-colour set that excludes violet and the AQI fills. Legend always shown |
| Legend | Always available, collapsible. Category names + ranges, confidence ramp + hatch sample, symbols, "violet = simulated" |

## 9. Data-viz rules

1. **Uncertainty bands are always shown.** Forecast: P10–P90 band + P50 line (§2.6 series 1). Impact: counterfactual band + CIs. What-If: P10–P90 range bars. A band cannot be toggled off.
2. The P50 or point line is 2 px solid. Counterfactuals are dashed. Observed data uses `foreground`.
3. Point estimates in tables use **CI whiskers** (dot + whisker) with a visible zero line for effects.
4. Every interval states its level ("80 %", "95 % CI") in the legend or label.
5. Axes carry units (µg/m³, person-hours, %) and IST time. Effect and exposure charts start at zero unless "Zoom to data" is on, and then the axis is annotated.
6. No log scales, no 3D, no pie charts, no dual y-axes (use two panels instead).
7. "Indicative" appears under any AQI or low-cost-gas visual.
8. Colours follow §2.6. AQI colours appear only as faint background bands (8 % opacity) on concentration charts.
9. Tooltips list every quantile, not just P50.
10. Each chart has a `ChartFigure` summary sentence and a table view.

## 10. Motion

| Motion | Spec | Reduced motion |
|---|---|---|
| UI transitions (popover, sheet, dialog) | 150–200 ms ease-out (`tw-animate-css`) | Instant |
| Fleet position | Linear interpolation over 1000 ms between 1 Hz updates | Jump |
| Pod trails | TripsLayer animation ≤ 30 fps | Static trails (last 10 min) |
| Map fly-to on selection | 600 ms | `jumpTo` |
| New hotspot | One pulse ring, 1.2 s | Static outline + live-region message |
| Marketing counters | 800 ms count-up once | Final numbers |
| Skeletons | Subtle shimmer | Static |

No motion loops longer than 5 s, except the live trails, which the user can pause via Lite map.

## 11. Component inventory

### 11.1 shadcn/ui (Radix) components used

`accordion`, `alert`, `alert-dialog`, `avatar`, `badge`, `breadcrumb`, `button`, `calendar`, `card`, `chart` (Recharts wrapper), `checkbox`, `collapsible`, `command` (cmdk), `dialog`, `dropdown-menu`, `form`, `hover-card`, `input`, `label`, `pagination`, `popover`, `progress`, `radio-group`, `resizable`, `scroll-area`, `select`, `separator`, `sheet`, `sidebar`, `skeleton`, `slider`, `sonner`, `switch`, `table`, `tabs`, `textarea`, `toggle`, `toggle-group`, `tooltip`.

### 11.2 Custom components

| Component | Props | Rules |
|---|---|---|
| `AqiChip` | `value: number; range?: [number, number]; category?: AqiCategory; pollutant?: "aqi" \| "pm25" \| "pm10"; size?: "sm" \| "md"; indicative?: boolean /* default true */` | Fill + text-on + light border. Shows the number and the word. Range text when given. "indicative" as a superscript marker with a tooltip |
| `ConfidenceMeter` | `value: number /* 0–1 */; showValue?: boolean; size?: "sm" \| "md"` | 5 segments + word (High/Medium/Low). `role="meter"` with `aria-valuenow`, `aria-valuetext="High, 0.72"` |
| `CauseBadge` | `cause: CauseLabel \| (string & {}); confidence?: number; variant?: "solid" \| "outline"` | Icon + localised label + "78 %". Unknown values render "Unknown" neutrally (CONTRACTS §12.5) |
| `SimulatedBadge` | `variant?: "simulated" \| "includes" \| "recorded"; size?: "sm" \| "md"` | Violet fill, white text, flask icon. "Simulated" / "Includes simulated data" / "Recorded scenario". Never icon-only |
| `RealDeviceChip` | — | Brand outline + `BadgeCheck` + "Real device" |
| `GrapStagePill` | `stage: GrapStage; probability?: number; day?: string; size?: "sm" \| "md"` | §2.4 encodings. "Stage I · 72 %" |
| `UncertaintyValue` | `value: number; interval: { low: number; high: number; level: number } \| { unavailable: true }; unit: Unit; format?: "full" \| "compact"; signed?: boolean` | `interval` is **required**. Full: "164 µg/m³ (80 %: 137–191)". Compact: "164 ±27" with the full text in a tooltip and `aria-label`. Negative ranges use "to" ("−26.0 to −9.9") |
| `PlanTaskCard` | see [PAGES §3.7.3](PAGES.md#373-components) | Reason text is never truncated below 4 lines |
| `AuditorComment` | `objection; taskLabel?; canResolve; onApply(); onOverride(note)` | Severity icon + word, source label, resolution line, actions |
| `ApproveBar` | `plan; simulation; pendingOps; role` | Sticky, e2 elevation, 72 px, disabled reasons wired via `aria-describedby` |
| `StaleDataBanner` | `asOf: string; thresholds: {amberMin, redMin}; subject: "twin" \| "forecast"` | Amber/red with `Clock` icon. Text includes the age |
| `LiveStatusDot` | `status: WsStatus` | Dot + word. `aria-live="polite"` on change |
| `ChartFigure` | `title; summary: string; table: {columns, rows}; children` | `<figure>`/`<figcaption>`, "Show as table" toggle |
| `EmptyState` | `icon; title; body; lastChecked?: string; action?` | Always says why and when |
| `VerdictBadge`, `SiteGradeChip`, `EffectWhisker`, `IstTime`, `PersonHours` | see STRUCTURE | Follow §2.5 and §12 |

## 12. Content style

**Voice:** plain, specific and calm. Say what happened, why, and what to do. Prefer verbs ("Approve and dispatch", "Draft plan"). No hype, exclamation marks or emojis.

| Topic | Rule | Example |
|---|---|---|
| Time | IST, 24-hour, with "IST" in headers and dialogs | "06:45 IST", "Thu 13 Nov, 05:30 IST" |
| Relative time | Short units | "7 min ago", "1 h 12 min old" |
| Numbers | `en-IN` grouping. Console shows full digits; marketing may use lakh/crore | "18,450", "₹22–24 lakh" |
| Negatives | True minus sign (U+2212) | "−18.2 %" |
| Units (CONTRACTS §1) | Space before the unit; SI symbols | "164 µg/m³", "61 ppb", "1,210 ppm", "38.5 L/min", "14 km/h", "82 %" |
| Ranges | En dash for positive ranges, "to" when a bound is negative | "137–191", "−26.0 to −9.9" |
| Exposure | "person-hours above safe level" (short: "person-hours") | "18,450 person-hours" |
| AQI | Always "indicative" for computed AQI | "AQI 342 · Very poor (indicative)" |
| IDs | Monospace, never translated | `g500-041-077` |
| Machines | Human names first, ID second | "Sprinkler AST-SPR-0012" |
| Errors | What happened + what to do + request id | "Could not approve: the plan changed (v3 → v4). Review the changes and approve again." |

**Hindi copy guidelines:**
- Use simple, everyday Hindustani, not Sanskritised Hindi. Keep common English technical terms in Latin script where officers already use them: AQI, PM2.5, PM10, GRAP, ID, SMS, WhatsApp.
- Digits stay Latin (international numerals). Units stay as symbols.
- Use CPCB's Hindi category names (§2.3).
- Never machine-translate agent text silently. Agent reasons without a Hindi version display in English with `lang="en"` and the note "(अंग्रेज़ी में)".
- A native speaker on the team reviews every `hi.json` change (PR checklist).

| English | Hindi |
|---|---|
| Simulated | सिम्युलेटेड |
| Indicative | सांकेतिक |
| Confidence (High/Medium/Low) | भरोसा (उच्च / मध्यम / कम) |
| Uncertainty / range | अनिश्चितता / दायरा |
| Dust / Traffic / Burning / Regional smoke | धूल / ट्रैफ़िक / खुले में जलाना / क्षेत्रीय धुआँ |
| Hotspot | हॉटस्पॉट |
| Forecast | पूर्वानुमान |
| Plan / Approve and dispatch / Reject | योजना / मंज़ूर करें और भेजें / अस्वीकार करें |
| Auditor objection | ऑडिटर की आपत्ति |
| Person-hours above safe level | सुरक्षित स्तर से ऊपर व्यक्ति-घंटे |
| Effect / confidence interval | प्रभाव / विश्वास अंतराल |
| Live / Reconnecting / Stale | लाइव / फिर से जुड़ रहा है / पुराना डेटा |

## 13. Accessibility

Target: **WCAG 2.2 AA** for all pages. axe runs in e2e on every route in both locales ([LINTING_AND_QUALITY §14](LINTING_AND_QUALITY.md#14-testing-strategy)).

| Area | Requirement |
|---|---|
| Contrast | Text ≥ 4.5:1 (large ≥ 3:1), UI boundaries ≥ 3:1 (§3) |
| Focus | 2 px `ring` + 2 px offset on every interactive element, never removed. Focus is not obscured by sticky bars (`scroll-padding-bottom`, WCAG 2.4.11) |
| Keyboard | Everything operable by keyboard. Logical tab order. Skip link. Drawers and dialogs trap focus and return it on close (Radix). Esc closes |
| Map | MapLibre and deck keyboard pan/zoom. **Cell cursor** (C, arrows, Enter, Esc) when the map is focused. Hotspot rail as the list alternative. `aria-label` on the canvas region with instructions. Text summary in a polite live region (throttled). Single-key shortcuts only while the map is focused (2.1.4) |
| Charts | `ChartFigure` summary + table toggle. Tooltips reachable by keyboard (arrow keys move the active point) |
| Target size | ≥ 24×24 px for all targets (2.5.8), 32 px for primary map controls |
| Dragging | Every drag has buttons (task ↑/↓, scrubber steps) (2.5.7) |
| Authentication | Paste and password managers allowed. No cognitive test (3.3.8) |
| Consistent help | Help and shortcut links in the same place on every console page (3.2.6) |
| Motion | `prefers-reduced-motion` honoured (§10). No flashing |
| Language | `<html lang="en|hi">`. Inline `lang` for mixed content |
| Screen readers | Status changes (WS, approve result) announced politely. Errors announced assertively. Icons are `aria-hidden` with visible text beside them |
| Zoom | Works at 200 % browser zoom (console reflows to single column) and 400 % on public pages (1.4.10) |
