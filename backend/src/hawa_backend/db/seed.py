"""Seed the database with the demo data the API serves today.

Run after `alembic upgrade head`:

    uv run python -m hawa_backend.db.seed          # from backend/ (or `make db-seed` from the repo root)

Idempotent: rows whose primary key already exists are left untouched, so re-running only adds what is missing.
Sources: the backend fixtures (`api/fixtures.py`, seed plan 214 in `api/routes/plans.py`), the AI-ML station list
(`AI-ML/data/fixtures/stations_fallback.csv`), the AI-ML effectiveness priors and the AI-ML 500 m grid geometry.
Everything except the reference stations and grid cells is demo data and is marked `is_simulated` where the model allows.
"""
import asyncio
import csv
import math
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, Iterable, List, Type

from sqlalchemy import select

from ..api import fixtures
from ..api.routes.plans import DEFAULT_PLAN_ID, _get_or_create_default_plan
from .base import Base
from .models import (
    Alert,
    AppUser,
    Asset,
    Cell500m,
    Device,
    EffectivenessLibrary,
    Impact,
    Intervention,
    Plan,
    PlanReview,
    PlanTask,
    ReferenceStation,
    School,
    Ward,
)
from .session import get_engine, get_sessionmaker


def _ts(value: str) -> datetime:
    return datetime.fromisoformat(value.replace("Z", "+00:00"))


def _slug(name: str) -> str:
    return "ward-" + name.lower().replace(" ", "-")


def wards() -> List[Ward]:
    seen: Dict[str, Ward] = {}
    for _, place, _, ward, lon, lat, *_ in fixtures.RAW_HOTSPOTS:
        seen.setdefault(ward, Ward(ward_id=_slug(ward), name=ward, zone=ward, population=0, centroid_lat=lat, centroid_lon=lon))
    # ward referenced by seed plan 214
    seen["ward-084"] = Ward(ward_id="ward-084", name="Ward 084 (Mundka)", zone="West", population=0, centroid_lat=28.682, centroid_lon=77.035)
    return list(seen.values())


def schools() -> List[School]:
    # The fixture schools have no coordinates; place them around the Mundka plan area (ward-084).
    return [
        School(school_id=s["id"], name=s["name"], ward_id="ward-084", lat=28.682 + 0.004 * i, lon=77.035 + 0.004 * i,
               assembly_time=s["assemblyAt"])
        for i, s in enumerate(fixtures.SCHOOLS)
    ]


def reference_stations() -> List[ReferenceStation]:
    from hawa_ml.settings import settings as ml_settings

    path = ml_settings.FIXTURES_DIR / "stations_fallback.csv"
    with open(path, encoding="utf-8") as f:
        return [
            ReferenceStation(station_id=row["id"], name=row["name"], source="CPCB/DPCC",
                             lat=float(row["latitude"]), lon=float(row["longitude"]), is_active=True)
            for row in csv.DictReader(f)
        ]


def cells() -> List[Cell500m]:
    """The AI-ML 500 m grid geometry (10,600 cells, ids `G-RRR-CCC`), without population covariates."""
    from hawa_ml.geo import DELHI_BBOX, LAT_METERS_PER_DEG, LON_METERS_PER_DEG, get_cell_id, meters_to_latlon

    min_lat, min_lon, max_lat, max_lon = DELHI_BBOX
    size = 500.0
    cols = math.ceil((max_lon - min_lon) * LON_METERS_PER_DEG / size)
    rows = math.ceil((max_lat - min_lat) * LAT_METERS_PER_DEG / size)
    out = []
    for r in range(rows):
        for c in range(cols):
            lat, lon = meters_to_latlon((c + 0.5) * size, (r + 0.5) * size)
            if min_lat <= lat <= max_lat and min_lon <= lon <= max_lon:
                out.append(Cell500m(cell_id=f"G-{r:03d}-{c:03d}", cell_1km_id=get_cell_id(lat, lon, 1000.0),
                                    row=r, col=c, lat=lat, lon=lon, population=0))
    return out


def assets_and_devices() -> List[Base]:
    out: List[Base] = []
    for a in fixtures.get_mock_assets():
        tag = a.get("tag") or {}
        out.append(Asset(asset_id=a["id"], kind=a["kind"], label=a["label"], status=a["status"],
                         capacity_litres=float(tag.get("tankLitres", 5000.0)), tag_id=tag.get("tagId"),
                         is_simulated=bool(a.get("simulated", True))))
        if tag:
            out.append(Device(device_id=tag["tagId"], role="TAG", placement="vehicle", status="active",
                              trust_score=float(tag.get("trust", 1.0)), current_vehicle_id=a["id"],
                              calibration_version=tag.get("fw", "v1.0.0"), is_simulated=True))
    return out


def plan_rows() -> List[Base]:
    p = _get_or_create_default_plan(DEFAULT_PLAN_ID)
    out: List[Base] = [Plan(
        plan_id=p["id"], ward_id=p["ward"], status=p["status"],
        window_start=_ts(p["window"]["start"]), window_end=_ts(p["window"]["end"]), window_label=p["window"]["label"],
        drafted_by=p["draftedBy"], headline=p["headline"], summary=p["summary"], reasoning=p["reasoning"],
        checks=p["checks"], is_simulated=True,
    )]
    for group in p["groups"]:
        for t in group["tasks"]:
            out.append(PlanTask(task_id=t["id"], plan_id=p["id"], asset_id=group["asset"], op=t["op"], time_label=t["time"],
                                place=t["place"], action=t.get("action"), cause=t.get("cause"), cause_conf=t.get("causeConf"),
                                reason=t["reason"]))
    for c in p["comments"]:
        out.append(PlanReview(review_id=c["id"], plan_id=p["id"], agent_role="Auditor", objections=[c["objection"]],
                              suggestions=[c["suggestion"]], verdict="revise" if c["status"] == "open" else "acceptable"))
    return out


