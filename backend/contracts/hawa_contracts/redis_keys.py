"""Redis key namespace builders and TTL constants (§9)."""

# TTL Constants in seconds
TTL_DEDUPE_PACKET = 72 * 3600    # 72 hours (covers store-and-forward)
TTL_DEVICE_LATEST = 24 * 3600
TTL_TWIN_TILE = 30 * 60          # 30 minutes
TTL_HOTSPOTS = 15 * 60           # 15 minutes
TTL_FORECAST = 60 * 60           # 1 hour
TTL_IDEMPOTENCY = 24 * 3600
TTL_OTP = 5 * 60                 # 5 minutes
TTL_LOCK_PLAN = 120              # 2 minutes lock timeout
TTL_LOCK_SCHED = 300             # 5 minutes


class RedisKeyBuilder:
    def __init__(self, env: str = "dev"):
        self.env = env
        self.prefix = f"hawa:{env}"

    def dedupe_packet(self, device_id: str, seq: int) -> str:
        return f"{self.prefix}:dedupe:packet:{device_id}:{seq}"

    def live_fleet(self) -> str:
        return f"{self.prefix}:live:fleet"

    def device_latest(self, device_id: str) -> str:
        return f"{self.prefix}:device:latest:{device_id}"

    def twin_version(self) -> str:
        return f"{self.prefix}:twin:version"

    def twin_tile(self, z: int, x: int, y: int, version: str) -> str:
        return f"{self.prefix}:twin:tile:{version}:{z}:{x}:{y}"

    def hotspots(self, ward_id: str = "all") -> str:
        return f"{self.prefix}:hotspots:{ward_id}"

    def forecast(self, ward_id: str = "all") -> str:
        return f"{self.prefix}:forecast:{ward_id}"

    def lock_plan(self, ward_id: str) -> str:
        return f"{self.prefix}:lock:plan:{ward_id}"

    def lock_sched(self, job_name: str) -> str:
        return f"{self.prefix}:lock:sched:{job_name}"

    def idempotency(self, key: str) -> str:
        return f"{self.prefix}:idem:{key}"

    def otp(self, phone_hash: str) -> str:
        return f"{self.prefix}:otp:{phone_hash}"

    def rate_limit(self, scope: str, client_id: str) -> str:
        return f"{self.prefix}:rl:{scope}:{client_id}"
