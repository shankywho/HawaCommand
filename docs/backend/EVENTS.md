# Events (Kafka)

Kafka in depth for HawaCommand: clusters, topic bootstrap, envelope and serde, producer and consumer design, the transactional outbox, the consumer group map, scheduler commands, the dispatch saga as choreography, replay, lag, schema evolution and debugging.

Related: [README](README.md) · [ARCHITECTURE](ARCHITECTURE.md) · [CACHING](CACHING.md) · [DATA_MODEL](DATA_MODEL.md) · [LOGGING_AND_OBSERVABILITY](LOGGING_AND_OBSERVABILITY.md) · [DEPLOYMENT](DEPLOYMENT.md) · [../CONTRACTS.md](../CONTRACTS.md) §5 · [../SYSTEM_OVERVIEW.md](../SYSTEM_OVERVIEW.md)

---

## 1. Why Kafka

The proposal buffers the stream with SQS (hackathon) and Kinesis (scale), and orchestrates with EventBridge and Step Functions (§8.1, §11). We replace both with Kafka (`../SYSTEM_OVERVIEW.md` §8):

- **One replayable log between every loop stage.** Raw telemetry kept for 7 days covers the 72 h store-and-forward window twice over. We can re-run ingest, the twin or the verifier over past data by resetting offsets.
- **Independent consumer groups.** The twin, the live map, the archiver and the audit trail each read the same topic at their own pace. SQS would need a fan-out topology per consumer.
- **Ordering per key.** Per `device_id` for packets, per `plan_id` for plan and task lifecycle, per `asset_id` for spray segments.
- **Identical semantics locally and on AWS.** The same code runs against Apache Kafka in Docker and Amazon MSK.
- Work distribution (the BullMQ role in the proposal) is covered by consumer groups, and Redis stays a cache and coordination store ([CACHING.md](CACHING.md)).

Library: **aiokafka** (latest stable, pinned in `uv.lock`), with extras for `lz4`. Delivery is at-least-once, and every consumer is idempotent.

## 2. Clusters

### 2.1 Local

| Component | Image | Role |
|---|---|---|
| Apache Kafka, KRaft single node (broker + controller) | `apache/kafka` (3.8.x, pinned) | Listeners: `INTERNAL://kafka:19092` (containers), `EXTERNAL://localhost:9092` (host tools and `uv run`), `CONTROLLER://:9093`. `auto.create.topics.enable=false`, RF 1 for internal topics |
| Confluent Schema Registry | `confluentinc/cp-schema-registry` (pinned) | Only for the logifyx Avro log topic `hawa.logs.v1`. Domain topics are JSON and don't use it |
| Kafka UI | `provectuslabs/kafka-ui` (or its maintained fork `kafbat/kafka-ui`, drop-in) | Browse topics and messages, consumer groups, lag, and Schema Registry subjects at http://localhost:8080 |

The compose definition is in [DEPLOYMENT.md](DEPLOYMENT.md) §2.

### 2.2 AWS

**Proposed contract addition (PCA-01): Amazon MSK provisioned, not MSK Serverless.** The AWS IoT Rules Kafka action supports only `SSL` and `SASL_SSL` with `PLAIN`, `SCRAM-SHA-512` or `GSSAPI`, and AWS documents that MSK Serverless (IAM-only) is not supported by that action. MSK Serverless also carries a fixed cluster-hour charge ($0.75/h, about $550 a month before partitions), which alone exceeds the §12.3 pilot envelope. The pilot therefore runs:

| Setting | Value |
|---|---|
| Cluster | MSK provisioned, `kafka.t3.small` × 2 (demo/pilot), `kafka.m7g.large` × 3 (zone scale) |
| Auth | **IAM** (port 9098) for all ECS services; **SASL/SCRAM-SHA-512** (port 9096) only for the IoT Rule, with the secret `AmazonMSK_hawa_iot_rule` (MSK requires the `AmazonMSK_` prefix and a customer-managed KMS key) |
| Encryption | TLS in transit, KMS at rest |
| Topic configs | RF 3 (RF 2 on a 2-broker cluster), `min.insync.replicas=2` (1 on 2 brokers), `auto.create.topics.enable=false` |
| Schema Registry | `cp-schema-registry` as an ECS service, storing into MSK (needs the `aws-msk-iam-auth` jar in a thin custom image), or disabled if the logs topic is off on AWS (PCA-24) |

### 2.3 Client authentication in code

```python
# events/msk_auth.py (sketch)
from aiokafka.abc import AbstractTokenProvider
from aiokafka.helpers import create_ssl_context
from aws_msk_iam_sasl_signer import MSKAuthTokenProvider

class MSKIamTokenProvider(AbstractTokenProvider):
    def __init__(self, region: str) -> None:
        self._region = region

    async def token(self) -> str:
        token, _expiry_ms = await asyncio.to_thread(MSKAuthTokenProvider.generate_auth_token, self._region)
        return token

def kafka_security(s: KafkaSettings) -> dict[str, Any]:
    match s.security:                                  # HAWA_KAFKA_SECURITY
        case "iam":
            return {"security_protocol": "SASL_SSL", "sasl_mechanism": "OAUTHBEARER",
                    "sasl_oauth_token_provider": MSKIamTokenProvider(s.aws_region),
                    "ssl_context": create_ssl_context()}
        case "scram":
            return {"security_protocol": "SASL_SSL", "sasl_mechanism": "SCRAM-SHA-512",
                    "sasl_plain_username": s.username, "sasl_plain_password": s.password.get_secret_value(),
                    "ssl_context": create_ssl_context()}
        case _:
            return {"security_protocol": "PLAINTEXT"}
```

## 3. Envelope, serde and headers

### 3.1 Envelope

