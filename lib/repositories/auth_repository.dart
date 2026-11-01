import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  static final UserModel defaultAdminUser = UserModel(
    id: 'admin_nayagra_01',
    email: 'admin@nayagra.com',
    displayName: 'Administrator (Nayagra)',
    role: 'admin',
    createdAt: DateTime(2026, 1, 1),
  );

  AuthRepository({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  UserModel? _currentUser;
  bool _isDemoSession = false;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null || _firebaseAuth.currentUser != null;

  Stream<UserModel?> get authStateChanges {
    return _firebaseAuth.authStateChanges().asyncMap((user) async {
      if (user != null) {
        String role = 'admin';
        String displayName = user.displayName ?? (user.email?.split('@').first ?? 'Administrator');

        try {
          final userDoc = await _firestore.collection('users').doc(user.uid).get();
          if (userDoc.exists) {
            final data = userDoc.data();
            role = data?['role'] ?? 'admin';
            displayName = data?['displayName'] ?? displayName;
          }
        } catch (e) {
          debugPrint('Error fetching user profile doc: $e');
        }

        _currentUser = UserModel(
          id: user.uid,
          email: user.email ?? 'admin@nayagra.com',
          displayName: displayName,
          role: role,
        );
        return _currentUser;
      }
      if (_isDemoSession && _currentUser != null) {
        return _currentUser;
      }
      return _currentUser;
    }).handleError((err) {
      debugPrint('Stream authStateChanges error: $err');
      return _currentUser;
    });
  }

  /// Single default login handler
  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim();

    // Check if this is the default admin login
    final isDefaultAdmin = cleanEmail.toLowerCase() == 'admin@nayagra.com' && password == 'admin123';

    try {
      // 1. Attempt Firebase Auth sign-in
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );
      final user = credential.user;

      String role = 'admin';
      String displayName = user?.displayName ?? cleanEmail.split('@').first;

      try {
        if (user != null) {
          final doc = await _firestore.collection('users').doc(user.uid).get();
          if (doc.exists) {
            role = doc.data()?['role'] ?? 'admin';
            displayName = doc.data()?['displayName'] ?? displayName;
          }
        }
      } catch (_) {}

      final userModel = UserModel(
        id: user?.uid ?? 'uid_admin',
        email: user?.email ?? cleanEmail,
        displayName: displayName,
        role: role,
      );
      _currentUser = userModel;
      _isDemoSession = false;
      return userModel;
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException during login: ${e.code}');

      // If user doesn't exist in Firebase yet, try creating it automatically in the cloud
      if (e.code == 'user-not-found' || isDefaultAdmin) {
        try {
          final newCred = await _firebaseAuth.createUserWithEmailAndPassword(
            email: cleanEmail,
            password: password,
          );
          final newUser = newCred.user;
          if (newUser != null) {
            await newUser.updateDisplayName('Administrator (Nayagra)');
            await _firestore.collection('users').doc(newUser.uid).set({
              'id': newUser.uid,
              'email': cleanEmail,
              'displayName': 'Administrator (Nayagra)',
              'role': 'admin',
              'createdAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          }
          final userModel = UserModel(
            id: newUser?.uid ?? 'uid_admin',
            email: cleanEmail,
            displayName: 'Administrator (Nayagra)',
            role: 'admin',
          );
          _currentUser = userModel;
          _isDemoSession = false;
          return userModel;
        } catch (createErr) {
          debugPrint('Could not auto-create in Firebase Auth ($createErr). Using default admin session.');
        }
      }

      // If Firebase Auth is not activated (configuration-not-found), allow default admin login
      if (isDefaultAdmin ||
          e.code == 'configuration-not-found' ||
          e.code == 'network-request-failed' ||
          e.code == 'operation-not-allowed') {
        _currentUser = defaultAdminUser;
        _isDemoSession = true;
        return defaultAdminUser;
      }

      rethrow;
    } catch (e) {
      debugPrint('Generic auth error: $e');
      if (isDefaultAdmin) {
        _currentUser = defaultAdminUser;
        _isDemoSession = true;
        return defaultAdminUser;
      }
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      debugPrint('Error signing out of Firebase: $e');
    }
    _currentUser = null;
    _isDemoSession = false;
  }
}
