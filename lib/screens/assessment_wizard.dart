import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../widgets/glass_card.dart';
import '../state/app_state.dart';
import '../services/db_service.dart';

// ==========================================
// 1. MEDICAL SYMPTOM MODEL & DATABASE
// ==========================================
class MedicalSymptom {
  final String name;
  final String category;
  final List<String> bodyLocations;
  final Map<String, List<String>> followUpQuestions;

  const MedicalSymptom({
    required this.name,
    required this.category,
    required this.bodyLocations,
    required this.followUpQuestions,
  });
}

const List<MedicalSymptom> symptomDatabase = [
  // Neurology
  MedicalSymptom(
    name: 'Headache',
    category: 'Neurological Symptoms',
    bodyLocations: ['Head'],
    followUpQuestions: {
      'Which side is the pain on?': ['Left Side', 'Right Side', 'Front', 'Back', 'Entire Head'],
      'How would you describe the pain?': ['Throbbing', 'Dull Ache', 'Sharp/Stabbing', 'Pressure'],
      'Does light or noise worsen the pain?': ['Yes, both', 'Light only', 'Noise only', 'Neither'],
    },
  ),
  MedicalSymptom(
    name: 'Migraine',
    category: 'Neurological Symptoms',
    bodyLocations: ['Head'],
    followUpQuestions: {
      'Are you experiencing nausea or vomiting?': ['Yes', 'No'],
      'Do you see flashing lights or blind spots (Aura)?': ['Yes', 'No'],
    },
  ),
  MedicalSymptom(
    name: 'Dizziness',
    category: 'Neurological Symptoms',
    bodyLocations: ['Head'],
    followUpQuestions: {
      'Does the room feel like it is spinning (Vertigo)?': ['Yes', 'No'],
      'Do you feel lightheaded or off-balance?': ['Lightheaded', 'Off-balance', 'Both'],
    },
  ),
  MedicalSymptom(
    name: 'Memory Loss',
    category: 'Neurological Symptoms',
    bodyLocations: ['Head'],
    followUpQuestions: {
      'Is the memory loss sudden or gradual?': ['Sudden', 'Gradual'],
      'Does it affect daily tasks?': ['Yes', 'No'],
    },
  ),
  MedicalSymptom(
    name: 'Insomnia',
    category: 'Neurological Symptoms',
    bodyLocations: ['Head'],
    followUpQuestions: {
      'How long have you had trouble sleeping?': ['Less than a week', '1-4 weeks', 'More than a month'],
      'What is the main issue?': ['Falling asleep', 'Staying asleep', 'Waking up too early'],
    },
  ),

  // Cardiology
  MedicalSymptom(
    name: 'Chest Pain',
    category: 'Heart Symptoms',
    bodyLocations: ['Chest'],
    followUpQuestions: {
      'Describe the sensation:': ['Pressure/Squeezing', 'Sharp/Stabbing', 'Burning', 'Aching'],
      'Does the pain radiate anywhere?': ['Left Arm', 'Neck/Jaw', 'Back', 'No radiation'],
      'Does it worsen with deep breathing or coughing?': ['Yes', 'No'],
    },
  ),
  MedicalSymptom(
    name: 'Palpitations',
    category: 'Heart Symptoms',
    bodyLocations: ['Chest'],
    followUpQuestions: {
      'How do the palpitations feel?': ['Fluttering', 'Pounding/Hard beating', 'Skipped beats'],
      'Are they accompanied by dizziness or chest discomfort?': ['Yes', 'No'],
    },
  ),

  // Pulmonology
  MedicalSymptom(
    name: 'Cough',
    category: 'Respiratory Symptoms',
    bodyLocations: ['Chest', 'Neck'],
    followUpQuestions: {
      'Is the cough dry or productive?': ['Dry', 'Wet (produces mucus)'],
      'Have you noticed blood in your mucus?': ['Yes', 'No'],
      'Is the cough worse at night?': ['Yes', 'No'],
    },
  ),
  MedicalSymptom(
    name: 'Shortness of Breath',
    category: 'Respiratory Symptoms',
    bodyLocations: ['Chest'],
    followUpQuestions: {
      'When does it occur?': ['At rest', 'During mild exertion', 'During heavy exercise'],
      'Does it get worse when lying flat?': ['Yes', 'No'],
    },
  ),
  MedicalSymptom(
    name: 'Wheezing',
    category: 'Respiratory Symptoms',
    bodyLocations: ['Chest'],
    followUpQuestions: {
      'Is it accompanied by a tight chest feeling?': ['Yes', 'No'],
      'Do you have a history of asthma or allergies?': ['Yes', 'No'],
    },
  ),

  // Gastroenterology
  MedicalSymptom(
    name: 'Stomach Pain',
    category: 'Digestive Symptoms',
    bodyLocations: ['Abdomen'],
    followUpQuestions: {
      'Where is the pain located?': ['Upper Abdomen', 'Lower Abdomen', 'Around Navel', 'All over'],
      'Is it worse before or after eating?': ['Before eating', 'After eating', 'No change'],
    },
  ),
  MedicalSymptom(
    name: 'Stomach Bloating',
    category: 'Digestive Symptoms',
    bodyLocations: ['Abdomen'],
    followUpQuestions: {
      'Is the bloating constant or does it come and go?': ['Constant', 'Comes and goes'],
      'Is it associated with specific foods?': ['Yes', 'No'],
    },
  ),
  MedicalSymptom(
    name: 'Stomach Cramps',
    category: 'Digestive Symptoms',
    bodyLocations: ['Abdomen'],
    followUpQuestions: {
      'Are the cramps relieved by bowel movements?': ['Yes', 'No'],
    },
  ),
  MedicalSymptom(
    name: 'Nausea',
    category: 'Digestive Symptoms',
    bodyLocations: ['Abdomen', 'Head'],
    followUpQuestions: {
      'Have you vomited?': ['Yes', 'No'],
    },
  ),
  MedicalSymptom(
    name: 'Vomiting',
    category: 'Digestive Symptoms',
    bodyLocations: ['Abdomen'],
    followUpQuestions: {
      'How many times in the last 24 hours?': ['1-2 times', '3-5 times', 'More than 5 times'],
      'Are you able to keep fluids down?': ['Yes', 'No'],
    },
  ),

  // Dermatology
  MedicalSymptom(
    name: 'Skin Rash',
    category: 'Skin Symptoms',
    bodyLocations: ['Arms', 'Hands', 'Legs', 'Feet', 'Abdomen', 'Chest', 'Neck'],
    followUpQuestions: {
      'Is the rash itchy?': ['Extremely itchy', 'Mildly itchy', 'Not itchy'],
      'Is it raised or flat?': ['Raised bumps', 'Flat spots', 'Blisters'],
    },
  ),
  MedicalSymptom(
    name: 'Hair Loss',
    category: 'Skin Symptoms',
    bodyLocations: ['Head'],
    followUpQuestions: {
      'Is the hair thinning or falling out in patches?': ['Thinning', 'Patches', 'All over'],
    },
  ),

  // Psychiatry
  MedicalSymptom(
    name: 'Anxiety',
    category: 'Mental Health Symptoms',
    bodyLocations: ['Head', 'Chest'],
    followUpQuestions: {
      'Do you experience physical symptoms like sweating or rapid heartbeat?': ['Yes, often', 'Sometimes', 'No'],
    },
  ),
  MedicalSymptom(
    name: 'Depression',
    category: 'Mental Health Symptoms',
    bodyLocations: ['Head'],
    followUpQuestions: {
      'Have you lost interest in activities you normally enjoy?': ['Yes', 'No'],
    },
  ),

  // Ophthalmology / ENT
  MedicalSymptom(
    name: 'Eye Pain',
    category: 'General Symptoms',
    bodyLocations: ['Eyes'],
    followUpQuestions: {
      'Is there redness or discharge?': ['Redness and discharge', 'Redness only', 'Discharge only', 'Neither'],
      'Is your vision blurry?': ['Yes', 'No'],
    },
  ),
  MedicalSymptom(
    name: 'Ear Pain',
    category: 'General Symptoms',
    bodyLocations: ['Ears'],
    followUpQuestions: {
      'Is there any fluid draining from the ear?': ['Yes', 'No'],
      'Is your hearing reduced?': ['Yes', 'No'],
    },
  ),
  MedicalSymptom(
    name: 'Toothache',
    category: 'General Symptoms',
    bodyLocations: ['Head'],
    followUpQuestions: {
      'Is it sensitive to hot or cold?': ['Hot and cold', 'Hot only', 'Cold only', 'Neither'],
    },
  ),

  // Orthopedics
  MedicalSymptom(
    name: 'Back Pain',
    category: 'Pain Symptoms',
    bodyLocations: ['Back'],
    followUpQuestions: {
      'Where is the pain?': ['Upper Back', 'Mid Back', 'Lower Back'],
      'Does the pain travel down your leg?': ['Yes', 'No'],
    },
  ),
  MedicalSymptom(
    name: 'Knee Pain',
    category: 'Pain Symptoms',
    bodyLocations: ['Legs'],
    followUpQuestions: {
      'Is there swelling or stiffness?': ['Swelling and stiffness', 'Swelling only', 'Stiffness only', 'Neither'],
    },
  ),
  MedicalSymptom(
    name: 'Neck Pain',
    category: 'Pain Symptoms',
    bodyLocations: ['Neck'],
    followUpQuestions: {
      'Does it limit your neck movement?': ['Yes, severely', 'Mildly', 'No'],
    },
  ),

  // General Medicine
  MedicalSymptom(
    name: 'Fever',
    category: 'General Symptoms',
    bodyLocations: ['Head', 'Chest', 'Abdomen', 'Legs', 'Arms'],
    followUpQuestions: {
      'What is your approximate temperature?': ['Low grade (< 100.4°F)', 'High grade (100.4°F - 103°F)', 'Severe (> 103°F)', 'Not measured'],
      'Are you experiencing chills or sweating?': ['Chills only', 'Sweating only', 'Both', 'Neither'],
    },
  ),
  MedicalSymptom(
    name: 'Fatigue',
    category: 'General Symptoms',
    bodyLocations: ['Head', 'Legs', 'Arms'],
    followUpQuestions: {
      'How long have you felt abnormally tired?': ['A few days', '1-2 weeks', 'More than a month'],
    },
  ),
];

