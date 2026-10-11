# App screens

<!-- nav:start -->

**Navigate:** [Project](../../README.md) · [Docs hub](../README.md) · [Overview](../SYSTEM_OVERVIEW.md) · [AWS architecture](../AWS_ARCHITECTURE.md) · [AWS guide](../AWS_SETUP_GUIDE.md) · [API](../backend/API.md) · [Environment](../ENVIRONMENT_VARIABLES.md) · [Contracts](../CONTRACTS.md)

**App docs:** [Runbook](../../app_frontend/README.md) · [Index](README.md) · [Architecture](ARCHITECTURE.md) · **Screens** · [Offline and sync](OFFLINE_AND_SYNC.md) · [Notifications and realtime](NOTIFICATIONS_AND_REALTIME.md) · [Deployment](DEPLOYMENT.md)

<!-- nav:end -->

<p align="center">
<img src="https://img.shields.io/badge/roles-5-02569B?logo=flutter&logoColor=white" alt="5 roles">
<img src="https://img.shields.io/badge/languages-English%20%C2%B7%20Hindi-0E7C66" alt="English and Hindi">
<img src="https://img.shields.io/badge/navigation-go__router-6E7781" alt="go_router">
<img src="https://img.shields.io/badge/data-real%20or%20fake%20per%20feature-2EA44F" alt="Real or fake">
</p>

Every role, its tabs and screens, and where each screen gets its data.

- Routes: `lib/app/router/routes.dart`; shells: one bottom-tab shell per role.
- **Real** = the HawaCommand backend; **fake** = the in-app fake backend with the same contract. Which one is used is set per feature by `REAL_FEATURES` ([app deployment](DEPLOYMENT.md)).

---

## Sign-in and onboarding

| Route | Screen | Notes |
|---|---|---|
| `/splash` | Splash | Restores the session |
| `/onboarding/language` | Language | Hindi or English, both scripts shown |
| `/onboarding/permissions/:kind` | Permissions | Location, camera, notifications, asked in context |
| `/auth/phone` → `/auth/otp` | Phone and OTP | Demo OTP `123456` |
| `/auth/role` | Role picker | For users with several roles |

Demo numbers: driver `98100 12345`, inspector `98100 22222`, school `98100 33333`, site `98100 44444`, driver + citizen `98100 55555`; any other number is a citizen.

---

## Citizen (Air · Report · My reports · More)

| Route | Screen | Data | Source |
|---|---|---|---|
| `/citizen/map` | AI air map: pollution layer, red-zone hotspots, forecast slider, clean-air routes | `/v1/twin`, `/v1/hotspots`, `/v1/forecast`, OSRM, Photon | Real |
| `/citizen` | Air near me: AQI, advice, safe outdoor window | `/v1/twin?bbox=`, `/v1/hotspots`, `/v1/citizen/safe-window` | Real |
| `/citizen/live-ops` | **Govt in Action** radar: live vehicles, verified interventions | `/v1/citizen/live-operations`, `WS /v1/ws/fleet` | Real |
| `/citizen/report/privacy` → `/new` → `/review` | **Citizen Eyes**: privacy note, camera, review, send | `/v1/uploads/presign`, S3, `/v1/reports` | Real with `citizen_reports` |
| `/citizen/reports`, `/citizen/reports/:id` | My reports and report status timeline | `/v1/reports/mine`, `/v1/reports/{id}` | Real with `citizen_reports` |
| `/citizen/subscription` | Alert area: home, radius, kinds, quiet hours | `/v1/me/alert-subscription` | Real with `citizen_subscription` |
| `/citizen/safe-route` | Safe route comparison | Demo data | — |
| `/citizen/ward-score` | Ward scorecard | Demo data | — |
| `/citizen/report/missed-machine` | Flag a missed machine | Demo data | — |
| `/citizen/route-tip` | Route tip | Demo data | — |

---

## Driver (Route · Map · More)

| Route | Screen |
|---|---|
| `/driver` | Today's route: next stop hero, stop cards, shift bar |
| `/driver/stops/:taskId` | Stop detail: place, action, cause, time window |
| `/driver/stops/:taskId/skip` | Skip with a reason |
| `/driver/stops/:taskId/manual-done` | Mark done with a photo when the HawaTag is offline |
| `/driver/map` | Route map |
| `/driver/shift/summary` | Shift summary: stops, litres, impact |

- HawaTag spray events mark stops done automatically (auto-done overlay).
- A re-plan shows a route-changed banner.
- Shift location tracking runs as a foreground service with battery-aware sampling.

---

## Inspector (Targets · Map · More)

| Route | Screen |
|---|---|
| `/inspector` | Assigned targets |
| `/inspector/targets/:id` | Evidence bundle: photos, readings, cause |
| `/inspector/targets/:id/outcome` | Outcome: confirmed, not found, unreachable, with photos |
| `/inspector/targets/:id/photos/:index` | Photo viewer |
| `/inspector/map` | Targets map |

---

## School (Today · Air · Alerts · More)

| Route | Screen | Data |
|---|---|---|
| `/school` | Today: safe outdoor windows for the class schedule | Fixtures |
| `/school/air` | Indoor vs outdoor | Fixtures |
| `/school/forecast` | 72 h forecast for the school's cell | `/v1/forecast/{cell_id}` (real) |

---

## Site manager

| Route | Screen |
|---|---|
| `/site` | Site compliance score and actions |

---

## Shared

| Route | Screen | Data |
|---|---|---|
| `/alerts`, `/alerts/:id` | Alert inbox and detail | `/v1/alerts` (real) |
| `/map`, `/map/search` | Air map and place search | Real |
| `/settings` | Language, display (incl. colour-blind palette), data saver, notifications, switch role, pending sync, sign-out | Local |
| `/settings/notifications` | Notification channels | Local |
| `/settings/sync` | Sync queue: pending, failed and retried operations | Local outbox |
| `/settings/dev` | Dev tools: simulate a spray, verification, route change or tag offline; test push; go offline; reset the local database | Local |
| `/profile` | Name, phone (masked), roles | `/v1/me` (fake) |

---

## Related

- [App architecture](ARCHITECTURE.md) · [Offline and sync](OFFLINE_AND_SYNC.md) · [Notifications and realtime](NOTIFICATIONS_AND_REALTIME.md) · [App deployment](DEPLOYMENT.md)

<!-- footer:start -->

---

[Back to top](#app-screens) · [Docs hub](../README.md) · [Project README](../../README.md)

<!-- footer:end -->
