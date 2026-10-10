# AWS integration: handoff runbook

> **Status (2026-10-10).** The backend's AWS layer (`backend/src/hawa_backend/aws/`: `settings.py`, `clients.py`, `cache.py`, `forecast.py`, `dispatch.py`, `events.py`) is implemented and tested with `moto` (`backend/tests/aws/test_aws_integration.py`). It is off unless `HAWA_AWS_ENABLED=true`. `infrastructure/cloudformation/hawa-integration.yaml` creates:
> - the DynamoDB cache table (parameter `CacheTableName`)
> - the SNS alerts topic
> - the Kinesis sensor stream
> - a backend IAM managed policy
>
> Its outputs are `AlertsTopicArn`, `SensorStreamName` and `BackendPolicyArn`. The Step Functions state machines and the SageMaker endpoint are not in the template and must be created separately. Nothing has been deployed to a real account.


**Audience:** the engineer (and their AI coding agent) who is wiring HawaCommand to AWS.
**Read this first, then work top to bottom.** Everything below is verified against the code in this repo unless marked `UNTESTED` (nothing in this repo has ever run against a real AWS account; tests use `moto` mocks).

---

## 0. Ground rules

1. **Push straight to the `dev` branch. Do not open pull requests.**
2. **AWS stays optional.** `HAWA_AWS_ENABLED` defaults to `false`; with it off the backend must behave exactly as before. Do not remove the fallbacks (AI-ML HTTP -> in-process `hawa_ml` -> fixtures). A demo must survive an AWS or network failure.
3. **Never commit secrets** (`.env`, keys, ARNs with account ids are fine in docs, keys are not). Use IAM roles on AWS, not static keys.
4. Region: `ap-south-1` (Mumbai) unless a service is unavailable there (check Bedrock models, see Task 4).
5. After anything is deployed, **update the honesty statements** listed in section 11. The landing page currently says "Wired, not deployed".
6. Run the checks in section 12 before pushing.

## 1. What the product does (30-second context)

HawaCommand = Delhi air-pollution command centre.
`Sense -> Map -> Attribute -> Forecast -> Decide -> Act -> Verify`.

| Component | Path | Runs as |
|---|---|---|
| Backend API (FastAPI) | `backend/src/hawa_backend` | `uvicorn hawa_backend.api.app:app` on :8000 |
| AI-ML engine (models, optimiser, agents) | `AI-ML/src/hawa_ml` | imported **in-process** by the backend, or optionally its own FastAPI (`hawa_ml.api.main:app`) |
| Officer console + landing page (Next.js) | `frontend/` | `pnpm dev` / `pnpm build && pnpm start` on :3000 |
| Mobile app (Flutter) | `app_frontend/` | not part of the AWS work |

Data flow for the demo: frontend -> backend `/v1/*` -> `IntelClient` (`backend/src/hawa_backend/core/intel_client.py`) -> AI-ML.

**Be aware:** the trained models and station history are **synthetic data** (see `AI-ML/README.md` caveat). Alerts, devices, driver routes and impact come from fixtures in `backend/src/hawa_backend/api/fixtures.py`. That is expected for the hackathon; do not "fix" it as part of AWS work.

## 2. What exists today (code, already tested with moto)

Package `backend/src/hawa_backend/aws/`, all gated by `HAWA_AWS_ENABLED`:

| File | Function | AWS service | Used by |
|---|---|---|---|
| `settings.py` | `AwsSettings` (env prefix `HAWA_AWS_`) | n/a | all |
| `clients.py` | `get_client(service)`, `get_cache_table()` | boto3 (imported lazily; backend runs without boto3) | all |
| `cache.py` | `cache_get`, `cache_set` | DynamoDB | `forecast.py` |
| `forecast.py` | `get_aws_forecast(cell_id)` | Step Functions Express **or** SageMaker endpoint | route `GET /v1/forecast/{cell_id}` only |
| `dispatch.py` | `start_dispatch(plan)` | Step Functions (`StartExecution`) | route `POST /v1/plans/{id}/approve` |
| `events.py` | `publish_alert`, `publish_sensor_reading` | SNS, Kinesis | **no route calls these yet** |

