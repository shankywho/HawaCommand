# Model Card: HawaCommand Source Attribution Classifier (F7)

<!-- nav:start -->

**Navigate:** [Project](../../README.md) · [Docs hub](../../docs/README.md) · [Overview](../../docs/SYSTEM_OVERVIEW.md) · [AWS architecture](../../docs/AWS_ARCHITECTURE.md) · [AWS guide](../../docs/AWS_SETUP_GUIDE.md) · [API](../../docs/backend/API.md) · [Environment](../../docs/ENVIRONMENT_VARIABLES.md) · [Contracts](../../docs/CONTRACTS.md)

<!-- nav:end -->

> Status: Partial. The committed artifact `models/attribution_classifier.txt` is trained and loadable, but no runtime path uses it: hotspots, the optimiser and the API all use the rule engine in `src/hawa_ml/attribution/rules.py`. Note: `scripts/train_all.py` regenerates this file from a template in `src/hawa_ml/attribution/classifier.py` (`_write_model_card`), which overwrites these notes.

## Honest methodological disclosure
- **Labels are weak proxies.** Delhi CAAQMS stations do not record source origin. `generate_weak_proxy_labels()` assigns labels with fixed rules, applied in this order (later rules overwrite earlier ones):
  1. `regional_smoke`: PM2.5/PM10 > 0.72, month in October-December, PM2.5 > 220.
  2. `road_dust`: ratio < 0.45, hour 8-18, PM10 > 240.
  3. `traffic`: hour 8-11 or 17-21, NO2 > 45, ratio 0.42-0.68.
  4. `open_burning`: hour ≥ 21 or ≤ 6, ratio > 0.68, PM2.5 > 180.
  5. `industrial`: SO2 > 25 and still unlabelled.
  6. Everything else: `road_dust`.
- The classifier therefore learns to reproduce these rules from the same columns. High accuracy against these labels measures rule recovery, not real-world attribution accuracy.
- NO2 and SO2 in the CPCB data are µg/m³; the thresholds are applied to them as given.

## Model
- **Architecture:** LightGBM multiclass (`LGBMClassifier`, `objective="multiclass"`, `num_class=5`), `n_estimators=60` (300 trees), `max_depth=5`, `learning_rate=0.08`, `random_state=42`.
- **Classes (index order):** 0 road_dust, 1 traffic, 2 open_burning, 3 regional_smoke, 4 industrial.
- **Features (11, in order):** pm25, pm10, ratio_pm25_pm10, no2, co, so2, hour, month, temperature, humidity, wind_speed. Missing values are filled with column medians before training.
- **Training data:** all rows of `data/processed/stations_hourly.parquet` (no hold-out during training).
- **Inference API:** `AttributionClassifier.predict_source(pm25, pm10, no2=35, co=1.2, so2=10, hour=12, month=11, temp=20, rh=65, ws=2.5)` returns `(SourceClass, confidence, {class: probability})`. Without the booster file it returns a fixed probability vector chosen by the PM2.5/PM10 ratio (< 0.45, > 0.70, otherwise).

## Evaluation
- `scripts/eval_metrics.py` scores the booster on the last 20 % of rows by time against the weak labels. Because the booster was trained on all rows, this is in-sample. The 99.91 % weighted precision/recall/F1 on 28,071 rows once quoted in an evaluation PDF (removed from the repository) came from this procedure; no metrics file is written.
- There is no comparison against ground-truth source labels, inspections or citizen reports.

## Recommended downstream action mapping
These mappings are what the rule engine and greedy optimiser implement, not the classifier:
- `road_dust`: `sprinkler` (rules); sprinklers, smog guns and sweepers are compatible in the optimiser.
- `traffic`: `traffic_advisory`; the optimiser skips traffic hotspots.
- `open_burning`: `inspection_team` (never water on smoke; also enforced by the Auditor agent).
- `regional_smoke`: `protect_people`; the optimiser skips these hotspots.
- `industrial`: `industrial_inspection`; the optimiser allows `inspection_team`.

## Limitations
- Not wired into any decision path.
- Labels encode the same thresholds as the rules, with small differences (for example the rules use a 0.45 dust ratio from `config/fingerprint_rules.yaml` and an upwind-fire requirement for regional smoke that the labels omit).
- No probability calibration, no `mixed` or `unknown` class.

<!-- footer:start -->

---

**Related across the project:** [Source attribution](../../docs/aiml/MODELS.md#2-source-attribution) · [Training](../../docs/aiml/DATA_AND_TRAINING.md#training) · [Map page](../../docs/frontend/PAGES.md#map-live-hotspot-map)

[Back to top](#model-card-hawacommand-source-attribution-classifier-f7) · [Docs hub](../../docs/README.md) · [Project README](../../README.md)

<!-- footer:end -->