Exactly [CONTRACTS §5.1](../CONTRACTS.md#51-envelope). The Pydantic model lives in `hawa_contracts/envelope.py`:

```python
T = TypeVar("T", bound=BaseModel)

class Envelope(BaseModel, Generic[T]):
    model_config = ConfigDict(extra="ignore", frozen=True)   # consumers tolerate additive fields
    event_id: UUID                     # UUIDv7 (see §3.4)
    type: str                          # e.g. "plan.approved"
    version: int = 1
    source: str                        # producing service, e.g. "api", "dispatch-worker"
    occurred_at: AwareDatetime         # when it happened (UTC)
    produced_at: AwareDatetime         # when it was serialised
    correlation_id: UUID               # one per loop run / saga
    causation_id: UUID | None = None   # event_id or request_id that caused this
    subject: str                       # "plan:<id>", "device:HPM-0142", "run:<id>"
    is_simulated: bool
    data: T

    @classmethod
    def build(cls, data: T, *, type: str, version: int, subject: str, is_simulated: bool,
              ctx: EventContext, event_id: UUID | None = None, occurred_at: datetime | None = None) -> "Envelope[T]": ...
```

Every event payload model (`hawa_contracts/events/*.py`) declares `TYPE: ClassVar[str]` and `VERSION: ClassVar[int]`, and registers itself in `hawa_contracts.events.REGISTRY: dict[tuple[str, int], type[BaseModel]]`.

### 3.2 Headers

| Header | Value | Set by |
|---|---|---|
| `content-type` | `application/json` | producer wrapper |
| `hawa-type` | envelope `type` | producer wrapper |
| `hawa-version` | envelope `version` | producer wrapper |
| `traceparent` | W3C trace context of the producing span (`00-<trace_id>-<span_id>-<flags>`) | producer wrapper via `opentelemetry.propagate.inject` |
| `tracestate` | if present | same |
| DLQ headers | §5.4 | consumer base on dead-letter |

Consumers route on `hawa-type` before deserialising the body, so a handler that doesn't care about a type never pays to parse it.

### 3.3 Raw ingress encodings (PCA-02)

**Proposed contract addition (PCA-02).** `hawa.telemetry.raw.v1` accepts two encodings, because the AWS IoT Rule cannot build our envelope exactly (it has no UUIDv7 and no nested object assembly we can rely on):

| Encoding | Produced by | Value | Headers |
|---|---|---|---|
| **Envelope** | `mqtt-bridge` | `{event_id, type: "telemetry.raw", ..., data: {topic, payload, received_at}}`, where `payload` is the parsed packet object | standard |
| **Bare packet** | IoT Rule Kafka action (one rule per MQTT suffix) | the packet JSON as published | `hawa-type` (static per rule, e.g. `telemetry.raw`), `hawa-mqtt-topic: ${topic()}`, `hawa-received-at: ${timestamp()}`; message key `${topic(3)}` (the device id) |

Rules for the raw topic:
- The raw `event_id` may be absent or a UUIDv4. Ingest dedupes on `(device_id, seq)`, never on the raw `event_id`.
- The raw `is_simulated` is **advisory and ignored**. Ingest derives it from `device.is_simulated` ([CONTEXT.md](CONTEXT.md) §6).
- Unparseable JSON is rejected to `hawa.telemetry.dlq.v1` with the new reason code `malformed_payload`.

### 3.4 Event ids (PCA-11)

- Events created by a service decision (API, dispatch, scheduler, feeds) get `uuid7()` at creation time, **after** the aggregate row lock is taken, so ids are monotonic per aggregate (§6.3).
- **Proposed contract addition (PCA-11):** events **derived from a packet** (`reading.cleaned`, `reading.rejected`, `device.*`, `spray.started`, `spray.stopped`) use a deterministic UUIDv7. Its timestamp field is the packet `ts` and its random bits come from `sha256(device_id, seq, type)`. A crash-and-retry therefore republishes the *same* `event_id`, and downstream idempotency absorbs it.

```python
# hawa_contracts/ids.py
def uuid7_deterministic(ts: datetime, *parts: str) -> UUID:
    ms = int(ts.timestamp() * 1000) & ((1 << 48) - 1)
    h = hashlib.sha256("\x1f".join(parts).encode()).digest()
    rand_a = int.from_bytes(h[0:2], "big") & 0x0FFF
    rand_b = int.from_bytes(h[2:10], "big") & ((1 << 62) - 1)
    return UUID(int=(ms << 80) | (0x7 << 76) | (rand_a << 64) | (0b10 << 62) | rand_b)
```

### 3.5 Serde

```python
# events/serde.py (sketch)
def encode(env: Envelope[Any]) -> tuple[bytes, list[tuple[str, bytes]]]:
    value = orjson.dumps(env.model_dump(mode="json"))
    headers = [("content-type", b"application/json"),
               ("hawa-type", env.type.encode()),
               ("hawa-version", str(env.version).encode())]
    carrier: dict[str, str] = {}
    propagate.inject(carrier)                                   # traceparent / tracestate
    headers += [(k, v.encode()) for k, v in carrier.items()]
    return value, headers

def decode(rec: ConsumerRecord) -> Envelope[Any]:
    hdr = {k: v.decode() for k, v in (rec.headers or ())}
    etype, ever = hdr.get("hawa-type"), int(hdr.get("hawa-version", "1"))
    model = REGISTRY.get((etype, ever))
    if model is None:
        if etype and any(t == etype for t, _ in REGISTRY):     # known type, newer version
            raise PoisonMessage("unsupported_version")
        raise UnknownType(etype)                               # ack and skip, counted
    try:
        raw = orjson.loads(rec.value)
        return Envelope[model].model_validate(raw)             # type: ignore[valid-type]
    except (orjson.JSONDecodeError, ValidationError) as exc:
        raise PoisonMessage("invalid_envelope") from exc
```

Producers build payloads with typed models (so mistakes fail at build time). Consumers parse with `extra="ignore"` (tolerant to additive fields).

## 4. Topics and bootstrap

### 4.1 Topic registry

`hawa_contracts/topics.py` is the single source of topic names, keys, partitions, retention and consumer group names. It mirrors [CONTRACTS §5.2](../CONTRACTS.md#52-topics) plus the proposed topics in §8.

```python
@dataclass(frozen=True, slots=True)
class TopicSpec:
    name: str
    key: str                              # documentation of the key field
    retention: timedelta
    partitions_local: int = 3
    partitions_aws: int = 6
    event_types: tuple[str, ...] = ()
    serde: Literal["json", "avro"] = "json"

TELEMETRY_RAW   = TopicSpec("hawa.telemetry.raw.v1",   "device_id", timedelta(days=7),  6, 12,
                            ("telemetry.raw", "device_event.raw", "spray.raw", "clip.raw"))
TELEMETRY_CLEAN = TopicSpec("hawa.telemetry.clean.v1", "device_id", timedelta(days=3),  6, 12, ("reading.cleaned",))
TELEMETRY_DLQ   = TopicSpec("hawa.telemetry.dlq.v1",   "device_id", timedelta(days=14), 3, 6,  ("reading.rejected",))
PLAN_LIFECYCLE  = TopicSpec("hawa.plan.lifecycle.v1",  "plan_id",   timedelta(days=30), 3, 6, (...))
# ... every topic in CONTRACTS §5.2, plus CMD_DISPATCH, CMD_ALERT, CMD_MAINTENANCE (PCA-03..05)
LOGS            = TopicSpec("hawa.logs.v1", "service", timedelta(days=7), 3, 6, (), serde="avro")

TOPICS: tuple[TopicSpec, ...] = (TELEMETRY_RAW, TELEMETRY_CLEAN, ...)

class Group(StrEnum):                     # CONTRACTS §5.2 consumer groups
    INGEST = "ingest"; INGEST_CALIBRATION = "ingest-calibration"
    API_LIVE = "api-live"; API_CACHE = "api-cache"; API_ALERT_STATUS = "api-alert-status"
    DISPATCH = "dispatch"; NOTIFIER = "notifier"; ALERT_ENGINE = "alert-engine"; DEVICE_HEALTH = "device-health"
    AUDIT_WRITER = "audit-writer"; AUDIT = "audit"; EVIDENCE_REPORT = "evidence-report"; ARCHIVER = "archiver"; OPS = "ops"
    # intel-* groups are declared here too so AI-ML imports the same constants
```

Replication factor: 1 locally, 3 on AWS (2 on a 2-broker demo cluster). `min.insync.replicas` = RF − 1 (minimum 1).

### 4.2 `hawa kafka-init`

```text
uv run hawa kafka-init [--profile local|aws] [--dry-run] [--check]
```

1. Connect with `AIOKafkaAdminClient` using `kafka_security()`.
2. For each `TopicSpec` in `TOPICS`:
   - If it is missing, `create_topics([NewTopic(name, partitions, rf, topic_configs={"retention.ms": ..., "cleanup.policy": "delete", "min.insync.replicas": ...})])`.
   - If it exists, `describe_configs` and `alter_configs` for any retention drift. If the spec has more partitions than the topic, **warn**, and only add partitions with `--grow-partitions` (it changes the key → partition mapping, so do it in a maintenance window). If the spec has fewer, warn and do nothing (Kafka cannot shrink partitions).
3. `--check` exits 1 on any drift. CI runs it against the testcontainers broker, and the one-off ECS task runs it before each deploy.
4. It is idempotent: running it twice is a no-op. The `kafka-init` compose service runs it once on `make up`.

## 5. Producers and consumers

### 5.1 Producer

One `AIOKafkaProducer` per process (`events/producer.py`), started in the lifespan or worker startup and flushed on shutdown.

| Setting | Value | Why |
|---|---|---|
| `acks` | `"all"` | no loss on leader failover |
| `enable_idempotence` | `True` | no duplicates from producer retries; per-partition order preserved |
| `compression_type` | `"lz4"` | cheap CPU, good ratio on JSON (logifyx uses gzip for its own topic) |
| `linger_ms` | 5 (api, dispatch, notifier); 20 (ingest, mqtt-bridge, outbox-relay) | latency vs batching |
| `max_batch_size` | 256 KiB | |
| `max_request_size` | 1 MiB | envelopes are small; bigger means a bug |
| `request_timeout_ms` | 30 000 | |
| `client_id` | `{service}-{hostname}` | visible in broker logs and Kafka UI |

`Producer.publish(topic: TopicSpec, key: str, env: Envelope)` awaits the delivery future (fail fast). `publish_many` sends a batch and gathers the futures. Only the ingest hot path, the mqtt-bridge, the scheduler (commands) and the outbox relay call the producer directly. **The API never produces inside a request** ([CONTRACTS §5.1](../CONTRACTS.md#51-envelope)).

### 5.2 Consumer base class

```python
# events/consumer.py (sketch)
class Idempotency(StrEnum):
    DB = "db"          # Redis fast path + processed_event row in the SAME transaction as side effects
    REDIS = "redis"    # fast path only; side effects are idempotent by construction (upserts)
    NONE = "none"      # live fan-out; duplicates are harmless (api-live)

@dataclass(frozen=True)
class ConsumerSpec:
    group: Group
    topics: tuple[TopicSpec, ...]
    idempotency: Idempotency = Idempotency.DB
    max_attempts: int = 5
    backoff_initial_s: float = 0.2
    backoff_max_s: float = 5.0
    max_records: int = 200
    auto_offset_reset: Literal["earliest", "latest"] = "earliest"
    max_event_age_s: float | None = None        # api-live: 60

class KafkaConsumerBase(ABC):
    spec: ClassVar[ConsumerSpec]
    handlers: ClassVar[Mapping[str, str]]       # event type -> method name, e.g. {"plan.approved": "on_plan_approved"}

    def __init__(self, c: Container) -> None:
        self._c, self._stopping, self._lock = c, asyncio.Event(), asyncio.Lock()
        self._next_offsets: dict[TopicPartition, int] = {}

    async def run(self) -> None:
        self._consumer = AIOKafkaConsumer(
            bootstrap_servers=self._c.settings.kafka.bootstrap, group_id=self.spec.group,
            client_id=f"{self.spec.group}-{socket.gethostname()}",
            enable_auto_commit=False, auto_offset_reset=self.spec.auto_offset_reset,
            max_poll_records=self.spec.max_records, max_poll_interval_ms=300_000,
            session_timeout_ms=30_000, heartbeat_interval_ms=3_000,
            isolation_level="read_committed", **kafka_security(self._c.settings.kafka))
        self._consumer.subscribe([t.name for t in self.spec.topics], listener=_Rebalance(self))
        await self._consumer.start()
        try:
            while not self._stopping.is_set():
                batches = await self._consumer.getmany(timeout_ms=500, max_records=self.spec.max_records)
                async with self._lock:                               # rebalance waits for the batch
                    for tp, records in batches.items():
                        for rec in records:                           # sequential per partition = ordered
                            await self._process_with_retry(rec)
                            self._next_offsets[tp] = rec.offset + 1
                        await self._commit([tp])                     # commit only after success or DLQ
        finally:
            async with self._lock:
                await self._commit(list(self._next_offsets))
            await self._consumer.stop()

    async def _process_with_retry(self, rec: ConsumerRecord) -> None:
        with log_ctx.bind_record(rec, group=self.spec.group):          # event_id, topic, partition, offset ...
            try:
                env = serde.decode(rec)
            except UnknownType:
                metrics.events_skipped.labels(self.spec.group, rec.topic).inc(); return
            except PoisonMessage as exc:
                await self._dead_letter(rec, exc, attempts=0); return
            if (method := self.handlers.get(env.type)) is None or self._is_stale(env):
                return
            for attempt in range(1, self.spec.max_attempts + 1):
                try:
                    with tracing.consumer_span(rec, env):                # extracts traceparent
                        await self._process_once(env, getattr(self, method))
                    return
                except PoisonMessage as exc:
                    await self._dead_letter(rec, exc, attempts=attempt); return
                except Exception as exc:                                  # noqa: BLE001 - classified below
                    if attempt == self.spec.max_attempts or not is_retryable(exc):
                        await self._dead_letter(rec, exc, attempts=attempt); return
                    delay = min(self.spec.backoff_max_s, self.spec.backoff_initial_s * 2 ** (attempt - 1))
                    log.warning("handler_retry", extra={"attempt": attempt, "delay_s": delay, "error_type": type(exc).__name__})
                    await asyncio.sleep(delay * random.uniform(0.5, 1.5))

    async def _process_once(self, env: Envelope[Any], handler: Callable[..., Awaitable[None]]) -> None:
        mode, key = self.spec.idempotency, keys.dedupe_evt(self.spec.group, env.event_id)
        if mode is not Idempotency.NONE and await self._c.cache.exists_safe(key):   # Redis down -> False
            metrics.dedupe_hits.labels(layer="redis", group=self.spec.group).inc(); return
        if mode is Idempotency.DB:
            async with self._c.uow_factory() as uow:
                if not await uow.processed_events.claim(self.spec.group, env.event_id):  # INSERT .. ON CONFLICT DO NOTHING
                    metrics.dedupe_hits.labels(layer="db", group=self.spec.group).inc(); return
                await handler(env, uow)                                   # side effects + outbox rows
                await uow.commit()                                        # one transaction
        else:
            await handler(env, None)
        if mode is not Idempotency.NONE:
            await self._c.cache.set_safe(key, b"1", ex=86_400)            # dedupe:evt TTL 24 h

class _Rebalance(ConsumerRebalanceListener):
    def __init__(self, owner: KafkaConsumerBase) -> None: self._o = owner
    async def on_partitions_revoked(self, revoked: set[TopicPartition]) -> None:
        async with self._o._lock:                                          # wait for the in-flight batch
            await self._o._commit(list(revoked))
            for tp in revoked: self._o._next_offsets.pop(tp, None)
    async def on_partitions_assigned(self, assigned: set[TopicPartition]) -> None:
        log.info("partitions_assigned", extra={"partitions": sorted(f"{tp.topic}:{tp.partition}" for tp in assigned)})
```

A worker declares only its spec and handlers:

```python
class DispatchConsumer(KafkaConsumerBase):
    spec = ConsumerSpec(group=Group.DISPATCH,
                        topics=(PLAN_LIFECYCLE, TASK_LIFECYCLE, INTERVENTION_SEGMENT, IMPACT_VERIFIED,
                                REPORT_LIFECYCLE, CMD_DISPATCH))
    handlers = {"plan.approved": "on_plan_approved", "plan.rejected": "on_plan_rejected",
                "cmd.dispatch.release": "on_release", "cmd.dispatch.sweep": "on_sweep",
                "spray.started": "on_spray_started", "spray.stopped": "on_spray_stopped",
                "task.done": "on_app_task_update", "task.skipped": "on_app_task_update",
                "impact.verified": "on_impact_verified", "report.verified": "on_report_verified"}
```

### 5.3 Idempotency

| Layer | Key | Scope | Durable? |
|---|---|---|---|
| Fast path | Redis `dedupe:evt:{group}:{event_id}` (24 h) | skip obvious redeliveries without a DB round-trip | no; Redis may be down or evicted |
| Durable | `processed_event (consumer_group, event_id)` primary key, inserted **in the same transaction** as the handler's side effects and outbox rows | exactly-once *effects* per group | yes |
| Domain | natural keys and state checks (for example `plan_task` transition allowed only from the expected state; `alert` unique `(school_id, date, phase)`; `impact` unique per `(intervention_id, pollutant)`) | defence in depth, and the only layer for `Idempotency.REDIS` handlers | yes |

`processed_event` rows are purged after 35 days by the nightly retention step (DATA_MODEL §13.2, §19.1). That is longer than any topic retention the handler reads from, except the 90 d topics, whose consumers (`api-cache`, `api-live`, `dispatch`) also rely on domain state checks.

The ingest hot path is special. It dedupes packets on `(device_id, seq)` with Redis `dedupe:pkt:*` plus the `reading` unique constraint ([ARCHITECTURE.md](ARCHITECTURE.md) §5.1), not on `event_id`.

### 5.4 Retries and dead-lettering (PCA-10)

- **Retryable:** `OperationalError`, `DBAPIError` with connection or serialization failures, `asyncio.TimeoutError`, `httpx.TransportError`, Redis `ConnectionError` inside a handler that requires Redis, and `RetryableError` raised explicitly.
- **Non-retryable:** `PoisonMessage`, `ValidationError`, `IntegrityError` (a constraint violation other than the claim), `InvalidTransition` (logged at INFO; the message is acked, not DLQ'd, because an illegal transition is an expected race).
- Attempts are bounded in process (default 5, 0.2 s → 5 s with jitter). The partition is blocked during retries (this preserves order) and the budget is kept far below `max_poll_interval_ms`.
- After the last attempt, the original key and value are published to **`hawa.dlq.v1`** with these headers:

| Header | Meaning | Status |
|---|---|---|
| `hawa-dlq-topic` | original topic | CONTRACTS |
| `hawa-dlq-group` | consumer group that failed | CONTRACTS |
| `hawa-dlq-error` | error message (truncated to 1 KB, masked) | CONTRACTS |
| `hawa-dlq-error-type` | exception class | **PCA-10** |
| `hawa-dlq-partition`, `hawa-dlq-offset` | original coordinates | **PCA-10** |
| `hawa-dlq-attempts` | attempts made | **PCA-10** |
| `hawa-dlq-failed-at` | UTC ISO-8601 | **PCA-10** |

  All original headers (including `traceparent`) are copied. Only then is the offset committed.
- Telemetry validation failures are **not** consumer errors. Ingest publishes `reading.rejected` to `hawa.telemetry.dlq.v1` as normal output.

### 5.5 Poison messages

A poison message can never succeed: undecodable JSON, an envelope that fails validation, or an unsupported version. The base class sends it to `hawa.dlq.v1` immediately with `attempts=0` and increments `hawa_consumer_poison_total{group,topic}`. It never blocks the partition. An unknown `hawa-type` (a producer running a newer contract) is **skipped and counted**, not DLQ'd.

### 5.6 Rebalance and shutdown

- The revoke callback waits for the in-flight batch (shared `asyncio.Lock`), commits the offsets processed so far, and forgets the revoked partitions. Nothing is processed twice unless the process crashes. After a crash, idempotency covers the replay.
- On shutdown (SIGTERM), the worker sets `_stopping`, lets the current batch finish, commits, and calls `consumer.stop()` (which leaves the group cleanly and triggers an immediate rebalance). Then it flushes the producer and logifyx ([ARCHITECTURE.md](ARCHITECTURE.md) §8).
- `session_timeout_ms=30000` and `heartbeat_interval_ms=3000`. aiokafka heartbeats from a background task, so a long handler doesn't cause a rebalance while it stays under `max_poll_interval_ms`.

### 5.7 Ordering guarantees

| Guarantee | Holds because |
|---|---|
| Packets of one device are ingested in `seq` order within a partition | key `device_id`; sequential processing per partition |
| Lifecycle events of one plan (plan and task topics) are each ordered | key `plan_id` on both topics |
| `spray.started` precedes `spray.stopped` for one asset | key `asset_id` |
| **No** ordering across topics | the saga reads DB state, and handlers are state checks. Early or late events are parked (for example, an unmatched segment is re-matched by the sweep) |
| Outbox publish order equals commit order per aggregate | §6.3 |

## 6. Transactional outbox

### 6.1 Table

Shape below; [DATA_MODEL.md](DATA_MODEL.md) is authoritative.

```sql
-- DATA_MODEL.md §13.1 (authoritative)
CREATE TABLE hawa.outbox_event (
  id            uuid        PRIMARY KEY,                -- = envelope.event_id (UUIDv7)
  topic         text        NOT NULL CHECK (topic LIKE 'hawa.%'),
  key           text        NOT NULL,                   -- Kafka message key (CONTRACTS §5.2)
  type          text        NOT NULL,                   -- e.g. plan.approved
  envelope      jsonb       NOT NULL,                   -- full CONTRACTS §5.1 envelope
  headers       jsonb       NOT NULL DEFAULT '{}',      -- traceparent captured at write time
  available_at  timestamptz NOT NULL DEFAULT now(),     -- delayed publish when needed
  published_at  timestamptz,
  attempts      smallint    NOT NULL DEFAULT 0,
  last_error    text
);
CREATE INDEX ix_outbox_event_unpublished ON hawa.outbox_event (available_at, id) WHERE published_at IS NULL;
```

### 6.2 Writer and relay

```python
# events/outbox.py (sketch), used through the UnitOfWork
class Outbox:
    def __init__(self, session: AsyncSession, ctx: EventContext) -> None:
        self._s, self._ctx = session, ctx

    def add(self, topic: TopicSpec, key: str, event: EventPayload, *, subject: str,
            is_simulated: bool, available_at: datetime | None = None) -> UUID:
        env = Envelope.build(event, type=event.TYPE, version=event.VERSION, subject=subject,
                             is_simulated=is_simulated, ctx=self._ctx)    # uuid7() generated now, under the row lock
        self._s.add(OutboxEvent(id=env.event_id, topic=topic.name, key=key, type=env.type,
                                envelope=env.model_dump(mode="json"), headers=tracing.capture(),
                                available_at=available_at or self._ctx.now))
        self._notify = True                     # the UoW issues NOTIFY hawa_outbox before COMMIT
        return env.event_id
```

```python
# events/relay.py (sketch): runs in the outbox-relay process
RELAY_SQL = text("""
  SELECT id, topic, key, envelope, headers
  FROM hawa.outbox_event
  WHERE published_at IS NULL AND available_at <= now()
  ORDER BY available_at, id
  LIMIT :n
  FOR UPDATE SKIP LOCKED
""")

async def relay_once(sf: async_sessionmaker[AsyncSession], producer: Producer, n: int = 500) -> int:
    async with sf() as s, s.begin():
        rows = (await s.execute(RELAY_SQL, {"n": n})).all()
        if not rows:
            return 0
        futs = [await producer.send_raw(r.topic, key=r.key, envelope_json=r.envelope, extra_headers=r.headers)
                for r in rows]
        await asyncio.gather(*futs)          # any failure raises -> transaction rolls back -> rows retried
        await s.execute(text("UPDATE hawa.outbox_event SET published_at = now(), attempts = attempts + 1 "
                             "WHERE id = ANY(:ids)"), {"ids": [r.id for r in rows]})
    return len(rows)

async def relay_forever(...):
    while not stopping.is_set():
        sent = await relay_once(...)
        if sent < 500:
            await wait_for_notify_or(timeout=0.2)   # LISTEN hawa_outbox (DATA_MODEL §13.1), else a 200 ms poll
```

- **At-least-once.** If the relay crashes after the publish and before the commit, the rows are published again. Consumers dedupe on `event_id`.
- **Housekeeping.** Published rows older than 7 days are deleted by the nightly retention step of `hawa partitions` (DATA_MODEL §19.1). Metric `hawa_outbox_lag_seconds` = `now − min(available_at) where published_at is null and available_at <= now`.
- Rows whose publish keeps failing (for example, the topic is missing) get `attempts` and `last_error` updated in a separate transaction. The relay alerts when the oldest unpublished row is more than 30 s old.

### 6.3 Ordering per aggregate

Every state transition locks its aggregate row first (`SELECT ... FOR UPDATE` on `plan`, `plan_task`, `alert` …) and only then generates the event id. Two transactions on the same aggregate therefore commit in id order, with `available_at = now()` at write time. The relay reads committed rows `ORDER BY available_at, id`, and the idempotent producer preserves per-partition order. Rows written with a future `available_at` (delayed publish) are the only exception, so don't use delayed publish for events whose order matters. The default is one relay replica. To run N relays, shard by `hashtext(key) % N` (each relay filters its shard). The message key is the ordering unit on the topic, and `SKIP LOCKED` across shards would otherwise reorder a single key.

## 7. Consumer group map

Backend groups first, then AI-ML groups (owned by [../aiml/](../aiml/)) for completeness.

| Consumer group | Process | Topics | Idempotency | Side effects |
|---|---|---|---|---|
| `ingest` | ingest-worker | `hawa.telemetry.raw.v1` | packet dedupe (`dedupe:pkt` MGET, `pk_reading`; DATA_MODEL §14.2) | `reading`, `device_event`, `intervention` (HawaTag open/close), `device.last_seen`; `live:device:*`, `live:fleet`; publishes `reading.cleaned`, `reading.rejected`, `device.*`, `spray.*` |
| `ingest-calibration` | ingest-worker | `hawa.external.observation.v1` | DB (upsert on `(device_id, station_id, minute_ts)`) | `calibration_pair` rows (PCA-15) |
| `api-live` | api | `hawa.telemetry.clean.v1`, `hawa.device.event.v1`, `hawa.intervention.segment.v1`, `hawa.twin.updated.v1`, `hawa.hotspot.updated.v1`, `hawa.forecast.issued.v1`, `hawa.plan.lifecycle.v1`, `hawa.task.lifecycle.v1`, `hawa.impact.verified.v1`, `hawa.report.lifecycle.v1`, `hawa.integrity.flag.v1`, **`hawa.alert.requested.v1` (PCA-06)** | none (`latest`, drop > 60 s) | Redis `PUBLISH ws:{channel}` / `ws:user:{user_id}`; 1 Hz fleet batches |
| `api-cache` | api | `hawa.twin.updated.v1`, `hawa.hotspot.updated.v1`, `hawa.forecast.issued.v1`, `hawa.impact.verified.v1` | redis | pre-warm tiles, `SET twin:version`, bump/invalidate `cache:*` versions |
| `api-alert-status` | api | `hawa.alert.delivery.v1` | DB | `alert.status` roll-up (queued → sent → delivered / failed / read) |
| `dispatch` | dispatch-worker | `hawa.plan.lifecycle.v1`, **`hawa.task.lifecycle.v1` (PCA-06, app-originated only)**, `hawa.intervention.segment.v1`, `hawa.impact.verified.v1`, `hawa.report.lifecycle.v1`, **`hawa.cmd.dispatch.v1` (PCA-03)** | DB | plan/task transitions and plan roll-up (from app-originated task events too), intervention link + `verify_after` + `verification_status`, inspection tickets, alerts; outbox `plan.*`, `task.*`, `alert.requested`, `report.ticketed`, `cmd.verify.run` (manual interventions are created by the api, API.md §7) |
| `notifier` | notifier | `hawa.alert.requested.v1`, `hawa.task.lifecycle.v1`, `hawa.report.lifecycle.v1` | DB (+ `alert_delivery` claim row per `(alert_id, channel, attempt)`, DATA_MODEL §10.2) | provider sends; `alert_delivery`; outbox `alert.sent/failed/delivered`. `task.*` is used to cancel pending escalations (ack, cancel, skip); `report.*` renders acknowledgement and outcome messages |
| `alert-engine` | alert-engine | `hawa.hotspot.updated.v1`, `hawa.forecast.issued.v1`, **`hawa.cmd.alert.v1` (PCA-04)** | DB | `alert` rows + outbox `alert.requested` (school safe windows, pollutant warnings, GRAP outlook to officers) |
| `device-health` | alert-engine (**PCA-26**) | `hawa.device.event.v1` | DB | `device.status`, `device.trust_score` (from `device.trust_changed`), `device.cal_*` + `calibration_version` (from `device.calibrated`, DATA_MODEL §5.1), device-health alerts; publishes `hawa:{env}:inv:device` |
| `audit-writer` | audit-writer | `hawa.audit.v1` | DB | `audit_log` INSERT |
| `audit` | audit-writer (**PCA-26**; suggest merging into `audit-writer`) | `hawa.plan.lifecycle.v1`, `hawa.task.lifecycle.v1`, `hawa.integrity.flag.v1` | DB | derived `audit_log` rows (agent drafts, system transitions, integrity flags) |
| `evidence-report` | evidence-report | `hawa.cmd.report.v1` | DB | PDF to S3, `evidence_report` row |
| `archiver` | archiver | `hawa.telemetry.clean.v1`, **`hawa.cmd.maintenance.v1` (PCA-05)** | redis (Parquet files keyed by partition + offset range) | on `cmd.partitions.maintain`: `hawa partitions` (all partitioned tables, archive with verified manifest to `archive/{table}/dt=…`, detach, drop, row retention; DATA_MODEL §14.3, §19.1) using the owner login; `cmd.snapshot.freeze`; optional streaming Parquet `lake/stream/readings/dt=YYYY-MM-DD/hour=HH/part-{partition}-{first_offset}.parquet` for fresher training data (cut rule 7) |
| `archiver-raw` (optional, **PCA-25**) | archiver | `hawa.telemetry.raw.v1` | redis | raw JSONL.gz archive in S3 |
| `ops` | `hawa dlq` CLI, Kafka UI | `hawa.telemetry.dlq.v1`, `hawa.dlq.v1` | none | inspection and replay only; never committed by a long-running service |
| `intel-twin-live` | AI-ML intel-worker | `hawa.telemetry.clean.v1` | AI-ML | live twin points |
| `intel-twin` | AI-ML | `hawa.external.observation.v1`, `hawa.external.weather.v1`, `hawa.cmd.twin.v1` | AI-ML | `twin_run`, `cell_state`, `hotspot` |
| `intel-forecast` | AI-ML | `hawa.external.weather.v1`, `hawa.cmd.forecast.v1` | AI-ML | `forecast_run`, `forecast`, `grap_outlook`, `school_safe_window` |
| `intel-attribution` | AI-ML | `hawa.external.fire.v1` | AI-ML | fire features |
| `intel-spike` | AI-ML | `hawa.device.event.v1` | AI-ML | spike fingerprint; may emit `cmd.plan.draft` (`mode=spike`) |
| `intel-plan` | AI-ML | `hawa.cmd.plan.v1`, `hawa.twin.updated.v1` (spike mode) | AI-ML | `plan`, `plan_task`, `plan_review` |
| `intel-verify-scheduler` | AI-ML | `hawa.intervention.segment.v1`, `hawa.task.lifecycle.v1` | AI-ML | donor pre-selection (AI-ML doc) |
| `intel-verify` | AI-ML | `hawa.cmd.verify.v1` | AI-ML | `impact`, `effectiveness_library` |
| `intel-trainer` | AI-ML | `hawa.cmd.train.v1` | AI-ML | model versions |
| `intel-vision` | AI-ML | `hawa.report.lifecycle.v1` | AI-ML | `citizen_report` verification fields |

**Producer additions (PCA-07):**
- intel-worker also produces `device.calibrated` and `device.trust_changed` on `hawa.device.event.v1` (CONTRACTS lists only ingest-worker).
- The api produces `alert.delivered` and `alert.read` on `hawa.alert.delivery.v1` from WhatsApp status webhooks (CONTRACTS lists only the notifier).

## 8. Scheduler → commands

The `scheduler` runs APScheduler (latest stable 3.x `AsyncIOScheduler`, pinned) with `CronTrigger(timezone="Asia/Kolkata")`, `coalesce=True`, `max_instances=1` and `misfire_grace_time=60`. Jobs are defined in `config/schedules.yaml`. Each fire first takes `SET lock:sched:{job} <instance> NX PX <interval − 5 s>` ([CACHING.md](CACHING.md) §10). A replica that loses the race skips the fire, so several scheduler replicas are safe. Commands are produced directly (they carry fresh ids, and consumers are idempotent), except the verification scan, which goes through the outbox because it also writes to the DB (§10).

| Job | Cron (IST) | Topic | Key | Type and data |
|---|---|---|---|---|
| `twin_rebuild` | `*/15 * * * *` | `hawa.cmd.twin.v1` | `"twin"` | `cmd.twin.rebuild` `{as_of, window_min: 60, advection: true}` |
| `forecast_hourly` | `5 * * * *` | `hawa.cmd.forecast.v1` | `"forecast"` | `cmd.forecast.run` `{issued_at, horizons: [1..72], master: false}` |
| `forecast_master` | `0 17 * * *` | same | same | `{..., master: true}` |
| `replan` | `0 8,11,14 * * *` | `hawa.cmd.plan.v1` | `ward_id` | `cmd.plan.draft` per active ward `{plan_id, mode: "replan", ward_ids, window_start: now+30m, window_end: now+3h, requested_by: "scheduler"}` |
| `master_plan` | `30 18 * * *` | same | `ward_id` | `{mode: "master", window: next day 05:30–11:00 IST}` |
| `data_freeze` | `0 16 * * *` | **`hawa.cmd.maintenance.v1` (PCA-05)** | `"snapshot"` | `cmd.snapshot.freeze` `{as_of, hours: 24}` |
| `school_alerts_draft` | `0 19 * * *` | **`hawa.cmd.alert.v1` (PCA-04)** | `"alert"` | `cmd.alert.school_run` `{phase: "draft", date: tomorrow}` |
| `school_alerts_final` | `0 22 * * *` | same | same | `{phase: "final", date: tomorrow}` |
| `school_alerts_morning` (STRETCH) | `30 6 * * *` | same | same | `{phase: "morning", date: today}` |
| `dispatch_release` | `30 5 * * *` | **`hawa.cmd.dispatch.v1` (PCA-03)** | `"dispatch"` | `cmd.dispatch.release` `{as_of}`: release approved master plans with `window_start ≤ as_of + 5 min` |
| `dispatch_sweep` | `* * * * *` (**PCA-09**, replaces the `*/10` plan expiry check) | same | `"dispatch"` | `cmd.dispatch.sweep` `{now}`: plan expiry, overdue release, ack escalation, spray window timeouts, open segments > 2 h, verification exhaustion, late matching |
| `verify_scan` | `*/10 * * * *` + `0 11 * * *` | `hawa.cmd.verify.v1` (via outbox) | `intervention_id` | `cmd.verify.run` `{intervention_id, task_id, attempt, requested_by: "scheduler"}` |
| `nightly_train` | `0 2 * * *` | `hawa.cmd.train.v1` | `model` | `cmd.train.run` × `forecaster`, `calibration`, `effectiveness`, `site_score` |
| `evidence_weekly` | `0 7 * * 1` | `hawa.cmd.report.v1` | `"report"` | `cmd.evidence_report.build` `{week_start, ward_ids: "all"}` |
| `partitions` | `0 1 * * *` | `hawa.cmd.maintenance.v1` | `"partitions"` | `cmd.partitions.maintain` `{tables: "all", ahead_days: 7}`: runs `hawa partitions` (create, archive, drop, row retention per DATA_MODEL §19.1) |

External feed polling (CPCB/OpenAQ `*/15`, weather `0 *`, FIRMS `0 */3`) runs inside `feeds-worker` with its own APScheduler instance and the same `lock:sched:{job}` pattern ([CONTRACTS §11](../CONTRACTS.md#11-schedules): "feeds-worker internal").

**Proposed topics (PCA-03/04/05):**

| Topic | Key | Producer | Consumer group | Retention | Types |
|---|---|---|---|---|---|
| `hawa.cmd.dispatch.v1` | `"dispatch"` | scheduler | `dispatch` | 1 d | `cmd.dispatch.release`, `cmd.dispatch.sweep` |
| `hawa.cmd.alert.v1` | `"alert"` | scheduler | `alert-engine` | 1 d | `cmd.alert.school_run` |
| `hawa.cmd.maintenance.v1` | job name | scheduler | `archiver` | 1 d | `cmd.partitions.maintain`, `cmd.snapshot.freeze` |

Manual triggers for demos and debugging: `uv run hawa scheduler trigger <job> [--force]`. `--force` skips the lock.

## 9. Dispatch saga as event choreography

There is no central orchestrator process holding state in memory. State lives in `plan` and `plan_task` (DATA_MODEL §8.3–8.4: `status`, `version`, `expires_at`, `dispatched_at`, `acknowledged_at`, `window_start/end`, `status_source`) plus `intervention` (`verify_after`, `verification_status`, and the PCA-16 columns). DATA_MODEL §20.3 offers an optional `dispatch_saga` table. This design takes its "derive from statuses" alternative, so no table is needed (the lead confirms). Each step is a reaction to an event, done in one transaction with its outbox rows.

### 9.1 Plan-level

| Plan status | Entered on | Written by | Event emitted | Next trigger |
|---|---|---|---|---|
| `drafting` | `POST /draft` (the api inserts the row, DATA_MODEL §20.4), scheduler or intel-spike command | api / intel-worker | `plan.drafting` | optimiser + agents finish; sweep: > 10 min → `plan.failed` |
| `draft` | draft ready | intel-worker | `plan.drafted` (or `plan.failed` → `failed`) | officer edit / approve / reject; sweep expiry |
| `draft` (edited) | `PATCH /v1/plans/{id}` | api | `plan.edited` | |
| `rejected` | `POST /reject` | api | `plan.rejected` | dispatch cancels pending tasks |
| `expired` | sweep: `now ≥ window_start` and still `draft` | dispatch-worker | `plan.expired` | — |
| `approved` | `POST /approve` | api | `plan.approved` | dispatch releases now, or for `master` plans at `window_start` (05:30 IST) via `cmd.dispatch.release` / sweep |
| `dispatched` | tasks released | dispatch-worker | `plan.dispatched` | first task `in_progress` |
| `in_progress` | first task `en_route` or `in_progress` | dispatch-worker | `plan.in_progress` | all tasks terminal |
| `completed` / `partially_completed` | all tasks terminal (all `done`/`verifying`/`verified`/`inconclusive` → completed; any `missed`/`skipped`/`failed` → partially) | dispatch-worker | `plan.completed` / **`plan.partially_completed` (PCA-08)** | — |

### 9.2 Task-level

| Task status | Entered on | Written by | Event | Timeout (sweep) |
|---|---|---|---|---|
| `pending` | plan drafted | intel-worker | — | plan expiry → `cancelled` |
| `dispatched` | release | dispatch-worker | `task.dispatched` + `alert.requested` (route_assignment / inspection_target) | ack: 15 min per escalation step; spray window end + 30 min → `missed` |
| `acknowledged` | app ack | api | `task.acknowledged` (notifier cancels escalation) | window end + 30 min → `missed` |
| `en_route` | app status | api | `task.en_route` | same |
| `in_progress` | `spray.started` matched, or inspector on site | dispatch-worker / api | `task.in_progress` | open segment > 2 h → close with `stop_inferred` |
| `done` | `spray.stopped` matched (dispatch-worker), or manual done / inspection evidence (api: sets `status_source`, creates the manual intervention, API.md §7) | dispatch-worker / api | `task.done` (`data.source` = `plan_task.status_source`: `hawatag` \| `manual` \| `gps_inferred` \| `system`) | — |
| `verifying` | verification scheduled (spray/sweep tasks) | dispatch-worker | `task.verifying` | `verify_after` + 3 attempts → `inconclusive` |
| `verified` / `inconclusive` | `impact.verified` for the task's primary pollutant (PM10 for dust tasks, PM2.5 otherwise); verdict `inconclusive` → `inconclusive` | dispatch-worker | `task.verified` / `task.inconclusive` | — |
| `missed` / `skipped` / `cancelled` / `failed` | sweep / app / officer / no reachable channel | dispatch-worker / api | `task.missed` / `task.skipped` / `task.cancelled` / `task.failed` (**`task.failed` is proposed; CONTRACTS lists the status but not the event type, PCA-08**) | — |

`intervention.verify_after = end_ts + HAWA_VERIFY_DELAY_MIN` (default 120 min, [CONTRACTS §10.3](../CONTRACTS.md#103-thresholds-used-across-services)). If `verify_after ≤ now` when the task is marked done (backfilled demo history), the dispatch-worker emits `cmd.verify.run` immediately instead of waiting for the scan.

## 10. Delayed verification scan

The `verify_scan` job claims due interventions and writes the outbox commands in **one transaction**. Nothing is published twice within an hour, and nothing is lost if the scheduler crashes.

```sql
-- uses DATA_MODEL §9.1 columns (verify_after, verification_status, index ix_intervention_verify_scan)
-- plus PCA-16 columns (verify_requested_at, verify_attempts)
WITH due AS (
  SELECT iv.id
  FROM hawa.intervention iv
  WHERE iv.end_ts IS NOT NULL
    AND iv.verify_after <= now()
    AND (   iv.verification_status = 'pending'
         OR (iv.verification_status = 'requested'
             AND iv.verify_attempts < :max_attempts
             AND iv.verify_requested_at < now() - interval '1 hour'))
  ORDER BY iv.verify_after
  LIMIT 200
  FOR UPDATE SKIP LOCKED
)
UPDATE hawa.intervention iv
   SET verification_status = 'requested', verify_requested_at = now(), verify_attempts = iv.verify_attempts + 1
  FROM due
 WHERE iv.id = due.id
RETURNING iv.id, iv.task_id, iv.verify_attempts, iv.is_simulated;
-- then, same transaction: one outbox row per returned id -> hawa.cmd.verify.v1 (key intervention_id)
```

On `impact.verified`, the dispatch-worker sets `verification_status` to `verified` or `inconclusive` (for the task's primary pollutant). Interventions without enough data (for example, no donor cells) are set to `not_verifiable` by the verifier's result, and never re-requested.

The 11:00 batch runs the same query with `LIMIT 2000`. Interventions that exhaust their attempts are turned into `task.inconclusive` (reason `verification_timeout`) by the next dispatch sweep.

## 11. Replay and backfill procedures

| Situation | Procedure |
|---|---|
| Ingest bug fixed; re-ingest the last N hours | `docker compose stop ingest-worker` → `kafka-consumer-groups.sh --bootstrap-server kafka:19092 --group ingest --topic hawa.telemetry.raw.v1 --reset-offsets --to-datetime 2026-11-12T00:00:00.000 --execute` → start. Rejected packets never set a dedupe key, so they are reprocessed; stored ones hit `dedupe:pkt`/DB and are skipped |
| Reprocess rejected telemetry (for example after registering devices) | `uv run hawa dlq replay --topic hawa.telemetry.dlq.v1 --reason unknown_device --since 6h` republishes each original raw payload to `hawa.telemetry.raw.v1` |
| A consumer failed on a bug (`hawa.dlq.v1`) | Deploy the fix → `uv run hawa dlq list --group dispatch` → `uv run hawa dlq replay --group dispatch --since 2h` republishes the original envelope (same `event_id`) to `hawa-dlq-topic`. Other groups on that topic ignore it through `processed_event` |
| Rebuild a projection (for example `alert.status` roll-ups) | Stop the owning process → reset its group to `--to-earliest` → start. Handlers are idempotent upserts |
| A new consumer group needs history | Create it with `auto_offset_reset=earliest`. It reads the full retention. Live-only groups (`api-live`) use `latest` |
| Backfill external feeds | `uv run hawa feeds backfill --source cpcb --from 2026-11-01 --to 2026-11-07` (upserts + outbox events flagged `data.backfill=true`) |
| Rebuild the Parquet lake for a day | `uv run hawa archive rebuild --date 2026-11-12` (reads Postgres, not Kafka) |
| Demo backfill (optional variant of DATA_MODEL §18.3 `hawa seed history --shift-to-now`) | `uv run hawa-sim backfill --hours 6 --scenario golden` publishes historical packets with their original `ts` (inside the 72 h window, flagged `sd_replay`) through the real pipeline ([DEPLOYMENT.md](DEPLOYMENT.md) §5.2) |

Offset resets are logged to `hawa.audit.v1` by the CLI (`action=ops.offset_reset`).

## 12. Lag monitoring and alerting

- Every consumer exports `hawa_consumer_lag{group,topic,partition}` (highwater − position, sampled every 15 s) and `hawa_consumer_last_commit_timestamp_seconds{group}`.
- `kafka-exporter` (obs profile) exports broker-side `kafka_consumergroup_lag`. It catches a consumer that is dead and therefore exports nothing.
- The relay exports `hawa_outbox_lag_seconds`.

| Alert | Condition | Severity |
|---|---|---|
| Ingest falling behind | `sum(kafka_consumergroup_lag{consumergroup="ingest"}) > 2000` for 2 min | page |
| Dispatch lag | `dispatch` lag > 50 for 2 min | page (tasks and spray matching delayed) |
| Notifier lag | `notifier` lag > 100 for 5 min | warn |
| Live map stale | `api-live` lag > 1000 for 2 min | warn |
| Consumer stopped committing | `time() - hawa_consumer_last_commit_timestamp_seconds > 300` while lag > 0 | page |
| DLQ receiving | `increase(kafka_topic_partition_current_offset{topic="hawa.dlq.v1"}[5m]) > 0` | warn |
| Outbox stuck | `hawa_outbox_lag_seconds > 30` for 1 min | page |

Rules live in `backend/docker/local/prometheus/rules/kafka.yml`, with CloudWatch equivalents on AWS ([LOGGING_AND_OBSERVABILITY.md](LOGGING_AND_OBSERVABILITY.md) §14).

## 13. Schema evolution rules

1. Additive fields within a topic version are allowed: add an optional field with a default, consumers use `extra="ignore"`, and the envelope `version` is unchanged ([CONTRACTS §12](../CONTRACTS.md#12-versioning-and-change-rules)).
2. Changing a field's meaning or type, or removing or renaming a field, requires a new topic `.v2`. Producers dual-publish to `.v1` and `.v2` for at least one release, consumers migrate, then `.v1` is retired.
3. A consumer that sees a known type with a newer `version` dead-letters it (`unsupported_version`) instead of guessing. An unknown type is skipped and counted.
4. Enum additions are additive. Payload models use a lenient enum type that maps unknown values to `unknown` ([CONTRACTS §12](../CONTRACTS.md#12-versioning-and-change-rules) rule 5).
5. JSON Schemas for every event are exported to `backend/contracts/schemas/*.json` (`uv run hawa contracts export`) and committed. A contract test fails on a breaking diff (a removed property, a changed type, or a new required property).
6. `hawa.logs.v1` (Avro) evolves under Schema Registry `BACKWARD` compatibility, owned by logifyx.
7. Every contract change touches `../CONTRACTS.md` and `hawa_contracts` in the same PR, tagged to all four leads.

## 14. Local debugging recipes

```bash
# list topics and partitions
kcat -b localhost:9092 -L | grep hawa.

# tail the last 5 clean readings with key and headers
kcat -b localhost:9092 -t hawa.telemetry.clean.v1 -C -o -5 -e -f '%k | %h\n%s\n\n'

# follow plan and task lifecycle live, pretty-printed
kcat -b localhost:9092 -C -t hawa.plan.lifecycle.v1 -t hawa.task.lifecycle.v1 -o end -u | jq .

# produce a twin rebuild command by hand (prefer: uv run hawa scheduler trigger twin_rebuild --force)
echo '{"event_id":"'$(uv run python -c "import uuid6;print(uuid6.uuid7())")'","type":"cmd.twin.rebuild","version":1,"source":"dev","occurred_at":"2026-11-12T01:15:00Z","produced_at":"2026-11-12T01:15:00Z","correlation_id":"01927f3e-7000-7aaa-8bbb-000000000001","subject":"twin","is_simulated":false,"data":{"as_of":"2026-11-12T01:15:00Z","window_min":60,"advection":true}}' \
  | kcat -b localhost:9092 -t hawa.cmd.twin.v1 -P -k twin -H hawa-type=cmd.twin.rebuild -H hawa-version=1

# consumer group lag
docker compose exec kafka /opt/kafka/bin/kafka-consumer-groups.sh \
  --bootstrap-server kafka:19092 --describe --group ingest

# watch MQTT traffic before it reaches Kafka
mosquitto_sub -h localhost -u ops -P "$MQTT_OPS_PASSWORD" -t 'hawa/v1/#' -v

# project CLI helpers
uv run hawa events tail hawa.plan.lifecycle.v1 --pretty --type plan.approved
uv run hawa dlq list --since 1h
```

Kafka UI (http://localhost:8080) shows topics, messages (JSON pretty view), consumer groups with per-partition lag, and Schema Registry subjects for `hawa.logs.v1`.

## 15. The logifyx log topic `hawa.logs.v1`

- It is written only by the logifyx Kafka handler (aiokafka async producer, **Avro** through Confluent Schema Registry, gzip, its own circuit breaker), keyed by service name, with 7 d retention.
- It is **separate from the JSON domain topics.** It never carries domain events, no domain service consumes it, and the consumer base class refuses to subscribe to a topic whose `TopicSpec.serde` is `avro`.
- It is created by `hawa kafka-init` like every other topic. The subject `hawa.logs.v1-value` is registered by logifyx on first write with `schema_compatibility="BACKWARD"`.
- Sinks are post-hackathon: Kafka Connect S3 sink (Parquet) or OpenSearch sink. For the hackathon, logs are read on stdout (`docker compose logs`) and in Kafka UI.
- On AWS, it is enabled only once logifyx supports MSK authentication (PCA-24, [LOGGING_AND_OBSERVABILITY.md](LOGGING_AND_OBSERVABILITY.md) §2.4). Until then, stdout JSON goes to CloudWatch Logs.

## 16. Proposed contract additions (defined here)

| ID | Addition |
|---|---|
| PCA-02 | Dual raw encodings (envelope or bare packet + `hawa-type`, `hawa-mqtt-topic`, `hawa-received-at` headers); raw `event_id` may be absent or UUIDv4; raw `is_simulated` ignored; reason code `malformed_payload` |
| PCA-03 | `hawa.cmd.dispatch.v1` (`cmd.dispatch.release`, `cmd.dispatch.sweep`) → group `dispatch` |
| PCA-04 | `hawa.cmd.alert.v1` (`cmd.alert.school_run {phase, date}`) → group `alert-engine` |
| PCA-05 | `hawa.cmd.maintenance.v1` (`cmd.partitions.maintain`, `cmd.snapshot.freeze`) → group `archiver` |
| PCA-06 | `dispatch` also consumes `hawa.task.lifecycle.v1` (events with envelope `source="api"`); `api-live` also consumes `hawa.alert.requested.v1` |
| PCA-07 | Producers: intel-worker → `device.calibrated`, `device.trust_changed`; api → `alert.delivered`, `alert.read` |
| PCA-08 | Event types `plan.partially_completed`, `task.failed` |
| PCA-09 | Schedule: `dispatch_sweep` every minute (absorbs the plan expiry check and the 10 min drafting timeout), `dispatch_release` via `cmd.dispatch.release`, school runs via `cmd.alert.school_run` (+ optional 06:30 morning), freeze and partitions via `cmd.maintenance.*` |
| PCA-10 | DLQ headers `hawa-dlq-error-type`, `hawa-dlq-partition`, `hawa-dlq-offset`, `hawa-dlq-attempts`, `hawa-dlq-failed-at` |
| PCA-11 | Deterministic UUIDv7 for ingest-derived events |
| PCA-16 | `intervention.verify_requested_at`, `verify_attempts`, `flags`; the scheduler writes `verification_status` and those columns; saga state is derived (no `dispatch_saga` table) |
| PCA-29 | `intervention` writers include the api (manual fallback, API.md §7) |
| PCA-25 | Optional `archiver-raw` group |
| PCA-26 | `device-health` hosted by alert-engine; `audit` + `audit-writer` hosted by audit-writer (merge suggested) |
| — | `cmd.verify.run` data `{intervention_id, task_id, attempt, requested_by}` (CONTRACTS names the type but not the data) |
