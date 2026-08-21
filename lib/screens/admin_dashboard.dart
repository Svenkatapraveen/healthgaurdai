import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_storage/firebase_storage.dart';
import '../theme/colors.dart';
import '../widgets/app_card.dart';
import '../widgets/stat_card.dart';
import '../widgets/app_button.dart';
import '../widgets/app_badge.dart';
import '../widgets/app_modal.dart';
import '../widgets/app_layout.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/empty_state.dart';
import '../state/app_state.dart';
import '../services/db_service.dart';
import '../services/auth_service.dart';
import '../data/doctor_database.dart';
import '../utils/web_download_helper.dart';
import '../utils/pdf_generator_helper.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedTab = 0; // 0: Dashboard, 1: Appointments, 2: Patients, 3: Doctors, 4: Reports

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final routeName = ModalRoute.of(context)?.settings.name;
    if (routeName != null) {
      if (routeName.contains('tab=appointments')) {
        _selectedTab = 1;
      } else if (routeName.contains('tab=patients')) {
        _selectedTab = 2;
      } else if (routeName.contains('tab=doctors')) {
        _selectedTab = 3;
      } else if (routeName.contains('tab=reports')) {
        _selectedTab = 4;
      }
    }
  }

  void _showViewDetailsDialog(AppointmentModel appt) {
    showDialog(
      context: context,
      builder: (context) => AppModal(
        title: 'Appointment Details (${appt.id})',
        icon: Icons.info_outline,
        iconColor: AppColors.primaryBlue,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Patient Name', appt.patientName),
            _buildDetailRow('Patient Email', appt.patientEmail),
            _buildDetailRow('Mobile Number', appt.mobileNumber.isNotEmpty ? appt.mobileNumber : 'N/A'),
            _buildDetailRow('Doctor Name', appt.doctorName.isNotEmpty ? 'Dr. ${appt.doctorName}' : 'Assigned Physician'),
            _buildDetailRow('Specialty / Dept', appt.doctorSpecialty),
            _buildDetailRow('Date & Time', '${appt.preferredDateTime.day}/${appt.preferredDateTime.month}/${appt.preferredDateTime.year} @ ${appt.timeSlot}'),
            _buildDetailRow('Risk Level', appt.riskLevel),
            _buildDetailRow('Status', appt.status),
            if (appt.symptomsSummary.isNotEmpty) _buildDetailRow('Symptoms Summary', appt.symptomsSummary),
            if (appt.rejectionReason != null && appt.rejectionReason!.isNotEmpty)
              _buildDetailRow('Rejection Reason', appt.rejectionReason!),
          ],
        ),
        actions: [
          AppButton(
            label: 'Close',
            variant: AppButtonVariant.secondary,
            size: AppButtonSize.small,
            onPressed: () => Navigator.pop(context),
          ),
          if (appt.reportId.isNotEmpty) ...[
            const SizedBox(width: 8),
            AppButton(
              label: 'View Medical Report',
              icon: Icons.picture_as_pdf,
              size: AppButtonSize.small,
              onPressed: () {
                Navigator.pop(context);
                _handleViewReport(appt);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(AppointmentModel appt, AppState state) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AppModal(
        title: 'Reject Appointment Request',
        icon: Icons.cancel_outlined,
        iconColor: AppColors.danger,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to reject the appointment request for ${appt.patientName}?', style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 14),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: 'Reason for rejection (Optional)',
                hintText: 'e.g. Doctor unavailable on requested date',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          AppButton(
            label: 'Cancel',
            variant: AppButtonVariant.secondary,
            size: AppButtonSize.small,
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          AppButton(
            label: 'Confirm Rejection',
            variant: AppButtonVariant.danger,
            size: AppButtonSize.small,
            onPressed: () async {
              Navigator.pop(context);
              final reason = reasonController.text.trim();
              await state.updateAppointmentStatusAdmin(
                appt.id,
                'Rejected',
                rejectionReason: reason.isNotEmpty ? reason : null,
                targetUserId: appt.userId,
                doctorName: appt.doctorName.isNotEmpty ? appt.doctorName : appt.doctorSpecialty,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Appointment request rejected.'), backgroundColor: AppColors.danger),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _showRescheduleDialog(AppointmentModel appt, AppState state) async {
    DateTime selectedDate = appt.preferredDateTime;
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(appt.preferredDateTime);

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate.isAfter(DateTime.now()) ? selectedDate : DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );

    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );

    if (pickedTime == null || !mounted) return;

    final newDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    await state.rescheduleAppointmentAdmin(
      appt.id,
      newDateTime,
      targetUserId: appt.userId,
      doctorName: appt.doctorName.isNotEmpty ? appt.doctorName : appt.doctorSpecialty,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment rescheduled successfully.'), backgroundColor: AppColors.success),
      );
    }
  }

  Future<Uint8List> _getOrGenerate21SectionPdfBytes(AppointmentModel appt, AppState state) async {
    if (appt.reportStoragePath.isNotEmpty) {
      try {
        final data = await FirebaseStorage.instance.ref(appt.reportStoragePath).getData(10 * 1024 * 1024);
        if (data != null && data.isNotEmpty) return data;
      } catch (e) {
        print('Storage getData warning: $e');
      }
    }

    final targetUrl = appt.reportUrl.trim();
    if (targetUrl.startsWith('http') && !targetUrl.contains('/#/report')) {
      try {
        final res = await http.get(Uri.parse(targetUrl)).timeout(const Duration(seconds: 4));
        if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
          return res.bodyBytes;
        }
      } catch (e) {
        print('HTTP download warning: $e');
      }
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
      primarySymptoms: appt.symptomsSummary.isNotEmpty ? appt.symptomsSummary.split(', ').toList() : ['General Symptom Assessment'],
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

    AppUser? patientUser;
    if (state.currentUser != null && state.currentUser!.uid == appt.userId) {
      patientUser = state.currentUser;
    }

    return await generate21SectionMedicalReportPdfBytes(
      assessment: assessment,
      user: patientUser,
    );
  }

  Future<void> _handleViewReport(AppointmentModel appt) async {
    final reportId = appt.reportId.isNotEmpty ? appt.reportId : appt.id;
    Navigator.pushNamed(context, '/report?id=$reportId');
  }

  Future<void> _handleDownloadReport(AppointmentModel appt) async {
    final state = AppStateProvider.of(context);
    final bytes = await _getOrGenerate21SectionPdfBytes(appt, state);
    final filename = appt.reportFileName.isNotEmpty ? appt.reportFileName : 'Medical_Report_${appt.id}.pdf';
    await downloadPdfFileFromUrl('', filename, bytes: bytes);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final state = AppStateProvider.of(context);

    if (state.currentUser?.isAdmin != true && state.currentUser?.role != 'admin') {
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
                  const Icon(Icons.gpp_maybe_outlined, color: AppColors.danger, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Access Denied',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.getTextPrimary(isDark)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You do not have permission to access this page.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.getTextSecondary(isDark), fontSize: 13),
                  ),
                  const SizedBox(height: 24),
                  AppButton(
                    label: 'Return to Dashboard',
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final allAppts = state.appointments;

    int totalPatients = state.totalPatientCount > 0 ? state.totalPatientCount : (allAppts.map((a) => a.userId).toSet().length);
    int totalDoctors = doctorDatabase.length;
    int pendingCount = allAppts.where((a) => a.status.toLowerCase() == 'pending').length;
    int approvedCount = allAppts.where((a) => a.status.toLowerCase() == 'approved').length;
    int rejectedCount = allAppts.where((a) => a.status.toLowerCase() == 'rejected').length;
    int rescheduledCount = allAppts.where((a) => a.status.toLowerCase() == 'rescheduled').length;

    final bool isDesktop = MediaQuery.of(context).size.width >= 900;

    String currentRouteStr = '/admin-dashboard';
    if (_selectedTab == 1) currentRouteStr = '/admin-dashboard?tab=appointments';
    if (_selectedTab == 2) currentRouteStr = '/admin-dashboard?tab=patients';
    if (_selectedTab == 3) currentRouteStr = '/admin-dashboard?tab=doctors';
    if (_selectedTab == 4) currentRouteStr = '/admin-dashboard?tab=reports';

    return AppLayout(
      title: 'Operations Center',
      subtitle: 'System-wide appointment approvals, doctors, patients, & medical reports',
      role: UserRole.admin,
      currentRoute: currentRouteStr,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stat Cards Grid
          LayoutBuilder(
            builder: (ctx, constraints) {
              int count = isDesktop ? 6 : (constraints.maxWidth > 600 ? 3 : 2);
              return GridView.count(
                crossAxisCount: count,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: isDesktop ? 2.0 : 2.2,
                children: [
                  StatCard(title: 'Total Patients', value: '$totalPatients', icon: Icons.people_outline, iconBgColor: AppColors.primaryBlue.withValues(alpha: 0.12), iconColor: AppColors.primaryBlue, onTap: () => setState(() => _selectedTab = 2)),
                  StatCard(title: 'Pending Appts', value: '$pendingCount', icon: Icons.pending_actions_outlined, iconBgColor: AppColors.warning.withValues(alpha: 0.15), iconColor: AppColors.warning, onTap: () => setState(() => _selectedTab = 1)),
                  StatCard(title: 'Approved Appts', value: '$approvedCount', icon: Icons.check_circle_outline, iconBgColor: AppColors.success.withValues(alpha: 0.15), iconColor: AppColors.success, onTap: () => setState(() => _selectedTab = 1)),
                  StatCard(title: 'Rejected Appts', value: '$rejectedCount', icon: Icons.cancel_outlined, iconBgColor: AppColors.danger.withValues(alpha: 0.15), iconColor: AppColors.danger, onTap: () => setState(() => _selectedTab = 1)),
                  StatCard(title: 'Rescheduled', value: '$rescheduledCount', icon: Icons.edit_calendar_outlined, iconBgColor: AppColors.info.withValues(alpha: 0.15), iconColor: AppColors.info, onTap: () => setState(() => _selectedTab = 1)),
                  StatCard(title: 'Total Doctors', value: '$totalDoctors', icon: Icons.medical_services_outlined, iconBgColor: AppColors.primaryTeal.withValues(alpha: 0.15), iconColor: AppColors.primaryTeal, onTap: () => setState(() => _selectedTab = 3)),
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // Admin Section Switcher Bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildAdminTabChip(0, 'Overview', Icons.dashboard_outlined),
                const SizedBox(width: 8),
                _buildAdminTabChip(1, 'Appointments (${allAppts.length})', Icons.calendar_month_outlined),
                const SizedBox(width: 8),
                _buildAdminTabChip(2, 'Patients Directory', Icons.people_outline),
                const SizedBox(width: 8),
                _buildAdminTabChip(3, 'Doctor Directory', Icons.medical_services_outlined),
                const SizedBox(width: 8),
                _buildAdminTabChip(4, 'Medical Reports', Icons.description_outlined),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Tab Content Rendering
          if (_selectedTab == 0 || _selectedTab == 1)
            _buildAppointmentsTableSection(isDark, state, allAppts)
          else if (_selectedTab == 2)
            _buildPatientsSection(isDark, state, allAppts)
          else if (_selectedTab == 3)
            _buildDoctorsSection(isDark)
          else
            _buildReportsSection(isDark, state, allAppts),
        ],
      ),
    );
  }

  Widget _buildAdminTabChip(int tabIndex, String label, IconData icon) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isSelected = _selectedTab == tabIndex;

    return ChoiceChip(
      avatar: Icon(icon, size: 16, color: isSelected ? Colors.white : AppColors.getTextSecondary(isDark)),
      label: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : AppColors.getTextPrimary(isDark))),
      selected: isSelected,
      selectedColor: AppColors.primaryBlue,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      onSelected: (val) {
        if (val) setState(() => _selectedTab = tabIndex);
      },
    );
  }

  String _apptFilterTab = 'All';

  Widget _buildAppointmentsTableSection(bool isDark, AppState state, List<AppointmentModel> allAppts) {
    final subTabs = ['All', 'Pending', 'Approved', 'Rejected', 'Rescheduled', 'Completed'];
    List<AppointmentModel> displayAppts = allAppts;
    if (_apptFilterTab != 'All') {
      displayAppts = allAppts.where((a) => a.status.toLowerCase() == _apptFilterTab.toLowerCase()).toList();
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Appointment Management', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.getTextPrimary(isDark))),
              Text('${displayAppts.length} records shown', style: TextStyle(fontSize: 12, color: AppColors.getTextSecondary(isDark))),
            ],
          ),
          const SizedBox(height: 12),

          // Status Filter Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: subTabs.map((st) {
                final isSel = _apptFilterTab == st;
                final count = st == 'All' ? allAppts.length : allAppts.where((a) => a.status.toLowerCase() == st.toLowerCase()).length;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text('$st ($count)', style: TextStyle(fontSize: 12, fontWeight: isSel ? FontWeight.w700 : FontWeight.w500, color: isSel ? Colors.white : AppColors.getTextPrimary(isDark))),
                    selected: isSel,
                    selectedColor: AppColors.primaryBlue,
                    backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightBg,
                    onSelected: (val) {
                      if (val) setState(() => _apptFilterTab = st);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          if (displayAppts.isEmpty)
            EmptyState(
              icon: Icons.calendar_month_outlined,
              title: 'No Appointments Recorded',
              description: 'No patient appointments found for status "$_apptFilterTab".',
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(isDark ? AppColors.darkSurface : const Color(0xFFF1F5F9)),
                columns: const [
                  DataColumn(label: Text('Appt ID', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Patient', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Doctor / Specialty', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Date & Time', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Risk Level', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: displayAppts.map((appt) {
                  final isPending = appt.status.toLowerCase() == 'pending';
                  final isCancelled = appt.status.toLowerCase() == 'cancelled' || appt.status.toLowerCase() == 'rejected';
                  return DataRow(
                    cells: [
                      DataCell(Text(appt.id.substring(0, appt.id.length > 8 ? 8 : appt.id.length), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                      DataCell(Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(appt.patientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text(appt.patientEmail, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      )),
                      DataCell(Text('Dr. ${appt.doctorName}\n${appt.doctorSpecialty}', style: const TextStyle(fontSize: 12))),
                      DataCell(Text('${appt.preferredDateTime.day}/${appt.preferredDateTime.month}/${appt.preferredDateTime.year}\n${appt.timeSlot}', style: const TextStyle(fontSize: 12))),
                      DataCell(AppBadge.risk(appt.riskLevel)),
                      DataCell(AppBadge.status(appt.status)),
                      DataCell(Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.visibility_outlined, size: 18, color: AppColors.primaryBlue),
                            tooltip: 'View Details',
                            onPressed: () => _showViewDetailsDialog(appt),
                          ),
                          IconButton(
                            icon: const Icon(Icons.download_outlined, size: 18, color: AppColors.primaryTeal),
                            tooltip: 'Download PDF Report',
                            onPressed: () => _handleDownloadReport(appt),
                          ),
                          if (isPending) ...[
                            IconButton(
                              icon: const Icon(Icons.check_circle_outline, size: 18, color: AppColors.success),
                              tooltip: 'Confirm / Approve',
                              onPressed: () async {
                                final ok = await AppModal.showConfirmation(
                                  context: context,
                                  title: 'Approve Appointment',
                                  message: 'Approve appointment for ${appt.patientName} with Dr. ${appt.doctorName}?',
                                  confirmLabel: 'Approve',
                                );
                                if (ok == true) {
                                  await state.updateAppointmentStatusAdmin(appt.id, 'Approved', targetUserId: appt.userId, doctorName: appt.doctorName);
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.cancel_outlined, size: 18, color: AppColors.danger),
                              tooltip: 'Reject',
                              onPressed: () => _showRejectDialog(appt, state),
                            ),
                          ],
                          if (!isCancelled) ...[
                            IconButton(
                              icon: const Icon(Icons.edit_calendar_outlined, size: 18, color: AppColors.warning),
                              tooltip: 'Edit / Reschedule',
                              onPressed: () => _showRescheduleDialog(appt, state),
                            ),
                            IconButton(
                              icon: const Icon(Icons.block, size: 18, color: Colors.orange),
                              tooltip: 'Cancel Appointment',
                              onPressed: () async {
                                final ok = await AppModal.showConfirmation(
                                  context: context,
                                  title: 'Cancel Appointment',
                                  message: 'Cancel appointment for ${appt.patientName}?',
                                  confirmLabel: 'Cancel Appointment',
                                );
                                if (ok == true) {
                                  await state.updateAppointmentStatusAdmin(appt.id, 'Cancelled', targetUserId: appt.userId, doctorName: appt.doctorName);
                                }
                              },
                            ),
                          ],
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                            tooltip: 'Delete Record',
                            onPressed: () async {
                              final ok = await AppModal.showConfirmation(
                                context: context,
                                title: 'Delete Appointment Record',
                                message: 'Permanently delete record ${appt.id} for ${appt.patientName}?',
                                confirmLabel: 'Delete Record',
                              );
                              if (ok == true) {
                                await state.deleteAppointmentAdmin(appt.id);
                              }
                            },
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
    );
  }

  void _showPatientDetailDialog(AppUser patient, AppState state) {
    final patientAppts = state.appointments.where((a) => a.userId == patient.uid).toList();
    final patientAsms = state.assessments.where((a) => a.userId == patient.uid).toList();
    final latestRisk = patientAsms.isNotEmpty ? patientAsms.first.riskCategory : (patientAppts.isNotEmpty ? patientAppts.first.riskLevel : 'No Assessment');

    showDialog(
      context: context,
      builder: (context) => AppModal(
        title: 'Patient Profile: ${patient.fullName}',
        icon: Icons.person_outline,
        iconColor: AppColors.primaryTeal,
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Patient ID (UID)', patient.uid),
              _buildDetailRow('Full Name', patient.fullName),
              _buildDetailRow('Email Address', patient.email),
              _buildDetailRow('Mobile Phone', patient.mobileNumber.isNotEmpty ? patient.mobileNumber : 'N/A'),
              _buildDetailRow('Age / Gender', '${patient.age > 0 ? patient.age : "N/A"} • ${patient.gender}'),
              _buildDetailRow('Registration Date', patient.createdAt != null ? '${patient.createdAt!.day}/${patient.createdAt!.month}/${patient.createdAt!.year}' : 'N/A'),
              _buildDetailRow('Latest Risk Level', latestRisk),
              const SizedBox(height: 12),
              Text('Medical Assessments (${patientAsms.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 4),
              if (patientAsms.isEmpty)
                const Text('No health assessment submitted yet.', style: TextStyle(fontSize: 11, color: Colors.grey))
              else
                ...patientAsms.take(3).map((a) => Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Text('• ${a.date.day}/${a.date.month}/${a.date.year}: ${a.primarySymptoms.join(", ")} (${a.riskCategory})', style: const TextStyle(fontSize: 11)),
                )),
              const SizedBox(height: 12),
              Text('Appointments History (${patientAppts.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 4),
              if (patientAppts.isEmpty)
                const Text('No scheduled appointments.', style: TextStyle(fontSize: 11, color: Colors.grey))
              else
                ...patientAppts.take(3).map((a) => Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Text('• ${a.preferredDateTime.day}/${a.preferredDateTime.month}/${a.preferredDateTime.year} with Dr. ${a.doctorName} [${a.status}]', style: const TextStyle(fontSize: 11)),
                )),
            ],
          ),
        ),
        actions: [
          AppButton(
            label: 'Close',
            variant: AppButtonVariant.secondary,
            size: AppButtonSize.small,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientsSection(bool isDark, AppState state, List<AppointmentModel> allAppts) {
    final patients = state.allPatients;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Registered Patients Directory', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.getTextPrimary(isDark))),
              Text('${patients.length} Registered Patients', style: TextStyle(fontSize: 12, color: AppColors.getTextSecondary(isDark))),
            ],
          ),
          const SizedBox(height: 16),
          if (patients.isEmpty && state.isLoading)
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (patients.isEmpty)
            EmptyState(
              icon: Icons.people_outline,
              title: 'No Registered Patients Found',
              description: 'Patient records will appear here as users register on HealthGuard AI.',
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(isDark ? AppColors.darkSurface : const Color(0xFFF1F5F9)),
                columns: const [
                  DataColumn(label: Text('Patient ID', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Patient Name', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Email Address', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Mobile', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Age / Gender', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Registration Date', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Risk Level', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: patients.map((pt) {
                  final ptAsms = state.assessments.where((a) => a.userId == pt.uid).toList();
                  final ptAppts = state.appointments.where((a) => a.userId == pt.uid).toList();
                  final riskStr = ptAsms.isNotEmpty ? ptAsms.first.riskCategory : (ptAppts.isNotEmpty ? ptAppts.first.riskLevel : 'Low Risk');
                  final regDateStr = pt.createdAt != null ? '${pt.createdAt!.day}/${pt.createdAt!.month}/${pt.createdAt!.year}' : 'N/A';
                  final uidShort = pt.uid.length > 8 ? pt.uid.substring(0, 8) : pt.uid;

                  return DataRow(
                    cells: [
                      DataCell(Text(uidShort, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                      DataCell(Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: AppColors.primaryTeal,
                            child: Text(pt.fullName.isNotEmpty ? pt.fullName[0].toUpperCase() : 'P', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 10),
                          Text(pt.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      )),
                      DataCell(Text(pt.email, style: const TextStyle(fontSize: 12))),
                      DataCell(Text(pt.mobileNumber.isNotEmpty ? pt.mobileNumber : 'N/A', style: const TextStyle(fontSize: 12))),
                      DataCell(Text('${pt.age > 0 ? pt.age : "N/A"} • ${pt.gender}', style: const TextStyle(fontSize: 12))),
                      DataCell(Text(regDateStr, style: const TextStyle(fontSize: 12))),
                      DataCell(AppBadge.risk(riskStr)),
                      DataCell(
                        IconButton(
                          icon: const Icon(Icons.visibility_outlined, size: 18, color: AppColors.primaryBlue),
                          tooltip: 'View Health Info',
                          onPressed: () => _showPatientDetailDialog(pt, state),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDoctorsSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Specialist Doctor Directory', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.getTextPrimary(isDark))),
            Text('${doctorDatabase.length} Medical Specialists', style: TextStyle(fontSize: 12, color: AppColors.getTextSecondary(isDark))),
          ],
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 320,
            mainAxisExtent: 140,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
          ),
          itemCount: doctorDatabase.length,
          itemBuilder: (context, index) {
            final doc = doctorDatabase[index];
            return AppCard(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTeal.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.medical_services_outlined, color: AppColors.primaryTeal, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(doc.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.getTextPrimary(isDark)), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text(doc.specialty, style: const TextStyle(fontSize: 12, color: AppColors.primaryTeal, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(doc.qualification, style: TextStyle(fontSize: 11, color: AppColors.getTextSecondary(isDark)), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 14),
                            const SizedBox(width: 4),
                            Text('${doc.rating} • ${doc.experienceYears}', style: TextStyle(fontSize: 11, color: AppColors.getTextSecondary(isDark))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildReportsSection(bool isDark, AppState state, List<AppointmentModel> allAppts) {
    final assessments = state.assessments;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Medical Reports Directory', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.getTextPrimary(isDark))),
              Text('${assessments.length} Total Patient Reports', style: TextStyle(fontSize: 12, color: AppColors.getTextSecondary(isDark))),
            ],
          ),
          const SizedBox(height: 16),
          if (assessments.isEmpty && state.isLoading)
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (assessments.isEmpty && allAppts.isEmpty)
            EmptyState(
              icon: Icons.description_outlined,
              title: 'No Medical Reports Found',
              description: 'Patient medical reports will be listed here after health assessment submission.',
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(isDark ? AppColors.darkSurface : const Color(0xFFF1F5F9)),
                columns: const [
                  DataColumn(label: Text('Report ID', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Patient Name', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Primary Symptoms', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Risk Assessment', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Assessment Date', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Report Status', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('PDF Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: assessments.map((asm) {
                  final pt = state.allPatients.firstWhere((p) => p.uid == asm.userId, orElse: () => AppUser(uid: asm.userId, fullName: asm.details['patientName'] ?? 'Patient', email: '', mobileNumber: '', age: 0, gender: 'Other'));
                  final ptName = pt.fullName.isNotEmpty ? pt.fullName : (asm.details['patientName'] ?? 'Patient');
                  final rId = asm.id.length > 10 ? asm.id.substring(0, 10) : asm.id;

                  return DataRow(
                    cells: [
                      DataCell(Text(rId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      DataCell(Text(ptName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                      DataCell(Text(asm.primarySymptoms.isNotEmpty ? asm.primarySymptoms.join(', ') : 'General Assessment', style: const TextStyle(fontSize: 12))),
                      DataCell(AppBadge.risk(asm.riskCategory)),
                      DataCell(Text('${asm.date.day}/${asm.date.month}/${asm.date.year}', style: const TextStyle(fontSize: 12))),
                      DataCell(AppBadge(label: 'Verified', isSmall: true)),
                      DataCell(Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.visibility_outlined, size: 18, color: AppColors.primaryBlue),
                            tooltip: 'View Medical Report PDF',
                            onPressed: () => Navigator.pushNamed(context, '/report?id=${asm.id}'),
                          ),
                          IconButton(
                            icon: const Icon(Icons.download_outlined, size: 18, color: AppColors.primaryTeal),
                            tooltip: 'Download PDF Report',
                            onPressed: () async {
                              final bytes = await generate21SectionMedicalReportPdfBytes(
                                assessment: asm,
                                user: pt,
                              );
                              await downloadPdfFileFromUrl('', 'Medical_Report_${asm.id}.pdf', bytes: bytes);
                            },
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
    );
  }
}
