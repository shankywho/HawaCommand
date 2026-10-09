"""Dependency injection and service singletons for FastAPI serving layer."""
from hawa_ml.settings import settings
from hawa_ml.twin.kriging import twin_engine
from hawa_ml.forecasting.predict import forecaster
from hawa_ml.forecasting.grap import grap_engine
from hawa_ml.exposure.engine import exposure_engine
from hawa_ml.attribution.rules import rule_attribution
from hawa_ml.attribution.classifier import attribution_classifier
from hawa_ml.causal.effectiveness_library import effectiveness_library
from hawa_ml.optimization.vrp import vrp_optimizer
from hawa_ml.optimization.whatif import whatif_simulator
from hawa_ml.calibration.drive_by import drive_by_calibrator
from hawa_ml.agents.forecaster_agent import forecaster_agent
from hawa_ml.agents.planner_agent import planner_agent
from hawa_ml.agents.auditor_agent import auditor_agent
from hawa_ml.agents.communicator_agent import communicator_agent
from hawa_ml.insights.triggers import insight_trigger_engine
from hawa_ml.insights.narratives import narrative_generator
from hawa_ml.twin.grid import load_grid


def get_twin_engine():
    return twin_engine


def get_forecaster():
    return forecaster


def get_grap_engine():
    return grap_engine


def get_exposure_engine():
    return exposure_engine


def get_vrp_optimizer():
    return vrp_optimizer


def get_whatif_simulator():
    return whatif_simulator


def get_effectiveness_library():
    return effectiveness_library


def get_grid():
    return load_grid(500.0)
