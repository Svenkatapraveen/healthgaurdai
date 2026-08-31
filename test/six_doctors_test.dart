import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1healthgaurdai/data/doctor_database.dart';

void main() {
  group('6 Unique Doctors & Department Verification', () {
    test('Verify all 6 exact doctors are present in doctorDatabase', () {
      final docNames = doctorDatabase.map((d) => d.name).toList();
      
      expect(docNames, contains('Dr. Arun Kumar'));
      expect(docNames, contains('Dr. Priya Sharma'));
      expect(docNames, contains('Dr. Rahul Reddy'));
      expect(docNames, contains('Dr. Sneha Rao'));
      expect(docNames, contains('Dr. Kiran Kumar'));
      expect(docNames, contains('Dr. Anjali Devi'));
    });

    test('Verify all 6 doctors have unique IDs and distinct departments', () {
      final targetDocs = [
        doctorDatabase.firstWhere((d) => d.name == 'Dr. Arun Kumar'),
        doctorDatabase.firstWhere((d) => d.name == 'Dr. Priya Sharma'),
        doctorDatabase.firstWhere((d) => d.name == 'Dr. Rahul Reddy'),
        doctorDatabase.firstWhere((d) => d.name == 'Dr. Sneha Rao'),
        doctorDatabase.firstWhere((d) => d.name == 'Dr. Kiran Kumar'),
        doctorDatabase.firstWhere((d) => d.name == 'Dr. Anjali Devi'),
      ];

      // Unique IDs check
      final ids = targetDocs.map((d) => d.id).toSet();
      expect(ids.length, equals(6));

      // Distinct Departments check
      final departments = targetDocs.map((d) => getDepartmentName(d.specialty)).toSet();
      expect(departments.length, equals(6));
      expect(departments, containsAll([
        'Cardiology',
        'Neurology',
        'General Medicine',
        'Dermatology',
        'Orthopedics',
        'Gynecology',
      ]));
    });

    test('Verify getDoctorsBySpecialty returns full list when All Specialties selected', () {
      final allDocs = getDoctorsBySpecialty('All Specialties / Departments');
      expect(allDocs.length, greaterThanOrEqualTo(6));
    });
  });
}
