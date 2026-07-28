import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  UserProfile? _currentUser;
  final bool _useFirebase = true;

  Stream<UserProfile?> get authStateChanges => _authStateController.stream;
  UserProfile? get currentUser => _currentUser;
  bool get isFirebaseEnabled => _useFirebase;

  Future<void> init() async {
    final auth = FirebaseAuth.instance;

    // Listen to Firebase Auth state changes
    auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _currentUser = UserProfile(
          uid: user.uid,
          email: user.email ?? '',
          displayName: user.displayName ?? 'User',
          isMockUser: false,
        );
      } else {
        _currentUser = null;
      }
      _authStateController.add(_currentUser);
    });
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
    return null;
  }

  Future<void> sendForgotPasswordEmail(String email) async {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  Future<void> deleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.delete();
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
