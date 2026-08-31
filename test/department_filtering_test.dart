import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1healthgaurdai/data/doctor_database.dart';

void main() {
  group('Strict Department Doctor Filtering & 48-Doctor Catalog Tests', () {
    test('Verify exactly 48 doctors exist in doctorDatabase', () {
      expect(doctorDatabase.length, equals(48));
    });

    test('Verify CARDIOLOGY filtering returns ONLY 6 Cardiology doctors', () {
      final docs = getDoctorsBySpecialty('Cardiologist');
      expect(docs.length, equals(6));
      for (var d in docs) {
        expect(getDepartmentName(d.specialty), equals('Cardiology'));
      }
      final names = docs.map((d) => d.name).toList();
      expect(names, containsAll([
        'Dr. Arun Kumar',
        'Dr. Vikram Reddy',
        'Dr. Suresh Rao',
        'Dr. Kavya Sharma',
        'Dr. Rajesh Kumar',
        'Dr. Anil Varma',
      ]));
    });

    test('Verify NEUROLOGY filtering returns ONLY 6 Neurology doctors', () {
      final docs = getDoctorsBySpecialty('Neurologist');
      expect(docs.length, equals(6));
      for (var d in docs) {
        expect(getDepartmentName(d.specialty), equals('Neurology'));
      }
      final names = docs.map((d) => d.name).toList();
      expect(names, containsAll([
        'Dr. Priya Sharma',
        'Dr. Naveen Reddy',
        'Dr. Meena Rao',
        'Dr. Karthik Kumar',
        'Dr. Swathi Verma',
        'Dr. Rohit Sharma',
      ]));
    });

    test('Verify DERMATOLOGY filtering returns ONLY 6 Dermatology doctors', () {
      final docs = getDoctorsBySpecialty('Dermatologist');
      expect(docs.length, equals(6));
      for (var d in docs) {
        expect(getDepartmentName(d.specialty), equals('Dermatology'));
      }
      final names = docs.map((d) => d.name).toList();
      expect(names, containsAll([
        'Dr. Sneha Rao',
        'Dr. Pooja Reddy',
        'Dr. Neha Sharma',
        'Dr. Ramesh Kumar',
        'Dr. Divya Rao',
        'Dr. Ajay Varma',
      ]));
    });

    test('Verify ORTHOPEDICS filtering returns ONLY 6 Orthopedics doctors', () {
      final docs = getDoctorsBySpecialty('Orthopedic Specialist');
      expect(docs.length, equals(6));
      for (var d in docs) {
        expect(getDepartmentName(d.specialty), equals('Orthopedics'));
      }
      final names = docs.map((d) => d.name).toList();
      expect(names, containsAll([
        'Dr. Kiran Kumar',
        'Dr. Mahesh Reddy',
        'Dr. Anjali Rao',
        'Dr. Vivek Sharma',
        'Dr. Sanjay Kumar',
        'Dr. Harsha Verma',
      ]));
    });

    test('Verify GYNECOLOGY filtering returns ONLY 6 Gynecology doctors', () {
      final docs = getDoctorsBySpecialty('Gynecologist');
      expect(docs.length, equals(6));
      for (var d in docs) {
        expect(getDepartmentName(d.specialty), equals('Gynecology'));
      }
      final names = docs.map((d) => d.name).toList();
      expect(names, containsAll([
        'Dr. Anjali Devi',
        'Dr. Lakshmi Rao',
        'Dr. Swathi Reddy',
        'Dr. Priya Kumar',
        'Dr. Deepa Sharma',
        'Dr. Nandini Rao',
      ]));
    });

    test('Verify PULMONOLOGY filtering returns ONLY 6 Pulmonology doctors', () {
      final docs = getDoctorsBySpecialty('Pulmonologist');
      expect(docs.length, equals(6));
      for (var d in docs) {
        expect(getDepartmentName(d.specialty), equals('Pulmonology'));
      }
      final names = docs.map((d) => d.name).toList();
      expect(names, containsAll([
        'Dr. Neha Verma',
        'Dr. Rakesh Kumar',
        'Dr. Sunil Rao',
        'Dr. Asha Reddy',
        'Dr. Manish Sharma',
        'Dr. Divya Kumar',
      ]));
    });

    test('Verify GASTROENTEROLOGY filtering returns ONLY 6 Gastroenterology doctors', () {
      final docs = getDoctorsBySpecialty('Gastroenterologist');
      expect(docs.length, equals(6));
      for (var d in docs) {
        expect(getDepartmentName(d.specialty), equals('Gastroenterology'));
      }
      final names = docs.map((d) => d.name).toList();
      expect(names, containsAll([
        'Dr. Amit Roy',
        'Dr. Rahul Sharma',
        'Dr. Varun Reddy',
        'Dr. Meera Kumar',
        'Dr. Akhil Rao',
        'Dr. Pavan Sharma',
      ]));
    });

    test('Verify ENT filtering returns ONLY 6 ENT doctors', () {
      final docs = getDoctorsBySpecialty('ENT');
      expect(docs.length, equals(6));
      for (var d in docs) {
        expect(getDepartmentName(d.specialty), equals('ENT'));
      }
      final names = docs.map((d) => d.name).toList();
      expect(names, containsAll([
        'Dr. Tariq Khan',
        'Dr. Imran Kumar',
        'Dr. Farhan Rao',
        'Dr. Sameer Reddy',
        'Dr. Aditya Sharma',
        'Dr. Nikhil Kumar',
      ]));
    });

    test('Verify all 48 doctors have unique doctor IDs', () {
      final ids = doctorDatabase.map((d) => d.id).toSet();
      expect(ids.length, equals(48));
    });
  });
}
