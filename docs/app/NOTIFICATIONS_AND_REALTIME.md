# App notifications and realtime

<!-- nav:start -->

**Navigate:** [Project](../../README.md) · [Docs hub](../README.md) · [Overview](../SYSTEM_OVERVIEW.md) · [AWS architecture](../AWS_ARCHITECTURE.md) · [AWS guide](../AWS_SETUP_GUIDE.md) · [API](../backend/API.md) · [Environment](../ENVIRONMENT_VARIABLES.md) · [Contracts](../CONTRACTS.md)

**App docs:** [Runbook](../../app_frontend/README.md) · [Index](README.md) · [Architecture](ARCHITECTURE.md) · [Screens](SCREENS.md) · [Offline and sync](OFFLINE_AND_SYNC.md) · **Notifications and realtime** · [Deployment](DEPLOYMENT.md)

<!-- nav:end -->

<p align="center">
<img src="https://img.shields.io/badge/push-Firebase%20Cloud%20Messaging-FFCA28?logo=firebase&logoColor=black" alt="FCM">
<img src="https://img.shields.io/badge/live-WebSocket-2EA44F" alt="WebSocket">
<img src="https://img.shields.io/badge/channels-5-6E7781" alt="5 channels">
</p>

How the app hears about changes: FCM pushes, local notifications, deep links and WebSockets.

- Code: `lib/core/notifications/`, `lib/core/realtime/`, `lib/firebase/`.
- Backend side: [backend services: push and alerts](../backend/SERVICES.md#push).

---

## Push (FCM)

| Piece | What it does |
|---|---|
| `firebase_options_env.dart` | Builds Firebase options from the `FIREBASE_*` defines; none set = no Firebase |
| `FcmService` | Foreground messages, taps, token refresh; subscribes to the topic `FCM_TOPIC` (`hawa-alerts`) |
| `PushTokenRegistrar` | Queues `PUT /v1/me/push-token` after sign-in and on token refresh |
| `firebaseMessagingBackgroundHandler` | Initializes Firebase in its isolate, stores the alert, shows a localized notification, schedules a sync |

**Two kinds of push from the backend:**

| Push | Target | `type` | Opens |
|---|---|---|---|
| Alert broadcast | Topic `hawa-alerts` (every install) | `pollutant_warning`, `grap_outlook`, `safe_window` | `hawa://alerts/<id>` |
| Report update | The reporter's tokens | `report_outcome` | `hawa://reports/<id>` |

- Messages are **data-only**; the app writes the notification text, so it is never shown twice.
- Payload fields: `type`, `alert_id`, `entity_id`, `deep_link`, `role`, `lang`, `title`, `body`, `args`, `sent_at`, `collapse_key`.

---

## Notification channels (Android)

| Channel | Used for |
|---|---|
| `air_alerts` | Pollutant warnings, safe windows, GRAP outlook |
| `reports` | Citizen report outcomes |
| `route_updates` | Route assignments, route changes, auto-done stops, inspection targets |
| `device_status` | HawaTag health |
| `shift_tracking` | The ongoing shift (foreground service) |

---

## Deep links

`hawa://<entity>/<id>` from a push or notification tap:

| Entity | Opens | Role |
|---|---|---|
| `route` | Today's route | Driver |
| `tasks` | Stop detail | Driver |
| `inspections` | Target detail | Inspector |
| `schools` | School day | School |
| `reports` | Report status | Citizen |
| `alerts` | Alert detail | Any |
| `sites` | Site score | Site manager |

- If the user holds the target role but is in another one, the app switches role first.

---

## Realtime

| Socket | Used by | Behaviour |
|---|---|---|
| `${WS_URL}/fleet` (backend `/v1/ws/fleet`) | Govt in Action radar | Snapshot, then every vehicle ping; heartbeat 25 s; reconnects after 10 s; radar also polls every 15 s |
| `${WS_URL}` (`/v1/ws`) | Task events (`WsClient`) | Heartbeat 25 s, full-jitter backoff 1–30 s, token refresh on close 4401; the demo uses `FakeRealtimeClient` |

- Events are de-duplicated against pushes (`event_deduper.dart`), so one change never shows twice.

---

## Set it up

1. Create the Firebase project and Android app: [AWS guide §7](../AWS_SETUP_GUIDE.md#7-firebase-cloud-messaging-and-its-secrets-manager-secret).
2. Put the `FIREBASE_*` values and `push` in `REAL_FEATURES` in `env/staging.json`: [AWS guide §8](../AWS_SETUP_GUIDE.md#8-rebuild-the-app-with-the-new-build-defines).
3. Test: `uv run hawa aws-check --push-test` on the server sends a notification to every install.

---

## Related

- [Screens](SCREENS.md) · [Offline and sync](OFFLINE_AND_SYNC.md) · [App architecture](ARCHITECTURE.md) · [App deployment](DEPLOYMENT.md)

<!-- footer:start -->

---

[Back to top](#app-notifications-and-realtime) · [Docs hub](../README.md) · [Project README](../../README.md)

<!-- footer:end -->
