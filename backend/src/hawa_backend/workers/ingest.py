"""Edge telemetry ingestion, deduplication, calibration, and spatial cell assignment."""
from datetime import datetime, timezone
from typing import Optional, Set, Tuple
from hawa_contracts import (
    TelemetryPacket,
    validate_packet,
    calculate_indicative_aqi,
    pm25_to_category,
    format_cell_500m,
    format_cell_1km,
    uuid7,
)
from hawa_contracts.events.telemetry import ReadingCleaned, ReadingRejected
from hawa_contracts.events.device import DeviceSpike

# Standard UTM cell grid dimensions for Delhi (snapped 500 m)
ORIGIN_LAT = 28.40
ORIGIN_LON = 76.80
CELL_SIZE_DEG = 0.0045  # ~500 m in degrees latitude


class IngestProcessor:
    """Ingestion pipeline handler validating and calibrating raw sensor packets."""

    def __init__(self):
        # In-memory deduplication set for fast tracking / testing
        self._seen_packets: Set[Tuple[str, int]] = set()

    def is_duplicate(self, device_id: str, seq: int) -> bool:
        key = (device_id, seq)
        if key in self._seen_packets:
            return True
        self._seen_packets.add(key)
        return False

    def map_to_grid(self, lat: float, lon: float) -> Tuple[str, str]:
        """Map latitude and longitude to 500 m and 1 km cell IDs."""
        row_500 = max(0, int((lat - ORIGIN_LAT) / CELL_SIZE_DEG))
        col_500 = max(0, int((lon - ORIGIN_LON) / CELL_SIZE_DEG))
        cell_500m = format_cell_500m(row_500, col_500)
        cell_1km = format_cell_1km(row_500 // 2, col_500 // 2)
        return cell_500m, cell_1km

    def apply_calibration(
        self,
        pm25_raw: float,
        pm10_raw: Optional[float],
        rh: float,
        coeff_a: float = 0.85,
        coeff_b: float = -0.15,
        coeff_c: float = 5.0,
    ) -> Tuple[float, Optional[float]]:
        """Apply humidity-compensated regression model: ref = max(0, a*raw + b*RH + c)."""
        pm25_cal = max(0.0, coeff_a * pm25_raw + coeff_b * rh + coeff_c)
        pm10_cal = None
        if pm10_raw is not None:
            pm10_cal = max(pm25_cal, coeff_a * pm10_raw + coeff_b * rh + coeff_c)
        return round(pm25_cal, 1), round(pm10_cal, 1) if pm10_cal is not None else None

    def process_packet(
        self,
        packet: TelemetryPacket,
        baseline_pm25: float = 80.0,
    ) -> Tuple[Optional[ReadingCleaned], Optional[ReadingRejected], Optional[DeviceSpike]]:
        """Process incoming raw telemetry packet."""
        # 1. Deduplication check
        if self.is_duplicate(packet.dev, packet.seq):
            rejected = ReadingRejected(
                device_id=packet.dev,
                seq=packet.seq,
                ts=packet.ts,
                reason="duplicate_packet",
                raw_payload=packet.model_dump_json(),
            )
            return None, rejected, None

        # 2. Validation check
        val_error = validate_packet(packet)
        if val_error:
            rejected = ReadingRejected(
                device_id=packet.dev,
                seq=packet.seq,
                ts=packet.ts,
                reason=val_error,
                raw_payload=packet.model_dump_json(),
            )
            return None, rejected, None

        # 3. Grid mapping
        cell_500m, cell_1km = self.map_to_grid(packet.lat, packet.lon)

        # 4. Calibration
        pm25_clean, pm10_clean = self.apply_calibration(packet.pm25, packet.pm10, packet.rh)

        # 5. Air Quality Index
        aqi = calculate_indicative_aqi(pm25=pm25_clean, pm10=pm10_clean)
        category = pm25_to_category(pm25_clean)

        reading = ReadingCleaned(
            reading_id=uuid7(),
            device_id=packet.dev,
            ts=packet.ts,
            seq=packet.seq,
            lat=packet.lat,
            lon=packet.lon,
            cell_500m_id=cell_500m,
            cell_1km_id=cell_1km,
            pm25=pm25_clean,
            pm10=pm10_clean,
            pm25_raw=packet.pm25,
            pm10_raw=packet.pm10,
            rh=packet.rh,
            t=packet.t,
            speed_kmh=packet.spd,
            indicative_aqi=aqi,
            aqi_category=category,
            calibration_version="cal-huber-v1.0",
            is_simulated=packet.is_simulated,
        )

        # 6. Spike detection (PM2.5 >= 3x rolling baseline)
        spike = None
        if pm25_clean >= 3.0 * baseline_pm25:
            spike = DeviceSpike(
                device_id=packet.dev,
                seq=packet.seq,
                ts=packet.ts,
                lat=packet.lat,
                lon=packet.lon,
                cell_500m_id=cell_500m,
                pm25_spike=pm25_clean,
                pm25_baseline=baseline_pm25,
                rise_factor=round(pm25_clean / baseline_pm25, 2),
                confirmed_by_cloud=True,
                is_simulated=packet.is_simulated,
            )

        return reading, None, spike
