"""Tests run on defaults, not on the developer's backend/.env (which may turn on AWS, Redis or API keys).
Individual tests opt in with monkeypatch.setenv(...) and a settings cache_clear()."""
import pytest

from hawa_backend.aws.settings import AwsSettings, get_aws_settings
from hawa_backend.core import config as core_config
from hawa_backend.core.config import Settings, get_settings

Settings.model_config["env_file"] = None
AwsSettings.model_config["env_file"] = None
core_config._secrets_loaded = True  # never call Secrets Manager implicitly in tests


@pytest.fixture(autouse=True)
def _fresh_settings():
    get_settings.cache_clear()
    get_aws_settings.cache_clear()
    yield
    get_settings.cache_clear()
    get_aws_settings.cache_clear()
