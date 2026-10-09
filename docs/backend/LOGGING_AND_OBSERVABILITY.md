# Logging and Observability

How every backend process logs (with **logifyx**), traces (OpenTelemetry), exports metrics (Prometheus), and reports health. Also covers the dashboards and alerts that prove the loop works during the demo.

Related: [README](README.md) · [ARCHITECTURE](ARCHITECTURE.md) · [EVENTS](EVENTS.md) · [CACHING](CACHING.md) · [DEPLOYMENT](DEPLOYMENT.md) · [STRUCTURE](STRUCTURE.md) · [../CONTRACTS.md](../CONTRACTS.md) · [../SYSTEM_OVERVIEW.md](../SYSTEM_OVERVIEW.md)

---

## 1. Goals

1. One log line format across all backend processes, JSON in containers, readable colour locally.
2. Every line answers **who** (service, user, role), **what** (event, request, task), **which loop run** (`correlation_id`), and **where in the trace** (`trace_id`, `span_id`).
3. No PII or secrets in any log, ever (§9).
4. Latency budgets from [CONTEXT.md](CONTEXT.md) §7.1 are metrics, not guesses.
5. Logs are for diagnosis. The **audit log** is the business record (§10).

## 2. logifyx

logifyx is the team's own logging library (PyPI `logifyx` 2.0.0, [github.com/Madhur-Prakash/Logifyx-Py](https://github.com/Madhur-Prakash/Logifyx-Py)). It is installed with the Kafka extra: `logifyx[kafka]` (pinned in `uv.lock`). **All backend logging goes through it.** `print` is banned (ruff `T20`), and `logging.getLogger` is banned outside `core/logging.py` (ruff `TID251`).

### 2.1 API we use

```python
from logifyx import (
    configure_logging,        # process-wide policy, called once at startup (re-calling replaces handlers, no duplicates)
    get_logify_logger,        # get_logify_logger(name, **overrides) -> named logger (singleton per name)
    ContextLoggerAdapter,     # ContextLoggerAdapter(log, {"request_id": ..., "user_id": ...}) injects context
    flush,                    # flush(timeout=5.0) -> bool: wait for queued remote/Kafka records
    shutdown,                 # flushes and stops async handlers; registered with atexit automatically
    setup_logify,             # NOT used in services (see below)
)
```

`configure_logging(level=..., output="console"|"file"|"both"|"none", log_file=..., json_mode=True, mask=True, kafka_servers=..., kafka_topic=..., schema_registry_url=..., schema_compatibility="BACKWARD")` also accepts `log_dir`, `color`, `max_bytes`, `backup_count`, `remote_url`, `yaml_file` and `reset`.

- **`setup_logify()` is not called.** It registers the logifyx logger class globally, which would change the class of loggers that third-party libraries create afterwards. We keep third-party loggers as plain stdlib loggers and route them explicitly (§2.6).
- logifyx loggers are `logging.Logger` subclasses. That is what lets our third-party bridge forward stdlib records into them (§3).

### 2.2 Configuration precedence

logifyx resolves each setting in this order: **per-logger kwargs > `configure_logging()` > environment variables > `logifyx.yaml` > defaults.**

| Source | Keys |
|---|---|
| env vars | `LOG_LEVEL`, `LOG_OUTPUT`, `LOG_FILE`, `LOG_DIR`, `LOG_COLOR`, `LOG_JSON`, `LOG_MASK`, `LOG_MAX_BYTES`, `LOG_BACKUP_COUNT`, `LOG_REMOTE`, `LOG_KAFKA_SERVERS`, `LOG_KAFKA_TOPIC`, `LOG_SCHEMA_REGISTRY`, `LOG_SCHEMA_COMPATIBILITY`; aliases `LOGIFYX_OUTPUT`, `LOGIFYX_LEVEL`, `LOGIFYX_LOG_FILE`, `LOGIFYX_LOG_DIR` |
| `backend/logifyx.yaml` | the same `LOG_*` names as keys (as in the logifyx README example, `LOG_LEVEL: INFO`); holds **baseline defaults only**: `LOG_MASK: true`, `LOG_SCHEMA_COMPATIBILITY: BACKWARD`, `LOG_KAFKA_TOPIC: hawa.logs.v1`, `LOG_MAX_BYTES`, `LOG_BACKUP_COUNT` |

Because explicit `configure_logging()` arguments beat env vars, our setup **passes a profile value only when the operator has not set the matching env var**. `LOG_LEVEL=DEBUG docker compose up api` therefore still works. In compose we use the `LOGIFYX_LEVEL` / `LOGIFYX_OUTPUT` aliases, because some third-party images in the same environment interpret `LOG_LEVEL` themselves.

### 2.3 Handlers

