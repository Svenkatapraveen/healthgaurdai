from appium import webdriver
from appium.options.android import UiAutomator2Options
from tests.config.config import Config
from tests.utils.logger import get_logger

logger = get_logger()

class AppiumDriverFactory:
    @staticmethod
    def get_mobile_driver(platform='Android'):
        if platform.lower() == 'android':
            options = UiAutomator2Options()
            options.platform_name = Config.PLATFORM_NAME
            options.platform_version = Config.PLATFORM_VERSION
            options.device_name = Config.DEVICE_NAME
            options.app = Config.APP_PATH
            options.automation_name = 'UiAutomator2'
            
            try:
                driver = webdriver.Remote(Config.APPIUM_SERVER_URL, options=options)
                logger.info(f"Initialized Appium Android driver for device {Config.DEVICE_NAME}")
                return driver
            except Exception as e:
                logger.warning(f"Appium server connection failed or not running: {e}")
                return None
        else:
            raise NotImplementedError("iOS Appium driver configuration placeholder.")
