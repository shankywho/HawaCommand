"""Citizen Eyes reports (app contract: POST /v1/reports, GET /v1/reports/mine, GET /v1/reports/{id}) and
the officer side (list by ward/status, change status). Storage: services/reports.py."""
import hmac
import logging
from typing import Literal, Optional

from fastapi import APIRouter, BackgroundTasks, Depends, Header, HTTPException, Query, Request

from ...core.config import get_settings
from ...core.identity import ANONYMOUS, caller_id, require_admin_key
from ...services import reports
from ...services._util import iso, utcnow

logger = logging.getLogger("hawa_backend.routes.reports")

router = APIRouter(prefix="/v1/reports", tags=["Citizen reports"])

STORE_DOWN = "Report storage is unavailable; retry shortly"


async def _verify_safely(report_id: str) -> None:
    try:
        await reports.verify(report_id)
    except Exception as exc:
        logger.warning("verification of report %s failed: %s", report_id, exc)


def _is_admin(x_api_key: Optional[str]) -> bool:
    key = get_settings().admin_api_key
    return bool(key and x_api_key and hmac.compare_digest(key, x_api_key))


@router.post("", status_code=202)
async def create_report(req: reports.ReportCreateIn, request: Request, background: BackgroundTasks):
    """Store a report whose photo was uploaded through POST /v1/uploads/presign; verification runs next."""
    try:
        item = await reports.create(caller_id(request), req)
    except ValueError as exc:
        raise HTTPException(status_code=422, detail=str(exc))
    except reports.StoreUnavailable:
        raise HTTPException(status_code=503, detail=STORE_DOWN)
    if item["status"] == "submitted":
        background.add_task(_verify_safely, item["report_id"])
    return reports.create_out(item)


@router.get("/mine")
async def my_reports(
    request: Request,
    limit: int = Query(50, ge=1, le=100),
    cursor: Optional[str] = Query(None, description="Not used yet; every call returns the newest `limit`"),
):
    try:
        items = await reports.mine(caller_id(request), limit)
    except reports.StoreUnavailable:
        raise HTTPException(status_code=503, detail=STORE_DOWN)
    return {"items": [reports.list_item(i) for i in items], "next_cursor": None}


@router.get("", dependencies=[Depends(require_admin_key)])
async def list_reports(
    ward_id: Optional[str] = Query(None, description="Ward, e.g. Ward-3 (uses the WardStatusIndex GSI)"),
    status: Optional[Literal["submitted", "verifying", "verified", "rejected", "ticketed", "closed"]] = None,
    limit: int = Query(100, ge=1, le=500),
):
    """Officer view: reports by ward and status, with reporter, PM2.5 and SLA breach flags."""
    try:
        items = await reports.by_ward(ward_id, status, limit)
    except reports.StoreUnavailable:
        raise HTTPException(status_code=503, detail=STORE_DOWN)
    now = utcnow()
    views = [reports.officer_view(i, now) for i in items]
    return {
        "asOf": iso(now),
        "count": len(views),
        "slaBreaches": sum(1 for v in views if v["sla_breach"]),
        "items": views,
    }


@router.get("/{report_id}")
async def get_report(report_id: str, request: Request, x_api_key: Optional[str] = Header(None)):
    try:
        item = await reports.get(report_id)
    except reports.StoreUnavailable:
        raise HTTPException(status_code=503, detail=STORE_DOWN)
    admin = _is_admin(x_api_key)
    if not item or (not admin and item.get("owner_id") not in (caller_id(request), ANONYMOUS)):
        raise HTTPException(status_code=404, detail=f"Report '{report_id}' not found")
    return reports.officer_view(item) if admin else reports.detail(item)


@router.patch("/{report_id}", dependencies=[Depends(require_admin_key)])
async def update_report(report_id: str, req: reports.ReportUpdateIn):
    """Officer action: ticketed (assign an inspection), closed (with an outcome) or rejected.
    The reporter gets a push notification when FCM is configured."""
    try:
        item = await reports.update_status(report_id, req)
    except reports.ReportNotFound:
        raise HTTPException(status_code=404, detail=f"Report '{report_id}' not found")
    except reports.BadTransition as exc:
        raise HTTPException(status_code=409, detail=str(exc))
    except reports.StoreUnavailable:
        raise HTTPException(status_code=503, detail=STORE_DOWN)
    return reports.officer_view(item)


@router.post("/{report_id}/verify", dependencies=[Depends(require_admin_key)])
async def reverify_report(report_id: str):
    """Run the automated verification again for a report stuck in `submitted`."""
    try:
        item = await reports.verify(report_id)
    except reports.StoreUnavailable:
        raise HTTPException(status_code=503, detail=STORE_DOWN)
    if not item:
        raise HTTPException(status_code=404, detail=f"Report '{report_id}' not found")
    return reports.officer_view(item)
