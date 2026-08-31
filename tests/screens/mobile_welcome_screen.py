from appium.webdriver.common.appiumby import AppiumBy
from tests.screens.base_screen import BaseScreen

class MobileWelcomeScreen(BaseScreen):
    BRANDING_TITLE = (AppiumBy.ACCESSIBILITY_ID, "HealthGuard AI")
    EMAIL_LOGIN_BTN = (AppiumBy.ACCESSIBILITY_ID, "Log In with Email")
    CREATE_ACCOUNT_BTN = (AppiumBy.ACCESSIBILITY_ID, "Create New Account")
    GOOGLE_SIGNIN_BTN = (AppiumBy.ACCESSIBILITY_ID, "Sign in with Google")

    def tap_email_login(self):
        self.click_element(*self.EMAIL_LOGIN_BTN)

    def tap_create_account(self):
        self.click_element(*self.CREATE_ACCOUNT_BTN)
