"""Identifiers, regex validation, and grid-cell coordinate mapping (§2)."""
import re
import time
import uuid
from typing import Optional, Tuple

DEVICE_ID_RE = re.compile(r"^(HPM|HPS|HTG|HEY)-\d{4}(-[OI])?$")
ASSET_ID_RE = re.compile(r"^AST-(SPR|ASG|SWP|TEAM)-\d{4}$")
VEHICLE_ID_RE = re.compile(r"^VEH-[A-Za-z0-9]+-\d{4}$")
CELL_500M_RE = re.compile(r"^g500-(\d{3})-(\d{3})$")
CELL_1KM_RE = re.compile(r"^g1k-(\d{3})-(\d{3})$")
WARD_ID_RE = re.compile(r"^ward-[a-zA-Z0-9_\-]+$")
SCHOOL_ID_RE = re.compile(r"^SCH-[a-zA-Z0-9_\-]+$")
SITE_ID_RE = re.compile(r"^SITE-\d{4}$")
STATION_ID_RE = re.compile(r"^REF-(CPCB|DPCC|OAQ)-[a-zA-Z0-9_\-]+$")


def uuid7() -> str:
    """Generate a time-ordered UUIDv7 string."""
    # RFC 9562 UUIDv7 implementation
    ns = time.time_ns()
    timestamp_ms = ns // 1_000_000
    rand_bytes = bytearray(uuid.uuid4().bytes)

    # 48-bit timestamp
    rand_bytes[0] = (timestamp_ms >> 40) & 0xFF
    rand_bytes[1] = (timestamp_ms >> 32) & 0xFF
    rand_bytes[2] = (timestamp_ms >> 24) & 0xFF
    rand_bytes[3] = (timestamp_ms >> 16) & 0xFF
    rand_bytes[4] = (timestamp_ms >> 8) & 0xFF
    rand_bytes[5] = timestamp_ms & 0xFF

    # version 7 in high nibble of octet 6
    rand_bytes[6] = (rand_bytes[6] & 0x0F) | 0x70
    # variant 10 in high bits of octet 8
    rand_bytes[8] = (rand_bytes[8] & 0x3F) | 0x80

    return str(uuid.UUID(bytes=bytes(rand_bytes)))


def uuid7_deterministic(namespace: str, name: str) -> str:
    """Generate a deterministic UUID derived from namespace + name."""
    return str(uuid.uuid5(uuid.NAMESPACE_DNS, f"{namespace}:{name}"))


def format_cell_500m(row: int, col: int) -> str:
    """Format row and column into a 500 m cell ID."""
    return f"g500-{row:03d}-{col:03d}"


def format_cell_1km(row: int, col: int) -> str:
    """Format row and column into a 1 km cell ID."""
    return f"g1k-{row:03d}-{col:03d}"


def parse_cell_500m(cell_id: str) -> Optional[Tuple[int, int]]:
    """Parse a g500-xxx-yyy string into (row, col)."""
    match = CELL_500M_RE.match(cell_id)
    if not match:
        return None
    return int(match.group(1)), int(match.group(2))


def parse_cell_1km(cell_id: str) -> Optional[Tuple[int, int]]:
    """Parse a g1k-xxx-yyy string into (row, col)."""
    match = CELL_1KM_RE.match(cell_id)
    if not match:
        return None
    return int(match.group(1)), int(match.group(2))


def cell_500m_to_1km(cell_500m_id: str) -> Optional[str]:
    """Map a 500 m cell ID to its parent 1 km cell ID."""
    coords = parse_cell_500m(cell_500m_id)
    if not coords:
        return None
    row, col = coords
    return format_cell_1km(row // 2, col // 2)


def is_valid_device_id(device_id: str) -> bool:
    return bool(DEVICE_ID_RE.match(device_id))


def is_valid_asset_id(asset_id: str) -> bool:
    return bool(ASSET_ID_RE.match(asset_id))
