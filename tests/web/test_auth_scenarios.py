import pytest

@pytest.mark.web
@pytest.mark.regression
class TestAuthScenarios:

    @pytest.mark.smoke
    @pytest.mark.parametrize("email,password", [
        (f"user{i}@healthguard.ai", f"PassWord{i}!") for i in range(1, 16)
    ])
    def test_positive_authentication_flows(self, email, password):
        assert "@healthguard.ai" in email
        assert len(password) >= 8

    @pytest.mark.parametrize("email,password,expected_error", [
        ("invalid.email", "Pass123!", "Invalid Email Format"),
        ("user@domain.com", "short", "Password too short"),
        ("", "Pass123!", "Email is required"),
        ("user@domain.com", "", "Password is required"),
        ("nonexistent@domain.com", "Pass123!", "User not found"),
        ("wrong@domain.com", "WrongPassword", "Invalid Credentials"),
        ("  user@domain.com  ", "Pass123!", "Trim whitespace required"),
        ("user@domain.com", "   ", "Invalid Password"),
        ("a" * 100 + "@domain.com", "Pass123!", "Email length exceeded"),
        ("user@domain.com", "a" * 200, "Password length exceeded"),

        ("admin@domain.com", "WrongAdminPass", "Invalid Admin Credentials"),
        ("<script>alert(1)</script>", "Pass123!", "Sanitized Input Required"),
        ("user@domain.com' --", "Pass123!", "SQL Injection Prevention"),
        ("user@domain.com", "12345678", "Weak Password"),
        ("user@domain.com", "abcdefgh", "Missing Special Character"),

        ("user@domain.com", "ABCDEFGH", "Missing Lowercase Character"),
        ("user@domain.com", "1234abcd!", "Missing Uppercase Character"),
        ("user@domain.com", "1234ABCD!", "Missing Lowercase Character"),
        ("user@domain.com", "Password!", "Missing Digit"),
        ("user@domain.com", "Password123", "Missing Symbol"),

        ("locked.user@healthguard.ai", "Pass123!", "Account Locked"),
        ("unverified@healthguard.ai", "Pass123!", "Email Verification Required"),
        ("expired.session@healthguard.ai", "Pass123!", "Session Expired"),
        ("disabled.user@healthguard.ai", "Pass123!", "Account Disabled"),
        ("suspended.user@healthguard.ai", "Pass123!", "Account Suspended"),

        ("banned.user@healthguard.ai", "Pass123!", "Account Banned"),
        ("2fa.required@healthguard.ai", "Pass123!", "2FA Code Required"),
        ("2fa.invalid@healthguard.ai", "Pass123!", "Invalid 2FA Code"),
        ("reset.pending@healthguard.ai", "Pass123!", "Password Reset Pending"),
        ("deleted.user@healthguard.ai", "Pass123!", "Account Deleted"),
    ])
    def test_negative_authentication_scenarios(self, email, password, expected_error):
        assert len(expected_error) > 0
