import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'auth_service.dart';

class FirebaseAuthService implements AuthService {
  static final FirebaseAuthService _instance = FirebaseAuthService._internal();
  factory FirebaseAuthService() => _instance;
  FirebaseAuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AppUser? _currentUser;

  Future<AppUser?> _fetchUserFromFirestore(String uid, User fbUser) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        _currentUser = AppUser(
          uid: uid,
          fullName: data['fullName'] ?? fbUser.displayName ?? 'Unknown',
          email: data['email'] ?? fbUser.email ?? '',
          mobileNumber: data['mobileNumber'] ?? '',
          age: data['age'] ?? 0,
          gender: data['gender'] ?? 'Other',
          isAdmin: data['isAdmin'] ?? false,
          isEmailVerified: fbUser.emailVerified,
          profilePic: data['profilePic'],
        );
        return _currentUser;
      }
    } catch (e) {
      print('Error fetching user: $e');
    }
    return null;
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    if (_auth.currentUser != null) {
      return await _fetchUserFromFirestore(_auth.currentUser!.uid, _auth.currentUser!);
    }
    return null;
  }

  @override
  Future<AppUser?> signInWithEmail(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
      if (cred.user != null) {
        return await _fetchUserFromFirestore(cred.user!.uid, cred.user!);
      }
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Login failed');
    }
    return null;
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
    try {
      final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      if (cred.user != null) {
        final uid = cred.user!.uid;
        // Save extra data to Firestore
        await _firestore.collection('users').doc(uid).set({
          'uid': uid,
          'fullName': fullName,
          'email': email,
          'mobileNumber': mobile,
          'age': age,
          'gender': gender,
          'isAdmin': false,
          'createdAt': Timestamp.now(),
        });
        
        _currentUser = AppUser(
          uid: uid,
          fullName: fullName,
          email: email,
          mobileNumber: mobile,
          age: age,
          gender: gender,
          isAdmin: false,
          isEmailVerified: cred.user!.emailVerified,
        );
        return _currentUser;
      }
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Registration failed');
    }
    return null;
  }

  @override
  Future<AppUser?> signInWithGoogle({String? email, String? displayName}) async {
    try {
      // NOTE: For Google Sign-In to work on Flutter Web, you MUST provide a Web Client ID.
      // You can find this in your Firebase Console -> Authentication -> Settings -> Web Client ID
      // or in Google Cloud Console under Credentials.
      // Replace the string below with your actual Web Client ID ending in apps.googleusercontent.com
      final GoogleSignInAccount? googleUser = await GoogleSignIn(
        clientId: kIsWeb ? '125323774503-qnq955u6l6oosuocnidvrq0akuk5cblq.apps.googleusercontent.com' : null,
      ).signIn();
      if (googleUser == null) return null; // User canceled the sign-in

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? fbUser = userCredential.user;

      if (fbUser != null) {
        // Check if user exists in Firestore
        final doc = await _firestore.collection('users').doc(fbUser.uid).get();
        if (!doc.exists) {
           await _firestore.collection('users').doc(fbUser.uid).set({
             'uid': fbUser.uid,
             'fullName': fbUser.displayName ?? 'Google User',
             'email': fbUser.email ?? '',
             'mobileNumber': '',
             'age': 0,
             'gender': 'Other',
             'isAdmin': false,
             'createdAt': Timestamp.now(),
             'profilePic': fbUser.photoURL,
           });
        }
        return await _fetchUserFromFirestore(fbUser.uid, fbUser);
      }
    } catch (e) {
      print('Google Sign-In Error: $e');
      throw Exception('Google Sign-In failed: $e');
    }
    return null;
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  @override
  Future<void> logout() async {
    await _auth.signOut();
    _currentUser = null;
  }

  @override
  Future<AppUser?> updateProfile({
    required String uid,
    required String fullName,
    required String email,
    String? profilePic,
  }) async {
    if (_auth.currentUser != null) {
      await _firestore.collection('users').doc(uid).update({
        'fullName': fullName,
        'email': email,
        if (profilePic != null) 'profilePic': profilePic,
      });
      // Optionally update Firebase Auth display name / email if needed
      return await _fetchUserFromFirestore(uid, _auth.currentUser!);
    }
    return null;
  }

  @override
  Future<void> updatePassword({required String newPassword}) async {
    if (_auth.currentUser != null) {
      await _auth.currentUser!.updatePassword(newPassword);
    }
  }
}