| Handler | Enabled by | Behaviour | Our use |
|---|---|---|---|
| Console | `output="console"` or `"both"` | stderr, coloured unless `json_mode` (json wins when both are set) | always (local colour, containers JSON) |
| Rotating file | `output="file"` or `"both"` | `ConcurrentRotatingFileHandler` (process-safe), creates dirs, UTF-8 | off by default (containers log to stdout); allowed for the on-venue laptop (`LOG_OUTPUT=both`, `LOG_DIR=./logs`) |
| Remote HTTP | `remote_url` | queue-based, retries, circuit breaker, disables after max retries | not used |
| Kafka | `kafka_servers` | aiokafka async producer, **Avro via Schema Registry**, gzip, circuit breaker | docker profile → `hawa.logs.v1` |

### 2.4 Kafka handler on AWS (PCA-24)

logifyx 2.0.0 exposes `kafka_servers`, `kafka_topic`, `schema_registry_url` and `schema_compatibility`, but **no passthrough for Kafka security settings** (SASL, TLS). Amazon MSK needs IAM (OAUTHBEARER) or SCRAM over TLS ([EVENTS.md](EVENTS.md) §2.2). Therefore:

- **AWS default:** Kafka log handler **off**. JSON logs go to stdout → CloudWatch Logs (awslogs driver) with 30 d retention.
- **Proposed contract addition (PCA-24), a logifyx enhancement:** add `kafka_security: dict | None` (or `kafka_producer_kwargs`) forwarded to the aiokafka producer, including `sasl_oauth_token_provider`. Once that ships, set `HAWA_LOG_KAFKA_ENABLED=true` on AWS and logs flow to `hawa.logs.v1` on MSK. The Schema Registry (ECS) must also authenticate to MSK.

### 2.5 Masking

`mask=True` (always on) masks values after `password=`, `token=`, `secret=`, `api_key=`, `access_key=` and `access_token=` with `****`. This is a **safety net**, not the policy. It doesn't know phone numbers, OTPs, JWTs in headers, or FCM push tokens. Our own rules (§9) mask at the call site, and a `PiiFilter` attached to our loggers is a second net.

### 2.6 Consequences of `propagate=False` (no root logger)

logifyx loggers never propagate and never attach handlers to the root logger. That keeps uvicorn, SQLAlchemy and aiokafka logs out of our handlers by default, which has three consequences:

1. **Uvicorn's access log is disabled** (`uvicorn.run(..., access_log=False, log_config=None)`). HTTP requests are logged once by our `RequestContextMiddleware` through logifyx, with request id, route template, status, duration and user (§5). Uvicorn's own startup and error messages stay (`uvicorn.error` at INFO, routed through the bridge).
2. **Third-party logs are routed deliberately.** A small stdlib handler (`_ToLogifyx`) is installed on the root logger. It forwards records at the levels below into the logifyx logger `hawa.thirdparty`, so they come out in the same JSON format with masking. Library log levels are pinned explicitly:

   | Logger | Level | Why |
   |---|---|---|
   | `uvicorn.error` | INFO | startup, shutdown, worker errors |
   | `uvicorn.access` | disabled | replaced by our middleware |
   | `sqlalchemy.engine`, `sqlalchemy.pool` | WARNING | INFO echoes SQL with parameters, which may contain PII |
   | `aiokafka` | WARNING | INFO is very chatty on rebalance |
   | `httpx`, `httpcore` | WARNING | INFO logs full URLs; the FIRMS key sits in the URL path |
   | `apscheduler` | WARNING | we log job runs ourselves |
   | `botocore`, `boto3`, `s3transfer` | WARNING | |
   | `aiomqtt` | WARNING | |
   | `asyncio` | WARNING | slow-callback warnings are useful |
   | `opentelemetry` | WARNING | exporter failures |
   | `weasyprint`, `fontTools` | ERROR | very noisy on font fallback |
   | everything else (root) | WARNING | catch-all |
3. **Tests can't rely on `caplog` for logifyx loggers.** A `logifyx_records` fixture attaches a list handler to the logifyx logger under test.

## 3. `core/logging.py` setup sketch

