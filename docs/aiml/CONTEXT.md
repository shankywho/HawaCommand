# AI-ML Context

> **Status (reconciled 2026-10-10, commit `a33e043`).** This is the product context from the proposal. What is actually built is in [AI-ML/README.md](../../AI-ML/README.md#1-implementation-status). In short: every sensor is simulated; the agents are plain Python classes (no Strands SDK); the optimiser is greedy (OR-Tools is Planned); the What-If baseline is a constant 0.32 ratio; causal verification has only been validated on a seeded synthetic panel.


The problem, the closed loop and the constraints that every AI-ML component in HawaCommand is designed around, drawn from the proposal.

Related: [README](README.md) · [ARCHITECTURE](ARCHITECTURE.md) · [STRUCTURE](STRUCTURE.md) · [MODELS](MODELS.md) · [AGENTS](AGENTS.md) · [DATA_AND_TRAINING](DATA_AND_TRAINING.md) · [PLAN](PLAN.md) · [../CONTRACTS.md](../CONTRACTS.md) · [../SYSTEM_OVERVIEW.md](../SYSTEM_OVERVIEW.md)

---

## 1. The problem ML is solving (§2)

A November morning in Delhi, the phone says AQI 380. That single number hides five failures, and each maps to a piece of AI-ML work.

| # | Failure (§2) | Evidence in the proposal | What AI-ML must deliver |
|---|---|---|---|
| 1 | The city is half-blind (§2.1) | 47 CAAQMS stations for ~1,484 km², one per ~31 km² (target one per 25 km²); CAG found stations sited near trees, major and unpaved roads | Calibrated mobile readings fused with stations into a 500 m hourly map, with an honest confidence value per cell (F3, F4) |
| 2 | Everyone reacts after the damage (§2.2) | Beijing 2015 red alerts: starting cuts 1–2 days before an episode lowered the peak | 72 h forecast per 1 km cell with P10/P50/P90 and a probabilistic GRAP outlook 24–48 h ahead (F5, F6) |
| 3 | A large fleet works on guesswork (§2.3) | 376 anti-smog guns, 266 sprinklers, 91 sweepers, ~2,000 teams; GPS proves where a machine went, not that air got cleaner; routes are fixed | Source attribution (F7) and an exposure-first, cause-matched optimiser (F12, F13) with agent explanations (F14) |
| 4 | Nobody checks whether it worked (§2.4) | Road dust ≈ 15 % of winter PM2.5 but ≈ 64 % of NCAP funds; IIT Delhi: spraying had a very small PM2.5 effect, limited to ~200 m | Causal (synthetic-control) verification of every intervention and a learning effectiveness library (F18) |
| 5 | "Worst AQI" ≠ "most people hurt" (§2.5) | AQI 450 over an empty yard vs AQI 350 near three schools and a hospital at 08:00 | Rank by person-hours above threshold × vulnerability, not by AQI (F12) |

Problem statement (§2): Delhi measures its air too sparsely, acts too late, deploys its fleet without a targeting brain, never verifies whether an action worked, and does not prioritise the people most exposed.

## 2. What ML must do in each loop step (§5, §8)

The loop runs every 3 hours plus an evening master plan (§5). Times are IST.

| Step | ML responsibility | Cadence / trigger | Output (CONTRACTS names) | Feature |
|---|---|---|---|---|
| 1 Sense | Fit per-device humidity-aware calibration from drive-by pairs; maintain trust scores; detect drift. (Ingest applies coefficients; AI-ML fits them.) | Nightly `cmd.train.run {model: calibration}`, on demand | `device_calibration`, `device.calibrated`, `device.trust_changed`, `integrity_flag` (`device_drift`) | F3 |
| 1 Sense (edge) | TinyML spike model on the ESP32-S3: PM2.5 ≥ 3× rolling 5-min baseline within 20 s | Continuous, on device | `DeviceEventPacket` `type: spike` (`model: tinyml-spike@x.y.z`) | §10.5 |
| 2 Map | Regression kriging / GP over the last 60 min of calibrated points with land-use covariates, wind advection, speed down-weighting; posterior mean + variance → confidence | Every 15 min, `cmd.twin.rebuild` | `twin_run`, `cell_state` (`pm25_est`, `pm25_var`, `pm10_est`, `pm10_var`, `confidence`, `aqi`, `n_obs`), `twin.updated` | F4 |
| 3 Attribute | Fingerprint cause per cell and hotspot (rule table v1 → calibrated classifier v2); back-trajectory suspect pin for the top hotspots; hotspot clustering and ranking | Every 15 min (same run), and immediately on spikes | `cell_state.cause_label/cause_conf`, `hotspot`, `hotspot.updated` | F7 |
| 4 Forecast | LightGBM quantile regression, 1–72 h per 1 km cell; GRAP stage probabilities per ward per day; school safe windows | Hourly at :05, master at 17:00 | `forecast_run`, `forecast`, `grap_outlook`, `school_safe_window`, `forecast.issued`, `grap.outlook_issued`, `school.safe_window_computed` | F5, F6, F19 |
| 5 Decide | Exposure engine → CVRPTW optimiser (greedy fallback) → Planner and Auditor agents → constraint re-validation → What-If vs usual routes → draft plan for the officer | Every 3 h (08:00, 11:00, 14:00), master at 18:30, spikes, on demand | `plan` (`drafting` → `draft`/`failed`), `plan_task`, `plan_review`, `plan_simulation`, `plan.drafted` | F12, F13, F14 |
| 6 Act | Communicator drafts pollutant-specific alerts (Hindi + English) for protect tasks and school alerts; backend dispatches and notifies | With the plan; 19:00 and 22:00 school alerts | Alert drafts attached to the plan; backend `alert.requested` | F16 |
| 7 Verify | Synthetic control vs untreated, similar, weather-matched donor cells; placebo-in-space CI and p-value; verdict; update effectiveness library | 2–4 h after each spray, 11:00 batch; nightly library refit | `impact`, `impact.verified`, `effectiveness_library` | F18 |
| Learn | Retrain forecaster, recalibrate devices, refit library, recompute site scores; promote only through gates | 02:00 nightly `cmd.train.run` | New `model_version` rows, MLflow registry | — |

## 3. Features AI-ML owns (§6, SYSTEM_OVERVIEW §4)

Tiers: **BUILD** = must work in the demo · **STRETCH** = build if time allows · **VISION** = architecture only.

| ID | Feature | Origin | Tier | AI-ML scope |
|---|---|---|---|---|
| F1 | Hotspot Grid Engine | CHINA | BUILD | Build the 500 m / 1 km grid (`build_grid`), cell covariates (`cell_feature`), key-cell pre-ranking |
| F3 | Drive-by self-calibration | CHINA | BUILD | Pairing, robust fit, versioning, drift, trust score |
| F4 | Air digital twin | CHINA | BUILD | Regression kriging / GP + advection, confidence, fallbacks |
| F5 | 72 h forecaster | CHINA | BUILD | LightGBM quantiles per horizon bucket, baselines, calibration of intervals |
| F6 | Graded Response Copilot | CHINA | BUILD | Probabilistic stage mapping 24–48 h ahead; ward checklist selection (text is backend config) |
| F7 | Source fingerprint + back-trajectory | ORIGINAL | BUILD | Rules v1, classifier v2, trajectory ensemble, suspect pin, hotspot clusters |
| F12 | Exposure engine | ORIGINAL | BUILD | Formula (CONTRACTS §10.4), hourly population, vulnerability |
| F13 | Dispatch optimiser + What-If | CHINA | BUILD | OR-Tools CVRPTW / prize-collecting, greedy fallback, constraint checker, baseline comparison |
| F14 | Multi-agent command room | ORIGINAL | BUILD | Strands agents on Bedrock, deterministic orchestration |
| F16 | Targeted alerts | JAPAN | BUILD | Communicator agent text (en + hi), advice matrix; delivery is backend |
| F18 | Causal verification + effectiveness library | ORIGINAL | BUILD | Verifier, placebo, verdicts, hierarchical library |
| F9 | Site Compliance Score | CHINA | STRETCH | A/B/C scoring from sensor-measured behaviour |
| F11 | Active sensing router | ORIGINAL | STRETCH | Variance-driven blind spots, route/rider suggestions |
| F15 | Anti-gaming guard | CHINA | STRETCH | Station-clustering detection, integrity flags |
| F19 | School safe-window scheduler | ORIGINAL | STRETCH | Safe windows, seal vs ventilate (CO₂) |
| F20 | Citizen Eyes | ORIGINAL | STRETCH | Bedrock multimodal photo verification + spike matching |
| F22 | Evidence report | ORIGINAL | VISION→STRETCH | Narrative text from structured facts (backend renders PDF) |
| F8 | Smoky Vehicle Spotter (HawaEye) | CHINA | VISION | YOLO int8 on device; architecture only |
| F10 | Power-proxy compliance | CHINA | VISION | Smart-meter load check; architecture only |

F2 (mobile fleet), F17 (HawaTag tracking) and F21 (open data portal) are backend/edge features that AI-ML consumes or feeds.

## 4. Users affected by ML outputs (§7)

| User | ML output they see | What it must get right |
|---|---|---|
| Ward / district officer (MCD, DPCC) | Twin map with confidence, ranked hotspots with cause and suspect pin, 72 h forecast, GRAP outlook, AI plan with per-task reasons and Auditor objections, What-If comparison, verified impacts | Reasons must cite real numbers; uncertainty always visible; nothing dispatches without their approval |
| Driver / field team | Ordered stops with arrival windows (optimiser) | Feasible routes inside shift and capacity; no pointless trips |
| Inspector | Suspect source pin, evidence (spike, citizen photo, trajectory) | A target, not an area; honest confidence |
| School principal | WhatsApp/app alert with safe window, indoor vs outdoor | Pollutant-specific advice, correct Hindi, lead time ≥ 12 h |
| Citizen / outdoor worker | Pollutant-specific alerts; Citizen Eyes outcome | Correct advice for the cause (masks/indoors for smoke, avoid the road for traffic NO₂) |
| Site manager | Site Compliance Score and PM10 trend | Graded on measured behaviour, with data sufficiency shown |
| Public / researchers | Calibrated street-level data and published methods (F21) | Labelled indicative, methods documented |

## 5. Data realities ML must respect

| Reality | Consequence for models | Source |
|---|---|---|
| Low-cost sensors are **indicative, not regulatory**. Official stations remain the legal record | Use mobile data to target and verify, never for compliance values or fines. AQI from the twin is labelled "indicative" everywhere | §10.7, §12.4, CONTRACTS §10.1 |
| Optical PM sensors (PMS5003/SEN55) **over-read in humid air** (Delhi winter fog) | Heater in hardware plus an RH term in calibration; flag `heater_on`; higher noise variance at RH > 75 % | §9.4, §10.7 |
| Sensors **drift**; gas sensors drift with heat; MiCS-6814 needs ~30 min warm-up | Versioned coefficients, drift detection, trust score; ignore gas values while `warming_up`; gases used for fingerprinting and ranking only | §9.4, §10.3, §10.7 |
| **Speed distorts inlet airflow** | Down-weight readings above 60 km/h (`high_speed`) in the twin | §10.7, CONTRACTS §10.3 |
| **Stations are sparse and some are poorly sited** | Twin confidence must drop away from observations; station-proximity effects feed the anti-gaming guard | §2.1, §4.1 |
| **Mobile coverage is uneven in space and time** | Confidence varies by cell and hour; the active sensing router targets blind spots; the verifier requires post-period observations | §6 F11 |
| **Store-and-forward replays** arrive up to 72 h late | Late points are used by later twin runs within their window; training datasets are rebuilt from the archive, not from live state | §10.5, CONTRACTS §4 |
| **FIRMS misses small fires** (§8.2: "too small") and passes only a few times a day | Burning attribution must work from sensor signatures and citizen photos without a fire point | §8.2, §12.2 |
| **Weather comes from reanalysis/forecast grids**, not street level | Advection uses a smoothed wind field; trajectories are ensembles, not single lines | §9.4 |
| **HawaTag PM sensors sit in the spray plume** | Exclude TAG readings while spraying and for 2 min after from the twin; use them only as descriptive `pm_before/pm_after` | §10.4 |
| **The demo fleet is simulated** | Models must run identically on real and simulated inputs; evaluation against simulator ground truth is allowed, production code never reads ground truth | §10, §12.5 |

## 6. The honesty rule and what is real in the demo (§12.5)

**One real pod, a simulated fleet, a real pipeline.** Simulated devices publish the exact firmware packet over real MQTT. Every simulated device, asset, reading, intervention and event carries `is_simulated = true`; every AI-ML output derived from simulated inputs propagates the flag (a twin run is `is_simulated = true` if any contributing mobile point is simulated), and every UI labels it.

| Component | Status in the demo | AI-ML implication |
|---|---|---|
| CPCB / OpenAQ, weather, FIRMS feeds | Live | Twin and forecaster run on real reference data |
| IoT pipeline, storage, APIs, map | Live | AI-ML consumes the real Kafka topics |
| HawaPod / HawaTag fleet | Simulated devices, real packets (labelled) | Calibration and twin are exercised on realistic noise, drift and humidity bias |
| Calibration, twin, fingerprint, forecast, exposure | Running on real historical and live reference data | Forecaster trained on real CPCB history; twin validated on held-out real stations |
| Optimiser, What-If, agents, approval flow | Running | Real OR-Tools and real Bedrock calls |
| Causal verification | Running on simulated interventions with **injected, known effects** | We show the verifier recovers the injected effect within its CI; we never present simulated effects as measured field results |
| WhatsApp / SMS alerts | Live to test numbers | Communicator output is really sent |

What we must never claim: a measured real-world effect of spraying, a regulatory AQI, a forecast skill we have not measured on real data, or pilot KPIs as achieved results (§13.1 targets are targets).

## 7. Design principles

1. **Uncertainty everywhere** (§9.1 "every output carries uncertainty"). Twin: variance and confidence. Forecast: P10/P50/P90. Attribution: `cause_conf` and full class probabilities. Exposure: quantiles propagated from the forecast. Verification: CI and placebo p-value. The UI never receives a bare point estimate (CONTRACTS §1).
2. **LLM explains, optimiser decides, human approves** (§9.1, §15). The deterministic optimiser proposes; agents explain and critique but cannot bypass constraints; an officer approves every dispatch. Agent failures degrade to deterministic templated reasons.
3. **Cause before cure.** A machine is only sent to a cause it can fix (CONTRACTS §3 matrix, hard constraint). Regional smoke means protect people, not trucks.
4. **Exposure, not AQI.** Ranking and optimisation use person-hours above threshold weighted by vulnerability (CONTRACTS §10.4).
5. **Verify every action.** Each intervention gets an effect estimate with a CI or an explicit "inconclusive" with the reason. Naive before/after is flagged "low evidence" and can never produce an "effective" verdict.
6. **Conservative under doubt.** Low confidence narrows the action set (inspect or investigate rather than spray), widens intervals, and lowers verdict strength.
7. **Versioned and reproducible.** Every output row records `model_version` (`{model}@{semver}+{git_sha7}`); every training run records its data snapshot.
8. **Deterministic core, LLM at the edges.** Numbers are computed in Python; LLMs only phrase, critique and classify images, and every LLM output passes a schema and a constraint check.

## 8. KPIs and how ML measures them (§13.1)

Pilot targets, not claims.

| KPI | Definition (§13.1) | Target | How AI-ML measures it |
|---|---|---|---|
| Coverage | Share of pilot road-km observed at least daily | ≥ 70 % | Coverage router: map-matched readings per OSM road segment per day |
| Twin accuracy | Error of twin vs held-out reference station | Beat nearest-station baseline | Leave-station-out MAE, paired bootstrap vs nearest-station and IDW baselines ([DATA_AND_TRAINING §7](DATA_AND_TRAINING.md#7-dataset-splits-and-evaluation-protocol)) |
| Forecast skill | 24 h PM2.5 error vs persistence | Clear improvement | Skill = 1 − MAE₅₀/MAE_persistence at h = 24; gate ≥ 0.10 |
| Exposure avoided | Person-hours above threshold avoided, AI plan vs usual routes | Measured and reported weekly | What-If Monte Carlo (simulated), later verified impacts × exposure (measured) |
| Verified actions | Share of interventions with a verified effect and CI | ≥ 90 % | Share of interventions whose final verdict is `effective`, `no_detectable_effect` or `adverse` (not `inconclusive`) |
| Alert lead time | Hours between school alert and spike | ≥ 12 h | `alert.sent` time vs first forecast-exceedance hour at the school cell |
| Early action | GRAP-stage actions started before formal invocation | Tracked per episode | `grap_outlook` issue time vs official invocation date (manual entry) |

Operational ML metrics (not §13.1 KPIs) are in [ARCHITECTURE §9](ARCHITECTURE.md#9-observability).

## 9. Risks relevant to ML (§15, plus ML-specific)

| Risk | Mitigation | Where |
|---|---|---|
| Low-cost sensors drift or read high in humidity (§15) | Drive-by calibration with RH term, heater, trust score, down-weighting of bad devices | MODELS §2, §3 |
| Source attribution is uncertain (§15) | Show confidence; use it to choose the tool, never to fine; human approval; conservative gating of water trucks | MODELS §5 |
| Verification confounded by weather (§15) | Weather-matched donors, placebo tests, CIs, downwind-donor exclusion | MODELS §12 |
| LLM agents make a bad call (§15) | Agents only explain and critique; optimiser enforces constraints; every Auditor change re-validated; officer approval | AGENTS §2 |
| Gaming: cleaning only near monitors (§15) | Anti-gaming guard compares stations with surrounding mobile readings | MODELS §14 |
| Privacy of cameras and locations (§15) | No PII in prompts; EXIF stripped; on-device vision; evidence-only uploads | AGENTS §8, MODELS §20–21 |
| Station-trained forecaster applied to cells (domain shift) | Cell features, twin-at-station consistency check, retrain on twin history when available | MODELS §7 |
| Twin smoothing attenuates or leaks intervention effects | Spillover buffer for donors, post-period observation support rule, "observed-only" robustness check | MODELS §12 |
| Simulation-to-reality gap (models look better on the simulator) | Report real-data metrics separately; injected-effect validation is labelled as such | DATA_AND_TRAINING §6 |
| External feed outage (CPCB, FIRMS, Open-Meteo) | Freshness gauges, last-good caching, fallback chains, wider intervals | ARCHITECTURE §8 |
| Bedrock latency, quota or refusal | Timeouts, deterministic fallback plan, stub mode for tests | AGENTS §9 |
| Wrong or over-long Hindi alerts | Advice matrix drives content; length validators; reviewed templates as fallback; golden eval | AGENTS §11 |
| Overclaiming in the demo | Honesty rule, "Simulated" and "indicative" labels, verdict rules that cannot say "effective" on weak evidence | §6 above |

## 10. Non-goals

- Not a regulatory AQI or compliance monitor; official stations remain the legal record.
- No automated enforcement, fines or penalties from model output; attribution chooses a tool, it does not assign blame.
- No autonomous dispatch; every plan requires officer approval.
- No individual tracking or person-level exposure; population is aggregated per cell and hour. No face or plate recognition.
- No chemical sprays or new hardware actions; we direct the machines Delhi already has (§3).
- Not a replacement for IITM/SAFAR forecasts; HawaCommand is the decision and verification layer on top (§14.2).
- No health diagnosis or medical advice beyond standard protective guidance.
- No deep learning for the twin or forecaster in the hackathon; proven statistical methods first (§12.1).
- No claims of measured real-world intervention effects until a pilot produces them.
