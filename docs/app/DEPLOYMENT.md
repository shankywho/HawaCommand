# App deployment

<!-- nav:start -->

**Navigate:** [Project](../../README.md) · [Docs hub](../README.md) · [Overview](../SYSTEM_OVERVIEW.md) · [AWS architecture](../AWS_ARCHITECTURE.md) · [AWS guide](../AWS_SETUP_GUIDE.md) · [API](../backend/API.md) · [Environment](../ENVIRONMENT_VARIABLES.md) · [Contracts](../CONTRACTS.md)

**App docs:** [Runbook](../../app_frontend/README.md) · [Index](README.md) · [Architecture](ARCHITECTURE.md) · **Deployment**

<!-- nav:end -->

<p align="center">
<img src="https://img.shields.io/badge/Flutter-3.44-02569B?logo=flutter&logoColor=white" alt="Flutter">
<img src="https://img.shields.io/badge/Android-APK-3DDC84?logo=android&logoColor=white" alt="Android APK">
<img src="https://img.shields.io/badge/push-FCM-FFCA28?logo=firebase&logoColor=black" alt="FCM">
<img src="https://img.shields.io/badge/flavors-dev%20%C2%B7%20staging%20%C2%B7%20prod-6E7781" alt="Flavors">
</p>

How the Flutter app (`app_frontend/`) is built, configured and shared.

---

## Build the APK

```bash
make app-apk        # from the repo root
```

- Uses the **staging** flavor and the defines in `app_frontend/env/staging.json` (copied from `env/staging.json.example` on first run).
- Output: `app_frontend/build/app/outputs/flutter-apk/app-staging-release.apk`, installs as **Hawa STG**.
- Signed with the debug key unless `app_frontend/android/key.properties` exists; fine for sideloading.

---

## Build defines (`env/<flavor>.json`)

| Define | Value |
|---|---|
| `API_BASE_URL` | Backend URL, e.g. `http://<server>:8000` (no trailing slash) |
| `WS_URL` | `ws://<server>:8000/v1/ws` (`wss://` behind HTTPS); the live radar uses `${WS_URL}/fleet` |
| `USE_FAKE_API` | `true`: features not listed below run on the in-app fake backend |
| `REAL_FEATURES` | `air_map,citizen_air,alerts,school_forecast,citizen_reports,citizen_subscription,push` |
| `FIREBASE_API_KEY`, `FIREBASE_APP_ID`, `FIREBASE_MESSAGING_SENDER_ID`, `FIREBASE_PROJECT_ID` | From the flavor's `google-services.json`; all four set = push on |
| `FCM_TOPIC` | `hawa-alerts`, must match the backend's `HAWA_FCM_TOPIC` |
| `MAP_API_KEY` | Optional MapTiler key; empty uses the keyless Esri basemap |

- Firebase setup: [AWS guide §7–8](../AWS_SETUP_GUIDE.md#7-firebase-cloud-messaging-and-its-secrets-manager-secret).
- Full list: [environment variables](../ENVIRONMENT_VARIABLES.md#5-flutter-app---dart-define).

---

## Flavors

| Flavor | Android package | App name |
|---|---|---|
| `dev` | `in.hawacommand.field.dev` | Hawa DEV (cleartext only to the emulator and localhost) |
| `staging` | `in.hawacommand.field.stg` | Hawa STG |
| `prod` | `in.hawacommand.field` | HawaCommand |

- Pass `FLAVOR` in the define file as well as `--flavor`; the define controls dev tools and logging.
- Play Store release: `prod` flavor, a release keystore in `key.properties`, and an HTTPS `API_BASE_URL`.

---

## Verify on a phone

1. Install the APK and allow notifications.
2. **Settings → Dev tools** shows the backend URL in use.
3. Citizen → **Govt in Action** radar updates while `hawa simulate-fleet` runs.
4. Citizen Eyes → submit a report; **My reports** moves to **Verified** within seconds.

---

## Related

- [App architecture](ARCHITECTURE.md) · [App runbook](../../app_frontend/README.md) · [API reference](../backend/API.md)

<!-- footer:start -->

---

[Back to top](#app-deployment) · [Docs hub](../README.md) · [Project README](../../README.md)

<!-- footer:end -->
