# HawaCommand documentation

<!-- nav:start -->

**Navigate:** [Project](../README.md) · **Docs hub** · [Overview](SYSTEM_OVERVIEW.md) · [AWS architecture](AWS_ARCHITECTURE.md) · [AWS guide](AWS_SETUP_GUIDE.md) · [API](backend/API.md) · [Environment](ENVIRONMENT_VARIABLES.md) · [Contracts](CONTRACTS.md)

<!-- nav:end -->

<div align="center">

<a href="../README.md"><img src="https://img.shields.io/badge/project-README-111111?logo=github&logoColor=white" alt="Project README"></a>
<a href="AWS_ARCHITECTURE.md"><img src="https://img.shields.io/badge/AWS-architecture-FF9900?logo=amazonwebservices&logoColor=white" alt="AWS architecture"></a>
<a href="AWS_SETUP_GUIDE.md"><img src="https://img.shields.io/badge/AWS-integration%20guide-FF9900?logo=amazonwebservices&logoColor=white" alt="AWS integration guide"></a>
<a href="backend/API.md"><img src="https://img.shields.io/badge/API-reference-009688?logo=fastapi&logoColor=white" alt="API reference"></a>
<a href="ENVIRONMENT_VARIABLES.md"><img src="https://img.shields.io/badge/config-environment%20variables-6E7781" alt="Environment variables"></a>

</div>

