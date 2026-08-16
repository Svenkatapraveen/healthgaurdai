from appium.webdriver.common.appiumby import AppiumBy
from tests.screens.base_screen import BaseScreen

class MobileAssessmentScreen(BaseScreen):
    SEARCH_INPUT = (AppiumBy.XPATH, "//android.widget.EditText")
    HEAD_PART = (AppiumBy.ACCESSIBILITY_ID, "Head")
    CHEST_PART = (AppiumBy.ACCESSIBILITY_ID, "Chest")

    def tap_head_part(self):
        self.click_element(*self.HEAD_PART)
