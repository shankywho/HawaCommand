# HawaCommand AI-ML API and Data Contracts

<!-- nav:start -->

**Navigate:** [Project](../README.md) · [Docs hub](../docs/README.md) · [Overview](../docs/SYSTEM_OVERVIEW.md) · [AWS architecture](../docs/AWS_ARCHITECTURE.md) · [AWS setup](../docs/AWS_SETUP_GUIDE.md) · [API](../docs/backend/API.md) · [Environment](../docs/ENVIRONMENT_VARIABLES.md) · [Contracts](../docs/CONTRACTS.md)

**AI-ML docs:** [Runbook](README.md) · [Index](../docs/aiml/README.md) · [Context](../docs/aiml/CONTEXT.md) · [Architecture](../docs/aiml/ARCHITECTURE.md) · [Models](../docs/aiml/MODELS.md) · [Agents](../docs/aiml/AGENTS.md) · [Data and training](../docs/aiml/DATA_AND_TRAINING.md) · **Engine contracts** · [Structure](../docs/aiml/STRUCTURE.md) · [Plan](../docs/aiml/PLAN.md)

<!-- nav:end -->

The interfaces the AI-ML engine exposes as built: the telemetry packet schema, every HTTP endpoint with real request and response shapes, the Python symbols the backend imports in-process, the shared Pydantic models, and the JSON files the engine reads and writes. Examples were captured from the running app on 2026-10-10 (offline of any API keys, so LLM text is the deterministic template).

