import 'package:cloud_firestore/cloud_firestore.dart';
import 'db_service.dart';

class FirebaseDbService implements DatabaseService {
  static final FirebaseDbService _instance = FirebaseDbService._internal();
  factory FirebaseDbService() => _instance;
  FirebaseDbService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<List<AssessmentModel>> getAssessments(String userId) async {
    final query = await _firestore
        .collection('assessments')
        .where('userId', isEqualTo: userId)
        .get();

    final assessments = query.docs.map((doc) {
      final data = doc.data();
      return AssessmentModel(
        id: data['id'] ?? doc.id,
        userId: data['userId'],
        date: (data['date'] as Timestamp).toDate(),
        primarySymptoms: List<String>.from(data['primarySymptoms'] ?? []),
        details: Map<String, dynamic>.from(data['details'] ?? {}),
        associatedSymptoms: List<String>.from(data['associatedSymptoms'] ?? []),
        medicalHistory: List<String>.from(data['medicalHistory'] ?? []),
        lifestyle: Map<String, dynamic>.from(data['lifestyle'] ?? {}),
        overallRiskScore: (data['overallRiskScore'] ?? 0).toDouble(),
        riskCategory: data['riskCategory'] ?? 'Unknown',
        diseaseProbability: Map<String, double>.from(
            (data['diseaseProbability'] as Map?)?.map((key, value) => MapEntry(key.toString(), (value as num).toDouble())) ?? {}),
        clinicalSummary: data['clinicalSummary'] ?? '',
        possibleCauses: List<String>.from(data['possibleCauses'] ?? []),
        recommendations: List<String>.from(data['recommendations'] ?? []),
        preventiveActions: List<String>.from(data['preventiveActions'] ?? []),
        urgencyLevel: data['urgencyLevel'] ?? 'Regular',
      );
    }).toList();

    assessments.sort((a, b) => b.date.compareTo(a.date));
    return assessments;
  }

  @override
  Future<void> addAssessment(AssessmentModel assessment) async {
    await _firestore.collection('assessments').doc(assessment.id).set({
      'id': assessment.id,
      'userId': assessment.userId,
      'date': Timestamp.fromDate(assessment.date),
      'primarySymptoms': assessment.primarySymptoms,
      'details': assessment.details,
      'associatedSymptoms': assessment.associatedSymptoms,
      'medicalHistory': assessment.medicalHistory,
      'lifestyle': assessment.lifestyle,
      'overallRiskScore': assessment.overallRiskScore,
      'riskCategory': assessment.riskCategory,
      'diseaseProbability': assessment.diseaseProbability,
      'clinicalSummary': assessment.clinicalSummary,
      'possibleCauses': assessment.possibleCauses,
      'recommendations': assessment.recommendations,
      'preventiveActions': assessment.preventiveActions,
      'urgencyLevel': assessment.urgencyLevel,
    });
  }

  @override
  Future<List<AppointmentModel>> getAppointments(String userId) async {
    final query = await _firestore
        .collection('appointments')
        .where('userId', isEqualTo: userId)
        .get();

    final appointments = query.docs.map((doc) => _mapToAppointment(doc)).toList();
    appointments.sort((a, b) => b.preferredDateTime.compareTo(a.preferredDateTime));
    return appointments;
  }

  @override
  Future<List<AppointmentModel>> getAllAppointmentsAdmin() async {
    final query = await _firestore
        .collection('appointments')
        .orderBy('preferredDateTime', descending: true)
        .get();

    return query.docs.map((doc) => _mapToAppointment(doc)).toList();
  }

  AppointmentModel _mapToAppointment(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return AppointmentModel(
      id: data['id'] ?? doc.id,
      userId: data['userId'],
      patientName: data['patientName'] ?? 'Unknown',
      mobileNumber: data['mobileNumber'] ?? '',
      preferredDateTime: (data['preferredDateTime'] as Timestamp).toDate(),
      doctorSpecialty: data['doctorSpecialty'] ?? '',
      symptomsSummary: data['symptomsSummary'] ?? '',
      status: data['status'] ?? 'Pending',
    );
  }

  @override
  Future<void> addAppointment(AppointmentModel appointment) async {
    await _firestore.collection('appointments').doc(appointment.id).set({
      'id': appointment.id,
      'userId': appointment.userId,
      'patientName': appointment.patientName,
      'mobileNumber': appointment.mobileNumber,
      'preferredDateTime': Timestamp.fromDate(appointment.preferredDateTime),
      'doctorSpecialty': appointment.doctorSpecialty,
      'symptomsSummary': appointment.symptomsSummary,
      'status': appointment.status,
    });
  }

  @override
  Future<void> updateAppointmentStatus(String appointmentId, String status) async {
    await _firestore.collection('appointments').doc(appointmentId).update({
      'status': status,
    });
  }

  @override
  Future<List<NotificationModel>> getNotifications(String userId) async {
    final query = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .get();

    final notifications = query.docs.map((doc) {
      final data = doc.data();
      return NotificationModel(
        id: data['id'] ?? doc.id,
        userId: data['userId'],
        title: data['title'] ?? '',
        body: data['body'] ?? '',
        timestamp: (data['timestamp'] as Timestamp).toDate(),
        category: data['category'] ?? '',
      );
    }).toList();
    
    notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return notifications;
  }

  @override
  Future<void> addNotification(NotificationModel notification) async {
    await _firestore.collection('notifications').doc(notification.id).set({
      'id': notification.id,
      'userId': notification.userId,
      'title': notification.title,
      'body': notification.body,
      'timestamp': Timestamp.fromDate(notification.timestamp),
      'category': notification.category,
    });
  }

  @override
  Future<List<MedicineReminderModel>> getReminders(String userId) async {
    final query = await _firestore
        .collection('reminders')
        .where('userId', isEqualTo: userId)
        .get();

    return query.docs.map((doc) {
      final data = doc.data();
      return MedicineReminderModel(
        id: data['id'] ?? doc.id,
        userId: data['userId'],
        name: data['name'] ?? '',
        dosage: data['dosage'] ?? '',
        frequency: data['frequency'] ?? '',
        reminderTime: data['reminderTime'] ?? '',
        isTaken: data['isTaken'] ?? false,
      );
    }).toList();
  }

  @override
  Future<void> addReminder(MedicineReminderModel reminder) async {
    await _firestore.collection('reminders').doc(reminder.id).set({
      'id': reminder.id,
      'userId': reminder.userId,
      'name': reminder.name,
      'dosage': reminder.dosage,
      'frequency': reminder.frequency,
      'reminderTime': reminder.reminderTime,
      'isTaken': reminder.isTaken,
    });
  }

  @override
  Future<void> toggleReminderStatus(String reminderId, bool isTaken) async {
    await _firestore.collection('reminders').doc(reminderId).update({
      'isTaken': isTaken,
    });
  }
}
