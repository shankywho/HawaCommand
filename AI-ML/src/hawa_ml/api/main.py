"""HawaCommand AI-ML Engine FastAPI Application."""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from hawa_ml.settings import settings
from hawa_ml.logging_conf import configure_logging
from hawa_ml.api.routes import router

logger = configure_logging("api_main")

app = FastAPI(
    title="HawaCommand AI-ML Engine API",
    description=(
        "Street-scale sensing, 72-hour forecasting, exposure-first fleet dispatch, "
        "and causal verification for Delhi NCR air pollution mitigation."
    ),
    version="1.0.0",
)

# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount router at root, /v1 (public/backend surface), and /internal/v1 (AI-ML internal surface)
app.include_router(router)
app.include_router(router, prefix="/v1")
app.include_router(router, prefix="/internal/v1")


@app.on_event("startup")
def startup_event():
    logger.info(
        f"HawaCommand AI-ML Engine API started. Mode: offline={settings.OFFLINE_MODE}, "
        f"LLM Provider: {settings.LLM_PROVIDER}"
    )


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("hawa_ml.api.main:app", host="0.0.0.0", port=8000, reload=True)
