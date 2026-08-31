from selenium.webdriver.common.by import By
from tests.pages.base_page import BasePage

class EmergencyPage(BasePage):
    EMERGENCY_TRIGGER_BTN = (By.XPATH, "//button[contains(text(), 'Emergency') or contains(text(), 'SOS')]")
    HOSPITAL_LOCATOR_BTN = (By.XPATH, "//*[contains(text(), 'Hospital') or contains(text(), 'Locate')]")
    DISPATCH_ALERT_BTN = (By.XPATH, "//button[contains(text(), 'Dispatch')]")
