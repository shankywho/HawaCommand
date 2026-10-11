# AI-ML deployment

<!-- nav:start -->

**Navigate:** [Project](../../README.md) · [Docs hub](../README.md) · [Overview](../SYSTEM_OVERVIEW.md) · [AWS architecture](../AWS_ARCHITECTURE.md) · [AWS guide](../AWS_SETUP_GUIDE.md) · [API](../backend/API.md) · [Environment](../ENVIRONMENT_VARIABLES.md) · [Contracts](../CONTRACTS.md)

**AI-ML docs:** [Runbook](../../AI-ML/README.md) · [Index](README.md) · [Architecture](ARCHITECTURE.md) · [Models](MODELS.md) · [Agents](AGENTS.md) · [Data and training](DATA_AND_TRAINING.md) · [Engine API](../../AI-ML/CONTRACTS.md) · **Deployment**

<!-- nav:end -->

<p align="center">
<img src="https://img.shields.io/badge/runs-in%20the%20backend%20process-3776AB?logo=python&logoColor=white" alt="In process">
<img src="https://img.shields.io/badge/or-FastAPI%20%3A8100-009688?logo=fastapi&logoColor=white" alt="FastAPI 8100">
<img src="https://img.shields.io/badge/models-21%20LightGBM-02569B" alt="21 models">
<img src="https://img.shields.io/badge/LLM-Groq%20or%20Bedrock-01A88D?logo=amazonwebservices&logoColor=white" alt="LLM">
</p>

How the AI-ML engine (`AI-ML/`, package `hawa_ml`) runs in production.

---

## Modes

| Mode | When | How |
|---|---|---|
| **In process** (live) | Default | The backend imports `hawa_ml`; no extra process or port |
| **Separate service** | Isolate CPU-heavy work | `make aiml-api` on `127.0.0.1:8100`; the backend calls it first (`HAWA_AIML_SERVICE_URL`) and falls back to in process |
| **SageMaker / Step Functions** | Managed forecast | [AWS guide §16b](../AWS_SETUP_GUIDE.md#16b-sagemaker-or-step-functions-forecast) |

- One Python environment serves both: `backend/.venv` (`make install`).
- The backend image (`backend/Dockerfile`) already contains `AI-ML/` and pre-builds the grid.

---

## Steps (separate service on EC2)

1. `make install` from the repo root.
2. Build the grid once: `make aiml-data` (writes `AI-ML/data/processed/grid_covariates_*.parquet`).
3. Uncomment the `hawa-aiml` app in [`ecosystem.config.cjs`](../../infrastructure/ec2/ecosystem.config.cjs), then `pm2 start ... && pm2 save`.
4. Keep port **8100 closed** in the security group: only the backend calls it.
5. Verify: `curl http://127.0.0.1:8100/health`.

---

## Models and data

| Item | Where | Refresh |
|---|---|---|
| 21 forecaster models (1-72 h × P10/P50/P90) | `AI-ML/models/lgb_pm25_*.txt` (in git) | `cd AI-ML && make data && make train` |
| Attribution classifier | `AI-ML/models/attribution_classifier.txt` | same |
| 500 m and 1 km grids | `AI-ML/data/processed/` (generated) | `make aiml-data` |
| Rules and thresholds | `AI-ML/config/*.yaml` | edit and restart |

- Model cards: [forecaster](../../AI-ML/models/forecaster_model_card.md) · [attribution](../../AI-ML/models/attribution_model_card.md).
- Model files must keep LF line endings (`.gitattributes` enforces it).

---

## Configuration (`AI-ML/.env`)

| Variable | Effect |
|---|---|
| `LLM_PROVIDER` | `groq` or `bedrock`; anything else uses template text |
| `GROQ_API_KEY` | Groq agent text |
| `BEDROCK_MODEL_ID`, `AWS_REGION` | Bedrock agent text through the instance role ([AWS guide §16a](../AWS_SETUP_GUIDE.md#16a-bedrock-for-the-agents)) |
| `OPENAQ_API_KEY`, `NASA_FIRMS_MAP_KEY` | Real data for `scripts/fetch_all.py` |
| `OFFLINE_MODE` | `true` turns off every network call |

Full list: [environment variables](../ENVIRONMENT_VARIABLES.md#2-ai-ml-engine-ai-mlenv).

---

## Related

- [AI-ML architecture](ARCHITECTURE.md) · [Engine API](../../AI-ML/CONTRACTS.md) · [AI-ML runbook](../../AI-ML/README.md)

<!-- footer:start -->

---

[Back to top](#ai-ml-deployment) · [Docs hub](../README.md) · [Project README](../../README.md)

<!-- footer:end -->
