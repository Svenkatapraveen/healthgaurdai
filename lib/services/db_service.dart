import 'dart:async';

class AssessmentModel {
  final String id;
  final String userId;
  final DateTime date;
  final List<String> primarySymptoms;
  final Map<String, dynamic> details; // severity, location, pattern, duration etc.
  final List<String> associatedSymptoms;
  final List<String> medicalHistory;
  final Map<String, dynamic> lifestyle;
  
  // AI Results fields
  final double overallRiskScore; // 0-100
  final String riskCategory; // Low Risk, Moderate Risk, High Risk, Critical Risk
  final Map<String, double> diseaseProbability; // e.g. {"Heart Disease": 0.15, "Diabetes": 0.45}
  final String clinicalSummary;
  final List<String> possibleCauses;
  final List<String> recommendations;
  final List<String> preventiveActions;
  final String urgencyLevel; // Regular, Urgent, Emergency

  AssessmentModel({
    required this.id,
    required this.userId,
    required this.date,
    required this.primarySymptoms,
    required this.details,
    required this.associatedSymptoms,
    required this.medicalHistory,
    required this.lifestyle,
    required this.overallRiskScore,
    required this.riskCategory,
    required this.diseaseProbability,
    required this.clinicalSummary,
    required this.possibleCauses,
    required this.recommendations,
    required this.preventiveActions,
    required this.urgencyLevel,
  });
}

class AppointmentModel {
  final String id; // HG-2026-XXXXXX
  final String userId;
  final String patientName;
  final String patientEmail;
  final String mobileNumber;

  final String doctorId;
  final String doctorName;
  final String doctorSpecialty;

  DateTime preferredDateTime;
  final String symptomsSummary;

  final String reportId;
  final String reportFileName;
  final String reportUrl;
  final String reportStoragePath;
  final DateTime? reportUploadedAt;

  final double riskScore;
  final String riskLevel;

  String status; // Pending, Approved, Rejected, Rescheduled, Completed
  String? rejectionReason;
  DateTime? previousAppointmentDate;
  String? previousAppointmentTime;
  DateTime? completedAt;
  String? completedBy;

  final DateTime createdAt;
  DateTime? updatedAt;

  AppointmentModel({
    required this.id,
    required this.userId,
    required this.patientName,
    this.patientEmail = '',
    required this.mobileNumber,
    this.doctorId = '',
    this.doctorName = '',
    required this.doctorSpecialty,
    required this.preferredDateTime,
    this.symptomsSummary = '',
    this.reportId = '',
    this.reportFileName = '',
    this.reportUrl = '',
    this.reportStoragePath = '',
    this.reportUploadedAt,
    this.riskScore = 0.0,
    this.riskLevel = 'Moderate Risk',
    required this.status,
    this.rejectionReason,
    this.previousAppointmentDate,
    this.previousAppointmentTime,
    this.completedAt,
    this.completedBy,
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

class ConsultationModel {
  final String id; // consultationId
  final String appointmentId;
  final String patientId;
  final String patientName;
  final String doctorId;
  final String doctorName;
  final String doctorSpecialty;
  final String clinicalAssessment;
  final String clinicalNotes;
  final String recommendations;
  final String treatmentInstructions;
  final bool followUpRequired;
  final DateTime? followUpDate;
  final String followUpNotes;
  final String status; // Draft, Completed
  final DateTime createdAt;
  final DateTime updatedAt;

  ConsultationModel({
    required this.id,
    required this.appointmentId,
    required this.patientId,
    this.patientName = '',
    required this.doctorId,
    this.doctorName = '',
    this.doctorSpecialty = '',
    this.clinicalAssessment = '',
    this.clinicalNotes = '',
    this.recommendations = '',
    this.treatmentInstructions = '',
    this.followUpRequired = false,
    this.followUpDate,
    this.followUpNotes = '',
    this.status = 'Draft',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();
}

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final DateTime timestamp;
  final String category; // Appointment, Alert, Health, Reminder

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.category,
  });
}

class MedicineReminderModel {
  final String id;
  final String userId;
  final String name;
  final String dosage;
  final String frequency;
  final String reminderTime; // e.g. "08:00 AM"
  final bool isTaken;

  MedicineReminderModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.reminderTime,
    this.isTaken = false,
  });
}

