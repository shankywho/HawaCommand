"""Causally verified impact and Intervention Effectiveness Library."""
from fastapi import APIRouter
from ...core.intel_client import get_intel_client
from ..fixtures import get_mock_impact, impact_series

router = APIRouter(prefix="/v1/impact", tags=["Causal Impact"])


@router.get("")
async def get_impact_interventions():
    intel = get_intel_client()
    base_data = get_mock_impact()
    # Enrich the first intervention with live causal verification from AI-ML
    if base_data.get("items"):
        first_item = base_data["items"][0]
        verified_impact = await intel.verify_intervention(
            intervention_id=first_item["id"],
            cell_id=first_item.get("cellId", "C-2863-7721"),
            asset=first_item.get("asset", "T-12"),
            action=first_item.get("action", "Water Sprinkler"),
        )
        if verified_impact:
            first_item["impact"] = verified_impact
        impact = first_item["impact"]
        if not impact.get("series"):
            impact["series"] = impact_series(impact, first_item["startedAt"])
    return base_data


@router.get("/library")
async def get_effectiveness_library():
    intel = get_intel_client()
    return await intel.get_effectiveness_library()


@router.post("/{intervention_id}/verify")
@router.get("/{intervention_id}/verify")
async def verify_intervention_endpoint(intervention_id: str):
    intel = get_intel_client()
    return await intel.verify_intervention(intervention_id=intervention_id)


interventions_router = APIRouter(prefix="/v1/interventions", tags=["Interventions"])


@interventions_router.post("/{intervention_id}/verify")
@interventions_router.get("/{intervention_id}/verify")
async def verify_intervention_alias(intervention_id: str):
    intel = get_intel_client()
    return await intel.verify_intervention(intervention_id=intervention_id)



