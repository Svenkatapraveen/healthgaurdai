import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../theme/colors.dart';
import '../widgets/app_card.dart';
import '../widgets/app_button.dart';
import '../widgets/app_badge.dart';
import '../widgets/app_modal.dart';
import '../widgets/app_layout.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/empty_state.dart';
import '../state/app_state.dart';
import '../services/db_service.dart';
import '../data/doctor_database.dart';
import '../utils/pdf_generator_helper.dart';

class BookingWizardScreen extends StatefulWidget {
  final int initialTab;

  const BookingWizardScreen({super.key, this.initialTab = 0});

  @override
  State<BookingWizardScreen> createState() => _BookingWizardScreenState();
}

class _BookingWizardScreenState extends State<BookingWizardScreen> {
  late int _currentTab;
  AssessmentModel? _passedAssessment;
  String _passedSpecialty = 'General Physician';
  bool _argsParsed = false;

  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialTab;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_argsParsed) {
      _argsParsed = true;
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is AssessmentModel) {
        _passedAssessment = args;
        final raw = args.details['recommendedDoctor']?.toString() ?? 'General Physician';
        _passedSpecialty = normalizeSpecialty(raw);
      } else if (args is String && args.isNotEmpty) {
        _passedSpecialty = normalizeSpecialty(args);
      } else if (args is Map && args.containsKey('tab')) {
        _currentTab = args['tab'] as int;
      } else if (ModalRoute.of(context)?.settings.name == '/my-appointments') {
        _currentTab = 1;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              AppButton(
                label: 'Book New Appointment',
                icon: Icons.add_circle_outline,
                variant: _currentTab == 0 ? AppButtonVariant.primary : AppButtonVariant.secondary,
                onPressed: () => setState(() => _currentTab = 0),
              ),
              AppButton(
                label: 'My Appointments',
                icon: Icons.calendar_month_outlined,
                variant: _currentTab == 1 ? AppButtonVariant.primary : AppButtonVariant.secondary,
                onPressed: () => setState(() => _currentTab = 1),
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (_currentTab == 0)
            AppointmentBookingForm(
              initialSpecialty: _passedSpecialty,
              initialAssessment: _passedAssessment,
            )
          else
            const MyAppointmentsList(),
        ],
      ),
    );
  }
}

class AppointmentBookingForm extends StatefulWidget {
  /// Specialty pre-selected from the health report (e.g. 'Cardiologist').
  final String initialSpecialty;
  /// Full assessment passed from the report screen (may be null if navigated directly).
  final AssessmentModel? initialAssessment;

  const AppointmentBookingForm({
    super.key,
    this.initialSpecialty = 'General Physician',
    this.initialAssessment,
  });

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

  late String _specialty;
  DoctorModel? _selectedDoctor;

  AssessmentModel? _attachedAssessment;
  PlatformFile? _uploadedPdfFile;
  bool _isUploadingPdf = false;
  bool _isSlotBookedError = false;

  final List<String> _specialties = const [
    'All Specialties / Departments',
    'Cardiologist',
    'Neurologist',
    'General Physician',
    'Dermatologist',
    'Orthopedic',
    'Gynecologist',
    'Pulmonologist',
    'Gastroenterologist',
    'Ophthalmologist',
    'ENT',
    'Urologist',
    'Psychiatrist',
    'Endocrinologist',
  ];

  final List<String> _timeSlots = const [
    '09:00 AM',
    '10:00 AM',
    '11:00 AM',
    '02:00 PM',
    '03:00 PM',
    '04:00 PM',
    '05:00 PM',
  ];

  String _selectedSlot = '10:00 AM';