```python
# src/hawa_backend/core/logging.py (sketch)
from __future__ import annotations

import logging
import os
from typing import Any

from logifyx import ContextLoggerAdapter, configure_logging, flush, get_logify_logger

from hawa_backend.core import context as ctx
from hawa_backend.core.config import Settings
from hawa_backend.core.pii import PiiFilter

_PROFILES: dict[str, dict[str, Any]] = {
    "local":  {"output": "console", "color": True,  "json_mode": False},
    "docker": {"output": "console", "color": False, "json_mode": True},
    "aws":    {"output": "console", "color": False, "json_mode": True},
    "test":   {"output": "none"},
}
_ENV_NAMES = {                                  # profile key -> env vars that override it
    "level": ("LOG_LEVEL", "LOGIFYX_LEVEL"), "output": ("LOG_OUTPUT", "LOGIFYX_OUTPUT"),
    "json_mode": ("LOG_JSON",), "color": ("LOG_COLOR",), "mask": ("LOG_MASK",),
    "kafka_servers": ("LOG_KAFKA_SERVERS",), "kafka_topic": ("LOG_KAFKA_TOPIC",),
    "schema_registry_url": ("LOG_SCHEMA_REGISTRY",), "schema_compatibility": ("LOG_SCHEMA_COMPATIBILITY",),
}
_THIRD_PARTY = {
    "uvicorn.error": logging.INFO, "uvicorn.access": logging.CRITICAL + 1,
    "sqlalchemy.engine": logging.WARNING, "sqlalchemy.pool": logging.WARNING,
    "aiokafka": logging.WARNING, "httpx": logging.WARNING, "httpcore": logging.WARNING,
    "apscheduler": logging.WARNING, "botocore": logging.WARNING, "boto3": logging.WARNING,
    "s3transfer": logging.WARNING, "aiomqtt": logging.WARNING, "asyncio": logging.WARNING,
    "opentelemetry": logging.WARNING, "weasyprint": logging.ERROR, "fontTools": logging.ERROR,
}


def setup_logging(s: Settings) -> None:
    """Call once, first thing in every process (api lifespan, worker main, CLI callback)."""
    profile: dict[str, Any] = {**_PROFILES[s.log_profile], "level": s.log_level, "mask": True}
    if s.log_profile in {"docker", "aws"} and s.log_kafka_enabled:
        profile |= {
            "kafka_servers": s.kafka.bootstrap,
            "kafka_topic": "hawa.logs.v1",
            "schema_registry_url": s.schema_registry_url,
            "schema_compatibility": "BACKWARD",
        }
    # Explicit kwargs beat env vars in logifyx: only pass what the operator did not override.
    kwargs = {k: v for k, v in profile.items() if not any(os.getenv(n) for n in _ENV_NAMES.get(k, ()))}
    configure_logging(**kwargs)                          # idempotent; replaces logifyx handlers
    for name in ("hawa", "hawa.thirdparty"):
        get_logify_logger(name).addFilter(PiiFilter())   # second net after logifyx masking
    _route_third_party()


class _ToLogifyx(logging.Handler):
    """Forward stdlib records from libraries into a logifyx logger's handlers (same JSON, same masking)."""

    def __init__(self, target: logging.Logger) -> None:
        super().__init__()
        self._target = target

    def emit(self, record: logging.LogRecord) -> None:
        self._target.handle(record)


def _route_third_party() -> None:
    root = logging.getLogger()                           # the only allowed getLogger call (ruff per-file ignore)
    root.handlers[:] = [_ToLogifyx(get_logify_logger("hawa.thirdparty"))]
    root.setLevel(logging.WARNING)
    for name, level in _THIRD_PARTY.items():
        lg = logging.getLogger(name)
        lg.handlers.clear()
        lg.setLevel(level)
        lg.propagate = True


class HawaLogger:
    """Module-level logger proxy: binds the *current* context on every call."""

    __slots__ = ("_base",)

    def __init__(self, name: str) -> None:
        self._base = get_logify_logger(name)

    def _adapter(self) -> ContextLoggerAdapter:
        return ContextLoggerAdapter(self._base, ctx.log_fields())   # request/event ids + trace ids

    def _log(self, level: int, msg: str, *args: object, **kw: Any) -> None:
        if self._base.isEnabledFor(level):
            kw.setdefault("stacklevel", 3)                            # file/line of the caller, not this proxy
            self._adapter().log(level, msg, *args, **kw)

    def debug(self, msg: str, *a: object, **kw: Any) -> None: self._log(logging.DEBUG, msg, *a, **kw)
    def info(self, msg: str, *a: object, **kw: Any) -> None: self._log(logging.INFO, msg, *a, **kw)
    def warning(self, msg: str, *a: object, **kw: Any) -> None: self._log(logging.WARNING, msg, *a, **kw)
    def error(self, msg: str, *a: object, **kw: Any) -> None: self._log(logging.ERROR, msg, *a, **kw)
    def exception(self, msg: str, *a: object, **kw: Any) -> None:
        kw.setdefault("exc_info", True); self._log(logging.ERROR, msg, *a, **kw)


def get_logger(name: str) -> HawaLogger:
    return HawaLogger(name if name.startswith("hawa") else f"hawa.{name}")


def flush_logs(timeout: float = 5.0) -> bool:
    return flush(timeout=timeout)                          # called in graceful shutdown before exit
```

Usage: `log = get_logger(__name__)` at module level, then `log.info("plan_approved", extra={"plan_id": str(plan.id), "task_count": n})`. Messages are short **snake_case event names**. The details go in `extra`, never in f-strings (ruff `G004` is enabled).

