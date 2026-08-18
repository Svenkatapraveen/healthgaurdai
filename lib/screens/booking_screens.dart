import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../theme/colors.dart';
import '../widgets/app_card.dart';
import '../widgets/app_button.dart';
import '../widgets/app_badge.dart';
import '../widgets/app_text_field.dart';
import '../widgets/app_layout.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/empty_state.dart';
import '../state/app_state.dart';
import '../services/db_service.dart';
import '../data/doctor_database.dart';
import '../utils/pdf_generator_helper.dart';

class BookingWizardScreen extends StatefulWidget {
  const BookingWizardScreen({Key? key}) : super(key: key);

  @override
  State<BookingWizardScreen> createState() => _BookingWizardScreenState();
}

class _BookingWizardScreenState extends State<BookingWizardScreen> {
  int _currentTab = 0; // 0 = Book Appointment, 1 = My Appointments

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return AppLayout(
      title: 'Appointment Management',
      subtitle: 'Schedule consultations and track status with clinical doctors',
      role: UserRole.patient,
      currentRoute: '/my-appointments',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppButton(
                label: 'Back to Dashboard',
                icon: Icons.arrow_back,
                variant: AppButtonVariant.secondary,
                size: AppButtonSize.small,
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    Navigator.pushReplacementNamed(context, '/dashboard');
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Navigation Tabs
          Row(
            children: [
              AppButton(
                label: 'Book New Appointment',
                icon: Icons.add_circle_outline,
                variant: _currentTab == 0 ? AppButtonVariant.primary : AppButtonVariant.secondary,
                onPressed: () => setState(() => _currentTab = 0),
              ),
              const SizedBox(width: 12),
              AppButton(
                label: 'My Appointments',
                icon: Icons.calendar_month_outlined,
                variant: _currentTab == 1 ? AppButtonVariant.primary : AppButtonVariant.secondary,
                onPressed: () => setState(() => _currentTab = 1),
              ),
            ],
          ),
          const SizedBox(height: 24),

          _currentTab == 0 ? const AppointmentBookingForm() : const MyAppointmentsList(),
        ],
      ),
    );
  }
}

class AppointmentBookingForm extends StatefulWidget {
  const AppointmentBookingForm({Key? key}) : super(key: key);

  @override
  State<AppointmentBookingForm> createState() => _AppointmentBookingFormState();
}

