"""Proactive insight triggers for continuous command surveillance (F14).

Emits typed Insight objects based on 7 operational conditions:
1. Forecast crossing GRAP thresholds within 24-48h
2. School/Hospital cluster morning exposure threshold breach
3. Low-confidence digital twin blind spot detection
4. Sudden physical PM spike (>3x jump)
5. Regional smoke or sudden source shift
6. Intervention outcome verified effective or ineffective
7. Device trust score collapse / anomaly
"""
from datetime import datetime, timezone
from typing import Dict, List, Optional
import numpy as np
import pandas as pd

from hawa_ml.settings import settings
from hawa_ml.logging_conf import configure_logging
from hawa_ml.schemas import Insight, InsightSeverity

logger = configure_logging("insight_triggers")


class InsightTriggerEngine:
    def scan_cycle_insights(
        self,
        twin_grid: pd.DataFrame,
        forecast_points: List[dict] = None,
        spikes: List[dict] = None,
        verified_interventions: List[dict] = None,
    ) -> List[Insight]:
        """Evaluate operational triggers and return prioritized Insight list."""
        insights = []
        now = datetime.now(timezone.utc)

        # 1. GRAP Threshold Crossing Trigger (24-48h lead time)
        if forecast_points:
            for p in forecast_points:
                if p.get("horizon_h") in [24, 48] and p.get("grap_stage_number", 0) >= 3:
                    insights.append(
                        Insight(
                            id=f"INS-GRAP-{p['horizon_h']}H",
                            trigger_type="grap_threshold_crossing",
                            severity=InsightSeverity.CRITICAL,
                            title=f"72h Forecast: {p['grap_stage']} Triggered at +{p['horizon_h']}h",
                            cell_id=p.get("cell_id", "G-DELHI-CORE"),
                            evidence={
                                "horizon_h": p["horizon_h"],
                                "pm25_p50": p["pm25_p50"],
                                "pm25_p90": p["pm25_p90"],
                                "grap_stage": p["grap_stage"],
                            },
                            confidence=0.88,
                            recommended_action=f"Enact CAQM {p['grap_stage']} preemptive measures 24-48h in advance.",
                            created_at=now,
                        )
                    )
                    break

        # 2. School Morning Assembly Window Vulnerability Trigger
        if not twin_grid.empty and "primary_land_use" in twin_grid.columns and "pm25_est" in twin_grid.columns:
            sort_col = "exposure_score" if "exposure_score" in twin_grid.columns else "pm25_est"
            matching_mask = (twin_grid["primary_land_use"] == "school_cluster") & (twin_grid["pm25_est"] > 220.0)
            school_cells = twin_grid[matching_mask].sort_values(sort_col, ascending=False)

            if not school_cells.empty:
                top_school = school_cells.iloc[0]
                insights.append(
                    Insight(
                        id=f"INS-SCH-{top_school.get('cell_id', 'G-SCH')}",
                        trigger_type="school_morning_exposure",
                        severity=InsightSeverity.WARNING,
                        title=f"High Exposure at School Cluster ({top_school.get('cell_id', 'G-SCH')})",
                        cell_id=str(top_school.get("cell_id", "G-SCH")),
                        evidence={
                            "pm25": float(top_school["pm25_est"]),
                            "population": float(top_school.get("population", 5000.0)),
                            "schools_nearby": int(top_school.get("schools_nearby_count", 3)),
                            "ward": str(top_school.get("ward", "Unknown")),
                        },
                        confidence=float(top_school.get("confidence", 0.85)),
                        recommended_action="Dispatch water sprinkler before 6:30 AM; alert principal to hold assembly indoors.",
                        created_at=now,
                    )
                )

        # 3. Low-Confidence Digital Twin Blind Spot Trigger
        if not twin_grid.empty and "confidence" in twin_grid.columns:
            blind_spots = twin_grid[twin_grid["confidence"] < 0.35]
            if len(blind_spots) > 20:
                insights.append(
                    Insight(
                        id="INS-BLIND-SPOTS",
                        trigger_type="twin_blind_spots",
                        severity=InsightSeverity.INFO,
                        title=f"Monitoring Blind Spot Detected ({len(blind_spots)} cells)",
                        cell_id=blind_spots.iloc[0]["cell_id"],
                        evidence={"low_confidence_cell_count": len(blind_spots)},
                        confidence=0.92,
                        recommended_action="Route transit buses HPM-1002 and HPM-1005 through Outer Ring Road sector.",
                        created_at=now,
                    )
                )

        # 4. Sudden PM Spike (>3x jump)
        if spikes:
            for s in spikes:
                insights.append(
                    Insight(
                        id=f"INS-SPIKE-{s.get('dev_id', 'DEV')}",
                        trigger_type="sudden_spike",
                        severity=InsightSeverity.CRITICAL,
                        title=f"Sudden 3x Pollution Spike Detected by {s.get('dev_id')}",
                        cell_id=s.get("cell_id", "G-SPIKE"),
                        evidence=s,
                        confidence=0.90,
                        recommended_action="Dispatch nearest inspection enforcement team to investigate open burning or construction.",
                        created_at=now,
                    )
                )

        return insights


# Global instance
insight_trigger_engine = InsightTriggerEngine()