Status vocabulary: **Implemented**, **Partial**, **Stub/Mock**, **Planned** (see [README §1](README.md#1-implementation-status)). The system-wide contracts the AI-ML team was designed against (Kafka topics, database tables, `/internal/v1/*` service endpoints with bearer auth) are in [../docs/CONTRACTS.md](../docs/CONTRACTS.md); none of those are implemented in `AI-ML/` yet (§7).

---

## 1. Conventions

| Item | As implemented |
|---|---|
| Units | PM and NO2 sub-index inputs in µg/m³; gas packet fields in ppb; temperature °C; RH %; pressure hPa; speed km/h; wind m/s with direction "from" in degrees |
| Time | ISO 8601 with UTC offset (`datetime.now(timezone.utc).isoformat()`), e.g. `2026-10-10T05:16:05.230684+00:00` |
| Grid cell id | `G-{row:03d}-{col:03d}` from `geo.get_cell_id`: row and column of a 500 m (or 1 km) square counted from the origin 28.40 N, 76.84 E with a local equirectangular projection (110,852 m per degree latitude, 97,710 m per degree longitude). The same format is used for both cell sizes |
| Ward | `Ward-1` .. `Ward-12`, assigned as `(row % 12) + 1` (synthetic) |
| Plan id | `PLAN-{YYYYMMDD-HHMM}` (UTC); task ids `TASK-001`, `TASK-002`, ... |
| Intervention id | Free string in the API (ignored); `INT-{YYYYMMDDHHMM}` for seeded interventions |
| Errors | FastAPI defaults: HTTP 422 with `{"detail": [...]}` for validation errors, 404 for unknown paths. No custom error body |
| Auth | None. CORS allows all origins, methods and headers with credentials |

---

## 2. Telemetry packet (Proposal §10.6)

> Status: Implemented as a Pydantic model (`hawa_ml.schemas.TelemetryPacket`) accepted by `POST /ingest/telemetry` and produced by the simulator. MQTT transport on `hawa/v1/{deviceId}/telemetry` is Planned: no MQTT client exists in `AI-ML/`, and `device_sim.py --mode mqtt` only writes the JSONL file.

| Field | Type | Required | Validation / default |
|---|---|---|---|
| `v` | int | no | default 1 |
| `dev` | string | yes | device id, e.g. `HPM-1000`, `HPS-001-OUT`, `HTAG-01` |
| `role` | enum `DeviceRole` | yes | `M` (mobile), `S` (sentinel), `TAG` (intervention tag), `EYE` (vision) |
| `seq` | int | yes | ≥ 0 |
| `ts` | datetime | yes | ISO 8601 |
| `gps.lat`, `gps.lon` | float | yes | -90..90, -180..180 |
| `gps.spd` | float | no | ≥ 0, default 0.0 (km/h) |
| `gps.hdop` | float | no | ≥ 0, default 1.0 |
| `pm.pm1` | float | no | 0..2000 |
| `pm.pm25` | float | yes | 0..2000 |
| `pm.pm10` | float | yes | 0..3000 |
| `gas.no2_ppb`, `gas.so2_ppb` | float | no | 0..5000 |
| `gas.co_ppb` | float | no | 0..100000 |
| `gas.voc_kohm` | float | no | 0..1000 |
| `env.t` | float | yes | -10..60 |
| `env.rh` | float | yes | 0..100 |
| `env.p` | float | no | 800..1200, default 1013.25 |
| `flags` | string[] | no | default `[]`; the simulator adds `heater_on` above 75 % RH |
| `fw` | string | no | default `1.0.0` |
| `batt` | float | no | 0..15, default 4.0 |
| `intervention.flow_lpm`, `intervention.pump_current_a` | float | no | ≥ 0 (only set by the simulator for `TAG`) |
| `intervention.spraying` | bool | no | default false |

```json
{
  "v": 1, "dev": "HPM-1000", "role": "M", "seq": 101, "ts": "2026-10-10T04:47:52.374953Z",
  "gps": {"lat": 28.67071, "lon": 77.2273, "spd": 25.7, "hdop": 0.9},
  "pm": {"pm1": 115.7, "pm25": 178.0, "pm10": 305.1},
  "gas": {"no2_ppb": 35.0, "co_ppb": 1200.0, "so2_ppb": 8.0, "voc_kohm": 45.0},
  "env": {"t": 10.3, "rh": 99.2, "p": 1013.2},
  "flags": ["heater_on"], "fw": "1.4.2", "batt": 4.05, "intervention": null
}
```

(First line of `data/interim/simulated_telemetry.jsonl`.)

---

## 3. HTTP API

`hawa_ml.api.main:app` (FastAPI, title "HawaCommand AI-ML Engine API", version 1.0.0). The router in `hawa_ml.api.routes` is mounted three times, so each path below also answers under `/v1` and `/internal/v1`. The backend calls the un-prefixed paths. Run with `uvicorn hawa_ml.api.main:app --port 8100`.

### 3.1 `GET /health`, `GET /healthz`

> Status: Implemented. Model names are fixed strings; nothing is probed.

```json
{
  "status": "healthy",
  "service": "hawa-ml-engine",
  "timestamp": "2026-10-10T05:15:43.612915+00:00",
  "offline_mode": false,
  "llm_provider": "groq",
  "models": {
    "forecaster": "LightGBM Quantile (1h..72h)",
    "digital_twin": "Gaussian Process Kriging (500m)",
    "source_attribution": "LightGBM + Domain Heuristics",
    "causal_verifier": "Synthetic Control with Placebo CI"
  }
}
```

`llm_provider` echoes the `LLM_PROVIDER` setting, not the client actually in use (with no key it is the template client).

### 3.2 `GET /twin`

> Status: Partial. Each call fits two Gaussian processes (PM2.5, PM10) on four hard-coded observations (Connaught Place 235/380, AIIMS 195/310, Punjabi Bagh 285/460, Anand Vihar 290/440 µg/m³) and predicts all 10,600 cells.

| Query | Type | Default | Notes |
|---|---|---|---|
| `bbox` | `min_lat,min_lon,max_lat,max_lon` | none | Filters on cell centroid; unparsable values are ignored silently |
| `ts` | string | now | Echoed in `timestamp`; does not change the computation |
| `limit` | int | 500 | Maximum 2000 (422 above) |

```json
{
  "timestamp": "2026-10-10T05:15:48.065022+00:00",
  "total_cells": 10600,
  "returned_cells": 2,
  "cells": [
    {
      "cell_id": "G-000-000", "row": 0, "col": 0,
      "latitude": 28.402255259264603, "longitude": 76.8425585917511,
      "population": 392.5706787109375, "vulnerability_weight": 1.0,
      "primary_land_use": "residential", "road_density_km_km2": 2.1896387705335356,
      "nearest_school_dist_m": 25492.126441728964, "schools_nearby_count": 0,
      "nearest_hospital_dist_m": 27365.310812748834, "hospitals_nearby_count": 0,
      "ward": "Ward-1",
      "pm25_est": 103.2, "pm10_est": 166.1, "variance": 175.1, "confidence": 0.68
    }
  ]
}
```

`primary_land_use` is one of `hospital_cluster`, `school_cluster`, `dense_residential`, `industrial_outskirts`, `residential`. `variance` is the PM2.5 posterior variance; `confidence = clip(exp(-variance/450), 0.20, 0.98)`.

### 3.3 `GET /forecast/{cell_id}`

> Status: Partial. `cell_id` is only echoed; the 7 horizons depend on the `pm25` query value and the current UTC time (see [docs/aiml/MODELS.md §7](../docs/aiml/MODELS.md)).

| Query | Type | Default |
|---|---|---|
| `pm25` | float | 210.0 (current PM2.5, µg/m³) |

```json
{
  "cell_id": "G-052-054",
  "peak_horizon_h": 1,
  "peak_pm25_p50": 209.6,
  "peak_pm25_p90": 290.1,
  "grap_stage": "Very Poor",
  "grap_stage_number": 2,
  "mandated_actions": ["Daily water sprinkling along with dust suppressants on primary roads", "..."],
  "summary": "Cell G-052-054 is projected to peak at PM2.5 209.6 µg/m³ (P90 290.1 µg/m³) in +1 hours. This triggers CAQM Very Poor at an AQI of 369. Municipal actions should initiate 24-48h ahead to suppress particulate build-up before morning school hours.",
  "points": [
    {
      "horizon_h": 1, "valid_time": "2026-10-10T06:15:...+00:00",
      "pm25_p10": 148.6, "pm25_p50": 209.6, "pm25_p90": 290.1, "pm10_p50": 345.8,
      "aqi_p50": 369, "aqi_category": "Very Poor",
      "grap_stage": "Very Poor", "grap_stage_number": 2,
      "mandated_actions": ["..."]
    }
  ],
  "horizons": ["same 7 objects as points"]
}
```

`points` and `horizons` are the same list (horizons 1, 3, 6, 12, 24, 48, 72); `horizons` exists for the backend, which reads that key. `grap_stage` values are the stage names from `config/grap.yaml` (`Poor`, `Very Poor`, `Severe`, `Severe Plus`) or `Normal / Moderate` with stage number 0. `pm10_p50` is `1.65 x pm25_p50`. Captured horizon P50 values for `pm25=245`: 209.6, 151.3, 143.0, 186.3, 195.2, 116.4, 105.2.

### 3.4 `GET /hotspots`

> Status: Partial. The PM field is synthetic (`pm25_est = 210 + 1.5 x row`, `pm10_est = 1.6 x pm25_est`); at that PM2.5/PM10 ratio every hotspot classifies as `unknown` with action `monitor`.

| Query | Type | Default | Notes |
|---|---|---|---|
| `ward` | string | `all` | Case-insensitive match on `Ward-N`; an unknown ward silently returns all wards |
| `limit` | int | 10 | Maximum 50 |
| `hour` | int | 8 | 0-23; selects diurnal population multipliers and attribution hour rules |

Response: `Hotspot[]` ranked by `exposure_score` (person-µg/m³-hours above 60 µg/m³, unnormalised).

```json
[
  {
    "cell_id": "G-050-072",
    "rank": 1,
    "exposure_score": 5330918.3,
    "pm25": 285.0,
    "pm10": 456.0,
    "cause": "unknown",
    "cause_confidence": 0.4,
    "recommended_asset": "monitor",
    "suspect_pin": {"lat": 28.67925, "lon": 77.08578, "distance_m": 13500.0, "spread_m": 1160.0},
    "ward": "Ward-3"
  }
]
```

### 3.5 `POST /plans/draft`

> Status: Partial. Ranks hotspots from the static grid with constant PM2.5 180 / PM10 280 (not the twin), allocates assets greedily, then runs the Auditor. Nothing is persisted.

Request body (`DraftPlanRequest`, required; `{}` is valid):

```json
{
  "ward": "all",
  "limit_hotspots": 10,
  "shift_hours": 4.0,
  "assets": [
    {"id": "SPR-04", "type": "sprinkler", "depot_lat": 28.6476, "depot_lon": 77.3, "capacity_litres": 10000},
    {"id": "ASG-02", "type": "smog_gun", "depot_lat": 28.674, "depot_lon": 77.131, "capacity_litres": 8000},
    {"id": "INSP-01", "type": "inspection_team", "depot_lat": 28.6139, "depot_lon": 77.209, "capacity_litres": 0}
  ]
}
```

The three assets shown are the defaults used when `assets` is empty. `AssetSpec.type` values the optimiser understands: `sprinkler`, `smog_gun`, `sweeper`, `inspection_team` (any other type is never assigned). `depot_lat` and `depot_lon` are required; `capacity_litres` defaults to 10000 and is not enforced.

Response:

```json
{
  "plan_id": "PLAN-20261010-0516",
  "created_at": "2026-10-10T05:16:05.230684+00:00",
  "status": "draft",
  "total_exposure_avoided_person_hours": 689048.0,
  "tasks": [
    {
      "task_id": "TASK-001",
      "asset_id": "ASG-02",
      "cell_id": "G-050-072",
      "action": "suppress_unknown",
      "eta_start": "2026-10-10T05:28:13.402262+00:00",
      "eta_end": "2026-10-10T06:28:13.402262+00:00",
      "expected_pm_reduction_pct": 5.0,
      "reason": "Cause is unknown (conf 40%). Targeting 142158 person-hours exposure reduction."
    }
  ],
  "planner_reasoning": "Dispatched 5 machines targeting 689048 person-hours of exposure avoided. Fleet routes are prioritized around morning school assembly hours and vulnerable pediatric zones.",
  "hotspots": ["Hotspot objects considered (see 3.4)"],
  "auditor_verdict": "approved",
  "auditor_critique": "Plan verified and approved. All 5 assigned machine tasks match their respective cause classifications (road dust suppression) and respect operational shift limits."
}
```

`auditor_verdict` is `approved` or `revise`. `action` is `suppress_{cause}`. With an LLM key configured, `planner_reasoning` and `auditor_critique` contain model text instead of the templates.

### 3.6 `POST /plans/{plan_id}/simulate`

> Status: Stub/Mock. `plan_id` is copied into the response, not looked up. The baseline is a fixed 32 % of the AI result, so `gain_percentage` is always 212.5.

Request body (`SimulatePlanRequest`, required; `{}` uses the top 5 hotspots from the static grid and assets SPR-04 and ASG-02):

```json
{"hotspots": [], "assets": []}
```

Response:

```json
{
  "ai_plan": {"person_hours_avoided": 689048.0, "tasks_count": 5, "schools_protected": 3, "exposure_reduction_per_kl_water": 38280.4},
  "usual_fixed_route_baseline": {"person_hours_avoided": 220495.3, "tasks_count": 2, "schools_protected": 0, "exposure_reduction_per_kl_water": 12249.7},
  "comparison": {
    "delta_person_hours_avoided": 468552.6,
    "gain_percentage": 212.5,
    "summary": "AI Dispatch achieves 212.5% more person-hours of exposure avoided than usual fixed routes with the EXACT SAME vehicle fleet and water usage."
  },
  "plan_id": "PLAN-X"
}
```

There is no `delta_gain_pct` key, which the backend expects (see [README §8](README.md#8-integration-with-other-components)).

### 3.7 `POST /interventions/{intervention_id}/verify`, `GET|POST /interventions/{intervention_id}/impact`

> Status: Stub/Mock. Every call runs `verify_injected_intervention_recovery()` on the same seeded synthetic panel. Side effects: updates `data/internal/effectiveness_library.json` (`road_dust:water_sprinkler`) and rewrites `reports/verifier_metrics.json`. The GET variant has the same side effects.

No body. Response:

```json
{
  "intervention_id": "INT-ANY",
  "method": "synthetic_control",
  "measured_effect_pct": -18.82,
  "ci_low_pct": -22.24,
  "ci_high_pct": -15.4,
  "duration_minutes": 90,
  "status": "statistically_significant",
  "acceptance_check_passed": true
}
```

`status` is `statistically_significant` when the recovery test passes, else `inconclusive`. `duration_minutes` is a constant.

### 3.8 `GET /insights`

> Status: Stub/Mock. Scans the first 20 grid cells with fixed values (PM2.5 265, `school_cluster`, 3 schools, population 7500, exposure 28000); only the school trigger can fire. `since` is accepted and ignored.

```json
{
  "count": 1,
  "insights": [
    {
      "insight": {
        "id": "INS-SCH-G-000-000",
        "trigger_type": "school_morning_exposure",
        "severity": "warning",
        "title": "High Exposure at School Cluster (G-000-000)",
        "cell_id": "G-000-000",
        "evidence": {"pm25": 265.0, "population": 7500.0, "schools_nearby": 3, "ward": "Ward-1"},
        "confidence": 0.85,
        "recommended_action": "Dispatch water sprinkler before 6:30 AM; alert principal to hold assembly indoors.",
        "created_at": "2026-10-10T05:16:28.067703+00:00"
      },
      "narrative": {
        "insight_id": "INS-SCH-G-000-000",
        "narrative_en": "WHAT: High particulate concentration (PM2.5 265 µg/m³) during morning hours. WHERE: Cell G-000-000 (Ward-1). WHY: Road dust accumulation and cold morning inversion (confidence 85%). WHO: Approximately 7500 residents and students across 3 nearby schools. WHAT TO DO: Dispatch water sprinkler before 6:30 AM; alert principal to hold assembly indoors. EXPECTED EFFECT: Water suppression cuts PM10 by ~18.5% for approximately 90 minutes.",
        "narrative_hi": "चेतावनी: सेल G-000-000 में सुबह 3 स्कूलों के पास PM2.5 का स्तर 265 µg/m³ है। सुझाव: सुबह की प्रार्थना सभा अंदर आयोजित करें और 6:30 बजे से पहले पानी का छिड़काव करें।",
        "recommended_action": "Dispatch water sprinkler before 6:30 AM; alert principal to hold assembly indoors."
      }
    }
  ]
}
```

`trigger_type` values the engine can emit: `grap_threshold_crossing` (critical), `school_morning_exposure` (warning), `twin_blind_spots` (info), `sudden_spike` (critical).

### 3.9 `POST /ingest/telemetry`

> Status: Partial. Applies the per-device drive-by calibration to PM2.5 and returns it. Nothing is stored, forwarded or added to the twin. Unknown devices get an identity profile (trust 1.0).

Body: one `TelemetryPacket` (§2) or a JSON array of them. Response:

```json
{
  "ingested_count": 2,
  "records": [
    {"dev": "HPM-1", "seq": 1, "raw_pm25": 145.0, "calibrated_pm25": 145.0, "trust_score": 1.0, "status": "ingested"},
    {"dev": "HPM-TEST-CALIB", "seq": 2, "raw_pm25": 145.0, "calibrated_pm25": 161.6, "trust_score": 0.92, "status": "ingested"}
  ]
}
```

### 3.10 `GET /effectiveness-library`, `GET /effectiveness`

> Status: Implemented (returns the persisted library).

```json
{
  "records": [
    {
      "cause": "road_dust", "action": "water_sprinkler", "conditions": "daytime_dry",
      "pm10_reduction_pct": 18.9, "pm25_reduction_pct": 6.5, "duration_minutes": 93,
      "ci_low_pct": -22.2, "ci_high_pct": -15.4, "sample_count": 80, "last_updated": ""
    }
  ]
}
```

Five records at HEAD: `road_dust:water_sprinkler`, `road_dust:smog_gun`, `road_dust:sweeper`, `open_burning:inspection_team`, `traffic:traffic_advisory`. Reductions are positive percentages; `ci_*` for the sprinkler record are negative (effect sign) while the others are positive (reduction sign). `sample_count` grows with every verification call.

---

## 4. In-process Python API used by the backend

The backend imports these symbols directly, so their names and return shapes are a de-facto public API. All are module-level singletons created at import time; they share state with the HTTP app in the same process and write the same files under `AI-ML/data/`.

| Symbol | Import path | Called as | Returns | Backend call site |
|---|---|---|---|---|
| `get_twin_engine()` | `hawa_ml.api.deps` | `.fit_and_predict(obs_points)` with dicts `{latitude, longitude, pm25, pm10}` | `pandas.DataFrame` of all grid cells plus `pm25_est`, `pm10_est`, `variance`, `confidence` | `core/intel_client.py:287` |
| `get_exposure_engine()` | `hawa_ml.api.deps` | `.get_ranked_hotspots(df, top_n, hour, ward)` | `list[Hotspot]` | `intel_client.py:437`, `:964` |
| `get_forecaster()` | `hawa_ml.api.deps` | `.predict_cell_forecast(cell_id, current_pm25=...)` | list of 7 forecast point dicts (§3.3) | `intel_client.py:437`, `:632` |
| `get_grid()` | `hawa_ml.api.deps` | — | 500 m grid `DataFrame` | `intel_client.py:437`, `:964` |
| `get_whatif_simulator()` | `hawa_ml.api.deps` | `.simulate_comparison(hotspots, assets)` | dict as §3.6 without `plan_id` | `intel_client.py:964` |
| `get_effectiveness_library()` | `hawa_ml.api.deps` | `.records.values()` | `EffectivenessRecord` dataclasses | `intel_client.py:1133` |
| `forecaster_agent` | `hawa_ml.api.deps` | `.analyze_forecast(cell_id=..., current_pm25=...)` | dict as §3.3 | `intel_client.py:541` |
| `planner_agent`, `auditor_agent` | `hawa_ml.api.deps` | `.draft_plan(assets=, ward=, limit_hotspots=, shift_hours=)`; `.audit_plan(tasks, hotspots)` | plan dict as §3.5 without the auditor keys; `(verdict, critique)` | `intel_client.py:729` |
| `drive_by_calibrator` | `hawa_ml.api.deps` | `.calibrate_reading(device_id, raw_pm25, rh)` | `(calibrated_pm25, trust_score)` | `intel_client.py:1198` |
| `AssetSpec`, `PlanTask`, `Hotspot` | `hawa_ml.schemas` | constructors | Pydantic models (§5) | `intel_client.py:730`, `:965` |
| `verify_injected_intervention_recovery()` | `hawa_ml.causal.placebo` | no arguments | `{injected_pct, recovered_pct, error, ci_low, ci_high, p_value, is_significant, duration_minutes, passed}` | `intel_client.py:1064` |
| `safe_route_optimizer` | `hawa_ml.exposure.routing` | `.default_bg_pm25 = x` (mutated by the backend), `.compute_route_alternatives(origin, destination, mode)` | `{origin, destination, mode, ventilation_rate_lpm, fastest, cleanest, balanced}`; each route has `label, tagline, distance_km, duration_min, avg_pm25, inhaled_dose_ug, dose_saved_pct, air_grade, highlights[], waypoints[[lat, lon]]` (+ `time_delta_min` for cleanest/balanced) | `api/routes/citizen.py:7`, `:42-45` |
| `safe_window_calculator` | `hawa_ml.forecasting.safe_window` | `.baseline_pm25 = x` (mutated), `.compute_daily_window(lat, lon, persona)` | `{persona, persona_label, threshold_pm25, has_safe_window, recommended_window, lowest_pm25, danger_window, peak_pm25, recommendation, timeline[24]}`; personas `asthma_elderly`, `children_school`, `runners_athletes`, `general` | `citizen.py:8`, `:65-68` |
| `iot_auditor`, `FLEET_TELEMETRY` | `hawa_ml.simulation.audit` | `.audit_missed_intervention(asset_id, cell_id, ward, reported_by)`; dict of 3 assets | `{report_id, timestamp, asset_id, ward, verdict, sla_breach, message, ...}`; verdicts `MACHINE_ACTIVE_VERIFIED`, `SLA_BREACH_CONFIRMED` (adds `penalty_fine_inr: 25000`, `contractor_id`), `UNDER_INVESTIGATION` | `citizen.py:9`, `:77`, `:128` |

Because the backend assigns `default_bg_pm25` and `baseline_pm25` on shared singletons before each call, concurrent requests can see each other's values.

---

## 5. Shared Pydantic models (`hawa_ml.schemas`)

| Model | Fields | Used by |
|---|---|---|
| `DeviceRole` (enum) | `M`, `S`, `TAG`, `EYE` | `TelemetryPacket` |
| `GPSData`, `PMData`, `GasData`, `EnvData`, `InterventionTelemetry`, `TelemetryPacket` | §2 | ingest, simulator |
| `SourceClass` (enum) | `road_dust`, `dust`, `traffic`, `open_burning`, `burning`, `regional_smoke`, `industrial`, `mixed`, `unknown` | attribution, hotspots; only `road_dust`, `traffic`, `open_burning`, `regional_smoke`, `industrial`, `unknown` are produced |
| `SuspectPin` | `lat, lon, distance_m, spread_m` | back-trajectory |
| `Hotspot` | `cell_id, rank, exposure_score, pm25, pm10, cause: SourceClass, cause_confidence, recommended_asset, suspect_pin?, ward?` | `/hotspots`, planner, optimiser, auditor |
| `AssetSpec` | `id, type, depot_lat, depot_lon, capacity_litres=10000.0` | plan endpoints |
| `PlanTask` | `task_id, asset_id, cell_id, action, eta_start, eta_end, expected_pm_reduction_pct, reason` | optimiser output |
| `InsightSeverity` (enum) | `info`, `warning`, `critical` | insights |
| `Insight` | `id, trigger_type, severity, title, cell_id?, evidence{}, confidence, recommended_action, created_at` | `/insights` |
| `Narrative` | `insight_id, narrative_en, narrative_hi?, recommended_action` | `/insights` |
| `CellState`, `ForecastPoint`, `PlanDraft`, `SyntheticControlResult` | defined | not used by any code path |

---

## 6. File contracts

These files are read and written at run time. Four of them are tracked in git and change whenever tests, the demo seed or verification run (see [data/README.md](data/README.md)).

| File | Format | Writer | Reader |
|---|---|---|---|
| `data/internal/effectiveness_library.json` | object keyed `"{cause}:{action}"` → `EffectivenessRecord` (`cause, action, conditions, pm10_reduction_pct, pm25_reduction_pct, duration_minutes, ci_low_pct, ci_high_pct, sample_count, last_updated`) | `EffectivenessLibrary.save()` (seeds 5 priors if missing; updates on every verification) | optimiser, `/effectiveness-library`, backend |
| `data/internal/calibration_profiles.json` | object keyed by device id → `DeviceCalibrationProfile` (`dev_id, slope_a, rh_coef_b, offset_c, trust_score, version, last_calibrated, mae_before, mae_after, r2_after, co_location_samples`) | `DriveByCalibrator.fit_calibration()` | `calibrate_reading()` |
| `data/internal/synthetic_data/known_interventions.json` | array of `InjectedIntervention` (`intervention_id, asset_id, action_type, lat, lon, cell_id, start_time, end_time, radius_m, true_pm10_reduction_pct, true_pm25_reduction_pct, duration_minutes, decay_half_life_min`) | `InterventionManager.inject_default_demo_intervention()` (append) | `FleetSimulator` (attenuation) |
| `data/fixtures/demo_scenario.json` | `{scenario_name, created_at, hotspots[3], forecast_outlook, injected_intervention}` | `scripts/demo_seed.py` | nothing in `AI-ML/` |
| `data/interim/simulated_telemetry.jsonl` | one `TelemetryPacket` JSON per line | `FleetSimulator.run_file_mode()` | nothing in `AI-ML/` |
| `models/lgb_pm25_{h}h_{p10,p50,p90}.txt` | LightGBM text boosters, 37 unnamed features (`Column_0..36`) in `features.py` order | `forecasting/train.py` | `forecasting/predict.py` |
| `models/attribution_classifier.txt` | LightGBM multiclass (5) booster, 11 features | `attribution/classifier.py` | `AttributionClassifier` (not used at run time) |
| `reports/forecast_metrics.json` | `{"1h": {mae_p50, rmse_p50, mae_persistence, skill_vs_persistence_pct, coverage_p10_p90_pct, pinball_p10, pinball_p50, pinball_p90}, ...}` | `forecasting/train.py` | `tests/test_phase2_forecast.py` |
| `reports/twin_metrics.json` | `{mae_kriging_gp, rmse_kriging_gp, mae_nearest_station_baseline, mae_idw_baseline, skill_vs_nearest_station_pct, evaluated_stations_count}` | `twin/kriging.py` | `tests/test_phase3_twin_sim.py` (existence only) |
| `reports/verifier_metrics.json` | `{injected_pct, recovered_pct, error, ci_low, ci_high, p_value, is_significant, duration_minutes, passed}` | `causal/placebo.py` | nothing |

---

## 7. Planned contracts

> Status: Planned. Designed in [../docs/CONTRACTS.md](../docs/CONTRACTS.md) and [../docs/aiml/ARCHITECTURE.md](../docs/aiml/ARCHITECTURE.md); not implemented in `AI-ML/`.

| Contract | Target design |
|---|---|
| Internal service surface | `POST /internal/v1/simulate` (Monte Carlo What-If with P10/P50/P90), `POST /internal/v1/optimize`, `POST /internal/v1/exposure`, `POST /internal/v1/alerts/draft`, `GET /internal/v1/models`, `GET /metrics`, all behind `Authorization: Bearer <HAWA_INTERNAL_TOKEN>` with RFC 9457 problem responses |
| MQTT ingest | Devices publish `TelemetryPacket` on `hawa/v1/{deviceId}/telemetry`; the backend ingest worker cleans and forwards to Kafka |
| Kafka commands and events | Consumer groups `intel-twin`, `intel-forecast`, `intel-plan`, `intel-verify`, `intel-spike`, `intel-vision`, `intel-trainer` and others on `hawa.cmd.*.v1` and `hawa.*` event topics, producing `twin.updated`, `hotspot.updated`, `forecast.issued`, `plan.drafted`, `impact.verified` |
| Database tables | AI-ML-owned writes to `cell_state`, `hotspot`, `forecast`, `grap_outlook`, `plan`, `plan_task`, `plan_review`, `plan_simulation`, `impact`, `effectiveness_library`, `device_calibration`, `model_version` and others |
| Identifiers and versions | `g500-RRR-CCC` / `g1k-RRR-CCC` cells on an EPSG:32643 grid, `ward-NNN`, and a `model_version` string `{model}@{semver}+{git_sha7}` on every output |
| Uncertainty on every output | Twin variance per pollutant, forecast quantiles, cause probabilities, verification CI and placebo p-value, carried end to end |

<!-- footer:start -->

---

[Back to top](#hawacommand-ai-ml-api-and-data-contracts) · [Docs hub](../docs/README.md) · [Project README](../README.md)

<!-- footer:end -->
