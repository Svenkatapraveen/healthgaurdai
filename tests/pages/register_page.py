from selenium.webdriver.common.by import By
from tests.pages.base_page import BasePage

class RegisterPage(BasePage):
    NAME_INPUT = (By.XPATH, "//input[contains(@hint, 'Name') or contains(@placeholder, 'Name')]")
    EMAIL_INPUT = (By.XPATH, "//input[@type='email']")
    PASSWORD_INPUT = (By.XPATH, "//input[@type='password']")
    CONFIRM_PASSWORD_INPUT = (By.XPATH, "//input[contains(@hint, 'Confirm')]")
    REGISTER_BTN = (By.XPATH, "//button[contains(text(), 'Create Account') or contains(text(), 'Register')]")

    def register_user(self, name, email, password):
        if self.is_displayed(self.NAME_INPUT):
            self.type_text(self.NAME_INPUT, name)
        self.type_text(self.EMAIL_INPUT, email)
        self.type_text(self.PASSWORD_INPUT, password)
        self.click(self.REGISTER_BTN)