Other pieces:
- `infrastructure/cloudformation/hawa-integration.yaml`: DynamoDB table, SNS topic, Kinesis stream, one IAM managed policy for the backend.
- `backend/tests/aws/test_aws_integration.py`: moto tests (DynamoDB, SNS, Kinesis, Step Functions start, route fallback).
- `AI-ML/src/hawa_ml/agents/llm_provider.py`: Groq / **Bedrock** / template fallback. Bedrock client exists (`LLM_PROVIDER=bedrock`). **Fixed in this branch:** it used to require static `AWS_ACCESS_KEY_ID`, which silently disabled Bedrock under an IAM role. It now relies on the default boto3 credential chain.
- `frontend/amplify.yml`: Amplify Hosting build spec (`appRoot: frontend`).

### Known limitation to design around
Plans are stored **in memory** in the backend (`_ACTIVE_PLANS` in `api/routes/plans.py`). Run the backend as **a single instance** (no autoscaling above 1, no scale-to-zero between demo steps), or plans vanish between requests.

## 3. Configuration reference

### Backend (`HAWA_` prefix, `backend/src/hawa_backend/core/config.py`)
| Env var | Default | Notes |
|---|---|---|
| `HAWA_JWT_SECRET` | an insecure dev string | **override in any deployment** (Secrets Manager) |
| `HAWA_AIML_SERVICE_URL` | `http://localhost:8100` | URL of a deployed AI-ML FastAPI, if you deploy it separately |
| `HAWA_AIML_TIMEOUT_SECONDS` | `10` | |

### AWS layer (`HAWA_AWS_` prefix, `backend/src/hawa_backend/aws/settings.py`)
| Env var | Default | Meaning |
|---|---|---|
| `HAWA_AWS_ENABLED` | `false` | master switch |
| `HAWA_AWS_REGION` | `ap-south-1` | |
| `HAWA_AWS_ENDPOINT_URL` | unset | LocalStack / moto |
| `HAWA_AWS_CACHE_TABLE` | `hawa-cache` | DynamoDB table, partition key `pk` (S). Attributes written: `value` (S, JSON), `ttl` (N, epoch). Enable DynamoDB TTL on `ttl`. |
| `HAWA_AWS_CACHE_TTL_SECONDS` | `3600` | |
| `HAWA_AWS_FORECAST_ENDPOINT` | unset | SageMaker endpoint name (see Task 2) |
| `HAWA_AWS_FORECAST_STATE_MACHINE_ARN` | unset | Express state machine; **wins over the endpoint if both set** |
| `HAWA_AWS_DISPATCH_STATE_MACHINE_ARN` | unset | Standard state machine started on plan approval |
| `HAWA_AWS_ALERTS_TOPIC_ARN` | unset | SNS topic for `publish_alert` |
| `HAWA_AWS_SENSOR_STREAM` | unset | Kinesis stream name for `publish_sensor_reading` |

### AI-ML (no prefix, `AI-ML/src/hawa_ml/settings.py`, reads `AI-ML/.env`)
`LLM_PROVIDER` (`groq` | `bedrock`), `BEDROCK_MODEL_ID` (default `anthropic.claude-3-5-sonnet-20241022-v2:0`), `AWS_REGION`, `GROQ_API_KEY`, `OFFLINE_MODE`.

### Frontend (`frontend/.env.local` or Amplify env vars)
`NEXT_PUBLIC_API_URL` (empty = built-in mock mode), `NEXT_PUBLIC_COGNITO_USER_POOL_ID`, `NEXT_PUBLIC_COGNITO_CLIENT_ID`.

## 4. Task list (suggested order)

Each task: **Goal / Spec / Verify.** Tick them off and update section 11 when done.

| # | Task | Required for demo? |
|---|---|---|
| 1 | Deploy base stack (table, topic, stream, policy) | yes |
| 2 | SageMaker forecast endpoint | yes (AWS Usage score) |
| 3 | Dispatch state machine | yes |
| 4 | Bedrock for the agents | yes |
| 5 | Host the backend | yes |
| 6 | Host the frontend (Amplify) | yes |
| 7 | Wire SNS alerts into a route | recommended |
| 8 | Cognito sign-in | optional |
| 9 | IoT Core -> Kinesis ingest | optional |
| 10 | CloudWatch + secrets | recommended |
| 11 | EventBridge schedule, S3/Timestream | optional |

