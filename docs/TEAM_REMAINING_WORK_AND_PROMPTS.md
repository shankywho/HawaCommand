# Team Remaining Work, Task Checklist, and Role-Specific Prompts

This document provides a comprehensive operational breakdown of remaining integration, scaling, and production-hardening tasks across all engineering disciplines for the HawaCommand and HawaCitizen ecosystem.

Each section contains:
1. Role ownership and primary responsibilities
2. Actionable, prioritized task checklist
3. Execution prompt tailored for an AI assistant or human engineer to execute the work directly

---

## 1. Cloud and DevOps Engineer

### Role Responsibilities
Owns AWS cloud infrastructure, serverless deployments, managed database migrations, Kinesis telemetry ingestion streams, Redis ElastiCache clusters, and secure S3 presigned URL pipelines.

### Task Checklist
- [ ] Deploy S3 production bucket (`hawa-citizen-evidence-prod`) with KMS encryption, CORS headers, and 30/90/180-day lifecycle transitions.
- [ ] Provision DynamoDB tables (`hawa-citizen-grievances` with `WardStatusIndex` GSI and `hawa-fleet-telemetry` with TTL auto-expiry).
- [ ] Configure AWS ElastiCache Redis cluster (`cache.t4g.small`) for 500m grid spatial caching and live fleet tracking (`geo:fleet:active`).
- [ ] Set up AWS Kinesis Data Stream (`hawa-sensor-data`) with on-demand capacity and Lambda consumers for streaming pod telemetry.
- [ ] Configure Amazon ECS Fargate cluster with Application Load Balancer (ALB) and ACM SSL/TLS certificates for the FastAPI backend and AI-ML service.
- [ ] Automate CI/CD pipelines via GitHub Actions for automated Docker builds, container vulnerability scanning, and blue-green deployments.
- [ ] Set up AWS CloudWatch alarms and SNS notification topics for API error rates exceeding 2% and SLA breach notifications.

### Execution Prompt for Cloud Engineer
```text
You are the Lead Cloud and DevOps Engineer for Mission_CleanTheAir (HawaCommand).
Your objective is to complete the production deployment of the HawaCommand infrastructure on AWS (ap-south-1 Mumbai region).

Review docs/AWS_INTEGRATION.md and docs/CLOUD_ENGINEER_INTEGRATION_CHECKLIST.md.
Execute the following tasks:
1. Create and validate the Terraform/CloudFormation templates in infrastructure/ for ECS Fargate, DynamoDB tables, ElastiCache Redis, and S3 evidence buckets.
2. Ensure environment variables are parameterized via AWS SSM Parameter Store and Secrets Manager (WAQI_TOKEN, OPENAQ_API_KEY, NASA_FIRMS_MAP_KEY, GROQ_API_KEY).
3. Validate that the FastAPI backend running in Docker can communicate with Redis for 500m grid caching and DynamoDB for outbox ingestion.
4. Set up CloudWatch logging and metrics dashboard for p95 latency, sensor ingestion rates, and fleet active pings.
Provide infrastructure-as-code manifests and validation commands upon completion.
```

---

## 2. AI / ML Engineer

### Role Responsibilities
Owns spatial interpolation, causal inference verification, LightGBM quantile forecasting models, exposure hotspot ranking, and autonomous agent orchestration.

### Task Checklist
- [ ] Fine-tune Gaussian Process Regressor hyperparameters (length scale, RBF variance, noise level) against multi-year historical Delhi CPCB data.
- [ ] Retrain LightGBM quantile forecaster models (P10, P50, P90) on updated ERA5 reanalysis and IMD weather forecast features.
- [ ] Validate Synthetic Control Method (SCM) donor pool selection to prevent spillover bias during anti-smog gun misting interventions.
- [ ] Optimize OR-Tools Vehicle Routing Problem (VRP) solver to handle road width constraints (restricting large 10,000 L misting trucks to arterial roads).
- [ ] Calibrate diurnal boundary-layer inversion risk calculator across all 272 Delhi municipal wards.
- [ ] Export ONNX runtime models for sub-10ms edge inference in the FastAPI backend container.

### Execution Prompt for AI/ML Engineer
```text
You are the Principal AI/ML Engineer for HawaCommand.
Your objective is to scale and validate the machine learning and econometric inference engines in AI-ML/.

Key Focus Areas:
1. In hawa_ml/digital_twin/kriging.py, optimize the spatial interpolation pipeline so fitting across 10,600 500m cells completes in under 2.5 seconds using optimized matrix operations.
2. In hawa_ml/causal/synthetic_control.py, enforce donor-pool distance exclusion filters (excluding cells within 1.5 km of treated misting zones) to avoid control unit contamination.
3. In hawa_ml/forecasting/quantile_forecaster.py, evaluate forecast calibration metrics (pinball loss, coverage rates for the 80% P10-P90 prediction interval) across 72-hour forecast horizons.
4. Ensure all models run deterministically with calibrated unit tests in AI-ML/tests/.
Deliver benchmark results and clean test suites.
```

