"""FastAPI application factory, CORS, exception handlers, and routing."""
import asyncio
import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from ..core.config import bootstrap_secrets, get_settings

# Pull HAWA_AWS_SECRETS_ID (Secrets Manager) into the environment before any settings or hawa_ml import.
bootstrap_secrets()

from ..aws.settings import get_aws_settings  # noqa: E402
from ..core.context import bind_context  # noqa: E402
from ..core.errors import HawaException  # noqa: E402
from .routes import (  # noqa: E402
    health,
    hotspots,
    forecast,
    plans,
    devices,
    impact,
    alerts,
    driver,
    open_data,
    citizen,
    uploads,
    reports,
    me,
    fleet,
)

logger = logging.getLogger("hawa_backend.app")


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Starts the Kinesis telemetry consumer in this process when HAWA_AWS_KINESIS_CONSUMER=true."""
    aws = get_aws_settings()
    stop = asyncio.Event()
    task = None
    if aws.enabled and aws.sensor_stream and aws.kinesis_consumer:
        from ..aws.kinesis_consumer import run

        task = asyncio.create_task(run(stop))
        logger.info("Kinesis consumer started for %s", aws.sensor_stream)
    try:
        yield
    finally:
        stop.set()
        if task is not None:
            task.cancel()
            await asyncio.gather(task, return_exceptions=True)


def create_app() -> FastAPI:
    """Create and configure the main HawaCommand FastAPI application."""
    settings = get_settings()

    app = FastAPI(
        title="HawaCommand Command Center API",
        description="Air Quality AI Command Center for Delhi - REST and WebSocket API",
        version="0.1.0",
        docs_url="/docs",
        redoc_url="/redoc",
        openapi_url="/openapi.json",
        lifespan=lifespan,
    )

    # Enable CORS for the Next.js web console and Flutter clients
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    @app.middleware("http")
    async def context_middleware(request: Request, call_next):
        """Bind request context from headers."""
        req_id = request.headers.get("x-request-id")
        corr_id = request.headers.get("x-correlation-id")
        bind_context(request_id=req_id, correlation_id=corr_id)
        
        response = await call_next(request)
        if req_id:
            response.headers["x-request-id"] = req_id
        if corr_id:
            response.headers["x-correlation-id"] = corr_id
        return response

    @app.exception_handler(HawaException)
    async def hawa_exception_handler(request: Request, exc: HawaException):
        """Render domain exceptions according to RFC 9457 Problem Details."""
        problem = exc.to_problem(instance=request.url.path)
        return JSONResponse(
            status_code=exc.status,
            content=problem.model_dump(exclude_none=True),
            headers={"content-type": "application/problem+json"},
        )

    # Register Route Handlers
    app.include_router(health.router)
    app.include_router(hotspots.router)
    app.include_router(forecast.router)
    app.include_router(plans.router)
    app.include_router(devices.router)
    app.include_router(impact.router)
    app.include_router(impact.interventions_router)
    app.include_router(alerts.router)
    app.include_router(driver.router)
    app.include_router(open_data.router)
    app.include_router(citizen.router)
    app.include_router(uploads.router)
    app.include_router(reports.router)
    app.include_router(me.router)
    app.include_router(fleet.router)

    return app



# Default application instance for ASGI servers
app = create_app()