### Task 1: base stack
- **Goal:** create DynamoDB cache table, SNS topic, Kinesis stream, backend IAM policy.
- **Spec:** `aws cloudformation deploy --template-file infrastructure/cloudformation/hawa-integration.yaml --stack-name hawa-integration --capabilities CAPABILITY_IAM --region ap-south-1`. Template outputs: `AlertsTopicArn`, `SensorStreamName`, `BackendPolicyArn`. The table already declares TTL on `ttl`.
- **Extend the template** (it is the right place) when you add the pieces below; keep it `cfn-lint` clean (`pip install cfn-lint && cfn-lint infrastructure/cloudformation/*.yaml`).
- **The backend policy must also allow** (it currently lacks these): `states:StartExecution` on the dispatch state machine (it only has `StartSyncExecution`), and `bedrock:InvokeModel`.
- **Verify:** `aws dynamodb describe-table --table-name hawa-cache` shows `TimeToLiveStatus: ENABLED`; `aws sns list-topics` lists `hawa-alerts`.

### Task 2: SageMaker forecast endpoint
- **Goal:** `GET /v1/forecast/{cell_id}` is computed by a SageMaker endpoint and cached in DynamoDB.
- **Contract the endpoint must satisfy** (`backend/src/hawa_backend/aws/forecast.py`):
  - Request body (JSON): `{"cell_id": "<string>"}`. Optional extras your handler may accept: `current_pm25`, `current_pm10`, `temp`, `rh`, `ws`, `wd`.
  - Response (JSON), **must contain a `horizons` list** or the backend ignores it:
    ```json
    {"cell_id": "C-1", "horizons": [
      {"horizon_h": 1, "valid_time": "...", "pm25_p10": 150.0, "pm25_p50": 200.0, "pm25_p90": 260.0,
       "pm10_p50": 330.0, "aqi_p50": 310, "aqi_category": "Very Poor",
       "grap_stage": "Stage II", "grap_stage_number": 2, "mandated_actions": ["..."]}
    ]}
    ```
    Horizons produced today: 1, 3, 6, 12, 24, 48, 72.
- **Recommended implementation** (do not rewrite the model code): reuse the repo's predictor, `hawa_ml.forecasting.predict.ForecastPredictor().predict_cell_forecast(cell_id, **kwargs)`. It returns exactly the list above.
  - Models are **tracked in git**: `AI-ML/models/lgb_pm25_{1,3,6,12,24,48,72}h_{p10,p50,p90}.txt` (21 files, 5.4 MB).
  - Packaging trick: `hawa_ml/settings.py` computes `BASE_DIR = Path(__file__).resolve().parents[2]`. If the model tarball is laid out as `models/*.txt`, `config/*.yaml` (copy `AI-ML/config/`), and `code/{inference.py, requirements.txt, hawa_ml/}` (copy `AI-ML/src/hawa_ml`), then `BASE_DIR` resolves to the tarball root and the predictor finds `models/` and `config/` without code changes.
  - `inference.py` needs the four SageMaker handler functions: `model_fn(model_dir)` (return a `ForecastPredictor`), `input_fn`, `predict_fn` (call `predict_cell_forecast`, wrap as `{"cell_id":..., "horizons": [...]}`), `output_fn` (`json.dumps`).
  - Container: the SageMaker scikit-learn framework image, with `lightgbm`, `pydantic`, `pydantic-settings`, `pyyaml` in `code/requirements.txt`. `UNTESTED`: confirm the exact image URI with `sagemaker.image_uris.retrieve("sklearn", "ap-south-1", "1.2-1")`. Use a **serverless** endpoint (`ServerlessInferenceConfig`, 3-4 GB) to keep cost near zero; first call is a cold start (tens of seconds), so warm it before a demo. The backend client has a 10 s read timeout and retries, then falls back.
