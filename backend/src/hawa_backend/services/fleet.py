"""Live fleet telemetry from HawaTag vehicle trackers.

A ping ({asset_id, lat, lon, speed_kmh, pump_flow_lpm, timestamp, ...}) arrives over HTTP
(POST /v1/telemetry/vehicles), or from IoT Core through Kinesis (aws/kinesis_consumer.py), and goes to:

- process memory: the latest ping and a short track per asset (always; the fallback for the rest)
- Redis (HAWA_REDIS_URL): GEOADD geo:fleet:active, ZADD fleet:lastseen, SET fleet:latest:<asset>,
  PUBLISH fleet:pings (WebSocket fan-out across processes)
- DynamoDB (HAWA_AWS_FLEET_TABLE): one item per ping, keys asset_id + timestamp, expiring via ttl_epoch
- Kinesis (HAWA_AWS_SENSOR_STREAM): HTTP pings are forwarded with via=api, which the consumer skips
"""
from __future__ import annotations

import asyncio
import json
import logging
import time
from collections import deque
from datetime import timedelta
from typing import Any, AsyncIterator, Deque, Dict, List, Optional, Set, Union

from pydantic import BaseModel, ConfigDict, Field

from ..aws.settings import get_aws_settings
from ..core.config import get_settings
from ..core.places import nearest_locality
from ..core.redis_store import get_redis, mark_failed
from ._util import drop_none, from_dynamo, haversine_m, iso, parse_ts, to_dynamo, utcnow

logger = logging.getLogger("hawa_backend.fleet")

GEO_KEY = "geo:fleet:active"
LASTSEEN_KEY = "fleet:lastseen"
LATEST_PREFIX = "fleet:latest:"
CHANNEL = "fleet:pings"
TRACK_LEN = 720  # 6 h of 30 s pings per asset in memory
SPRAY_MIN_LPM = 5.0
MOVING_MIN_KMH = 3.0

KIND_BY_PREFIX = (("SPR", "sprinkler"), ("SMG", "smog_gun"), ("ASG", "smog_gun"), ("SWP", "sweeper"), ("T-", "sprinkler"))
KIND_LABEL = {"sprinkler": "Water Sprinkler", "smog_gun": "Anti-Smog Gun", "sweeper": "Mechanical Sweeper"}


class VehiclePing(BaseModel):
    """One HawaTag reading. Matches the IoT Core payload on hawa/vehicles/<asset_id>/telemetry."""

    model_config = ConfigDict(extra="ignore")

    asset_id: str = Field(..., pattern=r"^[A-Za-z0-9_.:-]{1,64}$", examples=["SPR-04"])
    lat: float = Field(..., ge=-90, le=90)
    lon: float = Field(..., ge=-180, le=180)
    timestamp: Optional[Union[float, str]] = Field(None, description="ISO-8601 or epoch seconds/ms; default now")
    speed_kmh: float = Field(0.0, ge=0, le=250)
    pump_flow_lpm: float = Field(0.0, ge=0, le=2000)
    heading_deg: Optional[float] = Field(None, ge=0, le=360)
    litres_cum: Optional[float] = Field(None, ge=0, description="Cumulative litres sprayed this shift")
    pm25: Optional[float] = Field(None, ge=0)
    pm10: Optional[float] = Field(None, ge=0)
    kind: Optional[str] = Field(None, description="sprinkler | smog_gun | sweeper (guessed from the id if absent)")
    tag_id: Optional[str] = None
    seq: Optional[int] = None
    source: str = Field("api", description="api | iot | simulator")


def asset_kind(asset_id: str, kind: Optional[str] = None) -> str:
    if kind in KIND_LABEL:
        return kind
    upper = asset_id.upper()
    for prefix, k in KIND_BY_PREFIX:
        if upper.startswith(prefix):
            return k
    return "sprinkler"


