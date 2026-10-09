"""Readable hotspot names: the nearest well-known Delhi locality to a point, and spatial thinning of ranked cells."""
import math
import re
from typing import Any, Dict, List, Sequence, Tuple

# (name, lat, lon): approximate centres, used only to label the nearest landmark
LOCALITIES: Sequence[Tuple[str, float, float]] = (
    ("Narela", 28.8527, 77.0929), ("Bawana", 28.7970, 77.0510), ("Alipur", 28.8000, 77.1370),
    ("Rohini", 28.7383, 77.0822), ("Burari", 28.7500, 77.1900), ("Jahangirpuri", 28.7260, 77.1630),
    ("Pitampura", 28.7000, 77.1320), ("Shalimar Bagh", 28.7160, 77.1560), ("Wazirpur", 28.6980, 77.1650),
    ("Mundka", 28.6820, 77.0300), ("Nangloi", 28.6830, 77.0620), ("Mangolpuri", 28.6920, 77.0930),
    ("Ashok Vihar", 28.6950, 77.1810), ("Mukherjee Nagar", 28.7050, 77.2150), ("Civil Lines", 28.6800, 77.2250),
    ("Punjabi Bagh", 28.6683, 77.1313), ("Rajouri Garden", 28.6492, 77.1220), ("Karol Bagh", 28.6510, 77.1900),
    ("Chandni Chowk", 28.6560, 77.2300), ("Connaught Place", 28.6315, 77.2167), ("ITO", 28.6280, 77.2410),
    ("Seelampur", 28.6700, 77.2680), ("Shahdara", 28.6700, 77.2900), ("Vivek Vihar", 28.6720, 77.3150),
    ("Anand Vihar", 28.6469, 77.3160), ("Laxmi Nagar", 28.6300, 77.2770), ("Patparganj", 28.6240, 77.3060),
    ("Mayur Vihar", 28.6080, 77.2950), ("Janakpuri", 28.6219, 77.0878), ("Dwarka", 28.5921, 77.0460),
    ("Najafgarh", 28.6090, 76.9790), ("Lajpat Nagar", 28.5677, 77.2430), ("RK Puram", 28.5660, 77.1760),
    ("Nehru Place", 28.5490, 77.2530), ("Jamia Nagar", 28.5610, 77.2810), ("Saket", 28.5245, 77.2066),
    ("Vasant Kunj", 28.5200, 77.1580), ("Mehrauli", 28.5190, 77.1850), ("Okhla", 28.5300, 77.2700),
    ("Tughlakabad", 28.5000, 77.2600), ("Badarpur", 28.4930, 77.3040),
)

_CELL = re.compile(r"(\d+)-(\d+)\s*$")


def _km(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    dy = (lat2 - lat1) * 111.0
    dx = (lon2 - lon1) * 111.0 * math.cos(math.radians((lat1 + lat2) / 2))
    return math.hypot(dx, dy)


def nearest_locality(lon: float, lat: float) -> str:
    return min(LOCALITIES, key=lambda p: _km(lat, lon, p[1], p[2]))[0]


def spread(cell_ids: Sequence[str], limit: int, min_cells: int = 4) -> List[int]:
    """Indices (in ranked order) of up to `limit` cells at least `min_cells` apart, so one plume is not ten rows."""
    kept: List[Tuple[int, int, int]] = []
    for i, cid in enumerate(cell_ids):
        m = _CELL.search(str(cid))
        rc = (int(m.group(1)), int(m.group(2))) if m else (i * 100, 0)
        if all(max(abs(rc[0] - r), abs(rc[1] - c)) >= min_cells for _, r, c in kept):
            kept.append((i, *rc))
            if len(kept) == limit:
                break
    if len(kept) < limit:  # not enough separated cells: fill with the best remaining
        have = {i for i, _, _ in kept}
        kept += [(i, 0, 0) for i in range(len(cell_ids)) if i not in have][: limit - len(kept)]
        kept.sort()
    return [i for i, _, _ in kept]


_DIRS = ("East", "North-east", "North", "North-west", "West", "South-west", "South", "South-east")


def _side(lon: float, lat: float, loc: str) -> str:
    _, la, lo = next(p for p in LOCALITIES if p[0] == loc)
    ang = math.degrees(math.atan2((lat - la) * 111.0, (lon - lo) * 111.0 * math.cos(math.radians(la)))) % 360
    return _DIRS[int((ang + 22.5) // 45) % 8]


def name_places(items: List[Dict[str, Any]]) -> None:
    """Rename 'Ward-9 Hotspot #7' style places to the nearest locality; a repeat becomes 'North Rohini', then 'North Rohini 2'."""
    used_loc: set = set()
    count: Dict[str, int] = {}
    for it in items:
        lon, lat = it["at"]
        loc = nearest_locality(lon, lat)
        name = loc if loc not in used_loc else f"{_side(lon, lat, loc)} {loc}"
        used_loc.add(loc)
        n = count[name] = count.get(name, 0) + 1
        it["place"] = name if n == 1 else f"{name} {n}"
        it["placeFull"] = f"Near {loc} · cell {it['cellId']} · {it['ward'].replace('-', ' ')}"
