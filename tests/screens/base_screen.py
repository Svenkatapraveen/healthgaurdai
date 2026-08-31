from appium.webdriver.common.appiumby import AppiumBy
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from tests.config.config import Config

class BaseScreen:
    def __init__(self, driver):
        self.driver = driver
        self.config = Config

    def find_element(self, by, value):
        return WebDriverWait(self.driver, self.config.EXPLICIT_WAIT).until(
            EC.presence_of_element_located((by, value))
        )

    def click_element(self, by, value):
        element = WebDriverWait(self.driver, self.config.EXPLICIT_WAIT).until(
            EC.element_to_be_clickable((by, value))
        )
        element.click()

    def input_text(self, by, value, text):
        element = self.find_element(by, value)
        element.clear()
        element.send_keys(text)
