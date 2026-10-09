# HawaCommand

An autonomous artificial intelligence command centre that maps, forecasts, and remediates urban air pollution hotspots street by street, and econometrically verifies the efficacy of every intervention.

Environmental Hacks 2026 · Bharat Builds Tour · Track 01: Air

---

## Executive Summary

The National Capital Territory (NCT) of Delhi deploys extensive physical remediation machinery: 376 anti-smog guns, 266 water sprinklers, and 91 mechanised road sweepers. Despite this municipal investment, air quality remediation remains largely reactive, uncoordinated, and unverified. Fleet units operate along static schedules regardless of localized particulate spikes, and municipal authorities lack causal tools to verify whether a given water misting run actually reduced ground-level particulate matter or whether changes were merely driven by wind dispersion.

HawaCommand provides the decision intelligence for municipal air quality governance. It ingests multi-source observational data (live statutory monitoring stations, satellite fire hotspots, and meteorological features), fits a high-resolution 500-metre spatial digital twin across 10,600 grid cells, attributes dominant emission sources, forecasts 72-hour quantile risk intervals, dynamically dispatches remediation machinery, protects vulnerable populations via citizen and school mobile applications, and verifies intervention efficacy using econometric Synthetic Control Methods.

---

## The Closed-Loop Architecture

```
  [Sense] ───────> [Map] ────────> [Attribute] ───────> [Forecast]
     ▲                                                         │
     │                                                         ▼
 [Verify] <─────── [Act] <──────────────────────────────── [Decide]
     │                                                         │
     └───────────── What Worked Feeds The Next Plan ───────────┘
```

The system operates as an end-to-end feedback loop consisting of seven stages:

| Stage | Subsystem | Technical Implementation |
|---|---|---|
| 1. Sense | Multi-Source Ingestion | Real-time statutory CAAQMS stations via WAQI and OpenAQ APIs, NASA FIRMS VIIRS satellite thermal anomaly detection, and ECMWF ERA5 meteorological reanalysis. |
| 2. Map | 500m Spatial Digital Twin | Gaussian Process Regressor with Radial Basis Function (RBF) kernel interpolating 10,600 discrete 500m cells across Delhi with predictive uncertainty variance. |
| 3. Attribute | Explainable Source Attribution | Supervised LightGBM classifier attributing dominant local pollution sources (unpaved road dust, vehicular exhaust, biomass/waste burning, regional smoke). |
| 4. Forecast | 72-Hour Quantile Predictor | LightGBM quantile regression models outputting P10, P50, and P90 particulate forecasts and predicting Graded Response Action Plan (GRAP) threshold breaches 24 to 48 hours in advance. |
| 5. Decide | Fleet Route Optimization | Google OR-Tools Vehicle Routing Problem (VRP) solver calculating constrained dispatch paths based on water capacity, street width limits, and population exposure risk. |
| 6. Act | Multi-Stakeholder Action | Automated dispatch instructions to machine drivers, targeted inspection tasks to municipal ward officers, and diurnal safe-air breathing windows to citizens and schools. |
| 7. Verify | Econometric Causal Verification | Synthetic Control Method (SCM) constructing synthetic counterfactual donor pools from un-misted control cells to empirically prove true net particulate reduction. |

---

## Repository Structure

