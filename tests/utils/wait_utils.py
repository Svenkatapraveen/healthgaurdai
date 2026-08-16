from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from tests.config.config import Config
from tests.utils.logger import get_logger

logger = get_logger()

class WaitUtils:
    @staticmethod
    def wait_for_element_visible(driver, locator, timeout=Config.EXPLICIT_WAIT):
        try:
            return WebDriverWait(driver, timeout).until(EC.visibility_of_element_located(locator))
        except Exception as e:
            logger.error(f"Element not visible {locator}: {e}")
            raise

    @staticmethod
    def wait_for_element_clickable(driver, locator, timeout=Config.EXPLICIT_WAIT):
        try:
            return WebDriverWait(driver, timeout).until(EC.element_to_be_clickable(locator))
        except Exception as e:
            logger.error(f"Element not clickable {locator}: {e}")
            raise

    @staticmethod
    def wait_for_text_present(driver, locator, text, timeout=Config.EXPLICIT_WAIT):
        try:
            return WebDriverWait(driver, timeout).until(EC.text_to_be_present_in_element(locator, text))
        except Exception as e:
            logger.error(f"Text '{text}' not present in {locator}: {e}")
            raise
