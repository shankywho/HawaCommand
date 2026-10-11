# AI-ML Models and Algorithms

<!-- nav:start -->

**Navigate:** [Project](../../README.md) · [Docs hub](../README.md) · [Overview](../SYSTEM_OVERVIEW.md) · [AWS architecture](../AWS_ARCHITECTURE.md) · [AWS setup](../AWS_SETUP_GUIDE.md) · [API](../backend/API.md) · [Environment](../ENVIRONMENT_VARIABLES.md) · [Contracts](../CONTRACTS.md)

**AI-ML docs:** [Runbook](../../AI-ML/README.md) · [Index](README.md) · [Context](CONTEXT.md) · [Architecture](ARCHITECTURE.md) · **Models** · [Agents](AGENTS.md) · [Data and training](DATA_AND_TRAINING.md) · [Engine contracts](../../AI-ML/CONTRACTS.md) · [Structure](STRUCTURE.md) · [Plan](PLAN.md)

<!-- nav:end -->

> **Status per section (as implemented at commit `a33e043`).** This document gives the target algorithm for each component; the code differs as follows. §1 grid: Implemented, 10,600 cells at 500 m and 2,650 at 1 km, cell ids `G-RRR-CCC`, wards are synthetic `Ward-1`..`Ward-12`. §2 calibration: Partial; Huber fit `ref = a*raw + b*RH + c` works, but co-location pairing is not implemented. §3 twin: Partial; scikit-learn GP with a `C*RBF + White` kernel on lat/lon plus a straight 15-minute wind shift. It is not PyKrige or a spherical variogram, and `config/settings.yaml` is unused. LOSO MAE is 37.82 vs 7.4 for nearest-station on 3 stations. §4 hotspots: Partial (top-N by exposure). §5 fingerprint: Implemented as rules from `config/fingerprint_rules.yaml`; the LightGBM weak-label classifier is trained but unused. §6 back-trajectory: Implemented (single straight line). §7 forecaster: Partial; 21 LightGBM quantile models with 37 features and a 45-day holdout, but inference fills lags from one value (metrics in `AI-ML/reports/forecast_metrics.json`). §8 GRAP: Implemented, with a gap bug between integer breakpoints. §9 exposure: Implemented. §10 optimiser: Partial (greedy only). §11 What-If: Stub/Mock (baseline = AI x 0.32). §12 causal: Partial (SLSQP weights plus placebo; API replays a seeded test). §13 library: Partial (JSON running average, key mismatch). §14-17: Planned. §18 safe window: Stub/Mock (fixed diurnal curve x 260 baseline, 4 personas). §19-21: Planned. §22: Planned; template narratives exist in `insights/narratives.py`. Full detail: [AI-ML/README.md](../../AI-ML/README.md#1-implementation-status).


Technical specification of every algorithm AI-ML runs, following proposal §9.4 exactly and extending it with the details needed to build, validate and operate it.

Related: [README](README.md) · [CONTEXT](CONTEXT.md) · [ARCHITECTURE](ARCHITECTURE.md) · [STRUCTURE](STRUCTURE.md) · [AGENTS](AGENTS.md) · [DATA_AND_TRAINING](DATA_AND_TRAINING.md) · [PLAN](PLAN.md) · [../CONTRACTS.md](../CONTRACTS.md) · [../SYSTEM_OVERVIEW.md](../SYSTEM_OVERVIEW.md)

---

## Contents

1. [Conventions and the grid (F1)](#1-conventions-and-the-grid-f1)
2. [Drive-by calibration (F3)](#2-drive-by-calibration-f3)
3. [Digital twin (F4)](#3-digital-twin-f4)
4. [Hotspot detection](#4-hotspot-detection)
5. [Source fingerprint (F7)](#5-source-fingerprint-f7)
6. [Back-trajectory (F7)](#6-back-trajectory-f7)
7. [72 h forecaster (F5)](#7-72-h-forecaster-f5)
8. [GRAP Copilot (F6)](#8-grap-copilot-f6)
9. [Exposure engine (F12)](#9-exposure-engine-f12)
10. [Dispatch optimiser (F13)](#10-dispatch-optimiser-f13)
11. [What-If simulator (F13)](#11-what-if-simulator-f13)
12. [Causal verification (F18)](#12-causal-verification-f18)
13. [Effectiveness library (F18)](#13-effectiveness-library-f18)
14. [Anti-gaming guard (F15)](#14-anti-gaming-guard-f15)
15. [Active sensing router (F11)](#15-active-sensing-router-f11)
16. [Site compliance score (F9)](#16-site-compliance-score-f9)
17. [Power-proxy compliance (F10, VISION)](#17-power-proxy-compliance-f10-vision)
18. [School safe-window scheduler (F19)](#18-school-safe-window-scheduler-f19)
19. [TinyML spike detector (edge)](#19-tinyml-spike-detector-edge)
20. [Citizen Eyes photo verification (F20)](#20-citizen-eyes-photo-verification-f20)
21. [HawaEye smoky-vehicle detection (F8, VISION)](#21-hawaeye-smoky-vehicle-detection-f8-vision)
22. [Evidence report narrative (F22)](#22-evidence-report-narrative-f22)
23. [Summary: versions, budgets, fallbacks](#23-summary-versions-budgets-fallbacks)

---

## 1. Conventions and the grid (F1)

### 1.1 Common conventions

- **Section template.** Every algorithm below lists: purpose, inputs, outputs (CONTRACTS names), method with maths, hyperparameters (defaults live in `AI-ML/configs/*.yaml`), validation metric and target, fallback, compute budget, hackathon cut, tests.
- **Units** follow CONTRACTS §1: PM in µg/m³, gases in ppb, CO₂ in ppm, wind in m/s with direction "from" in degrees, speed km/h, time UTC ISO-8601 (IST only for human-facing hours and calendars).
- **Transform.** PM concentrations are modelled in `z = log1p(pm)` space (right-skewed, multiplicative errors). Back-transforms use the posterior median `expm1(μ)` for point values and the lognormal variance for `*_var`. Quantiles transform monotonically, so P10/P50/P90 survive `expm1`.
- **Time resolution.** Twin states every 15 min; forecast hourly; verification on the 15-min twin series.
- **Uncertainty.** No output leaves a model without its uncertainty field (CONTRACTS §1).
- **Versions.** Each component has a version constant (`twin@1.0.0`, `fingerprint-rules@1.0.0`, …) combined with the git SHA into `model_version` ([ARCHITECTURE §11](ARCHITECTURE.md#11-model-versioning-and-loading)).
- **Simulated flag.** Outputs inherit `is_simulated = true` when any contributing mobile input is simulated.
- Standard logistic membership used by rules: `σ(x; t, s) = 1 / (1 + exp(−(x − t)/s))`, and `σ̄ = 1 − σ`.

### 1.2 Grid (F1)

- CRS for computation EPSG:32643 (UTM 43N). Origin = south-west corner of Delhi's bounding box snapped down to a multiple of 500 m; stored in `grid_meta` (`origin_x`, `origin_y`, `cell_m = 500`, `n_rows`, `n_cols`, `crs`). Row increases northward, column eastward.
- Ids: `g500-{row:03d}-{col:03d}`; `g1k-{row//2:03d}-{col//2:03d}` (CONTRACTS §2). Cells kept if they intersect the NCT of Delhi boundary: ≈ 6,000 × 500 m cells and ≈ 1,500 × 1 km cells for ~1,484 km².
- Point → cell: `row = floor((y − origin_y)/500)`, `col = floor((x − origin_x)/500)` after transforming lon/lat to UTM (vectorised in `grid/index.py`).
- Build details and population: [DATA_AND_TRAINING §3–4](DATA_AND_TRAINING.md#3-grid-build).

### 1.3 Key cells (F1)

"Satellite AOD, fire points and station history pre-rank key cells for dense monitoring" (§6 F1). Score per 500 m cell, written to `cell_feature.key_cell_score`:

```math
K(c) = 0.35\,\tilde z_{\text{hist}}(c) + 0.25\,\tilde z_{\text{src}}(c) + 0.15\,\tilde z_{\text{fire}}(c) + 0.25\,\tilde z_{\text{people}}(c)
```

where each term is a rank-normalised (0–1) value: `hist` = winter mean PM2.5 from a stations-only kriged climatology (plus MAIAC AOD where available, STRETCH); `src` = construction + industrial + road density; `fire` = FIRMS detections within 2 km over the last two winters; `people` = night population × static vulnerability. Top 10 % are key cells: devices sample faster there (backend `DeviceCommand` sampling mode) and the coverage router weights them. Cut: `people` + `src` only.

---

## 2. Drive-by calibration (F3)

### 2.1 Purpose

"When a device is within 200 m of a reference station, moving slowly, with stable wind, pairs of readings are collected. A robust regression fits `ref = a·raw + b·RH + c` per device … Coefficients are versioned; a device whose fit keeps drifting loses trust score" (§9.4). Removes per-device bias and the humid over-reading of optical PM sensors without calibration visits.

### 2.2 Inputs and outputs

| Direction | Name | Fields used |
|---|---|---|
| Trigger | `hawa.cmd.train.v1` `cmd.train.run {model: calibration, device_ids?}` (nightly 02:00, on demand, P-03) | |
| In | `reading` | `device_id, ts, lat, lon, pm25_raw, pm10_raw, rh, t, speed_kmh, flags, calibration_version` |
| In | `reference_station`, `reference_observation` | station geometry; `pm25`, `pm10`, interval start/end, quality flag |
| In | `weather_observation` | `ws` near the station |
| In | `device`, `device_calibration` | current version and coefficients |
| Out | `device_calibration` | `device_id, pollutant, version, a, b, c, n_pairs, n_visits, fit_window_start, fit_window_end, ref_station_ids, mae_train, mae_holdout, r2_holdout, huber_scale, status (active\|rejected\|prior), trust_score, model_version` |
| Out | `hawa.device.event.v1` | `device.calibrated`, `device.trust_changed` (P-01) |
| Out | `integrity_flag` | `kind: device_drift` |

Ingest (backend) applies the active version: `pm25 = max(0, a·pm25_raw + b·rh + c)` (same for PM10) and stamps `calibration_version`.

### 2.3 Method

**Pairing** (CONTRACTS §10.3): device within 200 m of a reference station, speed < 10 km/h, wind ≤ 3 m/s, at least 20 paired 1-min points.

1. Select readings with `ST_DWithin(reading.geom, station.geom, 200)` (geography) and `speed_kmh < 10`; drop `fan_stall`, `flatline`, `gps_no_fix`, `sd_replay` older than the fit window.
2. Average device values to 1-min means (two 30 s packets per minute).
3. Assign each minute the reference value of the station interval that contains it (CPCB 15-min average; OpenAQ hourly); drop intervals flagged by the source.
4. Keep minutes with nearest-hour `ws ≤ 3` m/s and a stable reference (|Δ| between adjacent intervals ≤ 20 %).
5. Group consecutive minutes into **visits** (gap > 10 min starts a new visit). Weight each minute `1/n_visit_minutes^0.5` so one long stop cannot dominate.
6. Require ≥ 20 pairs **and** ≥ 2 visits for a device-specific fit. Rolling fit window 14 days.

**Model** per device and pollutant (PM2.5, PM10):

```math
\text{ref}_i = a\,\text{raw}_i + b\,\text{RH}_i + c + \varepsilon_i
```

fitted with Huber loss (`sklearn.linear_model.HuberRegressor`, `epsilon = 1.35`, `alpha = 1e-4`) and the visit weights. The RH term corrects the known humid over-reading (§9.4, §10.7). Extension v1.1 (optional, promoted only if hold-out MAE improves ≥ 5 %): add `d·raw·g(RH)` with `g(RH) = (RH/100)^2 / (1 − RH/100)` capped at RH = 95 %, a κ-Köhler-style hygroscopic growth term.

**Shrinkage to the fleet** (stabilises devices with few pairs):

```math
\hat\theta_{\text{dev}} = \frac{n\,\hat\theta_{\text{fit}} + n_0\,\theta_{\text{fleet}}}{n + n_0},\qquad n_0 = 30
```

with `θ_fleet` the robust median of active device coefficients (factory `a = 1, b = 0, c = 0` before any fleet fits).

**Acceptance.** The last 20 % of visits (by time) are held out. A new version becomes `active` only if `a ∈ [0.3, 1.6]`, `b ∈ [−3, 1]` µg/m³ per %RH, `|c| ≤ 80` µg/m³, `n_pairs ≥ 20`, and `MAE_holdout(new) ≤ 1.05 × MAE_holdout(current)` on the same hold-out. Otherwise the row is written with `status = rejected` and the current version stays.

**Drift.**

- Coefficient stability: `Δa = |a_new − a_prev|`, `Δc = |c_new − c_prev|`.
- Residual CUSUM on new pairs under the *current* coefficients: `S_t = max(0, S_{t−1} + z_t − k)`, `k = 0.5`, alarm at `h = 5` → `integrity_flag` `device_drift`.
- Peer check (no station needed): when two devices report from the same 500 m cell within 2 min, the calibrated difference is tracked; a persistent bias > 25 % against ≥ 3 peers raises `device_drift`.

**Trust score** in [0, 1], bands from CONTRACTS §3 (`high ≥ 0.8`, `medium 0.5–0.8`, `low < 0.5`):

```math
\text{trust} = 0.35\,q + 0.25\,s + 0.25\,h + 0.15\,f
```

- `q = clip(1 − MAE_rel / 0.5, 0, 1)`, `MAE_rel = MAE_holdout / mean(ref)`.
- `s = exp(−Δa/0.15 − Δc/15)` (1 for the first version).
- `h = 1 −` share of the last 24 h of packets with `fan_stall`, `flatline`, `gps_no_fix` or ingest `implausible_*` rejections.
- `f = exp(−days_since_last_accepted_fit / 14)`.
- Never-fitted devices: 0.5. A `device.tamper` event halves trust until an admin clears it.

`device.trust_changed` is emitted when the band changes or |Δtrust| ≥ 0.05.

### 2.4 Hyperparameters (`configs/calibration.yaml`)

| Key | Default |
|---|---|
| `pairing.max_distance_m` / `max_speed_kmh` / `max_wind_ms` / `min_pairs` | 200 / 10 / 3 / 20 |
| `pairing.min_visits`, `visit_gap_min`, `window_days` | 2, 10, 14 |
| `huber.epsilon`, `huber.alpha` | 1.35, 1e-4 |
| `shrinkage.n0` | 30 |
| `bounds.a`, `bounds.b`, `bounds.c_abs` | [0.3, 1.6], [−3, 1], 80 |
| `accept.max_mae_ratio` | 1.05 |
| `cusum.k`, `cusum.h` | 0.5, 5 |
| `trust.weights` | q 0.35, s 0.25, h 0.25, f 0.15 |

### 2.5 Validation

- Per device: hold-out MAE, R², bias; reported in `device_calibration`.
- Simulator (known true coefficients and drift, [DATA_AND_TRAINING §6](DATA_AND_TRAINING.md#6-synthetic-data-contract-with-the-backend-simulator)): for devices with ≥ 60 pairs, recovered `a` and `b` within ±10 % and `c` within ±5 µg/m³ of truth; injected 2 %/day drift detected within 3 days; false drift alarms ≤ 5 % per device-month.
- Fleet: after calibration, MAE against the co-located real pod's reference ≤ 25 % of the reference mean (indicative-grade target).

### 2.6 Fallback

No valid pairs → fleet-prior coefficients with `status = prior` and trust decaying through `f`. Rejected fit → keep current. Reference feed down → skip the run (no new version), trust decays slowly.

### 2.7 Compute budget

100 devices × 2 pollutants, ≤ 5,000 pairs each: < 30 s total, nightly.

### 2.8 Hackathon cut

v1 linear formula, no hygroscopic term, no peer check. Trust from `q` and `h` only if time is short.

### 2.9 Tests

Unit: recover known `a, b, c` from synthetic pairs with 10 % gross outliers within tolerance (Huber vs OLS comparison); pairing excludes points at 201 m or 10 km/h; visit grouping; bounds rejection; CUSUM alarms on injected drift and stays silent on stationary noise (seeded). Property (hypothesis): fit invariant to row order; trust always in [0, 1]; band boundaries exactly 0.5 and 0.8.

---

## 3. Digital twin (F4)

### 3.1 Purpose

"Calibrated points from the last hour are combined with a Gaussian-process (kriging) model using land-use covariates … The field is then shifted downwind by the IMD wind vector for the elapsed time. Each cell stores the posterior mean and variance; variance is the confidence shown to officers" (§9.4). Produces the 500 m, 15-minute state that every later step uses.

### 3.2 Inputs and outputs

| Direction | Name | Fields |
|---|---|---|
| Trigger | `hawa.cmd.twin.v1` `cmd.twin.rebuild` | `as_of`, `window_min` (60), `advection` (bool) |
| In | `reading` | calibrated `pm25`, `pm10`, `weight`, `trust`, `speed_kmh`, `flags`, `rh`, `lat`, `lon`, `cell_id`, `ts`, device role, `is_simulated` |
| In | `reference_observation` | station `pm25`, `pm10` in the window |
| In | `weather_observation` | `ws`, `wd` at grid points (latest hour) |
| In | `cell`, `cell_feature` | centroids, covariates |
| Out | `twin_run` | `run_id, run_seq, as_of, window_min, method, advection_applied, n_obs_mobile, n_obs_station, n_superobs, kernel_params, duration_ms, status, model_version, is_simulated` |
| Out | `cell_state` | `cell_id, ts (= as_of), run_id, pm25_est, pm25_var, pm10_est, pm10_var, confidence, aqi, n_obs, cause_label, cause_conf, cause_probs, exposure_ph, exposure_ph_pm10, model_version` |
| Out | `hawa.twin.updated.v1` | `{run_id, as_of, tile_version, cells_updated, bbox, model_version}` |

### 3.3 Method

**(1) Reading weight** (P-07, shared with ingest via `hawa_contracts.quality.reading_weight`):

```math
w_i = \text{trust}_i \cdot f_{\text{speed}}(v_i) \cdot f_{\text{flags}} \cdot f_{\text{rh}}
```

- `f_speed(v) = 1` for `v ≤ 40` km/h; `1 − 0.035·(v − 40)` for `40 < v ≤ 60` (0.3 at 60); `0.2` above 60 (`high_speed`, §10.7).
- `f_flags = 0` for `fan_stall`, `flatline`, `gps_no_fix`; HawaTag readings while `tag.spraying = true` and for 2 min after also get 0 (the cab sensor sits in the spray plume). `warming_up` affects gases only.
- `f_rh = 0.5` when RH > 90 % (fog droplets), else 1.

**(2) Super-observations.** Mobile readings are aggregated per (500 m cell, 10-min slot): `z_j` = weighted mean of `log1p(pm)`, position and time = weighted means. Noise variance (log space):

```math
\sigma_j^2 = \frac{\sigma^2_{\text{meas}}}{\sum_{i\in j} w_i} + \sigma^2_{\text{micro}}
```

`σ²_meas = 0.04` (≈ 20 % CV per calibrated reading), `σ²_micro = 0.02` (sub-cell variability). Reference stations enter as super-obs with `σ² = 0.005 + 0.01` (instrument + representativeness). Typical pilot hour: ~600 mobile super-obs + 47 stations.

**(3) Trend (regression-kriging stage 1).** Weighted ridge regression on standardised cell covariates `x(c)` = [road density, construction density, industrial share, green share, log distance to major road, log population density]:

```math
z_j = \beta_0 + \beta^\top x(c_j) + r_j,\qquad \hat\beta = \arg\min \sum_j \frac{(z_j - \beta_0 - \beta^\top x_j)^2}{\sigma_j^2} + \lambda\lVert\beta\rVert^2,\ \lambda = 1
```

**(4) Residual GP with two scales.** Residuals `r_j` are modelled with an additive kernel and heteroscedastic noise:

```math
k(s, s') = C_L\,\text{Matérn}_{3/2}(s, s'; \ell_L) + C_S\,\text{Matérn}_{3/2}(s, s'; \ell_S),\qquad r = f(s) + \epsilon,\ \epsilon_j \sim \mathcal N(0, \sigma_j^2)
```

Implemented with `sklearn.gaussian_process.GaussianProcessRegressor(kernel=C_L*Matern(ℓ_L, nu=1.5) + C_S*Matern(ℓ_S, nu=1.5), alpha=σ²_j array, normalize_y=False)`. Bounds: `ℓ_L ∈ [3, 20]` km (default 8), `ℓ_S ∈ [0.3, 2]` km (default 0.8). Hyperparameters are re-optimised each run by marginal likelihood, warm-started from `ml:feat:twin_kernel:latest` (`n_restarts_optimizer = 0`); when `n > 1,500` the cached values are used without re-optimisation. Separate fits for PM2.5 and PM10.

**(5) Wind advection.** The large-scale component is transported; the small-scale component is tied to stationary sources (roads, sites) and is not moved. With dual coefficients `α = K⁻¹ r` from the fitted GP:

```math
m_L(s^*) = k_L(s^*, S)\,\alpha,\qquad m_S(s^*) = k_S(s^*, S)\,\alpha
```

```math
\mu^*(s^*) = \hat\beta^\top x(s^*) + m_L\big(s^* - \mathbf u\,\overline{\Delta t}\big) + m_S(s^*)
```

`u` is the wind vector (m/s, converted from `ws`, `wd` "from" to a "to" vector) interpolated from weather grid points (IDW, 30 km); `Δt̄ = as_of − weighted mean observation time` (~30 min). The displacement is clipped to 3 km. Small-scale observations are aged instead: `σ²_j += κ·(as_of − t_j)/60 min`, `κ = 0.02`. Advection is disabled (`advection: false`, or wind older than 3 h) by setting `u = 0`, which is plain regression kriging — the first thing the cut rule drops (§16).

**(6) Variance and confidence.**

```math
\sigma^{*2}(s^*) = \operatorname{Var}_{\text{GP}}[f(s^*)] + x^{*\top}\Sigma_\beta x^* + \gamma\,C_L\min\!\Big(1, \tfrac{|\mathbf u|\overline{\Delta t}}{\ell_L}\Big),\quad \gamma = 0.1
```

Back-transform: `pm_est = expm1(μ*)` (posterior median, clipped ≥ 0); `pm_var = (e^{σ*²} − 1)·e^{2μ* + σ*²}` (lognormal variance). Confidence is the share of prior uncertainty removed:

```math
\text{confidence}(c) = \operatorname{clip}\!\left(1 - \sqrt{\sigma^{*2}(c) / (C_L + C_S)},\ 0,\ 1\right)
```

So confidence 0.5 means the posterior sd is half the prior sd — the threshold used for hotspots (CONTRACTS §10.3). The reported `confidence` is the minimum of the PM2.5 and PM10 values. `n_obs` = raw readings in the cell in the window.

**(7) Indicative AQI** per cell from `pm25_est` and `pm10_est` with CONTRACTS §10.1 breakpoints (max of sub-indices), always labelled indicative.

**(8) Outlier screening** (feeds F15/integrity): closed-form GP leave-one-out for each super-obs, `μ₋ⱼ = r_j − [K⁻¹r]_j/[K⁻¹]_jj`, `σ²₋ⱼ = 1/[K⁻¹]_jj`. `|z| > 5` three times in 24 h for the same device → `integrity_flag` `implausible_jump`.

After the field: fingerprint (§5), hotspots (§4), trajectories (§6), exposure (§9), coverage gaps (§15) run in the same handler.

### 3.4 Hyperparameters (`configs/twin.yaml`)

| Key | Default |
|---|---|
| `window_min`, `superobs.slot_min` | 60, 10 |
| `noise.meas_var`, `noise.micro_var`, `noise.station_var` | 0.04, 0.02, 0.015 |
| `trend.ridge_lambda` | 1.0 |
| `kernel.l_long_km` (bounds), `kernel.l_short_km` (bounds) | 8 [3, 20], 0.8 [0.3, 2] |
| `kernel.reoptimise_max_n` | 1,500 |
| `advection.max_shift_m`, `age_kappa`, `wind_max_age_h`, `gamma` | 3,000, 0.02, 3, 0.1 |
| `weights.speed_knots` | 40 → 1.0, 60 → 0.3, > 60 → 0.2 |
| `fallback.idw_power`, `idw_radius_km`, `carry_forward_decay` | 2, 3, 0.8 |

### 3.5 Validation

- **Leave-station-out (LOSO)** on real data, the §13.1 KPI: hold out each CPCB/DPCC station in the pilot area in turn, run the twin without it, compare hourly means at its cell with the station. Metrics: MAE, RMSE, bias, 80 % interval coverage. Baselines: nearest-station value; IDW of the remaining stations. **Target and gate:** twin MAE below nearest-station MAE with the paired-bootstrap 95 % CI of the difference below 0; 80 % interval coverage within [0.7, 0.9]. Reported with and without mobile data and with and without advection.
- **Simulator:** RMSE against the ground-truth field over all cells; reliability of confidence (empirical error quantiles vs predicted sd per confidence decile).
- Nightly `cmd.train.run {model: twin_eval}` (P-03) refreshes `twin_holdout_mae`.

### 3.6 Fallback chain

1. Regression kriging GP + advection (default).
2. Same without advection.
3. PyKrige `OrdinaryKriging` (spherical variogram) on residuals, or on `z` when covariates are missing.
4. IDW (power 2, radius 3 km) with confidence from a distance-based proxy `exp(−d_nearest/1 km)`.
5. Carry forward the last good state with confidence × 0.8 per missed run.

`twin_run.method` records which one ran.

### 3.7 Compute budget

~700 super-obs: one GP likelihood evaluation ≈ 0.3 s; ~30 evaluations per pollutant ≈ 10 s; prediction for 6,000 cells < 1 s. Whole twin handler including attribution, trajectories and exposure: p95 ≤ 45 s, hard 120 s.

### 3.8 Hackathon cut

Drop advection first (cut rule §16). Next: single-scale kernel; then ordinary kriging. Keep confidence in every variant.

### 3.9 Tests

Unit: super-obs weights and variances; weight curve at 40/60/61 km/h; TAG spray exclusion; trend with collinear covariates stays finite; confidence = 1 − σ/σ_prior at synthetic points; lognormal variance formula; AQI breakpoints. Property: confidence ∈ [0, 1]; variance ≥ 0; with `u = 0` result equals no-advection path exactly; translating all observations and cells by the same vector translates the field (stationarity). Integration: synthetic field from a known GP → posterior covers truth at ~80 % for 80 % intervals.

---

## 4. Hotspot detection

### 4.1 Purpose

Turn the cell field into a ranked list of actionable clusters with cause and suspect location (CONTRACTS §2: "a connected cluster of high-exposure 500 m cells at one twin timestamp").

### 4.2 Inputs and outputs

In: `cell_state` of the run; latest `forecast` (for the next 3 h, downscaled, §7.3); previous run's `hotspot`. Out: `hotspot` rows (fields in P-09: `hotspot_id, run_id, track_id, rank, ward_id, cell_ids, peak_cell_id, pm25_peak, pm10_peak, exposure_ph, exposure_ph_next3h, cause_label, cause_conf, cause_probs, suspect_*, trajectory, trigger, evidence, model_version`); `hotspot.updated` per ward.

### 4.3 Method

1. **Flag cells** (CONTRACTS §10.3): `exposure_ph` in the top 5 % of cells with `exposure_ph > 0`, **or** indicative AQI ≥ 301 with `confidence ≥ 0.5`.
2. **Cluster** flagged cells by 8-connectivity on the (row, col) grid (`scipy.ndimage.label`), equivalent to DBSCAN with `eps ≈ 710 m`, `min_samples = 1` on centroids (DBSCAN is available for irregular inputs such as spike points).
3. **Split** clusters larger than 25 cells by ward boundary (city-wide smoke produces huge components; planning is per ward).
4. **Aggregate** per hotspot: `exposure_ph = Σ` over cells; `exposure_ph_next3h` from the downscaled forecast P50; peak cell = argmax exposure; `cause_probs` = exposure-weighted mean of member cells' probabilities (§5), label and confidence per §5.3.
5. **Rank** by `exposure_ph_next3h`, ties by current `exposure_ph` (planning acts on the next hours).
6. **Track** identity: match to the previous run's hotspots by cell IoU ≥ 0.3 or centroid distance ≤ 750 m → same `track_id`; else new.
7. Top 10 by rank get a back-trajectory (§6).

### 4.4 Hyperparameters (`configs/hotspots.yaml`)

`top_share 0.05`, `aqi_min 301`, `conf_min 0.5`, `connectivity 8`, `max_cells_before_split 25`, `track_iou 0.3`, `track_dist_m 750`, `trajectory_top_n 10`.

### 4.5 Validation

Simulator: a source is detected if a hotspot lies within 500 m during its active window. Recall ≥ 0.8 for sources raising covered-cell PM ≥ 50 % above background; precision ≥ 0.7. Track stability: ≥ 90 % of persistent sources keep one `track_id` across consecutive runs.

### 4.6 Fallback · 4.7 Budget · 4.8 Cut · 4.9 Tests

Fallback: none needed (pure function); if exposure is missing, rank by AQI × confidence. Budget < 1 s. Cut: no ward splitting, no tracking. Tests: labelling on synthetic masks; threshold edges (AQI 300 vs 301, confidence 0.49 vs 0.5); tracking under a one-cell shift keeps `track_id`.

---

## 5. Source fingerprint (F7)

### 5.1 Purpose

"PM2.5/PM10 ratio, NO₂/CO co-signals, VOC, time and fire points classify each hotspot's cause" (§6 F7), so the optimiser can send the right tool (CONTRACTS §3 matrix).

### 5.2 Inputs and outputs

Per cell (and aggregated per hotspot), features:

| Feature | Definition | Source |
|---|---|---|
| `R` | `pm25_est / pm10_est` (observed super-obs ratio when available) | twin, super-obs |
| `no2`, `co` | median over mobile super-obs in the cell and 8 neighbours in the last 60 min; else nearest station within 3 km | `reading`, `reference_observation` |
| `voc_i` | `median_24h(voc_kohm) / voc_kohm` per device (> 1 = more VOC; BME680 resistance drops with VOC) | `reading` |
| `spike` | max spike ratio in the cell in the last 30 min (device events) or 20-min change of observed PM2.5 | `device_event`, super-obs |
| `hour` | local IST hour | |
| `fire_local` | FIRMS points within 2 km in the last 12 h | `ml:feat:fires:recent` |
| `fire_upwind` | FIRMS points in the wind-from sector ±30° within 300 km, last 24 h (+ FRP sum) | `fire_point` |
| `wd`, `ws` | wind from direction and speed | weather |
| land use | road density, construction density, distance to nearest active construction site, industrial share | `cell_feature`, `site` |
| `city_rise` | city median PM2.5 now / 6 h ago | twin history |
| `homog` | `|log(pm25_cell / city_median)|` (small = city-wide, large = local anomaly) | twin |
| `photo` | verified Citizen Eyes report within 500 m in the last 2 h (cause) | `citizen_report` |

Outputs: `cell_state.cause_label`, `cause_conf`, `cause_probs`; `hotspot` same fields. `CauseLabel` enum from CONTRACTS §3.

### 5.3 Method

**v1: the §9.4 rule table as soft scores.** Each cause's score is the weighted geometric mean of its criteria memberships, computed over available features only (missing features are skipped and counted):

| Cause (§9.4 row) | Criteria (membership) |
|---|---|
| `dust`: high PM10, low PM2.5/PM10, daytime, low NO₂, near roads or sites | `σ(pm10; 200, 40)`, `σ̄(R; 0.45, 0.05)`, day(07–19 → 1, else 0.3), `σ̄(no2; 40, 10)`, `max(σ(road_density; q75, 0.2·q75), near_site_300m)` |
| `traffic`: high NO₂ + CO, rush hours, along corridors | `σ(no2; 50, 10)`, `σ(co; 1500, 300)`, rush(08–11, 17–21 → 1, else 0.4), corridor(`σ(road_density; q75, 0.2·q75)` or major road ≤ 200 m) |
| `burning`: sharp PM2.5 + VOC spike, night, fire point or photo | `σ(spike; 2.0, 0.3)`, `σ(voc_i; 1.5, 0.2)`, `σ(R; 0.6, 0.05)`, night(19–06 → 1, else 0.5), evidence = max(`fire_local ≥ 1`, photo = burning, **0.5 floor**) |
| `regional_smoke`: city-wide PM2.5 rise, north-west wind, FIRMS fires upwind | `σ(city_rise; 1.3, 0.1)`, `σ̄(homog; 0.3, 0.1)`, NW wind(`wd ∈ [270°, 360°]` and `ws ≥ 1` → 1, else 0.3), `σ(fire_upwind; 50, 15)`, `σ(R; 0.6, 0.05)` |

`q75` is the city 75th percentile of road density. The 0.5 evidence floor for burning is deliberate: FIRMS misses small fires (§8.2).

```math
S_k = \exp\!\Big(\textstyle\sum_{m \in A_k} \omega_m \log m\ \big/ \sum_{m\in A_k}\omega_m\Big),\qquad
p_k = \frac{S_k}{\sum_{k'} S_{k'} + s_{\text{unk}}},\quad s_{\text{unk}} = 0.15
```

`p_unknown = s_unk / (Σ S + s_unk)`. Labelling:

- `mixed` if the top two causes are both ≥ 0.3 and within 0.15; the dominant sub-cause (argmax) drives the matrix (CONTRACTS §3, P-08).
- `unknown` if `max p < 0.4` or data quality `q < 0.3`.
- otherwise argmax.

`cause_conf = p_max × q`, `q = min(1, confidence/0.5) × (1 − 0.5 × missing_fraction)`. A single-device spike caps `cause_conf` at 0.65 until corroborated (second device, photo or fire point).

**v2: calibrated gradient-boosted classifier.** LightGBM multiclass over {dust, traffic, burning, regional_smoke} on the same features plus raw values (native missing handling), `class_weight = balanced`; probabilities calibrated with isotonic regression (`CalibratedClassifierCV(method="isotonic")`, one-vs-rest then normalised); `mixed` and `unknown` derived from the calibrated probabilities with the rules above. Labels, in decreasing trust: inspection outcomes `closed_confirmed` with a recorded cause; verified Citizen Eyes reports; expert-labelled episodes (Diwali nights, stubble days identified from FIRMS and wind); simulator ground truth (dominant source contribution per cell-time). Rule outputs are never used as evaluation labels (circularity) and at most as down-weighted (0.3) warm-start labels. Splits are grouped by day to avoid leakage.

**P-08 gating metadata.** Every cell/hotspot record exposes `cause_probs`; the optimiser applies the machine gate (sprinkler/ASG/sweeper only if `P(dust) ≥ 0.5` and `P(burning) + P(regional_smoke) < 0.3` and confidence ≥ 0.3).

### 5.4 Hyperparameters

`configs/fingerprint_rules.yaml` holds every threshold and width above (initial values, tuned on labelled and simulated data). Classifier: `num_leaves 31`, `learning_rate 0.05`, up to 500 trees with early stopping (50), `min_data_in_leaf 50`, `feature_fraction 0.8`.

### 5.5 Validation

Macro-F1, per-class recall (burning recall is critical: missing burning sends water to smoke), Brier score, Expected Calibration Error. **Promotion gate** for v2 over rules: macro-F1 ≥ rules + 0.05 on held-out real-labelled + simulated data, burning recall ≥ rules and ≥ 0.8, ECE ≤ 0.08, and on the golden smoke set `P(dust) < 0.5` for every case. Rules must reproduce the four §9.4 rows on canonical inputs.

### 5.6 Fallback · 5.7 Budget · 5.8 Cut

Fallback: rules (always loaded). Budget < 1 s for 6,000 cells. Cut: rules only (v2 is post-hackathon unless labels exist).

### 5.9 Tests

Canonical input per §9.4 row → expected label (four tests). Missing gases lower `cause_conf` but never raise an error. Property: probabilities sum to 1; monotonicity (increasing NO₂ never lowers `p_traffic`; increasing `fire_upwind` never lowers `p_regional_smoke`); `mixed` rule boundaries; spike-only cap.

---

## 6. Back-trajectory (F7)

### 6.1 Purpose

"Reversing wind vectors pins a likely upwind source" (§6 F7), giving inspectors a target instead of an area.

### 6.2 Inputs and outputs

In: top-10 hotspots (centroid, cause); wind field from `weather_observation` (+ `weather_forecast` for the current hour) at grid points; candidate sources: `site` (construction, industrial_unit, waste_site with grade and violations), recent `fire_point` (12 h), major road segments (OSM). Out: `hotspot.suspect_geom`, `suspect_conf`, `suspect_ref_type` (`site | fire | road | upwind_point | regional_sector`), `suspect_ref_id`, `trajectory` (LineString, median member), `trajectory_spread_m`, `evidence.candidates` (top 3 with scores).

### 6.3 Method

Wind `u(x, t)`: IDW over weather grid points within 30 km, linear in time. Back-trajectory with step Δt = 5 min:

```math
x_{k+1} = x_k - \mathbf u(x_k, t_k)\,\Delta t + \eta_k,\qquad t_{k+1} = t_k - \Delta t
```

Horizon by cause: dust 30 min, traffic 30 min, burning 60 min, mixed/unknown 60 min, regional smoke 180 min (§6 F7 "1–3 h"). **Ensemble** of M = 30 members: speed × (1 + ε_s), ε_s ~ N(0, 0.2²); direction + ε_d, ε_d ~ N(0, 15°²); random walk η_k ~ N(0, 50² m²).

Candidate score for source `j`:

```math
\text{score}_j = \pi(\text{type}_j \mid \text{cause})\cdot a_j \cdot \frac1M\sum_{m}\max_k \exp\!\Big(-\frac{d(x_{m,k}, s_j)^2}{2\sigma_K^2}\Big),\qquad \sigma_K = 250\text{ m}
```

`π` priors (config): construction site | dust 0.8; road | traffic 0.9; waste site | burning 0.7; FIRMS point | burning 0.9; industrial unit | burning 0.4. `a_j` activity: grade C 1.0, B 0.7, A 0.4; recent violation +0.2; fire FRP-scaled. Candidates inside the hotspot cells count from step 0.

`suspect = argmax score`; `suspect_conf = score_best / (Σ score + s_bg)`, `s_bg = 0.2`. If `suspect_conf < 0.25` or no candidates: pin at the ensemble median position 15 min upwind, `ref_type = upwind_point`, conf ≤ 0.3. **Calm** (`ws < 0.5` m/s): no trajectory; candidates within 500 m scored by distance and prior, conf capped at 0.4. **Regional smoke**: no in-city pin; `ref_type = regional_sector` with bearing and the FIRMS count and FRP along the extended 3 h path.

### 6.4 Hyperparameters (`configs/trajectory.yaml`)

`dt_min 5`, horizons above, `members 30`, `speed_sd 0.2`, `dir_sd_deg 15`, `rw_sd_m 50`, `kernel_sigma_m 250`, `bg_mass 0.2`, `calm_ms 0.5`.

### 6.5 Validation

Simulator: suspect within 300 m of the true source for ≥ 60 % of detected hotspots when wind ≥ 1 m/s; hit rate increases monotonically with `suspect_conf` deciles (calibration).

### 6.6 Fallback · 6.7 Budget · 6.8 Cut · 6.9 Tests

Fallback: nearest candidate by prior within 500 m. Budget: 10 × 30 × 36 steps < 200 ms. Cut: single deterministic trajectory (M = 1), same scoring. Tests: uniform westerly wind (from 270°) → path heads west; an upwind candidate outscores an equidistant downwind one; calm branch; regional branch returns a sector, never an in-city pin.

---

## 7. 72 h forecaster (F5)

### 7.1 Purpose

"Gradient-boosted model per cell using lagged readings, IMD/ERA5 weather, calendar and fire features; outputs P10/P50/P90 so officers see uncertainty" (§6 F5); "LightGBM per horizon (1–72 h)" (§8.1). "Per cell" means one prediction per 1 km cell; the model is global across cells (data-efficient, one set of weights).

### 7.2 Inputs and outputs

| Direction | Name | Fields |
|---|---|---|
| Trigger | `hawa.cmd.forecast.v1` `cmd.forecast.run` | `issued_at`, `horizons [1..72]`, `master` |
| In | `cell_state` (last 72 h, aggregated to g1k: confidence-weighted mean of child cells) | `pm25_est`, `pm10_est` |
| In | `reference_observation` | station lags (training and city features) |
| In | `weather_forecast`, `weather_observation` | ws, wd, t, rh, boundary-layer height, precipitation, pressure |
| In | `fire_point` | sector counts, FRP |
| In | `cell_feature`, calendar config | static covariates, holidays, Diwali window, stubble season, school days |
| Out | `forecast_run` | `run_id, issued_at, master, n_cells, feature_freshness, status, model_version` |
| Out | `forecast` | `run_id, cell_id (g1k), issued_at, horizon_h, valid_at, pollutant, p10, p50, p90, grap_stage, model_version` |
| Out | `hawa.forecast.issued.v1` | `forecast.issued` |

`forecast.grap_stage` is the stage of the indicative hourly AQI of P50 (for map colouring). The official, 24 h-average-based outlook is `grap_outlook` (§8).

### 7.3 Method

**Target** `y = log1p(PM2.5)` hourly mean at valid time `t + h` (PM10 is the same pipeline, STRETCH).

**Training data.** (A) Station-hourly series from CPCB/DPCC/OpenAQ (~40 Delhi stations, Oct 2022 → Sep 2026), each with its g1k cell covariates — the primary source during the hackathon (§12.5 "real historical data"). (B) Twin-derived g1k series once ≥ 60 days exist, weighted by mean confidence. The model is applied to cells using twin-derived lags; `scripts/backfill_twin_history.py` produces a stations-only twin reanalysis for the preceding 7 days so lags exist at demo start.

**Models.** For each horizon bucket `b ∈ {1–3, 4–6, 7–12, 13–24, 25–48, 49–72}` and quantile `τ ∈ {0.1, 0.5, 0.9}`: one LightGBM model (`objective="quantile", alpha=τ`), 18 in total, with horizon `h` as a feature. Training rows sample up to 3 horizons per origin per bucket. Loss:

```math
L_\tau(y, q) = \max\big(\tau (y - q),\ (\tau - 1)(y - q)\big)
```

**Features**

| Group | Features |
|---|---|
| Lags | `y(t)`, `y(t−1)`, `y(t−2)`, `y(t−3)`, `y(t−6)`, `y(t−12)`, `y(t−24)`, `y(t−48)` |
| Rolling | mean, sd, min, max over 3, 6, 24 h; Δ1 h, Δ3 h |
| Spatial | ring mean of the 8 neighbours; city median now and its 24 h trend; PM2.5/PM10 ratio now |
| Weather at `t+h` (forecast) | wind speed, sin/cos direction, temperature, RH, boundary-layer height, ventilation index `BLH × ws`, precipitation, pressure tendency |
| Weather now | same, observed |
| Calendar at `t+h` | sin/cos hour, day of week, holiday, Diwali window (−2 … +3 days, dates from a maintained table), stubble season (1 Oct – 30 Nov), school day, GRAP stage in force |
| Fire | FIRMS count and FRP in the NW sector (270°–330°) within 100 km and 300 km over 24 h and 48 h; wind-weighted transport index `Σ FRP · max(0, cos(bearing − wd_to))` |
| Static | road density, industrial share, green share, construction density, population density, cell climatology mean for (month, hour) |
| Horizon | `h` |

**Quantile post-processing.**

1. Crossing fix by rearrangement: sort `(q̂_0.1, q̂_0.5, q̂_0.9)` per row.
2. Minimum width: `q̂_0.9 − q̂_0.1 ≥ 0.10 + 0.004·h` (log space).
3. Conformalised quantile regression per bucket on a rolling 14-day window of realised errors: `E_i = max(q̂_0.1,i − y_i, y_i − q̂_0.9,i)`; widen both ends by the `⌈0.8 (n+1)⌉/n` empirical quantile of `E` (P50 unchanged) so P10–P90 covers ≈ 80 %.
4. `expm1` back-transform, clip ≥ 0.

**Downscaling to 500 m** (for exposure and school cells):

```math
C_{500}(c, t+h) = F_{1k}(t+h)\cdot r_c^{\,\exp(-h/\tau_d)},\qquad r_c = \frac{\text{pm}_{500}(c, t)}{\text{pm}_{1k}(\text{parent}, t)},\ \tau_d = 6\text{ h}
```

applied to each quantile.

**Baselines** (always computed, also the fallback): persistence `ŷ(t+h) = y(t)`; seasonal persistence `y(t+h−24)`; climatology mean by (cell or station, month, hour, day type); intervals from empirical residual quantiles by horizon.

### 7.4 Hyperparameters (`configs/forecaster.yaml`)

```yaml
target: pm25
buckets: [[1,3],[4,6],[7,12],[13,24],[25,48],[49,72]]
quantiles: [0.1, 0.5, 0.9]
horizons_per_origin: 3
lightgbm:
  num_leaves: 63
  learning_rate: 0.05
  n_estimators: 2000
  early_stopping_rounds: 100
  min_data_in_leaf: 100
  feature_fraction: 0.8
  bagging_fraction: 0.8
  bagging_freq: 1
  lambda_l2: 1.0
  max_bin: 255
postprocess:
  min_width_log: {intercept: 0.10, per_hour: 0.004}
  conformal: {window_days: 14, target_coverage: 0.8}
downscale_tau_h: 6
```

### 7.5 Validation

Rolling-origin backtest on the test split ([DATA_AND_TRAINING §7](DATA_AND_TRAINING.md#7-dataset-splits-and-evaluation-protocol)), per horizon and per season (winter Oct–Feb reported separately):

| Metric | Target / gate |
|---|---|
| MAE of P50 at h = 24 vs persistence | Skill `1 − MAE/MAE_persist ≥ 0.10` (the §13.1 "clear improvement"); gate |
| MAE at 48 and 72 h vs climatology | Better than climatology; gate |
| Pinball loss per quantile | Not worse than champion by > 2 %; gate |
| P10–P90 coverage | 0.72–0.88; gate |
| Mean interval width | Reported (sharpness) |
| CRPS (quantile approximation) | Reported |

Online: every hour, realised errors for forecasts issued 1–72 h earlier update `forecast_pinball_loss`, `forecast_mae_ratio_persistence`, `forecast_interval_coverage`.

### 7.6 Fallback

1. Previous champion. 2. No-NWP variant (trained without forecast-weather features) when `weather_forecast` is older than 6 h. 3. Baseline blend `ŷ = w_h·persistence + (1 − w_h)·climatology`, `w_h = exp(−h/12)`, empirical quantiles widened × 1.2, `model_version = forecaster-baseline@…`.

### 7.7 Compute budget

Inference: 1,500 cells × 72 h × 3 quantiles ≈ 324k predictions < 5 s; feature build ≈ 20 s; COPY ≈ 5 s; p95 ≤ 90 s including GRAP and safe windows. Nightly training ≤ 45 min on 8 vCPU.

### 7.8 Hackathon cut

Three buckets (1–6, 7–24, 25–72); no conformal step (keep crossing fix and minimum width); PM2.5 only; station-only training. Never cut the 72 h horizon: the demo's "GRAP outlook turns orange for Thursday" needs 48–72 h (§16.1).

### 7.9 Tests

Pinball loss against hand-computed values; no leakage (a feature builder test on a synthetic series asserts every feature timestamp ≤ `issued_at`); property: after post-processing, `p10 ≤ p50 ≤ p90` and minimum width hold for arbitrary inputs; baselines on a constant series are exact; downscale factor → 1 as `h → ∞`; bucket routing covers 1..72 exactly once.

---

## 8. GRAP Copilot (F6)

### 8.1 Purpose

"Maps forecasts to Delhi's GRAP stages 24–48 h ahead and generates a ward-wise checklist of stage actions, so agencies act before the stage is formally invoked" (§6 F6). Official GRAP is invoked NCR-wide; the ward outlook is an early-action advisory.

### 8.2 Inputs and outputs

In: `forecast` (g1k quantiles) for D+1 … D+3; ward ↔ g1k population weights; `configs/grap_thresholds.yaml`; latest ward hotspots and site grades (drivers). Out: `grap_outlook` (`ward_id, date, issued_at, lead_h, stage_p50, prob_ge {1..4}, recommended_stage, early_action, drivers, model_version`), `grap.outlook_issued`. The checklist **text** is backend config (`grap_actions.yaml`, CONTRACTS §10.2); AI-ML supplies the stage and the drivers (dominant causes, top hotspots, grade-C sites) that parameterise it.

### 8.3 Method

Hourly ward concentration `C_w(t) = Σ_c π_c C_c(t)` with population weights `π_c`. From each hour's quantiles on log scale: `μ_t = log q50`, `σ_t = (log q90 − log q10)/(2 × 1.2816)`. Monte Carlo with N = 500 draws, `z_t` AR(1) across hours with ρ = 0.9 (errors are persistent), fully correlated across cells of a ward (conservative):

```math
\tilde C_w^{(n)}(t) = \exp\big(\mu_t + \sigma_t z_t^{(n)}\big),\quad \bar C^{(n)}_d = \tfrac1{24}\textstyle\sum_{t\in d}\tilde C_w^{(n)}(t)
```

Daily AQI from `C̄` via CONTRACTS §10.1 (PM2.5 sub-index; max with PM10 when the PM10 forecast exists) → stage via CONTRACTS §10.2. `prob_ge[s] = P(stage ≥ s)`; `stage_p50` = stage of the daily mean of P50; `recommended_stage = max{s : P(stage ≥ s) ≥ 0.5}`; `early_action = true` when some `s` above today's stage has `P(stage ≥ s) ≥ 0.3` at 24–48 h lead.

```yaml
# configs/grap_thresholds.yaml
stages:            # CONTRACTS §10.2 (indicative AQI upper bounds)
  - {stage: 0, aqi_max: 200}
  - {stage: 1, aqi_max: 300}
  - {stage: 2, aqi_max: 400}
  - {stage: 3, aqi_max: 450}
  - {stage: 4, aqi_max: 500}
outlook_days: 3
mc_draws: 500
hourly_ar1_rho: 0.9
recommend_prob: 0.5
early_action_prob: 0.3
early_action_lead_h: [24, 48]
```

### 8.4 Validation · 8.5 Fallback · 8.6 Budget · 8.7 Cut · 8.8 Tests

Validation: backtest against city daily AQI (CPCB bulletin) — Brier score and reliability for `P(stage ≥ 3)`; hit and false-alarm rates of `early_action` at 24–48 h; Brier skill vs climatology > 0. Fallback: last outlook kept, flagged stale. Budget < 2 s. Cut: stage from P50 plus "P90 crosses the threshold" flag (the CONTRACTS minimum), no Monte Carlo. Tests: stage boundaries (200/201, 300/301, 400/401, 450/451); `prob_ge` non-increasing in `s`; ρ = 1 vs ρ = 0 changes spread in the right direction.

---

## 9. Exposure engine (F12)

### 9.1 Purpose

"Person-hours of harmful exposure per cell = concentration × population × time-of-day weights × vulnerability" (§6 F12); the planner minimises total forecast E (§9.4).

### 9.2 Inputs and outputs

In: `cell.population` (WorldPop 100 m), `poi` (schools with enrolment, hospitals with beds, elder-care, markets, bus stops), `school`, `configs/population_profiles.yaml`, `configs/vulnerability_weights.yaml`, concentrations (twin now; downscaled forecast quantiles). Out: `cell_state.exposure_ph`, `exposure_ph_pm10`; `/internal/v1/exposure`; node values for the optimiser.

### 9.3 Method

CONTRACTS §10.4:

```math
E(c, t) = \max\big(0,\ C(c,t) - C_{\text{safe}}\big)\cdot \text{Pop}(c,t)\cdot V(c,t)\cdot \Delta t
```

with `C_safe = 60` µg/m³ for PM2.5 (`exposure_ph`) and `100` µg/m³ for PM10 (`exposure_ph_pm10`); `Δt = 0.25 h` for twin states, `1 h` for forecast hours. Population is a sum over groups `g` with hourly profiles, and `V` is the population-weighted group vulnerability, which reduces to the contract formula:

```math
\text{Pop}(c,t)\,V(c,t) = \sum_g \text{Pop}_g(c,t)\,v_g,\qquad V(c,t) = \frac{\sum_g \text{Pop}_g v_g}{\sum_g \text{Pop}_g}
```

| Group `g` | `Pop_g(c, t)` | `v_g` |
|---|---|---|
| residential | WorldPop × at-home fraction(hour, day type) (0.95 night, 0.6 working day) | 1.0 |
| school_children | Σ enrolment (UDISE, default 800) × 1[school day, 07:30–13:30] | 2.0 |
| hospital | beds × 2 (patients + attendants), constant | 2.0 |
| elder_care | capacity, constant | 2.0 |
| outdoor_workers | 3 % of daytime population on cells with major roads, 08–20 | 1.5 |
| bus_stop_commuters | GTFS departures per hour at stops in cell × 20 | 1.3 |
| market_visitors | default footfall × profile (peak 17–21) | 1.2 |

Residential daytime is rescaled so the city total stays within ±10 % of WorldPop. Schools weighted in the morning and markets in the evening, as §9.4 specifies.

**Uncertainty.** `E` is monotone non-decreasing in `C`, so for each cell-hour `E_q = E(C_q)` exactly for q ∈ {P10, P50, P90}. Sums of quantiles are not quantiles of sums: totals with uncertainty come from the What-If Monte Carlo (§11); rankings use P50.

**Avoided exposure** of an action that multiplies concentration by `(1 − e(t))`: `ΔE = E(C) − E(C·(1 − e))`, computed exactly (the `max(0, ·)` makes it non-linear).

Units: µg/m³ · person · h, reported as "person-hours above threshold" with the concentration excess shown alongside (CONTRACTS §10.4).

```yaml
# configs/vulnerability_weights.yaml
version: 1
groups:
  residential: 1.0
  school_children: 2.0
  hospital: 2.0
  elder_care: 2.0
  outdoor_workers: 1.5
  bus_stop_commuters: 1.3
  market_visitors: 1.2
```

### 9.4 Validation · 9.5 Fallback · 9.6 Budget · 9.7 Cut · 9.8 Tests

Validation: city day/night totals vs WorldPop; golden case from §2.5 — a cell with AQI 350 near three schools and a hospital at 08:00 must outrank an empty industrial yard at AQI 450. Fallback: residential only if POIs are missing. Budget: `Pop·V` arrays (cells × 168 hours of a week × day types) precomputed at startup; lookups O(1); `/exposure` p95 ≤ 1 s. Cut: residential + schools + hospitals. Tests: `C ≤ C_safe → 0`; linear in excess above threshold; property: monotone in `C`, `Pop`, `V`; §2.5 golden case; `Δt` handling.

---

## 10. Dispatch optimiser (F13)

### 10.1 Purpose

"A capacitated vehicle-routing problem in OR-Tools: each asset has a depot, shift window and capacity; each hotspot has a time window (before the forecast peak), a required asset type (from the cause) and a value equal to its expected exposure reduction, taken from the effectiveness library. The solver maximises exposure avoided within the shift; a greedy fallback runs in milliseconds" (§9.4).

### 10.2 Inputs and outputs

In (frozen `PlanContext`): ranked hotspots (≤ 40) with `cause_probs`, target g500 cells, suspect pin; downscaled forecast exposure series per target cell over `[window_start, window_end]`; `asset` (id, type, depot, capacity, status) and `asset_shift`; `effectiveness_library`; `configs/cause_asset_matrix.yaml`, `configs/optimizer.yaml`; mode. Out: routes and `plan_task` candidates (`asset_id, cell_id (g1k), target_cell_ids (g500), kind (spray|sweep|inspect|protect_alert), eta_start, eta_end, seq, expected_effect {p10,p50,p90}, reason_text (template until the Planner writes it), model_version`), plus a constraint report.

### 10.3 Method

**Allowed asset types** per hotspot = CONTRACTS §3 matrix for its label (`mixed` → dominant sub-cause), then the P-08 machine gate:

```yaml
# configs/cause_asset_matrix.yaml
version: 1
matrix:                     # CONTRACTS §3 (hard constraint)
  dust:           [sprinkler, anti_smog_gun, sweeper, inspection_team]
  traffic:        [inspection_team]
  burning:        [inspection_team]
  regional_smoke: []
  unknown:        [inspection_team]
  mixed:          dominant_sub_cause
alerts: {traffic: true, burning: true, regional_smoke: true, unknown: true}
machine_gate:               # P-08 (hard, stricter than the matrix)
  machine_types: [sprinkler, anti_smog_gun, sweeper]
  min_p_dust: 0.5
  max_p_burning_plus_regional: 0.3
  min_cell_confidence: 0.3
```

**Candidate nodes.** For each hotspot `h` and allowed type `a`: location = nearest road point to the peak-exposure target cell (machines) or the suspect pin (inspection); service time `s_a` (sprinkler 25 min per cell pass, anti-smog gun 40 min, sweeper 30 min, inspection 35 min); demand `d_a` (sprinkler/ASG litres = `flow_lpm × s_a`, e.g. 40 × 25 = 1,000 L; sweeper 1; inspection 1).

**Time-window copies.** Value depends on timing relative to the forecast peak, so each (h, a) gets up to K = 3 copies with windows `[t_k − 30, t_k + 30]` min at `t_k ∈ {peak − 120, peak − 60, peak − 15}` min (inside shifts and the plan window). Copies form one disjunction (at most one visited).

**Node value** (expected avoided exposure, P50, in person-hours above threshold):

```math
V_{h,a,k} = P(\text{cause}_a \mid h)\cdot \text{cov}_a \sum_{t=t_k}^{t_k + D_a} \Big[E\big(C_t\big) - E\big(C_t\,(1 - e_a\,g(t - t_k))\big)\Big]
```

- `e_a`, `D_a`: effectiveness-library posterior mean effect (fraction) and duration for the stratum (cause × asset type × land use × season × hour band, §13).
- `g`: effect profile (1 for the first `D/2`, then linear to 0 at `D`).
- `cov_a`: share of the target cell's exposed population the action reaches (spray effect limited to ~200 m, §2.4): sprinkler 0.4, anti-smog gun 0.3, sweeper 0.5. For inspection: `cov = suspect_conf × P(abated | found) (0.7)`, and `e` = share of the excess attributable to the local source, `(C − C_background)/C`.
- `P(cause_a | h)`: probability the hotspot has the cause this asset fixes (from `cause_probs`); expected value under attribution uncertainty.
- Summed over PM2.5 exposure plus `0.5 ×` PM10 exposure for dust-capable assets (config `pm10_weight`).

**Routing model** (OR-Tools `pywrapcp`):

- `RoutingIndexManager(n_nodes, n_vehicles, starts, ends)` with each asset's depot as start and end.
- Transit callback: travel minutes = haversine × 1.35 detour / speed (sprinkler and ASG 15 km/h, sweeper 10 km/h, inspection team 20 km/h; config; OSRM matrix optional) + service time of the origin node.
- **Time dimension** (`AddDimension`, slack ≤ 60 min): node windows via `CumulVar(index).SetRange(open, close)`; vehicle start/end windows from `asset_shift`.
- **Capacity dimension** (`AddDimensionWithVehicleCapacity`): tank litres per asset from `asset.capacity` (inspection teams: max inspections per shift, default 6).
- **Hard cause constraint**: `routing.SetAllowedVehiclesForIndex(allowed_vehicle_ids, index)` per node — a sprinkler vehicle is never allowed on a burning node, so the solver cannot produce one.
- **Prize collecting**: `routing.AddDisjunction(copies, penalty = V_max·scale, 1)`; the regret of choosing a lower-value copy is added to arcs leaving it: `arc_cost(i → j) = travel_min(i, j)·c_travel + (V_max − V_i)·scale`. Dropping a node costs its value, so the solver maximises exposure avoided minus travel cost. `c_travel = 2` person-hours per minute (config): a 30-min detour must buy ≥ 60 person-hours.
- Per-asset task cap (default 8 per shift).
- Search: `PARALLEL_CHEAPEST_INSERTION` first solution, `GUIDED_LOCAL_SEARCH`, time limit 8 s (master), 5 s (replan and `/optimize`), 2 s (spike); integer scaling ×10.

**Protect-only tasks.** Hotspots whose allowed set is empty (regional smoke) or has no available asset produce `protect_alert` tasks (no vehicle) for the schools and wards they affect. Their exposure reduction is **not** counted in "exposure avoided" (behavioural effects are unverified); the plan reports people alerted instead.

**Greedy fallback.** Sort candidate nodes by `V / (s_a + travel from nearest depot)`; for each, cheapest feasible insertion across allowed vehicles (re-timing the route, checking windows and capacity); accept if `V − c_travel·Δtravel > 0`. O(n²m) for n ≤ 120 nodes, m ≤ 50 vehicles: milliseconds.

**Constraint checker** (`optimizer/constraints.py`, the single source of truth for the optimiser, the agents' `check_constraints` tool, the Auditor re-validation and `/optimize`):

| Code | Severity | Rule |
|---|---|---|
| `CAUSE_ASSET_MATRIX` | hard | asset type ∈ matrix(cause) |
| `CAUSE_CONFIDENCE_GATE` | hard | P-08 machine gate |
| `ASSET_UNAVAILABLE` | hard | status `available`, not `maintenance`/`offline` |
| `SHIFT_WINDOW` / `NODE_WINDOW` | hard | ETA inside shift and node window |
| `CAPACITY` | hard | cumulative demand ≤ capacity |
| `DOUBLE_BOOKING` | hard | one asset, non-overlapping tasks |
| `WARD_SCOPE` | hard | target cells in the plan's wards |
| `LOW_CONFIDENCE_MACHINE` | hard | no machine on cells with confidence < 0.3 |
| `DUPLICATE_TARGET` | warning | two machines on one g500 cell within 60 min |
| `STATION_PROXIMITY` | warning | > 30 % of spray tasks within 1 km of a reference station while those hotspots have < 3 mobile super-obs (F15) |
| `SCHOOL_WINDOW_MISSED` | warning | a school-cell hotspot in the top 5 has no task or alert before 07:30 |

Plans with hard violations are never persisted.

### 10.4 Hyperparameters (`configs/optimizer.yaml`)

`service_min {sprinkler 25, anti_smog_gun 40, sweeper 30, inspection_team 35}`, `speed_kmh {15, 15, 10, 20}`, `detour 1.35`, `copies 3`, `copy_offsets_min [−120, −60, −15]`, `window_half_min 30`, `coverage {0.4, 0.3, 0.5}`, `abate_prob 0.7`, `pm10_weight 0.5`, `c_travel_ph_per_min 2`, `max_tasks_per_asset 8`, `time_limit_s {master 8, replan 5, api 5, spike 2}`, `max_hotspots 40`, `value_scale 10`.

### 10.5 Validation

Synthetic scenarios: CVRPTW objective ≥ greedy (typically ≥ 5 % better); within 2 % of an exact MIP optimum on tiny instances (≤ 8 nodes, solved by brute force in tests); 100 % feasibility under the checker; solve time within limits; golden scenarios (regional smoke → zero machine tasks; burning → inspection only; school morning prioritised).

### 10.6 Fallback · 10.7 Budget · 10.8 Cut

Fallback: greedy; if no feasible machine task, protect-only plan; if nothing at all, `plan.failed`. Budget: ≤ 120 nodes × ≤ 50 vehicles in 2–8 s. Cut: K = 1 window copy, haversine travel. Never cut the hard constraints.

### 10.9 Tests

Property (hypothesis, random causes/assets/windows): every returned plan passes `check_plan` with zero hard violations; no machine on `burning`/`regional_smoke`/`traffic` nodes; regional-smoke-only inputs produce zero vehicle tasks; greedy and CVRPTW both feasible; objective(CVRPTW) ≥ objective(greedy) − ε on the same instance. Unit: disjunction regret arithmetic; time-window copy generation respects shifts; allowed-vehicle wiring; capacity accounting.

---

## 11. What-If simulator (F13)

### 11.1 Purpose

"The What-If screen compares 'usual routes' against the AI plan in person-hours avoided" (§6 F13) — one of the two features that must never be dropped (§16).

### 11.2 Inputs and outputs

In: a plan (tasks) or a candidate; the baseline from `asset_usual_route` (P-10): each asset's fixed route and start time in the window, with traversed cells and pass times; forecast quantiles; effectiveness library; hotspot `cause_probs`. Out: `plan_simulation` (`simulation_id, plan_id, baseline_kind, n_draws, seed, plan_p10/p50/p90, baseline_p10/p50/p90, delta_p10/p50/p90, prob_better, per_ward, per_task, model_versions, is_simulated, created_at`); `plan.drafted.expected_exposure_avoided_ph = plan_p50`, `baseline_exposure_avoided_ph = baseline_p50`.

### 11.3 Method

Same fleet, same forecast, same effect model for both arms, so the comparison isolates targeting. The baseline treats every traversed target cell at its pass time with the asset's type **regardless of cause**; the library gives water on smoke an effect near zero, so misdirected passes add nothing.

Paired Monte Carlo, N = 1,000 draws with common random numbers:

1. Concentration paths per cell from the forecast quantiles (lognormal fit per hour, AR(1) ρ = 0.9 in time).
2. Effect sizes per stratum from the library posterior (normal in log-ratio space).
3. Cause realisation per hotspot from `cause_probs`.
4. Avoided exposure `A_plan`, `A_base` per draw using §9.3; `Δ = A_plan − A_base`.

Report P10/P50/P90 of `A_plan`, `A_base`, `Δ` and `P(Δ > 0)`. Per-task contributions (Shapley-free, one-at-a-time removal on the P50 draw) feed the task cards. The UI labels What-If as model-based until verified impacts exist.

### 11.4 Validation · 11.5 Fallback · 11.6 Budget · 11.7 Cut · 11.8 Tests

Validation: over ≥ 20 simulated days, What-If predicted avoided exposure vs ground-truth avoided exposure (simulator truth effects): Spearman ≥ 0.7; truth inside P10–P90 in ≥ 70 % of days. Fallback: P50-only evaluation with forecast P10/P90 bounds. Budget: vectorised numpy, ≤ 60 tasks × 200 cells × 6 h × 1,000 draws < 1 s; `/simulate` p95 ≤ 3 s. Cut: never cut; minimal form is the P50-only fallback. Tests: plan identical to baseline → `Δ = 0` in every draw; adding a positive-value task never lowers `A_plan` in any draw; water on a smoke cell adds zero; seed reproducibility.

---

## 12. Causal verification (F18)

### 12.1 Purpose

"For each intervention, donor cells are chosen that were not treated, have similar land use, and moved similarly over the previous six hours. A weighted synthetic control predicts what the treated cell would have looked like without the spray; the difference is the effect. A placebo test on donor cells gives a confidence interval, so a result like 'PM10 −18 % for 90 min' comes with its uncertainty" (§9.4). The second never-drop feature (§16).

### 12.2 Inputs and outputs

| Direction | Name | Fields |
|---|---|---|
| Trigger | `hawa.cmd.verify.v1` `cmd.verify.run {intervention_id, stage}` (P-02) | |
| In | `intervention` | `task_id, asset_id, start_ts, end_ts, track, cell_ids, litres, pm_before, pm_after, source (hawatag\|manual\|gps_inferred), is_simulated` |
| In | `cell_state` | 15-min `pm25_est`, `pm10_est`, `confidence`, `n_obs` for treated and candidate cells over `[start − 6 h, end + H]` |
| In | `intervention` (others), `weather_observation`, `cell_feature` | donor exclusion, wind, land use |
| In | S3 `verify/{intervention_id}/pre.parquet` | frozen pre-period (reproducibility) |
| Out | `impact` (one row per pollutant: `pm10`, `pm25`) | `impact_id, intervention_id, task_id, cell_id (primary g500), treated_cells, pollutant, effect_pct, ci_low, ci_high, duration_min, method, verdict, donor_cells, donor_weights, placebo_p, pre_rmspe, n_post_obs, stage, evidence_level, reason, model_version, is_simulated` |
| Out | `hawa.impact.verified.v1` | `impact.verified` (CONTRACTS §5.3 + P-02 fields) |

### 12.3 Method

**Windows** (CONTRACTS §10.3 as resolved by P-02): pre-period `T0 = [t_s − 6 h, t_s)` = 24 points at 15 min; post-period `T1 = [t_s, t_e + H]` with `H = 2 h` (provisional run at `t_e + 2 h`) or `4 h` (final run at `t_e + 4 h`). `t_s`, `t_e` = spray start and end.

**Treated series.** `Y1_t = log1p` of the pollutant, track-length-weighted mean over treated cells; primary `cell_id` = the cell with the longest track.

**Donor pool** (in order):

1. **Untreated**: no intervention touching the cell in `[t_s − 6 h, t_e + H]` (Redis `ml:feat:treated:*` for speed, `intervention` authoritative).
2. **Spillover buffer**: centroid ≥ 1.5 km from every treated cell (the twin's short length scale ~0.8 km and the ~200 m spray reach would otherwise leak the effect).
3. **Not downwind**: exclude cells within 3 km inside the ±30° downwind cone of the treated cells during `T1`.
4. **Land use**: same dominant class, or standardised covariate distance ≤ 1.5.
5. **Similar pre-trend**: `corr(Y1, Yj) ≥ 0.6` over `T0` and de-meaned normalised RMSE ≤ 0.3.
6. **Weather-matched**: within 8 km (shared local meteorology) — wind, mixing height and humidity are then common to donors and treated.
7. **Data quality**: `confidence ≥ 0.5` in ≥ 80 % of `T0` and `T1` points.

Rank by pre-period RMSE; keep `K ≤ 30`; synthetic control needs `K ≥ 8`.

**Weights** (de-meaned synthetic control; levels differ between cells, trends co-move). With `Ỹ = Y − mean_{T0}(Y)`:

```math
w^* = \arg\min_{w}\ \sum_{t\in T_0}\Big(\tilde Y_{1t} - \sum_j w_j \tilde Y_{jt}\Big)^2 + \lambda\lVert w\rVert^2 \quad\text{s.t.}\quad w_j \ge 0,\ \sum_j w_j = 1
```

Solved by `scipy.optimize.minimize(method="SLSQP")` with bounds [0, 1] and the equality constraint (`λ = 10⁻³ × mean diag`). Counterfactual `Ŷ0_t = mean_{T0}(Y1) + Σ_j w_j Ỹ_jt`; gap `g_t = Y1_t − Ŷ0_t` (log space). Pre-fit quality `pre_rmspe = sqrt(mean_{T0} g_t²)`.

**Effect** over a **pre-registered** window `T_eff = [t_s, t_e + D_prior]` with `D_prior` = library duration for the stratum (default 90 min), fixed before looking at the post data to avoid selecting the window by significance:

```math
\hat e_1 = \frac{1}{|T_{\text{eff}}|}\sum_{t \in T_{\text{eff}}} g_t
```

**Placebo-in-space.** For each donor `j`, treat it as treated, build its synthetic control from the other donors (the real treated unit excluded), compute `ê_j` and `pre_rmspe_j`; drop placebos with `pre_rmspe_j > 5 × pre_rmspe_1` (ADH practice, configurable). With `J'` retained placebos:

- p-value on the RMSPE ratio `ρ = post_rmspe/pre_rmspe`: `placebo_p = (1 + #{j : ρ_j ≥ ρ_1}) / (1 + J')`. With `J' ≥ 19` the minimum is ≤ 0.05.
- Bias-corrected effect `e = ê_1 − median_j ê_j`; confidence interval by test inversion: `[ê_1 − q_{0.975}(ê_j), ê_1 − q_{0.025}(ê_j)]` (95 % when `J' ≥ 19`, else 90 % with `ci_level` recorded in `evidence`). The median lies between the quantiles, so `ci_low ≤ effect ≤ ci_high` by construction.
- Percent scale: `effect_pct = 100·(e^{e} − 1)`, same transform for the bounds.

**Duration.** `duration_min` = length of the contiguous period from `t_s` during which the 3-point rolling mean of `g_t` stays below the placebo 10th-percentile band (0 if never), capped by `T1`.

**Verdict** (`ImpactVerdict`; negative effect = reduction):

| Verdict | Rule |
|---|---|
| `inconclusive` | any of: `pre_rmspe > 0.10`, `n_post_obs < 3` (treated cells had fewer than 3 observed super-obs in `T1`), CI width > 40 percentage points, method `before_after_naive` |
| `effective` | `ci_high < 0` and `placebo_p ≤ 0.10` |
| `adverse` | `ci_low > 0` and `placebo_p ≤ 0.10` |
| `no_detectable_effect` | CI contains 0 (or `placebo_p > 0.10`) and CI width ≤ 30 points (an informative null) |
| `inconclusive` | otherwise |

Evidence level: `high` = synthetic control with `J' ≥ 19`, good pre-fit and `n_post_obs ≥ 6`; `medium` = fewer placebos, DiD, `manual` or `gps_inferred` source; `low` = naive.

**Method fallback** (`ImpactMethod`):

- `diff_in_diff` when `3 ≤ K < 8` or the SC pre-fit fails: controls = best 5 donors, equal weights; `(Ȳ1,post − Ȳ1,pre) − (Ȳc,post − Ȳc,pre)`; CI from a moving-block bootstrap over time (block 4 points = 1 h, B = 1,000); parallel pre-trends tested (slope difference p > 0.1) or the verdict is `inconclusive`.
- `before_after_naive` when `K < 3`: 60 min pre vs 60 min post in the treated cells, block-bootstrap CI, flagged "low evidence", verdict **never** `effective` or `adverse`.

**Robustness check.** Recompute with observed-only cell super-obs (not the posterior) where available; if the sign disagrees, downgrade `evidence_level` one step.

**Other intervention sources.** `manual` (inspection closure, §8.2 "verifier tracks the cell returning to baseline") and `gps_inferred` use the same pipeline with the recorded or inferred start; evidence at most `medium`.

### 12.4 Hyperparameters (`configs/verifier.yaml`)

```yaml
windows: {pre_h: 6, post_h: {provisional: 2, final: 4}, step_min: 15}
donors:
  spillover_buffer_km: 1.5
  downwind_cone_deg: 30
  downwind_radius_km: 3
  max_distance_km: 8
  landuse_max_dist: 1.5
  min_pre_corr: 0.6
  max_pre_nrmse: 0.3
  min_confidence: 0.5
  min_valid_share: 0.8
  k_max: 30
  k_min_sc: 8
  k_min_did: 3
sc: {ridge_lambda_rel: 1.0e-3}
placebo: {max_pre_rmspe_ratio: 5.0, ci_level_full: 0.95, ci_level_small: 0.90}
effect: {default_duration_min: 90}
verdict:
  max_pre_rmspe: 0.10
  min_post_obs: 3
  max_ci_width_pp: 40
  informative_null_width_pp: 30
  p_threshold: 0.10
did: {n_controls: 5, block_points: 4, bootstrap: 1000}
```

### 12.5 Validation

**Injected known effects** (§12.5 of the proposal; simulator contract in [DATA_AND_TRAINING §6](DATA_AND_TRAINING.md#6-synthetic-data-contract-with-the-backend-simulator)). Suite of ≥ 200 simulated interventions across true cell-mean effects {0, −5, −10, −20, −30 %}, durations {45, 90, 150 min}, wind regimes and post-period coverage levels. The estimand is the **cell-mean** reduction recorded by the simulator (not the local 200 m plume effect).

| Metric | Target |
|---|---|
| 95 % CI covers the true effect | ≥ 0.88 |
| Mean bias of `effect_pct` | ≤ 3 percentage points |
| False `effective` at true effect 0 | ≤ 0.10 (goal 0.05) |
| Power (`effective`) at −20 % with ≥ 6 post observations | ≥ 0.70 |
| Duration MAE (effective cases) | ≤ 45 min |
| Demo interventions | Injected effect inside the CI (the §12.5 claim) |

**Real-data null calibration** (no simulator needed): run the verifier on random untreated "fake interventions" in real twin data; `effective` + `adverse` rate ≤ 0.10 and `placebo_p` approximately uniform. Both suites run nightly as `cmd.train.run {model: verifier_eval}` (P-03) and gate verifier code changes in CI.

### 12.6 Fallback

As above: SC → DiD → naive (low evidence). Compute timeout → `inconclusive`, `reason: compute_timeout`. No post observations → `inconclusive`, `reason: no_post_observations`, and the coverage router requests a pass (§15).

### 12.7 Compute budget

K ≤ 30 donors, ~40 time points: SC solve ~ms; 30 placebo solves < 1 s; data load dominates. p95 ≤ 10 s, hard 60 s.

### 12.8 Hackathon cut

Never cut. Minimal version: SC with the top 20 donors by pre-RMSE, placebo p-value and CI, verdict rules; skip the duration estimate and the observed-only check.

### 12.9 Tests

Property (hypothesis): weights `≥ 0` and sum to 1 (±1e-6); exact recovery — if `Y1 = Σ w_true·Yj + c + δ·1[post]` without noise, `effect ≈ δ`; invariance to donor order; `ci_low ≤ effect ≤ ci_high`; `placebo_p ∈ [1/(J'+1), 1]`; naive method never returns `effective`/`adverse`. Statistical (slow marker): under the null with iid noise, p-values are approximately uniform (KS test, seeded). Unit: donor rules (buffer, downwind cone, treated exclusion); verdict table cases; P-02 stage windows.

---

## 13. Effectiveness library (F18)

### 13.1 Purpose

"Every verified outcome updates the Intervention Effectiveness Library, so tomorrow's plan is better than today's" (§5). Supplies `e_a` and `D_a` to the optimiser (§10.3) and the What-If (§11).

### 13.2 Inputs and outputs

In: `impact` (final preferred; provisional weighted 0.5 until superseded), `configs/effectiveness_priors.yaml`, strata keys at treatment time: cause (hotspot label), asset type, land use (cell class), season (winter Oct–Feb, summer Mar–Jun, monsoon Jul–Sep), hour band (05–08, 08–11, 11–16, 16–21, 21–05), pollutant. Out: `effectiveness_library` rows (`pollutant, cause, asset_type, land_use, season, hour_band` with `*` for pooled levels, `level, effect_mean_pct, effect_p10_pct, effect_p90_pct, duration_mean_min, n_obs, n_effective, tau, prior_mean_pct, prior_sd, source (prior|pooled|data), updated_at, model_version`).

### 13.3 Method

Work in log-ratio space `θ = log(1 + effect_pct/100)`. Each impact gives `θ̂_i` with `se_i = (log(1 + ci_high/100) − log(1 + ci_low/100)) / (2·z)` (z = 1.96 for 95 %, 1.645 for 90 %). Hierarchy: L0 = (pollutant, asset type, cause) → L1 + land use → L2 + season → L3 + hour band. Normal–normal partial pooling:

```math
\theta_{\text{child}} \sim \mathcal N(\theta_{\text{parent}}, \tau_k^2),\qquad \hat\theta_i \sim \mathcal N(\theta_{\text{child}}, se_i^2 + \sigma_w^2)
```

```math
m = \frac{\mu_{\text{parent}}/\tau_k^2 + \sum_i \hat\theta_i/(se_i^2+\sigma_w^2)}{1/\tau_k^2 + \sum_i 1/(se_i^2+\sigma_w^2)},\qquad v = \Big(1/\tau_k^2 + \textstyle\sum_i 1/(se_i^2+\sigma_w^2)\Big)^{-1}
```

`τ_k` by DerSimonian–Laird method of moments across siblings (floor 0.02, cap 0.3); `σ_w = 0.05` within-stratum heterogeneity; the root takes the prior from config. Evidence weighting: naive estimates excluded; DiD `se × √2`; `inconclusive` results with an estimate are included (their wide `se` limits influence); `no_post_observations` excluded. Duration: the same pooling on `log(duration)` using `effective` results only. The optimiser reads the deepest node's posterior (it already contains the parents' information). Incremental update on each `impact.verified` recomputes the affected path (closed form); the nightly job (`cmd.train.run {model: effectiveness}`) refits `τ`.

**Priors** (explicitly priors, not claims; informed by §2.4: IIT Delhi found a very small PM2.5 effect limited to ~200 m):

| Asset type × cause | PM10 prior (mean, sd) | PM2.5 prior | Duration prior |
|---|---|---|---|
| sprinkler × dust | −10 %, 8 | −3 %, 4 | 60 min |
| anti_smog_gun × dust | −8 %, 8 | −3 %, 4 | 45 min |
| sweeper × dust | −6 %, 6 | −2 %, 3 | 120 min |
| inspection_team × dust (site check) | −10 %, 10 | −4 %, 6 | 240 min |
| inspection_team × burning (source abated) | −15 %, 15 | −25 %, 15 | 180 min |
| any water asset × burning or regional_smoke | 0 %, 2 | 0 %, 2 | 0 |

### 13.4 Validation · 13.5 Fallback · 13.6 Budget · 13.7 Cut · 13.8 Tests

Validation: on the simulator with known stratum effects, posterior means converge to truth and P10–P90 covers truth ≈ 80 %; leave-one-intervention-out MSE lower than raw stratum means. Fallback: priors. Budget: milliseconds. Cut: L0 + L1 levels only. Tests: conjugate update arithmetic; no data → prior; many consistent observations → posterior near their mean; lower `se` moves the posterior more; every optimiser stratum resolves to some node.

---

## 14. Anti-gaming guard (F15)

### 14.1 Purpose

"Flags cells where cleaning clusters around official stations while mobile readings nearby stay high, China's documented failure mode" (§6 F15, §4.1).

### 14.2 Inputs and outputs

In: `intervention` (trailing 7 days), `reference_station`, mobile super-obs from `cell_state`/`reading` in rings around stations, hotspot exposure. Out: `integrity_flag` (`flag_id, kind: station_clustering, subject: station_id, ward_id, severity, score, window_start, window_end, evidence, model_version`), `integrity.flagged`; the `STATION_PROXIMITY` warning in the constraint checker; an Auditor category.

### 14.3 Method

Per station `s`, radius `R = 1` km, ring 1–3 km:

- **Concentration ratio** `G_s = (spray minutes within R of s / all spray minutes) / (hotspot exposure within R of s / all hotspot exposure)` over the ward and week. `G > 2` is suspicious.
- **Divergence** `D_s`: difference-in-differences of (station − ring mobile mean) between days with near-station spraying and days without. Significantly negative `D` (p < 0.1, block bootstrap) means the station improves relative to its surroundings when cleaned nearby.
- Severity: `low` if `2 ≤ G < 3`; `medium` if `G ≥ 3` or `D` significant; `high` if both.

Device-level integrity flags also written here: `implausible_jump` (§3.3 step 8), `device_drift` (§2.3), `device_tamper` (from `device.tamper` events).

### 14.4 Validation · Fallback · Budget · Cut · Tests

Simulator scenario with an operator spraying only near a station: flagged within 3 days; false alarms ≤ 5 % per ward-week on normal plans. Fallback: `G` only when ring data is sparse. Budget: seconds, nightly and on each plan (warning only). Cut (STRETCH): `G` ratio and the planning warning. Tests: `G` arithmetic; divergence sign on synthetic station/ring series; no flag when exposure near the station justifies the spraying.

---

## 15. Active sensing router (F11)

### 15.1 Purpose

"Low-confidence cells are sent to the planner as 'blind spots'; the system suggests which bus route or rider should pass through next" (§6 F11). Also drives post-spray passes so verification has data.

### 15.2 Inputs and outputs

In: `cell_state` (confidence, variance), exposure (next 3 h), GTFS routes/shapes/trips mapped to cells by time, `device` ↔ vehicle links, rider devices, interventions awaiting post-period data. Out: `coverage_gap` (`run_id, cell_id, voi, confidence, reason (low_confidence|verification_pending), suggested_kind (bus_route|rider|none), suggested_ref, suggested_window, expected_confidence_gain, model_version`); the §13.1 coverage KPI.

### 15.3 Method

Value of information per cell:

```math
\text{VOI}(c) = \underbrace{\textstyle\sum_{t\in\text{next 3 h}} \text{Pop}(c,t)V(c,t)}_{\text{people at stake}}\cdot p_c(1-p_c) + \beta\,E_{\text{pending}}(c)
```

`p_c = P(C > C_hot)` from the lognormal posterior (misclassification risk is highest near the threshold, `C_hot` = AQI 301 equivalent); the second term boosts cells with interventions awaiting post-period observations (`β = 1`). Blind spots: confidence < 0.5 and VOI in the top 10 %. For each GTFS trip in the next 3 h served by a HawaPod-equipped vehicle, coverage value `Σ_{cells on shape} VOI·(1 − confidence)`; suggest the top 5 trips. Riders: detour of ≤ 2 km maximising VOI per km. Expected confidence gain from the GP posterior with a hypothetical observation (rank-one update).

### 15.4 Validation · Fallback · Budget · Cut · Tests

Simulator: following suggestions raises blind-spot confidence more than random routing and lowers `inconclusive` verdicts from `no_post_observations`. Fallback: VOI list only. Budget < 2 s per twin run. Cut (STRETCH): VOI list and verification-pending boost, no GTFS matching. Tests: VOI peaks at `p = 0.5`; pending boost; trip scoring on a toy shape.

---

## 16. Site compliance score (F9)

### 16.1 Purpose

"Construction sites and units graded A/B/C from sensor-measured behaviour; better grades face lighter curbs on bad days" (§6 F9). Grades target inspections; they never fine.

### 16.2 Inputs and outputs

In: `site`, mobile super-obs within 300 m, wind, dust hotspots whose suspect is the site, `inspection` outcomes, verified citizen reports within 200 m. Out: `site_score` (`site_id, as_of, score, grade, components, n_windows, confidence, data_sufficient, model_version`); nightly `cmd.train.run {model: site_score}`.

### 16.3 Method

Trailing 14 days:

- Downwind excess `x̃`: median over paired windows (working hours) of PM10 downwind (±45° cone of wind-to, ≤ 300 m) minus upwind, normalised by city background.
- `H`: dust hotspots per week with suspect = site and `suspect_conf ≥ 0.4`.
- `I`: share of inspections `closed_confirmed`.
- `Rp`: verified dust/burning reports within 200 m.

`S = 100 − (40·f(x̃) + 30·g(H) + 20·I + 10·h(Rp))` with saturating `f, g, h ∈ [0, 1]`. Grade A ≥ 70, B 40–70, C < 40, with ±5-point hysteresis. Fewer than 20 paired windows → `data_sufficient = false`, grade carried forward (new sites stay ungraded).

### 16.4 Validation · Fallback · Budget · Cut · Tests

Simulator with good and bad sites: grade separation AUC ≥ 0.8; week-on-week grade changes ≤ 20 % without new evidence. Fallback: carry forward. Budget: seconds. Cut (STRETCH): `H` and `I` components only. Tests: hysteresis; insufficiency rule; component monotonicity.

---

## 17. Power-proxy compliance (F10, VISION)

Architecture only. "On restriction days, smart-meter load of listed units checks whether a promised shutdown really happened" (§6 F10). Design: 15-min load per listed unit from the utility (pilot integration); expected profile = median by weekday × hour over 8 weeks; on restriction days, compliant if observed ≤ 20 % of expected during mandated hours; CUSUM change-point for the shutdown time; output a compliance flag with confidence to `integrity_flag` (new kind, additive enum) and the site record. `hawa_ml/power/proxy.py` holds the interface only.

---

## 18. School safe-window scheduler (F19)

### 18.1 Purpose

"Indoor/outdoor HawaPod-S pairs plus the forecast give each school the safest outdoor window and tell it when to seal or ventilate classrooms" (§6 F19); Flow C.

### 18.2 Inputs and outputs

In: downscaled forecast (P10/P50/P90) at the school's g500 cell for the next school day; HawaPod-S pair readings (`HPS-NNNN-O` outdoor PM2.5, `HPS-NNNN-I` indoor PM2.5 and `co2_ppm`); school hours (default 07:30–13:30); `configs/school_window.yaml`. Out: `school_safe_window` (`school_id, date, windows [{start, end, level, confidence}], advice (seal|ventilate|purge|normal), advice_reason, alert_trigger, io_ratio, co2_ppm, forecast_run_id, model_version`); `school.safe_window_computed`.

### 18.3 Method

- Hourly slots in school hours: `safe` if P90 PM2.5 ≤ 60; `acceptable` if P50 ≤ 60 and P90 ≤ 90; else `unsafe`. Windows = contiguous `safe` slots (or `acceptable` if none) of ≥ 1 h; `confidence = mean P(C ≤ 60)` from the lognormal fit.
- Same-day nowcast correction: outdoor HawaPod-S / forecast ratio applied with `exp(−h/3 h)` decay.
- Advice from `IO = PM_in/PM_out` (last hour) and CO₂:
  - `seal`: outdoor PM2.5 (now or P50 next 2 h) > 60 and `PM_out > 1.2·PM_in` → keep windows and doors shut.
  - `ventilate`: CO₂ > 1,000 ppm and outdoor P50 next hour ≤ 60.
  - `purge`: CO₂ > 1,200 ppm and outdoor > 60 → ventilate 10–15 min in the lowest-PM forecast hour, otherwise seal.
  - `normal` otherwise.
- `alert_trigger` per CONTRACTS §10.3: forecast P50 PM2.5 > 250 µg/m³ in school hours, or GRAP ≥ 3.
- Protection evidence (§10.4 HawaPod-S): IO ratio during sealed hours reported with the next day's result.

### 18.4 Validation · Fallback · Budget · Cut · Tests

Backtest: share of `safe` windows whose realised PM2.5 ≤ 60 ≥ 0.85 (precision of "safe"); alert lead time ≥ 12 h (§13.1) for 19:00 alerts. Fallback: forecast-only advice when the pair is offline. Budget < 1 s for 20 pilot schools. Cut (STRETCH, second in the §16 cut list): forecast-only windows. Tests: slot classification boundaries; CO₂ rules; windows never outside school hours.

---

## 19. TinyML spike detector (edge)

### 19.1 Purpose

"A tiny model flags sudden spikes and publishes an event immediately on a priority topic" (§10.5); §8.2 "PM2.5 jumping 3× in 20 s". The model is a false-positive filter on top of the contract rule (PM2.5 ≥ 3 × rolling 5-min baseline within 20 s, CONTRACTS §10.3), so every published spike also satisfies the rule the ingest double-check applies.

### 19.2 Inputs and outputs

In (on device): 1 Hz PM2.5 from PMS5003 active mode, 5-min EWMA baseline, RH and its 20 s change, GPS speed, IMU acceleration magnitude. Out: `DeviceEventPacket` `type: spike` with `spike {pollutant, baseline, peak, ratio, window_s: 20, model: "tinyml-spike@x.y.z"}`.

### 19.3 Method

Input vector: last 20 s of `pm_t/baseline` (20 values) + scalars (`log baseline`, RH, ΔRH, speed, accel). Model: `Conv1D(8, k=5) → ReLU → Conv1D(8, k=3) → ReLU → GlobalAveragePooling → concat(scalars) → Dense(8, ReLU) → Dense(1, sigmoid)`, ~1–2k parameters. Fire when the rule holds **and** `p ≥ 0.5`. Training data: simulator traces with injected plumes (burning, dust bursts) and negatives — own-exhaust while idling (CO co-rise, stationary), fog onset (PM and RH rise together), road bumps (IMU), single-sample glitches — plus traces from the one real pod. Export: full-integer int8 via the TFLite converter with a representative dataset; ops limited to those TFLite Micro supports (CONV_2D, RESHAPE, MEAN, FULLY_CONNECTED, CONCATENATION, LOGISTIC); `gen_c_array.py` emits the header for ESP-IDF.

### 19.4 Validation · Budget · Cut · Tests

Held-out simulator + real traces: precision ≥ 0.9, recall ≥ 0.85 relative to true spikes; ≤ 1 false spike per device-day; int8 vs float agreement ≥ 98 %. Budget: model ≤ 20 KB flash, tensor arena ≤ 16 KB, inference ≤ 5 ms on the ESP32-S3 at 240 MHz. Cut: rule-only in firmware and simulator for the demo; the model is post-demo. Tests: rule consistency (model can only suppress); quantised model agreement; header generation round-trip.

---

## 20. Citizen Eyes photo verification (F20)

### 20.1 Purpose

"WhatsApp photo of burning → multimodal model checks it → matched to a sensor spike → inspection dispatched → reporter told the outcome" (§6 F20, Flow D). Also raises the confidence of the §8.2 spike attribution.

### 20.2 Inputs and outputs

In: `report.submitted {report_id}`; `citizen_report` (`photo_s3`, geom, submitted time, caption, channel); `device_event` spikes and `ml:feat:spikes:*`; `hotspot`; `fire_point`. Out: `citizen_report` verification fields (P-09: `verification` JSONB, `verification_conf`, `matched_spike_event_id`, `match_distance_m`, `needs_human_review`, `verification_model_version`); `report.verified` / `report.rejected`; hotspot cause update + `hotspot.updated`.

### 20.3 Method

1. **Preprocess** (`vision/preprocess.py`): JPEG/PNG (HEIC converted), ≤ 10 MB; read EXIF `DateTimeOriginal` and GPS, then strip all EXIF; resize to long edge ≤ 1568 px; perceptual hash vs the last 7 days of reports within 2 km (Hamming ≤ 6 → duplicate).
2. **Consistency**: capture time within 2 h before submission (unknown when EXIF is absent, e.g. WhatsApp, which is not a failure); submission location inside the NCR bbox; EXIF GPS (if present) within 500 m of the submitted location.
3. **Vision model**: Claude Opus 5 on Bedrock via the Citizen Eyes agent ([AGENTS §5.5](AGENTS.md#55-citizen-eyes-verifier)) returns `PhotoVerification` (`scene`, `smoke_visible`, `flames_visible`, `dust_visible`, `confidence`, `visible_evidence`, `image_quality`, `people_identifiable`, `plates_readable`, `notes`). Input is the image plus coarse context (ward, local time) only.
4. **Spike match**: candidates within 1 km and ±60 min — `device.spike` events and cells with `P(burning) ≥ 0.4`; `match = max exp(−d/500 m)·exp(−|Δt|/30 min)`.
5. **Decision** (`vision/decide.py`):
   - `verified` if scene ∈ {open_burning, waste_burning, dust_construction, dust_road, vehicle_smoke} with `confidence ≥ 0.6`, consistency passes and not a duplicate; `evidence_level = high` if also `match ≥ 0.3`.
   - `rejected` if scene ∈ {no_pollution_visible, not_outdoor_scene} with `confidence ≥ 0.7`, or image unusable, or duplicate.
   - otherwise `needs_human_review` (report stays `verifying`, officer queue).
   - Cause mapping: burning scenes → `burning`; dust scenes → `dust`; vehicle smoke → `traffic`; industrial smoke → `unknown` with a note.
6. **Hotspot update**: Bayesian update of the nearest hotspot's `cause_probs` with likelihood ratio `LR = 1 + 3·confidence·exp(−d/500 m)` for the photo's cause; recompute `cause_conf` (§8.2 "confidence rises to high").

Privacy: EXIF stripped before the model call; no identity, phone number or caption beyond 200 characters (caption treated as untrusted data); if `people_identifiable` or `plates_readable`, the backend blurs before any officer display; model text never describes people.

### 20.4 Validation · Fallback · Budget · Cut · Tests

Labelled set of ≥ 100 images (burning, dust, fog, unrelated, screenshots, duplicates): precision of `verified` ≥ 0.9, recall ≥ 0.7; zero verified screenshots. Fallback: model refusal/timeout → `needs_human_review` (never auto-verify without the photo check). Budget p95 20 s, hard 45 s. Cut (STRETCH, first in the §16 cut list with the school scheduler). Tests: EXIF stripped (no GPS tag survives); duplicate detection; decision table; prompt-injection text in a caption does not change the decision.

---

## 21. HawaEye smoky-vehicle detection (F8, VISION)

Architecture only. Raspberry Pi Zero 2 W + Camera Module 3 running a YOLO-class nano detector quantised to int8 on device (§10.4). Classes `smoky_vehicle`, `vehicle`; a detection is flagged when ≥ 5 of 10 consecutive frames agree, with hard negatives for shadows and wet roads ("the hard part is telling smoke from shadows and wet roads", §4.1). Only short evidence clips (≤ 10 s) for flagged events are uploaded (`ClipPacket` + presigned S3 PUT), never continuous video; faces blurred on device; clips go to an authorised officer review queue, retained briefly, nothing published (§10.4, §12.4, §15). Target operating point precision ≥ 0.9 to limit reviewer load. Outputs would feed the `traffic` cause evidence and inspection targets.

---

## 22. Evidence report narrative (F22)

### 22.1 Purpose

"Weekly auto-generated PDF: hotspots, sources, actions, measured impact per rupee, and recommended reallocation" (§6 F22). AI-ML supplies the narrative; backend renders the PDF (CONTRACTS §8, P-04).

### 22.2 Method

1. `reports/facts.py` builds a structured facts JSON for the week and wards: hotspot counts by cause, top hotspots, interventions and litres, verified impacts (effect, CI, verdict, evidence level), cost per intervention (`cost_paise` from asset configuration), **impact per rupee** from verified impacts only (simulated and model-based numbers labelled), What-If totals (labelled model-based), integrity flags, and a deterministic reallocation rule (move hours from strata with repeated `no_detectable_effect` to strata with `effective` results).
2. The narrator agent (Opus 5) writes sections (summary, sources, actions, measured impact, reallocation) from the facts only.
3. `reports/number_check.py` verifies every number in the text exists in the facts (rounding tolerance); on failure regenerate once, then fall back to the template narrative.
4. Output `narrative.json {sections [{title, body_md}], facts_hash, model_version}` to S3; `evidence_report.narrative_ready` (P-04).

Cut: template narrative (VISION → STRETCH). Tests: number checker catches an injected fabricated number; template path always renders.

---

## 23. Summary: versions, budgets, fallbacks

| Component | Version name | Runs in | p95 budget | Fallback | Tier |
|---|---|---|---|---|---|
| Calibration | `calibration` | intel-trainer | < 30 s nightly | fleet prior / keep current | BUILD |
| Twin | `twin` | intel-twin | 45 s | no advection → OK → IDW → carry forward | BUILD |
| Hotspots | `hotspots` | intel-twin | < 1 s | rank by AQI × confidence | BUILD |
| Fingerprint | `fingerprint-rules` / `fingerprint` | intel-twin, intel-spike | < 1 s | rules | BUILD |
| Back-trajectory | `trajectory` | intel-twin | < 0.2 s | nearest candidate | BUILD |
| Forecaster | `forecaster` | intel-forecast | 90 s (run) | no-NWP → baseline blend | BUILD |
| GRAP outlook | `grap` | intel-forecast | < 2 s | last outlook (stale) | BUILD |
| Exposure | `exposure` | all | < 1 s | residential only | BUILD |
| Optimiser | `optimizer` | intel-plan, intel-service | 2–8 s | greedy → protect-only | BUILD |
| What-If | `whatif` | intel-plan, intel-service | < 3 s | P50-only | BUILD (never drop) |
| Verifier | `verifier` | intel-verify | 10 s | DiD → naive (low evidence) | BUILD (never drop) |
| Effectiveness library | `effectiveness` | intel-verify, trainer | ms | priors | BUILD |
| Anti-gaming | `integrity` | intel-twin, trainer | s | ratio only | STRETCH |
| Coverage router | `coverage` | intel-twin | < 2 s | VOI list | STRETCH |
| Site score | `site_score` | trainer | s | carry forward | STRETCH |
| Safe windows | `safe_window` | intel-forecast | < 1 s | forecast-only | STRETCH |
| Citizen Eyes | `citizen_eyes` | intel-vision | 20 s | human review | STRETCH |
| Evidence narrative | `narrator` | intel-report | 60 s | template | STRETCH |
| TinyML spike | `tinyml-spike` | device | 5 ms | rule only | edge |
| Power-proxy, HawaEye | — | — | — | — | VISION |

<!-- footer:start -->

---

[Back to top](#ai-ml-models-and-algorithms) · [Docs hub](../README.md) · [Project README](../../README.md)

<!-- footer:end -->