```
Mission_CleanTheAir/
|-- AI-ML/               # Core intelligence engine: Digital Twin, LightGBM models, OR-Tools, Causal Verifier
|-- app_frontend/        # Cross-platform Flutter mobile application (Citizen, Driver, Inspector, School)
|-- backend/             # FastAPI REST & WebSocket service with live CAAQMS ingestion and circuit breakers
|-- docs/                # Architecture specifications, contracts, blueprints, and cloud integration guides
|-- frontend/            # Next.js 15 command console, MapLibre GL 3D visualization, and public portal
|-- infrastructure/      # AWS CloudFormation and infrastructure-as-code deployment manifests
|-- HawaCommand_Proposal.pdf # Comprehensive product proposal and operational specification
|-- LICENSE              # Project licensing terms
`-- README.md            # Master repository documentation
```

---

## Subsystem Details

### 1. AI-ML Intelligence Engine (`AI-ML/`)
- **Digital Twin Engine (`DigitalTwinEngine`):** Employs Gaussian Process Kriging to map sparse ground observations to a continuous 10,600-cell grid covering the entirety of Delhi NCT. Provides cell-level confidence scores where variance increases with distance from active monitors.
- **Exposure Ranking Engine (`ExposureEngine`):** Ranks hotspots using a multi-factor formula combining estimated PM2.5, population density, proximity to schools and hospitals, and primary land-use classification.
- **Quantile Forecaster (`ForecasterAgent`):** Evaluates 72 sequential hourly horizons. Employs asymmetric pinball loss to provide calibrated P10, P50, and P90 confidence ribbons.
- **Causal Verification Engine (`CausalEngine`):** Solves a constrained convex optimization problem to weight similar untreated donor cells, measuring the exact difference between observed and counterfactual PM2.5 to verify misting impact.

### 2. Backend Service (`backend/`)
- **FastAPI Architecture:** Asynchronous API service implementing strict Pydantic v2 schemas and OpenAPI contracts.
- **Live Station Ingestion:** Integrates 24 active Delhi CAAQMS statutory monitoring stations with automated 15-minute caching and graceful fallback.
- **Resilience and Circuit Breaker:** Implements in-memory circuit breakers (5 consecutive errors trigger an OPEN state with a 15-second recovery window) ensuring zero downtime if external APIs experience transient network timeouts.
- **Diurnal Safe Window Calculator:** Computes boundary-layer thermal inversion risks to deliver optimal outdoor exercise and school assembly schedules.

### 3. Citizen Mobile Application (`app_frontend/`)
- **Flutter Multi-Persona Architecture:** Single codebase supporting Citizen, Machine Driver, Ward Inspector, and School Principal roles.
- **Air Near Me:** Displays indicative cell AQI with a high-confidence badge, live PM2.5 in micrograms per cubic metre, dominant pollutant, and LightGBM source attribution.
- **Safe Air Navigator:** Offline-capable clean airway routing that guides pedestrians and cyclists away from heavy arterial pollution corridors, reducing inhaled particulate doses by up to 43 percent.
- **Diurnal Breath Safe Window:** 24-hour visual thermal inversion timeline indicating morning inversion danger zones and afternoon solar mixing windows.
- **Democratic Accountability:** Ward air scorecards grading wards from A+ to F based on 30-day compliance and machine deployment metrics.

### 4. Officer Command Console (`frontend/`)
- **Next.js 15 and React 19:** High-performance dashboard utilizing Tailwind CSS and custom design tokens.
- **MapLibre GL and Deck.gl:** Interactive 3D geospatial visualization rendering 10,600 cells with real-time color categorization, wind particle advection vectors, and fleet markers.
- **Plan Review and What-If Playground:** Enables senior municipal officers to inspect proposed machine dispatches, modify parameters, preview counterfactual outcomes, and grant formal digital approval.

---

## Local Development and Setup

### Prerequisites
- Python 3.11 or higher
- Node.js 20 or higher with pnpm
- Flutter SDK 3.19 or higher (for mobile development)
- Android Studio / Xcode / Physical Android device (optional, for app deployment)

---

### Step 1: Start the AI-ML Intelligence Engine (Port 8100)

```bash
cd AI-ML
python -m venv .venv

# On Windows PowerShell:
.\.venv\Scripts\Activate.ps1
# On macOS/Linux:
# source .venv/bin/activate

pip install -e .
pip install -r requirements.txt

# Start the AI-ML service
uvicorn hawa_ml.api.main:app --host 127.0.0.1 --port 8100 --reload
```

---

### Step 2: Start the FastAPI Backend Service (Port 8000)

Open a new terminal window:

```bash
cd backend
python -m venv .venv

# On Windows PowerShell:
.\.venv\Scripts\Activate.ps1
# On macOS/Linux:
# source .venv/bin/activate

pip install -e contracts
pip install -e .

# Configure environment variables (copy example if necessary)
# Ensure WAQI_TOKEN and OPENAQ_API_KEY are configured in .env

# Start the backend service
uvicorn hawa_backend.api.app:app --host 127.0.0.1 --port 8000 --reload
```

Verify backend health:
```bash
curl http://127.0.0.1:8000/healthz
# Response: {"status":"ok","timestamp":"..."}
```

---

### Step 3: Start the Web Command Console (Port 3000)

Open a new terminal window:

```bash
cd frontend
pnpm install

# Configure backend connection
echo "NEXT_PUBLIC_API_URL=http://localhost:8000" > .env.local

# Start Next.js development server
pnpm dev
```

Open your browser:
- Landing Page: `http://localhost:3000`
- Officer Command Console: `http://localhost:3000/map`

---

### Step 4: Run the Flutter Mobile Application

Open a new terminal window:

