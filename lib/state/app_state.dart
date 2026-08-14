import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/db_service.dart';
import '../services/firebase_auth_service.dart';
import '../services/firebase_db_service.dart';

class AppState extends ChangeNotifier {
  final AuthService _authService = FirebaseAuthService();
  final DatabaseService _dbService = FirebaseDbService();

  AppUser? _currentUser;
  bool _isLoading = false;
  ThemeMode _themeMode = ThemeMode.dark; // Defaulting to professional dark theme

  List<AssessmentModel> _assessments = [];
  List<AppointmentModel> _appointments = [];
  List<NotificationModel> _notifications = [];
  List<MedicineReminderModel> _reminders = [];

  // Getters
  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  List<AssessmentModel> get assessments => _assessments;
  List<AppointmentModel> get appointments => _appointments;
  List<NotificationModel> get notifications => _notifications;
  List<MedicineReminderModel> get reminders => _reminders;

  AuthService get authService => _authService;
  DatabaseService get dbService => _dbService;

  // Toggle Theme
  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Reload data from DB
  Future<void> reloadUserData() async {
    if (_currentUser == null) return;
    final uid = _currentUser!.uid;
    _assessments = await _dbService.getAssessments(uid);
    _appointments = await _dbService.getAppointments(uid);
    _notifications = await _dbService.getNotifications(uid);
    _reminders = await _dbService.getReminders(uid);
    notifyListeners();
  }

  // Authentication wrapper methods
  Future<bool> login(String email, String password) async {
    setLoading(true);
    try {
      final user = await _authService.signInWithEmail(email, password);
      if (user != null) {
        _currentUser = user;
        await reloadUserData();
        setLoading(false);
        return true;
      }
    } catch (e) {
      setLoading(false);
      rethrow;
    }
    setLoading(false);
    return false;
  }

  Future<bool> register({
    required String fullName,
    required String email,
    required String mobile,
    required int age,
    required String gender,
    required String password,
  }) async {
    setLoading(true);
    try {
      final user = await _authService.registerWithEmail(
        fullName: fullName,
        email: email,
        mobile: mobile,
        age: age,
        gender: gender,
        password: password,
      );
      if (user != null) {
        _currentUser = user;
        await reloadUserData();
        setLoading(false);
        return true;
      }
    } catch (e) {
      setLoading(false);
      rethrow;
    }
    setLoading(false);
    return false;
  }

  Future<bool> loginWithGoogle({String? email, String? displayName}) async {
    setLoading(true);
    try {
      final user = await _authService.signInWithGoogle(email: email, displayName: displayName);
      if (user != null) {
        _currentUser = user;
        await reloadUserData();
        setLoading(false);
        return true;
      }
    } catch (e) {
      setLoading(false);
    }
    setLoading(false);
    return false;
  }

  Future<void> requestPasswordReset(String email) async {
    setLoading(true);
    try {
      await _authService.sendPasswordReset(email);
    } finally {
      setLoading(false);
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    _assessments = [];
    _appointments = [];
    _notifications = [];
    _reminders = [];
    notifyListeners();
  }

  // Database operations
  Future<void> submitAssessment(AssessmentModel assessment) async {
    setLoading(true);
    await _dbService.addAssessment(assessment);
    if (_currentUser != null) {
      _assessments = await _dbService.getAssessments(_currentUser!.uid);
    }
    setLoading(false);
  }

  Future<void> createAppointment({
    required String patientName,
    required String mobileNumber,
    required DateTime dateTime,
    required String doctorSpecialty,
    required String symptomsSummary,
  }) async {
    if (_currentUser == null) return;
    setLoading(true);
    final idSuffix = DateTime.now().millisecondsSinceEpoch.toString().substring(7);
    final newAppt = AppointmentModel(
      id: 'HG-2026-$idSuffix',
      userId: _currentUser!.uid,
      patientName: patientName,
      mobileNumber: mobileNumber,
      preferredDateTime: dateTime,
      doctorSpecialty: doctorSpecialty,
      symptomsSummary: symptomsSummary,
      status: 'Pending',
    );
    await _dbService.addAppointment(newAppt);
    
    // Add Notification
    await _dbService.addNotification(NotificationModel(
      id: 'notif_new_${DateTime.now().millisecondsSinceEpoch}',
      userId: _currentUser!.uid,
      title: 'Appointment Booked',
      body: 'Your appointment request for $doctorSpecialty (ID: ${newAppt.id}) is now Pending approval.',
      timestamp: DateTime.now(),
      category: 'Appointment',
    ));

    await reloadUserData();
    setLoading(false);
  }

  Future<void> createReminder({
    required String name,
    required String dosage,
    required String frequency,
    required String reminderTime,
  }) async {
    if (_currentUser == null) return;
    setLoading(true);
    final newReminder = MedicineReminderModel(
      id: 'rem_${DateTime.now().millisecondsSinceEpoch}',
      userId: _currentUser!.uid,
      name: name,
      dosage: dosage,
      frequency: frequency,
      reminderTime: reminderTime,
      isTaken: false,
    );
    await _dbService.addReminder(newReminder);
    await reloadUserData();
    setLoading(false);
  }

  Future<void> updateReminderStatus(String reminderId, bool isTaken) async {
    await _dbService.toggleReminderStatus(reminderId, isTaken);
    if (_currentUser != null) {
      _reminders = await _dbService.getReminders(_currentUser!.uid);
      notifyListeners();
    }
  }

  // Admin capabilities
  Future<List<AppointmentModel>> fetchAllAdminAppointments() async {
    return await _dbService.getAllAppointmentsAdmin();
  }

  Future<void> updateAppointmentStatusAdmin(String id, String status) async {
    await _dbService.updateAppointmentStatus(id, status);
    if (_currentUser != null) {
      await reloadUserData();
    }
  }

  Future<void> updateAdminProfile({
    required String name,
    required String email,
    String? profilePic,
  }) async {
    if (_currentUser == null) return;
    setLoading(true);
    try {
      final updated = await _authService.updateProfile(
        uid: _currentUser!.uid,
        fullName: name,
        email: email,
        profilePic: profilePic,
      );
      if (updated != null) {
        _currentUser = updated;
        notifyListeners();
      }
    } finally {
      setLoading(false);
    }
  }

  Future<void> updateAdminPassword({required String newPassword}) async {
    if (_currentUser == null) return;
    setLoading(true);
    try {
      await _authService.updatePassword(newPassword: newPassword);
    } finally {
      setLoading(false);
    }
  }
}

// InheritedNotifier wrapper for scoped access in Flutter Widget Tree
class AppStateProvider extends InheritedNotifier<AppState> {
  const AppStateProvider({
    Key? key,
    required AppState state,
    required Widget child,
  }) : super(key: key, notifier: state, child: child);

  static AppState of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<AppStateProvider>();
    assert(provider != null, 'No AppStateProvider found in context');
    return provider!.notifier!;
  }
}
