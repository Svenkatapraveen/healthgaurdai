import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../widgets/app_card.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import '../widgets/body_map_widget.dart';
import '../state/app_state.dart';
import '../services/db_service.dart';
import '../data/symptom_database.dart';

class AssessmentWizard extends StatefulWidget {
  final bool isNested;
  const AssessmentWizard({super.key, this.isNested = false});

  @override
  State<AssessmentWizard> createState() => _AssessmentWizardState();
}

class _AssessmentWizardState extends State<AssessmentWizard> {
  int _currentStep = 1;

  final TextEditingController _fullNameCtrl = TextEditingController();
  final TextEditingController _ageCtrl = TextEditingController(text: '28');
  final TextEditingController _heightCtrl = TextEditingController(text: '172 cm');
  final TextEditingController _weightCtrl = TextEditingController(text: '68 kg');
  final TextEditingController _allergiesCtrl = TextEditingController(text: 'None');
  final TextEditingController _medicationsCtrl = TextEditingController(text: 'None');
  String _patientGender = 'Male';
  bool _profileInitialized = false;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _bodyViewMode = 'front';
  String? _selectedBodyArea;
  final Set<String> _selectedPrimary = {};

  final Map<String, Map<String, String>> _followUpAnswers = {};
  double _severity = 5.0;
  final String _painLocation = 'Center';
  final String _duration = 'Days';
  final String _pattern = 'Intermittent';

  final Set<String> _selectedHistory = {};
  String _smoking = 'Never';
  final String _alcohol = 'Rarely';
  final String _exercise = '1-2 times/week';
  final double _sleepHours = 7.0;
  final double _waterLiters = 2.0;
  String _stressLevel = 'Moderate';