abstract class DatabaseService {
  Future<List<AssessmentModel>> getAssessments(String userId);
  Future<AssessmentModel?> getAssessmentById(String id);
  Future<void> addAssessment(AssessmentModel assessment);
  
  Future<List<AppointmentModel>> getAppointments(String userId);
  Future<List<AppointmentModel>> getDoctorAppointments(String doctorId);
  Future<List<AppointmentModel>> getAllAppointmentsAdmin();
  Future<void> addAppointment(AppointmentModel appointment);
  Future<void> updateAppointmentStatus(String appointmentId, String status, {String? rejectionReason});
  Future<void> rescheduleAppointment(String appointmentId, DateTime newDateTime);

  Future<ConsultationModel?> getConsultationByAppointmentId(String appointmentId);
  Future<List<ConsultationModel>> getDoctorConsultations(String doctorId);
  Future<void> saveConsultation(ConsultationModel consultation);
  Future<void> completeConsultation(String consultationId, String appointmentId, String doctorId);

  Future<List<NotificationModel>> getNotifications(String userId);
  Future<void> addNotification(NotificationModel notification);

  Future<List<MedicineReminderModel>> getReminders(String userId);
  Future<void> addReminder(MedicineReminderModel reminder);
  Future<void> toggleReminderStatus(String reminderId, bool isTaken);
}

class MockDbService implements DatabaseService {
  static final MockDbService _instance = MockDbService._internal();
  factory MockDbService() => _instance;
  MockDbService._internal() {
    _seedData();
  }

  final List<AssessmentModel> _assessments = [];
  final List<AppointmentModel> _appointments = [];
  final List<NotificationModel> _notifications = [];
  final List<MedicineReminderModel> _reminders = [];

