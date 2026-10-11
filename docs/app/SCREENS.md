# Screens

<!-- nav:start -->

**Navigate:** [Project](../../README.md) · [Docs hub](../README.md) · [Overview](../SYSTEM_OVERVIEW.md) · [AWS architecture](../AWS_ARCHITECTURE.md) · [AWS setup](../AWS_SETUP_GUIDE.md) · [API](../backend/API.md) · [Environment](../ENVIRONMENT_VARIABLES.md) · [Contracts](../CONTRACTS.md)

**App docs:** [Runbook](../../app_frontend/README.md) · [Index](README.md) · [Context](CONTEXT.md) · [Architecture](ARCHITECTURE.md) · **Screens** · [Offline and sync](OFFLINE_AND_SYNC.md) · [Quality](LINTING_AND_QUALITY.md) · [Structure](STRUCTURE.md) · [Plan](PLAN.md)

<!-- nav:end -->

> **Status per screen.** Data sources for each screen:
> - **Live against the backend:** the citizen air map (`/v1/twin`, `/v1/hotspots`, `/v1/forecast`), air near me (`/v1/twin`, `/v1/hotspots`, `/v1/citizen/safe-window`), alerts (`/v1/alerts`) and the school 72 h forecast (`/v1/forecast/{cell_id}`).
> - **In-app fake backend and `assets/fixtures/`:** login, driver, inspector, school today and indoor/outdoor, Citizen Eyes reports, and the site score.
> - **Hard-coded demo data:** the citizen safe route, live operations, ward scorecard and missed-machine screens. The backend's `/v1/citizen/*` endpoints for these exist but are not called.
>
> Broken navigation: "Flag Missed Machine" and the citizen "72-Hour AI Air Forecast" tile ([docs/app/README.md](README.md#9-known-issues), issue 5). The en/hi copy below is the design copy; the shipped strings are in `app_frontend/lib/app/l10n/arb/app_en.arb` and `app_hi.arb`.


Purpose: a screen-by-screen spec for every role. Each screen lists its route, data, wireframe, widgets, interactions, states, en/hi copy and acceptance criteria. The push notification catalogue is in §9.

Related: [README](README.md) · [CONTEXT](CONTEXT.md) · [ARCHITECTURE](ARCHITECTURE.md) · [STRUCTURE](STRUCTURE.md) · [OFFLINE_AND_SYNC](OFFLINE_AND_SYNC.md) · [../CONTRACTS.md](../CONTRACTS.md) · [../SYSTEM_OVERVIEW.md](../SYSTEM_OVERVIEW.md) · [../backend/API.md](../backend/API.md) · [../frontend/DESIGN_SYSTEM.md](../frontend/DESIGN_SYSTEM.md)

---

## 0. Conventions

### 0.1 Standard states (apply to every data screen unless the screen says otherwise)

| State | Rule | Widget |
|---|---|---|
| Loading | With cache: render the cache + a thin top progress bar. Without cache: skeleton blocks (no shimmer, cheap on low-end GPUs) | `LoadingSkeleton` |
| Empty | Icon + one sentence + optional action. Never a blank screen | `EmptyState` |
| Offline | Blue-grey banner "Offline: showing saved data from 07:42". Actions stay enabled and queue into the outbox | `OfflineBanner` |
| Stale | Amber banner "Last updated 07:42" when older than the scope's threshold ([OFFLINE_AND_SYNC §9](OFFLINE_AND_SYNC.md#9-stale-data-indicator)) | `StaleBanner` |
| Error | With cache: error banner over the data + **Retry**. Without cache: `ErrorView` (message + Retry + Details with request id) | `ErrorView` |
| Simulated | Top chip "Includes simulated data" + a purple **Simulated** badge (flask icon + word) on each simulated item | `SimulatedScreenChip`, `SimulatedBadge` |

### 0.2 Copy rules

- Every string is in ARB (en + hi). The tables below give the key strings. Placeholders use `{name}`.
- Times: IST, en "6:30 AM", hi "सुबह 6:30" ([ARCHITECTURE §14](ARCHITECTURE.md#14-internationalisation-en--hi)).
- AQI always carries "indicative / सांकेतिक". Model outputs always carry range or confidence.
- Wireframes are 40 columns wide. `[ BUTTON ]` is a primary action, `( )` a status icon, `<Simulated>` the badge.

### 0.3 Role shells

| Shell | Tabs | App bar actions |
|---|---|---|
| Driver | Route · Map · More | outdoor-mode toggle, sync chip, alerts bell |
| Inspector | Targets · Map · More | outdoor-mode toggle, sync chip, alerts bell |
| School | Today · Air · Alerts · More | language toggle, sync chip |
| Citizen | Air · Report · My reports · More | sync chip, alerts bell |
| Site | Site · More | none |

"More" opens a sheet: Profile, Settings, Pending uploads, Switch role (if more than one role), Log out.

---

## 1. Onboarding and auth

### A1 Splash (`/splash`, all)

Purpose: bootstrap (Firebase, DB, prefs, session restore), then redirect. It shows the logo and nothing else. If the session is cached and valid, it goes to the role home **without network**. Acceptance: cold start to redirect in ≤ 1.5 s on the reference device, and it never blocks on the network.

### A2 Language (`/onboarding/language`, all, first run)

```text
+----------------------------------------+
|              HawaCommand               |
|                                        |
|   Choose your language                 |
|   अपनी भाषा चुनें                        |
|                                        |
|   [            हिन्दी             ]     |
|   [            English            ]     |
|                                        |
|   You can change this later            |
+----------------------------------------+
```

| Key | en | hi |
|---|---|---|
| title | Choose your language | अपनी भाषा चुनें |
| hint | You can change this later in Settings | इसे बाद में सेटिंग्स में बदल सकते हैं |

Interactions: tap a language to set the locale immediately and go to `/auth/phone`. The title is shown in both scripts at once. Each button is labelled in its own script. Acceptance: the choice persists across restarts and is sent via `PATCH /v1/me {lang}` (proposed) after login.

### A3 Phone (`/auth/phone`, signed out)

Data: `POST /v1/auth/otp/request {phone_e164, channel: "sms", lang}` → `{request_id, expires_in, resend_after}`.

```text
+----------------------------------------+
|  Enter your mobile number              |
|  +------+----------------------------+ |
|  | +91  | 98xxx xxxxx                | |
|  +------+----------------------------+ |
|  We'll send a 6-digit code by SMS      |
|                                        |
|  [            SEND CODE             ]  |
|                                        |
|  Your number is never shown to other   |
|  users.                                |
+----------------------------------------+
```

| Key | en | hi |
|---|---|---|
| title | Enter your mobile number | अपना मोबाइल नंबर डालें |
| helper | We'll send a 6-digit code by SMS | हम SMS से 6 अंकों का कोड भेजेंगे |
| send | Send code | कोड भेजें |
| invalid | Enter a 10-digit mobile number | 10 अंकों का मोबाइल नंबर डालें |
| rateLimited | Too many tries. Try again in {minutes} min | बहुत बार कोशिश हुई। {minutes} मिनट बाद फिर कोशिश करें |
| offline | No internet. Connect to get your code | इंटरनेट नहीं है। कोड पाने के लिए इंटरनेट चालू करें |
| privacy | Your number is never shown to other users | आपका नंबर किसी और उपयोगकर्ता को कभी नहीं दिखाया जाता |

States: offline disables Send with the `offline` message (OTP is online-only). `RateLimitedFailure` shows the `rateLimited` message using `Retry-After`. Acceptance: accepts only 10 digits starting 6–9. The numeric keypad opens automatically. One tap sends.

### A4 OTP (`/auth/otp`, signed out)

Data: `POST /v1/auth/otp/verify {phone_e164, request_id, code, install_id}` → tokens + user. Then `GET /v1/me` and `PUT /v1/me/push-token`.

```text
+----------------------------------------+
|  < Change number                       |
|  Enter the code sent to +91 98•••••210 |
|   +--+ +--+ +--+ +--+ +--+ +--+        |
|   |4 | |8 | |1 | |  | |  | |  |        |
|   +--+ +--+ +--+ +--+ +--+ +--+        |
|  Resend code in 24 s                   |
|  [             VERIFY               ]  |
+----------------------------------------+
```

| Key | en | hi |
|---|---|---|
| title | Enter the code sent to {phone} | {phone} पर भेजा गया कोड डालें |
| resendIn | Resend code in {seconds} s | {seconds} सेकंड में कोड दोबारा भेजें |
| resend | Resend code | कोड दोबारा भेजें |
| wrong | Wrong code. {left} tries left | कोड गलत है। {left} कोशिश बाकी |
| expired | Code expired. Request a new one | कोड की समय-सीमा खत्म। नया कोड मँगाएँ |
| verify | Verify | पुष्टि करें |

Interactions:
- The Android SMS User Consent prompt fills the code, and it auto-submits on the 6th digit.
- Paste is supported.
- Error codes the app branches on (proposed problem+json `code`s): `otp_invalid`, `otp_expired`, `otp_rate_limited`.

Acceptance:
- In fake mode, `123456` logs in.
- Tokens land in secure storage.
- A single-role user lands on the role home. A multi-role user lands on A5.
- If the user arrived via a deep link, they are taken to that link after login.

### A5 Role picker (`/auth/role`, signed in with more than one app role)

Data: `roles[]` from `GET /v1/me`. Web-only roles are filtered out.

```text
+----------------------------------------+
|  How will you use HawaCommand today?   |
|  [ (truck)  Driver / field team     ]  |
|  [ (search) Inspector               ]  |
|  [ (person) Citizen                 ]  |
|  You can switch later from More        |
+----------------------------------------+
```

| Key | en | hi |
|---|---|---|
| title | How will you use HawaCommand today? | आज आप HawaCommand का उपयोग किस रूप में करेंगे? |
| driver | Driver / field team | ड्राइवर / फ़ील्ड टीम |
| inspector | Inspector | निरीक्षक |
| school | School principal | स्कूल प्रधानाचार्य |
| citizen | Citizen | नागरिक |
| siteManager | Site manager | साइट प्रबंधक |
| hint | You can switch later from More | बाद में "और" से बदल सकते हैं |

Acceptance: the last-used role is preselected and stored in prefs. Switching role later tears down the previous shell's WS subscriptions and stops a running shift only after the user confirms.

### A6 Unsupported role (`/unsupported-role`)

Copy: "This app is for field teams, schools and citizens. Officers, please use the web console." / "यह ऐप फ़ील्ड टीम, स्कूल और नागरिकों के लिए है। अधिकारी कृपया वेब कंसोल का उपयोग करें।" + **Log out**.

---

## 2. Permission education

One screen template, `/onboarding/permissions/:kind`, shown **before** each system dialog. It's shown once per kind, and again from the feature entry point if the permission is denied.

| Kind | Shown to | When |
|---|---|---|
| `notifications` | all roles | right after the first role selection |
| `location` | driver, inspector | before the first **Start shift** |
| `location` | citizen | before the first "air near me" or report |
| `camera` | citizen, inspector | at the first photo capture (just in time) |

```text
+----------------------------------------+
|           [ illustration ]             |
|  Location only during your shift       |
|  We use your location only between     |
|  Start shift and End shift ...         |
|  Tip: choose "While using the app"     |
|  [            CONTINUE              ]  |
|             Not now                    |
+----------------------------------------+
```

| Key | en | hi |
|---|---|---|
| notif.title | Get your route and air alerts | अपना रूट और हवा की चेतावनी पाएँ |
| notif.body.driver | Your route arrives at 5:30 AM. We'll also tell you when a stop is done automatically. | आपका रूट सुबह 5:30 बजे आता है। स्टॉप अपने-आप पूरा होने पर भी हम बताएँगे। |
| notif.body.school | We'll warn you the evening before bad air, with a safe time for outdoor activities. | हवा खराब होने से एक शाम पहले हम चेतावनी देंगे, बाहर की गतिविधियों के सुरक्षित समय के साथ। |
| notif.body.citizen | Get warnings for your area and updates on your reports. | अपने इलाके की चेतावनी और अपनी रिपोर्ट की जानकारी पाएँ। |
| notif.fallback | If notifications are off, we'll send your route by SMS. | सूचनाएँ बंद होने पर हम आपका रूट SMS से भेजेंगे। |
| loc.title | Location only during your shift | लोकेशन सिर्फ़ आपकी शिफ्ट के दौरान |
| loc.body.field | We use your location only between Start shift and End shift, to show your position on the route and confirm arrival at stops. You'll always see a notification while it's on. | हम आपकी लोकेशन सिर्फ़ "शिफ्ट शुरू करें" और "शिफ्ट खत्म करें" के बीच इस्तेमाल करते हैं, ताकि रूट पर आपकी जगह दिखे और स्टॉप पर पहुँचने की पुष्टि हो। चालू रहने पर हमेशा एक सूचना दिखेगी। |
| loc.body.citizen | We use your approximate location to show the air near you, and your exact location only when you send a report. | आपके पास की हवा दिखाने के लिए हम अनुमानित लोकेशन लेते हैं, और सटीक लोकेशन सिर्फ़ तब जब आप रिपोर्ट भेजते हैं। |
| loc.tip | Tip: choose "While using the app" | सुझाव: "ऐप इस्तेमाल करते समय" चुनें |
| cam.title | Take a photo as evidence | सबूत के लिए फ़ोटो लें |
| cam.body | Photograph the fire or smoke, not people or number plates. We remove hidden photo data before sending and never show your number. | आग या धुएँ की फ़ोटो लें, लोगों या नंबर प्लेट की नहीं। भेजने से पहले हम फ़ोटो की छिपी जानकारी हटा देते हैं और आपका नंबर कभी नहीं दिखाते। |
| continue / notNow | Continue / Not now | आगे बढ़ें / अभी नहीं |
| deniedForever | This is off in phone Settings. Turn it on to continue. | यह फ़ोन की सेटिंग्स में बंद है। आगे बढ़ने के लिए चालू करें। |
| openSettings | Open Settings | सेटिंग्स खोलें |

Acceptance:
- The system dialog never appears without this screen first.
- "Not now" never blocks the whole app. It only blocks the dependent action:
  - Start shift needs location.
  - A report needs camera + location.
- A permanently denied permission shows **Open Settings**.
- No background-location dialog ever appears.

---

## 3. Driver (BUILD, Flow B)

### D1 Today's route (`/driver`)

| | |
|---|---|
| Purpose | Show today's ordered stops, the next stop, and shift control. The driver needs "a clear route and nothing else" (§7) |
| Data | `GET /v1/tasks/mine?date=` (cache first). WS `tasks:me`. Push `route_assignment`, `route_changed`, `task_done_auto`, `device_health`. Outbox `task_ack` (auto on first open), `shift_start`/`shift_end` |

```text
+----------------------------------------+
| Today, Thu 13 Nov   [Sun] [Sync 2] [!] |
| <Includes simulated data>              |
|----------------------------------------|
| SHIFT OFF             [ START SHIFT ]  |
|----------------------------------------|
| NEXT STOP  1 of 6          <Simulated> |
| Ajmal Khan Rd, Karol Bagh              |
| Arrive 6:10 - 6:40 AM                  |
| (drop) Spray about 600 L along 800 m   |
| HawaTag online, seen 1 min ago         |
| [    NAVIGATE  (Google Maps)       ]   |
|----------------------------------------|
| 2  Pusa Rd            6:45-7:15   ( )  |
| 3  Shankar Rd         7:20-7:50   ( )  |
| 4  Rajendra Pl        7:55-8:25   ( )  |
| ...                                    |
|----------------------------------------|
|   [Route]        [Map]       [More]    |
+----------------------------------------+
```

Widgets: `ShiftBar`, `NextStopHero`, `StopCard` list (`ListView.builder`), `TagStatusChip`, `RouteChangedBanner`, `AutoDoneOverlay`, `SyncStatusChip`, `SimulatedBadge`.

Interactions:
- **Start shift:** location education (first time) → start the foreground service → `shift_start` op → the bar reads "Shift on: location shared".
- **End shift:** confirm sheet → stop the service → `shift_end` → D6.
- **Navigate:** enqueue `task_status en_route` → Google Maps intent.
- Tapping a stop card opens D3.
- Pull to refresh.
- WS `task.done` (source `hawatag`) → `AutoDoneOverlay` (tick, chime, vibration, 1.5 s), then the hero advances to the next pending stop.
- WS `task.cancelled` / `task.updated`, or push `route_changed` → banner "Route changed: 1 added, 1 removed", with **See changes** highlighting the affected cards.

States: standard. **Empty:** "No route today. We'll notify you when a route is assigned." **Offline:** cached route + banner, and Start shift still works (the op queues). **All done:** "All stops done. Well done!" + **End shift**.

| Key | en | hi |
|---|---|---|
| title | Today's route | आज का रूट |
| startShift | Start shift | शिफ्ट शुरू करें |
| endShift | End shift | शिफ्ट खत्म करें |
| shiftOn | Shift on: location shared | शिफ्ट चालू: लोकेशन साझा हो रही है |
| nextStop | Next stop | अगला स्टॉप |
| stopOf | Stop {n} of {total} | {total} में से स्टॉप {n} |
| arriveWindow | Arrive {start} – {end} | पहुँचें {start} – {end} |
| navigate | Navigate | रास्ता देखें |
| doSpray | Spray about {litres} L along {metres} m | {metres} मीटर में लगभग {litres} लीटर छिड़काव करें |
| doSweep | Sweep {metres} m of road | {metres} मीटर सड़क की सफ़ाई करें |
| doSmogGun | Run the smog gun for {minutes} min | स्मॉग गन {minutes} मिनट चलाएँ |
| tagOnline | HawaTag online, seen {ago} | HawaTag चालू, {ago} पहले देखा |
| tagOffline | HawaTag offline since {time} | HawaTag {time} से बंद |
| doneByTag | Done by HawaTag | HawaTag ने पूरा किया |
| doneManual | Done manually (lower evidence) | हाथ से पूरा (कम सबूत) |
| empty | No route today. We'll notify you when a route is assigned. | आज कोई रूट नहीं। रूट मिलते ही हम आपको सूचना देंगे। |
| allDone | All stops done. Well done! | सभी स्टॉप पूरे। बहुत बढ़िया! |
| routeChanged | Route changed: {added} added, {removed} removed | रूट बदला: {added} जोड़े, {removed} हटाए |
| seeChanges | See changes | बदलाव देखें |

Acceptance:
1. Stops render in `sequence` order with windows in IST, within 2.5 s of cold start from cache.
2. When the simulated HawaTag reports a spray, the stop flips to "Done by HawaTag" within 1 s of the WS event, with no driver action.
3. In airplane mode the route still renders and Start shift succeeds locally.
4. Every stop and asset with `is_simulated` shows the badge.
5. At 200 % text scale nothing clips and **Navigate** stays visible without scrolling on a 720p screen.
6. Every status is icon + word, never colour alone.

### D2 Route map (`/driver/map`)

| | |
|---|---|
| Purpose | Overview of the route and the driver's position. Not turn-by-turn |
| Data | Cached route geometry + stops. Own position during shift only. Tiles via the cached tile provider |

```text
+----------------------------------------+
| Map                 [Sun] [Sync] [!]   |
| +------------------------------------+ |
| |   (1)=====(2)                      | |
| |            \\                      | |
| |             (3)====(4)   [you]     | |
| |                     \\             | |
| |                      (5)---(6)     | |
| +------------------------------------+ |
| (c) MapTiler (c) OpenStreetMap         |
| NEXT: 3 Shankar Rd  7:20-7:50  [ GO ]  |
+----------------------------------------+
```

Interactions:
- Tap a marker → a bottom card with the stop summary + **Navigate**.
- **Recenter** button.
- No gesture is required for any action.

States:
- **Offline without tiles:** plain background + polyline + markers + "Map tiles not saved for this area".
- **Location off:** no position marker and no prompt, except the one on Start shift.

Acceptance:
- Numbered markers show a status icon.
- The polyline stays visible in outdoor mode.
- Attribution is always visible.
- There are zero requests to `tile.openstreetmap.org` (asserted in tests by URL template).

### D3 Stop detail (`/driver/stops/:taskId`)

| | |
|---|---|
| Purpose | Everything for one stop: what to do, when, the status, and the fallbacks |
| Data | Cached task. `GET /v1/tasks/{id}` refresh. WS `tasks:me` for this id. Outbox `task_status` |

```text
+----------------------------------------+
| < Stop 2 of 6              <Simulated> |
| Pusa Rd near Rajinder Nagar            |
| Arrive 6:45 - 7:15 AM                  |
|----------------------------------------|
| WHAT TO DO                             |
| (drop) Spray about 500 L along 700 m   |
| Why: road dust (78 %)                  |
|----------------------------------------|
| STATUS  (clock) At stop                |
| Waiting for HawaTag to confirm spraying|
|----------------------------------------|
| [          NAVIGATE                 ]  |
| [          I'VE ARRIVED             ]  |
|        Can't do this stop              |
+----------------------------------------+
```

After done and verified, the status block reads: `(tick) Done by HawaTag, 612 L` and `Verified: PM10 −18 % for 90 min (range −26 to −10 %)`. The number formatting follows DESIGN_SYSTEM §12: U+2212 minus, and "to" for negative bounds.

Interactions:
- **I've arrived** is **local only**: it switches the card to "You're here, start spraying". The geofence triggers it automatically.
  - Nothing is posted. The server moves the stop to `in_progress` when the HawaTag reports `spray_start` (WS `task.in_progress`), and the status line then reads "Spraying…".
- **Can't do this stop** opens D4.
- **Mark done manually** appears only when both hold: `asset.tag_status ∈ {offline, degraded}` (or a `device_health` push), and the task is `acknowledged` or `en_route`. Those are the only states the backend accepts manual done from (backend ARCHITECTURE §5.2). It opens D5.
- The verified block appears once `impact_summary` is present.

| Key | en | hi |
|---|---|---|
| whatToDo | What to do | क्या करना है |
| why | Why: {cause} ({pct} %) | कारण: {cause} ({pct} %) |
| arrived | I've arrived | यहाँ पहुँच गए |
| waitingTag | Waiting for HawaTag to confirm spraying | HawaTag से छिड़काव की पुष्टि का इंतज़ार |
| cantDo | Can't do this stop | यह स्टॉप नहीं हो सकता |
| markManual | Mark done manually | हाथ से पूरा दर्ज करें |
| verified | Verified: {pollutant} {effect} % for {minutes} min (range {low} to {high} %) | पुष्टि: {minutes} मिनट तक {pollutant} {effect} % (दायरा {low} से {high} %) |
| verifying | Checking the effect (2–4 h after spraying) | असर की जाँच हो रही है (छिड़काव के 2–4 घंटे बाद) |
| inconclusive | Inconclusive: the effect could not be measured | अनिर्णीत: असर मापा नहीं जा सका |
| lowerEvidence | Lower evidence | कम सबूत |

Acceptance:
- **Mark done manually** is not rendered while the HawaTag is online.
- The verified line always shows the CI range and the method label ("lower evidence" for `before_after_naive` or `manual`).
- An outbox op that's still pending shows a small "Saved, will send" clock icon.

### D4 Skip reason (`/driver/stops/:taskId/skip`, modal)

Data: outbox `task_status {status: "skipped", reason, note?}`. `reason` uses proposed `SkipReason`.

```text
+----------------------------------------+
| Why can't you do this stop?            |
| [ Road blocked                      ]  |
| [ Vehicle problem                   ]  |
| [ Water tank empty                  ]  |
| [ Unsafe to work here               ]  |
| [ Not allowed in                    ]  |
| [ Other                             ]  |
|        Cancel           [ SKIP STOP ]  |
+----------------------------------------+
```

| `SkipReason` | en | hi |
|---|---|---|
| `road_blocked` | Road blocked | रास्ता बंद है |
| `vehicle_issue` | Vehicle problem | गाड़ी में खराबी |
| `water_empty` | Water tank empty | पानी की टंकी खाली |
| `unsafe` | Unsafe to work here | यहाँ काम करना असुरक्षित |
| `access_denied` | Not allowed in | अंदर जाने नहीं दिया |
| `other` | Other (add a note) | अन्य (टिप्पणी लिखें) |

Skip is available for `dispatched`/`acknowledged`/`en_route` stops even when the HawaTag is online. A blocked road is not a sensor problem ([CONTEXT §3.1](CONTEXT.md#31-flow-b-driver-runs-a-route-with-no-manual-reporting-71)). It's hidden once spraying has started (`in_progress`). The code is stored in `plan_task.skip_reason` (free text in backend DATA_MODEL §8.4; the enum is proposed). Acceptance: two taps to skip. `other` requires a note of ≥ 3 characters. Works offline.

### D5 Manual done (`/driver/stops/:taskId/manual-done`, modal, HawaTag offline only)

Data: optional `photo_upload`, then `task_status {status: "done", source: "manual", litres?, s3_keys?}`. The backend creates an `intervention` with `source=manual`, `flags=["low_evidence"]`, and replaces it if a HawaTag segment later matches (backend ARCHITECTURE §5.2 "Manual fallback").

| Key | en | hi |
|---|---|---|
| title | HawaTag is offline | HawaTag बंद है |
| body | Only if you sprayed here. This is recorded as manual, with lower evidence. | सिर्फ़ तभी दबाएँ जब आपने यहाँ छिड़काव किया हो। यह हाथ से दर्ज होगा, कम सबूत के साथ। |
| litres | Litres sprayed (optional) | कितने लीटर छिड़के (वैकल्पिक) |
| photo | Add photo (optional) | फ़ोटो जोड़ें (वैकल्पिक) |
| confirm | Yes, I sprayed here | हाँ, मैंने यहाँ छिड़काव किया |

Acceptance:
- The route is unreachable when the tag is online (deep links redirect to D3).
- The resulting stop shows "Done manually (lower evidence)".
- If HawaTag later reports the spray, the server's `hawatag` source wins and a conflict banner explains it ([OFFLINE_AND_SYNC §7](OFFLINE_AND_SYNC.md#7-conflict-resolution)).

### D6 Shift summary (`/driver/shift/summary`)

Data: local aggregation of cached tasks + outbox depth.

| Key | en | hi |
|---|---|---|
| title | Shift summary | शिफ्ट का सारांश |
| counts | {done} done, {skipped} skipped, {pending} left | {done} पूरे, {skipped} छोड़े, {pending} बाकी |
| litres | {litres} L sprayed (HawaTag) | {litres} लीटर छिड़काव (HawaTag) |
| endConfirm | End shift and stop sharing location | शिफ्ट खत्म करें और लोकेशन बंद करें |
| unsent | {n} updates not sent yet. They will send when you're online. | {n} अपडेट अभी नहीं भेजे गए। इंटरनेट मिलते ही भेजे जाएँगे। |

Acceptance: after End shift, the ongoing notification disappears within 2 s and no location sampling continues (verified by the tracker test and a manual check).

---

## 4. Inspector (BUILD; offline capture STRETCH)

### I1 Targets (`/inspector`)

| | |
|---|---|
| Purpose | "A target, not an area" (§7). Ordered by `inspection.priority` (1 = most urgent), then task `sequence` |
| Data | `GET /v1/tasks/mine?date=` (kind `inspect`) **∪** `GET /v1/inspections?status=assigned`. Report-origin inspections assigned by an officer (`POST /v1/inspections/{id}/assign`) may have no plan task. Merged by inspection id. WS `tasks:me`, `alerts:me`. Push `inspection_target` |

```text
+----------------------------------------+
| Targets              [Sun] [Sync] [!]  |
|----------------------------------------|
| (!) Likely open burning   <Simulated>  |
|     Anand Parbat, near DTC depot       |
|     Confidence high (86 %)             |
|     From citizen report, 06:44         |
|----------------------------------------|
| ( ) Likely road dust                   |
|     Site SITE-0311, Naraina            |
|     Confidence medium (64 %)           |
|     From sensor hotspot                |
+----------------------------------------+
```

| Key | en | hi |
|---|---|---|
| title | Inspection targets | निरीक्षण लक्ष्य |
| likely | Likely {cause} | संभावित {cause} |
| confidence | Confidence {level} ({pct} %) | भरोसा {level} ({pct} %) |
| fromReport | From citizen report, {time} | नागरिक की रिपोर्ट से, {time} |
| fromHotspot | From sensor hotspot | सेंसर हॉटस्पॉट से |
| empty | No targets right now | अभी कोई लक्ष्य नहीं |

Confidence levels (DESIGN_SYSTEM §2.5, shared with the console): High ≥ 0.7 "High / उच्च", Medium 0.4–0.7 "Medium / मध्यम", Low < 0.4 "Low / कम". Cause is icon + label, never a hue. Acceptance: cause and confidence always appear together, and a new target from push appears at the top within 2 s of opening.

### I2 Inspector map (`/inspector/map`)

Suspect pins for all open targets, each with the cause icon + confidence text. Tap → I3. Same tile and attribution rules as D2.

### I3 Target detail (`/inspector/targets/:targetId`)

| | |
|---|---|
| Data | Cached target + proposed `GET /v1/inspections/{id}` evidence bundle, falling back to `GET /v1/hotspots/{id}`. The bundle has the spike series, the redacted photo via a 5-min presigned GET, and the back-trajectory. Thumbnails are cached on first view. Outbox `task_status` (`en_route`, `in_progress` = on site) for task-backed targets. For task-less inspections, arrival is local until the proposed on-site transition exists |

```text
+----------------------------------------+
| < Likely open burning      <Simulated> |
| Confidence high (86 %)                 |
| Likely cause, not proof. Confirm on    |
| site.                                  |
|----------------------------------------|
| +------------------------------------+ |
| |  [?] suspect pin                   | |
| |    \ . . wind path . .  (cam)      | |
| +------------------------------------+ |
|----------------------------------------|
| SENSOR SPIKE  PM2.5 262 vs usual 81    |
|  ___/\____   (20 s spike, Bus HPM-0142)|
|----------------------------------------|
| CITIZEN PHOTO  06:44  [ thumbnail ]    |
| Reported by a citizen                  |
|----------------------------------------|
| [ NAVIGATE ]         [ ARRIVED ]       |
| [          RECORD OUTCOME           ]  |
+----------------------------------------+
```

| Key | en | hi |
|---|---|---|
| suspect | Suspected source | संदिग्ध स्रोत |
| notProof | Likely cause, not proof. Confirm on site. | यह संभावित कारण है, सबूत नहीं। मौके पर पुष्टि करें। |
| spike | Sensor spike: PM2.5 {peak} vs usual {baseline} | सेंसर उछाल: PM2.5 {peak}, सामान्य {baseline} |
| photo | Citizen photo, {time} | नागरिक की फ़ोटो, {time} |
| reporter | Reported by a citizen | एक नागरिक ने रिपोर्ट किया |
| trajectory | Wind path (back-trajectory) | हवा का रास्ता (बैक-ट्रैजेक्टरी) |
| arrived | Arrived | पहुँच गए |
| record | Record outcome | नतीजा दर्ज करें |

States: **offline** with cached evidence renders fully (thumbnails from cache). Offline without cache shows text evidence only + "Photos will load when online". **Expired signed URL** triggers a silent refetch of the bundle. Acceptance: never shows reporter identity or phone. Evidence renders offline after it has been opened once online.

### I4 Record outcome (`/inspector/targets/:targetId/outcome`)

Data: `photo_upload` ops, then `inspection_close` → `POST /v1/inspections/{id}/close {outcome, notes, evidence_keys[], closed_at, location}`. This is the flow in backend ARCHITECTURE §5.4. The backend stores `inspection.evidence_keys`/`outcome_notes`, closes the linked report (with `outcome_text`) and marks any linked `inspect` task `done`. Outcome values are exactly `InspectionStatus` `closed_confirmed | closed_not_found | closed_unreachable`.

```text
+----------------------------------------+
| < What did you find?                   |
| [ (tick)  Source confirmed          ]  |
| [ (x)     Nothing found             ]  |
| [ (road)  Could not reach the spot  ]  |
|----------------------------------------|
| Photos  [+] [img] [img]                |
| Notes   [________________________]     |
|----------------------------------------|
| [          SAVE OUTCOME             ]  |
+----------------------------------------+
```

| Key | en | hi |
|---|---|---|
| title | What did you find? | आपको क्या मिला? |
| confirmed | Source confirmed | स्रोत की पुष्टि हुई |
| notFound | Nothing found | कुछ नहीं मिला |
| unreachable | Could not reach the spot | जगह तक नहीं पहुँच सके |
| addPhotos | Add photos | फ़ोटो जोड़ें |
| notes | Notes | टिप्पणी |
| save | Save outcome | नतीजा सेव करें |
| savedOffline | Saved. Will send when online. | सेव हो गया। इंटरनेट मिलते ही भेजा जाएगा। |
| sent | Sent | भेज दिया गया |

Acceptance:
- `closed_confirmed` requires ≥ 1 photo. The other two require a note.
- Save works offline and the draft survives app kill.
- The inspection is closed exactly once server-side even after retries (idempotency test).

### I5 Photo viewer (`/inspector/targets/:targetId/photos/:index`)

Full-screen pinch-zoom of evidence photos, with the capture time and "Reported by a citizen". There's no share or save action.

---

## 5. School principal (STRETCH, F19)

### S1 Today (`/school`)

| | |
|---|---|
| Purpose | "When is it safe outdoors" (§7) |
| Data | `GET /v1/schools/me`. `GET /v1/schools/{id}/safe-window?date=` (today, tomorrow). Latest advice from `indoor-outdoor`. Proposed `GET /v1/grap/outlook?ward=&days=3`. Push `safe_window`, `pollutant_warning`, `grap_outlook`, `device_health` |

```text
+----------------------------------------+
| Sarvodaya Vidyalaya  [हिन्दी|English]   |
| <Includes simulated data>              |
|----------------------------------------|
| SAFE OUTDOOR TIME                      |
| Today     1:30 - 3:00 PM   conf. med.  |
| Tomorrow  none: keep activities inside |
|----------------------------------------|
| Morning assembly: hold indoors         |
| PM2.5 at 8 AM: likely 262              |
| (range 210 - 330) ug/m3, indicative    |
|----------------------------------------|
| CLASSROOMS NOW                         |
| (shut) Keep windows shut               |
| Outdoor air is much worse than indoor. |
| [ See indoor vs outdoor ]              |
|----------------------------------------|
| GRAP Stage III likely Thursday (70 %)  |
+----------------------------------------+
```

| Key | en | hi |
|---|---|---|
| safeTitle | Safe outdoor time | बाहर सुरक्षित समय |
| today / tomorrow | Today / Tomorrow | आज / कल |
| window | {start} – {end} · confidence {level} | {start} – {end} · भरोसा {level} |
| none | No safe window. Keep activities indoors. | बाहर का कोई सुरक्षित समय नहीं। गतिविधियाँ अंदर रखें। |
| borderline | Borderline: air may cross the limit near the end | सीमा पर: आखिर में हवा सीमा पार कर सकती है |
| assembly | Morning assembly: hold indoors | सुबह की प्रार्थना सभा: अंदर करें |
| pm8 | PM2.5 at 8 AM: likely {p50} (range {p10} – {p90}) µg/m³ | सुबह 8 बजे PM2.5: संभावित {p50} (दायरा {p10} – {p90}) µg/m³ |
| shut | Keep windows shut | खिड़कियाँ बंद रखें |
| shutWhy | Outdoor air is much worse than indoor. | बाहर की हवा अंदर से काफ़ी खराब है। |
| ventilate | Ventilate now | अभी खिड़कियाँ खोलें |
| ventilateWhy | CO₂ is high indoors and outdoor air is better right now. Open windows for a few minutes. | अंदर CO₂ ज़्यादा है और अभी बाहर की हवा बेहतर है। कुछ मिनट के लिए खिड़कियाँ खोलें। |
| normal | No change needed | कोई बदलाव ज़रूरी नहीं |
| grap | GRAP Stage {roman} likely on {day} ({pct} %) | {day} को GRAP चरण {roman} की संभावना ({pct} %) |

Advice comes **from the server**. The app never computes it:
- `school_safe_window.advice` uses `ClassroomAdvice = normal | seal | ventilate` (backend DATA_MODEL §7.7; to be added to CONTRACTS §3). `seal` → `shut`/`shutWhy`, `ventilate` → `ventilate`/`ventilateWhy`, `normal` → `normal`.
- When the server sends `advice_reason` / `advice_reason_hi`, the app shows that text instead of the generic "Why" line.
- `{roman}` is the GRAP stage as a Roman numeral (I–IV), per DESIGN_SYSTEM §2.4.
- The P10–P90 range is labelled "80 % range" in S3's legend (DESIGN_SYSTEM §9 rule 4).

Acceptance:
- Every window shows a confidence level and every concentration a P10–P90 range.
- The language toggle switches instantly and persists.
- The 19:00/22:00 push opens this screen on the right date.

### S2 Indoor vs outdoor (`/school/air`)

Data: `GET /v1/schools/{id}/indoor-outdoor?from=now-6h&to=now` (outdoor PM2.5, indoor PM2.5, indoor `co2_ppm`, `advice` as `ClassroomAdvice`, device status per unit `HPS-NNNN-O`/`-I`, `is_simulated`).

```text
+----------------------------------------+
| < Indoor vs outdoor        <Simulated> |
| Outdoor PM2.5   212  very poor         |
| Classroom PM2.5  74  moderate          |
| Classroom CO2  1050 ppm                |
| Indoor is 35 % of outdoor              |
|  outdoor ----\___/------               |
|  indoor  ______________                |
|  06:00     08:00     10:00  12:00      |
| (shut) Keep windows shut               |
+----------------------------------------+
```

| Key | en | hi |
|---|---|---|
| title | Indoor vs outdoor | अंदर बनाम बाहर |
| outdoor | Outdoor PM2.5 | बाहर PM2.5 |
| indoor | Classroom PM2.5 | कक्षा में PM2.5 |
| co2 | Classroom CO₂ | कक्षा में CO₂ |
| ratio | Indoor is {ratio} % of outdoor | अंदर की हवा बाहर की {ratio} % है |
| offline | Sensor offline since {time} | सेंसर {time} से बंद |

Acceptance: lines are distinguished by dash pattern + legend, not colour alone. A HawaPod-S offline state shows the last reading time. The simulated pair shows the badge.

### S3 Forecast (`/school/forecast`)

Data: `GET /v1/forecast/{cell_id}` (72 h P10/P50/P90 + GRAP). Chart (DESIGN_SYSTEM §9):
- P50 as a 2 dp `brand` line with a P10–P90 band
- school hours shaded
- the alert threshold (PM2.5 250) as a dashed line
- AQI colours only as faint 8 % background bands
- IST time axis with units

Copy: "72-hour forecast" / "72 घंटे का पूर्वानुमान". "Likely value (line) and 80 % range (band)" / "संभावित मान (रेखा) और 80 % दायरा (पट्टी)".

Acceptance: the band is always drawn and can't be toggled off. A missing P10/P90 renders "range unavailable" instead of a bare line. A "Show as table" toggle lists every quantile.

School alerts use the shared inbox X1/X2 with **acknowledge** ([§8](#8-shared-screens)).

---

## 6. Citizen / outdoor worker (STRETCH, F16 + F20)

### C1 Air near me (`/citizen`)

| | |
|---|---|
| Purpose | "Should I avoid this road now" (§7) |
| Data | `GET /open/v1/air?bbox=` with the bbox **snapped to a ~1 km grid** around the coarse position. The app picks the cell containing the user locally. Needed fields: `aqi`, `aqi_category`, `dominant_pollutant`, `pm25`, `no2_ppb`, `confidence`, `cause_label`, `cause_conf`, `as_of`, `is_simulated`. Push `pollutant_warning`, `grap_outlook` |

```text
+----------------------------------------+
| Air near you              [Sync] [!]   |
| +------------------------------------+ |
| | AQI 312  VERY POOR   indicative    | |
| | Main pollutant: PM2.5              | |
| | Likely source: burning (72 %)      | |
| | Updated 7:45 AM                    | |
| +------------------------------------+ |
| WHAT TO DO                             |
| - Wear a mask outdoors (N95 if you     |
|   have one)                            |
| - Stay indoors if you can; keep        |
|   windows shut                         |
| [        REPORT BURNING            ]   |
| Alerts for my area: ON  >              |
+----------------------------------------+
```

Advice rules (pure function `advice_rules.dart`, unit tested; mirrors F16's pollutant-specific advice):

| Condition | Advice keys |
|---|---|
| category ≤ `satisfactory` | `adviceFine` |
| dominant `pm25` and cause `burning` or `regional_smoke` | `adviceMask`, `adviceIndoors` |
| dominant `no2` or cause `traffic` | `adviceAvoidRoad`, `adviceQuietStreets` |
| dominant `pm10` or cause `dust` | `adviceCoverDust` |
| confidence < 0.4 (Low) | append `adviceRough` |

| Key | en | hi |
|---|---|---|
| title | Air near you | आपके पास की हवा |
| aqi | AQI {value} · {category} · indicative | AQI {value} · {category} · सांकेतिक |
| main | Main pollutant: {pollutant} | मुख्य प्रदूषक: {pollutant} |
| source | Likely source: {cause} ({pct} %) | संभावित स्रोत: {cause} ({pct} %) |
| adviceFine | Air is fine for outdoor activity | बाहर की गतिविधियों के लिए हवा ठीक है |
| adviceMask | Wear a mask outdoors (N95 if you have one) | बाहर मास्क पहनें (हो सके तो N95) |
| adviceIndoors | Stay indoors if you can; keep windows shut | हो सके तो घर के अंदर रहें; खिड़कियाँ बंद रखें |
| adviceAvoidRoad | Avoid this road for now | अभी इस सड़क से बचें |
| adviceQuietStreets | Walk or ride on quieter streets | कम ट्रैफ़िक वाली गलियों से जाएँ |
| adviceCoverDust | Cover nose and mouth near construction or dusty roads | निर्माण या धूल भरी सड़कों के पास नाक और मुँह ढकें |
| adviceRough | Few sensors nearby; treat this as a rough estimate | पास में कम सेंसर हैं; इसे मोटा अनुमान मानें |
| report | Report burning | जलाने की शिकायत करें |

States: **location denied** → manual area picker (ward list) instead of a dead end. **Stale** after 30 min. Acceptance: the chip shows number + category word + "indicative", the precise user position is never sent, and simulated cells show the badge.

### C2 Alert subscription (`/citizen/subscription`)

Data: proposed `GET/PUT /v1/me/alert-subscription {home: {lat, lon} rounded to 0.005°, radius_m: 1000, kinds: ["pollutant_warning","grap_outlook"], quiet_hours: {start: "22:00", end: "06:00"}}`. The server stores only resolved cell ids. Outbox `profile_update`.

| Key | en | hi |
|---|---|---|
| title | Alerts for my area | मेरे इलाके की चेतावनी |
| area | Area: around {place} (about 1 km) | इलाका: {place} के आसपास (लगभग 1 किमी) |
| useCurrent | Use my current location | मेरी अभी की लोकेशन लें |
| kindWarn | Bad air warnings | खराब हवा की चेतावनी |
| kindGrap | GRAP outlook | GRAP पूर्वानुमान |
| quiet | Quiet hours 10 PM – 6 AM | शांत समय रात 10 से सुबह 6 |
| save | Save | सेव करें |

### C3 Report privacy notice (`/citizen/report/privacy`, first use)

| Key | en | hi |
|---|---|---|
| title | Before you report | रिपोर्ट करने से पहले |
| b1 | Photograph the fire or smoke, not people or vehicle number plates. | आग या धुएँ की फ़ोटो लें, लोगों या गाड़ियों की नंबर प्लेट की नहीं। |
| b2 | We send the photo, the time and your location. Hidden photo data is removed. | हम फ़ोटो, समय और आपकी लोकेशन भेजते हैं। फ़ोटो की छिपी जानकारी हटा दी जाती है। |
| b3 | Inspectors never see your name or number. | निरीक्षक आपका नाम या नंबर कभी नहीं देखते। |
| b4 | Stay safe. Don't go close to the fire. | सुरक्षित रहें। आग के पास न जाएँ। |
| ok | I understand | समझ गए, आगे बढ़ें |

Acceptance: shown before the first capture, available again from the report screen's "i" icon, and the acceptance is stored locally.

### C4 Report capture (`/citizen/report/new`)

Opens the system camera (camera only). In parallel it gets a GPS fix with accuracy. After capture → C5.

| Key | en | hi |
|---|---|---|
| take | Take photo | फ़ोटो लें |
| locating | Getting your location… | आपकी लोकेशन ली जा रही है… |
| rough | Location is rough (±{m} m). Move to open sky if you can. | लोकेशन सटीक नहीं (±{m} मीटर)। हो सके तो खुले आसमान के नीचे जाएँ। |

Acceptance: there's no gallery option. If Android kills the activity during capture, the photo is recovered via `retrieveLostData()` and the draft resumes.

### C5 Report review (`/citizen/report/review`)

Data: `reports_draft` row. On **Send**: outbox `photo_upload` → `report_submit`. That's `POST /v1/reports` as JSON `{client_report_id, s3_key, lat, lon, location_accuracy_m, captured_at, category, note}` after the presigned POST, matching backend ARCHITECTURE §5.4. See the contract note in [ARCHITECTURE §7](ARCHITECTURE.md#7-api-surface-used-by-the-app). One photo per report (`citizen_report.photo_s3_key`). Rate limit: 10 reports per hour per user, and a `RateLimitedFailure` shows "You've sent many reports. Try again in {minutes} min" / "आपने बहुत रिपोर्ट भेजी हैं। {minutes} मिनट बाद फिर कोशिश करें".

```text
+----------------------------------------+
| < Review report                        |
| [        photo preview          ]      |
| 7:02 AM · +/- 12 m · Anand Parbat      |
| What is burning?                       |
| ( ) Garbage or leaves                  |
| ( ) Construction dust                  |
| ( ) Something else                     |
| Note (optional) [_______________]      |
| [          SEND REPORT             ]   |
+----------------------------------------+
```

| Key | en | hi |
|---|---|---|
| what | What is burning? | क्या जल रहा है? |
| catBurning | Garbage or leaves | कचरा या पत्ते |
| catDust | Construction dust | निर्माण की धूल |
| catOther | Something else | कुछ और |
| note | Add a note (optional) | टिप्पणी जोड़ें (वैकल्पिक) |
| send | Send report | रिपोर्ट भेजें |
| savedOffline | Saved. Will send when you're online. | सेव हो गई। इंटरनेट मिलते ही भेजी जाएगी। |
| sent | Sent. Thank you! | भेज दी गई। धन्यवाद! |

Category maps to proposed `ReportCategory = burning | dust | other`. Acceptance: the uploaded bytes have no EXIF (test), one report is created per Send even with retries, and the offline Send appears in C6 as "Waiting to send".

### C6 My reports (`/citizen/reports`)

Data: `GET /v1/reports/mine` (cursor-paged) merged with local unsent drafts. Includes WhatsApp reports from the same number (proposed). Each row shows a photo thumb (local if available), time, place and a status pill. Copy: "My reports" / "मेरी रिपोर्ट". "Waiting to send" / "भेजना बाकी". Empty: "No reports yet. Seen burning? Report it with a photo." / "अभी कोई रिपोर्ट नहीं। कहीं कुछ जलता दिखे? फ़ोटो के साथ रिपोर्ट करें।"

### C7 Report status (`/citizen/reports/:reportId`)

Data: `GET /v1/reports/{id}` with proposed `timeline: [{status, at}]` and `outcome` (`InspectionStatus` `closed_*` or `null`). Push `report_outcome`.

```text
+----------------------------------------+
| < Report, 13 Nov 7:02 AM               |
| (o) Sent                    7:02 AM    |
| (o) Being checked           7:03 AM    |
| (o) Confirmed by our system 7:04 AM    |
| (o) Inspector sent          7:05 AM    |
| (o) Closed                  7:40 AM    |
|----------------------------------------|
| OUTCOME                                |
| The inspector confirmed the source and |
| acted on it. Thank you for reporting.  |
+----------------------------------------+
```

| `ReportStatus` / outcome | en | hi |
|---|---|---|
| `submitted` | Sent | भेजी गई |
| `verifying` | Being checked | जाँच हो रही है |
| `verified` | Confirmed by our system | सिस्टम ने पुष्टि की |
| `rejected` | Could not be confirmed | पुष्टि नहीं हो सकी |
| `ticketed` | Inspector sent | निरीक्षक भेजा गया |
| `closed` | Closed | बंद |
| `closed_confirmed` | The inspector confirmed the source and acted on it. | निरीक्षक ने स्रोत की पुष्टि की और कार्रवाई की। |
| `closed_not_found` | The inspector found nothing at the spot. | निरीक्षक को मौके पर कुछ नहीं मिला। |
| `closed_unreachable` | The inspector could not reach the spot. | निरीक्षक मौके तक नहीं पहुँच सके। |

The outcome text comes from the server's `outcome_text` / `outcome_text_hi` (backend DATA_MODEL §11.1) when present. The table above is the fallback by outcome code. `rejected` shows `rejection_reason` if the server sends one in the user's language, otherwise the neutral line.

Acceptance: the timeline follows the `ReportStatus` order. `rejected` ends the timeline with a neutral explanation (no blame). The outcome appears within 2 s of opening from a `report_outcome` push.

### C8 Cleaner-route tip (`/citizen/route-tip`, STRETCH)

Shows the `advice.alt_route` text carried in a traffic `pollutant_warning` (server-written en/hi, e.g. "Take Pusa Rd instead of Shankar Rd until 10 AM"). There's no in-app routing engine. Title: "Cleaner route tip" / "साफ़ हवा वाला रास्ता".

---

## 7. Site manager (VISION, F9)

### M1 Site score (`/site`, read-only)

Data: `GET /v1/sites/me` with proposed `pm10_trend: [{date, pm10_p50, n_obs}]`, `grade`, `grade_since`, `flags_30d`, `last_inspection_at`, `is_simulated`.

```text
+----------------------------------------+
| SITE-0311, Naraina                     |
|   +-----+                              |
|   |  B  |  Grade B since 2 Nov         |
|   +-----+                              |
| PM10 trend, last 30 days (indicative)  |
|   ..--''--..__..--''                   |
| Better grades face lighter curbs on    |
| bad-air days.                          |
| Indicative sensor data, not a legal    |
| finding.                               |
+----------------------------------------+
```

| Key | en | hi |
|---|---|---|
| title | Your site grade | आपकी साइट का ग्रेड |
| grade | Grade {g} since {date} | {date} से ग्रेड {g} |
| trend | PM10 trend, last 30 days (indicative) | PM10 रुझान, पिछले 30 दिन (सांकेतिक) |
| incentive | Better grades face lighter curbs on bad-air days. | बेहतर ग्रेड पर खराब हवा वाले दिनों में कम पाबंदियाँ। |
| notLegal | Indicative sensor data, not a legal finding. | सांकेतिक सेंसर डेटा, कानूनी निष्कर्ष नहीं। |

---

## 8. Shared screens

### X1 Alert inbox (`/alerts`)

Data: `GET /v1/alerts` (cursor), drift `alerts`, WS `alerts:me`. Each row shows kind icon, title, time, unread dot + "New" word, and an acknowledged tick for schools. Copy: "Alerts" / "सूचनाएँ". Empty: "No alerts" / "कोई सूचना नहीं". Acceptance: works offline from cache. Expired alerts (`expires_at` passed) are greyed with "Expired / समाप्त".

### X2 Alert detail (`/alerts/:alertId`)

Data: `GET /v1/alerts/{id}`. Proposed `POST /v1/alerts/{id}/ack` (outbox `alert_ack`). Opening marks it read locally. **Acknowledge** is shown for audience `school` (and for `grap_outlook` to site managers).

| Key | en | hi |
|---|---|---|
| ack | I've read this | मैंने पढ़ लिया |
| acked | Acknowledged at {time} | {time} पर पढ़ा गया |
| openRelated | Open | खोलें |

Acceptance: the ack is idempotent (one server record). The officer console can see the acknowledgement once synced.

### X3 Settings (`/settings`)

```text
+----------------------------------------+
| < Settings                             |
| Language          [हिन्दी | English]    |
| Notifications                     >    |
| Display   Standard / Dark / Outdoor    |
| Data saver                      [on]   |
| Pending uploads (2)               >    |
| Switch role                       >    |
| Licences                          >    |
| Version 0.1.0 (dev)                    |
| [            LOG OUT               ]   |
+----------------------------------------+
```

| Key | en | hi |
|---|---|---|
| title | Settings | सेटिंग्स |
| language | Language | भाषा |
| notifications | Notifications | सूचनाएँ |
| display | Display: Standard / Dark / Outdoor (high contrast) | डिस्प्ले: सामान्य / डार्क / धूप में (हाई कॉन्ट्रास्ट) |
| dataSaver | Data saver | डेटा बचत |
| dataSaverHint | Smaller photos, no map downloads on mobile data | छोटी फ़ोटो, मोबाइल डेटा पर नक्शा डाउनलोड नहीं |
| pending | Pending uploads ({n}) | भेजना बाकी ({n}) |
| switchRole | Switch role | भूमिका बदलें |
| logout | Log out | लॉग आउट |
| logoutWarn | {n} updates are not sent yet. If you log out now they will be lost. | {n} अपडेट अभी नहीं भेजे गए। अभी लॉग आउट करने पर वे मिट जाएँगे। |
| sendNow | Send now | अभी भेजें |
| logoutAnyway | Log out anyway | फिर भी लॉग आउट करें |

Notifications sub-screen: per-kind toggles (citizen: pollutant warnings, GRAP outlook, report updates; school: safe windows, pollutant warnings). Driver/inspector route notifications can't be turned off in-app. The text explains that SMS covers the route if they're disabled at OS level.

Acceptance:
- Language change re-renders instantly, re-registers notification channel names and enqueues `profile_update`.
- Logout with an unsent outbox shows `logoutWarn`.
- Logout wipes data ([OFFLINE_AND_SYNC §10](OFFLINE_AND_SYNC.md#10-storage-limits-cleanup-and-logout)).
- In the dev flavor, a **Dev tools** row appears: simulate HawaTag spray, send test push, toggle fake offline, reset DB.

### X4 Pending uploads (`/settings/sync`)

Data: `outbox_ops` stream. Each row shows the op kind in words ("Stop 3 status", "Report photo"), its state (waiting for internet / retrying at 07:52 / failed: reason) and **Retry now**. Failed permanent ops offer **Discard** with a confirm. Copy: "All sent" / "सब भेज दिया गया". "Waiting for internet" / "इंटरनेट का इंतज़ार". "Failed: {reason}" / "नहीं भेजा जा सका: {reason}". "Retry now" / "अभी फिर कोशिश करें".

### X5 Profile (`/profile`)

Name, own phone **masked** (`+91 98•••••210`), roles, ward, app version, install id (for support). There's no way to see other users.

---

## 9. Push notification catalogue

Payload schema: [ARCHITECTURE §10.3](ARCHITECTURE.md#103-fcm-data-payload-proposed-contract-fcm-data-values-are-strings). `route_changed` and `task_done_auto` are **proposed additions** to `AlertKind`. The server sends title/body in the user's `lang`, and the app falls back to these templates from `type` + `args`. If `is_simulated == "true"`, the body gets the suffix " · Simulated" / " · सिम्युलेटेड". The **Deep link** column shows the payload's entity link (the backend `alert.deep_link` form `hawa://…`) → the app route it resolves to for that role ([ARCHITECTURE §5.3](ARCHITECTURE.md#53-deep-links-from-push)). `{roman}` renders GRAP stages as I–IV.

| `type` | Title (en / hi) | Body (en / hi) | Deep link | Role(s) | Channel |
|---|---|---|---|---|---|
| `route_assignment` | Today's route is ready<br>आज का रूट तैयार है | {count} stops, first at {time}. Tap to start.<br>{count} स्टॉप, पहला {time} पर। शुरू करने के लिए दबाएँ। | `hawa://route?date=` → `/driver` | driver | `route_updates` |
| `route_changed` | Your route changed<br>आपका रूट बदल गया है | {added} added, {removed} removed. Check the new order.<br>{added} जोड़े गए, {removed} हटाए गए। नया क्रम देखें। | `hawa://route?date=&changed=1` → `/driver` + diff banner | driver | `route_updates` |
| `task_done_auto` | Stop {n} done<br>स्टॉप {n} पूरा | HawaTag recorded {litres} L sprayed. Next: {next}.<br>HawaTag ने {litres} लीटर छिड़काव दर्ज किया। अगला: {next}। | `hawa://tasks/{task_id}` → `/driver/stops/{task_id}` | driver | `route_updates` |
| `inspection_target` | New inspection target<br>नया निरीक्षण लक्ष्य | Likely {cause} near {place}. Confidence {level}.<br>{place} के पास संभावित {cause}। भरोसा {level}। | `hawa://inspections/{inspection_id}` → `/inspector/targets/{inspection_id}` | inspector | `route_updates` |
| `safe_window` | Safe outdoor time {day}: {start}–{end}<br>{day} बाहर सुरक्षित समय: {start}–{end} | PM2.5 at 8 AM likely {p50} µg/m³ (range {p10}–{p90}). Hold assembly indoors.<br>सुबह 8 बजे PM2.5 संभावित {p50} µg/m³ (दायरा {p10}–{p90})। प्रार्थना सभा अंदर करें। | `hawa://schools/{school_id}/safe-window?date={date}` → `/school?date={date}` | school | `air_alerts` |
| `pollutant_warning` (smoke, PM2.5) | Smoke nearby: air {category}<br>पास में धुआँ: हवा {category} | Wear a mask outdoors and keep windows shut until {time}.<br>{time} तक बाहर मास्क पहनें और खिड़कियाँ बंद रखें। | `hawa://alerts/{alert_id}` → `/alerts/{alert_id}` | citizen, school | `air_alerts` |
| `pollutant_warning` (traffic, NO₂) | Heavy traffic fumes on {road}<br>{road} पर वाहनों का भारी धुआँ | Avoid this road until {time}. {alt_route}<br>{time} तक इस सड़क से बचें। {alt_route} | `hawa://alerts/{alert_id}` → `/alerts/{alert_id}` | citizen | `air_alerts` |
| `pollutant_warning` (dust, PM10) | Dusty air near {place}<br>{place} के पास धूल भरी हवा | Cover nose and mouth near construction until {time}.<br>{time} तक निर्माण के पास नाक और मुँह ढकें। | `hawa://alerts/{alert_id}` → `/alerts/{alert_id}` | citizen | `air_alerts` |
| `grap_outlook` | GRAP Stage {roman} likely on {day}<br>{day} को GRAP चरण {roman} की संभावना | Probability {pct} %. Plan outdoor work early.<br>संभावना {pct} %। बाहर का काम पहले कर लें। | `hawa://alerts/{alert_id}` → `/alerts/{alert_id}` | school, citizen, site_manager | `air_alerts` |
| `report_outcome` | Your report: {status}<br>आपकी रिपोर्ट: {status} | {outcome_text} Thank you for reporting.<br>{outcome_text} रिपोर्ट करने के लिए धन्यवाद। | `hawa://reports/{report_id}` → `/citizen/reports/{report_id}` | citizen | `reports` |
| `device_health` (HawaTag) | HawaTag offline on {asset}<br>{asset} पर HawaTag बंद है | Stops won't complete automatically. After spraying, tap "Mark done manually".<br>स्टॉप अपने-आप पूरे नहीं होंगे। छिड़काव के बाद "हाथ से पूरा दर्ज करें" दबाएँ। | `hawa://route?date=` → `/driver` | driver | `device_status` |
| `device_health` (HawaPod-S) | Classroom sensor offline<br>कक्षा का सेंसर बंद है | Indoor readings paused since {time}.<br>{time} से अंदर की रीडिंग रुकी हुई है। | `hawa://schools/{school_id}/air` → `/school/air` | school | `device_status` |

Delivery rules:
- Dedupe by `collapse_key` and by the WS/FCM deduper (10 min).
- Don't show if `expires_at` has passed.
- Citizen quiet hours are applied server-side, and the app doesn't re-alert for them.
- `report_outcome` is sent for `verified`, `rejected` and `closed` only (not every transition).
- A push whose `role` the user doesn't hold is ignored and logged.

---

## 10. Copy glossary (enum labels)

| Enum value | en | hi |
|---|---|---|
| `AqiCategory.good` / `satisfactory` / `moderate` | Good / Satisfactory / Moderate | अच्छा / संतोषजनक / मध्यम |
| `AqiCategory.poor` / `very_poor` / `severe` | Poor / Very poor / Severe | खराब / बहुत खराब / गंभीर |
| `CauseLabel.dust` | Dust | धूल |
| `CauseLabel.traffic` | Traffic | ट्रैफ़िक |
| `CauseLabel.burning` | Burning | खुले में जलाना |
| `CauseLabel.regional_smoke` | Regional smoke | क्षेत्रीय धुआँ |
| `CauseLabel.mixed` / `unknown` | Mixed / Unknown | मिला-जुला / पता नहीं |
| `TaskKind.spray` / `sweep` / `inspect` | Spray / Sweep / Inspect | छिड़काव / सफ़ाई / निरीक्षण |
| `TaskStatus.pending` / `dispatched` / `acknowledged` | Pending / Assigned / Seen | बाकी / सौंपा गया / देखा गया |
| `TaskStatus.en_route` / `in_progress` / `done` | On the way / At stop / Done | रास्ते में / स्टॉप पर / पूरा |
| `TaskStatus.verifying` / `verified` / `inconclusive` | Checking effect / Verified / Inconclusive | असर की जाँच / पुष्टि हुई / अनिर्णीत |
| `TaskStatus.skipped` / `cancelled` / `missed` / `failed` | Skipped / Removed / Missed / Failed | छोड़ा गया / हटाया गया / समय निकल गया / विफल |
| Confidence (`cause_conf`, twin `confidence`) High ≥ 0.7 / Medium 0.4–0.7 / Low < 0.4 | High / Medium / Low | उच्च / मध्यम / कम |
| `ClassroomAdvice.seal` / `ventilate` / `normal` | Keep windows shut / Ventilate now / No change needed | खिड़कियाँ बंद रखें / अभी खिड़कियाँ खोलें / कोई बदलाव ज़रूरी नहीं |
| `GrapStage` 0 / 1 / 2 / 3 / 4 | None / Stage I · Poor / Stage II · Very poor / Stage III · Severe / Stage IV · Severe+ | कोई नहीं / चरण I · खराब / चरण II · बहुत खराब / चरण III · गंभीर / चरण IV · गंभीर+ |
| `InterventionSource.hawatag` / `manual` / `gps_inferred` | HawaTag / Manual (lower evidence) / From GPS | HawaTag / हाथ से (कम सबूत) / GPS से |
| `ImpactVerdict.effective` / `no_detectable_effect` / `inconclusive` / `adverse` | Worked / No clear effect / Inconclusive / Made it worse | असरदार / साफ़ असर नहीं / अनिर्णीत / हालत बिगड़ी |
| Pollutants | PM2.5 (fine particles) · PM10 (dust particles) · NO₂ (vehicle gas) · CO₂ | PM2.5 (बारीक कण) · PM10 (धूल के कण) · NO₂ (वाहनों की गैस) · CO₂ |
| Common | Simulated · Includes simulated data · Indicative · Retry · Something went wrong | सिम्युलेटेड · इसमें सिम्युलेटेड डेटा शामिल है · सांकेतिक · फिर कोशिश करें · कुछ गड़बड़ हो गई |
| Offline / stale | Offline: showing saved data from {time} · Last updated {time} | ऑफ़लाइन: {time} का सेव किया डेटा · आखिरी अपडेट {time} |
| Conflict banners | HawaTag already confirmed this stop. Your manual entry wasn't needed. · The control room removed this stop from your route. | HawaTag ने यह स्टॉप पहले ही पूरा दर्ज कर दिया। आपकी हाथ से एंट्री की ज़रूरत नहीं थी। · कंट्रोल रूम ने यह स्टॉप आपके रूट से हटा दिया। |
| Unknown enum value (any) | Unknown | पता नहीं |

<!-- footer:start -->

---

[Back to top](#screens) · [Docs hub](../README.md) · [Project README](../../README.md)

<!-- footer:end -->
