from selenium.webdriver.common.by import By
from tests.pages.base_page import BasePage

class AssessmentPage(BasePage):
    SEARCH_BAR = (By.XPATH, "//input[contains(@hint, 'Search') or contains(@placeholder, 'Search')]")
    CLEAR_FILTERS_BTN = (By.XPATH, "//*[contains(text(), 'Clear Filters')]")
    CONTINUE_BTN = (By.XPATH, "//button[contains(text(), 'Continue')]")
    ANALYZE_NOW_BTN = (By.XPATH, "//button[contains(text(), 'Analyze Now')]")

    def search_symptom(self, symptom_name):
        self.type_text(self.SEARCH_BAR, symptom_name)

    def select_body_part(self, body_part_name):
        part_locator = (By.XPATH, f"//*[text()='{body_part_name}']")
        self.click(part_locator)

    def select_symptom_chip(self, symptom_name):
        chip_locator = (By.XPATH, f"//*[text()='{symptom_name}']")
        self.click(chip_locator)