## 4. Per-environment configuration

| Environment | `HAWA_LOG_PROFILE` | Output | Format | Level (`hawa.*`) | Kafka `hawa.logs.v1` | Notes |
|---|---|---|---|---|---|---|
| local (`uv run` on host) | `local` | console | colour text | DEBUG | off | fastest feedback |
| docker (compose) | `docker` | console | JSON | INFO | **on**: `kafka:19092`, Schema Registry `http://schema-registry:8081`, `BACKWARD` | `docker compose logs -f api \| jq` |
| demo laptop fallback | `docker` + `LOG_OUTPUT=both` | console + file | JSON | INFO | on | files under `./logs` survive a container crash |
| aws (ECS) | `aws` | console → CloudWatch | JSON | INFO (per-service `LOG_LEVEL` override) | off until PCA-24 | CloudWatch retention 30 d |
| tests | `test` | `none` | — | WARNING | off | the `logifyx_records` fixture captures when a test asserts on logs |
| one-off CLI (`hawa seed`, `demo-reset`) | inherits | console | per profile | INFO | off (short-lived; avoids a flush wait) | |

## 5. Request middleware (pure ASGI)

```python
# api/middleware/request_context.py (sketch)
class RequestContextMiddleware:
    """Binds request_id/correlation_id, echoes them, logs one line per request via logifyx."""

    def __init__(self, app: ASGIApp) -> None:
        self.app = app

    async def __call__(self, scope: Scope, receive: Receive, send: Send) -> None:
        if scope["type"] not in ("http", "websocket"):
            return await self.app(scope, receive, send)
        headers = Headers(scope=scope)
        request_id = valid_uuid(headers.get("x-request-id")) or str(uuid7())
        correlation_id = valid_uuid(headers.get("x-correlation-id")) or request_id
        status, started = 500, time.perf_counter()

        async def send_wrapper(message: Message) -> None:
            nonlocal status
            if message["type"] == "http.response.start":
                status = message["status"]
                message.setdefault("headers", [])
                message["headers"] += [(b"x-request-id", request_id.encode()),
                                       (b"x-correlation-id", correlation_id.encode())]
            await send(message)

        # A mutable RequestContext object: the auth dependency later sets user_id/role/ward_ids on the
        # SAME object, so the final log line below sees them even if a threadpool copied the context.
        with ctx.bind(request_id=request_id, correlation_id=correlation_id) as rc:
            try:
                await self.app(scope, receive, send_wrapper)
            finally:
                route = getattr(scope.get("route"), "path", "unmatched")
                duration_ms = round((time.perf_counter() - started) * 1000, 1)
                metrics.http_duration.labels(scope.get("method", "WS"), route, f"{status // 100}xx").observe(duration_ms / 1000)
                if route not in QUIET_ROUTES:                       # /healthz, /readyz, /metrics
                    level = logging.WARNING if status >= 500 else logging.INFO
                    log._log(level, "http_request", extra={
                        "http_method": scope.get("method"), "http_route": route, "http_status": status,
                        "duration_ms": duration_ms, "client_ip_hash": hash_ip(client_ip(scope)),
                        "user_id": rc.user_id, "role": rc.role,
                    })
```

- The auth dependency does `ctx.current().bind_principal(principal)`, which sets `user_id`, `role` and `ward_ids` on the bound object.
- The route **template** (`/v1/plans/{plan_id}/approve`) is logged, never the raw path with ids.
- Query strings are never logged (they may carry `?token=` for Flutter WebSockets).
- Only pure ASGI middlewares are used. `BaseHTTPMiddleware` runs the app in a separate task, which breaks context propagation and streaming.

## 6. Kafka consumer logging pattern

The consumer base class binds the record context around each message ([EVENTS.md](EVENTS.md) §5.2):

```python
with ctx.bind(event_id=str(env.event_id), event_type=env.type, correlation_id=str(env.correlation_id),
              causation_id=str(env.causation_id) if env.causation_id else None,
              topic=rec.topic, partition=rec.partition, offset=rec.offset, consumer_group=self.spec.group,
              is_simulated=env.is_simulated):
    ...
```

| Moment | Level | Event name | Extra fields |
|---|---|---|---|
| partitions assigned or revoked | INFO | `partitions_assigned` / `partitions_revoked` | partitions |
| event processed | DEBUG | `event_processed` | `duration_ms` |
| domain state change (in the handler) | INFO | for example `task_dispatched`, `plan_expired`, `spray_matched` | `plan_id`, `task_id`, `asset_id`, `from_status`, `to_status` |
| duplicate skipped | DEBUG | `event_duplicate` | `layer` |
| retry | WARNING | `handler_retry` | `attempt`, `delay_s`, `error_type` |
| dead-lettered | ERROR | `event_dead_lettered` | `attempts`, `error_type`, `dlq_topic` |
| batch summary (at most every 30 s) | INFO | `consumer_progress` | `processed`, `skipped`, `lag` |

