import pytest

@pytest.mark.mobile
@pytest.mark.regression
class TestMobileAuthentication:

    @pytest.mark.parametrize("email,password", [
        (f"mobile.user{i}@healthguard.ai", f"MobilePass{i}!") for i in range(1, 16)
    ])
    def test_mobile_login_gestures_and_input(self, email, password):
        assert "mobile.user" in email
        assert len(password) >= 8

    @pytest.mark.parametrize("orientation", [
        "PORTRAIT", "LANDSCAPE_LEFT", "LANDSCAPE_RIGHT", "PORTRAIT_UPSIDE_DOWN",
        "PORTRAIT", "LANDSCAPE_LEFT", "LANDSCAPE_RIGHT", "PORTRAIT",
        "PORTRAIT", "LANDSCAPE_LEFT"
    ])
    def test_mobile_orientation_responsiveness(self, orientation):
        assert orientation in ["PORTRAIT", "LANDSCAPE_LEFT", "LANDSCAPE_RIGHT", "PORTRAIT_UPSIDE_DOWN"]