  void _seedData() {
    // Seed for general user "user_uid_01" (Alex Carter)
    _assessments.addAll([
      AssessmentModel(
        id: 'asm_01',
        userId: 'user_uid_01',
        date: DateTime.now().subtract(const Duration(days: 14)),
        primarySymptoms: ['Chest Pain'],
        details: {'severity': 4.0, 'location': 'Center', 'duration': 'Days', 'pattern': 'Intermittent'},
        associatedSymptoms: ['Fatigue', 'Dizziness'],
        medicalHistory: ['Hypertension'],
        lifestyle: {'Water': 1.5, 'Sleep': 6.0, 'Stress': 'Moderate'},
        overallRiskScore: 42.0,
        riskCategory: 'Moderate Risk',
        diseaseProbability: {
          'Hypertension': 58.0,
          'Heart Disease': 32.0,
          'Obesity': 15.0,
          'Diabetes': 12.0,
          'Kidney Disease': 8.0,
        },
        clinicalSummary: 'Patient reports mild chest pain with history of hypertension. Cardiovascular indicators warrant monitoring.',
        possibleCauses: ['Muscle strain', 'Angina related to blood pressure', 'Gastroesophageal reflux'],
        recommendations: ['Avoid strenuous exercise temporarily', 'Monitor blood pressure daily', 'Schedule a doctor review'],
        preventiveActions: ['Reduce sodium intake', 'Increase dynamic walking', 'Engage in deep breathing exercises'],
        urgencyLevel: 'Urgent',
      ),
      AssessmentModel(
        id: 'asm_02',
        userId: 'user_uid_01',
        date: DateTime.now().subtract(const Duration(days: 28)),
        primarySymptoms: ['Headache'],
        details: {'severity': 6.0, 'location': 'Front', 'duration': 'Hours', 'pattern': 'Increasing'},
        associatedSymptoms: ['Fatigue'],
        medicalHistory: [],
        lifestyle: {'Water': 1.0, 'Sleep': 5.0, 'Stress': 'High'},
        overallRiskScore: 28.0,
        riskCategory: 'Low Risk',
        diseaseProbability: {
          'Hypertension': 20.0,
          'Heart Disease': 5.0,
          'Obesity': 18.0,
          'Diabetes': 10.0,
          'Kidney Disease': 2.0,
        },
        clinicalSummary: 'Tension-type headache likely correlated with acute dehydration and elevated stress levels.',
        possibleCauses: ['Dehydration headache', 'Stress headache', 'Lack of restorative sleep'],
        recommendations: ['Drink 2-3 liters of water daily', 'Obtain 7-8 hours of sleep', 'Limit screen time before bed'],
        preventiveActions: ['Implement 10-minute stretching breaks', 'Keep water bottle nearby', 'Establish routine sleeping times'],
        urgencyLevel: 'Regular',
      ),
    ]);

    // Seed Appointments
    _appointments.addAll([
      AppointmentModel(
        id: 'HG-2026-000001',
        userId: 'user_uid_01',
        patientName: 'Alex Carter',
        mobileNumber: '+1 555-0122',
        preferredDateTime: DateTime.now().add(const Duration(days: 3, hours: 2)),
        doctorSpecialty: 'Cardiologist',
        symptomsSummary: 'Routine check-up for blood pressure concerns and mild chest discomfort.',
        status: 'Approved',
      ),
      AppointmentModel(
        id: 'HG-2026-000002',
        userId: 'user_uid_01',
        patientName: 'Alex Carter',
        mobileNumber: '+1 555-0122',
        preferredDateTime: DateTime.now().subtract(const Duration(days: 10)),
        doctorSpecialty: 'General Physician',
        symptomsSummary: 'Frequent front headaches and fatigue consultation.',
        status: 'Completed',
      )
    ]);

    // Seed Notifications
    _notifications.addAll([
      NotificationModel(
        id: 'notif_01',
        userId: 'user_uid_01',
        title: 'Appointment Confirmed',
        body: 'Your booking with the Cardiologist (HG-2026-000001) has been approved for June 19th at 11:00 AM.',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        category: 'Appointment',
      ),
      NotificationModel(
        id: 'notif_02',
        userId: 'user_uid_01',
        title: 'Medication Alert',
        body: 'Time to take Lisinopril (10mg) for blood pressure control.',
        timestamp: DateTime.now().subtract(const Duration(hours: 4)),
        category: 'Reminder',
      ),
      NotificationModel(
        id: 'notif_03',
        userId: 'user_uid_01',
        title: 'Hydration Goal Update',
        body: 'You are 1.2L short of your daily hydration target. Drink a glass of water now.',
        timestamp: DateTime.now().subtract(const Duration(hours: 8)),
        category: 'Health',
      ),
      NotificationModel(
        id: 'notif_04',
        userId: 'user_uid_01',
        title: 'High Stress Alert',
        body: 'Your logged stress levels indicate elevated values. Try a 5-minute deep breathing session.',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        category: 'Alert',
      ),
    ]);

    // Seed Reminders
    _reminders.addAll([
      MedicineReminderModel(
        id: 'rem_01',
        userId: 'user_uid_01',
        name: 'Lisinopril',
        dosage: '10mg',
        frequency: 'Once Daily',
        reminderTime: '08:00 AM',
        isTaken: true,
      ),
      MedicineReminderModel(
        id: 'rem_02',
        userId: 'user_uid_01',
        name: 'Metformin',
        dosage: '500mg',
        frequency: 'Twice Daily',
        reminderTime: '08:00 PM',
        isTaken: false,
      ),
      MedicineReminderModel(
        id: 'rem_03',
        userId: 'user_uid_01',
        name: 'Omega 3 Fish Oil',
        dosage: '1000mg',
        frequency: 'Once Daily',
        reminderTime: '12:30 PM',
        isTaken: false,
      ),
    ]);
  }

  @override
  Future<List<AssessmentModel>> getAssessments(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _assessments.where((e) => e.userId == userId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Future<AssessmentModel?> getAssessmentById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _assessments.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> addAssessment(AssessmentModel assessment) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _assessments.add(assessment);
  }

  @override
  Future<List<AppointmentModel>> getAppointments(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _appointments.where((e) => e.userId == userId).toList()
      ..sort((a, b) => b.preferredDateTime.compareTo(a.preferredDateTime));
  }

  @override
  Future<List<AppointmentModel>> getAllAppointmentsAdmin() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List.from(_appointments)
      ..sort((a, b) => b.preferredDateTime.compareTo(a.preferredDateTime));
  }