---

## 3. Backend Engineer

### Role Responsibilities
Owns FastAPI REST API, WebSocket streams, database models, background scheduler tasks, open data interfaces, and authentication.

### Task Checklist
- [ ] Add PostgreSQL + PostGIS database persistence alongside the existing in-process and DynamoDB fallback layers.
- [ ] Implement database migrations using Alembic for wards, sensors, reports, and intervention records.
- [ ] Implement JWT authentication with role-based access control (Admin, Officer, Inspector, School, Citizen).
- [ ] Add rate-limiting middleware (SlowAPI / Redis token bucket) on public endpoints (`/open/v1/air`, `/v1/citizen/safe-window`).
- [ ] Implement WebSocket connection manager for live fleet telemetry broadcasts to the web command console.
- [ ] Write integration test coverage for all routes in `backend/src/hawa_backend/api/routes/`.

### Execution Prompt for Backend Engineer
```text
You are the Senior Backend Engineer for HawaCommand.
Your task is to harden and expand the FastAPI backend in backend/.

Tasks to Implement:
1. In backend/src/hawa_backend/api/app.py, configure Redis-backed rate limiting on all public routes to protect against traffic spikes.
2. In backend/src/hawa_backend/api/routes/citizen.py, add complete CRUD and filtering endpoints for citizen reports with photo upload presigning.
3. In backend/src/hawa_backend/core/intel_client.py, verify robust error handling, automated retry with exponential backoff for WAQI and OpenAQ API requests, and graceful fallback when external network calls time out.
4. Expand test suites in backend/tests/ to verify status codes, contract schema compliance, and performance under simulated concurrency.
```

---

## 4. Mobile App Engineer (Flutter)

### Role Responsibilities
Owns the cross-platform Flutter application for Citizens, Field Drivers, Site Inspectors, and School Administrators.

### Task Checklist
- [ ] Finalize offline outbox SQLite database drainer with automatic network connectivity listeners.
- [ ] Implement push notification listeners (Firebase Cloud Messaging) for GRAP alert stage changes and morning thermal inversion warnings.
- [ ] Complete Inspector Target Outcome screen with mandatory geo-fenced photo capture and EXIF integrity checks.
- [ ] Complete Driver Route guidance with turn-by-turn waypoint acknowledgment and misting cannon on/off telemetry toggles.
- [ ] Optimize vector tile basemap rendering on low-end Android hardware.
- [ ] Run `flutter build apk --release` and verify 0 crash reports and zero memory leaks.

### Execution Prompt for Mobile App Engineer
```text
You are the Lead Mobile Application Engineer for the HawaCitizen / HawaCommand Flutter app in app_frontend/.

Tasks to Execute:
1. In app_frontend/lib/features/citizen_reports/, wire camera capture with image compression (target under 800 KB) and outbox synchronization.
2. In app_frontend/lib/features/citizen_air/presentation/air_near_me_screen.dart, verify smooth 60fps scrolling on Android and iOS devices, ensuring zero RenderFlex overflow across all screen sizes.
3. In app_frontend/lib/core/sync/outbox_drainer.dart, ensure network state changes trigger background sync without locking the UI thread.
4. Verify full localization support (English and Hindi) across all citizen navigation screens.
Provide test verification logs and release APK build metrics.
```

---

## 5. Web Frontend Engineer

### Role Responsibilities
Owns Next.js command console, MapLibre GL 3D geospatial visualizations, What-If simulation playground, and public landing page.

### Task Checklist
- [ ] Connect the Command Console live map to backend WebSocket streams for real-time sweeper and anti-smog gun telemetry.
- [ ] Implement Deck.gl 3D extruded hexagon layers for displaying 500m cell PM2.5 concentrations and population density.
- [ ] Connect the What-If simulation slider controls to the backend simulation engine to preview counterfactual emissions reduction in real time.
- [ ] Finalize the Public Air Portal at `/open` with searchable ward scorecard tables and CSV/GeoJSON export buttons.
- [ ] Perform WCAG 2.1 AA accessibility audit across all console dashboards and high-contrast color palettes.

### Execution Prompt for Web Frontend Engineer
```text
You are the Senior Frontend Engineer for the HawaCommand Web Platform in frontend/.

Tasks to Execute:
1. In frontend/src/app/(console)/map/, wire live MapLibre GL and Deck.gl layers to fetch the 500m Kriging digital twin grid from the backend /v1/twin endpoint.
2. In frontend/src/app/(console)/plans/[id]/, complete the interactive plan approval workflow allowing officers to inspect route geometry, adjust dispatch hours, and approve machine deployments.
3. In frontend/src/components/impact/SyntheticControlChart.tsx, ensure causal verification charts clearly display pre-treatment fit, treatment intervention point, and post-treatment divergence bands.
4. Validate that production builds succeed without TypeScript or lint warnings via pnpm build.
```
