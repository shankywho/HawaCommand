# Environment Variables

<!-- nav:start -->

**Navigate:** [Project](../README.md) · [Docs hub](README.md) · [Overview](SYSTEM_OVERVIEW.md) · [AWS architecture](AWS_ARCHITECTURE.md) · [AWS guide](AWS_SETUP_GUIDE.md) · [API](backend/API.md) · **Environment** · [Contracts](CONTRACTS.md)

**Cloud docs:** [AWS architecture](AWS_ARCHITECTURE.md) · [AWS integration guide](AWS_SETUP_GUIDE.md) · **Environment variables**

<!-- nav:end -->

Every setting HawaCommand reads: where it lives, its default, and what it changes. Nothing is strictly required to start; every service runs with no variables set, using fixtures, synthetic data and template text. Variables unlock live data, LLM-written text, AWS and a non-default database.

Related: [root README](../README.md#quick-start) · [backend/.env.example](../backend/.env.example) · [AI-ML/.env.example](../AI-ML/.env.example) · [frontend/.env.example](../frontend/.env.example) · [AWS_SETUP_GUIDE.md](AWS_SETUP_GUIDE.md) (console steps for every AWS variable)

---

## Where each component reads its settings

| Component | File | Loaded by | Notes |
|---|---|---|---|
| Backend API, Alembic, seed script | `backend/.env` | `backend/src/hawa_backend/core/config.py` (`Settings`), `backend/src/hawa_backend/aws/settings.py` (`AwsSettings`) | Resolved by absolute path, so the working directory does not matter |
| AI-ML engine (and the backend's in-process `hawa_ml` fallback) | `AI-ML/.env` | `AI-ML/src/hawa_ml/settings.py` | Resolved by absolute path |
| Web console | `frontend/.env.local` | Next.js | `NEXT_PUBLIC_*` values are baked in at `pnpm build`; rebuild after changing them |
| Flutter app | `--dart-define` / `--dart-define-from-file` | `app_frontend/lib/app/env.dart` | Compile-time constants, not an env file |
| Root `Makefile` | command line | `Makefile` | e.g. `make frontend API_URL=...` |

In both Python services, real environment variables (exported in the shell) override values in the `.env` file. Each folder reads only its own file: a key needed by both services, such as `OPENAQ_API_KEY`, goes in both files.

The backend can also load any of its variables from one AWS Secrets Manager JSON secret named by `HAWA_AWS_SECRETS_ID` (read at startup, before anything else). Precedence: exported variables > the secret > `backend/.env`. The backend's tests ignore `backend/.env` (`backend/tests/conftest.py`).

Set up the files from the templates:

```bash
cp backend/.env.example backend/.env
cp AI-ML/.env.example AI-ML/.env
cp frontend/.env.example frontend/.env.local
```

---

## 1. Backend: `backend/.env`

### Core

| Variable | Default | Required? | What it does |
|---|---|---|---|
| `WAQI_TOKEN` | unset | Recommended | Live Delhi station readings from WAQI (tried first). Get one at https://aqicn.org/data-platform/token/ |
| `OPENAQ_API_KEY` | unset | Recommended | Live stations from OpenAQ v3 when WAQI returns fewer than 3. With neither key, the backend uses 5 built-in baseline stations |
| `HAWA_DATABASE_URL` | `postgresql+asyncpg://hawa:hawa@localhost:5432/hawa` | For `make db-update` / `make db-seed` | Async SQLAlchemy URL. The default matches `make db-up`. SQLite demo: `sqlite+aiosqlite:///./hawa.db` |
| `HAWA_AIML_SERVICE_URL` | `http://localhost:8100` | Optional | Where the backend calls the AI-ML engine |
| `HAWA_AIML_TIMEOUT_SECONDS` | `10.0` | Optional | AI-ML HTTP timeout |
| `HAWA_JWT_SECRET` | dev value | Change on any shared server | JWT signing secret (used by the auth helpers; no route enforces auth yet) |
| `HAWA_JWT_ALGORITHM` | `HS256` | Optional | JWT algorithm |
| `HAWA_JWT_EXPIRY_MINUTES` | `1440` | Optional | Token lifetime |
| `HAWA_DEV_OTP` | `123456` | Optional | Static OTP for dev logins |
| `HAWA_ENV` | `development` | Optional | Label printed by `hawa config` |
| `HAWA_DEBUG` | `false` | Optional | `true` echoes SQL |
| `HAWA_HOST`, `HAWA_PORT` | `0.0.0.0`, `8000` | Not used | Do not bind the server; use `make backend BACKEND_HOST=... BACKEND_PORT=...` |
| `HAWA_REDIS_URL` | empty | Optional; needed for more than one backend process | Redis 6.2+ / ElastiCache / Valkey, `redis://host:6379/0` or `rediss://` (TLS). Holds the live fleet geo index `geo:fleet:active`, the twin snapshot `grid:pm25:500m:<hour>` (TTL 900 s), plans, push tokens, sent alerts, alert areas, Kinesis checkpoints, and relays `/v1/ws/fleet` pings between processes. Empty or unreachable: process memory (retried every 30 s) |
| `HAWA_TRUST_CLIENT_TOKENS` | `true` | Optional | Accept the `sub` of an unverified bearer JWT (the app's in-app fake sign-in) as the caller for `/v1/reports/mine` and `/v1/me/*`. Tokens signed with `HAWA_JWT_SECRET` are always verified |
| `HAWA_ADMIN_API_KEY` | empty | **Set on any server** | `X-Api-Key` for officer writes: `POST /v1/alerts/broadcast`, `POST /v1/alerts/subscribers`, `GET /v1/reports`, `PATCH /v1/reports/{id}`, `POST /v1/reports/{id}/verify`. Empty = those routes are open |
| `HAWA_INGEST_API_KEY` | empty | **Set on any server** | `X-Api-Key` for `POST /v1/telemetry/vehicles` (the admin key also works). Empty = open. `hawa simulate-fleet` sends it |
| `HAWA_FLEET_ACTIVE_MINUTES` | `15` | Optional | A vehicle with no ping for this long leaves `/v1/fleet/live` and the radar (status `Offline`) |
| `HAWA_REPORT_SLA_HOURS` | `3` | Optional | An open citizen report older than this is flagged `sla_breach` in the officer list |
| `HAWA_FCM_SERVICE_ACCOUNT_FILE` | unset | Optional | Path to a Firebase service-account JSON, for push without Secrets Manager |
| `HAWA_FCM_SERVICE_ACCOUNT_JSON` | unset | Optional | The service-account JSON itself (e.g. from a secret). File, then JSON, then `HAWA_AWS_FCM_SECRET_ID` is the order tried |
| `HAWA_FCM_TOPIC` | `hawa-alerts` | Optional | FCM topic for broadcasts; must equal the app's `FCM_TOPIC` |
| `HAWA_KAFKA_BOOTSTRAP_SERVERS` | `localhost:9092` | Not used yet | Planned Kafka |
| `HAWA_KAFKA_SECURITY` | `plaintext` | Not used yet | Planned Kafka |

`WAQI_TOKEN` and `OPENAQ_API_KEY` are also accepted as `HAWA_WAQI_TOKEN` and `HAWA_OPENAQ_API_KEY`. An empty value skips that source.

### Optional AWS layer

Everything AWS is off unless `HAWA_AWS_ENABLED=true`, and each service is off until its own name or ARN is set. Console setup for each: [AWS_SETUP_GUIDE.md](AWS_SETUP_GUIDE.md); the matching resources are in `infrastructure/cloudformation/hawa-integration.yaml`. Check a deployment with `uv run hawa aws-check` in `backend/`.

| Variable | Default | Used by running code? | What it does |
|---|---|---|---|
| `HAWA_AWS_ENABLED` | `false` | Yes | Master switch |
| `HAWA_AWS_REGION` | `ap-south-1` | Yes | AWS region |
| `HAWA_AWS_ENDPOINT_URL` | unset | Yes | Custom endpoint, e.g. LocalStack `http://localhost:4566` |
| `HAWA_AWS_FORECAST_STATE_MACHINE_ARN` | unset | Yes: `GET /v1/forecast/{cell_id}` | Step Functions **Express** workflow run with `start_sync_execution`; must return the AI-ML forecast shape (a dict with `horizons`) |
| `HAWA_AWS_FORECAST_ENDPOINT` | unset | Yes: same route, if no state machine is set | SageMaker endpoint name, same input and output |
| `HAWA_AWS_CACHE_TABLE` | `hawa-cache` | Yes: forecast results only | DynamoDB table (`pk` string key, `ttl` attribute) caching remote forecast results |
| `HAWA_AWS_CACHE_TTL_SECONDS` | `3600` | Yes | Forecast cache TTL |
| `HAWA_AWS_DISPATCH_STATE_MACHINE_ARN` | unset | Yes: `POST /v1/plans/{id}/approve` | Step Functions execution started with the approved plan (id, ward, window, task groups); the execution ARN is returned in the plan |
| `HAWA_AWS_SECRETS_ID` | unset | Yes: startup | Secrets Manager secret (JSON object of `NAME: value`) copied into the environment before settings load, e.g. `hawa/backend` |
| `HAWA_AWS_ALERTS_TOPIC_ARN` | unset | Yes: `POST /v1/alerts/broadcast`, `POST /v1/alerts/subscribers`, plan approval | SNS topic; messages carry attributes `type`, `ward` (`all` = city-wide), `severity`, `audience` |
| `HAWA_AWS_ALERT_ON_PLAN_APPROVAL` | `true` | Yes | Publish one SNS notice per approved plan; set `false` if a dispatch state machine publishes too |
| `HAWA_AWS_SENSOR_STREAM` | unset | Yes: `POST /v1/telemetry/vehicles` (producer) and the Kinesis consumer | Kinesis stream name, e.g. `hawa-sensor-data` |
| `HAWA_AWS_KINESIS_CONSUMER` | `false` | Yes | Run the Kinesis → live fleet consumer inside the API process. Otherwise run `hawa consume-telemetry`. One consumer per stream |
| `HAWA_AWS_KINESIS_START` | `LATEST` | Yes | Where a consumer with no checkpoint starts: `LATEST` or `TRIM_HORIZON` |
| `HAWA_AWS_IOT_ENDPOINT` | unset | `hawa simulate-fleet --target iot` only | IoT Core device data endpoint (`xxxx-ats.iot.<region>.amazonaws.com`) |
| `HAWA_AWS_GRIEVANCES_TABLE` | unset | Yes: `/v1/reports*` | DynamoDB table (keys `report_id` + `created_at`; GSIs `WardStatusIndex`, `OwnerIndex`). Unset = process memory |
| `HAWA_AWS_GRIEVANCES_WARD_INDEX` | `WardStatusIndex` | Yes | GSI (`ward_id` + `status`) used by the officer list |
| `HAWA_AWS_FLEET_TABLE` | unset | Yes: telemetry ingest, `/v1/fleet/{id}/track`, missed-machine audit | DynamoDB table (keys `asset_id` + `timestamp`, TTL attribute `ttl_epoch`). Unset = process memory |
| `HAWA_AWS_FLEET_TTL_DAYS` | `7` | Yes | Days before a ping expires (`ttl_epoch`) |
| `HAWA_AWS_FCM_SECRET_ID` | unset | Yes: push | Secrets Manager secret holding the Firebase service-account JSON, e.g. `hawa/firebase/service-account` |
| `HAWA_AWS_EVIDENCE_READ_TTL_SECONDS` | `3600` | Yes: report photo URLs | Lifetime of the pre-signed GET URLs in `/v1/reports*` (needs `s3:GetObject`) |
| `HAWA_AWS_EVIDENCE_BUCKET` | unset | Yes: `POST /v1/uploads/presign` | S3 bucket name (not an `s3://` URI) for evidence photos; unset makes the route return `503` |
| `HAWA_AWS_EVIDENCE_PREFIX` | empty | Yes | Optional key prefix, e.g. `evidence/`; keys are `{prefix}{purpose}/YYYY/MM/DD/{uuid}.{ext}` |
| `HAWA_AWS_UPLOAD_MAX_BYTES` | `5242880` | Yes | Max photo size; larger requests get `413`, and the S3 policy enforces it |
| `HAWA_AWS_PRESIGN_TTL_SECONDS` | `900` | Yes | How long a pre-signed upload stays valid |

Any AWS failure is logged and the backend falls back (forecast to the AI-ML engine; plan approval still succeeds; push and SNS are skipped). The exception is the grievances table: when it is configured but failing, report routes answer `503` so the app's outbox retries, rather than storing reports where other processes cannot see them. The repository contains no Step Functions definitions, Lambda functions or SageMaker model: the forecast and dispatch workflows must be built separately. `hawa-integration.yaml` creates the two DynamoDB tables, the cache table, the SNS topic, the Kinesis stream, the IoT rule and the backend IAM policy (S3 read/write on the existing evidence bucket included), and can attach the policy to an existing role.

### AWS credentials (shell or instance role only)

boto3 does not read `.env` files. Use an IAM instance role, or export these in the shell before starting the backend:

| Variable | What it does |
|---|---|
| `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN` | Static or temporary credentials |
| `AWS_PROFILE` | Named profile from `~/.aws/credentials` |

---

## 2. AI-ML engine: `AI-ML/.env`

| Variable | Default | Required? | What it does |
|---|---|---|---|
| `GROQ_API_KEY` | unset | Optional | LLM-written agent text (plan rationale, forecast summary, auditor critique) when `LLM_PROVIDER=groq`; model `openai/gpt-oss-120b`. Without it, deterministic templates |
| `LLM_PROVIDER` | `groq` | Optional | `groq` or `bedrock`; anything else gives templates |
| `BEDROCK_MODEL_ID` | `anthropic.claude-3-5-sonnet-20241022-v2:0` | For Bedrock | Bedrock model id |
| `AWS_REGION` | `ap-south-1` | For Bedrock | Bedrock region |
| `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` | unset | For Bedrock without a role | Leave them unset (commented) to use an IAM role or `AWS_PROFILE`. Do not set them to empty strings: an empty key is passed to boto3 and breaks role-based auth |
| `OPENAQ_API_KEY` | unset | Optional | Real station metadata for `scripts/fetch_all.py`; otherwise `data/fixtures/stations_fallback.csv` |
| `NASA_FIRMS_MAP_KEY` | unset | Optional | Real VIIRS fire points for `scripts/fetch_all.py`; otherwise synthetic fires |
| `OFFLINE_MODE` | `false` | Optional | `true` disables every network call (template LLM text, fixture and synthetic data) |
| `WAQI_TOKEN`, `CDS_API_KEY`, `DATA_GOV_IN_API_KEY` | unset | Not used | Declared and reported by `scripts/check_env.py`; no ingestion code reads them |
| `LOG_LEVEL` | `INFO` | Not used | Printed by `scripts/check_env.py`; not applied to the logger |

Check what the engine sees (keys are masked): `cd AI-ML && python scripts/check_env.py`.

---

## 3. Web console: `frontend/.env.local`

| Variable | Default | Required? | What it does |
|---|---|---|---|
| `NEXT_PUBLIC_API_URL` | empty | Required to use the real backend | Backend base URL with no trailing slash and no `/v1`, e.g. `http://localhost:8000` or `http://<server-ip>:8000`. Empty: every call is answered in the browser by `src/mocks/`. Must be reachable from the user's browser |
| `NEXT_PUBLIC_COGNITO_USER_POOL_ID` | empty | Optional | Cognito sign-in on `/login`; needs the client id too |
| `NEXT_PUBLIC_COGNITO_CLIENT_ID` | empty | Optional | Cognito app client id |
| `API_URL` | `http://127.0.0.1:8099` | Optional | Only for `scripts/verify_backend_contracts.ts` |

`make frontend API_URL=http://<host>:8000` passes `NEXT_PUBLIC_API_URL` to the build and overrides `.env.local`.

---

## 4. Root `Makefile` variables

Pass on the command line, e.g. `make backend BACKEND_PORT=9000`.

| Variable | Default | Used by |
|---|---|---|
| `AIML_HOST` | `0.0.0.0` | `make aiml-api` |
| `AIML_PORT` | `8100` | `make aiml-api` |
| `BACKEND_HOST` | `0.0.0.0` | `make backend` |
| `BACKEND_PORT` | `8000` | `make backend` |
| `API_URL` | empty | `make frontend` (becomes `NEXT_PUBLIC_API_URL`) |
| `HAWA_DATABASE_URL` | unset | `make db-update`, `make db-seed` (overrides `backend/.env`) |
| `UV` | `uv` | Python targets |
| `PNPM` | `pnpm` | Frontend targets |

If you change `AIML_PORT`, set `HAWA_AIML_SERVICE_URL` in `backend/.env` to match.

---

## 5. Flutter app: `--dart-define`

Compile-time values from `app_frontend/lib/app/env.dart`. Pass each with `--dart-define=NAME=value`, or put them in `app_frontend/env/<flavor>.json` for `make run` / `make apk` (`--dart-define-from-file`). For a shareable APK pass the backend URL directly: `fvm flutter build apk --release --flavor staging --dart-define=FLAVOR=staging --dart-define=API_BASE_URL=http://<backend-host>:8000` (or use `make app-apk`, which reads `app_frontend/env/staging.json`).

| Define | Default | What it does |
|---|---|---|
| `FLAVOR` | `dev` | Build flavour label (also pass `--flavor`) |
| `API_BASE_URL` | `http://10.0.2.2:8000` | Backend URL (`10.0.2.2` is the Android emulator's host alias) |
| `WS_URL` | `ws://10.0.2.2:8000/v1/ws` | WebSocket base. The Govt in Action radar connects to `${WS_URL}/fleet` (served); the task-event socket at `WS_URL` itself is not served yet. Use `wss://` behind HTTPS |
| `USE_FAKE_API` | `true` | Use the in-app fake backend for endpoints the backend does not serve |
| `REAL_FEATURES` | `air_map,citizen_air,alerts,school_forecast` | Features that always call the real backend, reads and writes alike. Add `citizen_reports` (photo upload, report submit, My reports), `citizen_subscription` (alert area) and `push` (FCM token registration) to use the backend for those while sign-in stays fake |
| `FAKE_FEATURES` | empty | Features forced onto the fake backend |
| `MAP_API_KEY` | empty | MapTiler key; empty uses the keyless Esri basemap |
| `MAP_TILE_URL` | MapTiler streets-v2 | Basemap tiles when a key is set |
| `MAP_ATTRIBUTION` | `© MapTiler © OpenStreetMap contributors` | Basemap attribution |
| `MAP_FALLBACK_TILE_URL` | Esri World Street Map | Keyless basemap |
| `MAP_FALLBACK_ATTRIBUTION` | Esri attribution | Keyless basemap attribution |
| `ROUTING_URL` | `https://routing.openstreetmap.de/routed-{profile}/route/v1/driving` | OSRM router for clean-air routes |
| `GEOCODING_URL` | `https://photon.komoot.io/api/` | Place search |
| `FIREBASE_API_KEY`, `FIREBASE_APP_ID`, `FIREBASE_MESSAGING_SENDER_ID`, `FIREBASE_PROJECT_ID` | empty | Firebase for this flavor's Android app (from its `google-services.json`; [AWS_SETUP_GUIDE.md §7](AWS_SETUP_GUIDE.md#7-firebase-cloud-messaging-and-its-secrets-manager-secret)). All four set = FCM and Crashlytics on; any empty = off (`lib/firebase/firebase_options_env.dart`) |
| `FIREBASE_STORAGE_BUCKET` | empty | Optional Firebase value |
| `FCM_TOPIC` | `hawa-alerts` | Topic every install subscribes to for broadcasts; must equal the backend's `HAWA_FCM_TOPIC` |
| `CRASH_REPORTING` | `false` | Crash reporting switch |
| `LOG_LEVEL` | `info` | App log level |
| `SHOW_DEV_TOOLS` | `true` | Settings → Dev tools |
| `ALERTS_CONTRACT` | `false` | Use the OpenAPI alerts contract instead of the backend's current shape |
| `OPEN_AIR_CONTRACT` | `false` | Use the OpenAPI open-air contract (GeoJSON) instead of the backend's current shape |


---

## 6. Fixed values (no variable)

| Where | Value |
|---|---|
| `backend/docker-compose.yml` Postgres | user `hawa`, password `hawa`, database `hawa`, port 5432 (matches the default `HAWA_DATABASE_URL`) |
| `backend/docker-compose.yml` Redis, Kafka | ports 6379, 9092 (set `HAWA_REDIS_URL=redis://localhost:6379/0` to use that Redis) |
| `frontend/package.json` | `pnpm dev` and `pnpm start` use port 3000 |
| `frontend/src/lib/visuals/hawa-gl.js` | basemap style (OpenFreeMap positron / dark) |

---

## 7. Recipes

### Local development (everything on one machine)

```bash
# backend/.env
WAQI_TOKEN=<your token>
OPENAQ_API_KEY=<your key>

# frontend/.env.local
NEXT_PUBLIC_API_URL=http://localhost:8000
```

Everything else can stay at its default.

### Server

```bash
# backend/.env
WAQI_TOKEN=<your token>
OPENAQ_API_KEY=<your key>
HAWA_JWT_SECRET=<long random string>
# HAWA_DATABASE_URL=postgresql+asyncpg://<user>:<password>@<host>:5432/<db>   # if not using `make db-up`

# AI-ML/.env (optional)
GROQ_API_KEY=<key>
NASA_FIRMS_MAP_KEY=<key>
OPENAQ_API_KEY=<key>
```

```bash
make frontend API_URL=http://<server-ip>:8000      # bakes the backend URL into the web build
```

Open ports 3000 (web) and 8000 (backend) in the security group. Keep 8100 (AI-ML) closed: only the backend calls it, and it has no authentication.

### AWS (EC2 + PM2, the full checklist)

Every value and where it comes from: [AWS_SETUP_GUIDE.md §13](AWS_SETUP_GUIDE.md#13-every-variable-in-one-table).

### Fully offline demo

```bash
# AI-ML/.env
OFFLINE_MODE=true
```

Leave `WAQI_TOKEN`, `OPENAQ_API_KEY` and `NEXT_PUBLIC_API_URL` unset: the backend uses its baseline stations and the web console runs on its built-in mock data.

---

## 8. Security notes

- Never commit `.env` or `.env.local`; they are gitignored. Only the `.env.example` templates are tracked.
- Earlier commits (`fec1f58`) contained hard-coded WAQI and OpenAQ keys in `backend/src/hawa_backend/core/intel_client.py`. They have been removed from the code but remain in git history: revoke them and use your own.
- `HAWA_JWT_SECRET` still has a development default in `core/config.py` and `.env.example`; set your own on any shared machine, together with `HAWA_ADMIN_API_KEY` and `HAWA_INGEST_API_KEY` (without them the officer and telemetry write routes are open).
- Secrets can live in AWS Secrets Manager instead of `.env`: `HAWA_AWS_SECRETS_ID` for backend variables, `HAWA_AWS_FCM_SECRET_ID` for the Firebase service account.
- On AWS, prefer an IAM role over static keys for both Bedrock (AI-ML) and the backend's AWS layer.

<!-- footer:start -->

---

[Back to top](#environment-variables) · [Docs hub](README.md) · [Project README](../README.md)

<!-- footer:end -->
