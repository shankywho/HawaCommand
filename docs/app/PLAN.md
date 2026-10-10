# Hackathon plan: the app slice

> **Status (2026-10-10).** The app shell, five role shells, en/hi localisation, the outbox and the fake backend are built. The air map, air near me, alerts and school forecast are live against the backend. Every other flow waits on backend endpoints. Next steps: [TEAM_REMAINING_WORK_AND_PROMPTS.md](../TEAM_REMAINING_WORK_AND_PROMPTS.md#4-mobile-app-engineer-flutter); defects: [docs/app/README.md](README.md#9-known-issues). Milestones below are the original plan.


Purpose: an hour-by-hour plan for the app developer, who also owns the agents. Covers milestones with acceptance criteria, backend dependencies with a mock-first fallback, cut rules, the demo-day checklist, the post-hackathon roadmap, and the contract proposals to raise.

Related: [README](README.md) · [CONTEXT](CONTEXT.md) · [ARCHITECTURE](ARCHITECTURE.md) · [SCREENS](SCREENS.md) · [OFFLINE_AND_SYNC](OFFLINE_AND_SYNC.md) · [LINTING_AND_QUALITY](LINTING_AND_QUALITY.md) · [../SYSTEM_OVERVIEW.md](../SYSTEM_OVERVIEW.md) · [../CONTRACTS.md](../CONTRACTS.md) · [../backend/API.md](../backend/API.md) · [../frontend/DESIGN_SYSTEM.md](../frontend/DESIGN_SYSTEM.md)

---

## 1. Constraints and principles

- **One person, two jobs.** SYSTEM_OVERVIEW §11 gives the "Agents + app" column to the same developer:
  - 0–3 h: Strands skeleton; Flutter shell + lint + login
  - 3–8 h: Planner + Auditor; driver task list
  - 8–14 h: Communicator + alerts; driver route + FCM
  - 14–19 h: inspector + school screens
  - 19–22 h: integration
  - 22–24 h: demo

  The app slice gets roughly **11 of 24 hours** and must stay lean.
- **The app's job in the demo** is golden path step 6–7 ([SYSTEM_OVERVIEW §10](../SYSTEM_OVERVIEW.md#10-golden-path-build-this-first)): "Officer approves → push to the Flutter driver app + SMS → simulated HawaTag reports the spray → task auto-marked done." Demo script 1:55–2:20 shows the "driver route (Flutter app)".
- **Mock-first.** Every feature is built against fake remote sources and JSON fixtures shaped like [../backend/API.md](../backend/API.md), then switched to the real backend per feature. The UI never waits for the backend.
- **Quality floor from minute one.** Zero lint issues, Simulated badge and Hindi strings. These are cheap early and expensive late.
- **AI agents do the typing.** One brief per milestone. Review each diff against [LINTING_AND_QUALITY §11](LINTING_AND_QUALITY.md#11-code-review-checklist).

## 2. Scope and tiers (app surface)

| Tier | In the app | Why |
|---|---|---|
| **BUILD** (never cut) | OTP login, role shell, driver route list + stop detail, push `route_assignment`, auto-done via WS/push, Simulated badge, en/hi for driver screens | Flow B is the demo's field moment (§7.1, golden path step 6–7) |
| **BUILD** (lean) | Start/stop shift with foreground service, route map, Google Maps hand-off, inspector target list + detail + outcome (online) | Spike path §8.2 "Inspector closes case" |
| STRETCH | Inspector offline capture, school today + indoor/outdoor + ack (F19), citizen air + Citizen Eyes (F16, F20), tile prefetch, verified chip | F19/F20 are STRETCH in §6; WhatsApp covers them in the demo |
| VISION | Site manager screen (F9), cleaner-route tip | Specified in SCREENS.md, not built |

## 3. Before hour 0 (accounts and devices, not code)

If event rules allow preparation, do these. They're accounts and setup, not product code.

| Item | Why it can't wait | Done when |
|---|---|---|
| Firebase projects `hawacommand-dev` (+ staging) with Android apps for `in.hawacommand.field.dev`/`.stg`, debug SHA-1 added | FCM setup eats an hour on the day | `google-services.json` downloaded to the vault |
| MapTiler account + restricted key + usage cap. Plan terms checked for caching | Map tiles need a key | Key in the vault |
| Demo Android phone (Android 10+) + test SIM for the SMS fallback + a second phone | Real push, foreground service and SMS behave differently on emulators | Both phones in developer mode, `scrcpy` works |
| Emulator image API 34 with Google Play | Android 14 foreground-service type rules | Boots with Play services |
| FVM + Flutter stable installed, `.fvmrc` version chosen | Reproducible builds | `fvm flutter doctor` clean |

## 4. Hour-by-hour

`P` = app work, `A` = agents work (details in [../aiml/](../aiml/README.md)). Hours are from the hackathon start.

| Hours | Focus | Work | Output / check |
|---|---|---|---|
| 0.0–0.75 | P | Scaffold `app_frontend/` (`flutter create --org in.hawacommand --project-name hawa_app`), `.fvmrc`, deps, `analysis_options.yaml`, `build.yaml`, `l10n.yaml`, Android flavors + env files, `.github/workflows/app.yml`, Makefile. Sub-prompt 1 | **M0** |
| 0.75–1.75 | A | Strands agent skeleton | (agents) |
| 1.75–3.0 | P | Theme tokens, ARB en/hi skeleton, router + guard, session, fake auth, A2–A5 screens. Sub-prompt 2 | **M1** |
| 3.0–5.0 | A | Planner + Auditor with the OR-Tools tool | (agents) |
| 5.0–7.0 | P | drift tables (`routes`, `tasks`, `stops`, `outbox_ops`, `sync_state`), driver domain + fake remote, D1 + D3 + D4, outbox with `task_ack`/`task_status`, Simulated badge. Sub-prompts 3 + 8 (minimal drainer) | **M2** |
| 7.0–8.0 | A | Planner/Auditor wiring to the plan API | (agents) |
| 8.0–10.0 | A | Communicator agent + alert texts (en/hi), notifier hand-off | (agents) |
| 10.0–12.0 | P | Firebase + FCM + local notifications + push token + `PushRouter` deep links. WS client `tasks:me`, auto-done overlay. Switch driver to real `/v1/tasks/mine` if ready. Sub-prompt 4 | push + WS working |
| 12.0–13.5 | P | Shift start/stop (foreground service), route map (flutter_map + MapTiler + polyline + markers), Google Maps hand-off | **M3** |
| 13.5–14.0 | P | **Hour-14 checkpoint** (§7): M3 green on the real phone? If not, cut everything below and fix Flow B | go / no-go |
| 14.0–16.0 | P | Inspector I1, I3, I4 (online, photos via presign). Sub-prompt 5 | **M4** |
| 16.0–17.5 | P | STRETCH: school S1 + S2 + alert ack. Sub-prompt 6 | **M5** |
| 17.5–19.0 | A | Auditor demo scenario (rejects water on smoke), Communicator Hindi review | (agents) |
| 19.0–22.0 | All | Integration + bug bash: golden path on the real phone ×3, Hindi pass, outdoor mode, one offline pass, release APK | **M6** |
| 22.0–24.0 | All | Demo video (phone via `scrcpy`), README, blog draft | video |

Citizen Eyes (sub-prompt 7) only starts if M6 is green before hour 21. Otherwise the WhatsApp intake demonstrates F20.

## 5. Milestones and acceptance criteria

| Milestone | By | Acceptance criteria |
|---|---|---|
| **M0 Scaffold** | 0.75 h | `make lint` reports zero issues. `make test` passes (smoke test). The CI workflow runs green on a PR. `fvm flutter run --flavor dev --dart-define-from-file=env/dev.json` shows the language screen on the emulator **and** the real phone |
| **M1 Login** | 3 h | Fake mode: OTP `123456` → role home. Multi-role fixture → role picker. Kill/restart keeps the session. Logout wipes data. Language choice persists and Hindi renders in Noto Sans Devanagari. `authRedirect` unit tests pass. If backend auth is up: real `otp/request` → SMS on the test SIM → verify succeeds |
| **M2 Driver list** | 7 h | D1 renders 6 simulated stops from `tasks_mine_driver.json` in `sequence` order with IST windows. Simulated chip + badges visible. D3 shows "what to do". Opening enqueues `task_ack` ops that drain (fake: 200). Airplane mode → route still renders, skip queues and drains on reconnect. At 200 % text nothing clips |
| **M3 Flow B live** | 13.5 h | **Approve the plan on the web → the driver phone gets a push ≤ 10 s → tapping it opens D1 with the new route → the stop is auto-marked done ≤ 5 s after the simulated HawaTag's `spray_stop`** (WS when foreground, `task_done_auto` push when backgrounded). Start shift shows the ongoing "Shift on" notification. End shift removes it within 2 s. The map shows the polyline, numbered markers and attribution, and makes no OSM tile server requests |
| **M4 Inspector** | 16 h | Spike path: officer approves or assigns an inspection → `inspection_target` push → I3 shows suspect pin, cause + confidence, spike chart and the redacted citizen photo, with no reporter identity → Record outcome `closed_confirmed` with a photo (`POST /v1/inspections/{id}/close`) → the web console shows the inspection closed and the reporter gets `report_outcome`. Retrying the save never closes twice |
| M5 School (STRETCH) | 17.5 h | S1 shows today/tomorrow windows with confidence and P10–P90. Advice comes from the server (`ClassroomAdvice` `seal`/`ventilate`). A `safe_window` push opens S1 on the right date. Ack syncs, and the officer can see it |
| **M6 Demo-ready** | 22 h | Golden path steps 6–7 pass 3 times in a row on the demo phone with `make demo-reset` between runs. Both languages are demoable. No crash (Crashlytics clean). The Simulated badge is on every simulated item. Release APK installed. Backup screen recording captured |

## 6. Mock-first approach

- **One interface, two implementations.** Each feature's `*_remote_source.dart` has a `Fake*RemoteSource` reading `assets/fixtures/api/*.json`. `lib/app/providers.dart` overrides the providers when `USE_FAKE_API=true`, or for the features listed in `FAKE_FEATURES` ([ARCHITECTURE §16](ARCHITECTURE.md#16-flavors-and-configuration)).
- **Fixtures follow API.md.** When API.md lands, update the fixtures first. The contract test (fixtures must deserialize with the generated `hawa_api` models) proves the fakes and the real API agree.
- **Fake realtime.** Dev tools (Settings → Dev tools, dev flavor) has buttons:
  - "Simulate HawaTag spray (next stop)" emits a `task.done` WS event with `source=hawatag` and `is_simulated=true`
  - "Send test push" runs a local `route_assignment` payload through `PushRouter`
  - "Go offline" makes the fake sources throw `NetworkFailure`
- **Real realtime.** The backend simulator emits HawaTag `spray_start`/`spray_stop` for the assigned asset (golden path step 7). Nothing in the app changes.
- **Switch per feature.** For example `USE_FAKE_API=false`, `FAKE_FEATURES=inspector,school` while only auth + tasks are live.

## 7. Cut rules

**Never cut:** OTP login · driver route list + stop detail · auto-done from HawaTag (via WS **or** push) · `route_assignment` push · Simulated badge · Hindi on driver screens · zero lint issues.

**Hour-14 checkpoint** (aligned with the system cut rule in SYSTEM_OVERVIEW §4): if M3 isn't green on the real phone, stop all inspector/school work until it is.

Cut in this order when behind (first line goes first):

1. Site manager screen (VISION, not built anyway) and the cleaner-route tip.
2. Citizen air + Citizen Eyes screens (STRETCH). WhatsApp intake demonstrates F20.
3. School S2/S3. Keep S1 if it's already done, since WhatsApp demonstrates Flow C.
4. Inspector offline capture → online-only outcome.
5. Corridor tile prefetch → runtime tile cache only.
6. Proposed shift endpoints → local-only shift (location still only during shift).
7. WS client → rely on the `task_done_auto` push + refresh on resume.
8. Route map D2 → list + Google Maps hand-off only.

## 8. Backend dependencies and build risks

### 8.1 Dependencies

| Need | Endpoint / artefact | For | Needed by | Mock-first fallback | Owner |
|---|---|---|---|---|---|
| Auth | `POST /v1/auth/otp/request`, `/otp/verify`, `/refresh`, `GET /v1/me` | M1 | 3 h (fake), 10 h (real) | `FakeAuthRemoteSource`, OTP `123456` | backend |
| OpenAPI snapshot | `/openapi.json` with stable `operationId`s | generated client | 5 h | Hand-typed fakes until the first snapshot. Regenerate often | backend |
| Driver tasks | `GET /v1/tasks/mine?date=` with route geometry + stop fields (ARCHITECTURE §7.2) | M2 | 5 h (shape), 10 h (live) | `tasks_mine_driver.json` | backend |
| Task mutations | `POST /v1/tasks/{id}/ack`, `/status` | M2–M3 | 10 h | Fake returns 200 echo | backend |
| Realtime | WS `/v1/ws?token=` `tasks:me` with `task.done` | M3 | 11 h | Fake realtime + Dev tools | backend |
| Push | notifier FCM data payload (ARCHITECTURE §10.3) for `route_assignment`, `task_done_auto` | M3 | 11 h | Firebase console test message with the same data keys | backend |
| Push token | `PUT /v1/me/push-token` | M3 | 11 h | no-op fake | backend |
| Spray | simulator HawaTag for the assigned asset → `spray.stopped` → `task.done` | M3 | 12 h | Dev tools "Simulate HawaTag spray" | backend |
| Shifts | proposed `POST /v1/shifts/{id}/start`, `/end`, `/locations` on `asset_shift` (+ `shift.id` in `tasks/mine`) | M3 | 12 h | local-only shift | backend |
| Inspector | `GET /v1/tasks/mine` (inspect), `GET /v1/inspections?status=assigned`, proposed `GET /v1/inspections/{id}`, `POST /v1/inspections/{id}/close`, `POST /v1/uploads/presign` (presigned POST to MinIO). The officer assigns with `POST /v1/inspections/{id}/assign` (backend PCA-17) | M4 | 14 h | fixtures + fake presign (writes to a temp dir) | backend |
| School | `GET /v1/schools/me`, `/safe-window`, `/indoor-outdoor`, proposed `POST /v1/alerts/{id}/ack` | M5 | 16 h | fixtures | backend + AI-ML |
| Citizen | `GET /open/v1/air`, `POST /v1/reports`, `GET /v1/reports/mine`, `/{id}` | STRETCH | 19 h | fixtures | backend + AI-ML |

### 8.2 Risks during the build

| Risk | Mitigation |
|---|---|
| Firebase/FCM setup takes an hour (SHA-1, per-flavor config) | §3 prep. Test with a console message before writing app code |
| Android 14 foreground-service rules crash Start shift (missing typed permission) | Test on the API 34 emulator in the M3 hour. Check the merged manifest ([STRUCTURE §8](STRUCTURE.md)) |
| Venue Wi-Fi blocks FCM or WebSocket upgrades | Mobile hotspot for the demo phone. WS → polling fallback. SMS fallback on the test SIM |
| OpenAPI not ready or changes late | Mappers isolate the generated types. Fixtures + fakes keep the UI moving |
| `build_runner` gets slow | `generate_for` scoping in `build.yaml`. `make watch` during feature work |
| Devanagari rendering or clipping | Bundled Noto Sans Devanagari, line height 1.4, goldens in hi from M1 |
| The AI agent adds unreviewed packages | Review the pubspec diff every milestone |

## 9. Demo-day checklist

**Device**
- [ ] Demo Android phone charged (+ power bank). Developer options on. Screen timeout 10 min. Do Not Disturb **off**. Notification volume up.
- [ ] `scrcpy` mirroring tested on the venue projector laptop.
- [ ] Release-mode APK (staging or demo backend) installed. Version visible in Settings. Crashlytics on.
- [ ] Logged in as the seeded demo driver (phone number in the backend seed). A second role (citizen) available if Citizen Eyes is built.
- [ ] Language set for the demo moment (start in Hindi, toggle to English on stage, or the reverse).
- [ ] Outdoor mode on (it also reads better on a projector).

**Network and backend**
- [ ] Mobile hotspot with a known-good SIM for the demo phone. FCM verified over it.
- [ ] Backend demo URL reachable from the phone. `adb reverse tcp:8000 tcp:8000` fallback if running locally over USB.
- [ ] `make demo-reset` run on the backend. A fresh plan is ready to approve.
- [ ] **Test SIM** in the second phone, registered as the SMS-fallback recipient (and, if SMS goes through SNS in sandbox mode, the number is verified in SNS).

**Rehearsal (3 clean runs)**
- [ ] Approve plan on the web → push on the phone within 10 s → open route → simulated HawaTag sprays → big tick "Done by HawaTag" → web shows the intervention → verifier impact shown on web.
- [ ] Simulated badges visible on stops and asset (honesty rule).
- [ ] Optional 10 s offline moment: airplane mode → route still there → skip a stop → back online → sync chip clears.
- [ ] SMS fallback shown on the second phone.
- [ ] Backup: a screen recording of the full golden path on the phone, ready to play if the network fails.

**If something fails live:** a push doesn't arrive → open the app (WS/refresh shows the route). WS fails → pull to refresh. Backend down → switch to the dev build in fake mode and say so out loud (honesty rule).

## 10. Post-hackathon roadmap

| Horizon | Item |
|---|---|
| Weeks 1–2 | **Play Store internal testing**: Play App Signing, foreground-service (location) declaration + video, privacy policy URL, Data safety form (location during shift, photos, phone number), current target SDK |
| Weeks 1–2 | Field test with 5 drivers and 2 inspectors. Hindi copy review by field staff. TalkBack pass with a screen-reader user |
| Weeks 2–4 | **iOS**: Xcode schemes per flavor, APNs, background location during shift, TestFlight |
| Weeks 2–4 | **Offline maps**: Protomaps Delhi-NCR PMTiles extract, vector rendering, download on Wi-Fi |
| Month 2 | **Low-literacy voice prompts**: Hindi TTS for next stop and auto-done (e.g. "स्टॉप 2 पूरा, अगला पूसा रोड"), big-icon mode |
| Month 2 | Play Integrity signal on Citizen Eyes. Certificate pinning for prod. App Links (https) for SMS/WhatsApp deep links |
| Month 3 | Site manager screen (F9) once site scores ship. SMS keyword fallback ("SKIP 3 ROAD") (VISION). More NCR languages |
| Ongoing | Privacy-preserving KPIs: ack latency after dispatch, share of stops auto-done vs manual, report-to-outcome time. Device-farm runs on low-end phones |

## 11. Contract proposals to raise

These are the gaps and conflicts the app depends on. Raise them as one PR against [../CONTRACTS.md](../CONTRACTS.md) + [../backend/API.md](../backend/API.md), cross-checked with the backend docs already written (ARCHITECTURE, DATA_MODEL, CACHING, EVENTS). Exact names are below.

**Conflicts to resolve first**
1. **`POST /v1/reports` body.** CONTRACTS §6 says "multipart". Backend ARCHITECTURE §5.4 uses JSON after presign `(s3_key, lat, lon, taken_at, note)`, while DATA_MODEL §11.1 names the column `captured_at`. The app sends JSON `{client_report_id, s3_key, lat, lon, location_accuracy_m, captured_at, category, note}` and needs one agreed time field name.
2. **Two inspection close paths.** CONTRACTS lists `POST /v1/tasks/{id}/evidence` and `POST /v1/inspections/{id}/close`. The app uses **only** `POST /v1/inspections/{id}/close {outcome, notes, evidence_keys[], closed_at, location}`, and the backend marks the linked `inspect` task `done`. Late evidence on an already-closed inspection should return `200 {applied: false}` (code `inspection_already_closed`) instead of discarding field work.
3. **Multi-role users.** The backend model is single-role (`app_user.role`, JWT claim `role`). The app's role picker needs `roles[]` in `GET /v1/me` and either a `roles` claim or `POST /v1/auth/switch-role {role}` that reissues tokens. Otherwise the picker never shows.
4. **Idempotency retention.** The backend keeps `idem:{user_id}:{key}` for 24 h (CACHING §9), but outbox ops can wait up to 72 h offline. Raise retention to ≥ 72 h, **or** add a unique `citizen_report.client_report_id`. Task transitions already rely on state checks.
5. **Upload method.** CONTRACTS §6 says "S3 presigned PUT". Backend ARCHITECTURE §7 issues a presigned **POST** with policy fields. The app implements POST, so CONTRACTS should be updated.

**Endpoints (new)**
6. `POST /v1/shifts/{id}/start`, `POST /v1/shifts/{id}/end` on `asset_shift` (`ShiftStatus` `scheduled → active → completed`, DATA_MODEL §8.2), and `POST /v1/shifts/{id}/locations` `{pings: [{ts, lat, lon, accuracy_m, speed_kmh}]}`. Pings are sent only for inspection-team shifts or while the HawaTag is offline.
7. `PATCH /v1/me` `{lang, notification_prefs}` (`app_user.lang` exists).
8. `POST /v1/alerts/{id}/ack`, adding `alert.acked_at`. Visible to officers.
9. `GET /v1/inspections/{id}`: the inspector evidence bundle `{status, task_id, origin, priority, cause_label, cause_conf, suspect_pin (target_geom), back_trajectory, spike{pollutant, baseline, peak, series[]}, photos[{url, thumb_url, captured_at, expires_at}] (redacted copy), reporter{kind}, is_simulated}`.
10. An on-site transition for task-less inspections, e.g. `POST /v1/inspections/{id}/on-site` (`assigned → on_site`, sets `on_site_at`).
11. `GET /v1/me/alert-subscription`, `PUT /v1/me/alert-subscription` `{home{lat, lon}, radius_m, kinds[], quiet_hours}`. The server stores cell ids only.
12. Optional `POST /v1/ws/ticket` (single-use WS auth ticket instead of the JWT in `?token=`).

**Endpoint changes and fields**
13. `POST /v1/tasks/{id}/status` body `{status, source?, reason?, note?, litres?, s3_keys?, client_ts, location?}`. App-sent statuses per the backend state machine (ARCHITECTURE §5.2):
    - driver: `en_route`, `done` (`source=manual`, from `acknowledged`/`en_route`), `skipped`
    - inspector: `en_route`, `in_progress`
14. `POST /v1/uploads/presign` request `{purpose, content_type, content_length, sha256}`.
15. `PUT /v1/me/push-token` `{token, platform (android|ios), app_flavor, app_version, locale}`. Logout drops the session's token.
16. `POST /v1/auth/otp/request` `channel: sms | whatsapp`. An unknown phone gets `citizen` on first verify.
17. `GET /v1/grap/outlook`: allow `school`, `citizen`, `site_manager` (own ward, read-only).
18. `GET /v1/tasks/mine`:
    - `asset{tag_device_id, tag_status, tag_last_seen_at}`
    - `shift{id, status, start, end}`
    - `route{route_id, plan_id, version, geometry, bbox}`
    - per item: `sequence`, `window_start`, `window_end`, `place_name{en, hi}`, `instructions{en, hi}`, `target_litres`, `segment_length_m`, `arrival_radius_m`, `cause_label`, `cause_conf`, `completion_source`, `intervention_id`, `impact_summary{pollutant, effect_pct, ci_low, ci_high, duration_min, method, verdict}`, `version`, `updated_at`, `is_simulated`
    - inspector items add `inspection_id`, `origin`, `priority`, `hotspot_id`, `report_id`, `suspect_pin`
19. `GET /v1/reports/{id}`: expose `outcome_text`/`outcome_text_hi` and `rejection_reason` (they exist in DATA_MODEL §11.1), plus `timeline[{status, at}]` and `outcome` (`closed_*` or null). `GET /v1/reports/mine` includes WhatsApp reports matched by phone hash.
20. `GET /v1/schools/{id}/indoor-outdoor`: `advice` (`ClassroomAdvice`), `advice_reason`/`advice_reason_hi`, per-unit device status.
21. `GET /v1/sites/me`: `grade_since`, `pm10_trend[{date, pm10_p50, n_obs}]`, `flags_30d`.
22. `GET /open/v1/air` items: `aqi`, `aqi_category`, `dominant_pollutant`, `confidence`, `cause_label`, `cause_conf`, `no2_ppb`, `as_of`, `is_simulated`.

**Enums (additive, CONTRACTS §3)**
23. `AlertKind += route_changed | task_done_auto`.
24. `SkipReason = road_blocked | vehicle_issue | water_empty | unsafe | access_denied | other`, stored in `plan_task.skip_reason`.
25. `UploadPurpose = report_photo | inspection_photo | task_photo` (the DATA_MODEL key path `uploads/report_photo/…` already implies it).
26. `ClassroomAdvice = normal | seal | ventilate`: already in backend DATA_MODEL §7.7, missing from CONTRACTS §3.
27. `ReportCategory = burning | dust | other` (citizen-declared; distinct from AI-ML `verification_label`).
28. A documented mapping for inspector targets: `TaskStatus.en_route ↔ InspectionStatus.assigned`, `in_progress ↔ on_site`, `done ↔ closed_*`.

**Events and push**
29. `task.updated` on `hawa.task.lifecycle.v1` and WS `tasks:me` (sequence/window/route version change without a status change).
30. `task.verified` WS data carries the impact summary.
31. FCM data payload schema (string values): `type, alert_id, entity_id, deep_link, role, lang, title, body, args, is_simulated, sent_at, collapse_key`. `deep_link` uses the backend entity form `hawa://{entity}/{id}` (`alert.deep_link`, DATA_MODEL §10.1). The app maps entities to routes (ARCHITECTURE §5.3).

**Errors and infra**
32. problem+json `code` values the app branches on: `otp_invalid`, `otp_expired`, `otp_rate_limited`, `already_in_state`, `transition_already_past`, `task_already_done`, `task_cancelled`, `inspection_already_closed`, `upload_expired`, `media_too_large`. The backend already defines `idempotency_in_progress` (409) and `idempotency_key_mismatch` (422) in CACHING §9, and the app handles both.
33. Stable OpenAPI `operationId`s and tags (for readable generated Dart).
34. Optional `ETag` / `If-None-Match` on `GET /v1/tasks/mine` (`ETag` is already an exposed header in backend ARCHITECTURE §7).
35. Rule: the API never returns another user's phone number to app roles, not even masked (backend masks to the last 4 for non-owners, and the app renders none).

**Repo coordination (not a contract)**
36. One git hook manager: the app's `tool/hooks/pre_commit.sh` is called from the root Husky hook ([LINTING_AND_QUALITY §7](LINTING_AND_QUALITY.md#7-pre-commit-hooks)).
37. Design tokens: the Flutter theme mirrors `frontend/src/styles/tokens.json`. The web team tags the app dev on token changes (DESIGN_SYSTEM §2).