Ingest logs per packet only at DEBUG, and never in production. Rejections are aggregated: the first 5 per `reason` per minute are logged at INFO (with `device_id`, `reason`, `seq`, never the payload), the rest are counted in `hawa_packets_rejected_total`.

## 7. Standard log fields

logifyx provides the timestamp, level, logger name, message and the standard record attributes. We add these through the context adapter and `extra`:

| Field | When present | Example |
|---|---|---|
| `service` | always (static, from `HAWA_SERVICE_NAME`) | `dispatch-worker` |
| `env` | always | `local`, `demo`, `pilot` |
| `version` | always (git sha from the image) | `a1b2c3d` |
| `instance` | always (hostname / ECS task id) | `ip-10-0-1-23` |
| `request_id` | HTTP | UUIDv7 |
| `correlation_id` | HTTP and events | UUIDv7 (one per loop run / saga) |
| `causation_id` | events | UUIDv7 |
| `trace_id`, `span_id` | when a span is active | 32 / 16 hex |
| `user_id`, `role` | authenticated HTTP | UUIDv7, `officer` |
| `event_id`, `event_type`, `topic`, `partition`, `offset`, `consumer_group` | consumers | |
| `plan_id`, `task_id`, `asset_id`, `device_id`, `cell_id`, `ward_id`, `alert_id`, `report_id` | domain logs | ids only |
| `is_simulated` | anything touching devices, assets, readings, interventions | `true` |
| `http_method`, `http_route`, `http_status`, `duration_ms` | request log | |
| `error_type`, `exc_info` | errors | exception class + stack |

Field names are snake_case and stable. Dashboards and CloudWatch Insights queries depend on them.

## 8. Log-level policy

| Level | Use for | Never for |
|---|---|---|
| DEBUG | per-packet, per-event detail; SQL timings; cache hits | anything needed to operate production |
| INFO | lifecycle (start, stop, config summary without secrets); one line per HTTP request; domain state transitions; job runs; batch summaries | per-packet lines |
| WARNING | retries; degraded dependency (Redis breaker open, stale feed); rejected auth attempts; rate-limit bursts; a 5xx response | expected business outcomes (a rejected plan is INFO) |
| ERROR | dead-lettered events; unhandled exceptions; an alert that failed on every channel; failed scheduled jobs | client 4xx |
| CRITICAL | the process cannot continue: invalid config, migration head mismatch, cannot bind a port | |

Defaults: `hawa.*` at INFO in containers and DEBUG locally. It is adjustable per service with `LOGIFYX_LEVEL`.

## 9. PII and secret rules

| Data | Rule | Helper |
|---|---|---|
| Phone numbers | mask to the last 4: `+91******1234` | `pii.mask_phone()` |
| Email | `o***@mcd.gov.in` | `pii.mask_email()` |
| JWTs, refresh tokens, `HAWA_INTERNAL_TOKEN`, WhatsApp / SNS / FCM credentials, API keys | **never logged**, not even masked; header values are dropped before logging | `pii.redact_headers()` |
| OTP codes | never logged, never in Kafka | — |
| FCM push tokens | last 6 characters only | `pii.mask_token()` |
| Photos, clips, PDFs, request and response bodies | never logged (log size and content type only) | — |
| Citizen report free text | length only | — |
| Driver / asset location | log `cell_id` (500 m), never lat/lon; live positions only in Redis and the DB | — |
| Client IP | hashed (`client_ip_hash`) in request logs; raw only in security events (failed login, rate-limit ban), which are kept 30 d | `pii.hash_ip()` |
| DB errors | `sqlalchemy.engine` at WARNING; statement parameters never logged (`hide_parameters=True` on the engine) | — |
| Exceptions | messages passed through `PiiFilter`; payload fields never interpolated into messages | — |

`PiiFilter` regex-masks Indian mobile numbers (`(\+?91[\s-]?)?[6-9]\d{9}`), emails and `Bearer <token>` patterns in the rendered message and in `extra` values. It is a safety net and adds microseconds per record.

## 10. Audit log vs app log

