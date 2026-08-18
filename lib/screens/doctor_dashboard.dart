import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../theme/colors.dart';
import '../widgets/app_card.dart';
import '../widgets/stat_card.dart';
import '../widgets/app_button.dart';
import '../widgets/app_badge.dart';
import '../widgets/app_text_field.dart';
import '../widgets/app_layout.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/empty_state.dart';
import '../state/app_state.dart';
import '../services/db_service.dart';
import '../data/doctor_database.dart';
import '../utils/web_download_helper.dart';
import '../utils/pdf_generator_helper.dart';

class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({Key? key}) : super(key: key);

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  AppointmentModel? _selectedAppointment;
  ConsultationModel? _activeConsultation;

  final _clinicalAssessmentController = TextEditingController();
  final _clinicalNotesController = TextEditingController();
  final _recommendationsController = TextEditingController();
  final _treatmentInstructionsController = TextEditingController();
  final _followUpNotesController = TextEditingController();
  bool _followUpRequired = false;
  DateTime? _followUpDate;
  bool _isSavingConsultation = false;

  @override
  void dispose() {
    _clinicalAssessmentController.dispose();
    _clinicalNotesController.dispose();
    _recommendationsController.dispose();
    _treatmentInstructionsController.dispose();
    _followUpNotesController.dispose();
    super.dispose();
  }

  void _openConsultationWorkspace(AppointmentModel appt) async {
    setState(() {
      _selectedAppointment = appt;
      _isLoadingConsultation = true;
    });

    final state = AppStateProvider.of(context);
    final existingConsultation = await state.dbService.getConsultationByAppointmentId(appt.id);

    if (mounted) {
      setState(() {
        _activeConsultation = existingConsultation;
        _clinicalAssessmentController.text = existingConsultation?.clinicalAssessment ?? '';
        _clinicalNotesController.text = existingConsultation?.clinicalNotes ?? '';
        _recommendationsController.text = existingConsultation?.recommendations ?? '';
        _treatmentInstructionsController.text = existingConsultation?.treatmentInstructions ?? '';
        _followUpNotesController.text = existingConsultation?.followUpNotes ?? '';
        _followUpRequired = existingConsultation?.followUpRequired ?? false;
        _followUpDate = existingConsultation?.followUpDate;
        _isLoadingConsultation = false;
      });
    }
  }

  void _closeConsultationWorkspace() {
    setState(() {
      _selectedAppointment = null;
      _activeConsultation = null;
    });
  }

  Future<Uint8List> _getOrGenerate21SectionPdfBytes(AppointmentModel appt, AppState state) async {
    if (appt.reportStoragePath.isNotEmpty) {
      try {
        final ref = FirebaseStorage.instance.ref(appt.reportStoragePath);
        final bytes = await ref.getData(15 * 1024 * 1024);
        if (bytes != null && bytes.isNotEmpty) return bytes;
      } catch (_) {}
    }

    if (appt.reportUrl.isNotEmpty && appt.reportUrl.startsWith('http')) {
      try {
        final bytes = await fetchPdfBytesFromUrl(appt.reportUrl);
        if (bytes != null && bytes.isNotEmpty) return bytes;
      } catch (_) {}
    }

    AssessmentModel? assessment;
    if (appt.reportId.isNotEmpty) {
      try {
        assessment = await state.dbService.getAssessmentById(appt.reportId);
      } catch (_) {}
    }

    assessment ??= AssessmentModel(
      id: appt.reportId.isNotEmpty ? appt.reportId : appt.id,
      userId: appt.userId,
      date: appt.createdAt,
      primarySymptoms: appt.symptomsSummary.isNotEmpty ? appt.symptomsSummary.split(', ').toList() : ['General Clinical Assessment'],
      details: {
        'severity': 5.0,
        'duration': 'Recent',
        'pattern': 'Intermittent',
        'recommendedDoctor': appt.doctorSpecialty,
        'patientName': appt.patientName,
        'patientEmail': appt.patientEmail,
        'mobileNumber': appt.mobileNumber,
      },
      associatedSymptoms: const [],
      medicalHistory: const [],
      lifestyle: const {'smoking': 'Never', 'alcohol': 'Rarely', 'exercise': 'Regular', 'sleep': 7.0, 'water': 2.0, 'stress': 'Moderate'},
      overallRiskScore: appt.riskScore,
      riskCategory: appt.riskLevel.isNotEmpty ? appt.riskLevel : 'Moderate Risk',
      diseaseProbability: {appt.doctorSpecialty: appt.riskScore},
      clinicalSummary: 'Official HealthGuard AI Clinical Medical Assessment Report for ${appt.patientName}.',
      possibleCauses: [appt.doctorSpecialty],
      recommendations: const ['Consult specialist physician for physical clinical examination.'],
      preventiveActions: const ['Monitor vital signs regularly'],
      urgencyLevel: 'Regular',
    );

    return await generate21SectionMedicalReportPdfBytes(
      assessment: assessment,
      user: state.currentUser?.uid == appt.userId ? state.currentUser : null,
    );
  }

  Future<void> _handleViewReport(AppointmentModel appt) async {
    final reportId = appt.reportId.isNotEmpty ? appt.reportId : appt.id;
    Navigator.pushNamed(context, '/report?id=$reportId');
  }

  Future<void> _handleDownloadReport(AppointmentModel appt) async {
    final state = AppStateProvider.of(context);
    final fileName = appt.reportFileName.isNotEmpty ? appt.reportFileName : 'HealthGuard_AI_Medical_Report_${appt.id}.pdf';
    final pdfBytes = await _getOrGenerate21SectionPdfBytes(appt, state);
    await downloadPdfFileFromUrl('', fileName, bytes: pdfBytes);
  }

  Future<void> _saveConsultation({bool complete = false}) async {
    if (_selectedAppointment == null) return;
    final state = AppStateProvider.of(context);
    final doctor = state.currentDoctor ?? doctorDatabase.first;

    setState(() => _isSavingConsultation = true);

    try {
      final consultationId = _activeConsultation?.id ?? 'cons_${DateTime.now().millisecondsSinceEpoch}';
      final consultation = ConsultationModel(
        id: consultationId,
        appointmentId: _selectedAppointment!.id,
        patientId: _selectedAppointment!.userId,
        patientName: _selectedAppointment!.patientName,
        doctorId: doctor.id,
        doctorName: doctor.name,
        doctorSpecialty: doctor.specialty,
        clinicalAssessment: _clinicalAssessmentController.text.trim(),
        clinicalNotes: _clinicalNotesController.text.trim(),
        recommendations: _recommendationsController.text.trim(),
        treatmentInstructions: _treatmentInstructionsController.text.trim(),
        followUpRequired: _followUpRequired,
        followUpDate: _followUpDate,
        followUpNotes: _followUpNotesController.text.trim(),
        status: complete ? 'Completed' : 'Draft',
      );

      await state.dbService.saveConsultation(consultation);

      if (complete) {
        await state.dbService.completeConsultation(consultationId, _selectedAppointment!.id, doctor.id);
        setState(() {
          _selectedAppointment!.status = 'Completed';
        });
      }

      if (mounted) {
        setState(() => _isSavingConsultation = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(complete ? 'Consultation completed successfully!' : 'Consultation draft saved successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        if (complete) _closeConsultationWorkspace();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSavingConsultation = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving consultation: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final state = AppStateProvider.of(context);

    if (state.currentDoctor == null) {
      return Scaffold(
        backgroundColor: AppColors.getBg(isDark),
        body: Center(
          child: AppCard(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.medical_services_outlined, color: AppColors.primaryBlue, size: 48),
                  const SizedBox(height: 16),
                  Text('Physician Access Required', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.getTextPrimary(isDark))),
                  const SizedBox(height: 8),
                  Text('Please sign in with your physician credentials to access the Doctor Clinical Workspace.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.getTextSecondary(isDark), fontSize: 13)),
                  const SizedBox(height: 24),
                  AppButton(
                    label: 'Go to Doctor Login',
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/doctor-login', (route) => false),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final currentDoc = state.currentDoctor!;

    // Filter appointments strictly by currentDoctorId
    final docAppts = state.appointments.where((a) {
      return a.doctorId == currentDoc.id || a.doctorName.toLowerCase() == currentDoc.name.toLowerCase();
    }).toList();

    int todayCount = docAppts.where((a) => a.preferredDateTime.day == DateTime.now().day).length;
    int upcomingCount = docAppts.where((a) => a.preferredDateTime.isAfter(DateTime.now())).length;
    int completedCount = docAppts.where((a) => a.status.toLowerCase() == 'completed').length;
    int pendingCount = docAppts.where((a) => a.status.toLowerCase() == 'pending').length;

    final bool isDesktop = MediaQuery.of(context).size.width >= 900;

    return AppLayout(
      title: 'Dr. ${currentDoc.name}',
      subtitle: '${currentDoc.specialty} • ${currentDoc.hospital}',
      role: UserRole.doctor,
      currentRoute: '/doctor-dashboard',
      body: _selectedAppointment != null
          ? _buildConsultationWorkspace(isDark)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Doctor Stats Grid
                LayoutBuilder(
                  builder: (ctx, constraints) {
                    int count = isDesktop ? 4 : (constraints.maxWidth > 600 ? 2 : 1);
                    return GridView.count(
                      crossAxisCount: count,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: isDesktop ? 2.2 : 2.5,
                      children: [
                        StatCard(title: "Today's Schedule", value: '$todayCount', icon: Icons.today_outlined, iconBgColor: AppColors.primaryTeal.withOpacity(0.15), iconColor: AppColors.primaryTeal),
                        StatCard(title: 'Upcoming Consults', value: '$upcomingCount', icon: Icons.calendar_month_outlined, iconBgColor: AppColors.primaryBlue.withOpacity(0.12), iconColor: AppColors.primaryBlue),
                        StatCard(title: 'Completed', value: '$completedCount', icon: Icons.task_alt_outlined, iconBgColor: AppColors.success.withOpacity(0.15), iconColor: AppColors.success),
                        StatCard(title: 'Pending Action', value: '$pendingCount', icon: Icons.pending_actions_outlined, iconBgColor: AppColors.warning.withOpacity(0.15), iconColor: AppColors.warning),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 28),

                // Clinical Schedule Table Container
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Today's Clinical Schedule", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.getTextPrimary(isDark))),
                          Text('${docAppts.length} Assigned Patients', style: TextStyle(fontSize: 12, color: AppColors.getTextSecondary(isDark))),
                        ],
                      ),
                      const SizedBox(height: 16),

                      if (docAppts.isEmpty)
                        EmptyState(
                          icon: Icons.assignment_outlined,
                          title: 'No Clinical Appointments Scheduled',
                          description: 'No patient appointments are assigned to your schedule.',
                        )
                      else
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(isDark ? AppColors.darkSurface : const Color(0xFFF1F5F9)),
                            columns: const [
                              DataColumn(label: Text('Time Slot', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Patient Name', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Symptom Overview', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Risk Score', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                            ],
                            rows: docAppts.map((appt) {
                              return DataRow(
                                cells: [
                                  DataCell(Text(appt.timeSlot, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                                  DataCell(Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(appt.patientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                      Text(appt.patientEmail, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                    ],
                                  )),
                                  DataCell(Text(appt.symptomsSummary, style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                  DataCell(AppBadge.risk(appt.riskLevel)),
                                  DataCell(AppBadge.status(appt.status)),
                                  DataCell(Row(
                                    children: [
                                      AppButton(
                                        label: 'Consultation Workspace',
                                        icon: Icons.medical_information_outlined,
                                        size: AppButtonSize.small,
                                        onPressed: () => _openConsultationWorkspace(appt),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.visibility_outlined, size: 18, color: AppColors.primaryTeal),
                                        tooltip: 'View Patient Report',
                                        onPressed: () => _handleViewReport(appt),
                                      ),
                                    ],
                                  )),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildConsultationWorkspace(bool isDark) {
    final appt = _selectedAppointment!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AppButton(
              label: 'Back to Clinical Schedule',
              icon: Icons.arrow_back,
              variant: AppButtonVariant.secondary,
              size: AppButtonSize.small,
              onPressed: _closeConsultationWorkspace,
            ),
            const Spacer(),
            AppBadge.status(appt.status),
          ],
        ),
        const SizedBox(height: 20),

        // Patient Overview Header Card
        AppCard(
          backgroundColor: AppColors.primaryBlue,
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.primaryTeal,
                child: Text(
                  appt.patientName.characters.first.toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Patient: ${appt.patientName}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('Email: ${appt.patientEmail} • Phone: ${appt.mobileNumber}', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                    Text('Appt ID: ${appt.id} • Slot: ${appt.timeSlot}', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                  ],
                ),
              ),
              AppButton(
                label: 'View Full Report',
                icon: Icons.description_outlined,
                variant: AppButtonVariant.outline,
                size: AppButtonSize.small,
                onPressed: () => _handleViewReport(appt),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Consultation Form Workspace
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Doctor\'s Clinical Assessment & Documentation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.getTextPrimary(isDark))),
              const SizedBox(height: 16),

              AppTextField(
                label: 'Clinical Assessment & Diagnostic Summary',
                hint: 'Record physical findings, blood pressure, vitals & diagnostic observations...',
                controller: _clinicalAssessmentController,
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              AppTextField(
                label: 'Clinical Notes',
                hint: 'Enter detailed clinical observations...',
                controller: _clinicalNotesController,
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              AppTextField(
                label: 'Treatment & Medication Instructions',
                hint: 'Specify prescribed medications, dosage, frequency & treatment plan...',
                controller: _treatmentInstructionsController,
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              AppTextField(
                label: 'Recommendations & Patient Guidance',
                hint: 'Dietary, lifestyle, or specialized testing advice...',
                controller: _recommendationsController,
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton(
                    label: 'Save Draft',
                    icon: Icons.save_outlined,
                    variant: AppButtonVariant.secondary,
                    isLoading: _isSavingConsultation,
                    onPressed: () => _saveConsultation(complete: false),
                  ),
                  const SizedBox(width: 12),
                  AppButton(
                    label: 'COMPLETE CONSULTATION',
                    icon: Icons.check_circle_outline,
                    isLoading: _isSavingConsultation,
                    onPressed: () => _saveConsultation(complete: true),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