  TimeOfDay _parseSlotTime(String slot) {
    final parts = slot.split(' ');
    final timeParts = parts[0].split(':');
    int hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    final isPm = parts[1].toLowerCase() == 'pm';
    if (isPm && hour != 12) hour += 12;
    if (!isPm && hour == 12) hour = 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  bool _isSlotBooked(String slot) {
    if (_selectedDoctor == null) return false;
    final state = AppStateProvider.of(context);
    final targetTime = _parseSlotTime(slot);
    final targetDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      targetTime.hour,
      targetTime.minute,
    );

    return state.appointments.any((appt) {
      if ((appt.doctorId == _selectedDoctor!.id || appt.doctorName == _selectedDoctor!.name) && appt.status != 'Rejected') {
        final apptDate = appt.preferredDateTime;
        return apptDate.year == targetDateTime.year &&
            apptDate.month == targetDateTime.month &&
            apptDate.day == targetDateTime.day &&
            apptDate.hour == targetDateTime.hour &&
            apptDate.minute == targetDateTime.minute;
      }
      return false;
    });
  }

  void _autoCorrectSlotSelection() {
    for (var slot in _timeSlots) {
      if (!_isSlotBooked(slot)) {
        setState(() {
          _selectedSlot = slot;
          _selectedTime = _parseSlotTime(slot);
        });
        break;
      }
    }
    _checkSlotAvailability();
  }

