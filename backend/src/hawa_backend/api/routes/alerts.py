"""Multi-channel school, citizen, and worker alerts."""
from fastapi import APIRouter
from ..fixtures import get_mock_alerts

router = APIRouter(prefix="/v1/alerts", tags=["Alerts"])


@router.get("")
async def list_alerts():
    return get_mock_alerts()
