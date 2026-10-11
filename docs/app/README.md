# HawaCommand Field & Community: Flutter app docs

<!-- nav:start -->

**Navigate:** [Project](../../README.md) · [Docs hub](../README.md) · [Overview](../SYSTEM_OVERVIEW.md) · [AWS architecture](../AWS_ARCHITECTURE.md) · [AWS setup](../AWS_SETUP_GUIDE.md) · [API](../backend/API.md) · [Environment](../ENVIRONMENT_VARIABLES.md) · [Contracts](../CONTRACTS.md)

**App docs:** [Runbook](../../app_frontend/README.md) · **Index** · [Context](CONTEXT.md) · [Architecture](ARCHITECTURE.md) · [Screens](SCREENS.md) · [Offline and sync](OFFLINE_AND_SYNC.md) · [Quality](LINTING_AND_QUALITY.md) · [Structure](STRUCTURE.md) · [Plan](PLAN.md)

<!-- nav:end -->

Purpose: the index, quick start, implementation status and known issues for the Flutter app in `app_frontend/`, used by drivers, inspectors, school principals, citizens and site managers.

Related: [CONTEXT](CONTEXT.md) · [ARCHITECTURE](ARCHITECTURE.md) · [STRUCTURE](STRUCTURE.md) · [SCREENS](SCREENS.md) · [OFFLINE_AND_SYNC](OFFLINE_AND_SYNC.md) · [LINTING_AND_QUALITY](LINTING_AND_QUALITY.md) · [PLAN](PLAN.md) · [../CONTRACTS.md](../CONTRACTS.md) · [../SYSTEM_OVERVIEW.md](../SYSTEM_OVERVIEW.md) · [../backend/API.md](../backend/API.md) · [../frontend/DESIGN_SYSTEM.md](../frontend/DESIGN_SYSTEM.md) · [app_frontend/README.md](../../app_frontend/README.md)

> These docs were reconciled with the code by static reading (HEAD `a33e043`). Flutter was not available while doing so, so no `make lint` or `make test` result is recorded here. The code is the source of truth: when a doc and the code disagree, fix the doc.

Status vocabulary used across the app docs: **Implemented** (works as described), **Partial** (built, with the missing part named), **Stub/Mock** (runs on fixtures, the in-app fake backend or hard-coded data), **Planned** (not in the code).

---

## 1. What this app is

HawaCommand closes the loop Sense → Map → Attribute → Forecast → Decide → **Act** → **Verify** (§5). The web console (`frontend/`) is where officers decide. This app is where the city **acts** and where people are **protected**:

- **Drivers** get an ordered route. HawaTag confirms each spray automatically, so the driver never files a report (Flow B, §7.1).
- **Inspectors** get a target (a suspect pin with evidence), not an area, and record the outcome (§7, §8.2).
- **School principals** get safe outdoor windows, a 72 h forecast and indoor vs outdoor readings (Flow C, F19).
- **Citizens** get an AI air map with clean-air routing, "air near me" with pollutant-specific advice, alerts, and can report burning with a photo (F16, F20, Flow D).
- **Site managers** see their own A/B/C grade and PM10 trend (F9).

It is one Android-first binary (`hawa_app`, Flutter 3.44 / Dart 3.12) with role-based shells after phone-OTP login. SYSTEM_OVERVIEW §8 records the deviation from the proposal: *"Driver phone PWA → Flutter app; SMS/WhatsApp remain the fallback."*

