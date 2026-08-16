from selenium import webdriver
from selenium.webdriver.chrome.options import Options as ChromeOptions
from selenium.webdriver.firefox.options import Options as FirefoxOptions
from tests.config.config import Config
from tests.utils.logger import get_logger

logger = get_logger()

class DriverFactory:
    @staticmethod
    def get_driver(browser=None, headless=None):
        browser = browser or Config.BROWSER
        headless = headless if headless is not None else Config.HEADLESS

        if browser == 'chrome':
            options = ChromeOptions()
            if headless:
                options.add_argument('--headless=new')
            options.add_argument('--no-sandbox')
            options.add_argument('--disable-dev-shm-usage')
            options.add_argument('--window-size=1920,1080')
            options.add_argument('--disable-gpu')
            driver = webdriver.Chrome(options=options)
        elif browser == 'firefox':
            options = FirefoxOptions()
            if headless:
                options.add_argument('-headless')
            driver = webdriver.Firefox(options=options)
        else:
            options = ChromeOptions()
            if headless:
                options.add_argument('--headless=new')
            driver = webdriver.Chrome(options=options)

        driver.implicitly_wait(Config.IMPLICIT_WAIT)
        logger.info(f"Initialized {browser} driver (headless={headless})")
        return driver
