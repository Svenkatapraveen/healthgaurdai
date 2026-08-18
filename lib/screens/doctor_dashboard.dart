import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../theme/colors.dart';
import '../widgets/glass_card.dart';
import '../state/app_state.dart';
import '../services/db_service.dart';
import '../services/firebase_db_service.dart';
import '../data/doctor_database.dart';
import '../utils/web_download_helper.dart';
import '../utils/pdf_generator_helper.dart';

class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({Key? key}) : super(key: key);

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  int _selectedNavIndex = 0; // 0: Dashboard, 1: Appointments, 2: Today's Schedule, 3: My Patients, 4: Medical Reports, 5: Consultations, 6: Notifications, 7: Profile
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  // Search & Filters
  String _searchQuery = '';
  String _selectedTabFilter = 'All'; // All, Today, Upcoming, Approved, Rescheduled, Completed

  // Selected Appointment for Modal/Workspace
  AppointmentModel? _selectedAppointment;
  ConsultationModel? _activeConsultation;

  // Form Controllers for Consultation Workspace
  final _clinicalAssessmentController = TextEditingController();
  final _clinicalNotesController = TextEditingController();
  final _recommendationsController = TextEditingController();
  final _treatmentInstructionsController = TextEditingController();
  final _followUpNotesController = TextEditingController();
  bool _followUpRequired = false;
  DateTime? _followUpDate;
  bool _isSavingConsultation = false;
  bool _showConsultationSuccess = false;

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
      _showConsultationSuccess = false;
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
      _showConsultationSuccess = false;
    });
  }

  Future<Uint8List> _getOrGenerate21SectionPdfBytes(AppointmentModel appt, AppState state) async {
    // 1. Try fetching PDF from Firebase Storage
    if (appt.reportStoragePath.isNotEmpty) {
      try {
        final ref = FirebaseStorage.instance.ref(appt.reportStoragePath);
        final bytes = await ref.getData(15 * 1024 * 1024);
        if (bytes != null && bytes.isNotEmpty) return bytes;
      } catch (_) {}
    }

    // 2. Try HTTP download URL
    if (appt.reportUrl.isNotEmpty && appt.reportUrl.startsWith('http')) {
      try {
        final bytes = await fetchPdfBytesFromUrl(appt.reportUrl);
        if (bytes != null && bytes.isNotEmpty) return bytes;
      } catch (_) {}
    }

    // 3. Fallback: Generate full 21-section PDF dynamically
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
      primarySymptoms: appt.symptomsSummary.isNotEmpty
          ? appt.symptomsSummary.split(', ').toList()
          : ['General Clinical Assessment'],
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
    final state = AppStateProvider.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            SizedBox(width: 12),
            Text('Opening Medical Report in new tab...'),
          ],
        ),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      if (appt.reportUrl.isNotEmpty && appt.reportUrl.startsWith('http')) {
        await openPdfUrlInNewTab(appt.reportUrl);
        return;
      }

      final pdfBytes = await _getOrGenerate21SectionPdfBytes(appt, state);
      await openPdfUrlInNewTab('', bytes: pdfBytes);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open the medical report. Please try again.'),
            backgroundColor: AppColors.riskCritical,
          ),
        );
      }
    }
  }

  Future<void> _handleDownloadReport(AppointmentModel appt) async {
    final state = AppStateProvider.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            SizedBox(width: 12),
            Text('Preparing Medical Report PDF for download...'),
          ],
        ),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      final fileName = appt.reportFileName.isNotEmpty 
          ? appt.reportFileName 
          : 'HealthGuard_AI_Medical_Report_${appt.id}.pdf';

      final pdfBytes = await _getOrGenerate21SectionPdfBytes(appt, state);
      await downloadPdfFileFromUrl(appt.reportUrl, fileName, bytes: pdfBytes);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to download the medical report. Please try again.'),
            backgroundColor: AppColors.riskCritical,
          ),
        );
      }
    }
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
          _showConsultationSuccess = true;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(complete ? 'Consultation completed successfully!' : 'Consultation saved as draft.'),
            backgroundColor: AppColors.riskLow,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save consultation: ${e.toString()}'),
            backgroundColor: AppColors.riskCritical,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingConsultation = false);
    }
  }

  void _confirmCompleteConsultation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Complete Consultation?'),
        content: const Text('Once completed, this appointment will be marked as completed and consultation recommendations will be available to the patient.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _saveConsultation(complete: true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryTeal),
            child: const Text('Complete Consultation', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateProvider.of(context);
    final currentDoctor = state.currentDoctor ?? doctorDatabase.first;
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return Scaffold(
      key: _scaffoldKey,
      drawer: isDesktop ? null : _buildMobileDrawer(currentDoctor, state),
      body: StreamBuilder<List<AppointmentModel>>(
        stream: state.dbService is FirebaseDbService 
            ? (state.dbService as FirebaseDbService).streamDoctorAppointments(currentDoctor.id)
            : Stream.fromFuture(state.dbService.getDoctorAppointments(currentDoctor.id)),
        builder: (context, snapshot) {
          final allDoctorAppts = snapshot.data ?? [];
          
          // Doctor-Wise Data Filtering (strictly enforced for security & display)
          final assignedAppts = allDoctorAppts.where((a) => 
            a.doctorId == currentDoctor.id || 
            a.doctorId.toLowerCase() == currentDoctor.id.toLowerCase() ||
            (a.doctorId.isEmpty && a.doctorSpecialty.toLowerCase() == currentDoctor.specialty.toLowerCase())
          ).toList();

          return Row(
            children: [
              // Desktop Professional Sidebar
              if (isDesktop) _buildSidebar(currentDoctor, state),

              // Main Clinical Content Area
              Expanded(
                child: Column(
                  children: [
                    _buildTopHeader(currentDoctor, state, isDesktop),
                    Expanded(
                      child: Stack(
                        children: [
                          _buildMainBodyContent(currentDoctor, assignedAppts, state),
                          if (_selectedAppointment != null)
                            _buildConsultationWorkspaceModal(currentDoctor, state),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ==================== SIDEBAR ====================
  Widget _buildSidebar(DoctorModel doctor, AppState state) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: state.isDarkMode ? const Color(0xFF0F1C3F) : const Color(0xFFFFFFFF),
        border: Border(
          right: BorderSide(
            color: state.isDarkMode ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08),
          ),
        ),
      ),
      child: Column(
        children: [
          // Branding Header
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.local_hospital_rounded, color: AppColors.primaryTeal, size: 24),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HEALTHGUARD AI',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: state.isDarkMode ? Colors.white : AppColors.lightTextPrimary,
                      ),
                    ),
                    const Text(
                      'Doctor Portal',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryTeal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Navigation Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildNavItem(0, Icons.dashboard_outlined, Icons.dashboard_rounded, 'Dashboard', state),
                _buildNavItem(1, Icons.calendar_month_outlined, Icons.calendar_month_rounded, 'Appointments', state),
                _buildNavItem(2, Icons.access_time_outlined, Icons.access_time_filled_rounded, "Today's Schedule", state),
                _buildNavItem(3, Icons.people_outline_rounded, Icons.people_rounded, 'My Patients', state),
                _buildNavItem(4, Icons.description_outlined, Icons.description_rounded, 'Medical Reports', state),
                _buildNavItem(5, Icons.medical_services_outlined, Icons.medical_services_rounded, 'Consultations', state),
                _buildNavItem(6, Icons.notifications_outlined, Icons.notifications_rounded, 'Notifications', state),
                _buildNavItem(7, Icons.person_outline_rounded, Icons.person_rounded, 'Profile', state),
              ],
            ),
          ),

          // Bottom Logout
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: ListTile(
              leading: const Icon(Icons.logout_rounded, color: AppColors.riskCritical, size: 20),
              title: const Text('Logout', style: TextStyle(color: AppColors.riskCritical, fontSize: 14, fontWeight: FontWeight.w600)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              onTap: () {
                state.logoutDoctor();
                Navigator.of(context).pushReplacementNamed('/doctor-login');
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData iconData, IconData activeIconData, String label, AppState state) {
    final isSelected = _selectedNavIndex == index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        selected: isSelected,
        selectedTileColor: AppColors.primaryTeal.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        leading: Icon(
          isSelected ? activeIconData : iconData,
          color: isSelected ? AppColors.primaryTeal : (state.isDarkMode ? Colors.white60 : Colors.black54),
          size: 20,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? AppColors.primaryTeal : (state.isDarkMode ? Colors.white70 : AppColors.lightTextPrimary),
          ),
        ),
        onTap: () {
          setState(() {
            _selectedNavIndex = index;
            _selectedAppointment = null;
          });
          if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
            Navigator.of(context).pop();
          }
        },
      ),
    );
  }

  Widget _buildMobileDrawer(DoctorModel doctor, AppState state) {
    return Drawer(
      backgroundColor: state.isDarkMode ? const Color(0xFF0F1C3F) : Colors.white,
      child: _buildSidebar(doctor, state),
    );
  }

  // ==================== TOP HEADER ====================
  Widget _buildTopHeader(DoctorModel doctor, AppState state, bool isDesktop) {
    final titles = [
      'Doctor Dashboard',
      'Appointments Management',
      "Today's Clinical Schedule",
      'My Patients',
      'Patient Medical Reports',
      'Completed Consultations',
      'Notifications Center',
      'Doctor Profile'
    ];

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: state.isDarkMode ? const Color(0xFF0F1C3F) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: state.isDarkMode ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08),
          ),
        ),
      ),
      child: Row(
        children: [
          if (!isDesktop)
            IconButton(
              icon: const Icon(Icons.menu_rounded),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
          Text(
            titles[_selectedNavIndex],
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: state.isDarkMode ? Colors.white : AppColors.lightTextPrimary,
            ),
          ),
          const Spacer(),

          // Search Bar
          if (isDesktop && (_selectedNavIndex == 1 || _selectedNavIndex == 3))
            SizedBox(
              width: 250,
              height: 40,
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search patient name or ID...',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          const SizedBox(width: 16),

          // Notifications Icon
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => setState(() => _selectedNavIndex = 6),
          ),
          const SizedBox(width: 12),

          // Doctor Avatar & Profile Info
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primaryTeal,
                child: Text(
                  doctor.name.replaceFirst('Dr. ', '').characters.first,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doctor.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: state.isDarkMode ? Colors.white : AppColors.lightTextPrimary,
                    ),
                  ),
                  Text(
                    doctor.specialty,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.primaryTeal,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== MAIN BODY CONTENT ====================
  Widget _buildMainBodyContent(DoctorModel doctor, List<AppointmentModel> appts, AppState state) {
    switch (_selectedNavIndex) {
      case 0:
        return _buildDashboardOverviewTab(doctor, appts, state);
      case 1:
        return _buildAppointmentsTab(appts, state);
      case 2:
        return _buildTodaysScheduleTab(appts, state);
      case 3:
        return _buildMyPatientsTab(appts, state);
      case 4:
        return _buildMedicalReportsTab(appts, state);
      case 5:
        return _buildConsultationsTab(appts, state);
      case 6:
        return _buildNotificationsTab(appts, state);
      case 7:
        return _buildProfileTab(doctor, state);
      default:
        return _buildDashboardOverviewTab(doctor, appts, state);
    }
  }

  // 1. DASHBOARD OVERVIEW TAB
  Widget _buildDashboardOverviewTab(DoctorModel doctor, List<AppointmentModel> appts, AppState state) {
    final today = DateTime.now();
    final todayAppts = appts.where((a) => 
      a.preferredDateTime.year == today.year && 
      a.preferredDateTime.month == today.month && 
      a.preferredDateTime.day == today.day
    ).toList();

    final upcomingAppts = appts.where((a) => 
      a.preferredDateTime.isAfter(today) && a.status != 'Completed' && a.status != 'Rejected'
    ).toList();

    final pendingConsultations = appts.where((a) => a.status == 'Approved' || a.status == 'Rescheduled').toList();
    final completedConsultations = appts.where((a) => a.status == 'Completed').toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Banner
          GlassCard(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Good Morning, ${doctor.name}',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: state.isDarkMode ? Colors.white : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Here is your clinical schedule and patient overview for today (${today.day} ${_getMonthName(today.month)} ${today.year}).',
                        style: TextStyle(
                          fontSize: 13.5,
                          color: state.isDarkMode ? Colors.white70 : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primaryTeal.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_user_rounded, color: AppColors.primaryTeal, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '${doctor.specialty} (${doctor.id.toUpperCase()})',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryTeal, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 4 Doctor Statistics Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth >= 1100 ? 4 : (constraints.maxWidth >= 650 ? 2 : 1);
              return GridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 2.2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStatCard("Today's Appointments", '${todayAppts.length}', 'scheduled today', Icons.calendar_today_rounded, AppColors.primaryTeal, state),
                  _buildStatCard('Upcoming Appointments', '${upcomingAppts.length}', 'future visits', Icons.event_available_rounded, Colors.blue, state),
                  _buildStatCard('Pending Consultations', '${pendingConsultations.length}', 'awaiting review', Icons.pending_actions_rounded, Colors.orange, state),
                  _buildStatCard('Completed Consultations', '${completedConsultations.length}', 'successfully completed', Icons.check_circle_outline_rounded, Colors.green, state),
                ],
              );
            },
          ),
          const SizedBox(height: 28),

          // Today's Clinical Schedule Table
          Text(
            "TODAY'S CLINICAL SCHEDULE",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: state.isDarkMode ? Colors.white : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 12),
          todayAppts.isEmpty
              ? _buildEmptyState('No appointments scheduled for today.', Icons.event_available_outlined, state)
              : _buildClinicalScheduleTable(todayAppts, state),

          const SizedBox(height: 28),

          // Upcoming Appointments List
          Text(
            'UPCOMING CLINICAL APPOINTMENTS',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: state.isDarkMode ? Colors.white : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 12),
          upcomingAppts.isEmpty
              ? _buildEmptyState('No upcoming appointments found.', Icons.calendar_month_outlined, state)
              : _buildClinicalScheduleTable(upcomingAppts.take(5).toList(), state),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String count, String subtext, IconData icon, Color color, AppState state) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                count,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: state.isDarkMode ? Colors.white : AppColors.lightTextPrimary,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: state.isDarkMode ? Colors.white70 : AppColors.lightTextSecondary,
                ),
              ),
              Text(
                subtext,
                style: TextStyle(
                  fontSize: 10,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // CLINICAL SCHEDULE TABLE (DESKTOP & MOBILE RESPONSIVE)
  Widget _buildClinicalScheduleTable(List<AppointmentModel> appts, AppState state) {
    return GlassCard(
      padding: const EdgeInsets.all(0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
            state.isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
          ),
          columns: const [
            DataColumn(label: Text('TIME', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            DataColumn(label: Text('PATIENT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            DataColumn(label: Text('APPOINTMENT ID', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            DataColumn(label: Text('RISK LEVEL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            DataColumn(label: Text('STATUS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            DataColumn(label: Text('ACTION', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          ],
          rows: appts.map((appt) {
            final timeStr = '${appt.preferredDateTime.hour.toString().padLeft(2, '0')}:${appt.preferredDateTime.minute.toString().padLeft(2, '0')}';
            return DataRow(
              cells: [
                DataCell(Text(timeStr, style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(appt.patientName, style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(appt.mobileNumber, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
                DataCell(Text(appt.id, style: const TextStyle(fontFamily: 'monospace', fontSize: 11))),
                DataCell(_buildRiskBadge(appt.riskLevel)),
                DataCell(_buildStatusBadge(appt.status)),
                DataCell(
                  ElevatedButton.icon(
                    onPressed: () => _openConsultationWorkspace(appt),
                    icon: const Icon(Icons.medical_services_outlined, size: 14),
                    label: const Text('Consult', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryTeal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  // 2. APPOINTMENTS TAB
  Widget _buildAppointmentsTab(List<AppointmentModel> appts, AppState state) {
    var filtered = appts.where((a) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesName = a.patientName.toLowerCase().contains(q);
        final matchesId = a.id.toLowerCase().contains(q);
        if (!matchesName && !matchesId) return false;
      }
      if (_selectedTabFilter == 'Approved') return a.status == 'Approved';
      if (_selectedTabFilter == 'Rescheduled') return a.status == 'Rescheduled';
      if (_selectedTabFilter == 'Completed') return a.status == 'Completed';
      if (_selectedTabFilter == 'Today') {
        final now = DateTime.now();
        return a.preferredDateTime.year == now.year && a.preferredDateTime.month == now.month && a.preferredDateTime.day == now.day;
      }
      return true;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Chips
          Wrap(
            spacing: 8,
            children: ['All', 'Today', 'Approved', 'Rescheduled', 'Completed'].map((filter) {
              final isSelected = _selectedTabFilter == filter;
              return ChoiceChip(
                label: Text(filter),
                selected: isSelected,
                selectedColor: AppColors.primaryTeal,
                labelStyle: TextStyle(color: isSelected ? Colors.white : (state.isDarkMode ? Colors.white70 : Colors.black87)),
                onSelected: (val) => setState(() => _selectedTabFilter = filter),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          filtered.isEmpty
              ? _buildEmptyState('No appointments found under "$_selectedTabFilter" filter.', Icons.folder_open_outlined, state)
              : _buildClinicalScheduleTable(filtered, state),
        ],
      ),
    );
  }

  // 3. TODAY'S SCHEDULE TAB
  Widget _buildTodaysScheduleTab(List<AppointmentModel> appts, AppState state) {
    final now = DateTime.now();
    final todayAppts = appts.where((a) => 
      a.preferredDateTime.year == now.year && a.preferredDateTime.month == now.month && a.preferredDateTime.day == now.day
    ).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("TODAY'S CLINICAL VISITS (${now.day} ${_getMonthName(now.month)} ${now.year})", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          todayAppts.isEmpty
              ? _buildEmptyState('No clinical appointments scheduled for today.', Icons.event_busy_outlined, state)
              : _buildClinicalScheduleTable(todayAppts, state),
        ],
      ),
    );
  }

  // 4. MY PATIENTS TAB
  Widget _buildMyPatientsTab(List<AppointmentModel> appts, AppState state) {
    // Unique assigned patients for current doctor
    final patientMap = <String, List<AppointmentModel>>{};
    for (var a in appts) {
      patientMap.putIfAbsent(a.patientName, () => []).add(a);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ASSIGNED PATIENTS DIRECTORY (${patientMap.length} Patients)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          patientMap.isEmpty
              ? _buildEmptyState('No patients currently assigned to your care.', Icons.person_off_outlined, state)
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: patientMap.length,
                  itemBuilder: (context, index) {
                    final pName = patientMap.keys.elementAt(index);
                    final pAppts = patientMap[pName]!;
                    final latest = pAppts.first;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primaryTeal.withValues(alpha: 0.2),
                          child: const Icon(Icons.person, color: AppColors.primaryTeal),
                        ),
                        title: Text(pName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Last Visit: ${latest.preferredDateTime.day} ${_getMonthName(latest.preferredDateTime.month)} ${latest.preferredDateTime.year} • ${pAppts.length} Appointments Recorded'),
                        trailing: ElevatedButton(
                          onPressed: () => _openConsultationWorkspace(latest),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryTeal),
                          child: const Text('View Clinical File', style: TextStyle(color: Colors.white, fontSize: 12)),
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  // 5. MEDICAL REPORTS TAB
  Widget _buildMedicalReportsTab(List<AppointmentModel> appts, AppState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('PATIENT HEALTH ASSESSMENT REPORTS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          appts.isEmpty
              ? _buildEmptyState('No medical reports attached to your appointments.', Icons.description_outlined, state)
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: appts.length,
                  itemBuilder: (context, index) {
                    final appt = appts[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent, size: 32),
                        title: Text('Health Assessment Report - ${appt.patientName}'),
                        subtitle: Text('Report ID: ${appt.reportId.isNotEmpty ? appt.reportId : appt.id} • Risk Score: ${appt.riskScore.toStringAsFixed(0)}/100'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.visibility_outlined, color: AppColors.primaryTeal),
                              onPressed: () => _handleViewReport(appt),
                              tooltip: 'View Original PDF',
                            ),
                            IconButton(
                              icon: const Icon(Icons.download_outlined, color: AppColors.primaryTeal),
                              onPressed: () => _handleDownloadReport(appt),
                              tooltip: 'Download Original PDF',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  // 6. CONSULTATIONS TAB
  Widget _buildConsultationsTab(List<AppointmentModel> appts, AppState state) {
    final completed = appts.where((a) => a.status == 'Completed').toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('COMPLETED CLINICAL CONSULTATIONS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          completed.isEmpty
              ? _buildEmptyState('No completed consultations recorded yet.', Icons.check_circle_outline, state)
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: completed.length,
                  itemBuilder: (context, index) {
                    final appt = completed[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const Icon(Icons.task_alt_rounded, color: Colors.green, size: 30),
                        title: Text(appt.patientName),
                        subtitle: Text('Completed on: ${appt.completedAt != null ? "${appt.completedAt!.day} ${_getMonthName(appt.completedAt!.month)}" : "Recently"}'),
                        trailing: ElevatedButton(
                          onPressed: () => _openConsultationWorkspace(appt),
                          child: const Text('View Record', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  // 7. NOTIFICATIONS TAB
  Widget _buildNotificationsTab(List<AppointmentModel> appts, AppState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('CLINICAL ALERTS & NOTIFICATIONS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: appts.take(5).length,
            itemBuilder: (context, index) {
              final a = appts[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: const Icon(Icons.notification_important_rounded, color: AppColors.primaryTeal),
                  title: Text('Approved Appointment: ${a.patientName}'),
                  subtitle: Text('Scheduled for ${a.preferredDateTime.day} ${_getMonthName(a.preferredDateTime.month)} ${a.preferredDateTime.year} at ${a.preferredDateTime.hour}:${a.preferredDateTime.minute.toString().padLeft(2, "0")}'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // 8. DOCTOR PROFILE TAB
  Widget _buildProfileTab(DoctorModel doctor, AppState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: GlassCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.primaryTeal,
                  child: Text(doctor.name.replaceFirst('Dr. ', '').characters.first, style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(doctor.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Text(doctor.specialty, style: const TextStyle(fontSize: 14, color: AppColors.primaryTeal, fontWeight: FontWeight.bold)),
                    Text('Doctor ID: ${doctor.id.toUpperCase()} • Status: ${doctor.status}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ],
            ),
            const Divider(height: 32),
            _buildProfileRow('Email Account:', doctor.email),
            _buildProfileRow('Contact Phone:', doctor.phone),
            _buildProfileRow('Medical Qualifications:', doctor.qualification),
            _buildProfileRow('Clinical Experience:', doctor.experienceYears),
            _buildProfileRow('Available Clinical Days:', doctor.availableDays),
            _buildProfileRow('Available Clinical Hours:', doctor.availableHours),
            _buildProfileRow('Medical Facility:', doctor.clinicLocation),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(width: 180, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  // ==================== DOCTOR CONSULTATION WORKSPACE MODAL ====================
  Widget _buildConsultationWorkspaceModal(DoctorModel doctor, AppState state) {
    final appt = _selectedAppointment!;

    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.6),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 900, maxHeight: 850),
            decoration: BoxDecoration(
              color: state.isDarkMode ? const Color(0xFF0F1C3F) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primaryTeal.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                // Modal Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal.withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.medical_information_rounded, color: AppColors.primaryTeal),
                      const SizedBox(width: 10),
                      Text(
                        'DOCTOR CONSULTATION WORKSPACE - ${appt.patientName}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: _closeConsultationWorkspace,
                      ),
                    ],
                  ),
                ),

                // Modal Content Body
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Success Panel if completed
                        if (_showConsultationSuccess)
                          Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Consultation Completed Successfully!', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                                      Text('Appointment ${appt.id} is now marked as Completed. Recommendations have been pushed to patient portal.', style: const TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // 1. Patient Overview Header
                        const Text('1. PATIENT OVERVIEW', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryTeal)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: state.isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Wrap(
                            spacing: 24,
                            runSpacing: 8,
                            children: [
                              _buildInfoPair('Patient Name', appt.patientName),
                              _buildInfoPair('Appointment ID', appt.id),
                              _buildInfoPair('Mobile', appt.mobileNumber),
                              _buildInfoPair('Assigned Doctor', 'Dr. ${doctor.name} (${doctor.specialty})'),
                              _buildInfoPair('Risk Level', appt.riskLevel),
                              _buildInfoPair('Status', appt.status),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // 2. Clinical Summary
                        const Text('2. CLINICAL SUMMARY & SYMPTOMS', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryTeal)),
                        const SizedBox(height: 8),
                        Text('Reported Complaints: ${appt.symptomsSummary.isEmpty ? "General clinical assessment requested" : appt.symptomsSummary}'),
                        const SizedBox(height: 20),

                        // 3. AI Health Assessment Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.psychology_rounded, color: Colors.blue),
                                  const SizedBox(width: 8),
                                  Text('HEALTHGUARD AI ASSISTED ASSESSMENT (Score: ${appt.riskScore.toStringAsFixed(0)}/100)', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text('Calculated Category: ${appt.riskLevel}'),
                              const SizedBox(height: 4),
                              const Text('Notice: This AI-assisted assessment is intended to support clinical review and does not replace professional medical judgment.', style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // 4. Original Medical Report Buttons
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => _handleViewReport(appt),
                              icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                              label: const Text('VIEW ORIGINAL MEDICAL REPORT'),
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryTeal, foregroundColor: Colors.white),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton.icon(
                              onPressed: () => _handleDownloadReport(appt),
                              icon: const Icon(Icons.download_outlined, size: 16),
                              label: const Text('DOWNLOAD ORIGINAL PDF'),
                            ),
                          ],
                        ),
                        const Divider(height: 32),

                        // 5. Editable Clinical Fields
                        const Text('5. PHYSICIAN CLINICAL EVALUATION', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryTeal)),
                        const SizedBox(height: 12),

                        // Clinical Assessment
                        const Text('Clinical Assessment:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _clinicalAssessmentController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            hintText: 'Enter your clinical diagnostic assessment & observations...',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Clinical Notes
                        const Text('Clinical Notes:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _clinicalNotesController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            hintText: 'Document physical findings, examination notes, and vital checks...',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Recommendations
                        const Text('Recommendations:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _recommendationsController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            hintText: 'Enter patient recommendations, diagnostic test orders, or lifestyle advice...',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Treatment / Medication Instructions
                        const Text('Treatment & Medication Instructions:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _treatmentInstructionsController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            hintText: 'Enter prescribed medications, dosage schedules, or clinical instructions...',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Follow-up Plan
                        Row(
                          children: [
                            Checkbox(
                              value: _followUpRequired,
                              onChanged: (val) => setState(() => _followUpRequired = val ?? false),
                            ),
                            const Text('Follow-Up Required', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        if (_followUpRequired) ...[
                          const SizedBox(height: 8),
                          TextField(
                            controller: _followUpNotesController,
                            decoration: InputDecoration(
                              labelText: 'Follow-Up Notes / Timelines',
                              hintText: 'e.g. Return in 2 weeks for blood pressure re-evaluation',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Modal Footer Action Buttons
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: state.isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: _isSavingConsultation ? null : () => _saveConsultation(complete: false),
                        child: const Text('SAVE CONSULTATION DRAFT'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _isSavingConsultation ? null : _confirmCompleteConsultation,
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryTeal, foregroundColor: Colors.white),
                        child: _isSavingConsultation
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('COMPLETE CONSULTATION', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoPair(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildRiskBadge(String riskLevel) {
    Color bg = Colors.grey;
    if (riskLevel.contains('Critical')) bg = AppColors.riskCritical;
    else if (riskLevel.contains('High')) bg = AppColors.riskHigh;
    else if (riskLevel.contains('Moderate')) bg = AppColors.riskModerate;
    else if (riskLevel.contains('Low')) bg = AppColors.riskLow;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
      child: Text(riskLevel, style: TextStyle(color: bg, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.blue;
    if (status == 'Approved') color = Colors.green;
    if (status == 'Rescheduled') color = Colors.orange;
    if (status == 'Completed') color = AppColors.primaryTeal;
    if (status == 'Rejected') color = AppColors.riskCritical;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
      child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }

  Widget _buildEmptyState(String msg, IconData icon, AppState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: state.isDarkMode ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: Colors.grey),
          const SizedBox(height: 8),
          Text(msg, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[(month - 1).clamp(0, 11)];
  }
}
