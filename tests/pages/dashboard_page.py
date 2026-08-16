from selenium.webdriver.common.by import By
from tests.pages.base_page import BasePage

class DashboardPage(BasePage):
    HEALTH_SCORE_CARD = (By.XPATH, "//*[contains(text(), 'Health Score') or contains(text(), 'Score')]")
    ASSESSMENT_TAB = (By.XPATH, "//*[contains(text(), 'Checkup') or contains(text(), 'Assessment')]")
    BOOKING_TAB = (By.XPATH, "//*[contains(text(), 'Book') or contains(text(), 'Doctor')]")
    EMERGENCY_TAB = (By.XPATH, "//*[contains(text(), 'Emergency') or contains(text(), 'SOS')]")
    PROFILE_TAB = (By.XPATH, "//*[contains(text(), 'Profile')]")

    def click_assessment_tab(self):
        self.click(self.ASSESSMENT_TAB)

    def click_booking_tab(self):
        self.click(self.BOOKING_TAB)

    def click_emergency_tab(self):
        self.click(self.EMERGENCY_TAB)

    def click_profile_tab(self):
        self.click(self.PROFILE_TAB)
