import pytest
from tests.api.api_client import APIClient

@pytest.fixture(scope="session")
def api_client():
    return APIClient()