  @override
  void initState() {
    super.initState();
    // Set specialty once from constructor parameter – never reset by rebuilds
    final normalized = normalizeSpecialty(widget.initialSpecialty);
    _specialty = _specialties.contains(normalized) ? normalized : _specialties.first;
    _attachedAssessment = widget.initialAssessment;

    final docs = getDoctorsBySpecialty(_specialty);
    _selectedDoctor = docs.isNotEmpty ? docs.first : doctorDatabase.first;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only populate user profile fields – do NOT touch specialty here
    final state = AppStateProvider.of(context);
    final user = state.currentUser;
    if (user != null) {
      if (_nameController.text.isEmpty) _nameController.text = user.fullName;
      if (_emailController.text.isEmpty) _emailController.text = user.email;
      if (_mobileController.text.isEmpty) _mobileController.text = user.mobileNumber;
    }

    // If no assessment was passed via constructor, try to load the latest one
    if (_attachedAssessment == null && state.assessments.isNotEmpty) {
      _attachedAssessment = state.assessments.first;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _autoCorrectSlotSelection();
      }
    });
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
      final doctorSpecialty = _selectedDoctor?.specialty ?? _specialty;
      final riskScore = _attachedAssessment?.overallRiskScore ?? 35.0;
      final riskLevel = _attachedAssessment?.riskCategory ?? 'Moderate Risk';

      await state.createAppointment(
        patientName: _nameController.text,
        patientEmail: _emailController.text,
        mobileNumber: _mobileController.text,
        dateTime: apptDateTime,
        doctorId: doctorId,
        doctorName: doctorName,
        doctorSpecialty: doctorSpecialty,
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
            content: Text('Appointment request submitted successfully.'),
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
    
    // Strict department filtering: availableDoctors contains ONLY doctors matching selected department
    final List<DoctorModel> availableDoctors = getDoctorsBySpecialty(_specialty);

    final bool isMobile = MediaQuery.of(context).size.width < 600;

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

            // Show recommended specialist banner when auto-selected from health report
            if (widget.initialSpecialty != 'General Physician' && widget.initialAssessment != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primaryTeal.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.recommend_outlined, color: AppColors.primaryTeal, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Recommended Specialty from Health Report: ${widget.initialSpecialty}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primaryTeal),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Step 1: Select Specialty
            Text('Step 1: Choose Medical Specialty / Department', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.getTextPrimary(isDark))),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _specialties.contains(_specialty) ? _specialty : _specialties.first,
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
                    final List<DoctorModel> docs = getDoctorsBySpecialty(val);
                    _selectedDoctor = docs.isNotEmpty ? docs.first : null;
                  });
                  _autoCorrectSlotSelection();
                }
              },
            ),
            const SizedBox(height: 24),

            // Step 2: Choose Doctor
            Text('Step 2: Choose Doctor (${availableDoctors.length} Doctors Available)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.getTextPrimary(isDark))),
            const SizedBox(height: 12),
            if (availableDoctors.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No $_specialty doctors are currently available. Please select a different specialty or contact support.',
                  style: TextStyle(fontSize: 13, color: AppColors.getTextSecondary(isDark)),
                ),
              )
            else if (isMobile)
              // Responsive stack for mobile to prevent overflow and let cards size dynamically
              Column(
                children: availableDoctors.map((doc) {
                  final isSel = _selectedDoctor?.id == doc.id;
                  final isRec = widget.initialSpecialty.toLowerCase() == doc.specialty.toLowerCase();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AppCard(
                      onTap: () {
                        setState(() => _selectedDoctor = doc);
                        _autoCorrectSlotSelection();
                      },
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      backgroundColor: isSel ? AppColors.primaryBlue.withValues(alpha: 0.12) : null,
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
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        doc.name,
                                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.getTextPrimary(isDark)),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (isRec)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryTeal.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text('Recommended', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.primaryTeal)),
                                      ),
                                  ],
                                ),
                                Text(
                                  'Dept: ${getDepartmentName(doc.specialty)} • ${doc.specialty}',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.getTextSecondary(isDark)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${doc.experienceYears} Exp • ${doc.qualification} ${doc.consultationFee != null ? "• Fee: \$${doc.consultationFee!.toInt()}" : ""}',
                                  style: TextStyle(fontSize: 10, color: AppColors.primaryTeal, fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Schedule: ${doc.availableDays} • ${doc.availableHours}',
                                  style: TextStyle(fontSize: 9, color: AppColors.getTextSecondary(isDark)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 320,
                  mainAxisExtent: 115,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: availableDoctors.length,
                itemBuilder: (ctx, i) {
                  final doc = availableDoctors[i];
                  final isSel = _selectedDoctor?.id == doc.id;
                  final isRec = widget.initialSpecialty.toLowerCase() == doc.specialty.toLowerCase();
                  return AppCard(
                    onTap: () {
                      setState(() => _selectedDoctor = doc);
                      _autoCorrectSlotSelection();
                    },
                    backgroundColor: isSel ? AppColors.primaryBlue.withValues(alpha: 0.12) : null,
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
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(doc.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.getTextPrimary(isDark)), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ),
                                  if (isRec)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryTeal.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text('Recommended', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.primaryTeal)),
                                    ),
                                ],
                              ),
                              Text('Dept: ${getDepartmentName(doc.specialty)} • ${doc.specialty}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.getTextSecondary(isDark)), maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Text('${doc.experienceYears} Exp • ${doc.qualification}', style: TextStyle(fontSize: 10, color: AppColors.primaryTeal, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 2),
                              Text('Schedule: ${doc.availableDays} • ${doc.availableHours}', style: TextStyle(fontSize: 9, color: AppColors.getTextSecondary(isDark)), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: 24),

            // Step 3 & 4: Choose Date & Time Slot
            Text('Step 3 & 4: Choose Date & Time Slot', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.getTextPrimary(isDark))),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppCard(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    onTap: () async {
                      final date = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 90)));
                      if (date != null) {
                        setState(() => _selectedDate = date);
                        _autoCorrectSlotSelection();
                      }
                    },
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month, color: AppColors.primaryTeal, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.getTextPrimary(isDark)), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Step 4: Select Available Time Slot', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.getTextPrimary(isDark))),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _timeSlots.map((slot) {
                final bool isBooked = _isSlotBooked(slot);
                final bool isSel = _selectedSlot == slot;

                return ChoiceChip(
                  label: Text(
                    isBooked ? '$slot (Booked)' : slot,
                    style: TextStyle(
                      fontSize: 11,
                      color: isBooked
                          ? (isDark ? Colors.white24 : Colors.black26)
                          : (isSel ? Colors.white : AppColors.getTextPrimary(isDark)),
                    ),
                  ),
                  selected: isSel && !isBooked,
                  selectedColor: AppColors.primaryTeal,
                  backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightBg,
                  onSelected: isBooked
                      ? null
                      : (val) {
                          if (val) {
                            setState(() {
                              _selectedSlot = slot;
                              _selectedTime = _parseSlotTime(slot);
                            });
                            _checkSlotAvailability();
                          }
                        },
                );
              }).toList(),
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
  const MyAppointmentsList({super.key});

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

    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tabs row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: tabs.map((tab) {
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
            }).toList(),
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
              final hasActions = appt.status.toLowerCase() == 'completed' || appt.reportId.isNotEmpty;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppCard(
                  child: isMobile
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.12),
                                  child: Text(
                                    appt.doctorName.trim().isNotEmpty
                                        ? appt.doctorName.trim().characters.first.toUpperCase()
                                        : 'D',
                                    style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              'Dr. ${appt.doctorName}',
                                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.getTextPrimary(isDark)),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          AppBadge.status(appt.status),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${appt.doctorSpecialty} • Appt ID: ${appt.id}',
                                        style: TextStyle(fontSize: 12, color: AppColors.getTextSecondary(isDark)),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Date: ${appt.preferredDateTime.day}/${appt.preferredDateTime.month}/${appt.preferredDateTime.year} at ${appt.timeSlot}',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryTeal),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (hasActions) ...[
                              const SizedBox(height: 14),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  alignment: WrapAlignment.end,
                                  children: [
                                    if (appt.status.toLowerCase() == 'completed')
                                      AppButton(
                                        label: 'View Consultation',
                                        icon: Icons.medical_information_outlined,
                                        size: AppButtonSize.small,
                                        variant: AppButtonVariant.primary,
                                        onPressed: () => _showConsultationResultModal(context, state, appt),
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
                            ],
                          ],
                        )
                      : Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.12),
                              child: Text(
                                appt.doctorName.trim().isNotEmpty
                                    ? appt.doctorName.trim().characters.first.toUpperCase()
                                    : 'D',
                                style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          'Dr. ${appt.doctorName}',
                                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.getTextPrimary(isDark)),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
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
                            Row(
                              children: [
                                if (appt.status.toLowerCase() == 'completed') ...[
                                  AppButton(
                                    label: 'View Consultation',
                                    icon: Icons.medical_information_outlined,
                                    size: AppButtonSize.small,
                                    variant: AppButtonVariant.primary,
                                    onPressed: () => _showConsultationResultModal(context, state, appt),
                                  ),
                                  const SizedBox(width: 8),
                                ],
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
                          ],
                        ),
                ),
              );
            },
          ),
      ],
    );
  }

  void _showConsultationResultModal(BuildContext context, AppState state, AppointmentModel appt) async {
    final consultation = await state.dbService.getConsultationByAppointmentId(appt.id);
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AppModal(
        title: 'Doctor Consultation Summary',
        icon: Icons.medical_information,
        iconColor: AppColors.primaryTeal,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Attending Doctor', 'Dr. ${consultation?.doctorName ?? appt.doctorName} (${consultation?.doctorSpecialty ?? appt.doctorSpecialty})'),
            _buildInfoRow('Consultation Date', '${appt.preferredDateTime.day}/${appt.preferredDateTime.month}/${appt.preferredDateTime.year}'),
            const Divider(height: 20),
            _buildInfoRow('Clinical Assessment', consultation?.clinicalAssessment.isNotEmpty == true ? consultation!.clinicalAssessment : 'Clinical review completed.'),
            if (consultation?.clinicalNotes.isNotEmpty == true)
              _buildInfoRow('Doctor Notes', consultation!.clinicalNotes),
            if (consultation?.recommendations.isNotEmpty == true)
              _buildInfoRow('Recommendations', consultation!.recommendations),
            if (consultation?.treatmentInstructions.isNotEmpty == true)
              _buildInfoRow('Treatment & Medications', consultation!.treatmentInstructions),
            if (consultation?.followUpRequired == true)
              _buildInfoRow('Follow-up Plan', 'Follow-up recommended. ${consultation?.followUpNotes ?? ""}'),
          ],
        ),
        actions: [
          AppButton(
            label: 'Close',
            variant: AppButtonVariant.secondary,
            size: AppButtonSize.small,
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primaryTeal)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}