Every document in the repository, grouped by who needs it. HawaCommand is a **fully developed prototype**, deployed on AWS with every flow working end to end ([live demo](http://ec2-13-207-49-123.ap-south-1.compute.amazonaws.com:3000/)).

- **Code wins:** where a doc and the code disagree, the doc is the bug.
- **Section references** such as **§9.4** point to the original HawaCommand proposal (v3), which is no longer kept in the repo.

---

## Reading paths

| You are | Read in this order |
|---|---|
| **Judge or first-time visitor** | [Project README](../README.md) → [AWS architecture](AWS_ARCHITECTURE.md) → [System overview](SYSTEM_OVERVIEW.md) |
| **Cloud engineer** | [AWS architecture](AWS_ARCHITECTURE.md) → [AWS integration guide](AWS_SETUP_GUIDE.md) → [Environment variables](ENVIRONMENT_VARIABLES.md) |
| **Backend developer** | [Runbook](../backend/README.md) → [Architecture](backend/ARCHITECTURE.md) → [Services](backend/SERVICES.md) → [API](backend/API.md) → [Data stores](backend/DATA_STORES.md) → [Deployment](backend/DEPLOYMENT.md) |
| **AI / ML developer** | [Runbook](../AI-ML/README.md) → [Architecture](aiml/ARCHITECTURE.md) → [Models](aiml/MODELS.md) → [Agents](aiml/AGENTS.md) → [Data and training](aiml/DATA_AND_TRAINING.md) → [Deployment](aiml/DEPLOYMENT.md) |
| **Web developer** | [Runbook](../frontend/README.md) → [Pages](frontend/PAGES.md) → [Design system](frontend/DESIGN_SYSTEM.md) → [Architecture](frontend/ARCHITECTURE.md) → [Deployment](frontend/DEPLOYMENT.md) |
| **Mobile developer** | [Runbook](../app_frontend/README.md) → [Screens](app/SCREENS.md) → [Architecture](app/ARCHITECTURE.md) → [Offline and sync](app/OFFLINE_AND_SYNC.md) → [Notifications and realtime](app/NOTIFICATIONS_AND_REALTIME.md) → [Deployment](app/DEPLOYMENT.md) |

---

## Cross-cutting

| Doc | What is in it |
|---|---|
| [SYSTEM_OVERVIEW.md](SYSTEM_OVERVIEW.md) | Product, closed loop, users, feature map, architecture, stack |
| [AWS_ARCHITECTURE.md](AWS_ARCHITECTURE.md) | All 22 AWS services: why, how, resources, code, IAM, fallbacks, data flows |
| [AWS_SETUP_GUIDE.md](AWS_SETUP_GUIDE.md) | Why AWS, the integration checklist, console steps, smoke tests, costs, optional AI and workflow services |
| [ENVIRONMENT_VARIABLES.md](ENVIRONMENT_VARIABLES.md) | Every setting: backend, AI-ML, web, Flutter defines, Makefile |
| [CONTRACTS.md](CONTRACTS.md) | Shared IDs, enums, units, packets, endpoints, AQI and GRAP tables |

---

## By module

Every module has a **README** (index and status), **ARCHITECTURE** and **DEPLOYMENT**, plus the docs that matter for that module.

| Module | Core | Module-specific |
|---|---|---|
| ![AI-ML](https://img.shields.io/badge/AI--ML-engine-3776AB?logo=python&logoColor=white) | [Runbook](../AI-ML/README.md) · [Index](aiml/README.md) · [Architecture](aiml/ARCHITECTURE.md) · [Engine API](../AI-ML/CONTRACTS.md) · [Deployment](aiml/DEPLOYMENT.md) | [Models](aiml/MODELS.md): twin, forecaster, attribution, exposure, optimiser, verifier · [Agents](aiml/AGENTS.md): Planner, Auditor, Forecaster, Communicator · [Data and training](aiml/DATA_AND_TRAINING.md): sources, datasets, training |
| ![Backend](https://img.shields.io/badge/backend-API-009688?logo=fastapi&logoColor=white) | [Runbook](../backend/README.md) · [Index](backend/README.md) · [Architecture](backend/ARCHITECTURE.md) · [API](backend/API.md) · [Deployment](backend/DEPLOYMENT.md) | [Services](backend/SERVICES.md): reports, fleet, alerts, push · [Data stores](backend/DATA_STORES.md): DynamoDB, Redis, S3, SQL · [Testing](backend/TESTING.md): suites, moto, fakeredis |
| ![Web](https://img.shields.io/badge/web-console-000000?logo=nextdotjs&logoColor=white) | [Runbook](../frontend/README.md) · [Index](frontend/README.md) · [Architecture](frontend/ARCHITECTURE.md) · [Deployment](frontend/DEPLOYMENT.md) | [Pages](frontend/PAGES.md): every console page · [Design system](frontend/DESIGN_SYSTEM.md): colours, AQI bands, type, components |
| ![App](https://img.shields.io/badge/mobile-app-02569B?logo=flutter&logoColor=white) | [Runbook](../app_frontend/README.md) · [Index](app/README.md) · [Architecture](app/ARCHITECTURE.md) · [Deployment](app/DEPLOYMENT.md) | [Screens](app/SCREENS.md): every role and screen · [Offline and sync](app/OFFLINE_AND_SYNC.md): outbox and retries · [Notifications and realtime](app/NOTIFICATIONS_AND_REALTIME.md): FCM, deep links, WebSockets |

### Next to the code

| Doc | What is in it |
|---|---|
| [Forecaster model card](../AI-ML/models/forecaster_model_card.md) · [Attribution model card](../AI-ML/models/attribution_model_card.md) | Training data, metrics, limits |
| [AI-ML/data/README.md](../AI-ML/data/README.md) | Data folders and fixtures |
| Agent prompts: [planner](../AI-ML/src/hawa_ml/agents/prompts/planner.md) · [auditor](../AI-ML/src/hawa_ml/agents/prompts/auditor.md) · [forecaster](../AI-ML/src/hawa_ml/agents/prompts/forecaster.md) · [communicator](../AI-ML/src/hawa_ml/agents/prompts/communicator.md) | System prompts the agents load at runtime |
| [Design export notes](../frontend/design/EXPORT_NOTES.md) | The design source the web console was ported from |

---

## Ground rules

1. **Contracts first:** names in [CONTRACTS.md](CONTRACTS.md) change together with `backend/contracts/`.
2. **Honesty rule:** anything simulated carries `simulated: true` and a badge on screen.
3. **Uncertainty everywhere:** no model output without its confidence, P10/P90 or interval.
4. **Humans approve:** the optimiser decides, agents explain, officers approve.
5. **Docs follow code:** change behaviour, change the matching module doc in the same PR.

<!-- footer:start -->

---

[Back to top](#hawacommand-documentation) · [Docs hub](README.md) · [Project README](../README.md)

<!-- footer:end -->
