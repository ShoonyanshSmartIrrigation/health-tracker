import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'isar_models.dart';

class DatabaseService {
  late Isar _isar;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  Future<void> init() async {
    if (_isInitialized) return;

    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [
        UserProfileModelSchema,
        HealthDataPointModelSchema,
        GoalProgressModelSchema,
        NotificationLogModelSchema,
        SettingsModelSchema,
      ],
      directory: dir.path,
      inspector: true, // Enable local Isar inspector for debugging
    );

    // Write default settings if none exist
    final count = await _isar.settingsModels.count();
    if (count == 0) {
      await _isar.writeTxn(() async {
        await _isar.settingsModels.put(
          SettingsModel()
            ..isDarkMode = true
            ..themeMode = 'system'
            ..languageCode = 'en'
            ..unitSystem = 'metric'
            ..autoReconnect = true
            ..enableNotifications = true
            ..isDeveloperMode = true, // Default to true so simulator starts working
        );
      });
    }

    // Write default profile if none exists
    final profileCount = await _isar.userProfileModels.count();
    if (profileCount == 0) {
      await _isar.writeTxn(() async {
        await _isar.userProfileModels.put(
          UserProfileModel()
            ..name = 'Jane Doe'
            ..age = 28
            ..gender = 'Female'
            ..heightCm = 168.0
            ..weightKg = 62.0
            ..dailyStepGoal = 10000
            ..dailyWaterGoal = 2500
            ..dailyCaloriesGoal = 2200
            ..targetSleepHours = 8.0,
        );
      });
    }

    _isInitialized = true;
  }

  // --- Profile CRUD ---
  Future<UserProfileModel?> getUserProfile() async {
    return await _isar.userProfileModels.where().findFirst();
  }

  Future<void> saveUserProfile(UserProfileModel profile) async {
    await _isar.writeTxn(() async {
      await _isar.userProfileModels.put(profile);
    });
  }

  // --- Vitals Logs ---
  Future<void> saveHealthDataPoint(HealthDataPointModel point) async {
    await _isar.writeTxn(() async {
      await _isar.healthDataPointModels.put(point);
    });
  }

  Future<List<HealthDataPointModel>> getHealthDataPoints(DateTime start, DateTime end) async {
    return await _isar.healthDataPointModels
        .filter()
        .timestampBetween(start, end)
        .sortByTimestamp()
        .findAll();
  }

  Future<List<HealthDataPointModel>> getRecentHealthPoints(int limit) async {
    return await _isar.healthDataPointModels
        .where()
        .sortByTimestampDesc()
        .limit(limit)
        .findAll();
  }

  // --- Goal Progress CRUD ---
  Future<GoalProgressModel?> getGoalProgressForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    return await _isar.goalProgressModels
        .filter()
        .dateEqualTo(startOfDay)
        .findFirst();
  }

  Future<void> saveGoalProgress(GoalProgressModel progress) async {
    final startOfDay = DateTime(progress.date!.year, progress.date!.month, progress.date!.day);
    progress.date = startOfDay;
    await _isar.writeTxn(() async {
      await _isar.goalProgressModels.put(progress);
    });
  }

  Future<List<GoalProgressModel>> getGoalHistory(DateTime start, DateTime end) async {
    return await _isar.goalProgressModels
        .filter()
        .dateBetween(start, end)
        .sortByDate()
        .findAll();
  }

  // --- Notification Log CRUD ---
  Future<List<NotificationLogModel>> getNotifications() async {
    return await _isar.notificationLogModels
        .where()
        .sortByTimestampDesc()
        .findAll();
  }

  Future<void> addNotification(NotificationLogModel log) async {
    await _isar.writeTxn(() async {
      await _isar.notificationLogModels.put(log);
    });
  }

  Future<void> markNotificationAsRead(int id) async {
    await _isar.writeTxn(() async {
      final item = await _isar.notificationLogModels.get(id);
      if (item != null) {
        item.isRead = true;
        await _isar.notificationLogModels.put(item);
      }
    });
  }

  Future<void> clearNotifications() async {
    await _isar.writeTxn(() async {
      await _isar.notificationLogModels.where().deleteAll();
    });
  }

  // --- Settings CRUD ---
  Future<SettingsModel> getSettings() async {
    final settings = await _isar.settingsModels.where().findFirst();
    if (settings != null) return settings;
    // Fallback if null
    return SettingsModel()
      ..isDarkMode = true
      ..themeMode = 'system'
      ..languageCode = 'en'
      ..unitSystem = 'metric'
      ..autoReconnect = true
      ..enableNotifications = true
      ..isDeveloperMode = true;
  }

  Future<void> saveSettings(SettingsModel settings) async {
    await _isar.writeTxn(() async {
      await _isar.settingsModels.put(settings);
    });
  }
}