The backend that exists today serves the AI-ML read endpoints (`/v1/twin`, `/v1/hotspots`, `/v1/forecast`, `/v1/alerts`, `/v1/citizen/*`, `/open/v1/air`) but none of the field-app endpoints (auth, tasks, inspections, reports, uploads, WebSocket). So by default the app runs on an **in-app fake backend** built from JSON fixtures, and only four features call the real backend ([§6.3](#63-fake-and-real-modes)).

## 2. Implementation status

| Area | Status | What exists / what is missing |
|---|---|---|
| App shell: bootstrap, `Env`, Riverpod wiring, go_router + guard, five role shells, en/hi l10n (638 keys each), light/dark/outdoor themes | **Implemented** | `lib/bootstrap.dart`, `lib/app/` ([ARCHITECTURE §2–§5](ARCHITECTURE.md)) |
| Phone-OTP login, role picker, session restore, role switch, logout wipe | **Stub/Mock** | Complete flow, but only against the fake backend (OTP `123456`). The backend has no `/v1/auth/*` or `/v1/me` |
| Driver: today's route, stop detail, skip, manual done, shift start/end, auto-done overlay, route-change banner, shift summary | **Stub/Mock** | Fake backend + `tasks_mine_driver.json`. Dev tools simulate the HawaTag spray, verification and re-plan |
| Inspector: targets, evidence bundle, arrived, outcome with photos | **Stub/Mock** | Fake backend fixtures. Inspector shifts and the on-site call for task-less inspections are **Planned** |
| School: today (safe windows), indoor vs outdoor, 72 h forecast | **Partial** | Forecast is live (`/v1/forecast/{cell_id}`, reshaped). Safe windows, indoor/outdoor, GRAP outlook and `/v1/schools/me` come from fixtures |
| Citizen AI air map with clean-air routing | **Implemented** | Live `/v1/twin` (paged), `/v1/hotspots`, `/v1/forecast`; OSRM routing and Photon search. Its fixture fallback is broken (Known issue 3) |
| Citizen air near me | **Partial** | Live twin + hotspots through an adapter, live `/v1/citizen/safe-window`. Alert subscription is on fixtures |
| Citizen Eyes report, My reports, report status | **Implemented** | With `citizen_reports` in `REAL_FEATURES`: pre-signed S3 upload, `POST /v1/reports`, automated verification, officer status changes and push updates through the backend. On the fake backend otherwise |
| Citizen live operations (Govt in Action radar) | **Implemented** | `GET /v1/citizen/live-operations` every 15 s plus the `/v1/ws/fleet` WebSocket for each ping; built-in demo list when the backend is unreachable |
| Citizen Safe route, Ward scorecard, Missed machine screens | **Stub/Mock** | Hard-coded demo data. The backend's `/v1/citizen/safe-route`, `/wards/leaderboard`, `/reports/missed-machine` are not called yet |
| Site manager score | **Stub/Mock** | `sites_me.json` via the fake backend |
| Alerts inbox and detail | **Partial** | Live command-center broadcast log (`GET /v1/alerts`) mapped to inbox items; acks stay on the phone. The contract inbox (`ALERTS_CONTRACT=true`) needs endpoints the backend lacks |
| Offline cache (drift), outbox, drainer, conflict resolver, sync triggers | **Implemented** | Executes against the fake backend in the default build ([OFFLINE_AND_SYNC](OFFLINE_AND_SYNC.md)). Some cleanup jobs are never called |
| Network stack: three Dio clients, 8 interceptors, typed failures, generated `hawa_api` | **Implemented** | The generated client targets a hand-written contract snapshot, not the backend's real OpenAPI |
| Realtime | **Partial** | The live radar uses the backend's `/v1/ws/fleet`. Task events: `FakeRealtimeClient` drives the demo; `WsClient` is complete but the backend serves no `/v1/ws` |
| Push notifications (FCM) and Crashlytics | **Partial** | Code is wired. Firebase options come from the `FIREBASE_*` build defines (`lib/firebase/firebase_options_env.dart`); without them both are disabled. Each install subscribes to the FCM topic `FCM_TOPIC` (backend broadcasts), and report updates are pushed to the token registered with `PUT /v1/me/push-token` ([AWS_SETUP_GUIDE §7–8](../AWS_SETUP_GUIDE.md#7-firebase-cloud-messaging-and-its-secrets-manager-secret)). Local notifications and in-app banners work |
| Background sync (workmanager) | **Implemented** | Android periodic 15 min task + one-off from the FCM handler |
| Shift location tracking (foreground service, battery-aware sampling, geofence) | **Implemented** | Driver only |
| Maps (flutter_map, MapTiler or keyless Esri basemap, file tile cache, markers) | **Partial** | Corridor tile prefetch, cache size cap and polyline simplification exist but are never called |
| Camera, EXIF strip, presigned upload | **Implemented** | Capture and processing are real; report photos go to the real S3 bucket with `citizen_reports` in `REAL_FEATURES`, inspection photos stay on the fake S3 |
| Deep links | **Partial** | Push and notification taps are routed. `hawa://` links from SMS/WhatsApp open the app but are not routed (Known issue 8) |
| Tests | **Partial** | 5 test files ([LINTING_AND_QUALITY §10](LINTING_AND_QUALITY.md#10-testing-strategy)); the two prototype tests that did not compile were removed |
| CI workflow, wired pre-commit hook, golden tests, integration test, mock server | **Planned** | Makefile targets reference them; the files do not exist |
| iOS | **Partial** | Runner project only: no flavors, no Firebase, no `hawa://` scheme |

## 3. Reading order

| # | Doc | Read it when | Main readers |
|---|---|---|---|
| 1 | [CONTEXT.md](CONTEXT.md) | First. Who the users are, the flows, field realities, privacy and non-goals, with what is built today | Everyone |
| 2 | [ARCHITECTURE.md](ARCHITECTURE.md) | Before writing code. Layers, Riverpod, go_router, networking and fake mode, the API surface vs the backend, storage, realtime, push, location, maps, media, i18n, theme, flavors, security | App dev, AI agents |
| 3 | [STRUCTURE.md](STRUCTURE.md) | When creating files. The `app_frontend/` tree | App dev, AI agents |
| 4 | [SCREENS.md](SCREENS.md) | When building a screen. Routes, data, states, copy and the push catalogue | App dev, designers |
| 5 | [OFFLINE_AND_SYNC.md](OFFLINE_AND_SYNC.md) | Before touching any mutation. Drift schema, outbox, idempotency, conflicts, triggers, cleanup | App dev, backend |
| 6 | [LINTING_AND_QUALITY.md](LINTING_AND_QUALITY.md) | Before the first commit. Lints, Make targets, hooks, the test files and DoD | App dev, AI agents |
| 7 | [PLAN.md](PLAN.md) | When planning work. What was built against the hackathon plan, what remains, contract proposals | App dev, team lead |

Binding upstream docs: [../CONTRACTS.md](../CONTRACTS.md) holds the enums, units, endpoint index, the `is_simulated` rule and the uncertainty rule. [../backend/API.md](../backend/API.md) holds request/response shapes. The app's own contract snapshot is `app_frontend/openapi/openapi.json` (hand-written from API.md + CONTRACTS §13, see [ARCHITECTURE §6.1](ARCHITECTURE.md#61-http-clients-and-the-generated-client)).

## 4. What the app owns

| The app owns (`app_frontend/`) | The app does **not** own |
|---|---|
| Phone-OTP login UX, token storage, role picker | OTP generation, SMS sending, JWT issuing (backend) |
| Role shells: driver, inspector, school, citizen, site manager | Officer console, plan approval, What-If (web `frontend/`) |
| Today's route, stop list, route map, navigation hand-off | Route optimisation (AI-ML), dispatch (backend) |
| Shift start/stop and location sampling **only during a shift** | Fleet positions from HawaTag GPS (backend ingest) |
| Displaying HawaTag auto-done and verified results | Spray detection (HawaTag + ingest), verification (AI-ML verifier) |
| Inspector evidence viewer and outcome capture, including offline | Attribution, back-trajectory (AI-ML) |
| School safe windows, indoor/outdoor view, alert acknowledgement | Safe-window computation (AI-ML), alert drafting (Communicator) |
| Citizen air map, clean-air route scoring, air near me, alert subscription, Citizen Eyes capture and upload | The twin, hotspots and forecast themselves (AI-ML via backend), photo verification |
| Offline cache (drift), outbox with idempotency, sync | Server-side idempotency store, conflict authority (backend) |
| FCM token registration, local notifications, deep-link routing | Sending pushes/SMS/WhatsApp (backend notifier) |
| The in-app fake backend and its fixtures (`assets/fixtures/`) | The real API implementation |
| Contract snapshot `openapi/openapi.json` and the generated `packages/hawa_api` | The backend's own `/openapi.json` |
| App CI workflow (**Planned**: there is no `.github/` in the repo) | Other folders' CI |

## 5. Roles at a glance

| Role (`UserRole` wire) | Shell and tabs | Home route | Status |
|---|---|---|---|
| `driver` | Driver: Route · Map · More | `/driver` | Stub/Mock (fake backend) |
| `inspector` | Inspector: Targets · Map · More | `/inspector` | Stub/Mock |
| `school` | School: Today · Air · Alerts (a tab that pushes `/alerts`) · More | `/school` | Partial (live forecast) |
| `citizen` | Citizen: Map · Air · Report · My reports · More | `/citizen/map` | Partial (live air map and air near me) |
| `site_manager` | Site: Site · More | `/site` | Stub/Mock |
| `officer`, `admin`, `analyst`, unknown | none: `/unsupported-role` ("Use the web console") | — | Implemented |

A user holding several app roles picks one on `/auth/role` and can switch from **More → Switch role**; a push for another held role switches automatically ([ARCHITECTURE §5.4](ARCHITECTURE.md#54-roles-and-role-switching)). Every role can open the citizen air map from **More** (`/map`). Screen-by-screen detail is in [SCREENS.md](SCREENS.md).

## 6. Quick start

### 6.1 Prerequisites

| Tool | Version in the repo | Notes |
|---|---|---|
| [FVM](https://fvm.app) + Flutter | Flutter `3.44.0` (`.fvmrc`), Dart `>=3.12.0` (`pubspec.yaml`) | The Makefile calls `fvm flutter` / `fvm dart` (override with `FLUTTER=flutter DART=dart`) |
| Android SDK + emulator or phone | `compileSdk 37`, `minSdk 24`, `targetSdk` = Flutter default | AGP 9.0.1, Kotlin 2.3.20, Gradle 9.1.0, Java 17 (`android/`) |
| Docker | `openapitools/openapi-generator-cli:v7.17.0` | Only for `make gen-api` / `make gen-api-local` |
| `make` | | On Windows run the Makefile commands by hand |
| Firebase | build defines | `FIREBASE_API_KEY`, `FIREBASE_APP_ID`, `FIREBASE_MESSAGING_SENDER_ID`, `FIREBASE_PROJECT_ID` from the Android app's `google-services.json`; no FlutterFire CLI or `google-services.json` in the build ([ARCHITECTURE §16.3](ARCHITECTURE.md#163-firebase)) |

### 6.2 First run

Generated code (`*.g.dart`, `*.freezed.dart`, `lib/app/l10n/gen/`) is not committed, so generate it first.

```bash
cd app_frontend
make setup                 # fvm install + flutter pub get + make gen (gen-l10n + build_runner build)
fvm flutter run --flavor dev
```

`make run FLAVOR=dev` adds `--dart-define-from-file=env/dev.json`, but no `env/` directory is committed (Known issue 2). Either run without a define file as above (every `Env` value has a dev default: fake backend, real air features, backend at `http://10.0.2.2:8000`) or create `app_frontend/env/dev.json` from the template in [ARCHITECTURE §16.2](ARCHITECTURE.md#162-dart-defines-env).

Unverified: these commands are derived from the Makefile and `pubspec.yaml`; they were not executed for this doc.

### 6.3 Fake and real modes

Each feature picks its remote source from `Env.isFake('<feature>')`:

```text
isFake(f) = f not in REAL_FEATURES  and  (USE_FAKE_API or f in FAKE_FEATURES)
```

| Dart define | Default | Effect |
|---|---|---|
| `USE_FAKE_API` | `true` | Every feature not in `REAL_FEATURES` uses the in-app fake backend. Outbox mutations and uploads follow the same per-feature rule (`push` for push tokens, `citizen_subscription` for the alert area, `citizen_reports` for report photos and submits, `inspector` for inspection and task photos); realtime follows `driver_route` |
| `REAL_FEATURES` | `air_map,citizen_air,alerts,school_forecast` | These always call the real backend (`API_BASE_URL`). The backend now also serves `citizen_reports`, `citizen_subscription` and `push` |
| `FAKE_FEATURES` | empty | With `USE_FAKE_API=false`, the features listed here stay fake |
| `ALERTS_CONTRACT` | `false` | `alerts` real: `true` uses the contract `GET /v1/alerts` (generated client) instead of the command-center adapter |
| `OPEN_AIR_CONTRACT` | `false` | `citizen_air` real: `true` uses `GET /open/v1/air?bbox=` instead of the twin adapter |

Feature keys: `auth`, `driver_route`, `inspector`, `alerts`, `school`, `school_forecast`, `citizen_air`, `citizen_subscription`, `citizen_reports`, `site`, `air_map` (plus `settings`, used only to route `PATCH /v1/me`). The full define list is in [ARCHITECTURE §16.2](ARCHITECTURE.md#162-dart-defines-env).

What the default build talks to:

| Feature | Calls | Served by the backend? |
|---|---|---|
| `air_map` | `GET /v1/twin?limit=2000` (+ latitude strips `?bbox=`), `GET /v1/hotspots?hour=0`, `GET /v1/forecast` | yes |
| `citizen_air` | `GET /v1/twin?bbox=…&limit=400` + `GET /v1/hotspots`; `GET /v1/citizen/safe-window?persona=general` | yes |
| `alerts` | `GET /v1/alerts` (command-center broadcast log) | yes |
| `school_forecast` | `GET /v1/forecast/{cell_id}` | yes |
| Dev tools | `GET /healthz` | yes |
| Air map routing | OSRM `routing.openstreetmap.de`, Photon `photon.komoot.io` (third party) | n/a |
| Everything else | in-app fake backend | n/a |

`USE_FAKE_API=false` is not usable against today's backend: login fails at `POST /v1/auth/otp/request` (Known issue 13). The full endpoint matrix is in [ARCHITECTURE §7](ARCHITECTURE.md#7-api-surface-used-by-the-app).

### 6.4 Demo logins and Dev tools

Fake auth accepts OTP `123456` (5 wrong codes → `429` for 60 s). Numbers map to `/v1/me` fixtures (`FakeBackend.phoneFixtures`):

| Phone | Fixture | Role(s) |
|---|---|---|
| 98100 12345 | `me_driver.json` | driver |
| 98100 22222 | `me_inspector.json` | inspector |
| 98100 33333 | `me_school.json` | school |
| 98100 44444 | `me_site_manager.json` | site_manager |
| 98100 55555 | `me_multi_role.json` | driver + citizen (role picker) |
| 98100 66666 | `me_officer.json` | officer (unsupported-role screen) |
| any other `+91` 6–9xxxxxxxxx | `me_citizen.json` | a new citizen (stable id per number) |

Fixture dates are rebased from 2026-11-13 to today's IST date. Fake state (stop statuses, reports, acks) is saved to `fake_backend_state.json` in the app documents directory and restored on the same IST day. Citizen reports advance on timers: `verifying` 4 s, `verified` 10 s, `ticketed` 16 s (creates an inspection), `closed` 45 s.

**Settings → Dev tools** (`/settings/dev`, shown when `SHOW_DEV_TOOLS=true` and `FLAVOR != prod`): backend health (`/healthz`), the list of real features, Simulate HawaTag spray, Simulate verification, Simulate route change, HawaTag offline toggle, Send test push, New inspection target, Go offline (fails every request on both Dio clients and the fake backend), Reset local DB.

### 6.5 Pointing at a real backend

The backend runs on port 8000 (`backend/README.md`: `uvicorn hawa_backend.api.app:app --host 0.0.0.0 --port 8000`).

| Device | `API_BASE_URL` | Extra step |
|---|---|---|
| Android emulator | `http://10.0.2.2:8000` (the default) | none |
| USB phone | `http://localhost:8000` | `adb reverse tcp:8000 tcp:8000` |
| Phone on Wi-Fi | `http://<laptop-ip>:8000` | cleartext is allowed in every flavor today (Known issue 7) |

Pass it as `--dart-define=API_BASE_URL=…` or in `env/<flavor>.json`. `WS_URL` (default `ws://10.0.2.2:8000/v1/ws`) only matters when realtime is real, which needs a backend `/v1/ws` that does not exist yet.

### 6.6 Everyday commands

| Command | Does | Status |
|---|---|---|
| `make setup` | `fvm install`, `flutter pub get`, `make gen` | Implemented |
| `make gen` | `flutter gen-l10n` + `dart run build_runner build` (riverpod_generator, freezed, json_serializable, drift_dev). `sh tool/gen.sh` does the same behind a directory lock | Implemented |
| `make watch` | build_runner watch | Implemented |
| `make l10n` | `flutter gen-l10n` + `dart run tool/check_untranslated.dart` | Implemented |
| `make format` / `make format-check` | `dart format` on tracked non-generated Dart files | Implemented |
| `make analyze` | `flutter analyze --fatal-infos` | Implemented |
| `make guard` | `sh tool/architecture_guard.sh` | Implemented |
| `make lint` | `format-check` + `analyze` + `guard` | Implemented |
| `make fix` | `dart fix --apply` then `make format` | Implemented |
| `make test` | `flutter test --coverage` | Not run here (no Flutter SDK); the two prototype tests that did not compile were removed |
| `make golden` | `flutter test --tags golden --update-goldens` | Planned: no golden tests exist |
| `make it` | `flutter test integration_test/flow_b_driver_test.dart …` | Planned: `integration_test/` does not exist |
| `make run FLAVOR=…` / `make apk FLAVOR=…` | `flutter run` / `flutter build apk --split-per-abi` with `env/$(FLAVOR).json` | Partial: needs the missing env file |
| `make mock-server` | `tool/mock_server` on :8081 | Planned: the directory does not exist |
| `make gen-api API_URL=…` | download `$(API_URL)/openapi.json`, then `gen-api-local` | Partial: the backend's OpenAPI does not describe the field routes yet |
| `make gen-api-local` | regenerate `packages/hawa_api` from the committed `openapi/openapi.json` (Docker) + build_runner | Implemented |

### 6.7 Regenerating the API client

`packages/hawa_api` is generated by openapi-generator 7.17.0 (`dart-dio`, `json_serializable`, `enumUnknownDefaultCase`) from `openapi/openapi.json` and committed, including its `*.g.dart`. That snapshot (`1.1.0-app`) was written by hand from API.md and CONTRACTS §13 because the backend does not serve those routes. Never edit the package by hand: change the snapshot (or, once the backend exports the routes, run `make gen-api API_URL=<backend>`), then `make gen-api-local`, then fix the mappers in `features/*/data/`. `packages/hawa_api/pubspec_overrides.yaml` pins `json_serializable <6.10` because the generated package declares Dart `>=3.5`.

## 7. Supported platforms

| Platform | Status | Details |
|---|---|---|
| **Android** | **Implemented** (primary) | `applicationId in.hawacommand.field` (placeholder domain), flavors `dev` (`.dev`, "Hawa DEV"), `staging` (`.stg`, "Hawa STG"), `prod` ("HawaCommand"). `minSdk 24`, `compileSdk 37`, core library desugaring on. Release signing from `android/key.properties` if present, else the debug key |
| iOS | **Partial** | `ios/Runner` with bundle id `in.hawacommand.field`, deployment target 13.0, location/camera usage strings, `UIBackgroundModes` remote-notification + location. No flavor schemes (`--flavor dev` fails), no `GoogleService-Info.plist`, no `hawa://` URL scheme, no entitlements |
| Web / desktop | Not supported | Officers use `frontend/` |

**Why minSdk 24.** The plugins in use (flutter_secure_storage, flutter_image_compress, workmanager, drift's SQLite, geolocator foreground service) are best supported at 23+, API 24 brings network security config, and Android 7+ covers nearly all active field phones. Revisit with Play Console stats after a pilot.

## 8. Key decisions (one line each)

| Decision | Choice in the code | Where |
|---|---|---|
| Architecture | Feature-first, layered: presentation → application → domain → data, shared `core/`, wiring in `app/` | [ARCHITECTURE §2](ARCHITECTURE.md#2-layers) |
| State | Riverpod 3 (`flutter_riverpod 3.4.3`) with `riverpod_generator`; `riverpod_lint` not installed | [ARCHITECTURE §4](ARCHITECTURE.md#4-state-management-riverpod-with-code-generation) |
| Navigation | go_router 18, `StatefulShellRoute.indexedStack` per role, pure redirect guard, push deep links | [ARCHITECTURE §5](ARCHITECTURE.md#5-navigation-go_router) |
| Networking | Dio 5 + generated `hawa_api` + interceptor chain; `CommandCenterApi` for the backend's live read endpoints | [ARCHITECTURE §6](ARCHITECTURE.md#6-networking) |
| Fake mode | In-app `FakeBackend` from fixtures, per-feature switch via `Env.isFake` | [ARCHITECTURE §6.6](ARCHITECTURE.md#66-the-in-app-fake-backend) |
| Offline | drift (SQLite, WAL) cache + outbox with `Idempotency-Key`, server authoritative | [OFFLINE_AND_SYNC](OFFLINE_AND_SYNC.md) |
| Realtime | WS `/v1/ws?token=` client (`tasks:me`, `alerts:me`) in foreground + FCM data messages; fake realtime in fake mode | [ARCHITECTURE §10](ARCHITECTURE.md#10-realtime-websocket--fcm) |
| Location | geolocator foreground service, **only during a shift**, battery-aware | [ARCHITECTURE §11](ARCHITECTURE.md#11-location-and-shift) |
| Maps | flutter_map 8 + MapTiler raster with a key, else keyless Esri World Street Map; never OSM tile servers | [ARCHITECTURE §12](ARCHITECTURE.md#12-maps) |
| i18n | `flutter_localizations` + ARB, en + hi, Inter + Noto Sans Devanagari bundled | [ARCHITECTURE §14](ARCHITECTURE.md#14-internationalisation-en--hi) |
| Lints | `very_good_analysis` 10.3 + strict modes + `tool/architecture_guard.sh` | [LINTING_AND_QUALITY](LINTING_AND_QUALITY.md) |
| Crash reporting | Firebase Crashlytics wrapper, off until Firebase exists and `CRASH_REPORTING=true` | [ARCHITECTURE §17](ARCHITECTURE.md#17-errors-logging-and-crash-reporting) |

## 9. Known issues

Defects found by reading the code. Paths are relative to `app_frontend/` unless they start with another top-level folder.

| # | Issue | Where |
|---|---|---|
| 1 | Fixed (2026-10-11): the two prototype tests that imported the old package `hawacommand_app` were deleted with the rest of the prototype | — |
| 2 | Only `env/staging.json.example` is committed (EC2 backend); `make run` / `make apk` for other flavors still need `env/<flavor>.json` created by hand. The repo-root `.gitignore` now re-includes `app_frontend/env/` | `Makefile:21-23`, `app_frontend/env/`, `.gitignore` (repo root) |
| 3 | The air-map fixtures are not declared as assets, so `FakeAirMapRemoteSource` (the `air_map` fake mode and the fallback when the backend is down) throws "Unable to load asset". Tests read the files from disk and pass | `pubspec.yaml:69-77`, `lib/features/air_map/data/air_map_remote_source.dart:121` |
| 4 | Make targets point at missing files: `tool/mock_server/`, `integration_test/flow_b_driver_test.dart`; `make golden` has no golden tests | `Makefile:20-21`, `Makefile:24` |
| 5 | Citizen "Flag Missed Machine" pushes `/citizen/report/missed-machine`, but the route is registered under the capture route as `/citizen/report/new/missed-machine`, so go_router shows its error page. The "72-Hour AI Air Forecast" tile pushes `/school/forecast`, which the guard redirects to the citizen home | `lib/features/citizen_air/presentation/air_near_me_screen.dart:339,366`, `lib/app/router/routes.dart:45`, `lib/app/router/router.dart:228-232`, `lib/app/router/guards.dart:37-38` |
| 6 | The prototype theme `lib/app/theme.dart`, the only prototype file left, is imported by four live citizen screens; move them to `lib/app/theme/` before deleting it. That theme uses Geist, GeistMono and Silkscreen fonts that `pubspec.yaml` does not declare, so those screens render in the fallback font | `lib/features/citizen_air/presentation/safe_route_screen.dart:4`, `live_operations_screen.dart:3`, `ward_scorecard_screen.dart:4`, `lib/features/citizen_reports/presentation/missed_machine_screen.dart:3`, `lib/app/theme.dart:21-26`, `analysis_options.yaml:17-19`, `pubspec.yaml:78-88` |
| 7 | Cleartext HTTP is allowed in every flavor: the main manifest sets `usesCleartextTraffic="true"`; only the dev flavor has a restrictive network security config | `android/app/src/main/AndroidManifest.xml:26`, `android/app/src/dev/res/xml/network_security_config.xml` |
| 8 | `hawa://` links from SMS/WhatsApp open the app but are not routed: the manifest declares the scheme and disables Flutter deep linking, and no Dart code reads the incoming intent | `android/app/src/main/AndroidManifest.xml:45-52` |
| 9 | Fixed: the FCM background handler now initializes Firebase in its isolate from the same build defines, so background pushes are stored and shown | `lib/core/notifications/fcm_background_handler.dart` |
| 10 | An inspector outcome with several photos can fail permanently: `inspection_close` depends only on the last `photo_upload`; if an earlier photo is still uploading, resolving its key throws `media_not_uploaded`, which the drainer classifies as `failed` | `lib/features/inspector/data/inspector_repository_impl.dart:229`, `lib/core/sync/executors/op_executor.dart:29`, `lib/core/sync/outbox_drainer.dart:299-303` |
| 11 | After a `413`, the re-compressed photo is presigned with the original file's `sha256` | `lib/core/sync/executors/photo_upload_executor.dart:43` |
| 12 | `Env.flavor` comes from the `FLAVOR` define (default `dev`), not from the Gradle flavor. `--flavor prod` without `FLAVOR=prod` keeps Dev tools, HTTP logging and the forced-offline interceptor on | `lib/app/env.dart:6`, `lib/core/network/dio_provider.dart:48`, `lib/features/settings/presentation/settings_screen.dart:118` |
| 13 | `USE_FAKE_API=false` cannot work against today's backend: it serves none of `/v1/auth/*`, `GET/PATCH /v1/me`, `/v1/tasks*`, `/v1/shifts*`, `/v1/inspections*`, `/v1/schools*`, `/v1/grap/outlook`, `/v1/sites/me`, `/v1/ws` (it does serve `/v1/reports*`, `/v1/me/push-token`, `/v1/me/alert-subscription`, `/v1/alerts/{id}` and `/v1/ws/fleet`). Use `USE_FAKE_API=true` with `REAL_FEATURES` instead | `backend/src/hawa_backend/api/app.py:69-79` |
| 14 | `/open/v1/air` exists on the backend with a different contract (`ward`, `limit` → `{asOf, cells[]}`) from the app's (`bbox` → GeoJSON FeatureCollection), so `OPEN_AIR_CONTRACT=true` would fail to parse | `backend/src/hawa_backend/api/routes/open_data.py:11-36`, `lib/features/citizen_air/data/open_air_remote_source.dart:31` |
| 15 | Switching role during a shift stops the location tracker directly instead of ending the shift: no `shift_end` op is queued and the saved shift stays, so the driver shell later offers "Resume" | `lib/features/shell/presentation/widgets/more_sheet.dart:91-101` |
| 16 | The pre-commit script expects a repo-root hook manager that does not exist (no Husky or lefthook config) | `tool/hooks/pre_commit.sh:2-3` |

## 10. Links

- System context: [../SYSTEM_OVERVIEW.md](../SYSTEM_OVERVIEW.md)
- Contracts: [../CONTRACTS.md](../CONTRACTS.md) (§3 enums, §6 REST + WS index, §10 AQI/GRAP, §13 field-app additions)
- Backend API (target shapes): [../backend/API.md](../backend/API.md); backend run instructions: [../../backend/README.md](../../backend/README.md)
- Design tokens: [../frontend/DESIGN_SYSTEM.md](../frontend/DESIGN_SYSTEM.md)
- Web console docs: [../frontend/README.md](../frontend/README.md)
- AI-ML docs (twin, forecast, safe windows, attribution, verifier): [../aiml/README.md](../aiml/README.md)
- App folder readme: [../../app_frontend/README.md](../../app_frontend/README.md)
- Source proposal: the original proposal v3, no longer in the repository (§6 features, §7 users/flows, §8 timeline, §10 hardware, §12.4 privacy, §15 risks)

<!-- footer:start -->

---

[Back to top](#hawacommand-field--community-flutter-app-docs) · [Docs hub](../README.md) · [Project README](../../README.md)

<!-- footer:end -->
