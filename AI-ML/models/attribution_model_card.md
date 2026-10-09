# Model Card: HawaCommand Source Attribution Classifier (F7)

## Honest Methodological Disclosure
- **Labels are Weak Proxies:** Delhi CAAQMS reference stations do not record ground-truth source origins. Training labels are generated using physical multi-pollutant co-signals (PM2.5/PM10 ratio, NO2 traffic peaks, night VOC burning signals, and winter NW wind stubble spikes).
- **Architecture:** Multi-class LightGBM (5 classes: road_dust, traffic, open_burning, regional_smoke, industrial).
- **Features (11):** pm25, pm10, ratio_pm25_pm10, no2, co, so2, hour, month, temperature, humidity, wind_speed.

## Recommended Downstream Action Mapping
- `road_dust`: Water sprinkler / mechanized road sweeper.
- `traffic`: Traffic advisory & smoky vehicle inspection.
- `open_burning`: Enforcement inspection team (no water sprinklers on smoke).
- `regional_smoke`: Citizen protection advisory & N95 masking.
- `industrial`: Industrial compliance audit.
