"""CLI to run HawaCommand operational cycle once or on a recurring schedule.

Usage:
  python scripts/run_cycle.py --once
  python scripts/run_cycle.py --loop --interval-sec 10800
"""
import argparse
import sys
import time
from pathlib import Path

# Add src to sys.path
BASE_DIR = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(BASE_DIR / "src"))

from hawa_ml.pipelines.cycle import run_3hour_cycle
from hawa_ml.logging_conf import configure_logging

logger = configure_logging("run_cycle_cli")


def main():
    parser = argparse.ArgumentParser(description="HawaCommand Operational Cycle CLI")
    parser.add_argument("--once", action="store_true", default=True, help="Run single cycle and exit")
    parser.add_argument("--loop", action="store_true", help="Run continuously on recurring interval")
    parser.add_argument("--interval-sec", type=int, default=10800, help="Interval in seconds (default 3h = 10800s)")
    args = parser.parse_args()

    if args.loop:
        logger.info(f"Starting HawaCommand cycle daemon with interval {args.interval_sec}s...")
        while True:
            try:
                run_3hour_cycle()
            except Exception as e:
                logger.error(f"Error in cycle run: {e}")
            logger.info(f"Sleeping for {args.interval_sec} seconds until next scheduled cycle...")
            time.sleep(args.interval_sec)
    else:
        logger.info("Executing single HawaCommand 3-hour operational cycle...")
        res = run_3hour_cycle()
        print(f"Cycle finished. Plan ID: {res['plan']['plan_id']} | Avoided Person-Hours: {res['plan']['total_exposure_avoided_person_hours']}")


if __name__ == "__main__":
    main()
