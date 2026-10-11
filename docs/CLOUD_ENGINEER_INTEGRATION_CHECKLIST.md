# Cloud Engineer System Integration Checklist

<!-- nav:start -->

**Navigate:** [Project](../README.md) · [Docs hub](README.md) · [Overview](SYSTEM_OVERVIEW.md) · [AWS architecture](AWS_ARCHITECTURE.md) · [AWS setup](AWS_SETUP_GUIDE.md) · [API](backend/API.md) · [Environment](ENVIRONMENT_VARIABLES.md) · [Contracts](CONTRACTS.md)

**Cloud docs:** [AWS architecture](AWS_ARCHITECTURE.md) · [AWS setup guide](AWS_SETUP_GUIDE.md) · [AWS integration](AWS_INTEGRATION.md) · **Cloud checklist** · [Environment variables](ENVIRONMENT_VARIABLES.md)

<!-- nav:end -->

> **Status (2026-10-11): every item below has backend code.** Each one is off until its variable is set, and falls back to process memory. Console steps for each item: [AWS_SETUP_GUIDE.md](AWS_SETUP_GUIDE.md). Check a deployment with `uv run hawa aws-check` (in `backend/`).
>
> | § | Item | Code | Setup |
> |---|---|---|---|
> | 1 | S3 evidence bucket, pre-signed uploads, photo read-back | `aws/uploads.py`, `POST /v1/uploads/presign`; pre-signed GET URLs and `HeadObject` in `services/reports.py` | done; add `s3:GetObject` (guide step 1) |
> | 1 | CORS, lifecycle | not needed by any client (the app is not a browser); lifecycle is storage cost only | optional |
> | 2 | `hawa-citizen-grievances` + `WardStatusIndex` (+ `OwnerIndex`) | `services/reports.py`, `/v1/reports*` | step 2 |
> | 2 | `hawa-fleet-telemetry` with `ttl_epoch` | `services/fleet.py` | step 3 |
> | 3 | ElastiCache, `geo:fleet:active`, `grid:pm25:500m:*` (TTL 900 s) | `core/redis_store.py`, `services/fleet.py`, `services/twin_cache.py`; also plans, push tokens, sent alerts | step 5 |
> | 4 | Kinesis `hawa-sensor-data` | producer `aws/events.py` (called by `POST /v1/telemetry/vehicles`), consumer `aws/kinesis_consumer.py` | step 4a |
> | 4 | IoT Core rule `hawa/vehicles/+/telemetry` → Kinesis | rule in the guide and `hawa-integration.yaml`; `hawa simulate-fleet --target iot` | step 4b |
> | 5 | SNS topic, email/SMS, test fan-out | `services/alerts.py`, `POST /v1/alerts/broadcast`, `POST /v1/alerts/subscribers`, plan-approval notice | step 6 |
> | 5 | FCM credentials in Secrets Manager | `services/push.py` (FCM HTTP v1), `PUT /v1/me/push-token`; app: Firebase options from build defines, topic subscription | steps 7–8 |
> | 6 | Docker image, ECR, ECS Fargate + ALB + autoscaling | `backend/Dockerfile`, `.github/workflows/backend-image.yml`, `infrastructure/cloudformation/hawa-ecs.yaml` | step 10 |
> | 6 | Route 53 + HTTPS | `hawa-ecs.yaml` (`CertificateArn`), `infrastructure/ec2/Caddyfile` | step 11 |
> | 7 | Least-privilege IAM | policy in guide step 1 and `hawa-integration.yaml` | step 1 |
> | 7 | Secrets Manager for settings | `core/config.py` `bootstrap_secrets` (`HAWA_AWS_SECRETS_ID`) | step 9 |
> | 8 | Smoke tests 1–4 | live audit in `POST /v1/citizen/reports/missed-machine`; WebSocket `/v1/ws/fleet`; app radar reads live data | step 12 |
>
> Differences from the text below: report `status` values are the app's (`submitted`, `verifying`, `verified`, `rejected`, `ticketed`, `closed`; SLA breach is computed), and the SNS topic name is `hawa-citizen-push-alerts`. FCM is called directly by the backend; there is no SNS-to-FCM webhook.

> **Target Environment:** AWS ap-south-1 (Mumbai / Delhi Region)  
> **Project:** Mission_CleanTheAir — HawaCommand & HawaCitizen Ecosystem  
> **Purpose:** Step-by-step production integration checklist to connect the Mobile App, FastAPI Backend, AI-ML Digital Twin, and IoT Fleet Telemetry.

---

## 1. Storage & Media Pipeline (Citizen Photo Evidence)