| | Audit log | App log |
|---|---|---|
| Purpose | Accountability: who approved, edited or overrode what, and what the agents said | Diagnosis |
| Path | `audit.recorded` → `hawa.audit.v1` (365 d) → `audit-writer` → `audit_log` (append-only); plus derived rows from `plan`/`task` lifecycle and `integrity.flagged` (group `audit`) | logifyx → stdout / CloudWatch / `hawa.logs.v1` (7 d) |
| Written by | services, in the same transaction as the action (outbox) | anyone |
| Retention | 365 d in monthly partitions, then Parquet 3 y (DATA_MODEL §19.1) | 7–30 d |
| Content | columns per DATA_MODEL §12.5: `actor_kind` (user / agent / service / system), `actor_id`, `actor_role`, `action` (`plan.approve`, `plan.edit`, `task.status_manual`, `auth.login`, `device.register`, `ops.offset_reset`), `subject_type`, `subject_id`, `ward_id`, `request_id`, `correlation_id`, `ip`, `user_agent`, `before`/`after`/`details`; replay-safe via `UNIQUE (event_id, occurred_at)` | operational fields (§7) |
| PII | ids, plus `ip` for security-relevant actions; never secrets or OTPs | none |
| Readers | officers (plan history), admins, evidence report | engineers |
| Guarantees | `app_rw` has INSERT + SELECT only on `audit_log`, with no UPDATE or DELETE grants (DATA_MODEL §17.7) | best effort; may be sampled |

Never answer an audit question from app logs, and never put debugging detail in the audit log.

## 11. Tracing (OpenTelemetry)

```python
# core/telemetry.py (sketch)
def setup_tracing(s: Settings, *, app: FastAPI | None = None, engine: AsyncEngine | None = None) -> None:
    if s.otel_disabled:
        return
    resource = Resource.create({"service.name": s.service_name, "service.version": s.version,
                                "deployment.environment": s.env})
    provider = TracerProvider(resource=resource, sampler=ParentBased(TraceIdRatioBased(s.otel_sample_ratio)),
                              id_generator=AwsXRayIdGenerator() if s.env_is_aws else RandomIdGenerator())
    provider.add_span_processor(BatchSpanProcessor(OTLPSpanExporter(endpoint=s.otel_endpoint)))
    trace.set_tracer_provider(provider)
    if app is not None:
        FastAPIInstrumentor.instrument_app(app, excluded_urls="healthz,readyz,metrics")
    if engine is not None:
        SQLAlchemyInstrumentor().instrument(engine=engine.sync_engine)
    RedisInstrumentor().instrument()
    HTTPXClientInstrumentor().instrument()
    # aiokafka: use the contrib instrumentor if the pinned opentelemetry-instrumentation-aiokafka is available;
    # our producer/consumer wrappers ALWAYS inject/extract traceparent themselves (below), so traces connect either way.
```

| Hop | Propagation |
|---|---|
| Browser / app → api | `traceparent` header if the client sends one; otherwise the api starts a root span |
| api → intel-service | httpx instrumentation injects `traceparent` |
| api → outbox → Kafka | the outbox writer captures `traceparent` of the current span into `outbox_event.headers`; the relay publishes it as the Kafka header |
| producer → Kafka → consumer | `propagate.inject(carrier)` into headers; the consumer base does `propagate.extract` and starts a `CONSUMER` span `"{topic} process"` with attributes `messaging.system=kafka`, `messaging.destination.name`, `messaging.kafka.consumer.group`, `messaging.kafka.message.offset`, `hawa.event_type`, `hawa.correlation_id` |
| Long sagas (hours) | not one trace: each step is its own trace **linked** to its cause (span links), and `hawa.correlation_id` ties them together in Jaeger search |

