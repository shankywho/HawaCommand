# HawaCommand — Documentation

Blueprint for building **HawaCommand**: an AI command centre that finds, forecasts and fixes Delhi's pollution hotspots, and proves every fix worked. (Environmental Hacks 2026 · Bharat Builds Tour · Track 01: Air.)

Everything here is derived from [`HawaCommand_Proposal.pdf`](../HawaCommand_Proposal.pdf) (Proposal v3). Section references like **§9.4** point to that PDF.

## Start here

| Read | Why |
|---|---|
| [SYSTEM_OVERVIEW.md](SYSTEM_OVERVIEW.md) | The product, the closed loop, users, day timeline, feature → owner map, whole-system architecture, stack, deviations from the proposal, golden path, 24 h plan |
| [CONTRACTS.md](CONTRACTS.md) | **Binding** cross-team contracts: IDs, enums, units, MQTT packets, Kafka topics and events, REST/WebSocket index, table ownership, Redis keys, AQI/GRAP tables, schedules |

Then read the folder for your discipline. Every folder has the same backbone:

| File | Contents |
|---|---|
| `README.md` | Index, quick start, what this part owns |
| `CONTEXT.md` | The full product context from the PDF, seen from this part |
| `ARCHITECTURE.md` | Components, data flows, sequence diagrams, failure modes |
| `STRUCTURE.md` | Folder and file layout of the code folder |
| `PLAN.md` | Hackathon hour-by-hour plan, milestones with acceptance criteria, cut rules, roadmap |

## By discipline

### AI / ML → code in [`AI-ML/`](../AI-ML)
[aiml/README.md](aiml/README.md): twin, attribution, forecasting, exposure, optimiser, causal verification, Strands agents on Bedrock.
Extra docs: [MODELS.md](aiml/MODELS.md) (every algorithm), [AGENTS.md](aiml/AGENTS.md) (multi-agent command room, full system prompts), [DATA_AND_TRAINING.md](aiml/DATA_AND_TRAINING.md) (data sources, features, MLflow, promotion gates).

### Backend → code in [`backend/`](../backend)
[backend/README.md](backend/README.md): FastAPI, PostgreSQL + PostGIS, Alembic, Redis, Kafka, logifyx.
Extra docs: [DATA_MODEL.md](backend/DATA_MODEL.md) (schema + Alembic), [API.md](backend/API.md) (REST + WebSocket + auth), [EVENTS.md](backend/EVENTS.md) (Kafka), [CACHING.md](backend/CACHING.md) (Redis), [LOGGING_AND_OBSERVABILITY.md](backend/LOGGING_AND_OBSERVABILITY.md) (logifyx, OpenTelemetry, metrics), [DEPLOYMENT.md](backend/DEPLOYMENT.md) (Docker Compose, AWS CDK, CI/CD).

### Web frontend → code in [`frontend/`](../frontend)
[frontend/README.md](frontend/README.md): Next.js officer console, public site, open data portal; deck.gl + MapLibre.
Extra docs: [PAGES.md](frontend/PAGES.md) (page and component spec), [DESIGN_SYSTEM.md](frontend/DESIGN_SYSTEM.md) (tokens, AQI colours, the shared source of truth), [LINTING_AND_QUALITY.md](frontend/LINTING_AND_QUALITY.md) (ESLint, Prettier, TypeScript, Husky, CI, tests).

### Mobile app (Flutter) → code in [`app_frontend/`](../app_frontend)
[app/README.md](app/README.md): driver, inspector, school principal, citizen, site manager.
Extra docs: [SCREENS.md](app/SCREENS.md) (screen spec, en/hi copy, push catalogue), [OFFLINE_AND_SYNC.md](app/OFFLINE_AND_SYNC.md) (offline-first outbox), [LINTING_AND_QUALITY.md](app/LINTING_AND_QUALITY.md) (very_good_analysis, CI, tests).

## Ground rules for every team

1. **Contracts first.** Names in [CONTRACTS.md](CONTRACTS.md) are the law. To change one, update CONTRACTS.md and `backend/contracts/` in the same PR and tag all four leads.
2. **Honesty rule.** One real pod, a simulated fleet, a real pipeline. Anything with `is_simulated = true` shows a "Simulated" badge.
3. **Uncertainty everywhere.** No model output reaches a screen without its confidence, P10/P90 or CI.
4. **The optimiser decides, agents explain, officers approve.** Nothing dispatches without human approval.
5. **Cut rule.** If behind, drop wind advection, Citizen Eyes and the school scheduler. Never drop the What-If screen and causal verification.
