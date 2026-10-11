# Web design system

<!-- nav:start -->

**Navigate:** [Project](../../README.md) · [Docs hub](../README.md) · [Overview](../SYSTEM_OVERVIEW.md) · [AWS architecture](../AWS_ARCHITECTURE.md) · [AWS guide](../AWS_SETUP_GUIDE.md) · [API](../backend/API.md) · [Environment](../ENVIRONMENT_VARIABLES.md) · [Contracts](../CONTRACTS.md)

**Web docs:** [Runbook](../../frontend/README.md) · [Index](README.md) · [Architecture](ARCHITECTURE.md) · [Pages](PAGES.md) · **Design system** · [Deployment](DEPLOYMENT.md)

<!-- nav:end -->

<p align="center">
<img src="https://img.shields.io/badge/paper-%23FAF9F6-FAF9F6" alt="paper">
<img src="https://img.shields.io/badge/ink-%230B1215-0B1215" alt="ink">
<img src="https://img.shields.io/badge/teal-%230F766E-0F766E" alt="teal">
<img src="https://img.shields.io/badge/fonts-Geist%20%C2%B7%20Noto%20Devanagari-6E7781" alt="Fonts">
<img src="https://img.shields.io/badge/icons-lucide-F56565" alt="lucide">
</p>

The tokens and rules every console screen follows. Source of truth: [`frontend/tailwind.config.ts`](../../frontend/tailwind.config.ts); the Flutter app mirrors them in `lib/app/theme/tokens.dart`.

---

## Colour

| Token | Value | Use |
|---|---|---|
| `paper` | ![#FAF9F6](https://img.shields.io/badge/-%23FAF9F6-FAF9F6) | Page background |
| `ink` | ![#0B1215](https://img.shields.io/badge/-%230B1215-0B1215) | Text and primary actions |
| `ink-2` | ![#1C272C](https://img.shields.io/badge/-%231C272C-1C272C) | Secondary text on dark |
| `muted` | ![#4A555B](https://img.shields.io/badge/-%234A555B-4A555B) | Labels, captions |
| `line` | ![#E6E3DC](https://img.shields.io/badge/-%23E6E3DC-E6E3DC) | Borders and dividers |
| `teal` | ![#0F766E](https://img.shields.io/badge/-%230F766E-0F766E) | Brand accent, selection, links |
| `danger` | ![#C02A2A](https://img.shields.io/badge/-%23C02A2A-C02A2A) | Errors, destructive actions |
| `sand` | ![#B39571](https://img.shields.io/badge/-%23B39571-B39571) | Landing page accent background |

---

## AQI bands (data only)

CPCB categories, used **only for data** (cells, chips, charts), never for buttons or chrome.

| Band | Colour | PM2.5 (µg/m³) |
|---|---|---|
| Good | ![#1E8A4C](https://img.shields.io/badge/-%231E8A4C-1E8A4C) | 0–30 |
| Satisfactory | ![#5E8F1B](https://img.shields.io/badge/-%235E8F1B-5E8F1B) | 31–60 |
| Moderate | ![#B8920A](https://img.shields.io/badge/-%23B8920A-B8920A) | 61–90 |
| Poor | ![#D0690E](https://img.shields.io/badge/-%23D0690E-D0690E) | 91–120 |
| Very poor | ![#C02A2A](https://img.shields.io/badge/-%23C02A2A-C02A2A) | 121–250 |
| Severe | ![#7F1D3A](https://img.shields.io/badge/-%237F1D3A-7F1D3A) | 251+ |

- `AqiChip` always spells the unit: **AQI** or **µg/m³**, never a bare number.

---

## Type

| Font | Variable | Use |
|---|---|---|
| Geist | `--font-geist` (`font-sans`) | All UI text |
| Geist Mono | `--font-geist-mono` (`font-mono`) | Numbers, IDs, timestamps |
| Noto Sans Devanagari | `--font-deva` (`font-deva`) | Hindi text (driver view, alerts) |
| Silkscreen | `--font-silkscreen` (`font-pixel`) | Pixel accents and chips |

Loaded with `next/font/google` in `src/app/layout.tsx`.

---

## Elevation and motion

| Token | Value | Use |
|---|---|---|
| `shadow-pop` | `0 12px 32px rgba(11,18,21,.14)` | Popovers, panels |
| `shadow-modal` | `0 24px 64px rgba(11,18,21,.2)` | Command palette, dialogs |
| `shadow-sel` | inset teal bar | Selected list row |
| `animate-sk` | 1.4 s pulse | Skeletons |
| `animate-pin` | 0.2 s rise | Map pins appearing |
| `animate-blink` | 1.6 s | Live indicator |

---

## Components

| Component | Rule it enforces |
|---|---|
| `AqiChip` | Band colour + explicit unit |
| `CauseTag` | One icon and label per cause (dust, traffic, burning, regional smoke, industrial) |
| `Confidence` | Every model output shows its confidence |
| `CountUp` | Headline numbers animate once, then stay still |
| `Skeleton`, `QueryError` | Every query has a loading and an error state |
| `icons.tsx` | One lucide glyph per cause and asset type, shared by every screen |

---

## Product rules

- **Uncertainty everywhere:** forecasts show P10–P90, effects show a 95 % interval, causes show confidence.
- **Honest data:** simulated items carry a badge (`simulated: true`).
- **Humans approve:** nothing dispatches without **Approve and dispatch**.
- **Hindi where it matters:** driver instructions and alerts lead with Hindi.

---

## Related

- [Pages](PAGES.md) · [Web architecture](ARCHITECTURE.md) · [Web deployment](DEPLOYMENT.md)

<!-- footer:start -->

---

**Related across the project:** [App theme](../app/ARCHITECTURE.md) · [AQI tables](../CONTRACTS.md) · [Design export](../../frontend/design/EXPORT_NOTES.md)

[Back to top](#web-design-system) · [Docs hub](../README.md) · [Project README](../../README.md)

<!-- footer:end -->