class _AppointmentBookingFormState extends State<AppointmentBookingForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 0);

  String _specialty = 'General Physician';
  DoctorModel? _selectedDoctor;

  AssessmentModel? _attachedAssessment;
  PlatformFile? _uploadedPdfFile;
  String? _uploadError;
  bool _isUploadingPdf = false;
  bool _isSlotBookedError = false;

  final List<String> _specialties = const [
    'General Physician',
    'Cardiologist',
    'Neurologist',
    'Dermatologist',
    'Ophthalmologist',
    'ENT Specialist',
    'Pulmonologist',
    'Gastroenterologist',
    'Orthopedic Specialist',
    'Urologist',
    'Gynecologist',
    'Psychiatrist',
    'Endocrinologist',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = AppStateProvider.of(context);
    final user = state.currentUser;
    if (user != null) {
      if (_nameController.text.isEmpty) _nameController.text = user.fullName;
      if (_emailController.text.isEmpty) _emailController.text = user.email;
      if (_mobileController.text.isEmpty) _mobileController.text = user.mobileNumber;
    }

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is AssessmentModel) {
      _attachedAssessment = args;
      _specialty = args.details['recommendedDoctor']?.toString() ?? 'General Physician';
    } else if (_attachedAssessment == null && state.assessments.isNotEmpty) {
      _attachedAssessment = state.assessments.first;
      if (_attachedAssessment?.details['recommendedDoctor'] != null) {
        _specialty = _attachedAssessment!.details['recommendedDoctor'].toString();
      }
    }

    final docs = getDoctorsBySpecialty(_specialty);
    if (_selectedDoctor == null || _selectedDoctor!.specialty != _specialty) {
      _selectedDoctor = docs.isNotEmpty ? docs.first : null;
    }
  }

  void _checkSlotAvailability() {
    final state = AppStateProvider.of(context);
    final targetDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    bool isBooked = false;
    if (_selectedDoctor != null) {
      isBooked = state.appointments.any((appt) {
        if (appt.doctorId == _selectedDoctor!.id || appt.doctorName == _selectedDoctor!.name) {
          final diff = appt.preferredDateTime.difference(targetDateTime).inMinutes.abs();
          if (diff < 30 && appt.status != 'Rejected') return true;
        }
        return false;
      });
    }

    if (mounted) {
      setState(() {
        _isSlotBookedError = isBooked;
      });
    }
  }

  void _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;
    _checkSlotAvailability();

    if (_isSlotBookedError) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This appointment slot is no longer available. Please select another time.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final state = AppStateProvider.of(context);
    setState(() => _isUploadingPdf = true);

    try {
      final apptDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      String reportId = _attachedAssessment?.id ?? 'HG-REPORT-${DateTime.now().millisecondsSinceEpoch}';
      String reportFileName = _uploadedPdfFile?.name ?? 'HealthGuard_AI_Medical_Report_$reportId.pdf';
      String reportDownloadUrl = '';
      String storagePath = 'medical_reports/${state.currentUser?.uid ?? "patients"}/$reportId.pdf';

      Uint8List? pdfBytes;
      if (_uploadedPdfFile?.bytes != null) {
        pdfBytes = _uploadedPdfFile!.bytes!;
      } else if (_attachedAssessment != null) {
        pdfBytes = await generate21SectionMedicalReportPdfBytes(
          assessment: _attachedAssessment!,
          user: state.currentUser,
        );
      }

      if (pdfBytes != null && pdfBytes.isNotEmpty) {
        try {
          final ref = FirebaseStorage.instance.ref().child(storagePath);
          final uploadTask = await ref.putData(
            pdfBytes,
            SettableMetadata(contentType: 'application/pdf'),
          ).timeout(const Duration(seconds: 4));

          reportDownloadUrl = await uploadTask.ref.getDownloadURL().timeout(const Duration(seconds: 3));
        } catch (e) {
          print('Storage upload warning: $e');
        }
      }

      final doctorId = _selectedDoctor?.id ?? 'doc_default';
      final doctorName = _selectedDoctor?.name ?? 'Dr. Specialist ($_specialty)';
      final riskScore = _attachedAssessment?.overallRiskScore ?? 35.0;
      final riskLevel = _attachedAssessment?.riskCategory ?? 'Moderate Risk';

      await state.createAppointment(
        patientName: _nameController.text,
        patientEmail: _emailController.text,
        mobileNumber: _mobileController.text,
        dateTime: apptDateTime,
        doctorId: doctorId,
        doctorName: doctorName,
        doctorSpecialty: _specialty,
        symptomsSummary: _attachedAssessment?.primarySymptoms.join(', ') ?? 'Routine Consultation Request',
        reportId: reportId,
        reportFileName: reportFileName,
        reportUrl: reportDownloadUrl,
        riskScore: riskScore,
        riskLevel: riskLevel,
      );

      if (mounted) {
        setState(() => _isUploadingPdf = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment booked successfully! Status: Pending Approval.'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingPdf = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booking error: ${e.toString()}'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final availableDoctors = getDoctorsBySpecialty(_specialty);

    return AppCard(
      padding: const EdgeInsets.all(28),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Book Clinical Appointment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.getTextPrimary(isDark))),
            const SizedBox(height: 4),
            Text('Select doctor specialty, physician, date/time, and review attached report.', style: TextStyle(fontSize: 13, color: AppColors.getTextSecondary(isDark))),
            const SizedBox(height: 24),

            // Step 1: Select Specialty
            Text('Step 1: Choose Medical Specialty', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.getTextPrimary(isDark))),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _specialty,
              decoration: InputDecoration(
                filled: true,
                fillColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.getBorder(isDark))),
              ),
              items: _specialties.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _specialty = val;
                    final docs = getDoctorsBySpecialty(val);
                    _selectedDoctor = docs.isNotEmpty ? docs.first : null;
                  });
                  _checkSlotAvailability();
                }
              },
            ),
            const SizedBox(height: 24),

            // Step 2: Choose Doctor
            Text('Step 2: Choose Doctor', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.getTextPrimary(isDark))),
            const SizedBox(height: 12),
            if (availableDoctors.isEmpty)
              Text('No doctors currently listed for this specialty.', style: TextStyle(fontSize: 13, color: AppColors.getTextSecondary(isDark)))
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 320,
                  mainAxisExtent: 100,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: availableDoctors.length,
                itemBuilder: (ctx, i) {
                  final doc = availableDoctors[i];
                  final isSel = _selectedDoctor?.id == doc.id;
                  return AppCard(
                    onTap: () {
                      setState(() => _selectedDoctor = doc);
                      _checkSlotAvailability();
                    },
                    backgroundColor: isSel ? AppColors.primaryBlue.withOpacity(0.12) : null,
                    borderColor: isSel ? AppColors.primaryBlue : null,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.primaryTeal,
                          child: Text(doc.name.characters.first.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(doc.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.getTextPrimary(isDark)), maxLines: 1, overflow: TextOverflow.ellipsis),
                              Text(doc.specialty, style: TextStyle(fontSize: 11, color: AppColors.getTextSecondary(isDark))),
                              const SizedBox(height: 4),
                              Text('${doc.experienceYears} Years Exp • ${doc.hospital}', style: TextStyle(fontSize: 10, color: AppColors.primaryTeal, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: 24),

            // Step 3 & 4: Date & Time Picker
            Text('Step 3 & 4: Choose Date & Time Slot', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.getTextPrimary(isDark))),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppCard(
                    onTap: () async {
                      final date = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 90)));
                      if (date != null) {
                        setState(() => _selectedDate = date);
                        _checkSlotAvailability();
                      }
                    },
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month, color: AppColors.primaryTeal, size: 20),
                        const SizedBox(width: 10),
                        Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.getTextPrimary(isDark))),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppCard(
                    onTap: () async {
                      final time = await showTimePicker(context: context, initialTime: _selectedTime);
                      if (time != null) {
                        setState(() => _selectedTime = time);
                        _checkSlotAvailability();
                      }
                    },
                    child: Row(
                      children: [
                        const Icon(Icons.access_time, color: AppColors.primaryTeal, size: 20),
                        const SizedBox(width: 10),
                        Text(_selectedTime.format(context), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.getTextPrimary(isDark))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (_isSlotBookedError) ...[
              const SizedBox(height: 8),
              const Text('Selected slot is unavailable. Please pick a different time.', style: TextStyle(color: AppColors.danger, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
            const SizedBox(height: 24),

            // Step 5: Attached Medical Report Info
            Text('Step 5: Attached Medical Report', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.getTextPrimary(isDark))),
            const SizedBox(height: 8),
            AppCard(
              backgroundColor: isDark ? AppColors.darkSurface : const Color(0xFFF1F5F9),
              child: Row(
                children: [
                  const Icon(Icons.picture_as_pdf, color: AppColors.danger, size: 28),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _attachedAssessment != null ? 'Attached AI Assessment Report (${_attachedAssessment!.id})' : 'General Appointment Request',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.getTextPrimary(isDark)),
                        ),
                        Text(
                          _attachedAssessment != null ? 'Risk Score: ${_attachedAssessment!.overallRiskScore.toInt()}% • ${_attachedAssessment!.symptoms.length} Symptoms' : 'No previous report linked',
                          style: TextStyle(fontSize: 11, color: AppColors.getTextSecondary(isDark)),
                        ),
                      ],
                    ),
                  ),
                  AppBadge(label: 'Attached', type: BadgeType.success, isSmall: true),
                ],
              ),
            ),
            const SizedBox(height: 28),

            AppButton(
              label: 'CONFIRM APPOINTMENT',
              icon: Icons.check_circle_outline,
              isLoading: _isUploadingPdf,
              isFullWidth: true,
              size: AppButtonSize.large,
              onPressed: _submitBooking,
            ),
          ],
        ),
      ),
    );
  }
}

