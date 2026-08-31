import pytest
from tests.utils.appium_factory import AppiumDriverFactory

@pytest.fixture(scope="function")
def mobile_driver():
    driver = AppiumDriverFactory.get_mobile_driver()
    if driver is None:
        pytest.skip("Appium server or mobile device emulator is not connected.")
    yield driver
    driver.quit()
