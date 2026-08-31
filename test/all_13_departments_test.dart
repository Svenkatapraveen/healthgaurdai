import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1healthgaurdai/data/doctor_database.dart';

void main() {
  group('13 Departments Strict Doctor Filtering Test Suite', () {
    test('Verify exactly 78 total doctors exist in doctorDatabase', () {
      expect(doctorDatabase.length, equals(78));
    });

    final testCases = <String, Map<String, dynamic>>{
      'Cardiologist': {'dept': 'Cardiology', 'count': 6, 'firstName': 'Dr. Arun Kumar'},
      'Neurologist': {'dept': 'Neurology', 'count': 6, 'firstName': 'Dr. Priya Sharma'},
      'General Physician': {'dept': 'General Medicine', 'count': 6, 'firstName': 'Dr. Rahul Reddy'},
      'Dermatologist': {'dept': 'Dermatology', 'count': 6, 'firstName': 'Dr. Sneha Rao'},
      'Orthopedic': {'dept': 'Orthopedics', 'count': 6, 'firstName': 'Dr. Kiran Kumar'},
      'Gynecologist': {'dept': 'Gynecology', 'count': 6, 'firstName': 'Dr. Anjali Devi'},
      'Pulmonologist': {'dept': 'Pulmonology', 'count': 6, 'firstName': 'Dr. Neha Verma'},
      'Gastroenterologist': {'dept': 'Gastroenterology', 'count': 6, 'firstName': 'Dr. Amit Roy'},
      'Ophthalmologist': {'dept': 'Ophthalmology', 'count': 6, 'firstName': 'Dr. Meera Joshi'},
      'ENT': {'dept': 'ENT', 'count': 6, 'firstName': 'Dr. Tariq Khan'},
      'Urologist': {'dept': 'Urology', 'count': 6, 'firstName': 'Dr. Ritu Kapoor'},
      'Psychiatrist': {'dept': 'Psychiatry', 'count': 6, 'firstName': 'Dr. Sanjay Gupta'},
      'Endocrinologist': {'dept': 'Endocrinology', 'count': 6, 'firstName': 'Dr. Shalini Das'},
    };

    testCases.forEach((specialty, config) {
      test('Selecting "$specialty" returns ONLY ${config['count']} doctors from ${config['dept']}', () {
        final docs = getDoctorsBySpecialty(specialty);
        expect(docs.length, equals(config['count']));
        expect(docs.first.name, equals(config['firstName']));
        
        for (var doc in docs) {
          final docDept = getDepartmentName(doc.specialty);
          expect(docDept, equals(config['dept']), reason: 'Doctor ${doc.name} (${doc.specialty}) must belong to ${config['dept']}');
        }
      });
    });

    test('Verify all 78 doctors have unique doctor IDs', () {
      final ids = doctorDatabase.map((d) => d.id).toSet();
      expect(ids.length, equals(78));
    });
  });
}
