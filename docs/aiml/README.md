# HawaCommand AI-ML

Index and entry point for everything the `AI-ML/` folder owns: models, optimiser, verifier, agents, and the processes that run them.

Related: [CONTEXT](CONTEXT.md) · [ARCHITECTURE](ARCHITECTURE.md) · [STRUCTURE](STRUCTURE.md) · [MODELS](MODELS.md) · [AGENTS](AGENTS.md) · [DATA_AND_TRAINING](DATA_AND_TRAINING.md) · [PLAN](PLAN.md) · [../CONTRACTS.md](../CONTRACTS.md) · [../SYSTEM_OVERVIEW.md](../SYSTEM_OVERVIEW.md)

---

## 1. What AI-ML owns

AI-ML is the "Think" and "Decide" layers of HawaCommand (§9.1). It turns cleaned readings into state and state into a plan, and it proves whether each action worked. Concretely, it owns: drive-by calibration of low-cost sensors (F3); the 500 m digital twin with a confidence value per cell (F4); hotspot detection, source fingerprinting and back-trajectory (F7); the 72 h P10/P50/P90 forecaster (F5) and GRAP outlook (F6); the exposure engine (F12); the OR-Tools dispatch optimiser and What-If simulator (F13); the Strands multi-agent command room on Amazon Bedrock (F14) and the Communicator that writes pollutant-specific alerts (F16); synthetic-control causal verification and the Intervention Effectiveness Library (F18); plus the STRETCH/VISION items: anti-gaming guard (F15), active sensing router (F11), site compliance score (F9), school safe-window scheduler (F19), Citizen Eyes photo verification (F20), evidence narrative (F22), power-proxy (F10) and HawaEye/TinyML edge models (F8, spike detector). AI-ML never changes the database schema (backend Alembic owns DDL), writes only the tables listed for it in [CONTRACTS §8](../CONTRACTS.md#8-database-table-ownership), and is reached only through Kafka `hawa.cmd.*` topics and a small internal HTTP service. Every output carries its uncertainty and its `model_version`.

## 2. Reading order

| # | Document | Read it when | Lines (approx.) |
|---|---|---|---|
| 1 | [CONTEXT.md](CONTEXT.md) | First. Problem, what ML does in each loop step, data realities, honesty rule, KPIs, non-goals | ~170 |
| 2 | [ARCHITECTURE.md](ARCHITECTURE.md) | Before writing any process code. Processes, topics, tables, Redis keys, sequences, failure modes, observability, **proposed contract additions** | ~600 |
| 3 | [STRUCTURE.md](STRUCTURE.md) | Before creating files. Full folder tree and tooling | ~430 |
| 4 | [MODELS.md](MODELS.md) | When building any algorithm. Inputs, outputs, maths, defaults, metrics, fallbacks, tests | ~1200 |
| 5 | [AGENTS.md](AGENTS.md) | When building `hawa_agents`. Orchestration, full system prompts, tool schemas, Pydantic outputs, guardrails, eval suite | ~1050 |
| 6 | [DATA_AND_TRAINING.md](DATA_AND_TRAINING.md) | When acquiring data or training. Sources, licences, grid, feature store, simulator contract, splits, MLflow, gates | ~250 |
| 7 | [PLAN.md](PLAN.md) | To schedule work. Hour-by-hour hackathon plan, milestones with acceptance criteria, cut rules, pilot roadmap | ~150 |

AI coding agents: read `CONTEXT` → `ARCHITECTURE` → `STRUCTURE`, then the `MODELS`/`AGENTS` section for your module.

## 3. Processes at a glance

| Process | Entry point | Role |
|---|---|---|
| `intel-worker` | `uv run intel-worker --groups <list>` | aiokafka consumer groups: `intel-twin`, `intel-twin-live`, `intel-forecast`, `intel-plan`, `intel-verify`, `intel-verify-scheduler`, `intel-spike`, `intel-attribution`, `intel-vision`, `intel-trainer` (+ proposed `intel-report`) |
| `intel-service` | `uv run intel-service` | Internal FastAPI: `/internal/v1/simulate`, `/optimize`, `/exposure`, `/models`, `/healthz` |
| `trainer` | `uv run hawa-trainer run --model <name>` | Nightly and on-demand training, evaluation, promotion gates, MLflow registry |
| `hawa_agents` | library | Strands agents (Forecaster, Planner, Auditor, Communicator, Citizen Eyes verifier) called by `intel-worker` and `intel-service` |

## 4. Quick start

Prerequisites: Python 3.12, [`uv`](https://docs.astral.sh/uv/), Docker. The whole local stack (Postgres + PostGIS, Redis, Kafka, Schema Registry, MinIO, MLflow, Jaeger, Prometheus) is started from the repo root by the backend's compose file.

```bash
# 0. From the repo root: bring up shared infrastructure and apply backend migrations
make up            # docker compose up -d (backend-owned)
make seed          # grid, wards, POIs, assets (backend seed; grid built by AI-ML build_grid)

# 1. Install AI-ML (hawa-contracts is a uv path dependency on ../backend/contracts)
cd AI-ML
uv sync --all-extras
cp .env.example .env          # fill HAWA_INTERNAL_TOKEN, AWS profile/region, Bedrock model ids
uv run pre-commit install

# 2. One-off data preparation (see DATA_AND_TRAINING.md)
uv run python scripts/build_grid.py --out s3://hawa-local-lake/grid/
uv run python scripts/fetch_cpcb.py --from 2022-10-01 --to 2026-09-15
uv run python scripts/fetch_weather.py --source open-meteo --from 2022-10-01
uv run python scripts/fetch_firms.py --days 10

# 3. Run the processes
uv run intel-worker --groups all                      # or: --groups intel-twin,intel-forecast
uv run intel-service                                  # uvicorn on :8100, internal network only
HAWA_LLM_MODE=stub uv run intel-worker --groups intel-plan   # agents without Bedrock (deterministic stub)

# 4. Tests and quality gates
uv run ruff check . && uv run ruff format --check .
uv run mypy src
uv run pytest -m "unit or property"                   # fast, no services
uv run pytest -m contract                             # needs the live DB (reflects schema)
uv run pytest -m eval_agents                          # golden agent scenarios (Bedrock or stub)

# 5. Train and evaluate a model (writes to MLflow, applies promotion gates)
uv run hawa-trainer run --model forecaster
uv run hawa-trainer run --model calibration --device-ids HPM-0142,HPM-0143
uv run hawa-trainer evaluate --model twin --holdout-stations REF-CPCB-site_301
```

`make` wrappers exist for all of the above (`make sync`, `make lint`, `make test`, `make train MODEL=forecaster`, `make worker`, `make service`); see [STRUCTURE.md §4](STRUCTURE.md#4-makefile-targets).

## 5. Non-negotiables (summary)

1. Use the exact names in [CONTRACTS.md](../CONTRACTS.md): topics, event types, tables, Redis keys, IDs, enums, units.
2. Every model output carries uncertainty (`*_var`/`confidence`, `p10/p50/p90`, `ci_low/ci_high`, `cause_conf`) and `model_version`.
3. The optimiser decides, LLM agents explain and critique, a human officer approves. Agents cannot bypass constraints. Agent failure falls back to a deterministic plan; the pipeline never blocks.
4. Cause → asset matrix (CONTRACTS §3) is a hard constraint: no water on smoke, no trucks for regional smoke.
5. Simulated data is always flagged `is_simulated = true`. The verifier is demonstrated on simulated interventions with injected, known effects (§12.5).
6. AI-ML never runs DDL, never writes backend-owned tables, and never sends personal data to an LLM beyond what the task needs.
7. Never drop the What-If simulator or causal verification (§16 cut rule).

## 6. Links

- Proposal (source of truth): `../../HawaCommand_Proposal.pdf` — especially §6 (features), §8 (execution flow), §9.4 (algorithms), §12.5 (what is real), §16 (build plan).
- Whole-system context: [../SYSTEM_OVERVIEW.md](../SYSTEM_OVERVIEW.md)
- Binding contracts: [../CONTRACTS.md](../CONTRACTS.md)
- Proposed contract additions from AI-ML: [ARCHITECTURE.md §12](ARCHITECTURE.md#12-proposed-contract-additions)
- Sibling teams: [../backend/](../backend/) · [../frontend/](../frontend/) · [../app/README.md](../app/README.md)
- Logging library: `logifyx` 2.x (PyPI `logifyx`, github.com/Madhur-Prakash/Logifyx-Py)
