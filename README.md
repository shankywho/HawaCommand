# HawaCommand

**An AI command centre that finds, forecasts and fixes Delhi's pollution hotspots, street by street, and proves every fix worked.**

Environmental Hacks 2026 · Bharat Builds Tour · Track 01: Air

Delhi already owns the machines: 376 anti-smog guns, 266 sprinklers and 91 mechanised sweepers. What it lacks is a way to point them at the right street at the right hour, and a way to tell whether a spray run cleaned the air. HawaCommand is that brain.

## The loop

```
 Sense → Map → Attribute → Forecast → Decide → Act → Verify ─┐
   ▲                                                         │
   └───────── what worked feeds the next plan ◄──────────────┘
```

| Step | What it does |
|---|---|
| Sense | Low-cost sensors on vehicles and schools, official stations, weather and satellite fire data |
| Map | A 500 m digital twin fills the gaps between sensors and gives every cell a value and a confidence |
| Attribute | Each hotspot gets a likely cause (dust, traffic, burning, regional smoke) and an upwind suspect location |
| Forecast | 72-hour forecast per cell with P10/P50/P90 and the GRAP stage it would trigger, 24–48 h ahead |
| Decide | An exposure-first optimiser proposes routes; Planner and Auditor agents explain and challenge the plan; an officer approves |
| Act | Routes to drivers, targets to inspectors, warnings with a safe window to schools and citizens |
| Verify | A synthetic control built from similar untreated cells measures the true effect of each intervention |

## What is in this repo

| Folder | What it is |
|---|---|
| [`frontend/`](frontend) | Next.js officer console (map, forecast, plans, what-if, impact, fleet, alerts) and the public landing page |
| [`backend/`](backend) | FastAPI service: REST API, plan approval, alerts, open data (`/open/v1/air`), optional AWS integration |
| [`AI-ML/`](AI-ML) | The engine: digital twin, LightGBM quantile forecaster, exposure ranking, OR-Tools dispatch, causal verification, LLM agents |
| [`app_frontend/`](app_frontend) | Flutter app for drivers, inspectors, schools and citizens |
| [`infrastructure/`](infrastructure) | CloudFormation for the AWS pieces |
| [`docs/`](docs) | System overview, contracts, per-part documentation, AWS runbook |

## Run it locally

You need Python 3.11+, Node 20+ and pnpm. Open three terminals.

```bash
# 1. AI-ML engine on :8100
cd AI-ML
python3 -m venv .venv && source .venv/bin/activate
pip install -e . && pip install -r requirements.txt
uvicorn hawa_ml.api.main:app --port 8100
```

```bash
# 2. Backend on :8000 (talks to the engine on :8100)
cd backend
python3 -m venv .venv && source .venv/bin/activate
pip install -e contracts && pip install -e .
uvicorn hawa_backend.api.app:app --port 8000
```

```bash
# 3. Website on :3000
cd frontend
pnpm install
echo "NEXT_PUBLIC_API_URL=http://localhost:8000" > .env.local
pnpm dev
```

Open http://localhost:3000 for the landing page and http://localhost:3000/map for the console. With `NEXT_PUBLIC_API_URL` empty the console runs on built-in mock data.

Tests: `pytest` inside `backend/` and `AI-ML/`. Website: `pnpm exec tsc --noEmit` inside `frontend/`.

## What is real and what is simulated

We want this to be easy to judge fairly.

- **Real:** the models, the optimiser, the causal verifier, the API and the console all run end to end.
- **Simulated:** sensor readings, station history and interventions come from a synthetic data generator, and the sensor fleet is simulated by a program that emits the same packets a real pod would. Alerts, devices and driver routes are backend fixtures. Plans are held in memory on a single backend instance.
- **Optional AWS layer:** DynamoDB cache, SageMaker and Step Functions calls, SNS alerts and Kinesis publishing sit behind one flag (`HAWA_AWS_ENABLED`). Everything falls back cleanly when it is off. See [`docs/AWS_INTEGRATION.md`](docs/AWS_INTEGRATION.md) for the deployment runbook and current status.

## More

- [System overview](docs/SYSTEM_OVERVIEW.md) and [contracts](docs/CONTRACTS.md)
- [AWS integration runbook](docs/AWS_INTEGRATION.md)
- [Proposal](HawaCommand_Proposal.pdf)
