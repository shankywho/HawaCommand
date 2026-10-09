# HawaCommand AI-ML API & Data Contracts

This document establishes the strict schemas, endpoints, and data contracts between the **AI-ML Engine** and all external consumers (Backend, Fleet Simulator, Web Console, Driver PWA).

---

## 1. MQTT Telemetry Packet Contract (Proposal §10.6)
Both physical sensors (`HawaPod-M`, `HawaPod-S`, `HawaTag`) and the fleet simulator publish packets conforming exactly to this JSON schema:

* **Topic:** `hawa/v1/{deviceId}/telemetry`
* **Schema:**
```json
{
  "v": 1,
  "dev": "HPM-0142",
  "role": "M",
  "seq": 88214,
  "ts": "2026-11-12T01:14:30Z",
  "gps": {
    "lat": 28.6331,
    "lon": 77.2194,
    "spd": 14.2,
    "hdop": 0.9
  },
  "pm": {
    "pm1": 141.0,
    "pm25": 212.0,
    "pm10": 318.0
  },
  "gas": {
    "no2_ppb": 61.0,
    "co_ppb": 1840.0,
    "so2_ppb": 12.0,
    "voc_kohm": 38.0
  },
  "env": {
    "t": 17.8,
    "rh": 82.0,
    "p": 1015.0
  },
  "flags": ["heater_on"],
  "fw": "1.4.2",
  "batt": 4.02,
  "intervention": {
    "flow_lpm": 0.0,
    "pump_current_a": 0.0,
    "spraying": false
  }
}
```

---

## 2. FastAPI Serving Endpoints

### `GET /health`
* **Response:** `200 OK`
```json
{
  "status": "healthy",
  "timestamp": "2026-11-12T06:00:00Z",
  "offline_mode": false,
  "llm_provider": "groq",
  "active_models": {
    "forecaster": "lgb_quantile_v1",
    "twin": "gaussian_process_v1",
    "attribution": "classifier_v1"
  }
}
```

### `GET /twin?bbox={min_lat},{min_lon},{max_lat},{max_lon}&ts={iso_timestamp}`
* **Response:** Vector or GeoJSON FeatureCollection of 500m cells:
```json
{
  "type": "FeatureCollection",
  "timestamp": "2026-11-12T06:00:00Z",
  "features": [
    {
      "type": "Feature",
      "id": "C-2863-7721",
      "geometry": {
        "type": "Polygon",
        "coordinates": [...]
      },
      "properties": {
        "pm25_est": 234.5,
        "pm10_est": 368.1,
        "variance": 14.2,
        "confidence": 0.88,
        "cause_label": "road_dust",
        "cause_confidence": 0.81,
        "exposure_score": 1284.0
      }
    }
  ]
}
```

### `GET /forecast/{cell_id}`
* **Response:** 72-hour forecast at discrete horizons with P10/P50/P90 quantiles and GRAP stage:
```json
{
  "cell_id": "C-2863-7721",
  "issued_at": "2026-11-12T06:00:00Z",
  "horizons": [
    {
      "horizon_h": 24,
      "valid_time": "2026-11-13T06:00:00Z",
      "pm25_p10": 195.0,
      "pm25_p50": 265.0,
      "pm25_p90": 340.0,
      "pm10_p50": 395.0,
      "aqi_p50": 405,
      "grap_stage": "Stage 3 (Severe)",
      "lead_time_compliant": true
    }
  ]
}
```

### `GET /hotspots?ward={ward_id}&limit={n}`
* **Response:** Hotspots ranked strictly by human exposure:
```json
[
  {
    "cell_id": "C-2863-7721",
    "rank": 1,
    "exposure_score": 18420.5,
    "pm25": 284.0,
    "pm10": 420.0,
    "cause": "road_dust",
    "cause_confidence": 0.84,
    "vulnerability_factors": {
      "schools_nearby": 3,
      "hospitals_nearby": 1,
      "morning_rush_exposed": 12400
    },
    "suspect_pin": {
      "lat": 28.6360,
      "lon": 77.2150,
      "distance_m": 420.0,
      "spread_m": 150.0
    },
    "recommended_asset": "sprinkler"
  }
]
```