- **Alternative that needs no SageMaker packaging:** deploy the existing AI-ML FastAPI (`hawa_ml.api.main:app`) as a second service and set `HAWA_AIML_SERVICE_URL`. `IntelClient` already calls it (`/hotspots`, `/forecast/{cell}`) with a circuit breaker and in-process fallback. Note this path carries the **hotspot list and per-hotspot forecasts**, which the SageMaker flag does not (see below).
- **Wiring note:** `HAWA_AWS_FORECAST_ENDPOINT` is only used by `GET /v1/forecast/{cell_id}`. The aggregated `GET /v1/forecast` and the per-hotspot forecasts in `/v1/hotspots` are built in `IntelClient` (`_aggregate_forecast`, `_cell_horizons`). If you want SageMaker to carry those, add an endpoint call inside `IntelClient._cell_horizons` (it already takes `cell_id` and returns the same `horizons` list).
- **Verify:**
  - Endpoint alone: invoke with `{"cell_id":"C-1"}`; response has 7 horizons.
  - Through the backend with `HAWA_AWS_ENABLED=true HAWA_AWS_FORECAST_ENDPOINT=<name>`: `curl -s localhost:8000/v1/forecast/C-1 | jq '.series|length'` prints `73`; the second call is served from DynamoDB: `aws dynamodb get-item --table-name hawa-cache --key '{"pk":{"S":"forecast:C-1"}}'` returns an item.

### Task 3: dispatch state machine
- **Goal:** approving a plan starts a real Step Functions execution and returns its ARN.
- **Backend side is done** (`aws/dispatch.py`). It calls `StartExecution` with input `{"planId", "ward", "window": {start,end,label}, "groups": [...]}` and puts the real ARN in the approve response as `executionArn`. With the env var unset, `executionArn` is absent (never fake).
- **You create:** a **Standard** state machine. Suggested states: (1) DynamoDB `PutItem` into `hawa-cache` with `pk = "dispatch:<planId>"` (no `ttl` attribute needed; the cache reader only looks at `forecast:*` keys); (2) SNS `Publish` of the plan to the alerts topic (this is how drivers/schools get notified); end. Use the optimised integrations `arn:aws:states:::dynamodb:putItem` and `arn:aws:states:::sns:publish`.
- **IAM:** a state-machine role allowing `dynamodb:PutItem` on the table and `sns:Publish` on the topic. Put it in the CloudFormation template.
- **Verify:** `curl -s -X POST localhost:8000/v1/plans/214/approve -H 'content-type: application/json' -d '{}' | jq .executionArn` prints an ARN starting `arn:aws:states:`; then `aws stepfunctions describe-execution --execution-arn <arn>` reports `SUCCEEDED`.
- Plan 214 is a seeded demo plan; `POST /v1/plans/draft` makes new ones. Restarting the backend resets plan state.

### Task 4: Bedrock for the agents
- **Goal:** Planner/Auditor/Forecaster/Communicator agents use Bedrock instead of Groq.
- **Spec:** set `LLM_PROVIDER=bedrock`, `AWS_REGION`, and `BEDROCK_MODEL_ID` on the process that runs `hawa_ml` (the backend, since it runs AI-ML in-process; or the AI-ML service). Enable model access in the Bedrock console for that region. Check which model IDs exist: `aws bedrock list-foundation-models --region <r> --query "modelSummaries[].modelId"`. The default ID may not be offered in `ap-south-1`; if so, use a cross-region **inference profile ID** from `aws bedrock list-inference-profiles`.
- **IAM:** the runtime role needs `bedrock:InvokeModel`.
- **Behaviour:** if Bedrock fails, the client logs a warning and returns an empty string, and the agents use their deterministic template text. So a misconfiguration is **silent**; always verify with the log line `Initializing Amazon Bedrock client...` and a real response.
- **Verify:** with the env set, `python -c "from hawa_ml.agents.llm_provider import llm_client; print(type(llm_client).__name__, llm_client.generate('Say OK'))"` prints `BedrockLLMClient OK`.

### Task 5: host the backend
- **Needs:** a container (there is **no Dockerfile in the repo**). The image must install **both** Python packages:
  `pip install -e backend/contracts -e "backend[aws]" -e AI-ML -r AI-ML/requirements.txt`, and on a slim base add `libgomp1` (LightGBM). Build context = repo root.
- **Run command:** `uvicorn hawa_backend.api.app:app --host 0.0.0.0 --port 8000` (if the packages are not installed editable, set `PYTHONPATH=backend/src:backend/contracts`). Health check path: `/healthz`.
- **Data in the image:** `AI-ML/data/processed/` is gitignored; the 500 m grid is regenerated at runtime if missing (`twin/grid.py: load_grid`), so the first hotspot request is slower. Models are in the image because they are tracked.
- **Hosting options:** App Runner (simplest; set max instances = 1) or ECS Fargate (desired count = 1). Give the service an **instance/task role** attached to the backend policy from task 1; do not use static keys.
- **CORS** is already `*` in `api/app.py`. Tighten to the Amplify domain if time allows.
- **Verify:** `curl https://<service-url>/healthz` -> `{"status":"ok"}`; `curl https://<service-url>/v1/hotspots | jq '.items|length'` -> `10`.

