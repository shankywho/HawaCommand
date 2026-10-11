"""HawaCommand CLI tool.

  hawa version | config | check
  hawa aws-check                 verify every configured AWS service, Redis and FCM with one cheap call each
  hawa simulate-fleet            send moving HawaTag vehicle pings (to the API, IoT Core or Kinesis)
  hawa consume-telemetry         run the Kinesis -> fleet consumer in the foreground
"""
import argparse
import asyncio
import json
import math
import sys
import time
from typing import Callable, List, Optional, Tuple

from . import __version__
from .core.config import bootstrap_secrets, get_settings


# --------------------------------------------------------------------------- aws-check


def _row(results: List[Tuple[str, str, str]], name: str, fn: Callable[[], str]) -> None:
    try:
        results.append((name, "OK", fn() or ""))
    except Exception as exc:  # noqa: BLE001 - report every failure
        results.append((name, "FAIL", f"{type(exc).__name__}: {exc}"[:300]))


def aws_check(push_test: bool = False) -> int:
    """One cheap call per configured service. Exit code 1 when anything configured fails."""
    import asyncio as aio

    from .aws.settings import get_aws_settings
    from .core.redis_store import get_sync_redis

    bootstrap_secrets()
    s = get_aws_settings()
    settings = get_settings()
    results: List[Tuple[str, str, str]] = []
    skipped: List[str] = []

    if not s.enabled:
        print("HAWA_AWS_ENABLED is false: every AWS feature is off. Set it to true in backend/.env.")
    else:
        from .aws.clients import get_client, get_s3_client, get_table

        def identity() -> str:
            ident = get_client("sts").get_caller_identity()
            return f"{ident['Arn']} (account {ident['Account']}, region {s.region})"

        _row(results, "credentials (STS)", identity)

        if s.secrets_id:
            from .aws.secrets import get_secret_json

            _row(results, f"Secrets Manager {s.secrets_id}", lambda: f"{len(get_secret_json(s.secrets_id))} keys")
        else:
            skipped.append("Secrets Manager (HAWA_AWS_SECRETS_ID)")

        if s.evidence_bucket:
            def s3_check() -> str:
                key = f"{s.evidence_prefix}healthcheck/aws-check.txt"
                client = get_s3_client()
                client.put_object(Bucket=s.evidence_bucket, Key=key, Body=b"hawa aws-check", ContentType="text/plain")
                client.head_object(Bucket=s.evidence_bucket, Key=key)
                return f"PutObject + HeadObject on s3://{s.evidence_bucket}/{key}"

            _row(results, f"S3 {s.evidence_bucket}", s3_check)
        else:
            skipped.append("S3 evidence bucket (HAWA_AWS_EVIDENCE_BUCKET)")

        if s.grievances_table:
            from boto3.dynamodb.conditions import Key

            def grievances_check() -> str:
                table = get_table(s.grievances_table)
                table.query(KeyConditionExpression=Key("report_id").eq("aws-check"), Limit=1)
                table.query(IndexName=s.grievances_ward_index, KeyConditionExpression=Key("ward_id").eq("aws-check"), Limit=1)
                note = f"table + {s.grievances_ward_index}"
                try:
                    table.query(IndexName="OwnerIndex", KeyConditionExpression=Key("owner_id").eq("aws-check"), Limit=1)
                    note += " + OwnerIndex"
                except Exception:
                    note += " (no OwnerIndex: 'my reports' will Scan)"
                return note

            _row(results, f"DynamoDB {s.grievances_table}", grievances_check)
        else:
            skipped.append("DynamoDB grievances (HAWA_AWS_GRIEVANCES_TABLE)")

        if s.fleet_table:
            from boto3.dynamodb.conditions import Key

            _row(
                results,
                f"DynamoDB {s.fleet_table}",
                lambda: get_table(s.fleet_table).query(
                    KeyConditionExpression=Key("asset_id").eq("aws-check"), Limit=1
                ) and "Query OK",
            )
        else:
            skipped.append("DynamoDB fleet telemetry (HAWA_AWS_FLEET_TABLE)")

        if s.sensor_stream:
            def kinesis_check() -> str:
                d = get_client("kinesis").describe_stream_summary(StreamName=s.sensor_stream)["StreamDescriptionSummary"]
                mode = d.get("StreamModeDetails", {}).get("StreamMode", "?")
                return f"{d['StreamStatus']}, {mode}, {d.get('OpenShardCount', '?')} shards"

            _row(results, f"Kinesis {s.sensor_stream}", kinesis_check)
        else:
            skipped.append("Kinesis (HAWA_AWS_SENSOR_STREAM)")

        if s.alerts_topic_arn:
            def sns_check() -> str:
                a = get_client("sns").get_topic_attributes(TopicArn=s.alerts_topic_arn)["Attributes"]
                return f"{a.get('SubscriptionsConfirmed', '?')} confirmed, {a.get('SubscriptionsPending', '?')} pending subscriptions"

            _row(results, "SNS alerts topic", sns_check)
        else:
            skipped.append("SNS (HAWA_AWS_ALERTS_TOPIC_ARN)")

        if s.iot_endpoint:
            _row(results, "IoT Core endpoint", lambda: f"https://{s.iot_endpoint} (used by simulate-fleet --target iot)")

    if settings.redis_url:
        def redis_check() -> str:
            r = get_sync_redis()
            if r is None:
                raise ConnectionError("cannot connect (check the security group, TLS rediss:// and the URL)")
            r.geoadd("aws-check:geo", (77.3158, 28.6476, "SPR-04"))
            hits = r.geosearch("aws-check:geo", longitude=77.3158, latitude=28.6476, radius=1, unit="km")
            r.delete("aws-check:geo")
            info = r.info("server")
            return f"{info.get('redis_version', '?')}; GEOADD/GEOSEARCH ok ({len(hits)} hit)"

        _row(results, "Redis", redis_check)
    else:
        skipped.append("Redis (HAWA_REDIS_URL)")

    from .services import push

    if push.configured():
        def fcm_check() -> str:
            creds = push.credentials()
            push._fetch_access_token(creds)
            note = f"project {creds['project_id']}, OAuth token ok"
            if push_test:
                name = aio.run(push.send_to_topic("HawaCommand test", "Push from hawa aws-check", {"type": "pollutant_warning"}))
                note += f", test push {'sent: ' + name if name else 'FAILED'}"
            return note

        _row(results, "Firebase Cloud Messaging", fcm_check)
    else:
        skipped.append("FCM (HAWA_FCM_SERVICE_ACCOUNT_FILE / _JSON or HAWA_AWS_FCM_SECRET_ID)")

    width = max([len(r[0]) for r in results] + [10])
    for name, status, note in results:
        print(f"[{status:4}] {name.ljust(width)}  {note}")
    for name in skipped:
        print(f"[skip] {name}")
    return 1 if any(r[1] == "FAIL" for r in results) else 0