// ==========================================
// 2. ASSESSMENT WIZARD STATEFUL WIDGET
// ==========================================
class AssessmentWizard extends StatefulWidget {
  final bool isNested;
  const AssessmentWizard({Key? key, this.isNested = false}) : super(key: key);

  @override
  State<AssessmentWizard> createState() => _AssessmentWizardState();
}

class _AssessmentWizardState extends State<AssessmentWizard> {
  int _currentStep = 1; // Step 1: Search & Selector, Step 2: Dynamic Questions, Step 3: History & Habits

  // Step 1 State: Search & Selection
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedLocation;
  String _selectedCategory = 'All';
  bool _isFrontView = true;
  final Set<String> _selectedPrimary = {};
  
  // Tab for Step 1 layout: Body Map vs Categories Filters
  int _step1Tab = 0; // 0 = Body Map, 1 = Categories Filters

  // Step 2 State: Symptom-Specific Answers & Global Details
  // Stores answers: symptomName -> question -> answer
  final Map<String, Map<String, String>> _followUpAnswers = {};
  double _severity = 5.0; // 1-10 slider
  String _painLocation = 'Center';
  String _duration = 'Days';
  String _pattern = 'Intermittent';

  // Step 3 State: Medical History & Lifestyle
  final Set<String> _selectedHistory = {};
  String _smoking = 'Never';
  String _alcohol = 'Rarely';
  String _exercise = '1-2 times/week';
  double _sleepHours = 7.0;
  double _waterLiters = 2.0;
  String _stressLevel = 'Moderate';

