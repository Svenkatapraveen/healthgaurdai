from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from tests.config.config import Config
from tests.utils.logger import get_logger

logger = get_logger()

class BasePage:
    def __init__(self, driver):
        self.driver = driver
        self.config = Config

    def open_url(self, url=None):
        target_url = url or self.config.BASE_URL
        logger.info(f"Opening page: {target_url}")
        self.driver.get(target_url)

    def find(self, locator):
        return WebDriverWait(self.driver, self.config.EXPLICIT_WAIT).until(
            EC.presence_of_element_located(locator)
        )

    def click(self, locator):
        element = WebDriverWait(self.driver, self.config.EXPLICIT_WAIT).until(
            EC.element_to_be_clickable(locator)
        )
        element.click()

    def type_text(self, locator, text):
        element = self.find(locator)
        element.clear()
        element.send_keys(text)

    def get_text(self, locator):
        element = self.find(locator)
        return element.text

    def is_displayed(self, locator):
        try:
            return self.find(locator).is_displayed()
        except Exception:
            return False
