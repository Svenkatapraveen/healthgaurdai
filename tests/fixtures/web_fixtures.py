import pytest
from tests.utils.driver_factory import DriverFactory
from tests.utils.screenshot_utils import ScreenshotUtils

@pytest.fixture(scope="function")
def web_driver(request):
    driver = DriverFactory.get_driver()
    yield driver
    if hasattr(request.node, "rep_call") and request.node.rep_call.failed:
        ScreenshotUtils.capture_screenshot(driver, name_prefix=request.node.name)
    driver.quit()