### `POST /plans/draft`
* **Request:**
```json
{
  "ward_id": "all",
  "target_window_hours": 4,
  "available_assets": [
    { "id": "ASG-01", "type": "smog_gun", "depot_lat": 28.63, "depot_lon": 77.21, "capacity_litres": 8000 },
    { "id": "SPR-04", "type": "sprinkler", "depot_lat": 28.65, "depot_lon": 77.15, "capacity_litres": 10000 }
  ]
}
```
* **Response:**
```json
{
  "plan_id": "PLAN-20261112-06",
  "created_at": "2026-11-12T06:05:00Z",
  "status": "draft",
  "total_exposure_avoided_person_hours": 34820.0,
  "tasks": [
    {
      "task_id": "TASK-01",
      "asset_id": "SPR-04",
      "cell_id": "C-2863-7721",
      "action": "water_sprinkling",
      "eta_start": "2026-11-12T06:45:00Z",
      "eta_end": "2026-11-12T08:15:00Z",
      "expected_pm10_reduction_pct": 18.5,
      "reason": "Road dust causing 18.4k person-hrs exposure near 3 schools before morning assembly."
    }
  ],
  "agent_insights": {
    "planner_reasoning": "Prioritized SPR-04 to Anand Vihar sector due to 8 AM school assembly vulnerability.",
    "auditor_verdict": "approved",
    "auditor_critique": "Plan respects asset capacities and does not allocate water suppression to biomass burning."
  }
}
```

### `POST /plans/{id}/simulate`
* **Response:** What-If comparison between AI Plan vs "Usual Fixed Routes" baseline:
```json
{
  "plan_id": "PLAN-20261112-06",
  "ai_plan": {
    "person_hours_avoided": 34820.0,
    "schools_protected": 7,
    "water_efficiency_reduction_per_kilo_litre": 3.48
  },
  "usual_fixed_route_baseline": {
    "person_hours_avoided": 11200.0,
    "schools_protected": 2,
    "water_efficiency_reduction_per_kilo_litre": 1.12
  },
  "delta_gain_pct": 210.89
}
```

### `POST /interventions/{id}/verify`
* **Response:** Synthetic-control causal verification results:
```json
{
  "intervention_id": "INT-9912",
  "cell_id": "C-2863-7721",
  "asset_id": "SPR-04",
  "action": "water_sprinkling",
  "measured_effect_pct": -18.2,
  "ci_low_pct": -23.1,
  "ci_high_pct": -13.4,
  "duration_minutes": 95,
  "p_value": 0.008,
  "method": "synthetic_control",
  "donor_pool_count": 12,
  "effectiveness_status": "statistically_significant"
}
```

### `GET /insights?since={iso_timestamp}`
* **Response:**
```json
[
  {
    "id": "INS-SCH-G-052-054",
    "trigger_type": "school_morning_exposure",
    "severity": "warning",
    "title": "High Exposure at School Cluster (G-052-054)",
    "cell_id": "G-052-054",
    "evidence": {
      "pm25": 284.0,
      "population": 12500,
      "schools_nearby": 3,
      "ward": "Ward 7"
    },
    "confidence": 0.85,
    "recommended_action": "Dispatch water sprinkler before 6:30 AM; alert principal to hold assembly indoors.",
    "narrative_en": "Cell G-052-054 (Ward 7) will likely exceed PM2.5 250 at 8 AM. Likely road dust (85% confidence), 3 schools within 400 m. Send Sprinkler S-12 by 6 AM. Similar past runs cut PM10 about 18.7% for ~90 min.",
    "narrative_hi": "सैल G-052-054 (Ward 7) में सुबह 8 बजे PM2.5 250 पार करने की संभावना है। मुख्य कारण सड़क की धूल (85% विश्वसनीयता), 400 मीटर के भीतर 3 स्कूल हैं।"
  }
]
```

### `POST /ingest/telemetry`
* **Request:** Array of telemetry packets in proposal format or single packet.
* **Response:**
```json
{
  "status": "ingested",
  "received_count": 1,
  "calibrated_count": 1,
  "timestamp": "2026-11-12T06:00:00Z"
}
```

### `GET /effectiveness-library`
* **Response:**
```json
[
  {
    "cause": "road_dust",
    "action": "water_sprinkler",
    "pm10_reduction_pct": 18.7,
    "duration_minutes": 90,
    "ci_low_pct": -22.5,
    "ci_high_pct": -15.0,
    "sample_count": 18,
    "last_updated": "2026-11-12T06:00:00Z"
  }
]
```
