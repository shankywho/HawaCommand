"""RFC 9457 Problem Details error models and exception hierarchy."""
from typing import Any, Dict, Optional
from pydantic import BaseModel, Field


class ProblemDetail(BaseModel):
    """RFC 9457 Problem Details payload."""
    type: str = Field("about:blank", description="URI reference identifying the problem type")
    title: str = Field(..., description="Short, human-readable summary")
    status: int = Field(..., description="HTTP status code")
    detail: str = Field(..., description="Human-readable explanation specific to this occurrence")
    code: str = Field(..., description="Machine-readable application error code")
    instance: Optional[str] = Field(None, description="URI reference identifying the specific occurrence")
    invalid_params: Optional[Dict[str, Any]] = None


class HawaException(Exception):
    """Base application exception mapping to RFC 9457."""
    def __init__(
        self,
        status: int,
        code: str,
        title: str,
        detail: str,
        invalid_params: Optional[Dict[str, Any]] = None,
    ):
        super().__init__(detail)
        self.status = status
        self.code = code
        self.title = title
        self.detail = detail
        self.invalid_params = invalid_params

    def to_problem(self, instance: Optional[str] = None) -> ProblemDetail:
        return ProblemDetail(
            type=f"https://hawacommand.in/errors/{self.code}",
            status=self.status,
            code=self.code,
            title=self.title,
            detail=self.detail,
            instance=instance,
            invalid_params=self.invalid_params,
        )


class NotFoundError(HawaException):
    def __init__(self, resource: str, identifier: str):
        super().__init__(
            status=404,
            code="not_found",
            title="Resource Not Found",
            detail=f"{resource} '{identifier}' was not found.",
        )


class ConflictError(HawaException):
    def __init__(self, code: str, detail: str):
        super().__init__(
            status=409,
            code=code,
            title="Conflict",
            detail=detail,
        )


class ValidationError(HawaException):
    def __init__(self, detail: str, invalid_params: Optional[Dict[str, Any]] = None):
        super().__init__(
            status=422,
            code="validation_error",
            title="Unprocessable Entity",
            detail=detail,
            invalid_params=invalid_params,
        )


class ForbiddenError(HawaException):
    def __init__(self, code: str = "forbidden", detail: str = "Access denied"):
        super().__init__(
            status=403,
            code=code,
            title="Forbidden",
            detail=detail,
        )


class UnauthorizedError(HawaException):
    def __init__(self, detail: str = "Authentication required"):
        super().__init__(
            status=401,
            code="unauthorized",
            title="Unauthorized",
            detail=detail,
        )


class RateLimitedError(HawaException):
    def __init__(self, retry_after_seconds: int = 60):
        super().__init__(
            status=429,
            code="rate_limited",
            title="Too Many Requests",
            detail=f"Rate limit exceeded. Retry after {retry_after_seconds} seconds.",
        )


class UpstreamServiceError(HawaException):
    def __init__(self, service_name: str, detail: str):
        super().__init__(
            status=503,
            code="upstream_unavailable",
            title="Service Unavailable",
            detail=f"Upstream service '{service_name}' failed: {detail}",
        )


class AimlUnavailableError(HawaException):
    def __init__(self, detail: str = "AI-ML service unavailable or circuit open"):
        super().__init__(
            status=503,
            code="upstream.aiml_unavailable",
            title="AI-ML Service Unavailable",
            detail=detail,
        )


class AimlTimeoutError(HawaException):
    def __init__(self, detail: str = "AI-ML request timed out"):
        super().__init__(
            status=504,
            code="upstream.timeout",
            title="Gateway Timeout",
            detail=detail,
        )

