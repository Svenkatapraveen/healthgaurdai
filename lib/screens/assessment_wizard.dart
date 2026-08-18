import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../state/app_state.dart';
import '../services/db_service.dart';
import '../data/symptom_database.dart';

// ==========================================
// ASSESSMENT WIZARD STATEFUL WIDGET
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
  final String _painLocation = 'Center';
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

  final List<String> _categories = symptomCategoriesList;

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
            orElse: () => const MedicalSymptom(name: '', category: '', bodyLocations: []));
        final qMap = _getEffectiveFollowUpQuestions(dbSymptom);
        final ansMap = _followUpAnswers[s] ?? {};
        if (ansMap.length < qMap.length) {
          allAnswered = false;
          break;
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

    // Diagnostics Mapping Heuristics across all categories
    for (var sName in _selectedPrimary) {
      final dbSymptom = symptomDatabase.firstWhere((element) => element.name == sName, 
          orElse: () => const MedicalSymptom(name: '', category: '', bodyLocations: []));
      final cat = dbSymptom.category;

      if (cat.contains('Heart') || cat.contains('Circulatory') || sName.contains('Chest Pain') || sName.contains('Palpitations')) {
        recommendedDoctor = 'Cardiologist';
        possibleCauses.addAll(['Angina Pectoris', 'Myocardial Strain', 'Acid Reflux / GERD']);
        recommendations.addAll(['Rest immediately in an upright position', 'Schedule an ECG & cardiac enzyme evaluation', 'Avoid caffeine and tobacco']);
        diseaseProbability['Cardiac Strain / Angina'] = 75.0;
      } else if (cat.contains('Neurological') || sName.contains('Headache') || sName.contains('Migraine') || sName.contains('Dizziness')) {
        recommendedDoctor = 'Neurologist';
        possibleCauses.addAll(['Migraine Episode', 'Tension Headache', 'Vertigo / Vestibular Strain']);
        recommendations.addAll(['Rest in a dark, quiet room with cold compress', 'Maintain a symptom diary to identify trigger foods', 'Ensure consistent hydration']);
        diseaseProbability['Migraine Tension'] = 80.0;
      } else if (cat.contains('Respiratory') || cat.contains('Lung') || sName.contains('Cough') || sName.contains('Breath')) {
        recommendedDoctor = 'Pulmonologist';
        possibleCauses.addAll(['Acute Bronchitis', 'Asthma Flare-up', 'Upper Respiratory Infection']);
        recommendations.addAll(['Avoid cold environments and air pollution', 'Inhale steam or use humidifier', 'Monitor peak flow reading if asthmatic']);
        diseaseProbability['Asthma / Bronchial spasm'] = 70.0;
      } else if (cat.contains('Digestive') || cat.contains('Abdominal') || sName.contains('Stomach')) {
        recommendedDoctor = 'Gastroenterologist';
        possibleCauses.addAll(['Gastritis', 'Gastroenteritis', 'Irritable Bowel Syndrome']);
        recommendations.addAll(['Eat small, bland meals (BRAT diet)', 'Avoid spicy, greasy, or acidic meals', 'Stay hydrated with electrolyte solutions']);
        diseaseProbability['Gastroesophageal Reflux'] = 65.0;
      } else if (cat.contains('Liver') || cat.contains('Gallbladder') || cat.contains('Pancreas')) {
        recommendedDoctor = 'Gastroenterologist / Hepatologist';
        possibleCauses.addAll(['Gallbladder Biliary Colic', 'Hepatic Dysfunction', 'Pancreatic Irritation']);
        recommendations.addAll(['Avoid high-fat meals', 'Schedule an abdominal ultrasound', 'Avoid alcohol consumption']);
      } else if (cat.contains('Kidney') || cat.contains('Urinary')) {
        recommendedDoctor = 'Nephrologist / Urologist';
        possibleCauses.addAll(['Urinary Tract Infection (UTI)', 'Renal Calculus (Kidney Stone)', 'Cystitis']);
        recommendations.addAll(['Increase fluid intake to 3L daily', 'Schedule urine analysis', 'Avoid delaying urination']);
      } else if (cat.contains('Arm') || cat.contains('Hand') || cat.contains('Back') || cat.contains('Leg') || cat.contains('Foot') || cat.contains('Hip') || cat.contains('Spine')) {
        recommendedDoctor = 'Orthopedist / Rheumatologist';
        possibleCauses.addAll(['Musculoskeletal Strain', 'Joint Inflammation / Arthritis', 'Sciatica Nerve Compression']);
        recommendations.addAll(['Apply warm/cold compresses', 'Avoid heavy lifting or sudden twisting', 'Perform gentle mobility stretches']);
      } else if (cat.contains('Skin') || cat.contains('Hair') || cat.contains('Nail')) {
        recommendedDoctor = 'Dermatologist';
        possibleCauses.addAll(['Contact Dermatitis', 'Allergic Urticaria', 'Eczema Flare-up']);
        recommendations.addAll(['Apply mild, fragrance-free moisturizers', 'Avoid scratching affected regions', 'Review recent cosmetic or detergent switches']);
      } else if (cat.contains('Eye')) {
        recommendedDoctor = 'Ophthalmologist';
        possibleCauses.addAll(['Conjunctivitis', 'Corneal Strain', 'Dry Eye Syndrome']);
        recommendations.addAll(['Restrict digital screen-time', 'Avoid wearing contact lenses temporarily', 'Use sterile lubricating eye drops']);
      } else if (cat.contains('Ear') || cat.contains('Nose') || cat.contains('Throat') || cat.contains('Sinus') || cat.contains('Mouth')) {
        recommendedDoctor = 'ENT Specialist';
        possibleCauses.addAll(['Otitis Media', 'Sinusitis Pressure', 'Pharyngitis / Tonsillitis']);
        recommendations.addAll(['Keep ear dry during showers', 'Inhale steam or use saline spray', 'Gargle with warm salt water']);
      } else if (cat.contains('Reproductive') || cat.contains('Sexual')) {
        recommendedDoctor = 'Gynecologist / Urologist';
        possibleCauses.addAll(['Pelvic Inflammatory Response', 'Hormonal Imbalance', 'Prostatic / Testicular Strain']);
        recommendations.addAll(['Schedule a specialized clinical consultation', 'Rest and maintain hydration']);
      } else if (cat.contains('Mental') || cat.contains('Psychological')) {
        recommendedDoctor = 'Psychiatrist / Therapist';
        possibleCauses.addAll(['Stress-Induced Anxiety', 'Clinical Depression', 'Burnout Syndrome']);
        recommendations.addAll(['Practice daily mindfulness or breathing cycles', 'Maintain structured sleep routines', 'Consult a counselor']);
      }
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
        body: 'Critical risk symptoms detected from your latest assessment. Seek emergency assistance immediately.',
        timestamp: DateTime.now(),
        category: 'Alert',
      ));
    }

    // Navigate to results
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/results', arguments: newAssessment);
    }
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
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
                  }
                },
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

    final List<MedicalSymptom> filteredSymptoms = SymptomDatabaseService.filterSymptoms(
      query: _searchQuery,
      category: _selectedCategory,
      location: _selectedLocation,
    );

    final List<MedicalSymptom> suggestions = SymptomDatabaseService.getSuggestions(_searchQuery);

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
      constraints: const BoxConstraints(maxWidth: 340),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
      ),
      child: _isFrontView
          ? Column(
              children: [
                // Front View: Head, Eyes, Ears, Nose, Mouth
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    buildBodyPartButton('Ears', 42, 26),
                    const SizedBox(width: 6),
                    buildBodyPartButton('Head', 52, 52, shape: BoxShape.circle),
                    const SizedBox(width: 6),
                    buildBodyPartButton('Eyes', 42, 26),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    buildBodyPartButton('Nose', 45, 22),
                    const SizedBox(width: 8),
                    buildBodyPartButton('Mouth', 45, 22),
                  ],
                ),
                const SizedBox(height: 6),
                buildBodyPartButton('Neck', 50, 22),
                const SizedBox(height: 6),
                buildBodyPartButton('Shoulders', 90, 24),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        buildBodyPartButton('Arms', 34, 70),
                        const SizedBox(height: 6),
                        buildBodyPartButton('Hands', 34, 26),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Column(
                      children: [
                        buildBodyPartButton('Chest', 85, 46),
                        const SizedBox(height: 6),
                        buildBodyPartButton('Abdomen', 85, 52),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Column(
                      children: [
                        buildBodyPartButton('Arms', 34, 70),
                        const SizedBox(height: 6),
                        buildBodyPartButton('Hands', 34, 26),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                buildBodyPartButton('Hips', 95, 26),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        buildBodyPartButton('Legs', 38, 50),
                        const SizedBox(height: 4),
                        buildBodyPartButton('Knees', 38, 22),
                        const SizedBox(height: 4),
                        buildBodyPartButton('Feet', 38, 24),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Column(
                      children: [
                        buildBodyPartButton('Legs', 38, 50),
                        const SizedBox(height: 4),
                        buildBodyPartButton('Knees', 38, 22),
                        const SizedBox(height: 4),
                        buildBodyPartButton('Feet', 38, 24),
                      ],
                    ),
                  ],
                ),
              ],
            )
          : Column(
              children: [
                // Back View: Head, Neck, Shoulders, Back (Upper/Mid/Lower), Arms, Elbows, Hands, Hips, Legs, Knees, Feet
                buildBodyPartButton('Head', 55, 55, shape: BoxShape.circle),
                const SizedBox(height: 6),
                buildBodyPartButton('Neck', 50, 22),
                const SizedBox(height: 6),
                buildBodyPartButton('Shoulders', 90, 24),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        buildBodyPartButton('Arms', 34, 45),
                        const SizedBox(height: 4),
                        buildBodyPartButton('Elbows', 34, 22),
                        const SizedBox(height: 4),
                        buildBodyPartButton('Hands', 34, 26),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Column(
                      children: [
                        buildBodyPartButton('Upper Back', 90, 32),
                        const SizedBox(height: 4),
                        buildBodyPartButton('Middle Back', 90, 32),
                        const SizedBox(height: 4),
                        buildBodyPartButton('Lower Back', 90, 32),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Column(
                      children: [
                        buildBodyPartButton('Arms', 34, 45),
                        const SizedBox(height: 4),
                        buildBodyPartButton('Elbows', 34, 22),
                        const SizedBox(height: 4),
                        buildBodyPartButton('Hands', 34, 26),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                buildBodyPartButton('Hips', 95, 26),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        buildBodyPartButton('Legs', 38, 50),
                        const SizedBox(height: 4),
                        buildBodyPartButton('Knees', 38, 22),
                        const SizedBox(height: 4),
                        buildBodyPartButton('Feet', 38, 24),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Column(
                      children: [
                        buildBodyPartButton('Legs', 38, 50),
                        const SizedBox(height: 4),
                        buildBodyPartButton('Knees', 38, 22),
                        const SizedBox(height: 4),
                        buildBodyPartButton('Feet', 38, 24),
                      ],
                    ),
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
            orElse: () => const MedicalSymptom(name: '', category: '', bodyLocations: []),
          );

          final effectiveQuestions = _getEffectiveFollowUpQuestions(dbSymptom);

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
                
                ...effectiveQuestions.entries.map((questionEntry) {
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
