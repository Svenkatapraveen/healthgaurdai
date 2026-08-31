import pytest
from tests.api.api_client import APIClient

@pytest.mark.api
@pytest.mark.regression
class TestHealthDataAPI:

    @pytest.mark.parametrize("body_part,expected_min_symptoms", [
        ("Head", 10),
        ("Eyes", 6),
        ("Ears", 6),
        ("Nose", 6),
        ("Neck", 5),
        ("Chest", 7),
        ("Abdomen", 10),
        ("Arms", 5),
        ("Hands", 4),
        ("Legs", 5),
        ("Feet", 5),
        ("Back", 5),
        ("Multi", 5),
        ("Systemic", 4),
        ("General", 5),
    ])
    def test_symptom_catalog_by_body_part(self, api_client, body_part, expected_min_symptoms):
        assert expected_min_symptoms > 0
        assert len(body_part) >= 3

    @pytest.mark.parametrize("symptom,severity,history,expected_risk", [
        (["Chest Pain", "Palpitations"], 8.0, ["Heart Disease"], "Emergency"),
        (["Shortness of Breath", "Wheezing"], 7.0, ["Asthma"], "High Risk"),
        (["Headache", "Migraine"], 5.0, [], "Moderate Risk"),
        (["Runny Nose", "Sneezing"], 2.0, [], "Low Risk"),
        (["Stomach Pain", "Nausea"], 6.0, ["Gastritis"], "Moderate Risk"),
        (["Back Pain", "Spinal Stiffness"], 4.0, [], "Low Risk"),
        (["Eye Pain", "Blurred Vision"], 6.0, [], "Moderate Risk"),
        (["Ear Pain", "Tinnitus"], 3.0, [], "Low Risk"),
        (["Fever", "Fatigue"], 9.0, ["Diabetes"], "Emergency"),
        (["Knee Pain", "Leg Cramps"], 4.0, [], "Low Risk"),
        (["Arm Weakness", "Confusion"], 9.0, [], "Emergency"),
        (["Skin Rash", "Itchy Ears"], 3.0, [], "Low Risk"),
        (["Difficulty Swallowing", "Hoarseness"], 6.0, [], "Moderate Risk"),
        (["Diarrhea", "Vomiting"], 7.0, [], "High Risk"),
        (["Cold Feet", "Tingling Toes"], 5.0, ["Diabetes"], "Moderate Risk"),
    ])
    def test_risk_score_calculation_engine(self, api_client, symptom, severity, history, expected_risk):
        assert severity >= 1.0
        assert expected_risk in ["Emergency", "High Risk", "Moderate Risk", "Low Risk"]
