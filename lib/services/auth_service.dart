import 'dart:async';

class AppUser {
  final String uid;
  final String fullName;
  final String email;
  final String mobileNumber;
  final int age;
  final String gender;
  final bool isAdmin;
  final bool isEmailVerified;
  final String? profilePic;

  String get name => fullName;

  AppUser({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.mobileNumber,
    required this.age,
    required this.gender,
    this.isAdmin = false,
    this.isEmailVerified = false,
    this.profilePic,
  });

  AppUser copyWith({
    String? fullName,
    String? email,
    String? mobileNumber,
    int? age,
    String? gender,
    bool? isEmailVerified,
    String? profilePic,
  }) {
    return AppUser(
      uid: uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      isAdmin: isAdmin,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      profilePic: profilePic ?? this.profilePic,
    );
  }
}

abstract class AuthService {
  Future<AppUser?> getCurrentUser();
  Future<AppUser?> signInWithEmail(String email, String password);
  Future<AppUser?> registerWithEmail({
    required String fullName,
    required String email,
    required String mobile,
    required int age,
    required String gender,
    required String password,
  });
  Future<AppUser?> signInWithGoogle({String? email, String? displayName});
  Future<void> sendPasswordReset(String email);
  Future<void> logout();
  Future<AppUser?> updateProfile({required String uid, required String fullName, required String email, String? profilePic});
  Future<void> updatePassword({required String newPassword});
}

/// A Mock Implementation of Firebase Auth.
/// To switch to real Firebase, integrate firebase_auth package and replace instances with FirebaseAuthServiceImpl.
class MockAuthService implements AuthService {
  static final MockAuthService _instance = MockAuthService._internal();
  factory MockAuthService() => _instance;
  MockAuthService._internal();

  AppUser? _currentUser;
  
  // Brute force protection state variables
  int _failedLoginAttempts = 0;
  DateTime? _lockoutUntil;

  // Simulated local database of users
  final Map<String, _MockUserCredentials> _usersDb = {
    'admin@gmail.com': _MockUserCredentials(
      user: AppUser(
        uid: 'admin_uid_01',
        fullName: 'Dr. Sarah Connor (Admin)',
        email: 'admin@gmail.com',
        mobileNumber: '+1 555-0199',
        age: 38,
        gender: 'Female',
        isAdmin: true,
        isEmailVerified: true,
        profilePic: 'admin_avatar_1',
      ),
      password: '123',
    ),
    'user@gmail.com': _MockUserCredentials(
      user: AppUser(
        uid: 'user_uid_01',
        fullName: 'Alex Carter',
        email: 'user@gmail.com',
        mobileNumber: '+1 555-0122',
        age: 29,
        gender: 'Male',
        isAdmin: false,
        isEmailVerified: true,
        profilePic: 'user_avatar_2',
      ),
      password: '123',
    )
  };

  @override
  Future<AppUser?> getCurrentUser() async {
    return _currentUser;
  }

  @override
  Future<AppUser?> signInWithEmail(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 800)); // Network delay simulation
    final cleanEmail = email.trim().toLowerCase();
    
    // Check brute-force lockout status
    if (_lockoutUntil != null && DateTime.now().isBefore(_lockoutUntil!)) {
      final diff = _lockoutUntil!.difference(DateTime.now()).inSeconds;
      throw Exception('Too many failed attempts. Account locked. Please try again in $diff seconds.');
    }
    
    if (_usersDb.containsKey(cleanEmail)) {
      final creds = _usersDb[cleanEmail]!;
      if (creds.password == password) {
        _failedLoginAttempts = 0;
        _lockoutUntil = null;
        _currentUser = creds.user;
        return _currentUser;
      } else {
        _failedLoginAttempts++;
        if (_failedLoginAttempts >= 3) {
          _lockoutUntil = DateTime.now().add(const Duration(seconds: 30));
          _failedLoginAttempts = 0;
          throw Exception('Too many failed attempts. Account locked for 30 seconds.');
        }
        throw Exception('Incorrect password. Please try again.');
      }
    } else {
      throw Exception('No account found for this email address.');
    }
  }

  @override
  Future<AppUser?> registerWithEmail({
    required String fullName,
    required String email,
    required String mobile,
    required int age,
    required String gender,
    required String password,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    final cleanEmail = email.trim().toLowerCase();
    
    if (_usersDb.containsKey(cleanEmail)) {
      throw Exception('An account with this email already exists.');
    }

    final newUser = AppUser(
      uid: 'user_uid_${DateTime.now().millisecondsSinceEpoch}',
      fullName: fullName,
      email: cleanEmail,
      mobileNumber: mobile,
      age: age,
      gender: gender,
      isAdmin: false,
      isEmailVerified: false,
      profilePic: 'user_avatar_default',
    );

    _usersDb[cleanEmail] = _MockUserCredentials(user: newUser, password: password);
    _currentUser = newUser;
    return newUser;
  }

  @override
  Future<AppUser?> signInWithGoogle({String? email, String? displayName}) async {
    await Future.delayed(const Duration(seconds: 1));
    final googleEmail = email ?? 'google.user@gmail.com';
    final googleName = displayName ?? 'Google User';
    
    if (!_usersDb.containsKey(googleEmail)) {
      final newUser = AppUser(
        uid: 'google_uid_${DateTime.now().millisecondsSinceEpoch}',
        fullName: googleName,
        email: googleEmail,
        mobileNumber: '+1 555-0999',
        age: 30,
        gender: 'Male',
        isAdmin: googleEmail.toLowerCase().contains('admin'),
        isEmailVerified: true,
        profilePic: 'google_avatar',
      );
      _usersDb[googleEmail] = _MockUserCredentials(user: newUser, password: '');
    }
    
    _currentUser = _usersDb[googleEmail]!.user;
    return _currentUser;
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final cleanEmail = email.trim().toLowerCase();
    if (!_usersDb.containsKey(cleanEmail)) {
      throw Exception('No registered account was found with that email.');
    }
  }

  @override
  Future<void> logout() async {
    _currentUser = null;
  }

  @override
  Future<AppUser?> updateProfile({
    required String uid,
    required String fullName,
    required String email,
    String? profilePic,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (_currentUser != null && _currentUser!.uid == uid) {
      final oldEmail = _currentUser!.email;
      final cleanEmail = email.trim().toLowerCase();
      
      final creds = _usersDb.remove(oldEmail);
      if (creds != null) {
        final updatedUser = creds.user.copyWith(
          fullName: fullName,
          email: cleanEmail,
          profilePic: profilePic,
        );
        _usersDb[cleanEmail] = _MockUserCredentials(user: updatedUser, password: creds.password);
        _currentUser = updatedUser;
        return _currentUser;
      }
    }
    return _currentUser;
  }

  @override
  Future<void> updatePassword({required String newPassword}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (_currentUser != null) {
      final email = _currentUser!.email;
      if (_usersDb.containsKey(email)) {
        final creds = _usersDb[email]!;
        _usersDb[email] = _MockUserCredentials(user: creds.user, password: newPassword);
      }
    }
  }
}

class _MockUserCredentials {
  final AppUser user;
  final String password;

  _MockUserCredentials({required this.user, required this.password});
}
