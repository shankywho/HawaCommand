"""FastAPI application factory, CORS, exception handlers, and routing."""
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from ..core.config import get_settings
from ..core.context import bind_context
from ..core.errors import HawaException
from .routes import (
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
)


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

    return app



# Default application instance for ASGI servers
app = create_app()
