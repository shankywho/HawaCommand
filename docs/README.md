# HawaCommand documentation

<div align="center">

<a href="../README.md"><img src="https://img.shields.io/badge/project-README-111111?logo=github&logoColor=white" alt="Project README"></a>
<a href="AWS_ARCHITECTURE.md"><img src="https://img.shields.io/badge/AWS-architecture-FF9900?logo=amazonwebservices&logoColor=white" alt="AWS architecture"></a>
<a href="AWS_SETUP_GUIDE.md"><img src="https://img.shields.io/badge/AWS-setup%20guide-FF9900?logo=amazonwebservices&logoColor=white" alt="AWS setup guide"></a>
<a href="backend/API.md"><img src="https://img.shields.io/badge/API-reference-009688?logo=fastapi&logoColor=white" alt="API reference"></a>
<a href="ENVIRONMENT_VARIABLES.md"><img src="https://img.shields.io/badge/config-environment%20variables-6E7781" alt="Environment variables"></a>
<img src="https://img.shields.io/badge/docs-58%20pages-2563EB?logo=readthedocs&logoColor=white" alt="58 pages">

</div>

Every document in the repository, grouped by who needs it. HawaCommand is a **fully developed prototype**, deployed on AWS with every flow working end to end ([live demo](http://ec2-13-207-49-123.ap-south-1.compute.amazonaws.com:3000/)).

- **Code wins:** where a doc and the code disagree, the doc is the bug.
- **Status words everywhere:** **Implemented** (works) · **Partial** (works, gap named) · **Stub/Mock** (fixtures or synthetic data) · **Planned** (designed, not built).
- **Section references** such as **§9.4**, and "the PDF", point to the original HawaCommand proposal (v3, 27 Sep 2026), which is no longer kept in the repo.

---

## Reading paths

| You are | Read in this order |
|---|---|
| **Judge or first-time visitor** | [Project README](../README.md) → [AWS architecture](AWS_ARCHITECTURE.md) → [System overview](SYSTEM_OVERVIEW.md) |
| **Cloud engineer** | [AWS architecture](AWS_ARCHITECTURE.md) → [AWS setup guide](AWS_SETUP_GUIDE.md) → [Environment variables](ENVIRONMENT_VARIABLES.md) → [Cloud checklist](CLOUD_ENGINEER_INTEGRATION_CHECKLIST.md) |
| **Backend developer** | [backend/README.md](../backend/README.md) → [backend docs](backend/README.md) → [API](backend/API.md) → [Contracts](CONTRACTS.md) |
| **AI / ML developer** | [AI-ML/README.md](../AI-ML/README.md) → [AI-ML docs](aiml/README.md) → [Models](aiml/MODELS.md) → [Agents](aiml/AGENTS.md) |
| **Web developer** | [frontend/README.md](../frontend/README.md) → [web docs](frontend/README.md) → [Pages](frontend/PAGES.md) → [Design system](frontend/DESIGN_SYSTEM.md) |
| **Mobile developer** | [app_frontend/README.md](../app_frontend/README.md) → [app docs](app/README.md) → [Screens](app/SCREENS.md) → [Offline and sync](app/OFFLINE_AND_SYNC.md) |

---

## Run it

| Component | Runbook | Port |
|---|---|---|
| ![AI-ML](https://img.shields.io/badge/AI--ML-engine-3776AB?logo=python&logoColor=white) | [AI-ML/README.md](../AI-ML/README.md) | 8100 |
| ![Backend](https://img.shields.io/badge/backend-API-009688?logo=fastapi&logoColor=white) | [backend/README.md](../backend/README.md) | 8000 |
| ![Web](https://img.shields.io/badge/web-console-000000?logo=nextdotjs&logoColor=white) | [frontend/README.md](../frontend/README.md) | 3000 |
| ![App](https://img.shields.io/badge/mobile-app-02569B?logo=flutter&logoColor=white) | [app_frontend/README.md](../app_frontend/README.md) | — |

- From the repo root: `make install`, `make aiml-api`, `make backend`, `make frontend` ([quick start](../README.md#quick-start)).

---

## Cross-cutting

| Doc | What is in it |
|---|---|
| [SYSTEM_OVERVIEW.md](SYSTEM_OVERVIEW.md) | Product, closed loop, users, day timeline, feature map, architecture, stack, status |
| [AWS_ARCHITECTURE.md](AWS_ARCHITECTURE.md) | All 22 AWS services: why, how, resources, code, IAM, fallbacks, data flows |
| [AWS_SETUP_GUIDE.md](AWS_SETUP_GUIDE.md) | Console steps for every service, variables, smoke tests, costs |
| [AWS_INTEGRATION.md](AWS_INTEGRATION.md) | Engineering runbook: forecast and dispatch workflows, Bedrock, hosting tasks |
| [CLOUD_ENGINEER_INTEGRATION_CHECKLIST.md](CLOUD_ENGINEER_INTEGRATION_CHECKLIST.md) | The cloud checklist, item by item, mapped to code |
| [ENVIRONMENT_VARIABLES.md](ENVIRONMENT_VARIABLES.md) | Every setting: backend, AI-ML, web, Flutter defines, Makefile |
| [CONTRACTS.md](CONTRACTS.md) | Binding IDs, enums, units, packets, topics, endpoints, Redis keys, AQI and GRAP tables |

---

## By discipline

Each discipline folder has the same backbone: `README` (index and status) · `CONTEXT` (users and rules) · `ARCHITECTURE` (components and flows) · `STRUCTURE` (file tree) · `PLAN` (milestones).

### AI / ML · code in [`AI-ML/`](../AI-ML)

| Doc | What is in it |
|---|---|
| [aiml/README.md](aiml/README.md) | Index, status, quick start |
| [aiml/CONTEXT.md](aiml/CONTEXT.md) | Problem framing and features from the AI side |
| [aiml/ARCHITECTURE.md](aiml/ARCHITECTURE.md) | Engine components and data flow |
| [aiml/MODELS.md](aiml/MODELS.md) | Every algorithm: twin, attribution, forecaster, exposure, optimiser, causal verifier |
| [aiml/AGENTS.md](aiml/AGENTS.md) | Planner, Auditor, Forecaster, Communicator and their prompts |
| [aiml/DATA_AND_TRAINING.md](aiml/DATA_AND_TRAINING.md) | Sources, features, training, promotion gates |
| [aiml/STRUCTURE.md](aiml/STRUCTURE.md) | File tree |
| [aiml/PLAN.md](aiml/PLAN.md) | Milestones |
| [AI-ML/CONTRACTS.md](../AI-ML/CONTRACTS.md) | Engine HTTP and in-process API |
| [AI-ML/data/README.md](../AI-ML/data/README.md) | Data folders and fixtures |
| [Forecaster model card](../AI-ML/models/forecaster_model_card.md) · [Attribution model card](../AI-ML/models/attribution_model_card.md) | Training data, metrics, limits |
| Agent prompts: [planner](../AI-ML/src/hawa_ml/agents/prompts/planner.md) · [auditor](../AI-ML/src/hawa_ml/agents/prompts/auditor.md) · [forecaster](../AI-ML/src/hawa_ml/agents/prompts/forecaster.md) · [communicator](../AI-ML/src/hawa_ml/agents/prompts/communicator.md) | System prompts the agents send to the LLM |

### Backend · code in [`backend/`](../backend)

| Doc | What is in it |
|---|---|
| [backend/README.md](backend/README.md) | Index, status, known issues |
| [backend/CONTEXT.md](backend/CONTEXT.md) | Responsibilities and the day timeline |
| [backend/ARCHITECTURE.md](backend/ARCHITECTURE.md) | Components, flows, failure modes |
| [backend/API.md](backend/API.md) | Every route, field and status code, plus WebSocket |
| [backend/DATA_MODEL.md](backend/DATA_MODEL.md) | SQL schema and Alembic |
| [backend/EVENTS.md](backend/EVENTS.md) | Event and topic design |
| [backend/CACHING.md](backend/CACHING.md) | Cache design and Redis keys |
| [backend/LOGGING_AND_OBSERVABILITY.md](backend/LOGGING_AND_OBSERVABILITY.md) | Logs, metrics, tracing |
| [backend/DEPLOYMENT.md](backend/DEPLOYMENT.md) | Docker, ECS, CI/CD |
| [backend/STRUCTURE.md](backend/STRUCTURE.md) | File tree |
| [backend/PLAN.md](backend/PLAN.md) | Milestones |

### Web console · code in [`frontend/`](../frontend)

| Doc | What is in it |
|---|---|
| [frontend/README.md](frontend/README.md) | Index, status |
| [frontend/CONTEXT.md](frontend/CONTEXT.md) | Who the console serves and its product rules |
| [frontend/ARCHITECTURE.md](frontend/ARCHITECTURE.md) | App structure, data layer, map |
| [frontend/PAGES.md](frontend/PAGES.md) | Page and component spec |
| [frontend/DESIGN_SYSTEM.md](frontend/DESIGN_SYSTEM.md) | Tokens, AQI colours, typography |
| [frontend/LINTING_AND_QUALITY.md](frontend/LINTING_AND_QUALITY.md) | Lint, types, tests |
| [frontend/STRUCTURE.md](frontend/STRUCTURE.md) | File tree |
| [frontend/PLAN.md](frontend/PLAN.md) | Milestones |
| [Design export notes](../frontend/design/EXPORT_NOTES.md) | The design source the console was ported from |

### Mobile app · code in [`app_frontend/`](../app_frontend)

| Doc | What is in it |
|---|---|
| [app/README.md](app/README.md) | Index, status, known issues |
| [app/CONTEXT.md](app/CONTEXT.md) | Users, field realities, privacy |
| [app/ARCHITECTURE.md](app/ARCHITECTURE.md) | Layers, Riverpod, networking, push, location, flavors |
| [app/SCREENS.md](app/SCREENS.md) | Every screen with English and Hindi copy |
| [app/OFFLINE_AND_SYNC.md](app/OFFLINE_AND_SYNC.md) | Outbox, drainer, conflict rules |
| [app/LINTING_AND_QUALITY.md](app/LINTING_AND_QUALITY.md) | Analysis, tests, hooks |
| [app/STRUCTURE.md](app/STRUCTURE.md) | File tree |
| [app/PLAN.md](app/PLAN.md) | Milestones |

---

## Project files

| File | What is in it |
|---|---|
| [README.md](../README.md) | Project overview, AWS table, live demo, team |
| [LICENSE](../LICENSE) | MIT |

---

## Ground rules

1. **Contracts first:** names in [CONTRACTS.md](CONTRACTS.md) are the law; change them with `backend/contracts/` in the same PR.
2. **Honesty rule:** anything simulated carries `simulated: true` and a badge on screen.
3. **Uncertainty everywhere:** no model output without its confidence, P10/P90 or interval.
4. **Humans approve:** the optimiser decides, agents explain, officers approve. Nothing dispatches on its own.
5. **Docs follow code:** change behaviour, change the matching doc and status word in the same PR.

---

[Back to the project README](../README.md)
