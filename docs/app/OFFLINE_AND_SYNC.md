# Offline-first and sync

> **Status: Implemented in the app, unverified end to end.** The drift outbox, drainer, backoff, conflict resolver and background sync live in `app_frontend/lib/core/sync/` and `lib/core/storage/`. Today every outbox write goes to the in-app fake backend, because the backend has none of the write endpoints. Known defects: multi-photo inspection close ordering, and the presign hash after re-compression ([docs/app/README.md](README.md#9-known-issues), issues 10-11). Not run on a device by the reviewer.


Purpose: how the app keeps working with patchy 4G. Covers what is cached, the drift schema, the outbox for mutations, idempotency, conflict resolution, sync triggers, staleness, cleanup, offline testing and the failure matrix.

Related: [README](README.md) · [ARCHITECTURE](ARCHITECTURE.md) · [STRUCTURE](STRUCTURE.md) · [SCREENS](SCREENS.md) · [LINTING_AND_QUALITY](LINTING_AND_QUALITY.md) · [../CONTRACTS.md](../CONTRACTS.md) · [../SYSTEM_OVERVIEW.md](../SYSTEM_OVERVIEW.md) · [../backend/API.md](../backend/API.md) · [../frontend/DESIGN_SYSTEM.md](../frontend/DESIGN_SYSTEM.md)

---

## 1. Principles

1. **Cache is the UI's source of truth.** Screens watch drift streams. Network responses are written into drift, and the UI updates from the stream.
2. **Every mutation goes through the outbox**, even when online. There is one code path, so offline is never a special case.
3. **Client-generated UUIDv7 per operation, sent as `Idempotency-Key`.** A retry can never double-apply (CONTRACTS §6: `Idempotency-Key` accepted on all state-changing `POST`s).
4. **Server authoritative.** Local writes are optimistic overlays (`pending_status`) until the server confirms or contradicts them. HawaTag auto-done beats a manual mark.
5. **Honest freshness.** Every cached dataset shows its age when stale. The app never presents yesterday's route as today's.
6. The edge already does this: HawaTag and HawaPods store and forward for 72 h with sequence numbers (§10.5, §15). The app matches that stance, so a driver who sprays in a dead zone still gets the stop confirmed later.

## 2. What is cached, and for how long

Times are measured with server-corrected time (`core/network/server_clock.dart`).

| Data | Source | Stored in | Kept for | Stale after | Prefetch |
|---|---|---|---|---|---|
| Today's route, stops, asset + HawaTag status (driver) | `GET /v1/tasks/mine?date=` | `routes`, `tasks`, `stops` | today + previous 6 days (for summaries) | 10 min during shift, 60 min otherwise | on `route_assignment`/`route_changed` push, app resume, 05:25 IST workmanager job |
| Map tiles for the route corridor | tile provider | `tiles/` file store | 30 days, LRU | n/a | corridor z15–z16 + bbox z12–z14, ≤ 400 tiles ([ARCHITECTURE §12.4](ARCHITECTURE.md)) |
| Inspection targets | `GET /v1/tasks/mine` (kind `inspect`) ∪ `GET /v1/inspections?status=assigned` (report-origin inspections may have no task) | `tasks` (kind `inspect`, keyed by inspection id) | until closed + 24 h | 10 min | on `inspection_target` push |
| Inspection evidence bundle + thumbnails | proposed `GET /v1/inspections/{id}` | `cached_payloads` + `media_files` (thumbs) | until closed + 24 h | 30 min (and before the signed URL `expires_at`) | on first list render when on Wi-Fi or data saver is off |
| Latest safe windows (today, tomorrow) | `GET /v1/schools/{id}/safe-window?date=` | `safe_windows` | 2 days | once the next scheduled issuance (19:00, 22:00 IST) has passed | on `safe_window` push |
| Indoor/outdoor series | `GET /v1/schools/{id}/indoor-outdoor` | `cached_payloads` | last 6 h | 15 min | school home open |
| School forecast | `GET /v1/forecast/{cell_id}` | `cached_payloads` | latest issue | 75 min (mirrors the API cache TTL, CONTRACTS §9) | school home open |
| Alert inbox | `GET /v1/alerts` + WS `alerts:me` + push | `alerts` | 30 days or 200 newest | 30 min | on any push |
| Air near me | `GET /open/v1/air?bbox=` (snapped bbox) | `cached_payloads` | 6 h | 30 min (twin rebuilds every 15 min) | citizen home open |
| My reports + status | `GET /v1/reports/mine`, `GET /v1/reports/{id}` | `reports_draft` + `cached_payloads` | 90 days (status only after closed) | 15 min while not closed | on `report_outcome` push |
| Site score | `GET /v1/sites/me` | `cached_payloads` | 7 days | 24 h | site home open |
| Profile / roles | `GET /v1/me` | secure storage + prefs | until logout | refreshed on every cold start when online | |

## 3. Drift schema sketch

Tables named in the brief plus four support tables. Column types are drift types, and timestamps are stored as UTC.

```dart
// core/storage/tables/*.dart (sketch)
class Routes extends Table {
  TextColumn get routeId => text()();
  TextColumn get serviceDate => text()();               // YYYY-MM-DD (IST)
  TextColumn get assetJson => text()();                 // asset + tag status snapshot
  TextColumn get geometryJson => text().nullable()();   // GeoJSON LineString
  TextColumn get bboxJson => text().nullable()();
  IntColumn get version => integer()();                 // route.version from server
  BoolColumn get isSimulated => boolean()();
  DateTimeColumn get fetchedAt => dateTime()();
  @override
  Set<Column> get primaryKey => {routeId};
}

class Tasks extends Table {
  TextColumn get id => text()();                        // server UUIDv7
  TextColumn get routeId => text().nullable()();
  TextColumn get kind => text()();                      // TaskKind wire value
  TextColumn get status => text()();                    // TaskStatus (server)
  TextColumn get pendingStatus => text().nullable()();  // optimistic overlay from an unsent op
  TextColumn get completionSource => text().nullable()(); // InterventionSource
  TextColumn get serviceDate => text()();
  DateTimeColumn get windowStart => dateTime()();
  DateTimeColumn get windowEnd => dateTime()();
  RealColumn get lat => real()();
  RealColumn get lon => real()();
  TextColumn get payloadJson => text()();               // full entity JSON for detail screens
  IntColumn get serverVersion => integer()();           // task.version
  DateTimeColumn get serverUpdatedAt => dateTime()();
  BoolColumn get isSimulated => boolean()();
  @override
  Set<Column> get primaryKey => {id};
}

class Stops extends Table {
  TextColumn get routeId => text().references(Routes, #routeId)();
  IntColumn get sequence => integer()();
  TextColumn get taskId => text().references(Tasks, #id)();
  @override
  Set<Column> get primaryKey => {routeId, sequence};
}

class Alerts extends Table {
  TextColumn get id => text()();
  TextColumn get kind => text()();                      // AlertKind
  TextColumn get title => text()();
  TextColumn get body => text()();
  TextColumn get lang => text()();
  TextColumn get deepLink => text().nullable()();
  DateTimeColumn get receivedAt => dateTime()();
  DateTimeColumn get readAt => dateTime().nullable()();
  DateTimeColumn get ackedAt => dateTime().nullable()();
  DateTimeColumn get expiresAt => dateTime().nullable()();
  BoolColumn get isSimulated => boolean()();
  TextColumn get payloadJson => text()();
  @override
  Set<Column> get primaryKey => {id};
}

class ReportsDraft extends Table {
  TextColumn get clientReportId => text()();            // UUIDv7, also sent to the server
  TextColumn get mediaIdsJson => text()();              // media_files ids
  RealColumn get lat => real()();
  RealColumn get lon => real()();
  RealColumn get accuracyM => real()();
  TextColumn get locationQuality => text()();           // precise | coarse
  DateTimeColumn get capturedAt => dateTime()();
  TextColumn get category => text()();                  // ReportCategory (proposed)
  TextColumn get note => text().nullable()();
  TextColumn get state => text()();                     // draft | queued | submitted
  TextColumn get serverReportId => text().nullable()();
  TextColumn get lastStatus => text().nullable()();     // ReportStatus
  DateTimeColumn get lastStatusAt => dateTime().nullable()();
  @override
  Set<Column> get primaryKey => {clientReportId};
}

class OutboxOps extends Table {
  TextColumn get id => text()();                        // UUIDv7 = Idempotency-Key
  TextColumn get userId => text()();                    // owner; ops never cross users
  TextColumn get kind => text()();                      // OpKind (§5.1)
  TextColumn get orderingKey => text()();               // e.g. task:<id>
  TextColumn get dependsOn => text().nullable()();      // op id that must be done first
  TextColumn get coalesceKey => text().nullable()();    // latest-wins ops (push_token, profile)
  IntColumn get priority => integer()();                // 1 highest
  TextColumn get payloadJson => text()();               // immutable once enqueued
  TextColumn get state => text()();                     // pending | in_flight | done | failed | superseded
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextAttemptAt => dateTime()();
  DateTimeColumn get expiresAt => dateTime().nullable()();
  TextColumn get lastErrorCode => text().nullable()();
  IntColumn get lastHttpStatus => integer().nullable()();
  TextColumn get resultJson => text().nullable()();     // e.g. server shift id, object_key
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get clientTs => dateTime()();          // when the user acted
  @override
  Set<Column> get primaryKey => {id};
}

class SyncState extends Table {
  TextColumn get scope => text()();                     // tasks:2026-11-13 | alerts | safe_window:SCH-…:2026-11-13 | outbox_drain
  DateTimeColumn get lastSuccessAt => dateTime().nullable()();
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();
  TextColumn get lastErrorCode => text().nullable()();
  TextColumn get etag => text().nullable()();           // If-None-Match (proposed ETag support)
  TextColumn get cursor => text().nullable()();
  BoolColumn get dirty => boolean().withDefault(const Constant(false))();
  TextColumn get leaseOwner => text().nullable()();     // isolate id holding the drain lease
  DateTimeColumn get leaseUntil => dateTime().nullable()();
  @override
  Set<Column> get primaryKey => {scope};
}
```

Support tables:

| Table | Key columns | Purpose |
|---|---|---|
| `media_files` | `id`, `path`, `sha256`, `bytes`, `purpose` (`UploadPurpose`), `object_key?`, `state` (`local`/`uploaded`/`missing`), `thumb_path?` | Photos awaiting or after upload |
| `location_pings` | `id`, `shift_local_id`, `ts`, `lat`, `lon`, `accuracy_m`, `speed`, `batched` | Shift-only positions for `location_batch` |
| `safe_windows` | `school_id`, `date`, `payload_json`, `issued_at`, `is_simulated` | F19 cache |
| `cached_payloads` | `key`, `payload_json`, `fetched_at`, `expires_at`, `is_simulated` | Generic JSON cache (inspection bundles, air, forecast, site) |

Indexes: `tasks(service_date, kind)`, `outbox_ops(state, next_attempt_at)`, `outbox_ops(ordering_key, created_at)`, `alerts(received_at DESC)`.

The DB opens with `NativeDatabase.createInBackground(file, setup: (db) { db.execute('PRAGMA journal_mode=WAL'); db.execute('PRAGMA busy_timeout=5000'); })`. The FCM background handler and the workmanager callback open their own connections to the same file, and WAL + busy timeout make that safe. Migrations use drift's `MigrationStrategy` with committed schema dumps and generated migration tests ([LINTING_AND_QUALITY §10](LINTING_AND_QUALITY.md#10-testing-strategy)).

## 4. Read path (stale-while-revalidate)

```text
screen watches drift stream ──► renders cache immediately (with stale/offline banner if needed)
        │
controller.build() ─► repository.refresh(scope)
        │                 ├─ skip if a refresh for scope is in flight (single-flight per scope)
        │                 ├─ GET with If-None-Match: sync_state.etag (if server supports ETag)
        │                 ├─ 304 → touch sync_state.lastSuccessAt
        │                 ├─ 200 → transaction { upsert rows (server wins), re-apply pending overlays,
        │                 │                      delete rows absent from a full snapshot, update sync_state }
        │                 └─ Failure → sync_state.lastErrorCode; the UI shows an error banner over the cache
        └─ drift stream emits → screen re-renders
```

A full snapshot (like `tasks/mine` for a date) replaces the set for that scope. Rows that are missing from the snapshot but have pending outbox ops are kept. Those ops will resolve as `superseded` (§7).

Exception: the backend returns driver/inspector tasks only during the shift ± 2 h (backend ARCHITECTURE §6). An **empty** `tasks/mine` response after the shift window is therefore not treated as "all stops removed". The cached day stays, read-only, for the shift summary and the "verified later" results until it's purged after 7 days.

## 5. Outbox pattern

### 5.1 Operation kinds

| `OpKind` | Endpoint | `ordering_key` | `depends_on` | Coalescing | Expires | Priority |
|---|---|---|---|---|---|---|
| `task_ack` | `POST /v1/tasks/{id}/ack` | `task:{id}` | none | one per task (dedupe on enqueue) | never | 1 |
| `task_status` | `POST /v1/tasks/{id}/status` `{status, source?, reason?, note?, litres?, s3_keys?, client_ts, location?}`. Driver: `en_route`, `done` (`source=manual`), `skipped`. Inspector: `en_route`, `in_progress` | `task:{id}` | `photo_upload` (manual done with photo) | none | `en_route`/`in_progress`: 12 h. `done`/`skipped`: never | 1 |
| `inspection_close` | `POST /v1/inspections/{id}/close` `{outcome, notes, evidence_keys[], closed_at, location}` | `inspection:{id}` | every `photo_upload` for it | none | never | 2 |
| `photo_upload` | `POST /v1/uploads/presign` then S3 presigned **POST** (multipart form) | `media:{media_id}` | none | none | never (until uploaded or media missing) | 3 |
| `report_submit` | `POST /v1/reports` `{client_report_id, s3_key, lat, lon, location_accuracy_m, captured_at, category, note?}` | `report:{client_report_id}` | its `photo_upload` | none | never | 2 |
| `alert_ack` | `POST /v1/alerts/{id}/ack` (proposed) | `alert:{id}` | none | one per alert | 7 days | 1 |
| `shift_start` | `POST /v1/shifts/{shift_id}/start` (proposed; `asset_shift` id from `tasks/mine.shift.id`) | `shift:{shift_id}` | none | none | 24 h | 1 |
| `shift_end` | `POST /v1/shifts/{shift_id}/end` (proposed) | `shift:{shift_id}` | none (head-of-line after `shift_start` on the same key) | none | 24 h | 1 |
| `location_batch` | `POST /v1/shifts/{shift_id}/locations` (proposed). Only for inspection-team shifts or while the HawaTag is offline ([ARCHITECTURE §11.3](ARCHITECTURE.md#113-geofence-and-upload)) | `loc:{shift_id}` | `shift_start` | none (append batches) | 6 h (then dropped) | 4 |
| `push_token` | `PUT /v1/me/push-token` | `profile:push` | none | latest wins (`coalesce_key`) | never | 1 |
| `profile_update` | `PATCH /v1/me` (proposed), `PUT /v1/me/alert-subscription` (proposed) | `profile:{field}` | none | latest wins | never | 4 |

Enqueueing happens in the **same drift transaction** as the optimistic change (for example `tasks.pending_status = 'skipped'` + insert op), so the UI and the queue can never disagree. After commit, the repository calls `drainer.kick()`.

### 5.2 Ordering and dependencies

An op is **ready** when all of these hold:
- `state = pending` and `next_attempt_at ≤ now`
- `expires_at` is null or in the future (otherwise it becomes `superseded` with reason `expired`)
- `depends_on` is null or points to an op in state `done` (a dependency `failed` → this op `failed` with `dependency_failed`; a dependency `superseded` → this op `superseded`)
- no **earlier** op with the same `ordering_key` is `pending` or `in_flight` (head-of-line per key)

Ops with different ordering keys run concurrently, up to 3 in flight, and at most 1 `photo_upload` at a time on mobile data. Ready ops are picked by `priority`, then `created_at`, so small status updates reach the server before large photos on a thin connection. A `failed` op (permanent) does not block later ops on its key. It's surfaced in `/settings/sync`.

### 5.3 Idempotency

- `op.id` (UUIDv7) is the `Idempotency-Key`. It's the same on every attempt, while `X-Request-Id` is new per attempt.
- Payloads are immutable once enqueued. Editing a queued item (for example changing a report note before it is sent) supersedes the old op and enqueues a new one with a new id. A key is never reused with a different body.
- Creates also carry a natural key (`client_report_id`, and for evidence the op id itself), so the server can dedupe even after its idempotency store has expired.
- **Backend today** (backend CACHING §9): records live in `idem:{user_id}:{key}` for **24 h**.
  - A replay returns the stored response.
  - A replay while the first request is still processing returns `409 idempotency_in_progress` with `Retry-After: 1`, which the app retries.
  - The same key with a different body returns `422 idempotency_key_mismatch`, which the app treats as a bug and marks `failed`.
- **Gap.** An outbox op can wait longer than 24 h, since the edge store-and-forward window is 72 h (§10.5). After 24 h, safety rests on domain idempotency:
  - task transitions are state-checked server-side, and a repeated transition returns `already_in_state`/`transition_already_past`
  - reports carry `client_report_id`, which needs a proposed **unique** column
  - inspection close is state-checked

  **Proposal:** raise idempotency retention to ≥ 72 h, or add the `client_report_id` unique key. Listed in [PLAN §11](PLAN.md#11-contract-proposals-to-raise).

### 5.4 Retry and backoff

```dart
// core/sync/backoff.dart (sketch): full jitter
Duration nextDelay(int attempts, {Duration? retryAfter, Random? rng}) {
  const base = Duration(seconds: 2);
  const cap = Duration(minutes: 15);
  final exp = base * pow(2, min(attempts, 10)).toInt();
  final ceiling = exp > cap ? cap : exp;
  final jittered = Duration(milliseconds: (rng ?? Random()).nextInt(ceiling.inMilliseconds + 1));
  return retryAfter != null && retryAfter > jittered ? retryAfter : jittered;
}
```

- While connectivity is `none`, attempts are not consumed. The drainer sleeps until a trigger (§8).
- Transient failures retry until `expires_at` (there's no max attempts). The sync chip shows "Retrying".
- `ops.in_flight` rows found at startup (the app was killed mid-request) reset to `pending`. Replaying with the same key is safe by design.

### 5.5 Result classification

| Response | Result | Effect |
|---|---|---|
| `2xx` | `done` | Store `result_json` (shift id, object key). Clear the `pending_status` overlay once the server state arrives |
| `409` `idempotency_in_progress` | retry after `Retry-After` (1 s) | The first attempt is still being processed server-side (backend CACHING §9) |
| `422` `idempotency_key_mismatch` | `failed` | App bug (payloads are immutable). Non-fatal report |
| `409` `code ∈ {already_in_state, transition_already_past}` | `done` | No banner: the server is already there or beyond |
| `409` `task_already_done` (e.g. HawaTag completed it) | `superseded` | Banner via `conflict_banner_bus` (§7) |
| `409` `task_cancelled`, `410` | `superseded` | Banner "The control room removed this stop from your route" |
| `404` | `superseded` | Silent for alerts. Banner for tasks |
| `400`, `422` | `failed` | Non-fatal to Crashlytics with `code`. Shown in `/settings/sync` |
| `401` | pause | The refresh interceptor handles it. If the session expired, the drainer pauses until the same user logs in again |
| `403` | `failed` | Role or scope changed. Triggers a `/v1/me` refresh |
| `413` (photo) | retry once after re-compressing at 1280 px q70, then `failed` | |
| `408`, `429`, `5xx`, network, timeout | retry | `nextDelay()`, honouring `Retry-After` |

The problem+json `code` values above are **proposed** for API.md, so the app can branch on codes and never on message text.

### 5.6 Where the drainer runs

| Context | How | Notes |
|---|---|---|
| Foreground | Riverpod keep-alive `OutboxDrainer`, kicked by triggers | Shows progress in the sync chip |
| Shift active (Android) | The foreground service keeps the process alive, so the same drainer keeps running in the background. A periodic 60 s tick | Main isolate |
| Background (Android) | `workmanager` periodic task every 15 min (Android minimum) with `NetworkType.connected`, plus one-off tasks scheduled from the FCM background handler | Top-level `callbackDispatcher` builds a minimal container (DB, Dio, hawa_api, executors). Same drainer code |
| iOS | Resume + push-triggered fetch. Background refresh via workmanager is opportunistic | Secondary platform |

Exactly one drainer runs at a time. It holds a lease: row `sync_state(scope='outbox_drain')`, `lease_owner` = isolate id, `lease_until` = now + 2 min, renewed per op. It's acquired with a conditional `UPDATE … WHERE lease_until IS NULL OR lease_until < now`.

## 6. Photo pipeline (presign first)

```text
capture (camera) ─► process: resize + JPEG re-encode, keepExif=false, sha256
   ─► media_files(state=local) + outbox photo_upload (+ dependent report_submit / inspection_close / task_status)
   ─► drainer: POST /v1/uploads/presign {purpose, content_type: image/jpeg, content_length, sha256}
             ─► presigned POST (bare Dio, multipart/form-data: policy fields first, then file; progress)
                 ├─ 204/201 → media_files.object_key = returned key, state=uploaded → op done
                 ├─ 403 policy expired (5 min) → re-presign once, retry
                 └─ network → backoff
   ─► dependent op executes: reads object keys from media_files at execution time (payload stores media ids)
```

- Presign is requested **at upload time, not enqueue time**. The policy expires after 5 min (backend ARCHITECTURE §7), so it must never sit in the queue.
- The payload stores media **ids**, not object keys, because keys only exist after upload.
- If the file is missing (user cleared app storage), `media_files.state = missing` and the op fails with `media_missing`. The UI asks the citizen to retake, or lets the driver send manual done without the photo.
- Local full-size files are deleted 24 h after the dependent op is `done`. A 320 px thumbnail is kept for "My reports".
- Sizes: ~150–400 KB per photo, well under the 8 MB policy cap. Restarting a single POST is cheap at that size, so no resumable upload is needed.

## 7. Conflict resolution

The server is authoritative for task, inspection, report and alert state. Completion-source precedence (server and app agree): **`hawatag` > `gps_inferred` > `manual`**.

| Case | Detection | Resolution | User sees |
|---|---|---|---|
| Manual done queued offline, then HawaTag auto-done arrives first | WS/fetch shows `done` + `completion_source=hawatag` while the op is pending | Op → `superseded` (not sent) | "HawaTag already confirmed this stop. Your manual entry wasn't needed." |
| Manual done reached the server, HawaTag data arrives later (store-and-forward) | server event `task.done` with source `hawatag` | Server upgrades the source. App upserts | Stop shows "Done by HawaTag". No banner |
| Skip queued, server says done by HawaTag | 409 `task_already_done` | `superseded` | "This stop was completed by HawaTag. Skip not needed." |
| Status for a stop removed by re-plan | 409 `task_cancelled` / 410, or a snapshot without the task | `superseded` | "The control room removed this stop from your route." + route diff banner |
| `en_route`/`in_progress` behind server state | 409 `transition_already_past` | `done` | nothing |
| Inspector outcome recorded offline, case closed by someone else meanwhile | 409 `inspection_already_closed` | Proposed: the server **attaches** the late evidence and returns `200 {applied: false}` so field work isn't lost. The app marks `done` | "This case was already closed. Your photos and notes were attached." |
| Alert ack for an expired or deleted alert | 404 | `superseded` silently | nothing |
| Report retried after the server already created it | 200/201 with the existing report (same `client_report_id`) | `done` | normal "Sent" |
| Route version changed while offline | `route.version` > cached | Replace stops. Pending ops on removed tasks resolve as above | Route-changed banner with added/removed counts |

Display rule: `pending_status` is shown (with a small clock icon) only while its op is `pending`/`in_flight` **and** the server `status` isn't terminal. When the server reports a terminal status, the overlay clears.

## 8. Sync triggers

| Trigger | Detected by | Action |
|---|---|---|
| Connectivity regained | `connectivity_plus` stream, `none` → `wifi`/`mobile`, debounced 3 s | Kick drainer + refresh dirty/stale scopes. The first real request is the internet test, since connectivity doesn't guarantee internet |
| App resume | `AppLifecycleState.resumed` | Kick drainer, refresh the active role's scopes, connect WS |
| Push received | FCM foreground: refresh that entity's scope now. Background handler: set `sync_state.dirty`, schedule a one-off workmanager task | |
| WS (re)connected | `ws_client` | Gap-fill refresh of `tasks:*` and `alerts` |
| Local enqueue | `OutboxRepository.enqueue` | `drainer.kick()` |
| Periodic | foreground: 60 s during shift, 5 min otherwise. Background: workmanager 15 min | Drain + refresh stale scopes |
| Service date rollover | timer at 00:00 IST | Refetch route for the new date. Keep yesterday for summaries |
| Pre-dispatch warm-up | workmanager one-off at 05:25 IST for drivers (best effort) | Refresh token + prefetch route if already dispatched |
| Manual | pull-to-refresh, **Retry now** in `/settings/sync` | Immediate drain/refresh, bypassing backoff for that op |

## 9. Stale-data indicator

- Each scope's age is `serverNow − sync_state.lastSuccessAt`. Thresholds are the "Stale after" column in §2 (`core/sync/stale_policy.dart`).
- Banner selection (one at a time, most important first):
  1. **Offline** (connectivity `none` or the last request failed with `NetworkFailure`): "Offline: showing saved data from 07:42 / ऑफ़लाइन: 07:42 का सेव किया डेटा".
  2. **Stale** (online but older than threshold, e.g. the refresh failed with 5xx): amber "Last updated 07:42 / आखिरी अपडेट 07:42". Tapping it retries.
  3. **Error** with no cache: `ErrorView`.
- Hard limits: a route whose `service_date` is not today (IST) is never shown as "Today's route". The screen says "No route for today yet" and offers yesterday's summary. Safe windows for a past date are hidden.
- The sync chip in the app bar shows the outbox depth (for example "2") and opens `/settings/sync`. It's hidden when the queue is empty.

## 10. Storage limits, cleanup and logout

| Store | Limit | Cleanup |
|---|---|---|
| drift DB | soft cap 50 MB | tasks older than 7 days. Alerts beyond 30 days or 200 newest. `done`/`superseded` ops after 24 h. `failed` ops after 7 days. `cached_payloads` by `expires_at`. Location pings after upload or shift end + 6 h. Closed reports keep status only after 90 days |
| Media (`media/`) | 100 MB | Never auto-delete un-uploaded media. Warn at 80 MB with pending uploads. Delete full-size 24 h after upload |
| Tiles (`tiles/`) | 100 MB (40 MB with data saver) | LRU by mtime, 30-day max age |
| Device free space < 200 MB | none | Warn once, force data saver, skip tile prefetch |

Cleanup runs after the first frame on cold start (idle) and daily via workmanager.

**Logout** (`logout_controller.dart`):
1. If the outbox has pending ops: warn ([SCREENS X3](SCREENS.md#x3-settings-settings)) → **Send now** (drain with a 20 s budget) or **Log out anyway**.
2. Stop the shift tracker and close the WS.
3. Best-effort `POST /v1/auth/logout` (3 s timeout), then `FirebaseMessaging.deleteToken()`.
4. Delete the drift DB file, `media/`, secure storage and prefs, **except** language and the onboarding language flag. Tiles are kept (not personal).
5. Go to `/auth/phone`.

**Session expired** (refresh failed) is not a logout. Data and outbox are kept and the UI is locked at login. If a **different** user signs in (`user_id` mismatch), the wipe runs before any data loads. Ops never cross users.

## 11. Testing offline

### 11.1 Automated

| Level | What | Tools |
|---|---|---|
| Unit: backoff | Sequence bounds, jitter range, `Retry-After` override | `Random` seeded |
| Unit: drainer | Head-of-line per key, dependencies (done/failed/superseded propagation), priority, concurrency cap, lease acquisition/expiry, `in_flight` reset on start, expiry → superseded, pause on session expiry | in-memory drift, fake executors, `fake_async`, fake `Clock` |
| Unit: executors | Each §5.5 row, e.g. 409 `task_already_done` → superseded + banner event | `http_mock_adapter` on Dio |
| Unit: conflict resolver | Every §7 row | in-memory drift |
| Repository | Snapshot replace keeps rows with pending ops; overlays re-applied after refresh | in-memory drift + mocked remote |
| Staleness | Banner selection at threshold boundaries; IST date rollover at 00:00 | fake `Clock` |
| Integration | Offline outcome → reconnect → exactly one inspection close applied server-side. Citizen report offline → sync → status timeline. Flow B with injected 503s | `integration_test` + `tool/mock_server` failure injection |

Mock server controls (`tool/mock_server`):

```text
POST /__mock/fail?path=/v1/tasks/*/status&status=503&count=3   # next 3 matching calls fail
POST /__mock/latency?ms=4000                                     # slow network
POST /__mock/ws/drop                                             # close all WS connections
POST /__mock/emit {"channel":"tasks:me","type":"task.done",...}  # push a WS event
GET  /__mock/requests?path=/v1/tasks/*/evidence                  # assert idempotent single apply
```

### 11.2 Airplane-mode and network scripts (emulator and USB phone)

```bash
adb shell cmd connectivity airplane-mode enable     # recent Android images; toggles airplane mode
adb shell cmd connectivity airplane-mode disable
adb shell svc wifi disable && adb shell svc data disable   # data off without airplane mode
adb shell svc wifi enable && adb shell svc data enable
adb emu network speed gsm                           # emulator console: throttle bandwidth
adb emu network delay gprs                          # emulator console: add latency
adb emu geo fix 77.2095 28.6412                     # emulator location (longitude first) for geofence tests
```

### 11.3 Manual field checklist (real phone, before demo)

1. Start shift → airplane mode → skip stop 2 → mark stop 3 manually (tag offline fixture) → airplane off → both sync once, and `/settings/sync` is empty.
2. Record an inspector outcome with 2 photos in airplane mode → swipe-kill the app → reopen online → uploads resume, the inspection is closed exactly once.
3. Submit a Citizen Eyes report offline → reboot the phone → reopen → the report sends.
4. With pending ops, log out → warning appears → "Send now" drains.
5. Toggle data saver → a new photo is ≤ 1280 px and no tile prefetch happens on mobile data.

## 12. Failure matrix

| # | Scenario | Detection | App behaviour | User sees | Recovery |
|---|---|---|---|---|---|
| 1 | No data at 05:30, push not delivered | none on device | SMS fallback from notifier (proposed 10 min rule). On open: empty cache + retry | "No route today yet" + Retry | Refresh on connectivity regain |
| 2 | Network drops mid-shift | connectivity `none` / `NetworkFailure` | Ops queue. WS closed. Cached route stays usable | Offline banner, sync chip count | Drain + gap-fill on regain. HawaTag's 72 h store-and-forward confirms sprays later |
| 3 | HawaTag offline | `tag_status` offline/degraded, push `device_health` | Enable **Mark done manually** (`source=manual`) | Tag offline chip + manual button | Server upgrades to `hawatag` if the tag's buffered data arrives |
| 4 | App and HawaTag both offline | local: no connectivity; last-known tag status online | No manual button (last-known tag online). Explain buffering | "HawaTag saves data and will confirm when back online" | Reconciled when either reconnects |
| 5 | OEM battery killer kills the app mid-shift | on restart, persisted `shift.active` | Offer to resume tracking (never auto-starts location without the user) | "Your shift is still on. Resume location sharing?" | User taps Resume |
| 6 | Phone reboot mid-shift | same as 5 | same as 5. The outbox persisted in SQLite | same | same |
| 7 | Access token expired while offline | 401 on first call after regain | Single-flight refresh, replay | nothing | automatic |
| 8 | Refresh token expired/revoked | refresh 401 | Session expired, data + outbox kept | Login screen with "Please log in again" | Same user logs in → drain resumes |
| 9 | Presigned URL expired | S3 403 | Re-presign once | nothing | automatic |
| 10 | Photo file missing | `media_missing` | Op `failed` | "Photo was lost. Retake it?" (report) / "Send without photo" (manual done) | User action |
| 11 | Server 5xx storm | 5xx | Backoff with jitter, `Retry-After` | "Retrying" chip. Cached data | automatic |
| 12 | 409 conflict | problem `code` | §7 rules | Conflict banner where relevant | automatic |
| 13 | WS reconnect loop (proxy blocks upgrades) | 5 failed attempts in 2 min | Fall back to polling `tasks/mine` every 60 s during shift | nothing | Retry WS on next resume |
| 14 | FCM blocked on venue/depot Wi-Fi | no pushes; token OK | WS in foreground, poll on resume | nothing | SMS fallback. Carry a mobile hotspot for demos |
| 15 | Device clock wrong | skew from `Date` header > 2 min | Display and staleness use server time. `client_ts` still sent (server records `received_at`) | correct times | automatic |
| 16 | Low storage | free space < 200 MB | Force data saver, no prefetch | One-time warning | User frees space |
| 17 | Double tap on Send / Save | UI + same op | Button disabled after first tap. Natural key dedupe | One "Sent" | n/a |
| 18 | DB migration fails after app update | migration exception | Keep the old DB file, report non-fatal, block writes, never drop pending ops | "Update problem. Please contact support" | Hotfix release |
| 19 | Role removed server-side | 403 on ops / `/v1/me` roles changed | Ops `failed`. Role picker or unsupported screen | "Your access changed" | Admin fixes role |
| 20 | Route re-planned while offline | `route.version` bump on regain | Replace stops, supersede ops on removed tasks | Route-changed banner | automatic |
