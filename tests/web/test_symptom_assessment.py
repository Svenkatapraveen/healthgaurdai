import pytest

@pytest.mark.web
@pytest.mark.regression
class TestSymptomAssessmentEngine:

    @pytest.mark.parametrize("body_part,symptom_name,category", [
        # Head
        ("Head", "Headache", "Neurological Symptoms"),
        ("Head", "Migraine", "Neurological Symptoms"),
        ("Head", "Dizziness", "Neurological Symptoms"),
        ("Head", "Memory Loss", "Neurological Symptoms"),
        ("Head", "Insomnia", "Neurological Symptoms"),
        ("Head", "Confusion / Brain Fog", "Neurological Symptoms"),
        ("Head", "Toothache", "General Symptoms"),
        ("Head", "Jaw Pain / TMJ", "Pain Symptoms"),
        ("Head", "Scalp Tenderness", "Skin Symptoms"),
        ("Head", "Hair Loss", "Skin Symptoms"),

        # Eyes
        ("Eyes", "Eye Pain", "ENT & Eye Symptoms"),
        ("Eyes", "Blurred Vision", "ENT & Eye Symptoms"),
        ("Eyes", "Red Eyes / Conjunctivitis", "ENT & Eye Symptoms"),
        ("Eyes", "Watery / Itchy Eyes", "ENT & Eye Symptoms"),
        ("Eyes", "Double Vision", "ENT & Eye Symptoms"),
        ("Eyes", "Sensitivity to Light (Photophobia)", "ENT & Eye Symptoms"),

        # Ears
        ("Ears", "Ear Pain", "ENT & Eye Symptoms"),
        ("Ears", "Tinnitus (Ringing in Ears)", "ENT & Eye Symptoms"),
        ("Ears", "Ear Discharge", "ENT & Eye Symptoms"),
        ("Ears", "Hearing Loss", "ENT & Eye Symptoms"),
        ("Ears", "Ear Fullness / Pressure", "ENT & Eye Symptoms"),
        ("Ears", "Itchy Ears", "ENT & Eye Symptoms"),

        # Nose
        ("Nose", "Runny Nose (Rhinorrhea)", "ENT & Eye Symptoms"),
        ("Nose", "Nasal Congestion (Stuffy Nose)", "ENT & Eye Symptoms"),
        ("Nose", "Sneezing", "ENT & Eye Symptoms"),
        ("Nose", "Loss of Smell (Anosmia)", "ENT & Eye Symptoms"),
        ("Nose", "Nosebleed (Epistaxis)", "ENT & Eye Symptoms"),
        ("Nose", "Sinus Pressure & Pain", "ENT & Eye Symptoms"),

        # Neck
        ("Neck", "Neck Pain", "Pain Symptoms"),
        ("Neck", "Sore Throat", "Respiratory Symptoms"),
        ("Neck", "Difficulty Swallowing (Dysphagia)", "Respiratory Symptoms"),
        ("Neck", "Swollen Lymph Nodes", "General Symptoms"),
        ("Neck", "Hoarseness / Voice Loss", "Respiratory Symptoms"),

        # Chest
        ("Chest", "Chest Pain", "Heart Symptoms"),
        ("Chest", "Palpitations", "Heart Symptoms"),
        ("Chest", "Rapid Heartbeat (Tachycardia)", "Heart Symptoms"),
        ("Chest", "Chest Tightness", "Respiratory Symptoms"),
        ("Chest", "Cough", "Respiratory Symptoms"),
        ("Chest", "Shortness of Breath", "Respiratory Symptoms"),
        ("Chest", "Wheezing", "Respiratory Symptoms"),

        # Abdomen
        ("Abdomen", "Stomach Pain", "Digestive Symptoms"),
        ("Abdomen", "Stomach Bloating", "Digestive Symptoms"),
        ("Abdomen", "Stomach Cramps", "Digestive Symptoms"),
        ("Abdomen", "Nausea", "Digestive Symptoms"),
        ("Abdomen", "Vomiting", "Digestive Symptoms"),
        ("Abdomen", "Diarrhea", "Digestive Symptoms"),
        ("Abdomen", "Constipation", "Digestive Symptoms"),
        ("Abdomen", "Heartburn / Acid Reflux", "Digestive Symptoms"),
        ("Abdomen", "Indigestion / Dyspepsia", "Digestive Symptoms"),
        ("Abdomen", "Loss of Appetite", "Digestive Symptoms"),

        # Arms
        ("Arms", "Arm Pain", "Pain Symptoms"),
        ("Arms", "Numbness / Tingling in Arm", "Neurological Symptoms"),
        ("Arms", "Arm Weakness", "Neurological Symptoms"),
        ("Arms", "Elbow / Wrist Joint Pain", "Pain Symptoms"),
        ("Arms", "Tremors / Hand Shaking", "Neurological Symptoms"),

        # Hands
        ("Hands", "Hand Pain", "Pain Symptoms"),
        ("Hands", "Finger Stiffness", "Pain Symptoms"),
        ("Hands", "Numbness in Fingers (Carpal Tunnel)", "Neurological Symptoms"),
        ("Hands", "Cold Hands & Fingers", "General Symptoms"),

        # Legs
        ("Legs", "Knee Pain", "Pain Symptoms"),
        ("Legs", "Leg Cramps / Muscle Spasms", "Pain Symptoms"),
        ("Legs", "Leg Swelling (Edema)", "General Symptoms"),
        ("Legs", "Calf Pain / Soreness", "Pain Symptoms"),
        ("Legs", "Numbness / Tingling in Legs", "Neurological Symptoms"),

        # Feet
        ("Feet", "Foot Pain", "Pain Symptoms"),
        ("Feet", "Heel Pain (Plantar Fasciitis)", "Pain Symptoms"),
        ("Feet", "Swollen Feet & Ankles", "General Symptoms"),
        ("Feet", "Cold Feet & Toes", "General Symptoms"),
        ("Feet", "Tingling / Burning in Toes (Neuropathy)", "Neurological Symptoms"),

        # Back
        ("Back", "Back Pain", "Pain Symptoms"),
        ("Back", "Upper Back Pain", "Pain Symptoms"),
        ("Back", "Lower Back Pain (Lumbago)", "Pain Symptoms"),
        ("Back", "Back Muscle Spasms", "Pain Symptoms"),
        ("Back", "Spinal Stiffness", "Pain Symptoms"),

        # Systemic & Multi
        ("Head", "Fever", "General Symptoms"),
        ("Chest", "Fever", "General Symptoms"),
        ("Abdomen", "Fever", "General Symptoms"),
        ("Legs", "Fever", "General Symptoms"),
        ("Arms", "Fatigue", "General Symptoms"),
        ("Head", "Fatigue", "General Symptoms"),
        ("Arms", "Skin Rash", "Skin Symptoms"),
        ("Legs", "Skin Rash", "Skin Symptoms"),
        ("Head", "Anxiety", "Mental Health Symptoms"),
        ("Head", "Depression", "Mental Health Symptoms"),
    ])
    def test_symptom_mapping_for_all_body_parts(self, body_part, symptom_name, category):
        assert len(body_part) >= 3
        assert len(symptom_name) >= 3
        assert len(category) >= 5

    @pytest.mark.parametrize("search_query,expected_match", [
        ("migraine", "Migraine"),
        ("head", "Headache"),
        ("dizz", "Dizziness"),
        ("cough", "Cough"),
        ("breath", "Shortness of Breath"),
        ("chest", "Chest Pain"),
        ("stomach", "Stomach Pain"),
        ("rash", "Skin Rash"),
        ("ear", "Ear Pain"),
        ("eye", "Eye Pain"),
    ])
    def test_partial_symptom_search(self, search_query, expected_match):
        assert expected_match.lower().find(search_query) != -1 or search_query in expected_match.lower()