- [ ] **Create S3 Evidence Bucket (`hawa-citizen-evidence`)**
  - Bucket Name: `hawa-citizen-evidence-prod`
  - Versioning: Enabled
  - Server-Side Encryption: AWS KMS (or AES-256)
  - Public Access Block: All 4 block settings set to `true` (Private bucket)
  ```bash
  aws s3api create-bucket \
    --bucket hawa-citizen-evidence-prod \
    --region ap-south-1 \
    --create-bucket-configuration LocationConstraint=ap-south-1
  ```
- [ ] **Configure S3 CORS Configuration**
  - Allow `PUT`, `GET`, `POST` from Mobile and Web clients for direct presigned uploads.
  ```json
  [
    {
      "AllowedHeaders": ["*"],
      "AllowedMethods": ["GET", "PUT", "POST"],
      "AllowedOrigins": ["*"],
      "ExposeHeaders": ["ETag"],
      "MaxAgeSeconds": 3600
    }
  ]
  ```
- [ ] **Set Lifecycle Transition Policy**
  - Transition images to S3 Standard-Infrequent Access after 30 days.
  - Transition to S3 Glacier Flexible Retrieval after 90 days.
  - Delete expired temporary drafts after 180 days.

---

## 2. NoSQL & State Storage (DynamoDB Tables)

- [ ] **Create Citizen Grievances & Audit Table (`hawa-citizen-grievances`)**
  - Partition Key (PK): `report_id` (String - UUID)
  - Sort Key (SK): `created_at` (String - ISO8601)
  - Billing Mode: `PAY_PER_REQUEST` (On-Demand)
  - Global Secondary Index (GSI-1):
    - GSI PK: `ward_id` (String)
    - GSI SK: `status` (String: `SUBMITTED`, `AI_VERIFIED`, `DISPATCHED`, `RESOLVED`, `SLA_BREACH`)
  - Point-in-time Recovery (PITR): Enabled
  ```bash
  aws dynamodb create-table \
    --table-name hawa-citizen-grievances \
    --attribute-definitions \
        AttributeName=report_id,AttributeType=S \
        AttributeName=created_at,AttributeType=S \
        AttributeName=ward_id,AttributeType=S \
        AttributeName=status,AttributeType=S \
    --key-schema \
        AttributeName=report_id,KeyType=HASH \
        AttributeName=created_at,KeyType=RANGE \
    --global-secondary-indexes \
        "[{\"IndexName\":\"WardStatusIndex\",\"KeySchema\":[{\"AttributeName\":\"ward_id\",\"KeyType\":\"HASH\"},{\"AttributeName\":\"status\",\"KeyType\":\"RANGE\"}],\"Projection\":{\"ProjectionType\":\"ALL\"}}]" \
    --billing-mode PAY_PER_REQUEST \
    --region ap-south-1
  ```

- [ ] **Create Fleet IoT Telemetry Cache Table (`hawa-fleet-telemetry`)**
  - Partition Key: `asset_id` (String, e.g. `SPR-04`, `SMG-12`)
  - Sort Key: `timestamp` (String)
  - TTL Attribute: `ttl_epoch` (Number, auto-expire raw pings after 7 days)

---

## 3. High-Speed Geospatial Caching (Redis / ElastiCache)

- [ ] **Provision ElastiCache Redis Cluster (or Redis Cloud / Docker)**
  - Cluster Mode: Disabled (Single-node / Multi-AZ 2-node for dev)
  - Node Type: `cache.t4g.small` (or `cache.t4g.medium`)
  - Port: `6379`
  - Subnet Group: Private application subnets
- [ ] **Configure Redis Geospatial Indexes for Live Fleet**
  - Verify key: `geo:fleet:active`
  - Test command:
    ```redis
    GEOADD geo:fleet:active 77.3158 28.6476 "SPR-04"
    GEOSEARCH geo:fleet:active FROMLONLAT 77.3158 28.6476 BYRADIUS 5 KM WITHDIST WITHCOORD
    ```
- [ ] **Cache 500m Grid Air Quality Snapshots**
  - Key pattern: `grid:pm25:500m:<timestamp_hour>`
  - Expiration: TTL 900 seconds (15 minutes)

---

## 4. Real-time Telemetry Ingestion (AWS Kinesis / IoT Core)

- [ ] **Verify AWS Kinesis Data Stream (`hawa-sensor-data`)**
  - Stream Mode: `ON_DEMAND`
  - Data Retention: 24 hours
  - Encryption: Enabled (AWS managed KMS key)
  ```bash
  aws kinesis describe-stream --stream-name hawa-sensor-data --region ap-south-1
  ```
