"""Fast greedy vehicle and team routing optimizer for pollution dispatch (F13).

Allocates available anti-pollution machines (sprinklers, smog guns, sweepers)
and inspection teams to hotspots matching their cause-specific action capabilities.
Maximizes total person-hours of exposure avoided.
Runs in milliseconds.
"""
from datetime import datetime, timezone, timedelta
from typing import Dict, List, Optional, Tuple
import numpy as np

from hawa_ml.settings import settings
from hawa_ml.logging_conf import configure_logging
from hawa_ml.schemas import Hotspot, AssetSpec, PlanTask, SourceClass
from hawa_ml.causal.effectiveness_library import effectiveness_library
from hawa_ml.geo import haversine_distance_m

logger = configure_logging("optimizer_greedy")

# Compatibility matrix: which asset types can address which causes
ASSET_CAUSE_COMPATIBILITY = {
    "sprinkler": [SourceClass.ROAD_DUST.value, SourceClass.UNKNOWN.value],
    "smog_gun": [SourceClass.ROAD_DUST.value, SourceClass.UNKNOWN.value],
    "sweeper": [SourceClass.ROAD_DUST.value, SourceClass.UNKNOWN.value],
    "inspection_team": [SourceClass.OPEN_BURNING.value, SourceClass.INDUSTRIAL.value, SourceClass.TRAFFIC.value],
}


class GreedyDispatchOptimizer:
    def __init__(self, speed_kmh: float = 22.0, spray_duration_min: int = 60):
        self.speed_kmh = speed_kmh
        self.spray_duration_min = spray_duration_min

    def solve(
        self,
        hotspots: List[Hotspot],
        assets: List[AssetSpec],
        shift_hours: float = 4.0,
        start_time: Optional[datetime] = None,
    ) -> Tuple[List[PlanTask], float]:
        """Greedily allocate assets to hotspots to maximize person-hours of exposure avoided."""
        if start_time is None:
            start_time = datetime.now(timezone.utc)

        tasks: List[PlanTask] = []
        total_avoided_ph = 0.0

        # Track asset state: current location and time remaining in shift
        asset_state = {
            a.id: {
                "spec": a,
                "curr_lat": a.depot_lat,
                "curr_lon": a.depot_lon,
                "remaining_minutes": shift_hours * 60.0,
                "curr_time": start_time,
                "water_remaining": a.capacity_litres,
            }
            for a in assets
        }

        # Value hotspots by potential exposure avoided = exposure_score * (expected_effect_pct / 100)
        unvisited_hotspots = []
        for h in hotspots:
            eff_rec = effectiveness_library.lookup_expected_effect(h.cause.value, h.recommended_asset)
            pot_reduction = eff_rec.pm10_reduction_pct if h.cause == SourceClass.ROAD_DUST else eff_rec.pm25_reduction_pct
            potential_value = h.exposure_score * (pot_reduction / 100.0)
            unvisited_hotspots.append({
                "hotspot": h,
                "potential_value": potential_value,
                "expected_reduction_pct": pot_reduction,
                "assigned": False,
            })

        # Sort hotspots by potential exposure reduction descending
        unvisited_hotspots.sort(key=lambda x: x["potential_value"], reverse=True)

        task_counter = 1
        for item in unvisited_hotspots:
            h = item["hotspot"]
            cause_val = h.cause.value

            # Skip regional smoke or traffic where mobile water assets are ineffective
            if h.cause in [SourceClass.REGIONAL_SMOKE, SourceClass.TRAFFIC]:
                continue

            # Find best candidate asset
            best_asset_id = None
            min_travel_min = 99999.0

            for a_id, st in asset_state.items():
                spec = st["spec"]
                # Check compatibility
                compatible_causes = ASSET_CAUSE_COMPATIBILITY.get(spec.type, [])
                if cause_val not in compatible_causes:
                    continue

                # Check if asset has sufficient shift time
                if st["remaining_minutes"] < (self.spray_duration_min + 15):
                    continue

                # Calculate travel time from asset's current location
                pin_lat = h.suspect_pin.lat if h.suspect_pin else 28.6139
                pin_lon = h.suspect_pin.lon if h.suspect_pin else 77.2090
                dist_m = haversine_distance_m(st["curr_lat"], st["curr_lon"], pin_lat, pin_lon)
                travel_min = (dist_m / 1000.0 / self.speed_kmh) * 60.0

                if travel_min + self.spray_duration_min <= st["remaining_minutes"]:
                    if travel_min < min_travel_min:
                        min_travel_min = travel_min
                        best_asset_id = a_id

            if best_asset_id is not None:
                st = asset_state[best_asset_id]
                eta_start = st["curr_time"] + timedelta(minutes=min_travel_min)
                eta_end = eta_start + timedelta(minutes=self.spray_duration_min)

                pin_lat = h.suspect_pin.lat if h.suspect_pin else 28.6139
                pin_lon = h.suspect_pin.lon if h.suspect_pin else 77.2090

                task = PlanTask(
                    task_id=f"TASK-{task_counter:03d}",
                    asset_id=best_asset_id,
                    cell_id=h.cell_id,
                    action=f"suppress_{cause_val}",
                    eta_start=eta_start,
                    eta_end=eta_end,
                    expected_pm_reduction_pct=round(item["expected_reduction_pct"], 1),
                    reason=(
                        f"Cause is {cause_val} (conf {h.cause_confidence*100:.0f}%). "
                        f"Targeting {item['potential_value']:.0f} person-hours exposure reduction."
                    ),
                )
                tasks.append(task)
                total_avoided_ph += item["potential_value"]
                task_counter += 1

                # Update asset state
                st["remaining_minutes"] -= (min_travel_min + self.spray_duration_min)
                st["curr_time"] = eta_end
                st["curr_lat"] = pin_lat
                st["curr_lon"] = pin_lon
                item["assigned"] = True

        logger.info(f"Greedy optimization complete: assigned {len(tasks)} tasks avoiding {total_avoided_ph:.1f} person-hrs.")
        return tasks, round(total_avoided_ph, 1)


# Global instance
greedy_optimizer = GreedyDispatchOptimizer()