def to_record(ping: VehiclePing) -> Dict[str, Any]:
    ts = parse_ts(ping.timestamp)
    return drop_none({
        "asset_id": ping.asset_id,
        "timestamp": iso(ts),
        "epoch": round(ts.timestamp(), 3),
        "lat": round(ping.lat, 6),
        "lon": round(ping.lon, 6),
        "speed_kmh": round(ping.speed_kmh, 2),
        "pump_flow_lpm": round(ping.pump_flow_lpm, 2),
        "heading_deg": ping.heading_deg,
        "litres_cum": ping.litres_cum,
        "pm25": ping.pm25,
        "pm10": ping.pm10,
        "kind": asset_kind(ping.asset_id, ping.kind),
        "tag_id": ping.tag_id,
        "seq": ping.seq,
        "source": ping.source,
        "area": nearest_locality(ping.lon, ping.lat),
    })


def status_of(rec: Dict[str, Any], now_epoch: Optional[float] = None) -> str:
    """Web-console AssetStatus: Offline (stale), Spraying, En route or Idle."""
    now_epoch = now_epoch or time.time()
    if now_epoch - float(rec["epoch"]) > get_settings().fleet_active_minutes * 60:
        return "Offline"
    if float(rec.get("pump_flow_lpm", 0)) >= SPRAY_MIN_LPM:
        return "Spraying"
    if float(rec.get("speed_kmh", 0)) >= MOVING_MIN_KMH:
        return "En route"
    return "Idle"


# --------------------------------------------------------------------------- memory


class _Memory:
    def __init__(self) -> None:
        self.latest: Dict[str, Dict[str, Any]] = {}
        self.tracks: Dict[str, Deque[Dict[str, Any]]] = {}

    def add(self, rec: Dict[str, Any]) -> None:
        prev = self.latest.get(rec["asset_id"])
        if prev is None or prev["epoch"] <= rec["epoch"]:
            self.latest[rec["asset_id"]] = rec
        track = self.tracks.setdefault(rec["asset_id"], deque(maxlen=TRACK_LEN))
        track.append(rec)

    def clear(self) -> None:
        self.latest.clear()
        self.tracks.clear()


_memory = _Memory()
_subscribers: Set[asyncio.Queue] = set()


def reset_memory() -> None:
    _memory.clear()


# --------------------------------------------------------------------------- writes


async def _to_redis(rec: Dict[str, Any]) -> bool:
    r = await get_redis()
    if r is None:
        return False
    payload = json.dumps(rec)
    try:
        pipe = r.pipeline(transaction=False)
        pipe.geoadd(GEO_KEY, (rec["lon"], rec["lat"], rec["asset_id"]))
        pipe.zadd(LASTSEEN_KEY, {rec["asset_id"]: rec["epoch"]})
        pipe.set(LATEST_PREFIX + rec["asset_id"], payload, ex=24 * 3600)
        pipe.publish(CHANNEL, payload)
        await pipe.execute()
        return True
    except Exception as exc:
        logger.warning("Redis fleet write failed: %s", exc)
        mark_failed()
        return False


def _put_dynamo(table_name: str, rec: Dict[str, Any], ttl_days: int) -> None:
    from ..aws.clients import get_table

    item = dict(rec, ttl_epoch=int(rec["epoch"]) + ttl_days * 86400)
    get_table(table_name).put_item(Item=to_dynamo(item))


async def _to_dynamo(rec: Dict[str, Any]) -> None:
    s = get_aws_settings()
    if not (s.enabled and s.fleet_table):
        return
    try:
        await asyncio.to_thread(_put_dynamo, s.fleet_table, rec, s.fleet_ttl_days)
    except Exception as exc:
        logger.warning("fleet telemetry write to %s failed: %s", s.fleet_table, exc)


async def _to_kinesis(rec: Dict[str, Any]) -> None:
    from ..aws.events import publish_sensor_reading

    payload = {k: v for k, v in rec.items() if k not in ("epoch", "area")}
    await publish_sensor_reading(rec["asset_id"], dict(payload, via="api"))


def _to_local(rec: Dict[str, Any]) -> None:
    for q in list(_subscribers):
        try:
            q.put_nowait(rec)
        except asyncio.QueueFull:
            pass