def impact_rows() -> List[Base]:
    out: List[Base] = []
    assets = {a["id"]: a for a in fixtures.get_mock_assets()}
    for item in fixtures.get_mock_impact()["items"]:
        imp = item["impact"]
        start = _ts(item["startedAt"])
        tag = assets.get(item["asset"], {}).get("tag", {})
        lon, lat = assets.get(item["asset"], {}).get("at", [77.035, 28.682])
        out.append(Intervention(
            intervention_id=item["id"], tag_id=tag.get("tagId", "unknown"), asset_id=item["asset"],
            start_ts=start, end_ts=start + timedelta(minutes=imp["durationMin"]), lat=lat, lon=lon,
            cell_500m_id=item["cellId"], litres_delivered=float(tag.get("litresThisRun", 0.0)),
            flow_avg_lpm=float(tag.get("flowLpm", 0.0)), verification_status="verified",
            verify_after=start + timedelta(hours=2), is_simulated=True,
        ))
        out.append(Impact(impact_id=f"imp-{item['id']}", intervention_id=item["id"], pollutant=imp["pollutant"],
                          effect_pct=imp["effectPct"], ci_low_pct=imp["ciLow"], ci_high_pct=imp["ciHigh"],
                          verdict=imp["verdict"], series=imp["series"], is_simulated=True))
    return out


def effectiveness() -> List[EffectivenessLibrary]:
    # AI-ML priors store positive reductions; the table stores signed effects (negative = cleaner air).
    from hawa_ml.causal.effectiveness_library import DEFAULT_PRIORS

    return [
        EffectivenessLibrary(id=f"{p.cause}:{p.action}", cause=p.cause, asset_kind=p.action, sample_size=p.sample_count,
                             effect_pct=-p.pm10_reduction_pct, ci_low=-p.ci_high_pct, ci_high=-p.ci_low_pct)
        for p in DEFAULT_PRIORS
    ]


def alerts() -> List[Alert]:
    return [
        Alert(alert_id=a["id"], audience=a["audience"], channel=a["channel"], title=a["target"], body_en=a["message"],
              body_hi=a.get("messageHi", a["message"]), status="delivered", is_simulated=True)
        for a in fixtures.get_mock_alerts()["items"]
    ]


def users() -> List[AppUser]:
    # Demo personas matching the Flutter app's fake-auth numbers (README: Demo login).
    people = [
        ("usr-officer", "+919810000001", "Demo Ward Officer", "officer"),
        ("usr-driver", "+919810012345", "Demo Driver", "driver"),
        ("usr-inspector", "+919810022222", "Demo Inspector", "inspector"),
        ("usr-school", "+919810033333", "Demo School Principal", "school"),
        ("usr-site", "+919810044444", "Demo Site Manager", "site_manager"),
    ]
    return [AppUser(user_id=u, phone_e164=ph, full_name=n, role=r, ward_ids=["ward-084"]) for u, ph, n, r in people]


async def _insert_missing(session, model: Type[Base], rows: Iterable[Base]) -> int:
    rows = list(rows)
    if not rows:
        return 0
    pk = model.__mapper__.primary_key
    existing = {tuple(r) for r in (await session.execute(select(*pk))).all()}
    new = [r for r in rows if tuple(getattr(r, c.key) for c in pk) not in existing]
    session.add_all(new)
    await session.flush()
    return len(new)


async def seed() -> Dict[str, int]:
    groups: List[tuple] = [
        (Ward, wards()),
        (School, schools()),
        (ReferenceStation, reference_stations()),
        (Cell500m, cells()),
    ]
    assets_devices = assets_and_devices()
    groups += [
        (Asset, [r for r in assets_devices if isinstance(r, Asset)]),
        (Device, [r for r in assets_devices if isinstance(r, Device)]),
    ]
    plan = plan_rows()
    groups += [(Plan, [r for r in plan if isinstance(r, Plan)]),
               (PlanTask, [r for r in plan if isinstance(r, PlanTask)]),
               (PlanReview, [r for r in plan if isinstance(r, PlanReview)])]
    imp = impact_rows()
    groups += [(Intervention, [r for r in imp if isinstance(r, Intervention)]),
               (Impact, [r for r in imp if isinstance(r, Impact)]),
               (EffectivenessLibrary, effectiveness()),
               (Alert, alerts()),
               (AppUser, users())]

    counts: Dict[str, int] = {}
    async with get_sessionmaker()() as session:
        for model, rows in groups:
            counts[model.__tablename__] = await _insert_missing(session, model, rows)
        await session.commit()
    await get_engine().dispose()
    return counts


def main() -> None:
    counts = asyncio.run(seed())
    width = max(len(k) for k in counts)
    print(f"Seeded at {datetime.now(timezone.utc).isoformat(timespec='seconds')} (rows inserted, 0 = already present):")
    for table, n in counts.items():
        print(f"  {table:<{width}}  {n}")


if __name__ == "__main__":
    main()