# --------------------------------------------------------------------------- simulate-fleet

# (asset_id, kind, centre lat, centre lon, radius in degrees, spraying)
DEMO_FLEET = [
    ("SPR-04", "sprinkler", 28.6476, 77.3158, 0.004, True),
    ("SMG-12", "smog_gun", 28.6720, 77.1250, 0.003, True),
    ("SPR-09", "sprinkler", 28.6820, 77.0300, 0.005, True),
    ("SWP-07", "sweeper", 28.5350, 77.2710, 0.0, False),  # parked at the depot: the ghost-worker case
]


def _ping(asset: Tuple, step: int, interval: float) -> dict:
    asset_id, kind, lat0, lon0, radius, spraying = asset
    angle = step * 0.08 + sum(map(ord, asset_id)) % 7
    moving = radius > 0
    flow = (42.0 + 12.0 * math.sin(step / 5.0)) if spraying else 0.0
    return {
        "asset_id": asset_id,
        "kind": kind,
        "lat": round(lat0 + radius * math.sin(angle), 6),
        "lon": round(lon0 + radius * math.cos(angle), 6),
        "speed_kmh": round(12.0 + 4.0 * math.sin(step / 3.0), 1) if moving else 0.0,
        "pump_flow_lpm": round(flow, 1),
        "litres_cum": round(flow * step * interval / 60.0, 1),
        "seq": step,
        "timestamp": time.time(),
        "source": "simulator",
    }