class MyAppointmentsList extends StatefulWidget {
  const MyAppointmentsList({Key? key}) : super(key: key);

  @override
  State<MyAppointmentsList> createState() => _MyAppointmentsListState();
}

class _MyAppointmentsListState extends State<MyAppointmentsList> {
  String _selectedTab = 'All';

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final state = AppStateProvider.of(context);
    final appts = state.appointments;

    final tabs = ['All', 'Pending', 'Approved', 'Rescheduled', 'Completed', 'Rejected'];

    List<AppointmentModel> filtered = appts;
    if (_selectedTab != 'All') {
      filtered = appts.where((a) => a.status.toLowerCase() == _selectedTab.toLowerCase()).toList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tabs row
        SizedBox(
          height: 38,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: tabs.length,
            itemBuilder: (ctx, i) {
              final tab = tabs[i];
              final isSel = _selectedTab == tab;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(tab, style: TextStyle(fontSize: 12, fontWeight: isSel ? FontWeight.w700 : FontWeight.w500, color: isSel ? Colors.white : AppColors.getTextPrimary(isDark))),
                  selected: isSel,
                  selectedColor: AppColors.primaryBlue,
                  backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightBg,
                  onSelected: (val) {
                    if (val) setState(() => _selectedTab = tab);
                  },
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),

        if (filtered.isEmpty)
          EmptyState(
            icon: Icons.calendar_today_outlined,
            title: 'No Appointments Found',
            description: 'No appointment records found for status "$_selectedTab".',
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            itemBuilder: (ctx, i) {
              final appt = filtered[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppCard(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.primaryBlue.withOpacity(0.12),
                        child: Text(appt.doctorName.characters.first.toUpperCase(), style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text('Dr. ${appt.doctorName}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.getTextPrimary(isDark))),
                                const SizedBox(width: 10),
                                AppBadge.status(appt.status),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text('${appt.doctorSpecialty} • Appt ID: ${appt.id}', style: TextStyle(fontSize: 12, color: AppColors.getTextSecondary(isDark))),
                            const SizedBox(height: 4),
                            Text('Date: ${appt.preferredDateTime.day}/${appt.preferredDateTime.month}/${appt.preferredDateTime.year} at ${appt.timeSlot}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryTeal)),
                          ],
                        ),
                      ),
                      if (appt.reportId.isNotEmpty)
                        AppButton(
                          label: 'View Report',
                          icon: Icons.description_outlined,
                          size: AppButtonSize.small,
                          variant: AppButtonVariant.outline,
                          onPressed: () {
                            Navigator.pushNamed(context, '/report?id=${appt.reportId}');
                          },
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
