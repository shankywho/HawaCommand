"""Virtual IoT sensor fleet simulator generating authentic MQTT packets."""
from datetime import datetime, timezone
import math
from typing import Generator, List
from hawa_contracts import TelemetryPacket, SprayPacket


class FleetSimulator:
    """Simulates mobile sensing pods and intervention spray tags."""

    def __init__(self, device_count: int = 10):
        self.device_count = device_count
        self.step = 0

    def generate_telemetry_batch(self) -> List[TelemetryPacket]:
        """Generate one round of 30 s readings across simulated devices."""
        self.step += 1
        now_iso = datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")
        packets = []

        for i in range(1, self.device_count + 1):
            dev_id = f"HPM-{i:04d}"
            # Simulate movement in West Delhi / Central corridor
            angle = (self.step * 0.1) + i
            lat = 28.65 + 0.05 * math.sin(angle)
            lon = 77.15 + 0.05 * math.cos(angle)
            speed = 22.0 + 8.0 * math.sin(self.step + i)
            
            # Simulated PM2.5 with diurnal variation and regional hotspot bump
            base_pm = 180.0 + 40.0 * math.sin(self.step * 0.05)
            pm25 = max(20.0, base_pm + (i * 12.0) % 80)
            pm10 = pm25 * 1.6 + 15.0

            packets.append(
                TelemetryPacket(
                    dev=dev_id,
                    seq=self.step,
                    ts=now_iso,
                    lat=round(lat, 5),
                    lon=round(lon, 5),
                    spd=round(speed, 1),
                    pm25=round(pm25, 1),
                    pm10=round(pm10, 1),
                    rh=65.0,
                    t=19.5,
                    is_simulated=True,
                )
            )
        return packets

    def generate_spray_event(self, asset_id: str = "AST-SPR-0012", action: str = "stop") -> SprayPacket:
        """Generate simulated HawaTag spray telemetry."""
        now_iso = datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")
        return SprayPacket(
            tag="HTG-0012",
            asset=asset_id,
            seq=self.step,
            ts=now_iso,
            lat=28.682,
            lon=77.035,
            action=action,
            flow_lpm=65.0 if action != "stop" else 0.0,
            pump_a=14.5 if action != "stop" else 0.0,
            litres_cum=1250.0,
            pm25_local=140.0,
            pm10_local=210.0,
            is_simulated=True,
        )
