# HawaCommand Field & Community: Flutter app docs

Purpose: the index and quick start for the Flutter app in `app_frontend/`, used by drivers, inspectors, school principals, citizens and site managers.

Related: [CONTEXT](CONTEXT.md) · [ARCHITECTURE](ARCHITECTURE.md) · [STRUCTURE](STRUCTURE.md) · [SCREENS](SCREENS.md) · [OFFLINE_AND_SYNC](OFFLINE_AND_SYNC.md) · [LINTING_AND_QUALITY](LINTING_AND_QUALITY.md) · [PLAN](PLAN.md) · [../CONTRACTS.md](../CONTRACTS.md) · [../SYSTEM_OVERVIEW.md](../SYSTEM_OVERVIEW.md) · [../backend/API.md](../backend/API.md) · [../frontend/DESIGN_SYSTEM.md](../frontend/DESIGN_SYSTEM.md)

---

## 1. What this app is

HawaCommand closes the loop Sense → Map → Attribute → Forecast → Decide → **Act** → **Verify** (§5). The web console (`frontend/`) is where officers decide. This app is where the city **acts** and where people are **protected**:

- **Drivers** get an ordered route at 05:30. HawaTag confirms each spray automatically, so the driver never files a report (Flow B, §7.1).
- **Inspectors** get a target (a suspect pin with evidence), not an area, and record the outcome (§7, §8.2).
- **School principals** get safe outdoor windows and indoor vs outdoor readings from their HawaPod-S pair (Flow C, F19).
- **Citizens and outdoor workers** get pollutant-specific advice and can report burning with a photo (F16, F20, Flow D).
- **Site managers** see their own A/B/C grade and PM10 trend (F9, VISION in the app).

SYSTEM_OVERVIEW §8 records the deviation: *"Driver phone PWA → Flutter app (driver + inspector + school + citizen roles); SMS/WhatsApp remain the fallback."* The app is one binary with role-based shells after phone-OTP login.

## 2. Reading order

| # | Doc | Read it when | Main readers |
|---|---|---|---|
| 1 | [CONTEXT.md](CONTEXT.md) | First. Covers who the users are, the flows, field realities, privacy and non-goals | Everyone |
| 2 | [ARCHITECTURE.md](ARCHITECTURE.md) | Before writing code. Covers layers, Riverpod, go_router, Dio + generated client, realtime, location, maps, i18n, theme, security | App dev, AI agents |
| 3 | [STRUCTURE.md](STRUCTURE.md) | When creating files. Gives the full `app_frontend/` tree with one line per file | App dev, AI agents |
| 4 | [SCREENS.md](SCREENS.md) | When building a screen. Gives routes, data, wireframes, states, en/hi copy, acceptance criteria and the push catalogue | App dev, designers, backend (push types) |
| 5 | [OFFLINE_AND_SYNC.md](OFFLINE_AND_SYNC.md) | Before touching any mutation. Covers the drift schema, outbox, idempotency, conflicts and the failure matrix | App dev, backend |
| 6 | [LINTING_AND_QUALITY.md](LINTING_AND_QUALITY.md) | Before the first commit. Covers lints, hooks, CI YAML, the testing strategy and DoD | App dev, AI agents |
| 7 | [PLAN.md](PLAN.md) | At hour 0 of the hackathon. Gives hour-by-hour work, milestones, cut rules and the demo checklist | App dev, team lead |

Binding upstream docs: [../CONTRACTS.md](../CONTRACTS.md) holds the enums, units, endpoint index, WS channels, the `is_simulated` rule and the uncertainty rule. [../backend/API.md](../backend/API.md) holds the request/response shapes, auth and JWT claims. **If a shape in these app docs disagrees with API.md, API.md wins.** File a contract PR rather than hand-patching the client.

## 3. What the app owns

| The app owns (`app_frontend/`) | The app does **not** own |
|---|---|
| Phone-OTP login UX, token storage, role picker | OTP generation, SMS sending, JWT issuing (backend `api`) |
| Role shells: driver, inspector, school, citizen, site manager | Officer console, plan approval, What-If (web `frontend/`) |
| Today's route, stop list, route map, navigation hand-off | Route optimisation (AI-ML optimiser), dispatch (backend `dispatch-worker`) |
| Shift start/stop and location sharing **only during shift** | Fleet positions from HawaTag GPS (backend ingest) |
| Displaying HawaTag auto-done and verified results | Spray detection (HawaTag firmware + ingest), verification (AI-ML verifier) |
| Inspector evidence viewer and outcome capture, including offline | Hotspot attribution, back-trajectory (AI-ML) |
| School safe windows, indoor/outdoor view, alert acknowledgement | Safe-window computation (AI-ML), alert drafting (Communicator agent) |
| Citizen air view, alert subscription, Citizen Eyes capture + upload | Photo verification (vision model), inspection ticketing (backend) |
| Offline cache (drift), outbox with idempotency, sync | Server-side idempotency store, conflict authority (backend) |
| FCM token registration, local notifications, deep links | Sending pushes/SMS/WhatsApp (backend `notifier`) |
| Generated API client package `packages/hawa_api` (generated, not hand-edited) | The OpenAPI document itself (backend, `/openapi.json`) |
| App CI workflow `.github/workflows/app.yml` (path filter `app_frontend/**`) | Other folders' CI |