### Task 6: host the frontend
- **Spec:** Amplify Hosting, connect the repo, branch `dev`, build spec `frontend/amplify.yml` (already set, `appRoot: frontend`, pnpm). Environment variable `NEXT_PUBLIC_API_URL=https://<backend-url>` (**must be set at build time**; it is inlined into the bundle). Add `NEXT_PUBLIC_COGNITO_*` only if task 8 is done.
- **Verify:** open the Amplify URL; `/map` shows hotspots and the header chip shows a real PM2.5 value; with the backend stopped the pages show an error, not fake data.

### Task 7: wire SNS alerts into a route (recommended)
- `publish_alert(message: dict, **attributes)` exists but nothing calls it. The simplest high-value wiring is in `backend/src/hawa_backend/api/routes/plans.py` `approve_plan`, right after `start_dispatch`: publish a short alert (plan id, ward, window, number of tasks) so subscribers get an SMS/email on approval. The dispatch state machine may already publish; pick **one** place so alerts are not sent twice.
- Subscribe an email or SMS number to the topic to demo it: `aws sns subscribe --topic-arn <arn> --protocol email --notification-endpoint <addr>`, then confirm. SMS in India needs sender registration; email is the safe demo choice.
- **Verify:** approve a plan; the subscriber receives the message.

### Task 8: Cognito (optional)
- Create a user pool (admin-created users only) and an app client **without a secret**, SRP auth. Set `NEXT_PUBLIC_COGNITO_USER_POOL_ID` and `NEXT_PUBLIC_COGNITO_CLIENT_ID`. The console then shows a sign-in page.
- **Important limitation:** the frontend signs in and sends the Cognito ID token as a bearer token, but **the backend does not verify it**: no route has an auth dependency. Say so honestly in the demo. Enforcing it = a JWT dependency on the routers, or an API Gateway authorizer in front of the backend.

### Task 9: IoT Core -> Kinesis ingest (optional)
- IoT Rule `SELECT * FROM 'hawa/telemetry/#'` with a Kinesis action to the sensor stream (partition key `${topic(3)}`), plus an IAM role for IoT to `kinesis:PutRecord`. Test with `aws iot-data publish --topic hawa/telemetry/pod-1 --payload ...`.
- **Gap:** there is no consumer. Nothing reads the stream into the backend. Either add a small Lambda that forwards records to the backend/AI-ML ingest (`AI-ML` has `POST /ingest/telemetry`), or state that ingest stops at Kinesis.

### Task 10: CloudWatch and secrets (recommended)
- App Runner/ECS ship logs to CloudWatch Logs automatically. Add an alarm on the backend 5xx count and on Step Functions `ExecutionsFailed`.
- Put `HAWA_JWT_SECRET`, `GROQ_API_KEY` (if still used) in Secrets Manager and inject them as service secrets.

### Task 11: optional extras
- EventBridge Scheduler to call `POST /v1/plans/draft` every 3 hours (the landing page says "new plan every 3 hours"; nothing schedules it today).
- S3 for model artifacts (needed for task 2 anyway). Timestream and an S3 open-data export are **not implemented**; do not claim them.

## 5. End-to-end acceptance test (run after tasks 1-6)

1. `GET /healthz` on the hosted backend -> `ok`.
2. Open the Amplify URL, `/map`: hotspots load, timeline works.
3. `/forecast`: GRAP stage banner with a probability and a "Stage N checklist" that expands real actions.
4. `/plans`: open the plan, click **Approve & dispatch**. A toast appears; the response has a real `executionArn`; Step Functions shows `SUCCEEDED`; the SNS subscriber gets a message.
5. DynamoDB `hawa-cache` contains `forecast:*` items after hitting `/v1/forecast/{cell}` twice.
6. Bedrock: an agent-written sentence appears (not the template text) and the log shows the Bedrock init line.
7. With `HAWA_AWS_ENABLED=false`, everything still works (the fallback requirement).

## 6. Gotchas found while building (save yourself the debugging)

