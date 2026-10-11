# Web console pages

<!-- nav:start -->

**Navigate:** [Project](../../README.md) · [Docs hub](../README.md) · [Overview](../SYSTEM_OVERVIEW.md) · [AWS architecture](../AWS_ARCHITECTURE.md) · [AWS guide](../AWS_SETUP_GUIDE.md) · [API](../backend/API.md) · [Environment](../ENVIRONMENT_VARIABLES.md) · [Contracts](../CONTRACTS.md)

**Web docs:** [Runbook](../../frontend/README.md) · [Index](README.md) · [Architecture](ARCHITECTURE.md) · **Pages** · [Design system](DESIGN_SYSTEM.md) · [Deployment](DEPLOYMENT.md)

<!-- nav:end -->

<p align="center">
<img src="https://img.shields.io/badge/pages-11-000000?logo=nextdotjs&logoColor=white" alt="11 pages">
<img src="https://img.shields.io/badge/data-TanStack%20Query-FF4154?logo=reactquery&logoColor=white" alt="TanStack Query">
<img src="https://img.shields.io/badge/live%20poll-5%20s-2EA44F" alt="5 s poll">
<img src="https://img.shields.io/badge/contracts-zod-3E67B1?logo=zod&logoColor=white" alt="zod">
</p>

Every page of the officer console: who it is for, what it shows, the endpoints behind it and its main components.

- Live: [ec2-13-207-49-123.ap-south-1.compute.amazonaws.com:3000](http://ec2-13-207-49-123.ap-south-1.compute.amazonaws.com:3000/)
- Data hooks: `src/hooks/`; client: `src/lib/api.ts`; every response is validated with zod (`src/contracts/`).
- Without `NEXT_PUBLIC_API_URL` every call is answered in the browser by `src/mocks/`.

---

## Page map

| Route | Page | Endpoints | Refresh |
|---|---|---|---|
| `/` | Landing page | — | — |
| `/login` | Officer sign-in (Cognito when configured) | — | — |
| `/map` | Live hotspot map | `GET /v1/hotspots` | 5 s at hour 0 |
| `/forecast` | 72 h forecast and GRAP | `GET /v1/forecast`, `GET /v1/hotspots` | on load |
| `/plans` | Plan list and drafting | `GET /v1/plans`, `POST /v1/plans/draft` | on load |
| `/plans/[id]` | Plan review and approval | `GET /v1/plans/{id}`, `POST .../approve`, `.../request-changes`, `.../suggestions/{id}/apply` | after each action |
| `/what-if` | AI plan vs usual routes | `GET /v1/plans`, `GET /v1/plans/{id}/compare` | on load |
| `/impact` | Verified interventions | `GET /v1/impact`, `GET /v1/impact/library` | on load |
| `/fleet` | Vehicles and HawaTag state | `GET /v1/devices` | 5 s |
| `/alerts` | Sent alerts | `GET /v1/alerts` | on load |
| `/route` | Hindi-first driver view | `GET /v1/driver/route?asset=` | on load |

---

## `/map`: live hotspot map

- **For:** ward officer, first screen of the day.
- **Shows:** 500 m cells coloured by PM2.5 band, ranked hotspots with likely cause and confidence, exposure in people-hours, schools nearby, the upwind suspect pin.
- **Controls:** time scrubber (−24 h to +72 h), layer toggles (heat, stations, bus trails, fleet, schools), ward picker, wind chip.
- **Components:** `HawaMap`, `HotspotList`, `HotspotDetail`, `TimeScrubber`, `LayerToggles`, `Legend`.

## `/forecast`: 72 hours ahead

- **Shows:** P10/P50/P90 band chart, GRAP stage with probability, the stage checklist of mandated actions, the map at the peak hour.
- **Components:** `ForecastChart`, `HawaMap`, `TimeScrubber`, `Legend`.

## `/plans` and `/plans/[id]`: review and approve

- **List:** drafted plans newest first; **Draft plan** asks the Planner for a new one for the ward.
- **Detail:**
  - `PlanHeader`: status, window, headline (people-hours protected, assets used, confidence).
  - `PlanDiff`: tasks per vehicle, added or removed against the usual route.
  - `PlannerNote`: the Planner's reasoning.
  - `AuditorComment`: each objection with a one-click **Apply suggestion**.
  - `PlanDetails`: checks (no water on burning, anti-gaming guard, shift limits).
  - `ApproveBar`: **Approve and dispatch** or **Request changes**.
- **On approval:** the backend may start a Step Functions dispatch and sends one SNS notice.

## `/what-if`: prove the plan beats the routine

- **Shows:** person-hours of exposure avoided by the AI plan vs usual fixed routes, side by side on the map with the reduction applied.

## `/impact`: did it work?

- **Shows:** each intervention with its effect and 95 % interval from synthetic control, the treated vs synthetic chart, and the effectiveness library by cause and action.
- **Export:** a plain-text evidence report per intervention (`impact/report.ts`).
- **Components:** `ImpactTable`, `InterventionDetail`, `SyntheticControlChart`, `EffectLibrary`.

## `/fleet`: where is every machine

- **Shows:** live HawaTag vehicles first (status, pump flow, litres, last ping), then the demo fleet; the asset panel shows the tag state.
- **Components:** `FleetTable`, `AssetPanel`, `HawaMap`.

## `/alerts`: who was told what

- **Shows:** broadcasts sent through SNS and push, then the demo alerts; audience, target, channel, delivery, lead time; a WhatsApp-style preview.
- **Components:** `AlertStats`, `AlertsTable`, `WhatsAppPreview`.

## `/route`: the driver's screen

- **For:** sprinkler and smog-gun drivers on a phone.
- **Shows:** stops in order with Hindi-first instructions, times and actions; start, done and navigate buttons.

---

## Shared shell

| Piece | What it does |
|---|---|
| `ConsoleShell`, `IconRail`, `ConsoleHeader` | Layout, navigation rail, ward picker, live PM2.5 chip |
| `CommandPalette` | **Cmd/Ctrl + K**: jump between screens and run common commands |
| `AuthGuard` | Redirects to `/login` when Cognito is configured |
| `Skeleton`, `QueryError` | Loading and error states for every query |

---

## Related

- [Web architecture](ARCHITECTURE.md) · [Design system](DESIGN_SYSTEM.md) · [Web deployment](DEPLOYMENT.md) · [API reference](../backend/API.md)

<!-- footer:start -->

---

**Related across the project:** [Backend API](../backend/API.md) · [Models behind the pages](../aiml/MODELS.md) · [Plan agents](../aiml/AGENTS.md) · [Plans service](../backend/SERVICES.md#plans) · [App screens](../app/SCREENS.md)

[Back to top](#web-console-pages) · [Docs hub](../README.md) · [Project README](../../README.md)

<!-- footer:end -->
