# Team Remaining Work, Task Checklist, and Role-Specific Prompts

Remaining integration, correctness and production-hardening work for each discipline, reconciled with the code at commit `a33e043` (2026-10-10). Every path below exists in the repository unless the task is to create it.

Each section contains:
1. Role ownership
2. Prioritised checklist (correctness first, then integration, then scale)
3. An execution prompt for an AI assistant or engineer

How to run the stack locally: [root README](../README.md#local-development-and-setup). Known defects per component: [AI-ML](../AI-ML/README.md#9-known-issues), [backend](../backend/README.md#known-issues), [web](frontend/README.md), [app](app/README.md#9-known-issues).

---

## 0. Cross-cutting (whoever gets there first)

- [ ] Remove the hard-coded WAQI and OpenAQ tokens from `backend/src/hawa_backend/core/intel_client.py` (lines 200, 246), rotate both tokens, and read them through `core/config.py` settings.
- [ ] Declare `hawa-ml` as a backend dependency (`backend/pyproject.toml`, path dependency on `../AI-ML`).
- [ ] Change `AI-ML/Makefile` `api` target to port 8100 and `test` to `python -m pytest`.
- [ ] Make the AI-ML tests hermetic: stop them rewriting `AI-ML/data/fixtures/demo_scenario.json` and the three files in `AI-ML/data/internal/`.
- [ ] Add CI (`.github/workflows/`) per folder: `python -m pytest` for AI-ML, `pytest` for backend, `pnpm typecheck && pnpm build` for web, `make lint test` for Flutter.

---

## 1. Cloud and DevOps Engineer

### Role Responsibilities
AWS infrastructure, deployment of the two Python services and the web console, secrets, monitoring.

### Task Checklist
- [ ] Deploy `infrastructure/cloudformation/hawa-integration.yaml` in `ap-south-1` and wire its outputs into the backend `HAWA_AWS_*` variables (see [CLOUD_ENGINEER_INTEGRATION_CHECKLIST.md](CLOUD_ENGINEER_INTEGRATION_CHECKLIST.md)).
- [ ] Write Dockerfiles for `backend/` (must also install `../AI-ML`) and `AI-ML/` (Planned: none exist).
- [ ] Run both services on ECS Fargate behind an ALB with TLS; the backend reaches AI-ML through `HAWA_AIML_SERVICE_URL`.
- [ ] Host `frontend/` on Amplify (`frontend/amplify.yml` exists) with `NEXT_PUBLIC_API_URL` pointing at the ALB.
- [ ] Move `WAQI_TOKEN`, `OPENAQ_API_KEY`, `NASA_FIRMS_MAP_KEY`, `GROQ_API_KEY` into Secrets Manager.
- [ ] CloudWatch alarms on API 5xx rate and AI-ML latency.
- [ ] Planned, only once the backend uses them: RDS PostgreSQL + PostGIS, ElastiCache Redis, MSK.

### Execution Prompt for Cloud Engineer
```text
You are the Lead Cloud and DevOps Engineer for HawaCommand (ap-south-1).

Read docs/AWS_INTEGRATION.md, docs/CLOUD_ENGINEER_INTEGRATION_CHECKLIST.md,
infrastructure/cloudformation/hawa-integration.yaml and backend/src/hawa_backend/aws/.

1. Validate and deploy infrastructure/cloudformation/hawa-integration.yaml; map every output
   to the HAWA_AWS_* settings in backend/src/hawa_backend/aws/settings.py.
2. Add Dockerfiles for backend/ (installing ./contracts and ../AI-ML) and AI-ML/ (uvicorn
   hawa_ml.api.main:app on port 8100), and an ECS Fargate service for each behind an ALB.
3. Configure frontend/amplify.yml hosting with NEXT_PUBLIC_API_URL set to the backend URL.
4. Store WAQI_TOKEN, OPENAQ_API_KEY, NASA_FIRMS_MAP_KEY and GROQ_API_KEY in Secrets Manager
   and inject them as environment variables.
Deliver the templates and the commands used to validate them.
```

---

## 2. AI / ML Engineer

### Role Responsibilities
`AI-ML/`: digital twin, forecaster, attribution, exposure, optimiser, causal verifier, agents.

### Task Checklist
- [ ] Fix AQI gaps between integer breakpoints returning 500 (`AI-ML/src/hawa_ml/forecasting/grap.py:41-52`).
- [ ] Fix the effectiveness-library key mismatch (`sprinkler` vs `water_sprinkler`) so verified effects reach the optimiser (`attribution/rules.py`, `optimization/greedy.py:64`, `causal/placebo.py:144`).
- [ ] Forecast inference: build real lag and rolling features per cell instead of filling them from one value (`forecasting/predict.py`).
- [ ] Training: select the latest hours, not the last stations alphabetically (`forecasting/train.py:37-39`).
- [ ] Digital twin: the committed leave-one-station-out run (`reports/twin_metrics.json`) loses to nearest-station and IDW; tune the kernel on real CPCB data with more than 3 stations.
- [ ] `/twin`, `/hotspots`, `/insights`: use real observations instead of hard-coded points or synthetic PM fields (`api/routes.py`).
- [ ] Replace the constant What-If baseline (`optimization/whatif.py:35-36`) with a simulated fixed-route plan.
- [ ] Implement OR-Tools CVRP in `optimization/vrp.py` (it currently always runs the greedy solver) and add `ortools` to the dependencies.
- [ ] Verification route: verify the requested intervention instead of replaying the seeded test (`api/routes.py`, `pipelines/verify.py`).
- [ ] Add `boto3` to the dependencies so the Bedrock provider can load.
- [ ] Regenerate `reports/` figures and the PDF from the metrics files instead of hard-coded numbers.

### Execution Prompt for AI/ML Engineer
```text
You are the Principal AI/ML Engineer for HawaCommand, working in AI-ML/.
Read AI-ML/README.md (sections 1, 7 and 9) first.

1. In src/hawa_ml/forecasting/grap.py, make AQI sub-index interpolation continuous across
   CPCB breakpoint gaps; add tests for 30.5, 60.5 and 250.5 ug/m3.
2. In src/hawa_ml/optimization/greedy.py and src/hawa_ml/attribution/rules.py, align the
   asset keys with src/hawa_ml/causal/effectiveness_library.py so verified effects are used.
3. In src/hawa_ml/forecasting/predict.py, compute lag/rolling features from the cell's recent
   series; in src/hawa_ml/forecasting/train.py, hold out the latest 45 days across all stations.
4. In src/hawa_ml/twin/kriging.py, re-run evaluate_leave_one_station_out on real CPCB data and
   report skill against nearest-station and IDW in reports/twin_metrics.json.
5. In src/hawa_ml/optimization/vrp.py, implement an OR-Tools CVRP with time windows and keep
   greedy.py as the fallback.
Run `python -m pytest -q` from AI-ML/ and restore AI-ML/data with git afterwards.
```

---

## 3. Backend Engineer

### Role Responsibilities
`backend/`: FastAPI routes, AI-ML bridge, persistence, auth, events.

### Task Checklist
- [ ] Fix `delta_gain_pct` handling in `core/intel_client.py` (lines 933, 977) to read AI-ML's `comparison.gain_percentage`.
- [ ] Make `/readyz` check real dependencies (`api/routes/health.py`).
- [ ] Persist plans (currently an in-process dict in `api/routes/plans.py`) using the SQLAlchemy models in `db/models/`; add Alembic.
- [ ] Add auth endpoints and enforce JWT with role scoping (`core/security.py` has the helpers).
- [ ] Serve the field API the Flutter app expects (`app_frontend/openapi/openapi.json`): `/v1/auth/*`, `/v1/me`, `/v1/tasks*`, `/v1/inspections*`, `/v1/reports*`, `/v1/uploads/presign`, `/v1/ws`.
- [ ] Raise `HawaException` subclasses from routes so clients get RFC 9457 bodies.
- [ ] Replace fixture routes (`/v1/devices`, `/v1/alerts`, `/v1/driver/route`, `/v1/citizen/live-operations`, `/v1/citizen/wards/leaderboard`) with real data.
- [ ] Fix or update `tests/integration/test_end_to_end.py::test_full_mission_air_pipeline`.
- [ ] Planned: Kafka producers/consumers and outbox relay, Redis cache and rate limits, WebSocket.

### Execution Prompt for Backend Engineer
```text
You are the Senior Backend Engineer for HawaCommand, working in backend/.
Read backend/README.md and docs/backend/README.md first. Install with
`pip install -e contracts -e ".[dev]" -e ../AI-ML` and run tests with `pytest -q`.

1. In src/hawa_backend/core/intel_client.py, read WAQI_TOKEN and OPENAQ_API_KEY from settings
   (no hard-coded defaults) and fix the What-If response mapping (delta_gain_pct).
2. In src/hawa_backend/api/routes/plans.py, persist plans with the SQLAlchemy models in
   src/hawa_backend/db/models/plan.py; add Alembic migrations for all models.
3. Add /v1/auth/otp/request, /v1/auth/otp/verify and /v1/me using src/hawa_backend/core/security.py,
   and require a bearer token on /v1/plans/* writes.
4. Make tests/integration/test_end_to_end.py pass and add tests for every new route.
```

---

## 4. Mobile App Engineer (Flutter)

### Role Responsibilities
`app_frontend/`: one app for drivers, inspectors, school principals, citizens and site managers.

### Task Checklist
- [ ] Fix the two legacy tests that import `hawacommand_app` (`test/data_mapping_test.dart`, `test/i18n_test.dart`) or delete them, so `make test` compiles.
- [ ] Commit `env/dev.json.example` (and fix the root `.gitignore` `env/` rule that hides it) so `make run` works.
- [ ] Declare the air-map fixtures as assets so the offline fallback loads (`pubspec.yaml`, `lib/features/air_map/data/air_map_remote_source.dart`).
- [ ] Fix the broken routes for "Flag Missed Machine" and the citizen "72-Hour AI Air Forecast" tile (`lib/features/citizen_air/presentation/air_near_me_screen.dart`).
- [ ] Move the four citizen screens off the legacy `lib/app/theme.dart`.
- [ ] Call the backend's existing `/v1/citizen/safe-route`, `/live-operations`, `/wards/leaderboard` and `/reports/missed-machine` instead of hard-coded data.
- [ ] Fix multi-photo inspection close ordering (`lib/features/inspector/data/inspector_repository_impl.dart:229`).
- [ ] Switch features from the fake backend to `REAL_FEATURES` as the backend ships each field endpoint.

### Execution Prompt for Mobile App Engineer
```text
You are the Lead Mobile Engineer for the HawaCommand Flutter app in app_frontend/.
Read app_frontend/README.md and docs/app/README.md (section 9, Known issues) first.

1. Make `make lint test` pass: fix or remove test/data_mapping_test.dart and test/i18n_test.dart.
2. Add env/dev.json.example with FLAVOR, API_BASE_URL, USE_FAKE_API and REAL_FEATURES.
3. Declare assets/fixtures/air_map/ in pubspec.yaml and confirm the air map works offline.
4. In lib/features/citizen_air/, wire safe_route_screen.dart, live_operations_screen.dart and
   ward_scorecard_screen.dart to the backend's /v1/citizen/* endpoints.
5. In lib/features/inspector/data/inspector_repository_impl.dart, make inspection_close depend
   on every photo_upload op.
Provide `make lint test` output and a release APK build log.
```

---

## 5. Web Frontend Engineer

### Role Responsibilities
`frontend/`: Next.js officer console, landing page, driver view.

### Task Checklist
- [ ] Commit an ESLint config so `pnpm lint` runs non-interactively; add Prettier if wanted.
- [ ] Feed the map's truck routes, bus trails, schools and suspect pin from the API instead of built-in demo data (`src/components/map/`, `src/lib/visuals/hawa-gl.js`).
- [ ] Fix the What-If delta sign mismatch between backend and mocks.
- [ ] Replace fixed copy on `/forecast` (day and plan link) and `/fleet` (last-packet age).
- [ ] Add a sign-out control and send the Cognito token to the backend once it verifies tokens.
- [ ] Planned: WebSocket live updates, deck.gl layers, `/open` public data portal, alert compose.

### Execution Prompt for Web Frontend Engineer
```text
You are the Senior Frontend Engineer for HawaCommand in frontend/.
Read frontend/README.md and docs/frontend/README.md first.

1. Add an ESLint flat config (next, typescript-eslint, react-hooks, jsx-a11y) and make
   `pnpm lint`, `pnpm typecheck` and `pnpm build` pass.
2. In src/app/(console)/map/ and src/components/map/HawaMap.tsx, render hotspots, assets and
   suspect pins from /v1/hotspots and /v1/devices instead of the component's demo data.
3. In src/app/(console)/what-if/page.tsx, align the delta sign with the backend's compare response.
4. Run scripts/verify_backend_contracts.ts against a local backend and keep it passing.
```