- Exporters: OTLP gRPC → Jaeger all-in-one locally (`http://jaeger:4317`, UI at http://localhost:16686). On AWS: an **ADOT collector** sidecar → AWS X-Ray, with the X-Ray-compatible id generator. The W3C `traceparent` stays the wire format in Kafka.
- Sampling: 100 % locally and in the demo. 10 % head sampling in the pilot, plus the collector's tail-sampling policy to keep all error traces and all traces with a span over 2 s.
- Logs carry `trace_id` / `span_id` (from `trace.get_current_span()`) through `ctx.log_fields()`, so Jaeger ↔ logs navigation works both ways.

## 12. Metrics (Prometheus)

`prometheus-client` with one registry per process. The api serves `/metrics` on 8000 (internal network only; the ALB doesn't route it). Workers serve it on their ops port 9100 (PCA-23). Each container runs one Uvicorn worker, so there is no multiprocess mode. Every metric is prefixed `hawa_`.

| Metric | Type | Labels | Emitted by | Meaning |
|---|---|---|---|---|
| `hawa_packets_ingested_total` | counter | `role`, `kind` (telemetry, event, spray, clip), `is_simulated` | ingest | packets stored |
| `hawa_packets_rejected_total` | counter | `reason` (CONTRACTS §4.1 codes + `malformed_payload`) | ingest | packets rejected to the DLQ |
| `hawa_dedupe_hits_total` | counter | `layer` (redis, db), `group` | ingest, consumers | duplicates absorbed |
| `hawa_ingest_latency_seconds` | histogram (0.1 … 30) | `role` | ingest | packet `ts` → DB commit |
| `hawa_e2e_packet_to_ws_seconds` | histogram (1 … 120) | `channel_kind` | api-live | packet `ts` → WebSocket publish |
| `hawa_consumer_lag` | gauge | `group`, `topic`, `partition` | every consumer | highwater − position |
| `hawa_consumer_events_total` | counter | `group`, `type`, `outcome` (ok, duplicate, skipped, retried, dlq) | consumers | |
| `hawa_consumer_handler_seconds` | histogram | `group`, `type` | consumers | |
| `hawa_consumer_last_commit_timestamp_seconds` | gauge | `group` | consumers | stuck detection |
| `hawa_outbox_lag_seconds` | gauge | — | outbox-relay | oldest unpublished row age |
| `hawa_outbox_published_total` | counter | `topic` | outbox-relay | |
| `hawa_twin_age_seconds` | gauge | — | api (from `twin:version` / `twin_run.as_of`) | freshness of the map |
| `hawa_forecast_age_seconds` | gauge | — | api | |
| `hawa_plan_draft_seconds` | histogram (1 … 600) | `mode` | api-live (`cmd.plan.draft` produced → `plan.drafted` occurred) | draft latency |
| `hawa_spike_to_draft_seconds` | histogram (5 … 600) | — | api-live | `device.spike` → `plan.drafted` (`mode=spike`, same correlation) |
| `hawa_dispatch_saga_state` | gauge | `state` (TaskStatus) | dispatch-worker (every 30 s over active plans) | tasks per state |
| `hawa_dispatch_notify_seconds` | histogram | `kind` | notifier | `alert.requested` → provider accepted |
| `hawa_task_transitions_total` | counter | `from`, `to`, `source` | dispatch-worker, api | |
| `hawa_alerts_total` | counter | `channel`, `kind`, `status` (sent, failed, dry_run) | notifier | |
| `hawa_impacts_verified_total` | counter | `verdict`, `is_simulated` | api-cache | verification outcomes |
| `hawa_ws_connections` | gauge | — | api | open WebSocket connections per replica |
| `hawa_ws_subscriptions` | gauge | `channel_kind` | api | |
| `hawa_cache_requests_total` | counter | `cache`, `result` | api | source of the cache hit ratio ([CACHING.md](CACHING.md) §15) |
| `hawa_http_request_duration_seconds` | histogram (0.005 … 10) | `method`, `route`, `status_class` | api | |
| `hawa_http_requests_total` | counter | `method`, `route`, `status` | api | |
| `hawa_intel_call_seconds` | histogram | `endpoint`, `outcome` | api | intel-service latency |
| `hawa_circuit_breaker_state` | gauge | `target` | all | 0 closed, 1 half-open, 2 open |
| `hawa_feed_last_success_timestamp_seconds` | gauge | `source` (cpcb, openaq, openmeteo, firms) | feeds-worker | staleness |
| `hawa_feed_fetch_total` | counter | `source`, `outcome` | feeds-worker | |
| `hawa_scheduler_job_runs_total` | counter | `job`, `outcome` (ran, skipped_locked, failed) | scheduler | |
| `hawa_scheduler_job_last_run_timestamp_seconds` | gauge | `job` | scheduler | |
| `hawa_devices_active` | gauge | `role`, `is_simulated` | api (from `live:device`) | devices seen in the last 5 min |
| `hawa_db_pool_in_use` | gauge | `pool` | all | SQLAlchemy pool checked-out connections |

Cardinality rule: **no** `user_id`, `device_id`, `plan_id`, `cell_id` or raw path labels. Recording rules precompute `hawa:cache_hit_ratio:5m`, `hawa:http_p95_seconds:5m` and `hawa:ingest_p95_seconds:5m`.

## 13. Dashboards (Grafana)

Provisioned from `backend/docker/local/grafana/dashboards/*.json` (datasources: Prometheus, Jaeger). The **Golden Path** dashboard is shown in the demo, in the role the CloudWatch dashboard had in the original plan (§9, §11), and mirrored as a CloudWatch dashboard on AWS.

| Dashboard | Panels |
|---|---|
| **HawaCommand: Golden Path** (demo) | packets/s split real vs simulated; ingest p95 (packet → DB); rejects by reason; dedupe hits; twin age; hotspots by cause (from the API); plans by status + `plan_draft_seconds` p95; saga states (stacked); alerts sent by channel with dry-run marked; impacts verified by verdict; consumer lag per group; WebSocket connections; API p95 and error rate; cache hit ratio |
| Kafka | lag per group and partition, produce/consume rates, DLQ rate, outbox lag, kafka-exporter broker metrics |
| API | request rate / latency / errors per route, intel calls and breaker state, rate-limit rejections, WS fan-out |
| Stores | Postgres (postgres-exporter: connections, tx/s, slow queries, partition count), Redis (memory, hit ratio, evictions, ops/s), DB pool usage |
| Feeds and scheduler | last success per source, job runs and skips, next fire times |

## 14. Alert rules

`backend/docker/local/prometheus/rules/*.yml` locally; CloudWatch alarms (from EMF metrics exported by the ADOT collector) → SNS on AWS.

| Alert | Expression (PromQL) | For | Severity |
|---|---|---|---|
| IngestStalled | `sum(rate(hawa_packets_ingested_total[5m])) == 0 and sum(hawa_devices_active) > 0` | 3 m | page |
| IngestSlow | `hawa:ingest_p95_seconds:5m > 5` | 5 m | warn |
| RejectRateHigh | `sum(rate(hawa_packets_rejected_total[5m])) / sum(rate(hawa_packets_ingested_total[5m]) + rate(hawa_packets_rejected_total[5m])) > 0.05` | 10 m | warn |
| TwinStale | `hawa_twin_age_seconds > 1200` | 5 m | page (demo-critical) |
| ForecastStale | `hawa_forecast_age_seconds > 5400` | 10 m | warn |
| ConsumerLag | per group ([EVENTS.md](EVENTS.md) §12) | 2–5 m | page / warn |
| DLQTraffic | `increase(hawa_consumer_events_total{outcome="dlq"}[10m]) > 0` | 0 m | warn |
| OutboxStuck | `hawa_outbox_lag_seconds > 30` | 1 m | page |
| ApiErrors | `sum(rate(hawa_http_requests_total{status=~"5.."}[5m])) / sum(rate(hawa_http_requests_total[5m])) > 0.02` | 5 m | page |
| ApiSlow | `hawa:http_p95_seconds:5m > 1` | 10 m | warn |
| BreakerOpen | `max by (target) (hawa_circuit_breaker_state) == 2` | 5 m | warn |
| FeedStale | `time() - hawa_feed_last_success_timestamp_seconds{source=~"cpcb\|openaq"} > 3600` | 0 m | warn |
| SchedulerMissed | `time() - hawa_scheduler_job_last_run_timestamp_seconds{job="twin_rebuild"} > 1200` | 0 m | page |
| AlertsFailing | `sum(rate(hawa_alerts_total{status="failed"}[15m])) / sum(rate(hawa_alerts_total[15m])) > 0.2` | 15 m | warn |
| RedisMemory | `redis_memory_used_bytes / redis_memory_max_bytes > 0.8` | 5 m | warn |
| NotReady | `up{job=~"hawa-.*"} == 0` or `/readyz` probe failing (blackbox) | 2 m | page |

## 15. Health probes (PCA-23)

**Proposed contract addition (PCA-23):** every worker exposes `/healthz`, `/readyz` and `/metrics` on container port 9100 (the api on 8000). It is a tiny Starlette app started by the worker runner.

| Probe | Semantics | Checks | Used by |
|---|---|---|---|
| `GET /healthz` (liveness) | "the process is alive and its event loop is responsive"; **no dependency checks**, so a DB outage never causes restart storms | event-loop lag < 2 s (a heartbeat task updates a timestamp); for workers, the main consumer task is not dead | Docker `HEALTHCHECK`, ECS container health check |
| `GET /readyz` (readiness) | "this instance can do useful work now" | DB `SELECT 1` (1 s timeout); DB `alembic_version` not **behind** the image's `ALEMBIC_HEAD` (ahead is fine, DATA_MODEL §17.11); Kafka producer metadata fresh (≤ 30 s); workers: partitions assigned or rebalance < 60 s old; api: `twin:version` pointer loaded; Redis reachable, **reported as `degraded` but still 200** | ALB target group (api), compose `depends_on: service_healthy`, `hawa demo-check` |
| `GET /metrics` | Prometheus exposition | — | Prometheus / ADOT |

Readiness body (200 or 503):

```json
{
  "status": "ready",
  "service": "ingest-worker",
  "version": "a1b2c3d",
  "checks": {
    "db": {"ok": true, "latency_ms": 2.1},
    "migrations": {"ok": true, "head": "20261110_1200_reading_partitions"},
    "kafka": {"ok": true, "assigned_partitions": 6},
    "redis": {"ok": true, "degraded": false}
  }
}
```

During graceful shutdown, `/readyz` returns 503 `{"status":"draining"}` immediately, so the ALB stops sending traffic while in-flight requests finish.

## 16. Proposed contract additions (defined here)

- **PCA-23** worker ops endpoints `/healthz`, `/readyz`, `/metrics` on port 9100.
- **PCA-24** logifyx Kafka security passthrough (`kafka_security` / `kafka_producer_kwargs`) so `hawa.logs.v1` can run on MSK; until then the AWS log path is stdout → CloudWatch.