```bash
cd app_frontend
flutter pub get

# To run on connected physical Android device (e.g. via USB):
# First route device port 8000 to host machine:
adb reverse tcp:8000 tcp:8000

# Launch application in development mode
flutter run --flavor dev --dart-define=API_BASE_URL=http://localhost:8000
```

---

## API Endpoints Reference

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/healthz` | System health and replica readiness probe |
| `GET` | `/v1/twin?bbox={bbox}&limit={limit}` | 500m Kriging digital twin cells with estimated PM2.5, PM10, variance, and confidence |
| `GET` | `/v1/hotspots?hour={h}&ward={w}` | Top ranked exposure hotspots with LightGBM source attribution and suspect plume vectors |
| `GET` | `/v1/forecast?cellId={id}` | 72-hour P10, P50, and P90 quantile particulate prediction series |
| `GET` | `/v1/citizen/safe-window` | Live diurnal thermal inversion curve and recommended outdoor breathing window |
| `POST` | `/v1/citizen/safe-route` | Cleanest pedestrian and vehicular airway route avoiding high-particulate corridors |
| `GET` | `/v1/fleet` | Live anti-smog gun and sweeper asset telemetry, operational state, and tank capacity |
| `GET` | `/v1/impact` | Causal verification impact table with pre/post treatment empirical difference |
| `GET` | `/open/v1/air?bbox={bbox}` | Public open data air quality GeoJSON FeatureCollection |

---

## Data Sources and Live Integrations

1. **Statutory Ground Stations (Live):** Ingests real-time continuous observations from 24 Central Pollution Control Board (CPCB) and Delhi Pollution Control Committee (DPCC) CAAQMS stations via the World Air Quality Index (WAQI) and OpenAQ APIs.
2. **Satellite Active Fire Data:** Ingests near-real-time satellite thermal anomaly detections from NASA FIRMS (VIIRS 375m and MODIS 1km) to flag regional agricultural stubble burning plumes upwind of the capital.
3. **Meteorological Reanalysis:** Ingests boundary layer height, 10m surface wind vectors (u/v components), surface temperature, and relative humidity from ECMWF ERA5 and Indian Meteorological Department (IMD) forecasts.
4. **Calibrated Offline Fallbacks:** When offline or disconnected from external API quotas, the system transitions to calibrated historical fixtures without crashing.

---

## Cloud Integration and Production Readiness

HawaCommand is designed for deployment in AWS Region `ap-south-1` (Mumbai / Delhi):
- **Container Orchestration:** Amazon ECS Fargate running separate task definitions for FastAPI and the AI-ML service.
- **Geospatial and State Caching:** Amazon ElastiCache Redis cluster caching 500m digital twin grids with 15-minute TTLs and tracking live fleet positions via Redis Geospatial indexes.
- **Citizen Evidence Pipeline:** Private Amazon S3 bucket with KMS encryption and presigned upload URLs for citizen grievance photo submissions.
- **Telemetry Ingestion:** Amazon Kinesis Data Streams handling streaming telemetry from mobile machine sensor pods.

Detailed deployment runbooks and architecture specifications are available in:
- [`docs/CLOUD_ENGINEER_INTEGRATION_CHECKLIST.md`](docs/CLOUD_ENGINEER_INTEGRATION_CHECKLIST.md)
- [`docs/AWS_INTEGRATION.md`](docs/AWS_INTEGRATION.md)
- [`docs/TEAM_REMAINING_WORK_AND_PROMPTS.md`](docs/TEAM_REMAINING_WORK_AND_PROMPTS.md)

---

## Verification and Testing

Execute the test suites across each repository layer:

```bash
# Test AI-ML algorithms and model contracts
cd AI-ML
pytest tests/ -v

# Test Backend API endpoints and circuit breakers
cd ../backend
pytest tests/ -v

# Verify Web TypeScript compilation
cd ../frontend
pnpm exec tsc --noEmit

# Analyze Flutter mobile application
cd ../app_frontend
flutter analyze lib/
```

---

## Documentation Index

- [System Overview](docs/SYSTEM_OVERVIEW.md)
- [Cross-Discipline System Contracts](docs/CONTRACTS.md)
- [Cloud Engineer Integration Checklist](docs/CLOUD_ENGINEER_INTEGRATION_CHECKLIST.md)
- [Team Remaining Work and Role Prompts](docs/TEAM_REMAINING_WORK_AND_PROMPTS.md)
- [AWS Deployment Runbook](docs/AWS_INTEGRATION.md)
- [Proposal Specification](HawaCommand_Proposal.pdf)
