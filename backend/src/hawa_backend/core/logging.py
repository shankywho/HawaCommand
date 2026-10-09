"""Structured JSON logging with PII redaction and contextvar injection."""
import json
import logging
import re
from datetime import datetime, timezone
from typing import Any, Dict
from .context import get_current_context

PHONE_RE = re.compile(r"(\+91[\s-]?)?([6-9]\d{2})[\s-]?\d{4}[\s-]?(\d{3,4}\b)")


def mask_phone(text: str) -> str:
    """Mask central digits of phone numbers for privacy."""
    def _repl(m: re.Match) -> str:
        prefix = m.group(1) or ""
        lead = m.group(2)
        tail = m.group(3)
        return f"{prefix}{lead}****{tail[-2:]}"
    return PHONE_RE.sub(_repl, text)


def mask_token(token: str) -> str:
    """Mask API keys, auth tokens, or JWTs."""
    if len(token) <= 8:
        return "***"
    return f"{token[:4]}...{token[-4:]}"


class JSONFormatter(logging.Formatter):
    """Formats log records as single-line JSON objects with context."""
    def format(self, record: logging.LogRecord) -> str:
        ctx = get_current_context()
        log_entry: Dict[str, Any] = {
            "timestamp": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
            "level": record.levelname,
            "logger": record.name,
            "message": mask_phone(record.getMessage()),
            "request_id": ctx.request_id,
            "correlation_id": ctx.correlation_id,
        }
        if ctx.user_id:
            log_entry["user_id"] = ctx.user_id
        if record.exc_info:
            log_entry["exception"] = self.formatException(record.exc_info)
        return json.dumps(log_entry)


def get_logger(name: str) -> logging.Logger:
    """Get or configure a structured logger."""
    logger = logging.getLogger(name)
    if not logger.handlers:
        handler = logging.StreamHandler()
        handler.setFormatter(JSONFormatter())
        logger.addHandler(handler)
        logger.setLevel(logging.INFO)
    return logger