## 4. Roles and tiers at a glance

| Role (`UserRole`) | Shell | Tier in the app | Core screen |
|---|---|---|---|
| `driver` | Driver | **BUILD** (Flow B, never cut) | Today's route + auto-done stops |
| `inspector` | Inspector | **BUILD** (online first; offline capture STRETCH) | Target list, evidence, record outcome |
| `school` | School | STRETCH (F19) | Safe windows, indoor vs outdoor, alert ack |
| `citizen` | Citizen | STRETCH (F16 app surface, F20) | Air near me, Citizen Eyes report + status |
| `site_manager` | Site | VISION (read-only screen spec only) | Own grade + PM10 trend |

Officers, admins and analysts use the web console. If one of them logs into the app, it shows "Use the web console" and nothing else.

## 5. Quick start

### 5.1 Prerequisites

| Tool | Why | Notes |
|---|---|---|
| [FVM](https://fvm.app) | Pins Flutter per repo | The Flutter version is pinned in `app_frontend/.fvmrc` (latest stable at project start) |
| Android Studio + SDK + an emulator image with Google Play services | Android build + FCM on emulator | JDK 17 (the JBR bundled with Android Studio works) |
| A real Android phone (Android 8+ recommended) | Push, foreground service and camera behave differently on emulators | USB debugging on |
| Docker | `make gen-api` runs `openapi-generator` in a container | Image tag pinned in the Makefile |
| `make` | Convenience targets | On Windows use Git Bash + `make` (e.g. via Chocolatey) or run the commands in the Makefile by hand |
| Firebase CLI + FlutterFire CLI (optional) | Only if you (re)configure Firebase projects | `flutterfire configure` per flavor |

Package versions are **latest stable, pinned in `pubspec.lock`**. The Flutter version is pinned in `.fvmrc`. Don't bump either in a feature PR.

### 5.2 First run

```bash
cd app_frontend
fvm install                                   # installs the Flutter version from .fvmrc
fvm flutter pub get
fvm dart run build_runner build -d            # freezed, json_serializable, riverpod_generator, drift
cp env/dev.json.example env/dev.json          # fill MAP_API_KEY; keep USE_FAKE_API=true until the backend is up
fvm flutter run --flavor dev --dart-define-from-file=env/dev.json
```

In fake mode (`USE_FAKE_API=true`) the OTP is `123456` and the route comes from JSON fixtures shaped like [API.md](../backend/API.md). The dev flavor shows a **Dev tools** entry in Settings with "Simulate HawaTag spray", "Send test push" and "Go offline".

### 5.3 Pointing at a real backend

| Device | `API_BASE_URL` / `WS_URL` in `env/dev.json` | Extra step |
|---|---|---|
| Android emulator | `http://10.0.2.2:8000` / `ws://10.0.2.2:8000/v1/ws` | none (the dev network security config allows cleartext to 10.0.2.2 only) |
| USB phone | `http://localhost:8000` / `ws://localhost:8000/v1/ws` | `adb reverse tcp:8000 tcp:8000` |
| Phone on venue Wi-Fi | staging HTTPS URL | use `--flavor staging --dart-define-from-file=env/staging.json` |

Set `USE_FAKE_API=false`. The backend's local stack comes up with `docker compose up` at the repo root (see [../SYSTEM_OVERVIEW.md](../SYSTEM_OVERVIEW.md) §9).

### 5.4 Everyday commands

| Command | Does |
|---|---|
| `make gen` | `dart run build_runner build -d` |
| `make watch` | build_runner in watch mode |
| `make l10n` | `flutter gen-l10n` (ARB → `lib/app/l10n/gen/`) |
| `make lint` | format check + `flutter analyze --fatal-infos` + `dart run custom_lint` (must be zero issues) |
| `make fix` | `dart fix --apply` then `dart format` |
| `make test` | `flutter test --coverage` (unit + widget + golden) |
| `make it` | Flow B integration test on a running emulator against `tool/mock_server` |
| `make run FLAVOR=staging` | run another flavor |
| `make apk FLAVOR=dev` | release-mode APK, split per ABI, for testers |
| `make gen-api API_URL=http://localhost:8000` | refresh `openapi/openapi.json` and regenerate `packages/hawa_api` |
| `make mock-server` | start the scripted mock API + WS on :8081 |

### 5.5 Regenerating the API client

`packages/hawa_api` is **generated from the backend's `/openapi.json` with `openapi-generator` (`dart-dio`) and committed**. Never edit it by hand. When the backend changes an endpoint:

1. The backend merges the change and updates [../backend/API.md](../backend/API.md).
2. The app dev runs `make gen-api API_URL=<backend>`, which writes `openapi/openapi.json` and regenerates the package.
3. Fix the compile errors in `features/*/data/` mappers only. Presentation code never imports `hawa_api`.
4. Commit the snapshot and the generated package together, as `chore(app): regenerate hawa_api`.

## 6. Supported platforms

| Platform | Status | Details |
|---|---|---|
| **Android** | **Primary** | `minSdk 24` (Android 7.0), `targetSdk` = the level Google Play currently requires, `compileSdk` = latest stable |
| iOS | Secondary (post-hackathon parity) | Builds and runs; flavors, APNs and background location are wired after the hackathon (see [PLAN.md](PLAN.md) §10). Minimum iOS = the higher of Flutter's and Firebase's current minimums, set in `ios/Podfile` |
| Web / desktop | Not supported | Officers use `frontend/` |

**Why minSdk 24.**
- Plugins we depend on (flutter_secure_storage with Keystore-backed AES, camera/image compression, workmanager, drift's bundled SQLite) are best supported and tested at 23+.
- API 24 adds network security config improvements and file-based encryption on most devices.
- Android 7+ covers the overwhelming majority of active Android devices in India. Our field users are on low-end *recent* phones, not on 2014 hardware.

Going lower would add test burden and no users. Going higher (26+) would exclude some donated or older phones that municipal field teams still carry. Revisit with Play Console device stats after the pilot.

**Reference low-end device** for performance budgets: Android 10–12, 2–3 GB RAM, 720p screen, entry-level octa-core SoC. Budgets are in [ARCHITECTURE.md §19](ARCHITECTURE.md#19-performance-budgets).

## 7. Key decisions (one line each)

| Decision | Choice | Where |
|---|---|---|
| Architecture | Feature-first, layered: presentation → application → domain → data | [ARCHITECTURE §2](ARCHITECTURE.md#2-layers) |
| State | Riverpod with `riverpod_generator` | [ARCHITECTURE §4](ARCHITECTURE.md#4-state-management-riverpod-with-code-generation) |
| Navigation | go_router, role-based `StatefulShellRoute`s, redirect guard, push deep links | [ARCHITECTURE §5](ARCHITECTURE.md#5-navigation-go_router) |
| Networking | Dio + generated `hawa_api` (openapi-generator `dart-dio`) + interceptor chain | [ARCHITECTURE §6](ARCHITECTURE.md#6-networking) |
| Offline | drift (SQLite) cache + outbox with `Idempotency-Key`, server authoritative | [OFFLINE_AND_SYNC](OFFLINE_AND_SYNC.md) |
| Realtime | WS `/v1/ws?token=` (`tasks:me`, `alerts:me`) in foreground + FCM data messages | [ARCHITECTURE §10](ARCHITECTURE.md#10-realtime-websocket--fcm) |
| Location | geolocator + Android foreground service, **only during shift** | [ARCHITECTURE §11](ARCHITECTURE.md#11-location-and-shift) |
| Maps | flutter_map + MapTiler raster tiles (Protomaps post-hackathon); never bulk-fetch tile.openstreetmap.org | [ARCHITECTURE §12](ARCHITECTURE.md#12-maps) |
| i18n | `flutter_localizations` + ARB, en + hi, Inter + Noto Sans Devanagari bundled | [ARCHITECTURE §14](ARCHITECTURE.md#14-internationalisation-en--hi) |
| Lints | `very_good_analysis` + `custom_lint` + `riverpod_lint`, zero issues | [LINTING_AND_QUALITY](LINTING_AND_QUALITY.md) |
| Crash reporting | Firebase Crashlytics (Firebase is already required for FCM) | [ARCHITECTURE §17](ARCHITECTURE.md#17-errors-logging-and-crash-reporting) |

## 8. Links

- System context: [../SYSTEM_OVERVIEW.md](../SYSTEM_OVERVIEW.md) (golden path step 6, hackathon plan §11)
- Contracts (binding): [../CONTRACTS.md](../CONTRACTS.md) (§3 enums, §6 REST + WS index, §10 AQI/GRAP)
- Backend API (shapes, auth, JWT claims): [../backend/API.md](../backend/API.md)
- Design tokens: [../frontend/DESIGN_SYSTEM.md](../frontend/DESIGN_SYSTEM.md)
- Web console docs: [../frontend/README.md](../frontend/README.md)
- AI-ML docs (safe windows, attribution, verifier): [../aiml/README.md](../aiml/README.md)
- Source proposal: `HawaCommand_Proposal.pdf` (§6 features, §7 users/flows, §8 timeline, §10 hardware, §12.4 privacy, §15 risks)