def simulate_fleet(target: str, url: str, assets: Optional[List[str]], interval: float, count: int) -> int:
    from .aws.settings import get_aws_settings

    bootstrap_secrets()
    s = get_aws_settings()
    fleet = [a for a in DEMO_FLEET if not assets or a[0] in assets]
    fleet += [(a, "sprinkler", 28.63, 77.22, 0.004, True) for a in (assets or []) if a not in {f[0] for f in fleet}]

    if target == "api":
        import httpx

        headers = {}
        key = get_settings().ingest_api_key or get_settings().admin_api_key
        if key:
            headers["X-Api-Key"] = key
        client = httpx.Client(base_url=url.rstrip("/"), headers=headers, timeout=10)

        def send(batch: List[dict]) -> str:
            r = client.post("/v1/telemetry/vehicles", json=batch)
            r.raise_for_status()
            return f"{r.json()['accepted']} accepted"
    elif target == "iot":
        if not s.iot_endpoint:
            print("Set HAWA_AWS_IOT_ENDPOINT (IoT Core > Settings > Device data endpoint) first.")
            return 2
        from .aws.clients import _config
        import boto3

        iot = boto3.client("iot-data", region_name=s.region, endpoint_url=f"https://{s.iot_endpoint}", config=_config())

        def send(batch: List[dict]) -> str:
            for p in batch:
                body = dict(p, timestamp=int(p["timestamp"] * 1000))
                iot.publish(topic=f"hawa/vehicles/{p['asset_id']}/telemetry", qos=1, payload=json.dumps(body))
            return f"{len(batch)} published to hawa/vehicles/+/telemetry"
    elif target == "kinesis":
        if not (s.enabled and s.sensor_stream):
            print("Set HAWA_AWS_ENABLED=true and HAWA_AWS_SENSOR_STREAM first.")
            return 2
        from .aws.clients import get_client

        def send(batch: List[dict]) -> str:
            get_client("kinesis").put_records(
                StreamName=s.sensor_stream,
                Records=[{"Data": json.dumps(p).encode(), "PartitionKey": p["asset_id"]} for p in batch],
            )
            return f"{len(batch)} records put on {s.sensor_stream}"
    else:
        print(f"unknown target {target}")
        return 2

    print(f"Simulating {', '.join(a[0] for a in fleet)} -> {target} every {interval}s (Ctrl+C to stop)")
    step = 0
    try:
        while count <= 0 or step < count:
            step += 1
            batch = [_ping(a, step, interval) for a in fleet]
            try:
                print(f"#{step}: {send(batch)}")
            except Exception as exc:  # noqa: BLE001
                print(f"#{step}: send failed: {exc}")
            time.sleep(interval)
    except KeyboardInterrupt:
        pass
    return 0


# --------------------------------------------------------------------------- main


def main() -> None:
    parser = argparse.ArgumentParser(prog="hawa", description="HawaCommand Backend Management CLI")
    subparsers = parser.add_subparsers(dest="command", help="Available subcommands")

    subparsers.add_parser("version", help="Print HawaCommand backend version")
    subparsers.add_parser("config", help="Print current active configuration")
    subparsers.add_parser("check", help="Verify configuration sanity")

    p_aws = subparsers.add_parser("aws-check", help="Check every configured AWS service, Redis and FCM")
    p_aws.add_argument("--push-test", action="store_true", help="Also send a test push to the FCM topic")

    p_sim = subparsers.add_parser("simulate-fleet", help="Send moving HawaTag vehicle pings")
    p_sim.add_argument("--target", choices=["api", "iot", "kinesis"], default="api")
    p_sim.add_argument("--url", default="http://localhost:8000", help="Backend URL for --target api")
    p_sim.add_argument("--assets", default="", help="Comma-separated asset ids (default: the demo fleet)")
    p_sim.add_argument("--interval", type=float, default=5.0, help="Seconds between rounds")
    p_sim.add_argument("--count", type=int, default=0, help="Rounds to send (0 = until Ctrl+C)")

    subparsers.add_parser("consume-telemetry", help="Run the Kinesis -> live fleet consumer in the foreground")

    args = parser.parse_args()

    if args.command == "version":
        print(f"HawaCommand Backend v{__version__}")
    elif args.command == "config":
        from .aws.settings import get_aws_settings

        settings = get_settings()
        aws = get_aws_settings()
        print(f"Environment: {settings.env}")
        print(f"Debug:       {settings.debug}")
        print(f"Database:    {settings.database_url}")
        print(f"Redis:       {settings.redis_url or '(off: process memory)'}")
        print(f"Kafka:       {settings.kafka_bootstrap_servers}")
        print(f"AWS:         {'enabled' if aws.enabled else 'disabled'} ({aws.region})")
        for label, value in (
            ("S3 bucket", aws.evidence_bucket), ("Grievances", aws.grievances_table), ("Fleet table", aws.fleet_table),
            ("Kinesis", aws.sensor_stream), ("SNS topic", aws.alerts_topic_arn), ("Secrets", aws.secrets_id),
            ("FCM secret", aws.fcm_secret_id), ("IoT endpoint", aws.iot_endpoint),
        ):
            print(f"  {label + ':':13} {value or '-'}")
    elif args.command == "check":
        get_settings()
        print("[OK] Configuration validated successfully.")
    elif args.command == "aws-check":
        sys.exit(aws_check(push_test=args.push_test))
    elif args.command == "simulate-fleet":
        assets = [a.strip() for a in args.assets.split(",") if a.strip()] or None
        sys.exit(simulate_fleet(args.target, args.url, assets, args.interval, args.count))
    elif args.command == "consume-telemetry":
        import logging

        from .aws.kinesis_consumer import run

        logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(name)s: %(message)s")
        bootstrap_secrets()
        try:
            asyncio.run(run())
        except KeyboardInterrupt:
            pass
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
