# Backend deployment

<!-- nav:start -->

**Navigate:** [Project](../../README.md) · [Docs hub](../README.md) · [Overview](../SYSTEM_OVERVIEW.md) · [AWS architecture](../AWS_ARCHITECTURE.md) · [AWS guide](../AWS_SETUP_GUIDE.md) · [API](API.md) · [Environment](../ENVIRONMENT_VARIABLES.md) · [Contracts](../CONTRACTS.md)

**Backend docs:** [Runbook](../../backend/README.md) · [Index](README.md) · [Architecture](ARCHITECTURE.md) · [API](API.md) · [Services](SERVICES.md) · [Data stores](DATA_STORES.md) · [Testing](TESTING.md) · **Deployment**

<!-- nav:end -->

<p align="center">
<img src="https://img.shields.io/badge/runs%20on-Amazon%20EC2-FF9900?logo=amazonec2&logoColor=white" alt="EC2">
<img src="https://img.shields.io/badge/process-PM2-2B037A?logo=pm2&logoColor=white" alt="PM2">
<img src="https://img.shields.io/badge/image-Dockerfile-2496ED?logo=docker&logoColor=white" alt="Docker">
<img src="https://img.shields.io/badge/scale-ECS%20Fargate-FF9900?logo=amazonecs&logoColor=white" alt="ECS Fargate">
<img src="https://img.shields.io/badge/port-8000-6E7781" alt="Port 8000">
</p>

How the FastAPI backend (`backend/`) is deployed, configured, checked and scaled.

---

## Targets

| Target | When | How |
|---|---|---|
| **EC2 + PM2** (live) | One server for the demo and pilots | [§1](#1-ec2-with-pm2) |
| **Docker image** | Any container host | [§2](#2-docker-image) |
| **ECS Fargate + ALB** | More than one instance, autoscaling | [§3](#3-ecs-fargate) |

---

## 1. EC2 with PM2

1. Launch Amazon Linux in ap-south-1 with the role `hawa-backend-ec2-role` ([AWS guide §1](../AWS_SETUP_GUIDE.md#1-iam-give-the-ec2-role-the-new-permissions)).
2. Install the toolchain: `uv`, Node 20 with `pnpm`, and `pm2` (`npm i -g pm2`).
3. Get the code and the environment:
   ```bash
   git clone <repo> ~/HawaCommand && cd ~/HawaCommand
   make install                         # backend/.venv with backend + AI-ML, web deps
   cp backend/.env.example backend/.env # then fill it (see Configuration)
   ```
4. Start everything:
   ```bash
   pm2 start infrastructure/ec2/ecosystem.config.cjs && pm2 save
   ```
5. Security group: open **8000** (API) and **3000** (console); keep **8100** (AI-ML) closed.
6. Verify:
   ```bash
   curl http://localhost:8000/healthz       # {"status":"ok"}
   curl http://localhost:8000/readyz        # which AWS services and Redis are on
   cd backend && uv run hawa aws-check      # one live call per AWS service
   ```

**Update:** `git pull && make install && pm2 restart hawa-backend`.

---

## 2. Docker image

- Build from the **repo root** (the image needs `AI-ML/` too):
  ```bash
  docker build -f backend/Dockerfile -t hawa-command-backend .
  docker run --rm -p 8000:8000 --env-file backend/.env hawa-command-backend
  ```
- Base `python:3.11-slim`, dependencies from `uv.lock`, non-root user, health check on `/healthz`.
- The 500 m grid is pre-built into the image, so the first request is fast.
- No Docker locally: run the GitHub Actions workflow [`backend-image.yml`](../../.github/workflows/backend-image.yml) to build and push to ECR.

---

## 3. ECS Fargate

- Stack: [`hawa-ecs.yaml`](../../infrastructure/cloudformation/hawa-ecs.yaml): cluster, Fargate service (1 vCPU / 2 GB), ALB with `/health` checks, CPU autoscaling at 70 %, CloudWatch logs, optional ACM certificate.
- Console steps: [AWS guide §10](../AWS_SETUP_GUIDE.md#10-optional-container-image-in-ecr-ecs-fargate-and-alb).
- **More than one task needs shared state:** set `HAWA_REDIS_URL` (ElastiCache) and both DynamoDB tables first; otherwise keep the desired count at 1.

---

## Configuration

| Where | What |
|---|---|
| `backend/.env` | All `HAWA_*` settings; read by absolute path, so the working directory does not matter |
| AWS Secrets Manager | Optional JSON secret named by `HAWA_AWS_SECRETS_ID`, loaded at startup |
| Instance or task role | AWS credentials; never put keys in `.env` |

- Precedence: exported variables, then the secret, then `.env`.
- Must set on any server: `HAWA_JWT_SECRET`, `HAWA_ADMIN_API_KEY`, `HAWA_INGEST_API_KEY`.
- Full list: [environment variables](../ENVIRONMENT_VARIABLES.md#1-backend-backendenv).

---

## Operations

| Task | How |
|---|---|
| Logs | `pm2 logs hawa-backend` (EC2) or CloudWatch `/ecs/hawa-command-backend` (ECS) |
| Health | `/healthz` (liveness), `/readyz` (which backends are on) |
| Cloud wiring | `uv run hawa aws-check` |
| Telemetry consumer | In the API (`HAWA_AWS_KINESIS_CONSUMER=true`) or `uv run hawa consume-telemetry`; one per stream |
| Demo traffic | `uv run hawa simulate-fleet --target iot` |
| Database (optional) | `make db-update db-seed`; the API itself keeps state in DynamoDB and Redis |
| HTTPS | Caddy on EC2 ([`Caddyfile`](../../infrastructure/ec2/Caddyfile)) or ACM on the ALB ([AWS guide §11](../AWS_SETUP_GUIDE.md#11-optional-domain-and-https)) |

---

## Related

- [Backend architecture](ARCHITECTURE.md) · [API reference](API.md) · [AWS architecture](../AWS_ARCHITECTURE.md)

<!-- footer:start -->

---

**Related across the project:** [AWS integration guide](../AWS_SETUP_GUIDE.md) · [AI-ML deployment](../aiml/DEPLOYMENT.md) · [Web deployment](../frontend/DEPLOYMENT.md) · [App deployment](../app/DEPLOYMENT.md)

[Back to top](#backend-deployment) · [Docs hub](../README.md) · [Project README](../../README.md)

<!-- footer:end -->
