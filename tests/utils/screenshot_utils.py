import os
from datetime import datetime
from tests.utils.logger import get_logger

logger = get_logger()

class ScreenshotUtils:
    @staticmethod
    def capture_screenshot(driver, name_prefix="failure"):
        try:
            reports_dir = os.path.join(os.path.dirname(__file__), '../reports/screenshots')
            os.makedirs(reports_dir, exist_ok=True)
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"{name_prefix}_{timestamp}.png"
            filepath = os.path.join(reports_dir, filename)
            driver.save_screenshot(filepath)
            logger.info(f"Saved screenshot: {filepath}")
            return filepath
        except Exception as e:
            logger.error(f"Failed to capture screenshot: {e}")
            return None
