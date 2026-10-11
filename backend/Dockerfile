# HawaCommand backend API (FastAPI) with the AI-ML engine (hawa_ml) running in process.
#
# Build from the repository root: the image needs backend/ and AI-ML/.
#   docker build -t hawa-command-backend -f backend/Dockerfile .
#   docker run --rm -p 8000:8000 --env-file backend/.env hawa-command-backend
#
# On AWS give the container an IAM role (ECS task role / EC2 instance role) instead of access keys.
# Health check: GET /healthz.

FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    UV_PYTHON_DOWNLOADS=never \
    UV_PROJECT_ENVIRONMENT=/opt/venv \
    PATH=/opt/venv/bin:$PATH

# libgomp1: OpenMP runtime for LightGBM. curl: container health check.
RUN apt-get update \
    && apt-get install -y --no-install-recommends libgomp1 curl \
    && rm -rf /var/lib/apt/lists/* \
    && pip install --no-cache-dir uv==0.12.23 \
    && useradd --create-home --uid 10001 hawa

WORKDIR /app

# Dependencies first, so code-only changes reuse this layer.
COPY backend/pyproject.toml backend/uv.lock backend/.python-version backend/README.md backend/
COPY backend/contracts backend/contracts
COPY AI-ML AI-ML
RUN cd backend && uv sync --frozen --no-install-project

COPY backend/src backend/src
COPY backend/alembic.ini backend/alembic.ini
COPY backend/migrations backend/migrations
RUN cd backend && uv sync --frozen

# Pre-build the 500 m / 1 km grid covariates so the first request does not wait for them
# (falls back to building on first use if OSM is unreachable during the build).
RUN cd AI-ML && python -m hawa_ml.twin.grid > /dev/null 2>&1 || echo "grid will be built on first request"

RUN chown -R hawa:hawa /app
USER hawa
WORKDIR /app/backend

EXPOSE 8000
HEALTHCHECK --interval=30s --timeout=5s --start-period=90s --retries=3 \
    CMD curl -fsS http://127.0.0.1:8000/healthz || exit 1

# --proxy-headers: behind an ALB / Caddy, trust X-Forwarded-* so URLs and client IPs are right.
CMD ["uvicorn", "hawa_backend.api.app:app", "--host", "0.0.0.0", "--port", "8000", "--proxy-headers", "--forwarded-allow-ips", "*"]
