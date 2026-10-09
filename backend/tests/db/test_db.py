"""Asynchronous unit tests for database models and relationships."""
import pytest
import pytest_asyncio
from datetime import datetime, timezone, timedelta
from sqlalchemy import select
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession
from hawa_backend.db.base import Base
from hawa_backend.db.models import (
    Ward,
    Cell500m,
    School,
    Device,
    Reading,
    Asset,
    Plan,
    PlanTask,
    Intervention,
    Impact,
    AppUser,
    OutboxEvent,
)
from hawa_contracts import uuid7


@pytest_asyncio.fixture
async def test_db_session():
    """Create in-memory SQLite database with all tables for testing."""
    engine = create_async_engine(
        "sqlite+aiosqlite:///:memory:",
        echo=False,
    )
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    session_maker = async_sessionmaker(bind=engine, class_=AsyncSession, expire_on_commit=False)
    async with session_maker() as session:
        yield session

    await engine.dispose()


@pytest.mark.asyncio
async def test_create_ward_and_grid(test_db_session: AsyncSession):
    ward = Ward(
        ward_id="ward-084",
        name="Mundka",
        zone="West",
        population=45000,
        centroid_lat=28.682,
        centroid_lon=77.035,
    )
    test_db_session.add(ward)
    await test_db_session.flush()

    cell = Cell500m(
        cell_id="g500-041-077",
        cell_1km_id="g1k-020-038",
        ward_id="ward-084",
        row=41,
        col=77,
        lat=28.682,
        lon=77.035,
        population=1200,
        is_key_cell=True,
    )
    test_db_session.add(cell)
    await test_db_session.commit()

    res = await test_db_session.execute(select(Ward).where(Ward.ward_id == "ward-084"))
    fetched_ward = res.scalar_one()
    assert fetched_ward.name == "Mundka"


@pytest.mark.asyncio
async def test_device_and_reading_flow(test_db_session: AsyncSession):
    device = Device(
        device_id="HPM-0142",
        role="M",
        placement="mobile",
        status="active",
        trust_score=0.92,
        is_simulated=True,
    )
    test_db_session.add(device)
    await test_db_session.flush()

    reading = Reading(
        reading_id=uuid7(),
        device_id="HPM-0142",
        seq=1,
        ts=datetime.now(timezone.utc),
        lat=28.682,
        lon=77.035,
        cell_500m_id="g500-041-077",
        cell_1km_id="g1k-020-038",
        pm25=145.0,
        pm10=220.0,
        pm25_raw=152.0,
        pm10_raw=230.0,
        rh=60.0,
        t=22.0,
        speed_kmh=15.0,
        indicative_aqi=320,
        is_simulated=True,
    )
    test_db_session.add(reading)
    await test_db_session.commit()

    res = await test_db_session.execute(select(Reading).where(Reading.device_id == "HPM-0142"))
    fetched_reading = res.scalar_one()
    assert fetched_reading.pm25 == 145.0
    assert fetched_reading.is_simulated is True


@pytest.mark.asyncio
async def test_plan_and_intervention_flow(test_db_session: AsyncSession):
    asset = Asset(
        asset_id="AST-SPR-0012",
        kind="sprinkler",
        label="Sprinkler Truck 12",
        ward_id="ward-084",
        status="available",
        is_simulated=True,
    )
    test_db_session.add(asset)
    await test_db_session.flush()

    now_utc = datetime.now(timezone.utc)
    plan_id = uuid7()
    plan = Plan(
        plan_id=plan_id,
        ward_id="ward-084",
        status="draft",
        window_start=now_utc,
        window_end=now_utc + timedelta(hours=4),
        window_label="Thu 06:00-10:00",
        is_simulated=True,
    )
    test_db_session.add(plan)
    await test_db_session.flush()

    task_id = uuid7()
    task = PlanTask(
        task_id=task_id,
        plan_id=plan_id,
        asset_id="AST-SPR-0012",
        op="add",
        time_label="06:30",
        place="Mundka Main Corridor",
        reason="Elevated road dust hotspot near morning commute",
        status="dispatched",
    )
    test_db_session.add(task)
    await test_db_session.flush()

    intervention_id = uuid7()
    intervention = Intervention(
        intervention_id=intervention_id,
        tag_id="HTG-0012",
        asset_id="AST-SPR-0012",
        task_id=task_id,
        start_ts=now_utc,
        end_ts=now_utc + timedelta(minutes=20),
        lat=28.682,
        lon=77.035,
        cell_500m_id="g500-041-077",
        litres_delivered=1200.0,
        flow_avg_lpm=60.0,
        verification_status="verified",
        verify_after=now_utc + timedelta(hours=2),
        is_simulated=True,
    )
    test_db_session.add(intervention)
    await test_db_session.flush()

    impact = Impact(
        impact_id=uuid7(),
        intervention_id=intervention_id,
        pollutant="pm25",
        effect_pct=-18.4,
        ci_low_pct=-24.1,
        ci_high_pct=-12.2,
        p_value=0.012,
        verdict="Verified",
        is_simulated=True,
    )
    test_db_session.add(impact)
    await test_db_session.commit()

    res = await test_db_session.execute(select(Impact).where(Impact.intervention_id == intervention_id))
    fetched_impact = res.scalar_one()
    assert fetched_impact.effect_pct == -18.4
    assert fetched_impact.verdict == "Verified"


@pytest.mark.asyncio
async def test_outbox_event_creation(test_db_session: AsyncSession):
    event = OutboxEvent(
        event_id=uuid7(),
        topic="hawa.plan.lifecycle.v1",
        payload={"plan_id": "test-plan", "status": "drafted"},
        status="pending",
        created_at=datetime.now(timezone.utc),
    )
    test_db_session.add(event)
    await test_db_session.commit()

    res = await test_db_session.execute(select(OutboxEvent).where(OutboxEvent.status == "pending"))
    fetched_event = res.scalar_one()
    assert fetched_event.topic == "hawa.plan.lifecycle.v1"
