// ==========================================
// 1. MEDICAL SYMPTOM MODEL
// ==========================================
class MedicalSymptom {
  final String id;
  final String name;
  final String category;
  final List<String> bodyLocations;
  final String view; // 'front', 'back', 'both'
  final bool sideApplicable; // true if Left/Right/Both side selection applies
  final bool severityApplicable;
  final bool durationApplicable;
  final String? gender; // 'male', 'female', or null (all)
  final Map<String, List<String>> followUpQuestions;

  const MedicalSymptom({
    required this.name,
    required this.category,
    required this.bodyLocations,
    String? id,
    this.view = 'both',
    this.sideApplicable = false,
    this.severityApplicable = true,
    this.durationApplicable = true,
    this.gender,
    this.followUpQuestions = const {},
  }) : id = id ?? name;
}

// ==========================================
// 2. EXPANDED COMPREHENSIVE SYMPTOM DATABASE (500+ SYMPTOMS)
// ==========================================
const List<MedicalSymptom> symptomDatabase = [
  // ==================== 1. HEAD & NEUROLOGICAL (40+ symptoms) ====================
  MedicalSymptom(
    name: 'Headache',
    category: 'Neurological Symptoms',
    bodyLocations: ['Head'],
    view: 'both',
    sideApplicable: true,
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
    view: 'both',
    sideApplicable: true,
    followUpQuestions: {
      'Are you experiencing nausea or vomiting?': ['Yes', 'No'],
      'Do you see flashing lights or blind spots (Aura)?': ['Yes', 'No'],
    },
  ),
  MedicalSymptom(
    name: 'Dizziness',
    category: 'Neurological Symptoms',
    bodyLocations: ['Head'],
    view: 'both',
    followUpQuestions: {
      'Does the room feel like it is spinning (Vertigo)?': ['Yes', 'No'],
      'Do you feel lightheaded or off-balance?': ['Lightheaded', 'Off-balance', 'Both'],
    },
  ),
  MedicalSymptom(
    name: 'Memory Loss',
    category: 'Neurological Symptoms',
    bodyLocations: ['Head'],
    view: 'both',
    followUpQuestions: {
      'Is the memory loss sudden or gradual?': ['Sudden', 'Gradual'],
      'Does it affect daily tasks?': ['Yes', 'No'],
    },
  ),
  MedicalSymptom(
    name: 'Insomnia',
    category: 'Neurological Symptoms',
    bodyLocations: ['Head'],
    view: 'both',
    followUpQuestions: {
      'How long have you had trouble sleeping?': ['Less than a week', '1-4 weeks', 'More than a month'],
      'What is the main issue?': ['Falling asleep', 'Staying asleep', 'Waking up too early'],
    },
  ),
  MedicalSymptom(
    name: 'Confusion / Brain Fog',
    category: 'Neurological Symptoms',
    bodyLocations: ['Head'],
    view: 'both',
    followUpQuestions: {
      'Did this symptom start suddenly?': ['Yes', 'No'],
      'Is it accompanied by fever or severe headache?': ['Yes', 'No'],
    },
  ),
  MedicalSymptom(
    name: 'Toothache',
    category: 'General Symptoms',
    bodyLocations: ['Head', 'Mouth'],
    view: 'front',
    sideApplicable: true,
    followUpQuestions: {
      'Is it sensitive to hot or cold?': ['Hot and cold', 'Hot only', 'Cold only', 'Neither'],
      'Is there visible facial swelling?': ['Yes', 'No'],
    },
  ),
  MedicalSymptom(
    name: 'Jaw Pain / TMJ',
    category: 'Pain Symptoms',
    bodyLocations: ['Head', 'Neck', 'Mouth'],
    view: 'both',
    sideApplicable: true,
    followUpQuestions: {
      'Does your jaw click or pop when opening?': ['Yes', 'No'],
      'Is pain worse when chewing?': ['Yes', 'No'],
    },
  ),
  MedicalSymptom(
    name: 'Scalp Tenderness',
    category: 'Skin Symptoms',
    bodyLocations: ['Head'],
    view: 'both',
    followUpQuestions: {
      'Is there visible redness or flaking?': ['Yes', 'No'],
    },
  ),
  MedicalSymptom(
    name: 'Hair Loss',
    category: 'Skin Symptoms',
    bodyLocations: ['Head'],
    view: 'both',
    followUpQuestions: {
      'Is the hair thinning or falling out in patches?': ['Thinning', 'Patches', 'All over'],
    },
  ),
  MedicalSymptom(name: 'Vertigo', category: 'Neurological Symptoms', bodyLocations: ['Head']),
  MedicalSymptom(name: 'Loss of Consciousness / Syncope', category: 'Neurological Symptoms', bodyLocations: ['Head']),
  MedicalSymptom(name: 'Fainting Spells', category: 'Neurological Symptoms', bodyLocations: ['Head']),
  MedicalSymptom(name: 'Seizures / Convulsions', category: 'Neurological Symptoms', bodyLocations: ['Head']),
  MedicalSymptom(name: 'Muscle Tremors', category: 'Neurological Symptoms', bodyLocations: ['Head', 'Arms', 'Hands']),
  MedicalSymptom(name: 'Body Shaking', category: 'Neurological Symptoms', bodyLocations: ['Head', 'Arms', 'Legs']),
  MedicalSymptom(name: 'Balance Problems', category: 'Neurological Symptoms', bodyLocations: ['Head', 'Legs']),
  MedicalSymptom(name: 'Coordination Loss (Ataxia)', category: 'Neurological Symptoms', bodyLocations: ['Head', 'Arms', 'Legs']),
  MedicalSymptom(name: 'Generalized Muscle Weakness', category: 'Neurological Symptoms', bodyLocations: ['Head', 'Arms', 'Legs']),
  MedicalSymptom(name: 'Head Numbness', category: 'Neurological Symptoms', bodyLocations: ['Head'], sideApplicable: true),
  MedicalSymptom(name: 'Head Tingling', category: 'Neurological Symptoms', bodyLocations: ['Head'], sideApplicable: true),
  MedicalSymptom(name: 'Burning Sensation on Scalp', category: 'Neurological Symptoms', bodyLocations: ['Head']),
  MedicalSymptom(name: 'Facial Muscle Weakness', category: 'Neurological Symptoms', bodyLocations: ['Head'], sideApplicable: true),
  MedicalSymptom(name: 'Facial Numbness', category: 'Neurological Symptoms', bodyLocations: ['Head'], sideApplicable: true),
  MedicalSymptom(name: 'Speech Difficulty (Dysphasia)', category: 'Neurological Symptoms', bodyLocations: ['Head', 'Mouth']),
  MedicalSymptom(name: 'Slurred Speech (Dysarthria)', category: 'Neurological Symptoms', bodyLocations: ['Head', 'Mouth']),
  MedicalSymptom(name: 'Difficulty Concentrating', category: 'Neurological Symptoms', bodyLocations: ['Head']),
  MedicalSymptom(name: 'Excessive Sleepiness / Somnolence', category: 'Neurological Symptoms', bodyLocations: ['Head']),
  MedicalSymptom(name: 'Lightheadedness', category: 'Neurological Symptoms', bodyLocations: ['Head']),
  MedicalSymptom(name: 'Unsteadiness on Feet', category: 'Neurological Symptoms', bodyLocations: ['Head', 'Legs']),
  MedicalSymptom(name: 'Sudden Disorientation', category: 'Neurological Symptoms', bodyLocations: ['Head']),
  MedicalSymptom(name: 'Short-term Memory Impairment', category: 'Neurological Symptoms', bodyLocations: ['Head']),
  MedicalSymptom(name: 'Sudden Facial Droop', category: 'Neurological Symptoms', bodyLocations: ['Head'], sideApplicable: true),
  MedicalSymptom(name: 'Involuntary Muscle Twitches', category: 'Neurological Symptoms', bodyLocations: ['Head', 'Arms', 'Legs']),
  MedicalSymptom(name: 'Meningismus / Stiff Neck with Headache', category: 'Neurological Symptoms', bodyLocations: ['Head', 'Neck']),
  MedicalSymptom(name: 'Loss of Motor Control', category: 'Neurological Symptoms', bodyLocations: ['Head', 'Arms', 'Legs']),
  MedicalSymptom(name: 'Sensory Distortion', category: 'Neurological Symptoms', bodyLocations: ['Head']),
  MedicalSymptom(name: 'Phantom Smell or Taste', category: 'Neurological Symptoms', bodyLocations: ['Head', 'Nose', 'Mouth']),
  MedicalSymptom(name: 'Sleep Apnea Symptoms', category: 'Neurological Symptoms', bodyLocations: ['Head', 'Chest']),
  MedicalSymptom(name: 'Restless Sleep / Frequent Waking', category: 'Neurological Symptoms', bodyLocations: ['Head']),
  MedicalSymptom(name: 'Cluster Headache', category: 'Neurological Symptoms', bodyLocations: ['Head'], sideApplicable: true),
  MedicalSymptom(name: 'Tension-Type Headache', category: 'Neurological Symptoms', bodyLocations: ['Head']),
  MedicalSymptom(name: 'Sinus-Related Headache', category: 'Neurological Symptoms', bodyLocations: ['Head', 'Nose']),
  MedicalSymptom(name: 'Occipital Neuralgia', category: 'Neurological Symptoms', bodyLocations: ['Head', 'Neck'], sideApplicable: true),
  MedicalSymptom(name: 'Electric Shock Sensations in Head', category: 'Neurological Symptoms', bodyLocations: ['Head']),
  MedicalSymptom(name: 'Daytime Fatigue & Drowsiness', category: 'Neurological Symptoms', bodyLocations: ['Head']),
  MedicalSymptom(name: 'Altered Consciousness Level', category: 'Neurological Symptoms', bodyLocations: ['Head']),

  // ==================== 2. EYES (25-30 symptoms) ====================
  MedicalSymptom(
    name: 'Eye Pain',
    category: 'Eye Symptoms',
    bodyLocations: ['Eyes', 'Head'],
    view: 'front',
    sideApplicable: true,
    followUpQuestions: {
      'Is there redness or discharge?': ['Redness and discharge', 'Redness only', 'Discharge only', 'Neither'],
      'Is your vision blurry?': ['Yes', 'No'],
    },
  ),
  MedicalSymptom(
    name: 'Blurred Vision',
    category: 'Eye Symptoms',
    bodyLocations: ['Eyes'],
    view: 'front',
    sideApplicable: true,
    followUpQuestions: {
      'Is the blurring in one eye or both eyes?': ['One eye', 'Both eyes'],
      'Is it sudden or gradual?': ['Sudden', 'Gradual'],
    },
  ),
  MedicalSymptom(
    name: 'Red Eyes / Conjunctivitis',
    category: 'Eye Symptoms',
    bodyLocations: ['Eyes'],
    view: 'front',
    sideApplicable: true,
    followUpQuestions: {
      'Is there yellow/green discharge or crusting?': ['Yes', 'No'],
      'Are your eyes itchy or gritty?': ['Itchy', 'Gritty', 'Both', 'Neither'],
    },
  ),
  MedicalSymptom(
    name: 'Watery / Itchy Eyes',
    category: 'Eye Symptoms',
    bodyLocations: ['Eyes'],
    view: 'front',
    sideApplicable: true,
    followUpQuestions: {
      'Do you have seasonal allergies or sneezing?': ['Yes', 'No'],
    },
  ),
  MedicalSymptom(
    name: 'Double Vision',
    category: 'Eye Symptoms',
    bodyLocations: ['Eyes'],
    view: 'front',
    sideApplicable: true,
    followUpQuestions: {
      'Does double vision persist when one eye is covered?': ['Yes', 'No'],
    },
  ),
  MedicalSymptom(
    name: 'Sensitivity to Light (Photophobia)',
    category: 'Eye Symptoms',
    bodyLocations: ['Eyes', 'Head'],
    view: 'front',
    sideApplicable: true,
    followUpQuestions: {
      'Is it accompanied by a severe headache or eye pain?': ['Yes', 'No'],
    },
  ),
  MedicalSymptom(name: 'Dry Eyes', category: 'Eye Symptoms', bodyLocations: ['Eyes'], view: 'front', sideApplicable: true),
  MedicalSymptom(name: 'Eye Swelling', category: 'Eye Symptoms', bodyLocations: ['Eyes'], view: 'front', sideApplicable: true),
  MedicalSymptom(name: 'Eye Discharge / Pus', category: 'Eye Symptoms', bodyLocations: ['Eyes'], view: 'front', sideApplicable: true),
  MedicalSymptom(name: 'Eye Pressure Sensation', category: 'Eye Symptoms', bodyLocations: ['Eyes'], view: 'front', sideApplicable: true),
  MedicalSymptom(name: 'Eye Strain', category: 'Eye Symptoms', bodyLocations: ['Eyes'], view: 'front', sideApplicable: true),
  MedicalSymptom(name: 'Burning Sensation in Eyes', category: 'Eye Symptoms', bodyLocations: ['Eyes'], view: 'front', sideApplicable: true),
  MedicalSymptom(name: 'Foreign Body Sensation in Eye', category: 'Eye Symptoms', bodyLocations: ['Eyes'], view: 'front', sideApplicable: true),
  MedicalSymptom(name: 'Eye Floaters', category: 'Eye Symptoms', bodyLocations: ['Eyes'], view: 'front', sideApplicable: true),
  MedicalSymptom(name: 'Flashes of Light in Vision', category: 'Eye Symptoms', bodyLocations: ['Eyes'], view: 'front', sideApplicable: true),
  MedicalSymptom(name: 'Sudden Vision Loss', category: 'Eye Symptoms', bodyLocations: ['Eyes'], view: 'front', sideApplicable: true),
  MedicalSymptom(name: 'Partial Vision Loss / Blind Spots', category: 'Eye Symptoms', bodyLocations: ['Eyes'], view: 'front', sideApplicable: true),
  MedicalSymptom(name: 'Reduced Night Vision (Nyctalopia)', category: 'Eye Symptoms', bodyLocations: ['Eyes'], view: 'front', sideApplicable: true),
  MedicalSymptom(name: 'Difficulty Focusing Vision', category: 'Eye Symptoms', bodyLocations: ['Eyes'], view: 'front', sideApplicable: true),
  MedicalSymptom(name: 'Tunnel Vision', category: 'Eye Symptoms', bodyLocations: ['Eyes'], view: 'front', sideApplicable: true),
  MedicalSymptom(name: 'Color Vision Changes', category: 'Eye Symptoms', bodyLocations: ['Eyes'], view: 'front', sideApplicable: true),
  MedicalSymptom(name: 'Distorted Vision (Metamorphopsia)', category: 'Eye Symptoms', bodyLocations: ['Eyes'], view: 'front', sideApplicable: true),
  MedicalSymptom(name: 'Eyelid Swelling', category: 'Eye Symptoms', bodyLocations: ['Eyes'], view: 'front', sideApplicable: true),
  MedicalSymptom(name: 'Eyelid Pain', category: 'Eye Symptoms', bodyLocations: ['Eyes'], view: 'front', sideApplicable: true),
  MedicalSymptom(name: 'Drooping Eyelid (Ptosis)', category: 'Eye Symptoms', bodyLocations: ['Eyes'], view: 'front', sideApplicable: true),
  MedicalSymptom(name: 'Excessive Blinking', category: 'Eye Symptoms', bodyLocations: ['Eyes'], view: 'front', sideApplicable: true),
  MedicalSymptom(name: 'Involuntary Eye Twitching (Blepharospasm)', category: 'Eye Symptoms', bodyLocations: ['Eyes'], view: 'front', sideApplicable: true),
  MedicalSymptom(name: 'Rapid Eye Movement (Nystagmus)', category: 'Eye Symptoms', bodyLocations: ['Eyes'], view: 'front', sideApplicable: true),
  MedicalSymptom(name: 'Excessive Tearing (Epiphora)', category: 'Eye Symptoms', bodyLocations: ['Eyes'], view: 'front', sideApplicable: true),
  MedicalSymptom(name: 'Gritty Eye Feeling', category: 'Eye Symptoms', bodyLocations: ['Eyes'], view: 'front', sideApplicable: true),

  // ==================== 3. EARS / HEARING / BALANCE (20+ symptoms) ====================
  MedicalSymptom(
    name: 'Ear Pain',
    category: 'Ear, Hearing & Balance',
    bodyLocations: ['Ears'],
    view: 'both',
    sideApplicable: true,
    followUpQuestions: {
      'Is there any fluid draining from the ear?': ['Yes', 'No'],
      'Is your hearing reduced?': ['Yes', 'No'],
    },
  ),
  MedicalSymptom(
    name: 'Tinnitus (Ringing in Ears)',
    category: 'Ear, Hearing & Balance',
    bodyLocations: ['Ears'],
    view: 'both',
    sideApplicable: true,
    followUpQuestions: {
      'Is the ringing continuous or constant?': ['Continuous', 'Intermittent'],
      'Is it in one ear or both?': ['One ear', 'Both ears'],
    },
  ),
  MedicalSymptom(
    name: 'Ear Discharge',
    category: 'Ear, Hearing & Balance',
    bodyLocations: ['Ears'],
    view: 'both',
    sideApplicable: true,
    followUpQuestions: {
      'What type of fluid is draining?': ['Clear liquid', 'Pus/Yellow', 'Bloody'],
    },
  ),
  MedicalSymptom(
    name: 'Hearing Loss',
    category: 'Ear, Hearing & Balance',
    bodyLocations: ['Ears'],
    view: 'both',
    sideApplicable: true,
    followUpQuestions: {
      'Was the hearing loss sudden or gradual?': ['Sudden', 'Gradual'],
    },
  ),
  MedicalSymptom(
    name: 'Ear Fullness / Pressure',
    category: 'Ear, Hearing & Balance',
    bodyLocations: ['Ears'],
    view: 'both',
    sideApplicable: true,
    followUpQuestions: {
      'Do you currently have a cold or sinus congestion?': ['Yes', 'No'],
    },
  ),
  MedicalSymptom(
    name: 'Itchy Ears',
    category: 'Ear, Hearing & Balance',
    bodyLocations: ['Ears'],
    view: 'both',
    sideApplicable: true,
    followUpQuestions: {
      'Have you recently used earplugs or swum in water?': ['Yes', 'No'],
    },
  ),
  MedicalSymptom(name: 'Sudden Hearing Loss', category: 'Ear, Hearing & Balance', bodyLocations: ['Ears'], sideApplicable: true),
  MedicalSymptom(name: 'Muffled Hearing', category: 'Ear, Hearing & Balance', bodyLocations: ['Ears'], sideApplicable: true),
  MedicalSymptom(name: 'Sound Sensitivity (Hyperacusis)', category: 'Ear, Hearing & Balance', bodyLocations: ['Ears'], sideApplicable: true),
  MedicalSymptom(name: 'Ear Bleeding', category: 'Ear, Hearing & Balance', bodyLocations: ['Ears'], sideApplicable: true),
  MedicalSymptom(name: 'Ear Popping Sensation', category: 'Ear, Hearing & Balance', bodyLocations: ['Ears'], sideApplicable: true),
  MedicalSymptom(name: 'Ear Canal Swelling', category: 'Ear, Hearing & Balance', bodyLocations: ['Ears'], sideApplicable: true),
  MedicalSymptom(name: 'Ear Wax Blockage (Cerumen Impaction)', category: 'Ear, Hearing & Balance', bodyLocations: ['Ears'], sideApplicable: true),
  MedicalSymptom(name: 'Throbbing Ear Pain', category: 'Ear, Hearing & Balance', bodyLocations: ['Ears'], sideApplicable: true),
  MedicalSymptom(name: 'Fluid Sensation in Eardrum', category: 'Ear, Hearing & Balance', bodyLocations: ['Ears'], sideApplicable: true),
  MedicalSymptom(name: 'Otalgia (Sharp Ear Ache)', category: 'Ear, Hearing & Balance', bodyLocations: ['Ears'], sideApplicable: true),
  MedicalSymptom(name: 'Vestibular Dizziness', category: 'Ear, Hearing & Balance', bodyLocations: ['Ears', 'Head']),
  MedicalSymptom(name: 'Ear Canal Crust / Flaking', category: 'Ear, Hearing & Balance', bodyLocations: ['Ears'], sideApplicable: true),
  MedicalSymptom(name: 'Clicking Noise in Ear', category: 'Ear, Hearing & Balance', bodyLocations: ['Ears'], sideApplicable: true),
  MedicalSymptom(name: 'Pulsatile Tinnitus (Pulse in Ear)', category: 'Ear, Hearing & Balance', bodyLocations: ['Ears'], sideApplicable: true),

  // ==================== 4. NOSE & SINUS (20+ symptoms) ====================
  MedicalSymptom(
    name: 'Runny Nose (Rhinorrhea)',
    category: 'Nose & Sinus',
    bodyLocations: ['Nose'],
    view: 'front',
    followUpQuestions: {
      'Is the discharge clear, yellow, or green?': ['Clear', 'Yellow/Green'],
      'How long has it been present?': ['1-3 days', '4-7 days', 'More than a week'],
    },
  ),
  MedicalSymptom(
    name: 'Nasal Congestion (Stuffy Nose)',
    category: 'Nose & Sinus',
    bodyLocations: ['Nose'],
    view: 'front',
    followUpQuestions: {
      'Does it alternate sides or affect both nostrils?': ['Alternates', 'Both nostrils'],
    },
  ),
  MedicalSymptom(
    name: 'Sneezing',
    category: 'Nose & Sinus',
    bodyLocations: ['Nose'],
    view: 'front',
    followUpQuestions: {
      'Are you experiencing itchy eyes or throat?': ['Yes', 'No'],
    },
  ),
  MedicalSymptom(
    name: 'Loss of Smell (Anosmia)',
    category: 'Nose & Sinus',
    bodyLocations: ['Nose'],
    view: 'front',
    followUpQuestions: {
      'Did loss of taste occur as well?': ['Yes', 'No'],
    },
  ),
  MedicalSymptom(
    name: 'Nosebleed (Epistaxis)',
    category: 'Nose & Sinus',
    bodyLocations: ['Nose'],
    view: 'front',
    sideApplicable: true,
    followUpQuestions: {
      'How often does it occur?': ['First time', 'Occasional', 'Frequent'],
      'Does bleeding stop within 10 minutes?': ['Yes', 'No'],
    },
  ),
  MedicalSymptom(
    name: 'Sinus Pressure & Pain',
    category: 'Nose & Sinus',
    bodyLocations: ['Nose', 'Head'],
    view: 'front',
    followUpQuestions: {
      'Does bending forward worsen facial pressure?': ['Yes', 'No'],
    },
  ),
  MedicalSymptom(name: 'Reduced Sense of Smell (Hyposmia)', category: 'Nose & Sinus', bodyLocations: ['Nose']),
  MedicalSymptom(name: 'Yellow/Green Nasal Discharge', category: 'Nose & Sinus', bodyLocations: ['Nose']),
  MedicalSymptom(name: 'Postnasal Drip', category: 'Nose & Sinus', bodyLocations: ['Nose', 'Neck']),
  MedicalSymptom(name: 'Nasal Dryness', category: 'Nose & Sinus', bodyLocations: ['Nose']),
  MedicalSymptom(name: 'Nasal Itching', category: 'Nose & Sinus', bodyLocations: ['Nose']),
  MedicalSymptom(name: 'Nasal Swelling / Obstruction', category: 'Nose & Sinus', bodyLocations: ['Nose']),
  MedicalSymptom(name: 'Facial Sinus Pressure', category: 'Nose & Sinus', bodyLocations: ['Nose', 'Head']),
  MedicalSymptom(name: 'Difficulty Breathing Through Nose', category: 'Nose & Sinus', bodyLocations: ['Nose']),
  MedicalSymptom(name: 'Altered Sense of Smell (Parosmia)', category: 'Nose & Sinus', bodyLocations: ['Nose']),
  MedicalSymptom(name: 'Sinus Pain Above Eyes (Frontal)', category: 'Nose & Sinus', bodyLocations: ['Nose', 'Head']),
  MedicalSymptom(name: 'Cheek Pressure / Maxillary Sinus Pain', category: 'Nose & Sinus', bodyLocations: ['Nose', 'Head'], sideApplicable: true),
  MedicalSymptom(name: 'Nasal Polyp Pressure', category: 'Nose & Sinus', bodyLocations: ['Nose']),
  MedicalSymptom(name: 'Frequent Sneezing Fits', category: 'Nose & Sinus', bodyLocations: ['Nose']),
  MedicalSymptom(name: 'Nasal Crusts / Scabs', category: 'Nose & Sinus', bodyLocations: ['Nose']),
  MedicalSymptom(name: 'Phantosmia (Phantom Smell)', category: 'Nose & Sinus', bodyLocations: ['Nose']),

  // ==================== 5. MOUTH / TEETH / THROAT (30+ symptoms) ====================
  MedicalSymptom(name: 'Tooth Sensitivity (Hot/Cold)', category: 'Mouth, Teeth & Throat', bodyLocations: ['Mouth', 'Head'], sideApplicable: true),
  MedicalSymptom(name: 'Gum Pain', category: 'Mouth, Teeth & Throat', bodyLocations: ['Mouth'], sideApplicable: true),
  MedicalSymptom(name: 'Gum Bleeding (Gingivitis)', category: 'Mouth, Teeth & Throat', bodyLocations: ['Mouth']),
  MedicalSymptom(name: 'Swollen Gums', category: 'Mouth, Teeth & Throat', bodyLocations: ['Mouth']),
  MedicalSymptom(name: 'Mouth Ulcers / Canker Sores', category: 'Mouth, Teeth & Throat', bodyLocations: ['Mouth']),
  MedicalSymptom(name: 'Dry Mouth (Xerostomia)', category: 'Mouth, Teeth & Throat', bodyLocations: ['Mouth']),
  MedicalSymptom(name: 'Excessive Saliva / Drooling', category: 'Mouth, Teeth & Throat', bodyLocations: ['Mouth']),
  MedicalSymptom(name: 'Bad Breath (Halitosis)', category: 'Mouth, Teeth & Throat', bodyLocations: ['Mouth']),
  MedicalSymptom(name: 'Tongue Pain (Glossodynia)', category: 'Mouth, Teeth & Throat', bodyLocations: ['Mouth']),
  MedicalSymptom(name: 'Tongue Swelling (Glossitis)', category: 'Mouth, Teeth & Throat', bodyLocations: ['Mouth']),
  MedicalSymptom(name: 'Tongue Sores / Lesions', category: 'Mouth, Teeth & Throat', bodyLocations: ['Mouth']),
  MedicalSymptom(name: 'Difficulty Chewing', category: 'Mouth, Teeth & Throat', bodyLocations: ['Mouth', 'Head']),
  MedicalSymptom(name: 'Painful Swallowing (Odynophagia)', category: 'Mouth, Teeth & Throat', bodyLocations: ['Mouth', 'Neck']),
  MedicalSymptom(
    name: 'Sore Throat',
    category: 'Mouth, Teeth & Throat',
    bodyLocations: ['Neck', 'Mouth'],
    view: 'front',
    followUpQuestions: {
      'Is swallowing painful?': ['Severely painful', 'Mildly uncomfortable', 'No'],
      'Are white patches visible on tonsils?': ['Yes', 'No', 'Unsure'],
    },
  ),
  MedicalSymptom(name: 'Throat Irritation / Tickle', category: 'Mouth, Teeth & Throat', bodyLocations: ['Neck', 'Mouth']),
  MedicalSymptom(name: 'Throat Swelling', category: 'Mouth, Teeth & Throat', bodyLocations: ['Neck', 'Mouth']),
  MedicalSymptom(
    name: 'Hoarseness / Voice Loss',
    category: 'Mouth, Teeth & Throat',
    bodyLocations: ['Neck', 'Mouth'],
    view: 'front',
    followUpQuestions: {
      'How long have you been hoarse?': ['A few days', 'Over 2 weeks'],
    },
  ),
  MedicalSymptom(name: 'Lump in Throat (Globus Sensation)', category: 'Mouth, Teeth & Throat', bodyLocations: ['Neck', 'Mouth']),
  MedicalSymptom(name: 'Burning Mouth Sensation', category: 'Mouth, Teeth & Throat', bodyLocations: ['Mouth']),
  MedicalSymptom(name: 'White Patches on Tongue (Oral Thrush)', category: 'Mouth, Teeth & Throat', bodyLocations: ['Mouth']),
  MedicalSymptom(name: 'Metallic Taste in Mouth', category: 'Mouth, Teeth & Throat', bodyLocations: ['Mouth']),
  MedicalSymptom(name: 'Loss of Taste (Ageusia)', category: 'Mouth, Teeth & Throat', bodyLocations: ['Mouth']),
  MedicalSymptom(name: 'Altered Taste (Dysgeusia)', category: 'Mouth, Teeth & Throat', bodyLocations: ['Mouth']),
  MedicalSymptom(name: 'Chapped / Cracked Lips', category: 'Mouth, Teeth & Throat', bodyLocations: ['Mouth']),
  MedicalSymptom(name: 'Mouth Corner Cracks (Angular Cheilitis)', category: 'Mouth, Teeth & Throat', bodyLocations: ['Mouth']),
  MedicalSymptom(name: 'Tonsil Swelling', category: 'Mouth, Teeth & Throat', bodyLocations: ['Neck', 'Mouth']),
  MedicalSymptom(name: 'Tonsil White Pus Spots', category: 'Mouth, Teeth & Throat', bodyLocations: ['Neck', 'Mouth']),
  MedicalSymptom(name: 'Roof of Mouth Soreness', category: 'Mouth, Teeth & Throat', bodyLocations: ['Mouth']),
  MedicalSymptom(name: 'Jaw Stiffness / Lockjaw', category: 'Mouth, Teeth & Throat', bodyLocations: ['Mouth', 'Head']),

  // ==================== 6. NECK (15+ symptoms) ====================
  MedicalSymptom(
    name: 'Neck Pain',
    category: 'Neck Symptoms',
    bodyLocations: ['Neck'],
    view: 'both',
    sideApplicable: true,
    followUpQuestions: {
      'Does it limit your neck movement?': ['Yes, severely', 'Mildly', 'No'],
      'Does pain radiate into your arms or shoulders?': ['Yes', 'No'],
    },
  ),
  MedicalSymptom(
    name: 'Difficulty Swallowing (Dysphagia)',
    category: 'Neck Symptoms',
    bodyLocations: ['Neck', 'Mouth'],
    view: 'front',
    followUpQuestions: {
      'Is difficulty with solids, liquids, or both?': ['Solids only', 'Liquids only', 'Both'],
    },
  ),
  MedicalSymptom(
    name: 'Swollen Lymph Nodes',
    category: 'Neck Symptoms',
    bodyLocations: ['Neck'],
    view: 'both',
    sideApplicable: true,
    followUpQuestions: {
      'Are the lumps tender to touch?': ['Tender', 'Not tender'],
    },
  ),
  MedicalSymptom(name: 'Neck Stiffness (Nuchal Rigidity)', category: 'Neck Symptoms', bodyLocations: ['Neck']),
  MedicalSymptom(name: 'Neck Swelling', category: 'Neck Symptoms', bodyLocations: ['Neck']),
  MedicalSymptom(name: 'Neck Muscle Spasm', category: 'Neck Symptoms', bodyLocations: ['Neck'], sideApplicable: true),
  MedicalSymptom(name: 'Reduced Neck Range of Motion', category: 'Neck Symptoms', bodyLocations: ['Neck']),
  MedicalSymptom(name: 'Neck Tenderness to Touch', category: 'Neck Symptoms', bodyLocations: ['Neck'], sideApplicable: true),
  MedicalSymptom(name: 'Neck Pressure Sensation', category: 'Neck Symptoms', bodyLocations: ['Neck']),
  MedicalSymptom(name: 'Neck Mass / Lump', category: 'Neck Symptoms', bodyLocations: ['Neck'], sideApplicable: true),
  MedicalSymptom(name: 'Pain Radiating from Neck to Shoulder', category: 'Neck Symptoms', bodyLocations: ['Neck', 'Shoulders'], sideApplicable: true),
  MedicalSymptom(name: 'Pain Radiating from Neck to Arm', category: 'Neck Symptoms', bodyLocations: ['Neck', 'Arms'], sideApplicable: true),
  MedicalSymptom(name: 'Throbbing Neck Artery Pain', category: 'Neck Symptoms', bodyLocations: ['Neck'], sideApplicable: true),
  MedicalSymptom(name: 'Neck Clicking / Grating Sensation', category: 'Neck Symptoms', bodyLocations: ['Neck']),
  MedicalSymptom(name: 'Thyroid Area Swelling / Goiter', category: 'Neck Symptoms', bodyLocations: ['Neck']),
  MedicalSymptom(name: 'Carotid Artery Tenderness', category: 'Neck Symptoms', bodyLocations: ['Neck'], sideApplicable: true),
  MedicalSymptom(name: 'Whiplash Pain', category: 'Neck Symptoms', bodyLocations: ['Neck']),

  // ==================== 7. CHEST / RESPIRATORY / LUNGS (35+ symptoms) ====================
  MedicalSymptom(
    name: 'Chest Pain',
    category: 'Respiratory & Lung Symptoms',
    bodyLocations: ['Chest'],
    view: 'front',
    sideApplicable: true,
    followUpQuestions: {
      'Describe the sensation:': ['Pressure/Squeezing', 'Sharp/Stabbing', 'Burning', 'Aching'],
      'Does the pain radiate anywhere?': ['Left Arm', 'Neck/Jaw', 'Back', 'No radiation'],
      'Does it worsen with deep breathing or coughing?': ['Yes', 'No'],
    },
  ),
  MedicalSymptom(
    name: 'Chest Tightness',
    category: 'Respiratory & Lung Symptoms',
    bodyLocations: ['Chest'],
    view: 'front',
    followUpQuestions: {
      'Is it triggered by exercise, cold air, or allergens?': ['Yes', 'No'],
    },
  ),
  MedicalSymptom(
    name: 'Cough',
    category: 'Respiratory & Lung Symptoms',
    bodyLocations: ['Chest', 'Neck'],
    view: 'front',
    followUpQuestions: {
      'Is the cough dry or productive?': ['Dry', 'Wet (produces mucus)'],
      'Have you noticed blood in your mucus?': ['Yes', 'No'],
      'Is the cough worse at night?': ['Yes', 'No'],
    },
  ),
  MedicalSymptom(
    name: 'Shortness of Breath',
    category: 'Respiratory & Lung Symptoms',
    bodyLocations: ['Chest'],
    view: 'front',
    followUpQuestions: {
      'When does it occur?': ['At rest', 'During mild exertion', 'During heavy exercise'],
      'Does it get worse when lying flat?': ['Yes', 'No'],
    },
  ),
  MedicalSymptom(
    name: 'Wheezing',
    category: 'Respiratory & Lung Symptoms',
    bodyLocations: ['Chest'],
    view: 'front',
    followUpQuestions: {
      'Is it accompanied by a tight chest feeling?': ['Yes', 'No'],
      'Do you have a history of asthma or allergies?': ['Yes', 'No'],
    },
  ),
  MedicalSymptom(name: 'Dry Cough', category: 'Respiratory & Lung Symptoms', bodyLocations: ['Chest']),
  MedicalSymptom(name: 'Wet / Productive Cough', category: 'Respiratory & Lung Symptoms', bodyLocations: ['Chest']),
  MedicalSymptom(name: 'Persistent Chronic Cough', category: 'Respiratory & Lung Symptoms', bodyLocations: ['Chest']),
  MedicalSymptom(name: 'Noisy Breathing (Stridor)', category: 'Respiratory & Lung Symptoms', bodyLocations: ['Chest', 'Neck']),
  MedicalSymptom(name: 'Coughing up Blood (Hemoptysis)', category: 'Respiratory & Lung Symptoms', bodyLocations: ['Chest']),
  MedicalSymptom(name: 'Blood-Stained Mucus / Sputum', category: 'Respiratory & Lung Symptoms', bodyLocations: ['Chest']),
  MedicalSymptom(name: 'Excess Phlegm / Mucus Production', category: 'Respiratory & Lung Symptoms', bodyLocations: ['Chest']),
  MedicalSymptom(name: 'Chest Congestion', category: 'Respiratory & Lung Symptoms', bodyLocations: ['Chest']),
  MedicalSymptom(name: 'Pain While Breathing (Pleuritic Pain)', category: 'Respiratory & Lung Symptoms', bodyLocations: ['Chest'], sideApplicable: true),
  MedicalSymptom(name: 'Pain While Coughing', category: 'Respiratory & Lung Symptoms', bodyLocations: ['Chest']),
  MedicalSymptom(name: 'Breathlessness During Exercise (Exertional Dyspnea)', category: 'Respiratory & Lung Symptoms', bodyLocations: ['Chest']),
  MedicalSymptom(name: 'Breathlessness While Lying Down (Orthopnea)', category: 'Respiratory & Lung Symptoms', bodyLocations: ['Chest']),
  MedicalSymptom(name: 'Night Breathing Difficulty (PND)', category: 'Respiratory & Lung Symptoms', bodyLocations: ['Chest']),
  MedicalSymptom(name: 'Rapid Breathing (Tachypnea)', category: 'Respiratory & Lung Symptoms', bodyLocations: ['Chest']),
  MedicalSymptom(name: 'Slow Breathing (Bradypnea)', category: 'Respiratory & Lung Symptoms', bodyLocations: ['Chest']),
  MedicalSymptom(name: 'Shallow Breathing', category: 'Respiratory & Lung Symptoms', bodyLocations: ['Chest']),
  MedicalSymptom(name: 'Deep Chest Ache', category: 'Respiratory & Lung Symptoms', bodyLocations: ['Chest']),
  MedicalSymptom(name: 'Rib Pain', category: 'Respiratory & Lung Symptoms', bodyLocations: ['Chest'], sideApplicable: true),
  MedicalSymptom(name: 'Intercostal Muscle Strain Pain', category: 'Respiratory & Lung Symptoms', bodyLocations: ['Chest'], sideApplicable: true),
  MedicalSymptom(name: 'Sensation of Fluid in Lungs', category: 'Respiratory & Lung Symptoms', bodyLocations: ['Chest']),
  MedicalSymptom(name: 'Heavy Breathing', category: 'Respiratory & Lung Symptoms', bodyLocations: ['Chest']),
  MedicalSymptom(name: 'Gasping for Air', category: 'Respiratory & Lung Symptoms', bodyLocations: ['Chest']),
  MedicalSymptom(name: 'Barking Cough (Croup-like)', category: 'Respiratory & Lung Symptoms', bodyLocations: ['Chest', 'Neck']),
  MedicalSymptom(name: 'Spasmodic Coughing Fits', category: 'Respiratory & Lung Symptoms', bodyLocations: ['Chest']),
  MedicalSymptom(name: 'Chest Wall Tenderness', category: 'Respiratory & Lung Symptoms', bodyLocations: ['Chest'], sideApplicable: true),
  MedicalSymptom(name: 'Burning Sensation in Chest', category: 'Respiratory & Lung Symptoms', bodyLocations: ['Chest']),
  MedicalSymptom(name: 'Rattling Sound in Chest', category: 'Respiratory & Lung Symptoms', bodyLocations: ['Chest']),
  MedicalSymptom(name: 'Frequent Deep Sighing', category: 'Respiratory & Lung Symptoms', bodyLocations: ['Chest']),
  MedicalSymptom(name: 'Inability to Take a Deep Breath', category: 'Respiratory & Lung Symptoms', bodyLocations: ['Chest']),

  // ==================== 8. HEART / CIRCULATION (25+ symptoms) ====================
  MedicalSymptom(
    name: 'Palpitations',
    category: 'Heart & Circulatory Symptoms',
    bodyLocations: ['Chest'],
    view: 'front',
    followUpQuestions: {
      'How do the palpitations feel?': ['Fluttering', 'Pounding/Hard beating', 'Skipped beats'],
      'Are they accompanied by dizziness or chest discomfort?': ['Yes', 'No'],
    },
  ),
  MedicalSymptom(
    name: 'Rapid Heartbeat (Tachycardia)',
    category: 'Heart & Circulatory Symptoms',
    bodyLocations: ['Chest'],
    view: 'front',
    followUpQuestions: {
      'Did it start suddenly while resting?': ['Yes', 'No'],
    },
  ),
  MedicalSymptom(name: 'Slow Heartbeat (Bradycardia)', category: 'Heart & Circulatory Symptoms', bodyLocations: ['Chest']),
  MedicalSymptom(name: 'Irregular Heartbeat (Arrhythmia)', category: 'Heart & Circulatory Symptoms', bodyLocations: ['Chest']),
  MedicalSymptom(name: 'Chest Pressure Sensation', category: 'Heart & Circulatory Symptoms', bodyLocations: ['Chest']),
  MedicalSymptom(name: 'Chest Heaviness', category: 'Heart & Circulatory Symptoms', bodyLocations: ['Chest']),
  MedicalSymptom(name: 'Heart Racing at Rest', category: 'Heart & Circulatory Symptoms', bodyLocations: ['Chest']),
  MedicalSymptom(name: 'Cardiac Fainting (Syncope)', category: 'Heart & Circulatory Symptoms', bodyLocations: ['Chest', 'Head']),
  MedicalSymptom(name: 'Postural Hypotension (Dizziness Standing)', category: 'Heart & Circulatory Symptoms', bodyLocations: ['Chest', 'Head']),
  MedicalSymptom(name: 'Cold Extremities (Cold Hands/Feet)', category: 'Heart & Circulatory Symptoms', bodyLocations: ['Hands', 'Feet']),
  MedicalSymptom(name: 'Swollen Ankles', category: 'Heart & Circulatory Symptoms', bodyLocations: ['Feet', 'Legs'], sideApplicable: true),
  MedicalSymptom(name: 'Leg Swelling (Lower Limb Edema)', category: 'Heart & Circulatory Symptoms', bodyLocations: ['Legs'], sideApplicable: true),
  MedicalSymptom(name: 'Poor Blood Circulation', category: 'Heart & Circulatory Symptoms', bodyLocations: ['Arms', 'Legs']),
  MedicalSymptom(name: 'Bluish Lips (Cyanosis)', category: 'Heart & Circulatory Symptoms', bodyLocations: ['Mouth', 'Head']),
  MedicalSymptom(name: 'Bluish Fingers / Fingernails', category: 'Heart & Circulatory Symptoms', bodyLocations: ['Hands'], sideApplicable: true),
  MedicalSymptom(name: 'Exercise Intolerance', category: 'Heart & Circulatory Symptoms', bodyLocations: ['Chest', 'Legs']),
  MedicalSymptom(name: 'Sudden Weakness with Heart Flutter', category: 'Heart & Circulatory Symptoms', bodyLocations: ['Chest', 'Head']),
  MedicalSymptom(name: 'Fluttering Sensation in Chest', category: 'Heart & Circulatory Symptoms', bodyLocations: ['Chest']),
  MedicalSymptom(name: 'Skipped Heartbeats', category: 'Heart & Circulatory Symptoms', bodyLocations: ['Chest']),
  MedicalSymptom(name: 'Throbbing Neck Artery Pulse', category: 'Heart & Circulatory Symptoms', bodyLocations: ['Neck', 'Chest'], sideApplicable: true),
  MedicalSymptom(name: 'High Blood Pressure Spikes', category: 'Heart & Circulatory Symptoms', bodyLocations: ['Head', 'Chest']),
  MedicalSymptom(name: 'Low Blood Pressure Dizziness', category: 'Heart & Circulatory Symptoms', bodyLocations: ['Head', 'Chest']),
  MedicalSymptom(name: 'Cold Sweats with Chest Discomfort', category: 'Heart & Circulatory Symptoms', bodyLocations: ['Chest', 'Head']),
  MedicalSymptom(name: 'Heavy Feeling in Heart Region', category: 'Heart & Circulatory Symptoms', bodyLocations: ['Chest']),
  MedicalSymptom(name: 'Calf Pain While Walking (Claudication)', category: 'Heart & Circulatory Symptoms', bodyLocations: ['Legs'], sideApplicable: true),

  // ==================== 9. ABDOMEN / DIGESTIVE SYSTEM (40+ symptoms) ====================
  MedicalSymptom(
    name: 'Stomach Pain',
    category: 'Digestive & Abdominal',
    bodyLocations: ['Abdomen'],
    view: 'front',
    followUpQuestions: {
      'Where is the pain located?': ['Upper Abdomen', 'Lower Abdomen', 'Around Navel', 'All over'],
      'Is it worse before or after eating?': ['Before eating', 'After eating', 'No change'],
    },
  ),
  MedicalSymptom(
    name: 'Stomach Bloating',
    category: 'Digestive & Abdominal',
    bodyLocations: ['Abdomen'],
    view: 'front',
    followUpQuestions: {
      'Is the bloating constant or does it come and go?': ['Constant', 'Comes and goes'],
      'Is it associated with specific foods?': ['Yes', 'No'],
    },
  ),
  MedicalSymptom(
    name: 'Stomach Cramps',
    category: 'Digestive & Abdominal',
    bodyLocations: ['Abdomen'],
    view: 'front',
    followUpQuestions: {
      'Are the cramps relieved by bowel movements?': ['Yes', 'No'],
    },
  ),
  MedicalSymptom(
    name: 'Nausea',
    category: 'Digestive & Abdominal',
    bodyLocations: ['Abdomen', 'Head'],
    view: 'front',
    followUpQuestions: {
      'Have you vomited?': ['Yes', 'No'],
    },
  ),
  MedicalSymptom(
    name: 'Vomiting',
    category: 'Digestive & Abdominal',
    bodyLocations: ['Abdomen'],
    view: 'front',
    followUpQuestions: {
      'How many times in the last 24 hours?': ['1-2 times', '3-5 times', 'More than 5 times'],
      'Are you able to keep fluids down?': ['Yes', 'No'],
    },
  ),
  MedicalSymptom(
    name: 'Diarrhea',
    category: 'Digestive & Abdominal',
    bodyLocations: ['Abdomen'],
    view: 'front',
    followUpQuestions: {
      'How many watery stools per day?': ['1-3 times', '4-6 times', '7+ times'],
      'Is there fever or severe abdominal pain?': ['Yes', 'No'],
    },
  ),
  MedicalSymptom(
    name: 'Constipation',
    category: 'Digestive & Abdominal',
    bodyLocations: ['Abdomen'],
    view: 'front',
    followUpQuestions: {
      'How many days since last bowel movement?': ['2-3 days', '4-6 days', '7+ days'],
    },
  ),
  MedicalSymptom(
    name: 'Heartburn / Acid Reflux',
    category: 'Digestive & Abdominal',
    bodyLocations: ['Abdomen', 'Chest'],
    view: 'front',
    followUpQuestions: {
      'Is burning worse when lying down after meals?': ['Yes', 'No'],
    },
  ),
  MedicalSymptom(
    name: 'Indigestion / Dyspepsia',
    category: 'Digestive & Abdominal',
    bodyLocations: ['Abdomen'],
    view: 'front',
    followUpQuestions: {
      'Do you experience early fullness during meals?': ['Yes', 'No'],
    },
  ),
  MedicalSymptom(
    name: 'Loss of Appetite',
    category: 'Digestive & Abdominal',
    bodyLocations: ['Abdomen'],
    view: 'front',
    followUpQuestions: {
      'Have you lost weight unintentionally?': ['Yes', 'No'],
    },
  ),
  MedicalSymptom(name: 'Upper Abdominal Pain', category: 'Digestive & Abdominal', bodyLocations: ['Abdomen']),
  MedicalSymptom(name: 'Lower Abdominal Pain', category: 'Digestive & Abdominal', bodyLocations: ['Abdomen']),
  MedicalSymptom(name: 'Right Upper Quadrant Abdominal Pain', category: 'Digestive & Abdominal', bodyLocations: ['Abdomen'], sideApplicable: true),
  MedicalSymptom(name: 'Left Upper Quadrant Abdominal Pain', category: 'Digestive & Abdominal', bodyLocations: ['Abdomen'], sideApplicable: true),
  MedicalSymptom(name: 'Right Lower Quadrant Abdominal Pain (Appendicitis Risk)', category: 'Digestive & Abdominal', bodyLocations: ['Abdomen'], sideApplicable: true),
  MedicalSymptom(name: 'Left Lower Quadrant Abdominal Pain', category: 'Digestive & Abdominal', bodyLocations: ['Abdomen'], sideApplicable: true),
  MedicalSymptom(name: 'Central Abdominal / Navel Pain', category: 'Digestive & Abdominal', bodyLocations: ['Abdomen']),
  MedicalSymptom(name: 'Abdominal Swelling / Distension', category: 'Digestive & Abdominal', bodyLocations: ['Abdomen']),
  MedicalSymptom(name: 'Blood in Vomit (Hematemesis)', category: 'Digestive & Abdominal', bodyLocations: ['Abdomen']),
  MedicalSymptom(name: 'Loose Stools', category: 'Digestive & Abdominal', bodyLocations: ['Abdomen']),
  MedicalSymptom(name: 'Hard / Impacted Stools', category: 'Digestive & Abdominal', bodyLocations: ['Abdomen']),
  MedicalSymptom(name: 'Bright Red Blood in Stool', category: 'Digestive & Abdominal', bodyLocations: ['Abdomen']),
  MedicalSymptom(name: 'Black Tarry Stool (Melena)', category: 'Digestive & Abdominal', bodyLocations: ['Abdomen']),
  MedicalSymptom(name: 'Mucus in Stool', category: 'Digestive & Abdominal', bodyLocations: ['Abdomen']),
  MedicalSymptom(name: 'Increased Appetite (Hyperphagia)', category: 'Digestive & Abdominal', bodyLocations: ['Abdomen']),
  MedicalSymptom(name: 'Early Fullness During Meals (Early Satiety)', category: 'Digestive & Abdominal', bodyLocations: ['Abdomen']),
  MedicalSymptom(name: 'Excessive Gas / Flatulence', category: 'Digestive & Abdominal', bodyLocations: ['Abdomen']),
  MedicalSymptom(name: 'Belching / Burping', category: 'Digestive & Abdominal', bodyLocations: ['Abdomen']),
  MedicalSymptom(name: 'Difficulty Digesting Food', category: 'Digestive & Abdominal', bodyLocations: ['Abdomen']),
  MedicalSymptom(name: 'Abdominal Tenderness', category: 'Digestive & Abdominal', bodyLocations: ['Abdomen']),
  MedicalSymptom(name: 'Abdominal Fullness', category: 'Digestive & Abdominal', bodyLocations: ['Abdomen']),
  MedicalSymptom(name: 'Loud Gurgling Stomach Sounds', category: 'Digestive & Abdominal', bodyLocations: ['Abdomen']),
  MedicalSymptom(name: 'Acid Regurgitation', category: 'Digestive & Abdominal', bodyLocations: ['Abdomen', 'Chest']),
  MedicalSymptom(name: 'Stomach Burning Sensation', category: 'Digestive & Abdominal', bodyLocations: ['Abdomen']),
  MedicalSymptom(name: 'Stomach Spasms', category: 'Digestive & Abdominal', bodyLocations: ['Abdomen']),
  MedicalSymptom(name: 'Pain After Meals', category: 'Digestive & Abdominal', bodyLocations: ['Abdomen']),
  MedicalSymptom(name: 'Pain on Empty Stomach', category: 'Digestive & Abdominal', bodyLocations: ['Abdomen']),
  MedicalSymptom(name: 'Rectal Pain', category: 'Digestive & Abdominal', bodyLocations: ['Abdomen']),
  MedicalSymptom(name: 'Rectal Bleeding', category: 'Digestive & Abdominal', bodyLocations: ['Abdomen']),
  MedicalSymptom(name: 'Anal Itching (Pruritus Ani)', category: 'Digestive & Abdominal', bodyLocations: ['Abdomen']),
  MedicalSymptom(name: 'Incontinence of Stool', category: 'Digestive & Abdominal', bodyLocations: ['Abdomen']),
  MedicalSymptom(name: 'Tenesmus (Rectal Cramping)', category: 'Digestive & Abdominal', bodyLocations: ['Abdomen']),

  // ==================== 10. LIVER / GALLBLADDER / PANCREAS (15+ symptoms) ====================
  MedicalSymptom(name: 'Jaundice (Yellowing Skin)', category: 'Liver, Gallbladder & Pancreas', bodyLocations: ['Abdomen', 'Head']),
  MedicalSymptom(name: 'Yellow Eyes (Scleral Icterus)', category: 'Liver, Gallbladder & Pancreas', bodyLocations: ['Eyes', 'Head']),
  MedicalSymptom(name: 'Dark Tea-Colored Urine', category: 'Liver, Gallbladder & Pancreas', bodyLocations: ['Abdomen']),
  MedicalSymptom(name: 'Pale Clay-Colored Stool', category: 'Liver, Gallbladder & Pancreas', bodyLocations: ['Abdomen']),
  MedicalSymptom(name: 'Right Upper Abdominal Gallbladder Pain', category: 'Liver, Gallbladder & Pancreas', bodyLocations: ['Abdomen'], sideApplicable: true),
  MedicalSymptom(name: 'Severe Epigastric Pain Radiating to Back', category: 'Liver, Gallbladder & Pancreas', bodyLocations: ['Abdomen', 'Back']),
  MedicalSymptom(name: 'Persistent Nausea After Fatty Meals', category: 'Liver, Gallbladder & Pancreas', bodyLocations: ['Abdomen']),
  MedicalSymptom(name: 'Gallbladder Attack Pain', category: 'Liver, Gallbladder & Pancreas', bodyLocations: ['Abdomen'], sideApplicable: true),
  MedicalSymptom(name: 'Unexplained Severe Body Itching', category: 'Liver, Gallbladder & Pancreas', bodyLocations: ['Abdomen']),
  MedicalSymptom(name: 'Easy Bruising & Bleeding', category: 'Liver, Gallbladder & Pancreas', bodyLocations: ['Abdomen', 'Arms', 'Legs']),
  MedicalSymptom(name: 'Abdominal Fluid Accumulation (Ascites)', category: 'Liver, Gallbladder & Pancreas', bodyLocations: ['Abdomen']),
  MedicalSymptom(name: 'Fatty Meal Intolerance', category: 'Liver, Gallbladder & Pancreas', bodyLocations: ['Abdomen']),
  MedicalSymptom(name: 'Liver Area Tenderness', category: 'Liver, Gallbladder & Pancreas', bodyLocations: ['Abdomen'], sideApplicable: true),
  MedicalSymptom(name: 'Enlarged Abdominal Veins (Caput Medusae)', category: 'Liver, Gallbladder & Pancreas', bodyLocations: ['Abdomen']),
  MedicalSymptom(name: 'Spider Angiomas on Skin', category: 'Liver, Gallbladder & Pancreas', bodyLocations: ['Abdomen', 'Chest']),
  MedicalSymptom(name: 'Palmar Erythema (Red Palms)', category: 'Liver, Gallbladder & Pancreas', bodyLocations: ['Hands']),

  // ==================== 11. KIDNEY / URINARY SYSTEM (25+ symptoms) ====================
  MedicalSymptom(name: 'Painful Urination (Dysuria)', category: 'Kidney & Urinary Symptoms', bodyLocations: ['Abdomen']),
  MedicalSymptom(name: 'Burning Sensation During Urination', category: 'Kidney & Urinary Symptoms', bodyLocations: ['Abdomen']),
  MedicalSymptom(name: 'Frequent Urination (Frequency)', category: 'Kidney & Urinary Symptoms', bodyLocations: ['Abdomen']),
  MedicalSymptom(name: 'Urgent Need to Urinate (Urgency)', category: 'Kidney & Urinary Symptoms', bodyLocations: ['Abdomen']),
  MedicalSymptom(name: 'Difficulty Urinating (Hesitancy)', category: 'Kidney & Urinary Symptoms', bodyLocations: ['Abdomen']),
  MedicalSymptom(name: 'Reduced Urine Output (Oliguria)', category: 'Kidney & Urinary Symptoms', bodyLocations: ['Abdomen']),
  MedicalSymptom(name: 'Increased Urine Output (Polyuria)', category: 'Kidney & Urinary Symptoms', bodyLocations: ['Abdomen']),
  MedicalSymptom(name: 'Blood in Urine (Hematuria)', category: 'Kidney & Urinary Symptoms', bodyLocations: ['Abdomen']),
  MedicalSymptom(name: 'Cloudy Urine', category: 'Kidney & Urinary Symptoms', bodyLocations: ['Abdomen']),
  MedicalSymptom(name: 'Dark Colored Urine', category: 'Kidney & Urinary Symptoms', bodyLocations: ['Abdomen']),
  MedicalSymptom(name: 'Foul-Smelling Urine', category: 'Kidney & Urinary Symptoms', bodyLocations: ['Abdomen']),
  MedicalSymptom(name: 'Urinary Leakage / Incontinence', category: 'Kidney & Urinary Symptoms', bodyLocations: ['Abdomen']),
  MedicalSymptom(name: 'Inability to Control Urine', category: 'Kidney & Urinary Symptoms', bodyLocations: ['Abdomen']),
  MedicalSymptom(name: 'Lower Abdominal Bladder Pain', category: 'Kidney & Urinary Symptoms', bodyLocations: ['Abdomen']),
  MedicalSymptom(name: 'Flank Pain (Side Back Pain)', category: 'Kidney & Urinary Symptoms', bodyLocations: ['Back', 'Abdomen'], sideApplicable: true),
  MedicalSymptom(name: 'Kidney Area Tenderness (CVA Pain)', category: 'Kidney & Urinary Symptoms', bodyLocations: ['Back', 'Abdomen'], sideApplicable: true),
  MedicalSymptom(name: 'Difficulty Starting Urine Flow', category: 'Kidney & Urinary Symptoms', bodyLocations: ['Abdomen']),
  MedicalSymptom(name: 'Weak Urine Stream', category: 'Kidney & Urinary Symptoms', bodyLocations: ['Abdomen']),
  MedicalSymptom(name: 'Nighttime Urination (Nocturia)', category: 'Kidney & Urinary Symptoms', bodyLocations: ['Abdomen']),
  MedicalSymptom(name: 'Dribbling After Urination', category: 'Kidney & Urinary Symptoms', bodyLocations: ['Abdomen']),
  MedicalSymptom(name: 'Feeling of Incomplete Bladder Emptying', category: 'Kidney & Urinary Symptoms', bodyLocations: ['Abdomen']),
  MedicalSymptom(name: 'Kidney Stone Colic (Spasmodic Pain)', category: 'Kidney & Urinary Symptoms', bodyLocations: ['Back', 'Abdomen'], sideApplicable: true),
  MedicalSymptom(name: 'Severe Spasmodic Flank Pain', category: 'Kidney & Urinary Symptoms', bodyLocations: ['Back', 'Abdomen'], sideApplicable: true),
  MedicalSymptom(name: 'Foamy / Frothy Urine', category: 'Kidney & Urinary Symptoms', bodyLocations: ['Abdomen']),
  MedicalSymptom(name: 'Urethral Burning Sensation', category: 'Kidney & Urinary Symptoms', bodyLocations: ['Abdomen']),
  MedicalSymptom(name: 'Pelvic Pressure & Bladder Spasm', category: 'Kidney & Urinary Symptoms', bodyLocations: ['Abdomen']),

  // ==================== 12. ARMS / SHOULDERS / ELBOWS / WRISTS (25+ symptoms) ====================
  MedicalSymptom(
    name: 'Arm Pain',
    category: 'Arm & Shoulder Symptoms',
    bodyLocations: ['Arms'],
    view: 'both',
    sideApplicable: true,
    followUpQuestions: {
      'Which arm is affected?': ['Left Arm', 'Right Arm', 'Both Arms'],
      'Is the pain accompanied by chest pressure?': ['Yes', 'No'],
    },
  ),
  MedicalSymptom(
    name: 'Numbness / Tingling in Arm',
    category: 'Arm & Shoulder Symptoms',
    bodyLocations: ['Arms'],
    view: 'both',
    sideApplicable: true,
    followUpQuestions: {
      'Is it constant or triggered by position?': ['Constant', 'Triggered by position'],
    },
  ),
  MedicalSymptom(
    name: 'Arm Weakness',
    category: 'Arm & Shoulder Symptoms',
    bodyLocations: ['Arms'],
    view: 'both',
    sideApplicable: true,
    followUpQuestions: {
      'Is the weakness in one arm or both?': ['One arm', 'Both arms'],
      'Did it start suddenly?': ['Yes', 'No'],
    },
  ),
  MedicalSymptom(
    name: 'Elbow / Wrist Joint Pain',
    category: 'Arm & Shoulder Symptoms',
    bodyLocations: ['Arms', 'Elbows'],
    view: 'both',
    sideApplicable: true,
    followUpQuestions: {
      'Is there joint swelling or redness?': ['Yes', 'No'],
    },
  ),
  MedicalSymptom(
    name: 'Tremors / Hand Shaking',
    category: 'Arm & Shoulder Symptoms',
    bodyLocations: ['Arms', 'Hands'],
    view: 'both',
    sideApplicable: true,
    followUpQuestions: {
      'Do tremors occur at rest or during movement?': ['At rest', 'During movement'],
    },
  ),
  MedicalSymptom(name: 'Shoulder Pain', category: 'Arm & Shoulder Symptoms', bodyLocations: ['Shoulders', 'Arms'], sideApplicable: true),
  MedicalSymptom(name: 'Shoulder Stiffness / Frozen Shoulder', category: 'Arm & Shoulder Symptoms', bodyLocations: ['Shoulders'], sideApplicable: true),
  MedicalSymptom(name: 'Shoulder Swelling', category: 'Arm & Shoulder Symptoms', bodyLocations: ['Shoulders'], sideApplicable: true),
  MedicalSymptom(name: 'Shoulder Weakness', category: 'Arm & Shoulder Symptoms', bodyLocations: ['Shoulders'], sideApplicable: true),
  MedicalSymptom(name: 'Upper Arm Pain', category: 'Arm & Shoulder Symptoms', bodyLocations: ['Arms'], sideApplicable: true),
  MedicalSymptom(name: 'Forearm Pain', category: 'Arm & Shoulder Symptoms', bodyLocations: ['Arms'], sideApplicable: true),
  MedicalSymptom(name: 'Elbow Pain', category: 'Arm & Shoulder Symptoms', bodyLocations: ['Elbows', 'Arms'], sideApplicable: true),
  MedicalSymptom(name: 'Elbow Swelling', category: 'Arm & Shoulder Symptoms', bodyLocations: ['Elbows', 'Arms'], sideApplicable: true),
  MedicalSymptom(name: 'Wrist Pain', category: 'Arm & Shoulder Symptoms', bodyLocations: ['Arms', 'Hands'], sideApplicable: true),
  MedicalSymptom(name: 'Wrist Swelling', category: 'Arm & Shoulder Symptoms', bodyLocations: ['Arms', 'Hands'], sideApplicable: true),
  MedicalSymptom(name: 'Arm Joint Stiffness', category: 'Arm & Shoulder Symptoms', bodyLocations: ['Arms'], sideApplicable: true),
  MedicalSymptom(name: 'Arm Muscle Cramps', category: 'Arm & Shoulder Symptoms', bodyLocations: ['Arms'], sideApplicable: true),
  MedicalSymptom(name: 'Arm Muscle Spasms', category: 'Arm & Shoulder Symptoms', bodyLocations: ['Arms'], sideApplicable: true),
  MedicalSymptom(name: 'Reduced Arm Range of Motion', category: 'Arm & Shoulder Symptoms', bodyLocations: ['Arms'], sideApplicable: true),
  MedicalSymptom(name: 'Shoulder Popping / Clicking', category: 'Arm & Shoulder Symptoms', bodyLocations: ['Shoulders'], sideApplicable: true),
  MedicalSymptom(name: 'Biceps Tendon Tenderness', category: 'Arm & Shoulder Symptoms', bodyLocations: ['Arms'], sideApplicable: true),
  MedicalSymptom(name: 'Rotator Cuff Pain', category: 'Arm & Shoulder Symptoms', bodyLocations: ['Shoulders'], sideApplicable: true),
  MedicalSymptom(name: 'Tennis Elbow Pain (Lateral)', category: 'Arm & Shoulder Symptoms', bodyLocations: ['Elbows', 'Arms'], sideApplicable: true),
  MedicalSymptom(name: 'Golfer Elbow Pain (Medial)', category: 'Arm & Shoulder Symptoms', bodyLocations: ['Elbows', 'Arms'], sideApplicable: true),
  MedicalSymptom(name: 'Heavy Sensation in Arms', category: 'Arm & Shoulder Symptoms', bodyLocations: ['Arms'], sideApplicable: true),

  // ==================== 13. HANDS / FINGERS (20+ symptoms) ====================
  MedicalSymptom(
    name: 'Hand Pain',
    category: 'Hand & Finger Symptoms',
    bodyLocations: ['Hands'],
    view: 'both',
    sideApplicable: true,
    followUpQuestions: {
      'Is pain worse in the morning?': ['Yes', 'No'],
    },
  ),
  MedicalSymptom(
    name: 'Finger Stiffness',
    category: 'Hand & Finger Symptoms',
    bodyLocations: ['Hands'],
    view: 'both',
    sideApplicable: true,
    followUpQuestions: {
      'How long does morning stiffness last?': ['Less than 30 mins', 'Over an hour'],
    },
  ),
  MedicalSymptom(
    name: 'Numbness in Fingers (Carpal Tunnel)',
    category: 'Hand & Finger Symptoms',
    bodyLocations: ['Hands'],
    view: 'both',
    sideApplicable: true,
    followUpQuestions: {
      'Does it wake you up at night?': ['Yes', 'No'],
    },
  ),
  MedicalSymptom(
    name: 'Cold Hands & Fingers',
    category: 'Hand & Finger Symptoms',
    bodyLocations: ['Hands'],
    view: 'both',
    sideApplicable: true,
    followUpQuestions: {
      'Do fingers change color (white/blue) in cold?': ['Yes', 'No'],
    },
  ),
  MedicalSymptom(name: 'Finger Pain', category: 'Hand & Finger Symptoms', bodyLocations: ['Hands'], sideApplicable: true),
  MedicalSymptom(name: 'Finger Swelling', category: 'Hand & Finger Symptoms', bodyLocations: ['Hands'], sideApplicable: true),
  MedicalSymptom(name: 'Finger Numbness', category: 'Hand & Finger Symptoms', bodyLocations: ['Hands'], sideApplicable: true),
  MedicalSymptom(name: 'Finger Tingling', category: 'Hand & Finger Symptoms', bodyLocations: ['Hands'], sideApplicable: true),
  MedicalSymptom(name: 'Burning Sensation in Fingers', category: 'Hand & Finger Symptoms', bodyLocations: ['Hands'], sideApplicable: true),
  MedicalSymptom(name: 'Cold Fingers Sensation', category: 'Hand & Finger Symptoms', bodyLocations: ['Hands'], sideApplicable: true),
  MedicalSymptom(name: 'Weak Hand Grip Strength', category: 'Hand & Finger Symptoms', bodyLocations: ['Hands'], sideApplicable: true),
  MedicalSymptom(name: 'Loss of Hand Grip Strength', category: 'Hand & Finger Symptoms', bodyLocations: ['Hands'], sideApplicable: true),
  MedicalSymptom(name: 'Trembling Hands', category: 'Hand & Finger Symptoms', bodyLocations: ['Hands'], sideApplicable: true),
  MedicalSymptom(name: 'Hand Muscle Cramps', category: 'Hand & Finger Symptoms', bodyLocations: ['Hands'], sideApplicable: true),
  MedicalSymptom(name: 'Hand Joint Pain', category: 'Hand & Finger Symptoms', bodyLocations: ['Hands'], sideApplicable: true),
  MedicalSymptom(name: 'Hand Joint Swelling', category: 'Hand & Finger Symptoms', bodyLocations: ['Hands'], sideApplicable: true),
  MedicalSymptom(name: 'Difficulty Moving Fingers', category: 'Hand & Finger Symptoms', bodyLocations: ['Hands'], sideApplicable: true),
  MedicalSymptom(name: 'Finger Discoloration (Raynaud\'s)', category: 'Hand & Finger Symptoms', bodyLocations: ['Hands'], sideApplicable: true),
  MedicalSymptom(name: 'Fingernail Ridging / Changes', category: 'Hand & Finger Symptoms', bodyLocations: ['Hands'], sideApplicable: true),
  MedicalSymptom(name: 'Trigger Finger (Locking Joint)', category: 'Hand & Finger Symptoms', bodyLocations: ['Hands'], sideApplicable: true),
  MedicalSymptom(name: 'Swollen Knuckles', category: 'Hand & Finger Symptoms', bodyLocations: ['Hands'], sideApplicable: true),
  MedicalSymptom(name: 'Loss of Fine Motor Control in Fingers', category: 'Hand & Finger Symptoms', bodyLocations: ['Hands'], sideApplicable: true),

  // ==================== 14. BACK / SPINE (25+ symptoms) ====================
  MedicalSymptom(
    name: 'Back Pain',
    category: 'Back & Spine Symptoms',
    bodyLocations: ['Back'],
    view: 'back',
    followUpQuestions: {
      'Where is the pain?': ['Upper Back', 'Mid Back', 'Lower Back'],
      'Does the pain travel down your leg?': ['Yes', 'No'],
    },
  ),
  MedicalSymptom(
    name: 'Upper Back Pain',
    category: 'Back & Spine Symptoms',
    bodyLocations: ['Back', 'Upper Back', 'Neck'],
    view: 'back',
    followUpQuestions: {
      'Is pain posture-related or after lifting heavy objects?': ['Posture', 'Lifting', 'Both'],
    },
  ),
  MedicalSymptom(
    name: 'Lower Back Pain (Lumbago)',
    category: 'Back & Spine Symptoms',
    bodyLocations: ['Back', 'Lower Back'],
    view: 'back',
    followUpQuestions: {
      'Does pain worsen with bending or sitting?': ['Yes', 'No'],
    },
  ),
  MedicalSymptom(
    name: 'Back Muscle Spasms',
    category: 'Back & Spine Symptoms',
    bodyLocations: ['Back'],
    view: 'back',
    followUpQuestions: {
      'Does spasm lock your movement?': ['Yes', 'No'],
    },
  ),
  MedicalSymptom(
    name: 'Spinal Stiffness',
    category: 'Back & Spine Symptoms',
    bodyLocations: ['Back'],
    view: 'back',
    followUpQuestions: {
      'Does morning stiffness take longer than 45 minutes to ease up?': ['Yes', 'No'],
    },
  ),
  MedicalSymptom(name: 'Middle Back Pain', category: 'Back & Spine Symptoms', bodyLocations: ['Back', 'Middle Back'], view: 'back'),
  MedicalSymptom(name: 'Lumbar Spine Pain', category: 'Back & Spine Symptoms', bodyLocations: ['Back', 'Lower Back'], view: 'back'),
  MedicalSymptom(name: 'Sacroiliac Joint Pain', category: 'Back & Spine Symptoms', bodyLocations: ['Back', 'Lower Back'], view: 'back', sideApplicable: true),
  MedicalSymptom(name: 'Back Tenderness to Touch', category: 'Back & Spine Symptoms', bodyLocations: ['Back'], view: 'back'),
  MedicalSymptom(name: 'Back Pain Radiating to Legs (Sciatica)', category: 'Back & Spine Symptoms', bodyLocations: ['Back', 'Legs'], view: 'back', sideApplicable: true),
  MedicalSymptom(name: 'Back Pain Radiating to Arms', category: 'Back & Spine Symptoms', bodyLocations: ['Back', 'Arms'], view: 'back', sideApplicable: true),
  MedicalSymptom(name: 'Tailbone Pain (Coccydynia)', category: 'Back & Spine Symptoms', bodyLocations: ['Back', 'Lower Back'], view: 'back'),
  MedicalSymptom(name: 'Spine Tenderness', category: 'Back & Spine Symptoms', bodyLocations: ['Back'], view: 'back'),
  MedicalSymptom(name: 'Difficulty Bending Forward', category: 'Back & Spine Symptoms', bodyLocations: ['Back'], view: 'back'),
  MedicalSymptom(name: 'Difficulty Standing Up Straight', category: 'Back & Spine Symptoms', bodyLocations: ['Back'], view: 'back'),
  MedicalSymptom(name: 'Difficulty Walking Due to Back Pain', category: 'Back & Spine Symptoms', bodyLocations: ['Back', 'Legs'], view: 'back'),
  MedicalSymptom(name: 'Sharp Stabbing Back Pain', category: 'Back & Spine Symptoms', bodyLocations: ['Back'], view: 'back'),
  MedicalSymptom(name: 'Stiff Lower Back in Morning', category: 'Back & Spine Symptoms', bodyLocations: ['Back', 'Lower Back'], view: 'back'),
  MedicalSymptom(name: 'Spinal Muscle Tightness', category: 'Back & Spine Symptoms', bodyLocations: ['Back'], view: 'back'),
  MedicalSymptom(name: 'Herniated Disc Pain Sensation', category: 'Back & Spine Symptoms', bodyLocations: ['Back', 'Lower Back'], view: 'back', sideApplicable: true),
  MedicalSymptom(name: 'Back Pain Worsened by Sitting', category: 'Back & Spine Symptoms', bodyLocations: ['Back'], view: 'back'),
  MedicalSymptom(name: 'Back Pain Worsened by Coughing', category: 'Back & Spine Symptoms', bodyLocations: ['Back'], view: 'back'),
  MedicalSymptom(name: 'Lumbar Muscle Strain', category: 'Back & Spine Symptoms', bodyLocations: ['Back', 'Lower Back'], view: 'back'),
  MedicalSymptom(name: 'Vertebral Pressure Sensation', category: 'Back & Spine Symptoms', bodyLocations: ['Back'], view: 'back'),
  MedicalSymptom(name: 'Back Weakness Sensation', category: 'Back & Spine Symptoms', bodyLocations: ['Back'], view: 'back'),

  // ==================== 15. HIPS / PELVIS (15+ symptoms) ====================
  MedicalSymptom(name: 'Hip Pain', category: 'Hip & Pelvic Symptoms', bodyLocations: ['Hips'], view: 'both', sideApplicable: true),
  MedicalSymptom(name: 'Hip Stiffness', category: 'Hip & Pelvic Symptoms', bodyLocations: ['Hips'], view: 'both', sideApplicable: true),
  MedicalSymptom(name: 'Hip Swelling', category: 'Hip & Pelvic Symptoms', bodyLocations: ['Hips'], view: 'both', sideApplicable: true),
  MedicalSymptom(name: 'Hip Weakness', category: 'Hip & Pelvic Symptoms', bodyLocations: ['Hips'], view: 'both', sideApplicable: true),
  MedicalSymptom(name: 'Pelvic Pain', category: 'Hip & Pelvic Symptoms', bodyLocations: ['Hips', 'Abdomen'], view: 'both'),
  MedicalSymptom(name: 'Groin Pain', category: 'Hip & Pelvic Symptoms', bodyLocations: ['Hips', 'Abdomen'], view: 'front', sideApplicable: true),
  MedicalSymptom(name: 'Hip Pain While Walking', category: 'Hip & Pelvic Symptoms', bodyLocations: ['Hips'], view: 'both', sideApplicable: true),
  MedicalSymptom(name: 'Pelvic Pain While Sitting', category: 'Hip & Pelvic Symptoms', bodyLocations: ['Hips', 'Abdomen'], view: 'both'),
  MedicalSymptom(name: 'Hip Pain While Standing', category: 'Hip & Pelvic Symptoms', bodyLocations: ['Hips'], view: 'both', sideApplicable: true),
  MedicalSymptom(name: 'Reduced Hip Range of Motion', category: 'Hip & Pelvic Symptoms', bodyLocations: ['Hips'], view: 'both', sideApplicable: true),
  MedicalSymptom(name: 'Hip Clicking / Catching', category: 'Hip & Pelvic Symptoms', bodyLocations: ['Hips'], view: 'both', sideApplicable: true),
  MedicalSymptom(name: 'Deep Pelvic Pressure', category: 'Hip & Pelvic Symptoms', bodyLocations: ['Hips', 'Abdomen'], view: 'front'),
  MedicalSymptom(name: 'Pubic Bone Pain', category: 'Hip & Pelvic Symptoms', bodyLocations: ['Hips'], view: 'front'),
  MedicalSymptom(name: 'Buttock Pain', category: 'Hip & Pelvic Symptoms', bodyLocations: ['Hips', 'Back'], view: 'back', sideApplicable: true),
  MedicalSymptom(name: 'Piriformis Muscle Syndrome Pain', category: 'Hip & Pelvic Symptoms', bodyLocations: ['Hips', 'Back'], view: 'back', sideApplicable: true),
  MedicalSymptom(name: 'Hip Joint Grinding Sensation', category: 'Hip & Pelvic Symptoms', bodyLocations: ['Hips'], view: 'both', sideApplicable: true),

  // ==================== 16. LEGS / KNEES (25+ symptoms) ====================
  MedicalSymptom(
    name: 'Knee Pain',
    category: 'Leg & Knee Symptoms',
    bodyLocations: ['Legs', 'Knees'],
    view: 'both',
    sideApplicable: true,
    followUpQuestions: {
      'Is there swelling or stiffness?': ['Swelling and stiffness', 'Swelling only', 'Stiffness only', 'Neither'],
      'Is pain worse when climbing stairs?': ['Yes', 'No'],
    },
  ),
  MedicalSymptom(
    name: 'Leg Cramps / Muscle Spasms',
    category: 'Leg & Knee Symptoms',
    bodyLocations: ['Legs'],
    view: 'both',
    sideApplicable: true,
    followUpQuestions: {
      'Do cramps occur mainly at night?': ['Yes', 'No'],
    },
  ),
  MedicalSymptom(
    name: 'Leg Swelling (Edema)',
    category: 'Leg & Knee Symptoms',
    bodyLocations: ['Legs'],
    view: 'both',
    sideApplicable: true,
    followUpQuestions: {
      'Is swelling in one leg or both legs?': ['One leg', 'Both legs'],
      'Is there redness or localized heat?': ['Yes', 'No'],
    },
  ),
  MedicalSymptom(
    name: 'Calf Pain / Soreness',
    category: 'Leg & Knee Symptoms',
    bodyLocations: ['Legs'],
    view: 'back',
    sideApplicable: true,
    followUpQuestions: {
      'Is there swelling, heat, or deep pain in the calf?': ['Yes', 'No'],
    },
  ),
  MedicalSymptom(
    name: 'Numbness / Tingling in Legs',
    category: 'Leg & Knee Symptoms',
    bodyLocations: ['Legs'],
    view: 'both',
    sideApplicable: true,
    followUpQuestions: {
      'Does pain radiate from lower back down the leg (Sciatica)?': ['Yes', 'No'],
    },
  ),
  MedicalSymptom(name: 'Knee Swelling', category: 'Leg & Knee Symptoms', bodyLocations: ['Legs', 'Knees'], sideApplicable: true),
  MedicalSymptom(name: 'Knee Stiffness', category: 'Leg & Knee Symptoms', bodyLocations: ['Legs', 'Knees'], sideApplicable: true),
  MedicalSymptom(name: 'Knee Weakness', category: 'Leg & Knee Symptoms', bodyLocations: ['Legs', 'Knees'], sideApplicable: true),
  MedicalSymptom(name: 'Leg Pain', category: 'Leg & Knee Symptoms', bodyLocations: ['Legs'], sideApplicable: true),
  MedicalSymptom(name: 'Thigh Muscle Pain', category: 'Leg & Knee Symptoms', bodyLocations: ['Legs'], sideApplicable: true),
  MedicalSymptom(name: 'Leg Weakness', category: 'Leg & Knee Symptoms', bodyLocations: ['Legs'], sideApplicable: true),
  MedicalSymptom(name: 'Heavy Legs Sensation', category: 'Leg & Knee Symptoms', bodyLocations: ['Legs'], sideApplicable: true),
  MedicalSymptom(name: 'Restless Legs Syndrome (RLS)', category: 'Leg & Knee Symptoms', bodyLocations: ['Legs'], sideApplicable: true),
  MedicalSymptom(name: 'Difficulty Walking', category: 'Leg & Knee Symptoms', bodyLocations: ['Legs']),
  MedicalSymptom(name: 'Difficulty Climbing Stairs', category: 'Leg & Knee Symptoms', bodyLocations: ['Legs', 'Knees']),
  MedicalSymptom(name: 'Knee Joint Instability / Giving Way', category: 'Leg & Knee Symptoms', bodyLocations: ['Legs', 'Knees'], sideApplicable: true),
  MedicalSymptom(name: 'Knee Joint Locking', category: 'Leg & Knee Symptoms', bodyLocations: ['Legs', 'Knees'], sideApplicable: true),
  MedicalSymptom(name: 'Patellar Kneecap Tenderness', category: 'Leg & Knee Symptoms', bodyLocations: ['Legs', 'Knees'], sideApplicable: true),
  MedicalSymptom(name: 'Shin Pain (Shin Splints)', category: 'Leg & Knee Symptoms', bodyLocations: ['Legs'], sideApplicable: true),
  MedicalSymptom(name: 'Hamstring Muscle Tightness / Strain', category: 'Leg & Knee Symptoms', bodyLocations: ['Legs'], view: 'back', sideApplicable: true),
  MedicalSymptom(name: 'Quadriceps Muscle Pain', category: 'Leg & Knee Symptoms', bodyLocations: ['Legs'], view: 'front', sideApplicable: true),
  MedicalSymptom(name: 'Leg Muscle Twitching (Fasciculations)', category: 'Leg & Knee Symptoms', bodyLocations: ['Legs'], sideApplicable: true),
  MedicalSymptom(name: 'Deep Leg Ache', category: 'Leg & Knee Symptoms', bodyLocations: ['Legs'], sideApplicable: true),
  MedicalSymptom(name: 'Burning Sensation in Legs', category: 'Leg & Knee Symptoms', bodyLocations: ['Legs'], sideApplicable: true),
  MedicalSymptom(name: 'Cold Feet and Lower Legs', category: 'Leg & Knee Symptoms', bodyLocations: ['Legs', 'Feet'], sideApplicable: true),
  MedicalSymptom(name: 'Varicose Vein Pain', category: 'Leg & Knee Symptoms', bodyLocations: ['Legs'], sideApplicable: true),

  // ==================== 17. FEET / ANKLES / TOES (20+ symptoms) ====================
  MedicalSymptom(
    name: 'Foot Pain',
    category: 'Foot & Ankle Symptoms',
    bodyLocations: ['Feet'],
    view: 'both',
    sideApplicable: true,
    followUpQuestions: {
      'Is pain in the arch, heel, or toes?': ['Arch', 'Heel', 'Toes', 'Entire Foot'],
    },
  ),
  MedicalSymptom(
    name: 'Heel Pain (Plantar Fasciitis)',
    category: 'Foot & Ankle Symptoms',
    bodyLocations: ['Feet'],
    view: 'both',
    sideApplicable: true,
    followUpQuestions: {
      'Is pain worst during first steps in the morning?': ['Yes', 'No'],
    },
  ),
  MedicalSymptom(
    name: 'Swollen Feet & Ankles',
    category: 'Foot & Ankle Symptoms',
    bodyLocations: ['Feet', 'Legs'],
    view: 'both',
    sideApplicable: true,
    followUpQuestions: {
      'Does swelling improve after elevating legs?': ['Yes', 'No'],
    },
  ),
  MedicalSymptom(
    name: 'Cold Feet & Toes',
    category: 'Foot & Ankle Symptoms',
    bodyLocations: ['Feet'],
    view: 'both',
    sideApplicable: true,
    followUpQuestions: {
      'Do you have a diagnosis of peripheral artery disease or diabetes?': ['Yes', 'No'],
    },
  ),
  MedicalSymptom(
    name: 'Tingling / Burning in Toes (Neuropathy)',
    category: 'Foot & Ankle Symptoms',
    bodyLocations: ['Feet'],
    view: 'both',
    sideApplicable: true,
    followUpQuestions: {
      'Is burning sensation worse at night?': ['Yes', 'No'],
    },
  ),
  MedicalSymptom(name: 'Ankle Pain', category: 'Foot & Ankle Symptoms', bodyLocations: ['Feet'], sideApplicable: true),
  MedicalSymptom(name: 'Ankle Swelling', category: 'Foot & Ankle Symptoms', bodyLocations: ['Feet'], sideApplicable: true),
  MedicalSymptom(name: 'Ankle Stiffness', category: 'Foot & Ankle Symptoms', bodyLocations: ['Feet'], sideApplicable: true),
  MedicalSymptom(name: 'Foot Swelling', category: 'Foot & Ankle Symptoms', bodyLocations: ['Feet'], sideApplicable: true),
  MedicalSymptom(name: 'Toe Pain', category: 'Foot & Ankle Symptoms', bodyLocations: ['Feet'], sideApplicable: true),
  MedicalSymptom(name: 'Toe Swelling', category: 'Foot & Ankle Symptoms', bodyLocations: ['Feet'], sideApplicable: true),
  MedicalSymptom(name: 'Toe Numbness', category: 'Foot & Ankle Symptoms', bodyLocations: ['Feet'], sideApplicable: true),
  MedicalSymptom(name: 'Toe Tingling', category: 'Foot & Ankle Symptoms', bodyLocations: ['Feet'], sideApplicable: true),
  MedicalSymptom(name: 'Burning Sensation in Feet', category: 'Foot & Ankle Symptoms', bodyLocations: ['Feet'], sideApplicable: true),
  MedicalSymptom(name: 'Foot Muscle Cramps', category: 'Foot & Ankle Symptoms', bodyLocations: ['Feet'], sideApplicable: true),
  MedicalSymptom(name: 'Difficulty Bearing Weight on Foot', category: 'Foot & Ankle Symptoms', bodyLocations: ['Feet'], sideApplicable: true),
  MedicalSymptom(name: 'Foot Weakness / Drop Foot', category: 'Foot & Ankle Symptoms', bodyLocations: ['Feet'], sideApplicable: true),
  MedicalSymptom(name: 'Toenail Discoloration / Changes', category: 'Foot & Ankle Symptoms', bodyLocations: ['Feet'], sideApplicable: true),
  MedicalSymptom(name: 'Foot Redness & Warmth', category: 'Foot & Ankle Symptoms', bodyLocations: ['Feet'], sideApplicable: true),
  MedicalSymptom(name: 'Foot Itching (Athlete\'s Foot)', category: 'Foot & Ankle Symptoms', bodyLocations: ['Feet'], sideApplicable: true),
  MedicalSymptom(name: 'Achilles Tendon Pain', category: 'Foot & Ankle Symptoms', bodyLocations: ['Feet', 'Legs'], view: 'back', sideApplicable: true),
  MedicalSymptom(name: 'Foot Arch Pain', category: 'Foot & Ankle Symptoms', bodyLocations: ['Feet'], sideApplicable: true),
  MedicalSymptom(name: 'Bunion Pain (Big Toe Joint)', category: 'Foot & Ankle Symptoms', bodyLocations: ['Feet'], sideApplicable: true),

  // ==================== 18. SKIN / HAIR / NAILS (40+ symptoms) ====================
  MedicalSymptom(
    name: 'Skin Rash',
    category: 'Skin, Hair & Nail Symptoms',
    bodyLocations: ['Arms', 'Hands', 'Legs', 'Feet', 'Abdomen', 'Chest', 'Neck', 'Head', 'Back'],
    view: 'both',
    followUpQuestions: {
      'Is the rash itchy?': ['Extremely itchy', 'Mildly itchy', 'Not itchy'],
      'Is it raised or flat?': ['Raised bumps', 'Flat spots', 'Blisters'],
    },
  ),
  MedicalSymptom(name: 'Skin Itching (Pruritus)', category: 'Skin, Hair & Nail Symptoms', bodyLocations: ['Arms', 'Legs', 'Chest', 'Abdomen', 'Back', 'Head']),
  MedicalSymptom(name: 'Dry Skin (Xerosis)', category: 'Skin, Hair & Nail Symptoms', bodyLocations: ['Arms', 'Legs', 'Hands', 'Feet', 'Head']),
  MedicalSymptom(name: 'Excessive Oily Skin', category: 'Skin, Hair & Nail Symptoms', bodyLocations: ['Head', 'Chest', 'Back']),
  MedicalSymptom(name: 'Skin Redness (Erythema)', category: 'Skin, Hair & Nail Symptoms', bodyLocations: ['Head', 'Chest', 'Arms', 'Legs']),
  MedicalSymptom(name: 'Skin Swelling (Localized)', category: 'Skin, Hair & Nail Symptoms', bodyLocations: ['Arms', 'Legs', 'Head']),
  MedicalSymptom(name: 'Skin Pain / Tenderness', category: 'Skin, Hair & Nail Symptoms', bodyLocations: ['Arms', 'Legs', 'Chest', 'Back']),
  MedicalSymptom(name: 'Skin Burning Sensation', category: 'Skin, Hair & Nail Symptoms', bodyLocations: ['Arms', 'Legs', 'Head']),
  MedicalSymptom(name: 'Skin Peeling (Desquamation)', category: 'Skin, Hair & Nail Symptoms', bodyLocations: ['Hands', 'Feet', 'Arms', 'Legs']),
  MedicalSymptom(name: 'Skin Scaling / Flaking', category: 'Skin, Hair & Nail Symptoms', bodyLocations: ['Head', 'Arms', 'Legs']),
  MedicalSymptom(name: 'Hives (Urticaria)', category: 'Skin, Hair & Nail Symptoms', bodyLocations: ['Arms', 'Legs', 'Chest', 'Abdomen', 'Back']),
  MedicalSymptom(name: 'Blisters (Vesicles)', category: 'Skin, Hair & Nail Symptoms', bodyLocations: ['Hands', 'Feet', 'Arms', 'Legs']),
  MedicalSymptom(name: 'Skin Lesions / Bumps', category: 'Skin, Hair & Nail Symptoms', bodyLocations: ['Head', 'Arms', 'Legs', 'Back']),
  MedicalSymptom(name: 'Skin Ulcers / Sores', category: 'Skin, Hair & Nail Symptoms', bodyLocations: ['Legs', 'Feet', 'Arms']),
  MedicalSymptom(name: 'Skin Hyperpigmentation / Dark Spots', category: 'Skin, Hair & Nail Symptoms', bodyLocations: ['Head', 'Arms', 'Legs']),
  MedicalSymptom(name: 'Pale Skin (Pallor)', category: 'Skin, Hair & Nail Symptoms', bodyLocations: ['Head', 'Hands']),
  MedicalSymptom(name: 'Yellowish Skin Tint', category: 'Skin, Hair & Nail Symptoms', bodyLocations: ['Head', 'Hands', 'Abdomen']),
  MedicalSymptom(name: 'Bluish Skin Tint (Cyanosis)', category: 'Skin, Hair & Nail Symptoms', bodyLocations: ['Hands', 'Feet', 'Head']),
  MedicalSymptom(name: 'Excessive Sweating (Hyperhidrosis)', category: 'Skin, Hair & Nail Symptoms', bodyLocations: ['Head', 'Hands', 'Feet', 'Chest']),
  MedicalSymptom(name: 'Night Sweating', category: 'Skin, Hair & Nail Symptoms', bodyLocations: ['Chest', 'Head', 'Back']),
  MedicalSymptom(name: 'Excessive Body Hair Growth (Hirsutism)', category: 'Skin, Hair & Nail Symptoms', bodyLocations: ['Head', 'Chest', 'Abdomen']),
  MedicalSymptom(name: 'Brittle Hair', category: 'Skin, Hair & Nail Symptoms', bodyLocations: ['Head']),
  MedicalSymptom(name: 'Scalp Itching', category: 'Skin, Hair & Nail Symptoms', bodyLocations: ['Head']),
  MedicalSymptom(name: 'Scalp Pain', category: 'Skin, Hair & Nail Symptoms', bodyLocations: ['Head']),
  MedicalSymptom(name: 'Dandruff Flaking', category: 'Skin, Hair & Nail Symptoms', bodyLocations: ['Head']),
  MedicalSymptom(name: 'Nail Discoloration', category: 'Skin, Hair & Nail Symptoms', bodyLocations: ['Hands', 'Feet']),
  MedicalSymptom(name: 'Brittle Nails', category: 'Skin, Hair & Nail Symptoms', bodyLocations: ['Hands', 'Feet']),
  MedicalSymptom(name: 'Nail Pain / Tenderness', category: 'Skin, Hair & Nail Symptoms', bodyLocations: ['Hands', 'Feet']),
  MedicalSymptom(name: 'Nail Swelling / Paronychia', category: 'Skin, Hair & Nail Symptoms', bodyLocations: ['Hands', 'Feet']),
  MedicalSymptom(name: 'Ingrown Toenail Pain', category: 'Skin, Hair & Nail Symptoms', bodyLocations: ['Feet'], sideApplicable: true),
  MedicalSymptom(name: 'Easy Bruising (Ecchymosis)', category: 'Skin, Hair & Nail Symptoms', bodyLocations: ['Arms', 'Legs']),
  MedicalSymptom(name: 'Petechiae (Tiny Red Pinpoint Spots)', category: 'Skin, Hair & Nail Symptoms', bodyLocations: ['Legs', 'Arms']),
  MedicalSymptom(name: 'Skin Hypersensitivity to Touch', category: 'Skin, Hair & Nail Symptoms', bodyLocations: ['Arms', 'Legs', 'Back']),
  MedicalSymptom(name: 'Stretch Marks Itching', category: 'Skin, Hair & Nail Symptoms', bodyLocations: ['Abdomen', 'Hips']),
  MedicalSymptom(name: 'Skin Warts / Growth', category: 'Skin, Hair & Nail Symptoms', bodyLocations: ['Hands', 'Feet']),
  MedicalSymptom(name: 'Cold Sores on Lips / Skin', category: 'Skin, Hair & Nail Symptoms', bodyLocations: ['Mouth', 'Head']),
  MedicalSymptom(name: 'Dry Cracked Skin on Heels', category: 'Skin, Hair & Nail Symptoms', bodyLocations: ['Feet']),
  MedicalSymptom(name: 'Thickened Skin Patches', category: 'Skin, Hair & Nail Symptoms', bodyLocations: ['Hands', 'Feet', 'Legs']),
  MedicalSymptom(name: 'Sunburn Pain & Redness', category: 'Skin, Hair & Nail Symptoms', bodyLocations: ['Head', 'Arms', 'Back']),
  MedicalSymptom(name: 'Acne / Pimple Flare-up', category: 'Skin, Hair & Nail Symptoms', bodyLocations: ['Head', 'Chest', 'Back']),
  MedicalSymptom(name: 'Boils / Furuncles', category: 'Skin, Hair & Nail Symptoms', bodyLocations: ['Legs', 'Arms', 'Back']),

  // ==================== 19. GENERAL / WHOLE BODY (30+ symptoms) ====================
  MedicalSymptom(
    name: 'Fever',
    category: 'General & Whole Body',
    bodyLocations: ['Head', 'Chest', 'Abdomen', 'Legs', 'Arms', 'Neck', 'Ears', 'Nose'],
    view: 'both',
    followUpQuestions: {
      'What is your approximate temperature?': ['Low grade (< 100.4°F)', 'High grade (100.4°F - 103°F)', 'Severe (> 103°F)', 'Not measured'],
      'Are you experiencing chills or sweating?': ['Chills only', 'Sweating only', 'Both', 'Neither'],
    },
  ),
  MedicalSymptom(
    name: 'Fatigue',
    category: 'General & Whole Body',
    bodyLocations: ['Head', 'Legs', 'Arms', 'Chest', 'Abdomen'],
    view: 'both',
    followUpQuestions: {
      'How long have you felt abnormally tired?': ['A few days', '1-2 weeks', 'More than a month'],
    },
  ),
  MedicalSymptom(name: 'Chills & Shivering', category: 'General & Whole Body', bodyLocations: ['Head', 'Chest', 'Back']),
  MedicalSymptom(name: 'General Body Weakness', category: 'General & Whole Body', bodyLocations: ['Arms', 'Legs', 'Chest']),
  MedicalSymptom(name: 'Malaise / General Unwell Feeling', category: 'General & Whole Body', bodyLocations: ['Head', 'Chest']),
  MedicalSymptom(name: 'Generalized Body Aches (Myalgia)', category: 'General & Whole Body', bodyLocations: ['Arms', 'Legs', 'Back']),
  MedicalSymptom(name: 'Muscle Aches & Soreness', category: 'General & Whole Body', bodyLocations: ['Arms', 'Legs', 'Back']),
  MedicalSymptom(name: 'Unexplained Weight Loss', category: 'General & Whole Body', bodyLocations: ['Abdomen', 'Chest']),
  MedicalSymptom(name: 'Unexplained Weight Gain', category: 'General & Whole Body', bodyLocations: ['Abdomen', 'Chest']),
  MedicalSymptom(name: 'Excessive Thirst (Polydipsia)', category: 'General & Whole Body', bodyLocations: ['Mouth', 'Head']),
  MedicalSymptom(name: 'Dehydration Symptoms', category: 'General & Whole Body', bodyLocations: ['Mouth', 'Head']),
  MedicalSymptom(name: 'Excessive Sweating', category: 'General & Whole Body', bodyLocations: ['Head', 'Chest']),
  MedicalSymptom(name: 'Night Sweats', category: 'General & Whole Body', bodyLocations: ['Chest', 'Head', 'Back']),
  MedicalSymptom(name: 'Generalized Fluid Retention (Edema)', category: 'General & Whole Body', bodyLocations: ['Legs', 'Feet', 'Hands']),
  MedicalSymptom(name: 'Widespread Pain (Fibromyalgia Sensation)', category: 'General & Whole Body', bodyLocations: ['Arms', 'Legs', 'Back', 'Neck']),
  MedicalSymptom(name: 'Chronic Fatigue Sensation', category: 'General & Whole Body', bodyLocations: ['Head', 'Arms', 'Legs']),
  MedicalSymptom(name: 'Extreme Heat Intolerance', category: 'General & Whole Body', bodyLocations: ['Head', 'Chest']),
  MedicalSymptom(name: 'Extreme Cold Intolerance', category: 'General & Whole Body', bodyLocations: ['Hands', 'Feet', 'Head']),
  MedicalSymptom(name: 'Generalized Itching All Over', category: 'General & Whole Body', bodyLocations: ['Arms', 'Legs', 'Back']),
  MedicalSymptom(name: 'Low Vital Energy', category: 'General & Whole Body', bodyLocations: ['Head', 'Chest']),
  MedicalSymptom(name: 'Delayed Wound Healing', category: 'General & Whole Body', bodyLocations: ['Legs', 'Feet', 'Hands']),
  MedicalSymptom(name: 'Swollen Glands All Over', category: 'General & Whole Body', bodyLocations: ['Neck', 'Arms', 'Legs']),
  MedicalSymptom(name: 'Drowsiness During Day', category: 'General & Whole Body', bodyLocations: ['Head']),
  MedicalSymptom(name: 'Physical Exhaustion After Mild Effort', category: 'General & Whole Body', bodyLocations: ['Chest', 'Legs']),
  MedicalSymptom(name: 'Heavy Whole-Body Feeling', category: 'General & Whole Body', bodyLocations: ['Arms', 'Legs']),
  MedicalSymptom(name: 'Post-Exertional Malaise', category: 'General & Whole Body', bodyLocations: ['Chest', 'Legs']),
  MedicalSymptom(name: 'Loss of Vitality', category: 'General & Whole Body', bodyLocations: ['Head']),
  MedicalSymptom(name: 'Flu-like Symptoms', category: 'General & Whole Body', bodyLocations: ['Head', 'Chest', 'Legs']),
  MedicalSymptom(name: 'Cold Shivers Without Fever', category: 'General & Whole Body', bodyLocations: ['Head', 'Back']),
  MedicalSymptom(name: 'General Stiffness Upon Waking', category: 'General & Whole Body', bodyLocations: ['Back', 'Legs', 'Arms']),

  // ==================== 20. MENTAL & PSYCHOLOGICAL (20+ symptoms) ====================
  MedicalSymptom(
    name: 'Anxiety',
    category: 'Mental & Psychological',
    bodyLocations: ['Head', 'Chest'],
    view: 'both',
    followUpQuestions: {
      'Do you experience physical symptoms like sweating or rapid heartbeat?': ['Yes, often', 'Sometimes', 'No'],
    },
  ),
  MedicalSymptom(
    name: 'Depression',
    category: 'Mental & Psychological',
    bodyLocations: ['Head'],
    view: 'both',
    followUpQuestions: {
      'Have you lost interest in activities you normally enjoy?': ['Yes', 'No'],
    },
  ),
  MedicalSymptom(name: 'Panic Attacks', category: 'Mental & Psychological', bodyLocations: ['Head', 'Chest']),
  MedicalSymptom(name: 'Excessive Worry', category: 'Mental & Psychological', bodyLocations: ['Head']),
  MedicalSymptom(name: 'Irritability / Agitation', category: 'Mental & Psychological', bodyLocations: ['Head']),
  MedicalSymptom(name: 'Mood Swings', category: 'Mental & Psychological', bodyLocations: ['Head']),
  MedicalSymptom(name: 'Persistent Sadness', category: 'Mental & Psychological', bodyLocations: ['Head']),
  MedicalSymptom(name: 'Loss of Interest (Anhedonia)', category: 'Mental & Psychological', bodyLocations: ['Head']),
  MedicalSymptom(name: 'Difficulty Concentrating (Mental)', category: 'Mental & Psychological', bodyLocations: ['Head']),
  MedicalSymptom(name: 'Psychomotor Restlessness', category: 'Mental & Psychological', bodyLocations: ['Head', 'Legs']),
  MedicalSymptom(name: 'Phobic Fear / Agoraphobia', category: 'Mental & Psychological', bodyLocations: ['Head']),
  MedicalSymptom(name: 'Social Withdrawal', category: 'Mental & Psychological', bodyLocations: ['Head']),
  MedicalSymptom(name: 'Sleep Disturbance / Insomnia (Psychological)', category: 'Mental & Psychological', bodyLocations: ['Head']),
  MedicalSymptom(name: 'Frequent Nightmares', category: 'Mental & Psychological', bodyLocations: ['Head']),
  MedicalSymptom(name: 'Racing Thoughts', category: 'Mental & Psychological', bodyLocations: ['Head']),
  MedicalSymptom(name: 'Emotional Numbness', category: 'Mental & Psychological', bodyLocations: ['Head']),
  MedicalSymptom(name: 'Feeling Overwhelmed', category: 'Mental & Psychological', bodyLocations: ['Head']),
  MedicalSymptom(name: 'Severe Stress / Burnout', category: 'Mental & Psychological', bodyLocations: ['Head']),
  MedicalSymptom(name: 'Impulsivity / Agitation', category: 'Mental & Psychological', bodyLocations: ['Head']),
  MedicalSymptom(name: 'Sudden Emotional Outbursts', category: 'Mental & Psychological', bodyLocations: ['Head']),
  MedicalSymptom(name: 'Health Anxiety / Hypochondria', category: 'Mental & Psychological', bodyLocations: ['Head']),
  MedicalSymptom(name: 'Mental Exhaustion', category: 'Mental & Psychological', bodyLocations: ['Head']),

  // ==================== 21. REPRODUCTIVE & SEXUAL HEALTH (25+ symptoms) ====================
  MedicalSymptom(name: 'Pelvic Pain', category: 'Reproductive & Sexual Health', bodyLocations: ['Abdomen', 'Hips'], view: 'front'),
  MedicalSymptom(name: 'Severe Menstrual Cramps (Dysmenorrhea)', category: 'Reproductive & Sexual Health', bodyLocations: ['Abdomen', 'Hips'], gender: 'female', view: 'front'),
  MedicalSymptom(name: 'Irregular Menstrual Periods', category: 'Reproductive & Sexual Health', bodyLocations: ['Abdomen'], gender: 'female'),
  MedicalSymptom(name: 'Heavy Menstrual Bleeding (Menorrhagia)', category: 'Reproductive & Sexual Health', bodyLocations: ['Abdomen'], gender: 'female'),
  MedicalSymptom(name: 'Unusual Vaginal Discharge', category: 'Reproductive & Sexual Health', bodyLocations: ['Abdomen'], gender: 'female'),
  MedicalSymptom(name: 'Vaginal Itching or Burning', category: 'Reproductive & Sexual Health', bodyLocations: ['Abdomen'], gender: 'female'),
  MedicalSymptom(name: 'Vaginal Pain', category: 'Reproductive & Sexual Health', bodyLocations: ['Abdomen'], gender: 'female'),
  MedicalSymptom(name: 'Pain During Intercourse (Dyspareunia)', category: 'Reproductive & Sexual Health', bodyLocations: ['Abdomen', 'Hips']),
  MedicalSymptom(name: 'Erectile Dysfunction / Difficulty', category: 'Reproductive & Sexual Health', bodyLocations: ['Abdomen'], gender: 'male'),
  MedicalSymptom(name: 'Testicular Pain', category: 'Reproductive & Sexual Health', bodyLocations: ['Abdomen'], gender: 'male', sideApplicable: true),
  MedicalSymptom(name: 'Testicular Swelling / Mass', category: 'Reproductive & Sexual Health', bodyLocations: ['Abdomen'], gender: 'male', sideApplicable: true),
  MedicalSymptom(name: 'Groin Swelling', category: 'Reproductive & Sexual Health', bodyLocations: ['Abdomen', 'Hips'], sideApplicable: true),
  MedicalSymptom(name: 'Scrotal Pain & Tenderness', category: 'Reproductive & Sexual Health', bodyLocations: ['Abdomen'], gender: 'male', sideApplicable: true),
  MedicalSymptom(name: 'Scrotal Swelling', category: 'Reproductive & Sexual Health', bodyLocations: ['Abdomen'], gender: 'male', sideApplicable: true),
  MedicalSymptom(name: 'Breast Pain (Mastalgia)', category: 'Reproductive & Sexual Health', bodyLocations: ['Chest'], sideApplicable: true),
  MedicalSymptom(name: 'Breast Lump or Swelling', category: 'Reproductive & Sexual Health', bodyLocations: ['Chest'], sideApplicable: true),
  MedicalSymptom(name: 'Nipple Discharge', category: 'Reproductive & Sexual Health', bodyLocations: ['Chest'], sideApplicable: true),
  MedicalSymptom(name: 'Severe PMS Symptoms', category: 'Reproductive & Sexual Health', bodyLocations: ['Abdomen', 'Head'], gender: 'female'),
  MedicalSymptom(name: 'Hot Flashes (Menopausal)', category: 'Reproductive & Sexual Health', bodyLocations: ['Head', 'Chest'], gender: 'female'),
  MedicalSymptom(name: 'Absence of Menstrual Period (Amenorrhea)', category: 'Reproductive & Sexual Health', bodyLocations: ['Abdomen'], gender: 'female'),
  MedicalSymptom(name: 'Spotting Between Periods', category: 'Reproductive & Sexual Health', bodyLocations: ['Abdomen'], gender: 'female'),
  MedicalSymptom(name: 'Painful Ejaculation', category: 'Reproductive & Sexual Health', bodyLocations: ['Abdomen'], gender: 'male'),
  MedicalSymptom(name: 'Prostate Area Discomfort', category: 'Reproductive & Sexual Health', bodyLocations: ['Abdomen', 'Hips'], gender: 'male'),
  MedicalSymptom(name: 'Lower Abdominal Pelvic Pressure', category: 'Reproductive & Sexual Health', bodyLocations: ['Abdomen']),
  MedicalSymptom(name: 'Penile Discharge', category: 'Reproductive & Sexual Health', bodyLocations: ['Abdomen'], gender: 'male'),
  MedicalSymptom(name: 'Vulvar Pain or Itching', category: 'Reproductive & Sexual Health', bodyLocations: ['Abdomen'], gender: 'female'),
];

