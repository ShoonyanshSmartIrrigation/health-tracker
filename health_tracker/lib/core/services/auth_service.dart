import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

class UserProfile {
  final String uid;
  final String email;
  final String displayName;
  final bool isMockUser;

  UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    this.isMockUser = false,
  });
}

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final _authStateController = StreamController<UserProfile?>.broadcast();
  final _secureStorage = const FlutterSecureStorage();

  UserProfile? _currentUser;
  final bool _useFirebase = true;

  // Secure Storage Keys
  static const _keyIsLoggedIn = 'is_logged_in';
  static const _keyUserId = 'user_id';
  static const _keyUserEmail = 'user_email';
  static const _keyUserName = 'user_name';

  Stream<UserProfile?> get authStateChanges async* {
    yield _currentUser;
    yield* _authStateController.stream;
  }
  UserProfile? get currentUser => _currentUser;
  bool get isFirebaseEnabled => _useFirebase;

  Future<void> init() async {
    final auth = FirebaseAuth.instance;

    // Load initial user state from secure storage if logged in
    try {
      final isLoggedInStr = await _secureStorage.read(key: _keyIsLoggedIn);
      if (isLoggedInStr == 'true') {
        final uid = await _secureStorage.read(key: _keyUserId);
        final email = await _secureStorage.read(key: _keyUserEmail);
        final name = await _secureStorage.read(key: _keyUserName);
        if (uid != null && email != null) {
          _currentUser = UserProfile(
            uid: uid,
            email: email,
            displayName: name ?? 'User',
            isMockUser: false,
          );
          _authStateController.add(_currentUser);
        }
      }
    } catch (e) {
      debugPrint('Failed to load user state from secure storage: $e');
    }

    // Listen to Firebase Auth state changes
    auth.authStateChanges().listen((User? user) async {
      if (user != null) {
        _currentUser = UserProfile(
          uid: user.uid,
          email: user.email ?? '',
          displayName: user.displayName ?? 'User',
          isMockUser: false,
        );
        // Sync to secure storage
        try {
          await _secureStorage.write(key: _keyIsLoggedIn, value: 'true');
          await _secureStorage.write(key: _keyUserId, value: user.uid);
          await _secureStorage.write(key: _keyUserEmail, value: user.email ?? '');
          await _secureStorage.write(key: _keyUserName, value: _currentUser!.displayName);
        } catch (e) {
          debugPrint('Failed to save state to secure storage: $e');
        }
      } else {
        _currentUser = null;
        // Sync to secure storage
        try {
          await _secureStorage.write(key: _keyIsLoggedIn, value: 'false');
          await _secureStorage.delete(key: _keyUserId);
          await _secureStorage.delete(key: _keyUserEmail);
          await _secureStorage.delete(key: _keyUserName);
        } catch (e) {
          debugPrint('Failed to clear state in secure storage: $e');
        }
      }
      _authStateController.add(_currentUser);
    });
  }

  Future<bool> isUserLoggedInSecurely() async {
    try {
      final val = await _secureStorage.read(key: _keyIsLoggedIn);
      return val == 'true';
    } catch (_) {
      return false;
    }
  }

  Future<UserProfile?> signInWithEmail(
    String email,
    String password, {
    bool rememberMe = true,
  }) async {
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user != null) {
        final profile = UserProfile(
          uid: user.uid,
          email: user.email ?? '',
          displayName: user.displayName ?? email.split('@')[0],
        );
        _currentUser = profile;
        _authStateController.add(profile);

        // Store login state in secure storage
        try {
          await _secureStorage.write(key: _keyIsLoggedIn, value: 'true');
          await _secureStorage.write(key: _keyUserId, value: user.uid);
          await _secureStorage.write(key: _keyUserEmail, value: user.email ?? '');
          await _secureStorage.write(key: _keyUserName, value: profile.displayName);
        } catch (e) {
          debugPrint('Failed to save sign-in credentials to secure storage: $e');
        }

        return profile;
      }
    } catch (e) {
      rethrow;
    }
    return null;
  }

  Future<UserProfile?> registerWithEmail(
    String email,
    String password,
    String name,
  ) async {
    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      final user = credential.user;
      if (user != null) {
        await user.updateDisplayName(name);

        // Save name and email in Firestore database at the time of sign up
        try {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'name': name,
            'email': email,
            'updatedAt': DateTime.now().toIso8601String(),
          }, SetOptions(merge: true));
        } catch (e) {
          debugPrint('Failed to save user profile to Firestore at sign up: $e');
        }

        // Save name and email in Firebase Realtime Database at the time of sign up
        try {
          // Firebase Realtime Database does not allow '.' in path keys, so we sanitize it to '_'
          final sanitizedEmail = email.replaceAll('.', '_');
          final dbRef = FirebaseDatabase.instanceFor(
            app: Firebase.app(),
            databaseURL: 'https://health-tracker-bf9f0-default-rtdb.asia-southeast1.firebasedatabase.app',
          ).ref('$sanitizedEmail/${user.uid}');
          await dbRef.set({
            'name': name,
            'email': email,
            'updatedAt': DateTime.now().toIso8601String(),
          });
        } catch (e) {
          debugPrint('Failed to save user profile to Realtime Database at sign up: $e');
        }

        final profile = UserProfile(
          uid: user.uid,
          email: user.email ?? '',
          displayName: name,
        );
        _currentUser = profile;
        _authStateController.add(profile);

        // Store login state in secure storage
        try {
          await _secureStorage.write(key: _keyIsLoggedIn, value: 'true');
          await _secureStorage.write(key: _keyUserId, value: user.uid);
          await _secureStorage.write(key: _keyUserEmail, value: user.email ?? '');
          await _secureStorage.write(key: _keyUserName, value: name);
        } catch (e) {
          debugPrint('Failed to save registration credentials to secure storage: $e');
        }

        return profile;
      }
    } catch (e) {
      rethrow;
    }
    return null;
  }

  Future<void> sendForgotPasswordEmail(String email) async {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    _currentUser = null;
    _authStateController.add(null);
    try {
      await _secureStorage.write(key: _keyIsLoggedIn, value: 'false');
      await _secureStorage.delete(key: _keyUserId);
      await _secureStorage.delete(key: _keyUserEmail);
      await _secureStorage.delete(key: _keyUserName);
    } catch (e) {
      debugPrint('Failed to clear secure storage during signOut: $e');
    }
  }

  Future<void> deleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.delete();
      _currentUser = null;
      _authStateController.add(null);
      try {
        await _secureStorage.write(key: _keyIsLoggedIn, value: 'false');
        await _secureStorage.delete(key: _keyUserId);
        await _secureStorage.delete(key: _keyUserEmail);
        await _secureStorage.delete(key: _keyUserName);
      } catch (e) {
        debugPrint('Failed to clear secure storage during deleteAccount: $e');
      }
    }
  }

  // Social Sign-in is not configured at Firebase Console level yet
  Future<UserProfile?> signInWithSocial(String provider) async {
    throw FirebaseAuthException(
      code: 'operation-not-allowed',
      message:
          'Social sign-in with $provider is not configured. Please sign in with email and password.',
    );
  }
}
