import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';
import 'ble/ble_service.dart';
import 'ble/mock_ble_service.dart';
import 'ble/real_ble_service.dart';
import 'database/database_service.dart';
import 'database/isar_models.dart';
import 'notifications/notifications_service.dart';

// --- Services Providers ---
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  throw UnimplementedError('databaseServiceProvider is not overridden');
});

final authServiceProvider = Provider<AuthService>((ref) {
  throw UnimplementedError('authServiceProvider is not overridden');
});

final notificationsServiceProvider = Provider<NotificationsService>((ref) {
  final db = ref.watch(databaseServiceProvider);
  return NotificationsService()..init(db);
});

// --- Auth States ---
final authStateProvider = StreamProvider<UserProfile?>((ref) {
  final auth = ref.watch(authServiceProvider);
  return auth.authStateChanges;
});

// --- Settings State ---
class SettingsNotifier extends StateNotifier<SettingsModel> {
  final DatabaseService _db;
  SettingsNotifier(this._db) : super(SettingsModel()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await _db.getSettings();
    state = settings;
  }

  Future<void> updateSettings(SettingsModel newSettings) async {
    await _db.saveSettings(newSettings);
    state = newSettings;
  }

  Future<void> toggleDarkMode(bool enabled) async {
    state.isDarkMode = enabled;
    state.themeMode = enabled ? 'dark' : 'light';
    await updateSettings(state);
  }

  Future<void> updateThemeMode(String mode) async {
    state.themeMode = mode;
    if (mode == 'dark') {
      state.isDarkMode = true;
    } else if (mode == 'light') {
      state.isDarkMode = false;
    }
    await updateSettings(state);
  }

  Future<void> toggleDeveloperMode(bool enabled) async {
    state.isDeveloperMode = enabled;
    await updateSettings(state);
  }

  Future<void> updateUnits(String unitSystem) async {
    state.unitSystem = unitSystem;
    await updateSettings(state);
  }

  Future<void> updateLanguage(String languageCode) async {
    state.languageCode = languageCode;
    await updateSettings(state);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsModel>(
  (ref) {
    final db = ref.watch(databaseServiceProvider);
    return SettingsNotifier(db);
  },
);

// --- Profile State ---
class ProfileNotifier extends StateNotifier<UserProfileModel> {
  final DatabaseService _db;
  bool _isLoaded = false;

  ProfileNotifier(this._db) : super(UserProfileModel()) {
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await _db.getUserProfile();
    if (profile != null) {
      state = profile;
    }
    _isLoaded = true;
    
    // Sync with Firestore if user is already logged in
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      await syncWithFirestore();
    }
  }

  Future<void> updateProfile(UserProfileModel newProfile) async {
    // 1. Save locally
    await _db.saveUserProfile(newProfile);
    state = newProfile;

    // 2. Upload to Firestore (if online/logged in)
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      try {
        final docRef = FirebaseFirestore.instance.collection('users').doc(firebaseUser.uid);
        final map = _profileToMap(newProfile);
        map['email'] = firebaseUser.email;
        // Merge with existing Firestore data
        await docRef.set(map, SetOptions(merge: true));

        // Also update the display name in Firebase Auth if it changed
        if (newProfile.name != null && newProfile.name != firebaseUser.displayName) {
          await firebaseUser.updateDisplayName(newProfile.name);
        }
      } catch (e) {
        debugPrint('Failed to save profile to Firestore: $e');
      }
    }
  }

  Future<void> updateLocalNameAndEmail(String name, String email) async {
    final updated = UserProfileModel()
      ..id = state.id
      ..name = name
      ..email = email
      ..age = state.age
      ..gender = state.gender
      ..heightCm = state.heightCm
      ..weightKg = state.weightKg
      ..dailyStepGoal = state.dailyStepGoal
      ..dailyWaterGoal = state.dailyWaterGoal
      ..dailyCaloriesGoal = state.dailyCaloriesGoal
      ..targetSleepHours = state.targetSleepHours;
    await _db.saveUserProfile(updated);
    state = updated;
  }

  Future<void> syncWithFirestore({String? displayName}) async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return;

    try {
      await firebaseUser.reload();
    } catch (e) {
      debugPrint('Failed to reload firebase user: $e');
    }

    final updatedUser = FirebaseAuth.instance.currentUser ?? firebaseUser;
    final String resolvedName = displayName ?? updatedUser.displayName ?? 'User';

