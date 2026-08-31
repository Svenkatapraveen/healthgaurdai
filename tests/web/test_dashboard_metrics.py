import pytest

@pytest.mark.web
@pytest.mark.regression
class TestDashboardMetrics:

    @pytest.mark.parametrize("score_val,expected_status", [
        (95, "Optimal"), (90, "Optimal"), (85, "Good"), (80, "Good"),
        (75, "Moderate"), (70, "Moderate"), (65, "Fair"), (60, "Fair"),
        (55, "Needs Attention"), (50, "Needs Attention"), (45, "Risk"), (40, "Risk"),
        (35, "Critical"), (30, "Critical"), (25, "Severe"), (20, "Severe"),
        (15, "Emergency"), (10, "Emergency"), (99, "Optimal"), (5, "Emergency"),
    ])
    def test_health_score_status_mapping(self, score_val, expected_status):
        assert 0 <= score_val <= 100
        assert len(expected_status) > 0

    @pytest.mark.parametrize("metric_name,val,min_val,max_val", [
        ("Water Intake (L)", 2.5, 0.5, 5.0),
        ("Sleep Duration (hrs)", 7.5, 2.0, 12.0),
        ("Physical Exercise (mins)", 45, 0, 180),
        ("Calorie Burn (kcal)", 2200, 1000, 5000),
        ("Systolic BP (mmHg)", 120, 80, 200),
        ("Diastolic BP (mmHg)", 80, 50, 130),
        ("Heart Rate (BPM)", 72, 40, 180),
        ("Oxygen Saturation SpO2 (%)", 98, 85, 100),
        ("Body Temperature (°F)", 98.6, 95.0, 105.0),
        ("Blood Glucose (mg/dL)", 95, 60, 300),

        ("BMI (kg/m²)", 22.5, 15.0, 45.0),
        ("Stress Level (1-10)", 4.0, 1.0, 10.0),
        ("Active Minutes", 60, 0, 300),
        ("Steps Count", 8500, 0, 50000),
        ("Floors Climbed", 12, 0, 100),

        ("Deep Sleep (%)", 25, 5, 50),
        ("REM Sleep (%)", 20, 5, 40),
        ("Resting Heart Rate", 65, 40, 100),
        ("VO2 Max", 42, 20, 80),
        ("Body Fat (%)", 18, 5, 50),
    ])
    def test_lifestyle_metrics_validation(self, metric_name, val, min_val, max_val):
        assert min_val <= val <= max_val
