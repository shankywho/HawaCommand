"""Evening Master Plan Pipeline (Executed daily at 17:00).

Synthesizes the past 24 hours of data, evaluates next-morning school exposure,
and drafts the master dispatch schedule for early morning fleet deployment (06:00 - 10:00).
"""
from datetime import datetime, timezone
from typing import Dict
from hawa_ml.logging_conf import configure_logging
from hawa_ml.pipelines.cycle import run_3hour_cycle
from hawa_ml.agents.communicator_agent import communicator_agent

logger = configure_logging("master_plan")


def run_evening_master_plan() -> Dict[str, any]:
    logger.info("=== Running 17:00 Evening Master Planning Cycle for Next Morning ===")
    cycle_out = run_3hour_cycle()

    top_spot = cycle_out.get("top_hotspot", {})
    cell_id = top_spot.get("cell_id", "G-052-054")
    pm25 = top_spot.get("pm25", 260.0)

    # Issue school alerts for 7 PM delivery to principals
    school_alert = communicator_agent.draft_school_alert(
        school_name="Central Delhi Public School Cluster",
        cell_id=cell_id,
        peak_pm25=pm25,
        peak_time_str="8:00 AM Tomorrow",
        safe_window_str="1:00 PM to 3:30 PM",
    )
    logger.info(f"Drafted next-morning school alert:\n{school_alert['english']}")

    return {
        "master_plan_id": f"MASTER-{datetime.now(timezone.utc).strftime('%Y%m%d')}",
        "cycle_results": cycle_out,
        "school_alert": school_alert,
    }


if __name__ == "__main__":
    run_evening_master_plan()
