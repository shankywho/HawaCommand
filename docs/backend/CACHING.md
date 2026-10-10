# Caching and Coordination (Redis)

> **Status: Planned (Redis).** No code connects to Redis; `redis` is a declared dependency and `hawa_contracts/redis_keys.py` defines the key builders. Caching that actually runs: live station data is cached in process for 15 minutes in `core/intel_client.py`; settings use `functools.lru_cache`; when `HAWA_AWS_ENABLED=true`, `aws/cache.py` caches twin and forecast payloads in DynamoDB (`HAWA_AWS_CACHE_TABLE`, default `hawa-cache`, TTL `HAWA_AWS_CACHE_TTL_SECONDS`, default 3600). Rate limiting, idempotency keys, OTP storage and GEO fleet sets below are the target design. See [docs/backend/README.md](README.md#1-implementation-status).


Redis in depth for HawaCommand: the client, key conventions and TTLs, versioned cache-aside, stampede protection, HTTP caching, rate limiting, OTP and token state, idempotency keys, locks, WebSocket fan-out, live fleet, eviction, sizing, failure behaviour and metrics.

Related: [README](README.md) · [ARCHITECTURE](ARCHITECTURE.md) · [EVENTS](EVENTS.md) · [API](API.md) · [LOGGING_AND_OBSERVABILITY](LOGGING_AND_OBSERVABILITY.md) · [DEPLOYMENT](DEPLOYMENT.md) · [../CONTRACTS.md](../CONTRACTS.md) §9 · [../SYSTEM_OVERVIEW.md](../SYSTEM_OVERVIEW.md)

---

## 1. What Redis is for (and what it is not)

| Use | Keys | Correctness depends on Redis? |
|---|---|---|
| Response and tile cache | `cache:*`, `twin:version` | No: every read falls back to Postgres |
| Packet and event dedupe fast path | `dedupe:pkt:*`, `dedupe:evt:*` | No: DB unique constraint and `processed_event` are durable |
| Rate limits | `rl:*` | No for security-critical correctness; degraded to in-process limits |
| OTP state, JWT deny list, Idempotency-Key | `otp:*`, `jwt:deny:*`, `idem:*` | Partly: OTP login is unavailable while Redis is down (fails closed) |
| Distributed locks | `lock:*` | No: every locked job is also idempotent |
| WebSocket fan-out | `ws:*` pub/sub | No: clients resync over REST |
| Live fleet and device state | `live:fleet`, `live:device:*` | No: fallback query on `reading` / `device` |
| AI-ML feature caches and model pointers | `ml:*` | AI-ML owned |

**Redis is never the system of record.** Durable state lives in Postgres; streams live in Kafka.

## 2. Client and key conventions

### 2.1 Client

```python
# cache/client.py (sketch)
from redis.asyncio import Redis
from redis.asyncio.retry import Retry
from redis.backoff import ExponentialBackoff

def build_redis(s: RedisSettings) -> Redis:
    return Redis.from_url(
        s.url,                                  # redis://redis:6379/0 locally, rediss://… on ElastiCache (TLS)
        max_connections=s.max_connections,      # api 50 per replica, workers 20
        socket_timeout=s.socket_timeout_s,      # 0.5 s api, 2 s workers
        socket_connect_timeout=1.0,
        health_check_interval=30,
        retry=Retry(ExponentialBackoff(cap=0.2, base=0.02), retries=2),
        retry_on_timeout=True,
        decode_responses=False,                 # we store bytes (orjson / MVT)
        client_name=f"{s.service}-{socket.gethostname()}",
    )
```

- One pooled client per process, created in `bootstrap.py` and closed on shutdown. Pub/sub uses a separate dedicated connection (`redis.pubsub()`), so a slow subscriber never starves the pool.
- **ElastiCache.** Redis OSS 7.x, cluster mode disabled (one primary plus one replica in the pilot), in-transit TLS (`rediss://`), AUTH token or IAM authentication through ElastiCache RBAC. Scripts and multi-key operations don't need hash tags while cluster mode is off (see §13 for the cluster-mode note).
- Every call goes through `cache/client.py` helpers (`get_safe`, `set_safe`, `exists_safe`) that apply the `redis` circuit breaker and return a fallback on failure (§14).

### 2.2 Keys and TTLs

Every key is prefixed `hawa:{env}:` (for example `hawa:local:`), and the builders in `hawa_contracts/redis_keys.py` add the prefix, so AI-ML uses the same functions. `{…}` below are placeholders, not Redis Cluster hash tags.

| Pattern | Type | Owner | TTL | Purpose | Status |
|---|---|---|---|---|---|
| `cache:twin:{tile_version}:{bbox_hash}` | string (orjson GeoJSON) | api | 20 min | `/v1/twin` responses | CONTRACTS |
| `cache:tile:{tile_version}:{z}:{x}:{y}` | string (gzip MVT bytes) | api | 20 min | vector tiles | CONTRACTS |
| `cache:hotspots:{ward_id}:{run_id}` | string | api | 20 min | ranked hotspots | CONTRACTS |
| `cache:forecast:{cell_id}:{issued_at}` | string | api | 75 min | forecast series | CONTRACTS |
| `cache:plan:{plan_id}:{version}` | string | api | 10 min | plan detail with tasks and review | CONTRACTS |
| `twin:version` | string (int) | api (`api-cache` on `twin.updated`) | none (protected) | current `tile_version` | CONTRACTS |
| `dedupe:pkt:{device_id}:{seq}` | string (`1`) | ingest-worker | 73 h (configurable, `HAWA_DEDUPE_PKT_TTL_H`) | packet dedupe: `MGET` before insert, `SET` after commit + publish (DATA_MODEL §14.2) | CONTRACTS |
| `dedupe:evt:{group}:{event_id}` | string | every consumer; api webhook uses group `wa-webhook` | 24 h | event idempotency fast path | CONTRACTS |
| `live:fleet` | GEO (sorted set) | ingest-worker | none (protected, pruned) | latest positions of assets and sensor vehicles | CONTRACTS |
| `live:device:{device_id}` | hash | ingest-worker | 1 h (refreshed per packet) | last seen, last packet summary, flags | CONTRACTS |
| `rl:{scope}:{subject}:{window}` | string (counter) | api | 2 × window | rate limits | CONTRACTS |
| `otp:{phone_e164}` | hash `{h, attempts, channel, created_at}` | api | 5 min | OTP hash + attempts (API.md §2.1) | CONTRACTS (see PCA-14) |
| `jwt:deny:{jti}` | string | api | remaining token lifetime | revoked access tokens | CONTRACTS |
| `lock:sched:{job}` | string (owner token) | scheduler, feeds-worker | job interval − 5 s | single-leader scheduling | CONTRACTS |
| `lock:plan:{ward_id}` | string | intel-worker | 10 min | one plan draft per ward | CONTRACTS |
| `ws:{channel}` | pub/sub channel | api | n/a | WebSocket broadcast | CONTRACTS |
| `ml:feat:{name}:{key}`, `ml:model:{name}:active` | string / hash | AI-ML | varies / none | AI-ML | CONTRACTS |
| `idem:{sub}:{key}` | hash `{fp, state, status, headers, body}` | api | 24 h (60 s while `in_progress`) | HTTP `Idempotency-Key` storage (§9, API.md §1.7) | **PCA-13** (also proposed in API.md) |
| `lock:cache:{key_hash}` | string (owner token) | api | 5 s | single-flight cache fill (§5) | **PCA-13** |
| `cache:open:{endpoint}:{tile_version}:{params_hash}` | string | api | 60 s | `/open/v1/*` responses | **PCA-13** |
| `cache:grap:{ward_id}:{issued_at}` | string | api | 75 min | GRAP outlook + checklist | **PCA-13** |
| `twin:run_id`, `forecast:issued_at` | string | api (`api-cache`) | none (protected) | current run pointers for hotspot and forecast keys | **PCA-13** |
| `ws:user:{user_id}` | pub/sub channel | api | n/a | internal fan-out for `tasks:me`, `alerts:me` | **PCA-13** |
| `inv:device` | pub/sub channel | api, alert-engine | n/a | registry cache invalidation for ingest | **PCA-13** |

`rl` scopes are those of API.md §1.9: `login`, `otp_req`, `otp_verify`, `refresh`, `user`, `plan_draft`, `simulate`, `reports`, `presign`, `open`, `twin_anon`. This doc adds `wa_in` for inbound WhatsApp reports (**PCA-13**).

Rules:
- The TTL argument of `cache.set()` is mandatory, and there is no default. A unit test asserts that every non-protected key builder is used only with a TTL.
- Protected (no-TTL) keys are exactly `twin:version`, `twin:run_id`, `forecast:issued_at`, `live:fleet` and `ml:model:*:active`. They are small and rebuilt from Postgres on api startup.
- Keys never contain raw PII. Phone numbers and emails are hashed (`sha256(pepper + value)[:16]`) wherever they would appear in a key (PCA-14).

## 3. Cache-aside with versioned keys

Keys embed a **version** of their source data. When the data changes, the version pointer changes, new reads use new keys, and the old keys simply expire. There are no `SCAN` + `DEL` mass deletes, and a reader can never see a half-invalidated cache.

| Cache | Version source | Bumped by |
|---|---|---|
| twin GeoJSON, tiles, open data | `tile_version` from `twin.updated` (monotonic per twin run) | `api-cache` sets `twin:version` after pre-warming (§5.3) |
| hotspots | `run_id` from `hotspot.updated` | `api-cache` sets `twin:run_id` |
| forecast, GRAP | `issued_at` of the latest forecast run | `api-cache` sets `forecast:issued_at` on `forecast.issued` |
| plan detail | `plan.version` (optimistic-concurrency counter, DATA_MODEL.md) | every plan transition increments it in the same transaction |

```python
# services/twin_service.py (sketch)
async def tile(self, z: int, x: int, y: int, v: int | None) -> TileResult:
    version = v or await self._pointers.twin_version()        # GET twin:version, else latest twin_run from DB
    key = keys.tile(version, z, x, y)
    data = await self._cache.get_or_fill(
        key, ttl_s=1200,
        fill=lambda: self._repo.render_tile(run_for(version), z, x, y),   # ST_AsMVT, gzip
    )
    return TileResult(body=data, version=version, etag=f'"{version}-{z}-{x}-{y}"')
```

- **Historical requests** (`?ts=`) resolve `ts` to the twin run that was current then and use its `tile_version`, so they are cached exactly like the current version.
- **Plan detail.** The version lookup is a primary-key read. The cached blob saves the task, review and simulation joins and the serialization.
- On api startup, `api-cache` rebuilds the protected pointers from Postgres (latest `twin_run`, latest `forecast_run`) before `/readyz` goes green.

## 4. HTTP caching interplay

[API.md](API.md) §1.8 is authoritative. The cache keys here are designed so each validator can be computed from Redis alone:

| Endpoint | `Cache-Control` | Validator | Redis source of the validator |
|---|---|---|---|
| `GET /v1/twin/tiles/{z}/{x}/{y}.mvt` | `private, max-age=60`; with `?v={tile_version}`: `private, max-age=86400, immutable` (**PCA-22**) | `ETag: "t{tile_version}"` | `twin:version` |
| `GET /v1/twin?bbox=&ts=` | `private, max-age=30` | `ETag: "t{tile_version}-{bbox_hash}"` | `twin:version` |
| `GET /v1/hotspots` | `private, max-age=30` | `ETag: "h{run_id}"` | `twin:run_id` |
| `GET /v1/forecast/*` | `private, max-age=300` | `ETag: "f{issued_at_epoch}"` | `forecast:issued_at` |
| `GET /v1/plans/{id}` | `private, no-cache` | `ETag: "v{version}"` (also the `If-Match` value) | `plan.version` (PK read) |
| `/open/v1/*` | `public, max-age=60, stale-while-revalidate=120` | strong `ETag` | `twin:version` |
| `/open/v1/methods` | `public, max-age=86400` | strong `ETag` | static |
| other authenticated JSON | `private, no-store` | — | — |

- 304 responses are produced before any cache or DB fill when the client's validator matches the current version.
- `Vary: Accept-Encoding` on tiles. Tiles are stored gzip-compressed and sent with `Content-Encoding: gzip`. A client without gzip support (rare) gets a decompressed copy.
- Rate limiting runs **before** the cache, so a 304 still counts toward the open-data limit.

## 5. Stampede protection

A version bump makes every client miss at the same moment. Three defences:

### 5.1 Single-flight

```python
# cache/cached.py (sketch)
async def get_or_fill(self, key: str, *, ttl_s: int, fill: Callable[[], Awaitable[bytes]]) -> bytes:
    if (hit := await self.get_safe(key)) is not None:
        self._m.hit(key); return hit
    self._m.miss(key)
    if (fut := self._inflight.get(key)) is not None:           # 1) in-process: one fill per key per replica
        return await asyncio.shield(fut)
    fut: asyncio.Future[bytes] = asyncio.get_running_loop().create_future()
    self._inflight[key] = fut
    try:
        lock_key, token = keys.lock_cache(hash16(key)), secrets.token_hex(8)
        if await self.set_nx_safe(lock_key, token, px=5_000, fallback=True):   # 2) cross-replica lock
            try:
                value = await fill()
                await self.set_safe(key, value, ex=ttl_s)
            finally:
                await self.release_lock(lock_key, token)       # compare-and-delete Lua (§10)
        else:
            value = await self.wait_for(key, timeout_s=2.0, poll_s=0.05) or await fill()   # bounded wait
        fut.set_result(value)
        return value
    except BaseException as exc:
        if not fut.done(): fut.set_exception(exc)
        raise
    finally:
        self._inflight.pop(key, None)
```

### 5.2 Early refresh

Forecast and hotspot entries store `{"v": value, "exp": expiry_ms, "d": fill_ms}`. A read refreshes in the background, still under single-flight, when `now_ms − d × β × ln(random()) ≥ exp` (probabilistic early expiration, β = 1). A hot key is renewed before it expires, and at most one replica does the work.

### 5.3 Warm then flip

On `twin.updated`, `api-cache`:
1. renders the common tiles (z10–z13 over the Delhi bbox, about 100 tiles) and the default `/v1/twin` bboxes under the **new** `tile_version`;
2. `SET twin:version <new>`;
3. lets api-live's WebSocket `twin.updated` tell clients to refetch with `?v=<new>`.

Tiles requested before the flip carry the explicit `v`, so ordering between `api-cache` and `api-live` does not affect correctness. At worst there is a coalesced miss.

## 6. Serialization

| Payload | Format | Notes |
|---|---|---|
| JSON responses | orjson bytes of the response model's `model_dump(mode="json")` | stored exactly as sent; the handler returns `Response(content=bytes, media_type="application/json")` |
| Vector tiles | raw MVT from PostGIS, gzip level 6 | ~5–30 KB per tile |
| Early-refresh entries | Redis hash `HSET key v <bytes> exp <ms> d <ms>` (value bytes as a field, metadata as numbers) | avoids double-encoding bytes inside JSON |
| Idempotency record | orjson `{state, req_hash, status, headers, body_b64}` | body base64 because it is embedded in JSON |
| Live device hash | Redis hash fields as ASCII numbers and strings | readable with `HGETALL` when debugging |

`pickle` is banned in the codebase (ruff `S301`). Values over 1 MB are not cached (the helper logs and skips).

## 7. Rate limiting

**Algorithm.** A sliding-window approximation over two fixed-window counters, implemented as one Lua script (atomic, one round-trip). It uses the contract key shape `rl:{scope}:{subject}:{window}`, where `{window}` is the window index (`floor(now / window)`).

```lua
-- cache/lua/sliding_window.lua
-- KEYS[1] = current window key, KEYS[2] = previous window key
-- ARGV[1] = limit, ARGV[2] = window_ms, ARGV[3] = now_ms, ARGV[4] = cost (usually 1)
local limit, window, now, cost = tonumber(ARGV[1]), tonumber(ARGV[2]), tonumber(ARGV[3]), tonumber(ARGV[4])
local curr = redis.call('INCRBY', KEYS[1], cost)
if curr == cost then redis.call('PEXPIRE', KEYS[1], window * 2) end
local prev = tonumber(redis.call('GET', KEYS[2]) or '0')
local elapsed = now % window
local estimated = prev * ((window - elapsed) / window) + curr
if estimated > limit then
  -- time until enough of the previous window has slid out (or the window rolls)
  local retry_ms = window - elapsed
  if prev > 0 then
    local need = estimated - limit
    retry_ms = math.min(retry_ms, math.ceil(need / prev * window))
  end
  return {0, math.floor(limit - estimated), retry_ms}
end
return {1, math.floor(limit - estimated), window - elapsed}
```

```python
# cache/rate_limit.py (sketch)
@dataclass(frozen=True)
class Limit:
    scope: str
    limit: int
    window_s: int

# values from API.md §1.9 (authoritative); subjects are hashed when they are phones or emails
LIMITS = {
    "login_ip":     Limit("login", 10, 900),           # per IP
    "login_email":  Limit("login", 10, 900),           # per lower(email)
    "otp_req":      Limit("otp_req", 3, 900),          # per phone (+ 30 s resend cooldown)
    "otp_req_ip":   Limit("otp_req", 20, 3600),        # per IP
    "refresh":      Limit("refresh", 30, 60),          # per user
    "user":         Limit("user", 600, 60),            # default authenticated, per user
    "plan_draft":   Limit("plan_draft", 10, 60),       # per user
    "simulate":     Limit("simulate", 30, 60),         # per user
    "reports":      Limit("reports", 10, 3600),        # per user
    "reports_ip":   Limit("reports", 30, 3600),        # per IP
    "presign":      Limit("presign", 30, 60),          # per user
    "open":         Limit("open", 60, 60),             # per client IP (trusted ALB X-Forwarded-For only)
    "twin_anon":    Limit("twin_anon", 60, 60),        # anonymous GET /v1/twin, per IP
    "wa_in":        Limit("wa_in", 20, 3600),          # inbound WhatsApp reports per sender (PCA-13)
}

async def hit(self, name: str, subject: str, cost: int = 1) -> Decision:
    lim, now_ms = LIMITS[name], self._clock.now_ms()
    w = lim.window_s * 1000
    idx = now_ms // w
    try:
        allowed, remaining, reset_ms = await self._script(
            keys=[keys.rl(lim.scope, subject, idx), keys.rl(lim.scope, subject, idx - 1)],
            args=[lim.limit, w, now_ms, cost])
    except RedisUnavailable:
        return self._local.hit(lim, subject, cost)     # in-process fallback (§14)
    return Decision(bool(allowed), max(0, remaining), reset_ms)
```

| Limit (from the brief) | Scope | Subject | Value | On exceed |
|---|---|---|---|---|
| Open data | `open` | client IP (from trusted proxy headers) | 60 req/min | 429 `rate_limited` |
| OTP request | `otp_req` | phone (hashed in the key); IP | 3 per 15 min per phone, 30 s cooldown; 20/h per IP | 429 `rate_limited` / `auth.otp_resend_too_soon`; the response never reveals whether the phone exists |
| OTP verify | `otp_verify` (the `attempts` field of `otp:{phone}`) | code | 5 attempts per code | the key is deleted on the 5th failure, `429 auth.otp_attempts_exceeded` |
| Login | `login` | IP; lowercased email | 10 per 15 min each | 429; failures are also security events; 5 consecutive failures lock the account for 15 min (API.md §2.1) |
| Report submit | `reports` | user; IP | 10 per hour per user; 30/h per IP | 429 |
| WhatsApp inbound | `wa_in` | `hash(sender)` | 20 per hour | message accepted, no report created, polite reply |
| General API | `user` | user | 600 per min | 429 |

- Rejected attempts also count (the counter is incremented before the check). This is deliberate: hammering keeps the client locked out.
- Response headers on every limited route: `RateLimit-Limit`, `RateLimit-Remaining`, `RateLimit-Reset` (seconds). On 429, also `Retry-After` and a problem+json body `{"code": "rate_limited", ...}`.
- A FastAPI dependency applies it: `Depends(rate_limit("open", by="ip"))`. The limiter runs before auth for `open`, `login` and `otp_*`.

## 8. OTP storage and JWT deny list

**OTP** (driver, inspector, school, site_manager, citizen):

| Step | Redis operation |
|---|---|
| Request | Rate limit `otp_req`. Generate `code = f"{secrets.randbelow(10**6):06d}"`. `HSET otp:{phone_key} h <hmac_sha256(OTP_PEPPER, phone + ":" + code)> attempts 0 channel sms created <ts>` + `EXPIRE 300`. The api sends the code directly through `SmsSender` (or `WhatsAppClient`), **not** through Kafka, so the code never enters a durable log and is not queued behind alerts. The code is never logged. |
| Verify | `HINCRBY otp:{phone_key} attempts 1`. If it exceeds 5, `DEL` and 429. Compare HMACs with `hmac.compare_digest`. On success, `DEL` (single use) and issue tokens. |
| Resend | 30 s cooldown and the `otp_req` limits (§7). An unknown phone verifying successfully becomes a `citizen` account; every other phone role must be pre-provisioned (API.md §2.1). |
| Dev | `HAWA_OTP_DEV_CODE=000000` is accepted **only** when `HAWA_ENV=local` (API.md §2.1). Startup refuses the setting in any other env. |

**Proposed contract addition (PCA-14):** use `otp:{phone_hash}` (`sha256(pepper + phone_e164)[:16]`) instead of `otp:{phone_e164}`. Raw phone numbers in key names show up in `MONITOR`, `SLOWLOG`, Kafka UI exports and memory dumps.

**JWT deny list.** On logout, password change or admin disable: `SET jwt:deny:{jti} 1 EX <exp − now>`. The verifier checks it once per request (one `EXISTS`). Access tokens live 15 min, so the set stays tiny. Refresh-token revocation is durable in Postgres (the refresh-token family is revoked on reuse), so sessions cannot be extended even if the deny list is lost. If Redis is unavailable, the check **fails closed for writes and open for reads**, with a warning (`HAWA_DENYLIST_FAIL_OPEN_READS`, API.md §2.5).

## 9. HTTP Idempotency-Key storage

**Proposed contract addition (PCA-13, also proposed in API.md §1.7):** the hash `idem:{sub}:{key}` with fields `{fp, state, status, headers, body}`. API.md §1.7 is authoritative for the semantics. The Redis mechanics are:

| Case | Redis operation | HTTP |
|---|---|---|
| First request | `HSETNX idem:{sub}:{key} state in_progress` succeeds → `HSET fp <sha256>` + `EXPIRE 60` (lock TTL), run the handler | — |
| Completed with 2xx or 4xx | `HSET state done status <code> headers <json> body <bytes>` + `EXPIRE 86400` | original response |
| Completed with 5xx | `DEL` (the client may retry with the same key) | 5xx |
| Repeat, same `fp`, `done` | `HGETALL` | stored response + `Idempotent-Replayed: true` |
| Repeat while `in_progress` | `HGETALL` | `409 idempotency.in_progress`, `Retry-After: 1` |
| Repeat, different `fp` | `HGETALL` | `422 idempotency.key_reuse_mismatch` |

`fp = sha256(method + path + canonical JSON body)` (part hashes for multipart). Key format: 1–64 chars `[A-Za-z0-9_-]` (the Flutter offline queue reuses one UUIDv7 per queued action). Anonymous webhooks dedupe on the provider message id instead. Domain operations are idempotent wherever possible (approving an already-approved plan at the same version returns the same 200), so a lost Redis record degrades to "safe but not byte-identical".

## 10. Distributed locks

```lua
-- release: compare-and-delete
if redis.call('GET', KEYS[1]) == ARGV[1] then return redis.call('DEL', KEYS[1]) else return 0 end
-- renew: compare-and-pexpire
if redis.call('GET', KEYS[1]) == ARGV[1] then return redis.call('PEXPIRE', KEYS[1], ARGV[2]) else return 0 end
```

| Lock | Holder | TTL | Semantics |
|---|---|---|---|
| `lock:sched:{job}` | scheduler / feeds-worker replica | job interval − 5 s (1 min jobs: 55 s; daily jobs: 23 h 59 min 55 s) | acquired at fire time and **not released**, so one fire per interval across replicas; `hawa scheduler trigger --force` bypasses it |
| `lock:plan:{ward_id}` | intel-worker | 10 min, renewed every 2 min while drafting | one plan draft per ward (AI-ML) |
| `lock:cache:{key_hash}` | api | 5 s | single-flight fill (§5) |

- Locks use a random owner token, release by compare-and-delete, and renew by compare-and-pexpire. A single Redis primary is used; Redlock is not needed.
- Locks are **advisory**. Every locked action is idempotent downstream (commands dedupe on `event_id`, and plan drafting checks `plan` state), so a lock lost to a failover can at worst cause duplicate work, never duplicate effects. No fencing tokens are needed.
- If Redis is unavailable, the scheduler with `HAWA_SCHED_REPLICAS=1` proceeds (fail open). With more replicas it skips the fire and alerts (fail closed).

## 11. Pub/sub fan-out for WebSockets

- The publisher is the api replica that owns the Kafka partition for the event (group `api-live`): `PUBLISH hawa:{env}:ws:{channel} <orjson message>`. The message is exactly the WebSocket frame `{"channel","type","data","ts"}` with sensitive fields removed ([CONTRACTS §6.1](../CONTRACTS.md#61-websocket)).
- Every replica holds one dedicated pub/sub connection with `PSUBSCRIBE hawa:{env}:ws:*`. A reader task pushes each message into the local hub, which delivers it to the connections subscribed to that channel (per-connection bounded queue, [ARCHITECTURE.md](ARCHITECTURE.md) §5.3).
- Per-user delivery goes over `ws:user:{user_id}` (PCA-13). The frame's `channel` field is still `tasks:me` or `alerts:me`.
- Pub/sub is at-most-once. On reconnect after a Redis blip, the replica sends `{"type":"resync"}` to all its clients, and clients refetch over REST. Clients also refetch on every WebSocket reconnect.
- Fleet messages are batched to 1 Hz before publishing, so pub/sub traffic stays under ~10 messages/s at demo scale.

## 12. Live fleet (GEO) and device hashes

```text
GEOADD  hawa:local:live:fleet 77.2194 28.6331 asset:AST-SPR-0012
GEOADD  hawa:local:live:fleet 77.2101 28.6402 vehicle:VEH-DTC-0457
HSET    hawa:local:live:device:HPM-0142 last_seen 1762910070 lat 28.6331 lon 77.2194 pm25 164.3 pm10 271.0 \
        flags heater_on batt 4.02 fw 1.4.2 seq 88214 cell g500-041-077 sim 1 member vehicle:VEH-DTC-0457
EXPIRE  hawa:local:live:device:HPM-0142 3600
GEOSEARCH hawa:local:live:fleet FROMLONLAT 77.2150 28.6400 BYRADIUS 3 km ASC COUNT 10 WITHDIST
```

- Members are `asset:{asset_id}` for HawaTag-carrying machines and inspection teams (team positions only from the app during an active shift), and `vehicle:{vehicle_id}` for HawaPod-M hosts. HawaPod-S sentinels are fixed and are not in the GEO set.
- The ingest-worker updates positions in one pipeline per batch.
- GEO members have no per-member TTL. `live:device:{id}` (1 h TTL) holds `last_seen`, and a prune task inside ingest (every 5 min) removes GEO members whose device hash has expired. `/v1/fleet/live` also filters on `last_seen > now − 10 min`.
- Uses:
  - `GET /v1/fleet/live` (officer).
  - WebSocket `fleet` (1 Hz).
  - The dispatch-worker's nearest-team proposal for inspections (`GEOSEARCH ... BYRADIUS 5 km`, then filter available teams).
  - The ingest spike double-check (the baseline from the device hash).
- Privacy: asset positions only. No driver identity is in Redis, and live positions vanish within 1 h.

## 13. Eviction policy and memory sizing

- `maxmemory-policy volatile-lru`. Only keys **with** a TTL are eviction candidates. The protected no-TTL keys (§2.2) are never evicted. If memory fills with non-evictable data, writes fail with OOM, so we alert at 80 % `used_memory / maxmemory`. `maxmemory` is set to 75 % of node memory (ElastiCache `reserved-memory-percent` 25).
- Every cache key has a TTL (mandatory API), so eviction pressure falls on caches and dedupe keys first. Both are safe to lose.

| Key family | Demo (60 devices) | Campus pilot (~160) | MCD zone (~1,000) | Formula |
|---|---|---|---|---|
| `dedupe:pkt` (73 h) | ~530 k keys ≈ 55 MB | ~1.4 M ≈ 140 MB | ~8.8 M ≈ 880 MB | devices × 120/h × 73 h × ~100 B |
| `dedupe:evt` (24 h) | ~50 k ≈ 5 MB | ~150 k ≈ 15 MB | ~1 M ≈ 100 MB | DB-idempotent groups only (`api-live` uses none) |
| `cache:tile` (2 live versions) | ~15 MB | ~15 MB | ~30 MB | ~500 tiles × 15 KB × 2 |
| other caches | ~10 MB | ~20 MB | ~50 MB | |
| live / rl / otp / idem / locks | < 5 MB | < 10 MB | < 30 MB | |
| **Total** | **~90 MB** | **~200 MB** | **~1.1 GB** | |
| Node | local container (512 MB cap) | `cache.t4g.small` (1.37 GB) | `cache.t4g.medium` (3.09 GB) or cut `dedupe:pkt` TTL to 6 h | |

At zone scale, cut `HAWA_DEDUPE_PKT_TTL_H` to 6 h. Store-and-forward replays older than 6 h then fall through to the `reading` unique constraint, which is slower but equally correct. For Redis Cluster (NCR scale), multi-key Lua scripts need hash tags (`rl:{open:1.2.3.4}:…`), and the key builders gain a `cluster=True` mode.

## 14. Failure behaviour

The `redis` circuit breaker opens after 5 consecutive failures, or when the error rate is 50 % or more over 20 calls in 10 s. It stays open for 10 s, so requests don't each wait out a 0.5 s timeout.

| Feature | Redis down → | User impact |
|---|---|---|
| Response and tile cache | read from Postgres; skip cache writes | slower tiles (~300 ms), same data |
| `twin:version` and run pointers | query the latest `twin_run` / `forecast_run` from Postgres (in-process memo, 5 s) | none |
| Rate limiting | in-process sliding window per replica (same limits per replica) | limits become per-replica (looser by × replica count) |
| OTP request and verify | **fail closed**: 503 `service_unavailable` | field and community logins wait; existing sessions keep working |
| Password login | works (in-process rate limit) | none |
| JWT deny list | fail **closed for writes**, open for reads, with a WARNING + `hawa_denylist_unavailable_total` (API.md §2.5); refresh revocation is still enforced in Postgres | writes return `503 service_unavailable`; a revoked token may read for ≤ 15 min |
| Idempotency-Key | processed without replay protection; domain idempotency still applies (report `photo_sha256`, plan versions); WARNING | a retried create may duplicate at worst, bounded by rate limits |
| `dedupe:pkt` / `dedupe:evt` | DB unique constraint / `processed_event` only | higher DB load; no duplicates |
| Scheduler locks | 1 replica: proceed; more replicas: skip and alert | none with 1 replica |
| WebSocket fan-out | publish to the local hub only; clients on other replicas get `resync` when Redis returns. The hackathon runs 1 api replica, so no change there | missed live pushes on other replicas; REST still correct |
| `live:fleet` / `live:device` | normally `/v1/fleet/live` is served only from Redis (API.md §8); while Redis is down it degrades to the latest `reading` per device in the last 10 min (indexed query); spike double-check falls back to `confirmed_by_cloud=false` | slightly slower fleet view |

When the breaker closes again, the api-cache consumer rebuilds the pointers, and caches refill lazily.

## 15. Metrics

| Metric | Type | Labels |
|---|---|---|
| `hawa_cache_requests_total` | counter | `cache` (twin, tile, hotspots, forecast, plan, open, grap), `result` (hit, miss, error) |
| `hawa_cache_fill_seconds` | histogram | `cache` |
| `hawa_cache_singleflight_waits_total` | counter | `cache`, `outcome` (value, timeout) |
| `hawa_redis_command_seconds` | histogram | `command` (get, set, eval, geoadd, publish, …) |
| `hawa_redis_errors_total` | counter | `kind` (timeout, connection, oom) |
| `hawa_circuit_breaker_state` | gauge (0 closed, 1 half-open, 2 open) | `target="redis"` |
| `hawa_rate_limit_decisions_total` | counter | `scope`, `decision` (allow, reject), `backend` (redis, local) |
| `hawa_lock_acquire_total` | counter | `lock` (sched job name, cache), `result` (acquired, busy, error) |
| `hawa_dedupe_hits_total` | counter | `layer` (redis, db), `group` |
| `hawa_ws_fanout_messages_total` | counter | `channel_kind` (twin, hotspots, fleet, plan, tasks, alerts, devices, impact) |

Cache hit ratio (PromQL, used on the golden-path dashboard):

```promql
sum by (cache) (rate(hawa_cache_requests_total{result="hit"}[5m]))
  / sum by (cache) (rate(hawa_cache_requests_total{result=~"hit|miss"}[5m]))
```

Server-side metrics come from `redis-exporter` (obs profile locally, CloudWatch on ElastiCache): `used_memory`, `evicted_keys`, `keyspace_hits/misses`, `connected_clients` and `instantaneous_ops_per_sec`. Alerts: memory > 80 %, `evicted_keys` rate > 0 for protected-key namespaces (should be impossible), and an error rate > 1 % for 5 min.

## 16. Proposed contract additions (defined here)

- **PCA-13** keys `idem:{sub}:{key}` (hash, 24 h; also in API.md §23), `lock:cache:{key_hash}` (5 s), `cache:open:{endpoint}:{tile_version}:{params_hash}` (60 s), `cache:grap:{ward_id}:{issued_at}` (75 min), protected pointers `twin:run_id` and `forecast:issued_at`, pub/sub channels `ws:user:{user_id}` and `inv:device`, `rl` scope names, and a configurable `dedupe:pkt` TTL.
- **PCA-14** `otp:{phone_hash}` instead of `otp:{phone_e164}`, with hashed subjects in `rl` keys.
- **PCA-22** tile URL `?v={tile_version}` with immutable caching and ETag.
