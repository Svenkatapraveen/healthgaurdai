from locust import HttpUser, task, between

class HealthGuardUser(HttpUser):
    wait_time = between(1, 3)

    @task(3)
    def view_welcome_page(self):
        self.client.get("/")

    @task(2)
    def search_symptoms(self):
        self.client.get("/api/symptoms?search=migraine")

    @task(1)
    def submit_assessment(self):
        payload = {
            "symptoms": ["Headache", "Migraine"],
            "severity": 7.0,
            "history": ["Hypertension"]
        }
        self.client.post("/api/assessments", json=payload)
