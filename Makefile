# HawaCommand: run the stack from the repository root.
#
# One Python environment (backend/.venv, managed by uv) runs both the backend and the AI-ML engine:
# backend/pyproject.toml depends on hawa-ml (../AI-ML) as an editable path dependency.
#
#   make install      first-time setup: uv sync (backend + AI-ML) and pnpm install (frontend)
#   make db-up        start Postgres (docker compose, backend/docker-compose.yml)
#   make db-update    alembic upgrade head
#   make db-seed      load demo data (idempotent)
#   make aiml-data    build the AI-ML 500 m and 1 km grids once (otherwise the first aiml-api start does it)
#   make aiml-api     AI-ML engine   -> http://127.0.0.1:8100
#   make backend      backend API    -> http://0.0.0.0:8000
#   make frontend     pnpm build + pnpm start -> http://localhost:3000
#
# Override any variable on the command line, e.g.
#   make frontend API_URL=http://<server-ip>:8000
#   make db-update HAWA_DATABASE_URL=sqlite+aiosqlite:///./hawa.db

UV ?= uv
PNPM ?= pnpm

AIML_HOST ?= 127.0.0.1
AIML_PORT ?= 8100
BACKEND_HOST ?= 0.0.0.0
BACKEND_PORT ?= 8000
# Backend URL baked into the web build (NEXT_PUBLIC_API_URL). Empty: use frontend/.env.local, or the built-in mocks.
API_URL ?=

# Pass a database URL through to Alembic and the seed script only when given.
ifdef HAWA_DATABASE_URL
export HAWA_DATABASE_URL
endif

.DEFAULT_GOAL := help
.PHONY: help install db-up db-update db-seed aiml-data aiml-api backend frontend

help:
	@echo "HawaCommand targets (run from the repo root):"
	@echo "  make install     uv sync backend + AI-ML env, pnpm install frontend"
	@echo "  make db-up       start Postgres via docker compose (backend/docker-compose.yml)"
	@echo "  make db-update   alembic upgrade head (HAWA_DATABASE_URL, default postgresql+asyncpg://hawa:hawa@localhost:5432/hawa)"
	@echo "  make db-seed     seed demo data into the database (safe to re-run)"
	@echo "  make aiml-data   build AI-ML grid covariates once (data/processed/)"
	@echo "  make aiml-api    AI-ML engine on $(AIML_HOST):$(AIML_PORT) (10-60 s silent startup)"
	@echo "  make backend     backend API on $(BACKEND_HOST):$(BACKEND_PORT)"
	@echo "  make frontend    pnpm build + pnpm start on port 3000 (API_URL=$(if $(API_URL),$(API_URL),<from .env.local or mocks>))"

install:
	cd backend && $(UV) sync --extra dev
	cd frontend && $(PNPM) install --frozen-lockfile

db-up:
	cd backend && docker compose up -d postgres

db-update:
	cd backend && $(UV) run alembic upgrade head

db-seed:
	cd backend && $(UV) run python -m hawa_backend.db.seed

aiml-data:
	cd AI-ML && $(UV) run --project ../backend python -m hawa_ml.twin.grid

aiml-api:
	@echo "Starting AI-ML engine on $(AIML_HOST):$(AIML_PORT). Loading models takes 10-60 s with no output;"
	@echo "the first start also builds AI-ML/data/processed/grid_covariates_500m.parquet (or run 'make aiml-data' once)."
	@echo "Wait for 'Uvicorn running on ...' before calling it."
	cd AI-ML && $(UV) run --project ../backend uvicorn hawa_ml.api.main:app --host $(AIML_HOST) --port $(AIML_PORT)

backend:
	cd backend && $(UV) run uvicorn hawa_backend.api.app:app --host $(BACKEND_HOST) --port $(BACKEND_PORT)

frontend:
	cd frontend && $(PNPM) install --frozen-lockfile
	cd frontend && $(if $(API_URL),NEXT_PUBLIC_API_URL=$(API_URL) )$(PNPM) build
	cd frontend && $(PNPM) start
