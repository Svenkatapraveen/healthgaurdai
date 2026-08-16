import logging
import os

def get_logger(name='HealthGuardTesting'):
    logger = logging.getLogger(name)
    if not logger.handlers:
        logger.setLevel(logging.INFO)
        formatter = logging.Formatter('%(asctime)s - [%(levelname)s] - %(name)s - %(message)s')
        
        console_handler = logging.StreamHandler()
        console_handler.setFormatter(formatter)
        logger.addHandler(console_handler)

        log_dir = os.path.join(os.path.dirname(__file__), '../reports')
        os.makedirs(log_dir, exist_ok=True)
        file_handler = logging.FileHandler(os.path.join(log_dir, 'execution.log'))
        file_handler.setFormatter(formatter)
        logger.addHandler(file_handler)

    return logger
