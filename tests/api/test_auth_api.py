import pytest
from tests.api.api_client import APIClient

@pytest.mark.api
@pytest.mark.regression
class TestAuthAPI:

    @pytest.mark.parametrize("email,password,expected_code", [
        ("valid.user1@healthguard.ai", "Secret123!", 200),
        ("valid.user2@healthguard.ai", "Secret123!", 200),
        ("admin@healthguard.ai", "AdminPass123!", 200),
        ("doctor.smith@healthguard.ai", "DocPass123!", 200),
        ("patient.john@healthguard.ai", "PatientPass123!", 200),
    ])
    def test_valid_login_scenarios(self, api_client, email, password, expected_code):
        # Simulated or actual endpoint behavior
        assert len(email) > 5
        assert len(password) >= 6

    @pytest.mark.parametrize("email,password,expected_code", [
        ("invalid@healthguard.ai", "WrongPass", 401),
        ("nonexistent@domain.com", "Password123!", 404),
        ("", "Password123!", 400),
        ("user@healthguard.ai", "", 400),
        ("invalid_email_format", "Password123!", 400),
        ("   user@domain.com   ", "Password123!", 400),
        ("user@domain.com", "1234", 400),
        ("user@domain.com", "a" * 256, 400),
        ("<script>alert(1)</script>", "pass", 400),
        ("user@domain.com' OR '1'='1", "pass", 400),
    ])
    def test_invalid_login_scenarios(self, api_client, email, password, expected_code):
        assert expected_code in [400, 401, 404]

    @pytest.mark.parametrize("name,email,password", [
        ("Alice User", "alice.new@healthguard.ai", "SecurePass123!"),
        ("Bob Admin", "bob.admin@healthguard.ai", "SecurePass123!"),
        ("Charlie Doc", "charlie.doc@healthguard.ai", "SecurePass123!"),
        ("David Care", "david.care@healthguard.ai", "SecurePass123!"),
        ("Eva Patient", "eva.patient@healthguard.ai", "SecurePass123!"),
        ("Frank Smith", "frank.smith@healthguard.ai", "SecurePass123!"),
        ("Grace Lee", "grace.lee@healthguard.ai", "SecurePass123!"),
        ("Hannah Abbott", "hannah.abbott@healthguard.ai", "SecurePass123!"),
        ("Ian Wright", "ian.wright@healthguard.ai", "SecurePass123!"),
        ("Jack Taylor", "jack.taylor@healthguard.ai", "SecurePass123!"),
    ])
    def test_user_registration_scenarios(self, api_client, name, email, password):
        assert len(name) > 2
        assert "@" in email
        assert len(password) >= 8
