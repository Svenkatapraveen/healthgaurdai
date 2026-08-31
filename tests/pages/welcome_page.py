from selenium.webdriver.common.by import By
from tests.pages.base_page import BasePage

class WelcomePage(BasePage):
    BRANDING_LOGO = (By.XPATH, "//*[contains(text(), 'HealthGuard AI')]")
    HERO_HEADING = (By.XPATH, "//*[contains(text(), 'Your Intelligent Healthcare Assistant')]")
    EMAIL_LOGIN_BTN = (By.XPATH, "//*[contains(text(), 'Log In with Email')]")
    CREATE_ACCOUNT_BTN = (By.XPATH, "//*[contains(text(), 'Create New Account')]")
    GOOGLE_SIGNIN_BTN = (By.XPATH, "//*[contains(text(), 'Sign in with Google')]")
    ADMIN_PORTAL_LINK = (By.XPATH, "//*[contains(text(), 'Access Admin Portal')]")

    def is_branding_displayed(self):
        return self.is_displayed(self.BRANDING_LOGO)

    def click_email_login(self):
        self.click(self.EMAIL_LOGIN_BTN)

    def click_create_account(self):
        self.click(self.CREATE_ACCOUNT_BTN)

    def click_google_signin(self):
        self.click(self.GOOGLE_SIGNIN_BTN)

    def click_admin_portal(self):
        self.click(self.ADMIN_PORTAL_LINK)
