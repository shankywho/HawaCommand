# AI-ML Build Plan

> **Status (2026-10-10).** Code exists for the twin, forecaster, attribution, exposure, greedy optimiser, What-If (constant baseline), causal verifier, four agents, insights, pipelines, simulator and HTTP API; 38 tests pass once `make data && make train` has been run (37/38 on a clean checkout). Still open: OR-Tools CVRP, real forecast features at inference, twin accuracy (loses to nearest-station in `reports/twin_metrics.json`), real What-If baseline, verification of real interventions, Kafka/DB integration, MLflow, Strands, Citizen Eyes vision, anti-gaming guard, coverage router, site score. Defects are in [AI-ML/README.md](../../AI-ML/README.md#9-known-issues).


The hour-by-hour hackathon plan for the ML engineer and the agents person, milestones with acceptance criteria, backend dependencies, cut rules, risks, and the post-hackathon model roadmap.

Related: [README](README.md) · [CONTEXT](CONTEXT.md) · [ARCHITECTURE](ARCHITECTURE.md) · [STRUCTURE](STRUCTURE.md) · [MODELS](MODELS.md) · [AGENTS](AGENTS.md) · [DATA_AND_TRAINING](DATA_AND_TRAINING.md) · [../CONTRACTS.md](../CONTRACTS.md) · [../SYSTEM_OVERVIEW.md](../SYSTEM_OVERVIEW.md)

---

## 1. Team split (§16, SYSTEM_OVERVIEW §11)

| Person | AI-ML responsibilities | Also owns |
|---|---|---|
| **ML engineer** | Data pulls, grid, calibration, fingerprint, exposure, twin, hotspots, forecaster, GRAP outlook, back-trajectory, verifier, effectiveness library | — |
| **Agents person** | Strands agents, prompts, tools, orchestrator, optimiser (OR-Tools + greedy + constraints), What-If, Communicator, Citizen Eyes, intel-service | Flutter app shell and screens (SYSTEM_OVERVIEW §11 "Agents + app"); hardware sheet (§16) |

The §16 table gives "Planner + Auditor with OR-Tools tool" to the agents person, so the optimiser lives with them; the exposure engine and verifier science live with the ML engineer, and the backend lead owns verifier *orchestration* (scheduler, `cmd.verify.run`, dispatch saga).

## 2. Hour-by-hour (24 h)

Checkpoints are at the end of the listed hour. "Fixtures" = Parquet/JSON test data under `tests/fixtures/` built from the simulator library or our own synthetic generator, so AI-ML never waits for a backend service to start work.

| Hours | ML engineer | Agents person (AI-ML share) | Checkpoint |
|---|---|---|---|
| 0–1 | `AI-ML/` skeleton: `pyproject.toml` (uv, path dep `hawa-contracts`), ruff/mypy/pytest/pre-commit, logifyx init. Start background pulls: CPCB, OpenAQ, Open-Meteo history, FIRMS 10 days | Request Bedrock model access (Opus 5, Haiku 4.5) and note inference-profile ids; `HAWA_LLM_MODE=stub`; `llm.py` skeleton; Strands hello-world with one `@tool` and a submit tool | **M0** |
| 1–3 | `build_grid.py`, `worldpop_to_cells.py`, `fetch_osm_pois.py`, `build_cell_features.py`; hand grid/cell/ward/POI seed files to backend at H3; pandera schemas for station and weather frames | `schemas.py` (all Pydantic outputs), `_shared_context.md`, tool factories over a fixture `PlanContext`; Flutter shell in parallel | **M1** |
| 3–5 | Calibration: pairing, Huber fit, fleet shrinkage, versioning, trust score, `device_calibration` writer; tests on simulated coefficients | Optimiser: `problem.py`, `nodes.py`, `constraints.py` (hard rules + property tests), `greedy.py` | |
| 5–7 | Fingerprint rules v1 (four §9.4 rows as soft scores), hotspot clustering and ranking, exposure engine (population profiles, vulnerability weights, §2.5 golden test) | `cvrptw.py` (allowed vehicles, time windows, capacity, disjunctions); Planner and Auditor prompts; `preaudit.py` | |
| 7–8 | Tests and fixtures for calibration, fingerprint, exposure; `hawa-ml publish` CLI to push test commands to Kafka | Orchestrator v1 (optimiser → Planner → Auditor → apply → re-validate → persist) with deterministic fallback; `intel-plan` handler → `plan.drafted` | **M2**, **M3** |
| 8–10 | Twin: super-obs, weights (P-07), trend, two-scale GP, confidence, IDW fallback | What-If (usual-routes baseline, paired Monte Carlo); `intel-service` with auth, `/internal/v1/simulate`, `/optimize`, `/exposure` (frontend's What-If screen needs it by H10) | **M5** |
| 10–11 | `intel-twin` handler end to end on Kafka: `cmd.twin.rebuild` → `cell_state`, `hotspot`, `twin.updated`, `hotspot.updated` | Communicator: advice matrix, templates, length validators | **M4** |
| 11–13 | Forecaster: station training matrix, 3-bucket cut version first, baselines, quantile post-processing; `intel-forecast` handler | Communicator prompt and Hindi examples reviewed by a Hindi speaker; protect-alert tasks; P-05 endpoint | |
| 13–14 | GRAP outlook (Monte Carlo per ward), forecast metrics vs persistence on the test split | Eval suite G1–G4, G10 in stub and Bedrock modes | **M6**, **cut decision** |
| 14–16 | Advection (if kept) and back-trajectory ensemble; LOSO twin evaluation | Spike mode: `intel-spike` → `cmd.plan.draft {mode: spike}`; plan_review summariser; Forecaster agent | |
| 16–19 | Verifier: windows (P-02), donors, synthetic control, placebo, verdicts, DiD/naive fallback; effectiveness priors and incremental update; injected-effect validation on simulator scenarios; `intel-verify` handler | Citizen Eyes (STRETCH) if on schedule, otherwise Auditor hardening and G5–G12; Flutter inspector and school screens in parallel | **M7** |
| 19–22 | Integration and bug bash (everyone): golden path (SYSTEM_OVERVIEW §10) twice on a clean `make demo-reset`; dashboards for `twin_run_seconds`, `plan_draft_seconds`, `verify_runs_total` | Same; Bedrock eval run 5× for blocking scenarios | **M8** |
| 22–24 | Demo video, README, AWS Builder Center blog draft (everyone): record twin + causes, forecast + GRAP, verifier effect ± CI | Record "Auditor rejects a sprinkler on a smoke hotspot" and What-If | **M9** |

## 3. Milestones and acceptance criteria

| ID | By | Milestone | Acceptance criteria (all must hold) |
|---|---|---|---|
| M0 | H1 | Skeleton | `uv sync --all-extras` resolves `hawa-contracts`; `pytest` runs; `ruff check`, `ruff format --check`, `mypy src` clean; logifyx emits JSON lines with `correlation_id` |
| M1 | H3 | Grid and data | Seed files with ≈ 6,000 `g500-` and ≈ 1,500 `g1k-` cells, ids and parent mapping per CONTRACTS §2, area check within 1 %; population total within 0.5 % of WorldPop; ≥ 3 winters of station-hourly data and 10 days of FIRMS in the feature store; pandera passes |
| M2 | H8 | Calibration, fingerprint, exposure | Calibration recovers simulated `a, b` within ±10 % and `c` within ±5 µg/m³ for devices with ≥ 60 pairs; the four §9.4 canonical cases give the expected cause; §2.5 exposure golden case passes; optimiser property tests pass (no machine on burning/regional smoke/traffic; regional-smoke-only input → zero vehicle tasks) |
| M3 | H8 | Plan draft v1 | `cmd.plan.draft` on Kafka → `plan` `drafting` → `draft`, `plan_task`, `plan_review` written, `plan.drafted` published within 150 s; G1 (water on smoke) passes on Bedrock; `HAWA_LLM_MODE=disabled` produces a valid deterministic draft |
| M4 | H11 | Twin live | Every `cmd.twin.rebuild` writes `cell_state` for all cells with `confidence` and variance and publishes `twin.updated`; p95 ≤ 45 s on the pilot fleet; hotspots visible on the web map; IDW fallback verified by fault injection |
| M5 | H10 | What-If | `/internal/v1/simulate` returns plan vs usual routes with P10/P50/P90 and `prob_better` in ≤ 3 s p95; plan identical to baseline gives Δ = 0; `plan.drafted` carries both exposure numbers |
| M6 | H14 | Forecaster, GRAP, Communicator | `forecast` for all g1k cells × 72 h with `p10 ≤ p50 ≤ p90`; 24 h skill vs persistence measured on the test split (target ≥ 0.10; reported honestly if not met); `grap_outlook` for D+1..D+3 per ward; G4 deterministic checks pass (lengths, GSM-7, Devanagari, advice codes, numbers) |
| M7 | H19 | Verifier | On ≥ 50 simulated injected-effect interventions: 95 % CI coverage ≥ 0.85, null false-positive rate ≤ 0.10, bias ≤ 5 pp (full targets in MODELS §12.5 are post-hackathon gates); the demo intervention's injected effect lies inside its CI; `impact.verified` consumed by the backend; library updated |
| M8 | H22 | Golden path | The 7 golden-path steps run twice in a row after `make demo-reset`; spike path spike → draft ≤ 3 min; blocking agent evals (G1, G2, G3, G4, G8, G9, G10) pass 5/5 on Bedrock; every simulated item shows `is_simulated` |
| M9 | H24 | Demo | Recorded: twin with cause labels and suspect pins; forecast spike near three schools and GRAP outlook; Auditor rejecting a sprinkler on smoke; What-If; HawaTag spray → verified effect ± CI (labelled simulated with injected known effect) |

## 4. Dependencies on backend

AI-ML builds against fixtures until each dependency lands, then switches to the live service. Contract tests (`pytest -m contract`) run as soon as the Alembic baseline exists.

| Needed | From backend | By hour | Blocks | Until then |
|---|---|---|---|---|
| `hawa_contracts` package (enums, envelope, event payloads) | contracts | H2 | all handlers | Use CONTRACTS.md JSON examples as fixtures; never define conflicting local names |
| Compose stack (Postgres + PostGIS, Redis, Kafka, MinIO, MLflow) | backend lead | H2 | M3+, M4 | Unit tests only |
| Alembic baseline with AI-ML tables (`twin_run`, `cell_state`, `hotspot`, `forecast_run`, `forecast`, `grap_outlook`, `plan`, `plan_task`, `plan_review`, `plan_simulation`, `impact`, `effectiveness_library`, `device_calibration`, `processed_event`, `model_version`) incl. P-09 columns | backend lead | H6 | M3, M4 | Write to Parquet in tests |
| Seeded `grid_meta`, `cell`, `cell_1k`, `ward`, `poi`, `asset`, `asset_shift` | backend seed (from AI-ML files at H3) | H4 | optimiser, exposure | Fixture tables |
| `asset_usual_route` seed (P-10) | backend seed (AI-ML `seed_usual_routes.py` provides the demo routes) | H8 | M5 | Fixture routes |
| Simulator packets → ingest → `reading` + `hawa.telemetry.clean.v1` | backend | H8 | M4 | Synthetic readings fixture |
| `scheduler` emitting `cmd.twin.rebuild`, `cmd.forecast.run`, `cmd.plan.draft` | backend | H10 | cadence | `hawa-ml publish` CLI |
| `feeds-worker` live CPCB, weather, FIRMS into tables | backend | H10 | live twin/forecast | Feature-store history |
| `POST /v1/plans/draft` → outbox → `cmd.plan.draft`; api calling `/internal/v1/simulate` | backend | H10 | M5 UI | Direct Kafka publish |
| `intervention` rows, `spray.stopped`, `cmd.verify.run` with stage (P-02) | backend | H15 | M7 | Simulator fixture interventions |
| Simulator ground truth + injected effects (P-15) | backend simulator | H15 | M7 validation | AI-ML's own synthetic generator in tests |
| Consumers of `plan.drafted`, `impact.verified`, `report.verified` | backend | H14–H19 | M8 | — |

## 5. Cut rules

From §16: "If behind at hour 14, drop wind advection (keep plain kriging), drop Citizen Eyes and the school scheduler. Never drop the What-If screen and causal verification."

At the H14 checkpoint, cut in this order and stop as soon as the plan is back on schedule:

1. **Wind advection** (`HAWA_TWIN_ADVECTION=false`; plain regression kriging). Always the first cut, before anything else.
2. Citizen Eyes (F20).
3. School safe-window scheduler (F19); keep the forecast-based school alert trigger (CONTRACTS §10.3).
4. Trajectory ensemble → single deterministic trajectory.
5. Forecaster down to 3 buckets, no conformal step, PM2.5 only (keep 72 h).
6. Forecaster agent → templated brief.
7. Planner re-optimisation tool.
8. Auditor round 2.
9. STRETCH items not started (anti-gaming, coverage router, site score, evidence narrative) stay unstarted.

**Never drop:** the What-If simulator and causal verification (§16); the hard cause→asset constraints; uncertainty fields on every output; `is_simulated` labelling; the deterministic agent fallback; the Auditor's water-on-smoke check (it is a demo beat, §16.1 1:20–1:55).

## 6. Risks

| Risk | Likelihood | Impact | Mitigation | Owner |
|---|---|---|---|---|
| Bedrock model access or quota not enabled in time | Medium | High | Request at H0; stub mode for development; deterministic fallback is demo-presentable | Agents |
| Inference-profile id confusion across regions | Medium | Medium | Env var per role; verify ids in the console at H0 | Agents |
| Strands options differ from the sketches | Medium | Medium | Pin the version at H1; one smoke test per option used | Agents |
| GP twin too slow or unstable | Low | High | Cached kernel, subsampling, IDW fallback chain | ML |
| Forecaster does not beat persistence on test | Medium | Medium | More lags, fire and ventilation features; baseline blend fallback; report the measured skill honestly | ML |
| Verifier fails to recover effects (twin smoothing, sparse post-period data) | Medium | High | Simulator guarantees post-spray passes; spillover buffer; observed-only check; honest `inconclusive` | ML |
| Backend tables or topics late | Medium | High | Fixtures, `hawa-ml publish`, contract tests; agree P-09 columns at H2 | Both |
| CPCB portal or API outage during pulls | Medium | Medium | OpenAQ backup; history cached in MinIO by H3 | ML |
| Poor or over-long Hindi alerts | Medium | Medium | Advice matrix + reviewed templates; validators; human review of the golden set | Agents |
| OR-Tools modelling overruns | Medium | Medium | Greedy first (works in ms), CVRPTW second | Agents |
| LLM non-determinism in the recorded demo | Medium | Medium | Scenario presets; 5× eval runs; record after a passing run | Agents |
| Over-claiming results | Low | High | Honesty checklist before recording: "Simulated" and "indicative" labels, injected-effect wording, KPIs as targets | Both |

## 7. After the hackathon (§14.1)

| Phase | Scope (§14.1) | AI-ML work | Exit criteria |
|---|---|---|---|
| **Phase 1** (0–3 months) | One campus or district with an e-rickshaw fleet partner and 10–20 schools; publish verified results | Real HawaPod-M co-located with a CPCB station for 2 weeks to seed calibration; LOSO twin validation on real mobile data; forecaster retrained on twin history (target B in MODELS §7.3); HawaPod-S safe windows; Citizen Eyes live; real-data verifier null calibration; methods page for open data | Twin beats nearest-station baseline on real LOSO; forecast skill ≥ 0.10 at 24 h on real data; ≥ 90 % of real interventions with a CI verdict |
| **Phase 2** (3–12 months) | One MCD zone with HawaTags on sprinklers and smog guns; integrate existing machine GPS | `gps_inferred` interventions from existing GPS; effectiveness library learning from hundreds of verified interventions (strata beyond priors); fingerprint classifier v2 trained on inspection labels; site compliance scores; anti-gaming guard in weekly reports; evidence reports; optional SageMaker pipelines | Library posteriors data-dominated for common strata; What-If predictions checked against verified outcomes |
| **Phase 3** (12+ months) | NCR-wide, then other NCAP cities; the effectiveness library becomes the moat | Cross-city transfer of forecaster and library (hierarchical by city); spatio-temporal twin; power-proxy (F10) and HawaEye (F8) where agencies provide data; external audit of the verifier; model cards per component | Independent audit of verification methodology |

### 7.1 Model roadmap

| Component | Hackathon | Phase 1 | Phase 2 | Phase 3 |
|---|---|---|---|---|
| Calibration | Linear `a·raw + b·RH + c`, Huber | + hygroscopic term, peer checks | Per-season coefficients | Fleet-wide drift forecasting |
| Twin | Regression kriging + two-scale GP, advection (or plain kriging) | Tuned on real LOSO | Spatio-temporal GP / sparse GP for larger fleets | Multi-city |
| Fingerprint | Rules v1 | Rules + real labels collected | Calibrated LightGBM v2 | Source apportionment with chemical markers where stations provide them |
| Forecaster | LightGBM quantiles, station-trained | Twin-trained, conformal | PM10 + NO₂ targets; ensemble with IITM/SAFAR as features | Cross-city transfer |
| Optimiser | CVRPTW + greedy, haversine travel | OSRM travel times, refills | Multi-day planning, crew rules | Multi-agency |
| Verifier | SC + placebo, DiD/naive fallbacks | Real null calibration | Augmented SC / conformal SC inference | External audit |
| Effectiveness library | Priors + partial pooling | First real strata | Data-dominated strata | Cross-city hierarchy |
| Agents | Planner, Auditor, Communicator, Forecaster | Officer feedback loop into evals | Ward-specific playbooks | Multilingual beyond en/hi |
| Edge | Rule-only spike | TinyML filter on device | HawaEye pilot (VISION) | — |

## 8. Demo readiness checklist (AI-ML)

Run through this before recording the §16.1 video and before judging.

- [ ] `make demo-reset` then the golden path twice; both runs green (M8).
- [ ] Every simulated device, asset, reading, intervention, impact and plan element shows the "Simulated" badge; twin AQI is labelled "indicative".
- [ ] The verifier shot says "simulated intervention with an injected, known effect" and shows the injected value inside the CI; no wording implies a measured field result (§12.5).
- [ ] What-If is described as model-based, with its P10–P90 range.
- [ ] Forecast skill quoted is the measured test-split number from MLflow, not the §13.1 target.
- [ ] Auditor water-on-smoke objection appears in the recorded plan review (G1 passed 5/5 that day).
- [ ] Regional-smoke plan shows zero machines and protective alerts (G2).
- [ ] Hindi alert on screen was reviewed by a Hindi-speaking team member (G4).
- [ ] `HAWA_LLM_MODE=disabled` fallback run rehearsed once, so a Bedrock outage during judging still yields a valid draft.
- [ ] Dashboards show `twin_run_seconds`, `plan_draft_seconds`, `verify_runs_total` and `agent_tokens_total` for the architecture segment.