async def ingest(ping: VehiclePing, forward: bool = True) -> Dict[str, Any]:
    """Store one ping everywhere configured. `forward=False` for pings that came from Kinesis."""
    rec = to_record(ping)
    _memory.add(rec)
    _to_local(rec)
    await _to_redis(rec)
    tasks = [_to_dynamo(rec)]
    if forward:
        tasks.append(_to_kinesis(rec))
    await asyncio.gather(*tasks)
    return dict(rec, status=status_of(rec))


async def ingest_many(pings: List[VehiclePing], forward: bool = True) -> List[Dict[str, Any]]:
    return [await ingest(p, forward=forward) for p in pings]


# --------------------------------------------------------------------------- reads


def _active_memory(now_epoch: float) -> List[Dict[str, Any]]:
    cutoff = now_epoch - get_settings().fleet_active_minutes * 60
    return [r for r in _memory.latest.values() if r["epoch"] >= cutoff]


async def _active_redis(r, now_epoch: float) -> List[Dict[str, Any]]:
    cutoff = now_epoch - get_settings().fleet_active_minutes * 60
    stale = await r.zrangebyscore(LASTSEEN_KEY, "-inf", f"({cutoff}")
    if stale:
        await r.zrem(LASTSEEN_KEY, *stale)
        await r.zrem(GEO_KEY, *stale)
    ids = await r.zrangebyscore(LASTSEEN_KEY, cutoff, "+inf")
    if not ids:
        return []
    values = await r.mget([LATEST_PREFIX + i for i in ids])
    return [json.loads(v) for v in values if v]


async def live_fleet() -> List[Dict[str, Any]]:
    """Latest ping of every asset seen within HAWA_FLEET_ACTIVE_MINUTES, newest first."""
    now_epoch = time.time()
    items: Optional[List[Dict[str, Any]]] = None
    r = await get_redis()
    if r is not None:
        try:
            items = await _active_redis(r, now_epoch)
        except Exception as exc:
            logger.warning("Redis fleet read failed: %s", exc)
            mark_failed()
    if items is None:
        items = _active_memory(now_epoch)
    items = [dict(i, status=status_of(i, now_epoch)) for i in items]
    return sorted(items, key=lambda i: i["epoch"], reverse=True)


async def latest(asset_id: str) -> Optional[Dict[str, Any]]:
    r = await get_redis()
    if r is not None:
        try:
            raw = await r.get(LATEST_PREFIX + asset_id)
            if raw:
                rec = json.loads(raw)
                return dict(rec, status=status_of(rec))
        except Exception as exc:
            logger.warning("Redis fleet read failed: %s", exc)
            mark_failed()
    rec = _memory.latest.get(asset_id)
    return dict(rec, status=status_of(rec)) if rec else None


async def nearby(lat: float, lon: float, radius_km: float = 5.0, limit: int = 50) -> List[Dict[str, Any]]:
    """Active vehicles within radius_km, nearest first (Redis GEOSEARCH when available)."""
    now_epoch = time.time()
    r = await get_redis()
    if r is not None:
        try:
            await _active_redis(r, now_epoch)  # prunes stale members from the geo index
            hits = await r.geosearch(
                GEO_KEY, longitude=lon, latitude=lat, radius=radius_km, unit="km",
                withdist=True, sort="ASC", count=limit,
            )
            if not hits:
                return []
            names = [h[0] for h in hits]
            values = await r.mget([LATEST_PREFIX + n for n in names])
            out = []
            for (name, dist), raw in zip(hits, values):
                if raw:
                    rec = json.loads(raw)
                    out.append(dict(rec, status=status_of(rec, now_epoch), distance_m=round(float(dist) * 1000.0, 1)))
            return out
        except Exception as exc:
            logger.warning("Redis GEOSEARCH failed: %s", exc)
            mark_failed()
    out = []
    for rec in _active_memory(now_epoch):
        d = haversine_m(lat, lon, rec["lat"], rec["lon"])
        if d <= radius_km * 1000.0:
            out.append(dict(rec, status=status_of(rec, now_epoch), distance_m=round(d, 1)))
    return sorted(out, key=lambda i: i["distance_m"])[:limit]


