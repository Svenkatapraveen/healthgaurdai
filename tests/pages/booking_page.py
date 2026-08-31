from selenium.webdriver.common.by import By
from tests.pages.base_page import BasePage

class BookingPage(BasePage):
    SYMPTOMS_TEXTAREA = (By.XPATH, "//textarea | //input[contains(@hint, 'symptoms')]")
    SPECIALIST_CHIP = (By.XPATH, "//*[contains(text(), 'Cardiologist') or contains(text(), 'Neurologist')]")
    CONFIRM_BOOKING_BTN = (By.XPATH, "//button[contains(text(), 'Confirm') or contains(text(), 'Book')]")
