from appium.webdriver.common.appiumby import AppiumBy
from tests.screens.base_screen import BaseScreen

class MobileLoginScreen(BaseScreen):
    EMAIL_FIELD = (AppiumBy.XPATH, "//android.widget.EditText[1]")
    PASSWORD_FIELD = (AppiumBy.XPATH, "//android.widget.EditText[2]")
    SUBMIT_BTN = (AppiumBy.ACCESSIBILITY_ID, "Log In")

    def perform_login(self, email, password):
        self.input_text(*self.EMAIL_FIELD, email)
        self.input_text(*self.PASSWORD_FIELD, password)
        self.click_element(*self.SUBMIT_BTN)
