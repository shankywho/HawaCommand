"""Central configuration and settings management for HawaCommand AI-ML.

All secrets, credentials, and runtime parameters are loaded strictly from AI-ML/.env.
No other module may call os.getenv directly.
"""
from pathlib import Path
from typing import Optional
from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict

BASE_DIR = Path(__file__).resolve().parents[2]


def mask_secret(val: Optional[str]) -> str:
    """Mask sensitive string, showing only first 4 and last 4 characters."""
    if not val:
        return "[MISSING]"
    s = str(val).strip()
    if len(s) <= 8:
        return "****"
    return f"{s[:4]}...{s[-4:]}"


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=str(BASE_DIR / ".env"),
        env_file_encoding="utf-8",
        extra="ignore",
    )

    # API Keys & Credentials
    OPENAQ_API_KEY: Optional[str] = Field(default=None, description="OpenAQ API key")
    NASA_FIRMS_MAP_KEY: Optional[str] = Field(default=None, description="NASA FIRMS map key for active fire data")
    GROQ_API_KEY: Optional[str] = Field(default=None, description="Groq API key for fast LLM inference")
    BEDROCK_MODEL_ID: Optional[str] = Field(default="anthropic.claude-3-5-sonnet-20241022-v2:0", description="AWS Bedrock model ID")
    WAQI_TOKEN: Optional[str] = Field(default=None, description="World Air Quality Index token")
    CDS_API_KEY: Optional[str] = Field(default=None, description="Copernicus Climate Data Store API key")
    DATA_GOV_IN_API_KEY: Optional[str] = Field(default=None, description="Data.gov.in CPCB API key")

    # AWS Credentials (optional for Bedrock)
    AWS_ACCESS_KEY_ID: Optional[str] = Field(default=None)
    AWS_SECRET_ACCESS_KEY: Optional[str] = Field(default=None)
    AWS_REGION: str = Field(default="ap-south-1")

    # Runtime & Mode Configuration
    LLM_PROVIDER: str = Field(default="groq", description="'groq' or 'bedrock'")
    OFFLINE_MODE: bool = Field(default=False, description="When true, force synthetic and cached fallbacks")
    LOG_LEVEL: str = Field(default="INFO")

    # Paths
    BASE_DIR: Path = BASE_DIR
    DATA_DIR: Path = BASE_DIR / "data"
    RAW_DATA_DIR: Path = BASE_DIR / "data" / "raw"
    INTERIM_DATA_DIR: Path = BASE_DIR / "data" / "interim"
    PROCESSED_DATA_DIR: Path = BASE_DIR / "data" / "processed"
    EXTERNAL_DATA_DIR: Path = BASE_DIR / "data" / "external"
    CACHE_DIR: Path = BASE_DIR / "data" / "cache"
    FIXTURES_DIR: Path = BASE_DIR / "data" / "fixtures"
    MODELS_DIR: Path = BASE_DIR / "models"
    REPORTS_DIR: Path = BASE_DIR / "reports"
    CONFIG_DIR: Path = BASE_DIR / "config"

    def get_masked_status(self) -> dict[str, str]:
        """Return masked key statuses for safe logging and diagnostics."""
        return {
            "OPENAQ_API_KEY": mask_secret(self.OPENAQ_API_KEY),
            "NASA_FIRMS_MAP_KEY": mask_secret(self.NASA_FIRMS_MAP_KEY),
            "GROQ_API_KEY": mask_secret(self.GROQ_API_KEY),
            "BEDROCK_MODEL_ID": self.BEDROCK_MODEL_ID or "[NOT SET]",
            "WAQI_TOKEN": mask_secret(self.WAQI_TOKEN),
            "CDS_API_KEY": mask_secret(self.CDS_API_KEY),
            "DATA_GOV_IN_API_KEY": mask_secret(self.DATA_GOV_IN_API_KEY),
            "AWS_ACCESS_KEY_ID": mask_secret(self.AWS_ACCESS_KEY_ID),
            "AWS_SECRET_ACCESS_KEY": mask_secret(self.AWS_SECRET_ACCESS_KEY),
            "LLM_PROVIDER": self.LLM_PROVIDER,
            "OFFLINE_MODE": str(self.OFFLINE_MODE),
        }

    def __repr__(self) -> str:
        return f"<HawaML Settings: offline={self.OFFLINE_MODE}, provider={self.LLM_PROVIDER}>"

    def __str__(self) -> str:
        return self.__repr__()


# Global singleton settings instance
settings = Settings()
