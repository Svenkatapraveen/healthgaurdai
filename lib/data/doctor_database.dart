class DoctorModel {
  final String id;
  final String name;
  final String specialty;
  final String email;
  final String phone;
  final String availableDays;
  final String availableHours;
  final double rating;
  final String clinicLocation;
  final String qualification;
  final String experienceYears;
  final String status;
  final String profileImage;

  String get hospital => clinicLocation;

  const DoctorModel({
    required this.id,
    required this.name,
    required this.specialty,
    this.email = '',
    this.phone = '+1 (555) 234-5678',
    required this.availableDays,
    required this.availableHours,
    this.rating = 4.9,
    this.clinicLocation = 'HealthGuard AI Central Medical Hub',
    this.qualification = 'MD, FACC, Board Certified',
    this.experienceYears = '12+ Years',
    this.status = 'Active',
    this.profileImage = '',
  });
}

const List<DoctorModel> doctorDatabase = [
  DoctorModel(
    id: 'doc_101',
    name: 'Dr. Rajesh Sharma',
    specialty: 'Cardiologist',
    email: 'dr.rajesh@healthguard.ai',
    phone: '+1 (555) 101-2001',
    availableDays: 'Mon – Fri',
    availableHours: '09:00 AM – 05:00 PM',
    rating: 4.9,
    qualification: 'MD Cardiology, FACC',
    experienceYears: '15 Years',
  ),
  DoctorModel(
    id: 'doc_102',
    name: 'Dr. Ananya Sen',
    specialty: 'Neurologist',
    email: 'dr.ananya@healthguard.ai',
    phone: '+1 (555) 102-2002',
    availableDays: 'Mon – Sat',
    availableHours: '10:00 AM – 04:00 PM',
    rating: 4.8,
    qualification: 'MD Neurology, DM',
    experienceYears: '12 Years',
  ),
  DoctorModel(
    id: 'doc_103',
    name: 'Dr. Vikram Malhotra',
    specialty: 'General Physician',
    email: 'dr.vikram@healthguard.ai',
    phone: '+1 (555) 103-2003',
    availableDays: 'Mon – Sun',
    availableHours: '08:00 AM – 08:00 PM',
    rating: 4.9,
    qualification: 'MD Internal Medicine',
    experienceYears: '18 Years',
  ),
  DoctorModel(
    id: 'doc_104',
    name: 'Dr. Priya Patel',
    specialty: 'Dermatologist',
    email: 'dr.priya@healthguard.ai',
    phone: '+1 (555) 104-2004',
    availableDays: 'Tue – Sat',
    availableHours: '11:00 AM – 05:00 PM',
    rating: 4.7,
    qualification: 'MD Dermatology, Board Certified',
    experienceYears: '10 Years',
  ),
  DoctorModel(
    id: 'doc_105',
    name: 'Dr. Neha Verma',
    specialty: 'Pulmonologist',
    email: 'dr.neha@healthguard.ai',
    phone: '+1 (555) 105-2005',
    availableDays: 'Mon – Fri',
    availableHours: '09:00 AM – 03:00 PM',
    rating: 4.9,
    qualification: 'MD Pulmonology, FCCP',
    experienceYears: '14 Years',
  ),
  DoctorModel(
    id: 'doc_106',
    name: 'Dr. Amit Roy',
    specialty: 'Gastroenterologist',
    email: 'dr.amit@healthguard.ai',
    phone: '+1 (555) 106-2006',
    availableDays: 'Mon – Fri',
    availableHours: '10:00 AM – 04:00 PM',
    rating: 4.8,
    qualification: 'MD Gastroenterology',
    experienceYears: '11 Years',
  ),
  DoctorModel(
    id: 'doc_107',
    name: 'Dr. Suresh Nair',
    specialty: 'Orthopedic',
    email: 'dr.suresh@healthguard.ai',
    phone: '+1 (555) 107-2007',
    availableDays: 'Mon – Sat',
    availableHours: '09:00 AM – 06:00 PM',
    rating: 4.9,
    qualification: 'MS Orthopedics, FRCS',
    experienceYears: '16 Years',
  ),
  DoctorModel(
    id: 'doc_108',
    name: 'Dr. Meera Joshi',
    specialty: 'Ophthalmologist',
    email: 'dr.meera@healthguard.ai',
    phone: '+1 (555) 108-2008',
    availableDays: 'Tue – Sun',
    availableHours: '10:00 AM – 04:00 PM',
    rating: 4.8,
    qualification: 'MS Ophthalmology',
    experienceYears: '9 Years',
  ),
  DoctorModel(
    id: 'doc_109',
    name: 'Dr. Tariq Khan',
    specialty: 'ENT',
    email: 'dr.tariq@healthguard.ai',
    phone: '+1 (555) 109-2009',
    availableDays: 'Mon – Fri',
    availableHours: '11:00 AM – 05:00 PM',
    rating: 4.7,
    qualification: 'MS ENT, DLO',
    experienceYears: '13 Years',
  ),
  DoctorModel(
    id: 'doc_110',
    name: 'Dr. Ritu Kapoor',
    specialty: 'Urologist',
    email: 'dr.ritu@healthguard.ai',
    phone: '+1 (555) 110-2010',
    availableDays: 'Mon – Sat',
    availableHours: '09:00 AM – 04:00 PM',
    rating: 4.9,
    qualification: 'MCh Urology',
    experienceYears: '15 Years',
  ),
  DoctorModel(
    id: 'doc_111',
    name: 'Dr. Kavita Rao',
    specialty: 'Gynecologist',
    email: 'dr.kavita@healthguard.ai',
    phone: '+1 (555) 111-2011',
    availableDays: 'Mon – Sat',
    availableHours: '09:00 AM – 05:00 PM',
    rating: 4.9,
    qualification: 'MD OB/GYN, FRCOG',
    experienceYears: '17 Years',
  ),
  DoctorModel(
    id: 'doc_112',
    name: 'Dr. Sanjay Gupta',
    specialty: 'Psychiatrist',
    email: 'dr.sanjay@healthguard.ai',
    phone: '+1 (555) 112-2012',
    availableDays: 'Mon – Fri',
    availableHours: '10:00 AM – 06:00 PM',
    rating: 4.8,
    qualification: 'MD Psychiatry',
    experienceYears: '14 Years',
  ),
  DoctorModel(
    id: 'doc_113',
    name: 'Dr. Shalini Das',
    specialty: 'Endocrinologist',
    email: 'dr.shalini@healthguard.ai',
    phone: '+1 (555) 113-2013',
    availableDays: 'Tue – Sat',
    availableHours: '09:00 AM – 03:00 PM',
    rating: 4.9,
    qualification: 'DM Endocrinology',
    experienceYears: '12 Years',
  ),
];

List<DoctorModel> getDoctorsBySpecialty(String specialty) {
  final match = doctorDatabase.where((d) => d.specialty.toLowerCase() == specialty.toLowerCase()).toList();
  return match.isNotEmpty ? match : doctorDatabase;
}

DoctorModel getDoctorById(String doctorId) {
  return doctorDatabase.firstWhere(
    (d) => d.id == doctorId || d.email.toLowerCase() == doctorId.toLowerCase(),
    orElse: () => doctorDatabase.first,
  );
}

String normalizeSpecialty(String rawInput) {
  final clean = rawInput.replaceAll(RegExp(r'^Dr\.\s*'), '').trim().toLowerCase();
  for (var doc in doctorDatabase) {
    if (doc.specialty.toLowerCase() == clean || clean.contains(doc.specialty.toLowerCase())) {
      return doc.specialty;
    }
  }
  return 'General Physician';
}