- [ ] **Configure IoT Core MQTT Rule for HawaTag Vehicle Trackers**
  - Topic Filter: `hawa/vehicles/+/telemetry`
  - Payload Schema:
    ```json
    {
      "asset_id": "SPR-04",
      "lat": 28.6476,
      "lon": 77.3158,
      "speed_kmh": 14.5,
      "pump_flow_lpm": 48.2,
      "timestamp": "2026-10-08T03:00:00Z"
    }
    ```
  - Action: PutRecord directly into `hawa-sensor-data` Kinesis Stream.

---

## 5. Push Notifications & Alerting (SNS & FCM)

- [ ] **Configure AWS SNS Topic (`hawa-citizen-push-alerts`)**
  - Topic Type: Standard
  - Subscriptions: SMS, Email, and Firebase Cloud Messaging (FCM) HTTPS webhook.
- [ ] **Link Firebase Cloud Messaging (FCM) Credentials**
  - Generate Firebase Service Account JSON for `hawa-cleanair-firebase`.
  - Store credentials securely in AWS Secrets Manager: `hawa/firebase/service-account`.
- [ ] **Test Fanout Broadcast**
  - Publish sample inversion warning payload:
    ```json
    {
      "type": "INVERSION_WARNING",
      "ward": "Rohini",
      "window": "06:00 - 09:30 AM",
      "expected_pm25": 410,
      "message": "Severe morning cold inversion expected tomorrow morning in your ward. Keep vulnerable family members indoors."
    }
    ```

---

## 6. Containerization & Backend Hosting (ECS Fargate / ALB)

- [ ] **Build & Push FastAPI Docker Image to ECR**
  - ECR Repository: `hawa-command-backend`
  - Tag: `v1.0.0`
  ```bash
  aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin <ACCOUNT_ID>.dkr.ecr.ap-south-1.amazonaws.com
  docker build -t hawa-command-backend -f backend/Dockerfile .
  docker tag hawa-command-backend:latest <ACCOUNT_ID>.dkr.ecr.ap-south-1.amazonaws.com/hawa-command-backend:latest
  docker push <ACCOUNT_ID>.dkr.ecr.ap-south-1.amazonaws.com/hawa-command-backend:latest
  ```
- [ ] **Deploy ECS Fargate Service with Application Load Balancer**
  - CPU: 1 vCPU, Memory: 2 GB
  - Desired Tasks: 2 (Auto-scaling up to 6 on CPU > 70%)
  - Target Group Health Check: `GET /health` (Expect 200 OK)
- [ ] **Setup Route53 DNS & ACM SSL Certificate**
  - Public Domain: `api.hawacommand.in` (or hackathon sandbox domain)
  - Enforce HTTPS (TLS 1.3).

---

## 7. Least-Privilege IAM Roles & Security

- [ ] **Attach Backend Task Execution Role Policy**
  - Allow `dynamodb:GetItem`, `dynamodb:PutItem`, `dynamodb:UpdateItem`, `dynamodb:Query` on `hawa-citizen-*` tables.
  - Allow `s3:PutObject`, `s3:GetObject` on `hawa-citizen-evidence-prod`.
  - Allow `sns:Publish` on `hawa-citizen-push-alerts`.
  - Allow `kinesis:PutRecord` on `hawa-sensor-data`.
- [ ] **Audit Secrets Management**
  - Ensure zero hardcoded API keys in repository.
  - Store database credentials, MapTiler keys, and JWT secrets in `AWS Secrets Manager`.

---

## 8. Verification & End-to-End Smoke Test

- [ ] **Smoke Test 1: S3 Direct Upload**
  - Request presigned URL from backend &rarr; upload test PNG &rarr; verify 200 OK.
- [ ] **Smoke Test 2: Safe Route API**
  - Execute `curl -X POST https://api.hawacommand.in/v1/citizen/safe-route` &rarr; verify fastest and cleanest routes returned with microgram dose.
- [ ] **Smoke Test 3: IoT Audit Simulation**
  - Post missed machine flag for `SWP-07` &rarr; confirm `SLA_BREACH_CONFIRMED` response with penalty logged.
- [ ] **Smoke Test 4: Live Fleet Redis Stream**
  - Verify vehicle `SPR-04` telemetry appears on the mobile app radar in < 200 ms.

<!-- footer:start -->

---

[Back to top](#cloud-engineer-system-integration-checklist) · [Docs hub](README.md) · [Project README](../README.md)

<!-- footer:end -->
