import os
from dotenv import load_dotenv

load_dotenv(os.path.join(os.path.dirname(__file__), 'test_env.env'))

class Config:
    BASE_URL = os.getenv('BASE_URL', 'http://localhost:5000')
    API_BASE_URL = os.getenv('API_BASE_URL', 'http://localhost:5000/api')
    IMPLICIT_WAIT = int(os.getenv('IMPLICIT_WAIT', '10'))
    EXPLICIT_WAIT = int(os.getenv('EXPLICIT_WAIT', '15'))
    HEADLESS = os.getenv('HEADLESS', 'true').lower() == 'true'
    BROWSER = os.getenv('BROWSER', 'chrome').lower()

    # Appium Mobile Config
    APPIUM_SERVER_URL = os.getenv('APPIUM_SERVER_URL', 'http://localhost:4723/wd/hub')
    PLATFORM_NAME = os.getenv('PLATFORM_NAME', 'Android')
    PLATFORM_VERSION = os.getenv('PLATFORM_VERSION', '12.0')
    DEVICE_NAME = os.getenv('DEVICE_NAME', 'Android Emulator')
    APP_PATH = os.getenv('APP_PATH', 'build/app/outputs/flutter-apk/app-debug.apk')

    # Test Credentials
    TEST_USER_EMAIL = os.getenv('TEST_USER_EMAIL', 'testuser@healthguard.ai')
    TEST_USER_PASSWORD = os.getenv('TEST_USER_PASSWORD', 'Password123!')
    ADMIN_USER_EMAIL = os.getenv('ADMIN_USER_EMAIL', 'admin@healthguard.ai')
    ADMIN_USER_PASSWORD = os.getenv('ADMIN_USER_PASSWORD', 'AdminPass123!')
