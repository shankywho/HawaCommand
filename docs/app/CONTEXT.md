# App context: users, flows and field realities

> **Status (reconciled 2026-10-10).** Product context from the proposal. As built:
> - Live against the backend (`REAL_FEATURES`): the citizen air map, air near me, alerts and the school 72 h forecast.
> - In-app fake backend: login, driver, inspector, reports and site flows, because the backend does not serve `/v1/auth/*`, `/v1/tasks*`, `/v1/inspections*`, `/v1/reports*`, `/v1/uploads/presign` or `/v1/ws`.
>
> See [docs/app/README.md](README.md#2-implementation-status).


Purpose: the product context the app is built for, drawn from the proposal (§6, §7, §8, §10, §12.4, §15). Read it before designing any screen.

Related: [README](README.md) · [ARCHITECTURE](ARCHITECTURE.md) · [SCREENS](SCREENS.md) · [OFFLINE_AND_SYNC](OFFLINE_AND_SYNC.md) · [PLAN](PLAN.md) · [../SYSTEM_OVERVIEW.md](../SYSTEM_OVERVIEW.md) · [../CONTRACTS.md](../CONTRACTS.md) · [../backend/API.md](../backend/API.md) · [../frontend/DESIGN_SYSTEM.md](../frontend/DESIGN_SYSTEM.md)

---

## 1. Why the app exists

Delhi has 376 anti-smog guns, 266 sprinklers, 91 mechanised sweepers and ~2,000 enforcement teams (§2.3). GPS proves where a machine went, not that the air got cleaner. HawaCommand decides where to send them and then proves the effect (§5). The app is the **last metre** of that loop:

| Loop step (§5.1) | What the app does |
|---|---|
| 6 Act | Delivers routes to drivers, targets to inspectors, warnings to schools and citizens |
| 7 Verify | Shows drivers that HawaTag confirmed the spray and, later, the verified effect with its uncertainty. Closes the citizen's loop ("reporter told the outcome", F20) |
| 1 Sense (indirect) | Citizen Eyes photos become evidence that raises attribution confidence (§8.2 06:44) |

The proposal's driver surface was a PWA or WhatsApp (§7, §9 "Driver view PWA / WhatsApp"). We ship a Flutter app instead: it runs offline first, holds a foreground location service during shifts, gets reliable push, and gives one codebase for four roles. **SMS/WhatsApp stay as the fallback channel** ([SYSTEM_OVERVIEW §8](../SYSTEM_OVERVIEW.md#8-deviations-from-the-proposal)).

## 2. Users (§7)

Each row quotes the proposal's *needs / sees / does* and then says what the app gives that user.

### 2.1 Driver / field team (`driver`)

| | |
|---|---|
| Needs (§7) | "A clear route and nothing else" |
| Sees (§7) | "Ordered stops on a phone PWA or WhatsApp, with arrival windows" |
| Does (§7) | "Drives the route; HawaTag confirms the spray automatically" |
| In the app | Today's route: ordered stops, arrival windows, map polyline, "what to do" per stop (spray / sweep / run smog gun). Start/stop shift. One-tap hand-off to Google Maps. Stops **auto-mark done** when HawaTag reports the spray. Manual "mark done" appears only when the HawaTag is offline, recorded as `source=manual` with lower evidence. Skip with reason. Route-change notices. Works offline. Big buttons. Hindi first |
| Must never | Ask the driver to fill a form to prove a spray (§7.1 Flow B: "no manual reporting") |

### 2.2 Inspector (`inspector`)

| | |
|---|---|
| Needs (§7) | "A target, not an area" |
| Sees (§7) | "Suspected source pin, evidence (sensor spike, citizen photo, trajectory)" |
| Does (§7) | "Visits, records outcome" |
| In the app | Target list from hotspots or citizen reports. Suspect pin. Cause label with confidence ("likely burning, 72 %"). Evidence: spike mini-chart, citizen photo (reporter anonymous), back-trajectory line. Navigate, "Arrived", then record the outcome (`closed_confirmed` / `closed_not_found` / `closed_unreachable`) with photos and notes. Works offline and syncs later |
| Must never | Present attribution as proof. §15: "Always shown with confidence; used to choose the tool, not to fine anyone" |

### 2.3 School principal (`school`)

| | |
|---|---|
| Needs (§7) | "When is it safe outdoors" |
| Sees (§7) | "WhatsApp alert with safe window; indoor vs outdoor readings" |
| Does (§7) | "Moves assembly or sport; seals or ventilates classrooms" |
| In the app | Today/tomorrow safe outdoor windows with uncertainty. Forecast summary (P50 with P10–P90 range). Indoor vs outdoor PM2.5 and indoor CO₂ from the HawaPod-S pair, with "keep windows shut" or "ventilate now" advice. Alert inbox with **acknowledge**. Hindi/English toggle |
| Must never | Hide uncertainty behind a single "safe" word. The window always shows its range and confidence |

### 2.4 Citizen / outdoor worker (`citizen`)

| | |
|---|---|
| Needs (§7) | "Should I avoid this road now" |
| Sees (§7) | "Pollutant-specific alert, cleaner-route tip" |
| Does (§7) | "Reports burning with a photo" |
| In the app | Nearby **indicative** air: AQI chip, dominant pollutant, pollutant-specific advice (masks and indoors for PM2.5 smoke, avoid the road for traffic NO₂; F16, §4.2 Japan lesson). Location-based alert subscription. **Citizen Eyes**: camera photo + GPS + time + optional note, privacy notice, upload via presign. Status timeline `submitted → verifying → verified → ticketed → closed` with the outcome told back. Cleaner-route tip (STRETCH) |
| Must never | Show the reporter's identity or number to anyone, or accept gallery photos as fresh evidence |

### 2.5 Site manager (`site_manager`)

| | |
|---|---|
| Needs (§7) | "Stay compliant, avoid shutdowns" |
| Sees (§7) | "Own Site Compliance Score and PM10 trend" |
| Does (§7) | "Fixes dust control; earns a better grade" |
| In the app | Read-only: own site's A/B/C grade, PM10 trend, recent flags. VISION in the app (screen specified, built only if everything else is done) |
| Must never | Present the grade as a legal finding. §12.4: "Low-cost sensors are indicative, not regulatory-grade" |

### 2.6 Not in the app

Ward/district officers, admins and analysts use the web console (`frontend/`). Plan approval (Flow A), What-If and impact review are web-only. If an officer logs into the app, the app shows a single "Use the web console" screen.

## 3. Flows, step by step

### 3.1 Flow B: driver runs a route, with no manual reporting (§7.1)

| # | What happens | System | App | Driver does |
|---|---|---|---|---|
| 1 | Officer approved the master plan at ~20:00 (Flow A, web) | `plan.approved` | nothing yet | sleeps |
| 2 | 05:30 dispatch releases tasks | `dispatch-worker` → `task.dispatched`. Notifier → push `route_assignment`. If there's no ack within 15 min, it re-notifies via WhatsApp, then SMS, then alerts the ward officer (backend ARCHITECTURE §5.2) | Notification "Today's route is ready" | taps it |
| 3 | Route opens | `GET /v1/tasks/mine?date=` | Caches route, stops and map tiles for the route corridor. Queues `POST /v1/tasks/{id}/ack` for each task (outbox) | sees ordered stops + windows |
| 4 | Start shift | proposed `POST /v1/shifts/{id}/start` (`asset_shift` → `active`) | Starts the Android foreground location service (notification "Shift on") | taps **Start shift** |
| 5 | Go to stop 1 | `POST /v1/tasks/{id}/status` `en_route` | Hands off to Google Maps | drives |
| 6 | Arrives | nothing is sent. Arrival is local, and the server sets `in_progress` itself on `spray.started` | Geofence (150 m) or a tap shows "what to do": spray 600 L along 800 m | starts pump |
| 7 | HawaTag detects flow + pump on (§10.4) | `spray_start` → `task.in_progress`. `spray_stop` → ingest → `spray.stopped` → `task.done` (`source=hawatag`) | WS `tasks:me` `task.done`, or push `task_done_auto` if backgrounded. Big green tick + chime, then next stop | nothing |
| 8 | Before/after PM captured | HawaTag cab-roof PMS5003 (§10.4) | none | none |
| 9 | Verifier scores the effect, 2–4 h later | `impact.verified` → `task.verified` | "Verified: PM10 −18 % for 90 min (range −26 % to −10 %)" on the stop, next time the driver looks | none |
| 10 | End shift | proposed `POST /v1/shifts/{id}/end` | Stops location service. Shift summary | taps **End shift** |

Fallbacks inside Flow B:
- If the HawaTag is offline (`DeviceStatus` `offline`/`degraded`, push `device_health`), the stop card shows **Mark done**, recorded `source=manual` with a "lower evidence" label.
- If a stop can't be served (road blocked, tank empty), the driver taps **Skip** and picks a reason. Skip is available even when the HawaTag is online, because a blocked road is not a sensor fault.
- If the route changes (re-plan at 08:00 / 11:00 / 14:00, CONTRACTS §11), push `route_changed` arrives and a banner shows what was added and removed.

### 3.2 Flow C: school protection (§7.1, F19)

| # | What happens | System | App | Principal does |
|---|---|---|---|---|
| 1 | Forecast: PM2.5 P50 > 250 µg/m³ at 08:00 near the school (CONTRACTS §10.3 school trigger) | AI-ML forecaster, `school.safe_window_computed` | nothing | |
| 2 | Communicator drafts the alert (19:00) | alert-engine → notifier: WhatsApp + push `safe_window` | Notification "Tomorrow: hold assembly indoors" | reads it |
| 3 | Principal acknowledges | proposed `POST /v1/alerts/{id}/ack` | Alert marked acknowledged. The officer console sees it | taps **I've read this** |
| 4 | 22:00 final safe windows | push `safe_window` (final) | Today/tomorrow card updates: window + range + confidence | plans PE for the window |
| 5 | Morning: assembly moved indoors | none | Indoor vs outdoor card: outdoor PM2.5 212, indoor 74, CO₂ 1,050 ppm → **Keep windows shut** | keeps windows shut |
| 6 | CO₂ rises in class | HawaPod-S indoor (Senseair S8, §10.4) | Advice flips to **Ventilate now (5 min)** when the server says so | opens windows briefly |
| 7 | Safe window for PE | `safe_window` update | "Safe outdoor time: 13:30–15:00" | moves PE |

The indoor/outdoor ratio "proves whether an alert actually protected children" (§10.4). The app shows the ratio. It doesn't turn it into a grade.

### 3.3 Flow D: Citizen Eyes (§7.1, F20)

| # | What happens | System | App | Citizen does |
|---|---|---|---|---|
| 1 | Citizen sees burning | | **Report burning** (first time: privacy notice) | taps |
| 2 | Photo + GPS + time | | Camera only (no gallery). Compress and **strip EXIF**. GPS from geolocator with accuracy. Optional note | takes photo, adds note |
| 3 | Submit | `POST /v1/uploads/presign` → S3 presigned POST → `POST /v1/reports` (JSON with `s3_key`, Idempotency-Key) | Works offline: saved to `reports_draft`, sent by the outbox | taps **Send** |
| 4 | Vision model verifies | `report.verified` / `report.rejected` | Status timeline: `verifying` → `verified` | |
| 5 | Matched to nearby sensor spike | intel-worker (§8.2 06:44) | Status detail: "Matched to a sensor spike nearby" | |
| 6 | Inspection dispatched | dispatch-worker opens an inspection → `report.ticketed`. The officer taps assign (`POST /v1/inspections/{id}/assign`, backend PCA-17) → push `inspection_target` | `ticketed`: "An inspector has been sent" | |
| 7 | Inspector closes the case | inspector app `POST /v1/inspections/{id}/close` → `report.closed` with `outcome_text` (en + hi) | push `report_outcome` with the outcome in plain words | reads the outcome |

WhatsApp remains an equal intake channel (`POST /v1/reports/webhook/whatsapp`). Reports sent over WhatsApp from the same phone number should appear in **My reports** too (proposed: `GET /v1/reports/mine` includes WhatsApp reports matched by phone).

### 3.4 Real-time spike path: inspector view (§8.2)

| Time | System | Inspector app |
|---|---|---|
| 06:42 | Bus 7 TinyML flags PM2.5 ×3 in 20 s | none |
| 06:43 | Fingerprint → "likely open burning" | none |
| 06:44 | Citizen photo 300 m away verified + matched → confidence high | none |
| 06:45 | Planner proposes nearest inspection team; Auditor confirms a sprinkler would not help smoke; officer approves | push `inspection_target`: "Likely burning near Anand Parbat, confidence high" |
| 06:46–07:05 | none | Opens target: suspect pin, spike mini-chart, citizen photo, back-trajectory line. **Navigate**. **Arrived** (`in_progress`) |
| 07:10 | Inspector closes the case; verifier tracks the cell back to baseline | **Record outcome** → `closed_confirmed` + 2 photos + note. Synced now or later |

## 4. The day from a field user's view (§8, CONTRACTS §11; all IST)

| Time | Driver | Inspector | School principal | Citizen / outdoor worker |
|---|---|---|---|---|
| 19:00 | | | Push/WhatsApp `safe_window` draft for tomorrow (Flow C) | `grap_outlook` if GRAP ≥ 3 is likely in the next 48 h |
| 20:00 | (officer approves on web) | | | |
| 22:00 | | | Final safe windows (push `safe_window`) | |
| 05:30 | Push `route_assignment` + SMS fallback | Push `inspection_target` for planned site checks | | |
| 05:45 | Opens route, app acks tasks, **Start shift** | Opens targets | | |
| 06:00–10:00 | Operations: stops auto-done by HawaTag. `route_changed` possible after the 08:00 re-plan | Spike path targets (§8.2), outcomes recorded | 06:30 (STRETCH) PE safe window confirmed by the live indoor/outdoor ratio (backend ARCHITECTURE §5.5). 08:00 assembly: indoor vs outdoor, "keep windows shut" | `pollutant_warning` on the way to work ("avoid this road until 10:00") |
| 11:00 | Verification batch: stops show "Verified" / "Inconclusive" | | Safe window for PE confirmed | `report_outcome` for morning reports |
| 14:00 | Afternoon re-plan: possible new route | New targets | | |
| Evening | **End shift** (location sharing stops) | End of day | Tomorrow's windows arrive at 19:00 | Evening `pollutant_warning` (markets weighted higher in the evening, §9.4) |

## 5. Features that surface in the app

Tiers from §6: **BUILD** works in the demo · **STRETCH** if time allows · **VISION** architecture only. "App tier" is the tier for *the app surface* (see [PLAN.md](PLAN.md) §7 cut rules).

| ID | Feature | Proposal tier | App surface | App tier |
|---|---|---|---|---|
| F17 | HawaTag intervention tracking | BUILD | Driver stops auto-marked done; manual fallback when the tag is offline | **BUILD** |
| F13 | Dispatch optimiser | BUILD | Driver route order + arrival windows (consumed, not computed) | **BUILD** |
| F7 | Source fingerprint + back-trajectory | BUILD | Inspector cause label + confidence, suspect pin, trajectory line | **BUILD** |
| F18 | Causal verification | BUILD | "Verified: effect ± CI" on driver stops | STRETCH (show when available) |
| F16 | Targeted, pollutant-specific alerts | BUILD (via WhatsApp/SMS) | Push + inbox + pollutant-specific advice | STRETCH (the WhatsApp/SMS path is BUILD on the backend) |
| F6 | GRAP Copilot | BUILD (web) | `grap_outlook` alerts only | STRETCH |
| F5 | 72 h forecaster | BUILD | School forecast summary P10/P50/P90 | STRETCH |
| F19 | School safe-window scheduler | STRETCH | School today/tomorrow, indoor vs outdoor, ack | STRETCH |
| F20 | Citizen Eyes | STRETCH | Report capture, upload, status timeline, outcome | STRETCH |
| F4 | Air digital twin | BUILD (web) | Citizen "air near me" (indicative, from `/open/v1/air`) | STRETCH |
| F9 | Site Compliance Score | STRETCH | Site manager read-only grade + PM10 trend | **VISION** |
| F21 | Open Air Data | STRETCH | Data source for the citizen air view | consumed |

## 6. Honesty rule

"One real pod, a simulated fleet, a real pipeline" ([SYSTEM_OVERVIEW §1.4](../SYSTEM_OVERVIEW.md)). In the demo, almost every task, asset and HawaTag is simulated. The app says so:

- Any entity with `is_simulated: true` (task, asset, device, reading, intervention, school pod reading, air cell) renders a purple **Simulated / सिम्युलेटेड** badge (token `simulated` `#7C3AED`) next to it. It is never hidden, even in the demo.
- A screen with any simulated item shows a top chip: "Includes simulated data / इसमें सिम्युलेटेड डेटा शामिल है" (the DESIGN_SYSTEM `SimulatedBadge` "includes" variant, with the flask icon).
- AQI is always labelled **indicative / सांकेतिक** (CONTRACTS §10.1: hourly AQI from twin values, not the official 24 h AQI). Official stations remain the legal record (§12.4).
- Every model output ships with its uncertainty (CONTRACTS §1): forecast P10–P90, twin confidence, `cause_conf`, impact `ci_low`/`ci_high`. The app never shows a bare point estimate. A naive before/after impact (`before_after_naive`) or a `manual` completion is labelled **lower evidence**.

## 7. Privacy commitments

The proposal lists privacy as a risk (§15: "Privacy (cameras, locations)"), and §12.4 limits camera data to evidence-only. The app commits to the following. Each item maps to a test or review check in [LINTING_AND_QUALITY.md](LINTING_AND_QUALITY.md).

| Commitment | How |
|---|---|
| **Driver/inspector location only during shift** | Location is sampled only between **Start shift** and **End shift**, by an Android foreground service with a visible ongoing notification. There is no `ACCESS_BACKGROUND_LOCATION` permission. Auto-stop at scheduled shift end + 2 h. Positions leave the phone only when the server has no other source: inspection-team shifts, or a driver whose HawaTag is offline. Otherwise they stay on the device for arrival detection and are purged at shift end. This matches backend CONTEXT §7.5: HawaTag positions belong to the machine, not the person |
| Citizens' location is coarse unless they report | "Air near me" sends a bbox snapped to a ~1 km grid, not the exact point. Alert subscription stores a server-resolved cell, never a raw trail. Precise GPS is sent only as part of a Citizen Eyes report |
| **Citizen photos EXIF-stripped** | Re-encoded on device (`keepExif: false`), which drops GPS/device EXIF. The server strips and re-encodes again (defence in depth, backend ARCHITECTURE §5.4) and keeps a faces/plates-blurred copy for officers and inspectors (`photo_redacted_key`). Location travels as explicit report fields. Camera only |
| **Phone numbers never shown to other users** | No screen renders another user's phone number. Inspectors see "Reported by a citizen". The API must not return other users' phone numbers to app roles (proposed rule for API.md). The user's own number is masked in Profile (`+91 98•••••210`) |
| No faces or plates on purpose | The Citizen Eyes privacy notice asks people to photograph the fire, not people or number plates. Server-side handling follows §15: "no faces or plates stored by default outside authorised review" |
| Minimal permissions | Location (while in use), notifications, camera (just in time). No contacts, SMS read, storage, microphone or background location |
| Shared devices | Logout wipes tokens, the drift database, cached photos and preferences except language. Logout warns if the outbox has unsent items |
| No PII in logs/crashes | Phone numbers, OTPs and tokens are never logged. Crash reports carry a hashed user id |

## 8. Field realities and design responses

| Reality | Design response |
|---|---|
| Low-end Android (2–3 GB RAM, slow storage) | Release (AOT) builds for testers. Cold start ≤ 2.5 s to cached route. Drift on a background isolate. Few heavy packages. APK ≤ 25 MB per ABI |
| Patchy 4G, dead zones in lanes and underpasses | Offline-first: route, stops, targets, windows and alerts are cached. Every mutation goes through the outbox with idempotency. The UI never blocks on the network |
| Sunlight on the screen | High-contrast **outdoor mode**: light surface, ink `#0B1220` text, 2 dp borders, no translucency, larger base type. Default for the driver shell |
| Gloves, one hand, vibrating cab | Primary targets 64 dp (minimum 48 dp everywhere). No swipe-only or long-press-only actions. Confirmations use two large buttons |
| Hindi-first, varied literacy | Language picker is the first screen. Driver strings are short and icon-led. The same icon and colour always mean the same thing. Colour is never the only signal. Voice prompts are on the roadmap |
| Shared or handed-over phones | Fast logout/switch user. No data from the previous user survives logout |
| Wrong device clocks | The client sends `client_ts`. The server's `Date` header gives a skew estimate and displayed times use server-corrected time |
| Battery anxiety during 5 h shifts | Battery-aware sampling (distance filter, slower when stationary or on low battery). WS only in the foreground |
| Venue/depot Wi-Fi blocks FCM | SMS fallback for route assignment. The app refetches on resume |
| Mixed Android skins that kill background work | Foreground service during shift. Outbox also drains on resume and on connectivity regain. Periodic workmanager job is best-effort only |

## 9. SMS and WhatsApp fallback

The app is not the only channel. The proposal's reach promise is "drivers get a route; schools get a WhatsApp message in Hindi or English" (§1).

| Situation | Fallback | Owner |
|---|---|---|
| Driver has no smartphone or the app isn't installed | SMS/WhatsApp route summary at 05:30: ordered stop names + windows. HawaTag still auto-confirms sprays, so nothing else is needed from the driver | backend notifier |
| Push not acknowledged | The dispatch saga re-notifies every 15 min on the next channel (push → WhatsApp → SMS), then alerts the ward officer (backend ARCHITECTURE §5.2, `HAWA_DISPATCH_ACK_TIMEOUT_MIN`). The app acks on first open of the route, so an unopened route escalates | backend dispatch-worker + notifier |
| School principal not on the app | WhatsApp alert with the safe window (the proposal's primary channel for schools) | notifier (Communicator text) |
| Citizen not on the app | WhatsApp photo to the Citizen Eyes number (`/v1/reports/webhook/whatsapp`); outcome told back on WhatsApp | backend |
| Phone has SMS but no data | SMS keyword replies (e.g. "SKIP 3 ROAD") | VISION |

The app shows the fallback exists. For example, the notifications permission screen says "If notifications are off, we'll send your route by SMS."

## 10. Non-goals

- No plan approval, editing, What-If or impact analysis in the app (web console only).
- No in-app turn-by-turn routing engine: navigation is handed off to Google Maps.
- No manual spray reporting in the normal path. Manual "done" exists only as the HawaTag-offline fallback.
- No location collection outside a shift. No background location permission.
- No gallery uploads for Citizen Eyes (camera only), no social feed, no public naming of polluters.
- No city-wide twin exploration for drivers or inspectors (they see their route or target only).
- No official AQI claims. All AQI is indicative, and official stations remain the legal record (§12.4).
- No iOS feature parity during the hackathon. Android is primary.
- No in-app chat or calling between users, and no display of other users' numbers.
- No regulatory enforcement actions from the site manager or inspector screens (attribution is not proof, §15).

## 11. Glossary

| Term | Meaning |
|---|---|
| HawaTag (`HTG-NNNN`) | Tracker on a sprinkler/smog gun/sweeper: flow sensor + pump current + GPS + cab-roof PM (§10.4). Spray = flow > 5 lpm and pump current > 2 A for ≥ 10 s (CONTRACTS §4.3) |
| HawaPod-S pair (`HPS-NNNN-O` / `-I`) | School sentinel: outdoor unit + indoor unit with CO₂ (Senseair S8) (§10.4) |
| Stop | One driver task (`TaskKind` `spray` or `sweep`) at a location with an arrival window |
| Target | One inspector task (`TaskKind` `inspect`) linked to an inspection, from a hotspot or a citizen report |
| Indicative AQI | Hourly AQI computed from twin values with CPCB breakpoints. Not the official 24 h AQI (CONTRACTS §10.1) |
| Safe window | A time range when forecast outdoor exposure near a school is below the alert threshold, with uncertainty (F19) |
| Outbox | Local queue of pending mutations, each with a client UUID used as `Idempotency-Key` ([OFFLINE_AND_SYNC](OFFLINE_AND_SYNC.md)) |
| Lower evidence | An intervention completed with `source=manual` or verified by `before_after_naive`. Still counted, but flagged |