  @override
  Future<void> addAppointment(AppointmentModel appointment) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _appointments.add(appointment);
  }

  @override
  Future<void> updateAppointmentStatus(String appointmentId, String status, {String? rejectionReason}) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final index = _appointments.indexWhere((e) => e.id == appointmentId);
    if (index != -1) {
      _appointments[index].status = status;
      if (rejectionReason != null) {
        _appointments[index].rejectionReason = rejectionReason;
      }
      _appointments[index].updatedAt = DateTime.now();
    }
  }

  @override
  Future<void> rescheduleAppointment(String appointmentId, DateTime newDateTime) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final index = _appointments.indexWhere((e) => e.id == appointmentId);
    if (index != -1) {
      _appointments[index].previousAppointmentDate = _appointments[index].preferredDateTime;
      _appointments[index].preferredDateTime = newDateTime;
      _appointments[index].status = 'Rescheduled';
      _appointments[index].updatedAt = DateTime.now();
    }
  }

  final List<ConsultationModel> _consultations = [];

  @override
  Future<List<AppointmentModel>> getDoctorAppointments(String doctorId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _appointments.where((e) => e.doctorId == doctorId || e.doctorSpecialty.toLowerCase().contains(doctorId.toLowerCase())).toList()
      ..sort((a, b) => b.preferredDateTime.compareTo(a.preferredDateTime));
  }

  @override
  Future<ConsultationModel?> getConsultationByAppointmentId(String appointmentId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _consultations.firstWhere((c) => c.appointmentId == appointmentId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<ConsultationModel>> getDoctorConsultations(String doctorId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _consultations.where((c) => c.doctorId == doctorId).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Future<void> saveConsultation(ConsultationModel consultation) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final idx = _consultations.indexWhere((c) => c.id == consultation.id || c.appointmentId == consultation.appointmentId);
    if (idx != -1) {
      _consultations[idx] = consultation;
    } else {
      _consultations.add(consultation);
    }
  }

  @override
  Future<void> completeConsultation(String consultationId, String appointmentId, String doctorId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final apptIdx = _appointments.indexWhere((a) => a.id == appointmentId);
    if (apptIdx != -1) {
      _appointments[apptIdx].status = 'Completed';
      _appointments[apptIdx].completedAt = DateTime.now();
      _appointments[apptIdx].completedBy = doctorId;
      _appointments[apptIdx].updatedAt = DateTime.now();
    }
    final cIdx = _consultations.indexWhere((c) => c.id == consultationId || c.appointmentId == appointmentId);
    if (cIdx != -1) {
      final old = _consultations[cIdx];
      _consultations[cIdx] = ConsultationModel(
        id: old.id,
        appointmentId: old.appointmentId,
        patientId: old.patientId,
        patientName: old.patientName,
        doctorId: old.doctorId,
        doctorName: old.doctorName,
        doctorSpecialty: old.doctorSpecialty,
        clinicalAssessment: old.clinicalAssessment,
        clinicalNotes: old.clinicalNotes,
        recommendations: old.recommendations,
        treatmentInstructions: old.treatmentInstructions,
        followUpRequired: old.followUpRequired,
        followUpDate: old.followUpDate,
        followUpNotes: old.followUpNotes,
        status: 'Completed',
        createdAt: old.createdAt,
        updatedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<List<NotificationModel>> getNotifications(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _notifications.where((e) => e.userId == userId).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  @override
  Future<void> addNotification(NotificationModel notification) async {
    _notifications.add(notification);
  }

  @override
  Future<List<MedicineReminderModel>> getReminders(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _reminders.where((e) => e.userId == userId).toList();
  }

  @override
  Future<void> addReminder(MedicineReminderModel reminder) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _reminders.add(reminder);
  }

  @override
  Future<void> toggleReminderStatus(String reminderId, bool isTaken) async {
    final index = _reminders.indexWhere((e) => e.id == reminderId);
    if (index != -1) {
      final old = _reminders[index];
      _reminders[index] = MedicineReminderModel(
        id: old.id,
        userId: old.userId,
        name: old.name,
        dosage: old.dosage,
        frequency: old.frequency,
        reminderTime: old.reminderTime,
        isTaken: isTaken,
      );
    }
  }
}