def _query_dynamo(table_name: str, asset_id: str, since_iso: str) -> List[Dict[str, Any]]:
    from boto3.dynamodb.conditions import Key

    from ..aws.clients import get_table

    resp = get_table(table_name).query(
        KeyConditionExpression=Key("asset_id").eq(asset_id) & Key("timestamp").gte(since_iso),
        ScanIndexForward=True,
        Limit=2000,
    )
    return [from_dynamo(i) for i in resp.get("Items", [])]


async def track(asset_id: str, minutes: int = 180) -> List[Dict[str, Any]]:
    """Pings of one asset in the last `minutes`, oldest first (DynamoDB when configured)."""
    since = utcnow() - timedelta(minutes=minutes)
    s = get_aws_settings()
    if s.enabled and s.fleet_table:
        try:
            items = await asyncio.to_thread(_query_dynamo, s.fleet_table, asset_id, iso(since))
            if items:
                return items
        except Exception as exc:
            logger.warning("fleet telemetry query on %s failed: %s", s.fleet_table, exc)
    cutoff = since.timestamp()
    return [r for r in _memory.tracks.get(asset_id, ()) if r["epoch"] >= cutoff]


async def audit(
    asset_id: str, lat: Optional[float], lon: Optional[float], window_minutes: int = 180, radius_m: float = 500.0,
) -> Optional[Dict[str, Any]]:
    """Did the asset dwell and spray near (lat, lon) in the window? None when it sent no telemetry."""
    pts = await track(asset_id, window_minutes)
    return evaluate(pts, lat, lon, window_minutes, radius_m) if pts else None


def evaluate(
    pts: List[Dict[str, Any]], lat: Optional[float], lon: Optional[float], window_minutes: int, radius_m: float = 500.0,
) -> Dict[str, Any]:
    """Dwell time, pump activity and closest approach of a track relative to (lat, lon); no site = anywhere."""

    def near(p: Dict[str, Any]) -> bool:
        return lat is None or lon is None or haversine_m(lat, lon, p["lat"], p["lon"]) <= radius_m

    dwell_s = 0.0
    litres = 0.0
    for a, b in zip(pts, pts[1:]):
        gap = min(max(float(b["epoch"]) - float(a["epoch"]), 0.0), 300.0)
        if near(a) and near(b):
            dwell_s += gap
            litres += float(a.get("pump_flow_lpm", 0)) * gap / 60.0
    sprayed_near = [p for p in pts if near(p) and float(p.get("pump_flow_lpm", 0)) >= SPRAY_MIN_LPM]
    closest = None if lat is None or lon is None else min(haversine_m(lat, lon, p["lat"], p["lon"]) for p in pts)
    return {
        "pings": len(pts),
        "window_minutes": window_minutes,
        "radius_m": radius_m,
        "dwell_minutes": round(dwell_s / 60.0, 1),
        "sprayed": bool(sprayed_near),
        "max_pump_flow_lpm": max(float(p.get("pump_flow_lpm", 0)) for p in pts),
        "litres_estimated": round(litres, 1),
        "closest_m": None if closest is None else round(closest, 1),
        "first_ping": pts[0]["timestamp"],
        "last_ping": pts[-1]["timestamp"],
        "latest": pts[-1],
    }


