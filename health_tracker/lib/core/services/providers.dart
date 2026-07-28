import 'package:flutter_riverpod/flutter_riverpod.dart';
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

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsModel>((ref) {
  final db = ref.watch(databaseServiceProvider);
  return SettingsNotifier(db);
});

// --- Profile State ---
class ProfileNotifier extends StateNotifier<UserProfileModel> {
  final DatabaseService _db;
  ProfileNotifier(this._db) : super(UserProfileModel()) {
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await _db.getUserProfile();
    if (profile != null) {
      state = profile;
    }
  }

  Future<void> updateProfile(UserProfileModel newProfile) async {
    await _db.saveUserProfile(newProfile);
    state = newProfile;
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, UserProfileModel>((ref) {
  final db = ref.watch(databaseServiceProvider);
  return ProfileNotifier(db);
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
      final progress = await db.getGoalProgressForDate(today) ?? (GoalProgressModel()..date = today);

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
