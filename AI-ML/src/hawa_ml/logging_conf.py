"""Logging configuration with secret scrubbing to prevent accidental credential leakage."""
import logging
import re
import sys
from typing import Optional

# Patterns that match API keys or sensitive authorization parameters
SECRET_PATTERNS = [
    re.compile(r"gsk_[a-zA-Z0-9]{30,}", re.IGNORECASE),
    re.compile(r"AKIA[0-9A-Z]{16}", re.IGNORECASE),
    re.compile(r"Bearer\s+[a-zA-Z0-9_\-\.]{15,}", re.IGNORECASE),
    re.compile(r"(?:api_?key|token|secret|password)=([a-zA-Z0-9_\-]{8,})", re.IGNORECASE),
]


class SecretSanitizingFilter(logging.Filter):
    """Filter that strips out sensitive keys and tokens from log messages."""

    def filter(self, record: logging.LogRecord) -> bool:
        if isinstance(record.msg, str):
            record.msg = self.sanitize(record.msg)
        if record.args:
            if isinstance(record.args, dict):
                record.args = {k: self.sanitize(str(v)) for k, v in record.args.items()}
            elif isinstance(record.args, (list, tuple)):
                record.args = tuple(self.sanitize(str(arg)) for arg in record.args)
        return True

    @staticmethod
    def sanitize(text: str) -> str:
        for pattern in SECRET_PATTERNS:
            text = pattern.sub("[REDACTED_SECRET]", text)
        return text


def configure_logging(level: str = "INFO") -> logging.Logger:
    """Configure root logger with sanitizing filter."""
    numeric_level = getattr(logging, level.upper(), logging.INFO)
    logger = logging.getLogger("hawa_ml")
    logger.setLevel(numeric_level)

    # Avoid duplicate handlers if called multiple times
    if not logger.handlers:
        handler = logging.StreamHandler(sys.stdout)
        handler.setLevel(numeric_level)
        formatter = logging.Formatter(
            fmt="%(asctime)s [%(levelname)s] %(name)s (%(filename)s:%(lineno)d): %(message)s",
            datefmt="%Y-%m-%d %H:%M:%S",
        )
        handler.setFormatter(formatter)
        handler.addFilter(SecretSanitizingFilter())
        logger.addHandler(handler)

    return logger
