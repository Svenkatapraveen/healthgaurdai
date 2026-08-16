import requests
from tests.config.config import Config

class APIClient:
    def __init__(self, base_url=None):
        self.base_url = base_url or Config.API_BASE_URL
        self.session = requests.Session()

    def login(self, email, password):
        payload = {"email": email, "password": password}
        return self.session.post(f"{self.base_url}/auth/login", json=payload)

    def register(self, email, password, name):
        payload = {"email": email, "password": password, "fullName": name}
        return self.session.post(f"{self.base_url}/auth/register", json=payload)

    def get_health_metrics(self, user_id):
        return self.session.get(f"{self.base_url}/health/{user_id}")

    def submit_assessment(self, payload):
        return self.session.post(f"{self.base_url}/assessments", json=payload)

    def get_symptoms_catalog(self):
        return self.session.get(f"{self.base_url}/symptoms")
