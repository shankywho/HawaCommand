# AWS integration guide

<!-- nav:start -->

**Navigate:** [Project](../README.md) · [Docs hub](README.md) · [Overview](SYSTEM_OVERVIEW.md) · [AWS architecture](AWS_ARCHITECTURE.md) · **AWS guide** · [API](backend/API.md) · [Environment](ENVIRONMENT_VARIABLES.md) · [Contracts](CONTRACTS.md)

**Cloud docs:** [AWS architecture](AWS_ARCHITECTURE.md) · **AWS integration guide** · [Environment variables](ENVIRONMENT_VARIABLES.md)

<!-- nav:end -->

<p align="center">
<img src="https://img.shields.io/badge/region-ap--south--1%20Mumbai-FF9900?logo=amazonwebservices&logoColor=white" alt="Region">
<img src="https://img.shields.io/badge/checklist-complete-2EA44F" alt="Checklist complete">
<img src="https://img.shields.io/badge/verify-hawa%20aws--check-0969DA" alt="hawa aws-check">
</p>

Why HawaCommand runs on AWS, the integration checklist, and the console steps that set every service up.

- Architecture of each service: [AWS architecture](AWS_ARCHITECTURE.md)
- Every variable: [environment variables](ENVIRONMENT_VARIABLES.md)
- Region: **Asia Pacific (Mumbai) ap-south-1** for everything; check the region picker before each step.
- Starting point: an IAM user, the S3 bucket `hawa-citizen-evidence-prod`, the EC2 role `hawa-backend-ec2-role`, and the backend on EC2 with PM2.
- Every feature switches on when its variable is set and falls back to process memory when it is not.
- After each step, verify on the instance:

```bash
cd ~/HawaCommand/backend && uv run hawa aws-check
```

It prints `[OK]`, `[FAIL]` (with the AWS error) or `[skip]` for each service.

---

## Why AWS

| Need | AWS service | Why this service |
|---|---|---|
| Keep citizen photo evidence private and cheap | S3 | Private bucket, pre-signed uploads straight from the phone, no bytes through the API |
| Grievances queryable by ward and status | DynamoDB | Serverless, pay per request, GSIs for ward and owner, point-in-time recovery |
| Telemetry from many vehicles | IoT Core + Kinesis | MQTT for low-power trackers, an ordered and replayable stream, bursts absorbed |
| A live fleet map in milliseconds | ElastiCache | GEO commands for nearby vehicles, pub/sub for the WebSocket |
| Reach citizens and officials by ward | SNS | Email and SMS with filter policies, no mail server to run |
| No secrets on disk | IAM + Secrets Manager + KMS | Instance role instead of keys, encrypted secrets and streams |
| Plans explained in plain language | Bedrock | Managed LLMs with IAM auth, no API keys |
| Scale past one server | ECR + ECS Fargate + ALB + CloudFormation | Repeatable stacks, autoscaling, rolling deploys |

- **Close to the users:** ap-south-1 keeps latency low for officers and field staff in Delhi.
- **Resilient by design:** each service is optional, so one outage degrades one feature, not the product.
- **Stateless backend:** with DynamoDB and ElastiCache holding state, the API scales from one EC2 instance to many Fargate tasks without code changes.

---

## Integration checklist

Every item has code, a console step below and a check in `hawa aws-check`.

