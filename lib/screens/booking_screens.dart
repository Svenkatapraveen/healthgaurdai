import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../theme/colors.dart';
import '../widgets/glass_card.dart';
import '../state/app_state.dart';
import '../services/db_service.dart';
import '../data/doctor_database.dart';
import '../utils/pdf_generator_helper.dart';

class AppointmentBookingScreen extends StatefulWidget {
  const AppointmentBookingScreen({Key? key}) : super(key: key);

  @override
  State<AppointmentBookingScreen> createState() => _AppointmentBookingScreenState();
}

class _AppointmentBookingScreenState extends State<AppointmentBookingScreen> {
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
    } else if (args is String) {
      if (_specialties.contains(args)) {
        _specialty = args;
      }
    } else if (_attachedAssessment == null && state.assessments.isNotEmpty) {
      _attachedAssessment = state.assessments.first;
      if (_attachedAssessment?.details['recommendedDoctor'] != null) {
        _specialty = _attachedAssessment!.details['recommendedDoctor'].toString();
      }
    }

    // Auto select doctor for chosen specialty
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

  void _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
      _checkSlotAvailability();
    }
  }

  void _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (time != null) {
      setState(() {
        _selectedTime = time;
      });
      _checkSlotAvailability();
    }
  }

  Future<void> _choosePdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        if (file.extension?.toLowerCase() != 'pdf') {
          setState(() {
            _uploadError = 'Only PDF format files are allowed.';
          });
          return;
        }

        if (file.size > 10 * 1024 * 1024) {
          setState(() {
            _uploadError = 'File size exceeds 10 MB limit. Please select a smaller PDF report.';
          });
          return;
        }

        setState(() {
          _uploadedPdfFile = file;
          _uploadError = null;
        });
      }
    } catch (e) {
      setState(() {
        _uploadError = 'Error selecting file: $e';
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
          backgroundColor: AppColors.riskCritical,
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
          print('Firebase Storage upload warning: $e');
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
        reportStoragePath: storagePath,
        riskScore: riskScore,
        riskLevel: riskLevel,
      ).timeout(const Duration(seconds: 4), onTimeout: () {});

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.check_circle_rounded, color: AppColors.primaryTeal, size: 28),
              SizedBox(width: 10),
              Text('Appointment Booked', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Your consultation request and HealthGuard AI report have been registered in status: Pending.'),
              const SizedBox(height: 12),
              Text('Doctor: $doctorName', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text('Specialty: $_specialty', style: const TextStyle(fontSize: 12)),
              Text('Date & Time: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year} at ${_selectedTime.format(context)}', style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(reportFileName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryTeal), overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Go to Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          ],
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isUploadingPdf = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final state = AppStateProvider.of(context);
    final user = state.currentUser;

    final availableDoctors = getDoctorsBySpecialty(_specialty);

    return Scaffold(
      backgroundColor: AppColors.getBg(isDark),
      appBar: AppBar(
        title: const Text('Book Doctor Appointment', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. HEALTH ASSESSMENT REPORT BANNER
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F2C59), Color(0xFF1E3A8A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F2C59).withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Health Assessment Report',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2DD4BF).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF2DD4BF)),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.check_circle, color: Color(0xFF2DD4BF), size: 14),
                              SizedBox(width: 4),
                              Text('Medical Report Attached ✓', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF2DD4BF))),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Report ID: ${_attachedAssessment?.id ?? "HG-RPT-2026"}', style: const TextStyle(fontSize: 11, color: Colors.white70)),
                              Text('Patient: ${user?.fullName ?? "Rahul"}', style: const TextStyle(fontSize: 11, color: Colors.white70)),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Risk Level: ${_attachedAssessment?.riskCategory ?? "Moderate Risk"}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amberAccent)),
                              Text('Risk Score: ${(_attachedAssessment?.overallRiskScore ?? 35.0).toStringAsFixed(0)}/100', style: const TextStyle(fontSize: 11, color: Colors.white70)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _uploadedPdfFile != null ? _uploadedPdfFile!.name : 'HealthGuard_AI_Medical_Report.pdf',
                              style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          TextButton(
                            onPressed: _choosePdf,
                            child: const Text('Change PDF', style: TextStyle(fontSize: 10, color: Color(0xFF2DD4BF), fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 2. AI RECOMMENDED SPECIALIST
              if (_attachedAssessment != null && _attachedAssessment!.details['recommendedDoctor'] != null) ...[
                Text('AI Recommended Specialist', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.getTextPrimary(isDark))),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primaryTeal.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: AppColors.primaryTeal.withOpacity(0.15), shape: BoxShape.circle),
                        child: const Icon(Icons.auto_awesome, color: AppColors.primaryTeal, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _attachedAssessment!.details['recommendedDoctor'].toString(),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryTeal),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Reason: Based on the reported symptoms (${_attachedAssessment!.primarySymptoms.join(", ")}) and risk assessment, this specialty is recommended.',
                              style: TextStyle(fontSize: 11, color: AppColors.getTextSecondary(isDark)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // 3. SELECT MEDICAL SPECIALTY
              Text('Select Medical Specialty', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.getTextPrimary(isDark))),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _specialties.contains(_specialty) ? _specialty : _specialties.first,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.medical_services_outlined, color: AppColors.primaryTeal),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                ),
                items: _specialties.map((spec) => DropdownMenuItem(value: spec, child: Text(spec))).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _specialty = val;
                      final docs = getDoctorsBySpecialty(_specialty);
                      _selectedDoctor = docs.isNotEmpty ? docs.first : null;
                    });
                    _checkSlotAvailability();
                  }
                },
              ),
              const SizedBox(height: 20),

              // 4. SELECT DOCTOR
              Text('Available Doctors', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.getTextPrimary(isDark))),
              const SizedBox(height: 8),
              Column(
                children: availableDoctors.map((doc) {
                  final isSelected = _selectedDoctor?.id == doc.id;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedDoctor = doc;
                        });
                        _checkSlotAvailability();
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? AppColors.primaryTeal : (isDark ? Colors.white10 : Colors.grey.shade300),
                            width: isSelected ? 2.0 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppColors.primaryTeal.withOpacity(0.15),
                              child: const Icon(Icons.person, color: AppColors.primaryTeal),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(doc.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  Text('${doc.specialty} • ${doc.availableDays}', style: TextStyle(fontSize: 11, color: AppColors.getTextSecondary(isDark))),
                                  Text('Hours: ${doc.availableHours}', style: TextStyle(fontSize: 10, color: AppColors.getTextSecondary(isDark))),
                                ],
                              ),
                            ),
                            Radio<String>(
                              value: doc.id,
                              groupValue: _selectedDoctor?.id,
                              activeColor: AppColors.primaryTeal,
                              onChanged: (val) {
                                setState(() {
                                  _selectedDoctor = doc;
                                });
                                _checkSlotAvailability();
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // 5. APPOINTMENT DATE AND TIME
              Text('Appointment Date & Preferred Time', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.getTextPrimary(isDark))),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_month, color: AppColors.primaryTeal),
                      label: Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickTime,
                      icon: const Icon(Icons.access_time, color: AppColors.primaryTeal),
                      label: Text(_selectedTime.format(context)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),

              if (_isSlotBookedError) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.riskCritical.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.riskCritical),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.warning_amber_rounded, color: AppColors.riskCritical, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This appointment slot is no longer available. Please select another time.',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.riskCritical),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // 6. PATIENT INFORMATION
              Text('Patient Information', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.getTextPrimary(isDark))),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) => val != null && val.isNotEmpty ? null : 'Enter patient name',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _mobileController,
                decoration: InputDecoration(
                  labelText: 'Mobile Number',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) => val != null && val.length > 5 ? null : 'Enter mobile number',
              ),
              const SizedBox(height: 24),

              // 7. APPOINTMENT SUMMARY CARD
              Text('Appointment Summary', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.getTextPrimary(isDark))),
              const SizedBox(height: 8),
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildSummaryRow('Patient:', _nameController.text.isNotEmpty ? _nameController.text : (user?.fullName ?? 'Rahul')),
                    _buildSummaryRow('Doctor:', _selectedDoctor?.name ?? 'Dr. Specialist'),
                    _buildSummaryRow('Specialty:', _specialty),
                    _buildSummaryRow('Date:', '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                    _buildSummaryRow('Time:', _selectedTime.format(context)),
                    _buildSummaryRow('Attached Report:', _uploadedPdfFile != null ? _uploadedPdfFile!.name : 'HealthGuard_AI_Medical_Report.pdf'),
                    _buildSummaryRow('Assessment Risk:', _attachedAssessment?.riskCategory ?? 'Moderate Risk'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 8. CONFIRM & BOOK APPOINTMENT BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isUploadingPdf || _isSlotBookedError ? null : _submitBooking,
                  icon: _isUploadingPdf
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.calendar_month, color: Colors.white),
                  label: Text(
                    _isUploadingPdf ? 'Booking Appointment...' : 'Confirm & Book Appointment',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
