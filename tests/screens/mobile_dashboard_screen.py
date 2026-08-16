from appium.webdriver.common.appiumby import AppiumBy
from tests.screens.base_screen import BaseScreen

class MobileDashboardScreen(BaseScreen):
    CHECKUP_TAB = (AppiumBy.ACCESSIBILITY_ID, "Checkup")
    DOCTOR_TAB = (AppiumBy.ACCESSIBILITY_ID, "Doctors")
    PROFILE_TAB = (AppiumBy.ACCESSIBILITY_ID, "Profile")

    def open_checkup(self):
        self.click_element(*self.CHECKUP_TAB)
