"""Device Fleet Simulator for HawaPod-M, HawaPod-S, and HawaTag nodes.

Simulates:
- HawaPod-M: Mobile pods riding DTC buses on real OSM trajectories with speed and humidity bias.
- HawaPod-S: Stationary school sentinel pairs (indoor/outdoor).
- HawaTag: Sprinklers and anti-smog guns reporting water flow, pump current, and PM before/after.

Emits exact Proposal §10.6 packets to JSONL file or MQTT broker.
"""
import argparse
import json
import sys
import time
from datetime import datetime, timezone, timedelta
from pathlib import Path
from typing import Generator, List

import numpy as np

from hawa_ml.settings import settings
from hawa_ml.logging_conf import configure_logging
from hawa_ml.schemas import TelemetryPacket
from hawa_ml.simulation.packet import create_telemetry_packet
from hawa_ml.simulation.noise_models import SensorNoiseModel
from hawa_ml.simulation.interventions import InterventionManager
from hawa_ml.ingestion.bus_routes_osm import load_bus_routes

logger = configure_logging("device_sim")


class FleetSimulator:
    def __init__(self, n_buses: int = 12, n_schools: int = 4, n_sprinklers: int = 3):
        self.n_buses = n_buses
        self.routes = load_bus_routes()
        self.route_keys = list(self.routes.keys())
        self.noise_models = {}
        self.intervention_mgr = InterventionManager()

        # Initialize Bus States
        self.buses = []
        for i in range(n_buses):
            dev_id = f"HPM-{1000 + i}"
            r_name = self.route_keys[i % len(self.route_keys)]
            self.noise_models[dev_id] = SensorNoiseModel(dev_id)
            self.buses.append({
                "dev_id": dev_id,
                "route_name": r_name,
                "waypoints": self.routes[r_name],
                "curr_idx": int((i * 45) % len(self.routes[r_name])),
                "speed_kmh": float(np.random.uniform(18.0, 38.0)),
                "seq": 100,
            })

        # Initialize School Sentinels (Stationary)
        self.schools = [
            {"dev_id": "HPS-001-OUT", "lat": 28.6315, "lon": 77.2167, "name": "CP Model School"},
            {"dev_id": "HPS-002-OUT", "lat": 28.6740, "lon": 77.1310, "name": "Punjabi Bagh Public School"},
            {"dev_id": "HPS-003-OUT", "lat": 28.5710, "lon": 77.0719, "name": "Dwarka Vidya Mandir"},
            {"dev_id": "HPS-004-OUT", "lat": 28.6500, "lon": 77.3000, "name": "Anand Vihar High School"},
        ]
        for s in self.schools:
            self.noise_models[s["dev_id"]] = SensorNoiseModel(s["dev_id"])

        # Initialize HawaTag Intervention Sprinklers
        self.tags = [
            {"dev_id": "HTAG-01", "asset_id": "SPR-01", "lat": 28.6740, "lon": 77.1310, "spraying": True, "flow": 140.0, "current": 18.2},
            {"dev_id": "HTAG-02", "asset_id": "ASG-01", "lat": 28.6500, "lon": 77.3150, "spraying": False, "flow": 0.0, "current": 0.0},
        ]
        for t in self.tags:
            self.noise_models[t["dev_id"]] = SensorNoiseModel(t["dev_id"])

    def step_simulation(self, current_time: datetime) -> List[TelemetryPacket]:
        """Advance all nodes by one time step (e.g. 30 seconds) and generate telemetry packets."""
        packets = []
        hour = current_time.hour
        # Base ambient ground truth diurnal curve
        base_pm25 = 180.0 + 65.0 * np.sin((hour - 8) * np.pi / 12)
        base_pm10 = base_pm25 * 1.65
        ambient_rh = 76.0 - 24.0 * np.sin((hour - 9) * np.pi / 12)
        ambient_temp = 18.0 + 8.0 * np.sin((hour - 9) * np.pi / 12)

        # 1. Simulate Mobile Pods (Buses)
        for bus in self.buses:
            dev_id = bus["dev_id"]
            pts = bus["waypoints"]
            bus["curr_idx"] = (bus["curr_idx"] + 1) % len(pts)
            lat, lon = pts[bus["curr_idx"]]
            spd = float(np.clip(bus["speed_kmh"] + np.random.normal(0, 3.0), 5.0, 55.0))
            bus["seq"] += 1

            # Check for active intervention attenuation
            att25, att10 = self.intervention_mgr.get_attenuation(lat, lon, current_time)
            true_pm25 = base_pm25 * att25
            true_pm10 = base_pm10 * att10

            # Apply sensor noise, humidity growth & speed distortion
            noisy_pm25, noisy_pm10, flags = self.noise_models[dev_id].apply_pm_noise(
                true_pm25, true_pm10, ambient_rh, spd
            )

            pkt = create_telemetry_packet(
                dev_id=dev_id,
                role="M",
                seq=bus["seq"],
                lat=lat,
                lon=lon,
                spd=spd,
                pm25=noisy_pm25,
                pm10=noisy_pm10,
                temp=ambient_temp,
                rh=ambient_rh,
                flags=flags,
                ts=current_time,
            )
            packets.append(pkt)

        # 2. Simulate School Sentinels
        for s in self.schools:
            dev_id = s["dev_id"]
            att25, att10 = self.intervention_mgr.get_attenuation(s["lat"], s["lon"], current_time)
            true_pm25 = base_pm25 * att25
            true_pm10 = base_pm10 * att10

            noisy_pm25, noisy_pm10, flags = self.noise_models[dev_id].apply_pm_noise(
                true_pm25, true_pm10, ambient_rh, speed_kmh=0.0
            )
            pkt = create_telemetry_packet(
                dev_id=dev_id,
                role="S",
                seq=int(time.time()) % 100000,
                lat=s["lat"],
                lon=s["lon"],
                spd=0.0,
                pm25=noisy_pm25,
                pm10=noisy_pm10,
                temp=ambient_temp,
                rh=ambient_rh,
                flags=flags,
                ts=current_time,
            )
            packets.append(pkt)

        # 3. Simulate HawaTag Interventions
        for t in self.tags:
            dev_id = t["dev_id"]
            noisy_pm25, noisy_pm10, flags = self.noise_models[dev_id].apply_pm_noise(
                base_pm25 * 0.82, base_pm10 * 0.78, ambient_rh, speed_kmh=12.0
            )
            pkt = create_telemetry_packet(
                dev_id=dev_id,
                role="TAG",
                seq=int(time.time()) % 100000,
                lat=t["lat"],
                lon=t["lon"],
                spd=12.0,
                pm25=noisy_pm25,
                pm10=noisy_pm10,
                temp=ambient_temp,
                rh=ambient_rh,
                flow_lpm=t["flow"],
                pump_current_a=t["current"],
                spraying=t["spraying"],
                flags=flags,
                ts=current_time,
            )
            packets.append(pkt)

        return packets

    def run_file_mode(self, out_path: Path, n_steps: int = 50) -> int:
        """Run simulation for N steps and write JSONL stream."""
        out_path.parent.mkdir(parents=True, exist_ok=True)
        total_packets = 0
        t0 = datetime.now(timezone.utc) - timedelta(minutes=n_steps * 0.5)

        logger.info(f"Generating {n_steps} simulation steps ({self.n_buses} buses) -> {out_path}...")
        with open(out_path, "w", encoding="utf-8") as f:
            for step in range(n_steps):
                cur_t = t0 + timedelta(seconds=step * 30)
                pkts = self.step_simulation(cur_t)
                for p in pkts:
                    f.write(p.model_dump_json() + "\n")
                    total_packets += 1

        logger.info(f"Simulation complete: wrote {total_packets} telemetry packets to {out_path}.")
        return total_packets


def main():
    parser = argparse.ArgumentParser(description="HawaCommand Device Fleet Simulator")
    parser.add_argument("--mode", choices=["file", "mqtt"], default="file")
    parser.add_argument("--steps", type=int, default=60, help="Number of 30-sec simulation steps")
    parser.add_argument("--out", type=str, default="data/interim/simulated_telemetry.jsonl")
    args = parser.parse_args()

    sim = FleetSimulator(n_buses=12, n_schools=4, n_sprinklers=2)
    out_file = settings.BASE_DIR / args.out

    if args.mode == "file":
        count = sim.run_file_mode(out_file, n_steps=args.steps)
        print(f"Generated {count} packets in {out_file}")
    else:
        logger.info("MQTT mode: Mock publishing to topic 'hawa/v1/{deviceId}/telemetry'...")
        sim.run_file_mode(out_file, n_steps=10)


if __name__ == "__main__":
    main()