- Bedrock failure is silent by design (template fallback). See task 4.
- Backend plan store is in memory: one instance only.
- `HAWA_AWS_FORECAST_STATE_MACHINE_ARN` beats the endpoint when both are set.
- DynamoDB TTL deletion is lazy; the cache reader checks `ttl` itself, so expired items are never served.
- `AI-ML` tests rewrite a few tracked JSON files in `AI-ML/data/` (timestamp churn). Run `git checkout -- AI-ML/data` before committing.
- The `grap_stage` the AI-ML engine returns uses an AQI that includes an *estimated* PM10, so it can read one stage higher than PM2.5 alone. The backend's forecast route derives the stage from PM2.5 thresholds (`GRAP_STAGE_MIN` in `intel_client.py`, from `AI-ML/config/grap.yaml`) so the stage and probability agree. Keep that consistent.
- Service-level cold starts (SageMaker serverless, App Runner scale-from-zero) make the first demo request slow; send a warm-up request first.

## 7. How to run things locally

```bash
# one-time: Python 3.11, then from the repo root
pip install -e backend/contracts -e "backend[dev,aws]" -e "AI-ML[dev]" -r AI-ML/requirements.txt \
  "moto[dynamodb,sns,kinesis,stepfunctions]" cfn-lint

# backend (from backend/)
PYTHONPATH=src:contracts uvicorn hawa_backend.api.app:app --port 8000

# backend with AWS on (example)
HAWA_AWS_ENABLED=true HAWA_AWS_REGION=ap-south-1 HAWA_AWS_FORECAST_ENDPOINT=<name> \
HAWA_AWS_DISPATCH_STATE_MACHINE_ARN=<arn> HAWA_AWS_ALERTS_TOPIC_ARN=<arn> \
PYTHONPATH=src:contracts uvicorn hawa_backend.api.app:app --port 8000

# frontend (from frontend/), pointing at the backend
echo 'NEXT_PUBLIC_API_URL=http://localhost:8000' > .env.local && pnpm install && pnpm dev
```

## 8. Tests

```bash
cd backend && pytest                 # 60+ tests; AWS ones use moto
cd AI-ML && pytest                   # 38 tests
cd frontend && pnpm exec tsc --noEmit
cd frontend && API_URL=http://127.0.0.1:8000 pnpm dlx tsx scripts/verify_backend_contracts.ts   # all 14 endpoints vs the frontend schemas
```
The moto tests **stub** SageMaker and Step Functions *sync* execution (moto cannot run them), so tasks 2 and 3 are only truly verified by the real-AWS checks above.

## 9. Files you will most likely touch

| Goal | File |
|---|---|
| New AWS behaviour | `backend/src/hawa_backend/aws/*.py` |
| Approve/draft plan routes | `backend/src/hawa_backend/api/routes/plans.py` |
| Forecast routes | `backend/src/hawa_backend/api/routes/forecast.py` |
| Hotspot/forecast building | `backend/src/hawa_backend/core/intel_client.py` |
| Infrastructure | `infrastructure/cloudformation/hawa-integration.yaml` |
| LLM provider | `AI-ML/src/hawa_ml/agents/llm_provider.py` |
| AWS settings | `backend/src/hawa_backend/aws/settings.py` |
| Tests | `backend/tests/aws/test_aws_integration.py` |

## 10. Things that are NOT implemented (do not claim them)

Cognito token verification on the backend; IoT Core and any consumer of the Kinesis stream; Timestream; S3 open-data export; EventBridge schedule; Lambda functions; Dockerfile; SageMaker packaging script; the forecast and dispatch state-machine definitions; any CloudWatch dashboards.

## 11. After you deploy: update these honesty statements

1. `frontend/src/app/(marketing)/sections/Aws.tsx`: the `TOWER` list has a status per layer (`built | wired | planned | simulated`) and the paragraph says "not deployed yet". Change both to match reality.
2. This doc: move finished items out of section 10 and note the real resource names.
3. `AI-ML/README.md`: its benchmark claims describe real CPCB data; the data in this repo is synthetic. Label it, or retrain on real data.
4. `docs/AWS_INTEGRATION.md` section 2 table: mark which routes now use AWS.

## 12. Before you push

- Backend and AI-ML tests pass, `tsc` is clean, contract script passes.
- `git checkout -- AI-ML/data` (test churn).
- No `.env`, keys or tokens in the diff.
- Push to `dev` (no PR).
