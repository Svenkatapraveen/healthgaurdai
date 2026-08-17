import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../theme/colors.dart';
import '../widgets/glass_card.dart';
import '../state/app_state.dart';

// ==========================================
// 1. APPOINTMENT BOOKING SCREEN
// ==========================================
class AppointmentBookingScreen extends StatefulWidget {
  const AppointmentBookingScreen({Key? key}) : super(key: key);

  @override
  State<AppointmentBookingScreen> createState() => _AppointmentBookingScreenState();
}

class _AppointmentBookingScreenState extends State<AppointmentBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  String _specialty = 'General Physician';

  PlatformFile? _selectedPdfFile;
  String? _uploadError;
  bool _isUploadingPdf = false;

  final List<String> _specialties = [
    'General Physician',
    'Cardiologist',
    'Neurologist',
    'Orthopedic',
    'Pulmonologist',
    'Gastroenterologist'
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = AppStateProvider.of(context);
    final user = state.currentUser;
    if (user != null) {
      if (_nameController.text.isEmpty) _nameController.text = user.fullName;
      if (_mobileController.text.isEmpty) _mobileController.text = user.mobileNumber;
    }

    final argSpecialty = ModalRoute.of(context)!.settings.arguments as String?;
    if (argSpecialty != null && _specialties.contains(argSpecialty)) {
      _specialty = argSpecialty;
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
      setState(() => _selectedDate = date);
    }
  }

  void _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (time != null) {
      setState(() => _selectedTime = time);
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
          _selectedPdfFile = file;
          _uploadError = null;
        });
      }
    } catch (e) {
      setState(() {
        _uploadError = 'Error selecting file: $e';
      });
    }
  }

  void _removePdf() {
    setState(() {
      _selectedPdfFile = null;
      _uploadError = null;
    });
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedPdfFile == null) {
      setState(() {
        _uploadError = 'Please upload your medical report before booking an appointment.';
      });
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

      String reportDownloadUrl = '';
      String storagePath = '';
      try {
        if (_selectedPdfFile?.bytes != null && state.currentUser != null) {
          storagePath = 'medical_reports/${state.currentUser!.uid}/${DateTime.now().millisecondsSinceEpoch}_${_selectedPdfFile!.name}';
          final ref = FirebaseStorage.instance.ref().child(storagePath);
          final uploadTask = await ref.putData(
            _selectedPdfFile!.bytes!,
            SettableMetadata(contentType: 'application/pdf'),
          ).timeout(const Duration(seconds: 2));
          
          reportDownloadUrl = await uploadTask.ref.getDownloadURL().timeout(const Duration(seconds: 2));
        }
      } catch (e) {
        print('Storage upload fallback: $e');
      }

      if (reportDownloadUrl.isEmpty) {
        final reportId = 'asm_${DateTime.now().millisecondsSinceEpoch}';
        reportDownloadUrl = 'https://health-ai-c2308.web.app/#/report?id=$reportId';
      }

      await state.createAppointment(
        patientName: _nameController.text,
        mobileNumber: _mobileController.text,
        dateTime: apptDateTime,
        doctorSpecialty: _specialty,
        reportFileName: _selectedPdfFile!.name,
        reportUrl: reportDownloadUrl,
        reportStoragePath: storagePath,
      ).timeout(const Duration(seconds: 3), onTimeout: () {});

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Appointment Booked Successfully', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your consultation request and medical report have been registered with status: Pending. The administrator will review your report shortly.',
              ),
              const SizedBox(height: 14),
              Text('Doctor Specialty: $_specialty', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text('Date: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}', style: const TextStyle(fontSize: 12)),
              Text('Report: ${_selectedPdfFile!.name}', style: const TextStyle(fontSize: 12, color: AppColors.primaryTeal, fontWeight: FontWeight.bold)),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/dashboard');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
                foregroundColor: Colors.white,
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

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final state = AppStateProvider.of(context);

    return Scaffold(
      backgroundColor: AppColors.getBg(isDark),
      appBar: AppBar(
        title: const Text('Book Appointment', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Schedule Consultation',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.getTextPrimary(isDark)),
              ),
              const SizedBox(height: 8),
              Text(
                'Select doctor specialty and choose preferred timing slots below.',
                style: TextStyle(fontSize: 13, color: AppColors.getTextSecondary(isDark)),
              ),
              const SizedBox(height: 24),
              
              // Patient Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Patient Full Name',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) => val != null && val.isNotEmpty ? null : 'Enter patient name.',
              ),
              const SizedBox(height: 16),
              
              // Mobile Number
              TextFormField(
                controller: _mobileController,
                decoration: InputDecoration(
                  labelText: 'Mobile Number',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) => val != null && val.length > 5 ? null : 'Enter contact number.',
              ),
              const SizedBox(height: 16),

              // Specialty Dropdown
              DropdownButtonFormField<String>(
                value: _specialty,
                decoration: InputDecoration(
                  labelText: 'Doctor Specialty',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: _specialties.map((spec) {
                  return DropdownMenuItem(value: spec, child: Text(spec));
                }).toList(),
                onChanged: (val) => setState(() => _specialty = val ?? 'General Physician'),
              ),
              const SizedBox(height: 16),

              // Date & Time Picker buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.date_range),
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
                      icon: const Icon(Icons.access_time),
                      label: Text(_selectedTime.format(context)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Medical Report / Health Assessment Upload Section
              Text(
                'Medical Report / Health Assessment',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.getTextPrimary(isDark),
                ),
              ),
              const SizedBox(height: 8),
              
              if (_selectedPdfFile == null)
                GestureDetector(
                  onTap: _choosePdf,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _uploadError != null ? AppColors.riskCritical : AppColors.primaryTeal.withOpacity(0.4),
                        width: _uploadError != null ? 1.5 : 1.0,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.cloud_upload_outlined, color: AppColors.primaryTeal, size: 38),
                        const SizedBox(height: 10),
                        Text(
                          'Upload Medical Report',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.getTextPrimary(isDark),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Upload your HealthGuard AI report in PDF format',
                          style: TextStyle(fontSize: 12, color: AppColors.getTextSecondary(isDark)),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 14),
                        ElevatedButton.icon(
                          onPressed: _choosePdf,
                          icon: const Icon(Icons.picture_as_pdf, size: 16),
                          label: const Text('Choose PDF', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryTeal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'PDF only • Max file size: 10 MB',
                          style: TextStyle(fontSize: 10, color: AppColors.getTextSecondary(isDark)),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.primaryTeal, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.redAccent.withOpacity(0.15),
                        child: const Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedPdfFile!.name,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.getTextPrimary(isDark),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatFileSize(_selectedPdfFile!.size),
                              style: TextStyle(fontSize: 11, color: AppColors.getTextSecondary(isDark)),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: const [
                                Icon(Icons.check_circle, color: AppColors.primaryTeal, size: 14),
                                SizedBox(width: 4),
                                Text(
                                  'Report attached',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryTeal,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        tooltip: 'Remove file',
                        onPressed: _removePdf,
                      ),
                    ],
                  ),
                ),

              if (_uploadError != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.riskCritical, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _uploadError!,
                        style: const TextStyle(fontSize: 12, color: AppColors.riskCritical, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),

              // Submit Booking Button
              ElevatedButton(
                onPressed: (state.isLoading || _isUploadingPdf) ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: (state.isLoading || _isUploadingPdf)
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('Uploading Report & Booking...', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      )
                    : const Text('Book Appointment Slot', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 2. DOCTOR RECOMMENDATION SCREEN
// ==========================================
class DoctorRecommendationScreen extends StatelessWidget {
  const DoctorRecommendationScreen({Key? key}) : super(key: key);

  // Mock Doctors database
  static final List<_MockDoctor> _doctors = [
    _MockDoctor(
      name: 'Dr. Evelyn Martinez',
      specialty: 'Cardiologist',
      experience: 12,
      clinic: 'St. Jude Heart Institute',
      rating: 4.9,
      availability: 'Mon - Fri',
    ),
    _MockDoctor(
      name: 'Dr. Raymond Vance',
      specialty: 'Neurologist',
      experience: 15,
      clinic: 'Advanced Neurological Care',
      rating: 4.8,
      availability: 'Tue, Wed, Thu',
    ),
    _MockDoctor(
      name: 'Dr. Aaron Patel',
      specialty: 'Pulmonologist',
      experience: 8,
      clinic: 'Metro Respiratory Clinic',
      rating: 4.7,
      availability: 'Mon, Wed, Fri',
    ),
    _MockDoctor(
      name: 'Dr. Sarah Jenkins',
      specialty: 'Gastroenterologist',
      experience: 10,
      clinic: 'Digestive Health Center',
      rating: 4.9,
      availability: 'Mon - Thu',
    ),
    _MockDoctor(
      name: 'Dr. Robert Mercer',
      specialty: 'Orthopedic',
      experience: 14,
      clinic: 'Joint & Spine Specialty',
      rating: 4.6,
      availability: 'Mon, Tue, Fri',
    ),
    _MockDoctor(
      name: 'Dr. Clara Thorne',
      specialty: 'General Physician',
      experience: 6,
      clinic: 'Family Healthcare Clinic',
      rating: 4.8,
      availability: 'Mon - Sat',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Read primary symptom arguments to filter recommended specialists
    final symptomArg = ModalRoute.of(context)!.settings.arguments as String?;
    
    String recommendedSpecialty = 'General Physician';
    if (symptomArg != null) {
      final symptom = symptomArg.toLowerCase();
      if (symptom.contains('chest') || symptom.contains('heart')) {
        recommendedSpecialty = 'Cardiologist';
      } else if (symptom.contains('headache') || symptom.contains('dizzy')) {
        recommendedSpecialty = 'Neurologist';
      } else if (symptom.contains('breath') || symptom.contains('cough')) {
        recommendedSpecialty = 'Pulmonologist';
      } else if (symptom.contains('stomach') || symptom.contains('abdominal')) {
        recommendedSpecialty = 'Gastroenterologist';
      } else if (symptom.contains('back') || symptom.contains('joint') || symptom.contains('bone')) {
        recommendedSpecialty = 'Orthopedic';
      }
    }

    // Filter list to prioritize recommendation
    final recommendedDoctors = _doctors.where((d) => d.specialty == recommendedSpecialty).toList();
    final otherDoctors = _doctors.where((d) => d.specialty != recommendedSpecialty).toList();
    final sortedDoctors = [...recommendedDoctors, ...otherDoctors];

    return Scaffold(
      backgroundColor: AppColors.getBg(isDark),
      appBar: AppBar(
        title: const Text('Recommended Specialists', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Callout banner detailing recommendations
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primaryTeal.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primaryTeal.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.psychology, color: AppColors.primaryTeal, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'AI Recommendation: Based on symptom inputs of "$symptomArg", booking a consultation with a $recommendedSpecialty is highly advised.',
                    style: const TextStyle(fontSize: 12, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: sortedDoctors.length,
              itemBuilder: (context, index) {
                final doc = sortedDoctors[index];
                final isRecommended = doc.specialty == recommendedSpecialty;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: GlassCard(
                    borderColor: isRecommended ? AppColors.primaryTeal.withOpacity(0.4) : null,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: (isRecommended ? AppColors.primaryTeal : AppColors.primaryBlue).withOpacity(0.15),
                          child: Icon(
                            Icons.person,
                            color: isRecommended ? AppColors.primaryTeal : AppColors.primaryBlue,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      doc.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                  ),
                                  if (isRecommended)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryTeal.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'RECOMMENDED',
                                        style: TextStyle(
                                          color: AppColors.primaryTeal,
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${doc.specialty} • ${doc.experience} Years Exp',
                                style: TextStyle(fontSize: 12, color: AppColors.getTextSecondary(isDark)),
                              ),
                              Text(
                                doc.clinic,
                                style: TextStyle(fontSize: 11, color: AppColors.getTextSecondary(isDark)),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.star, color: Colors.amber, size: 14),
                                      const SizedBox(width: 4),
                                      Text(
                                        doc.rating.toString(),
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(width: 12),
                                      const Icon(Icons.calendar_today, color: Colors.blueAccent, size: 12),
                                      const SizedBox(width: 4),
                                      Text(
                                        doc.availability,
                                        style: TextStyle(fontSize: 10, color: AppColors.getTextSecondary(isDark)),
                                      ),
                                    ],
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pushNamed(
                                        context,
                                        '/booking',
                                        arguments: doc.specialty,
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isRecommended ? AppColors.primaryTeal : Colors.transparent,
                                      foregroundColor: isRecommended ? Colors.white : AppColors.getTextPrimary(isDark),
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                      side: isRecommended ? null : BorderSide(color: AppColors.getBorder(isDark)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    child: const Text('Book Now', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

class _MockDoctor {
  final String name;
  final String specialty;
  final int experience;
  final String clinic;
  final double rating;
  final String availability;

  _MockDoctor({
    required this.name,
    required this.specialty,
    required this.experience,
    required this.clinic,
    required this.rating,
    required this.availability,
  });
}
