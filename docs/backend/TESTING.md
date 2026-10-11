# Backend testing

<!-- nav:start -->

**Navigate:** [Project](../../README.md) · [Docs hub](../README.md) · [Overview](../SYSTEM_OVERVIEW.md) · [AWS architecture](../AWS_ARCHITECTURE.md) · [AWS guide](../AWS_SETUP_GUIDE.md) · [API](API.md) · [Environment](../ENVIRONMENT_VARIABLES.md) · [Contracts](../CONTRACTS.md)

**Backend docs:** [Runbook](../../backend/README.md) · [Index](README.md) · [Architecture](ARCHITECTURE.md) · [API](API.md) · [Services](SERVICES.md) · [Data stores](DATA_STORES.md) · **Testing** · [Deployment](DEPLOYMENT.md)

<!-- nav:end -->

<p align="center">
<img src="https://img.shields.io/badge/pytest-97%20passing-2EA44F?logo=pytest&logoColor=white" alt="pytest">
<img src="https://img.shields.io/badge/AWS-moto-FF9900?logo=amazonwebservices&logoColor=white" alt="moto">
<img src="https://img.shields.io/badge/Redis-fakeredis-DC382D?logo=redis&logoColor=white" alt="fakeredis">
</p>

How the backend is tested without an AWS account or a Redis server.

```bash
cd backend && uv run pytest -q
```

---

## Suites

| File | Tests | Covers |
|---|---|---|
| `tests/api/test_api.py` | 11 | Core routes through ASGI |
| `tests/api/test_all_routes_comprehensive.py` | 8 | Every registered route, plan lifecycle |
| `tests/services/test_reports.py` | 7 | Report contract, verification, officer flow, DynamoDB store, `503` on failure |
| `tests/services/test_fleet.py` | 10 | Ingest, live/nearby/track, Redis GEO, DynamoDB TTL, WebSocket, missed-machine audit |
| `tests/services/test_aws_wiring.py` | 15 | SNS broadcast and subscribers, FCM, Secrets Manager, Kinesis consumer, twin snapshot, Redis plans, `/v1/me` |
| `tests/aws/test_aws_integration.py` | 10 | Forecast cache, Step Functions and SageMaker paths, SNS and Kinesis publishers |
| `tests/integration/test_aiml_integration.py` | 10 | Backend to AI-ML bridge |
| `tests/integration/test_end_to_end.py` | 1 | Packet to plan to verification |
| `tests/core/test_core.py` | 8 | Settings, logging masks, errors, security, clock |
| `tests/db/test_db.py` | 5 | SQLAlchemy models on SQLite |
| `tests/workers/test_workers.py` | 5 | Ingest, simulator, dispatch saga |
| `contracts/tests/test_contracts.py` | 8 | Enums, IDs, packets, topics, Redis keys |

---

## How the fakes work

| Dependency | Test double | Where |
|---|---|---|
| S3, DynamoDB, SNS, Kinesis, Secrets Manager | `moto` (`mock_aws`) | fixtures in each test file |
| Redis | `fakeredis` installed through `redis_store.set_clients()` | `test_fleet.py`, `test_aws_wiring.py` |
| FCM HTTP | `httpx` calls monkeypatched | `test_aws_wiring.py` |
| Twin and attribution | `geo.locate` and `geo.attribute` stubbed | `test_reports.py` |

- `tests/conftest.py` makes every test ignore `backend/.env`, so a configured server file never leaks into tests.
- Tests switch features on with `monkeypatch.setenv(...)` and a settings `cache_clear()`.

---

## Live checks (real AWS)

| Check | Command |
|---|---|
| Every configured service | `uv run hawa aws-check` |
| Test push to all installs | `uv run hawa aws-check --push-test` |
| Demo fleet through IoT Core | `uv run hawa simulate-fleet --target iot` |
| End-to-end smoke tests | [AWS guide §12](../AWS_SETUP_GUIDE.md#12-smoke-tests) |

---

## Notes

- The AI-ML engine rewrites a few tracked files under `AI-ML/data/` during tests; run `git checkout -- AI-ML/data` before committing.
- LightGBM needs the model files with LF line endings; `.gitattributes` enforces it on Windows.

---

## Related

- [Services](SERVICES.md) · [Data stores](DATA_STORES.md) · [Backend runbook](../../backend/README.md)

<!-- footer:start -->

---

**Related across the project:** [End-to-end smoke tests](../AWS_SETUP_GUIDE.md#12-smoke-tests) · [AI-ML runbook](../../AI-ML/README.md) · [AWS architecture](../AWS_ARCHITECTURE.md)

[Back to top](#backend-testing) · [Docs hub](../README.md) · [Project README](../../README.md)

<!-- footer:end -->