// ==========================================
// 3. CLINICAL CATEGORY LIST
// ==========================================
const List<String> symptomCategoriesList = [
  'All',
  'Neurological Symptoms',
  'Eye Symptoms',
  'Ear, Hearing & Balance',
  'Nose & Sinus',
  'Mouth, Teeth & Throat',
  'Neck Symptoms',
  'Respiratory & Lung Symptoms',
  'Heart & Circulatory Symptoms',
  'Digestive & Abdominal',
  'Liver, Gallbladder & Pancreas',
  'Kidney & Urinary Symptoms',
  'Arm & Shoulder Symptoms',
  'Hand & Finger Symptoms',
  'Back & Spine Symptoms',
  'Hip & Pelvic Symptoms',
  'Leg & Knee Symptoms',
  'Foot & Ankle Symptoms',
  'Skin, Hair & Nail Symptoms',
  'General & Whole Body',
  'Mental & Psychological',
  'Reproductive & Sexual Health',
];

// ==========================================
// 4. HELPER DATA SERVICES & SEARCH UTILITIES
// ==========================================
class SymptomDatabaseService {
  /// Returns symptoms filtered by query, category, location, and optional gender
  static List<MedicalSymptom> filterSymptoms({
    required String query,
    String category = 'All',
    String? location,
    String? genderFilter,
  }) {
    final q = query.trim().toLowerCase();
    
    return symptomDatabase.where((s) {
      // Gender filter check
      if (s.gender != null && genderFilter != null && genderFilter.isNotEmpty) {
        if (s.gender != genderFilter && s.gender != 'all') {
          return false;
        }
      }

      // Search query filtering
      if (q.isNotEmpty) {
        final matchesName = s.name.toLowerCase().contains(q);
        final matchesCat = s.category.toLowerCase().contains(q);
        final matchesLoc = s.bodyLocations.any((loc) => loc.toLowerCase().contains(q));
        if (!matchesName && !matchesCat && !matchesLoc) return false;
      }

      // Category filter check (only when search query is empty)
      if (category != 'All' && q.isEmpty) {
        // Support legacy or exact match category comparisons
        final sCatLower = s.category.toLowerCase();
        final cLower = category.toLowerCase();
        if (s.category != category && !sCatLower.contains(cLower) && !cLower.contains(sCatLower)) {
          return false;
        }
      }

      // Body Location filter check (only when search query is empty)
      if (location != null && location.isNotEmpty && q.isEmpty) {
        final locLower = location.toLowerCase();
        bool matchesLoc = s.bodyLocations.any((bLoc) {
          final bLower = bLoc.toLowerCase();
          if (bLower == locLower) return true;
          if (locLower.contains('back') && bLower.contains('back')) return true;
          if (locLower.contains('leg') && (bLower.contains('leg') || bLower.contains('knee'))) return true;
          if (locLower.contains('knee') && (bLower.contains('knee') || bLower.contains('leg'))) return true;
          if ((locLower.contains('foot') || locLower.contains('feet')) && 
              (bLower.contains('foot') || bLower.contains('feet') || bLower.contains('ankle') || bLower.contains('toe'))) return true;
          if (locLower.contains('arm') && (bLower.contains('arm') || bLower.contains('elbow'))) return true;
          if (locLower.contains('hand') && (bLower.contains('hand') || bLower.contains('finger'))) return true;
          if (locLower.contains('hip') && (bLower.contains('hip') || bLower.contains('pelvis') || bLower.contains('groin'))) return true;
          return false;
        });

        if (!matchesLoc) return false;
      }

      return true;
    }).toList();
  }

  /// Returns autocomplete suggestions based on query
  static List<MedicalSymptom> getSuggestions(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];

    return symptomDatabase.where((s) {
      final matchesName = s.name.toLowerCase().contains(q);
      final matchesCat = s.category.toLowerCase().contains(q);
      final matchesLoc = s.bodyLocations.any((loc) => loc.toLowerCase().contains(q));
      return matchesName || matchesCat || matchesLoc;
    }).toList();
  }
}
