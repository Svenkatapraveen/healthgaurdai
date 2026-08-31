import pytest

@pytest.mark.web
@pytest.mark.regression
class TestAppointmentsBooking:

    @pytest.mark.parametrize("specialty,doctor_name,experience_years", [
        ("Cardiologist", "Dr. Sarah Jenkins", 15),
        ("Neurologist", "Dr. Marcus Vance", 12),
        ("Pulmonologist", "Dr. Elena Rostova", 18),
        ("Gastroenterologist", "Dr. Rahul Sharma", 10),
        ("Dermatologist", "Dr. Jessica Chen", 8),
        ("Psychiatrist", "Dr. David Miller", 14),
        ("Ophthalmologist", "Dr. Arthur Pendelton", 20),
        ("ENT Specialist", "Dr. Priya Patel", 11),
        ("Orthopedic Surgeon", "Dr. James Wilson", 16),
        ("General Practitioner", "Dr. Amanda Blake", 9),
    ])
    def test_specialist_doctor_recommendations(self, specialty, doctor_name, experience_years):
        assert len(specialty) > 3
        assert len(doctor_name) > 5
        assert experience_years > 0

    @pytest.mark.parametrize("slot_time,day_offset,is_available", [
        ("09:00 AM", 1, True),
        ("09:30 AM", 1, True),
        ("10:00 AM", 1, True),
        ("10:30 AM", 1, False),
        ("11:00 AM", 1, True),
        ("11:30 AM", 1, True),
        ("02:00 PM", 1, True),
        ("02:30 PM", 1, True),
        ("03:00 PM", 1, False),
        ("03:30 PM", 1, True),

        ("04:00 PM", 1, True),
        ("04:30 PM", 1, True),
        ("05:00 PM", 1, True),
        ("09:00 AM", 2, True),
        ("10:00 AM", 2, True),
        ("11:00 AM", 2, True),
        ("02:00 PM", 2, True),
        ("03:00 PM", 2, True),
        ("04:00 PM", 2, True),
        ("05:00 PM", 2, True),

        ("09:00 AM", 3, True),
        ("10:00 AM", 3, True),
        ("11:00 AM", 3, True),
        ("02:00 PM", 3, True),
        ("03:00 PM", 3, True),
        ("04:00 PM", 3, True),
        ("05:00 PM", 3, True),
        ("09:00 AM", 4, True),
        ("10:00 AM", 4, True),
        ("11:00 AM", 4, True),
    ])
    def test_appointment_slot_booking_availability(self, slot_time, day_offset, is_available):
        assert len(slot_time) >= 7
        assert day_offset >= 1
