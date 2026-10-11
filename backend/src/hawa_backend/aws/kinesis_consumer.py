"""Kinesis consumer: telemetry records on HAWA_AWS_SENSOR_STREAM -> services.fleet.ingest.

Producers: the IoT Core rule on hawa/vehicles/+/telemetry (HawaTag devices, or `hawa simulate-fleet
--target iot`), and the backend itself, which forwards HTTP pings marked via=api; those are skipped here
because they were stored when they arrived.

A polling consumer (GetShardIterator + GetRecords), one loop per open shard; the shard list is refreshed
every SHARD_REFRESH_SECONDS so on-demand resharding is picked up. The last sequence number per shard is
checkpointed in Redis when configured, so a restart resumes where it stopped; otherwise a fresh start
begins at HAWA_AWS_KINESIS_START (LATEST by default).

Run it inside the API (HAWA_AWS_KINESIS_CONSUMER=true) or as its own process: `hawa consume-telemetry`.
Run only one consumer per stream.
"""
from __future__ import annotations

import asyncio
import json
import logging
from typing import Any, Dict, List, Optional, Set, Tuple

from ..core.redis_store import get_redis, mark_failed
from .clients import get_client
from .settings import get_aws_settings

logger = logging.getLogger("hawa_backend.kinesis_consumer")

CHECKPOINT_PREFIX = "kinesis:checkpoint:"
SHARD_REFRESH_SECONDS = 60.0
IDLE_SLEEP_SECONDS = 1.0
BUSY_SLEEP_SECONDS = 0.2

_memory_checkpoints: Dict[str, str] = {}


def parse_record(data: bytes) -> List[Any]:
    """Kinesis record data -> VehiclePing list (a record may hold one object or a list)."""
    from ..services.fleet import VehiclePing

    try:
        payload = json.loads(data)
    except (ValueError, UnicodeDecodeError):
        logger.warning("skipping a non-JSON record")
        return []
    out = []
    for p in payload if isinstance(payload, list) else [payload]:
        if not isinstance(p, dict) or p.get("via") == "api":
            continue
        p = dict(p)
        if "asset_id" not in p and "device_id" in p:
            p["asset_id"] = p["device_id"]
        if "lat" not in p or "lon" not in p:
            continue  # sensor readings without a position are not fleet pings
        p.setdefault("source", "iot")
        try:
            out.append(VehiclePing.model_validate(p))
        except Exception as exc:
            logger.warning("skipping an invalid ping: %s", exc)
    return out


async def _checkpoint_get(key: str) -> Optional[str]:
    r = await get_redis()
    if r is not None:
        try:
            return await r.get(CHECKPOINT_PREFIX + key)
        except Exception:
            mark_failed()
    return _memory_checkpoints.get(key)


async def _checkpoint_set(key: str, seq: str) -> None:
    _memory_checkpoints[key] = seq
    r = await get_redis()
    if r is not None:
        try:
            await r.set(CHECKPOINT_PREFIX + key, seq, ex=7 * 24 * 3600)
        except Exception:
            mark_failed()


def _list_shards(stream: str) -> List[str]:
    kinesis = get_client("kinesis")
    shards, kwargs = [], {"StreamName": stream}
    while True:
        resp = kinesis.list_shards(**kwargs)
        shards += [s["ShardId"] for s in resp.get("Shards", [])]
        token = resp.get("NextToken")
        if not token:
            return shards
        kwargs = {"NextToken": token}


def _iterator(stream: str, shard: str, seq: Optional[str], start: str) -> str:
    kwargs: Dict[str, Any] = {"StreamName": stream, "ShardId": shard}
    if seq:
        kwargs.update(ShardIteratorType="AFTER_SEQUENCE_NUMBER", StartingSequenceNumber=seq)
    else:
        kwargs["ShardIteratorType"] = start if start in ("LATEST", "TRIM_HORIZON") else "LATEST"
    return get_client("kinesis").get_shard_iterator(**kwargs)["ShardIterator"]


def _get_records(iterator: str) -> Tuple[List[Dict[str, Any]], Optional[str]]:
    resp = get_client("kinesis").get_records(ShardIterator=iterator, Limit=500)
    return resp.get("Records", []), resp.get("NextShardIterator")


async def process_records(records: List[Dict[str, Any]]) -> int:
    from ..services.fleet import ingest

    count = 0
    for rec in records:
        for ping in parse_record(rec["Data"]):
            await ingest(ping, forward=False)
            count += 1
    return count


async def _consume_shard(stream: str, shard: str, start: str, stop: asyncio.Event) -> None:
    key = f"{stream}:{shard}"
    seq = await _checkpoint_get(key)
    iterator: Optional[str] = await asyncio.to_thread(_iterator, stream, shard, seq, start)
    logger.info("consuming %s %s from %s", stream, shard, f"after {seq}" if seq else start)
    while iterator and not stop.is_set():
        try:
            records, iterator = await asyncio.to_thread(_get_records, iterator)
        except Exception as exc:
            name = type(exc).__name__ + str(exc)
            if "ExpiredIterator" in name:
                iterator = await asyncio.to_thread(_iterator, stream, shard, seq, start)
                continue
            logger.warning("GetRecords on %s failed: %s", shard, exc)
            await asyncio.sleep(2.0)
            continue
        if records:
            await process_records(records)
            seq = records[-1]["SequenceNumber"]
            await _checkpoint_set(key, seq)
        await asyncio.sleep(BUSY_SLEEP_SECONDS if records else IDLE_SLEEP_SECONDS)
    logger.info("shard %s closed or consumer stopping", shard)


async def run(stop: Optional[asyncio.Event] = None) -> None:
    """Consume until `stop` is set. Returns at once when the stream is not configured."""
    s = get_aws_settings()
    if not (s.enabled and s.sensor_stream):
        logger.warning("Kinesis consumer not started: set HAWA_AWS_ENABLED=true and HAWA_AWS_SENSOR_STREAM")
        return
    stop = stop or asyncio.Event()
    tasks: Dict[str, asyncio.Task] = {}
    closed: Set[str] = set()
    try:
        while not stop.is_set():
            try:
                shards = await asyncio.to_thread(_list_shards, s.sensor_stream)
            except Exception as exc:
                logger.warning("ListShards on %s failed: %s", s.sensor_stream, exc)
                shards = []
            for shard in shards:
                task = tasks.get(shard)
                if task is not None and task.done():
                    if not task.cancelled() and task.exception() is not None:
                        logger.warning("shard %s loop failed, restarting: %s", shard, task.exception())
                        del tasks[shard]
                    else:
                        closed.add(shard)
                if shard not in tasks and shard not in closed:
                    tasks[shard] = asyncio.create_task(_consume_shard(s.sensor_stream, shard, s.kinesis_start, stop))
            try:
                await asyncio.wait_for(stop.wait(), timeout=SHARD_REFRESH_SECONDS)
            except asyncio.TimeoutError:
                pass
    finally:
        stop.set()
        for task in tasks.values():
            task.cancel()
        await asyncio.gather(*tasks.values(), return_exceptions=True)
