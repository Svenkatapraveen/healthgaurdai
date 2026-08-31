from selenium.webdriver.common.by import By
from tests.pages.base_page import BasePage

class AdminPage(BasePage):
    ADMIN_HEADER = (By.XPATH, "//*[contains(text(), 'Admin Portal') or contains(text(), 'Management')]")
    USERS_TABLE = (By.XPATH, "//table | //*[contains(text(), 'Registered Patients')]")
    METRICS_OVERVIEW = (By.XPATH, "//*[contains(text(), 'System Health') or contains(text(), 'Total Users')]")