    final uid = updatedUser.uid;

    try {
      final docRef = FirebaseFirestore.instance.collection('users').doc(uid);
      final doc = await docRef.get();
      if (doc.exists) {
        // Document exists in Firestore -> download and update local Isar database
        final data = doc.data();
        if (data != null) {
          final updated = _profileFromMap(data, state);
          
          // If Firestore has a placeholder name, but we have a valid real name, update Firestore and local state
          if (resolvedName != 'User' && resolvedName != 'Jane Doe') {
            if (updated.name == null || updated.name == 'User' || updated.name == 'Jane Doe') {
              updated.name = resolvedName;
              await docRef.update({'name': resolvedName});
            }
          }

          // If Firestore has no email but we have it, update Firestore
          if (updated.email == null && updatedUser.email != null) {
            updated.email = updatedUser.email;
            await docRef.update({'email': updatedUser.email});
          }
          
          await _db.saveUserProfile(updated);
          state = updated;
        }
      } else {
        // Document does not exist in Firestore -> upload local Isar database data to Firestore
        final map = _profileToMap(state);
        map['email'] = updatedUser.email;
        if (map['name'] == null || map['name'] == 'Jane Doe' || map['name'] == 'User') {
          map['name'] = resolvedName;
        }
        await docRef.set(map);

        // Also update local state name and email if they are empty
        if (state.name == null || state.name == 'Jane Doe' || state.name == 'User' || state.email == null) {
          final updated = UserProfileModel()
            ..id = state.id
            ..name = resolvedName
            ..email = updatedUser.email
            ..age = state.age
            ..gender = state.gender
            ..heightCm = state.heightCm
            ..weightKg = state.weightKg
            ..dailyStepGoal = state.dailyStepGoal
            ..dailyWaterGoal = state.dailyWaterGoal
            ..dailyCaloriesGoal = state.dailyCaloriesGoal
            ..targetSleepHours = state.targetSleepHours;
          await _db.saveUserProfile(updated);
          state = updated;
        }
      }
    } catch (e) {
      debugPrint('Firestore sync failed: $e');
    }
  }

  Map<String, dynamic> _profileToMap(UserProfileModel profile) {
    return {
      'name': profile.name,
      'email': profile.email,
      'age': profile.age,
      'gender': profile.gender,
      'heightCm': profile.heightCm,
      'weightKg': profile.weightKg,
      'dailyStepGoal': profile.dailyStepGoal,
      'dailyWaterGoal': profile.dailyWaterGoal,
      'dailyCaloriesGoal': profile.dailyCaloriesGoal,
      'targetSleepHours': profile.targetSleepHours,
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  UserProfileModel _profileFromMap(Map<String, dynamic> data, UserProfileModel existing) {
    return UserProfileModel()
      ..id = existing.id
      ..name = data['name'] as String? ?? existing.name
      ..email = data['email'] as String? ?? existing.email
      ..age = data['age'] as int? ?? existing.age
      ..gender = data['gender'] as String? ?? existing.gender
      ..heightCm = (data['heightCm'] as num?)?.toDouble() ?? existing.heightCm
      ..weightKg = (data['weightKg'] as num?)?.toDouble() ?? existing.weightKg
      ..dailyStepGoal = data['dailyStepGoal'] as int? ?? existing.dailyStepGoal
      ..dailyWaterGoal = data['dailyWaterGoal'] as int? ?? existing.dailyWaterGoal
      ..dailyCaloriesGoal = data['dailyCaloriesGoal'] as int? ?? existing.dailyCaloriesGoal
      ..targetSleepHours = (data['targetSleepHours'] as num?)?.toDouble() ?? existing.targetSleepHours;
  }
}

final profileProvider =
    StateNotifierProvider<ProfileNotifier, UserProfileModel>((ref) {
      final db = ref.watch(databaseServiceProvider);
      final notifier = ProfileNotifier(db);

      // Listen to auth state changes to sync profile with Firestore
      ref.listen(authStateProvider, (previous, next) {
        next.whenData((user) {
          if (user != null) {
            // Update local state name immediately if it is a placeholder
            if (user.displayName != 'User' && user.displayName.isNotEmpty) {
              if (notifier.state.name == null || notifier.state.name == 'Jane Doe' || notifier.state.name == 'User') {
                notifier.updateLocalNameAndEmail(user.displayName, user.email);
              }
            }
            notifier.syncWithFirestore(displayName: user.displayName);
          }
        });
      });

      // Initial check if auth state is already loaded
      final authState = ref.read(authStateProvider);
      authState.whenData((user) {
        if (user != null) {
          if (user.displayName != 'User' && user.displayName.isNotEmpty) {
            if (notifier.state.name == null || notifier.state.name == 'Jane Doe' || notifier.state.name == 'User') {
              notifier.updateLocalNameAndEmail(user.displayName, user.email);
            }
          }
          notifier.syncWithFirestore(displayName: user.displayName);
        }
      });

      return notifier;
    });

// --- BLE Providers ---
final bleServiceProvider = Provider<BleService>((ref) {
  final settings = ref.watch(settingsProvider);
  final isDev = settings.isDeveloperMode ?? true;

  if (isDev) {
    final mockService = MockBleService();
    // Sync profile weight/height with simulator for calorie estimation
    final profile = ref.watch(profileProvider);
    mockService.weightKg = profile.weightKg ?? 62.0;
    mockService.heightCm = profile.heightCm ?? 168.0;
    mockService.gender = profile.gender ?? 'Female';
    return mockService;
  } else {
    final realService = RealBleService();
    final profile = ref.watch(profileProvider);
    realService.updateProfileData(
      weight: profile.weightKg ?? 62.0,
      height: profile.heightCm ?? 168.0,
      sex: profile.gender ?? 'Female',
    );
    return realService;
  }
});

final bleConnectionStateProvider = StreamProvider<BleConnectionState>((ref) {
  final ble = ref.watch(bleServiceProvider);
  return ble.connectionStateStream;
});

final scanResultsStreamProvider = StreamProvider<List<BleDevice>>((ref) {
  final ble = ref.watch(bleServiceProvider);
  return ble.scanResultsStream;
});

final vitalsStreamProvider = StreamProvider<BleVitalsData>((ref) {
  final ble = ref.watch(bleServiceProvider);
  return ble.vitalsStream;
});

final rssiStreamProvider = StreamProvider<int>((ref) {
  final ble = ref.watch(bleServiceProvider);
  return ble.rssiStream;
});

// --- Background Caching Sync Listener ---
// Reads data incoming from BLE, caches it in Isar, checks alerts thresholds, and saves daily goals completion
final vitalsCacheListenerProvider = Provider<void>((ref) {
  final db = ref.watch(databaseServiceProvider);
  final ble = ref.watch(bleServiceProvider);
  final profile = ref.watch(profileProvider);
  final notifier = ref.watch(notificationsServiceProvider);

  // Setup connection state notifications alert listener
  ble.connectionStateStream.listen((state) {
    final isConnected = state == BleConnectionState.connected;
    final deviceName = ble.connectedDeviceName ?? 'Wearable Sensor';
    notifier.triggerConnectionAlert(isConnected, deviceName);
  });

  // Setup live data sync and vital threshold alarm evaluator
  ble.vitalsStream.listen((vitals) async {
    // Only cache positive live metrics
    if (vitals.heartRate > 0 || vitals.steps > 0 || vitals.spo2 > 0) {
      final point = HealthDataPointModel()
        ..timestamp = vitals.timestamp
        ..heartRate = vitals.heartRate
        ..steps = vitals.steps
        ..spo2 = vitals.spo2
        ..temperature = vitals.temperature
        ..batteryLevel = vitals.batteryLevel
        ..caloriesBurned = vitals.caloriesBurned;

      await db.saveHealthDataPoint(point);

      // Verify and record progress against current daily goals
      final today = DateTime.now();
      final progress =
          await db.getGoalProgressForDate(today) ??
          (GoalProgressModel()..date = today);

      progress.stepsCount = vitals.steps;
      progress.caloriesBurned = vitals.caloriesBurned;

      final stepGoal = profile.dailyStepGoal ?? 10000;
      final calGoal = profile.dailyCaloriesGoal ?? 2200;

      progress.stepsGoalAchieved = vitals.steps >= stepGoal;
      progress.caloriesGoalAchieved = vitals.caloriesBurned >= calGoal;

      await db.saveGoalProgress(progress);

      // Evaluate limits to push custom health notifications alerts
      await notifier.evaluateVitalsAlerts(
        vitals.heartRate,
        vitals.spo2,
        vitals.batteryLevel,
        vitals.steps,
        stepGoal,
      );
    }
  });
});
