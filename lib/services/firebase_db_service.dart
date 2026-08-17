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
  Future<AssessmentModel?> getAssessmentById(String id) async {
    try {
      final doc = await _firestore.collection('assessments').doc(id).get();
      if (doc.exists) {
        final data = doc.data()!;
        return AssessmentModel(
          id: data['id'] ?? doc.id,
          userId: data['userId'] ?? '',
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
      }
    } catch (e) {
      print('Error fetching assessment by ID: $e');
    }
    return null;
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

  Stream<List<AppointmentModel>> streamAllAppointmentsAdmin() {
    return _firestore
        .collection('appointments')
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs.map((doc) => _mapToAppointment(doc)).toList();
          list.sort((a, b) => b.preferredDateTime.compareTo(a.preferredDateTime));
          return list;
        });
  }

  Stream<int> streamUserCount() {
    return _firestore
        .collection('users')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<int> streamAssessmentCount() {
    return _firestore
        .collection('assessments')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<int> streamAlertCount() {
    return _firestore
        .collection('notifications')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  AppointmentModel _mapToAppointment(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return AppointmentModel(
      id: data['id'] ?? doc.id,
      userId: data['userId'] ?? '',
      patientName: data['patientName'] ?? 'Unknown',
      mobileNumber: data['mobileNumber'] ?? '',
      preferredDateTime: data['preferredDateTime'] is Timestamp 
          ? (data['preferredDateTime'] as Timestamp).toDate() 
          : DateTime.now(),
      doctorSpecialty: data['doctorSpecialty'] ?? '',
      symptomsSummary: data['symptomsSummary'] ?? '',
      reportFileName: data['reportFileName'] ?? '',
      reportUrl: data['reportUrl'] ?? '',
      reportStoragePath: data['reportStoragePath'] ?? '',
      reportUploadedAt: data['reportUploadedAt'] is Timestamp 
          ? (data['reportUploadedAt'] as Timestamp).toDate() 
          : null,
      status: data['status'] ?? 'Pending',
      createdAt: data['createdAt'] is Timestamp 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
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
      'reportFileName': appointment.reportFileName,
      'reportUrl': appointment.reportUrl,
      'reportStoragePath': appointment.reportStoragePath,
      'reportUploadedAt': appointment.reportUploadedAt != null 
          ? Timestamp.fromDate(appointment.reportUploadedAt!) 
          : Timestamp.fromDate(DateTime.now()),
      'status': appointment.status,
      'createdAt': Timestamp.fromDate(appointment.createdAt),
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
