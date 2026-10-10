# HawaCommand field & community app (Flutter)

One Android app for the people who act on Delhi's air: **drivers** (today's route, spray confirmed by HawaTag), **inspectors** (targets with evidence), **school principals** (safe outdoor windows), **citizens** (AI air map with clean-air routes, air near me, report burning) and **site managers** (site score). Hindi-first, offline-first.

The spec is in [`../docs/app/`](../docs/app/README.md): ARCHITECTURE, STRUCTURE, SCREENS, OFFLINE_AND_SYNC, LINTING_AND_QUALITY, PLAN.

## Run

```sh
# Toolchain: Flutter 3.44.0 (.fvmrc). Android SDK 37.
make setup                   # fvm install, pub get, gen
make gen                     # gen-l10n + build_runner (Riverpod, freezed, drift, json)

# Run without a define file (Env defaults: dev flavor, fake API, API_BASE_URL http://10.0.2.2:8000)
fvm flutter run --flavor dev
# Physical device against a local backend
adb reverse tcp:8000 tcp:8000
fvm flutter run --flavor dev --dart-define=API_BASE_URL=http://localhost:8000

make lint test               # format check, analyze --fatal-infos, architecture guard, tests
```

`make run`, `make apk` and `make it` read `--dart-define-from-file=env/$(FLAVOR).json`. No `env/*.json` or `env/*.json.example` is committed (the repo-root `.gitignore` ignores every `env/` folder), so create `env/dev.json` yourself before using them. Other Makefile targets: `watch`, `l10n`, `format`, `format-check`, `analyze`, `guard`, `fix`, `golden`, `mock-server`, `gen-api`, `gen-api-local`; `mock-server` and `it` point at files that do not exist (`tool/mock_server/`, `integration_test/`).

Build-time defines (`lib/app/env.dart`): `FLAVOR`, `API_BASE_URL`, `WS_URL`, `USE_FAKE_API` (default `true`), `FAKE_FEATURES`, `REAL_FEATURES`, `MAP_TILE_URL`, `MAP_API_KEY`, `MAP_FALLBACK_TILE_URL`, `MAP_FALLBACK_ATTRIBUTION`, plus routing and geocoding URLs. `Env.flavor` comes from the `FLAVOR` define, not the Gradle flavor.

Implementation status and the full known-issues list: [docs/app/README.md](../docs/app/README.md). These docs were checked by reading the code; `make lint` and `make test` were not run (no Flutter SDK on the reviewing machine). Two legacy tests (`test/data_mapping_test.dart`, `test/i18n_test.dart`) import the old package name `hawacommand_app` and will not compile.

**Demo login** (fake auth, OTP `123456`): driver 98100 12345 · inspector 98100 22222 · school 98100 33333 · site 98100 44444 · driver + citizen 98100 55555 · any other number is a citizen. Dev tools (Settings → Dev tools) can simulate a HawaTag spray, verification, a route change, the tag going offline, a test push and going offline.

## What talks to the real backend

`USE_FAKE_API=true` keeps every endpoint the backend does not serve yet on the in-app fake backend (same contract, fixtures in `assets/fixtures/`). `REAL_FEATURES` lists the features that always call the HawaCommand backend (`API_BASE_URL`):

| Feature | Backend endpoint(s) | Screen |
|---|---|---|
| `air_map` | `/v1/twin` (AI-ML 500 m grid, paged by latitude), `/v1/hotspots`, `/v1/forecast` | Citizen air map: pollution layer, red-zone hotspots, forecast slider, clean-air routing |
| `citizen_air` | `/v1/twin?bbox=` (snapped ~1 km box) + `/v1/hotspots` (cause) | C1 Air near me |
| `alerts` | `/v1/alerts` (command-center broadcasts) | X1/X2 Alerts |
| `school_forecast` | `/v1/forecast/{cell_id}` | S3 72-hour forecast |

Auth, tasks, inspections, reports, sites and all writes (outbox) stay fake until the backend implements the field contract (`openapi/openapi.json`, generated client in `packages/hawa_api`). Move a feature to `REAL_FEATURES` once its endpoints exist.

## Clean-air routing (citizen map)

Road routes come from OSRM (`ROUTING_URL`, car/bike/foot profiles) and place search from Photon (`GEOCODING_URL`). The app adds detours around the dirtiest stretch found in the AI-ML twin, then scores every route by the PM2.5 a traveller would inhale (concentration × breathing rate × in-vehicle infiltration × time), reading the forecast-scaled field at the hour each stretch is travelled. It tags *Recommended* (dose vs extra time), *Cleanest air* and *Fastest*, suggests a better departure time, and hands the chosen route to Google Maps through its waypoints. Only start/end points go to the router; nothing about the user goes to HawaCommand.

Basemap: MapTiler when `MAP_API_KEY` is set, else Esri World Street Map (keyless, demo use). Never the OSM Foundation tile servers.

## Layout

`lib/app` (env, router, theme, l10n) · `lib/core` (network + fake backend, drift storage, outbox sync, realtime, notifications, location, media, maps, widgets) · `lib/features/<feature>/{domain,data,application,presentation}`. See `docs/app/STRUCTURE.md`.

**Legacy prototype files** (excluded from analysis). Most are unused, but `lib/app/theme.dart` is still imported by four citizen screens (safe route, live operations, ward scorecard, missed machine), so do not delete it until those screens move to `lib/app/theme/`: `lib/app/router.dart`, `lib/app/theme.dart`, `lib/core/{air,api_client,config,geo,i18n,prefs}.dart`, `lib/features/auth/*.dart` (top level), `lib/features/{citizen,driver,hub}/`, `lib/features/school/{school_alert_screen,school_data}.dart`, `lib/features/settings/settings_screen.dart`, `lib/widgets/`, `test/data_mapping_test.dart`, `test/i18n_test.dart`.
