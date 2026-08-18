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

  Stream<List<AppointmentModel>> streamUserAppointments(String userId) {
    return _firestore
        .collection('appointments')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs.map((doc) => _mapToAppointment(doc)).toList();
          list.sort((a, b) => b.preferredDateTime.compareTo(a.preferredDateTime));
          return list;
        });
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
      userId: data['userId'] ?? data['patientId'] ?? '',
      patientName: data['patientName'] ?? 'Unknown',
      patientEmail: data['patientEmail'] ?? '',
      mobileNumber: data['mobileNumber'] ?? data['patientMobile'] ?? '',
      doctorId: data['doctorId'] ?? '',
      doctorName: data['doctorName'] ?? '',
      doctorSpecialty: data['doctorSpecialty'] ?? '',
      preferredDateTime: data['preferredDateTime'] is Timestamp 
          ? (data['preferredDateTime'] as Timestamp).toDate() 
          : (data['appointmentDate'] is Timestamp ? (data['appointmentDate'] as Timestamp).toDate() : DateTime.now()),
      symptomsSummary: data['symptomsSummary'] ?? '',
      reportId: data['reportId'] ?? '',
      reportFileName: data['reportFileName'] ?? '',
      reportUrl: data['reportUrl'] ?? '',
      reportStoragePath: data['reportStoragePath'] ?? '',
      reportUploadedAt: data['reportUploadedAt'] is Timestamp 
          ? (data['reportUploadedAt'] as Timestamp).toDate() 
          : null,
      riskScore: (data['riskScore'] is num) ? (data['riskScore'] as num).toDouble() : 0.0,
      riskLevel: data['riskLevel'] ?? 'Moderate Risk',
      status: data['status'] ?? 'Pending',
      rejectionReason: data['rejectionReason'],
      previousAppointmentDate: data['previousAppointmentDate'] is Timestamp 
          ? (data['previousAppointmentDate'] as Timestamp).toDate() 
          : null,
      previousAppointmentTime: data['previousAppointmentTime'],
      completedAt: data['completedAt'] is Timestamp 
          ? (data['completedAt'] as Timestamp).toDate() 
          : null,
      completedBy: data['completedBy'],
      createdAt: data['createdAt'] is Timestamp 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
      updatedAt: data['updatedAt'] is Timestamp 
          ? (data['updatedAt'] as Timestamp).toDate() 
          : null,
    );
  }

  @override
  Future<List<AppointmentModel>> getDoctorAppointments(String doctorId) async {
    final query = await _firestore
        .collection('appointments')
        .where('doctorId', isEqualTo: doctorId)
        .get();

    final appointments = query.docs.map((doc) => _mapToAppointment(doc)).toList();
    appointments.sort((a, b) => b.preferredDateTime.compareTo(a.preferredDateTime));
    return appointments;
  }

  Stream<List<AppointmentModel>> streamDoctorAppointments(String doctorId) {
    return _firestore
        .collection('appointments')
        .where('doctorId', isEqualTo: doctorId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => _mapToAppointment(doc)).toList();
      list.sort((a, b) => b.preferredDateTime.compareTo(a.preferredDateTime));
      return list;
    });
  }

  @override
  Future<ConsultationModel?> getConsultationByAppointmentId(String appointmentId) async {
    final query = await _firestore
        .collection('consultations')
        .where('appointmentId', isEqualTo: appointmentId)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;
    return _mapToConsultation(query.docs.first);
  }

  @override
  Future<List<ConsultationModel>> getDoctorConsultations(String doctorId) async {
    final query = await _firestore
        .collection('consultations')
        .where('doctorId', isEqualTo: doctorId)
        .get();

    final list = query.docs.map((doc) => _mapToConsultation(doc)).toList();
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  ConsultationModel _mapToConsultation(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return ConsultationModel(
      id: data['id'] ?? doc.id,
      appointmentId: data['appointmentId'] ?? '',
      patientId: data['patientId'] ?? '',
      patientName: data['patientName'] ?? '',
      doctorId: data['doctorId'] ?? '',
      doctorName: data['doctorName'] ?? '',
      doctorSpecialty: data['doctorSpecialty'] ?? '',
      clinicalAssessment: data['clinicalAssessment'] ?? data['doctorAssessment'] ?? '',
      clinicalNotes: data['clinicalNotes'] ?? '',
      recommendations: data['recommendations'] ?? '',
      treatmentInstructions: data['treatmentInstructions'] ?? '',
      followUpRequired: data['followUpRequired'] ?? false,
      followUpDate: data['followUpDate'] is Timestamp ? (data['followUpDate'] as Timestamp).toDate() : null,
      followUpNotes: data['followUpNotes'] ?? '',
      status: data['status'] ?? 'Draft',
      createdAt: data['createdAt'] is Timestamp ? (data['createdAt'] as Timestamp).toDate() : DateTime.now(),
      updatedAt: data['updatedAt'] is Timestamp ? (data['updatedAt'] as Timestamp).toDate() : DateTime.now(),
    );
  }

  @override
  Future<void> saveConsultation(ConsultationModel consultation) async {
    final data = {
      'id': consultation.id,
      'consultationId': consultation.id,
      'appointmentId': consultation.appointmentId,
      'patientId': consultation.patientId,
      'patientName': consultation.patientName,
      'doctorId': consultation.doctorId,
      'doctorName': consultation.doctorName,
      'doctorSpecialty': consultation.doctorSpecialty,
      'clinicalAssessment': consultation.clinicalAssessment,
      'doctorAssessment': consultation.clinicalAssessment,
      'clinicalNotes': consultation.clinicalNotes,
      'recommendations': consultation.recommendations,
      'treatmentInstructions': consultation.treatmentInstructions,
      'followUpRequired': consultation.followUpRequired,
      'followUpDate': consultation.followUpDate != null ? Timestamp.fromDate(consultation.followUpDate!) : null,
      'followUpNotes': consultation.followUpNotes,
      'status': consultation.status,
      'createdAt': Timestamp.fromDate(consultation.createdAt),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };
    await _firestore.collection('consultations').doc(consultation.id).set(data, SetOptions(merge: true));
  }

  @override
  Future<void> completeConsultation(String consultationId, String appointmentId, String doctorId) async {
    final now = DateTime.now();
    await _firestore.collection('appointments').doc(appointmentId).update({
      'status': 'Completed',
      'completedAt': Timestamp.fromDate(now),
      'completedBy': doctorId,
      'updatedAt': Timestamp.fromDate(now),
    });
    await _firestore.collection('consultations').doc(consultationId).update({
      'status': 'Completed',
      'updatedAt': Timestamp.fromDate(now),
    });
  }

  @override
  Future<void> addAppointment(AppointmentModel appointment) async {
    await _firestore.collection('appointments').doc(appointment.id).set({
      'id': appointment.id,
      'appointmentId': appointment.id,
      'userId': appointment.userId,
      'patientId': appointment.userId,
      'patientName': appointment.patientName,
      'patientEmail': appointment.patientEmail,
      'mobileNumber': appointment.mobileNumber,
      'patientMobile': appointment.mobileNumber,
      'doctorId': appointment.doctorId,
      'doctorName': appointment.doctorName,
      'doctorSpecialty': appointment.doctorSpecialty,
      'preferredDateTime': Timestamp.fromDate(appointment.preferredDateTime),
      'appointmentDate': Timestamp.fromDate(appointment.preferredDateTime),
      'appointmentTime': '${appointment.preferredDateTime.hour.toString().padLeft(2, '0')}:${appointment.preferredDateTime.minute.toString().padLeft(2, '0')}',
      'symptomsSummary': appointment.symptomsSummary,
      'reportId': appointment.reportId,
      'reportFileName': appointment.reportFileName,
      'reportUrl': appointment.reportUrl,
      'reportStoragePath': appointment.reportStoragePath,
      'reportUploadedAt': appointment.reportUploadedAt != null 
          ? Timestamp.fromDate(appointment.reportUploadedAt!) 
          : Timestamp.fromDate(DateTime.now()),
      'riskScore': appointment.riskScore,
      'riskLevel': appointment.riskLevel,
      'status': appointment.status,
      'createdAt': Timestamp.fromDate(appointment.createdAt),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  @override
  Future<void> updateAppointmentStatus(String appointmentId, String status, {String? rejectionReason}) async {
    final Map<String, dynamic> updateData = {
      'status': status,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };
    if (rejectionReason != null) {
      updateData['rejectionReason'] = rejectionReason;
    }
    await _firestore.collection('appointments').doc(appointmentId).update(updateData);
  }

  @override
  Future<void> rescheduleAppointment(String appointmentId, DateTime newDateTime) async {
    final docRef = _firestore.collection('appointments').doc(appointmentId);
    final snapshot = await docRef.get();
    DateTime? prevDate;
    if (snapshot.exists && snapshot.data() != null) {
      final data = snapshot.data()!;
      if (data['preferredDateTime'] is Timestamp) {
        prevDate = (data['preferredDateTime'] as Timestamp).toDate();
      }
    }

    final timeStr = '${newDateTime.hour.toString().padLeft(2, '0')}:${newDateTime.minute.toString().padLeft(2, '0')}';
    await docRef.update({
      'status': 'Rescheduled',
      'preferredDateTime': Timestamp.fromDate(newDateTime),
      'appointmentDate': Timestamp.fromDate(newDateTime),
      'appointmentTime': timeStr,
      'previousAppointmentDate': prevDate != null ? Timestamp.fromDate(prevDate) : null,
      'previousAppointmentTime': prevDate != null ? '${prevDate.hour.toString().padLeft(2, '0')}:${prevDate.minute.toString().padLeft(2, '0')}' : null,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
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