  final List<String> _historyOptions = [
    'Diabetes',
    'Hypertension',
    'Asthma',
    'Heart Disease',
    'Kidney Disease',
    'Thyroid Disorder',
  ];

  final List<String> _categories = [
    'All',
    'General Symptoms',
    'Pain Symptoms',
    'Heart Symptoms',
    'Respiratory Symptoms',
    'Digestive Symptoms',
    'Neurological Symptoms',
    'Skin Symptoms',
    'Mental Health Symptoms',
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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_selectedPrimary.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or search at least one symptom to assess.')),
      );
      return;
    }
    
    if (_currentStep == 1) {
      // Initialize follow up questions map for new symptoms
      for (var s in _selectedPrimary) {
        if (!_followUpAnswers.containsKey(s)) {
          _followUpAnswers[s] = {};
        }
      }
      setState(() => _currentStep = 2);
    } else if (_currentStep == 2) {
      // Validate that all follow-up questions have been answered to guarantee professional quality
      bool allAnswered = true;
      for (var s in _selectedPrimary) {
        final dbSymptom = symptomDatabase.firstWhere((element) => element.name == s, 
            orElse: () => const MedicalSymptom(name: '', category: '', bodyLocations: [], followUpQuestions: {}));
        
        if (dbSymptom.name.isNotEmpty) {
          for (var q in dbSymptom.followUpQuestions.keys) {
            if (_followUpAnswers[s]?[q] == null) {
              allAnswered = false;
              break;
            }
          }
        }
      }

      if (!allAnswered) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please answer all follow-up questions for the selected symptoms.')),
        );
        return;
      }
      setState(() => _currentStep = 3);
    }
  }

  void _prevStep() {
    if (_currentStep > 1) {
      setState(() => _currentStep--);
    }
  }

  void _submit() async {
    final state = AppStateProvider.of(context);
    
    // ----------------------------------------------------
    // AI CLINICAL ENGINE SCORE CALCULATIONS
    // ----------------------------------------------------
    double riskScore = 15.0; // Base baseline risk
    
    // Calculate based on primary symptoms severity and classifications
    if (_selectedPrimary.contains('Chest Pain') || _selectedPrimary.contains('Shortness of Breath')) {
      riskScore += 35.0;
      // Radating chest pain is high risk
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
    
    // Severity additions
    riskScore += (_severity * 2.5);

    // Medical history modifications
    if (_selectedHistory.contains('Heart Disease') || _selectedHistory.contains('Hypertension')) {
      riskScore += 18.0;
    }
    if (_selectedHistory.contains('Diabetes')) {
      riskScore += 10.0;
    }

    // Stress and smoking modifications
    if (_stressLevel == 'High') riskScore += 8.0;
    if (_smoking == 'Daily') riskScore += 10.0;

    if (riskScore > 100) riskScore = 100;
    if (riskScore < 5) riskScore = 5;

    // Categories
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

    // Determine specialty doctor to recommend
    String recommendedDoctor = 'General Practitioner';
    List<String> possibleCauses = [];
    List<String> recommendations = [];
    Map<String, double> diseaseProbability = {
      'Influenza / Viral Fever': 15.0,
      'Migraine Tension': 10.0,
      'Gastroesophageal Reflux': 10.0,
      'Cardiac Strain / Angina': 5.0,
      'Asthma / Bronchial spasm': 5.0,
    };

    // Diagnostics Mapping Heuristics
    if (_selectedPrimary.contains('Chest Pain')) {
      recommendedDoctor = 'Cardiologist';
      possibleCauses.addAll(['Angina Pectoris', 'Myocardial Strain', 'Acid Reflux / GERD']);
      recommendations.addAll(['Rest immediately in an upright position', 'Schedule an ECG & cardiac enzyme evaluation', 'Avoid caffeine and tobacco consumption']);
      diseaseProbability['Cardiac Strain / Angina'] = 75.0;
      diseaseProbability['Gastroesophageal Reflux'] = 35.0;
    } 
    
    if (_selectedPrimary.contains('Headache') || _selectedPrimary.contains('Migraine')) {
      recommendedDoctor = 'Neurologist';
      possibleCauses.addAll(['Migraine Episode', 'Tension-type Headache', 'Sinusitis Pressure']);
      recommendations.addAll(['Rest in a dark, quiet room with cold compress', 'Maintain a symptom diary to identify trigger foods', 'Ensure consistent hydration']);
      diseaseProbability['Migraine Tension'] = 80.0;
      diseaseProbability['Influenza / Viral Fever'] = 25.0;
    }

    if (_selectedPrimary.contains('Cough') || _selectedPrimary.contains('Shortness of Breath') || _selectedPrimary.contains('Wheezing')) {
      recommendedDoctor = 'Pulmonologist';
      possibleCauses.addAll(['Acute Bronchitis', 'Asthma Flare-up', 'Allergic Response']);
      recommendations.addAll(['Avoid cold environments and direct AC drafts', 'Inhale steam or use humidifier', 'Monitor peak flow reading if asthmatic']);
      diseaseProbability['Asthma / Bronchial spasm'] = 70.0;
      diseaseProbability['Influenza / Viral Fever'] = 45.0;
    }

    if (_selectedPrimary.contains('Stomach Pain') || _selectedPrimary.contains('Vomiting') || _selectedPrimary.contains('Stomach Bloating')) {
      recommendedDoctor = 'Gastroenterologist';
      possibleCauses.addAll(['Gastritis', 'Gastroenteritis', 'Irritable Bowel Syndrome']);
      recommendations.addAll(['Eat small, bland meals (BRAT diet)', 'Avoid spicy, greasy, or acidic meals', 'Stay hydrated with electrolyte solutions']);
      diseaseProbability['Gastroesophageal Reflux'] = 65.0;
    }

    if (_selectedPrimary.contains('Skin Rash')) {
      recommendedDoctor = 'Dermatologist';
      possibleCauses.addAll(['Contact Dermatitis', 'Allergic Hives', 'Eczema Flare-up']);
      recommendations.addAll(['Apply mild, fragrance-free moisturizers', 'Avoid scratching affected regions', 'Review recent cosmetic or detergent switches']);
    }

    if (_selectedPrimary.contains('Anxiety') || _selectedPrimary.contains('Depression')) {
      recommendedDoctor = 'Psychiatrist / Therapist';
      possibleCauses.addAll(['Stress-induced Anxiety', 'Clinical Depression', 'Fatigue-associated Burnout']);
      recommendations.addAll(['Practice daily mindfulness or breathing cycles', 'Maintain structured sleep and waking routines', 'Consult a counselor']);
    }

    if (_selectedPrimary.contains('Eye Pain')) {
      recommendedDoctor = 'Ophthalmologist';
      possibleCauses.addAll(['Conjunctivitis', 'Corneal Strain', 'Dry Eye Syndrome']);
      recommendations.addAll(['Restrict digital display screen-time', 'Avoid wearing contact lenses temporarily', 'Use sterile lubricating eye drops']);
    }

    if (_selectedPrimary.contains('Ear Pain')) {
      recommendedDoctor = 'ENT Specialist';
      possibleCauses.addAll(['Otitis Media (Middle Ear Infection)', 'Eustachian Tube Dysfunction', 'Wax Build-up']);
      recommendations.addAll(['Keep ear dry during showers', 'Avoid inserting cotton swabs or probes', 'Use warm compress outside the ear']);
    }

    // Default Fallbacks
    if (possibleCauses.isEmpty) {
      possibleCauses.addAll(['General Fatigue Syndrome', 'Mild Viral Infection', 'Dehydration Headache']);
      recommendations.addAll(['Get 8 hours of restorative sleep', 'Increase daily water intake to 2.5L', 'Schedule regular active walking stretch sessions']);
    }

    // Build Dynamically Descriptive Summary
    String clinicalSummary = 'Patient logged symptoms: ${_selectedPrimary.join(", ")}. ';
    clinicalSummary += 'Overall severity index is $_severity/10 for a logged duration of $_duration in an $_pattern pattern. ';
    if (_selectedHistory.isNotEmpty) {
      clinicalSummary += 'Co-morbid history includes: ${_selectedHistory.join(", ")}. ';
    }
    
    // Add symptom specific answers to clinical summary to make it highly informative
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
        body: 'Critical risk symptoms detected from your latest assessment. Seek emergency assistance immediately.',
        timestamp: DateTime.now(),
        category: 'Alert',
      ));
    }

    // Navigate to results
    Navigator.pushReplacementNamed(context, '/results', arguments: newAssessment);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final state = AppStateProvider.of(context);

    return Scaffold(
      backgroundColor: AppColors.getBg(isDark),
      appBar: AppBar(
        title: const Text('Clinical Symptom Intelligence', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: widget.isNested
            ? null
            : IconButton(
                icon: Icon(Icons.close, color: AppColors.getTextPrimary(isDark)),
                onPressed: () => Navigator.pop(context),
              ),
      ),
      body: Column(
        children: [
          // Step progress indicator bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: Row(
              children: [
                _buildProgressSegment(1, 'Search & Select'),
                const SizedBox(width: 8),
                _buildProgressSegment(2, 'Follow-up Details'),
                const SizedBox(width: 8),
                _buildProgressSegment(3, 'Habits & Submit'),
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: _buildCurrentStepView(isDark),
            ),
          ),
          
          // Navigation Bottom Bar
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              border: Border(top: BorderSide(color: AppColors.getBorder(isDark))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentStep > 1)
                  OutlinedButton(
                    onPressed: _prevStep,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Back'),
                  )
                else
                  const SizedBox(),
                ElevatedButton(
                  onPressed: _currentStep < 3 ? _nextStep : (state.isLoading ? null : _submit),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: state.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(_currentStep < 3 ? 'Continue' : 'Analyze Now'),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildProgressSegment(int stepNum, String title) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final isDone = _currentStep > stepNum;
    final isActive = _currentStep == stepNum;
    final color = isDone || isActive ? AppColors.primaryTeal : (isDark ? Colors.white12 : Colors.black12);
    
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 5,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? AppColors.primaryTeal : AppColors.getTextSecondary(isDark),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStepView(bool isDark) {
    switch (_currentStep) {
      case 1:
        return _buildStep1(isDark);
      case 2:
        return _buildStep2(isDark);
      case 3:
        return _buildStep3(isDark);
      default:
        return _buildStep1(isDark);
    }
  }

  // ==========================================
  // STEP 1: SEARCH, CATEGORIES, & BODY SELECTOR
  // ==========================================
  Widget _buildStep1(bool isDark) {
    // Filter symptoms based on search text, selected body part, and selected category
    final List<MedicalSymptom> filteredSymptoms = symptomDatabase.where((s) {
      final matchesSearch = s.name.toLowerCase().contains(_searchQuery);
      final matchesLocation = _selectedLocation == null || s.bodyLocations.contains(_selectedLocation);
      final matchesCategory = _selectedCategory == 'All' || s.category == _selectedCategory;
      return matchesSearch && matchesLocation && matchesCategory;
    }).toList();

    // suggestions based on typing
    final List<MedicalSymptom> suggestions = _searchQuery.isEmpty
        ? []
        : symptomDatabase.where((s) => s.name.toLowerCase().startsWith(_searchQuery)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Search & Mapping Symptoms',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.getTextPrimary(isDark),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Select your symptoms by searching, clicking the interactive body diagram, or browsing clinical categories.',
          style: TextStyle(fontSize: 12.5, color: AppColors.getTextSecondary(isDark), height: 1.3),
        ),
        const SizedBox(height: 20),

        // 1. SMART SEARCH BAR
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search any symptom...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _searchController.clear();
                    },
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        
        // Dynamic Autocomplete Suggestions List
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: 4),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            color: isDark ? AppColors.darkSurface : Colors.white,
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: suggestions.length,
              itemBuilder: (context, idx) {
                final item = suggestions[idx];
                final isAlreadySelected = _selectedPrimary.contains(item.name);
                return ListTile(
                  title: Text(item.name, style: const TextStyle(fontSize: 14)),
                  subtitle: Text(item.category, style: const TextStyle(fontSize: 11)),
                  trailing: isAlreadySelected 
                      ? const Icon(Icons.check_circle, color: AppColors.primaryTeal)
                      : const Icon(Icons.add_circle_outline, color: Colors.blueAccent),
                  onTap: () {
                    setState(() {
                      if (isAlreadySelected) {
                        _selectedPrimary.remove(item.name);
                      } else {
                        _selectedPrimary.add(item.name);
                      }
                      _searchController.clear();
                    });
                  },
                );
              },
            ),
          ),
        ],
        const SizedBox(height: 20),

        // 2. SELECTED SYMPTOMS CHIPS DISPLAY
        if (_selectedPrimary.isNotEmpty) ...[
          Text(
            'Selected Symptoms (${_selectedPrimary.length})',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.getTextPrimary(isDark)),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedPrimary.map((symptom) {
              return InputChip(
                label: Text(symptom),
                onDeleted: () {
                  setState(() {
                    _selectedPrimary.remove(symptom);
                  });
                },
                backgroundColor: AppColors.primaryTeal.withOpacity(0.12),
                labelStyle: const TextStyle(color: AppColors.primaryTeal, fontWeight: FontWeight.bold, fontSize: 12),
                deleteIconColor: AppColors.primaryTeal,
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
        ],

        // 3. TAB SELECTOR: BODY MAP vs CATEGORIES
        Row(
          children: [
            Expanded(
              child: ChoiceChip(
                label: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.accessibility_new, size: 16),
                    SizedBox(width: 6),
                    Text('Body Map'),
                  ],
                ),
                selected: _step1Tab == 0,
                selectedColor: AppColors.primaryTeal.withOpacity(0.15),
                onSelected: (val) {
                  if (val) setState(() => _step1Tab = 0);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ChoiceChip(
                label: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.category_outlined, size: 16),
                    SizedBox(width: 6),
                    Text('Categories'),
                  ],
                ),
                selected: _step1Tab == 1,
                selectedColor: AppColors.primaryTeal.withOpacity(0.15),
                onSelected: (val) {
                  if (val) setState(() => _step1Tab = 1);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 4. BODY MAP LAYOUT
        if (_step1Tab == 0) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ChoiceChip(
                label: const Text('Front View', style: TextStyle(fontSize: 12)),
                selected: _isFrontView,
                onSelected: (val) => setState(() => _isFrontView = true),
              ),
              const SizedBox(width: 12),
              ChoiceChip(
                label: const Text('Back View', style: TextStyle(fontSize: 12)),
                selected: !_isFrontView,
                onSelected: (val) => setState(() => _isFrontView = false),
              ),
            ],
          ),
          const SizedBox(height: 14),
          
          // Custom Interactive Stack Silhouette
          Center(
            child: _buildInteractiveBodyDiagram(isDark),
          ),
        ] 
        // 5. CATEGORIES FILTER CHIPS
        else ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories.map((cat) {
              final isSel = _selectedCategory == cat;
              return ChoiceChip(
                label: Text(cat, style: const TextStyle(fontSize: 12)),
                selected: isSel,
                onSelected: (val) {
                  if (val) {
                    setState(() {
                      _selectedCategory = cat;
                      _selectedLocation = null; // reset location filter when switching category
                    });
                  }
                },
              );
            }).toList(),
          ),
        ],
        const SizedBox(height: 24),

        // 6. SYMPTOMS DATABASE LIST BASED ON FILTERS
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Available Symptoms (${filteredSymptoms.length})',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.getTextPrimary(isDark)),
            ),
            if (_selectedLocation != null || _selectedCategory != 'All')
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedLocation = null;
                    _selectedCategory = 'All';
                  });
                },
                child: const Text('Clear Filters', style: TextStyle(fontSize: 12, color: AppColors.primaryTeal)),
              ),
          ],
        ),
        const SizedBox(height: 12),

        if (filteredSymptoms.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Center(
              child: Text(
                'No matching symptoms found. Try search or reset filters.',
                style: TextStyle(fontSize: 13, color: AppColors.getTextSecondary(isDark)),
              ),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: filteredSymptoms.map((symptom) {
              final isSel = _selectedPrimary.contains(symptom.name);
              return FilterChip(
                label: Text(symptom.name, style: const TextStyle(fontSize: 12)),
                selected: isSel,
                selectedColor: AppColors.primaryTeal.withOpacity(0.2),
                checkmarkColor: AppColors.primaryTeal,
                backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: isSel ? AppColors.primaryTeal : (isDark ? Colors.white12 : Colors.black12)),
                ),
                onSelected: (val) {
                  setState(() {
                    if (val) {
                      _selectedPrimary.add(symptom.name);
                    } else {
                      _selectedPrimary.remove(symptom.name);
                    }
                  });
                },
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildInteractiveBodyDiagram(bool isDark) {
    Widget buildBodyPartButton(String location, double width, double height, {BoxShape shape = BoxShape.rectangle, BorderRadius? borderRadius}) {
      final isSel = _selectedLocation == location;
      final actColor = AppColors.primaryTeal;
      final inColor = isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.03);
      final borderCol = isSel ? actColor : (isDark ? Colors.white10 : Colors.black12);

      return GestureDetector(
        onTap: () => setState(() {
          _selectedLocation = isSel ? null : location;
          _selectedCategory = 'All'; // reset category filter when tapping location
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: isSel ? actColor.withOpacity(0.15) : inColor,
            shape: shape,
            borderRadius: shape == BoxShape.circle ? null : (borderRadius ?? BorderRadius.circular(8)),
            border: Border.all(
              color: isSel ? actColor : borderCol,
              width: isSel ? 2.0 : 1.0,
            ),
            boxShadow: isSel
                ? [
                    BoxShadow(
                      color: actColor.withOpacity(0.25),
                      blurRadius: 6,
                    )
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              location,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
                color: isSel ? actColor : (isDark ? Colors.white54 : Colors.black54),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
      ),
      child: _isFrontView
          ? Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    buildBodyPartButton('Ears', 40, 26),
                    const SizedBox(width: 8),
                    buildBodyPartButton('Head', 50, 50, shape: BoxShape.circle),
                    const SizedBox(width: 8),
                    buildBodyPartButton('Eyes', 40, 26),
                  ],
                ),
                const SizedBox(height: 6),
                buildBodyPartButton('Nose', 45, 22),
                const SizedBox(height: 6),
                buildBodyPartButton('Neck', 45, 20),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        buildBodyPartButton('Arms', 32, 70),
                        const SizedBox(height: 6),
                        buildBodyPartButton('Hands', 32, 24),
                      ],
                    ),
                    const SizedBox(width: 10),
                    Column(
                      children: [
                        buildBodyPartButton('Chest', 80, 44),
                        const SizedBox(height: 6),
                        buildBodyPartButton('Abdomen', 80, 48),
                      ],
                    ),
                    const SizedBox(width: 10),
                    Column(
                      children: [
                        buildBodyPartButton('Arms', 32, 70),
                        const SizedBox(height: 6),
                        buildBodyPartButton('Hands', 32, 24),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        buildBodyPartButton('Legs', 38, 80),
                        const SizedBox(height: 6),
                        buildBodyPartButton('Feet', 38, 24),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Column(
                      children: [
                        buildBodyPartButton('Legs', 38, 80),
                        const SizedBox(height: 6),
                        buildBodyPartButton('Feet', 38, 24),
                      ],
                    ),
                  ],
                ),
              ],
            )
          : Column(
              children: [
                buildBodyPartButton('Head', 55, 55, shape: BoxShape.circle),
                const SizedBox(height: 6),
                buildBodyPartButton('Neck', 45, 20),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildBodyPartButton('Arms', 32, 80),
                    const SizedBox(width: 10),
                    buildBodyPartButton('Back', 85, 100),
                    const SizedBox(width: 10),
                    buildBodyPartButton('Arms', 32, 80),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    buildBodyPartButton('Legs', 38, 80),
                    const SizedBox(width: 16),
                    buildBodyPartButton('Legs', 38, 80),
                  ],
                ),
              ],
            ),
    );
  }

  // ==========================================
  // STEP 2: DYNAMIC FOLLOW-UP DIAGNOSTIC Q&A
  // ==========================================
  Widget _buildStep2(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Clinical Follow-Up Questions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.getTextPrimary(isDark),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Answer symptom-specific details to help the AI narrow down possible conditions and urgency.',
          style: TextStyle(fontSize: 12.5, color: AppColors.getTextSecondary(isDark), height: 1.3),
        ),
        const SizedBox(height: 24),

        // Global Severity Slider
        Text(
          'Symptom Severity Index: ${_severity.toStringAsFixed(0)} / 10',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppColors.getTextPrimary(isDark)),
        ),
        Slider(
          value: _severity,
          min: 1.0,
          max: 10.0,
          divisions: 9,
          label: _severity.toStringAsFixed(0),
          activeColor: AppColors.primaryTeal,
          inactiveColor: AppColors.primaryTeal.withOpacity(0.2),
          onChanged: (val) => setState(() => _severity = val),
        ),
        const SizedBox(height: 16),

        // Global details: Duration and Pattern
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _duration,
                decoration: const InputDecoration(labelText: 'Duration'),
                items: ['Minutes', 'Hours', 'Days', 'Weeks']
                    .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
                onChanged: (val) => setState(() => _duration = val ?? 'Days'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _pattern,
                decoration: const InputDecoration(labelText: 'Pattern'),
                items: ['Constant', 'Intermittent', 'Increasing', 'Decreasing']
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (val) => setState(() => _pattern = val ?? 'Intermittent'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Dynamic Questions for Each Selected Symptom
        ..._selectedPrimary.map((symptomName) {
          final dbSymptom = symptomDatabase.firstWhere(
            (element) => element.name == symptomName,
            orElse: () => const MedicalSymptom(name: '', category: '', bodyLocations: [], followUpQuestions: {}),
          );

          if (dbSymptom.name.isEmpty || dbSymptom.followUpQuestions.isEmpty) {
            return const SizedBox();
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.psychology, color: AppColors.primaryTeal, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '$symptomName Details',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.getTextPrimary(isDark),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                
                ...dbSymptom.followUpQuestions.entries.map((questionEntry) {
                  final qText = questionEntry.key;
                  final options = questionEntry.value;
                  final currentAnswer = _followUpAnswers[symptomName]?[qText];

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          qText,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.getTextPrimary(isDark),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: options.map((opt) {
                            final isSelected = currentAnswer == opt;
                            return ChoiceChip(
                              label: Text(opt, style: const TextStyle(fontSize: 11)),
                              selected: isSelected,
                              selectedColor: AppColors.primaryTeal.withOpacity(0.2),
                              onSelected: (val) {
                                if (val) {
                                  setState(() {
                                    _followUpAnswers[symptomName]![qText] = opt;
                                  });
                                }
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  // ==========================================
  // STEP 3: MEDICAL HISTORY & LIFESTYLE INFO
  // ==========================================
  Widget _buildStep3(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'History & Habits Profile',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.getTextPrimary(isDark),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Complete medical baseline and lifestyle metrics to enable accurate disease calculations.',
          style: TextStyle(fontSize: 12.5, color: AppColors.getTextSecondary(isDark), height: 1.3),
        ),
        const SizedBox(height: 24),

        // 1. Previous Medical History
        Text(
          'Previous Medical History',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppColors.getTextPrimary(isDark)),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _historyOptions.map((h) {
            final isSelected = _selectedHistory.contains(h);
            return FilterChip(
              label: Text(h, style: const TextStyle(fontSize: 12)),
              selected: isSelected,
              selectedColor: AppColors.accentCyan.withOpacity(0.2),
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
        const SizedBox(height: 28),

        // 2. Lifestyle Habits
        Text(
          'Lifestyle Habits',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppColors.getTextPrimary(isDark)),
        ),
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _smoking,
                decoration: const InputDecoration(labelText: 'Smoking'),
                items: ['Never', 'Rarely', 'Daily']
                    .map((x) => DropdownMenuItem(value: x, child: Text(x)))
                    .toList(),
                onChanged: (val) => setState(() => _smoking = val ?? 'Never'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _alcohol,
                decoration: const InputDecoration(labelText: 'Alcohol'),
                items: ['Never', 'Rarely', 'Daily']
                    .map((x) => DropdownMenuItem(value: x, child: Text(x)))
                    .toList(),
                onChanged: (val) => setState(() => _alcohol = val ?? 'Rarely'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _exercise,
                decoration: const InputDecoration(labelText: 'Exercise'),
                items: ['None', '1-2 times/week', '3-5 times/week', 'Daily']
                    .map((x) => DropdownMenuItem(value: x, child: Text(x)))
                    .toList(),
                onChanged: (val) => setState(() => _exercise = val ?? '1-2 times/week'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _stressLevel,
                decoration: const InputDecoration(labelText: 'Stress Level'),
                items: ['Low', 'Moderate', 'High']
                    .map((x) => DropdownMenuItem(value: x, child: Text(x)))
                    .toList(),
                onChanged: (val) => setState(() => _stressLevel = val ?? 'Moderate'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Sleep & Water Intake Sliders
        Text(
          'Daily Rest: ${_sleepHours.toStringAsFixed(0)} Hours',
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.getTextPrimary(isDark)),
        ),
        Slider(
          value: _sleepHours,
          min: 4.0,
          max: 12.0,
          divisions: 8,
          label: _sleepHours.toStringAsFixed(0),
          activeColor: AppColors.primaryTeal,
          inactiveColor: AppColors.primaryTeal.withOpacity(0.2),
          onChanged: (val) => setState(() => _sleepHours = val),
        ),
        const SizedBox(height: 12),

        Text(
          'Daily Water: ${_waterLiters.toStringAsFixed(1)} Liters',
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.getTextPrimary(isDark)),
        ),
        Slider(
          value: _waterLiters,
          min: 1.0,
          max: 5.0,
          divisions: 8,
          label: _waterLiters.toStringAsFixed(1),
          activeColor: AppColors.primaryTeal,
          inactiveColor: AppColors.primaryTeal.withOpacity(0.2),
          onChanged: (val) => setState(() => _waterLiters = val),
        ),
      ],
    );
  }
}