class Subscription:
    """Every new ping as it is ingested: Redis pub/sub across processes, else this process only.

    Registered by `await start()`, so nothing published after that is missed; iterate with `async for`.
    """

    def __init__(self) -> None:
        self._queue: Optional[asyncio.Queue] = None
        self._pubsub: Any = None

    async def start(self) -> "Subscription":
        r = await get_redis()
        if r is not None:
            try:
                self._pubsub = r.pubsub()
                await self._pubsub.subscribe(CHANNEL)
                return self
            except Exception as exc:
                logger.warning("Redis subscribe failed, using this process only: %s", exc)
                self._pubsub = None
        self._queue = asyncio.Queue(maxsize=512)
        _subscribers.add(self._queue)
        return self

    async def __aiter__(self) -> AsyncIterator[Dict[str, Any]]:
        if self._pubsub is not None:
            async for msg in self._pubsub.listen():
                if msg.get("type") == "message":
                    yield json.loads(msg["data"])
        elif self._queue is not None:
            while True:
                yield await self._queue.get()

    async def close(self) -> None:
        if self._queue is not None:
            _subscribers.discard(self._queue)
        if self._pubsub is not None:
            try:
                await self._pubsub.unsubscribe(CHANNEL)
                await self._pubsub.aclose()
            except Exception:
                pass


async def subscribe() -> Subscription:
    return await Subscription().start()


# --------------------------------------------------------------------------- views


def to_asset(rec: Dict[str, Any]) -> Dict[str, Any]:
    """Web console Asset shape (frontend/src/contracts/asset.ts)."""
    status = rec.get("status") or status_of(rec)
    flow = float(rec.get("pump_flow_lpm", 0))
    litres = float(rec.get("litres_cum") or 0)
    kind = rec.get("kind", "sprinkler")
    summary = {
        "Spraying": f"Spraying · {flow:.0f} LPM · {litres:,.0f} L used",
        "En route": f"En route · {float(rec.get('speed_kmh', 0)):.0f} km/h near {rec.get('area', 'Delhi')}",
        "Idle": f"Idle near {rec.get('area', 'Delhi')}",
        "Offline": "No ping for over 15 min",
    }.get(status, status)
    asset = {
        "id": rec["asset_id"],
        "kind": kind,
        "label": f"{KIND_LABEL.get(kind, 'Vehicle')} {rec['asset_id']}",
        "task": f"Live · near {rec.get('area', 'Delhi')}",
        "status": status,
        "tagSummary": summary,
        "lastPingAt": rec["timestamp"],
        "at": [rec["lon"], rec["lat"]],
        "simulated": rec.get("source") == "simulator",
        "tag": {
            "tagId": rec.get("tag_id") or f"HTG-{rec['asset_id']}",
            "fw": "live",
            "pumpOn": flow >= SPRAY_MIN_LPM,
            "flowLpm": flow,
            "litresThisRun": litres,
            "tankLitres": 5000.0,
            "sprayWindows": [],
            "tamperIntact": True,
            "signalDbm": -70,
            "trust": 0.9,
            "lastSeq": int(rec.get("seq") or 0),
        },
    }
    if rec.get("pm10") is not None:
        asset["tag"]["pm10Now"] = float(rec["pm10"])
    return asset


def to_live_ops(rec: Dict[str, Any]) -> Dict[str, Any]:
    """Citizen live-operations radar shape (hawa_ml.simulation.audit.FLEET_TELEMETRY entries)."""
    status = rec.get("status") or status_of(rec)
    flow = float(rec.get("pump_flow_lpm", 0))
    kind = rec.get("kind", "sprinkler")
    return {
        "asset_id": rec["asset_id"],
        "type": {"sprinkler": "water_sprinkler", "smog_gun": "anti_smog_gun", "sweeper": "mechanical_sweeper"}.get(kind, kind),
        "ward": rec.get("area", "Delhi"),
        "assigned_route": None,
        "status": {"Spraying": "ACTIVE_SPRAYING", "En route": "EN_ROUTE", "Idle": "IDLE", "Offline": "OFFLINE"}.get(status, status),
        "last_gps": [rec["lat"], rec["lon"]],
        "speed_kmh": float(rec.get("speed_kmh", 0)),
        "water_pump_flow_lpm": flow,
        "water_disbursed_liters": float(rec.get("litres_cum") or 0),
        "contractor_id": None,
        "dwell_minutes_on_route": None,
        "is_compliant": status in ("Spraying", "En route"),
        "last_ping_at": rec["timestamp"],
        "live": True,
        "simulated": rec.get("source") == "simulator",
    }
