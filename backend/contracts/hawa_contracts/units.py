"""Units, thresholds, CPCB AQI breakpoints, and GRAP stage calculations (§10)."""
from typing import Optional
from .enums import AqiCategory, GrapStage

# Exposure safety baseline (NAAQS 24-hour standard: 60 ug/m3)
C_SAFE_PM25 = 60.0
C_SAFE_PM10 = 100.0


def pm25_to_category(pm25: float) -> AqiCategory:
    """Classify PM2.5 concentration (ug/m3) into a CPCB AQI category."""
    if pm25 <= 30.0:
        return AqiCategory.GOOD
    elif pm25 <= 60.0:
        return AqiCategory.SATISFACTORY
    elif pm25 <= 90.0:
        return AqiCategory.MODERATE
    elif pm25 <= 120.0:
        return AqiCategory.POOR
    elif pm25 <= 250.0:
        return AqiCategory.VERY_POOR
    else:
        return AqiCategory.SEVERE


def pm10_to_category(pm10: float) -> AqiCategory:
    """Classify PM10 concentration (ug/m3) into a CPCB AQI category."""
    if pm10 <= 50.0:
        return AqiCategory.GOOD
    elif pm10 <= 100.0:
        return AqiCategory.SATISFACTORY
    elif pm10 <= 250.0:
        return AqiCategory.MODERATE
    elif pm10 <= 350.0:
        return AqiCategory.POOR
    elif pm10 <= 430.0:
        return AqiCategory.VERY_POOR
    else:
        return AqiCategory.SEVERE


def _calc_sub_index(conc: float, b_lo: float, b_hi: float, i_lo: float, i_hi: float) -> float:
    return ((i_hi - i_lo) / (b_hi - b_lo)) * (conc - b_lo) + i_lo


def pm25_to_sub_index(pm25: float) -> int:
    """Convert PM2.5 concentration to sub-index per Central Pollution Control Board."""
    val = max(0.0, pm25)
    if val <= 30:
        idx = _calc_sub_index(val, 0, 30, 0, 50)
    elif val <= 60:
        idx = _calc_sub_index(val, 30, 60, 51, 100)
    elif val <= 90:
        idx = _calc_sub_index(val, 60, 90, 101, 200)
    elif val <= 120:
        idx = _calc_sub_index(val, 90, 120, 201, 300)
    elif val <= 250:
        idx = _calc_sub_index(val, 120, 250, 301, 400)
    else:
        idx = _calc_sub_index(val, 250, 380, 401, 500)
    return round(idx)


def pm10_to_sub_index(pm10: float) -> int:
    """Convert PM10 concentration to sub-index per CPCB."""
    val = max(0.0, pm10)
    if val <= 50:
        idx = _calc_sub_index(val, 0, 50, 0, 50)
    elif val <= 100:
        idx = _calc_sub_index(val, 50, 100, 51, 100)
    elif val <= 250:
        idx = _calc_sub_index(val, 100, 250, 101, 200)
    elif val <= 350:
        idx = _calc_sub_index(val, 250, 350, 201, 300)
    elif val <= 430:
        idx = _calc_sub_index(val, 350, 430, 301, 400)
    else:
        idx = _calc_sub_index(val, 430, 510, 401, 500)
    return round(idx)


def calculate_indicative_aqi(pm25: float, pm10: Optional[float] = None) -> int:
    """Calculate indicative AQI (max sub-index among available pollutants)."""
    sub_indices = [pm25_to_sub_index(pm25)]
    if pm10 is not None:
        sub_indices.append(pm10_to_sub_index(pm10))
    return max(sub_indices)


def aqi_to_grap_stage(aqi: int) -> GrapStage:
    """Map AQI value to Graded Response Action Plan (GRAP) stage."""
    if aqi <= 200:
        return GrapStage.STAGE_0
    elif aqi <= 300:
        return GrapStage.STAGE_1   # Poor
    elif aqi <= 400:
        return GrapStage.STAGE_2   # Very Poor
    elif aqi <= 450:
        return GrapStage.STAGE_3   # Severe
    else:
        return GrapStage.STAGE_4   # Severe+ (Emergency)