| # | Item | Code | Step | Status |
|---|---|---|---|---|
| 1 | S3 evidence bucket, pre-signed upload and read-back | `aws/uploads.py` | [1](#1-iam-give-the-ec2-role-the-new-permissions) | Done |
| 2 | DynamoDB `hawa-citizen-grievances` + `WardStatusIndex` + `OwnerIndex` | `services/reports.py` | [2](#2-dynamodb-citizen-grievances-table) | Done |
| 3 | DynamoDB `hawa-fleet-telemetry` with `ttl_epoch` | `services/fleet.py` | [3](#3-dynamodb-fleet-telemetry-table) | Done |
| 4 | Kinesis `hawa-sensor-data`, producer and consumer | `aws/events.py`, `aws/kinesis_consumer.py` | [4](#4-kinesis-stream-and-iot-core-rule) | Done |
| 5 | IoT Core rule `hawa/vehicles/+/telemetry` to Kinesis | rule + `hawa simulate-fleet` | [4b](#4b-iot-core-rule) | Done |
| 6 | ElastiCache: `geo:fleet:active`, `grid:pm25:500m:*` | `core/redis_store.py`, `services/twin_cache.py` | [5](#5-elasticache-redisvalkey) | Done |
| 7 | SNS topic, email/SMS, ward-filtered fan-out | `services/alerts.py` | [6](#6-sns-alerts-topic-email-and-sms) | Done |
| 8 | Firebase key in Secrets Manager, push | `services/push.py` | [7](#7-firebase-cloud-messaging-and-its-secrets-manager-secret) | Ready |
| 9 | Least-privilege IAM policy | `hawa-integration.yaml` | [1](#1-iam-give-the-ec2-role-the-new-permissions) | Done |
| 10 | Backend settings from Secrets Manager | `core/config.py` | [9](#9-optional-move-backend-secrets-into-secrets-manager) | Ready |
| 11 | Docker image, ECR, ECS Fargate, ALB, autoscaling | `backend/Dockerfile`, `hawa-ecs.yaml` | [10](#10-optional-container-image-in-ecr-ecs-fargate-and-alb) | Ready |
| 12 | Route 53 + HTTPS | `hawa-ecs.yaml`, `Caddyfile` | [11](#11-optional-domain-and-https) | Ready |
| 13 | Bedrock, SageMaker, Step Functions | `llm_provider.py`, `aws/forecast.py`, `aws/dispatch.py` | [16](#16-optional-bedrock-sagemaker-and-step-functions) | Ready |
| 14 | End-to-end smoke tests | live audit, WebSocket, reports | [12](#12-smoke-tests) | Done |

- **Done:** running on the deployment. **Ready:** code and steps in place, switched on by one variable.
- Report `status` values are the app's (`submitted`, `verifying`, `verified`, `rejected`, `ticketed`, `closed`); an SLA breach is computed on open reports.

---

## Contents

- [Why AWS](#why-aws) · [Integration checklist](#integration-checklist)

0. [Deploy the new code to EC2](#0-deploy-the-new-code-to-ec2)
1. [IAM: give the EC2 role the new permissions](#1-iam-give-the-ec2-role-the-new-permissions)
2. [DynamoDB: citizen grievances table](#2-dynamodb-citizen-grievances-table)
3. [DynamoDB: fleet telemetry table](#3-dynamodb-fleet-telemetry-table)
4. [Kinesis stream and IoT Core rule](#4-kinesis-stream-and-iot-core-rule)
5. [ElastiCache (Redis/Valkey)](#5-elasticache-redisvalkey)
6. [SNS alerts topic, email and SMS](#6-sns-alerts-topic-email-and-sms)
7. [Firebase Cloud Messaging and its Secrets Manager secret](#7-firebase-cloud-messaging-and-its-secrets-manager-secret)
8. [Rebuild the app with the new build defines](#8-rebuild-the-app-with-the-new-build-defines)
9. [Optional: move backend secrets into Secrets Manager](#9-optional-move-backend-secrets-into-secrets-manager)
10. [Optional: container image in ECR, ECS Fargate and ALB](#10-optional-container-image-in-ecr-ecs-fargate-and-alb)
11. [Optional: domain and HTTPS](#11-optional-domain-and-https)
12. [Smoke tests](#12-smoke-tests)
13. [Every variable in one table](#13-every-variable-in-one-table)
14. [Costs and clean-up](#14-costs-and-clean-up)
15. [Next for a city rollout](#15-next-for-a-city-rollout)
16. [Optional: Bedrock, SageMaker and Step Functions](#16-optional-bedrock-sagemaker-and-step-functions)

**Shortcut:** steps 1–4 and the SNS topic in step 6 are also one CloudFormation stack, `infrastructure/cloudformation/hawa-integration.yaml`. In the console go to CloudFormation → **Create stack** → **With new resources** → **Upload a template file**, and set the parameter `BackendRoleName` to `hawa-backend-ec2-role`. It creates the same resources as the console steps below, plus the IoT rule's role. Then continue at step 5.

---

## 0. Deploy the new code to EC2

On your laptop, `backend/.env` is already filled in with every resource name used below, plus three generated secrets: `HAWA_JWT_SECRET`, `HAWA_ADMIN_API_KEY` and `HAWA_INGEST_API_KEY`. Four values are left empty and marked `FILL`; the steps below say where each comes from.

1. Push the code from your laptop and pull it on the instance. SSH in, then:
   ```bash
   cd ~/HawaCommand            # wherever the repo lives on the instance
   git pull
   cd backend && uv sync --extra dev   # new dependencies: boto3, websockets, cryptography
   ```
2. Copy the env file to the instance. From PowerShell on your laptop:
   ```powershell
   scp -i C:\path\to\your-key.pem backend\.env ec2-user@<EC2-PUBLIC-IP>:~/HawaCommand/backend/.env
   ```
   (Use `ubuntu@` on Ubuntu AMIs. You can also open `nano backend/.env` on the instance and paste the contents.)
3. Make sure the instance uses the role: **EC2** → **Instances** → select the instance → **Actions** → **Security** → **Modify IAM role** → `hawa-backend-ec2-role` → **Update IAM role**.
4. Restart the backend:
   ```bash
   pm2 ls                                  # find the backend process name
   pm2 restart hawa-backend --update-env   # or whatever name pm2 ls shows
   ```
   A ready-made PM2 file is in `infrastructure/ec2/ecosystem.config.cjs` (`pm2 start infrastructure/ec2/ecosystem.config.cjs && pm2 save`).
5. Check: `curl http://localhost:8000/readyz` lists which services are on.

The backend reads `backend/.env` itself. AWS credentials come from the instance role, so you never put access keys in the file.

---

## 1. IAM: give the EC2 role the new permissions

The role currently allows `s3:PutObject`. The backend now also reads photos back (`s3:GetObject`, for the photo URLs in the app and to check that an upload exists), and calls DynamoDB, SNS, Kinesis, Secrets Manager and IoT.

1. Find your account ID: click your user name (top right). Copy the 12-digit **Account ID**.
2. **IAM** → **Policies** → **Create policy** → **JSON** tab. Paste the policy below, replacing all six `ACCOUNT_ID` with your account ID:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "EvidencePhotos",
      "Effect": "Allow",
      "Action": ["s3:PutObject", "s3:GetObject"],
      "Resource": "arn:aws:s3:::hawa-citizen-evidence-prod/*"
    },
    {
      "Sid": "Grievances",
      "Effect": "Allow",
      "Action": ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:UpdateItem", "dynamodb:Query", "dynamodb:Scan", "dynamodb:DescribeTable"],
      "Resource": [
        "arn:aws:dynamodb:ap-south-1:ACCOUNT_ID:table/hawa-citizen-grievances",
        "arn:aws:dynamodb:ap-south-1:ACCOUNT_ID:table/hawa-citizen-grievances/index/*"
      ]
    },
    {
      "Sid": "FleetTelemetry",
      "Effect": "Allow",
      "Action": ["dynamodb:PutItem", "dynamodb:Query", "dynamodb:DescribeTable"],
      "Resource": "arn:aws:dynamodb:ap-south-1:ACCOUNT_ID:table/hawa-fleet-telemetry"
    },
    {
      "Sid": "Alerts",
      "Effect": "Allow",
      "Action": ["sns:Publish", "sns:Subscribe", "sns:GetTopicAttributes"],
      "Resource": "arn:aws:sns:ap-south-1:ACCOUNT_ID:hawa-citizen-push-alerts"
    },
    {
      "Sid": "Telemetry",
      "Effect": "Allow",
      "Action": ["kinesis:PutRecord", "kinesis:PutRecords", "kinesis:GetRecords", "kinesis:GetShardIterator", "kinesis:ListShards", "kinesis:DescribeStreamSummary"],
      "Resource": "arn:aws:kinesis:ap-south-1:ACCOUNT_ID:stream/hawa-sensor-data"
    },
    {
      "Sid": "Secrets",
      "Effect": "Allow",
      "Action": "secretsmanager:GetSecretValue",
      "Resource": "arn:aws:secretsmanager:ap-south-1:ACCOUNT_ID:secret:hawa/*"
    },
    {
      "Sid": "FleetSimulatorViaIot",
      "Effect": "Allow",
      "Action": "iot:Publish",
      "Resource": "arn:aws:iot:ap-south-1:ACCOUNT_ID:topic/hawa/vehicles/*"
    }
  ]
}
```

3. **Next** → name it `hawa-backend-access` → **Create policy**.
4. **IAM** → **Roles** → `hawa-backend-ec2-role` → **Add permissions** → **Attach policies** → tick `hawa-backend-access` → **Add permissions**.

Keep your existing S3 policy; overlapping permissions do no harm. Copy the policy ARN (`arn:aws:iam::ACCOUNT_ID:policy/hawa-backend-access`); step 10 reuses it.

**Check:** `uv run hawa aws-check` shows `[OK] S3 hawa-citizen-evidence-prod  PutObject + HeadObject ...`.

---

## 2. DynamoDB: citizen grievances table

Citizen Eyes reports from the app (`POST /v1/reports`) are stored here instead of the app's fake backend.

1. **DynamoDB** → **Tables** → **Create table**.
2. **Table name:** `hawa-citizen-grievances`.
3. **Partition key:** `report_id`, type **String**. **Sort key:** `created_at`, type **String**.
4. **Table settings:** choose **Customize settings** → **Capacity mode: On-demand**.
5. **Secondary indexes** → **Create global index**:
   - Partition key `ward_id` (String), sort key `status` (String), index name `WardStatusIndex`, attribute projections **All** → **Create index**.
6. **Create global index** again:
   - Partition key `owner_id` (String), sort key `created_at` (String), index name `OwnerIndex`, projections **All** → **Create index**.
   (`OwnerIndex` makes "My reports" a query. Without it the backend falls back to scanning the table, which still works.)
7. **Create table**. Wait until the status is **Active** (about a minute).
8. Open the table → **Backups** tab → **Point-in-time recovery (PITR)** → **Edit** → turn it on → **Save changes**.

`HAWA_AWS_GRIEVANCES_TABLE=hawa-citizen-grievances` is already in `.env`.

**What gets stored:** one item per report with `report_id`, `created_at`, `owner_id` (the app user), `ward_id` (the nearest twin cell's ward; `unassigned` until verification runs), `status`, the photo key, location, category, note, verification result, timeline, inspection, outcome and `sla_due_at`.

`status` uses the app's values. The checklist's names map like this: SUBMITTED = `submitted`, AI_VERIFIED = `verified`, DISPATCHED = `ticketed`, RESOLVED = `closed`. An SLA breach is computed: `sla_breach: true` on a report still open after `HAWA_REPORT_SLA_HOURS` (3 h).

**Check:** `aws-check` shows `[OK] DynamoDB hawa-citizen-grievances  table + WardStatusIndex + OwnerIndex`.

---

## 3. DynamoDB: fleet telemetry table

Every HawaTag ping is written here, and pings expire after 7 days. The missed-machine audit reads a vehicle's track from this table.

1. **DynamoDB** → **Tables** → **Create table**.
2. **Table name:** `hawa-fleet-telemetry`. **Partition key:** `asset_id` (String). **Sort key:** `timestamp` (String).
3. **Customize settings** → **On-demand** → **Create table**.
4. Once it is **Active**: open the table → **Additional settings** tab → **Time to Live (TTL)** → **Turn on** → TTL attribute name `ttl_epoch` → **Turn on TTL**.

`HAWA_AWS_FLEET_TABLE=hawa-fleet-telemetry` is already in `.env`.

**Check:** `aws-check` shows `[OK] DynamoDB hawa-fleet-telemetry`.

---

## 4. Kinesis stream and IoT Core rule

The telemetry path is: HawaTag (or the simulator) → IoT Core topic `hawa/vehicles/<asset_id>/telemetry` → IoT rule → Kinesis `hawa-sensor-data` → consumer in the backend → DynamoDB, Redis, and the app's radar.

Pings sent straight to the backend over HTTP (`POST /v1/telemetry/vehicles`) are stored at once and also copied to the stream, marked `via=api` so the consumer skips them.

### 4a. Kinesis data stream

1. **Kinesis** → **Data streams** → **Create data stream**.
2. **Name:** `hawa-sensor-data`. **Capacity mode:** **On-demand** (as in the checklist), or **Provisioned** with **1** shard, which is cheaper for a demo (see [§14](#14-costs-and-clean-up)).
3. **Create data stream**.
4. Open the stream → **Configuration** tab:
   - **Data retention:** leave it at 24 hours.
   - **Encryption** → **Edit** → **Enable server-side encryption** → **Use AWS managed CMK** (`aws/kinesis`) → **Save changes**.

`.env` already has `HAWA_AWS_SENSOR_STREAM=hawa-sensor-data` and `HAWA_AWS_KINESIS_CONSUMER=true` (the consumer runs inside the backend process). Run only one consumer per stream. If you prefer a separate process, set `HAWA_AWS_KINESIS_CONSUMER=false` and enable the commented `hawa-telemetry-consumer` app in `infrastructure/ec2/ecosystem.config.cjs`.

### 4b. IoT Core rule

1. **IoT Core** → **Message routing** → **Rules** → **Create rule**.
2. **Rule name:** `hawa_vehicle_telemetry` → **Next**.
3. **SQL version:** `2016-03-23`. **SQL statement:**
   ```sql
   SELECT *, topic(3) AS asset_id, 'iot' AS source FROM 'hawa/vehicles/+/telemetry'
   ```
   → **Next**.
4. **Rule actions** → **Action 1:** **Kinesis Stream** → **Stream name** `hawa-sensor-data` → **Partition key** `${topic(3)}` → **IAM role:** **Create new role**, name `hawa-iot-to-kinesis` (the console grants it `kinesis:PutRecord` on the stream) → **Next** → **Create**.

### 4c. IoT data endpoint (for the simulator)

**IoT Core** → **Settings** (bottom of the left menu) → copy **Device data endpoint**. It looks like `a1b2c3d4e5f6g7-ats.iot.ap-south-1.amazonaws.com`. In newer consoles it is under **Connect** → **Domain configurations**, as the `iot:Data-ATS` domain.

Put it in `.env`: `HAWA_AWS_IOT_ENDPOINT=a1b2c3d4e5f6g7-ats.iot.ap-south-1.amazonaws.com` (no `https://`). Then restart the backend.

### 4d. Test the whole path

- **From the console:** **IoT Core** → **Test** → **MQTT test client** → **Publish to a topic** → topic `hawa/vehicles/SPR-04/telemetry`. Leave out `timestamp` so the ping counts as current; a fixed old time would put the vehicle outside the 15-minute live window. Use this payload:
  ```json
  {"lat": 28.6476, "lon": 77.3158, "speed_kmh": 14.5, "pump_flow_lpm": 48.2}
  ```
  → **Publish**. Within about 2 seconds, `curl http://localhost:8000/v1/fleet/live` on the instance lists `SPR-04` as `Spraying`.
- **From the instance, a moving demo fleet through IoT Core:**
  ```bash
  cd ~/HawaCommand/backend
  uv run hawa simulate-fleet --target iot     # one round every 10 minutes; Ctrl+C to stop
  ```
  Each round sends one ping per vehicle, so the default is 4 pings every 10 minutes (about 4,000 DynamoDB writes a week). Add `--interval 5` for a fast-moving demo, and stop it afterwards. `--target api` posts to the backend directly (using `HAWA_INGEST_API_KEY`), and `--target kinesis` writes straight to the stream. The demo fleet is SPR-04, SMG-12 and SPR-09 spraying, plus SWP-07 parked at the depot (the ghost-worker case).

**Check:** `aws-check` shows `[OK] Kinesis hawa-sensor-data  ACTIVE, ON_DEMAND, ...` and the IoT endpoint line.

---

## 5. ElastiCache (Redis/Valkey)

Redis holds the live fleet geo index `geo:fleet:active` (`GEOADD` / `GEOSEARCH`), the 500 m twin snapshot `grid:pm25:500m:<hour>` (15-minute TTL), plans, push tokens, sent alerts and the Kinesis checkpoints. It also relays pings between backend processes for the WebSocket. Without Redis, all of this lives in one process's memory, which is fine for a single EC2 process.

ElastiCache is reachable only inside its VPC. Your laptop cannot connect to it, so leave `HAWA_REDIS_URL` empty for local runs.

### 5a. Security group for Redis

1. **EC2** → **Instances** → your instance → **Security** tab → note the **VPC ID** and the **security group** ID (`sg-...`).
2. **EC2** → **Security Groups** → **Create security group**.
   - Name `hawa-redis-sg`, VPC = the instance's VPC.
   - **Inbound rules** → **Add rule**: type **Custom TCP**, port **6379**, source = the instance's security group ID.
   - **Create security group**.

### 5b. The cache

1. **ElastiCache** → **Valkey caches** (or **Redis OSS caches**) → **Create cache**.
2. **Deployment option:** **Design your own cache** → **Standard create**. **Cluster mode:** **Disabled**.
3. **Name:** `hawa-redis`. **Location:** AWS Cloud. Turn **Multi-AZ** off.
4. **Cache settings:** port **6379**, node type **cache.t4g.micro** (the checklist suggests `cache.t4g.small`; micro is plenty for a demo), **Number of replicas: 0**.
5. **Connectivity:** **Create a new subnet group**, name `hawa-redis-subnets`, VPC = the instance's VPC (keep the suggested subnets) → **Next**.
6. **Advanced settings:**
   - **Encryption at rest:** on.
   - **Encryption in transit:** your choice. **Off** means you connect with `redis://`. **On** means you use `rediss://`, and the backend handles TLS.
   - **Access control:** none.
   - **Security groups** → **Manage** → choose `hawa-redis-sg` only.
   - **Automatic backups:** off.
   - **Next** → **Create**.
7. Wait for the status **Available** (about 10 minutes). Open the cache and copy the **Primary endpoint**, without the `:6379`.

Put it in `.env` and restart:

```
HAWA_REDIS_URL=redis://hawa-redis.xxxxxx.ng.0001.aps1.cache.amazonaws.com:6379/0
# with in-transit encryption: rediss://master.hawa-redis.xxxxxx.aps1.cache.amazonaws.com:6379/0
```

**Check:** `aws-check` shows `[OK] Redis  8.x; GEOADD/GEOSEARCH ok (1 hit)`. With some vehicles live, you can also check by hand (Amazon Linux 2023):

```bash
sudo dnf install -y redis6
redis6-cli -h <primary-endpoint> GEOSEARCH geo:fleet:active FROMLONLAT 77.3158 28.6476 BYRADIUS 5 KM WITHDIST WITHCOORD
# add --tls if you enabled in-transit encryption
```

---

## 6. SNS alerts topic, email and SMS

`POST /v1/alerts/broadcast` publishes to this topic, and so does plan approval (one notice per approved plan; set `HAWA_AWS_ALERT_ON_PLAN_APPROVAL=false` to stop that). Every message carries the attributes `type`, `ward` (`all` for city-wide), `severity` and `audience`, so subscribers can filter by ward.

1. **SNS** → **Topics** → **Create topic** → **Standard** → **Name:** `hawa-citizen-push-alerts` → **Create topic**.
2. Copy the **ARN** into `.env`: `HAWA_AWS_ALERTS_TOPIC_ARN=arn:aws:sns:ap-south-1:ACCOUNT_ID:hawa-citizen-push-alerts`. Restart the backend.
3. **Email subscriber:** **Create subscription** → **Protocol: Email** → your address → **Create subscription**, then click **Confirm subscription** in the email AWS sends.
   - **Only one ward's alerts:** expand **Subscription filter policy** → **Message attributes** → enter `{"ward": ["Rohini", "all"]}`.
   - **Same thing from the API:**
     ```bash
     curl -X POST http://localhost:8000/v1/alerts/subscribers -H "X-Api-Key: $HAWA_ADMIN_API_KEY" \
          -H 'content-type: application/json' -d '{"protocol":"email","endpoint":"you@example.com","ward":"Rohini"}'
     ```
4. **SMS (optional):** new accounts are in the SMS sandbox. **SNS** → **Text messaging (SMS)** → **Sandbox destination phone numbers** → **Add phone number** → verify it with the OTP. Then create a subscription with **Protocol: SMS** and the number in E.164 format (`+91...`). India requires sender registration (DLT) for reliable delivery, so use email for demos.

In the commands here, `$HAWA_ADMIN_API_KEY` is the value from `backend/.env`. Export it first, from the `backend/` folder: `export $(grep ^HAWA_ADMIN_API_KEY= .env)`.

**Test (the checklist's fan-out broadcast):**

```bash
curl -X POST http://localhost:8000/v1/alerts/broadcast -H "X-Api-Key: $HAWA_ADMIN_API_KEY" -H 'content-type: application/json' -d '{
  "type": "INVERSION_WARNING", "ward": "Rohini", "window": "06:00 - 09:30 AM", "expected_pm25": 410, "severity": "severe",
  "message": "Severe morning cold inversion expected tomorrow morning in your ward. Keep vulnerable family members indoors."}'
```

The response's `delivered` says `SNS sent · Push sent` once both channels are set up. The email arrives within seconds, and the alert appears first in `GET /v1/alerts` (the web console's Alerts page and the app's inbox).

---

## 7. Firebase Cloud Messaging and its Secrets Manager secret

The backend sends two kinds of push: broadcasts to the topic `hawa-alerts`, which every app install subscribes to, and report status updates to the reporter's own phone. Both use the FCM HTTP v1 API with a Firebase service account read from Secrets Manager.

### 7a. Firebase project and Android app

1. Open <https://console.firebase.google.com> → **Create a project** → name it `hawa-cleanair` (Google Analytics is optional) → **Create project**.
2. **Project settings** (gear icon) → **General** → **Your apps** → **Add app** → **Android**.
   - **Package name:** `in.hawacommand.field.stg`, for the staging APK that `make app-apk` builds. Register `in.hawacommand.field.dev` and `in.hawacommand.field` as well if you build those flavours.
   - **Register app** → **Download google-services.json**. You only need to read values from it; do not commit it. Skip the remaining wizard steps.
3. From `google-services.json`, copy these values (step 8 uses them):

   | App define | Field in google-services.json |
   |---|---|
   | `FIREBASE_API_KEY` | `client[0].api_key[0].current_key` |
   | `FIREBASE_APP_ID` | `client[0].client_info.mobilesdk_app_id` |
   | `FIREBASE_MESSAGING_SENDER_ID` | `project_info.project_number` |
   | `FIREBASE_PROJECT_ID` | `project_info.project_id` |
   | `FIREBASE_STORAGE_BUCKET` | `project_info.storage_bucket` |

4. **Project settings** → **Cloud Messaging** tab: **Firebase Cloud Messaging API (V1)** must show **Enabled**. It is on by default for new projects; if not, enable it through the link shown.

### 7b. Service account key into Secrets Manager

1. **Project settings** → **Service accounts** → **Firebase Admin SDK** → **Generate new private key** → **Generate key**. A JSON file downloads. It is a credential, so keep it out of the repo.
2. AWS console → **Secrets Manager** → **Store a new secret**.
   - **Secret type:** **Other type of secret** → **Plaintext** tab → delete the placeholder and paste the whole JSON file → encryption key `aws/secretsmanager` → **Next**.
   - **Secret name:** `hawa/firebase/service-account` → **Next** → leave rotation off → **Next** → **Store**.
3. In `.env`, set `HAWA_AWS_FCM_SECRET_ID=hawa/firebase/service-account` and restart the backend.

**Check:**

```bash
uv run hawa aws-check              # [OK] Firebase Cloud Messaging  project hawa-cleanair, OAuth token ok
uv run hawa aws-check --push-test  # also sends a test notification to every install on the topic (after step 8)
```

(Instead of Secrets Manager, you can point `HAWA_FCM_SERVICE_ACCOUNT_FILE` at the JSON file on the instance.)

---

## 8. Rebuild the app with the new build defines

The app needs to know which features now live on the backend, and needs the Firebase values. Build defines live in `app_frontend/env/staging.json`. That file was created for you from the tracked template `env/staging.json.example`, and is gitignored.

```json
{
  "FLAVOR": "staging",
  "API_BASE_URL": "http://<EC2-PUBLIC-IP>:8000",
  "WS_URL": "ws://<EC2-PUBLIC-IP>:8000/v1/ws",
  "USE_FAKE_API": true,
  "REAL_FEATURES": "air_map,citizen_air,alerts,school_forecast,citizen_reports,citizen_subscription,push",
  "FIREBASE_API_KEY": "<from 7a>",
  "FIREBASE_APP_ID": "<from 7a>",
  "FIREBASE_MESSAGING_SENDER_ID": "<from 7a>",
  "FIREBASE_PROJECT_ID": "<from 7a>",
  "FIREBASE_STORAGE_BUCKET": "<from 7a>",
  "FCM_TOPIC": "hawa-alerts"
}
```

- `citizen_reports`: photo presign, upload, report submit, "My reports" and report detail all go to the backend. Sign-in, tasks and inspections stay on the in-app fake backend. The backend tells citizens apart by the `sub` of the fake sign-in token.
- `citizen_subscription`: the alert area is saved by the backend.
- `push`: the phone's FCM token is registered with the backend, so report updates reach that phone.
- The **Govt in Action radar** (citizen → live operations) now reads `/v1/citizen/live-operations` and the `/v1/ws/fleet` WebSocket. It shows the "simulated" chip only while no real vehicle is live.

Build from the repo root: `make app-apk`. The APK is at `app_frontend/build/app/outputs/flutter-apk/app-staging-release.apk`. Install it, open the app once, and allow notifications.

---

## 9. Optional: move backend secrets into Secrets Manager

The checklist asks for zero secrets on disk. The backend can load any of its variables from one JSON secret at startup. Precedence is: exported environment variables, then the secret, then `.env`.

1. **Secrets Manager** → **Store a new secret** → **Other type of secret** → **Key/value**. Add these rows, copying the values from `backend/.env`:
   - `HAWA_JWT_SECRET`
   - `HAWA_ADMIN_API_KEY`
   - `HAWA_INGEST_API_KEY`
   - `WAQI_TOKEN` and `OPENAQ_API_KEY`, if you have them
   - `HAWA_REDIS_URL`, if it contains a password
2. **Next** → name `hawa/backend` → **Next** → **Next** → **Store**.
3. In `.env`: set `HAWA_AWS_SECRETS_ID=hawa/backend` and delete the lines you moved. Restart.

**Check:** `aws-check` shows `[OK] Secrets Manager hawa/backend  N keys`.

The role policy from step 1 already allows `secretsmanager:GetSecretValue` on `hawa/*`. The old WAQI and OpenAQ keys in git history (see [ENVIRONMENT_VARIABLES.md §8](ENVIRONMENT_VARIABLES.md#8-security-notes)) should be rotated anyway.

---

## 10. Optional: container image in ECR, ECS Fargate and ALB

Your EC2 + PM2 deployment already runs everything above. Do this only if you want the checklist's container setup.

Run more than one task only after Redis (step 5) and both tables (steps 2–3) are configured. Without Redis, plans and live positions would be split between tasks.

### 10a. ECR repository

**ECR** → **Private registry** → **Repositories** → **Create repository** → name `hawa-command-backend` → **Create**.

### 10b. Build and push the image (you have no Docker locally)

Pick one:

- **GitHub Actions:** the workflow is `.github/workflows/backend-image.yml`.
  1. Create an IAM access key for your IAM user, with the managed policy `AmazonEC2ContainerRegistryPowerUser` attached.
  2. In GitHub, add repository secrets `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` (**Settings** → **Secrets and variables** → **Actions**).
  3. **Actions** → **backend-image** → **Run workflow** (tag `v1.0.0`).
- **On the EC2 instance:** attach `AmazonEC2ContainerRegistryPowerUser` to `hawa-backend-ec2-role` as well, then:
  ```bash
  sudo dnf install -y docker && sudo systemctl enable --now docker && sudo usermod -aG docker $USER && newgrp docker
  cd ~/HawaCommand
  aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin ACCOUNT_ID.dkr.ecr.ap-south-1.amazonaws.com
  docker build -t ACCOUNT_ID.dkr.ecr.ap-south-1.amazonaws.com/hawa-command-backend:v1.0.0 -f backend/Dockerfile .
  docker push ACCOUNT_ID.dkr.ecr.ap-south-1.amazonaws.com/hawa-command-backend:v1.0.0
  ```
  The build needs about 3 GB of free disk.

The image runs `uvicorn` on port 8000, checks its own health on `/healthz`, and runs as a non-root user. AWS credentials come from the task role. Test it locally with `docker run --rm -p 8000:8000 --env-file backend/.env <image>`.

### 10c. ECS Fargate service and load balancer

1. **CloudFormation** → **Create stack** → **With new resources** → **Upload a template file** → `infrastructure/cloudformation/hawa-ecs.yaml`.
2. Parameters:
   - `ImageUri`: the image you pushed.
   - `VpcId`: your VPC.
   - `PublicSubnetIds`: two public subnets in different AZs.
   - `BackendPolicyArn`: the `hawa-backend-access` ARN from step 1.
   - `BackendSecretArn`: the `hawa/backend` secret's ARN (step 9), or empty.
   - `CertificateArn`: empty for now (step 11).
   - `RedisUrl`: from step 5.
   - `DesiredCount` 2 and `MaxCount` 6 once Redis is set; otherwise 1 and 1.
3. Tick **I acknowledge that AWS CloudFormation might create IAM resources** → **Submit**.
4. The **Outputs** tab gives `LoadBalancerDns`. Test with `curl http://<LoadBalancerDns>/health`.

The stack creates:
- the cluster `hawa-cluster`
- the task definition (1 vCPU / 2 GB, the env vars of this guide, logs in `/ecs/hawa-command-backend`)
- the ALB with a target group health check on `GET /health`
- the service, with deployment circuit breaker and CPU target tracking at 70%

Edit the `Environment` block in the template if your names differ. If Redis is in use, add the stack output `TaskSecurityGroupId` as a source in `hawa-redis-sg` (port 6379).

---

## 11. Optional: domain and HTTPS

You need a domain. **Route 53** → **Registered domains** → **Register domains**, or use one you own with a Route 53 hosted zone.

**On the single EC2 instance (Caddy):**

1. Allocate an Elastic IP (**EC2** → **Elastic IPs** → **Allocate** → **Associate** with the instance).
2. **Route 53** → **Hosted zones** → your domain → **Create record** → `api` → type **A** → value: the Elastic IP. Add `app` the same way for the web console.
3. In the instance's security group, open 80 and 443, and close 8000 and 3000 to the internet.
4. Install Caddy (<https://caddyserver.com/docs/install>), then copy `infrastructure/ec2/Caddyfile` to `/etc/caddy/Caddyfile`, put in your hostnames, and run `sudo systemctl reload caddy`. Certificates come from Let's Encrypt automatically, and WebSockets work.

**On the ALB (ECS):**

1. **Certificate Manager (ACM)** → **Request certificate** → **Public** → `api.<domain>` → **DNS validation** → **Request**.
2. Open the certificate → **Create records in Route 53**. Wait for **Issued**.
3. Update the `hawa-ecs` stack with `CertificateArn` set. Port 80 then redirects to 443, with TLS 1.3.
4. **Route 53** → **Create record** → `api` → **Alias** → **Alias to Application and Classic Load Balancer** → ap-south-1 → the ALB.

**Either way, then:**
- Rebuild the web console: `make frontend API_URL=https://api.<domain>`.
- Rebuild the APK with `"API_BASE_URL": "https://api.<domain>"` and `"WS_URL": "wss://api.<domain>/v1/ws"`.

---

## 12. Smoke tests

Run these on the instance (or against your domain).

1. **Everything configured:** `uv run hawa aws-check`. Every configured line is `[OK]`.
2. **S3 direct upload (checklist test 1):** submit a report from the app with a photo, or rerun `aws-check` (it writes `healthcheck/aws-check.txt`).
3. **Safe route (checklist test 2):**
   ```bash
   curl -X POST http://localhost:8000/v1/citizen/safe-route -H 'content-type: application/json' \
        -d '{"origin":{"lat":28.6315,"lon":77.2167},"destination":{"lat":28.5245,"lon":77.2066},"mode":"cycling"}'
   ```
4. **IoT audit (checklist test 3):**
   - Run the simulator for a minute in fast mode: `uv run hawa simulate-fleet --target iot --interval 5`.
   - Then flag the parked sweeper:
     ```bash
     curl -X POST http://localhost:8000/v1/citizen/reports/missed-machine -H 'content-type: application/json' \
          -d '{"asset_id":"SWP-07","cell_id":"G-052-054","ward":"Okhla","lat":28.5300,"lon":77.2700}'
     ```
   - Expect `"evidence_source": "live_telemetry"` and `"verdict": "SLA_BREACH_CONFIRMED"`. The same call for `SPR-04` at `28.6476, 77.3158`, after 15+ minutes of simulation (20+ minutes at the default 10-minute interval), returns `MACHINE_ACTIVE_VERIFIED`.
5. **Live fleet (checklist test 4):**
   - Open the app → citizen → **Govt in Action radar** with the simulator running. Positions update as pings arrive: in local testing a ping reached the WebSocket about 25 ms after it was posted.
   - From a shell, connect with `npx wscat -c ws://<host>:8000/v1/ws/fleet`.
   - In Redis: the `GEOSEARCH` in step 5.
6. **Citizen report end to end:**
   1. Submit a report in the app. "My reports" shows it go **Submitted → Verifying → Verified** within seconds.
   2. In DynamoDB, **Explore items** on `hawa-citizen-grievances` shows the item.
   3. Officer side: list verified reports for the ward.
      ```bash
      curl -H "X-Api-Key: $HAWA_ADMIN_API_KEY" "http://localhost:8000/v1/reports?ward_id=Ward-7&status=verified"
      ```
   4. Ticket the report, then close it with an outcome. Each change sends a push to the phone.
      ```bash
      curl -X PATCH -H "X-Api-Key: $HAWA_ADMIN_API_KEY" -H 'content-type: application/json' \
           -d '{"status":"ticketed"}' http://localhost:8000/v1/reports/<report_id>
      curl -X PATCH -H "X-Api-Key: $HAWA_ADMIN_API_KEY" -H 'content-type: application/json' \
           -d '{"status":"closed","outcome":"closed_confirmed","outcome_text":"Burning stopped, fine issued"}' \
           http://localhost:8000/v1/reports/<report_id>
      ```
   The Swagger UI at `http://<host>:8000/docs` lists every route with **Try it out**; officer routes have an `x-api-key` header field to fill in.
7. **Broadcast:** the curl in step 6. Email arrives, the phone gets a notification, and the alert is listed in the web console.

---

## 13. Every variable in one table

All of these go in `backend/.env`, or in the `hawa/backend` secret (step 9). Rows marked *set* already have their value in the generated `.env`.

| Variable | Value | Where it comes from |
|---|---|---|
| `HAWA_AWS_ENABLED` | `true` | *set* |
| `HAWA_AWS_REGION` | `ap-south-1` | *set* |
| `HAWA_AWS_EVIDENCE_BUCKET` | `hawa-citizen-evidence-prod` | *set* (your bucket) |
| `HAWA_AWS_GRIEVANCES_TABLE` | `hawa-citizen-grievances` | *set*; table from step 2 |
| `HAWA_AWS_FLEET_TABLE` | `hawa-fleet-telemetry` | *set*; table from step 3 |
| `HAWA_AWS_SENSOR_STREAM` | `hawa-sensor-data` | *set*; stream from step 4a |
| `HAWA_AWS_KINESIS_CONSUMER` | `true` | *set*; `false` if you run `hawa consume-telemetry` separately |
| `HAWA_AWS_IOT_ENDPOINT` | `xxxx-ats.iot.ap-south-1.amazonaws.com` | **FILL** from step 4c |
| `HAWA_REDIS_URL` | `redis://<primary endpoint>:6379/0` | **FILL** from step 5 |
| `HAWA_AWS_ALERTS_TOPIC_ARN` | `arn:aws:sns:ap-south-1:<acct>:hawa-citizen-push-alerts` | **FILL** from step 6 |
| `HAWA_AWS_FCM_SECRET_ID` | `hawa/firebase/service-account` | **FILL** after step 7b |
| `HAWA_AWS_SECRETS_ID` | `hawa/backend` | optional, step 9 |
| `HAWA_JWT_SECRET`, `HAWA_ADMIN_API_KEY`, `HAWA_INGEST_API_KEY` | random | *set* (generated) |
| `HAWA_TRUST_CLIENT_TOKENS` | `true` | *set* |
| `HAWA_AWS_ALERT_ON_PLAN_APPROVAL` | `true` | *set* |
| `HAWA_FCM_TOPIC` | `hawa-alerts` | *set*; must match the app's `FCM_TOPIC` |
| `HAWA_FLEET_ACTIVE_MINUTES`, `HAWA_REPORT_SLA_HOURS`, `HAWA_AWS_FLEET_TTL_DAYS` | `15`, `3`, `7` | *set* (defaults) |
| `WAQI_TOKEN`, `OPENAQ_API_KEY` | your keys | optional |

App defines (`app_frontend/env/staging.json`): `API_BASE_URL`, `WS_URL`, `REAL_FEATURES`, `FIREBASE_*`, `FCM_TOPIC` (step 8). Full reference: [ENVIRONMENT_VARIABLES.md](ENVIRONMENT_VARIABLES.md).

---

## 14. Costs and clean-up

These prices are rough figures for low traffic. Check each service's pricing page for ap-south-1.

| Service | Billing |
|---|---|
| DynamoDB on-demand, SNS email, Secrets Manager, IoT Core | Cents at demo traffic. Each secret costs about $0.40 a month. |
| Kinesis | **Charged every hour the stream exists:** on-demand has a per-stream hourly fee; one provisioned shard is cheaper. |
| ElastiCache | **Hourly per node**, even when idle. |
| ECS Fargate and the ALB | **Hourly**, even when idle. |

**One week on a small budget (approximate on-demand prices for ap-south-1, before tax):**

| Item | One week |
|---|---|
| EC2 instance (runs 24/7) | t3.small ~$3.80, t3.medium ~$7.50, t3.large ~$15 |
| Its EBS disk (30 GB gp3) and public IPv4 address | ~$1.50 |
| Kinesis `hawa-sensor-data` | On-demand ~$7–8; provisioned with 1 shard ~$2.50–3 |
| ElastiCache `cache.t4g.micro` (optional) | ~$2–3 |
| DynamoDB (3 tables), S3, IoT Core, Secrets Manager, SNS email, CloudWatch | Under $1 at demo traffic, with the simulator at its default of 4 pings every 10 minutes |
| ECS Fargate and ALB (optional, §10) | ~$8–10 on top of the above |
| Route 53 (optional, §11) | Hosted zone $0.50 a month; a new domain costs a full year up front |

Accounts billed by AWS India (AISPL) pay 18% GST on top. Set a budget alert under **Billing and Cost Management** → **Budgets**; billing data lags by up to a day.

After the demo, delete the stream, the cache, and the ECS stack (CloudFormation → **Delete**). Each of those features then falls back to memory.

---

## 15. Next for a city rollout

- **Sign-in:** Amazon Cognito for officers and citizens, replacing the shared `HAWA_ADMIN_API_KEY` and the app's session-token identity (`HAWA_TRUST_CLIENT_TOKENS`).
- **Officer screens for reports and broadcasts:** the API is complete (`/v1/reports`, `/v1/alerts/broadcast`); the console uses Swagger at `/docs` today.
- **Area-targeted push:** the citizen alert area (`/v1/me/alert-subscription`) is stored; next it filters pushes, as SNS ward filters already do for email and SMS.
- **Vision check on report photos:** today's verification is S3 presence, location and fingerprint rules.
- **Physical HawaTags:** register each tracker under **IoT Core** → **Manage** → **Things** with a certificate and policy; it publishes to the same topic the simulator uses.

---

## 16. Optional: Bedrock, SageMaker and Step Functions

These services are wired in code and switched on by one variable each. The demo runs without them.

### 16a. Bedrock for the agents

- Set in `AI-ML/.env`: `LLM_PROVIDER=bedrock`, `AWS_REGION`, `BEDROCK_MODEL_ID`.
- Console: **Bedrock** → **Model access** → enable the model in the region (or use a cross-region inference profile ID).
- IAM: add `bedrock:InvokeModel` to the role.
- Failure is silent by design: agents fall back to template text. Verify:
  ```bash
  python -c "from hawa_ml.agents.llm_provider import llm_client; print(type(llm_client).__name__, llm_client.generate('Say OK'))"
  ```
  Expect `BedrockLLMClient OK`.

### 16b. SageMaker or Step Functions forecast

- Variable: `HAWA_AWS_FORECAST_ENDPOINT` (SageMaker) or `HAWA_AWS_FORECAST_STATE_MACHINE_ARN` (Express workflow, wins if both are set).
- Used by `GET /v1/forecast/{cell_id}`; results are cached in the DynamoDB table `hawa-cache` (`HAWA_AWS_CACHE_TABLE`).
- Request: `{"cell_id": "<id>"}`. Response must contain a `horizons` list:
  ```json
  {"cell_id": "C-1", "horizons": [{"horizon_h": 1, "pm25_p10": 150.0, "pm25_p50": 200.0, "pm25_p90": 260.0,
    "aqi_p50": 310, "aqi_category": "Very Poor", "grap_stage": "Stage II", "grap_stage_number": 2}]}
  ```
- Easiest handler: wrap `hawa_ml.forecasting.predict.ForecastPredictor().predict_cell_forecast(cell_id)` (horizons 1, 3, 6, 12, 24, 48, 72) in a SageMaker serverless endpoint; package `models/*.txt`, `config/*.yaml` and `hawa_ml/`.
- Verify: `curl -s localhost:8000/v1/forecast/C-1 | jq '.series|length'` prints `73`; the second call is served from `hawa-cache`.

### 16c. Step Functions dispatch on plan approval

- Variable: `HAWA_AWS_DISPATCH_STATE_MACHINE_ARN` (Standard workflow).
- Input sent on approval: `{"planId", "ward", "window": {start, end, label}, "groups": [...]}`; the execution ARN comes back as `executionArn` in the plan.
- Suggested states: DynamoDB `PutItem` (`pk = "dispatch:<planId>"`) then SNS `Publish` to the alerts topic.
- If the workflow publishes to SNS, set `HAWA_AWS_ALERT_ON_PLAN_APPROVAL=false` so officers are not notified twice.
- IAM: `states:StartExecution` for the backend; `dynamodb:PutItem` and `sns:Publish` for the workflow role.

<!-- footer:start -->

---

**Related across the project:** [Data stores](backend/DATA_STORES.md) · [Backend deployment](backend/DEPLOYMENT.md) · [App deployment](app/DEPLOYMENT.md) · [App push](app/NOTIFICATIONS_AND_REALTIME.md) · [Backend testing](backend/TESTING.md)

[Back to top](#aws-integration-guide) · [Docs hub](README.md) · [Project README](../README.md)

<!-- footer:end -->
