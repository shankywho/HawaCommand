"""Intervention plans, reviews, approvals, and What-If comparisons."""
from datetime import datetime, timezone, timedelta
from typing import Any, Dict, List, Optional
from fastapi import APIRouter, HTTPException, Path
from pydantic import BaseModel
from ...aws import start_dispatch

router = APIRouter(prefix="/v1/plans", tags=["Plans"])


class DraftPlanRequest(BaseModel):
    ward: str
    windowStart: Optional[str] = None


class ApprovePlanRequest(BaseModel):
    note: Optional[str] = None


class RequestChangesRequest(BaseModel):
    note: str


DEFAULT_PLAN_ID = "214"

# In-memory store for interactive plan state mutations
_ACTIVE_PLANS: Dict[str, Dict[str, Any]] = {}


def _get_or_create_default_plan(plan_id: str = "214") -> Dict[str, Any]:
    if plan_id not in _ACTIVE_PLANS:
        now_dt = datetime.now(timezone.utc)
        start_dt = now_dt + timedelta(hours=10)
        end_dt = start_dt + timedelta(hours=4)
        
        _ACTIVE_PLANS[plan_id] = {
            "id": plan_id,
            "ward": "ward-084",
            "window": {
                "start": start_dt.isoformat().replace("+00:00", "Z"),
                "end": end_dt.isoformat().replace("+00:00", "Z"),
                "label": "Thu 06:00 – 10:00",
            },
            "status": "draft",
            "draftedAt": now_dt.isoformat().replace("+00:00", "Z"),
            "draftedBy": "AI-ML Planner (Claude Opus 5)",
            "headline": {
                "protectedPct": 42.0,
                "peopleHoursSaved": 14200.0,
                "likelyRange": [11500.0, 16800.0],
                "peopleHoursUsual": 34000.0,
                "peopleHoursPlan": 19800.0,
                "assetsUsed": 8,
                "assetsTotal": 10,
                "extraKm": 14.5,
                "confidence": 0.88,
            },
            "summary": "Focuses mechanical sweepers on GT Road dust corridor before 07:00 AM rush hour, and positions 2 water sprinklers near Mundka school cluster prior to 08:00 AM assembly.",
            "reasoning": "High PM2.5 (380 ug/m3) forecast at 08:00 combined with low boundary layer. Priority shift to Mundka avoids 14,200 person-hours of severe exposure.",
            "groups": [
                {
                    "asset": "T-12",
                    "kind": "sprinkler",
                    "label": "Sprinkler 12 (West)",
                    "tasks": [
                        {
                            "id": "tsk-01",
                            "op": "add",
                            "time": "06:10",
                            "place": "Mundka Metro Corridor",
                            "action": "Median misting",
                            "cause": "Dust",
                            "causeConf": 0.82,
                            "reason": "Target unpaved shoulder near bus stops before pedestrian peak",
                        },
                        {
                            "id": "tsk-02",
                            "op": "add",
                            "time": "07:30",
                            "place": "Sarvodaya Vidyalaya Perimeter",
                            "action": "Boundary water curtain",
                            "cause": "Dust",
                            "causeConf": 0.78,
                            "reason": "Protect school grounds 30 minutes before morning assembly",
                            "flag": "auditor",
                        },
                    ],
                }
            ],
            "comments": [
                {
                    "id": "com-01",
                    "taskId": "tsk-02",
                    "status": "open",
                    "objection": "Sprinkler allocated within 100 m of CPCB station site_301; anti-gaming guard triggered.",
                    "confidence": 0.92,
                    "suggestion": {
                        "remove": "tsk-02",
                        "add": "Relocate spray curtain 250 m upwind to North-West perimeter",
                    },
                }
            ],
            "checks": [
                {"id": "chk-01", "label": "No water on open burning", "detail": "All sprinkler routes target Dust only", "ok": True},
                {"id": "chk-02", "label": "Anti-gaming guard", "detail": "Station proximity verified", "ok": True},
                {"id": "chk-03", "label": "Driver shift limits", "detail": "All routes under 4.0 hours active duty", "ok": True},
            ],
        }
    return _ACTIVE_PLANS[plan_id]


def _require_plan(plan_id: str) -> Dict[str, Any]:
    """The seeded demo plan or a plan drafted this session; anything else is a 404."""
    if plan_id == DEFAULT_PLAN_ID or plan_id in _ACTIVE_PLANS:
        return _get_or_create_default_plan(plan_id) if plan_id == DEFAULT_PLAN_ID else _ACTIVE_PLANS[plan_id]
    raise HTTPException(status_code=404, detail=f"Plan '{plan_id}' not found")


@router.get("")
async def list_plans():
    _get_or_create_default_plan(DEFAULT_PLAN_ID)
    now_iso = datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")
    plans = sorted(_ACTIVE_PLANS.values(), key=lambda p: p.get("draftedAt", ""), reverse=True)
    return {
        "asOf": now_iso,
        "simulated": True,
        "items": plans,
    }


@router.get("/{plan_id}")
async def get_plan_detail(plan_id: str = Path(...)):
    return _require_plan(plan_id)


@router.post("/draft")
async def draft_plan(req: DraftPlanRequest):
    from ...core.intel_client import get_intel_client
    intel = get_intel_client()
    plan = await intel.draft_plan(ward=req.ward, window_start=req.windowStart)
    plan_id = plan["id"]
    _ACTIVE_PLANS[plan_id] = plan
    return plan


@router.post("/{plan_id}/approve")
async def approve_plan(plan_id: str = Path(...), req: Optional[ApprovePlanRequest] = None):
    plan = _require_plan(plan_id)
    plan["status"] = "approved"
    plan["approvedAt"] = datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")
    if req and req.note:
        plan["approvalNote"] = req.note
    arn = await start_dispatch(plan)
    if arn:
        plan["executionArn"] = arn
    else:
        plan.pop("executionArn", None)
    return plan


@router.post("/{plan_id}/request-changes")
async def request_changes(plan_id: str = Path(...), req: RequestChangesRequest = ...):
    plan = _require_plan(plan_id)
    plan["status"] = "changes_requested"
    plan["changesNote"] = req.note
    return plan


@router.post("/{plan_id}/suggestions/{comment_id}/apply")
async def apply_suggestion(plan_id: str = Path(...), comment_id: str = Path(...)):
    plan = _require_plan(plan_id)
    for c in plan.get("comments", []):
        if c["id"] == comment_id:
            c["status"] = "applied"
    return plan


@router.get("/{plan_id}/compare")
@router.post("/{plan_id}/simulate")
async def compare_plan(plan_id: str = Path(...)):
    from ...core.intel_client import get_intel_client
    intel = get_intel_client()
    return await intel.simulate_plan(plan_id=plan_id)


