# Deployment

> **Status (as built).**
> - **Local run:** from the repo root, `make install`, `make db-up` (optional), `make db-update`, `make db-seed`, `make aiml-api` (127.0.0.1:8100), `make backend` (0.0.0.0:8000), `make frontend` (3000). The root `Makefile` wraps `uv sync`, `uv run alembic upgrade head`, `uv run python -m hawa_backend.db.seed` and `uv run uvicorn ...`. See [backend/README.md](../../backend/README.md#quick-start).
> - **Docker Compose:** `backend/docker-compose.yml` starts PostGIS 16, Redis 7 and Kafka 3.8 (KRaft) only; the API does not use them yet.
> - **Not built (Planned):** a backend Dockerfile, a root compose file, CDK, CI/CD and the ECS/RDS/MSK deployment described below.
> - **AWS:** the optional layer in `src/hawa_backend/aws/` is configured by `HAWA_AWS_ENABLED`, `HAWA_AWS_REGION`, `HAWA_AWS_ENDPOINT_URL`, `HAWA_AWS_FORECAST_STATE_MACHINE_ARN`, `HAWA_AWS_FORECAST_ENDPOINT`, `HAWA_AWS_DISPATCH_STATE_MACHINE_ARN`, `HAWA_AWS_CACHE_TABLE`, `HAWA_AWS_CACHE_TTL_SECONDS`, `HAWA_AWS_ALERTS_TOPIC_ARN` and `HAWA_AWS_SENSOR_STREAM`. The matching resources are in `infrastructure/cloudformation/hawa-integration.yaml`; see [../AWS_INTEGRATION.md](../AWS_INTEGRATION.md).


How HawaCommand runs locally (Docker Compose at the repo root), how the golden path is reset for the demo, and how the backend deploys to AWS with CDK. Also covers CI/CD, promotion, backups, secrets and cost.

Related: [README](README.md) · [ARCHITECTURE](ARCHITECTURE.md) · [STRUCTURE](STRUCTURE.md) · [EVENTS](EVENTS.md) · [CACHING](CACHING.md) · [LOGGING_AND_OBSERVABILITY](LOGGING_AND_OBSERVABILITY.md) · [DATA_MODEL](DATA_MODEL.md) · [PLAN](PLAN.md) · [../CONTRACTS.md](../CONTRACTS.md) · [../SYSTEM_OVERVIEW.md](../SYSTEM_OVERVIEW.md) §9

---

## 1. Environments

| Env | Runs on | Brokers | Data | Purpose |
|---|---|---|---|---|
| `local` | `docker compose` on a developer laptop (8 GB RAM for Docker) | Mosquitto, Kafka KRaft | seeded grid, POIs, assets; simulator fleet; recorded feed fixtures or live feeds | development, the hackathon build |
| `test` | CI runners (testcontainers) | Kafka container | mini grid fixtures | automated tests |
| `demo` | **Tier A:** one EC2 instance running the same compose + AWS IoT Core; **or Tier B:** the CDK stack | IoT Core → bridge → Kafka (A), IoT Core → IoT Rule → MSK (B) | live CPCB/OpenAQ/FIRMS/Open-Meteo + simulated fleet + one real pod | judging and demo video (§12.5: "live on AWS") |
| `pilot` | CDK stack (§6) | IoT Core → IoT Rule → MSK provisioned | real devices | campus pilot and beyond (§14.1) |

## 2. docker-compose (repo root)

### 2.1 Services

Profiles: services without a profile form the **infra** set, which `docker compose up -d` starts alone. `app`, `ml`, `web`, `obs` and `sim` add the rest, and `all` includes everything (`make up`).

| Service | Image | Host ports | Volumes | Profile | Notes |
|---|---|---|---|---|---|
| `postgres` | `postgis/postgis:16-3.4` | 5432 | `pgdata`, `init.sql` | infra | DBs `hawa`, `mlflow`; login users per DATA_MODEL §1.2 (`hawa_migrator`, `hawa_api`, `hawa_ingest`, …, `hawa_ml`); group roles from migration `0001` |
| `redis` | `redis:7-alpine` | 6379 | none (no persistence) | infra | `--maxmemory 512mb --maxmemory-policy volatile-lru` |
| `kafka` | `apache/kafka:3.8.x` (pinned tag) | 9092 | `kafkadata` | infra | KRaft single node; `INTERNAL://kafka:19092`, `EXTERNAL://localhost:9092` |
| `schema-registry` | `confluentinc/cp-schema-registry` (pinned tag) | 8081 | — | infra | for `hawa.logs.v1` only |
| `kafka-ui` | `provectuslabs/kafka-ui` (or `kafbat/kafka-ui`) | 8080 | — | infra | |
| `mosquitto` | `eclipse-mosquitto:2` | 1883 | `mosquittodata`, conf/acl/passwd | infra | no anonymous access |
| `minio` | `minio/minio` (pinned tag) | 9000, 9001 | `miniodata` | infra | S3 API + console |
| `minio-init` | `minio/mc` (pinned tag) | — | `init.sh` | infra | creates buckets once |
| `migrate` | `hawa-backend:local` | — | — | app | `alembic upgrade head` (runs to completion) |
| `kafka-init` | `hawa-backend:local` | — | — | app | `hawa kafka-init` (runs to completion) |
| `api` | `hawa-backend:local` | 8000 | — | app | also hosts consumers `api-live`, `api-cache`, `api-alert-status` |
| `ingest-worker` | `hawa-backend:local` | 9101 → 9100 | — | app | |
| `feeds-worker` | `hawa-backend:local` | 9102 → 9100 | — | app | `HAWA_FEEDS_MODE=live\|fixture` |
| `scheduler` | `hawa-backend:local` | 9103 → 9100 | — | app | |
| `dispatch-worker` | `hawa-backend:local` | 9104 → 9100 | — | app | |
| `notifier` | `hawa-backend:local` | 9105 → 9100 | `./backend/secrets` (FCM JSON, read-only) | app | providers `log` unless configured |
| `outbox-relay` | `hawa-backend:local` | 9106 → 9100 | — | app | |
| `mqtt-bridge` | `hawa-backend:local` | 9107 → 9100 | — | app | |
| `audit-writer` | `hawa-backend:local` | 9108 → 9100 | — | app | |
| `alert-engine` | `hawa-backend:local` | 9109 → 9100 | — | app | |
| `evidence-report` | `hawa-backend:local` | 9110 → 9100 | — | app | |
| `archiver` | `hawa-backend:local` | 9111 → 9100 | — | app | writes to MinIO |
| `simulator` | `hawa-backend:local` | 9112 → 9100 | `simout` | sim | `hawa-sim run --scenario golden` |
| `intel-service` | `hawa-aiml:local` (AI-ML) | 8100 | — | ml | internal REST |
| `intel-worker` | `hawa-aiml:local` (AI-ML) | 9120 | — | ml | |
| `trainer` | `hawa-aiml:local` (AI-ML) | — | — | ml (run on demand) | |
| `mlflow` | `ghcr.io/mlflow/mlflow` (pinned; AI-ML may add psycopg2 + boto3 in a thin image) | 5000 | — | ml | backend store Postgres `mlflow`, artifacts MinIO `hawa-local-models` |
| `web` | `hawa-web:local` (frontend) | 3000 | — | web | Next.js |
| `jaeger` | `jaegertracing/all-in-one` (pinned) | 16686, 4317, 4318 | — | obs | OTLP in, UI |
| `prometheus` | `prom/prometheus` (pinned) | 9090 | `promdata`, config + rules | obs | scrapes api:8000 and workers:9100 |
| `grafana` | `grafana/grafana` (pinned) | 3001 | `grafanadata`, provisioning | obs | golden-path dashboard |
| `kafka-exporter` | `danielqsj/kafka-exporter` (pinned) | 9308 | — | obs | group lag even if consumers are dead |
| `redis-exporter` | `oliver006/redis_exporter` (pinned) | 9121 | — | obs | |
| `postgres-exporter` | `prometheuscommunity/postgres-exporter` (pinned) | 9187 | — | obs | |

Pin every tag in `.env.example` (`*_TAG` variables) at kickoff and never use `latest` in the demo build.

### 2.2 Compose sketch

```yaml
# docker-compose.yml (repo root, excerpt; the full file follows the table in §2.1)
name: hawacommand

x-backend: &backend
  image: hawa-backend:local
  build: { context: ./backend, dockerfile: docker/Dockerfile }
  env_file: .env
  environment: &backend-env
    HAWA_ENV: local
    HAWA_LOG_PROFILE: docker
    HAWA_LOG_KAFKA_ENABLED: "true"
    # default login; each worker overrides it with its own member of app_rw (DATA_MODEL §1.2)
    HAWA_DATABASE_URL: postgresql+asyncpg://hawa_api:${HAWA_DB_PASSWORD:-hawa}@postgres:5432/hawa
    HAWA_REDIS_URL: redis://redis:6379/0
    HAWA_KAFKA_BOOTSTRAP: kafka:19092
    HAWA_SCHEMA_REGISTRY_URL: http://schema-registry:8081
    HAWA_MQTT_HOST: mosquitto
    HAWA_S3_ENDPOINT_URL: http://minio:9000
    HAWA_INTEL_URL: http://intel-service:8100
    OTEL_EXPORTER_OTLP_ENDPOINT: http://jaeger:4317
  depends_on:
    migrate: { condition: service_completed_successfully }
    kafka-init: { condition: service_completed_successfully }
    redis: { condition: service_healthy }
    mosquitto: { condition: service_started }
  restart: unless-stopped
  profiles: ["app", "all"]
  healthcheck:
    test: ["CMD", "python", "-c", "import urllib.request; urllib.request.urlopen('http://localhost:9100/healthz', timeout=2)"]
    interval: 15s
    timeout: 3s
    retries: 5

services:
  postgres:
    image: postgis/postgis:16-3.4
    environment:
      POSTGRES_USER: ${POSTGRES_USER:-hawa}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-hawa}
      POSTGRES_DB: hawa
    command: ["postgres", "-c", "shared_buffers=256MB", "-c", "max_connections=200",
              "-c", "log_min_duration_statement=500", "-c", "timezone=UTC"]
    ports: ["5432:5432"]
    volumes:
      - pgdata:/var/lib/postgresql/data
      - ./backend/docker/local/postgres/init.sql:/docker-entrypoint-initdb.d/10-init.sql:ro
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER:-hawa} -d hawa"]
      interval: 5s
      retries: 20

  redis:
    image: redis:7-alpine
    command: ["redis-server", "--maxmemory", "512mb", "--maxmemory-policy", "volatile-lru", "--save", "", "--appendonly", "no"]
    ports: ["6379:6379"]
    healthcheck: { test: ["CMD", "redis-cli", "ping"], interval: 5s, retries: 20 }

  kafka:
    image: apache/kafka:${KAFKA_TAG:-3.8.0}
    ports: ["9092:9092"]
    environment:
      KAFKA_NODE_ID: 1
      KAFKA_PROCESS_ROLES: broker,controller
      KAFKA_LISTENERS: INTERNAL://:19092,EXTERNAL://:9092,CONTROLLER://:9093
      KAFKA_ADVERTISED_LISTENERS: INTERNAL://kafka:19092,EXTERNAL://localhost:9092
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: INTERNAL:PLAINTEXT,EXTERNAL:PLAINTEXT,CONTROLLER:PLAINTEXT
      KAFKA_INTER_BROKER_LISTENER_NAME: INTERNAL
      KAFKA_CONTROLLER_LISTENER_NAMES: CONTROLLER
      KAFKA_CONTROLLER_QUORUM_VOTERS: 1@kafka:9093
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
      KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR: 1
      KAFKA_TRANSACTION_STATE_LOG_MIN_ISR: 1
      KAFKA_GROUP_INITIAL_REBALANCE_DELAY_MS: 0
      KAFKA_AUTO_CREATE_TOPICS_ENABLE: "false"
      KAFKA_LOG_DIRS: /var/lib/kafka/data          # must be writable by the image user; else use the image default dir
      CLUSTER_ID: ${KAFKA_CLUSTER_ID:-MkU3OEVBNTcwNTJENDM2Qk}
    volumes: [kafkadata:/var/lib/kafka/data]
    healthcheck:
      test: ["CMD-SHELL", "/opt/kafka/bin/kafka-broker-api-versions.sh --bootstrap-server localhost:19092 >/dev/null 2>&1"]
      interval: 10s
      retries: 30

  schema-registry:
    image: confluentinc/cp-schema-registry:${CP_SCHEMA_REGISTRY_TAG}
    depends_on: { kafka: { condition: service_healthy } }
    ports: ["8081:8081"]
    environment:
      SCHEMA_REGISTRY_HOST_NAME: schema-registry
      SCHEMA_REGISTRY_LISTENERS: http://0.0.0.0:8081
      SCHEMA_REGISTRY_KAFKASTORE_BOOTSTRAP_SERVERS: PLAINTEXT://kafka:19092

  kafka-ui:
    image: provectuslabs/kafka-ui:${KAFKA_UI_TAG}
    depends_on: { kafka: { condition: service_healthy } }
    ports: ["8080:8080"]
    environment:
      KAFKA_CLUSTERS_0_NAME: local
      KAFKA_CLUSTERS_0_BOOTSTRAPSERVERS: kafka:19092
      KAFKA_CLUSTERS_0_SCHEMAREGISTRY: http://schema-registry:8081
      DYNAMIC_CONFIG_ENABLED: "true"

  mosquitto:
    image: eclipse-mosquitto:2
    ports: ["1883:1883"]
    volumes:
      - ./backend/docker/local/mosquitto/mosquitto.conf:/mosquitto/config/mosquitto.conf:ro
      - ./backend/docker/local/mosquitto/acl:/mosquitto/config/acl:ro
      - ./backend/docker/local/mosquitto/passwd:/mosquitto/config/passwd:ro
      - mosquittodata:/mosquitto/data

  minio:
    image: minio/minio:${MINIO_TAG}
    command: ["server", "/data", "--console-address", ":9001"]
    environment:
      MINIO_ROOT_USER: ${MINIO_ROOT_USER:-minio}
      MINIO_ROOT_PASSWORD: ${MINIO_ROOT_PASSWORD:-minio12345}
    ports: ["9000:9000", "9001:9001"]
    volumes: [miniodata:/data]
    healthcheck: { test: ["CMD", "mc", "ready", "local"], interval: 5s, retries: 20 }

  minio-init:
    image: minio/mc:${MINIO_MC_TAG}
    depends_on: { minio: { condition: service_healthy } }
    entrypoint: ["/bin/sh", "/init.sh"]
    environment: { MINIO_ROOT_USER: ${MINIO_ROOT_USER:-minio}, MINIO_ROOT_PASSWORD: ${MINIO_ROOT_PASSWORD:-minio12345} }
    volumes: ["./backend/docker/local/minio/init.sh:/init.sh:ro"]

  migrate:
    <<: *backend
    command: ["migrate"]
    restart: "no"
    environment:
      <<: *backend-env
      HAWA_SERVICE_NAME: migrate
      HAWA_MIGRATOR_DATABASE_URL: postgresql+asyncpg://hawa_migrator:${HAWA_DB_PASSWORD:-hawa}@postgres:5432/hawa
    depends_on: { postgres: { condition: service_healthy } }
    healthcheck: { disable: true }

  kafka-init:
    <<: *backend
    command: ["kafka-init"]
    restart: "no"
    depends_on: { kafka: { condition: service_healthy } }
    healthcheck: { disable: true }

  api:
    <<: *backend
    command: ["api"]
    ports: ["8000:8000"]
    environment:
      <<: *backend-env
      HAWA_SERVICE_NAME: api
      OTEL_SERVICE_NAME: api
      HAWA_API_CONSUMERS: live,cache,alert-status
    healthcheck:
      test: ["CMD", "python", "-c", "import urllib.request; urllib.request.urlopen('http://localhost:8000/healthz', timeout=2)"]
      interval: 10s
      retries: 10

  ingest-worker:
    <<: *backend
    command: ["worker", "ingest"]
    ports: ["9101:9100"]
    environment:
      <<: *backend-env
      HAWA_SERVICE_NAME: ingest-worker
      OTEL_SERVICE_NAME: ingest-worker
      HAWA_DATABASE_URL: postgresql+asyncpg://hawa_ingest:${HAWA_DB_PASSWORD:-hawa}@postgres:5432/hawa

  dispatch-worker:
    <<: *backend
    command: ["worker", "dispatch"]
    ports: ["9104:9100"]
    environment:
      <<: *backend-env
      HAWA_SERVICE_NAME: dispatch-worker
      OTEL_SERVICE_NAME: dispatch-worker
      HAWA_DATABASE_URL: postgresql+asyncpg://hawa_dispatch:${HAWA_DB_PASSWORD:-hawa}@postgres:5432/hawa

  # feeds-worker (9102, hawa_feeds), scheduler (9103, hawa_scheduler), notifier (9105, hawa_notifier),
  # outbox-relay (9106, hawa_outbox), mqtt-bridge (9107, no DB), audit-writer (9108, hawa_audit*),
  # alert-engine (9109, hawa_alerts*), evidence-report (9110, hawa_reports*), archiver (9111, hawa_migrator for
  # `hawa partitions`): same pattern. * = login users proposed in PCA-28.

  simulator:
    <<: *backend
    profiles: ["sim", "all"]
    command: ["sim", "run", "--devices", "50", "--tags", "10", "--sentinel-pairs", "3", "--scenario", "golden"]
    ports: ["9112:9100"]
    depends_on: { mosquitto: { condition: service_started }, api: { condition: service_healthy } }
    volumes: [simout:/app/simulator/out]

  intel-service:
    image: hawa-aiml:local
    build: { context: ./AI-ML }
    profiles: ["ml", "all"]
    command: ["intel-service"]
    env_file: .env
    ports: ["8100:8100"]
    depends_on: { migrate: { condition: service_completed_successfully } }

  web:
    image: hawa-web:local
    build: { context: ./frontend }
    profiles: ["web", "all"]
    ports: ["3000:3000"]
    environment:
      NEXT_PUBLIC_API_BASE_URL: http://localhost:8000
      NEXT_PUBLIC_WS_URL: ws://localhost:8000/v1/ws

  jaeger:
    image: jaegertracing/all-in-one:${JAEGER_TAG}
    profiles: ["obs", "all"]
    ports: ["16686:16686", "4317:4317", "4318:4318"]

  prometheus:
    image: prom/prometheus:${PROMETHEUS_TAG}
    profiles: ["obs", "all"]
    ports: ["9090:9090"]
    volumes:
      - ./backend/docker/local/prometheus:/etc/prometheus:ro
      - promdata:/prometheus

  grafana:
    image: grafana/grafana:${GRAFANA_TAG}
    profiles: ["obs", "all"]
    ports: ["3001:3000"]
    environment: { GF_SECURITY_ADMIN_PASSWORD: ${GF_SECURITY_ADMIN_PASSWORD:-admin} }
    volumes:
      - ./backend/docker/local/grafana/provisioning:/etc/grafana/provisioning:ro
      - ./backend/docker/local/grafana/dashboards:/var/lib/grafana/dashboards:ro
      - grafanadata:/var/lib/grafana

volumes: { pgdata: {}, kafkadata: {}, miniodata: {}, mosquittodata: {}, promdata: {}, grafanadata: {}, simout: {} }
```

### 2.3 Local config files (`backend/docker/local/`)

```conf
# mosquitto/mosquitto.conf
listener 1883
allow_anonymous false
password_file /mosquitto/config/passwd
acl_file /mosquitto/config/acl
persistence true
persistence_location /mosquitto/data/
max_queued_messages 100000
```

```conf
# mosquitto/acl: username = device id for real devices
pattern write hawa/v1/%u/telemetry
pattern write hawa/v1/%u/event
pattern write hawa/v1/%u/spray
pattern write hawa/v1/%u/clip
pattern read  hawa/v1/%u/cmd

user bridge
topic read hawa/v1/+/+

user simulator
topic write hawa/v1/+/+

user ops
topic read hawa/v1/#
```

`passwd` is generated by `uv run hawa devices mqtt-passwd` (it hashes the passwords from `.env` and the registry). The file is git-ignored.

`postgres/init.sql` creates the `mlflow` database and the **login users** of DATA_MODEL §1.2 and §20.5 (`hawa_migrator`, `hawa_api`, `hawa_ingest`, `hawa_feeds`, `hawa_dispatch`, `hawa_notifier`, `hawa_outbox`, `hawa_scheduler`, `hawa_ml`, `hawa_analytics`, plus the PCA-28 users), all with the local password `${HAWA_DB_PASSWORD}`. Migration `0001` creates the group roles (`hawa_owner`, `app_rw`, `ml_rw`, `readonly`) and the extensions, and grants membership. The table grants live in migration `0010` (DATA_MODEL §17.7).

`minio/init.sh` creates `hawa-local-lake`, `hawa-local-media`, `hawa-local-reports` and `hawa-local-models`, with private policies and a 90-day lifecycle on `hawa-local-media/uploads/`.

## 3. Makefile (repo root)

```make
# Makefile: owned by the backend team. On Windows use Git Bash or WSL.
SHELL    := /bin/bash
COMPOSE  := docker compose
ALL      := --profile all
BACKEND  := uv run --directory backend

.PHONY: up infra down clean logs ps migrate kafka-init seed sim demo-reset demo-check fmt lint test test-int e2e openapi

up:            ## everything: infra + backend + AI-ML + web + observability
	$(COMPOSE) $(ALL) up -d --build
infra:         ## infra only (develop services on the host with uv run)
	$(COMPOSE) up -d
down:
	$(COMPOSE) $(ALL) down
clean:         ## also deletes volumes (DB, Kafka, MinIO)
	$(COMPOSE) $(ALL) down -v
logs:          ## make logs s=api
	$(COMPOSE) $(ALL) logs -f --tail=200 $(s)
ps:
	$(COMPOSE) $(ALL) ps
migrate:
	$(COMPOSE) $(ALL) run --rm migrate
kafka-init:
	$(COMPOSE) $(ALL) run --rm kafka-init
seed:
	$(COMPOSE) $(ALL) run --rm --no-deps api seed
sim:
	$(COMPOSE) --profile sim up -d simulator
demo-reset:    ## golden-path reset (DATA_MODEL §18.3; §5.2). Optional: make demo-reset BACKFILL=6
	$(COMPOSE) $(ALL) stop simulator scheduler
	$(COMPOSE) $(ALL) run --rm --no-deps api demo-reset --yes $(if $(BACKFILL),--backfill-hours $(BACKFILL))
	$(COMPOSE) $(ALL) start scheduler simulator
	$(COMPOSE) $(ALL) run --rm --no-deps api demo-check
demo-check:
	$(COMPOSE) $(ALL) run --rm --no-deps api demo-check
fmt:
	$(BACKEND) ruff format . && $(BACKEND) ruff check --fix .
lint:
	$(BACKEND) ruff check . && $(BACKEND) ruff format --check . \
	  && $(BACKEND) mypy src contracts simulator && $(BACKEND) lint-imports && (cd backend && uv lock --check)
test:
	$(BACKEND) pytest -m "not integration and not e2e"
test-int:
	$(BACKEND) pytest -m integration -n auto
e2e:
	$(BACKEND) pytest -m e2e
openapi:       ## export OpenAPI and regenerate the web + Flutter clients
	$(BACKEND) hawa contracts export
	pnpm --dir frontend run gen:api
	$(MAKE) -C app_frontend gen-api
```

`docker/entrypoint.sh` maps the first argument: `api` → `hawa api`, `worker <n>` → `hawa worker <n>`, `migrate` → `alembic upgrade head`, `kafka-init`, `seed`, `demo-reset`, `demo-check` → the `hawa` subcommands, `sim ...` → `hawa-sim ...`.

## 4. `.env.example` catalogue

One file at the repo root. Values below are **local defaults**; secrets are placeholders. Compose overrides hostnames for containers (§2.2), so the same `.env` works for `uv run` on the host.

### 4.1 General and API

| Variable | Local default | Used by | Notes |
|---|---|---|---|
| `HAWA_ENV` | `local` | all | `local`, `test`, `demo`, `pilot` |
| `HAWA_SERVICE_NAME` | set per container | all | also the logifyx `service` field |
| `HAWA_VERSION` | `dev` | all | git sha, injected by CI |
| `HAWA_DEMO_MODE` | `false` | dispatch, scheduler, api | demo-compressed windows, labelled in the UI |
| `HAWA_API_HOST` / `HAWA_API_PORT` | `0.0.0.0` / `8000` | api | |
| `HAWA_API_PUBLIC_BASE_URL` | `http://localhost:8000` | api | links in alerts |
| `HAWA_CORS_ORIGINS` | `http://localhost:3000` | api | comma list |
| `HAWA_FORWARDED_ALLOW_IPS` | `127.0.0.1` | api | proxy IPs trusted for `X-Forwarded-For` |
| `HAWA_API_CONSUMERS` | `live,cache,alert-status` | api | which api-hosted consumer groups run |
| `HAWA_MAX_BODY_BYTES` | `1048576` | api | |
| `HAWA_OPEN_INCLUDE_SIMULATED` | `true` | api | PCA-27; `false` in pilot |

### 4.2 Database

| Variable | Local default | Notes |
|---|---|---|
| `POSTGRES_USER` / `POSTGRES_PASSWORD` | `hawa` / `hawa` | image superuser, local only |
| `HAWA_DATABASE_URL` | `postgresql+asyncpg://hawa_api:hawa@localhost:5432/hawa` | per service login (member of `app_rw`); compose sets one per worker |
| `HAWA_MIGRATOR_DATABASE_URL` | `postgresql+asyncpg://hawa_migrator:hawa@localhost:5432/hawa` | Alembic (`SET ROLE hawa_owner`) and `hawa partitions` only |
| `HAWA_DB_PASSWORD` | `hawa` | the one local password for every login user in `init.sql`; on AWS each login has its own Secrets Manager secret |
| `HAWA_DB_POOL_SIZE` / `HAWA_DB_MAX_OVERFLOW` | `10` / `10` | per process |
| `HAWA_DB_STATEMENT_TIMEOUT_MS` | `5000` (api), `30000` (workers) | |

### 4.3 Redis, Kafka, Schema Registry, MQTT

| Variable | Local default | Notes |
|---|---|---|
| `HAWA_REDIS_URL` | `redis://localhost:6379/0` | `rediss://` on ElastiCache |
| `HAWA_REDIS_MAX_CONNECTIONS` | `50` | |
| `HAWA_REDIS_SOCKET_TIMEOUT_S` | `0.5` | |
| `HAWA_DEDUPE_PKT_TTL_H` | `73` | PCA-13 |
| `HAWA_KAFKA_BOOTSTRAP` | `localhost:9092` | |
| `HAWA_KAFKA_SECURITY` | `plaintext` | `plaintext`, `iam`, `scram` |
| `HAWA_KAFKA_PROFILE` | `local` | partitions/RF in `kafka-init` |
| `AWS_REGION` | `ap-south-1` | MSK IAM, S3, SNS |
| `HAWA_SCHEMA_REGISTRY_URL` | `http://localhost:8081` | |
| `KAFKA_CLUSTER_ID` | `MkU3OEVBNTcwNTJENDM2Qk` | KRaft cluster id (local) |
| `HAWA_MQTT_HOST` / `HAWA_MQTT_PORT` | `localhost` / `1883` | IoT Core endpoint on AWS demo Tier A (8883) |
| `HAWA_MQTT_USERNAME` / `HAWA_MQTT_PASSWORD` | `bridge` / `change-me` | Mosquitto |
| `HAWA_MQTT_TLS` | `false` | `true` for IoT Core |
| `HAWA_MQTT_CA_PATH`, `HAWA_MQTT_CERT_PATH`, `HAWA_MQTT_KEY_PATH` | empty | IoT Core X.509 (bridge Tier A, simulator) |
| `HAWA_MQTT_SHARED_GROUP` | `hawa-bridge` | shared subscription `$share/hawa-bridge/hawa/v1/+/+` |
| `MQTT_OPS_PASSWORD`, `MQTT_SIMULATOR_PASSWORD` | `change-me` | `mosquitto_sub` debugging, simulator |

### 4.4 Object storage

| Variable | Local default | Notes |
|---|---|---|
| `HAWA_S3_ENDPOINT_URL` | `http://localhost:9000` | empty on AWS |
| `HAWA_S3_BUCKET_LAKE` / `_MEDIA` / `_REPORTS` / `_MODELS` | `hawa-local-lake` / `-media` / `-reports` / `-models` | |
| `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` | `minio` / `minio12345` | **local only**; task roles on AWS |
| `MINIO_ROOT_USER` / `MINIO_ROOT_PASSWORD` | `minio` / `minio12345` | |
| `HAWA_PRESIGN_TTL_S` / `HAWA_UPLOAD_MAX_BYTES` | `300` / `8388608` | |

### 4.5 Auth and internal

| Variable | Local default | Notes |
|---|---|---|
| `HAWA_AUTH_VERIFIER` | `local` | `local` or `cognito` |
| `HAWA_JWT_ALGORITHM` | `RS256` | must match [API.md](API.md) |
| `HAWA_JWT_PRIVATE_KEY_PATH` / `HAWA_JWT_PUBLIC_KEYS_PATH` | `./.secrets/jwt_private.pem` / `./.secrets/jwks.json` | generated on first boot (API.md §2.2), `kid = hawa-{yyyy}-{mm}`; add `.secrets/` to `.gitignore` |
| `HAWA_JWT_ISSUER` / `HAWA_JWT_AUDIENCE` | `hawa-api` / `hawa` | API.md §2.2 |
| `HAWA_DENYLIST_FAIL_OPEN_READS` | `true` | deny-list behaviour when Redis is down (API.md §2.5) |
| `HAWA_ACCESS_TOKEN_TTL_MIN` / `HAWA_REFRESH_TOKEN_TTL_DAYS` | `15` / `30` | |
| `HAWA_OTP_TTL_S` / `HAWA_OTP_PEPPER` | `300` / `change-me` | |
| `HAWA_OTP_DEV_CODE` | empty | e.g. `000000`; accepted only when `HAWA_ENV=local` (API.md §2.1) |
| `HAWA_COGNITO_JWKS_URL` | empty | when the verifier is `cognito` |
| `HAWA_INTERNAL_TOKEN` / `HAWA_INTERNAL_TOKEN_NEXT` | `change-me` / empty | api → intel-service; dual token during rotation |
| `HAWA_INTEL_URL` | `http://localhost:8100` | |
| `HAWA_INTEL_TIMEOUT_S` / `HAWA_INTEL_OPTIMIZE_TIMEOUT_S` | `5` / `8` | |

### 4.6 Notifications

| Variable | Local default | Notes |
|---|---|---|
| `HAWA_NOTIFY_SMS_PROVIDER` / `_WHATSAPP_PROVIDER` / `_PUSH_PROVIDER` | `log` / `log` / `log` | `sns`, `cloud_api`, `fcm` when configured |
| `HAWA_NOTIFY_ALLOWLIST` | `+9198XXXXXXXX` | non-prod: only these receive real SMS/WhatsApp; others are `dry_run` |
| `HAWA_SNS_SENDER_ID`, `HAWA_SNS_DLT_ENTITY_ID`, `HAWA_SNS_DLT_TEMPLATE_IDS` | empty | India DLT (JSON map kind → template id) |
| `HAWA_WHATSAPP_PHONE_NUMBER_ID`, `HAWA_WHATSAPP_ACCESS_TOKEN`, `HAWA_WHATSAPP_APP_SECRET`, `HAWA_WHATSAPP_VERIFY_TOKEN` | empty / `change-me` | Cloud API + webhook signature |
| `HAWA_WHATSAPP_API_VERSION` | pinned Graph API version | |
| `HAWA_FCM_CREDENTIALS_PATH` / `HAWA_FCM_PROJECT_ID` | `./backend/secrets/fcm.json` / empty | |

### 4.7 Feeds, dispatch, scheduler

| Variable | Local default | Notes |
|---|---|---|
| `HAWA_FEEDS_MODE` | `live` | `fixture` replays `seed/fixtures/demo` (offline venue) |
| `HAWA_CPCB_API_KEY` / `HAWA_CPCB_RESOURCE_ID` | empty | data.gov.in real-time AQ resource |
| `HAWA_OPENAQ_API_KEY` | empty | OpenAQ v3 |
| `HAWA_FIRMS_MAP_KEY` | empty | NASA FIRMS |
| `HAWA_OPENMETEO_BASE_URL` | `https://api.open-meteo.com/v1` | no key |
| `HAWA_FEEDS_BBOX` | `76.7,28.3,77.5,29.0` | NCR bbox (CONTRACTS §4.1) |
| `HAWA_DISPATCH_ACK_TIMEOUT_MIN` | `15` | |
| `HAWA_DISPATCH_SPRAY_GRACE_MIN` | `30` | |
| `HAWA_DISPATCH_MATCH_BUFFER_M` | `250` | |
| `HAWA_SPRAY_MAX_OPEN_MIN` | `120` | |
| `HAWA_VERIFY_DELAY_MIN` / `HAWA_VERIFY_MAX_ATTEMPTS` | `120` / `3` | demo mode may use 5 min (labelled) |
| `HAWA_MASTER_RELEASE_TIME` | `05:30` | IST |
| `HAWA_SCHED_TZ` | `Asia/Kolkata` | |
| `HAWA_SCHED_ENABLED_JOBS` | `all` | comma list to limit on a laptop |
| `HAWA_SCHED_REPLICAS` | `1` | lock fail-open only when 1 (CACHING §10) |

### 4.8 Logging, tracing, metrics

| Variable | Local default | Notes |
|---|---|---|
| `HAWA_LOG_PROFILE` | `local` | `local`, `docker`, `aws`, `test` |
| `HAWA_LOG_KAFKA_ENABLED` | `false` (host), `true` (compose) | `hawa.logs.v1` |
| `LOGIFYX_LEVEL`, `LOGIFYX_OUTPUT`, `LOG_JSON`, `LOG_COLOR`, `LOG_MASK`, `LOG_DIR` | unset | operator overrides (LOGGING_AND_OBSERVABILITY §2.2) |
| `LOG_KAFKA_TOPIC` / `LOG_SCHEMA_COMPATIBILITY` | `hawa.logs.v1` / `BACKWARD` | |
| `OTEL_EXPORTER_OTLP_ENDPOINT` | `http://localhost:4317` | |
| `OTEL_SERVICE_NAME` | per container | |
| `OTEL_TRACES_SAMPLER` / `OTEL_TRACES_SAMPLER_ARG` | `parentbased_traceidratio` / `1.0` | `0.1` in pilot |
| `OTEL_SDK_DISABLED` | `false` | |
| `HAWA_METRICS_PORT` | `9100` (container) / 91xx (host) | |

### 4.9 Simulator, AI-ML, web, images

| Variable | Local default | Notes |
|---|---|---|
| `HAWA_SIM_DEVICES` / `HAWA_SIM_TAGS` / `HAWA_SIM_SENTINEL_PAIRS` | `50` / `10` / `3` | |
| `HAWA_SIM_SEED` / `HAWA_SIM_SCENARIO` | `42` / `golden` | deterministic runs |
| `HAWA_SIM_API_URL` | `http://localhost:8000` | simulated drivers use the real API |
| `HAWA_SEED_OFFICER_PASSWORD` | `change-me` | demo officer/admin passwords for `hawa seed users` (DATA_MODEL §18.1) |
| `HAWA_DEMO_REAL_PHONES` | empty | real test phones attached to one driver, one principal and one citizen (DATA_MODEL §18.2); also put them in `HAWA_NOTIFY_ALLOWLIST` |
| `HAWA_SIM_EFFECTS` | `simulator/hawa_simulator/scenarios/effects.yaml` | injected known effects |
| `MLFLOW_TRACKING_URI` | `http://localhost:5000` | AI-ML |
| `NEXT_PUBLIC_API_BASE_URL` / `NEXT_PUBLIC_WS_URL` | `http://localhost:8000` / `ws://localhost:8000/v1/ws` | web |
| `GF_SECURITY_ADMIN_PASSWORD` | `admin` | Grafana, local only |
| `KAFKA_TAG`, `CP_SCHEMA_REGISTRY_TAG`, `KAFKA_UI_TAG`, `MINIO_TAG`, `MINIO_MC_TAG`, `JAEGER_TAG`, `PROMETHEUS_TAG`, `GRAFANA_TAG`, `MLFLOW_TAG` | pinned at kickoff | never `latest` |

## 5. Dev workflow and demo-reset

### 5.1 Day-to-day workflow

1. `make infra` (or `docker compose up -d`), then run only the process you are changing on the host: `uv run hawa api --reload` or `uv run hawa worker dispatch`. Run everything else in compose: `docker compose --profile app up -d ingest-worker outbox-relay ...`.
2. **Schema change:**
   - edit `db/models/*`;
   - run `uv run alembic revision --autogenerate -m "intervention verify attempts"`;
   - **review** the generated file (partitions, PostGIS types, grants);
   - run `uv run alembic upgrade head`, then `uv run alembic check` (no drift);
   - run `uv run alembic downgrade -1 && uv run alembic upgrade head`.

   Details in [DATA_MODEL.md](DATA_MODEL.md).
3. **Contract change** (enum, topic, payload, key): edit `backend/contracts/` + `docs/CONTRACTS.md` in the same PR, run `uv run hawa contracts export`, and tag all four leads.
4. **API change:** run `make openapi` so the web and Flutter clients regenerate. The OpenAPI snapshot test shows the diff.
5. Before pushing, run `make lint test` (pre-commit runs ruff, mypy, import-linter and gitleaks), and `make test-int` for anything touching DB, Kafka or Redis.
6. Commits use Conventional Commits (`feat(dispatch): ...`). PRs target `dev`, and `main` is release-only.

### 5.2 `make demo-reset` (golden path)

Goal: a known, reproducible demo state. **The database steps are specified in [DATA_MODEL.md](DATA_MODEL.md) §18.3** (the truncate list, `hawa seed shifts`, `hawa seed history --shift-to-now`, the golden state, the Redis namespaces, Kafka offsets). This section adds the orchestration around them and an optional pipeline-backfill variant.

| Step | Action | Where |
|---|---|---|
| 0 | Guard: refuse unless `HAWA_ENV ∈ {local, demo}` and `--yes`; take `lock:sched:demo_reset`; write `audit.recorded` (`ops.demo_reset`) | CLI |
| 1 | Stop `simulator` and `scheduler` (the Makefile uses compose `stop`; on the AWS stack, desired count → 0) | Makefile |
| 2 | DATA_MODEL §18.3 steps 3–6: truncate the operational tables, keep the registry, reload shifts and golden history, reset the golden device and asset state, delete the Redis namespaces, leave Kafka offsets (or `--recreate-topics`) | `hawa demo-reset` |
| 3 | **Optional backfill variant** (`--backfill-hours 6`): instead of loading golden readings directly, `hawa-sim backfill --hours 6 --scenario golden` publishes 6 h of simulated history over **real MQTT** with original timestamps (inside the 72 h window, flagged `sd_replay`), including 2–3 sprays 3–5 h ago with injected known effects. This exercises ingest, and it gives verified impacts before the demo starts | simulator + pipeline |
| 4 | DATA_MODEL §18.3 step 7: `cmd.twin.rebuild` + master `cmd.forecast.run`, wait for `twin_run.status='succeeded'`; with backfill, also `hawa scheduler trigger verify_scan --force` | CLI |
| 5 | Start `scheduler` and `simulator --scenario golden` (the §8.2 bus-7 spike at a fixed offset and a scripted HawaTag spray with a known injected effect) | Makefile |
| 6 | `hawa demo-check`: twin age < 15 min, ≥ 3 hotspots with causes, forecast issued, ≥ 1 verified impact with CI (backfill variant) or one spray awaiting verification, a real test phone in `HAWA_NOTIFY_ALLOWLIST`, WS reachable, a draft request accepted. Exit 1 with a checklist on failure | CLI (read-only) |

Targets: under 2 minutes with golden history, under 5 minutes with the backfill variant. Every record involved is `is_simulated=true`. The console shows the demo banner ("Simulated fleet · verification on injected known effects", §12.5). Demo-compressed verification windows (`HAWA_DEMO_MODE`) are labelled on screen.

## 6. AWS via CDK (Python, `backend/infra/`)

### 6.1 Tiers

| Tier | When | Shape |
|---|---|---|
| **A: demo on one EC2** | hackathon (fastest path to "live on AWS") | one `m6i.xlarge` (or Graviton equivalent) running the compose stack; **AWS IoT Core** for device identity; `mqtt-bridge` connects to IoT Core over TLS 8883 with an X.509 cert and a policy allowing `iot:Subscribe/Receive` on `hawa/v1/+/+` (shared subscription); Caddy on 443 for TLS; Amplify for web; SNS/WhatsApp for alerts |
| **B: CDK stack** | pilot (and the demo, if time allows) | the stacks in §6.2 |

### 6.2 Stacks

| Stack | Resources | Key settings |
|---|---|---|
| `network` | VPC (2 AZs), public subnets (ALB, NAT), private subnets (ECS, MSK, RDS, Redis), 1 NAT gateway (demo/pilot), S3 gateway endpoint, security groups per tier | no public IPs on tasks; SG rules least-privilege (api → RDS 5432, Redis 6379, MSK 9098; IoT VPC destination → MSK 9096) |
| `data` | **RDS PostgreSQL 16** with the PostGIS extension, **ElastiCache Redis OSS 7**, **S3** buckets `hawa-{env}-lake`, `-media`, `-reports`, `-models` | RDS `db.t4g.medium` (single-AZ demo, Multi-AZ optional in pilot), gp3, `rds.force_ssl=1`, Performance Insights, automated backups + PITR; ElastiCache `cache.t4g.small`, TLS, AUTH, parameter group `maxmemory-policy volatile-lru`; S3 block public access, SSE, versioning on `reports`, lifecycle (lake → IA 30 d → Glacier IR 365 d; media backstop 180 d) |
| `streaming` | **Amazon MSK provisioned** (PCA-01), KMS key, SCRAM secret `AmazonMSK_hawa_iot_rule`, cluster configuration | `kafka.t3.small` × 2 (demo) / × 3 (pilot); IAM auth (services) + SASL/SCRAM (IoT Rule); `auto.create.topics.enable=false`; topics created by the one-off `kafka-init` task |
| `iot` | Thing types per role, things per device, certificates (a provisioning script, or fleet provisioning by claim for real hardware), IoT policy, **IoT Rule Kafka actions** → MSK via a Kafka **VPC destination**, rule error action → S3 | one rule per MQTT suffix (telemetry, event, spray, clip), static `hawa-type` header (PCA-02) |
| `compute` | ECS cluster (Fargate, ARM64), one service per process (§6.5), ALB + ACM cert, Cloud Map namespace `hawa.local` (intel-service), one-off task definitions (`migrate`, `kafka-init`, `seed`, `demo-reset`), ECR repos | deployment circuit breaker with rollback; `stopTimeout` 30 s; Fargate Spot for archiver, evidence-report, audit-writer |
| `ai` | IAM policies for AI-ML task roles: `bedrock:InvokeModel`, `bedrock:InvokeModelWithResponseStream` on the specific foundation-model and inference-profile ARNs | model access enabled per account; use an APAC cross-region inference profile if a model isn't served in `ap-south-1` |
| `messaging` | SNS SMS settings (Transactional, spend limit, sender ID, DLT attributes), SNS topic `hawa-{env}-ops-alarms`, Secrets Manager secrets (§11) | exit the SNS SMS sandbox early; DLT registration for India |
| `observability` | CloudWatch log groups `/hawa/{env}/{service}` (30 d), ADOT collector config (sidecar), X-Ray, Container Insights, CloudWatch dashboard `HawaCommand-GoldenPath`, alarms → `hawa-{env}-ops-alarms` | alarms mirror LOGGING_AND_OBSERVABILITY §14 |
| `web` | **Amplify Hosting** app for `frontend/` (monorepo `appRoot`), custom domain, env `NEXT_PUBLIC_API_BASE_URL`, `NEXT_PUBLIC_WS_URL` | Next.js SSR on Amplify compute |

`cdk-nag` (AwsSolutions pack) runs in `infra/tests`, and suppressions must carry a justification.

### 6.3 Streaming: why MSK provisioned (PCA-01)

- The AWS IoT Rules Kafka action supports `SSL` and `SASL_SSL` with `PLAIN`, `SCRAM-SHA-512` or `GSSAPI`. AWS documents that **MSK Serverless is not supported by that action**, because MSK Serverless is IAM-only. The action also needs broker listener ports in 9000–9100; MSK SCRAM is 9096.
- MSK Serverless's fixed charge (about $0.75 per cluster-hour, so roughly $550 a month before partition-hours) alone exceeds the §12.3 pilot estimate. Two or three `kafka.t3.small` brokers cost well under a fifth of that.
- Services authenticate with IAM (`HAWA_KAFKA_SECURITY=iam`, [EVENTS.md](EVENTS.md) §2.3), and per-service IAM policies grant `kafka-cluster:Connect`, `DescribeTopic`, `ReadData`/`WriteData` on exactly the topics each service uses, plus `DescribeGroup`/`AlterGroup` on its consumer groups.
- If Tier A (EC2) is used for the demo, Kafka stays in compose and the IoT Rule isn't needed (the bridge subscribes to IoT Core).

### 6.4 IoT Core

IoT policy (thing name = device id, for example `HPM-0142`):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    { "Effect": "Allow", "Action": "iot:Connect",
      "Resource": "arn:aws:iot:ap-south-1:<acct>:client/${iot:Connection.Thing.ThingName}" },
    { "Effect": "Allow", "Action": "iot:Publish",
      "Resource": [
        "arn:aws:iot:ap-south-1:<acct>:topic/hawa/v1/${iot:Connection.Thing.ThingName}/telemetry",
        "arn:aws:iot:ap-south-1:<acct>:topic/hawa/v1/${iot:Connection.Thing.ThingName}/event",
        "arn:aws:iot:ap-south-1:<acct>:topic/hawa/v1/${iot:Connection.Thing.ThingName}/spray",
        "arn:aws:iot:ap-south-1:<acct>:topic/hawa/v1/${iot:Connection.Thing.ThingName}/clip" ] },
    { "Effect": "Allow", "Action": "iot:Subscribe",
      "Resource": "arn:aws:iot:ap-south-1:<acct>:topicfilter/hawa/v1/${iot:Connection.Thing.ThingName}/cmd" },
    { "Effect": "Allow", "Action": "iot:Receive",
      "Resource": "arn:aws:iot:ap-south-1:<acct>:topic/hawa/v1/${iot:Connection.Thing.ThingName}/cmd" }
  ]
}
```

IoT Rule (one per suffix; this is `telemetry`):

```json
{
  "sql": "SELECT * FROM 'hawa/v1/+/telemetry'",
  "awsIotSqlVersion": "2016-03-23",
  "actions": [{
    "kafka": {
      "destinationArn": "arn:aws:iot:ap-south-1:<acct>:ruledestination/vpc/<destination-id>",
      "topic": "hawa.telemetry.raw.v1",
      "key": "${topic(3)}",
      "headers": [
        { "key": "hawa-type", "value": "telemetry.raw" },
        { "key": "hawa-mqtt-topic", "value": "${topic()}" },
        { "key": "hawa-received-at", "value": "${timestamp()}" },
        { "key": "content-type", "value": "application/json" }
      ],
      "clientProperties": {
        "bootstrap.servers": "<MSK SASL/SCRAM bootstrap brokers, port 9096>",
        "security.protocol": "SASL_SSL",
        "sasl.mechanism": "SCRAM-SHA-512",
        "sasl.scram.username": "${get_secret('AmazonMSK_hawa_iot_rule', 'SecretString', 'username', '<iot-secrets-role-arn>')}",
        "sasl.scram.password": "${get_secret('AmazonMSK_hawa_iot_rule', 'SecretString', 'password', '<iot-secrets-role-arn>')}",
        "acks": "all",
        "compression.type": "lz4",
        "key.serializer": "StringSerializer",
        "value.serializer": "ByteBufferSerializer"
      }
    }
  }],
  "errorAction": { "s3": { "bucketName": "hawa-pilot-lake", "key": "iot-rule-errors/${timestamp()}-${newuuid()}.json",
                           "roleArn": "<iot-s3-role-arn>" } }
}
```

The simulator can target IoT Core too (`hawa-sim run --aws`): one thing and certificate per simulated device, created by `hawa devices provision --aws --simulated` and marked `is_simulated` in the registry.

### 6.5 Compute (ECS Fargate, ARM64)

| Service | vCPU / GB | Desired (pilot) | Scaling | Exposed |
|---|---|---|---|---|
| api | 0.5 / 1 | 2 | CPU 60 %, 2–6 | ALB 443 → 8000 |
| ingest-worker | 0.5 / 1 | 1 | manual, up to the telemetry partition count | — |
| feeds-worker, scheduler, dispatch-worker, notifier, outbox-relay, alert-engine | 0.25 / 0.5 | 1 each | — | — |
| audit-writer, archiver, evidence-report | 0.25 / 0.5 (evidence 0.5 / 1) | 1 each (Fargate Spot) | — | — |
| schema-registry | 0.5 / 1 | 0 until PCA-24 | — | internal |
| intel-service, intel-worker | per AI-ML | per AI-ML | per AI-ML | Cloud Map `intel.hawa.local:8100` |

- Every task runs the ADOT collector as a sidecar (OTLP → X-Ray; Prometheus scrape of `localhost:8000/9100` → CloudWatch EMF).
- ALB: HTTP → HTTPS redirect. Rules route `/v1/*`, `/open/v1/*`, `/healthz` and `/readyz` to api, and `/metrics` gets a fixed 404. Target health check `/readyz`. Idle timeout 60 s (WebSocket ping every 25 s). Deregistration delay 30 s. An optional AWS WAF rate-based rule on `/open/v1/*` acts as an outer guard.
- The `readyz` migration-head check makes a task refuse traffic if it starts before `migrate` has run.

## 7. Migrations on AWS

1. The pipeline builds and pushes the image `hawa-backend:<git_sha>`.
2. It runs the **one-off ECS task `migrate`** (`alembic upgrade head`, as `hawa_migrator` with credentials from Secrets Manager) and waits for exit 0. A non-zero exit aborts the deploy, and the services keep running the previous image.
3. It runs the one-off `kafka-init` (create missing topics; `--check` for drift).
4. It updates the ECS services to the new image (rolling: minimum healthy 100 %, maximum 200 %, circuit breaker + rollback).

Zero-downtime rules (expand → migrate → contract):
- Add columns as nullable or with defaults, and backfill in a separate revision or job.
- Deploy code that reads both shapes, and only then add constraints or drop old columns in a later release.
- Never rename in place. Never auto-downgrade in `pilot`. Always take a manual RDS snapshot before a pilot migration (pipeline step).
- The partition parent and indexes are Alembic-owned. Child partitions are runtime maintenance (`hawa partitions`, or pg_partman on RDS).

## 8. CI/CD (GitHub Actions)

```yaml
# .github/workflows/backend.yml (sketch; pin actions by commit SHA in the real file)
name: backend
on:
  pull_request:
    paths: ["backend/**", "docs/CONTRACTS.md", ".github/workflows/backend.yml"]
  push:
    branches: [main]
    paths: ["backend/**", "docs/CONTRACTS.md", ".github/workflows/backend.yml"]
permissions: { contents: read, id-token: write }
concurrency: { group: backend-${{ github.ref }}, cancel-in-progress: true }

jobs:
  lint:
    runs-on: ubuntu-latest
    defaults: { run: { working-directory: backend } }
    steps:
      - uses: actions/checkout@v4
      - uses: astral-sh/setup-uv@v6
      - run: uv sync --frozen
      - run: uv run ruff check . && uv run ruff format --check .
      - run: uv run mypy src contracts simulator
      - run: uv run lint-imports
      - run: uv lock --check
      - run: uv run pip-audit --strict || true      # report-only during the hackathon

  test:
    needs: lint
    runs-on: ubuntu-latest                          # Docker available -> testcontainers
    defaults: { run: { working-directory: backend } }
    steps:
      - uses: actions/checkout@v4
      - uses: astral-sh/setup-uv@v6
      - run: uv sync --frozen
      - run: uv run pytest -m "not e2e" -n auto --cov=hawa_backend --cov-report=xml
      - run: uv run hawa contracts export --check   # schemas + OpenAPI snapshot unchanged or committed
      - run: oasdiff breaking origin/main:backend/openapi/openapi.v1.json backend/openapi/openapi.v1.json --fail-on ERR   # API.md §1.10

  migrations:
    needs: lint
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgis/postgis:16-3.4
        env: { POSTGRES_USER: hawa, POSTGRES_PASSWORD: hawa, POSTGRES_DB: hawa }
        ports: ["5432:5432"]
        options: --health-cmd "pg_isready -U hawa" --health-interval 5s --health-retries 20
    defaults: { run: { working-directory: backend } }
    env: { HAWA_MIGRATOR_DATABASE_URL: "postgresql+asyncpg://hawa:hawa@localhost:5432/hawa" }
    steps:
      - uses: actions/checkout@v4
      - uses: astral-sh/setup-uv@v6
      - run: uv sync --frozen
      - run: uv run alembic upgrade head
      - run: uv run alembic check                   # models == migrations (no drift)
      - run: test "$(uv run alembic heads | wc -l)" -eq 1   # single head (DATA_MODEL §17.10)
      - run: uv run alembic downgrade -1 && uv run alembic upgrade head
      - run: uv run pytest tests/db/test_grants.py  # CONTRACTS §8 ownership matrix

  image:
    needs: [test, migrations]
    if: github.event_name == 'push'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: aws-actions/configure-aws-credentials@v4
        with: { role-to-assume: "${{ vars.AWS_DEPLOY_ROLE_ARN }}", aws-region: ap-south-1 }
      - uses: aws-actions/amazon-ecr-login@v2
      - uses: docker/setup-buildx-action@v3
      - run: |
          docker buildx build backend -f backend/docker/Dockerfile \
            --platform linux/arm64 --build-arg GIT_SHA=${{ github.sha }} \
            -t ${{ vars.ECR_REPO }}:${{ github.sha }} --push

  deploy-demo:
    needs: image
    environment: demo                               # GitHub environment with required reviewers
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: aws-actions/configure-aws-credentials@v4
        with: { role-to-assume: "${{ vars.AWS_DEPLOY_ROLE_ARN }}", aws-region: ap-south-1 }
      - run: ./backend/infra/scripts/deploy.sh demo ${{ github.sha }}
        # cdk deploy (if infra/ changed) -> run-task migrate (wait) -> run-task kafka-init
        # -> update services to image tag -> smoke: /readyz, publish one simulated packet via IoT Core,
        #    poll GET /v1/devices/{id} last_seen < 60 s
```

- Path filters keep the web and Flutter PRs from running backend CI. `docs/CONTRACTS.md` changes also trigger the AI-ML contract tests (the AI-ML workflow).
- Deploys authenticate with GitHub OIDC (no long-lived AWS keys), using a deploy role limited to ECR push, ECS run-task/update-service, CloudFormation and CDK bootstrap assets.

## 9. Environment promotion

| From → To | Gate | What moves |
|---|---|---|
| PR → `dev` branch | CI green + 1 review | code |
| `dev` → `main` | CI green, `make e2e` green on the golden path, lead approval | code |
| `main` → **demo** | GitHub environment approval | the **same image digest** built from `main`; config from the SSM Parameter Store / Secrets Manager path `/hawa/demo/*` |
| demo → **pilot** | manual approval + release note + DB snapshot | same digest; `/hawa/pilot/*`; `HAWA_DEMO_MODE=false`, `HAWA_OPEN_INCLUDE_SIMULATED=false`, `HAWA_NOTIFY_ALLOWLIST` empty |

Images are promoted, never rebuilt. Database migrations only move forward. Rollback means redeploying the previous digest, which is compatible because of the expand/contract rules.

## 10. Backups and PITR

| Store | Backup | Restore |
|---|---|---|
| RDS | automated backups + PITR (7 d demo, 14 d pilot); manual snapshot before each pilot migration; optional cross-region snapshot copy | PITR to a new instance → repoint `HAWA_DATABASE_URL` secret → restart services; monthly restore drill that runs `hawa demo-check` against the copy |
| S3 | versioning on `reports` and `media`; lifecycle rules; the lake is itself the long-term archive of readings | object version restore |
| Kafka / MSK | **not a backup**; retention per topic; the DB + lake hold durable history | replay from retention ([EVENTS.md](EVENTS.md) §11) |
| Redis | none needed (cache and coordination only); pointers rebuilt from the DB on startup | automatic |
| Secrets | Secrets Manager versioning | previous version |
| Local | `docker compose exec postgres pg_dump -Fc hawa > backup.dump` before risky experiments | `pg_restore` |

## 11. Secrets and rotation

| Secret (Secrets Manager path) | Consumers | Rotation |
|---|---|---|
| `hawa/{env}/db/master` | bootstrap, admin | RDS-managed rotation, 30 d |
| `hawa/{env}/db/{login}` for each login user (`hawa_migrator`, `hawa_api`, `hawa_ingest`, …, `hawa_ml`) | the matching service | Secrets Manager single-user rotation, 30 d (services reconnect on auth failure) |
| `hawa/{env}/redis/auth` | all | rotate AUTH token with ElastiCache's two-token window, 90 d |
| `AmazonMSK_hawa_iot_rule` | IoT Rule | manual, 90 d (the rule reads it through `get_secret`) |
| `hawa/{env}/jwt/signing` | api | new `kid` every 90 d; JWKS holds current + previous until refresh tokens roll over |
| `hawa/{env}/internal-token` | api, intel-service | `HAWA_INTERNAL_TOKEN_NEXT` accepted alongside the current one, then swapped, 90 d |
| `hawa/{env}/whatsapp` (access token, app secret, verify token, phone number id) | notifier, api | system-user token rotated quarterly; app secret on compromise |
| `hawa/{env}/fcm` (service account JSON) | notifier | key rotation 90 d |
| `hawa/{env}/feeds` (CPCB, OpenAQ, FIRMS keys) | feeds-worker | on expiry / yearly |
| `hawa/{env}/otp-pepper` | api | rotation invalidates only in-flight OTPs (5 min), so rotate any time |

ECS injects secrets as environment variables at task start, so a rotation takes effect on the next deployment or task restart (the pipeline has a "restart services" job). Secrets never appear in images, logs, Kafka or `docker compose config` output shared in chat.

## 12. Cost estimate

§12.3 of the proposal estimates **AWS cloud at pilot scale: ₹4–6 lakh per year**. The backend-side mapping, with approximate on-demand list prices for `ap-south-1` at pilot scale (~160 devices), follows. Verify it with the AWS Pricing Calculator before committing.

| Item | Sizing | ≈ USD / month |
|---|---|---|
| ECS Fargate, backend (ARM64, ADOT sidecars, Spot for 3 workers) | 2 × 0.5 vCPU + 2 × 0.5 vCPU + 8 × 0.25 vCPU | 120–140 |
| ECS Fargate, AI-ML (intel-service, intel-worker) | ~2 vCPU / 6 GB total | 60–80 |
| RDS PostgreSQL + PostGIS | db.t4g.medium single-AZ, 100 GB gp3, backups | 65–80 (Multi-AZ ≈ 2×) |
| ElastiCache Redis | cache.t4g.small, no replica | ~25 |
| **MSK provisioned** | kafka.t3.small × 2, 100 GB each | ~90 |
| ALB | 1 ALB, low LCU | ~25 |
| NAT gateway | 1 NAT + data | ~40 |
| IoT Core | ~160 devices, 2 msgs/min + rules | ~20–25 |
| S3 | lake + media + reports | ~10 |
| CloudWatch (logs 30 d, metrics, alarms, dashboard) + X-Ray | | ~35 |
| Secrets Manager, Route 53, ACM, ECR | | ~10 |
| Amplify Hosting (web) | | ~10 |
| SNS SMS + WhatsApp | pilot volumes, per the current rate cards | ~20–40 |
| Bedrock (AI-ML) | model mix per AI-ML docs | 50–150 |
| **Total** | | **≈ 580–760 / month ≈ ₹5.9–7.8 lakh / year** (at ~₹85/USD) |

Levers to land inside ₹4–6 lakh:
- 1-year Compute Savings Plan for Fargate (about −20 %) and an RDS reserved instance (about −35 %).
- Fargate Spot for every non-latency-critical worker.
- Scale `evidence-report` and `archiver` to zero outside their windows.
- Haiku-class models for the Communicator and routine agent steps (AI-ML).
- A single NAT.

With those, the estimate is **≈ ₹4.5–5.5 lakh / year**. For comparison, MSK Serverless alone would add about ₹5.5 lakh / year (§6.3).

**Demo Tier A:** one `m6i.xlarge` for an event week (~$35–50), IoT Core (cents), and Amplify (free tier), so under ₹5,000 for the event.
