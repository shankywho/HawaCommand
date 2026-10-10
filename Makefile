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
#   make aiml-api     AI-ML engine   -> http://0.0.0.0:8100 (uvicorn --reload, uses the active venv)
#   make backend      backend API    -> http://0.0.0.0:8000
#   make frontend     pnpm build + pnpm start -> http://localhost:3000
#   make app-apk      shareable Android APK (staging flavor, backend URL from app_frontend/env/staging.json)
#
# Override any variable on the command line, e.g.
#   make frontend API_URL=http://<server-ip>:8000
#   make db-update HAWA_DATABASE_URL=sqlite+aiosqlite:///./hawa.db

UV ?= uv
PNPM ?= pnpm
FLUTTER ?= fvm flutter
DART ?= fvm dart
# Flutter flavor for `make app-apk`; build defines come from app_frontend/env/$(APP_FLAVOR).json
APP_FLAVOR ?= staging

AIML_HOST ?= 0.0.0.0
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
.PHONY: help install db-up db-update db-seed aiml-data aiml-api backend frontend app-apk

help:
	@echo "HawaCommand targets (run from the repo root):"
	@echo "  make install     uv sync backend + AI-ML env, pnpm install frontend"
	@echo "  make db-up       start Postgres via docker compose (backend/docker-compose.yml)"
	@echo "  make db-update   alembic upgrade head (HAWA_DATABASE_URL, default postgresql+asyncpg://hawa:hawa@localhost:5432/hawa)"
	@echo "  make db-seed     seed demo data into the database (safe to re-run)"
	@echo "  make aiml-data   build AI-ML grid covariates once (data/processed/)"
	@echo "  make aiml-api    AI-ML engine on $(AIML_HOST):$(AIML_PORT) with --reload (activate the venv first)"
	@echo "  make backend     backend API on $(BACKEND_HOST):$(BACKEND_PORT)"
	@echo "  make app-apk     Android APK to share (flavor $(APP_FLAVOR), defines from app_frontend/env/$(APP_FLAVOR).json)"
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
	cd AI-ML && python -m hawa_ml.twin.grid

# Runs uvicorn from the active virtualenv (e.g. `source backend/.venv/bin/activate`), which must have hawa_ml installed.
aiml-api:
	@echo "Starting AI-ML engine on $(AIML_HOST):$(AIML_PORT). The first start builds AI-ML/data/processed/ and can take a minute."
	cd AI-ML && uvicorn hawa_ml.api.main:app --host $(AIML_HOST) --port $(AIML_PORT) --reload

backend:
	cd backend && $(UV) run uvicorn hawa_backend.api.app:app --host $(BACKEND_HOST) --port $(BACKEND_PORT)

frontend:
	cd frontend && $(PNPM) install --frozen-lockfile
	cd frontend && $(if $(API_URL),NEXT_PUBLIC_API_URL=$(API_URL) )$(PNPM) build
	cd frontend && $(PNPM) start

# Universal release APK (one file for every phone), signed with the debug key unless app_frontend/android/key.properties exists.
app-apk:
	cd app_frontend && test -f env/$(APP_FLAVOR).json || cp env/$(APP_FLAVOR).json.example env/$(APP_FLAVOR).json
	cd app_frontend && $(FLUTTER) pub get
	cd app_frontend && $(FLUTTER) gen-l10n
	cd app_frontend && $(DART) run build_runner build --delete-conflicting-outputs
	cd app_frontend && $(FLUTTER) build apk --release --flavor $(APP_FLAVOR) --dart-define-from-file=env/$(APP_FLAVOR).json
	@echo "APK: app_frontend/build/app/outputs/flutter-apk/app-$(APP_FLAVOR)-release.apk"
