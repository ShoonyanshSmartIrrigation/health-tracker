import 'package:isar/isar.dart';

part 'isar_models.g.dart';

@collection
class UserProfileModel {
  Id id = Isar.autoIncrement;
  String? name;
  int? age;
  String? gender;
  double? heightCm;
  double? weightKg;
  
  // Goals
  int? dailyStepGoal;
  int? dailyWaterGoal;
  int? dailyCaloriesGoal;
  double? targetSleepHours;
}

@collection
class HealthDataPointModel {
  Id id = Isar.autoIncrement;
  
  @Index()
  DateTime? timestamp;
  
  int? heartRate;
  int? steps;
  int? spo2;
  double? temperature;
  int? batteryLevel;
  double? caloriesBurned;
}

@collection
class GoalProgressModel {
  Id id = Isar.autoIncrement;

  @Index()
  DateTime? date; // Day timestamp (truncated to midnight)

  int? stepsCount;
  int? waterMl;
  double? caloriesBurned;
  double? sleepHours;

  bool? stepsGoalAchieved;
  bool? waterGoalAchieved;
  bool? caloriesGoalAchieved;
  bool? sleepGoalAchieved;
}

@collection
class NotificationLogModel {
  Id id = Isar.autoIncrement;

  @Index()
  DateTime? timestamp;

  String? title;
  String? message;
  String? type; // 'low_battery', 'high_heart_rate', 'low_spo2', etc.
  bool? isRead;
}

@collection
class SettingsModel {
  Id id = Isar.autoIncrement;

  bool? isDarkMode;
  String? themeMode; // 'light', 'dark', 'system'
  String? languageCode; // 'en', etc.
  String? unitSystem; // 'metric', 'imperial'
  bool? autoReconnect;
  bool? enableNotifications;
  bool? isDeveloperMode; // simulator toggle
}
