import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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

  final _secureStorage = const FlutterSecureStorage();
  final _authStateController = StreamController<UserProfile?>.broadcast();
  
  UserProfile? _currentUser;
  bool _useFirebase = false;

  Stream<UserProfile?> get authStateChanges => _authStateController.stream;
  UserProfile? get currentUser => _currentUser;
  bool get isFirebaseEnabled => _useFirebase;

  Future<void> init() async {
    // Check if Firebase is initialized and configured
    try {
      final auth = FirebaseAuth.instance;
      _useFirebase = true;
      
      // Listen to Firebase Auth state changes
      auth.authStateChanges().listen((User? user) {
        if (user != null) {
          _currentUser = UserProfile(
            uid: user.uid,
            email: user.email ?? '',
            displayName: user.displayName ?? 'HealthSync User',
            isMockUser: false,
          );
        } else {
          _currentUser = null;
        }
        _authStateController.add(_currentUser);
      });
    } catch (_) {
      // Firebase not configured or failed to load. Use mock storage.
      _useFirebase = false;
      
      // Read saved credentials if any (Remember Login)
      final rememberedEmail = await _secureStorage.read(key: 'remembered_email');
      final rememberedUid = await _secureStorage.read(key: 'remembered_uid');
      if (rememberedEmail != null && rememberedUid != null) {
        _currentUser = UserProfile(
          uid: rememberedUid,
          email: rememberedEmail,
          displayName: rememberedEmail.split('@')[0],
          isMockUser: true,
        );
      }
      _authStateController.add(_currentUser);
    }
  }

  Future<UserProfile?> signInWithEmail(String email, String password, {bool rememberMe = true}) async {
    if (_useFirebase) {
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
          return profile;
        }
      } catch (e) {
        rethrow;
      }
    } else {
      // Offline mock authentication logic
      await Future.delayed(const Duration(milliseconds: 1000)); // Simulate networking
      
      if (email.contains('@') && password.length >= 6) {
        final profile = UserProfile(
          uid: 'MOCK-USER-12345',
          email: email,
          displayName: email.split('@')[0],
          isMockUser: true,
        );
        _currentUser = profile;
        _authStateController.add(profile);

        if (rememberMe) {
          await _secureStorage.write(key: 'remembered_email', value: email);
          await _secureStorage.write(key: 'remembered_uid', value: 'MOCK-USER-12345');
        }
        return profile;
      } else {
        throw FirebaseAuthException(
          code: 'wrong-password',
          message: 'Invalid credentials. Use any valid email and a password of at least 6 characters.',
        );
      }
    }
    return null;
  }

  Future<UserProfile?> registerWithEmail(String email, String password, String name) async {
    if (_useFirebase) {
      try {
        final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        final user = credential.user;
        if (user != null) {
          await user.updateDisplayName(name);
          final profile = UserProfile(
            uid: user.uid,
            email: user.email ?? '',
            displayName: name,
          );
          _currentUser = profile;
          _authStateController.add(profile);
          return profile;
        }
      } catch (e) {
        rethrow;
      }
    } else {
      await Future.delayed(const Duration(milliseconds: 1000));
      
      if (email.contains('@') && password.length >= 6) {
        final profile = UserProfile(
          uid: 'MOCK-USER-12345',
          email: email,
          displayName: name,
          isMockUser: true,
        );
        _currentUser = profile;
        _authStateController.add(profile);
        return profile;
      } else {
        throw FirebaseAuthException(
          code: 'email-already-in-use',
          message: 'Email input is invalid or password too weak.',
        );
      }
    }
    return null;
  }

  Future<void> sendForgotPasswordEmail(String email) async {
    if (_useFirebase) {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    } else {
      await Future.delayed(const Duration(milliseconds: 800));
      if (!email.contains('@')) {
        throw Exception('Invalid email address format.');
      }
    }
  }

  Future<void> signOut() async {
    if (_useFirebase) {
      await FirebaseAuth.instance.signOut();
    } else {
      _currentUser = null;
      _authStateController.add(null);
      await _secureStorage.delete(key: 'remembered_email');
      await _secureStorage.delete(key: 'remembered_uid');
    }
  }

  Future<void> deleteAccount() async {
    if (_useFirebase) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.delete();
      }
    } else {
      await signOut();
    }
  }

  // Google / Apple Login Simulation
  Future<UserProfile?> signInWithSocial(String provider) async {
    await Future.delayed(const Duration(milliseconds: 1200));
    final email = '${provider.toLowerCase()}user@healthsync.com';
    final profile = UserProfile(
      uid: 'MOCK-SOCIAL-${provider.toUpperCase()}',
      email: email,
      displayName: '${provider} User',
      isMockUser: true,
    );
    _currentUser = profile;
    _authStateController.add(profile);
    return profile;
  }
}
