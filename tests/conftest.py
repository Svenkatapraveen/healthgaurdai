import pytest
from tests.fixtures.web_fixtures import web_driver
from tests.fixtures.mobile_fixtures import mobile_driver
from tests.fixtures.api_fixtures import api_client

@pytest.hookimpl(tryfirst=True, hookwrapper=True)
def pytest_runtest_makereport(item, call):
    outcome = yield
    rep = outcome.get_result()
    setattr(item, "rep_" + rep.when, rep)
