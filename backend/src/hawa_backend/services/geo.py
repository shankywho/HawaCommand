"""Point -> 500 m twin cell (cell id, ward, current PM2.5/PM10) and cell id -> centre, for reports and audits."""
import logging
from typing import Any, Dict, Optional, Tuple

from ..core.places import nearest_locality

logger = logging.getLogger("hawa_backend.geo")

# Delhi NCT bounding box (lat, lon) with a small margin; reports outside it are rejected.
DELHI_BBOX = (28.38, 76.80, 28.90, 77.37)


def in_delhi(lat: float, lon: float) -> bool:
    return DELHI_BBOX[0] <= lat <= DELHI_BBOX[2] and DELHI_BBOX[1] <= lon <= DELHI_BBOX[3]


def _twin_df():
    from ..core.intel_client import get_intel_client

    return get_intel_client()._get_live_twin_df()


def locate(lat: float, lon: float) -> Dict[str, Any]:
    """Nearest twin cell to the point. Falls back to just the locality name when the twin is unavailable."""
    out: Dict[str, Any] = {"place": nearest_locality(lon, lat)}
    try:
        df = _twin_df()
        d2 = (df["latitude"] - lat) ** 2 + (df["longitude"] - lon) ** 2
        row = df.loc[d2.idxmin()]
        out.update({
            "cell_id": str(row["cell_id"]),
            "ward_id": str(row["ward"]) if "ward" in row else None,
            "pm25": round(float(row["pm25_est"]), 1) if "pm25_est" in row else None,
            "pm10": round(float(row["pm10_est"]), 1) if "pm10_est" in row else None,
        })
    except Exception as exc:
        logger.warning("twin lookup failed for (%s, %s): %s", lat, lon, exc)
    return out


def cell_center(cell_id: str) -> Optional[Tuple[float, float]]:
    """(lat, lon) of a twin cell id, or None."""
    try:
        df = _twin_df()
        hit = df[df["cell_id"] == cell_id]
        if hit.empty:
            return None
        row = hit.iloc[0]
        return float(row["latitude"]), float(row["longitude"])
    except Exception as exc:
        logger.warning("cell lookup failed for %s: %s", cell_id, exc)
        return None


# AI-ML SourceClass -> app CauseLabel (dust, traffic, burning, regional_smoke, mixed, unknown)
CAUSE_LABEL = {
    "road_dust": "dust",
    "dust": "dust",
    "traffic": "traffic",
    "open_burning": "burning",
    "burning": "burning",
    "regional_smoke": "regional_smoke",
    "industrial": "mixed",
    "mixed": "mixed",
}


def attribute(pm25: Optional[float], pm10: Optional[float], hour: int) -> Tuple[str, float]:
    """Rule-based source attribution for a cell (AI-ML config/fingerprint_rules.yaml): (CauseLabel, confidence)."""
    if pm25 is None:
        return "unknown", 0.3
    try:
        from hawa_ml.attribution.rules import rule_attribution

        source, conf, _ = rule_attribution.classify_source(pm25=pm25, pm10=pm10 or pm25 * 1.6, hour=hour)
        value = source.value if hasattr(source, "value") else str(source)
        return CAUSE_LABEL.get(value, "unknown"), round(float(conf), 2)
    except Exception as exc:
        logger.warning("attribution failed: %s", exc)
        return "unknown", 0.3