  final List<String> _historyOptions = [
    'Diabetes',
    'Hypertension',
    'Asthma',
    'Heart Disease',
    'Kidney Disease',
    'Thyroid Disorder',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_profileInitialized) {
      final state = AppStateProvider.of(context);
      final user = state.currentUser;
      if (user != null) {
        _fullNameCtrl.text = user.fullName;
        if (user.age > 0) _ageCtrl.text = '${user.age}';
        if (user.gender.isNotEmpty) _patientGender = user.gender;
        if (state.assessments.isNotEmpty) {
          for (var cond in state.assessments.first.medicalHistory) {
            _selectedHistory.add(cond);
          }
        }
      }
      _profileInitialized = true;
    }
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _ageCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _allergiesCtrl.dispose();
    _medicationsCtrl.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 1) {
      if (_fullNameCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your full name.')),
        );
        return;
      }
      setState(() => _currentStep = 2);
    } else if (_currentStep == 2) {
      if (_selectedPrimary.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select or search at least one symptom.')),
        );
        return;
      }
      for (var s in _selectedPrimary) {
        if (!_followUpAnswers.containsKey(s)) {
          _followUpAnswers[s] = {};
        }
      }
      setState(() => _currentStep = 3);
    } else if (_currentStep == 3) {
      bool allAnswered = true;
      for (var s in _selectedPrimary) {
        final dbSymptom = symptomDatabase.firstWhere(
          (element) => element.name == s,
          orElse: () => const MedicalSymptom(name: '', category: '', bodyLocations: []),
        );
        final qMap = _getEffectiveFollowUpQuestions(dbSymptom);
        final ansMap = _followUpAnswers[s] ?? {};
        if (ansMap.length < qMap.length) {
          allAnswered = false;
          break;
        }
      }

      if (!allAnswered) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please answer all follow-up questions for selected symptoms.')),
        );
        return;
      }
      setState(() => _currentStep = 4);
    }
  }

  Map<String, List<String>> _getEffectiveFollowUpQuestions(MedicalSymptom dbSymptom) {
    final Map<String, List<String>> qMap = Map.from(dbSymptom.followUpQuestions);
    if (dbSymptom.sideApplicable && !qMap.keys.any((k) => k.toLowerCase().contains('side'))) {
      qMap['Which side is affected?'] = ['Left Side', 'Right Side', 'Both Sides', 'Center / N/A'];
    }
    if (qMap.isEmpty) {
      qMap['How would you rate this symptom?'] = ['Mild / Occasional', 'Moderate', 'Severe / Frequent'];
    }
    return qMap;
  }

  void _prevStep() {
    if (_currentStep > 1) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _submit() async {
    final state = AppStateProvider.of(context);
    double riskScore = 15.0;

    if (_selectedPrimary.contains('Chest Pain') || _selectedPrimary.contains('Shortness of Breath')) {
      riskScore += 35.0;
      if (_followUpAnswers['Chest Pain']?['Does the pain radiate anywhere?'] != 'No radiation') {
        riskScore += 15.0;
      }
    }
    if (_selectedPrimary.contains('Migraine') || _selectedPrimary.contains('Dizziness')) {
      riskScore += 12.0;
    }
    if (_selectedPrimary.contains('Fever')) {
      final temp = _followUpAnswers['Fever']?['What is your approximate temperature?'];
      if (temp != null && temp.contains('Severe')) {
        riskScore += 25.0;
      } else if (temp != null && temp.contains('High')) {
        riskScore += 15.0;
      } else {
        riskScore += 8.0;
      }
    }

    riskScore += (_severity * 2.5);

    if (_selectedHistory.contains('Heart Disease') || _selectedHistory.contains('Hypertension')) {
      riskScore += 18.0;
    }
    if (_selectedHistory.contains('Diabetes')) {
      riskScore += 10.0;
    }

    if (_stressLevel == 'High') riskScore += 8.0;
    if (_smoking == 'Daily') riskScore += 10.0;

    if (riskScore > 100) riskScore = 100;
    if (riskScore < 5) riskScore = 5;

    String category = 'Low Risk';
    String urgency = 'Regular';
    if (riskScore >= 75) {
      category = 'Critical Risk';
      urgency = 'Emergency';
    } else if (riskScore >= 50) {
      category = 'High Risk';
      urgency = 'Urgent';
    } else if (riskScore >= 25) {
      category = 'Moderate Risk';
      urgency = 'Regular';
    }

    String recommendedDoctor = 'General Medicine';
    List<String> possibleCauses = [];
    List<String> recommendations = [];
    Map<String, double> diseaseProbability = {
      'General Consultation': 20.0,
    };

    for (var sName in _selectedPrimary) {
      final dbSymptom = symptomDatabase.firstWhere(
        (element) => element.name.toLowerCase() == sName.toLowerCase(),
        orElse: () => const MedicalSymptom(name: '', category: '', bodyLocations: []),
      );
      final cat = dbSymptom.category.toLowerCase();
      final lowerName = sName.toLowerCase();

      if (cat.contains('heart') || cat.contains('circulatory') || lowerName.contains('chest pain') || lowerName.contains('palpitations') || lowerName.contains('heartbeat')) {
        recommendedDoctor = 'Cardiology';
        possibleCauses.addAll(['Angina Pectoris', 'Myocardial Strain', 'Cardiovascular Evaluation']);
        recommendations.addAll(['Rest immediately in an upright position', 'Schedule an ECG & cardiac enzyme evaluation', 'Avoid caffeine and tobacco']);
        diseaseProbability['Cardiovascular Condition'] = 80.0;
      } else if (cat.contains('neurolog') || lowerName.contains('headache') || lowerName.contains('migraine') || lowerName.contains('dizziness') || lowerName.contains('seizure') || lowerName.contains('numbness') || lowerName.contains('weakness') || lowerName.contains('memory')) {
        recommendedDoctor = 'Neurology';
        possibleCauses.addAll(['Migraine Episode', 'Tension Headache', 'Neurological Evaluation', 'Vertigo / Vestibular Strain']);
        recommendations.addAll(['Rest in a dark, quiet room with cold compress', 'Maintain a symptom diary', 'Ensure consistent hydration']);
        diseaseProbability['Neurological Condition'] = 85.0;
      } else if (cat.contains('skin') || cat.contains('dermat') || lowerName.contains('rash') || lowerName.contains('itching') || lowerName.contains('acne') || lowerName.contains('lesion') || lowerName.contains('discoloration')) {
        recommendedDoctor = 'Dermatology';
        possibleCauses.addAll(['Allergic Dermatitis', 'Eczema Flare-up', 'Skin Lesion']);
        recommendations.addAll(['Avoid scratching affected skin area', 'Apply soothing hypoallergenic moisturizer', 'Keep skin clean and dry']);
        diseaseProbability['Dermatological Condition'] = 75.0;
      } else if (cat.contains('respirat') || cat.contains('lung') || lowerName.contains('cough') || lowerName.contains('breathing') || lowerName.contains('shortness of breath')) {
        recommendedDoctor = 'Pulmonology';
        possibleCauses.addAll(['Acute Bronchitis', 'Asthma Flare-up', 'Upper Respiratory Infection']);
        recommendations.addAll(['Avoid cold environments and dust', 'Inhale steam or use humidifier', 'Monitor peak flow reading']);
        diseaseProbability['Pulmonary / Respiratory Condition'] = 75.0;
      } else if (cat.contains('digest') || cat.contains('abdomin') || lowerName.contains('stomach') || lowerName.contains('vomiting') || lowerName.contains('diarrhea') || lowerName.contains('constipation') || lowerName.contains('reflux')) {
        recommendedDoctor = 'Gastroenterology';
        possibleCauses.addAll(['Gastritis', 'Gastroenteritis', 'Acid Reflux / GERD', 'Irritable Bowel Syndrome']);
        recommendations.addAll(['Eat small bland meals', 'Avoid spicy or greasy foods', 'Stay hydrated with electrolytes']);
        diseaseProbability['Gastrointestinal Condition'] = 70.0;
      } else if (cat.contains('ortho') || cat.contains('joint') || cat.contains('bone') || lowerName.contains('joint pain') || lowerName.contains('back pain') || lowerName.contains('muscle') || lowerName.contains('fracture')) {
        recommendedDoctor = 'Orthopedics';
        possibleCauses.addAll(['Musculoskeletal Strain', 'Joint Inflammation', 'Spinal / Back Pain']);
        recommendations.addAll(['Apply ice/heat packs to painful joints', 'Avoid heavy lifting or strenuous exercise', 'Ensure ergonomic posture']);
        diseaseProbability['Orthopedic / Musculoskeletal Strain'] = 75.0;
      } else if (cat.contains('ent') || lowerName.contains('ear') || lowerName.contains('hearing') || lowerName.contains('sinus') || lowerName.contains('throat') || lowerName.contains('nasal')) {
        recommendedDoctor = 'ENT';
        possibleCauses.addAll(['Sinusitis', 'Otitis / Ear Infection', 'Pharyngitis']);
        recommendations.addAll(['Perform warm saline gargles', 'Use nasal saline spray', 'Avoid loud noise exposure']);
        diseaseProbability['ENT Condition'] = 70.0;
      } else if (cat.contains('eye') || cat.contains('ophthal') || lowerName.contains('vision') || lowerName.contains('eye pain') || lowerName.contains('red eye')) {
        recommendedDoctor = 'Ophthalmology';
        possibleCauses.addAll(['Conjunctivitis', 'Ocular Strain', 'Dry Eye Syndrome']);
        recommendations.addAll(['Rest eyes from screen illumination', 'Avoid rubbing eyes', 'Use lubricating eye drops']);
        diseaseProbability['Ophthalmological Condition'] = 75.0;
      }
    }

    if (possibleCauses.isEmpty) {
      recommendedDoctor = 'General Medicine';
      possibleCauses.addAll(['General Fatigue Syndrome', 'Mild Viral Symptoms', 'General Health Evaluation']);
      recommendations.addAll(['Get 8 hours of restorative sleep', 'Increase daily water intake to 2.5L', 'Schedule routine health checkup']);
    }

    String clinicalSummary = 'This assessment indicates a possible risk and is not a medical diagnosis. Please consult a qualified healthcare professional. ';
    clinicalSummary += 'Patient logged symptoms: ${_selectedPrimary.join(", ")}. ';
    clinicalSummary += 'Overall severity index is $_severity/10 for duration of $_duration in an $_pattern pattern. ';
    if (_selectedHistory.isNotEmpty) {
      clinicalSummary += 'Co-morbid history: ${_selectedHistory.join(", ")}. ';
    }

    for (var s in _selectedPrimary) {
      if (_followUpAnswers[s] != null && _followUpAnswers[s]!.isNotEmpty) {
        clinicalSummary += '\n• $s: ';
        _followUpAnswers[s]!.forEach((q, a) {
          clinicalSummary += '${q.replaceAll("?", "")}: $a; ';
        });
      }
    }

    final newAssessment = AssessmentModel(
      id: 'asm_${DateTime.now().millisecondsSinceEpoch}',
      userId: state.currentUser!.uid,
      date: DateTime.now(),
      primarySymptoms: _selectedPrimary.toList(),
      details: {
        'location': _painLocation,
        'severity': _severity,
        'duration': _duration,
        'pattern': _pattern,
        'followUpAnswers': _followUpAnswers,
        'recommendedDoctor': recommendedDoctor,
      },
      associatedSymptoms: [],
      medicalHistory: _selectedHistory.toList(),
      lifestyle: {
        'smoking': _smoking,
        'alcohol': _alcohol,
        'exercise': _exercise,
        'sleep': _sleepHours,
        'water': _waterLiters,
        'stress': _stressLevel,
      },
      overallRiskScore: riskScore,
      riskCategory: category,
      diseaseProbability: diseaseProbability,
      clinicalSummary: clinicalSummary,
      possibleCauses: possibleCauses,
      recommendations: recommendations,
      preventiveActions: [
        'Engage in 150 minutes of moderate cardiovascular workout weekly.',
        'Maintain daily water log above 2.5 Liters.',
        'Adopt portion control and nutrient-rich organic options.',
      ],
      urgencyLevel: urgency,
    );

    await state.submitAssessment(newAssessment);

    if (urgency == 'Emergency') {
      await state.dbService.addNotification(NotificationModel(
        id: 'notif_em_${DateTime.now().millisecondsSinceEpoch}',
        userId: state.currentUser!.uid,
        title: 'Emergency Risk Detected!',
        body: 'Critical risk symptoms detected. Seek emergency assistance immediately.',
        timestamp: DateTime.now(),
        category: 'Alert',
      ));
    }

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/results', arguments: newAssessment);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final state = AppStateProvider.of(context);

    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Step Header Bar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.getSurface(isDark),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.getBorder(isDark)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                if (!widget.isNested)
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: AppColors.getTextPrimary(isDark)),
                    tooltip: 'Back',
                    onPressed: () {
                      if (_currentStep > 1) {
                        _prevStep();
                      } else if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        Navigator.pushReplacementNamed(context, '/dashboard');
                      }
                    },
                  ),
                if (!widget.isNested) const SizedBox(width: 8),
                _buildStepPill(1, '1. Patient Info'),
                const SizedBox(width: 8),
                _buildStepPill(2, '2. Select Symptoms'),
                const SizedBox(width: 8),
                _buildStepPill(3, '3. Symptom Details'),
                const SizedBox(width: 8),
                _buildStepPill(4, '4. Medical History & Habits'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        _buildStepContent(isDark),
        const SizedBox(height: 20),

        // Bottom Action Bar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.getSurface(isDark),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.getBorder(isDark)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_currentStep > 1)
                AppButton(
                  label: 'Previous Step',
                  variant: AppButtonVariant.secondary,
                  onPressed: _prevStep,
                )
              else
                const SizedBox.shrink(),
              AppButton(
                label: _currentStep < 4 ? 'Continue' : 'Analyze Symptoms',
                icon: _currentStep < 4 ? Icons.arrow_forward : Icons.science_outlined,
                isLoading: state.isLoading,
                onPressed: _currentStep < 4 ? _nextStep : (state.isLoading ? null : _submit),
              ),
            ],
          ),
        ),
      ],
    );

    if (widget.isNested) {
      return content;
    }

    return Scaffold(
      backgroundColor: AppColors.getBg(isDark),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: content,
      ),
    );
  }

  Widget _buildStepPill(int stepNum, String title) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isActive = _currentStep == stepNum;
    final bool isDone = _currentStep > stepNum;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.primaryBlue
            : isDone
                ? AppColors.primaryTeal.withValues(alpha: 0.15)
                : (isDark ? AppColors.darkSurface : const Color(0xFFF1F5F9)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        title,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isActive
              ? Colors.white
              : isDone
                  ? AppColors.primaryTeal
                  : AppColors.getTextSecondary(isDark),
        ),
      ),
    );
  }

  Widget _buildStepContent(bool isDark) {
    switch (_currentStep) {
      case 1:
        return _buildStep0PatientInfo(isDark);
      case 2:
        return _buildStep1Symptoms(isDark);
      case 3:
        return _buildStep2FollowUp(isDark);
      case 4:
      default:
        return _buildStep3Lifestyle(isDark);
    }
  }

  Widget _buildStep0PatientInfo(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Patient Intake Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.getTextPrimary(isDark))),
        const SizedBox(height: 4),
        Text('Review baseline patient parameters automatically pre-filled from your profile.', style: TextStyle(fontSize: 13, color: AppColors.getTextSecondary(isDark))),
        const SizedBox(height: 20),

        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.account_circle_outlined, color: AppColors.primaryTeal, size: 22),
                  const SizedBox(width: 8),
                  Text('Personal & Physical Metrics', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.getTextPrimary(isDark))),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: AppTextField(
                      label: 'Full Name',
                      controller: _fullNameCtrl,
                      prefixIcon: Icons.person_outline,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: AppTextField(
                      label: 'Age',
                      controller: _ageCtrl,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Gender', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.getTextPrimary(isDark))),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _patientGender,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            filled: true,
                            fillColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                          ),
                          items: ['Male', 'Female', 'Other'].map((g) => DropdownMenuItem(value: g, child: Text(g, style: const TextStyle(fontSize: 12)))).toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _patientGender = v);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Height',
                      controller: _heightCtrl,
                      prefixIcon: Icons.height,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      label: 'Weight',
                      controller: _weightCtrl,
                      prefixIcon: Icons.monitor_weight_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Known Allergies',
                controller: _allergiesCtrl,
                prefixIcon: Icons.warning_amber_outlined,
                hint: 'e.g. Penicillin, Peanuts, Dust',
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Current Medications',
                controller: _medicationsCtrl,
                prefixIcon: Icons.medication_outlined,
                hint: 'e.g. Aspirin 75mg, Insulin',
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _mapAreaToLocation(String area) {
    if (area.contains('Arm')) return 'Arms';
    if (area.contains('Hand')) return 'Hands';
    if (area.contains('Leg')) return 'Legs';
    if (area.contains('Foot')) return 'Feet';
    if (area.contains('Back')) return 'Back';
    return area;
  }

  Widget _buildStep1Symptoms(bool isDark) {
    final bool isDesktop = MediaQuery.of(context).size.width >= 900;

    List<MedicalSymptom> filteredSymptoms = [];
    if (_searchQuery.isNotEmpty) {
      filteredSymptoms = symptomDatabase.where((s) {
        return s.name.toLowerCase().contains(_searchQuery) ||
            s.category.toLowerCase().contains(_searchQuery);
      }).toList();
    } else if (_selectedBodyArea != null) {
      final targetLocation = _mapAreaToLocation(_selectedBodyArea!);
      filteredSymptoms = symptomDatabase.where((s) {
        return s.bodyLocations.any((loc) => loc.toLowerCase() == targetLocation.toLowerCase());
      }).toList();
    }

    Widget bodyMapComponent = BodyMapWidget(
      viewMode: _bodyViewMode,
      selectedBodyArea: _selectedBodyArea,
      onViewModeChanged: (mode) => setState(() => _bodyViewMode = mode),
      onSelectBodyArea: (area) => setState(() => _selectedBodyArea = area),
    );

    Widget symptomsPanel = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Global Search Bar
        AppTextField(
          hint: 'Search symptoms (e.g. Chest Pain, Headache, Fever, Cough)...',
          prefixIcon: Icons.search,
          controller: _searchController,
        ),
        const SizedBox(height: 16),

        // Selected Symptoms Section
        if (_selectedPrimary.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryTeal.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primaryTeal.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Selected Symptoms (${_selectedPrimary.length})',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.getTextPrimary(isDark),
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() {
                        _selectedPrimary.clear();
                        _followUpAnswers.clear();
                      }),
                      child: const Text('Clear All', style: TextStyle(fontSize: 11, color: AppColors.danger)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selectedPrimary.map((sName) {
                    final sideInfo = _followUpAnswers[sName]?['Which side is affected?'];
                    final label = sideInfo != null && sideInfo != 'Center / N/A'
                        ? '$sName ($sideInfo)'
                        : sName;
                    return Chip(
                      label: Text(
                        label,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                      backgroundColor: AppColors.primaryTeal,
                      deleteIcon: const Icon(Icons.close, size: 16, color: Colors.white),
                      onDeleted: () {
                        setState(() {
                          _selectedPrimary.remove(sName);
                          _followUpAnswers.remove(sName);
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Active Section Header / Instructions
        if (_searchQuery.isNotEmpty) ...[
          Text(
            'Search Results for "$_searchQuery" (${filteredSymptoms.length})',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.getTextPrimary(isDark)),
          ),
        ] else if (_selectedBodyArea != null) ...[
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _selectedBodyArea!,
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Related Symptoms (${filteredSymptoms.length})',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.getTextPrimary(isDark)),
              ),
            ],
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(24),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.getBorder(isDark)),
            ),
            child: Column(
              children: [
                const Icon(Icons.touch_app_outlined, size: 40, color: AppColors.primaryTeal),
                const SizedBox(height: 12),
                Text(
                  'Select a body area to view related symptoms.',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.getTextPrimary(isDark),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Click any region on the human body diagram on the left to filter symptoms, or search above.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.getTextSecondary(isDark)),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 14),

        // Symptoms Grid
        if (filteredSymptoms.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 260,
              mainAxisExtent: 70,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: filteredSymptoms.length,
            itemBuilder: (ctx, i) {
              final sym = filteredSymptoms[i];
              final isSel = _selectedPrimary.contains(sym.name);
              return AppCard(
                onTap: () {
                  setState(() {
                    if (isSel) {
                      _selectedPrimary.remove(sym.name);
                      _followUpAnswers.remove(sym.name);
                    } else {
                      _selectedPrimary.add(sym.name);
                      if (_selectedBodyArea != null) {
                        if (_selectedBodyArea!.startsWith('Left')) {
                          _followUpAnswers[sym.name] ??= {};
                          _followUpAnswers[sym.name]!['Which side is affected?'] = 'Left Side';
                        } else if (_selectedBodyArea!.startsWith('Right')) {
                          _followUpAnswers[sym.name] ??= {};
                          _followUpAnswers[sym.name]!['Which side is affected?'] = 'Right Side';
                        }
                      }
                    }
                  });
                },
                backgroundColor: isSel ? AppColors.primaryBlue.withValues(alpha: 0.12) : null,
                borderColor: isSel ? AppColors.primaryBlue : null,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Icon(
                      isSel ? Icons.check_circle : Icons.add_circle_outline,
                      color: isSel ? AppColors.primaryBlue : AppColors.getTextSecondary(isDark),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(sym.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.getTextPrimary(isDark)), maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text(sym.category, style: TextStyle(fontSize: 11, color: AppColors.getTextSecondary(isDark)), maxLines: 1, overflow: TextOverflow.ellipsis),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Symptom Intake & Body Location Map', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.getTextPrimary(isDark))),
        const SizedBox(height: 4),
        Text('Click a body region on the diagram or search to view and select current symptoms.', style: TextStyle(fontSize: 13, color: AppColors.getTextSecondary(isDark))),
        const SizedBox(height: 20),

        if (isDesktop)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 320, child: bodyMapComponent),
              const SizedBox(width: 24),
              Expanded(child: symptomsPanel),
            ],
          )
        else
          Column(
            children: [
              bodyMapComponent,
              const SizedBox(height: 24),
              symptomsPanel,
            ],
          ),
      ],
    );
  }

  Widget _buildStep2FollowUp(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Symptom Details & Severity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.getTextPrimary(isDark))),
        const SizedBox(height: 4),
        Text('Provide specific clinical parameters for your selected symptoms.', style: TextStyle(fontSize: 13, color: AppColors.getTextSecondary(isDark))),
        const SizedBox(height: 24),

        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Overall Severity Rating (${_severity.toInt()}/10)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.getTextPrimary(isDark))),
              Slider(
                value: _severity,
                min: 1.0,
                max: 10.0,
                divisions: 9,
                activeColor: _severity >= 8 ? AppColors.danger : _severity >= 5 ? AppColors.warning : AppColors.success,
                label: '${_severity.toInt()}',
                onChanged: (val) => setState(() => _severity = val),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Mild', style: TextStyle(fontSize: 11, color: AppColors.getTextSecondary(isDark))),
                  Text('Moderate', style: TextStyle(fontSize: 11, color: AppColors.getTextSecondary(isDark))),
                  Text('Severe', style: TextStyle(fontSize: 11, color: AppColors.getTextSecondary(isDark))),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        ..._selectedPrimary.map((sName) {
          final dbSym = symptomDatabase.firstWhere((e) => e.name == sName, orElse: () => const MedicalSymptom(name: '', category: '', bodyLocations: []));
          final qMap = _getEffectiveFollowUpQuestions(dbSym);
          final ansMap = _followUpAnswers[sName] ?? {};

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.help_outline, color: AppColors.primaryTeal, size: 20),
                      const SizedBox(width: 8),
                      Text(sName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.getTextPrimary(isDark))),
                    ],
                  ),
                  const Divider(height: 20),
                  ...qMap.entries.map((qEntry) {
                    final qText = qEntry.key;
                    final qOpts = qEntry.value;
                    final curAns = ansMap[qText];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(qText, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.getTextPrimary(isDark))),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: qOpts.map((opt) {
                              final isSel = curAns == opt;
                              return ChoiceChip(
                                label: Text(opt, style: TextStyle(fontSize: 12, color: isSel ? Colors.white : AppColors.getTextPrimary(isDark))),
                                selected: isSel,
                                selectedColor: AppColors.primaryTeal,
                                backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightBg,
                                onSelected: (val) {
                                  if (val) {
                                    setState(() {
                                      _followUpAnswers[sName]![qText] = opt;
                                    });
                                  }
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStep3Lifestyle(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Medical History & Habits', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.getTextPrimary(isDark))),
        const SizedBox(height: 4),
        Text('Final step to enhance AI clinical risk precision.', style: TextStyle(fontSize: 13, color: AppColors.getTextSecondary(isDark))),
        const SizedBox(height: 24),

        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pre-existing Medical Conditions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.getTextPrimary(isDark))),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _historyOptions.map((h) {
                  final isSel = _selectedHistory.contains(h);
                  return FilterChip(
                    label: Text(h, style: TextStyle(fontSize: 12, color: isSel ? Colors.white : AppColors.getTextPrimary(isDark))),
                    selected: isSel,
                    selectedColor: AppColors.primaryBlue,
                    backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightBg,
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _selectedHistory.add(h);
                        } else {
                          _selectedHistory.remove(h);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Lifestyle Profile', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.getTextPrimary(isDark))),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Smoking', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.getTextPrimary(isDark))),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _smoking,
                          decoration: InputDecoration(filled: true, fillColor: isDark ? AppColors.darkSurface : AppColors.lightSurface, contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                          items: ['Never', 'Occasionally', 'Daily'].map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 12)))).toList(),
                          onChanged: (val) => setState(() => _smoking = val ?? 'Never'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Stress Level', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.getTextPrimary(isDark))),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _stressLevel,
                          decoration: InputDecoration(filled: true, fillColor: isDark ? AppColors.darkSurface : AppColors.lightSurface, contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                          items: ['Low', 'Moderate', 'High'].map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 12)))).toList(),
                          onChanged: (val) => setState(() => _stressLevel = val ?? 'Moderate'),
                        ),
                      ],
                    ),
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
