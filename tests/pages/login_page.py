from selenium.webdriver.common.by import By
from tests.pages.base_page import BasePage

class LoginPage(BasePage):
    EMAIL_INPUT = (By.XPATH, "//input[@type='email' or contains(@hint, 'Email')]")
    PASSWORD_INPUT = (By.XPATH, "//input[@type='password' or contains(@hint, 'Password')]")
    SUBMIT_BTN = (By.XPATH, "//button[contains(text(), 'Log In') or contains(text(), 'Sign In')]")
    FORGOT_PASSWORD_LINK = (By.XPATH, "//*[contains(text(), 'Forgot Password')]")

    def login(self, email, password):
        self.type_text(self.EMAIL_INPUT, email)
        self.type_text(self.PASSWORD_INPUT, password)
        self.click(self.SUBMIT_BTN)
