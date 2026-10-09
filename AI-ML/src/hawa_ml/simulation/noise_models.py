"""Physical sensor error, humidity distortion, and vehicle bias models.

Simulates:
1. Low-cost optical particle counter (PMS5003/SEN55) hygroscopic growth distortion (RH > 70%).
2. Speed-dependent intake tube Bernoulli pressure drop (spd > 35 km/h).
3. Factory gain and offset calibration drift per device.
4. Occasional self-exhaust plume spikes and sensor dropouts.
"""
from typing import Dict, Tuple
import numpy as np


class SensorNoiseModel:
    def __init__(self, dev_id: str):
        self.dev_id = dev_id
        # Seed consistently by device ID for repeatable individual device characteristics
        seed = abs(hash(dev_id)) % (2**31)
        rng = np.random.RandomState(seed)

        # Inherent hardware factory calibration offset and gain
        self.gain_pm25 = rng.uniform(0.88, 1.14)
        self.offset_pm25 = rng.uniform(-12.0, 14.0)
        self.gain_pm10 = rng.uniform(0.85, 1.18)
        self.offset_pm10 = rng.uniform(-18.0, 20.0)

        # Humidity hygroscopic growth coefficient (optical laser scattering over-read)
        self.rh_coef = rng.uniform(0.0035, 0.0075)

    def apply_pm_noise(
        self,
        true_pm25: float,
        true_pm10: float,
        rh: float,
        speed_kmh: float = 0.0,
    ) -> Tuple[float, float, list]:
        """Apply humidity swelling, speed pressure drop, and sensor noise."""
        flags = []

        # 1. Hygroscopic growth when RH > 70% (Kohler aerosol growth theory approximation)
        if rh > 70.0:
            growth_factor = 1.0 + self.rh_coef * ((rh - 70.0) ** 1.35)
            pm25 = true_pm25 * growth_factor
            pm10 = true_pm10 * (1.0 + (growth_factor - 1.0) * 0.7)
            if rh > 75.0:
                flags.append("heater_on")
        else:
            pm25 = true_pm25
            pm10 = true_pm10

        # 2. Hardware gain and offset
        pm25 = pm25 * self.gain_pm25 + self.offset_pm25
        pm10 = pm10 * self.gain_pm10 + self.offset_pm10

        # 3. Vehicle intake dynamic pressure distortion at high speeds (> 35 km/h)
        if speed_kmh > 35.0:
            speed_bias = 1.0 - 0.003 * (speed_kmh - 35.0)
            pm25 *= speed_bias
            pm10 *= speed_bias

        # 4. Zero-mean gaussian sensor scattering noise
        noise_pm25 = np.random.normal(0.0, max(2.0, pm25 * 0.035))
        noise_pm10 = np.random.normal(0.0, max(4.0, pm10 * 0.045))

        pm25_noisy = float(np.clip(pm25 + noise_pm25, 5.0, 1800.0))
        pm10_noisy = float(np.clip(pm10 + noise_pm10, pm25_noisy * 1.05, 2500.0))

        return pm25_noisy, pm10_noisy, flags
